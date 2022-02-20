package Test1;

module mkTb ();

   Reg#(Bit#(32)) cnt <- mkReg(0);

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 8) $finish;
   endrule

   Reg#(int) x <- mkReg(0);
   Reg#(int) y <- mkReg(0);
   Reg#(int) z <- mkReg(0);

   // divide3, divide2, other 并不冲突，但强制给它们加上冲突：
   // 当 divide3 激活或 divide2 激活（或者都激活）时，other 不能激活
   (* preempts = "(divide3, divide2), other" *)

   rule divide3 (cnt%3 == 0);
      x <= x + 1;
   endrule

   rule divide2 (cnt%2 == 0);
      y <= y + 1;
   endrule

   rule other;
      z <= z + 1;
   endrule

   rule show;
      $display("cnt=%1d  x=%1d  y=%1d  z=%1d", cnt, x, y, z);
   endrule
   
endmodule

endpackage
