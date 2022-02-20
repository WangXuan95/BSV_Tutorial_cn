package BitCoding_v2;

import DReg::*;

// 用于计算 code 和 code 的长度
function Tuple2#(Bit#(10), UInt#(4)) getCode(Bit#(8) din);
   // 计算长度码 len
   UInt#(4) len = 0;
   for(UInt#(4) i=0; i<8; i=i+1)
      if(din[i] == 1)
         len = i;
   
   // 计算数据码 trim 的长度
   UInt#(4) trim_len = len>0 ? len : 1;

   // 获取数据码 trim （保留 din 的低 trim_len 个 bit，其余高位置 0）
   Bit#(7) trim = truncate(din) & ~('1<<trim_len);

   // 获取生成码 code
   Bit#(10) code = {trim, pack(len)[2:0]};

   return tuple2( code, trim_len+3 );
endfunction


interface BitCoder;
   method Action   put(Bit#(8) din);    // 动作方法：输入 8 bit数据
   method Bit#(16) get;                 // 值方法：获取 dout
endinterface


(* synthesize *)
module mkBitCoder (BitCoder);
   // 流水线第一级产生的数据，默认 code 和 code 的长度都是 0
   Reg#(Tuple2#(Bit#(10), UInt#(4))) in_code_and_len <- mkDReg( tuple2(0,0) );   // code 和 code 的长度
   
   // 流水线第二级产生的数据
   Reg#(Bit#(31)) drem       <- mkReg(0);        // 存放遗留码
   Reg#(UInt#(5)) drem_len   <- mkReg(0);        // 遗留码的长度
   Reg#(Bool)     dout_valid <- mkDReg(False);   // dout 是否有效
   Reg#(Bit#(16)) dout       <- mkReg(0);

   // 流水线第二级：更新遗留数据和输出数据
   rule get_drem_and_dout;
      match {.code, .code_len} = in_code_and_len;  // 当流水线上一级没有数据时，默认读到 0 ，不会对本 rule 造成副作用

      Bit#(31) data = (extend(code) << drem_len) | drem;   // data = code 拼接 drem
      UInt#(5) len = extend(code_len) + drem_len;

      if(len >= 16) begin                   // 如果总长度 >= 16 ，说明攒够了，可以输出一次
         dout_valid <= True;                //   输出有效
         dout <= truncate(data);            //   输出数据取低 16 bit
         data = data >> 16;                 //   高于 16 位的 bit 作为遗留数据
         len = len - 16;                    //   遗留数据长度-16， 因为有 16 bit 输出了
      end

      drem <= data;                         // 保存遗留数据，供下次使用
      drem_len <= len;                      // 保存遗留数据长度，供下次使用
   endrule

   // 流水线第一级：获取 code 以及其长度
   method Action put(Bit#(8) din);          // 动作方法：输入 din 时调用此方法
      in_code_and_len <= getCode(din);      // 计算 code 和 code 的长度
   endmethod

   method Bit#(16) get if(dout_valid) = dout;   // 值方法，隐式条件为 dout_valid=True
endmodule


module mkTb();
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
   endrule

   Reg#(Bit#(10)) din <- mkReg(0);
   let coder <- mkBitCoder;

   rule coder_put;
      din <= din + 1;                  // din 每增长一次
      if(din < 'h200)
         coder.put( truncate(din) );   // 就把它输入 coder
      else if(din == '1)
         $finish;
   endrule

   rule coder_get;
      $display("cnt=%4d   %b", cnt, coder.get);   // 只在 coder.get_valid 有效周期打印输出，因为 coder.get 具有隐式条件，不需要显式指定条件
   endrule
endmodule


endpackage
