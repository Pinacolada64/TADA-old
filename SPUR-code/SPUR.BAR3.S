
; spur.bar3.s

 on nocar goto dropped
 public compile

;
vinney
 print \"Vinny glances at your books..":gosub read.a1$
 vu=0:if (g7>0) or (g8>0) vu=1
bank
 print \"Vinny the Weasel 'smiles'..."
 if vu=1 print "'I wud suggest yuse make a payment..'"
 if vu=0 print "'So, whatcha need "n1$"?'"
 print \"R)eview B)orrow P)ay S)ave W)ithdraw":Input @2 "-> "i$
 if i$="" or i$="Q" goto lv.viney
 if i$="R" goto review
 if i$="B" goto borrow
 if i$="P" goto pay
 if i$="S" goto save
 if i$="W" goto withdraw
 print \"'Eh? Say what?'":goto bank

lv.viney
 gosub writ.a1$
 if vu=1 print \"'So, yer not gonna make payment, eh?'":goto bouncer
 print \"'Well, see ya later..'"\
 goto move

review
 gosub rev.b:gosub rev.a:gosub rev.c:goto bank
rev.b
 g1=g5:g2=g6:gosub v.prt.g:print \"In Account :"gd$" gold":return
rev.a
 g1=g7:g2=g8:gosub v.prt.g:print \"Owed Vinny :"gd$" gold":return
rev.c
 g1=gh:g2=gl:gosub v.prt.g:print \"In  sack   :"gd$" gold":return

pay
 if g7<1 then if g8<1 print \"'You don't owe nuttin!'":goto bank
 gosub rev.a:gosub rev.c
 input @2 \"PAY Debt - How much? "gd$
 if gd$="" print \"Mundo smiles also...":goto bank
 gosub v.val.g:if a=0 print \"Mundo moves a bit closer!":goto bank
 gosub v.spl.g:g3=gh:g4=gl:gosub v.chk.g:if a=0 print \"You don't have that much!":goto bank
 xy=1000:if g7=0 then if g8<xy then xy=(g8/4)
 if g1=0 then if g2<xy print \"'Minimum payment is "xy" gold!'":goto bank
 if (g1=>g7) then if g2>g8 print \"'Yuse don't owe that much!'":goto bank
 gosub v.sub.g:gosub v.pay.g:gosub rev.a:vu=0
 print "'Iza plesure duin buzzniz wit ya!'":goto bank
;
withdraw
 gosub rev.b
 input @2 \"Withdraw - How much? "gd$:if gd$="" goto bank
 gosub v.val.g:if a=0 print \"Mundo inspects his bat..":goto bank
 gosub v.spl.g:g3=g5:g4=g6:gosub v.chk.g:if a=0 print \"You don't have that much!":goto bank
 gosub v.tak.g:gosub rev.b:goto bank
;
save
 gosub rev.c
 input @2 \"Save - How much? "gd$:if gd$="" goto bank
 gosub v.val.g:if a=0 print \"Mundo looks impatient..":goto bank
 gosub v.spl.g:g3=gh:g4=gl:gosub v.chk.g:if a=0 print \"You don't have that much!":goto bank
 g3=0:g4=5000:gosub v.chk.g:if a=0 print \"'5000 gold max!'":goto bank
 gosub v.put.g:goto review
;
borrow
 print \"Vinny smiles even more!"
 if g8>1000 print \"'You owe me too much already!'":goto bank
 input @2 \"'How much?' (Max 5000) "gd$:if gd$="" goto bank
 gosub v.val.g:if a=0 print \"'Huh?'":goto bank
 gosub v.spl.g
 g3=0:g4=5000:gosub v.chk.g:if a=0 print \"'I said 5000 max!'":goto bank
 g3=g1:g4=g2:g1=g1*4/3:g2=g2*4/3:gosub v.prt.g
 print \"'You will pay back "gd$;:input @2", OK? Y/N :"i$
 if i$<>"Y" print \"'Den stop bodderin me!'":goto bank
 gosub v.loan:g1=g3:g2=g4:gosub v.add.g:goto review

