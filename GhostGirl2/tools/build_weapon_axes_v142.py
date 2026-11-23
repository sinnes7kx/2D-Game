#!/usr/bin/env python3
"""Extract frame-specific bow silhouettes from existing, approved bow-only masks.

The four 2048x1760 source atlases are untouched. This utility derives a
conservative short major axis through the painted bow for 256 in-game frames.
No source character pixels are modified or generated.
"""
from pathlib import Path
from PIL import Image
import json
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
MASKS=ROOT/'assets/ghost/bows_v139'
OUT=ROOT/'resources/weapon_glow_axes_v142.json'
DIRECTIONS=['front','back','left','right']
WIDTH=256
HEIGHT=220

def frame_axis(rgba):
    alpha=np.asarray(rgba.getchannel('A'),dtype=np.uint8)
    ys,xs=np.where(alpha>32)
    if len(xs)<20:
        raise ValueError('Bow mask missing or too faint in frame')
    points=np.stack((xs,ys),axis=1).astype('float64')
    weights=alpha[ys,xs].astype('float64')/255.0
    center=np.average(points,axis=0,weights=weights)
    centered=points-center
    cov=np.cov(centered.T,aweights=weights)
    vals,vecs=np.linalg.eigh(cov)
    axis=vecs[:,np.argmax(vals)]
    values=centered@axis
    low,high=np.percentile(values,(8,92))
    p0=center+axis*low
    p1=center+axis*high
    if p0[1]>p1[1]:
        p0,p1=p1,p0
    dist=np.linalg.norm(p1-p0)
    if dist<12 or dist>160:
        raise ValueError(f'Suspicious bow-axis length: {dist:.2f}')
    # The sprite texture is centered, so the guide is in body-local pixels.
    return [round(float(p0[0]-WIDTH/2),1),round(float(p0[1]-HEIGHT/2),1),round(float(p1[0]-WIDTH/2),1),round(float(p1[1]-HEIGHT/2),1)]

def generate():
    tracks={}
    for style in ('thornrose','moonveil'):
        for family in ('locomotion','combat'):
            image=Image.open(MASKS/f'{style}_{family}_mask_2048x1760.png').convert('RGBA')
            assert image.size==(2048,1760)
            for phase in range(2):
                action=('idle' if phase==0 else 'walk') if family=='locomotion' else ('light' if phase==0 else 'heavy')
                for facing,direction in enumerate(DIRECTIONS):
                    row=phase*4+facing
                    name=f'{style}_{action}_{direction}' if family=='locomotion' else f'attack_{style}_{action}_{direction}'
                    poses=[]
                    for col in range(8):
                        tile=image.crop((col*WIDTH,row*HEIGHT,(col+1)*WIDTH,(row+1)*HEIGHT))
                        poses.append(frame_axis(tile))
                    tracks[name]=poses
    OUT.write_text(json.dumps(tracks,indent=1)+'\n',encoding='utf8')
    print(f'{len(tracks)} animation tracks; {sum(map(len,tracks.values()))} frame guides; {OUT.stat().st_size} bytes')

if __name__=='__main__':
    generate()
