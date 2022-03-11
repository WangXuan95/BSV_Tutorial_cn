// Copyright(c) 2022 https://github.com/WangXuan95

package TbJpegEncoder;

// standard BSV packages
import StmtFSM::*;

// user defined packages
import PgmReader::*;
import JpegEncoder::*;


module mkTb ();
   PgmReader   pgm_reader  <- mkPgmReader("img/in011.pgm");
   JpegEncoder jpg_encoder <- mkJpegEncoder;

   Reg#(File)  jpg_file    <- mkReg(InvalidFile);

   mkAutoFSM( seq
      action
         let fp <- $fopen("out.jpg.txt", "w");
         jpg_file <= fp;
      endaction

      action
         int width  = pgm_reader.image_width;
         int height = pgm_reader.image_height;
         if(width%8 != 0 || height%8 !=0) begin     // 合法性检查， width 和 height 必须是 8 的倍数，否则 JpegEncoder 不支持
            $error("  Error: image width or height is not multiple of 8");
            $finish;
         end
         jpg_encoder.init( unpack(pack(width/8)[8:0]) , unpack(pack(height/8)[8:0]) );
      endaction

      while(pgm_reader.not_finish) seq
         action
            let pixels <- pgm_reader.get_pixels;
            jpg_encoder.put(pixels);
         endaction
         //delay(1);
      endseq

      delay(10000);
   endseq );

   rule write_jpg_to_file;
      $fwrite(jpg_file, "%032x", jpg_encoder.get);
   endrule

endmodule


endpackage
