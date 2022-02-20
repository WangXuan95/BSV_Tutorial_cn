package Test2;

module mkTb ();

   Reg#(Bit#(32)) cnt <- mkReg(0);

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 8) $finish;
   endrule

   Reg#(int) x <- mkReg(0);
   Reg#(int) z <- mkReg(0);

   // divide3 与 divide2 冲突，但 divide3 与 other ； divide2 与 other 都不冲突
   (* descending_urgency = "divide3, divide2" *)
   (* preempts = "divide2, other" *)

   rule divide3 (cnt%3 == 0);
      x <= x + 1;
   endrule

   rule divide2 (cnt%2 == 0);
      x <= x + 1;
   endrule

   rule other;
      z <= z + 1;
   endrule

   rule show;
      $display("cnt=%1d  x=%1d  z=%1d", cnt, x, z);
   endrule
   
endmodule

endpackage
