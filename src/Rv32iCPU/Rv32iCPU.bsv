// Copyright(c) 2022 https://github.com/WangXuan95

package Rv32iCPU;

import Vector::*;
import DReg::*;
import FIFOF::*;
import SpecialFIFOs::*;

import DFIFOF1::*;


// 枚举：指令码 OPCODE ---------------------------------------------------------------------------------------------
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

// 结构体：寄存器有效、地址、数据 ---------------------------------------------------------------------------------------------
typedef struct {
   Bool     e;
   Bit#(5)  a;
   Bit#(32) d;
} RegItem deriving(Bits);

// 结构体：指令解码和执行结果 ---------------------------------------------------------------------------------------------
typedef struct {        //struction of Decoded Instrunction item, named InstrItem.
   Bit#(32)  pc;        // fill at IF stage
   OpCode    opcode;    // fill at ID stage
   RegItem   rsrc1;     // fill at ID stage
   RegItem   rsrc2;     // fill at ID stage
   RegItem   rdst;      // rdst.e , rdst.a  fill at ID stage. rdst.d  fill at EX stage
   Bit#(7)   funct7;    // fill at ID stage
   Bit#(3)   funct3;    // fill at ID stage
   Bool      store;     // fill at ID stage
   Bool      load;      // fill at ID stage
   Bit#(32)  immu;      // fill at ID stage
} InstrItem deriving(Bits);


