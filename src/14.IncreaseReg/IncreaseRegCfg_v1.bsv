package IncreaseRegCfg_v1;


interface IncreaseRegCfg;
   interface Reg#(int) data;
   interface Reg#(int) step;
endinterface


(* synthesize *)
module mkIncreaseRegCfg (IncreaseRegCfg);

   Reg#(int) reg_data <- mkReg(0);
   Reg#(int) reg_step <- mkReg(1); 

   (* preempts = "data._write, increase" *)
   rule increase;
      reg_data <= reg_data + reg_step;
   endrule

   interface data = reg_data;
   interface step = reg_step;

endmodule


module mkTb();
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 10) $finish;
   endrule

   let inc_reg <- mkIncreaseRegCfg;

   rule update_step (cnt%7 == 0);
      $display("write step<=%3d", inc_reg.step + 1);
      inc_reg.step <= inc_reg.step + 1;
   endrule

   rule update_data (cnt%3 == 0);
      $display("write data<=%3d", 2 * cnt);
      inc_reg.data <= 2 * cnt;
   endrule

   rule show;
      $display("read  data =%3d", inc_reg.data);
   endrule
endmodule

endpackage
