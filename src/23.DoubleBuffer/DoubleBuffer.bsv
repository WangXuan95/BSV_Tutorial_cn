package DoubleBuffer;


import Vector::*;
import BRAM::*;



// 函数：vectorLen
// 参数：Vector 类型的变量
// 返回：Vector 的长度
function Integer vectorLen(Vector#(sz, td) vec) = valueOf(sz);


// 函数：regVector2Vector
// 功能：把寄存器向量中的数据取出来，组成新的数据向量返回
// 参数：Vector#(sz, Reg#(td)) 寄存器向量
// 返回：Vector#(sz, td)
function Vector#(sz, td) regVector2Vector( Vector#(sz, Reg#(td)) reg_vec )
   provisos( Bits#(td, td_sz) );
   Vector#(sz, td) vec;
   for(Integer i=0; i<valueOf(sz); i=i+1)
      vec[i] = reg_vec[i]._read;
   return vec;
endfunction



// 接口: DoubleBuffer
// 配置参数: sz : 双缓冲中每块的元素数量
//          td : 数据元素类型
// 方法 rewind : 重置，如果当前块被写入了一部分，就撤销当前正在写的块，重新开始积攒sz个元素
// 方法 put : 输入一个数据元素
//           indata : 一个输入数据元素
// 方法 get : 读一次数据，读出一整块（sz个元素）
//      返回值 : Tuple2(读计数，一整块数据) 
//               读计数: 当前一整块被读的次数，从0开始
//               一整块数据: sz个元素的Vector
interface DoubleBuffer#(numeric type sz, type td);
   method Action rewind;
   method Action put(td indata);
   method ActionValue#(Tuple2#(UInt#(32), Vector#(sz, td))) get;
endinterface



// 模块： mkDoubleBuffer
// 功能： 双缓冲模块，每块 sz 个数据元素，每次输入一个元素，攒够一块后，每次读 sz 个元素，共读 rtime 次。用寄存器实现。
// 接口： DoubleBuffer#(sz, td)
// 参数： rtime : 读一个块的次数
module mkDoubleBuffer#( UInt#(32) rtime ) ( DoubleBuffer#(sz, td) )
   provisos( Bits#(td, td_sz) );

   // 双缓冲寄存器组 ------------------------------------------------------------------------
   Vector#(sz, Reg#(td)) buffer [2];         // 两块，每块 sz 个元素
   buffer[0] <- replicateM( mkRegU );
   buffer[1] <- replicateM( mkRegU );

   // 常量 ------------------------------------------------------------------------
   UInt#(TLog#(sz)) wptrMax = fromInteger(valueOf(sz)-1);   // 写指针的最大值, 是运行时的常数

   // 双缓冲指针和计数 ------------------------------------------------------------------------
   Reg#(Bit#(2))        wblock <- mkReg(0);   // 写块号指针 , 取值范围 'b00 ~ 'b11
   Reg#(UInt#(TLog#(sz))) wptr <- mkReg(0);   // 写指针     , 取值范围 0 ~ wptrMax ， 也即 0~sz-1
   Reg#(Bit#(2))        rblock <- mkReg(0);   // 读块号指针 , 取值范围 'b00 ~ 'b11
   Reg#(UInt#(32))        rcnt <- mkReg(0);   // 读计数     , 取值范围 0 ~ rtime-1

   // 双缓冲空满判断 ------------------------------------------------------------------------
   Wire#(Bool) empty <- mkWire;
   Wire#(Bool) full  <- mkWire;
   rule empty_full;
      empty <= wblock ==   rblock;
      full  <= wblock == {~rblock[1], rblock[0]};
   endrule

   PulseWire rewind_call <- mkPulseWire;

   // 双缓冲重置方法 ------------------------------------------------------------------------
   method Action rewind if( empty );
      rewind_call.send;
      wptr <= 0;
   endmethod

   // 双缓冲输入方法 ------------------------------------------------------------------------
   method Action put(td indata) if( !full && !rewind_call );
      buffer[ wblock[0] ][ wptr ] <= indata;        //   写入缓冲区
      wptr <= wptr >= wptrMax ? 0 : wptr + 1;       //   移动写指针
      if(wptr >= wptrMax) wblock <= wblock + 1;     //   如果写指针=最大值，则写块号+1，即去写下一个块 
   endmethod

   // 双缓冲输出方法 ------------------------------------------------------------------------
   method ActionValue#(Tuple2#(UInt#(32), Vector#(sz, td))) get if( !empty );
      rcnt <= rcnt+1>=rtime ? 0 : rcnt + 1;         // 移动读计数
      if( rcnt+1>=rtime ) rblock <= rblock + 1;     // 如果读计数+1=读次数，则读块号+1, 即去读下一块
      return tuple2(                                // 构造 tuple2
         rcnt,                                      //   读计数
         regVector2Vector( buffer[ rblock[0] ] )    //   从缓冲区读取的块
      );
   endmethod

endmodule



// 模块： mkTbDoubleBuffer
// 功能： 针对 mkDoubleBuffer 的 testbench
module mkTbDoubleBuffer ();

   // 时钟周期计数器 cnt ------------------------------------------------------------------------
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 1000) $finish;   // 仿真 1000 个周期
   endrule

   DoubleBuffer#(5, UInt#(16)) doublebuffer <- mkDoubleBuffer(3);

   // 向 doublebuffer 中输入 ------------------------------------------------------------------------
   Reg#(UInt#(16)) indata <- mkReg(0);
   rule double_buffer_put;// (cnt%7==0);    // 可以添加隐式条件，来模拟“有时候输入，有时候不输入”的情况，发现不影响结果，只影响性能
      if(indata < 48) begin
         doublebuffer.put(indata);
         indata <= indata + 1;
      end
   endrule

   // 从 doublebuffer 中输出 ------------------------------------------------------------------------
   rule double_buffer_get;// (cnt%5==0);    // 可以添加隐式条件，来模拟“有时候接受输出，有时候不接受输出”的情况，发现不影响结果，只影响性能
      match {.rcnt, .rdata} <- doublebuffer.get;    // rcnt 是 读计数， rdata 是读到的块

      // 打印一行 -------------------------------
      $write("cnt=[%4d]   rcnt=[%4d]   data={", cnt, rcnt);
      for(Integer i=0; i<vectorLen(rdata); i=i+1)
         $write(" %2d", rdata[i]);
      $display("}");
   endrule

endmodule



// 接口： ReorderDoubleBuffer
// 配置参数: i_sz : 行计数器的位宽
//           j_sz : 列计数器的位宽
//           td : 数据元素类型
// 方法 rewind : 撤销当前正在写的块（矩阵），重新开始积攒元素
// 参数： i_j_transpose : 行列是否转置（True:列主序、 False:行主序）
//        i_reverse     : 行是否逆序
//        j_reverse     : 列是否逆序
// 方法 put : 输入一个数据元素
//           indata : 一个输入数据元素
// 方法 get : 读一个数据元素
//      返回值      : 读出的数据元素
interface ReorderDoubleBuffer#(numeric type i_sz, numeric type j_sz, type td);
   method Action rewind(UInt#(i_sz) i_max, UInt#(j_sz) j_max, Bool i_j_transpose, Bool i_reverse, Bool j_reverse);
   method Action put(td indata);
   method ActionValue#(td) get;
endinterface



// 模块： mkReorderDoubleBuffer
// 功能： 基于双缓冲的矩阵重排序，可实现转置、行倒序、列倒序。用 BRAM 实现
// 接口： ReorderDoubleBuffer#(td)
module mkReorderDoubleBuffer ( ReorderDoubleBuffer#(i_sz, j_sz, td) )
   provisos( Bits#(td, sz) );

   BRAM2Port#( Tuple3#(bit, UInt#(i_sz), UInt#(j_sz)) , td ) ram <- mkBRAM2Server(defaultValue);
   
   // 配置寄存器 ------------------------------------------------------------------------
   Reg#(UInt#(i_sz)) maxi <- mkReg(0);
   Reg#(UInt#(j_sz)) maxj <- mkReg(0);
   Reg#(Bool) transposeij <- mkReg(False);
   Reg#(Bool) reversei    <- mkReg(False);
   Reg#(Bool) reversej    <- mkReg(False);

   Reg#(Bit#(2))  wblock <- mkReg(0);       // 写块号
   Reg#(UInt#(i_sz)) wi <- mkReg(0);        // 写行号
   Reg#(UInt#(j_sz)) wj <- mkReg(0);        // 写列号

   Reg#(Bit#(2))  rblock <- mkReg(0);       // 读块号
   Reg#(UInt#(i_sz)) ri <- mkReg(0);        // 读行号
   Reg#(UInt#(j_sz)) rj <- mkReg(0);        // 读列号

   // 双缓冲空满判断 ------------------------------------------------------------------------
   Wire#(Bool) empty <- mkWire;
   Wire#(Bool) full  <- mkWire;
   rule empty_full;
      empty <= wblock == rblock;
      full  <= wblock == {~rblock[1], rblock[0]};
   endrule

   // 读数据请求 ------------------------------------------------------------------------
   rule read_ram ( !empty );
      let ria = reversei ? (maxi - ri) : ri;
      let rja = reversej ? (maxj - rj) : rj;
      ram.portB.request.put(BRAMRequest{write: False, responseOnWrite: False, address: tuple3(rblock[0], ria, rja), datain: unpack('0) } );

      if(transposeij) begin
         ri <= (ri >= maxi) ? 0 : ri + 1;
         if(ri >= maxi) rj <= (rj >= maxj) ? 0 : rj + 1;
      end else begin
         rj <= (rj >= maxj) ? 0 : rj + 1;
         if(rj >= maxj) ri <= (ri >= maxi) ? 0 : ri + 1;
      end
      if(rj >= maxj && ri >= maxi) rblock <= rblock + 1;
   endrule

   PulseWire rewind_call <- mkPulseWire;

   // 双缓冲重置方法 ------------------------------------------------------------------------
   method Action rewind(UInt#(i_sz) i_max, UInt#(j_sz) j_max, Bool i_j_transpose, Bool i_reverse, Bool j_reverse) if( empty );
      rewind_call.send;
      wi <= 0;
      wj <= 0;
      maxi <= i_max;
      maxj <= j_max;
      transposeij <= i_j_transpose;
      reversei <= i_reverse;
      reversej <= j_reverse;
   endmethod

   // 双缓冲输入方法 ------------------------------------------------------------------------
   method Action put(td indata) if( !full && !rewind_call );
      ram.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: tuple3(wblock[0], wi, wj), datain: indata } );
      wj <= (wj == maxj) ? 0 : wj + 1;
      if(wj == maxj) wi <= (wi >= maxi) ? 0 : wi + 1;
      if(wj >= maxj && wi >= maxi) wblock <= wblock + 1;
   endmethod

   // 数据输出 ------------------------------------------------------------------------
   method get = ram.portB.response.get;

endmodule



// 模块： mkTbReorderDoubleBuffer
// 功能： 针对 mkReorderDoubleBuffer 的 testbench
module mkTbReorderDoubleBuffer ();

   // 时钟周期计数器 cnt ------------------------------------------------------------------------
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 1000) $finish;   // 仿真 1000 个周期
   endrule

   ReorderDoubleBuffer#(3, 3, int) doublebuffer <- mkReorderDoubleBuffer;

   Reg#(int) indata <- mkReg(0);

   (* preempts = "double_buffer_rewind, double_buffer_put" *)
   rule double_buffer_rewind (cnt == 0);
      doublebuffer.rewind(2, 4, True, True, False);
   endrule

   // 向 doublebuffer 中输入 ------------------------------------------------------------------------
   rule double_buffer_put; // (cnt%3 == 0);    // 矩阵转置器 输入，可添加隐式条件来实现不积极输入
      if(indata < 48) begin
         doublebuffer.put(indata);
         indata <= indata + 1;
      end
   endrule

   // 从 doublebuffer 中输出 ------------------------------------------------------------------------
   rule double_buffer_get; // (cnt%2 == 0);    // 矩阵转置器 输出和验证，可添加隐式条件来实现不积极输出
      int rdata <- doublebuffer.get;
      $display("cnt=[%4d]   rdata=%d", cnt, rdata);
   endrule

endmodule


endpackage