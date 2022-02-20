package FSMTest;

import StmtFSM::*;

module mkTb ();

   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 20) $finish;
   endrule
   
   // 行为描述 + 构建状态机
   FSM testFSM <- mkFSM(
   seq
      $display("state1");  // 语句1：状态1
      $display("state2");  // 语句2：状态2
      $display("state3");  // 语句3：状态3
   endseq );

   rule r1;            // 效果：一旦状态机空闲，就启动它 （这样状态机每次运行完就只空闲一个周期）
      testFSM.start;   //   隐式条件：状态机空闲
   endrule

   rule r2 (testFSM.done);
      // 在状态机空闲时干一些事情
      $display("r1: FSM IDLE, cnt=%d", cnt);
   endrule

   rule r3;
      testFSM.waitTillDone;   //   隐式条件：状态机空闲
      // 也可以这样在状态机空闲时干一些事情
      $display("r2: FSM IDLE, cnt=%d", cnt);
   endrule
   
endmodule

endpackage