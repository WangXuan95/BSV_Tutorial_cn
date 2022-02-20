package FSMStructures2;

import FIFO::*;
import StmtFSM::*;

module mkTb ();

   // 时钟计数器 ------------------------------------
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 100) $finish;
   endrule

   // 一个 fifo，每50周期试图 deq 一次 ------------------------------------
   FIFO#(int) fifo <- mkFIFO;
   rule fifo_deq (cnt%50 == 0);
      fifo.deq;
   endrule

   // 主状态机 ---------------------------------------------------------------------
   FSM mfsm <- mkFSM( seq
      par
         seq                                                     // 线程1
            delay(10);
            $display("cnt=[%3d]  thread1: sfsm done", cnt);
         endseq

         action                                                  // 线程2
            fifo.enq(53);
            $display("cnt=[%3d]  thread2: fifo.enq done", cnt);
         endaction

         $display("cnt=[%3d]  thread3: par start", cnt);         // 线程3
      endpar                                                     // 所有线程结束，整个 par...endpar 才结束

      $display("cnt=[%3d]  endpar", cnt);

   endseq );

   rule r1;            // 效果：一旦状态机空闲，就启动它 （这样状态机每次运行完就只空闲一个周期）
      mfsm.start;      //   隐式条件：状态机空闲
   endrule
   
endmodule

endpackage