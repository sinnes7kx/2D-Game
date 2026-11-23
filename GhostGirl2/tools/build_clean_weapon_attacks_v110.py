"""Export effect-free heavy attack body frames for layered weapon play.

The original v1.4 unarmed animations paint magical crescents directly over the
character in impact frame 4. Instead of destructively cutting through her
hands/hair, two-handed weapon animations use the ORIGINAL pose from frame 5
at index 4. This retains approved character pixels but makes a 1-frame hold.
Heavy attacks also contain detached floor-swish paint; connected-component
filtering removes that outside the main character silhouette.
"""
from pathlib import Path
import numpy as np
import cv2
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'assets/ghost/combat_v14'
OUT=ROOT/'assets/ghost/weapon_combat_body_v110'
DIRECTIONS=('front','back','left','right')

def remove_detached_effects(src: Image.Image):
    arr=np.asarray(src.convert('RGBA')).copy()
    a=(arr[:,:,3]>5).astype('uint8')
    count,labels,areas,_=cv2.connectedComponentsWithStats(a,connectivity=8)
    if count>1:
        main=1+int(np.argmax(areas[1:,cv2.CC_STAT_AREA]))
        arr[(labels!=main)&(arr[:,:,3]>0),3]=0
    arr[arr[:,:,3]==0,:3]=0
    return Image.fromarray(arr,'RGBA')

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    for direction in DIRECTIONS:
        for frame in range(8):
            # Avoid the frame-four painted crescent by using the approved
            # neighbouring follow-through body pose rather than erasing limbs.
            source_frame=5 if frame==4 else frame
            filename=f'attack_unarmed_heavy_{direction}_{source_frame:02}.png'
            image=Image.open(SRC/filename).convert('RGBA')
            clean=remove_detached_effects(image)
            clean.save(OUT/f'heavy_{direction}_{frame:02}.png',optimize=True)
    print('Created 32 heavy attack bodies in',OUT)
if __name__=='__main__':main()
