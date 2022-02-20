package IncreaseReg_v1;


interface IncreaseReg;
   method Action write(int x);
   method int read;
endinterface


(* synthesize *)
module mkIncreaseReg (IncreaseReg);

   Reg#(int) reg_data <- mkReg(0);

   (* preempts = "write, increase" *)
   rule increase;
      reg_data <= reg_data + 1;
   endrule

   method write = reg_data._write;
   method read  = reg_data._read;

endmodule


module mkTb();
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 10) $finish;
   endrule

   let inc_reg <- mkIncreaseReg;

   rule update_data (cnt%3 == 0);
      $display("write inc_reg<=%3d", 2 * cnt);
      inc_reg.write(2 * cnt);
   endrule

   rule show;
      $display("read  inc_reg =%3d", inc_reg.read);
   endrule
endmodule

endpackage
