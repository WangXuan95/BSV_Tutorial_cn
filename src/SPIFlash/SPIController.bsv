// Copyright(c) 2022 https://github.com/WangXuan95

package SPIController;

import StmtFSM::*;


interface SPIController;
   method Action   write(Bit#(8) data);
   method Bit#(8)  read;
   method bit      sck_o;
   method bit      mosi_o;
   method Action   miso_i(bit i);
endinterface


(* synthesize *)
(* always_ready = "sck_o, mosi_o" *)
(* always_enabled = "miso_i" *)
module mkSPIController (SPIController);
   Reg#(bit)     sck    <- mkReg(0);
   Reg#(bit)     mosi   <- mkReg(0);
   Wire#(bit)    miso_w <- mkBypassWire;
   Reg#(Bit#(8)) wdata  <- mkReg(0);
   Reg#(Bit#(8)) rdata  <- mkReg(0);
   Reg#(int)     cnt    <- mkReg(7);

   FSM spiFsm <- mkFSM (
      seq
         while (cnt>=0) seq
            action
               sck <= 1'b0;
               mosi <= wdata[cnt];
            endaction
            action
               sck <= 1'b1;
               rdata[cnt] <= miso_w;
               cnt <= cnt - 1;
            endaction
         endseq
         action
            sck <= 1'b0;
            mosi <= 1'b0;
         endaction
         cnt <= 7;
      endseq
   );

   method Action write(Bit#(8) data);
      wdata <= data;
      spiFsm.start();
   endmethod

   method Bit#(8) read if(spiFsm.done) = rdata;

   // SPI bus connections
   method sck_o  = sck._read;
   method mosi_o = mosi._read;
   method miso_i = miso_w._write;

endmodule


endpackage
