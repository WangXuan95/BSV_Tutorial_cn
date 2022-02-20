// 功能：十进制计数器
// 目的：演示多模块项目的组织方式

package DecCounter;

interface DecCounter;                          // 模块 mkDecCounter 的接口，用于连接调用者和被调用者
   method UInt#(4) count;                      //    方法1：可被被调用者调用
   method Bool overflow;                       //    方法2：可被被调用者调用
endinterface


(* synthesize *)                               // 注释掉这行，则生成 Verilog 时不单独生成 mkDecCounter 模块，而是嵌入调用者代码体内。
module mkDecCounter (DecCounter);              // 模块名 mkDecCounter，被调用者，接口是DecCounter

   Reg#(UInt#(4)) cnt <- mkReg(0);             // 4bit 的计数变量（寄存器，或称为 D触发器）
   Bool oflow = cnt >= 9;                      // 判断 cnt 是否溢出，是组合逻辑

   rule run_counter;
      cnt <= oflow ? 0 : cnt + 1;
   endrule

   method UInt#(4) count = cnt;                // 必须实现方法1，这里直接返回 cnt 的值
   method Bool overflow = oflow;               // 必须实现方法2，这里直接返回 oflow 的值
endmodule


module mkTb ();                                // 模块名 mkTb ，调用者
   DecCounter counter <- mkDecCounter;         // 例化一个 mkDecCounter，并拿到它的接口
                                               // 该接口是 DecCounter 类型的， 命名为 counter

   rule test;
      $display("count=%d",  counter.count );   // 通过接口名 counter 来调用子模块，这里调用了 count 方法
      if( counter.overflow )                   // 通过接口名 counter 来调用子模块，这里调用了 overflow 方法
         $finish;
   endrule
endmodule

endpackage
