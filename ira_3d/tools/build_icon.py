"""Generate distinctive IRA 3D Android icons with Python's standard library."""
from pathlib import Path
import struct
import zlib
import math

ROOT = Path(__file__).resolve().parent.parent / "assets"
ROOT.mkdir(parents=True, exist_ok=True)
FONT = {
    "I": ("11111","00100","00100","00100","00100","00100","11111"),
    "R": ("11110","10001","10001","11110","10100","10010","10001"),
    "A": ("01110","10001","10001","11111","10001","10001","10001"),
    "3": ("11110","00001","00001","01110","00001","00001","11110"),
    "D": ("11100","10010","10001","10001","10001","10010","11100"),
}

def create_icon(size, destination):
    data = bytearray(size * size * 4)
    def paint(x,y,color):
        if 0 <= x < size and 0 <= y < size:
            idx = (y*size+x)*4
            data[idx:idx+4] = bytes(color)
    for y in range(size):
        for x in range(size):
            t=y/size
            paint(x,y,(7+int(16*t),17+int(22*t),36+int(18*t),255))
    cx,cy=size//2,int(size*.43)
    for y in range(size):
        for x in range(size):
            r=math.hypot(x-cx,y-cy)
            if abs(r-size*.34) <= size*.016:
                paint(x,y,(75,226,254,255))
            elif abs(r-size*.306) <= size*.008:
                paint(x,y,(255,57,91,255))
    def word(text,y,scale,color):
        w=len(text)*6*scale-scale
        ox=(size-w)//2
        for k,ch in enumerate(text):
            for gy,line in enumerate(FONT[ch]):
                for gx,bit in enumerate(line):
                    if bit=="1":
                        for dy in range(scale):
                            for dx in range(scale):
                                paint(ox+k*6*scale+gx*scale+dx,y+gy*scale+dy,(*color,255))
    word("3D",int(size*.25),max(2,size//49),(245,250,255))
    word("IRA",int(size*.75),max(1,size//104),(255,71,102))
    def chunk(kind,content):
        return struct.pack(">I",len(content))+kind+content+struct.pack(">I",zlib.crc32(kind+content)&0xffffffff)
    raw=b"".join(b"\x00"+data[y*size*4:(y+1)*size*4] for y in range(size))
    png=b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",size,size,8,6,0,0,0))+chunk(b"IDAT",zlib.compress(raw,8))+chunk(b"IEND",b"")
    destination.write_bytes(png)

if __name__ == "__main__":
    create_icon(192,ROOT/"icon_192.png")
    create_icon(432,ROOT/"icon_432.png")
    print("IRA 3D: Android launcher icons ready.")
