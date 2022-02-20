
package EnumTest;

//typedef enum {Green, Yellow, Red} Light deriving (Eq, Bits);          // Green=0, Yellow=1, Red=2
//typedef enum {Green, Yellow=5, Red} Light deriving(Eq, Bits);         // Green=0, Yellow=5, Red=6
typedef enum {Green=125, Yellow=20, Red=85} Light deriving(Eq, Bits);   // Green=125, Yellow=20, Red=85

module mkTb();
   rule test;
      Light va = Green;
      $display("Green = %b", va);
      va = Yellow;
      $display("Yellow = %b", va);
      va = Red;
      $display("Red = %b", va);

      // 查看把 unpack(0) 赋值给 va 会怎样
      va = unpack(0);
      $display("unpack(0) = %b", va);

      $finish;
   endrule
endmodule

endpackage
