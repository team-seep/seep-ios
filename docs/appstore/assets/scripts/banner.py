"""GH-113 제품 페이지 헤더(21:9, 3840×1646)와 검색 결과 이미지(3:2, 2400×1600)."""
import os
from PIL import Image, ImageDraw

from compose import GREEN, S, clean, device, font, obj, paste_shadowed


def dev(kind, key, screen_w, bezel, radius, hinge=False, angle=0):
    shot = clean(Image.open(S + f'raw/{kind}-{key}.png').convert('RGB'), kind)
    shot = shot.resize((screen_w, round(shot.height * screen_w / shot.width)), Image.LANCZOS)
    d = device(shot, bezel, radius, hinge)
    return d.rotate(angle, resample=Image.BICUBIC, expand=True) if angle else d


def copy_block(canvas, left, top, k):
    logo = Image.open(S + 'iphone/01.png').convert('RGBA').crop((120, 230, 300, 450))
    logo = logo.resize((round(logo.width * k), round(logo.height * k)), Image.LANCZOS)
    canvas.alpha_composite(logo, (left, top))
    d = ImageDraw.Draw(canvas)
    t = round(100 * k)
    y = top + logo.height + round(90 * k)
    d.text((left, y), '진짜 나를 위해', font=font(t), fill='white')
    d.text((left, y + round(t * 1.3)), '뭐 하고 싶어요?', font=font(round(t * 1.12), 'bold'), fill='white')
    s = round(44 * k)
    y3 = y + round(t * 1.3) + round(t * 1.12) + round(70 * k)
    d.text((left, y3), '하고 싶은 것 · 갖고 싶은 것 · 가고 싶은 곳', font=font(s), fill='white')
    d.text((left, y3 + round(s * 1.6)), '세 가지로 나눠 적는 나만의 위시리스트', font=font(s), fill='white')


def put(canvas, name, width, cx, cy):
    o = obj(name, width)
    paste_shadowed(canvas, o, (round(cx) - o.width // 2, round(cy) - o.height // 2), blur=22, alpha=50, offset=(0, 22))


def header():
    W, H = 3840, 1646
    c = Image.new('RGBA', (W, H), GREEN + (255,))
    # 가장자리가 잘려도 되도록 글은 가운데 쪽 안전 영역(좌우 15%) 안에 둔다
    copy_block(c, 560, 330, 1.4)
    pad = dev('pad', 'detail', 1300, 28, 46, angle=-6)
    paste_shadowed(c, pad, (2180, 230), blur=50, alpha=70, offset=(0, 40))
    duo = dev('duo-in', 'finished', 1000, 20, 32, hinge=True, angle=4)
    paste_shadowed(c, duo, (2820, 930), blur=50, alpha=70, offset=(0, 40))
    phone = dev('duo-out', 'home', 500, 18, 56, angle=-8)
    paste_shadowed(c, phone, (1990, 760), blur=50, alpha=75, offset=(0, 40))
    put(c, 'palette', 380, 3420, 300)
    put(c, 'cake', 360, 3640, 760)
    put(c, 'chair', 300, 340, 1360)
    return c.convert('RGB')


def search():
    W, H = 2400, 1600
    c = Image.new('RGBA', (W, H), GREEN + (255,))
    copy_block(c, 150, 170, 1.12)
    pad = dev('pad', 'detail', 1150, 26, 42, angle=-6)
    paste_shadowed(c, pad, (1290, 300), blur=44, alpha=70, offset=(0, 36))
    phone = dev('duo-out', 'home', 460, 18, 52, angle=-8)
    paste_shadowed(c, phone, (1010, 780), blur=44, alpha=75, offset=(0, 36))
    put(c, 'palette', 300, 2200, 230)
    put(c, 'chair', 260, 300, 1380)
    return c.convert('RGB')


if __name__ == '__main__':
    os.makedirs(S + 'out/banner', exist_ok=True)
    header().save(S + 'out/banner/header-3840x1646.png')
    search().save(S + 'out/banner/search-2400x1600.png')
    print('done')
