package CaseTest;


module mkTb();

    rule test;

        // ----------------------------- 测试 case 语句 -----------------------------
        Bit#(4) x = 'b1110;
        int y;

        case(x)
            'b0000   : y = -87;
            'b0001   : y = -87;
            'b0100   : y = 42;
            'b0110   : y = 42;
            'b1110   : y = 1;
            default  : y = 0;
        endcase

        $display("%d", y);


        // ----------------------------- 测试 case 表达式 -----------------------------
        y = case(x)
            'b0000   : return -87;
            'b0001   : return -87;
            'b0100   : return 42;
            'b0110   : return 42;
            'b1110   : return 1;
            default  : return 0;
        endcase;

        $display("%d", y);


        // ----------------------------- 测试 case matches 表达式（模糊匹配） -----------------------------
        y = case(x) matches
            'b000?   : return -87;
            'b01?0   : return 42;
            'b1110   : return 1;
            default  : return 0;
        endcase;

        $display("%d", y);

        $finish;
    endrule

endmodule

endpackage
