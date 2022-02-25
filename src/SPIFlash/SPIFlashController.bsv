// Copyright(c) 2022 https://github.com/WangXuan95

package SPIFlashController;

import BRAM::*;
import StmtFSM::*;

import SPIController::*;


interface SPIFlashController;
    method Action  operate(Bool wr, Bit#(9) addr, Bit#(8) data);
    method ActionValue#(Bit#(8)) read_byte;
    method bit     ss_o;
    method bit     sck_o;
    method bit     mosi_o;
    method Action  miso_i(bit i);
endinterface


typedef enum { Read='h03, Write='h02, Erase='h20, Default='hFF } FlashCommand deriving(Bits, Eq);


(* synthesize *)
(* always_ready = "ss_o, sck_o, mosi_o" *)
(* always_enabled = "miso_i" *)
module mkSPIFlashController (SPIFlashController);

    BRAM2Port#(Bit#(8), Bit#(8)) page_buffer <- mkBRAM2Server(defaultValue);
    SPIController  spi_ctrl    <- mkSPIController;
    Reg#(int)      cnt         <- mkReg(0);
    Reg#(FlashCommand) command <- mkReg(Default);
    Reg#(Bit#(8))  page_addr_h <- mkReg(0);
    Reg#(Bit#(8))  page_addr_l <- mkReg(0);
    Reg#(bit)      ss          <- mkReg(1);
    Reg#(Bool)     busybit     <- mkReg(True);

    function Action spi_ctrl_wait;
        return action
            let a = spi_ctrl.read;
        endaction;
    endfunction

    FSM spiFlashFsm <- mkFSM (
        seq
            // wait till SPIFlash not busy
            busybit <= True;
            while(busybit) seq
                delay(64);
                ss <= 1'b0;
                spi_ctrl.write(8'h05);
                spi_ctrl.write(8'h00);
                busybit <= unpack( spi_ctrl.read[0] );
                ss <= 1'b1;
            endseq

            // if write or erase operation
            if( command==Write || command==Erase ) seq
                delay(64);
                ss <= 1'b0;
                spi_ctrl.write(8'h06);
                spi_ctrl_wait;
                ss <= 1'b1;
            endseq
            
            delay(64);
            ss <= 1'b0;
            spi_ctrl.write(pack(command));
            spi_ctrl.write(page_addr_h);
            spi_ctrl.write(page_addr_l);
            spi_ctrl.write(8'h0);
            if( command == Erase )
                spi_ctrl_wait;
            else if( command == Write )
                for(cnt<=0; cnt<256; cnt<=cnt+1) seq
                    page_buffer.portB.request.put( BRAMRequest{ write: False, responseOnWrite:False, address: pack(cnt)[7:0], datain: 8'h0 } );
                    action
                        let bdata <- page_buffer.portB.response.get();
                        spi_ctrl.write( bdata );
                    endaction
                    spi_ctrl_wait;
                endseq
            else
                for(cnt<=0; cnt<256; cnt<=cnt+1) seq
                    spi_ctrl.write(8'h0);
                    page_buffer.portB.request.put( BRAMRequest{ write: True, responseOnWrite:False, address: pack(cnt)[7:0], datain: spi_ctrl.read } );
                endseq
            ss <= 1'b1;
        endseq
    );

    method Action operate(Bool wr, Bit#(9) addr, Bit#(8) data);
        if(addr[8]==1'b0) begin
            page_buffer.portA.request.put( BRAMRequest{ write: wr, responseOnWrite:False, address: addr[7:0], datain: data } );
        end else if(addr==9'h100) begin
            page_addr_l <= data;
        end else if(addr==9'h101) begin
            page_addr_h <= data;
        end else if(addr==9'h108) begin
            command <= unpack(data);
            spiFlashFsm.start();
            //$display("command=%x  addr=%x%x", data, page_addr_h, page_addr_l );
        end
    endmethod

    method ActionValue#(Bit#(8)) read_byte = page_buffer.portA.response.get;

    // SPI bus connections
    method ss_o   = ss._read;
    method sck_o  = spi_ctrl.sck_o;
    method mosi_o = spi_ctrl.mosi_o;
    method miso_i = spi_ctrl.miso_i;
endmodule


endpackage
