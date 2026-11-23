#!/usr/bin/env python3
"""V1.38 first-pass baked bowstring/nock/release clean-up, exact 8x8 frame order.

This preserves approved Ghost Girl body pixels as authored, adjusts an old
inherited melee trail on the release frame, then adds subtle bowstring
keyframes, nocked arrows and release glow across four directional tracks.
It is intentionally a first-pass bow motion refinement, not a new character.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT/'assets/ghost/bows_v126'
OUT = ROOT/'assets/ghost/bows_v138'
W,H=256,220
OUT.mkdir(exist_ok=True,parents=True)
# Hand and bow geometry keyed by direction, all positions local to each cell.
BOUNDS={
    'front':((132,85),(139,157),(132,120),(1,0)),
    'back': ((131,82),(137,158),(132,116),(0,-1)),
    'left': ((121,88),(117,157),(123,118),(-1,0)),
    'right':((127,86),(124,158),(126,119),(1,0)),
}
DIRECTIONS=['front','back','left','right','front','back','left','right']

def crescent_cleanup(rgba, facing, col):
    if col != 4:
        return rgba
    data = np.asarray(rgba).copy()
    rgb = data[:,:,:3].astype(np.int16)
    yy,xx=np.indices((H,W))
    # Restrict this mask to the legacy lilac sword crescent outside the body;
    # never modify the face/hair or the physical bow in the center of the pose.
    r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    purple = (r>108) & (b>145) & (g<145) & (r>g*1.17) & (b>g*1.25)
    xmask = xx>170 if facing in ('front','back','right') else xx<91
    cut=purple & xmask & (yy>65) & (yy<173)
    data[cut,3]=0
    return Image.fromarray(data,'RGBA')

def illustrate(frame, row, col, style):
    face = DIRECTIONS[row]
    upper,lower,grip,aim=BOUNDS[face]
    img=crescent_cleanup(frame,face,col)
    # Paint a small transparent overlay, leaving all character source textures
    # unchanged and the weapon already fused into the correct frame.
    fx=Image.new('RGBA',(W,H))
    dr=ImageDraw.Draw(fx,'RGBA')
    heavy=row>=4
    line=(237,217,255, 54 if face=='back' else 77)
    pux=1 if face!='left' else -1
    # Relative draw tension 0-3, snap and recovery 4-7.
    tension=[0.24,0.46,0.76,1.0,0.16,0.02,0.01,0.05][col]
    pull=(grip[0]-pux*11.0*tension,grip[1]+(5.0*tension if face in ('front','back') else 0.0))
    dr.line([upper,pull,lower],fill=line,width=1)
    if col in (1,2,3):
        # Nock glint and a partially visible arrow before release.
        phase=[0.0,0.45,0.68,1.0,0.0,0.0,0.0,0.0][col]
        dx,dy=aim
        start=(int(pull[0]),int(pull[1]))
        end=(int(start[0]+dx*(19+12*phase)),int(start[1]+dy*(19+12*phase)))
        arrow_ink=(236,201,214, 115) if style=='thornrose' else (193,232,250,125)
        dr.line([start,end],fill=arrow_ink,width=2)
        dr.ellipse((start[0]-2,start[1]-2,start[0]+2,start[1]+2),fill=(247,234,250,84))
    if col in (3,4,5):
        strength=[0,0,0,0.36,0.9,0.24,0,0][col]
        dx,dy=aim
        cx=grip[0]+dx*(17 if col==4 else 9)
        cy=grip[1]+dy*(17 if col==4 else 9)
        main=(250,170,210) if style=='thornrose' else (194,231,253)
        for radius in [4,7,10]:
            a=int(36*strength*(11-radius)/9)
            dr.ellipse((cx-radius,cy-radius,cx+radius,cy+radius),outline=(*main,a),width=1)
        dr.line((cx-4,cy,cx+4,cy),fill=(*main,int(80*strength)),width=1)
    img.alpha_composite(fx)
    return img

for style in ('thornrose','moonveil'):
    original=Image.open(SRC/f'{style}_combat_2048x1760.png').convert('RGBA')
    new=Image.new('RGBA',original.size)
    for row in range(8):
        for col in range(8):
            source_col=5 if col==4 else col
            frame=original.crop((source_col*W,row*H,(source_col+1)*W,(row+1)*H))
            # The original fourth release frame has an inseparable MELEE
            # crescent painted across the bow. Reuse its neighboring clean
            # authored recovery pose with a small keyed tilt, then add the
            # separate bowstring snap/glow; never crop the approved face.
            if col==4:
                frame=frame.rotate(-2.8 if row % 4 in (0,3) else 2.8, Image.Resampling.BICUBIC, expand=False, center=(128,124))
            new.alpha_composite(illustrate(frame,row,col,style),(col*W,row*H))
    target=OUT/f'{style}_combat_2048x1760.png'
    new.save(target,optimize=True)
    print(target.name,target.stat().st_size)
# Build readable contact sheet with equal cell heights / no accidental crop.
preview=Image.new('RGB',(8*180+20,4*200+20),(25,21,31))
for row,(style,track) in enumerate([('thornrose',0),('thornrose',4),('moonveil',2),('moonveil',6)]):
    atlas=Image.open(OUT/f'{style}_combat_2048x1760.png').convert('RGBA')
    for i in range(8):
        cut=atlas.crop((i*W,track*H,(i+1)*W,(track+1)*H))
        cut.thumbnail((176,180),Image.Resampling.LANCZOS)
        x=10+i*180; y=10+row*200
        preview.paste(cut,(x+(180-cut.width)//2,y),cut)
preview.save(ROOT/'docs/v138_bow_combat_review.jpg',quality=92)
print('contact sheet ready')
