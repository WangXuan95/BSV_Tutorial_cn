# -*- coding:utf-8 -*-
# Copyright (c) 2022 https://github.com/WangXuan95
#
# 这是一个灰度图像的 JPEG 压缩算法。
# 它不调用除了 numpy 以外的任何库，完整而简洁地展示了 JPEG 算法的原理。
#
# 另外为了进行测试，它还调用了 PIL.Image 库用来读取待压缩的原始文件，但在JPEG 压缩算法中没用 PIL.Image 库。
#
# 你可以用它来进行图像图像压缩，比如，运行以下命令可以把 image.pgm (原始像素文件) 压缩成 image.jpg (JPEG压缩文件) 。
#     python JpegEncoder.py image.pgm image.jpg
# 
# Note: 可以用Windows的图片查看器打开 .jpg 文件，来验证压缩算法的正确性
#

import sys
import numpy as np
from PIL.Image import open as imgopen

class BitstreamWriter():
    def __init__(self):
        self.bitpos = 7
        self.byte = 0x00
        self.stream = bytearray()
    def writebyte(self, _byte):
        self.stream.append(_byte)
    def writebytes(self, _bytes):
        self.stream += _bytes
    def writeword(self, word):
        self.writebyte((word>>8) & 0xFF)
        self.writebyte((word>>0) & 0xFF)
    def writebits(self, _value, _bitlen):
        for ii in range(_bitlen-1, -1, -1):
            if _value & (1<<ii):
                self.byte |= (1<<self.bitpos)
            self.bitpos -= 1
            if self.bitpos<0:
                self.writebyte(self.byte)
                self.bitpos = 7
                self.byte = 0x00
    def flush(self):
        self.writebyte(self.byte)
        self.bitpos = 7
        self.byte = 0x00
    def get(self):
        return self.stream

dct_mat = np.matrix( [
            [ 32, 32, 32, 32, 32, 32, 32, 32],
            [ 44, 38, 25,  9, -9,-25,-38,-44],
            [ 42, 17,-17,-42,-42,-17, 17, 42],
            [ 38, -9,-44,-25, 25, 44,  9,-38],
            [ 32,-32,-32, 32, 32,-32,-32, 32],
            [ 25,-44,  9, 38,-38, -9, 44,-25],
            [ 17,-42, 42,-17,-17, 42,-42, 17],
            [  9,-25, 38,-44, 44,-38, 25, -9] ], dtype = np.int32 )

zig_idxs = np.array( [
            [ 0, 1, 5, 6,14,15,27,28],
            [ 2, 4, 7,13,16,26,29,42],
            [ 3, 8,12,17,25,30,41,43],
            [ 9,11,18,24,31,40,44,53],
            [10,19,23,32,39,45,52,54],
            [20,22,33,38,46,51,55,60],
            [21,34,37,47,50,56,59,61],
            [35,36,48,49,57,58,62,63]  ], dtype = np.int32 )

def shift_round_clip(x):
    y = np.int8(x>>16)
    if x>>15 & 0x1:
        y = y + 1
    if y>63:
        y = 63
    elif y<-63:
        y = -63
    return y

