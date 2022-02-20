package IncreaseReg_v2;


(* synthesize *)
module mkIncreaseReg (Reg#(int));

   Reg#(int) reg_data <- mkReg(0);

   (* preempts = "_write, increase" *)
   rule increase;
      reg_data <= reg_data + 1;
   endrule

   return reg_data;      // 接口的简短实现：直接把子模块的接口名 value 作为 mkIncreaseReg 的接口返回

endmodule


module mkTb();
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 10) $finish;
   endrule

   Reg#(int) inc_reg <- mkIncreaseReg;

   rule update_data (cnt%3 == 0);
      $display("write inc_reg<=%3d", 2 * cnt);
      inc_reg <= 2 * cnt;
   endrule

   rule show;
      $display("read  inc_reg =%3d", inc_reg);
   endrule
endmodule

endpackage
