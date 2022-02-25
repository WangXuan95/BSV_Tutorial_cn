// Copyright(c) 2022 https://github.com/WangXuan95

package TbRv32iCPU;

import StmtFSM::*;
import BRAM::*;

import Rv32iCPU::*;


// 模块：CPU testbench
module mkTb ();
   
   String   filename_instruction = "benchmark/qsort_instruction.txt";  // 指定指令流文件, 仿真时 CPU 会运行其中的指令流
   String   filename_data        = "benchmark/no_data.txt";            // 指定数据流文件, 作为数据 RAM 的初始数据
   Bit#(32) print_data_count     = 40;                                 // 在仿真结束前打印数据 RAM 中的前 print_data_count 个数据

   // 把 latency 从 1 修改为 2 来模拟 ibus 和 dbus 的响应停顿
   BRAM1Port#(Bit#(32), Bit#(32))      instr_ram <- mkBRAM1Server  ( BRAM_Configure{memorySize:16384, latency:1, outFIFODepth:3, allowWriteResponseBypass:False, loadFormat: tagged Hex filename_instruction} );
   BRAM2PortBE#(Bit#(32), Bit#(32), 4) data_ram  <- mkBRAM2ServerBE( BRAM_Configure{memorySize:16384, latency:1, outFIFODepth:3, allowWriteResponseBypass:False, loadFormat: tagged Hex filename_data       } );

   let cpu <- mkRv32iCPU;

   Reg#(Bit#(32)) cyc <- mkReg(0);
   Reg#(Bit#(32)) cnt <- mkReg(0);
   Reg#(Bit#(32)) lastpc  <- mkReg('1);

   rule up_cycle;
      cyc <= cyc + 1;
   endrule


   // 主状态机：组织仿真行为
   mkAutoFSM( seq
      cpu.boot(0);

      // 执行指令，在无限跳转到自身时停止
      while ( lastpc != cpu.ibus_req ) seq
         action
            cpu.ibus_reqx;
            instr_ram.portA.request.put( BRAMRequest{write:False, responseOnWrite:False, address: cpu.ibus_req/4, datain: 0} );
            cnt <= cnt + 1;
            lastpc <= cpu.ibus_req;
            //$display("done: cycle=%7d   instructions=%7d   pc/4=%7d", cyc, cnt, cpu.ibus_req/4 );
         endaction
         //delay(1);  // 加入延迟，模拟 ibus 总线请求停顿
      endseq

      delay(9);

      $display("final: cycle=%5d   instructions=%5d   100*cpi=%4d   pc/4=%5d", cyc, cnt, 100*cyc/cnt, lastpc/4 );

      // 打印 Data RAM 中的一些数据
      for ( cnt<=0 ; cnt<print_data_count ; cnt<=cnt+1 ) seq
         data_ram.portB.request.put( BRAMRequestBE{writeen: 'b0000, responseOnWrite: False, address: cnt, datain: 0} );
         action
            Bit#(32) rdata <- data_ram.portB.response.get();
            int rdata_int = unpack(rdata);
            $display("DataRAM[%x] = %d", 4*cnt, rdata_int);
         endaction
      endseq
   endseq );


   // CPU数据总线请求
   rule cpu_dbus_req;// (cyc%2==0);  // 加入条件，模拟 dbus 总线请求停顿
      match { .is_write, .byte_en, .addr, .data } = cpu.dbus_req;
      cpu.dbus_reqx;
      data_ram.portA.request.put( BRAMRequestBE{writeen: byte_en, responseOnWrite: False, address: addr/4, datain: data} );
   endrule


   // CPU指令总线读数据
   rule cpu_ibus_resp;
      Bit#(32) rdata <- instr_ram.portA.response.get();
      cpu.ibus_resp(rdata);
   endrule

   // CPU数据总线读数据
   rule cpu_dbus_resp;
      Bit#(32) rdata <- data_ram.portA.response.get();
      cpu.dbus_resp(rdata);
   endrule

endmodule


endpackage
