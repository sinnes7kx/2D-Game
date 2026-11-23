#!/usr/bin/env python3
"""Create weapon-length FX guides from *weapon-only* v1.12 source layers.

The existing baked animations are not modified. These guides are in the same
256x220 centered body-local coordinate space as Ghost Girl's sprite frames.
"""
from pathlib import Path
from PIL import Image
import json
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'assets/ghost/weapon_layers_v112'
OUT=ROOT/'resources/long_weapon_glow_axes_v143.json'
W,H=256,220
DIRECTIONS=['front','back','left','right']

def frame_axis(front,back, row, frame):
    bounds=(frame*W,row*H,(frame+1)*W,(row+1)*H)
    a=np.asarray(front.crop(bounds).getchannel('A'))
    b=np.asarray(back.crop(bounds).getchannel('A'))
    alpha=np.maximum(a,b)
    ys,xs=np.where(alpha>40)
    if len(xs)<45:
        raise ValueError(f'Blank weapon-only overlay row={row} frame={frame}')
    pts=np.stack([xs,ys],axis=1).astype('float64')
    weights=alpha[ys,xs].astype('float64')/255.0
    center=np.average(pts,axis=0,weights=weights)
    cov=np.cov((pts-center).T,aweights=weights)
    values,axes=np.linalg.eigh(cov)
    main=axes[:,np.argmax(values)]
    distances=(pts-center)@main
    lo,hi=np.percentile(distances,[10,90])
    if hi-lo < 26:
        raise ValueError(f'Weapon guide too short row={row} frame={frame}: {hi-lo}')
    a0=center+main*lo
    a1=center+main*hi
    # Endpoint orientation is only used for a traveling glint. Always start
    # from the lower/closer end; avoid discontinuous first-frame flips.
    if a0[1]<a1[1]:a0,a1=a1,a0
    return [round(float(a0[0]-W/2),1),round(float(a0[1]-H/2),1),
            round(float(a1[0]-W/2),1),round(float(a1[1]-H/2),1)]

def build():
    data={}
    for style in ['scythe','halberd']:
        for family in ['locomotion','combat']:
            f=Image.open(SOURCE/f'{style}_{family}_front_2048x1760.png').convert('RGBA')
            b=Image.open(SOURCE/f'{style}_{family}_back_2048x1760.png').convert('RGBA')
            if f.size!=(2048,1760) or b.size!=(2048,1760):raise ValueError('Incorrect atlas size')
            for phase in range(2):
                action=('idle' if phase==0 else 'walk') if family=='locomotion' else ('light' if phase==0 else 'heavy')
                for direction_index,face in enumerate(DIRECTIONS):
                    name=f'{style}_{action}_{face}' if family=='locomotion' else f'attack_{style}_{action}_{face}'
                    row=phase*4+direction_index
                    data[name]=[frame_axis(f,b,row,col) for col in range(8)]
    OUT.write_text(json.dumps(data,indent=1)+'\n',encoding='utf8')
    print(f'{len(data)} directional tracks, {sum(len(v) for v in data.values())} guides; {OUT.stat().st_size} bytes')
    return data

if __name__=='__main__':build()
