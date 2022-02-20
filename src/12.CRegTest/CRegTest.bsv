package CRegTest;

module mkTb ();
   Reg#(int) cnt <- mkReg(23);       // 计数器 cnt 从 23 到 32

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 32) $finish;
   endrule
   
   Reg#(int) creg [3] <- mkCReg(3, 0);

   rule rule_test5 (cnt%5 == 0);     // 每5周期执行一次
      creg[0] <= creg[0] + 1;        // 优先级最高
   endrule

   rule rule_test3 (cnt%3 == 0);     // 每3周期执行一次
      creg[1] <= creg[1] + 1;        // 优先级第二
   endrule

   rule rule_test2 (cnt%2 == 0);     // 每2周期执行一次
      creg[2] <= creg[2] + 1;        // 优先级最低
   endrule

   rule show;
      $display("cnt=%2d    creg0=%2d", cnt, creg[0]);
   endrule
endmodule

endpackage
