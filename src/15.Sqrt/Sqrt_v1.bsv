// 16级迭代流水线，实现 UInt#(32) 的开方运算

package Sqrt_v1;

import DReg::*;


module mkTb();

   // ----- sqrt 实现 --------------------------------------------------------------------------------------------------------------------------

   // 进行单次迭代的函数（组合逻辑电路），该函数会被部署 16 次，分别在流水线的 16 个级
   function Tuple2#(UInt#(32), UInt#(32)) sqrtIteration( Tuple2#(UInt#(32), UInt#(32)) data, int n );
      match {.x, .y} = data;
      let t = (y<<1<<n) + (1<<n<<n);
      if(x >= t) begin
         x = x - t;
         y = y + (1<<n);
      end
      return tuple2(x, y);
   endfunction
   
   // 17 个 DReg，用于传递流水线各级的中间结果（也叫流水线段寄存器 Stage Register）
   Reg#( Tuple2#(UInt#(32), UInt#(32)) ) dregs [17];

   // 实例化这 17 个 DReg
   for(int n=16; n>=0; n=n-1)
      dregs[n] <- mkDReg( tuple2(0, 0) );

   // 放置 16 个 rule ，每个都部署一个 sqrtIteration 函数，实现了各级流水线的计算
   for(int n=15; n>=0; n=n-1)
      rule pipe_stages;
         dregs[n] <= sqrtIteration( dregs[n+1] , n );
      endrule
   

   // ----- sqrt 测试 --------------------------------------------------------------------------------------------------------------------------

   Reg#(UInt#(32)) cnt <- mkReg(1);

   rule sqrter_input;
      UInt#(32) x = cnt * 10000000;                             // x 是待开方的数据
      dregs[16] <= tuple2(x, 0);                                // 把 x=x, y=0 写入最前级流水段寄存器
      $display("input:%d      output:%d", x, tpl_2(dregs[0]));  // 从流水线最末级寄存器拿出数据
      cnt <= cnt + 1;
      if(cnt > 40) $finish;
   endrule

endmodule


endpackage