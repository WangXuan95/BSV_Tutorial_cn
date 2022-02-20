// usage of mutually_exclusive

package MutuallyExclusive;

module mkTb ();
   Reg#(Bit#(32)) cnt <- mkReg(1);

   rule up_counter;
      cnt <= cnt << 1;
      if(cnt > 10) $finish;
   endrule

   Reg#(int) x <- mkReg(1);

   // 用 mutually_exclusive 告诉编译器 test1 和 test2 互斥
   (* mutually_exclusive = "test1, test2" *)

   // test1 和 test2 实际上是互斥的，但编译器分析不出来
   rule test1 (cnt[1] == 1);     
      x <= x + 1;
   endrule

   rule test2 (cnt[2] == 1);
      x <= x - 1;
   endrule

   rule show;
      $display("x=%1d", x);
   endrule
endmodule

endpackage
