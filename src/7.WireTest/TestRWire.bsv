package TestRWire;

module mkTb ();
   Reg#(int) cnt <- mkReg(1);

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 5) $finish;
   endrule

   RWire#(int) w1 <- mkRWire;
   PulseWire w2 <- mkPulseWire;
   
   rule test1 (cnt%2 == 0);     // rule条件：只在能整除2的周期执行
      w1.wset(cnt);
   endrule

   rule test2 (cnt%3 == 0);     // rule条件：只在能整除3的周期执行
      w2.send;
   endrule

   rule show;
      Bool w1_v = isValid(w1.wget);       // w1.wget 得到的是 Maybe#(int) 类型，用 isValid 函数获取是否有效
      int  w1_d  = fromMaybe(0, w1.wget); // w1.wget 得到的是 Maybe#(int) 类型，用 fromMaybe 函数获取数据
      Bool w2_v = w2;                     // 直接用 w2 的名称获取它是否有效
      $display("cnt=%1d   w1_v=%1d   w1_d=%1d   w2_v=%1d", cnt, w1_v, w1_d, w2_v);
   endrule
endmodule

endpackage
