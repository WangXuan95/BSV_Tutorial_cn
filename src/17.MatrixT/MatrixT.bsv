// 功能：8*8 的矩阵转置，用 BRAM 做缓存


package MatrixT;

import BRAM::*;


// 流式 8x8 矩阵转置器 的接口
interface MatrixT;
   method Action datain(int val);      // 向矩阵转置器中写入行主序的数据
   method ActionValue#(int) dataout;   // 从矩阵转置器中获取列主序的数据
endinterface


// 流式 8x8 矩阵转置器
module mkMatrixT (MatrixT);

   BRAM2Port#( Tuple3#(bit, UInt#(3), UInt#(3)) , int ) ram <- mkBRAM2Server(defaultValue);

   Reg#(Bit#(2))  wb <- mkReg(0);    // 写块号
   Reg#(UInt#(3)) wi <- mkReg(0);    // 写行号
   Reg#(UInt#(3)) wj <- mkReg(0);    // 写列号

   Reg#(Bit#(2))  rb <- mkReg(0);    // 读块号
   Reg#(UInt#(3)) ri <- mkReg(0);    // 读行号
   Reg#(UInt#(3)) rj <- mkReg(0);    // 读列号

   // 双缓冲空满判断
   Wire#(Bool) empty <- mkWire;
   Wire#(Bool) full  <- mkWire;
   rule empty_full;
      empty <= wb == rb;
      full  <= wb == {~rb[1], rb[0]};
   endrule

   rule read_ram (!empty);
      ram.portB.request.put(BRAMRequest{write: False, responseOnWrite: False, address: tuple3(rb[0], ri, rj), datain: 0 } );
      ri <= ri + 1;
      if(ri == 7) begin
         rj <= rj + 1;
         if(rj == 7)
            rb <= rb + 1;
      end
   endrule

   method Action datain(int val) if(!full);
      ram.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: tuple3(wb[0], wi, wj), datain: val } );
      wj <= wj + 1;
      if(wj == 7) begin
         wi <= wi + 1;
         if(wi == 7)
            wb <= wb + 1;
      end
   endmethod

   method ActionValue#(int) dataout;
      let val <- ram.portB.response.get;
      return val;
   endmethod

endmodule



// 流式 8x8 矩阵转置器 的 testbench
// 行为：向矩阵转置器中输入 0,1,2,3,...,255 。然后打印输出
module mkTb ();
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
   endrule

   Reg#(int) data_in <- mkReg(0);
   Reg#(int) cnt_ref   <- mkReg(0);

   let matrixt <- mkMatrixT;

   rule matrixt_input (cnt%3 == 1);    // 矩阵转置器 输入，可添加隐式条件来实现不积极输入
      matrixt.datain(data_in);
      data_in <= data_in + 1;
   endrule

   rule matrixt_output (cnt%2 == 1);   // 矩阵转置器 输出和验证，可添加隐式条件来实现不积极输出
      cnt_ref <= cnt_ref + 1;

      int data_ref = unpack( { pack(cnt_ref)[31:6], pack(cnt_ref)[2:0], pack(cnt_ref)[5:3] } );
      
      int data_out <- matrixt.dataout;

      $display("cnt=%3d    output_data:%3d    reference_data:%3d", cnt, data_out, data_ref);

      if(data_out != data_ref) $display("wrong!");

      if(data_ref >= 255) $finish;
   endrule

endmodule


endpackage
