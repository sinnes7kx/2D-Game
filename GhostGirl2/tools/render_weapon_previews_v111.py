#!/usr/bin/env python3
"""Render full-size, padded proof sheets from the EXACT v1.11 Godot manifests.
No original-vs-new source images are mixed in these preview sheets, which
previously made the original rose hook look like it was still in the final art.
"""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/v111_previews';OUT.mkdir(parents=True,exist_ok=True)
W,H=256,220
body={e['name']:e for e in json.loads((ROOT/'resources/ghost_extra_animations.json').read_text())}
layer={e['name']:e for e in json.loads((ROOT/'resources/weapon_layer_manifest.json').read_text())}

def frame_from(entry,i):
    if 'atlas' in entry:
        row=entry['row'];x=i*W;y=row*H
        return Image.open(ROOT/entry['atlas']).convert('RGBA').crop((x,y,x+W,y+H))
    return Image.open(ROOT/entry['textures'][i]).convert('RGBA')

def weapon_frame(entry,i,depth):
    atlas=Image.open(ROOT/entry[f'atlas_{depth}']).convert('RGBA');row=entry['row']
    return atlas.crop((i*W,row*H,(i+1)*W,(row+1)*H))

def compose(name,i):
    e=layer[name];base=frame_from(body[name],i)
    out=Image.new('RGBA',(W,H));out.alpha_composite(weapon_frame(e,i,'back'))
    out.alpha_composite(base);out.alpha_composite(weapon_frame(e,i,'front'))
    return out

def make():
    for style in ('scythe','halberd'):
        names=[f'{style}_idle_front',f'{style}_walk_right',f'attack_{style}_light_front',f'attack_{style}_heavy_right']
        img=Image.new('RGB',(8*(W+20)+20,4*(H+60)+30),(28,24,36))
        d=ImageDraw.Draw(img)
        for row,name in enumerate(names):
            top=24+row*(H+60)
            d.text((22,top-19),name.upper().replace('_',' '),fill=(228,203,216))
            for col in range(8):
                x=20+col*(W+20);y=top+8
                d.rectangle((x,y,x+W,y+H),fill=(43,36,49),outline=(84,70,87),width=1)
                sprite=compose(name,col)
                img.paste(sprite,(x,y),sprite)
                d.text((x+8,y+H+8),f'frame {col+1}/8',fill=(171,156,177))
        out=OUT/f'{style}_full_frame_v111.jpg'
        img.save(out,quality=90)
        print(out, out.stat().st_size)
    # Generate a hook-free gallery from the actual atlas used in-game, not
    # the original (hook-bearing) reference sheets.
    src=Image.open(ROOT/'assets/ghost/weapon_body_v111/weapon_ready_locomotion_2048x1760.png').convert('RGBA')
    gal=Image.new('RGB',(8*(W+18)+18,8*(H+34)+24),(28,24,36))
    d=ImageDraw.Draw(gal)
    order=[f'{m} {f}' for m in ('idle','walk') for f in ('front','back','left','right')]
    for row,label in enumerate(order):
        for col in range(8):
            x=18+col*(W+18);y=12+row*(H+34)
            frame=src.crop((col*W,row*H,(col+1)*W,(row+1)*H))
            gal.paste(frame,(x,y),frame)
            d.text((x+6,y+H+6),f'{label}  {col+1}',fill=(201,183,207))
    out=OUT/'hook_free_all_64_frames_v111.jpg'
    gal.save(out,quality=88)
    print(out, out.stat().st_size)
if __name__=='__main__':make()
