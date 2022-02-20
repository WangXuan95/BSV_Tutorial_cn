// usage of conflict_free

package ConflictFree;

module mkTb ();
   Reg#(int) cnt <- mkReg(0);

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 5) $finish;
   endrule

   Reg#(int) x <- mkReg(1);
   Reg#(int) y <- mkReg(0);
   Reg#(int) z <- mkReg(0);

   // A. 先试试不加任何属性
   //(* mutually_exclusive = "test1, test2" *)  // B.再试试 mutually_exclusive ，发现会报运行时 Warning，因为 test1 和 test2 会同时执行
   (* conflict_free = "test1, test2" *)       // C.最后试试 conflict_free ，发现运行时不会报 Warning 了

   // test1 和 test2 能同时激活，但它们中会引起冲突的语句 x<=x+1 和 x<=x-1 不会同时执行，因为 if 语句。

   rule test1;
      y <= y + 1;      // 无关语句
      if(cnt < 3)
         x <= x + 1;   // 产生冲突的语句
   endrule

   rule test2;
      z <= z + 2;      // 无关语句
      if(cnt > 3)
         x <= x - 1;   // 产生冲突的语句
   endrule

   rule show;
      $display("x=%1d  y=%1d  z=%1d", x, y, z);
   endrule
endmodule

endpackage
