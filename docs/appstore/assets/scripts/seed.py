"""예시 위시를 넣는다. 사용: seed.py <App Group dev.sqlite> [언어(ko|en-US|ja|zh-Hans|zh-Hant)]
제목·메모·단계 문구는 l10n/copy.json의 언어별 seed·memo·steps에서 읽는다 (GH-117)."""
import sqlite3,sys,uuid,json,os,datetime as dt
REF=dt.datetime(2001,1,1)
def t(d): return (d-REF).total_seconds()
now=dt.datetime.now().replace(hour=9,minute=41,second=0,microsecond=0)
def day(n,h=23,m=59): return t((now+dt.timedelta(days=n)).replace(hour=h,minute=m,second=0))
lang=sys.argv[2] if len(sys.argv)>2 else "ko"
copy=json.load(open(os.path.join(os.path.dirname(__file__),"..","l10n","copy.json")))[lang]
currency={"ko":"KRW","en-US":"USD","ja":"JPY","zh-Hans":"CNY","zh-Hant":"TWD"}[lang]
db=sqlite3.connect(sys.argv[1]); c=db.cursor()
c.execute("delete from wish"); c.execute("delete from wishStep"); c.execute("delete from wishNotification"); c.execute("delete from wishSaving"); c.execute("delete from wishJournal")
W=[ # cat, emoji, dday, hashtag, finishedDaysAgo, 서핑 위시(메모·단계·알림)
("do","🏃",12,"sports",None,False),
("do","🏄",24,"trip",None,True),
("do","📷",40,"hobby",None,False),
("do","🎹",60,"hobby",None,False),
("do","🧶",None,"hobby",None,False),
("do","🍷",None,"life",None,False),
("get","🎧",2,"shopping",None,False),
("get","⌚️",30,"sports",None,False),
("get","🪴",None,"life",None,False),
("go","⛺️",18,"leisure",None,False),
("go","🗻",35,"trip",None,False),
("do","📚",None,"hobby",13,False),
("do","🍰",None,"hobby",28,False),
("do","🚴",None,"sports",43,False),
("go","🌅",None,"trip",75,False),
("get","🎒",None,"shopping",100,False),
("do","🏊",None,"sports",130,False),
]
cat={"do":"category_want_to_do","get":"category_want_to_get","go":"category_want_to_go"}
order={}
for i,((k,e,dd,tag,fin,surf),title) in enumerate(zip(W,copy["seed"])):
    wid=str(uuid.uuid4()).upper(); order[k]=order.get(k,0)+1
    created=t(now-dt.timedelta(days=60-i))
    date=day(dd) if dd is not None else (day(-fin) if fin else None)
    finish=day(-fin,20,0) if fin else None
    c.execute("insert into wish(id,category,emoji,title,date,finishDate,memo,hashtag,isSuccess,createdAt,updatedAt,manualOrder,currency) values(?,?,?,?,?,?,?,?,?,?,?,?,?)",
      (wid,cat[k],e,title,date,finish,copy["memo"] if surf else "",tag,1 if fin else 0,created,created,order[k],currency))
    if surf:
        for j,s in enumerate(copy["steps"]):
            c.execute('insert into wishStep(id,wishId,title,isDone,"order",updatedAt) values(?,?,?,?,?,?)',(str(uuid.uuid4()).upper(),wid,s,1 if j==0 else 0,j,created))
        c.execute('insert into wishNotification(id,wishId,type,time,"order",updatedAt) values(?,?,?,?,?,?)',(str(uuid.uuid4()).upper(),wid,"dayAgo",t(now.replace(hour=11,minute=0)),0,created))
    print(wid,title)
db.commit()
