"""GH-113 App Store 스크린샷 합성: 아이폰 7장과 같은 장면·카피로 아이패드 13″·듀오 크기를 만든다."""
import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

# 작업 폴더: raw/(시뮬레이터 캡처), obj/(pdf2png로 뽑은 3D 오브젝트), iphone/(지금 아이폰 스크린샷), out/(결과)
S = os.environ.get('STORE_WORKDIR', '.').rstrip('/') + '/'
FONT = '/System/Library/Fonts/AppleSDGothicNeo.ttc'
BG = (244, 246, 248)
GREEN = (102, 223, 27)
INK = (34, 36, 40)
SUB = (140, 145, 153)

# 아이폰 3~7번 카피 그대로 (굵은 부분, 나머지)
SCENES = [
    ('write',    '하고 싶은 걸', ('문서 한 장', '에 적어요'), '제목만 적고, 날짜·메모·단계는 필요할 때 꺼내 쓰세요', 'car'),
    ('detail',   'D-day와 단계로', ('차근차근', ' 이뤄요'), '메모, 단계, 알림이 한 장에 정리돼요', 'tent'),
    ('edit',     '고칠 때도', ('그 자리에서', ' 바로'), '수정 화면을 따로 열지 않고 문서를 그대로 고쳐요', 'piano'),
    ('finished', '올해 얼마나', ('이뤘는지', ' 모아봐요'), '이룬 싶은 배지와 연말 회고로 남아요', 'books'),
    ('widget',   '위젯·제어 센터에서', ('바로 적을 수', ' 있어요'), '홈 화면 위젯, 제어 센터, 단축어를 지원해요', 'plant'),
]


def font(size, weight='regular'):
    return ImageFont.truetype(FONT, size, index={'regular': 0, 'medium': 2, 'bold': 6, 'extrabold': 14}[weight])


def obj(name, width):
    im = Image.open(S + f'obj/{name}.png').convert('RGBA')
    im = im.crop(im.getbbox())
    return im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)


def clean(shot, kind):
    """시뮬레이터 흔적(날짜·앱 이름, 창 크기 조절 손잡이)을 지운다."""
    d = ImageDraw.Draw(shot)
    if kind == 'pad':
        d.rectangle((165, 0, 620, 62), fill=shot.getpixel((640, 30)))
        d.rectangle((1990, 2680, 2064, 2752), fill=shot.getpixel((1980, 2670)))
    return shot


def rounded(im, radius):
    m = Image.new('L', im.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, im.width - 1, im.height - 1), radius, fill=255)
    out = im.convert('RGBA')
    out.putalpha(m)
    return out


