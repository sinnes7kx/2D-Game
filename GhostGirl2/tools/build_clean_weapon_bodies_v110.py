"""Build weapon-ready body frames from canonical Ghost Girl art (v2.0).

No originals are overwritten. The authored transparent removal mask isolates the
rose-hook in idle/walk frames; the approved head, hair and dress are unchanged.
Requires Pillow + NumPy; OpenCV is only used to locate the rose accent.
"""
from pathlib import Path
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/ghost'
OUTPUT = SOURCE / 'weapon_body_v110'
DIRECTIONS=('front','back','left','right')


def locate_rose(source: Image.Image, direction: str):
    data=np.asarray(source.convert('RGBA'))
    hsv=cv2.cvtColor(data[:,:,:3],cv2.COLOR_RGB2HSV)
    yy,xx=np.indices(data.shape[:2])
    is_left=direction=='left'
    colored=(data[:,:,3]>90)&(hsv[:,:,1]>83)&(hsv[:,:,0]>125)&(hsv[:,:,0]<178)
    colored&=(yy>138)&((xx<105) if is_left else (xx>148))
    ys,xs=np.where(colored)
    if len(xs)<15:
        raise ValueError(f'Rose center detection failed: {direction}')
    return float(np.median(xs)),float(np.median(ys))


def clean(source: Image.Image,direction: str):
    rose_x,rose_y=locate_rose(source,direction)
    left=direction=='left'; sign=-1 if left else 1
    mask=Image.new('L',source.size,0)
    draw=ImageDraw.Draw(mask)
    def ellipse(x,y,rx,ry):
        draw.ellipse((round(x-rx),round(y-ry),round(x+rx),round(y+ry)), fill=255)
    def line(points,width):
        draw.line([(round(x),round(y)) for x,y in points],fill=255,width=width,joint='curve')
    # Physically separate the painted hook along the outside edge of the
    # wrist. Keep the arm, gown and legs on the opposite (body) side.
    # Every frame has slightly different rose positions, hence this authored
    # direction-aware silhouette boundary rather than a fixed bounding box.
    boundary=[(rose_x-sign*3,rose_y-21),
              (rose_x-sign*10,rose_y-13),
              (rose_x-sign*14,rose_y-5),
              (rose_x-sign*15,rose_y+12),
              (rose_x-sign*12,220)]
    if left:
        polygon=boundary+[(0,220),(0,rose_y-21)]
    else:
        polygon=boundary+[(255,220),(255,rose_y-21)]
    draw.polygon([(round(x),round(y)) for x,y in polygon],fill=255)
    # Decorative petals occasionally protrude toward the wrist; include only
    # the saturated rose accent and not the dress behind it.
    ellipse(rose_x,rose_y-1,11,13)
    # Soft 1px antialiasing to avoid cutout pixel stair-steps.
    mask=mask.filter(ImageFilter.GaussianBlur(0.75))
    arr=np.asarray(source.convert('RGBA')).copy()
    a=np.asarray(mask,dtype=np.float32)/255.0
    arr[:,:,3]=np.round(arr[:,:,3]*(1.0-a)).astype('uint8')
    arr[arr[:,:,3]==0,:3]=0
    return Image.fromarray(arr,'RGBA'),(round(rose_x),round(rose_y))


def main():
    OUTPUT.mkdir(parents=True,exist_ok=True)
    locations={}
    for kind in ('idle','walk'):
        for direction in DIRECTIONS:
            prefix=f'idle_{direction}' if kind=='idle' else direction
            for i in range(8):
                input_path=SOURCE/f'{prefix}_{i:02}.png'
                assert input_path.is_file(),input_path
                image=Image.open(input_path).convert('RGBA')
                cleaned,center=clean(image,direction)
                path=OUTPUT/f'{kind}_{direction}_{i:02}.png'
                cleaned.save(path,optimize=True)
                locations[path.name]=center
    print('Created',len(locations),'separate clean body frames in',OUTPUT)
    return locations

if __name__=='__main__':main()
