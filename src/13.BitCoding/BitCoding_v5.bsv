package BitCoding_v5;

import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;


(* synthesize *)
//(* always_ready="clear" *)     // 用 always_ready 来删除 clear 方法的 RDY 信号
module mkBitCoder ( FIFO#(Bit#(8)) );

   FIFO#(Bit#(8))                      fifo1 <- mkFIFO;
   FIFOF#(Tuple2#(Bit#(10), UInt#(4))) fifo2 <- mkDFIFOF( tuple2(0, 0) );   // 由流水线第一级enq ，第二级deq ，存放生成码 code 以及其长度
   FIFO#(Bit#(8))                      fifo3 <- mkFIFO;                     // 输出数据 fifo ，存放输出码 dout

   Reg#(Tuple2#(Bit#(31), UInt#(6))) drem_reg <- mkReg( tuple2(0, 0) );     // 存放遗留码 drem 以及其长度

   // 流水线第一级：计算生成码 code 以及其长度
   rule get_code;
      fifo1.deq;
      Bit#(8) din = fifo1.first;                          // din: 输入数据

      UInt#(4) len = 0;
      for(UInt#(4) i=0; i<8; i=i+1)                       // for循环：计算长度码 len
         if(din[i] == 1)
            len = i;
      
      UInt#(4) trim_len = len>0 ? extend(len) : 1;        // 计算数据码 trim 的长度
      Bit#(7) trim = truncate(din) & ~('1<<trim_len);     // 获取数据码 trim （保留 din 的低 trim_len 个 bit，其余高位置 0）
      
      Bit#(10) code = {trim, pack(len)[2:0]};             // 获取生成码 code

      fifo2.enq(tuple2( code, trim_len+3 ));
   endrule
   
   (* conflict_free = "clear, get_drem_and_dout" *)

   // 流水线第二级：更新遗留数据和输出数据
   rule get_drem_and_dout;
      match {.drem, .drem_len} = drem_reg;                // 拿到遗留码 drem 以及其长度
      match {.code, .code_len} = fifo2.first;             // 拿到生成码 code 以及其长度

      if(extend(code_len) + drem_len < 32) begin          // 只有当不会导致溢出
         fifo2.deq;                                       //   才取出数据
         drem = (extend(code) << drem_len) | drem;        //   生成码 拼接 遗留数据
         drem_len = extend(code_len) + drem_len;          //   长度 = 生成码长度 + 遗留码长度
      end

      if(drem_len >= 8) begin                             // 如果总长度 >= 8 ，说明攒够了，输出一次
         fifo3.enq( truncate(drem) );                     //   输出数据 dout 到 fifo3
         drem = drem >> 8;                                //   高于 8 位的 bit 作为遗留数据
         drem_len = drem_len - 8;                         //   遗留数据长度-8, 因为有 8 bit 输出了
      end

      drem_reg <= tuple2(drem, drem_len);                 // 保存遗留码 drem 以及其长度到 drem_reg ，供下次使用
   endrule

   method enq   = fifo1.enq;
   method deq   = fifo3.deq;
   method first = fifo3.first;
   method Action clear;
      drem_reg <= tuple2(0, 0);
      fifo1.clear;
      fifo2.clear;
      fifo3.clear;
   endmethod
endmodule



module mkTb();
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
   endrule

   Reg#(Bit#(10)) din <- mkReg(0);
   FIFO#(Bit#(8)) coder <- mkBitCoder;

   rule coder_put;// (cnt%4 == 0);    // 可以添加条件，实现按需输入
      din <= din + 1;                  // din 每增长一次
      if(din < 'h200)
         coder.enq( truncate(din) );   // 就把它输入 coder
      else if(din == '1)
         $finish;
   endrule

   rule coder_get;// (cnt%2 == 0);    // 因为 coder 中能积攒数据，所以可以添加条件，来让一些周期不读取 dout ，也不会导致数据丢失
      coder.deq;
      $display("cnt=%4d   %b", cnt, coder.first);
   endrule
endmodule


endpackage
