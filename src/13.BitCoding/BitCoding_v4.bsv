package BitCoding_v4;

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
   method Action  put(Bit#(8) din);    // 动作方法：输入 8 bit数据
   method ActionValue#(Bit#(8)) get;   // 动作值方法：获取 dout
endinterface


(* synthesize *)
module mkBitCoder (BitCoder);
   // 流水线第一级产生的数据，默认 code 和 code 的长度都是 0
   Reg#(Tuple2#(Bit#(10), UInt#(4))) in_code_and_len <- mkReg( tuple2(0,0) );   // code 和 code 的长度
   Reg#(Bool)    din_valid  <- mkReg(False);    // 指示 in_code_and_len 是否有效
   
   // 流水线第二级产生的数据
   Reg#(Bit#(31)) drem      <- mkReg(0);        // 存放遗留码
   Reg#(UInt#(6)) drem_len  <- mkReg(0);        // 遗留码的长度
   Reg#(Bool)     dout_valid<- mkReg(False);    // 指示 dout 是否有效
   Reg#(Bit#(8))  dout      <- mkReg(0);

   (* conflict_free = "put, get_drem_and_dout" *)

   // 流水线第二级：更新遗留数据和输出数据
   rule get_drem_and_dout (!dout_valid);
      Bit#(31) data = drem;                  // 拿到遗留数据
      UInt#(6) len = drem_len;               // 拿到遗留数据长度

      match {.code, .code_len} = in_code_and_len;

      if(extend(code_len) + drem_len < 32 && din_valid) begin// 只有当不会导致溢出，且 din 有效时
         data = (extend(code) << drem_len) | data;           //    才拿出流水线第一级的 code
         len = extend(code_len) + len;                       //    才拿出流水线第一级的 code_len
         din_valid <= False;                                 //    把 din_valid 置为无效（因为已经决定拿出数据了）
      end

      if(len >= 8) begin                    // 如果总长度 >= 8 ，说明攒够了，可以输出一次
         dout_valid <= True;                //   把输出数据置有效
         dout <= truncate(data);            //   输出数据取低 8 bit
         data = data >> 8;                  //   高于 8 位的 bit 作为遗留数据
         len = len - 8;                     //   遗留数据长度-8, 因为有 8 bit 输出了
      end

      drem <= data;                         // 保存遗留数据，供下次使用
      drem_len <= len;                      // 保存遗留数据长度，供下次使用
   endrule

   // 流水线第一级：获取 code 以及其长度
   method Action put(Bit#(8) din) if(!din_valid);   // 隐式条件保证下一周期 drem 的长度不会溢出
      din_valid <= True; 
      in_code_and_len <= getCode(din);              // 计算 code 和 code 的长度
   endmethod

   method ActionValue#(Bit#(8)) get if(dout_valid);   // 隐式条件：输出数据置有效
      dout_valid <= False;                            // 把输出数据置无效（因为已经决定拿出数据了）
      return dout;
   endmethod
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

   rule coder_get;// (cnt%2 == 0);    // 因为 coder 中能积攒数据，所以可以添加条件，来让一些周期不读取 dout ，也不会导致数据丢失
      let dout <- coder.get;
      $display("cnt=%4d   %b", cnt, dout);
   endrule
endmodule


endpackage
