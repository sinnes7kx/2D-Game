#!/usr/bin/env python3
"""Aligned, paletteable bow-only masks (NO character pixels), four atlases.
Used over the baked weapon frames to recolor bows without recoloring Ghost Girl.
"""
from pathlib import Path
from PIL import Image
import numpy as np
import sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
import build_bow_draw_v139 as new
# Reuse the v1.26 *overlay generator* without invoking its top-level atlas
# writer; this preserves the exact original locomotion weapon placement.
source=(ROOT/'tools/build_bows_v126.py').read_text()
prefix=source[:source.index('\nentries=[]')]
namespace={'__file__':str(ROOT/'tools/build_bows_v126.py'),'__name__':'bow_v126_helpers'}
exec(compile(prefix,str(ROOT/'tools/build_bows_v126.py'),'exec'),namespace)
base_overlay=namespace['overlay']
out=new.OUT
for style in ('thornrose','moonveil'):
    for family in ('locomotion','combat'):
        atlas=Image.new('RGBA',(2048,1760))
        for motion_i,motion in enumerate((('idle','walk') if family=='locomotion' else ('light','heavy'))):
            for face_i,face in enumerate(new.FACES):
                row=motion_i*4+face_i
                for i in range(8):
                    art = base_overlay(style,face,motion,i) if family=='locomotion' else new.draw_bow(style,face,i,motion=='heavy')
                    data=np.array(art.convert('RGBA'),dtype=np.uint8)
                    # Grayscale material shading: pixels are isolated weapon
                    # strokes, not a crude mask covering Ghost Girl's dress.
                    luma=(data[:,:,0].astype(np.float32)*.25+data[:,:,1]*.6+data[:,:,2]*.15).clip(0,255).astype(np.uint8)
                    data[:,:,0]=luma;data[:,:,1]=luma;data[:,:,2]=luma
                    atlas.alpha_composite(Image.fromarray(data,'RGBA'),(i*256,row*220))
        target=out/f'{style}_{family}_mask_2048x1760.png'
        atlas.save(target,optimize=True)
        print(target.name,target.stat().st_size)