;.. put gold in players hands
v.add.g
 gl=gl+g2:if gl=>10000 then gl=gl-10000:gh=gh+1
 gh=gh+g1
 return

;.. take gold from players hands
v.sub.g
 if g2>gl then gl=gl+10000:gh=gh-1
 gh=gh-g1:if gh<1 gh=0
 gl=gl-g2:if gl<1 gl=0
 return

;.. borrow money
v.loan
 g7=g7+g1
 g8=g8+g2:if g8=>10000 then g8=g8-10000:g7=g7+1
 return

;.. payment on loan
v.pay.g
 if g2>g8 then g8=g8+10000:g7=g7-1
 g8=g8-g2:g7=g7-g1:if g7<1 g7=0
 if g8<1 g8=0
 return

;.. put in account
v.put.g
 g5=g5+g1
 g6=g6+g2:if g6=>10000 then g6=g6-10000:g5=g5+1
 if g2>gl then gl=gl+10000:gh=gh-1
 gh=gh-g1:if gh<1 gh=0
 gl=gl-g2:if gl<1 gl=0
 return

;.. take from account
v.tak.g
 if g2>g6 then g6=g6+10000:g5=g5-1
 g5=g5-g1:g6=g6-g2
 gh=gh+g1
 gl=gl+g2:if gl=>10000 then gl=gl-10000:gh=gh+1
 return

;.. returns gd$ for printout of gold
v.prt.g
 a$=str$(g1):gd$="0000":if g1=0 then gd$="    ":a$=" "
 gd$=right$("    "+a$,5)+right$(gd$+str$(g2),4)
 return

;.. returns g1 and g2 from gd$
v.spl.g
 gd$=right$("00000000"+gd$,9)
 g1=val(left$(gd$,5)):g2=val(right$(gd$,4))
 if g1<0 g1=0:g2=0:gd$="":print \"Number too large!"
 return

;.. compares g3 to g1 and g4 to g2 to see g3 & g4 are at least as large
v.chk.g
 a=0
 if un=1 print "g3="g3", g1="g1", g4="g4", g2="g2
 if g3>g1 then a=1:return
 if (g3=g1) and (g4=>g2) then a=1:return
 return

v.val.g
 l=len(gd$)
 for i=1 to l:a=instr(mid$(gd$,i,1),"0123456789")
 if (not a) then i=l:next:return
 next:return
 
bouncer
 print \'
At a signal, Mundo the bouncer knocks you over the head with a baseball bat,
and throws you out in the street..':if hp>6 hp=hp-5
 goto advent

advent
 i=0:zv$=""
 print \"You return to the street.."
 dy$=dz$+"spur.main":link dy$
;
dropped
 i$="SPUR.BAR3"
 dy$=ds$+"spur.logon"
 link dy$,"quit3"
;
show.file
 setint(1):print \s$\:copy f$:setint(""):return
;
read.a1$
 dy$=dx$+"spur.a1$":open #1,dy$
 position #1,64,un
 input #1,g5,g6,g7,g8,g9,g9,g0
 close:return
;
writ.a1$
 dy$=dx$+"spur.a1$":open #1,dy$
 position #1,64,un
 print #1,g5,g6,g7,g8,pn,g9,g0
 close:return
;
move
 dy$=ds$+"spur.bar":link dy$,"restart"
;
compile
 if un=1 print "Compiled..":link "k:system.seg"
 return
;
 :a$=" "
 gd$=right$("    "+a$,5)+right$(gd$+str$(g2),4)
 return
 
chk.gold
 a=0
 if g3>g1 then a=1:return
 if (g3=g1) and (g4=>g2) then a=1:return
 return
;
read.a1$
 dy$=dx$+"spur.a1$":open #1,dy$
 position #1,64,un
 input #1,g5,g6,g7,g8,g9,g9,g0
 close:return
;
writ.a1$
 dy$=dx$+"spur.a1$":open #1,dy$
 position #1,64,un
 print #1,g5,g6,g7,g8,pn,g9,g0
 close:return
;
compile
 if un=1 print "Compiled..":link "k:system.seg"
 return
;