// 接口： CPU 的接口 ---------------------------------------------------------------------------------------------
interface CPU_ifc;
   method Action                                     boot(Bit#(32) boot_addr);    // CPU boot
   method Bit#(32)                                   ibus_req;                    // instruction-bus request, return addr (i.e. PC)
   method Action                                     ibus_reqx;                   // instruction-bus request ready
   method Action                                     ibus_resp(Bit#(32) rdata);   // instruction-bus response, parameter is rdata (i.e. instruction)
   method Tuple4#(Bool, Bit#(4), Bit#(32), Bit#(32)) dbus_req;                    // data-bus request, return (is_write?, byte_en, addr, wdata)
   method Action                                     dbus_reqx;                   // data-bus request ready
   method Action                                     dbus_resp(Bit#(32) rdata);   // data-bus response rdata, parameter is rdata (only response when is_write=False)
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
(* always_ready = "boot" *)
module mkRv32iCPU (CPU_ifc);

   // 函数：指令解码 ---------------------------------------------------------------------------------------------
   // 用在 ID段
   function InstrItem decode(Bit#(32) instr);
      InstrItem item = unpack('0);

      item.funct7 = instr[31:25];
      item.rsrc2.a = instr[24:20];
      item.rsrc1.a = instr[19:15];
      item.funct3 = instr[14:12];
      item.rdst.a = instr[11:7];
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
      item.immu = pack(imms);

      return item;
   endfunction

   // 函数：判断 BRANCH 类指令是否跳转 ---------------------------------------------------------------------------------------------
   // 用在 EX段
   function Bool is_branch(InstrItem item);
      int item_rsrc1_s = unpack(item.rsrc1.d);
      int item_rsrc2_s = unpack(item.rsrc2.d);
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

   // 函数：ALU，得到算术逻辑计算结果 ---------------------------------------------------------------------------------------------
   // 用在 EX段
   function Bit#(32) alu(InstrItem item);
      Bit#(5) shamti = truncate(item.immu);
      Bit#(5) shamtr = truncate(item.rsrc2.d);
      int item_rsrc1_s = unpack(item.rsrc1.d);
      int item_rsrc2_s = unpack(item.rsrc2.d);
      int imms = unpack(item.immu);
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
   
   // 函数：dbus_adapt_req，对读写请求进行访存转换（构建读写请求） ---------------------------------------------------------------------------------------------
   // 用在 EX段
   function Tuple4#(Bool, Bit#(4), Bit#(32), Bit#(32)) dbus_adapt_req(InstrItem item);
      Bit#(4)  byte_en = 0;
      Bit#(32) addr = item.rsrc1.d + item.immu;
      Bit#(32) wdata = item.rsrc2.d;
      if(item.store)
         case (item.funct3) matches
            3'b?00 : begin   byte_en = 'b0001 << addr[1:0];   wdata = wdata << {addr[1:0],3'd0};   end
            3'b?01 : begin   byte_en = 'b0011 << addr[1:0];   wdata = wdata << {addr[1:0],3'd0};   end
            default:         byte_en = 'b1111;
         endcase
      return tuple4(item.store, byte_en, (addr>>2<<2), wdata);
   endfunction

   // 函数：dbus_adapt_rdata，对读响应进行访存转换 ---------------------------------------------------------------------------------------------
   // 用在 EX段
   function Bit#(32) dbus_adapt_rdata(InstrItem item, Bit#(32) rdata);
      Bit#(32) addr = item.rsrc1.d + item.immu;
      Bit#(5)  shamt = {addr[1:0],3'd0};
      return case (item.funct3) matches
         3'b000 : return signExtend( (rdata>>shamt)[ 7:0] );
         3'b100 : return zeroExtend( (rdata>>shamt)[ 7:0] );
         3'b001 : return signExtend( (rdata>>shamt)[15:0] );
         3'b101 : return zeroExtend( (rdata>>shamt)[15:0] );
         default: return rdata;
      endcase;
   endfunction

   // Register file 32bit*32 ---------------------------------------------------------------------------------------------
   Vector#(32, Reg#(Bit#(32))) regfile <- replicateM( mkReg(0) );

   // To get the Next PC ---------------------------------------------------------------------------------------------
   Reg#(Maybe#(Bit#(32)))                             boot_pc  <- mkDReg(tagged Invalid);
   FIFOF#(Bit#(32))                                   if_pc    <- mkSizedBypassFIFOF(2);
   FIFOF#(Bit#(32))                                   id_pc    <- mkFIFOF;
   FIFOF#(Bit#(32))                                   id_instr <- mkBypassFIFOF;
   FIFOF#(InstrItem)                                  ex       <- mkDFIFOF(unpack('0));
   Reg#(RegItem)                                      wb       <- mkDReg(unpack('0));
   FIFOF#(InstrItem)                                  ld       <- mkDFIFOF1(unpack('0));
   FIFOF#(Tuple4#(Bool, Bit#(4), Bit#(32), Bit#(32))) lsq      <- mkBypassFIFOF;

   (* conflict_free = "ex_stage, id_stage" *)
   (* descending_urgency = "enq_boot_pc, ex_stage" *)
   (* descending_urgency = "enq_boot_pc, id_stage" *)
   (* mutually_exclusive = "dbus_resp, wb_stage" *)

   // 2. ID (Instruction Decode) stage -----------------------------------------------------------------
   rule id_stage;
      InstrItem item = decode(id_instr.first);
      item.pc = id_pc.first;

      // register bypass read logic
      item.rsrc1.d = (item.rsrc1.e && wb.e && item.rsrc1.a == wb.a) ? wb.d : regfile[item.rsrc1.a];
      item.rsrc2.d = (item.rsrc2.e && wb.e && item.rsrc2.a == wb.a) ? wb.d : regfile[item.rsrc2.a];

      // If there's no hazard, push this instruction to EX stage
      if( !( ld.first.load   && (item.rsrc1.e && item.rsrc1.a == ld.first.rdst.a || item.rsrc2.e && item.rsrc2.a == ld.first.rdst.a) ) &&      // NO hazard with wb_stage
          !( ex.first.rdst.e && (item.rsrc1.e && item.rsrc1.a == ex.first.rdst.a || item.rsrc2.e && item.rsrc2.a == ex.first.rdst.a) ) ) begin // NO hazard with ex_stage
         id_instr.deq;
         id_pc.deq;
         ex.enq(item);
         if(item.opcode != JALR && item.opcode != BRANCH)
            if_pc.enq( item.opcode==JAL ? item.pc+item.immu : item.pc+4 );
      end
   endrule

   // 3. EX&MEM (Execute and Memory Access) stage -----------------------------------------------------------------
   rule ex_stage;              
      ex.deq;             
      InstrItem item = ex.first;

      case( item.opcode )
         JALR   : if_pc.enq( item.rsrc1.d + item.immu );
         BRANCH : if_pc.enq( item.pc + (is_branch(item) ? item.immu : 4) );
      endcase
      
      if(item.store || item.load) begin
         lsq.enq( dbus_adapt_req(item) );
         if(item.load)
            ld.enq(item);
      end else begin
         item.rdst.d = alu(item);
         wb <= item.rdst;
      end
   endrule

   // 4. WB (Register Write Back) stage -----------------------------------------------------------------
   rule wb_stage (wb.e);
      regfile[wb.a] <= wb.d;
   endrule
   
   rule enq_boot_pc (isValid(boot_pc));
      if_pc.enq( fromMaybe(0, boot_pc) );
   endrule

   // CPU boot  -----------------------------------------------------------------------------------------------------------------------------------------
   method Action boot(Bit#(32) boot_addr);
      boot_pc <= tagged Valid boot_addr;
   endmethod

   // instr bus interface (methods) -------------------------------------------------------------------------------------------------------------------------------
   method ibus_req = if_pc.first;

   method Action ibus_reqx;
      if_pc.deq;
      id_pc.enq(if_pc.first);
   endmethod

   method ibus_resp = id_instr.enq;

   // data bus interface (methods) -------------------------------------------------------------------------------------------------------------------------------
   method dbus_req = lsq.first;
   
   method dbus_reqx = lsq.deq;

   method Action dbus_resp(Bit#(32) rdata) if(ld.first.load);
      ld.deq;
      regfile[ld.first.rdst.a] <= dbus_adapt_rdata(ld.first, rdata);
   endmethod

endmodule


endpackage
