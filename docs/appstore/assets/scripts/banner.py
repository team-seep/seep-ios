"""제품 페이지 헤더(21:9, 3840×1646)와 검색 결과 이미지(3:2, 2400×1600) (GH-113, 언어별은 GH-117).
사용: STORE_WORKDIR=<작업 폴더> STORE_LANG=<언어> banner.py"""
import os
from PIL import Image, ImageDraw

from compose import COPY, GREEN, LANG, S, clean, device, font, obj, paste_shadowed


def dev(kind, key, screen_w, bezel, radius, hinge=False, angle=0):
    shot = clean(Image.open(S + f'raw/{kind}-{LANG}-{key}.png').convert('RGB'), kind)
    shot = shot.resize((screen_w, round(shot.height * screen_w / shot.width)), Image.LANCZOS)
    d = device(shot, bezel, radius, hinge)
    return d.rotate(angle, resample=Image.BICUBIC, expand=True) if angle else d


def copy_block(canvas, left, top, k, max_w):
    logo = Image.open(S + 'iphone/01.png').convert('RGBA').crop((120, 230, 300, 450))
    logo = logo.resize((round(logo.width * k), round(logo.height * k)), Image.LANCZOS)
    canvas.alpha_composite(logo, (left, top))
    d = ImageDraw.Draw(canvas)
    l1, l2, s1, s2 = COPY['hero']
    # 번역이 길면 기기 이미지에 닿지 않게(max_w) 줄인다
    t = round(100 * k)
    t = min(t, int(t * max_w / max(d.textlength(l1, font=font(t)), d.textlength(l2, font=font(round(t * 1.12), 'bold')))))
    y = top + logo.height + round(90 * k)
    d.text((left, y), l1, font=font(t), fill='white')
    d.text((left, y + round(t * 1.3)), l2, font=font(round(t * 1.12), 'bold'), fill='white')
    s = round(44 * k)
    s = min(s, int(s * max_w / max(d.textlength(s1, font=font(s)), d.textlength(s2, font=font(s)))))
    y3 = y + round(t * 1.3) + round(t * 1.12) + round(70 * k)
    d.text((left, y3), s1, font=font(s), fill='white')
    d.text((left, y3 + round(s * 1.6)), s2, font=font(s), fill='white')


def put(canvas, name, width, cx, cy):
    o = obj(name, width)
    paste_shadowed(canvas, o, (round(cx) - o.width // 2, round(cy) - o.height // 2), blur=22, alpha=50, offset=(0, 22))


def header():
    W, H = 3840, 1646
    c = Image.new('RGBA', (W, H), GREEN + (255,))
    # 가장자리가 잘려도 되도록 글은 가운데 쪽 안전 영역(좌우 15%) 안에 둔다
    copy_block(c, 560, 330, 1.4, 1320)
    pad = dev('pad', 'detail', 1300, 28, 46, angle=-6)
    paste_shadowed(c, pad, (2180, 230), blur=50, alpha=70, offset=(0, 40))
    duo = dev('duo-in', 'finished', 1000, 20, 32, hinge=True, angle=4)
    paste_shadowed(c, duo, (2820, 930), blur=50, alpha=70, offset=(0, 40))
    phone = dev('phone', 'home', 400, 16, 56, angle=-8)
    paste_shadowed(c, phone, (1990, 640), blur=50, alpha=75, offset=(0, 40))
    put(c, 'palette', 380, 3420, 300)
    put(c, 'cake', 360, 3640, 760)
    put(c, 'chair', 300, 340, 1360)
    return c.convert('RGB')


def search():
    W, H = 2400, 1600
    c = Image.new('RGBA', (W, H), GREEN + (255,))
    copy_block(c, 150, 170, 1.12, 820)
    pad = dev('pad', 'detail', 1150, 26, 42, angle=-6)
    paste_shadowed(c, pad, (1290, 300), blur=44, alpha=70, offset=(0, 36))
    phone = dev('phone', 'home', 370, 16, 52, angle=-8)
    paste_shadowed(c, phone, (1010, 640), blur=44, alpha=75, offset=(0, 36))
    put(c, 'palette', 300, 2200, 230)
    put(c, 'chair', 260, 300, 1380)
    return c.convert('RGB')


if __name__ == '__main__':
    out = S + f'out/{LANG}/banner/'
    os.makedirs(out, exist_ok=True)
    header().save(out + 'header-3840x1646.png')
    search().save(out + 'search-2400x1600.png')
    print('done')
