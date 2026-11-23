#!/usr/bin/env python3
"""Generate reproducible, hand-keyed per-frame weapon layers from v1.6 art.

All poses are authored in 256x220 *character sheet* coordinates, then rasterized
into eight-frame rows. No weapon attachment offset is applied at runtime.

Required inputs: the approved core body frames and the two original v1.6
composite atlases. Outputs are transparent weapon-only 2048x1760 front/back
atlases. The original body sprites are never modified.
"""
from __future__ import annotations
from pathlib import Path
from PIL import Image
import math
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
GHOST = ROOT / 'assets/ghost'
DEST = GHOST / 'weapon_layers_v19'
DEST.mkdir(parents=True, exist_ok=True)
W, H = 256, 220
DIRECTIONS = ['front', 'back', 'left', 'right']

# Each pose = (hand grip x,y; direction/endpoint x,y). Full eight-key cycles,
# independently authored for each view/animation rather than global hand anchors.
# Values can be edited without touching game code; rerun this tool to re-export.
POSES = {
 'idle_front': [ (163,135,205,81),(163,134,205,81),(164,133,205,80),(164,134,205,81),
                 (162,135,204,82),(162,137,204,83),(163,137,205,84),(163,136,205,82)],
 'idle_back':  [ (159,135,198,70),(159,134,198,71),(159,133,198,70),(160,135,199,71),
                 (160,135,200,72),(159,135,199,73),(159,136,198,71),(159,136,198,70)],
 'idle_left':  [ (108,141,64,91),(108,140,64,92),(108,140,63,91),(108,141,64,90),
                 (108,142,64,91),(108,142,65,93),(108,141,64,92),(108,140,64,91)],
 'idle_right': [ (149,140,201,92),(149,139,201,91),(149,139,202,91),(149,140,201,92),
                 (149,141,201,93),(149,141,200,93),(149,140,200,92),(149,140,201,92)],
 'walk_front':[(162,135,205,85),(161,133,205,83),(160,133,204,81),(160,136,205,83),
                 (161,138,205,86),(164,138,206,87),(165,137,205,86),(163,136,205,85)],
 'walk_back': [(159,135,199,71),(158,132,200,69),(157,132,202,68),(157,136,202,70),
                 (158,137,201,72),(160,137,199,74),(161,136,198,72),(160,135,199,71)],
 'walk_left': [(109,140,65,92),(107,139,62,90),(106,137,61,90),(107,139,62,91),
                 (110,142,66,95),(112,143,68,96),(111,142,68,94),(109,141,66,93)],
 'walk_right':[(148,139,203,93),(147,137,204,89),(146,138,205,88),(148,141,205,92),
                 (150,142,202,96),(151,142,200,97),(150,140,201,95),(149,140,202,94)],
 'light_front':[(155,130,204,80),(153,126,218,86),(151,123,220,70),(154,118,224,64),
                (163,126,223,143),(164,129,213,180),(157,129,205,108),(155,132,204,80)],
 'light_back': [(150,130,198,66),(153,122,202,47),(157,118,186,39),(159,114,163,43),
                (164,120,207,126),(161,129,209,174),(154,132,196,94),(151,132,198,66)],
 'light_left': [(109,131,66,85),(108,129,51,98),(106,126,39,120),(108,121,35,135),
                (111,127,51,171),(113,132,68,182),(110,135,60,116),(109,134,66,85)],
 'light_right':[(149,131,193,85),(150,129,207,98),(151,126,219,120),(150,121,220,135),
                (147,127,208,171),(145,132,192,182),(149,135,198,116),(149,134,193,85)],
 'heavy_front':[(154,133,188,76),(157,128,174,53),(160,123,161,46),(158,117,210,44),
                (163,124,222,137),(161,135,201,180),(157,137,206,122),(155,137,196,81)],
 'heavy_back': [(153,134,191,68),(157,126,174,46),(159,119,161,43),(158,114,208,48),
                (164,122,212,132),(162,137,196,183),(157,137,196,124),(155,136,193,73)],
 'heavy_left': [(108,133,75,72),(108,125,91,53),(111,117,109,50),(109,118,45,78),
                (109,126,43,147),(111,135,73,180),(110,138,62,118),(110,135,74,77)],
 'heavy_right':[(149,133,184,72),(149,125,168,53),(146,117,146,50),(148,118,211,78),
                (150,126,214,147),(147,135,185,180),(147,138,198,118),(148,135,183,77)],
}
assert len(POSES) == 16 and all(len(v)==8 for v in POSES.values())

