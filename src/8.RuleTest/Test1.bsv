package Test1;

module mkTb ();

   Reg#(int) x <- mkReg(1);
   Reg#(int) y <- mkReg(2);    // y 是 Reg 时，rule的逻辑执行顺序是： r3 → r2 → r1
   // Wire#(int) y <- mkDWire(2); // 换成 Wire 试试，会发现 rule的逻辑执行顺序变成了： r2 → r3 → r1

   rule r1;               // 读 x，写 x
      $display("r1");
      x <= x + 1;
      if(x >= 2) $finish;
   endrule

   rule r2;               // 读 x，写 y
      $display("r2");
      y <= x;
   endrule

   rule r3;               // 读 x，读 y
      $display("r3   x=%1d  y=%1d", x, y);
   endrule

endmodule

endpackage
