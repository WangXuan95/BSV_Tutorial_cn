// Copyright(c) 2022 https://github.com/WangXuan95

package Rv32iCPU;

import FIFOF::*;
import SpecialFIFOs::*;
import BRAM::*;

// 枚举：指令码 OPCODE
typedef enum { AUIPC   = 7'b0010111,   // U_TYPE    rdst=pc+imm
               LUI     = 7'b0110111,   // U_TYPE    rdst=imm;
               JAL     = 7'b1101111,   // J_TYPE    rdst=pc+4,        pc= pc+imm,
               JALR    = 7'b1100111,   // I_TYPE    rdst=pc+4,        pc= rsrc1+imm
               BRANCH  = 7'b1100011,   // B_TYPE    conditional jump, pc= pc+imm,
               ALI     = 7'b0010011,   // I_TYPE    arithmetic&logical, rdst = alu(rsrc1, imm)
               ALR     = 7'b0110011,   // R_TYPE    arithmetic&logical, rdst = alu(rsrc1, rsrc2)
               LOAD    = 7'b0000011,   // I_TYPE    load, rdst=mem_load
               STORE   = 7'b0100011,   // S_TYPE    store
               UNKNOWN = 7'b0
} OpCode deriving(Bits, Eq);

// 结构体：寄存器有效、地址、数据
typedef struct {
   Bool      e;
   UInt#(5)  a;
   UInt#(32) d;
} RegItem deriving(Bits);

// 结构体：指令解码和执行结果
typedef struct {        //struction of Decoded Instrunction item, named InstrItem.
   UInt#(32) pc;        // fill at IF stage
   OpCode    opcode;    // fill at ID stage
   RegItem   rsrc1;     // fill at ID stage
   RegItem   rsrc2;     // fill at ID stage
   RegItem   rdst;      // rdst.e , rdst.a  fill at ID stage. rdst.d  fill at EX stage
   Bit#(7)   funct7;    // fill at ID stage
   Bit#(3)   funct3;    // fill at ID stage
   Bool      store;     // fill at ID stage
   Bool      load;      // fill at ID stage
   UInt#(32) immu;      // fill at ID stage
} InstrItem deriving(Bits);


