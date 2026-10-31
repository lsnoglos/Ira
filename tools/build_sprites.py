"""Extract sprite frames from the commissioned character sheets.
Run with: python tools/build_sprites.py --source /path/to/conversation/images
Requires Pillow and numpy. Keep original source illustrations outside version control if desired.
"""
from pathlib import Path
from PIL import Image, ImageFilter
import numpy as np
import argparse

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'sprites'
OUT.mkdir(parents=True,exist_ok=True)

def cut(image, box, kind, outname, target_height=168):
    im=image.crop(tuple(int(round(v)) for v in box)).convert('RGB')
    a=np.asarray(im).astype(np.int16)
    r,g,b=a[:,:,0],a[:,:,1],a[:,:,2]
    mx=np.max(a,axis=2); mn=np.min(a,axis=2)
    if kind=='hero':
        # The source sheet is charcoal gray; preserve metal, shadows and vivid energy.
        # Perimeter background is neutral, near 70RGB. Foreground red/white/black.
        color=np.maximum.reduce([abs(r-69),abs(g-72),abs(b-77)])
        red=(r>g+14)&(r>b+13)
        foreground=((mx>108)|(mn<42)|red|((color>24)&(mx>98)))
    else:
        # Civilian and enemy sheets have pale neutral panels.
        red=(r>g+20)&(r>b+17)
        chroma=mx-mn
        foreground=((mn<155)|(chroma>24)|red)&~((mn>224)&(chroma<14))
    # Eliminate isolated background remnants, preserve primary connected shapes.
    mask=(foreground.astype(np.uint8)*255)
    from PIL import Image
    alpha=Image.fromarray(mask,'L').filter(ImageFilter.MedianFilter(3)).filter(ImageFilter.GaussianBlur(.65))
    alpha_np=np.asarray(alpha)
    # Restrict to major area by retaining components; also keep nearby energy particles.
    try:
        import cv2
        cnt=(alpha_np>60).astype('uint8')
        n,l,stats,cent=cv2.connectedComponentsWithStats(cnt,8)
        areas=stats[1:,4] if n>1 else []
        if len(areas):
            lead=1+int(np.argmax(areas))
            lead_stats=stats[lead]
            # can include secondary red particles, provided adjacent to lead area
            kept=np.zeros_like(cnt)
            kept[l==lead]=1
            for j in range(1,n):
                if j==lead:continue
                if stats[j,4]>20:
                    ax,ay,aw,ah,_=stats[j]
                    lx,ly,lw,lh,_=lead_stats
                    if ax < lx+lw+85 and ax+aw >lx-85 and ay <ly+lh+45 and ay+ah>ly-45:
                        kept[l==j]=1
            alpha_np=np.minimum(alpha_np,(kept*255).astype('uint8'))
    except ImportError:
        pass
    pix=np.asarray(im).copy()
    rgba=np.dstack((pix,alpha_np.astype(np.uint8)))
    im=Image.fromarray(rgba,'RGBA')
    bb=im.getbbox()
    if bb:
        im=im.crop(bb)
    if im.height<1:return
    nw=max(1,round(im.width*target_height/im.height))
    if nw>340:
        nw=340
        target_height=max(1,round(im.height*nw/im.width))
    im=im.resize((nw,target_height),Image.Resampling.LANCZOS)
    im.save(OUT/outname,optimize=True)

def generate(source):
    hero=Image.open(source/'hoja_de_sprites_del_guerrero_biomecánico.png')
    source_rows={
        'idle':(0,160,6),
        'run':(161,321,8),
        'jump':(328,482,6),
        'attack':(485,640,6),
        'hurt':(642,779,4),
        'lead':(781,933,4),
    }
    for name,(y0,y1,count) in source_rows.items():
        xmin=198
        span=(hero.width-xmin)/count
        for k in range(count):
            left=xmin+span*k+7
            right=xmin+span*(k+1)-7
            cut(hero,(left,y0+3,right,y1-3),'hero',f'hero_{name}_{k}.png',180)

    enemy=Image.open(source/'hoja_de_sprites_de_enemigos_emocionales.png')
    for name,(y0,y1) in dict(sadness=(0,150),anger=(154,296),rage=(300,446),exhaustion=(450,599),anxiety=(604,753),burnout=(757,914)).items():
        xmin=276; count=11; span=(enemy.width-xmin)/count
        for k in range(count):
            cut(enemy,(xmin+span*k+3,y0+8,xmin+span*(k+1)-3,y1-5),'friend',f'enemy_{name}_{k}.png',172 if name!='rage' else 197)
    civilian=Image.open(source/'hoja_de_sprites_de_civiles_rescatados.png')
    cols={'civilian':(20,402),'mother':(422,808),'student':(829,1227),'elder':(1244,1659)}
    rows={'idle':(60,271,4),'walk':(296,479,6),'fear':(501,696,4),'safe':(714,916,4)}
    for who,(x0,x1) in cols.items():
        for anim,(y0,y1,count) in rows.items():
            span=(x1-x0)/count
            for k in range(count):
                cut(civilian,(x0+span*k+3,y0+3,x0+span*(k+1)-3,y1-4),'friend',f'ally_{who}_{anim}_{k}.png',168)
    print('Created',len(list(OUT.glob('*.png'))),'frames;',round(sum(x.stat().st_size for x in OUT.glob('*.png'))/1024),'KiB')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--source',type=Path,default=Path('/mnt/data'));a=parser.parse_args()
    generate(a.source)
