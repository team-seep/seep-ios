"""App Store 스크린샷 합성: 아이폰 7장과 같은 장면·카피로 크기·언어별 이미지를 만든다 (GH-113, 언어별은 GH-117).
사용: STORE_WORKDIR=<작업 폴더> STORE_LANG=<ko|en-US|ja|zh-Hans|zh-Hant> compose.py phone|pad|duo-in|duo-out"""
import glob
import json
import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

# 작업 폴더: raw/(시뮬레이터 캡처), obj/(pdf2png로 뽑은 3D 오브젝트), iphone/(지금 아이폰 스크린샷), out/(결과)
S = os.environ.get('STORE_WORKDIR', '.').rstrip('/') + '/'
LANG = os.environ.get('STORE_LANG', 'ko')
COPY = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'l10n', 'copy.json')))[LANG]
# 언어별 폰트: (파일, 굵기별 face index) — PingFang은 Semibold가 가장 굵다
PINGFANG = (glob.glob('/System/Library/AssetsV2/com_apple_MobileAsset_Font*/*/AssetData/PingFang.ttc') + [''])[0]
HIRAGINO = '/System/Library/Fonts/ヒラギノ角ゴシック W{}.ttc'
FONTS = {
    'ko': {w: ('/System/Library/Fonts/AppleSDGothicNeo.ttc', i) for w, i in
           {'regular': 0, 'medium': 2, 'bold': 6, 'extrabold': 14}.items()},
    'ja': {w: (HIRAGINO.format(n), 0) for w, n in {'regular': 3, 'medium': 5, 'bold': 6, 'extrabold': 8}.items()},
    'zh-Hans': {w: (PINGFANG, i) for w, i in {'regular': 3, 'medium': 7, 'bold': 11, 'extrabold': 11}.items()},
    'zh-Hant': {w: (PINGFANG, i) for w, i in {'regular': 2, 'medium': 6, 'bold': 10, 'extrabold': 10}.items()},
    'en-US': {w: ('/System/Library/Fonts/SFNS.ttf', v) for w, v in
              {'regular': 'Regular', 'medium': 'Medium', 'bold': 'Bold', 'extrabold': 'Heavy'}.items()},
}[LANG]
BG = (244, 246, 248)
GREEN = (102, 223, 27)
INK = (34, 36, 40)
SUB = (140, 145, 153)

# 아이폰 3~7번 장면. 카피는 l10n/copy.json의 scenes (줄1, 굵게, 나머지, 부제)
SCENES = [(key, c[0], (c[1], c[2]), c[3], o) for (key, o), c in zip(
    [('write', 'car'), ('detail', 'tent'), ('edit', 'piano'), ('finished', 'books'), ('widget', 'plant')], COPY['scenes'])]


def font(size, weight='regular'):
    path, face = FONTS[weight]
    if isinstance(face, str):  # SF Pro는 가변 폰트
        f = ImageFont.truetype(path, size)
        f.set_variation_by_name(face)
        return f
    return ImageFont.truetype(path, size, index=face)


def obj(name, width):
    im = Image.open(S + f'obj/{name}.png').convert('RGBA')
    im = im.crop(im.getbbox())
    return im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)


def clean(shot, kind, key=''):
    """시뮬레이터 흔적(날짜·앱 이름, 창 크기 조절 손잡이)을 지운다."""
    d = ImageDraw.Draw(shot)
    if kind == 'pad':
        # 시각('9:41', 영어·번체 '9:41 AM', 간체 '09:41') 뒤부터 날짜·앱 이름까지
        d.rectangle(({'en-US': 165, 'zh-Hans': 138, 'zh-Hant': 165}.get(LANG, 112), 0, 620, 62), fill=shot.getpixel((640, 30)))
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


def caption(canvas, top, line1, bold_rest, sub, sizes, color=INK, sub_color=SUB, center=True, left=0, sub_w=0.48):
    d = ImageDraw.Draw(canvas)
    t, s = sizes
    W = canvas.width
    # 번역이 길면 제목은 캔버스의 88% 안으로 줄이고, 부제는 오른쪽 위 오브젝트에 닿지 않게(sub_w) 두 줄로 나눈다
    t = min(t, int(t * W * 0.88 / max(d.textlength(line1, font=font(t)),
                                       d.textlength(bold_rest[0], font=font(t, 'extrabold')) + d.textlength(bold_rest[1], font=font(t)))))
    subs = split_sub(d, sub, font(s), W * sub_w)
    s = min(s, int(s * W * sub_w / max(d.textlength(line, font=font(s)) for line in subs)))
    f_reg, f_bold, f_sub = font(t), font(t, 'extrabold'), font(s)

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
    for i, line in enumerate(subs):
        ws = d.textlength(line, font=f_sub)
        d.text((x_for(ws), y2 + round(t * 1.5) + round(s * 1.35) * i), line, font=f_sub, fill=sub_color)


