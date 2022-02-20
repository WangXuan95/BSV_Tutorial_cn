package Test3;

import FIFO::*;

module mkTb ();
   Reg#(int) cnt <- mkReg(0);
   Wire#(int) w1 <- mkWire;   // w1 用于构造隐式条件

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt < 2) w1 <= cnt + 1;  // 只有在 cnt<2 时写 w1
      if(cnt > 5) $finish;
   endrule

   Reg#(int) x <- mkReg(1);
   Reg#(int) y <- mkReg(2);

   (* descending_urgency = "y2x, x2y" *)

   rule x2y;     
      y <= x + 1;       // 读 x，写 y
   endrule

   rule y2x;
      x <= y + w1;      // 读 y，写 x ，注意读 w1 是有隐式条件的！
   endrule

   rule show;
      $display("cnt=%1d  x=%1d  y=%1d", cnt, x, y);
   endrule
endmodule

endpackage
