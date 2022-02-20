// 功能：SPI写控制器的 testbench
// 目的：演示多文件（多包）项目的组织方式

package TbSPIWriter;   // 包名 TbSPIWriter ，必须与文件名相同

import StmtFSM::*;     // 引入 BSV 标准库 StmtFSM
import SPIWriter::*;   // 引入用户编写的包 SPIWriter （见文件SPIWriter.bsv）


module mkTb ();
   let spi_writer <- mkSPIWriter;

   mkAutoFSM(
      seq
         spi_writer.write(8'h65);   // SPI 发送 0x65
         spi_writer.write(8'h14);   // SPI 发送 0x14
         spi_writer.write(8'h00);
      endseq
   );

   rule spi_show;                   // 每个时钟周期都打印 spi_writer 产生的 SPI 信号
      let spi = spi_writer.spi;
      $display(" (ss, sck, mosi) = (%1d, %1d, %1d)", spi[2], spi[1], spi[0] );
   endrule

endmodule


endpackage
