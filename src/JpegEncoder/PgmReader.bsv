// Copyright(c) 2022 https://github.com/WangXuan95

package PgmReader;

import Vector::*;
import FIFOF::*;
import BRAMFIFO::*;
import StmtFSM::*;

// mkPgmReader 的接口，用来读取 .pgm 灰度图像
interface PgmReader;
   method int  image_width;
   method int  image_height;
   method ActionValue#(Vector#(8, UInt#(8))) get_pixels;
   method Bool not_finish;
endinterface


// 用来读取 .pgm 灰度图像，最大支持 4088*4088 的图像
module mkPgmReader#(parameter String pgm_file_name) (PgmReader);
   let filep <- mkReg(InvalidFile);
   Reg#(int) i <- mkReg(0);                                               // mkAutoFSM 中的循环变量 i
   Reg#(int) j <- mkReg(0);                                               // mkAutoFSM 中的循环变量 j
   Vector#(3, Reg#(int)) image_params <- replicateM( mkReg(0) );          // 图像宽、高、深（深是指像素阶数，比如 8bit 图像深度是 255）
   int width = image_params[0];
   int height= image_params[1];
   Reg#(Bit#(64)) load_pixels <- mkReg('0);
   FIFOF#(Vector#(8, UInt#(8))) pixel_fifo <- mkSizedBRAMFIFOF(2097152);
   
   FSM fsm <- mkFSM(  seq
      // 1. 打开文件，打开失败则退出
      action
         let filep_tmp <- $fopen( pgm_file_name, "rb" );
         if( filep_tmp == InvalidFile ) begin
            $error("  Error: invalid file: %s", pgm_file_name);
            $finish;
         end else
            filep <= filep_tmp;
      endaction

      // 2. 检查头部是否是 "P5" ，不是则退出
      for(i<=0; i<2; i<=i+1) action
         int header [2] = {'h50, 'h35};
         int chx <- $fgetc(filep);
         if(chx != header[i]) begin
            $error("  Error: file %s header is not P5", pgm_file_name);
            $finish;
         end
      endaction

      // 3. 读取ASCII字符形式的图像 宽、高、深 ，出现不合法格式则退出
      for(i<=0; i<3; i<=i) action
         int chx <- $fgetc(filep);
         if( chx >= 'h30 && chx <= 'h39 ) begin
            image_params[i] <= image_params[i] * 10 + chx - 'h30;
         end else if(chx == 'h20 || chx == 'h09 || chx == 'h0D || chx == 'h0A) begin
            if( image_params[i] > 0 )
               i <= i + 1;
         end else begin
            $error("  Error: file %s invalid format", pgm_file_name);
            $finish;
         end
      endaction

      // 4. 读取像素到 pixel_fifo 中
      for(i<=0; i<width*height; i<=i+8) seq
         for(j<=0; j<8; j<=j+1) action
            int chx <- $fgetc(filep);
            load_pixels <= {pack(chx)[7:0], load_pixels[63:8]};
         endaction
         pixel_fifo.enq(unpack(load_pixels));
      endseq

      $fclose(filep);
      $display("  Image load done, width=%5d, height=%5d", width, height);
   endseq );

   rule start_fsm (width == 0);
      fsm.start;
   endrule

   method int image_width  if(width>0 && fsm.done) = width;
   method int image_height if(width>0 && fsm.done) = height;

   method ActionValue#(Vector#(8, UInt#(8))) get_pixels if(width>0 && fsm.done);
      pixel_fifo.deq;
      return pixel_fifo.first;
   endmethod

   method Bool not_finish = width==0 || !fsm.done || pixel_fifo.notEmpty;
endmodule


endpackage