# Layout is intentionally identical to v1.6. Each of the 8 rows has 8 frames.
ROWS = {
 'locomotion': [f'idle_{d}' for d in DIRECTIONS] + [f'walk_{d}' for d in DIRECTIONS],
 'combat': [f'light_{d}' for d in DIRECTIONS] + [f'heavy_{d}' for d in DIRECTIONS],
}


def source_master(style: str) -> tuple[Image.Image, tuple[float,float], tuple[float,float]]:
    """Recover the v1.6 painted weapon, without any of Ghost Girl's pixels.

    Locomotion/right/idle frame zero has the entire visible silhouette within
    its cell; subtracting the exact original RGBA frame isolates the weapon.
    """
    full = Image.open(GHOST / 'weapons_v16' / f'{style}_locomotion_2048x1760.png').convert('RGBA')
    composite = np.array(full.crop((0, 3*H, W, 4*H)), dtype=np.int16)
    original = np.array(Image.open(GHOST / 'idle_right_00.png').convert('RGBA'), dtype=np.int16)
    difference = np.max(np.abs(composite-original), axis=2)
    alpha = np.where(difference > 2, composite[:,:,3], 0).astype('uint8')
    result = composite.astype('uint8')
    result[:,:,3] = alpha
    # Grip and head hub measured in this specific reference (no runtime anchor).
    return (Image.fromarray(result,'RGBA'),
            (160.0, 112.0) if style=='scythe' else (160.0, 115.0),
            (217.0, 78.0) if style=='scythe' else (210.0, 62.0))


def weapon_layers(master: Image.Image, grip: tuple[float,float], tip: tuple[float,float],
                  split: float) -> tuple[Image.Image,Image.Image]:
    """Split the image along the weapon axis, so hands/hair can occlude the shaft."""
    rgba=np.asarray(master).copy()
    dy,dx=np.mgrid[0:H,0:W]
    ux=tip[0]-grip[0];uy=tip[1]-grip[1]
    along=((dx-grip[0])*ux+(dy-grip[1])*uy)/(ux*ux+uy*uy)
    # 2px feather at seam, avoiding a visually harsh front/back discontinuity.
    blend=np.clip((along-split)*math.hypot(ux,uy)/2+0.5,0,1)
    fore=rgba.copy(); rear=rgba.copy()
    fore[:,:,3]=np.clip(rgba[:,:,3]*blend,0,255).astype('uint8')
    rear[:,:,3]=np.clip(rgba[:,:,3]*(1-blend),0,255).astype('uint8')
    return Image.fromarray(rear,'RGBA'),Image.fromarray(fore,'RGBA')


def render(source: Image.Image, orig_grip: tuple[float,float], orig_tip: tuple[float,float],
           dest_pose: tuple[float,float,float,float]) -> Image.Image:
    """Bake a frame-specific rotation/scale/translation into a transparent cell."""
    x,y,tipx,tipy=dest_pose
    ux,uy=orig_tip[0]-orig_grip[0],orig_tip[1]-orig_grip[1]
    vx,vy=tipx-x,tipy-y
    length=ux*ux+uy*uy
    a=(ux*vx+uy*vy)/length
    b=(ux*vy-uy*vx)/length
    denom=a*a+b*b
    inv_a=a/denom;inv_b=-b/denom
    # PIL mapping is output -> source. Forward: [a,-b;b,a].
    matrix=(inv_a,-inv_b,orig_grip[0]-inv_a*x+inv_b*y,
            inv_b,inv_a,orig_grip[1]-inv_b*x-inv_a*y)
    return source.transform((W,H),Image.Transform.AFFINE,matrix,resample=Image.Resampling.BICUBIC)


def make():
    for style in ('scythe','halberd'):
        master,grip,tip=source_master(style)
        for family,rows in ROWS.items():
            back=Image.new('RGBA',(8*W,8*H));front=Image.new('RGBA',(8*W,8*H))
            for r,key in enumerate(rows):
                # The back-facing pose hides more of the handle under her hair.
                split=0.60 if key.endswith('back') else (0.22 if family=='combat' else 0.33)
                rear,fore=weapon_layers(master,grip,tip,split)
                for c,pose in enumerate(POSES[key]):
                    # Slightly longer polearm, still firmly anchored at the hand.
                    if style=='halberd':
                        gx,gy,tx,ty=pose
                        pose=(gx,gy+1, gx+(tx-gx)*1.08, gy+1+(ty-gy)*1.08)
                    back.alpha_composite(render(rear,grip,tip,pose),(c*W,r*H))
                    front.alpha_composite(render(fore,grip,tip,pose),(c*W,r*H))
            for depth,asset in (('back',back),('front',front)):
                target=DEST/f'{style}_{family}_{depth}_2048x1760.png'
                asset.save(target,optimize=True)
                print(target.relative_to(ROOT),target.stat().st_size)

if __name__=='__main__':make()
