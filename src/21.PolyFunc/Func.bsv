package Func;


import Vector::*;


// 参数：Vector 类型的变量
// 返回：返回 Vector 的长度
function Integer vectorLen(Vector#(n, td) vec) = valueOf(n);


// 功能：把寄存器向量中的数据取出来，组成新的数据向量返回
// 参数：Vector#(n, Reg#(td)) 寄存器向量
// 返回：Vector#(n, td)
function Vector#(n, td) regVector2Vector( Vector#(n, Reg#(td)) reg_vec )
   provisos( Bits#(td, sz) );
   Vector#(n, td) vec;
   for(Integer i=0; i<valueOf(n); i=i+1)
      vec[i] = reg_vec[i]._read;
   return vec;
endfunction


// 参数：两个相同类型的变量，必须派生自 Arith
// 返回：返回它们的平方和
function td squareSum2(td a, td b)
   provisos( Arith#(td) );
   return a*a + b*b;
endfunction


// 参数：Bit#(n) data
// 返回：返回它最高位的1的下标。
// 举例：data=8'b00100101 时，返回 3'd5
function UInt#(k) highestOnePosition(Bit#(n) data)
   provisos( Log#(n, k) );                          // 要求返回值的位宽和输入数据的位宽有 Log#() 的约束
   UInt#(k) pos = 0;
   for(Integer i = 0; i < valueOf(n); i=i+1)        // 从 0 到 n-1 （data的最高位下标）
      if( data[i] == 1 )
         pos = fromInteger(i);
   return pos;
endfunction


// 参数：Vector类型，长度任意，元素类型任意（但必须派生自 Arith ）
// 返回：Vector 求和
function td vectorSum(Vector#(len, td) vec)
   provisos( Arith#(td) );
   td sum = 0;
   for(Integer i=0; i<valueOf(len); i=i+1)
      sum = sum + vec[i];
   return sum;
endfunction


// 参数：Vector类型，长度任意，元素类型任意（但必须派生自 Arith ）
// 返回：Vector 求和（无符号数），但扩展返回值的位宽，让它不可能溢出。
function td2 vectorSumAutoExtend(Vector#(len, td1) vec)
   provisos(
      Arith#(td2),
      Bits#(td1, sz1),
      Bits#(td2, sz2),
      Add#(sz1, TLog#(len), sz2)
   );
   td2 sum = 0;
   for(Integer i=0; i<valueOf(len); i=i+1)
      sum = sum + unpack(extend(pack(vec[i])));
   return sum;
endfunction




module mkTb();

   /* // ------------------------- highestOnePosition 使用例 -------------------------
   Reg#(Bit#(16)) cnt <- mkReg(0);
   rule test;
      let pos = highestOnePosition(cnt);          // 根据 highestOnePosition 的 provisos 知道 pos 是 UInt(4)
      //UInt#(4) pos = highestOnePosition(cnt);   // 这样也可以，但用户还要手动推断要用 UInt(4) ，不如 let 方便
      $display("cnt=%b    highestOnePosition(cnt)=%d", cnt, pos);
      cnt <= cnt + 1;
      if(cnt > 20) $finish;
   endrule
   */

   // ------------------------- vectorSumAutoExtend 使用例 -------------------------
   rule test;
      Vector#(7, UInt#(32)) vec1 = replicate(0);
      vec1[1] = 2;
      vec1[6] = 4;
      vec1[5] = 1;
      UInt#(35) sum = vectorSumAutoExtend(vec1);
      $display("sum(vec1)=%d", sum );
      $finish;
   endrule

endmodule


endpackage
