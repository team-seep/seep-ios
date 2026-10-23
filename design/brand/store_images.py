"""스토어 이미지(스크린샷·헤더·검색결과)를 HTML로 그려 Chrome headless로 PNG 렌더링한다."""
import os, subprocess, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(ROOT, "src")
OUT = os.path.join(ROOT, "out")
os.makedirs(OUT, exist_ok=True)
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

FONT = "'Apple SD Gothic Neo', 'AppleSDGothicNeo-Regular', sans-serif"
INK = "#2B2D31"
SUB = "#8A9099"
GREEN = "#66DF1B"


def src(name):
    return "file://" + os.path.join(SRC, name)


def phone(img, width, left, top, rotate=0, z=1, color="silver"):
    """iPhone 17/18 Pro 모양 프레임. 화면 비율 1206:2622, 다이내믹 아일랜드 포함"""
    bezel = width * 0.026  # 바깥 프레임 두께
    black = width * 0.012  # 안쪽 검은 테두리
    screen_w = width - 2 * (bezel + black)
    screen_h = screen_w * 2622 / 1206
    height = screen_h + 2 * (bezel + black)
    frame = {
        "silver": "linear-gradient(140deg,#f7f8fa 0%,#d6d9dd 22%,#eef0f2 48%,#c3c7cc 76%,#e9ebee 100%)",
        "blue": "linear-gradient(140deg,#4b5d78 0%,#2c3a50 30%,#5a6c87 55%,#26324a 80%,#44546e 100%)",
    }[color]
    r_out = width * 0.17
    r_in = r_out - bezel
    r_screen = r_in - black
    island_w = screen_w * 0.31
    island_h = screen_w * 0.092
    island_top = screen_w * 0.027
    btn = lambda side, t, h: (
        f'<div style="position:absolute;{side}:{-width*0.008}px;top:{t}px;width:{width*0.012}px;height:{h}px;'
        f'border-radius:{width*0.01}px;background:{frame}"></div>'
    )
    return f"""
<div style="position:absolute;left:{left}px;top:{top}px;width:{width}px;height:{height}px;transform:rotate({rotate}deg);transform-origin:50% 40%;z-index:{z}">
  {btn('left', height*0.17, height*0.045)}{btn('left', height*0.25, height*0.075)}{btn('left', height*0.34, height*0.075)}{btn('right', height*0.27, height*0.11)}
  <div style="position:absolute;inset:0;border-radius:{r_out}px;background:{frame};box-shadow:0 {width*0.05}px {width*0.12}px rgba(20,30,40,.22), inset 0 0 0 {width*0.003}px rgba(0,0,0,.18)"></div>
  <div style="position:absolute;inset:{bezel}px;border-radius:{r_in}px;background:#050505"></div>
  <div style="position:absolute;inset:{bezel+black}px;border-radius:{r_screen}px;overflow:hidden;background:#fff">
    <img src="{src(img)}" style="width:100%;height:100%;display:block">
    <div style="position:absolute;left:50%;top:{island_top}px;transform:translateX(-50%);width:{island_w}px;height:{island_h}px;border-radius:{island_h}px;background:#000"></div>
  </div>
</div>"""


def obj(name, width, left, top, rotate=0, z=2, shadow=True):
    sh = "filter:drop-shadow(0 30px 40px rgba(0,0,0,.18));" if shadow else ""
    return f'<img src="{src(name)}" style="position:absolute;left:{left}px;top:{top}px;width:{width}px;transform:rotate({rotate}deg);z-index:{z};{sh}">'


def page(w, h, bg, body):
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
html,body{{margin:0;padding:0;width:{w}px;height:{h}px;overflow:hidden}}
body{{background:{bg};font-family:{FONT};-webkit-font-smoothing:antialiased;position:relative}}
.h{{position:absolute;left:0;right:0;text-align:center;color:{INK};letter-spacing:-0.02em}}
</style></head><body>{body}</body></html>"""


def render(name, w, h, html):
    path = os.path.join(OUT, name + ".html")
    with open(path, "w") as f:
        f.write(html)
    png = os.path.join(OUT, name + ".png")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                    f"--window-size={w},{h}", f"--screenshot={png}", "--virtual-time-budget=3000", "file://" + path],
                   check=True, capture_output=True)
    return png


# ── 스크린샷 1~2: 초록 파노라마 (지금 스토어 1·2번 구성) ──
def panorama():
    W, H = 2640, 2868
    body = f"""
<img src="{src('logo-white.png')}" style="position:absolute;left:130px;top:250px;height:190px">
<div style="position:absolute;left:130px;top:560px;color:#fff;letter-spacing:-0.03em">
  <div style="font-size:118px;font-weight:300;opacity:.92;line-height:1.25">진짜 나를 위해</div>
  <div style="font-size:150px;font-weight:800;line-height:1.25">뭐 하고 싶어요?</div>
</div>
<div style="position:absolute;left:130px;top:1010px;color:#F2FFE8;font-size:52px;font-weight:500;line-height:1.5;opacity:.95">
  하고 싶은 것 · 갖고 싶은 것 · 가고 싶은 곳<br>세 가지로 나눠 적는 나만의 위시리스트
