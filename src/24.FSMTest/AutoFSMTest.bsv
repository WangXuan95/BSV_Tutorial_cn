package AutoFSMTest;

import StmtFSM::*;

module mkTb ();

   // 行为描述 + 构建状态机
   mkAutoFSM( seq
      $display("state1");  // 语句1：状态1
      $display("state2");  // 语句2：状态2
      $display("state3");  // 语句3：状态3
   endseq );               // 运行完自动运行 $finish
   
endmodule

endpackage