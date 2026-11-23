#!/usr/bin/env python3
"""Pack the already-cleaned v1.10 64 locomotion frames as a single proofed
8x8 body atlas; remove isolated residual magenta pixels only in old hook ROI.
Original character sprites are never touched. The new body atlas is used by
both weapon types, avoiding old/new reference images getting mixed in the UI.
"""
from pathlib import Path
from PIL import Image
import numpy as np
import cv2
import json
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'assets/ghost/weapon_body_v110'
OUT=ROOT/'assets/ghost/weapon_body_v111'
ROWS=[f'{motion}_{facing}' for motion in ('idle','walk') for facing in ('front','back','left','right')]

def build():
    OUT.mkdir(parents=True,exist_ok=True)
    atlas=Image.new('RGBA',(2048,1760))
    report=[]
    for row,track in enumerate(ROWS):
        facing=track.split('_')[-1]
        for frame in range(8):
            src=SRC/f'{track}_{frame:02d}.png'
            arr=np.asarray(Image.open(src).convert('RGBA')).copy()
            hsv=cv2.cvtColor(arr[:,:,:3],cv2.COLOR_RGB2HSV)
            yy,xx=np.indices((220,256))
            # The highly saturated rose accent should never be present on a
            # two-handed weapon-ready body. Other facial/dress pixels untouched.
            leftover=(arr[:,:,3]>60)&(hsv[:,:,1]>83)&(hsv[:,:,0]>125)&(hsv[:,:,0]<178)
            leftover &= (yy>138)&((xx<105) if facing=='left' else (xx>148))
            cleared=int(leftover.sum())
            arr[leftover,3]=0
            arr[arr[:,:,3]==0,:3]=0
            img=Image.fromarray(arr,'RGBA')
            atlas.alpha_composite(img, (frame*256,row*220))
            report.append({'track':track,'frame':frame,'remaining_rose_pixels_removed':cleared})
    dest=OUT/'weapon_ready_locomotion_2048x1760.png'
    atlas.save(dest,optimize=True)
    assert Image.open(dest).size==(2048,1760)
    assert len(report)==64
    (ROOT/'docs/V111_HOOK_CLEANUP_AUDIT.json').write_text(json.dumps(report,indent=2)+'\n')
    print(dest.relative_to(ROOT),dest.stat().st_size,'bytes, 64 cleaned frames, extra flecks',sum(x['remaining_rose_pixels_removed'] for x in report))
if __name__=='__main__':build()
