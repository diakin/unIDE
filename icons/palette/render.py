from PIL import Image, ImageDraw, ImageFont
import math, sys
sys.path.insert(0,'.')
from icons import ICONS
S=4; BIG=96
FONTB='/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf'
FONTN='/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf'
def r(v): return int(round(float(v)*S))
WHITE=(255,255,255); BLACK=(0,0,0)
def paint(script):
    # RGB: белое - пусто, чёрное - цвет значка, остальное - свой цвет (@)
    img=Image.new('RGB',(BIG,BIG),WHITE); d=ImageDraw.Draw(img); d.fontmode='1'
    INK=BLACK
    for cmd in script.split(';'):
        cmd=cmd.strip()
        if not cmd: continue
        op=cmd[0]; rest=cmd[1:].strip()
        if op=='@':
            INK=tuple(int(rest[i:i+2],16) for i in (0,2,4)) if rest else BLACK
            continue
        if op=='T':
            parts=rest.split(' ',4); x,y,h,b,text=parts
            f=ImageFont.truetype(FONTB if b=='B' else FONTN, r(h))
            d.text((r(x),r(y)),text,fill=INK,font=f); continue
        a=[float(v) for v in rest.split()]
        if op in 'FE':
            d.rectangle((r(a[0]),r(a[1]),r(a[2])-1,r(a[3])-1),fill=INK if op=='F' else WHITE)
        elif op=='R':
            w=a[4] if len(a)>4 else 1; x1,y1,x2,y2=a[:4]
            for rc in ((x1,y1,x2,y1+w),(x1,y2-w,x2,y2),(x1,y1,x1+w,y2),(x2-w,y1,x2,y2)):
                d.rectangle((r(rc[0]),r(rc[1]),r(rc[2])-1,r(rc[3])-1),fill=INK)
        elif op=='L':
            w=a[4] if len(a)>4 else 1; x1,y1,x2,y2=a[:4]
            dx,dy=x2-x1,y2-y1; ln=math.hypot(dx,dy) or 1; nx,ny=-dy/ln*w/2,dx/ln*w/2
            # горизонталь/вертикаль: от края до края; иначе - по оси
            if dy==0 or dx==0:
                if dy==0: pts=[(x1,y1-w/2),(x2,y1-w/2),(x2,y1+w/2),(x1,y1+w/2)]
                else: pts=[(x1-w/2,y1),(x1+w/2,y1),(x1+w/2,y2),(x1-w/2,y2)]
            else:
                pts=[(x1+nx,y1+ny),(x2+nx,y2+ny),(x2-nx,y2-ny),(x1-nx,y1-ny)]
            d.polygon([(r(px),r(py)) for px,py in pts],fill=INK)
        elif op in 'DK':
            cx,cy,rad=a; d.ellipse((r(cx-rad),r(cy-rad),r(cx+rad)-1,r(cy+rad)-1),fill=INK if op=='D' else WHITE)
        elif op=='C':
            cx,cy,rad=a[:3]; w=a[3] if len(a)>3 else 1
            m=Image.new('L',(BIG,BIG),0); md=ImageDraw.Draw(m)
            md.ellipse((r(cx-rad),r(cy-rad),r(cx+rad)-1,r(cy+rad)-1),fill=255)
            ri=rad-w; md.ellipse((r(cx-ri),r(cy-ri),r(cx+ri)-1,r(cy+ri)-1),fill=0)
            img.paste(INK,(0,0),m)
        elif op=='O':
            x1,y1,x2,y2,rad=a[:5]; w=a[5] if len(a)>5 else 1
            m=Image.new('L',(BIG,BIG),0); md=ImageDraw.Draw(m)
            md.rounded_rectangle((r(x1),r(y1),r(x2)-1,r(y2)-1),radius=r(rad),fill=255)
            md.rounded_rectangle((r(x1+w),r(y1+w),r(x2-w)-1,r(y2-w)-1),radius=max(0,r(rad-w)),fill=0)
            img.paste(INK,(0,0),m)
        elif op in 'PQ':
            pts=[(r(a[i]),r(a[i+1])) for i in range(0,len(a),2)]
            d.polygon(pts,fill=INK if op=='P' else WHITE)
    return img
def icon(script, ink, back):
    big=paint(script); b=big.load()
    out=Image.new('RGB',(24,24),back); p=out.load()
    for y in range(24):
        for x in range(24):
            acc=[0,0,0]; hit=0
            for i in range(S):
                for j in range(S):
                    v=b[x*S+i,y*S+j]
                    if v==WHITE: v=back
                    else:
                        hit+=1
                        if v==BLACK: v=ink
                    for k in range(3): acc[k]+=v[k]
            if hit: p[x,y]=tuple(a//(S*S) for a in acc)
    return out
if __name__=='__main__':
    names=list(ICONS)
    cols=12; cell=40
    for theme,(ink,back) in {'light':((0,0,0),(212,208,200)),'dark':((176,176,176),(45,45,48))}.items():
        rows=(len(names)+cols-1)//cols
        sheet=Image.new('RGB',(cols*cell*2,rows*(cell*2+14)),back); sd=ImageDraw.Draw(sheet)
        f=ImageFont.truetype(FONTN,10)
        for i,n in enumerate(names):
            x=(i%cols)*cell*2; y=(i//cols)*(cell*2+14)
            ic=icon(ICONS[n],ink,back)
            sheet.paste(ic.resize((48,48),Image.NEAREST),(x+4,y+2))
            sheet.paste(ic,(x+56,y+14))
            sd.text((x+2,y+cell*2-26),n[1:15],fill=ink,font=f)
        sheet.save(f'sheet_{theme}.png')
    print(len(names))
