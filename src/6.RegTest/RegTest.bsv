package RegTest;

import DReg::*;

module mkTb ();
   Reg#(int) cnt <- mkReg(0);

   rule up_counter;            // rule 每时钟周期都会执行一次
      cnt <= cnt + 1;
      if(cnt > 9) $finish;
   endrule

   Reg#(int) reg1 <- mkReg(99);   // reg1 初值 = 99
   Reg#(int) reg2 <- mkDReg(99);  // reg2 默认值 = 99

   rule test (cnt%3 == 0);     // 只在能整除3的周期执行，相当于每3周期执行一次
      reg1 <= -cnt;
      reg2 <= -cnt;
   endrule

   rule show;
      $display("cnt=%2d    reg1=%2d    reg2=%2d", cnt, reg1, reg2);
   endrule
endmodule

endpackage
