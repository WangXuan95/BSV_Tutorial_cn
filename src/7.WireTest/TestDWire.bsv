package TestDWire;

module mkTb ();
   Reg#(int) cnt <- mkReg(0);

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 3) $finish;
   endrule

   Wire#(int) w1 <- mkDWire(99);  // w1 默认值 = 99
   Reg#(int)  r1 <- mkReg(99);    // r1 初始值 = 99
   
   rule test1 (cnt%2 == 0);     // rule条件：只在能整除2的周期执行
      w1 <= cnt;
   endrule

   rule test2 (cnt%2 == 0);     // rule条件：只在能整除2的周期执行
      r1 <= cnt;
   endrule

   rule show;
      $display("cnt=%2d   w1=%2d   r1=%2d", cnt, w1, r1);
   endrule
endmodule

endpackage
