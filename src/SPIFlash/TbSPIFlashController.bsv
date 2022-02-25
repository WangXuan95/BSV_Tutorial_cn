// Copyright(c) 2022 https://github.com/WangXuan95

package TbSPIFlashController;

import StmtFSM::*;

import SPIFlashController::*;


module mkTb ();
    let spiflash_ctrl <- mkSPIFlashController;

    function Action read_and_show;
        return action
            let read_byte <- spiflash_ctrl.read_byte;
            $display("read_byte = %x", read_byte);
        endaction;
    endfunction

    mkAutoFSM( seq
        spiflash_ctrl.operate( True, 'h000, 'h12);   // write 1byte to buffer
        spiflash_ctrl.operate( True, 'h001, 'h34);   // write 1byte to buffer

        spiflash_ctrl.operate( True, 'h100, 'hab);   // set page_addr_l = 0xAB
        spiflash_ctrl.operate( True, 'h101, 'h01);   // set page_addr_h = 0x01
        spiflash_ctrl.operate( True, 'h108, 'h20);   // start erase page

        spiflash_ctrl.operate( True, 'h108, 'h02);   // start write page

        spiflash_ctrl.operate(False, 'h000, 'h00);   // read 1byte from buffer
        spiflash_ctrl.operate(False, 'h001, 'h00);   // read 1byte from buffer
        repeat(2) read_and_show;

        spiflash_ctrl.operate( True, 'h108, 'h03);   // start read page

        spiflash_ctrl.operate(False, 'h000, 'h00);   // read 1byte from buffer
        spiflash_ctrl.operate(False, 'h001, 'h00);   // read 1byte from buffer
        repeat(2) read_and_show;
    endseq );

    rule spi_set_miso;
        spiflash_ctrl.miso_i(0);
    endrule

    //rule spi_show;
    //    $display("ss:%d  sck:%d   mosi:%d", spiflash_ctrl.ss_o, spiflash_ctrl.sck_o, spiflash_ctrl.mosi_o);
    //endrule

endmodule


endpackage