def split_sub(d, sub, f, max_w):
    """한 줄에 안 들어가면 두 줄로 나눈다(세 줄이면 기기 화면에 닿는다). 끊을 자리(공백·쉼표·— 뒤)를 먼저 쓰고,
    그래도 안 들어가는 한중일 문장은 글자 사이에서 끊는다 — 영문·숫자 단어 안과 문장부호 앞은 빼고."""
    if d.textlength(sub, font=f) <= max_w:
        return [sub]
    marks = [i + 1 for i, ch in enumerate(sub[:-1]) if ch in ' ,、，。—・']
    cjk = any('\u3040' <= ch <= '\u9fff' for ch in sub)
    anywhere = [i for i in range(1, len(sub)) if not (sub[i - 1].isascii() and sub[i].isascii() and sub[i] != ' ')
                and sub[i] not in '、。，,・）」！？ー'] if cjk else []
    best = [sub]
    for cuts in (marks, anywhere):
        for n in (2,):
            if len(cuts) < n - 1:
                continue
            picks = []
            for k in range(1, n):
                options = [c for c in cuts if c not in picks and (not picks or c > picks[-1])]
                if not options:
                    break
                picks.append(min(options, key=lambda c: abs(c - len(sub) * k / n)))
            lines = [sub[a:b].strip() for a, b in zip([0] + picks, picks + [len(sub)])]
            if all(d.textlength(line, font=f) <= max_w for line in lines):
                return lines
            best = lines
    return best


# 크기별 배치. screen_w: 캔버스 안에서 화면 너비, top: 기기 윗변, obj: (크기, 기기 오른쪽 위 모서리 기준 x, y 보정)
LAYOUTS = {
    'phone': dict(size=(1320, 2868), cap_top=230, sizes=(104, 46), screen_w=960, top=700, bezel=30, radius=120,
                  obj=(310, -170, -170), hinge=False, sub_w=0.46),
    'pad': dict(size=(2064, 2752), cap_top=230, sizes=(112, 50), screen_w=1560, top=760, bezel=34, radius=58,
                obj=(540, -280, -330), hinge=False, sub_w=0.48),
    'duo-in': dict(size=(2853, 2007), cap_top=140, sizes=(100, 46), screen_w=2160, top=560, bezel=30, radius=50,
                   obj=(480, -260, -300), hinge=True, sub_w=0.48),
    'duo-out': dict(size=(1398, 2034), cap_top=190, sizes=(84, 40), screen_w=900, top=640, bezel=26, radius=86,
                    obj=(380, -230, -170), hinge=False, sub_w=0.48),
}


def scene(kind, key, line1, bold_rest, sub, objname):
    L = LAYOUTS[kind]
    W, H = L['size']
    canvas = Image.new('RGBA', (W, H), BG + (255,))
    caption(canvas, L['cap_top'], line1, bold_rest, sub, L['sizes'], sub_w=L['sub_w'])
    shot = clean(Image.open(S + f'raw/{kind}-{LANG}-{key}.png').convert('RGB'), kind, key)
    sw = L['screen_w']
    shot = shot.resize((sw, round(shot.height * sw / shot.width)), Image.LANCZOS)
    dev = device(shot, L['bezel'], L['radius'], L['hinge'])
    x = (W - dev.width) // 2
    paste_shadowed(canvas, dev, (x, L['top']), blur=40, alpha=55)
    size, dx, dy = L['obj']
    o = obj(objname, size)
    paste_shadowed(canvas, o, (x + dev.width + dx, L['top'] + dy), blur=24, alpha=45, offset=(0, 24))
    return canvas.convert('RGB')


def hero_copy(canvas, left, y, k, W):
    """첫 화면 카피(copy.json hero). 길면 첫 패널 안(제목 60%, 부제 64%)에 들어오게 줄인다."""
    d = ImageDraw.Draw(canvas)
    l1, l2, s1, s2 = COPY['hero']
    t = round(100 * k)
    t = min(t, int(t * W * 0.60 / max(d.textlength(l1, font=font(t)), d.textlength(l2, font=font(round(t * 1.12), 'bold')))))
    s = round(44 * k)
    s = min(s, int(s * W * 0.64 / max(d.textlength(s1, font=font(s)), d.textlength(s2, font=font(s)))))
    d.text((left, y), l1, font=font(t), fill='white')
    d.text((left, y + round(t * 1.3)), l2, font=font(round(t * 1.12), 'bold'), fill='white')
    y3 = y + round(t * 1.3) + round(t * 1.12) + round(70 * k)
    d.text((left, y3), s1, font=font(s), fill='white')
    d.text((left, y3 + round(s * 1.6)), s2, font=font(s), fill='white')


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
    hero_copy(pano, left, top + logo.height + round(110 * k), k, W)

    shot = clean(Image.open(S + f'raw/{kind}-{LANG}-{shot_key}.png').convert('RGB'), kind, shot_key)
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
    out = S + f'out/{LANG}/{kind}/'
    os.makedirs(out, exist_ok=True)
    a, b = hero(kind, 'home' if os.path.exists(S + f'raw/{kind}-{LANG}-home.png') else 'detail')
    a.save(out + '01.png')
    b.save(out + '02.png')
    for i, sc in enumerate(SCENES):
        if os.path.exists(S + f'raw/{kind}-{LANG}-{sc[0]}.png'):
            scene(kind, *sc).save(out + f'{i + 3:02d}.png')
    if kind == 'phone':  # 6.1″(1206×2622)는 6.9″와 비율이 같아 줄여서 만든다
        os.makedirs(S + f'out/{LANG}/phone-61/', exist_ok=True)
        for f in sorted(os.listdir(out)):
            Image.open(out + f).resize((1206, 2622), Image.LANCZOS).save(S + f'out/{LANG}/phone-61/' + f)
    print('done', kind, sorted(os.listdir(out)))
