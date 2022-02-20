package IncreaseRegCfg_v2;


(* synthesize *)
module mkIncreaseRegCfg ( Tuple2#(Reg#(int), Reg#(int)) );

   Reg#(int) reg_data <- mkReg(0);
   Reg#(int) reg_step <- mkReg(1); 

   (* preempts = "fst._write, increase" *)
   rule increase;
      reg_data <= reg_data + reg_step;
   endrule

   return tuple2(reg_data, reg_step);

endmodule


module mkTb();
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 10) $finish;
   endrule

   match {.inc_reg_data, .inc_reg_step} <- mkIncreaseRegCfg;

   rule update_step (cnt%7 == 0);
      $display("write step<=%3d", inc_reg_step + 1);
      inc_reg_step <= inc_reg_step + 1;
   endrule

   rule update_data (cnt%3 == 0);
      $display("write data<=%3d", 2 * cnt);
      inc_reg_data <= 2 * cnt;
   endrule

   rule show;
      $display("read  data =%3d", inc_reg_data);
   endrule
endmodule

endpackage
