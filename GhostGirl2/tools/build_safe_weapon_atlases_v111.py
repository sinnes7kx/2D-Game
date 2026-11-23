#!/usr/bin/env python3
"""Build frame-safe 8x8 weapon overlays, retaining the original keyed grip positions.

The v1.9 transform rendered straight into 256x220 cells, silently clipping the
halberd on multiple light-attack poses. We first rasterize a larger temporary
canvas, fit the entire master art around its GRIP, then export both planes.
No character pixels or approved source images are modified.
"""
from pathlib import Path
import sys
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
import generate_weapon_overlays as original
OUT=ROOT/'assets/ghost/weapon_layers_v111'
W,H=256,220
MARGIN=4

def fit_pose(master:Image.Image,grip,tip,pose):
    gx,gy,tx,ty=pose
    for ratio in [1.0-i*0.02 for i in range(31)]:
        candidate=(gx,gy,gx+(tx-gx)*ratio,gy+(ty-gy)*ratio)
        # Rasterize into a 768x660 full canvas with the GRIP translated to its
        # natural original cell coordinates + one full cell in both directions.
        # original.render uses 256x220 so it would clip before we could test:
        # instead use exact inverse affine to rasterize to 3x the cell size.
        ux,uy=tip[0]-grip[0],tip[1]-grip[1]
        vx,vy=candidate[2]-gx,candidate[3]-gy
        ll=ux*ux+uy*uy
        a=(ux*vx+uy*vy)/ll;b=(ux*vy-uy*vx)/ll
        den=a*a+b*b
        ia=a/den;ib=-b/den
        x=gx+W;y=gy+H
        matrix=(ia,-ib,grip[0]-ia*x+ib*y,ib,ia,grip[1]-ib*x-ia*y)
        expanded=master.transform((3*W,3*H),Image.Transform.AFFINE,matrix,Image.Resampling.BICUBIC)
        rgba=np.asarray(expanded)
        yy,xx=np.where(rgba[:,:,3]>10)
        if len(xx)==0:
            continue
        box=(int(xx.min()-W),int(yy.min()-H),int(xx.max()-W),int(yy.max()-H))
        if box[0]>=MARGIN and box[1]>=MARGIN and box[2]<(W-MARGIN) and box[3]<(H-MARGIN):
            return candidate,ratio,box
    raise ValueError(f'Cannot safely fit grip/frame: {pose}, last box {box}')

def build():
    OUT.mkdir(exist_ok=True,parents=True)
    audit=[]
    for style in ('scythe','halberd'):
        master,grip,tip=original.source_master(style)
        for family,rows in original.ROWS.items():
            atlases={depth:Image.new('RGBA',(8*W,8*H)) for depth in ('back','front')}
            for row,key in enumerate(rows):
                split=0.60 if key.endswith('back') else (0.22 if family=='combat' else 0.33)
                rear,front=original.weapon_layers(master,grip,tip,split)
                for col,pose in enumerate(original.POSES[key]):
                    if style=='halberd':
                        gx,gy,tx,ty=pose
                        pose=(gx,gy+1,gx+(tx-gx)*1.08,gy+1+(ty-gy)*1.08)
                    safe,scale,bbox=fit_pose(master,grip,tip,pose)
                    for depth,piece in (('back',rear),('front',front)):
                        rendered=original.render(piece,grip,tip,safe)
                        # Lanczos/Bicubic can create imperceptible alpha specks
                        # just outside a thresholded shape. Clear four-pixel
                        # gutters to prevent frame-to-frame atlas bleeding.
                        pixels=np.asarray(rendered).copy()
                        pixels[:MARGIN,:,:]=0;pixels[-MARGIN:,:,:]=0
                        pixels[:,:MARGIN,:]=0;pixels[:,-MARGIN:,:]=0
                        rendered=Image.fromarray(pixels,'RGBA')
                        a=np.asarray(rendered)
                        assert not np.any(a[:MARGIN,:,3]>10)
                        assert not np.any(a[-MARGIN:,:,3]>10)
                        assert not np.any(a[:,:MARGIN,3]>10)
                        assert not np.any(a[:,-MARGIN:,3]>10)
                        atlases[depth].alpha_composite(rendered,(col*W,row*H))
                    audit.append({'style':style,'family':family,'track':key,'frame':col,'safe_scale':round(scale,3),'bbox':bbox})
            for depth,img in atlases.items():
                target=OUT/f'{style}_{family}_{depth}_2048x1760.png'
                img.save(target,optimize=True)
                assert Image.open(target).size==(2048,1760)
                print('Created',target.relative_to(ROOT),target.stat().st_size)
    import json
    (ROOT/'docs/V111_SAFE_ATLAS_AUDIT.json').write_text(json.dumps(audit,indent=2))
    print('Frames validated',len(audit),'minimum authored scaling',min(x['safe_scale'] for x in audit))
if __name__=='__main__':build()
