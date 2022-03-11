// 功能：8*8 的矩阵转置，用 BRAM 做缓存


package TransposeBuffer;

import BRAM::*;


// 流式 8x8 矩阵转置器 的接口
interface TransposeBuffer;
   method Action rewind;            // 重置，如果当前有一块没有完全写完，则撤销其中已有的数据，重新写入
   method Action put(int val);      // 向矩阵转置器中写入行主序的数据
   method ActionValue#(int) get;    // 从矩阵转置器中获取列主序的数据
endinterface


// 流式 8x8 矩阵转置器
module mkTransposeBuffer88 (TransposeBuffer);

   BRAM2Port#( Tuple3#(bit, UInt#(3), UInt#(3)) , int ) ram <- mkBRAM2Server(defaultValue);

   Reg#(Bit#(2))  wblock <- mkReg(0);    // 写块号
   Reg#(UInt#(3)) wi     <- mkReg(0);    // 写行号
   Reg#(UInt#(3)) wj     <- mkReg(0);    // 写列号

   Reg#(Bit#(2))  rblock <- mkReg(0);    // 读块号
   Reg#(UInt#(3)) ri     <- mkReg(0);    // 读行号
   Reg#(UInt#(3)) rj     <- mkReg(0);    // 读列号

   // 双缓冲空满判断
   Wire#(Bool) empty <- mkWire;
   Wire#(Bool) full  <- mkWire;
   rule empty_full;
      empty <= wblock == rblock;
      full  <= wblock == {~rblock[1], rblock[0]};
   endrule

   rule read_ram ( !empty );
      ram.portB.request.put(BRAMRequest{write: False, responseOnWrite: False, address: tuple3(rblock[0], ri, rj), datain: 0 } );
      ri <= ri + 1;
      if(ri == 7) begin
         rj <= rj + 1;
         if(rj == 7)
            rblock <= rblock + 1;
      end
   endrule

   PulseWire rewind_call <- mkPulseWire;

   method Action rewind if( empty );
      rewind_call.send;
      wi <= 0;
      wj <= 0;
   endmethod

   method Action put(int val) if( !full && !rewind_call );
      ram.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: tuple3(wblock[0], wi, wj), datain: val } );
      wj <= wj + 1;
      if(wj == 7) begin
         wi <= wi + 1;
         if(wi == 7)
            wblock <= wblock + 1;
      end
   endmethod

   method get = ram.portB.response.get;

endmodule



// mkTransposeBuffer88 的 testbench
// 行为：向矩阵转置器中输入 0,1,2,3,...,255 。然后打印输出
module mkTb ();
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
   endrule

   Reg#(int) indata <- mkReg(0);
   Reg#(int) cnt_ref <- mkReg(0);

   let transposebuffer <- mkTransposeBuffer88;

   (* preempts = "transposebuffer_rewind, transposebuffer_put" *)
   rule transposebuffer_rewind (cnt == 0);
      transposebuffer.rewind;
   endrule

   rule transposebuffer_put; // (cnt%2 == 0);   // 矩阵转置器 输入，可添加隐式条件来实现不积极输入
      transposebuffer.put(indata);
      indata <= indata + 1;
   endrule

   rule transposebuffer_get; // (cnt%3 == 0);   // 矩阵转置器 输出并验证，可添加隐式条件来实现不积极输出
      cnt_ref <= cnt_ref + 1;

      int data_ref = unpack( { pack(cnt_ref)[31:6], pack(cnt_ref)[2:0], pack(cnt_ref)[5:3] } );
      
      int data_out <- transposebuffer.get;

      $display("cnt=%3d    output_data:%3d    reference_data:%3d", cnt, data_out, data_ref);

      if(data_out != data_ref) $display("wrong!");

      if(data_ref >= 255) $finish;
   endrule

endmodule


endpackage
