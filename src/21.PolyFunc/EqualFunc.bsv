package EqualFunc;


// 参数：两个相同类型的变量
// 返回：它们是否相等
function Bool equal( td i, td j )
   provisos( Eq#(td) );   // 派生要求：要求 td 派生自 Eq 。 provisos 本身构成了函数定义的一部分，不能省略
   return (i == j);
endfunction


// 参数：两个变量（类型相同或不同，但位宽必须相同）
// 返回：它们在位编码层面是否相同
function Bool bit_equal( td1 i, td2 j )
   provisos(
      Bits#(td1, sz1),             // 要求 td1 派生自 Bits 类型类，获取其位宽为 sz1
      Bits#(td2, sz2),             // 要求 td2 派生自 Bits 类型类，获取其位宽为 sz2
      Add#(sz1, 0, sz2)            // 要求 sz1+0=sz2 ，即 sz1==sz2
   );
   return pack(i) == pack(j);
endfunction


// 参数：两个变量（类型相同或不同，位宽相同或不同）
// 返回：它们在位编码层面（进行位扩展后）是否相同
function Bool bit_ext_equal( td1 i, td2 j )
   provisos(
      Bits#(td1, sz1),             // 要求 td1 派生自 Bits 类型类，获取其位宽为 sz1
      Bits#(td2, sz2)              // 要求 td2 派生自 Bits 类型类，获取其位宽为 sz2
   );
   Bit#(TMax#(sz1,sz2)) bi = extend(pack(i));
   Bit#(TMax#(sz1,sz2)) bj = extend(pack(j));
   return bi == bj;
endfunction


// 参数：两个变量（类型相同或不同，位宽相同或不同）
// 返回：它们在位编码层面（进行位扩展后）是否相同
function Bool bit_ext_equal_v2( td1 i, td2 j )
   provisos(
      Bits#(td1, sz1),             // 要求 td1 派生自 Bits 类型类，获取其位宽为 sz1
      Bits#(td2, sz2)              // 要求 td2 派生自 Bits 类型类，获取其位宽为 sz2
   );
   Bit#(TMax#(SizeOf#(td1), SizeOf#(td2))) bi = extend(pack(i));
   Bit#(TMax#(SizeOf#(td1), SizeOf#(td2))) bj = extend(pack(j));
   return bi == bj;
endfunction



module mkTb ();
   rule test;
      UInt#(20) a = 'h0ffff;
      Int#(16)  b = -1;

      Bool eq = bit_ext_equal_v2(a, b);

      $display("%b", eq);

      $finish;
   endrule
endmodule


endpackage
