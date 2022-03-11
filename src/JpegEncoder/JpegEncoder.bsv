// Copyright(c) 2022 https://github.com/WangXuan95

package JpegEncoder;

// standard BSV packages
import Vector::*;
import DReg::*;
import StmtFSM::*;

// user defined packages
import MoreRegs::*;
import DoubleBuffer::*;


interface JpegEncoder;
   method Action init(UInt#(9) xtile, UInt#(9) ytile);
   method Action waitTillDone;
   method Action put(Vector#(8, UInt#(8)) pixels);        // input a line of pixels (8 * UInt#(8))
   method Bit#(128) get;
endinterface


(* synthesize *)
module mkJpegEncoder (JpegEncoder);
   
   Reg#(Bit#(32)) x_y_bytes  <- mkReg(0);

   Bit#(128) jpg_header [18] = {               // .jpg 图像头，除了图像高、宽根据不同图像而改变外，其余都是固定内容（对任何图像都一样）
      128'hffd8000000ffe000104a464946000101,
      128'h00000100010000ffdb00430010080808,
      128'h08080808080808080808080810101010,
      128'h10101010101010101010101020202020,
      128'h20202020202020202020202040404040,
      128'h404040404040404040404040ffc0000b,
      {8'h08, x_y_bytes, 88'h01011100ffc400ab000000},   // 图像高(16bit)、宽(16bit) 填在此处
      128'h00000000000800000000000000000102,
      128'h03040506070010000000000000007f00,
      128'h0000000000000001020304050607f011,
      128'h12131415161700212223242526272831,
      128'h32333435363738414243444546474851,
      128'h52535455565758616263646566676871,
      128'h72737475767778818283848586878891,
      128'h92939495969798a1a2a3a4a5a6a7a8b1,
      128'hb2b3b4b5b6b7b8c1c2c3c4c5c6c7c8d1,
      128'hd2d3d4d5d6d7d8e1e2e3e4e5e6e7e8f1,
      128'hf2f3f4f5f6f7ffda0008010100003f00  };
   
   Bit#(128) jpg_footer = 128'hffd90000000000000000000000000000;   // .jpg 文件尾，是固定内容（对任何图像都一样）
   
   Int#(24) dct_matrix [8][8] = {              // 用于进行 DCT 变换的左乘/右乘的常数矩阵
      { 32, 32, 32, 32, 32, 32, 32, 32},
      { 44, 38, 25,  9, -9,-25,-38,-44},
      { 42, 17,-17,-42,-42,-17, 17, 42},
      { 38, -9,-44,-25, 25, 44,  9,-38},
      { 32,-32,-32, 32, 32,-32,-32, 32},
      { 25,-44,  9, 38,-38, -9, 44,-25},
      { 17,-42, 42,-17,-17, 42,-42, 17},
      {  9,-25, 38,-44, 44,-38, 25, -9}
   };
   
   UInt#(3) zig_map [8][8][2] = {     // zig-zag重排序下标 map。 zig-zag重排序公式是： D[i][j] = S[ zig_map[y][x][1] ][ zig_map[y][x][2] ];
      { {0,0}, {0,1}, {1,0}, {2,0}, {1,1}, {0,2}, {0,3}, {1,2} },
      { {2,1}, {3,0}, {4,0}, {3,1}, {2,2}, {1,3}, {0,4}, {0,5} },
      { {1,4}, {2,3}, {3,2}, {4,1}, {5,0}, {6,0}, {5,1}, {4,2} },
      { {3,3}, {2,4}, {1,5}, {0,6}, {0,7}, {1,6}, {2,5}, {3,4} },
      { {4,3}, {5,2}, {6,1}, {7,0}, {7,1}, {6,2}, {5,3}, {4,4} },
      { {3,5}, {2,6}, {1,7}, {2,7}, {3,6}, {4,5}, {5,4}, {6,3} },
      { {7,2}, {7,3}, {6,4}, {5,5}, {4,6}, {3,7}, {4,7}, {5,6} },
      { {6,5}, {7,4}, {7,5}, {6,6}, {5,7}, {6,7}, {7,6}, {7,7} }
   };
   
   function Int#(8) quant(Int#(9) x, UInt#(3) q);
      Int#(8) y = unpack(pack(x)[8:1]);
      y = (y>>q) + ( (pack(x)[q]==1'b1) ? 1 : 0 );
      if     (y>  63) y =  63;
      else if(y< -63) y = -63;
      return y;
   endfunction
   
   function UInt#(3) getLength(Int#(8) x);
      Bit#(7) v = (x>0) ? pack(x)[6:0] : pack(-x)[6:0];
      UInt#(3) len = 0;
      Bool one = False;
      for(int i=6; i>=0; i=i-1) begin 
         if(v[i]==1'b1) one = True;
         if(one) len = len + 1;
      end
      return len;
   endfunction
   
   function Bit#(7) getBits(Int#(8) x);
      UInt#(7) v = unpack(pack(x)[6:0]);
      return (x<0) ? pack(v-1) : pack(v);
   endfunction

   ReorderDoubleBuffer#(3, 9, Vector#(8, UInt#(8)))   linebuf     <- mkReorderDoubleBuffer;

   Vector#(8, Reg#(Int#(8)))                          norm_pixels <- replicateM( mkValidReg );

   DoubleBuffer#( 8, Vector#(8, Int#(24)) )    dcta_double_buffer <- mkDoubleBuffer(8);
   DoubleBuffer#( 8, Vector#(8, Int#( 9)) )    dctb_double_buffer <- mkDoubleBuffer(8);

   Vector#(8, Reg#(Int#(9)))                          zig_pixels  <- replicateM( mkReg(0) );
   Reg#(UInt#(3))                                     zig_sy      <- mkValidReg;

   Reg#(Vector#(8,Int#(8)))                           qnt_pixels  <- mkReg( replicate(0) );
   Reg#(Int#(8))                                      qnt_prev_dc <- mkReg(0);
   Reg#(UInt#(3))                                     qnt_sy      <- mkValidReg;

   Reg#(UInt#(4))                                     c_prev_zcnt <- mkReg(0);
   Vector#(8, Reg#(Bool))                             c_valid     <- replicateM( mkValidReg );
   Vector#(8, Reg#(UInt#(4)))                         c_zcnt      <- replicateM( mkReg(0) );
   Vector#(8, Reg#(UInt#(3)))                         c_len       <- replicateM( mkReg(0) );
   Vector#(8, Reg#(Bit#(7)))                          c_code      <- replicateM( mkReg(0) );

   Vector#(8, Reg#(UInt#(4)))                         pm_len      <- replicateM( mkDReg(0) );
   Vector#(8, Reg#(Bit#(14)))                         pm_bits     <- replicateM( mkDReg(0) );
   Reg#(Bool)                                         pm_en       <- mkDReg(False);

   Reg#(UInt#(8))                                     lm_len      <- mkReg(0);
   Reg#(Bit#(120))                                    lm_bits     <- mkValidReg;

   Reg#(UInt#(8))                                     st_rem_len  <- mkReg(0);
   Reg#(Bit#(128))                                    st_rem_bits <- mkReg(0);

   Reg#(Bit#(128))                                    j_data      <- mkValidReg;

   // 3. get pixels from linebuf, and act pixel-=128 on each pixel --------------------------------------------------------------------------------
   rule normalize;
      let bufout_pixels <- linebuf.get;
      for(int x=0; x<8; x=x+1)
         norm_pixels[x] <= unpack(pack(bufout_pixels[x] - 128));
   endrule

   // 4. DCT-A transform 8 pixel wise -----------------------------------------------------------------------------------------------------------------------
   rule dct_a_transform;
      Vector#(8, Int#(24)) dcta_line = replicate(0);
      for(int y=0; y<8; y=y+1)
         for(int x=0; x<8; x=x+1)
            dcta_line[y] = dcta_line[y] + extend(norm_pixels[x]) * dct_matrix[y][x];
      dcta_double_buffer.put(dcta_line);
   endrule

   // 5. DCT-B transform 8 pixel wise -----------------------------------------------------------------------------------------------------------------------
   rule dct_b_transform;
      match {.dctb_x, .dcta_tile} <- dcta_double_buffer.get;
      Vector#(8, Int#(9)) dctb_line;
      for(int y=0; y<8; y=y+1) begin
         Int#(24) acc = 0;
         for(int x=0; x<8; x=x+1)
            acc = acc + dcta_tile[x][dctb_x] * dct_matrix[y][x];
         dctb_line[y] = truncate(acc>>15);
      end
      dctb_double_buffer.put(dctb_line);
   endrule

   // 6. zig-zag ordering ---------------------------------------------------------------------------------------------------------------------------------
   rule zig_zag_ordering;
      match {.zig_y, .dctb_tile} <- dctb_double_buffer.get;
      for(int x=0; x<8; x=x+1)
         zig_pixels[x] <= dctb_tile[ zig_map[zig_y][x][1] ][ zig_map[zig_y][x][0] ];
      zig_sy <= truncate(zig_y);
   endrule

   (* mutually_exclusive = "init, quantization" *)   // for qnt_prev_dc._write

   // 7. quantization and DC-to-AC (DC value at [0][0]) ----------------------------------------------------------------------------------------------
   rule quantization;
      Vector#(8, Int#(8)) pixels;
      for(int x=0; x<8; x=x+1) begin
         UInt#(3) quant_level = zig_sy >> 1;
         if(zig_sy==0 && x==0) quant_level = 1;
         pixels[x] = quant(zig_pixels[x], quant_level);
      end
      if(zig_sy == 0) begin
         qnt_prev_dc <= pixels[0];
         pixels[0] = pixels[0] - qnt_prev_dc;
      end
      qnt_pixels <= pixels;
      qnt_sy     <= zig_sy;
   endrule

   // 8. bit coding & run-length coding ----------------------------------------------------------------------------------------------------------------
   rule coding;
      Bool mask [8];
      for(int i=0; i<8; i=i+1)
         mask[i] = i==0 && qnt_sy==0 || qnt_pixels[i]!=0;

      UInt#(4) zcnts [8];
      zcnts[0] = c_prev_zcnt + (mask[0] ? 0 : 1);
      for(int i=1; i<8; i=i+1)
         zcnts[i] = (mask[i-1] ? 0 : zcnts[i-1]) + (mask[i] ? 0 : 1);
      c_prev_zcnt <= (qnt_sy==7 || mask[7]) ? 0 : zcnts[7];

      for(int i=0; i<8; i=i+1) begin
         c_valid[i]<= (mask[i] || zcnts[i]==0 || i==7 && qnt_sy==7);
         c_zcnt[i] <= (mask[i] || zcnts[i]==0) ? zcnts[i] : 1;
         c_len[i]  <= getLength(qnt_pixels[i]);
         c_code[i] <= getBits(qnt_pixels[i]);
      end
   endrule
   
   // 9. pixel-wise bit merge ----------------------------------------------------------------------------------------------------------------
   rule pixel_wise_bit_merge;
      for(int i=0; i<8; i=i+1) begin
         if(c_valid[i]) begin
            Bit#(7) code = c_code[i] << (7 - c_len[i]);
            pm_bits[i] <= { pack(c_zcnt[i]), pack(c_len[i]-1), code };
            pm_len[i] <= 8 + extend(c_len[i]);
         end
      end
      pm_en <= True;
   endrule

   // 10. line-wise bit merge ----------------------------------------------------------------------------------------------------------------
   rule line_wise_bit_merge (pm_en);
      UInt#(8) len = 0;
      Bit#(120) bits = '0;
      for(int i=0; i<8; i=i+1) begin
         bits = bits | ( {106'b0, pm_bits[i]} << (105-len) );
         len = len + extend(pm_len[i]);
      end
      lm_len  <= len;
      lm_bits <= bits;
   endrule


   Reg#(UInt#(5))                                     header_idx <- mkReg(0);
   Reg#(UInt#(24))                                    inout_cnt  <- mkReg(0);
   Reg#(UInt#(24))                                    input_idx  <- mkReg(0);
   Reg#(UInt#(24))                                    output_idx <- mkReg(0);
   Wire#(Vector#(8, UInt#(8)))                        put_pixel  <- mkWire;

   FSM fsm <- mkFSM( seq
      st_rem_len  <= 0;
      st_rem_bits <= 0;
      for(header_idx<=0; header_idx<18; header_idx <= header_idx + 1)
         j_data <= jpg_header[header_idx];
      par
         seq
            input_idx <= inout_cnt;
            while(input_idx > 0) action
               input_idx <= input_idx - 1;
               linebuf.put(put_pixel);
            endaction
            noAction;
         endseq
         seq
            output_idx <= inout_cnt;
            while(output_idx > 0) action
               output_idx <= output_idx - 1;
               let len  = st_rem_len + lm_len;
               let bits = {st_rem_bits, 120'b0} | ( {lm_bits, 128'b0} >> st_rem_len );
               if(len >= 128) begin
                  j_data  <= bits[247:120];
                  len  = len - 128;
                  bits = {bits[119:0], 128'b0};
               end
               st_rem_len  <= len;
               st_rem_bits <= bits[247:120];
            endaction
            noAction;
         endseq
      endpar
      j_data <= st_rem_bits;
      j_data <= jpg_footer;
      noAction;
   endseq );

   // initialize, should be called once before input a image -------------------------------------------------------------------------------------------
   method Action init(UInt#(9) xtile, UInt#(9) ytile);
      if(xtile == 0) xtile = 1;
      if(ytile == 0) ytile = 1;
      x_y_bytes <= {4'h0, pack(ytile), 3'h0, 4'h0, pack(xtile), 3'h0};
      inout_cnt <= extend(xtile) * extend(ytile) << 3;
      linebuf.rewind(7, xtile-1, True, False, False);
      fsm.start;
      qnt_prev_dc <= 0;
   endmethod

   method waitTillDone = fsm.waitTillDone;

   // put 8 pixels to line-buffer -----------------------------------------------------------------------------------------------------------------------
   method put if(input_idx>0) = put_pixel._write;

   method get = j_data;

endmodule



endpackage
