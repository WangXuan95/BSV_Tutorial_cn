package FSMIfWhileFor;

import FIFO::*;
import StmtFSM::*;

module mkTb ();

   // 时钟计数器 ------------------------------------
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 20) $finish;
   endrule

   Reg#(int) regx <- mkReg(0);

   // 主状态机 ---------------------------------------------------------------------
   FSM mfsm <- mkFSM( seq

      if(cnt%3 == 0) seq
         $display("cnt=[%3d]  taken if      (1/1)", cnt);
      endseq else if(cnt%3 == 1) seq
         $display("cnt=[%3d]  taken else if (1/2)", cnt);
         $display("cnt=[%3d]                (2/2)", cnt);
      endseq else seq
         $display("cnt=[%3d]  taken else    (1/4)", cnt);
         $display("cnt=[%3d]                (2/4)", cnt);
         $display("cnt=[%3d]                (3/4)", cnt);
         $display("cnt=[%3d]                (4/4)", cnt);
      endseq

      $display("cnt=[%3d]  start while", cnt);
      while(cnt % 5 != 0) seq
         $display("cnt=[%3d]  while ...", cnt);
      endseq
      $display("cnt=[%3d]  end while", cnt);

      for(regx <= 0; regx < cnt; regx <= regx + 10) seq
         $display("cnt=[%3d]  for", cnt);
      endseq

   endseq );

   rule r1;            // 效果：一旦状态机空闲，就启动它 （这样状态机每次运行完就只空闲一个周期）
      mfsm.start;      //   隐式条件：状态机空闲
   endrule
   
endmodule

endpackage