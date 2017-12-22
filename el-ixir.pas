uses mycrt,Mouse;{$R+}
type
  tpole=array[0..5] of string;
  tscreen=array of array of array[0..1] of string;
var
  SX,SY,SX2:integer;
const
  czas1=550;        { czas na wybór }
  czas2=250;        { czas przy punktacji }
  czas3=400;        { czas przy embransie }
  czas4=100;        { czas przy zapelnianiu pól 1..4}
  fanim=5;          { ilość faz animacji }
  b0=#$70;
  strzalki:array[0..3] of tpole=
            ((' ',b0,'←',b0,' ',b0),
             (' ',b0,'↑',b0,' ',b0),
             (' ',b0,'→',b0,' ',b0),
             (' ',b0,'↓',b0,' ',b0));
  cyfry:array[0..3] of tpole=
            ((' ',b0,'1',b0,' ',b0),
             (' ',b0,'2',b0,' ',b0),
             (' ',b0,'3',b0,' ',b0),
             (' ',b0,'4',b0,' ',b0));
  pustka:tpole=(' ',#7,' ',#7,' ',#7);
  cz:tpole=(' ',#7,'•',#7,' ',#7);
  kierx:array[0..3] of integer=(-1,0,1,0);
  kiery:array[0..3] of integer=(0,-1,0,1);
  pc1=5;
  pc2=7;
  col:array[0..8] of byte=($07,$1c,$61,$1a,$20,$35,$40,$5d,7);
  colw:array[0..8] of byte=($08,$18,$60,$12,$28,$34,$4d,$5c,8);
  gcz=3;
  czx=14;
  czy=3;
  cy=10;
  cx1=3;
  py=4;
var
  kon:boolean;
  fast:boolean;
  rczasu:integer;
  czas:array[1..2] of integer;
  c1,c2:char;
  polet1,polet2,poler:tpole;
  polew,polez,polerz:array[1..2] of tpole;
  c1w,c2w:char;

procedure setcolors;
const
  ct1_mono=#$0f;
  ct2_mono=#$07;
  ct0_mono=#$70;
  polet1_mono:tpole=('▒',ct1_mono,'▒',ct1_mono,'▒',ct1_mono);
  polet2_mono:tpole=('▓',ct2_mono,'▓',ct2_mono,'▓',ct2_mono);
  poler_mono:tpole=(' ',ct0_mono,'Θ',ct0_mono,' ',ct0_mono);
  procedure p(var t:tpole;s1,a1,s2,a2,s3,a3:string);
  begin
    t[0]:=s1;
    t[1]:=a1;
    t[2]:=s2;
    t[3]:=a2;
    t[4]:=s3;
    t[5]:=a3;
  end;
begin
        polet1:=polet1_mono;
        polet2:=polet2_mono;
        poler:=poler_mono;
        p(polew[1], ' ',c1w,'•',c1w,' ',c1w);
        p(polez[1], ' ',c1, '•',c1, ' ',c1);
        p(polerz[1],' ',c1, 'Ω',c1, ' ',c1);
        p(polew[2], ' ',c2w,'•',c2w,' ',c2w);
        p(polez[2], ' ',c2, '•',c2, ' ',c2);
        p(polerz[2],' ',c2, 'Ω',c2, ' ',c2)
end;

var
  sco:array[1..2] of integer;
  screen:tscreen;
  tabl,tabl1:array[0..15,0..15] of integer;
  stos:array[1..196] of record x,y:byte end;
  ws1,ws2:integer;
  em:boolean;

procedure delay(ms:integer);
begin
  if fast
    then exit;
  mycrt.delay(ms);
end;


var
  vx,vy:integer;

procedure gotoxy(x,y:integer);
begin
  vx:=x;
  vy:=y;
end;

procedure outtext(txt:string);
var
  i:integer;
begin
  for i:=1 to length(txt)
    do begin
         if txt[i]<' '
           then txt[i]:='?';
         screen[vy,vx+i-1,0]:=txt[i];
         screen[vy,vx+i-1,1]:=char(TextAttr);
       end;
  mycrt.gotoxy(vx,vy);
  crtwrite(txt);
end;

procedure draw(x,y:integer;p:tpole);
  procedure c(s:string);
  begin
    if s=''
      then TextAttr:=7
      else TextAttr:=ord(s[1]);
  end;
var
  i:integer;
begin
  for i:=0 to 5
    do screen[y,x+(i div 2),i mod 2]:=p[i];
  mycrt.gotoxy(x,y);
  c(p[1]);
  crtwrite(p[0]);
  c(p[3]);
  crtwrite(p[2]);
  c(p[5]);
  crtwrite(p[4]);
end;

procedure czyscstos;
begin
  ws1:=0;
  ws2:=0
end;

procedure poloznastos(x,y:integer);
begin
  inc(ws1);
  stos[ws1].x:=x;
  stos[ws1].y:=y
end;

procedure wyswczas(gr:integer);
var
  m,n:integer;
  txt:string[20];
begin
  case rczasu of
   1:begin
       textattr:=$70;
       if gr=1
         then m:=czx
         else m:=SX-czx-gcz*14;
       for n:=1 to 14
         do draw(m-gcz+n*gcz,czy,cz)
     end;
   2:begin
       textattr:=7;
       if gr=1
         then gotoxy(cx1+1,cy)
         else gotoxy(SX-cx1-5+1,cy);
       outtext('Time:');
       if gr=1
         then gotoxy(cx1+2,     cy+2)
         else gotoxy(SX-cx1-5+2,cy+2);
       str(czas[gr]:3, txt);
       outtext(txt)
     end;
  end;
end;

procedure poprczas(gr:integer);
var
  txt:string[20];
begin
  case rczasu of
   1:begin
       textattr:=$70;
       if gr=1
         then draw(czx+czas[gr]*gcz,czy,pustka)
         else draw(SX-czx-gcz-czas[gr]*gcz,czy,pustka)
     end;
   2:begin
       textattr:=7;
       if gr=1
         then gotoxy(cx1+2,     cy+2)
         else gotoxy(SX-cx1-5+2,cy+2);
       str(czas[gr]:3, txt);
       outtext(txt)
    end;
  end;
end;

procedure czyscczas(gr:integer);
var
  m,n:integer;
begin
  case rczasu of
    1:begin
        textattr:=$70;
        if gr=1
          then m:=czx
          else m:=SX-czx-gcz*14;
        for n:=1 to 14
          do draw(m-gcz+n*gcz,czy,pustka)
      end;
   end;
end;

function bylklawisz(wczas:boolean;gr:integer):boolean;
var
  ch:char;
begin
  if not (kon or wczas)
    then waitkey;
  if keypressed or kon
    then begin
           while keypressed
             do ch:=readkey;
           if ch='q'
             then begin
                    kon:=true;
                    fast:=true
                  end;
           if ch=#9
             then fast:=true;
           bylklawisz:=true
         end
    else if (GetMouseButtons and 1)<>0
           then bylklawisz:=true
           else if wczas and (rczasu>0)
                  then begin
                         dec(czas[gr]);
                         if czas[gr]<0
                           then begin
                                  czas[gr]:=0;
                                  bylklawisz:=true
                                end
                           else begin
                                  poprczas(gr);
                                  bylklawisz:=false
                                end
                       end
                  else bylklawisz:=false
end;

procedure pisznapolu(x,y:integer;co:tpole);
begin
  draw(SX2-23+3*x,4+y,co);
end;

procedure czyscpole(x,y:integer);
begin
  if ((x=1) or (x=14)) and ((y=1) or (y=14))
    then pisznapolu(x,y,poler)
    else if odd(x+y)
           then pisznapolu(x,y,polet1)
           else pisznapolu(x,y,polet2)
end;

procedure zapelnpole(x,y,gr:integer);
begin
  if ((x=1) or (x=14)) and ((y=1) or (y=14))
    then pisznapolu(x,y,polerz[gr])
    else pisznapolu(x,y,polez[gr])
end;

var
  x,y:integer;
  dl,m,n,ilp:integer;
  polaw:integer;
  pola:array[1..4] of record x,y:integer end;
  an:array[1..2] of integer;

procedure anim(x,y,gr:integer);
var
  x0,y0,x1,y1:integer;
  xc,yc:integer;
  n,i:integer;
  tmp:tpole;
  ilr:integer;
const
  rogi:array[1..4,1..2] of integer=((1,1),(14,1),(14,14),(1,14));
begin
  ilr:=0;
  for n:=1 to 4
    do if tabl[rogi[n,1],rogi[n,2]]=gr*2
         then inc(ilr);
  if ilr=0
    then begin
           zapelnpole(x,y,gr);
           delay(czas3);
           exit
         end;
  an[gr]:=an[gr] mod ilr+1;
  ilr:=0;
  for n:=1 to 4
    do if tabl[rogi[n,1],rogi[n,2]]=gr*2
         then begin
                inc(ilr);
                if ilr=an[gr]
                  then begin
                         x0:=rogi[n,1];
                         y0:=rogi[n,2]
                       end
              end;
  y1:=py+y;
  x1:=SX2-23+3*x;
  y0:=py+y0;
  x0:=SX2-23+3*x0;
  for n:=0 to fanim
    do begin
         xc:=x0+longint((x1-x0))*n div fanim;
         yc:=y0+longint((y1-y0))*n div fanim;
         for i:=0 to 5
           do tmp[i]:=screen[yc,xc+(i div 2),i mod 2];
         draw(xc,yc,polez[gr]);
         delay(czas3 div (fanim+1));
         draw(xc,yc,tmp);
       end;
  zapelnpole(x,y,gr)
end;

function jednakowe:boolean;
begin
  for x:=1 to 14
    do for y:=1 to 14
         do if tabl[x,y]<>tabl1[x,y]
              then begin
                     jednakowe:=false;
                     exit
                   end;
  jednakowe:=true
end;

procedure komunikat(gr:integer;str:string);
begin
  gotoxy(SX2-1-length(str) div 2,SY-4);
  if gr=1
    then textattr:=byte(c1)
    else if gr=2
           then textattr:=byte(c2)
           else textattr:=byte(b0);
  outtext(' '+str+' ')
end;

procedure czkom;
begin
  textattr:=7;
  gotoxy(SX2-10,SY-4);
  outtext('                    ')
end;

procedure kunc;
begin
  if sco[1]>sco[2]
    then komunikat(1,'EL-IXIR')
    else if sco[1]<sco[2]
           then komunikat(2,'EL-IXIR')
           else komunikat(0,'EL-IXIR');
  bylklawisz(false,0);
  kon:=true
end;

procedure oznaczgracza(gr:integer);
var
  x:integer;
begin
  if gr=1
    then x:=2
    else x:=SX-7;
  draw(x,6,polez[gr]);
  draw(x+2,6,polez[gr]);
  draw(x,7,polez[gr]);
  draw(x+2,7,polez[gr]);
  if gr=1
    then x:=SX-7
    else x:=2;
  draw(x,6,pustka);
  draw(x+2,6,pustka);
  draw(x,7,pustka);
  draw(x+2,7,pustka);
end;

procedure score(gr:integer);
var
  x:integer;
  n:integer;
begin
  if gr=1
    then textattr:=byte(c1)
    else textattr:=byte(c2);
  if gr=1
    then x:=9
    else x:=SX-10;
  gotoxy(x-2,2);
  outtext('Score');
  textattr:=7;
  if sco[gr]>99
    then n:=0
    else if sco[gr]>9
           then n:=1
           else n:=2;
  if sco[gr]>99
    then begin
           gotoxy(x,4);
           outtext('1')
         end;
  if sco[gr]>9
    then begin
           gotoxy(x,5-n);
           outtext(char(ord('0')+sco[gr] div 10 mod 10))
         end;
  gotoxy(x,6-n);
  outtext(char(ord('0')+sco[gr] mod 10))
end;

procedure przejedzizapal(gr:integer;kom:string);
  procedure sprawdz(x,y:integer);
  begin
    if tabl1[x,y]=gr*2-1
      then begin
             poloznastos(x,y);
             tabl1[x,y]:=gr*2
           end
  end;
begin
  tabl1:=tabl;
  for x:=1 to 14
    do for y:=1 to 14
         do if tabl1[x,y]=gr*2
              then tabl1[x,y]:=gr*2-1;
  czyscstos;
  sprawdz(1,1);
  sprawdz(1,14);
  sprawdz(14,1);
  sprawdz(14,14);
  while ws1>ws2
    do begin
         inc(ws2);
         x:=stos[ws2].x;
         y:=stos[ws2].y;
         sprawdz(x+1,y);
         sprawdz(x-1,y);
         sprawdz(x,y+1);
         sprawdz(x,y-1)
       end;
  if not jednakowe
    then begin
           komunikat(gr,kom);
           for x:=1 to 14
             do for y:=1 to 14
                  do if tabl1[x,y]<>tabl[x,y]
                       then begin
                              inc(sco[gr]);
                              score(gr);
                              delay(czas2)
                            end;
           tabl:=tabl1;
           czkom
         end;
end;

procedure completeembrace(gr:integer);
var
  b:boolean;
  x1,y1:integer;
  procedure sprawdz(x,y:integer);
  begin
    if tabl1[x,y]=0
      then begin
             poloznastos(x,y);
             tabl1[x,y]:=-1
           end
  end;
  procedure sprawdz1(x,y:integer);
  begin
    if tabl1[x,y]=0
      then begin
             poloznastos(x,y);
             tabl1[x,y]:=-2;
             if (tabl[x-1,y]=gr*2) or
                  (tabl[x+1,y]=gr*2) or
                  (tabl[x,y-1]=gr*2) or
                  (tabl[x,y+1]=gr*2)
               then b:=true
           end
  end;
begin
  tabl1:=tabl;
  for x:=1 to 14
    do for y:=1 to 14
         do if tabl1[x,y]=gr*2
              then tabl1[x,y]:=gr*2-1;
  for x:=1 to 14
    do for y:=1 to 14
         do if tabl1[x,y]<>gr*2-1
              then tabl1[x,y]:=0;
  czyscstos;
  sprawdz(1,1);
  sprawdz(1,14);
  sprawdz(14,1);
  sprawdz(14,14);
  while ws1>ws2
    do begin
         inc(ws2);
         x:=stos[ws2].x;
         y:=stos[ws2].y;
         sprawdz(x+1,y);
         sprawdz(x-1,y);
         sprawdz(x,y+1);
         sprawdz(x,y-1);
         sprawdz(x+1,y+1);
         sprawdz(x-1,y-1);
         sprawdz(x-1,y+1);
         sprawdz(x+1,y-1)
       end;
  b:=false;
  for x:=1 to 14
    do for y:=1 to 14
         do if tabl1[x,y]=0
              then begin
                     x1:=x;
                     y1:=y;
                     b:=true
                   end;
  if b
    then begin
           b:=false;
           czyscstos;
           sprawdz1(x1,y1);
           while ws1>ws2
             do begin
                  inc(ws2);
                  x:=stos[ws2].x;
                  y:=stos[ws2].y;
                  sprawdz1(x+1,y);
                  sprawdz1(x-1,y);
                  sprawdz1(x,y+1);
                  sprawdz1(x,y-1)
                end;
           komunikat(gr,'Complete Embrace');
           em:=true;
           for y:=1 to 14
             do for x:=1 to 14
                  do if tabl1[x,y]=-2
                       then begin
                              if tabl[x,y]=0
                                then dec(polaw);
                               if b
                                then begin
                                       inc(sco[gr]);
                                       score(gr);
                                       tabl[x,y]:=gr*2
                                     end
                                else tabl[x,y]:=gr*2-1;
                              anim(x,y,gr)
                            end;
           przejedzizapal(gr,'Complete Embrace');
           czkom
         end;
end;

procedure anchorembrace(gr:integer);
var
  b:boolean;
  x1,y1:integer;
  procedure sprawdz(x,y:integer);
  begin
    if tabl1[x,y]=-3
      then begin
             poloznastos(x,y);
             tabl1[x,y]:=-1
           end
  end;
  procedure sprawdz1(x,y:integer);
  begin
    if tabl[x,y]=(3-gr)*2
      then begin
             poloznastos(x,y);
             tabl1[x,y]:=-1
           end
  end;
  procedure sprawdz2(x,y:integer);
  begin
    if tabl1[x,y]=-3
      then begin
             poloznastos(x,y);
             tabl1[x,y]:=-2
           end
  end;
begin
  tabl1:=tabl;
  for x:=1 to 14
    do for y:=1 to 14
         do if (tabl1[x,y]<>gr*2) and (tabl1[x,y]<>0)
              then tabl1[x,y]:=-3;
  czyscstos;
  for y:=1 to 14
    do for x:=1 to 14
         do if tabl[x,y]=0
              then begin
                     poloznastos(x,y);
                     tabl1[x,y]:=-1
                   end;
  sprawdz1(1,1);
  sprawdz1(1,14);
  sprawdz1(14,1);
  sprawdz1(14,14);
  while ws1>ws2
    do begin
         inc(ws2);
         x:=stos[ws2].x;
         y:=stos[ws2].y;
         sprawdz(x+1,y);
         sprawdz(x-1,y);
         sprawdz(x,y+1);
         sprawdz(x,y-1)
       end;
  b:=false;
  for y:=1 to 14
    do for x:=1 to 14
         do if tabl1[x,y]=-3
              then begin
                     x1:=x;
                     y1:=y;
                     b:=true
                   end;
  if b
    then begin
           czyscstos;
           sprawdz2(x1,y1);
           while ws1>ws2
             do begin
                  inc(ws2);
                  x:=stos[ws2].x;
                  y:=stos[ws2].y;
                  sprawdz2(x+1,y);
                  sprawdz2(x-1,y);
                  sprawdz2(x,y+1);
                  sprawdz2(x,y-1)
                end;
           komunikat(gr,'Anchoring Embrace');
           em:=true;
           for y:=1 to 14
             do for x:=1 to 14
                  do if tabl1[x,y]=-2
                       then begin
                              if tabl[x,y]=0
                                then dec(polaw);
                              inc(sco[gr]);
                              score(gr);
                              tabl[x,y]:=gr*2;
                              anim(x,y,gr)
                            end;
           przejedzizapal(gr,'Anchoring Embrace');
           czkom
         end;
end;

procedure ruch(gr:integer);
label emb;
begin
  if polaw<4
    then ilp:=polaw
    else ilp:=4;
  if rczasu=1
    then czas[gr]:=14;
  wyswczas(gr);
  for n:=1 to ilp
    do begin
         repeat
           x:=random(14)+1;
           y:=random(14)+1;
         until tabl[x,y]=0;
         tabl[x,y]:=-1;
         pola[n].x:=x;
         pola[n].y:=y
       end;
  n:=1;
  if ilp>1
    then repeat
          with pola[n]
            do czyscpole(x,y);
          inc(n);
          if n>ilp
            then n:=1;
          with pola[n]
            do pisznapolu(x,y,polew[gr]);
          delay(czas1);
         until bylklawisz(true,gr);
  for m:=1 to ilp
    do with pola[m]
         do tabl[x,y]:=0;
  x:=pola[n].x;
  y:=pola[n].y;
  if (tabl[x+1,y]=0) or
     (tabl[x-1,y]=0) or
     (tabl[x,y+1]=0) or
     (tabl[x,y-1]=0)
    then begin
           if rczasu=1
             then begin
                    czas[gr]:=14;
                    wyswczas(gr)
                  end;
           n:=random(4);
           repeat
             n:=succ(n) mod 4;
             pisznapolu(x,y,strzalki[n]);
             delay(czas1);
           until bylklawisz(true,gr);
           m:=n;
           n:=1;
           if rczasu=1
             then begin
                    czas[gr]:=14;
                    wyswczas(gr)
                  end;
           repeat
             n:=(n+2) mod 4+1;
             pisznapolu(x,y,cyfry[n-1]);
             delay(czas1);
           until bylklawisz(true,gr)
         end
    else m:=0;
  czyscczas(gr);
  dl:=n;
  n:=0;
  repeat
    tabl[x+n*kierx[m],y+n*kiery[m]]:=gr*2-1;
    zapelnpole(x+n*kierx[m],y+n*kiery[m],gr);
    delay(czas4);
    dec(polaw);
    inc(n);
  until (n=dl) or (tabl[x+n*kierx[m],y+n*kiery[m]]>0);
  przejedzizapal(gr,'Anchoring Chain');
emb:
  em:=false;
  completeembrace(gr);
  anchorembrace(3-gr);
  anchorembrace(gr);
  if em
    then goto emb;
end;

procedure fajrant;
begin
  write(#27'[0m'#27'[2J'#27'[0;0f');
  cursorin;
  DoneMouse;
  halt
end;

procedure menu;
var
  m,n:integer;
  ch:char;
  play:boolean;
  sel:boolean;
  gr:integer;
const
  min=2;
  wybory:array[min..24] of string[15]=(
                       ' EL-IXIR ',
                       ' EL-IXIR ',
                       ' EL-IXIR ',
                       ' EL-IXIR ',
                       ' EL-IXIR ',
                       ' EL-IXIR ',
                       ' EL-IXIR ',
                       ' EL-IXIR ',
                       ' EL-IXIR ',
                       '',
                       'Player 1',
                       'Player 2',
                       '',
                       'TIME:',
                       'For one move',
                       'For all game',
                       'No limit',
                       '',
                       '',
                       'Standard colors',
                       '',
                       'Play game',
                       'Exit to DOS');
  opcje:array[boolean] of set of byte=
                 ([12,13,16,17,18,21,23,24],
                  [2,3,4,5,6,7,8,9,12,13,21,24]);
begin
  n:=23;
  sel:=false;
  repeat
    textattr:=7;
    clrscr;
    cursorout;
    for m:=12 to 24
      do begin
           gotoxy(SX2+2-length(wybory[m]) div 2,m);
           outtext(wybory[m])
         end;
    for m:=2 to 10
      do begin
           textattr:=col[m-2];
           gotoxy(SX2+2-length(wybory[m]) div 2,m);
           outtext(wybory[m])
         end;
    if rczasu=0
      then gotoxy(SX2+11,18)
      else gotoxy(SX2+11,rczasu+15);
    outtext('√');
    gotoxy(22,12);
    textattr:=byte(c1);
    if sel and (gr=1)
      then outtext(' ??????? ')
      else outtext(' EL-IXIR ');
    gotoxy(SX-26,13);
    textattr:=byte(c2);
    if sel and (gr=2)
      then outtext(' ??????? ')
      else outtext(' EL-IXIR ');
    play:=false;
    repeat
      gotoxy(SX2-5,n);
      textattr:=$70;
      outtext('               ');
      gotoxy(SX2+2-length(wybory[n]) div 2,n);
      outtext(wybory[n]);
      ch:=readkey;
      gotoxy(SX2-5,n);
      textattr:=$07;
      outtext('               ');
      if n<11
        then textattr:=col[n-2];
      gotoxy(SX2+2-length(wybory[n]) div 2,n);
      outtext(wybory[n]);
      case ch of
        #0:begin
             ch:=readkey;
             case ch of
               #72:repeat
                     if n>min
                       then dec(n)
                       else n:=24;
                   until n in opcje[sel];
               #80:repeat
                     if n<24
                       then inc(n)
                       else n:=min
                   until n in opcje[sel];
              end;
           end;
        #27:begin
              ch:=readkey;
              case ch of
                '[':case readkey of
                      'A':repeat
                            if n>min
                              then dec(n)
                              else n:=24;
                          until n in opcje[sel];
                      'B':repeat
                            if n<24
                              then inc(n)
                              else n:=min
                          until n in opcje[sel];
                    end;
                #27:fajrant;
              end;
            end;
        'q':fajrant;
       end;
    until (ch=#13) or (ch=' ');
    textattr:=7;
    clrscr;
    case n of
     24:fajrant;
     23:play:=true;
     21:begin
          c1:=char(col[pc1]);
          c2:=char(col[pc2]);
          c1w:=char(colw[pc1]);
          c2w:=char(colw[pc2]);
          setcolors;
          sel:=false
        end;
     18:rczasu:=0;
     17:rczasu:=2;
     16:rczasu:=1;
     13:begin
          sel:=true;
          gr:=2
        end;
     12:begin
          sel:=true;
          gr:=1
        end;
     2..10:if ((gr=1) and (c2<>char(col[n-2]))) or
              ((gr=2) and (c1<>char(col[n-2])))
             then begin
                    sel:=false;
                    if gr=1
                      then begin
                             c1:=char(col[n-2]);
                             c1w:=char(colw[n-2]);
                             n:=13;
                           end
                      else begin
                             c2:=char(col[n-2]);
                             c2w:=char(colw[n-2]);
                             n:=12;
                           end;
                    setcolors;
                  end;
    end;
  until play
end;


procedure setsize;
var
  i:integer;
begin
  SX:=ScreenWidth;
  SY:=ScreenHeight;
  SX2:=SX div 2;
  SetLength(screen, SY+1);
  for i:=1 to SY
    do SetLength(screen[i], SX+1);
end;


begin
  rczasu:=0;
  InitMouse;
  setsize;
  c1:=char(col[pc1]);
  c2:=char(col[pc2]);
  c1w:=char(colw[pc1]);
  c2w:=char(colw[pc2]);
  setcolors;
  repeat
    menu;
    czas[1]:=400;
    czas[2]:=400;
    kon:=false;
    sco[1]:=0;
    sco[2]:=0;
    cursorout;
    randomize;
    textattr:=7;
    clrscr;
    for x:=1 to 14
      do for y:=1 to 14
           do czyscpole(x,y);
    if rczasu=2
      then begin
             wyswczas(1);
             wyswczas(2)
           end;
    for x:=0 to 15
      do for y:=0 to 15
           do tabl[x,y]:=127;
    for x:=1 to 14
      do for y:=1 to 14
           do tabl[x,y]:=0;
    polaw:=196;
    fast:=false;
    repeat
      komunikat(1,'Press any key');
      oznaczgracza(1);
      bylklawisz(false,0);
      czkom;
      ruch(1);
      if kon or (polaw=0) or (sco[1]>98) or (sco[2]>98)
        then break;
      komunikat(2,'Press any key');
      oznaczgracza(2);
      bylklawisz(false,0);
      czkom;
      ruch(2);
    until kon or (polaw=0) or (sco[1]>98) or (sco[2]>98);
    kunc;
  until false
end.
