// Copyright(c) 2022 https://github.com/WangXuan95

package DFIFOF1;

import FIFOF::*;


module mkDFIFOF1#(td default_value) (FIFOF#(td))
   provisos (Bits#(td, sz));

   FIFOF#(td) fifo <- mkUGFIFOF1;

   method td first = fifo.notEmpty ? fifo.first : default_value;

   method Action deq = fifo.deq;

   method Action enq(td value) if(fifo.notFull) = fifo.enq(value);

   method notEmpty = fifo.notEmpty;

   method notFull = fifo.notFull;

   method clear = fifo.clear;

endmodule


endpackage
