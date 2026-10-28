import sqlite3,sys,uuid,datetime as dt
REF=dt.datetime(2001,1,1)
def t(d): return (d-REF).total_seconds()
now=dt.datetime(2026,10,28,9,41)
def day(n,h=23,m=59): return t((now+dt.timedelta(days=n)).replace(hour=h,minute=m,second=0))
db=sqlite3.connect(sys.argv[1]); c=db.cursor()
c.execute("delete from wish"); c.execute("delete from wishStep"); c.execute("delete from wishNotification"); c.execute("delete from wishSaving"); c.execute("delete from wishJournal")
W=[ # cat, emoji, title, dday, hashtag, finishedDaysAgo, memo, steps
("do","🏃","10km 마라톤 완주하기",12,"sports",None,"",[]),
("do","🏄","양양에서 서핑 배우기",24,"trip",None,"오전반 강습이 파도가 잔잔하대요. 첫날은 보드 대여까지 포함된 패키지로!",[("서핑 강습 예약하기",1),("래시가드 사기",0),("양양 숙소 잡기",0)]),
("do","📷","필름 카메라로 한 롤 찍기",40,"hobby",None,"",[]),
("do","🎹","피아노로 한 곡 완주하기",60,"hobby",None,"",[]),
("do","🧶","목도리 직접 떠보기",None,"hobby",None,"",[]),
("do","🍷","와인 클래스 들어보기",None,"life",None,"",[]),
("get","🎧","노이즈캔슬링 헤드폰",2,"shopping",None,"",[]),
("get","⌚️","러닝용 스마트워치",30,"sports",None,"",[]),
("get","🪴","거실에 둘 큰 화분",None,"life",None,"",[]),
("go","⛺️","가을 캠핑 가기",18,"leisure",None,"",[]),
("go","🗻","교토 단풍 보러 가기",35,"trip",None,"",[]),
("do","📚","올해 책 20권 읽기",None,"hobby",13,"",[]),
("do","🍰","홈베이킹으로 케이크 굽기",None,"hobby",28,"",[]),
("do","🚴","한강 자전거 완주",None,"sports",43,"",[]),
("go","🌅","정동진 일출 보기",None,"trip",75,"",[]),
("get","🎒","여행용 백팩",None,"shopping",100,"",[]),
("do","🏊","수영 자유형 배우기",None,"sports",130,"",[]),
]
cat={"do":"category_want_to_do","get":"category_want_to_get","go":"category_want_to_go"}
order={}
for i,(k,e,title,dd,tag,fin,memo,steps) in enumerate(W):
    wid=str(uuid.uuid4()).upper(); order[k]=order.get(k,0)+1
    created=t(now-dt.timedelta(days=60-i))
    date=day(dd) if dd is not None else (day(-fin) if fin else None)
    finish=day(-fin,20,0) if fin else None
    c.execute("insert into wish(id,category,emoji,title,date,finishDate,memo,hashtag,isSuccess,createdAt,updatedAt,manualOrder,currency) values(?,?,?,?,?,?,?,?,?,?,?,?,?)",
      (wid,cat[k],e,title,date,finish,memo,tag,1 if fin else 0,created,created,order[k],"KRW"))
    for j,(s,done) in enumerate(steps):
        c.execute('insert into wishStep(id,wishId,title,isDone,"order",updatedAt) values(?,?,?,?,?,?)',(str(uuid.uuid4()).upper(),wid,s,done,j,created))
    if title.startswith("양양"):
        c.execute('insert into wishNotification(id,wishId,type,time,"order",updatedAt) values(?,?,?,?,?,?)',(str(uuid.uuid4()).upper(),wid,"dayAgo",t(now.replace(hour=11,minute=0)),0,created))
db.commit(); print(c.execute("select count(*) from wish").fetchone())
