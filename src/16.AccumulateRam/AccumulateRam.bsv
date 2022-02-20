package AccumulateRam;

import FIFO::*;
import BRAM::*;


interface AccumulateRam;
   method Action put(Bool is_acc, UInt#(12) addr, int data);   // is_acc: False(普通写入), True(累加式写入)    addr: 地址     data: 写入值
   method ActionValue#(Tuple3#(Bool, UInt#(12), int)) get;      // 返回值: 上次写入的信息，   Bool: 写入还是累加式写入?    UInt#(12): 地址    int: 写入值或累加后的值
endinterface


// 一个支持普通写入和累加式写入的 RAM
// 普通写入  ：指定地址写入输入数据。
// 累加式写入：指定地址，读出数据，加上输入数据，再写回。
module mkAccumulateRam( AccumulateRam );

   BRAM2Port#(UInt#(12), int) ram <- mkBRAM2Server(defaultValue);

   FIFO#(Tuple3#(Bool, UInt#(12), int)) fifo1 <- mkFIFO;
   FIFO#(Tuple3#(Bool, UInt#(12), int)) fifo2 <- mkFIFO;
   FIFO#(Tuple3#(Bool, UInt#(12), int)) fifo3 <- mkFIFO;
   FIFO#(Tuple3#(Bool, UInt#(12), int)) fifo4 <- mkLFIFO;

   Wire#(Maybe#(int)) data_from4 <- mkDWire(tagged Invalid);
   Wire#(Maybe#(int)) data_from3 <- mkDWire(tagged Invalid);

   rule stage1;
      match {.is_acc, .addr, .data} = fifo1.first;
      ram.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: addr, datain: 0 });
      fifo1.deq;
      fifo2.enq( fifo1.first );
   endrule

   rule stage2;
      match {.is_acc, .addr, .data} = fifo2.first;
      int rdata <- ram.portA.response.get();
      if( is_acc )
         data = data + fromMaybe(fromMaybe(rdata, data_from4), data_from3);
      fifo2.deq;
      fifo3.enq( tuple3(is_acc, addr, data) );
   endrule

   rule stage3;
      match {.is_acc, .addr, .data} = fifo3.first;
      ram.portB.request.put(BRAMRequest{write: True, responseOnWrite: False, address: addr, datain: data });
      fifo3.deq;
      fifo4.enq( fifo3.first );
   endrule

   rule stage3_forward;
      match {.is_acc, .addr, .data} = fifo3.first;
      if( tpl_2(fifo2.first) == addr ) data_from3 <= tagged Valid data;
   endrule

   rule stage4_forward;
      match {.is_acc, .addr, .data} = fifo4.first;
      if( tpl_2(fifo2.first) == addr ) data_from4 <= tagged Valid data;
   endrule

   method Action put(Bool is_acc, UInt#(12) addr, int data);
      fifo1.enq( tuple3(is_acc, addr, data) );
   endmethod

   method ActionValue#(Tuple3#(Bool, UInt#(12), int)) get;
      fifo4.deq;
      return fifo4.first;
   endmethod

endmodule


module mkTb();
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 100) $finish;
   endrule

   UInt#(12) addr_list [16] = {3, 6, 7, 0, 7, 3, 3, 2, 3, 6, 7, 7, 7, 7, 7, 7};

   Reg#(UInt#(4)) icnt <- mkReg(0);

   let acc_ram <- mkAccumulateRam;

   rule acc_ram_input;
      acc_ram.put(True, addr_list[icnt], 1);
      icnt <= icnt + 1;
   endrule

   rule acc_ram_output (cnt%3==0);
      match {.is_acc, .addr, .nedata} <- acc_ram.get;
      $display("cnt=%3d    idx=%d    acc=%4d", cnt, addr, nedata+1431655766);
   endrule

endmodule


endpackage