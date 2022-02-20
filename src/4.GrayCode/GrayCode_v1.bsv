// 把组合逻辑电路实现在 rule 内 
// 组合逻辑的结果变量的作用域仅仅是当前 rule 内。
// 限制变量的作用域，有利于提高可读性！！

package GrayCode_v1;

module mkTb ();

   // 寄存器
   Reg#(Bit#(6)) cnt <- mkReg(0);

   rule up_counter;           // 每周期都执行
      cnt <= cnt + 1;         // cnt 从0自增到63
      if(cnt >= 63) $finish;  // 自增到 63 时，仿真结束
   endrule

   rule convert;
      // 把 cnt （二进制编码）转化为 cnt_gray （格雷码）
      Bit#(6) cnt_gray = (cnt >> 1) ^ cnt;

      // 把 cnt_gray （格雷码） 转化回 cnt_bin （二进制编码）
      Bit#(6) cnt_bin = cnt_gray;
      cnt_bin[4] = cnt_gray[4] ^ cnt_bin[5];
      cnt_bin[3] = cnt_gray[3] ^ cnt_bin[4];
      cnt_bin[2] = cnt_gray[2] ^ cnt_bin[3];
      cnt_bin[1] = cnt_gray[1] ^ cnt_bin[2];
      cnt_bin[0] = cnt_gray[0] ^ cnt_bin[1];

      $display("cnt=%b   cnt_gray=%b   cnt_bin=%b", cnt, cnt_gray, cnt_bin );
   endrule

endmodule

endpackage
