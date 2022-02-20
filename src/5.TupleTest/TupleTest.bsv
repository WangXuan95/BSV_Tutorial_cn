// 目的：测试元组使用方法

package TupleTest;

module mkTb();
   rule test;
      // 元组的基本用法测试 ---------------------------------------------------------------------------------------------------------------
      Tuple2#(Bool, Int#(9)) t2 = tuple2(True, -25);                                                                  // 一个2元组
      Tuple8#(int, Bool, Bool, int, UInt#(3), int, bit, Int#(6)) t8 = tuple8(-3, False, False, 19, 1, 7, 'b1, 45);    // 一个8元组

      Bool v3 = tpl_3(t8);               // 获取 t8 的第三个元素（False）

      match {.va, .vb} = t2;             // 隐式定义了2个变量来承接 t2 的值

      $display("va=%d  vb=%d  v3=%d", va, vb, v3);

      // 把一个 Bit#(13) 变量拆成 Bit#(8) （高位）和一个 Bit#(5) ---------------------------------------------------------------------------
      Bit#(13) b13 = 'b1011100101100;
      Tuple2#(Bit#(8), Bit#(5)) tsplit = split(b13);
      match {.b8, .b5} = tsplit;
      
      $display("%b %b", b8, b5);

      $finish;
   endrule
endmodule

endpackage
