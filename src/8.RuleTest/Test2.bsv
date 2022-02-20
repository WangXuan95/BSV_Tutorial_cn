package Test2;

module mkTb ();

   Reg#(int) cnt <- mkReg(0);

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 5) $finish;
   endrule

   Reg#(int) x <- mkReg(1);
   Reg#(int) y <- mkReg(2);

   // 试图每周期都交换 x 和 y （但并不能达到效果！）
   rule x2y;               // 读 x，写 y
      y <= x;
   endrule

   rule y2x;               // 读 y，写 x
      x <= y;
   endrule

   rule show;
      $display("x=%1d  y=%1d", x, y);
   endrule

endmodule

endpackage