// 函数：指令解码
// 用在 ID阶段
function InstrItem decode(Bit#(32) instr);
   InstrItem item = unpack('0);

   item.funct7 = instr[31:25];
   item.rsrc2.a = unpack(instr[24:20]);
   item.rsrc1.a = unpack(instr[19:15]);
   item.funct3 = instr[14:12];
   item.rdst.a = unpack(instr[11:7]);
   item.opcode = unpack(instr[6:0]);

   item.store   = item.opcode == STORE;
   item.load    = item.rdst.a != 0 &&  item.opcode == LOAD;
   item.rdst.e  = item.rdst.a != 0 && (item.opcode == LOAD || item.opcode == JAL || item.opcode == JALR || item.opcode == LUI || item.opcode == AUIPC || item.opcode == ALI || item.opcode == ALR );
   item.rsrc2.e = item.opcode == ALR || item.opcode == STORE || item.opcode == BRANCH;
   item.rsrc1.e = item.opcode == ALI || item.opcode == LOAD  || item.opcode == JALR || item.rsrc2.e;

   int imms = case(item.opcode)
      AUIPC  : return unpack({instr[31:12], 12'h0});                                             // U_TYPE
      LUI    : return unpack({instr[31:12], 12'h0});                                             // U_TYPE
      ALI    : return extend(unpack(instr[31:20]));                                              // I_TYPE
      LOAD   : return extend(unpack(instr[31:20]));                                              // I_TYPE
      JALR   : return extend(unpack(instr[31:20]));                                              // I_TYPE
      STORE  : return extend(unpack({instr[31:25], instr[11:7]}));                               // S_TYPE
      BRANCH : return extend(unpack({instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}));    // B_TYPE
      JAL    : return extend(unpack({instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}));  // J_TYPE
      default: return 0;
   endcase;
   item.immu = unpack(pack(imms));

   return item;
endfunction

// 函数：判断 BRANCH 类指令是否跳转
// 用在 EX阶段
function Bool is_branch(InstrItem item);
   int item_rsrc1_s = unpack(pack(item.rsrc1.d));
   int item_rsrc2_s = unpack(pack(item.rsrc2.d));
   return case(item.funct3)
      3'b000 : return item.rsrc1.d == item.rsrc2.d;   // BEQ
      3'b001 : return item.rsrc1.d != item.rsrc2.d;   // BNE
      3'b100 : return item_rsrc1_s <  item_rsrc2_s;   // BLT
      3'b101 : return item_rsrc1_s >= item_rsrc2_s;   // BGE
      3'b110 : return item.rsrc1.d <  item.rsrc2.d;   // BLTU
      3'b111 : return item.rsrc1.d >= item.rsrc2.d;   // BGEU
      default: return False;
   endcase;
endfunction

// 函数：ALU，得到算术逻辑计算结果
// 用在 EX阶段
function UInt#(32) alu(InstrItem item);
   UInt#(5) shamti = truncate(item.immu);
   UInt#(5) shamtr = truncate(item.rsrc2.d);
   int item_rsrc1_s = unpack(pack(item.rsrc1.d));
   int item_rsrc2_s = unpack(pack(item.rsrc2.d));
   int imms = unpack(pack(item.immu));
   return case( {item.funct7, item.funct3, pack(item.opcode)} ) matches
      17'b???????_???_110?111 : return item.pc + 4;                           // JAL, JALR
      17'b???????_???_0110111 : return item.immu;                             // LUI
      17'b???????_???_0010111 : return item.pc + item.immu;                   // AUIPC
      17'b0000000_000_0110011 : return item.rsrc1.d + item.rsrc2.d;           // ADD
      17'b???????_000_0010011 : return item.rsrc1.d + item.immu;              // ADDI
      17'b0100000_000_0110011 : return item.rsrc1.d - item.rsrc2.d;           // SUB
      17'b0000000_100_0110011 : return item.rsrc1.d ^ item.rsrc2.d;           // XOR
      17'b???????_100_0010011 : return item.rsrc1.d ^ item.immu;              // XORI
      17'b0000000_110_0110011 : return item.rsrc1.d | item.rsrc2.d;           // OR
      17'b???????_110_0010011 : return item.rsrc1.d | item.immu;              // ORI
      17'b0000000_111_0110011 : return item.rsrc1.d & item.rsrc2.d;           // AND
      17'b???????_111_0010011 : return item.rsrc1.d & item.immu;              // ANDI
      17'b0000000_001_0110011 : return item.rsrc1.d << shamtr;                // SLL
      17'b0000000_001_0010011 : return item.rsrc1.d << shamti;                // SLLI
      17'b0000000_101_0110011 : return item.rsrc1.d >> shamtr;                // SRL
      17'b0000000_101_0010011 : return item.rsrc1.d >> shamti;                // SRL
      17'b0100000_101_0110011 : return unpack(pack(item_rsrc1_s >> shamtr));  // SRA
      17'b0100000_101_0010011 : return unpack(pack(item_rsrc1_s >> shamti));  // SRAI
      17'b0000000_010_0110011 : return (item_rsrc1_s < item_rsrc2_s) ? 1 : 0; // SLT
      17'b???????_010_0010011 : return (item_rsrc1_s < imms        ) ? 1 : 0; // SLTI
      17'b0000000_011_0110011 : return (item.rsrc1.d < item.rsrc2.d) ? 1 : 0; // SLTU
      17'b???????_011_0010011 : return (item.rsrc1.d < item.immu   ) ? 1 : 0; // SLTIU
      default                 : return 0;
   endcase;
endfunction


// 接口： CPU 的接口
interface CPU_ifc;
   // instruction-bus methods
   method UInt#(32) ibus_addr;                                   // instruction-bus request, return addr (i.e. PC)
   method Action ibus_next;                                      // instruction-bus request ready
   method Action ibus_rdata(UInt#(32) instr);                    // instruction-bus response, parameter is rdata (i.e. instruction)
   // data-bus methods
   method Tuple3#(Bool, UInt#(32), UInt#(32)) dbus_addr_wdata;   // data-bus request, return (is_write?, addr, wdata)
   method Action dbus_next;                                      // data-bus request ready
   method Action dbus_rdata(UInt#(32) read_data);                // data-bus response rdata, parameter is rdata (only response when is_write=False)
   // CPU boot
   method Action boot(UInt#(32) boot_addr);                      // cpu boot
endinterface


// 模块： CPU 的实现
//
// 支持  ： 基本完备的 RV32I 指令集
//          EX阶段和WB阶段的寄存器结果bypass到ID阶段
//         instruction-bus 和 data-bus 的握手与停顿 （例如能应对 cache-miss）
//
// 不支持: CSR 类指令
//         单字节、双字节 Load 和 Store，只支持四字节 Load 和 Store。
//
(* synthesize *)
module mkRv32iCPU (CPU_ifc);
   // Register file 32bit*32
   Reg#(UInt#(32)) regfile [32];
      for (Integer i=0; i<32; i=i+1)
         regfile[i] <- mkReg(0);

   // To get the Next PC ---------------------------------------------------------------------------------------------
   FIFOF#(UInt#(32)) if_pc <- mkSizedBypassFIFOF(2);
   FIFOF#(UInt#(32)) id_pc <- mkFIFOF;
   FIFOF#(UInt#(32)) id_instr <- mkBypassFIFOF;
   FIFOF#(InstrItem) ex_reg <- mkDFIFOF(unpack('0));
   FIFOF#(InstrItem) wb_reg <- mkDFIFOF(unpack('0));
   FIFOF#(Tuple3#(Bool, UInt#(32), UInt#(32))) loadstore_fifo <- mkBypassFIFOF;
   Wire#(Maybe#(UInt#(32))) wb_load_data <- mkDWire(tagged Invalid);

   (* conflict_free = "ex_stage, id_stage" *)
   (* descending_urgency = "boot, ex_stage" *)
   (* descending_urgency = "boot, id_stage" *)

   // 2. ID (Instruction Decode) stage -----------------------------------------------------------------
   rule id_stage;
      InstrItem item = decode(pack(id_instr.first));
      item.pc = id_pc.first;

      // register bypass read logic
      UInt#(32) forward_data = wb_reg.first.load ? fromMaybe(0, wb_load_data) : wb_reg.first.rdst.d;
      item.rsrc1.d = (item.rsrc1.e && wb_reg.first.rdst.e && item.rsrc1.a == wb_reg.first.rdst.a) ? forward_data : regfile[item.rsrc1.a];
      item.rsrc2.d = (item.rsrc2.e && wb_reg.first.rdst.e && item.rsrc2.a == wb_reg.first.rdst.a) ? forward_data : regfile[item.rsrc2.a];

      // If there's no hazard, push this instruction to EX stage
      if( !( wb_reg.first.load   && (item.rsrc1.e && item.rsrc1.a == wb_reg.first.rdst.a || item.rsrc2.e && item.rsrc2.a == wb_reg.first.rdst.a ) && !isValid(wb_load_data) ) &&  // NO hazard with wb_stage (load data not ready)
          !( ex_reg.first.rdst.e && (item.rsrc1.e && item.rsrc1.a == ex_reg.first.rdst.a || item.rsrc2.e && item.rsrc2.a == ex_reg.first.rdst.a ) ) ) begin                       // NO hazard with ex_stage
         id_instr.deq;
         id_pc.deq;
         ex_reg.enq(item);
         if(item.opcode != JALR && item.opcode != BRANCH)
            if_pc.enq( item.opcode==JAL ? item.pc+item.immu : item.pc+4 );
      end
   endrule

   // 3. EX&MEM (Execute and Memory Access) stage -----------------------------------------------------------------
   rule ex_stage;                           
      InstrItem item = ex_reg.first;
      ex_reg.deq;
      if(item.opcode == JALR)
         if_pc.enq( item.rsrc1.d + item.immu );
      else if(item.opcode == BRANCH)
         if_pc.enq( item.pc + (is_branch(item) ? item.immu : 4) );
      
      if(item.store || item.load)
         loadstore_fifo.enq( tuple3(item.store, item.rsrc1.d+item.immu, item.rsrc2.d) );
      if(item.rdst.e) begin
         item.rdst.d = alu(item);
         wb_reg.enq(item);
      end
   endrule

   // 4. WB (Register Write Back) stage -----------------------------------------------------------------
   rule wb_stage;                                   
      InstrItem item = wb_reg.first;
      if(item.load) begin
         if(isValid(wb_load_data)) begin
            regfile[item.rdst.a] <= fromMaybe(0, wb_load_data);
            wb_reg.deq;
         end
      end else if(item.rdst.e) begin
         regfile[item.rdst.a] <= item.rdst.d;
         wb_reg.deq;
      end
   endrule

   // instr bus interface (methods) -------------------------------------------------------------------------------------------------------------------------------
   method ibus_addr = if_pc.first;

   method Action ibus_next;
      id_pc.enq(if_pc.first);
      if_pc.deq;
   endmethod

   method ibus_rdata = id_instr.enq;

   // data bus interface (methods) -------------------------------------------------------------------------------------------------------------------------------
   method dbus_addr_wdata = loadstore_fifo.first;
   
   method dbus_next = loadstore_fifo.deq;

   method Action dbus_rdata(UInt#(32) read_data) if(wb_reg.first.load);
      wb_load_data <= tagged Valid read_data;
   endmethod

   // CPU boot (boot) -----------------------------------------------------------------------------------------------------------------------------------------
   method Action boot(UInt#(32) boot_addr);
      if_pc.enq( boot_addr );
   endmethod

endmodule



// 模块：CPU testbench
module mkTb ();
   // 指定指令流文件, 仿真时 CPU 会运行其中的指令流
   String instruction_stream_filename = "instruction_stream/instruction_stream_quicksort.txt";

   BRAM1Port#(UInt#(32), UInt#(32)) instr_ram <- mkBRAM1Server( BRAM_Configure{memorySize:4096, latency:1, outFIFODepth:3, allowWriteResponseBypass:False, loadFormat: tagged Hex instruction_stream_filename} );
   BRAM2Port#(UInt#(32), UInt#(32)) data_ram <- mkBRAM2Server( BRAM_Configure{memorySize:4096, latency:1, outFIFODepth:3, allowWriteResponseBypass:False, loadFormat: None} );

   CPU_ifc cpu <- mkRv32iCPU;

   UInt#(32) endCycle = 15000;
   Reg#(UInt#(32)) cycle <- mkReg(0);   // clock cycle count
   Reg#(UInt#(32)) count <- mkReg(0);   // instruction fetched count

   rule up_cycle;
      cycle <= cycle + 1;
      if(cycle > endCycle+60) $finish;
   endrule

   rule cpu_start (cycle == 0);
      cpu.boot(0);
   endrule

   // CPU指令总线请求
   rule cpu_instr_request;// (cycle%10==0 || cycle%10==1 || cycle%10==3 || cycle%10==4 || cycle%10==7 || cycle%10==9);  // 加入条件，可以验证指令总线停顿功能
      UInt#(32) instr_addr = cpu.ibus_addr;
      cpu.ibus_next;
      instr_ram.portA.request.put( BRAMRequest{write:False, responseOnWrite:False, address: instr_addr/4, datain: 0} );
      
      count <= count + 1;
      //if(cycle < endCycle)
      //   $display("cycle=%7d   count=%7d   pc/4=%7d", cycle, count, instr_addr/4);
   endrule

   // CPU指令总线响应
   rule cpu_instr_read_response;
      UInt#(32) instr <- instr_ram.portA.response.get();
      cpu.ibus_rdata(instr);
   endrule

   // CPU数据总线请求
   rule cpu_data_request;// (cycle>100 && (cycle%10==0 || cycle%10==2|| cycle%10==5 || cycle%10==7 || cycle%10==8));  // 加入条件，可以验证数据总线停顿功能
      match { .is_write, .addr, .data } = cpu.dbus_addr_wdata;
      cpu.dbus_next;
      data_ram.portA.request.put( BRAMRequest{write: is_write, responseOnWrite: False, address: addr/4, datain: data} );
   endrule

   // CPU数据总线响应
   rule cpu_data_read_response;
      UInt#(32) read_data <- data_ram.portA.response.get();
      cpu.dbus_rdata(read_data);
   endrule
   
   // 仿真的最后，读 dataram 并打印
   rule data_ram_dump_req  (cycle >= endCycle && cycle < endCycle+40);
      data_ram.portB.request.put( BRAMRequest{write: False, responseOnWrite: False, address: cycle-endCycle, datain: 0} );  
   endrule

   // 打印 dataram
   rule data_ram_dump_resp;
      UInt#(32) read_data <- data_ram.portB.response.get();
      int read_data_signed = unpack(pack(read_data));
      $display("%d", read_data_signed);
   endrule
   
endmodule

endpackage