</div>
{obj('cat_do_1.png', 520, 150, 1650, -8)}
{obj('cat_go_1.png', 560, 640, 1330, 10)}
{phone('home.png', 1120, 1180, 640, -11, z=3)}
{obj('cat_get_3.png', 470, 1880, 1880, 8, z=4)}
{obj('cat_do_2.png', 420, 2090, 330, 14, z=4)}
{obj('cat_go_5.png', 520, 1960, 1180, -6, z=2)}
"""
    full = render("panorama", W, H, page(W, H, GREEN, body))
    return full


# ── 스크린샷 3~7: 밝은 바탕 + 두 줄 제목 + 아래가 잘린 폰 (지금 스토어 2~7번 구성) ──
SHOTS = [
    ("shot3", "하고 싶은 걸<br><b>문서 한 장</b>에 적어요", "제목만 적고, 날짜·메모·단계는 필요할 때 꺼내 쓰세요", "write.png", "cat_get_5.png"),
    ("shot4", "D-day와 단계로<br><b>차근차근</b> 이뤄요", "메모, 단계, 알림이 한 장에 정리돼요", "detail.png", "cat_go_8.png"),
    ("shot5", "고칠 때도<br><b>그 자리에서</b> 바로", "수정 화면을 따로 열지 않고 문서를 그대로 고쳐요", "edit.png", "cat_do_7.png"),
    ("shot6", "올해 얼마나<br><b>이뤘는지</b> 모아봐요", "이룬 싶은 배지와 연말 회고로 남아요", "finished.png", "cat_get_4.png"),
    ("shot7", "위젯·제어 센터에서<br><b>바로 적을 수</b> 있어요", "홈 화면 위젯, 제어 센터, 단축어를 지원해요", "widget.png", "cat_do_8.png"),
]


def shot(name, title, sub, img, deco):
    W, H = 1320, 2868
    body = f"""
<div class="h" style="top:190px;font-size:96px;font-weight:400;line-height:1.32">{title.replace('<b>', '<b style="font-weight:800">')}</div>
<div class="h" style="top:470px;font-size:46px;color:{SUB};font-weight:500">{sub}</div>
{phone(img, 1040, 140, 690)}
{obj(deco, 300, 1000, 560, 10, z=3)}
"""
    return render(name, W, H, page(W, H, "#F4F6F8", body))


# ── 헤더 21:9 (3840×1646) ──
def header():
    W, H = 3840, 1646
    body = f"""
<div style="position:absolute;inset:0;background:radial-gradient(120% 150% at 30% 0%,#7BEA36 0%,{GREEN} 45%,#4FCB12 100%)"></div>
<div style="position:absolute;left:300px;top:470px;color:#fff;letter-spacing:-0.03em">
  <div style="font-size:120px;font-weight:300;line-height:1.25;opacity:.92">진짜 나를 위해</div>
  <div style="font-size:160px;font-weight:800;line-height:1.25">하고 싶은 것</div>
  <div style="font-size:54px;font-weight:500;line-height:1.6;margin-top:30px;color:#F2FFE8">적고, 모으고, 이루는 위시리스트</div>
</div>
{obj('cat_do_1.png', 430, 1520, 980, -8, z=1)}
{phone('home.png', 760, 2080, 260, -8, z=3)}
{phone('detail.png', 760, 2780, 120, 6, z=2)}
{obj('cat_go_1.png', 500, 1480, 200, 10, z=4)}
{obj('cat_get_3.png', 420, 3360, 1050, 8, z=4)}
"""
    return render("header-21x9", W, H, page(W, H, GREEN, body))


# ── 검색결과 3:2 (3840×2560) ──
def search():
    W, H = 3840, 2560
    body = f"""
<div style="position:absolute;left:260px;top:620px;color:{INK};letter-spacing:-0.03em">
  <img src="{src('logo-green.png')}" style="height:200px;margin-bottom:90px">
  <div style="font-size:170px;font-weight:300;line-height:1.28">하고 싶은 걸</div>
  <div style="font-size:200px;font-weight:800;line-height:1.28"><span style="color:#3FB80A">문서 한 장</span>에</div>
  <div style="font-size:72px;font-weight:500;color:{SUB};margin-top:50px">적고, 모으고, 이루는 위시리스트</div>
</div>
{phone('write.png', 1040, 2050, 360, -5, z=2)}
{phone('home.png', 1040, 2700, 260, 6, z=3)}
{obj('cat_go_5.png', 520, 1760, 1720, -6, z=4)}
{obj('cat_get_4.png', 460, 3300, 1780, 10, z=4)}
"""
    return render("search-3x2", W, H, page(W, H, "#F4F6F8", body))


if __name__ == "__main__":
    targets = sys.argv[1:] or ["panorama", "shots", "header", "search"]
    if "panorama" in targets:
        panorama()
    if "shots" in targets:
        for s in SHOTS:
            shot(*s)
    if "header" in targets:
        header()
    if "search" in targets:
        search()
    print("done")
