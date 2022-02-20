package Test2;

module mkTb ();
   Reg#(int) cnt <- mkReg(0);

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 5) $finish;
   endrule

   Reg#(int) x <- mkReg(1);
   Reg#(int) y <- mkReg(2);

   (* descending_urgency = "y2x, x2y" *)

   rule x2y;     
      y <= x + 1;          // 读 x，写 y
   endrule

   rule y2x (cnt<3);       // 显式条件 cnt<3
      x <= y + 1;          // 读 y，写 x
   endrule

   rule show;
      $display("cnt=%1d  x=%1d  y=%1d", cnt, x, y);
   endrule
endmodule

endpackage
