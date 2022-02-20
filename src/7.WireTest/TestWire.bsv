package TestWire;

module mkTb ();
   Reg#(int) cnt <- mkReg(1);

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 7) $finish;
   endrule

   Wire#(int) w1 <- mkWire;
   Wire#(int) w2 <- mkWire;
   
   rule test1 (cnt%2 == 0);     // rule条件：只在能整除2的周期执行
      $display("cnt=%1d  test1", cnt);
      w1 <= cnt;
   endrule

   rule test2 (cnt%3 == 0);     // rule条件：只在能整除3的周期执行
      $display("cnt=%1d  test2", cnt);
      w2 <= cnt;
   endrule

   rule show;
      $display("cnt=%1d   w1=%2d   w2=%2d", cnt, w1, w2);
   endrule
endmodule

endpackage
