#!/usr/bin/env python3
"""Create visible frame-composited long-weapon animations from existing approved sources.

Each pixel-aligned 256x220 frame is: back weapon -> clean Ghost Girl -> front weapon.
These atlases replace invisible / state-sensitive runtime attachment layers; FX remain
independent and item-colored.  Original source assets are left untouched.
"""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'assets/ghost/weapon_baked_v122'
PREV = ROOT / 'docs/v122_previews'
DEST.mkdir(parents=True, exist_ok=True)
PREV.mkdir(parents=True, exist_ok=True)
ANIMS = {e['name']: e for e in json.loads((ROOT/'resources/ghost_extra_animations.json').read_text())}
WEAPONS = {e['name']: e for e in json.loads((ROOT/'resources/weapon_layer_manifest.json').read_text())}
W,H=256,220
bodies = {}
atlases = {}

def source_frame(name, frame):
    spec = ANIMS[name]
    if 'atlas' in spec:
        key = spec['atlas']
        if key not in bodies:
            bodies[key] = Image.open(ROOT/key).convert('RGBA')
        row = int(spec['row'])
        return bodies[key].crop((frame*W,row*H,(frame+1)*W,(row+1)*H))
    return Image.open(ROOT/spec['textures'][frame]).convert('RGBA')

def weapon_part(spec,side,frame):
    key=spec['atlas_'+side]
    if key not in atlases:
        atlases[key] = Image.open(ROOT/key).convert('RGBA')
    row=int(spec['row'])
    return atlases[key].crop((frame*W,row*H,(frame+1)*W,(row+1)*H))

def build():
    for style in ('scythe','halberd'):
        for family in ('locomotion','combat'):
            names = [e['name'] for e in json.loads((ROOT/'resources/weapon_layer_manifest.json').read_text())
                     if (e['name'].startswith('attack_'+style+'_') if family=='combat' else e['name'].startswith(style+'_'))]
            assert len(names)==8,(style, family, names)
            canvas=Image.new('RGBA',(8*W,8*H))
            for row,name in enumerate(names):
                for i in range(8):
                    body=source_frame(name,i)
                    behind=weapon_part(WEAPONS[name],'back',i)
                    above=weapon_part(WEAPONS[name],'front',i)
                    assert body.size==behind.size==above.size==(W,H)
                    assert behind.getbbox() or above.getbbox(), f'No weapon pixels in {name} frame {i}'
                    fused=Image.alpha_composite(Image.alpha_composite(behind,body),above)
                    canvas.alpha_composite(fused,(i*W,row*H))
            target=DEST/f'{style}_{family}_2048x1760.png'
            canvas.save(target,optimize=True)
            print(target.relative_to(ROOT),f'{target.stat().st_size//1024} KiB')
        # Preview: 8 rows of clean combined frames, labelled with the animation and frame number.
        sheet=Image.new('RGB',(8*(W+10)+10,16*(H+34)+10),(24,19,30))
        draw=ImageDraw.Draw(sheet)
        for family,base_row in [('locomotion',0),('combat',8)]:
            atlas=Image.open(DEST/f'{style}_{family}_2048x1760.png').convert('RGBA')
            names=[e['name'] for e in json.loads((ROOT/'resources/weapon_layer_manifest.json').read_text())
                   if (e['name'].startswith('attack_'+style+'_') if family=='combat' else e['name'].startswith(style+'_'))]
            for row,name in enumerate(names):
                y=10+(base_row+row)*(H+34)
                draw.text((15,y+2),name,fill=(215,177,206))
                for f in range(8):
                    x=10+f*(W+10)
                    piece=atlas.crop((f*W,row*H,(f+1)*W,(row+1)*H))
                    sheet.paste(piece,(x,y+21),piece)
        out=PREV/f'{style}_all_128_frames.jpg'
        sheet.save(out,quality=88,optimize=True)
        print(out.relative_to(ROOT))

if __name__=='__main__': build()
