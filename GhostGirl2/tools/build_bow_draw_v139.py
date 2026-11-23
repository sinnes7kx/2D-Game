#!/usr/bin/env python3
"""Make bow-specific READY -> NOCK -> PULL -> FULL DRAW -> HOLD -> RELEASE frames.

No melee crescent, no inherited baked bow. Uses approved clean character
frames and draws bows/strings frame-by-frame in a consistent 256x220 grid.
The bow is placed beside the reaching hand rather than at her hip.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math, json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/ghost/bows_v139'
OUT.mkdir(parents=True,exist_ok=True)
W,H,S=256,220,3
FACES=['front','back','left','right']
# Bow sits at the extended hand. In the side profiles the bow is beyond the
# face/hand and the arrow draws backwards towards Ghost Girl's shoulder.
GRIP={'front':(166,115),'back':(163,113),'left':(77,116),'right':(179,116)}
DIRECTION={'front':1,'back':1,'left':-1,'right':1}
BODY_STAGES_HEAVY=[0,1,2,3,3,3,5,6]
BODY_STAGES_LIGHT=[0,1,2,3,5,6,6,7]
CHARGE_HEAVY=[0.0,0.17,0.44,0.77,1.0,1.0,0.0,0.0]
CHARGE_LIGHT=[0.0,0.28,0.73,1.0,0.0,0.0,0.0,0.0]


def body_frame(face,stage):
    p=ROOT/f'assets/ghost/combat_v14/attack_unarmed_light_{face}_{stage:02}.png'
    return Image.open(p).convert('RGBA')


def draw_bow(style, face, col, heavy):
    x0,y0=GRIP[face]
    # Stage 3-5 is an honest full draw, not an automated release.
    progress=(CHARGE_HEAVY if heavy else CHARGE_LIGHT)[col]
    prepared = col <= (5 if heavy else 3)
    direction=DIRECTION[face]
    base=(185,122,155,255) if style=='thornrose' else (157,203,228,255)
    shade=(69,35,64,255) if style=='thornrose' else (52,73,92,255)
    edge=(244,207,225,255) if style=='thornrose' else (217,243,250,255)
    glow=(242,157,204,190) if style=='thornrose' else (150,218,251,190)
    overlay=Image.new('RGBA',(W*S,H*S))
    d=ImageDraw.Draw(overlay,'RGBA')
    def pt(x,y): return (round(x*S),round(y*S))
    sway=math.sin(col*.85)*1.0
    # Large straight silhouette, vertical in front/back, with a modest
    # forward tilt for left/right to match the character's side perspective.
    ytop=y0-40; ybot=y0+41
    top=(x0-5*direction,ytop)
    bot=(x0-4*direction,ybot)
    grip=(x0+13*direction,y0+sway)
    # two tapered, arched limbs with a waist-width grip
    points=[]
    for i in range(49):
        t=i/48
        y=ytop+(y0-ytop)*t
        x=top[0]+(grip[0]-top[0])*(t**.75) + direction*5.5*math.sin(math.pi*t)
        points.append(pt(x,y))
    for i in range(1,49):
        t=i/48
        y=y0+(ybot-y0)*t
        x=grip[0]+(bot[0]-grip[0])*(t**.8)+direction*5*math.sin(math.pi*t)
        points.append(pt(x,y))
    d.line(points,fill=shade,width=8*S,joint='curve')
    d.line(points,fill=base,width=5*S,joint='curve')
    d.line([(x-direction*S,y-S) for x,y in points],fill=edge,width=2*S,joint='curve')
    d.ellipse((*pt(grip[0]-5,grip[1]-6),*pt(grip[0]+5,grip[1]+6)),fill=shade,outline=edge,width=2*S)
    d.ellipse((*pt(grip[0]-3,grip[1]-3),*pt(grip[0]+3,grip[1]+3)),fill=glow)
    for tip in (top,bot):
        d.ellipse((*pt(tip[0]-3,tip[1]-3),*pt(tip[0]+3,tip[1]+3)),fill=edge)
    # Draw point is pulled toward the chest while the bow is held out in the
    # other hand. At full tension the string stays there until input release.
    rest_x=x0-5*direction
    draw_x=rest_x-direction*(31*progress)
    nock=(draw_x,y0+1.5)
    string=(227,226,243,193)
    d.line([pt(*top),pt(*nock),pt(*bot)],fill=string,width=S)
    if prepared and progress>.08:
        # A single actual nocked arrow; extras belong to the projectile FX,
        # never to the hands or collision logic.
        start=(nock[0],nock[1])
        end=(nock[0]+direction*73,nock[1]-2)
        d.line([pt(*start),pt(*end)],fill=(204,190,194,215),width=2*S)
        d.line([pt(end[0]-direction*9,end[1]-3),pt(*end),pt(end[0]-direction*9,end[1]+3)],fill=edge,width=2*S)
        d.ellipse((*pt(nock[0]-2,nock[1]-2),*pt(nock[0]+2,nock[1]+2)),fill=glow)
        for sign in [-1,1]:
            y=nock[1]+sign*2.5
            d.line([pt(nock[0]-direction*7,y),pt(nock[0]-direction*14,y+sign*3)],fill=base,width=S)
    if col==6:
        d.arc((*pt(x0-16,y0-19),*pt(x0+27,y0+20)),start=210,end=320,fill=glow,width=2*S)
    # Subtle decorative knot/rose motif, NOT a full flaming VFX baked into the
    # character sprite. Those glows are generated from saved item seeds.
    for off in (-29,29):
        yy=y0+off
        d.ellipse((*pt(x0+8*direction-3,yy-3),*pt(x0+8*direction+3,yy+3)),fill=glow)
    return overlay.resize((W,H),Image.Resampling.LANCZOS)


def build():
    for style in ['thornrose','moonveil']:
        atlas=Image.new('RGBA',(2048,1760))
        for move,heavy in [('light',False),('heavy',True)]:
            for fi,face in enumerate(FACES):
                row=fi+(4 if heavy else 0)
                for col in range(8):
                    stage=(BODY_STAGES_HEAVY if heavy else BODY_STAGES_LIGHT)[col]
                    frame=body_frame(face,stage)
                    frame.alpha_composite(draw_bow(style,face,col,heavy))
                    atlas.alpha_composite(frame,(col*W,row*H))
        out=OUT/f'{style}_combat_2048x1760.png'
        atlas.save(out,optimize=True)
        print(out.name,out.stat().st_size)
    preview=Image.new('RGB',(8*170,4*190),(26,22,32))
    for r,(style,face,heavy) in enumerate([('thornrose','front',True),('thornrose','right',True),('moonveil','left',True),('moonveil','front',False)]):
        atlas=Image.open(OUT/f'{style}_combat_2048x1760.png')
        row=FACES.index(face)+(4 if heavy else 0)
        for col in range(8):
            cut=atlas.crop((col*W,row*H,(col+1)*W,(row+1)*H))
            cut.thumbnail((166,178),Image.Resampling.LANCZOS)
            x=col*170+(170-cut.width)//2;y=r*190
            preview.paste(cut,(x,y),cut)
    preview.save('/mnt/data/GhostGirl_v139_Bow_Draw_Review.jpg',quality=94)
if __name__=='__main__':build()
