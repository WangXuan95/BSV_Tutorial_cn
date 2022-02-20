package FSMStructures;

import FIFO::*;
import StmtFSM::*;

module mkTb ();

   // 时钟计数器 ------------------------------------
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 100) $finish;
   endrule

   // 两个 Reg
   Reg#(int) regx <- mkReg(1);
   Reg#(int) regy <- mkReg(2);

   // 一个 fifo，每50周期试图 deq 一次 ------------------------------------
   FIFO#(int) fifo <- mkFIFO;
   rule fifo_deq (cnt%50 == 0);
      fifo.deq;
   endrule

   // 子状态机 ---------------------------------------------------------------------
   FSM sfsm <- mkFSM( seq
      $display("  sfsm state (1/3)");
      $display("  sfsm state (2/3)");
      $display("  sfsm state (3/3)");
   endseq );
   
   // 主状态机 ---------------------------------------------------------------------
   FSM mfsm <- mkFSM( seq
      fifo.enq(42);                                   // 试图 enq 直到成功为止，可能占多个周期
      $display("cnt=[%3d]  fifo.enq done", cnt);      // 占1个周期

      sfsm.start;                                     // 试图 sfsm.start ，直到 sfsm 空闲才能跳到下一个周期
      $display("cnt=[%3d]  sfsm started", cnt);       // 占1个周期

      sfsm.waitTillDone;                              // 直到 sfsm 空闲才能跳到下一个周期，可能占多个周期，等效于 await(sfsm.done)
      $display("cnt=[%3d]  sfsm done", cnt);          // 占1个周期

      delay(10);                                      // 占10个周期
      $display("cnt=[%3d]  delay done", cnt);         // 占1个周期

      action                                          // 一个 action 只占一个状态
         regx <= regy;
         regy <= regx;
         $display("cnt=[%3d]  regx=%1d, regy=%1d, exchange", cnt, regx, regy);
      endaction

      action
         fifo.enq(53);                                // 只有在所有状态都满足时，才一并执行 action 中的所有语句
         sfsm.waitTillDone;
         $display("cnt=[%3d]  fifo.enq, sfsm done", cnt);
      endaction

      repeat(2) seq                                   // 顺序结构重复两次
         $display("cnt=[%3d]  repeat", cnt);
         $display("cnt=[%3d]  repeat", cnt);
      endseq
   endseq );

   rule r1;            // 效果：一旦状态机空闲，就启动它 （这样状态机每次运行完就只空闲一个周期）
      mfsm.start;      //   隐式条件：状态机空闲
   endrule
   
endmodule

endpackage