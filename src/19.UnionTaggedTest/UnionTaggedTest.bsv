package UnionTaggedTest;

// ----------------------------- 定义 union tagged -----------------------------
typedef union tagged {
   void None;            // 要么取无效
   UInt#(16) Alpha;      // 要么取黑白 16 bit
   struct {              // 要么取彩色 RGB565
      UInt#(8) r;
      UInt#(8) g;
      UInt#(8) b;
   } RGB;
} Pixel deriving (Bits, Eq);


module mkTb();

    rule test;

        Pixel pixel1 = tagged None;
        Pixel pixel2 = tagged Alpha 100;
        Pixel pixel3 = tagged RGB {r:6, g:2, b:9};

        Pixel pixel = pixel1;


        if         ( pixel matches tagged Alpha .alpha )
            $display("%d", alpha);
        else if( pixel matches tagged RGB .rgb )
            $display("%d %d %d", rgb.r, rgb.g, rgb.b);
        else if( pixel matches tagged None )
            $display("no pixel");
        

        case (pixel) matches
            tagged Alpha .alpha : $display("%d", alpha);
            tagged RGB .rgb     : $display("%d %d %d", rgb.r, rgb.g, rgb.b);
            tagged None         : $display("no pixel");
        endcase

        $finish;
    endrule

endmodule

endpackage
