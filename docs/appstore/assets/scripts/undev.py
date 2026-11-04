"""위젯 고르기 화면 캡처에서 개발 빌드 이름 '싶Dev'의 'Dev'를 지운다. 사용: undev.py <캡처.png> <x> <y> (Dev 글자 가운데, 픽셀)"""
import sys
from PIL import Image, ImageDraw
im = Image.open(sys.argv[1]).convert('RGB')
x, y = int(sys.argv[2]), int(sys.argv[3])
ImageDraw.Draw(im).rectangle((x - 50, y - 30, x + 60, y + 30), fill=im.getpixel((x + 110, y)))
im.save(sys.argv[1])
