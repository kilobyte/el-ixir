uses mycrt,Mouse;{$R+}
type
  tsquare=array[0..5] of string;
  tscreen=array of array of array[0..1] of string;
var
  SX,SY,SX2:integer;
const
  delay1=550;       { delay when cycling between options }
  delay2=250;       { score increment delay }
  delay3=400;       { embrace delay }
  delay4=100;       { delay when placing parts of a stone }
  fanim=5;          { # of animation phases }
  b0=#$70;
  arrows:array[0..3] of tsquare=
            ((' ',b0,'←',b0,' ',b0),
             (' ',b0,'↑',b0,' ',b0),
             (' ',b0,'→',b0,' ',b0),
             (' ',b0,'↓',b0,' ',b0));
  digits:array[0..3] of tsquare=
            ((' ',b0,'1',b0,' ',b0),
             (' ',b0,'2',b0,' ',b0),
             (' ',b0,'3',b0,' ',b0),
             (' ',b0,'4',b0,' ',b0));
  empty:tsquare=(' ',#7,' ',#7,' ',#7);
  timem:tsquare=(' ',#7,'•',#7,' ',#7);
  dirx:array[0..3] of integer=(-1,0,1,0);
  diry:array[0..3] of integer=(0,-1,0,1);
  wtl=3;            { width of time indicator }
  tlmx=14; tlmy=3;  { pos of time limit indicator, per move }
  tlgx1=3; tlgy=10; { pos of time limit indicator, per game }
  py=4;
  cb1=#$0f;
  cb2=#$07;
  ct0=#$70;
  c1= #$1a;
  c1s=#$12;
  c2= #$5d;
  c2s=#$5c;
  sqb1:tsquare=('▒',cb1,'▒',cb1,'▒',cb1);
  sqb2:tsquare=('▓',cb2,'▓',cb2,'▓',cb2);
  sqc:tsquare=(' ',ct0,'Θ',ct0,' ',ct0);
  sqs:array[1..2] of tsquare=
    ((' ',c1s,'•',c1s,' ',c1s), (' ',c2s,'•',c2s,' ',c2s));
  sqf:array[1..2] of tsquare=
    ((' ',c1 ,'•',c1 ,' ',c1 ), (' ',c2 ,'•',c2 ,' ',c2 ));
  sqcf:array[1..2] of tsquare=
    ((' ',c1 ,'Ω',c1 ,' ',c1 ), (' ',c2 ,'Ω',c2 ,' ',c2 ));
  col:array[1..2] of byte=(ord(c1),ord(c2));
var
  quitting:boolean;
  fast:boolean;
  tl_kind:integer;
  tlimit:array[1..2] of integer;
  sco:array[1..2] of integer;
  screen:tscreen;
  board,board1:array[0..15,0..15] of integer;
  stack:array[1..196] of record x,y:byte end;
  sp1,sp2:integer;
  em:boolean; { just embraced? }
  freesq:integer;
  an:array[1..2] of integer;
  vx,vy:integer; { virtual cursor's position }

procedure delay(ms:integer);
begin
  if fast
    then exit;
  mycrt.delay(ms);
end;

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

procedure draw(x,y:integer;p:tsquare);
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

procedure clearstack;
begin
  sp1:=0;
  sp2:=0
end;

procedure pushstack(x,y:integer);
begin
  inc(sp1);
  stack[sp1].x:=x;
  stack[sp1].y:=y
end;

procedure showtime(pl:integer);
var
  m,n:integer;
  txt:string[20];
begin
  case tl_kind of
   1:begin
       textattr:=$70;
       if pl=1
         then m:=tlmx
         else m:=SX-tlmx-wtl*14;
       for n:=1 to 14
         do draw(m-wtl+n*wtl,tlmy,timem)
     end;
   2:begin
       textattr:=7;
       if pl=1
         then gotoxy(tlgx1+1,tlgy)
         else gotoxy(SX-tlgx1-5+1,tlgy);
       outtext('Time:');
       if pl=1
         then gotoxy(tlgx1+2,     tlgy+2)
         else gotoxy(SX-tlgx1-5+2,tlgy+2);
       str(tlimit[pl]:3, txt);
       outtext(txt)
     end;
  end;
end;

procedure showdectime(pl:integer);
var
  txt:string[20];
begin
  case tl_kind of
   1:begin
       textattr:=$70;
       if pl=1
         then draw(tlmx+tlimit[pl]*wtl,tlmy,empty)
         else draw(SX-tlmx-wtl-tlimit[pl]*wtl,tlmy,empty)
     end;
   2:begin
       textattr:=7;
       if pl=1
         then gotoxy(tlgx1+2,     tlgy+2)
         else gotoxy(SX-tlgx1-5+2,tlgy+2);
       str(tlimit[pl]:3, txt);
       outtext(txt)
    end;
  end;
end;

procedure cleartime(pl:integer);
var
  m,n:integer;
begin
  case tl_kind of
    1:begin
        textattr:=$70;
        if pl=1
          then m:=tlmx
          else m:=SX-tlmx-wtl*14;
        for n:=1 to 14
          do draw(m-wtl+n*wtl,tlmy,empty)
      end;
   end;
end;

function waskey(timed:boolean;pl:integer):boolean;
var
  ch:char;
begin
  if not (quitting or timed)
    then waitkey;
  if keypressed or quitting
    then begin
           while keypressed
             do ch:=readkey;
           if ch='q'
             then begin
                    quitting:=true;
                    fast:=true
                  end;
           if ch=#9
             then fast:=true;
           waskey:=true
         end
    else if (GetMouseButtons and 1)<>0
           then waskey:=true
           else if timed and (tl_kind>0)
                  then begin
                         dec(tlimit[pl]);
                         if tlimit[pl]<0
                           then begin
                                  tlimit[pl]:=0;
                                  waskey:=true
                                end
                           else begin
                                  showdectime(pl);
                                  waskey:=false
                                end
                       end
                  else waskey:=false
end;

procedure drawsquare(x,y:integer;w:tsquare);
begin
  draw(SX2-23+3*x,4+y,w);
end;

procedure clearsquare(x,y:integer);
begin
  if ((x=1) or (x=14)) and ((y=1) or (y=14))
    then drawsquare(x,y,sqc)
    else if odd(x+y)
           then drawsquare(x,y,sqb1)
           else drawsquare(x,y,sqb2)
end;

procedure fillsquare(x,y,pl:integer);
begin
  if ((x=1) or (x=14)) and ((y=1) or (y=14))
    then drawsquare(x,y,sqcf[pl])
    else drawsquare(x,y,sqf[pl])
end;


procedure anim(x,y,pl:integer);
var
  x0,y0,x1,y1:integer;
  xc,yc:integer;
  n,i:integer;
  tmp:tsquare;
  numc:integer;
const
  corners:array[1..4,1..2] of integer=((1,1),(14,1),(14,14),(1,14));
begin
  numc:=0;
  for n:=1 to 4
    do if board[corners[n,1],corners[n,2]]=pl*2
         then inc(numc);
  if numc=0
    then begin
           fillsquare(x,y,pl);
           delay(delay3);
           exit
         end;
  an[pl]:=an[pl] mod numc+1;
  numc:=0;
  for n:=1 to 4
    do if board[corners[n,1],corners[n,2]]=pl*2
         then begin
                inc(numc);
                if numc=an[pl]
                  then begin
                         x0:=corners[n,1];
                         y0:=corners[n,2]
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
         draw(xc,yc,sqf[pl]);
         delay(delay3 div (fanim+1));
         draw(xc,yc,tmp);
       end;
  fillsquare(x,y,pl)
end;

function boardsame:boolean;
var
  x,y:integer;
begin
  for x:=1 to 14
    do for y:=1 to 14
         do if board[x,y]<>board1[x,y]
              then begin
                     boardsame:=false;
                     exit
                   end;
  boardsame:=true
end;

procedure message(pl:integer;str:string);
begin
  gotoxy(SX2-1-length(str) div 2,SY-4);
  if pl=1
    then textattr:=byte(c1)
    else if pl=2
           then textattr:=byte(c2)
           else textattr:=byte(b0);
  outtext(' '+str+' ')
end;

procedure clearmessage;
begin
  textattr:=7;
  gotoxy(SX2-10,SY-4);
  outtext('                    ')
end;

procedure showwinner;
begin
  if sco[1]>sco[2]
    then message(1,'EL-IXIR')
    else if sco[1]<sco[2]
           then message(2,'EL-IXIR')
           else message(0,'EL-IXIR');
  waskey(false,0);
  quitting:=true
end;

procedure markplayer(pl:integer);
var
  x:integer;
begin
  if pl=1
    then x:=2
    else x:=SX-7;
  draw(x,6,sqf[pl]);
  draw(x+2,6,sqf[pl]);
  draw(x,7,sqf[pl]);
  draw(x+2,7,sqf[pl]);
  if pl=1
    then x:=SX-7
    else x:=2;
  draw(x,6,empty);
  draw(x+2,6,empty);
  draw(x,7,empty);
  draw(x+2,7,empty);
end;

procedure score(pl:integer);
var
  x:integer;
  n:integer;
begin
  if pl=1
    then textattr:=byte(c1)
    else textattr:=byte(c2);
  if pl=1
    then x:=9
    else x:=SX-10;
  gotoxy(x-2,2);
  outtext('Score');
  textattr:=7;
  if sco[pl]>99
    then n:=0
    else if sco[pl]>9
           then n:=1
           else n:=2;
  if sco[pl]>99
    then begin
           gotoxy(x,4);
           outtext('1')
         end;
  if sco[pl]>9
    then begin
           gotoxy(x,5-n);
           outtext(char(ord('0')+sco[pl] div 10 mod 10))
         end;
  gotoxy(x,6-n);
  outtext(char(ord('0')+sco[pl] mod 10))
end;

procedure sweepandmark(pl:integer;msg:string);
  procedure check(x,y:integer);
  begin
    if board1[x,y]=pl*2-1
      then begin
             pushstack(x,y);
             board1[x,y]:=pl*2
           end
  end;
var
  x,y:integer;
begin
  board1:=board;
  for x:=1 to 14
    do for y:=1 to 14
         do if board1[x,y]=pl*2
              then board1[x,y]:=pl*2-1;
  clearstack;
  check(1,1);
  check(1,14);
  check(14,1);
  check(14,14);
  while sp1>sp2
    do begin
         inc(sp2);
         x:=stack[sp2].x;
         y:=stack[sp2].y;
         check(x+1,y);
         check(x-1,y);
         check(x,y+1);
         check(x,y-1)
       end;
  if not boardsame
    then begin
           message(pl,msg);
           for x:=1 to 14
             do for y:=1 to 14
                  do if board1[x,y]<>board[x,y]
                       then begin
                              inc(sco[pl]);
                              score(pl);
                              delay(delay2)
                            end;
           board:=board1;
           clearmessage
         end;
end;

procedure completeembrace(pl:integer);
var
  b:boolean;
  procedure check(x,y:integer);
  begin
    if board1[x,y]=0
      then begin
             pushstack(x,y);
             board1[x,y]:=-1
           end
  end;
  procedure check1(x,y:integer);
  begin
    if board1[x,y]=0
      then begin
             pushstack(x,y);
             board1[x,y]:=-2;
             if (board[x-1,y]=pl*2) or
                  (board[x+1,y]=pl*2) or
                  (board[x,y-1]=pl*2) or
                  (board[x,y+1]=pl*2)
               then b:=true
           end
  end;
var
  x,y,x1,y1:integer;
begin
  board1:=board;
  for x:=1 to 14
    do for y:=1 to 14
         do if board1[x,y]=pl*2
              then board1[x,y]:=pl*2-1;
  for x:=1 to 14
    do for y:=1 to 14
         do if board1[x,y]<>pl*2-1
              then board1[x,y]:=0;
  clearstack;
  check(1,1);
  check(1,14);
  check(14,1);
  check(14,14);
  while sp1>sp2
    do begin
         inc(sp2);
         x:=stack[sp2].x;
         y:=stack[sp2].y;
         check(x+1,y);
         check(x-1,y);
         check(x,y+1);
         check(x,y-1);
         check(x+1,y+1);
         check(x-1,y-1);
         check(x-1,y+1);
         check(x+1,y-1)
       end;
  b:=false;
  for x:=1 to 14
    do for y:=1 to 14
         do if board1[x,y]=0
              then begin
                     x1:=x;
                     y1:=y;
                     b:=true
                   end;
  if not b
    then exit;
  b:=false;
  clearstack;
  check1(x1,y1);
  while sp1>sp2
    do begin
         inc(sp2);
         x:=stack[sp2].x;
         y:=stack[sp2].y;
         check1(x+1,y);
         check1(x-1,y);
         check1(x,y+1);
         check1(x,y-1)
       end;
  message(pl,'Complete Embrace');
  em:=true;
  for y:=1 to 14
    do for x:=1 to 14
         do if board1[x,y]=-2
              then begin
                     if board[x,y]=0
                       then dec(freesq);
                     if b
                       then begin
                             inc(sco[pl]);
                             score(pl);
                             board[x,y]:=pl*2
                            end
                      else board[x,y]:=pl*2-1;
                    anim(x,y,pl)
                  end;
  sweepandmark(pl,'Complete Embrace');
  clearmessage
end;

procedure anchorembrace(pl:integer);
  procedure check(x,y:integer);
  begin
    if board1[x,y]=-3
      then begin
             pushstack(x,y);
             board1[x,y]:=-1
           end
  end;
  procedure check1(x,y:integer);
  begin
    if board[x,y]=(3-pl)*2
      then begin
             pushstack(x,y);
             board1[x,y]:=-1
           end
  end;
  procedure check2(x,y:integer);
  begin
    if board1[x,y]=-3
      then begin
             pushstack(x,y);
             board1[x,y]:=-2
           end
  end;
var
  b:boolean;
  x,y,x1,y1:integer;
begin
  board1:=board;
  for x:=1 to 14
    do for y:=1 to 14
         do if (board1[x,y]<>pl*2) and (board1[x,y]<>0)
              then board1[x,y]:=-3;
  clearstack;
  for y:=1 to 14
    do for x:=1 to 14
         do if board[x,y]=0
              then begin
                     pushstack(x,y);
                     board1[x,y]:=-1
                   end;
  check1(1,1);
  check1(1,14);
  check1(14,1);
  check1(14,14);
  while sp1>sp2
    do begin
         inc(sp2);
         x:=stack[sp2].x;
         y:=stack[sp2].y;
         check(x+1,y);
         check(x-1,y);
         check(x,y+1);
         check(x,y-1)
       end;
  b:=false;
  for y:=1 to 14
    do for x:=1 to 14
         do if board1[x,y]=-3
              then begin
                     x1:=x;
                     y1:=y;
                     b:=true
                   end;
  if not b
    then exit;
  clearstack;
  check2(x1,y1);
  while sp1>sp2
    do begin
         inc(sp2);
         x:=stack[sp2].x;
         y:=stack[sp2].y;
         check2(x+1,y);
         check2(x-1,y);
         check2(x,y+1);
         check2(x,y-1)
       end;
  message(pl,'Anchoring Embrace');
  em:=true;
  for y:=1 to 14
    do for x:=1 to 14
         do if board1[x,y]=-2
              then begin
                     if board[x,y]=0
                       then dec(freesq);
                     inc(sco[pl]);
                     score(pl);
                     board[x,y]:=pl*2;
                     anim(x,y,pl)
                   end;
  sweepandmark(pl,'Anchoring Embrace');
  clearmessage
end;

procedure playermove(pl:integer);
label emb;
var
  selsq:array[1..4] of record x,y:integer end;
  numsel,len:integer;
  x,y,n,m:integer;
begin
  if freesq<4
    then numsel:=freesq
    else numsel:=4;
  if tl_kind=1
    then tlimit[pl]:=14;
  showtime(pl);
  for n:=1 to numsel
    do begin
         repeat
           x:=random(14)+1;
           y:=random(14)+1;
         until board[x,y]=0;
         board[x,y]:=-1;
         selsq[n].x:=x;
         selsq[n].y:=y
       end;
  n:=1;
  if numsel>1
    then repeat
          with selsq[n]
            do clearsquare(x,y);
          inc(n);
          if n>numsel
            then n:=1;
          with selsq[n]
            do drawsquare(x,y,sqs[pl]);
          delay(delay1);
         until waskey(true,pl);
  for m:=1 to numsel
    do with selsq[m]
         do board[x,y]:=0;
  x:=selsq[n].x;
  y:=selsq[n].y;
  if (board[x+1,y]=0) or
     (board[x-1,y]=0) or
     (board[x,y+1]=0) or
     (board[x,y-1]=0)
    then begin
           if tl_kind=1
             then begin
                    tlimit[pl]:=14;
                    showtime(pl)
                  end;
           n:=random(4);
           repeat
             n:=succ(n) mod 4;
             drawsquare(x,y,arrows[n]);
             delay(delay1);
           until waskey(true,pl);
           m:=n;
           n:=1;
           if tl_kind=1
             then begin
                    tlimit[pl]:=14;
                    showtime(pl)
                  end;
           repeat
             n:=(n+2) mod 4+1;
             drawsquare(x,y,digits[n-1]);
             delay(delay1);
           until waskey(true,pl)
         end
    else m:=0;
  cleartime(pl);
  len:=n;
  n:=0;
  repeat
    board[x+n*dirx[m],y+n*diry[m]]:=pl*2-1;
    fillsquare(x+n*dirx[m],y+n*diry[m],pl);
    delay(delay4);
    dec(freesq);
    inc(n);
  until (n=len) or (board[x+n*dirx[m],y+n*diry[m]]>0);
  sweepandmark(pl,'Anchoring Chain');
emb:
  em:=false;
  completeembrace(pl);
  anchorembrace(3-pl);
  anchorembrace(pl);
  if em
    then goto emb;
end;

procedure quit;
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
const
  min=2;
  choices:array[min..24] of string[15]=(
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
                       '',
                       '',
                       '',
                       'TIME:',
                       'For one move',
                       'For all game',
                       'No limit',
                       '',
                       '',
                       '',
                       '',
                       'Play game',
                       'Exit to DOS');
  options:set of byte=[16,17,18,23,24];
begin
  n:=23;
  repeat
    textattr:=7;
    clrscr;
    cursorout;
    for m:=12 to 24
      do begin
           gotoxy(SX2+2-length(choices[m]) div 2,m);
           outtext(choices[m])
         end;
    if tl_kind=0
      then gotoxy(SX2+11,18)
      else gotoxy(SX2+11,tl_kind+15);
    outtext('√');
    repeat
      gotoxy(SX2-5,n);
      textattr:=$70;
      outtext('               ');
      gotoxy(SX2+2-length(choices[n]) div 2,n);
      outtext(choices[n]);
      ch:=readkey;
      gotoxy(SX2-5,n);
      textattr:=$07;
      outtext('               ');
      if n<11
        then textattr:=col[n-2];
      gotoxy(SX2+2-length(choices[n]) div 2,n);
      outtext(choices[n]);
      case ch of
        #0:begin
             ch:=readkey;
             case ch of
               #72:repeat
                     if n>min
                       then dec(n)
                       else n:=24;
                   until n in options;
               #80:repeat
                     if n<24
                       then inc(n)
                       else n:=min
                   until n in options;
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
                          until n in options;
                      'B':repeat
                            if n<24
                              then inc(n)
                              else n:=min
                          until n in options;
                    end;
                #27:quit;
              end;
            end;
        'q':quit;
       end;
    until (ch=#13) or (ch=' ');
    textattr:=7;
    clrscr;
    case n of
     24:quit;
     23:break;
     18:tl_kind:=0;
     17:tl_kind:=2;
     16:tl_kind:=1;
    end;
  until false
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


var
  x,y:integer;
begin
  tl_kind:=0;
  InitMouse;
  setsize;
  repeat
    menu;
    tlimit[1]:=400;
    tlimit[2]:=400;
    quitting:=false;
    sco[1]:=0;
    sco[2]:=0;
    cursorout;
    randomize;
    textattr:=7;
    clrscr;
    for x:=1 to 14
      do for y:=1 to 14
           do clearsquare(x,y);
    if tl_kind=2
      then begin
             showtime(1);
             showtime(2)
           end;
    for x:=0 to 15
      do for y:=0 to 15
           do board[x,y]:=127;
    for x:=1 to 14
      do for y:=1 to 14
           do board[x,y]:=0;
    freesq:=196;
    fast:=false;
    repeat
      message(1,'Press any key');
      markplayer(1);
      waskey(false,0);
      clearmessage;
      playermove(1);
      if quitting or (freesq=0) or (sco[1]>98) or (sco[2]>98)
        then break;
      message(2,'Press any key');
      markplayer(2);
      waskey(false,0);
      clearmessage;
      playermove(2);
    until quitting or (freesq=0) or (sco[1]>98) or (sco[2]>98);
    showwinner;
  until false
end.
