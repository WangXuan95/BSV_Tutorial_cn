import sys

txt_filename = sys.argv[1]
jpg_filename = sys.argv[2]

string = open(txt_filename, 'rt').read()

bstring = bytearray()
for i in range(0, len(string), 2):
    bstring += eval("b'\\x" + string[i:i+2] + "'")

open(jpg_filename, 'wb').write(bstring)