def device(screen, bezel, radius, hinge=False):
    """검은 베젤 + 얇은 금속 테두리. hinge면 가운데 접히는 선을 그린다(듀오 펼친 화면)."""
    w, h = screen.width + bezel * 2, screen.height + bezel * 2
    frame = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(frame)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius + bezel, fill=(196, 200, 206))
    edge = max(3, bezel // 6)
    d.rounded_rectangle((edge, edge, w - 1 - edge, h - 1 - edge), radius + bezel - edge, fill=(22, 22, 24))
    frame.alpha_composite(rounded(screen, radius), (bezel, bezel))
    if hinge:
        x = w // 2
        crease = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        cd = ImageDraw.Draw(crease)
        for i, a in enumerate([10, 18, 10]):
            cd.line((x - 1 + i, bezel, x - 1 + i, h - bezel), fill=(0, 0, 0, a), width=1)
        frame.alpha_composite(crease)
    return frame


def shadow(layer, blur, alpha=60, offset=(0, 30)):
    a = layer.split()[3].point(lambda v: v * alpha // 255)
    sh = Image.new('RGBA', layer.size, (20, 30, 40, 0))
    sh.putalpha(a)
    pad = blur * 3
    canvas = Image.new('RGBA', (layer.width + pad * 2, layer.height + pad * 2), (0, 0, 0, 0))
    canvas.alpha_composite(sh, (pad, pad))
    return canvas.filter(ImageFilter.GaussianBlur(blur)), pad


def paste_shadowed(canvas, layer, xy, blur, alpha=60, offset=(0, 30)):
    sh, pad = shadow(layer, blur, alpha)
    canvas.alpha_composite(sh, (xy[0] - pad + offset[0], xy[1] - pad + offset[1]))
    canvas.alpha_composite(layer, xy)


def caption(canvas, top, line1, bold_rest, sub, sizes, color=INK, sub_color=SUB, center=True, left=0):
    d = ImageDraw.Draw(canvas)
    t, s = sizes
    f_reg, f_bold, f_sub = font(t), font(t, 'extrabold'), font(s)
    W = canvas.width

    def x_for(width):
        return (W - width) // 2 if center else left

    w1 = d.textlength(line1, font=f_reg)
    d.text((x_for(w1), top), line1, font=f_reg, fill=color)
    bold, rest = bold_rest
    wb, wr = d.textlength(bold, font=f_bold), d.textlength(rest, font=f_reg)
    y2 = top + round(t * 1.32)
    x = x_for(wb + wr)
    d.text((x, y2), bold, font=f_bold, fill=color)
    d.text((x + wb, y2), rest, font=f_reg, fill=color)
    ws = d.textlength(sub, font=f_sub)
    d.text((x_for(ws), y2 + round(t * 1.5)), sub, font=f_sub, fill=sub_color)


# 크기별 배치. screen_w: 캔버스 안에서 화면 너비, top: 기기 윗변, obj: (크기, 기기 오른쪽 위 모서리 기준 x, y 보정)
LAYOUTS = {
    'pad': dict(size=(2064, 2752), cap_top=230, sizes=(112, 50), screen_w=1560, top=760, bezel=34, radius=58,
                obj=(540, -280, -330), hinge=False),
    'duo-in': dict(size=(2853, 2007), cap_top=140, sizes=(100, 46), screen_w=2160, top=560, bezel=30, radius=50,
                   obj=(480, -260, -300), hinge=True),
    'duo-out': dict(size=(1398, 2034), cap_top=190, sizes=(84, 40), screen_w=900, top=640, bezel=26, radius=86,
                    obj=(380, -230, -170), hinge=False),
}


def scene(kind, key, line1, bold_rest, sub, objname):
    L = LAYOUTS[kind]
    W, H = L['size']
    canvas = Image.new('RGBA', (W, H), BG + (255,))
    caption(canvas, L['cap_top'], line1, bold_rest, sub, L['sizes'])
    shot = clean(Image.open(S + f'raw/{kind}-{key}.png').convert('RGB'), kind)
    sw = L['screen_w']
    shot = shot.resize((sw, round(shot.height * sw / shot.width)), Image.LANCZOS)
    dev = device(shot, L['bezel'], L['radius'], L['hinge'])
    x = (W - dev.width) // 2
    paste_shadowed(canvas, dev, (x, L['top']), blur=40, alpha=55)
    size, dx, dy = L['obj']
    o = obj(objname, size)
    paste_shadowed(canvas, o, (x + dev.width + dx, L['top'] + dy), blur=24, alpha=45, offset=(0, 24))
    return canvas.convert('RGB')


def hero(kind, shot_key):
    """아이폰 1~2번처럼 초록 배경 두 장이 이어지는 첫 화면."""
    L = LAYOUTS[kind]
    W, H = L['size']
    pano = Image.new('RGBA', (W * 2, H), GREEN + (255,))
    k = W / 1320 if kind != 'duo-in' else 1.35
    logo = Image.open(S + 'iphone/01.png').convert('RGBA').crop((120, 230, 300, 450))
    logo = logo.resize((round(logo.width * k), round(logo.height * k)), Image.LANCZOS)
    left = round(130 * k)
    top = round(250 * k) if kind != 'duo-in' else 150
    pano.alpha_composite(logo, (left, top))
    d = ImageDraw.Draw(pano)
    t = round(100 * k)
    y = top + logo.height + round(110 * k)
    d.text((left, y), '진짜 나를 위해', font=font(t), fill='white')
    d.text((left, y + round(t * 1.3)), '뭐 하고 싶어요?', font=font(round(t * 1.12), 'bold'), fill='white')
    s = round(44 * k)
    y3 = y + round(t * 1.3) + round(t * 1.12) + round(70 * k)
    d.text((left, y3), '하고 싶은 것 · 갖고 싶은 것 · 가고 싶은 곳', font=font(s), fill='white')
    d.text((left, y3 + round(s * 1.6)), '세 가지로 나눠 적는 나만의 위시리스트', font=font(s), fill='white')

    shot = clean(Image.open(S + f'raw/{kind}-{shot_key}.png').convert('RGB'), kind)
    sw = round(L['screen_w'] * 1.08)
    shot = shot.resize((sw, round(shot.height * sw / shot.width)), Image.LANCZOS)
    dev = device(shot, L['bezel'], L['radius'], L['hinge']).rotate(-9, resample=Image.BICUBIC, expand=True)
    dx = round(W * (0.80 if kind == 'pad' else 0.70))
    dy = round(H * 0.30) if kind != 'duo-in' else round(H * 0.22)
    paste_shadowed(pano, dev, (dx, dy), blur=50, alpha=70, offset=(0, 40))

    def put(name, width, cx, cy):
        o = obj(name, round(width * k))
        paste_shadowed(pano, o, (round(cx * W) - o.width // 2, round(cy * H) - o.height // 2), blur=22, alpha=50, offset=(0, 22))

    put('palette', 330, 1.62, 0.18)
    put('airplane', 380, 0.70, 0.74)
    put('chair', 300, 0.25, 0.80)
    put('cake', 400, 1.75, 0.70)
    return pano.crop((0, 0, W, H)).convert('RGB'), pano.crop((W, 0, W * 2, H)).convert('RGB')


if __name__ == '__main__':
    kind = sys.argv[1]
    out = S + f'out/{kind}/'
    os.makedirs(out, exist_ok=True)
    a, b = hero(kind, 'home' if os.path.exists(S + f'raw/{kind}-home.png') else 'detail')
    a.save(out + '01.png')
    b.save(out + '02.png')
    for i, sc in enumerate(SCENES):
        if os.path.exists(S + f'raw/{kind}-{sc[0]}.png'):
            scene(kind, *sc).save(out + f'{i + 3:02d}.png')
    print('done', kind, sorted(os.listdir(out)))
