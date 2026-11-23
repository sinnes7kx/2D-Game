"""Original illustrated atlas pass for Ghost Girl's two moor enemy families.
Four authored poses each; no existing character or room artwork is modified.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math, random

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/enemies'
OUT.mkdir(parents=True,exist_ok=True)
S=3; SIZE=256

def tint(hexcode,alpha=255):
    c=tuple(bytes.fromhex(hexcode.lstrip('#')))
    return (*c,alpha)

def line(draw,coords,fill,width=1,joint='curve'):
    draw.line([(int(x*S),int(y*S)) for x,y in coords],fill=fill,width=max(1,int(width*S)),joint=joint)

def oval(draw,bounds,fill,outline=None,width=1):
    x0,y0,x1,y1=bounds
    draw.ellipse((x0*S,y0*S,x1*S,y1*S), fill=fill,outline=outline,width=max(1,int(width*S)))

def polygon(draw,coords,fill,outline=None):
    draw.polygon([(int(x*S),int(y*S)) for x,y in coords],fill=fill)
    if outline: line(draw,coords+[coords[0]],outline,1.4)

def curve(draw,p0,p1,p2,p3,fill,width=1):
    points=[]
    for n in range(31):
        t=n/30; u=1-t
        x=u**3*p0[0]+3*u*u*t*p1[0]+3*u*t*t*p2[0]+t**3*p3[0]
        y=u**3*p0[1]+3*u*u*t*p1[1]+3*u*t*t*p2[1]+t**3*p3[1]
        points.append((x,y))
    line(draw,points,fill,width)

def moth(frame):
    rng=random.Random(513+frame)
    im=Image.new('RGBA',(SIZE*S,SIZE*S)); d=ImageDraw.Draw(im,'RGBA')
    center=(128,126+[-2,1,2,-1][frame]); cy=center[1]
    flap=[0,-9,3,9][frame]
    # Undershadow and luminous dust are painted in the atlas, not hitboxes.
    oval(d,(80,181,176,206),tint('#25182c',64))
    for sign in (-1,1):
        # Four individually traced velvet wings: tapered silhouette and double veining.
        wing=[(128,cy-13),(128+sign*24,cy-50+flap),(128+sign*81,cy-100+flap),
              (128+sign*103,cy-72+flap),(128+sign*95,cy-30+flap),(128+sign*66,cy-2),(128+sign*13,cy+16)]
        polygon(d,wing,tint('#766780',226),tint('#c4b7d4',195))
        smaller=[(128,cy+6),(128+sign*63,cy-8),(128+sign*81,cy+19+flap/2),
                 (128+sign*60,cy+52),(128+sign*24,cy+41)]
        polygon(d,smaller,tint('#665b7c',231),tint('#c8b7ce',181))
        curve(d,(128,cy-3),(128+sign*59,cy-28),(128+sign*80,cy-55+flap),(128+sign*89,cy-70+flap),tint('#e4d4df',215),2)
        for k in range(4):
            yf=cy-43+12*k
            curve(d,(128+sign*18,cy-4),(128+sign*42,yf),(128+sign*75,yf-10),(128+sign*84,yf-15+flap),tint('#b9a6ce',140),0.9)
        for k in range(5):
            ox=128+sign*(44+11*k)
            oy=cy-22+int(8*math.sin(k*1.6))+flap/2
            oval(d,(ox-2.0,oy-2,ox+2,oy+2),tint('#e9d5e5',180))
        for k in range(3):
            ox=128+sign*(50+10*k); oy=cy+12+6*k
            oval(d,(ox-2.5,oy-2.5,ox+2.5,oy+2.5),tint('#cdbbd9',130))
    # Rose-petal thorax, lace collar, pale face and haunted eyes.
    oval(d,(117,cy-28,139,cy+34),tint('#b3a0bb',239),tint('#e0cbdc',208),2)
    oval(d,(110,cy-35,146,cy-3),tint('#bcaec2',245),tint('#eee0e8',226),1.6)
    for s in (-1,1):
        oval(d,(128+s*7-5,cy-25,128+s*7+5,cy-12),tint('#17131d',255))
        curve(d,(128+s*7,cy-32),(128+s*9,cy-45),(128+s*18,cy-52),(128+s*25,cy-51),tint('#c9b9d0',200),1.2)
    for k in range(5):
        theta=math.pi*2*k/5
        ox=128+math.cos(theta)*7; oy=cy+9+math.sin(theta)*5
        oval(d,(ox-3,oy-3,ox+3,oy+3),tint('#8d607e',190))
    oval(d,(125,cy+6,131,cy+13),tint('#f1dce9',240))
    # Fine astral dust for silhouette interest.
    for k in range(16):
        angle=rng.uniform(0,math.tau); rad=rng.uniform(60,112)
        x=128+rad*math.cos(angle); y=cy+rad*math.sin(angle)*0.6
        oval(d,(x-1,y-1,x+1,y+1),tint('#d5b9ee',rng.randrange(45,130)))
    glow=Image.new('RGBA',im.size); gd=ImageDraw.Draw(glow,'RGBA')
    oval(gd,(102,cy-52,154,cy+15),tint('#b89ce4',55))
    glow=glow.filter(ImageFilter.GaussianBlur(12*S))
    im=Image.alpha_composite(glow,im)
    return im.resize((SIZE,SIZE),Image.Resampling.LANCZOS)

def lantern(frame):
    im=Image.new('RGBA',(SIZE*S,SIZE*S)); d=ImageDraw.Draw(im,'RGBA')
    y=11*math.sin(frame*math.pi/2)
    cy=119+y
    oval(d,(69,199,189,211),tint('#201a22',85))
    # Ghostly cloth drapes, dull etched iron, hanging thorns.
    for s in (-1,1):
        polygon(d,[(128+s*17,cy-15),(128+s*31,cy+8),(128+s*40,cy+60),(128+s*26,cy+56),(128+s*9,cy+12)],tint('#5d626f',154),tint('#9397a0',100))
        curve(d,(128+s*19,cy),(128+s*46,cy+20),(128+s*34,cy+63),(128+s*52,cy+75),tint('#b8a5bd',169),2)
        for k in range(3):
            x=128+s*(35+9*k); yy=cy+44+k*6
            oval(d,(x-3,yy-3,x+3,yy+3),tint('#9e708c',170))
    # Brass lantern cap, gothic arched housing, foot.
    polygon(d,[(87,cy-43),(109,cy-64),(148,cy-64),(169,cy-43),(161,cy+40),(150,cy+52),(105,cy+52),(94,cy+40)],tint('#242832',247),tint('#c0acb4',230))
    polygon(d,[(103,cy-50),(112,cy-62),(145,cy-62),(153,cy-50)],tint('#7e6b77',245),tint('#d7c2bd',215))
    oval(d,(119,cy-78,136,cy-62),tint('#b8a1b0',235),tint('#ebd1d3',200),2)
    line(d,[(128,cy-76),(128,cy-91),(136,cy-97)],tint('#d3b6cc',209),2)
    for s in (-1,1):
        line(d,[(128+s*31,cy-46),(128+s*31,cy+34)],tint('#c2a4b7',245),3)
        curve(d,(128+s*31,cy-42),(128+s*7,cy-25),(128+s*7,cy+29),(128+s*30,cy+31),tint('#8d8296',220),2.0)
        polygon(d,[(128+s*29,cy+44),(128+s*37,cy+35),(128+s*18,cy+35)],tint('#a3889b',229))
    # Inner green-blue flame, rising translucent ghost smoke.
    for r,a in [(51,29),(40,49),(26,70)]:
        oval(d,(128-r*0.62,cy-r*0.82,128+r*0.62,cy+r*0.82),tint('#89e3d3',a))
    flame=[(128,cy-44),(143,cy-10),(139,cy+24),(129,cy+37),(118,cy+27),(112,cy+3)]
    polygon(d,flame,tint('#7ac9b9',185),tint('#ddf8db',200))
    polygon(d,[(128,cy-29),(135,cy+2),(130,cy+22),(124,cy+16),(123,cy-3)],tint('#ecffe8',209))
    for k in range(8):
        a=math.tau*k/8+frame*0.15; r=43+8*math.sin(k)
        x=128+math.cos(a)*r; yy=cy+math.sin(a)*r*0.9
        oval(d,(x-2,yy-2,x+2,yy+2),tint('#c6dbe0',120+k*11))
    # High quality halo built under opaque linework.
    halo=Image.new('RGBA',im.size); hd=ImageDraw.Draw(halo,'RGBA')
    oval(hd,(82,cy-74,174,cy+62),tint('#72d9ca',54))
    halo=halo.filter(ImageFilter.GaussianBlur(12*S))
    im=Image.alpha_composite(halo,im)
    return im.resize((SIZE,SIZE),Image.Resampling.LANCZOS)

if __name__=='__main__':
    for kind,fn in [('hush_moth',moth),('gloom_lantern',lantern)]:
        atlas=Image.new('RGBA',(SIZE*4,SIZE))
        for frame in range(4): atlas.alpha_composite(fn(frame),(SIZE*frame,0))
        path=OUT/f'{kind}_v130_4frames.png'
        atlas.save(path,optimize=True)
        print(path,atlas.size,path.stat().st_size)
