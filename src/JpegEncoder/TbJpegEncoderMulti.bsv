// Copyright(c) 2022 https://github.com/WangXuan95

package TbJpegEncoderMulti;

// standard BSV packages
import Vector::*;
import StmtFSM::*;

// user defined packages
import PgmReader::*;
import JpegEncoder::*;


module mkTb ();

   PgmReader pgm_readers [5];
   pgm_readers[0] <- mkPgmReader( "img/in000.pgm" );
   pgm_readers[1] <- mkPgmReader( "img/in004.pgm" );
   pgm_readers[2] <- mkPgmReader( "img/in002.pgm" );
   pgm_readers[3] <- mkPgmReader( "img/in009.pgm" );
   pgm_readers[4] <- mkPgmReader( "img/in001.pgm" );

   Vector#(5, Reg#(File)) jpg_files <- replicateM( mkReg(InvalidFile) );

   JpegEncoder jpg_encoder <- mkJpegEncoder;
   
   Reg#(int) ii <- mkReg(0);

   mkAutoFSM( seq
      action   let fp <- $fopen("out0.jpg.txt", "w");   jpg_files[0] <= fp;   endaction
      action   let fp <- $fopen("out1.jpg.txt", "w");   jpg_files[1] <= fp;   endaction
      action   let fp <- $fopen("out2.jpg.txt", "w");   jpg_files[2] <= fp;   endaction
      action   let fp <- $fopen("out3.jpg.txt", "w");   jpg_files[3] <= fp;   endaction
      action   let fp <- $fopen("out4.jpg.txt", "w");   jpg_files[4] <= fp;   endaction

      for(ii<=0; ii<5; ii<=ii+1) seq
         action
            int width  = pgm_readers[ii].image_width;
            int height = pgm_readers[ii].image_height;
            if(width%8 != 0 || height%8 !=0)     // 合法性检查， width 和 height 必须是 8 的倍数，否则 JpegEncoder 不支持
               $error("  Error: image width or height is not multiple of 8");
            jpg_encoder.init( unpack(pack(width/8)[8:0]) , unpack(pack(height/8)[8:0]) );
         endaction

         while(pgm_readers[ii].not_finish) seq
            action
               let pixels <- pgm_readers[ii].get_pixels;
               jpg_encoder.put(pixels);
            endaction
            //delay(1);
         endseq

         jpg_encoder.waitTillDone;
         $fclose(jpg_files[ii]);
         $display("  file #%d compress done", ii);
      endseq

      jpg_encoder.init( 0 , 0 );
   endseq );

   rule write_jpg_to_file;
      $fwrite(jpg_files[ii], "%032x", jpg_encoder.get);
   endrule

endmodule


endpackage
