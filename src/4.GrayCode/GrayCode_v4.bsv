// 把组合逻辑电路实现为 function 
// 对于常用、普适的组合逻辑电路，推荐这种方式！
// 这里，function 定义在了 module 内，是 module 内私有的，其它 module 或 package 无法调用。

package GrayCode_v4;

module mkTb ();

   // 把二进制编码转化为格雷码
   function Bit#(6) binary2gray(Bit#(6) value);
      return (value >> 1) ^ value;
   endfunction
   
   // 把格雷码转化为二进制编码
   function Bit#(6) gray2binary(Bit#(6) value);
      for(int i=4; i>=0; i=i-1)
         value[i] = value[i] ^ value[i+1];
      return value;
   endfunction

   // 寄存器
   Reg#(Bit#(6)) cnt <- mkReg(0);

   rule up_counter;           // 每周期都执行
      cnt <= cnt + 1;         // cnt 从0自增到63
      if(cnt >= 63) $finish;  // 自增到 63 时，仿真结束
   endrule

   rule convert;
      Bit#(6) cnt_gray = binary2gray(cnt);       // 调用函数 binary2gray
      Bit#(6) cnt_bin  = gray2binary(cnt_gray);  // 调用函数 gray2binary
      $display("cnt=%b   cnt_gray=%b   cnt_bin=%b", cnt, cnt_gray, cnt_bin );
   endrule

endmodule

endpackage
