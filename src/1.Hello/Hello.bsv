// 功能：Hello World
// 目的：演示单模块项目组织方式

package Hello;       // 包名: Hello。每个.bsv文件内只能有1个同名包

module mkTb();       // 模块名: mkTb
   rule hello;                   // rule 名: hello
      $display("Hello World!");  // 就像 Verilog 的 $display 那样，
                                 // 该语句不参与综合, 只是在仿真时打印
      $finish;                   // 仿真程序退出
   endrule
endmodule

endpackage
