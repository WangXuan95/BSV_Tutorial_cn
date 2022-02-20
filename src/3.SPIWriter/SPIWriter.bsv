// 功能：SPI写控制器

package SPIWriter;    // 包名 SPIWriter ，必须与文件名相同

import StmtFSM::*;


interface SPIWriter;
   method Action write(Bit#(8) data);
   method Bit#(3) spi;
endinterface


(* synthesize, always_ready="spi" *)
module mkSPIWriter (SPIWriter);        // BSV SPI 发送（可综合）， 模块名称为 mkSPIWriter
   Reg#(bit) ss <- mkReg(1'b1);
   Reg#(bit) sck <- mkReg(1'b1);
   Reg#(bit) mosi <- mkReg(1'b1);
   Reg#(Bit#(8)) wdata <- mkReg(8'h0);
   Reg#(int) cnt <- mkReg(7);          // cnt 的复位值为 7

   FSM spiFsm <- mkFSM (               // mkFSM 是一个状态机自动生成器，能根据顺序模型生成状态机 spiFsm
      seq                              // seq...endseq 描述一个顺序模型，其中的每个语句占用1个时钟周期
         ss <= 1'b0;                   // ss 拉低
         while (cnt>=0) seq            // while 循环，cnt 从 7 递减到 0，共8次
            action                     // action...endaction 内的语句在同一周期内执行，即原子操作。
               sck <= 1'b0;            // sck 拉低
               mosi <= wdata[cnt];     // mosi 依次产生串行 bit
            endaction
            action                     // action...endaction 内的语句在同一周期内执行，即原子操作。
               sck <= 1'b1;            // sck 拉高
               cnt <= cnt - 1;         // cnt 每次循环都递减
            endaction
         endseq
         mosi <= 1'b1;                 // mosi 拉高
         ss <= 1'b1;                   // ss 拉高，发送结束
         cnt <= 7;                     // cnt 置为 7，保证下次 while 循环仍然正常循环 8 次
      endseq );                        // 顺序模型结束

   method Action write(Bit#(8) data);  // 当外部需要发送 SPI 时，调用此 method。参数 data 是待发送的字节
      wdata <= data;
      spiFsm.start();                  // 试图启动状态机 spiFsm
   endmethod

   method Bit#(3) spi = {ss,sck,mosi}; // 该 method 用于将 SPI 信号引出到模块外部
endmodule


endpackage
