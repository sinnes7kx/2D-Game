#!/usr/bin/env python3
"""Baked four-direction bows using approved, hook-clean Ghost Girl frames.
All 256px x 220px frames have their own drawn bow pose. Source character PNGs
are never modified. Two styles, two atlases per style (idle/walk and shooting).
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math, json
ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/'assets/ghost/bows_v126'; ASSETS.mkdir(parents=True,exist_ok=True)
W,H=256,220
locomotion=Image.open(ROOT/'assets/ghost/weapon_body_v111/weapon_ready_locomotion_2048x1760.png').convert('RGBA')
faces=['front','back','left','right']

def limb_art(style, draw_progress=0.0):
    s=3; dim=150*s
    img=Image.new('RGBA',(dim,dim)); d=ImageDraw.Draw(img)
    def pt(x,y): return (int((75+x)*s),int((75+y)*s))
    icy=style=='moonveil'
    shaft=(155,191,223,255) if icy else (145,105,123,255)
    edge=(218,232,252,245) if icy else (240,185,206,245)
    dark=(64,63,92,255) if icy else (86,43,62,255)
    # Taut shimmering bowstring and two curved, asymmetric limbs
    d.line([pt(-1,-52),pt(-6-draw_progress*10,0),pt(-1,52)],fill=(238,232,250,190),width=1*s)
    coords=[]
    for j in range(81):
        t=-1+j/40
        y=52*t
        x=19*math.sin(math.pi*abs(t)) + (2 if t>0 else -2)
        coords.append(pt(x,y))
    d.line(coords,fill=dark,width=7*s,joint='curve')
    d.line(coords,fill=shaft,width=5*s,joint='curve')
    d.line([(a-1*s,b-1*s) for a,b in coords],fill=edge,width=2*s,joint='curve')
    for y in (-49,49):
        d.ellipse((pt(-5,y-4),pt(5,y+4)),fill=dark,outline=edge,width=1*s)
        d.line([pt(-1,y-5),pt(4,y+5)],fill=edge,width=1*s)
    # ornate grip and small spectral gem
    d.rounded_rectangle((*pt(-7,-8),*pt(6,8)),radius=3*s,fill=dark,outline=edge,width=s)
    d.ellipse((*pt(-4,-4),*pt(4,4)),fill=(137,209,248,240) if icy else (201,83,143,240),outline=(249,239,253,255),width=s)
    for y in (-34,34):
        d.ellipse((*pt(12,y-4),*pt(20,y+4)),fill=(174,201,241,210) if icy else (148,77,108,210),outline=edge,width=s)
    if not icy:
        for xx,yy in [(17,-27),(18,27)]:
            for ang in (0,120,240):
                cx=xx+math.cos(math.radians(ang))*5;cy=yy+math.sin(math.radians(ang))*5
                d.ellipse((*pt(cx-4,cy-3),*pt(cx+4,cy+3)),fill=(175,72,107,240),outline=edge,width=s)
    else:
        for x,y in [(-4,-22),(22,22),(20,-26)]:
            d.line([pt(x-4,y),pt(x+4,y),pt(x,y-4),pt(x,y+4)],fill=(197,231,253,190),width=s)
    return img

def overlay(style,face,motion,i):
    idle=motion=='idle';walk=motion=='walk';heavy=motion=='heavy';firing=motion in ('light','heavy')
    # Hand coordinates for the approved 256x220 body poses, keyed by facing and phase
    grip={'front':(155,125),'back':(155,126),'left':(106,124),'right':(154,122)}[face]
    wiggle=(-2,-1,1,3,1,-1,-2,0)[i]
    x,y=grip
    if walk: x+=wiggle; y+=(1 if i%2 else -1)
    if firing:
        x+=(-3,-2,0,2,4,3,0,-2)[i] * (1 if face!='left' else -1)
        y+=(-1,-2,-2,-3,0,2,1,0)[i]
    theta= {'front':-14,'back':13,'left':-7,'right':9}[face]
    if firing:
        swing=(0,4,15,25,54,48,22,3)[i]
        theta+=(-swing if face in ('right','front') else swing)
    elif walk:theta+=(-3,2,0,4,-2,1,-3,2)[i]
    bow=limb_art(style, (1 if i in (2,3) else 0) if firing else 0)
    bow=bow.rotate(theta,resample=Image.Resampling.BICUBIC,expand=False)
    bow=bow.resize((150,150),Image.Resampling.LANCZOS)
    result=Image.new('RGBA',(W,H))
    result.alpha_composite(bow,(int(x-75),int(y-75)))
    return result

def base_frame(face,motion,i):
    if motion in ('idle','walk'):
        row=(0 if motion=='idle' else 4)+faces.index(face)
        return locomotion.crop((W*i,H*row,W*(i+1),H*(row+1)))
    if motion=='light':
        path=ROOT/f'assets/ghost/combat_v14/attack_unarmed_light_{face}_{i:02d}.png'
    else:
        path=ROOT/f'assets/ghost/weapon_combat_body_v110/heavy_{face}_{i:02d}.png'
    return Image.open(path).convert('RGBA')

entries=[]
for style in ('thornrose','moonveil'):
    for phase,motions in [('locomotion',('idle','walk')),('combat',('light','heavy'))]:
        atlas=Image.new('RGBA',(2048,1760))
        for m_idx,motion in enumerate(motions):
            for f_idx,face in enumerate(faces):
                row=m_idx*4+f_idx
                name=f'{style}_{motion}_{face}' if phase=='locomotion' else f'attack_{style}_{motion}_{face}'
                for i in range(8):
                    body=base_frame(face,motion,i)
                    body.alpha_composite(overlay(style,face,motion,i))
                    atlas.alpha_composite(body,(i*W,row*H))
                entries.append({'name':name,'atlas':f'assets/ghost/bows_v126/{style}_{phase}_2048x1760.png','row':row,'frame_count':8,'frame_width':W,'frame_height':H,'speed':8 if motion=='idle' else (12 if motion=='walk' else 14 if motion=='light' else 10),'loop':motion in ('idle','walk')})
        path=ASSETS/f'{style}_{phase}_2048x1760.png';atlas.save(path,optimize=True)
        print(path.relative_to(ROOT), path.stat().st_size)
    # Item icon: Bow artwork on ornate gothic square
    icon=Image.new('RGBA',(160,160),(24,20,32,255));d=ImageDraw.Draw(icon)
    for inset,color in [(3,(185,145,167,255)),(8,(84,70,88,255))]:
        d.rounded_rectangle((inset,inset,159-inset,159-inset),radius=9,outline=color,width=2)
    large=limb_art(style).resize((150,150),Image.Resampling.LANCZOS)
    icon.alpha_composite(large,(5,5));(ASSETS/f'{style}_icon.png').write_bytes(b'') if False else None
    icon.save(ASSETS/f'{style}_icon.png')
(ROOT/'resources/bow_animations_v126.json').write_text(json.dumps(entries,indent=2)+'\n')
# contact sheet for all direction frames
c=Image.new('RGB',(8*160,8*165),(30,26,38))
for r,style in enumerate(('thornrose','moonveil')):
    a=Image.open(ASSETS/f'{style}_locomotion_2048x1760.png').convert('RGBA')
    for n in range(4):
        for j in (0,4):
            img=a.crop((j*W,n*H,(j+1)*W,(n+1)*H));img.thumbnail((155,150))
            x=(n*2+j//4)*160;y=r*4*165
            c.paste(img,(x+int((160-img.width)/2),y+4),img)
c.save('/mnt/data/GhostGirl_v126_Bow_Artwork_Review.jpg',quality=90)
print('Generated',len(entries),'animation tracks')
