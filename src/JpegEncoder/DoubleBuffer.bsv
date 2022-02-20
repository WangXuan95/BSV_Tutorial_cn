// Copyright(c) 2022 https://github.com/WangXuan95

package DoubleBuffer;

import Vector::*;


// 参数：Vector 类型的变量
// 返回：返回 Vector 的长度
function Integer vectorLen(Vector#(n, td) vec) = valueOf(n);


// 功能：把寄存器向量中的数据取出来，组成新的数据向量返回
// 参数：Vector#(n, Reg#(td)) 寄存器向量
// 返回：Vector#(n, td)
function Vector#(n, td) regVector2Vector( Vector#(n, Reg#(td)) reg_vec )
   provisos( Bits#(td, sz) );
   Vector#(n, td) vec;
   for(Integer i=0; i<valueOf(n); i=i+1)
      vec[i] = reg_vec[i]._read;
   return vec;
endfunction


//
// 双缓冲接口 DoubleBuffer
//
// 配置参数: n : 双缓冲中每块的元素数量
//          td : 数据元素类型
//
// 方法 put : 
//      参数 cancel : False:正常输入一个数据元素   True:撤销当前正在写的块，重新开始积攒n个元素
//           indata : 一个输入数据元素
//
// 方法 get :
//      效果        : 读一次数据，读出一整块（n个元素）
//      返回值      : Tuple2(读计数，一整块数据) 
//                       读计数: 当前一整块被读的次数，从0开始
//                       一整块数据:  n个元素的Vector
interface DoubleBuffer#(numeric type n, type td);
   method Action put(Bool cancel, td indata);
   method ActionValue#(Tuple2#(UInt#(32), Vector#(n, td))) get;
endinterface


//
// 双缓冲模块
// 
// 接口： DoubleBuffer#(n, td)
//
// 参数： readTimes : 允许读一个块的次数
module mkDoubleBuffer#( UInt#(32) readTimes ) ( DoubleBuffer#(n, td) )
   provisos( Bits#(td, sz) );

   // 双缓冲寄存器组 ------------------------------------------------------------------------
   Vector#(n, Reg#(td)) buffer [2];          // 两块，每块 n 个元素
   buffer[0] <- replicateM( mkRegU );
   buffer[1] <- replicateM( mkRegU );

   // 常量 ------------------------------------------------------------------------
   UInt#(TLog#(n)) wptrMax = fromInteger(valueOf(n)-1);   // 写指针的最大值, 是运行时的常数

   // 双缓冲指针和计数 ------------------------------------------------------------------------
   Reg#(Bit#(2))       wblock <- mkReg(0);   // 写块号指针 , 取值范围 'b00 ~ 'b11
   Reg#(UInt#(TLog#(n))) wptr <- mkReg(0);   // 写指针     , 取值范围 0 ~ wptrMax ， 也即 0~n-1
   Reg#(Bit#(2))       rblock <- mkReg(0);   // 读块号指针 , 取值范围 'b00 ~ 'b11
   Reg#(UInt#(32))       rcnt <- mkReg(0);   // 读计数     , 取值范围 0 ~ readTimes-1

   // 双缓冲空满判断 ------------------------------------------------------------------------
   Wire#(Bool) empty <- mkWire;
   Wire#(Bool) full  <- mkWire;
   rule empty_full;
      empty <= wblock ==   rblock;
      full  <= wblock == {~rblock[1], rblock[0]};
   endrule

   // 双缓冲输入方法 ------------------------------------------------------------------------
   method Action put(Bool cancel, td indata) if( !full );
      if(cancel) begin                              // 如果撤销
         wptr <= 0;
      end else begin                                // 如果正常输入数据
         buffer[ wblock[0] ][ wptr ] <= indata;     //   写入缓冲区
         wptr <= wptr >= wptrMax ? 0 : wptr + 1;    //   移动写指针
         if(wptr >= wptrMax)                        //   如果写指针=最大值
            wblock <= wblock + 1;                   //     写块号+1，即去写下一个块
      end
   endmethod

   // 双缓冲输出方法 ------------------------------------------------------------------------
   method ActionValue#(Tuple2#(UInt#(32), Vector#(n, td))) get if( !empty );
      rcnt <= rcnt+1>=readTimes ? 0 : rcnt + 1;     // 移动读计数
      if( rcnt+1>=readTimes )                       // 如果读计数+1=读次数
         rblock <= rblock + 1;                      //   读块号+1, 即去读下一块
      return tuple2(                                // 构造 tuple2
         rcnt,                                      //   读计数
         regVector2Vector( buffer[ rblock[0] ] )    //   从缓冲区读取的块
      );
   endmethod

endmodule



// 针对 mkDoubleBuffer 的 testbench

module mkTb ();

   // 时钟周期计数器 cnt ------------------------------------------------------------------------
   Reg#(int) cnt <- mkReg(0);
   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 1000) $finish;   // 仿真 1000 个周期
   endrule

   // DoubleBuffer 实例 ------------------------------------------------------------------------
   DoubleBuffer#(5, UInt#(16)) doublebuffer <- mkDoubleBuffer(3);

   // 向 doublebuffer 中输入 ------------------------------------------------------------------------
   Reg#(UInt#(16)) indata <- mkReg(0);
   rule double_buffer_put;// (cnt%9==0);    // 可以添加隐式条件，来模拟“有时候输入，有时候不输入”的情况，发现不影响结果，只影响性能
      if(indata < 48) begin
         doublebuffer.put(False, indata);
         indata <= indata + 1;
      end else
         doublebuffer.put(True, 0);
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


endpackage