def dct_quant_zig(tile):  # input tile must be (8*8)
    tile = np.matrix(tile, dtype=np.int32)
    zig_vect = np.zeros((64,), dtype=np.int8)
    dct_tile = ( dct_mat * tile * dct_mat.T )
    for i in range(8):
        for j in range(8):
            pos = zig_idxs[i][j]
            quant_level = (1 if pos==0 else pos//16)
            zig_vect[pos] = shift_round_clip( dct_tile[i,j] >> quant_level )
    return zig_vect

def get_code(val):
    absval = val if val>=0 else -val
    length = 0
    while absval:
        absval >>= 1
        length += 1
    code = val if val>=0 else (val-1)
    return length, code

def bit_encoding(stream_writer, zig_vect):
    zero_cnt = 0
    for ii, val in enumerate(zig_vect):
        length, code = get_code(val)
        zero_cnt += 0 if (ii==0 or val!=0) else 1
        if ii==0 or val!=0 or zero_cnt>=16 :
            stream_writer.writebits( zero_cnt&0x0f, 5 )
            stream_writer.writebits( length-1, 3 )
            stream_writer.writebits( code, length )
            zero_cnt = 0
        elif ii==63:
            stream_writer.writebits( 0x0f, 8 )

def jpeg_encoding(img_map):   # img_map must be a 2-dim numpy array, and has a height and width which can divide 8
    h, w = img_map.shape
    JpegStreamWriter = BitstreamWriter()
    JpegStreamWriter.writebytes(b'\xff\xd8\xff\xe0\x00\x10\x4a\x46\x49\x46\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xff\xdb\x00\x43\x00\x10\x08\x08\x08\x08\x08\x08\x08\x08\x08\x08\x08\x08\x08\x08\x08\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\xff\xc0\x00\x0b\x08')
    JpegStreamWriter.writeword(h)
    JpegStreamWriter.writeword(w)
    JpegStreamWriter.writebytes(b'\x01\x01\x11\x00\xff\xc4\x00\xab\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x01\x02\x03\x04\x05\x06\x07\x00\x10\x00\x00\x00\x00\x00\x00\x00\x7f\x00\x00\x00\x00\x00\x00\x00\x00\x01\x02\x03\x04\x05\x06\x07\xf0\x11\x12\x13\x14\x15\x16\x17\x00\x21\x22\x23\x24\x25\x26\x27\x28\x31\x32\x33\x34\x35\x36\x37\x38\x41\x42\x43\x44\x45\x46\x47\x48\x51\x52\x53\x54\x55\x56\x57\x58\x61\x62\x63\x64\x65\x66\x67\x68\x71\x72\x73\x74\x75\x76\x77\x78\x81\x82\x83\x84\x85\x86\x87\x88\x91\x92\x93\x94\x95\x96\x97\x98\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xff\xda\x00\x08\x01\x01\x00\x00\x3f\x00')
    dc_prev = 0
    for yblock in range(0, h, 8):
        for xblock in range(0, w, 8):
            tile = np.array(img_map[yblock:yblock+8,xblock:xblock+8], dtype=np.int32) - 128
            zig_vect = dct_quant_zig(tile)
            zig_vect[0], dc_prev = zig_vect[0] - dc_prev, zig_vect[0]
            bit_encoding(JpegStreamWriter, zig_vect)
    JpegStreamWriter.flush()
    JpegStreamWriter.writebytes(b'\xFF\xD9')
    return JpegStreamWriter.get()



# this main program reads a image file, get its raw pixel map,
# using jpeg_encoding() to compress it to jpeg stream (bytearray type),
# and write it to .jpg file
if __name__ == '__main__':
    
    try:
        jpg_name   = sys.argv[2]                # get output .jpg file name from command line argument 2
        img_object = imgopen(sys.argv[1])       # get input image file name from command line argument 1, and open it as img_object
    except:
        print('  Usage:\n       python %s <input-image-file> <output-jpg-file>' % (sys.argv[0],) )
        exit(-1)
    
    # convert img_object to monochrome (grayscale), if it is not.
    if img_object.mode != 'L':
        print("  warning: input image is not monochrome (grayscale), converting to monochrome...")
        img_object = img_object.convert('L')
    
    # convert img_object to numpy 2-D array
    img_map = np.asarray(img_object)
    
    # 检查输入图片是否满足要求：是2维数组（即灰度图像）
    if img_map.ndim != 2:
        print("  error: image map's dimision must be 2")
    
    # 检查输入图片是否满足要求：每个像素占1字节（即像素深度=256）
    if img_map.dtype != np.uint8:
        print("  error: image depth must be 256")
    
    # 对图像 img_map 进行裁剪，让 width 和 height 都是8的倍数，这是本 JpegEncoder 的要求
    # 虽然 JPEG 算法支持压缩长宽不是8的倍数的图片，但我没有实现
    hraw, wraw = img_map.shape
    hcut, wcut = 8*(hraw//8), 8*(wraw//8)
    if hcut != hraw:
        print("  warning: height is %d, cut to %d" % (hraw, hcut))
    if hcut == 0:
        print("  error: height is cut to 0")
        exit(-1)
    if wcut != wraw:
        print("  warning: width  is %d, cut to %d" % (wraw, wcut))
    if wcut == 0:
        print("  error: width  is cut to 0")
        exit(-1)
    img_map = img_map[:hcut, :wcut]

    # 调用 jpeg_encoding() 进行图像压缩，得到 jpeg_stream （是 bytearray 类型）
    jpeg_stream = jpeg_encoding( img_map )
    
    # 打印压缩率等信息
    print("  origin=%dPixels   jpg-size=%dB   compress-ratio=%.2f" % (hcut*wcut, len(jpeg_stream), hcut*wcut/len(jpeg_stream)) )
    
    # 写入 .jpg 文件
    open(jpg_name, 'wb').write(jpeg_stream)
    