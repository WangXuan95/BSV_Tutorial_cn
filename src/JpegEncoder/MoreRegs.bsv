package MoreRegs;

import DReg::*;


// mkValidReg
// 只有在 _write 后的下一个周期， _read 方法的隐式条件才有效，读出上一周期写入的值。
module mkValidReg ( Reg#(td) )
   provisos( Bits#(td, sz) );

   Reg#(Maybe#(td)) self_reg <- mkDReg(tagged Invalid);

   method Action _write(td wdata);
      self_reg <= tagged Valid wdata;
   endmethod

   method td _read if(isValid(self_reg)) = fromMaybe(unpack('0), self_reg);

endmodule


// mkWireReg
// 调用 _write 写入的数据可以立即在当前周期被 _read 到；在不调用 _write 的周期，则 _read 到上次写入的数据。
// 具有一个初始值 init_data
module mkWireReg#(td init_data) ( Reg#(td) )
   provisos( Bits#(td, sz) );

   RWire#(td) self_rwire <- mkRWire;
   Reg#(td) self_reg <- mkReg(init_data);
   Wire#(td) self_wire <- mkBypassWire;

   rule set_self_wire;
      self_wire <= self_reg;
   endrule
   
   method Action _write(td wdata);
      self_reg <= wdata;
      self_rwire.wset(wdata);
   endmethod

   method td _read = fromMaybe(self_wire, self_rwire.wget);

endmodule



module mkTb();

   Reg#(int) cnt <- mkReg(0);

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 10) $finish;
   endrule

   Reg#(int) valid_reg <- mkValidReg;
   Reg#(int) wire_reg <- mkWireReg(0);

   rule write_reg (cnt%3 == 0);
      valid_reg <= cnt;
      wire_reg <= cnt;
   endrule

   rule read_valid_reg;
      $display("cnt=%2d   valid_reg=%2d", cnt, valid_reg);
   endrule

   rule read_wire_reg;
      $display("cnt=%2d    wire_reg=%2d", cnt, wire_reg);
   endrule

endmodule


endpackage
