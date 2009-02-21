uses crt,cursor,dos;{$R+}
type
  tpole=array[0..5] of char;
  tscreen=array[1..25,1..80,0..1] of char;
const
  czas1=550;        { czas na wybór }
  czas2=250;        { czas przy punktacji }
  czas3=400;        { czas przy embransie }
  czas4=100;         { czas przy zapelnianiu pól 1..4}
  fanim=5;           { ilość faz animacji }
  b0=#$70;
  strzalki:array[0..3] of tpole=
            (' '+b0+#27+b0+' '+b0,
             ' '+b0+#24+b0+' '+b0,
             ' '+b0+#26+b0+' '+b0,
             ' '+b0+#25+b0+' '+b0);
  cyfry:array[0..3] of tpole=
            (' '+b0+'1'+b0+' '+b0,
             ' '+b0+'2'+b0+' '+b0,
             ' '+b0+'3'+b0+' '+b0,
             ' '+b0+'4'+b0+' '+b0);
  pustka:tpole=' '+#7+' '+#7+' '+#7;
  cz:tpole=' '+#7+#7+#7+' '+#7;
  kierx:array[0..3] of shortint=(-1,0,1,0);
  kiery:array[0..3] of shortint=(0,-1,0,1);
  pc1=5;
  pc2=7;
  col:array[0..7] of byte=($07,$1c,$61,$1a,$20,$35,$40,$5d);
  colw:array[0..7] of byte=($08,$18,$60,$12,$28,$34,$4d,$5c);
  gcz=3;
  czx=14;
  czy=3;
  cy=10;
  cx1=3;
  cx2=72;
  cx3=cx1+2;
  cx4=cx2+2;
var
  kon:boolean;
  fast:boolean;
  mjest:boolean;
  rczasu:byte;
  czas:array[1..2] of word;
  c1,c2:char;
  polet1,polet2,poler:tpole;
  polew,polez,polerz:array[1..2] of tpole;
  c1w,c2w:char;
procedure setcolors(c:byte);
const
  ct1_mono=#$0f;
  ct2_mono=#$07;
  ct0_mono=#$70;
  c1_mono=#$10;
  c1w_mono=#$18;
  c2_mono=#$60;
  c2w_mono=#$61;
  polet1_mono='▒'+ct1_mono+'▒'+ct1_mono+'▒'+ct1_mono;
  polet2_mono='▓'+ct2_mono+'▓'+ct2_mono+'▓'+ct2_mono;
  poler_mono=' '+ct0_mono+'Θ'+ct0_mono+' '+ct0_mono;
  polew_mono:array[1..2] of tpole=
               (' '+c1w_mono+#7+c1w_mono+' '+c1w_mono,
                ' '+c2w_mono+#7+c2w_mono+' '+c2w_mono);
  polez_mono:array[1..2] of tpole=
               (' '+c1_mono+#7+c1_mono+' '+c1_mono,
                ' '+c2_mono+#7+c2_mono+' '+c2_mono);
  polerz_mono:array[1..2] of tpole=
               (' '+c1_mono+'Ω'+c1_mono+' '+c1_mono,
                ' '+c2_mono+'Ω'+c2_mono+' '+c2_mono);
procedure p(var t:tpole;s:string);
begin
  move(s[1],t,6)
end;
begin
  case c of
    0:begin
        c1:=#$07;
        c1w:=#$07;
        c2:=#$70;
        c2w:=#$70;
        p(polet1,'▒'+#$07+'▒'+#$07+'▒'+#$07);
        polet2:=polet2_mono;
        p(poler,' '+#$70+'Θ'+#$7f+' '+#$70);
        p(polew[1],' '+c1w+'∙'+c1w+' '+c1w);
        p(polez[1],' '+c1+#7+c1+' '+c1);
        p(polerz[1],' '+c1+'Ω'+c1+' '+c1);
        p(polew[2],' '+c2w+'∙'+c2w+' '+c2w);
        p(polez[2],' '+c2+#7+c2+' '+c2);
        p(polerz[2],' '+c2+'Ω'+c2+' '+c2)
      end;
    1:begin
        polet1:=polet1_mono;
        polet2:=polet2_mono;
        poler:=poler_mono;
        polew[1]:=polew_mono[1];
        polez[1]:=polez_mono[1];
        polerz[1]:=polerz_mono[1];
        polew[2]:=polew_mono[2];
        polez[2]:=polez_mono[2];
        polerz[2]:=polerz_mono[2];
        c1:=c1_mono;
        c2:=c2_mono
      end;
    2:begin
        polet1:=polet1_mono;
        polet2:=polet2_mono;
        poler:=poler_mono;
        p(polew[1],' '+c1w+#7+c1w+' '+c1w);
        p(polez[1],' '+c1+#7+c1+' '+c1);
        p(polerz[1],' '+c1+'Ω'+c1+' '+c1);
        p(polew[2],' '+c2w+#7+c2w+' '+c2w);
        p(polez[2],' '+c2+#7+c2+' '+c2);
        p(polerz[2],' '+c2+'Ω'+c2+' '+c2)
      end
   end;
end;
var
  sco:array[1..2] of byte;
  screen:^tscreen;
  tabl,tabl1:array[-1..16,-1..16] of shortint;
  stos:array[1..196] of record x,y:byte end;
  ws1,ws2:byte;
  em:boolean;
  oldvec:pointer;
  oldproc:procedure absolute oldvec;
  licz:word;
{$F+}
procedure timer; interrupt;
begin
  dec(licz);
  asm
   PUSHF
  end;
  oldproc
end;
{$F-}
procedure delay(ms:longint);
begin
  if fast
    then exit;
  getintvec($1c,oldvec);
  licz:=(ms*91) div 5000;
  setintvec($1c,@timer);
  repeat until licz=0;
  setintvec($1c,oldvec)
end;
procedure czyscstos;
begin
  ws1:=0;
  ws2:=0
end;
procedure poloznastos(x,y:byte);
begin
  inc(ws1);
  stos[ws1].x:=x;
  stos[ws1].y:=y
end;
procedure wyswczas(gr:byte);
var
  m,n:byte;
begin
  case rczasu of
    1:begin
        textattr:=$70;
        if gr=1
          then m:=czx
          else m:=80-czx-gcz*14;
        for n:=1 to 14
          do move(cz,screen^[czy,m-gcz+n*gcz,0],6)
      end;
    2:begin
        textattr:=7;
        if gr=1
          then gotoxy(cx1+1,cy)
          else gotoxy(cx2+1,cy);
        write('Time:');
        if gr=1
          then gotoxy(cx3,cy+2)
          else gotoxy(cx4,cy+2);
        write(czas[gr]:3)
      end;
   end;
end;
procedure poprczas(gr:byte);
begin
  case rczasu of
    1:begin
        textattr:=$70;
        if gr=1
          then move(pustka,screen^[czy,czx+czas[gr]*gcz,0],6)
          else move(pustka,screen^[czy,80-czx-gcz-czas[gr]*gcz,0],6)
      end;
    2:begin
        textattr:=7;
        if gr=1
          then gotoxy(cx3,cy+2)
          else gotoxy(cx4,cy+2);
        write(czas[gr]:3)
      end;
   end;
end;
procedure czyscczas(gr:byte);
 var
 m,n:byte;
begin
  case rczasu of
    1:begin
        textattr:=$70;
        if gr=1
          then m:=czx
          else m:=80-czx-gcz*14;
        for n:=1 to 14
          do move(pustka,screen^[czy,m-gcz+n*gcz,0],6)
      end;
   end;
end;
function mbutton:boolean; assembler;
asm
  MOV AX,5
  MOV BX,0
  INT $33
  CMP BX,0
  JZ @a
  MOV AL,1
  JMP @b
@a:
  MOV AL,0
@b:
end;
function bylklawisz(wczas:boolean;gr:byte):boolean;
var
  ch:char;
begin
  if keypressed or kon
    then begin
           while keypressed
             do ch:=readkey;
           if ch=#27
             then begin
                    kon:=true;
                    fast:=true
                  end;
           if ch=#9
             then fast:=true;
           bylklawisz:=true
         end
    else if (mjest and mbutton)
           then bylklawisz:=true
           else if wczas and (rczasu>0)
                  then begin
                         dec(czas[gr]);
                         if czas[gr]=65535
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
procedure pisznapolu(x,y:byte;co:tpole);
begin
  move(co,screen^[4+y,17+3*x,0],6)
end;
procedure czyscpole(x,y:byte);
begin
  if x=1
    then if y=1
           then pisznapolu(x,y,poler)
           else if y=14
                  then pisznapolu(x,y,poler)
                  else if odd(x+y)
                         then pisznapolu(x,y,polet1)
                         else pisznapolu(x,y,polet2)
    else if x=14
           then if y=1
                  then pisznapolu(x,y,poler)
                  else if y=14
                         then pisznapolu(x,y,poler)
                         else if odd(x+y)
                                then pisznapolu(x,y,polet1)
                                else pisznapolu(x,y,polet2)
           else if odd(x+y)
                  then pisznapolu(x,y,polet1)
                  else pisznapolu(x,y,polet2)
end;
procedure zapelnpole(x,y,gr:byte);
begin
  if x=1
    then if y=1
           then pisznapolu(x,y,polerz[gr])
           else if y=14
                  then pisznapolu(x,y,polerz[gr])
                  else pisznapolu(x,y,polez[gr])
    else if x=14
           then if y=1
                  then pisznapolu(x,y,polerz[gr])
                  else if y=14
                         then pisznapolu(x,y,polerz[gr])
                         else pisznapolu(x,y,polez[gr])
           else pisznapolu(x,y,polez[gr])
end;
var
  x,y:integer;
  dl,m,n,ilp:byte;
  polaw:byte;
  pola:array[1..4] of record x,y:byte end;
  an:array[1..2] of byte;
procedure anim(x,y,gr:byte);
var
  x0,y0,x1,y1:byte;
  xc,yc:byte;
  n:byte;
  tmp:tpole;
  ilr:byte;
const
  rogi:array[1..4,1..2] of byte=((1,1),(14,1),(14,14),(1,14));
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
  y1:=4+y;
  x1:=17+3*x;
  y0:=4+y0;
  x0:=17+3*x0;
  for n:=0 to fanim
    do begin
         xc:=x0+longint((x1-x0))*n div fanim;
         yc:=y0+longint((y1-y0))*n div fanim;
         move(screen^[yc,xc,0],tmp,6);
         move(polez[gr],screen^[yc,xc,0],6);
         delay(czas3 div (fanim+1));
         move(tmp,screen^[yc,xc,0],6)
       end;
  zapelnpole(x,y,gr)
end;
function jednakowe:boolean;
var
  b:boolean;
begin
  b:=true;
  for x:=1 to 14
    do for y:=1 to 14
         do if tabl[x,y]<>tabl1[x,y]
              then b:=false;
  jednakowe:=b
end;
procedure komunikat(gr:byte;str:string);
begin
  gotoxy(39-length(str) div 2,21);
  if gr=1
    then textattr:=byte(c1)
    else if gr=2
           then textattr:=byte(c2)
           else textattr:=byte(b0);
  write(' ',str,' ')
end;
procedure czkom;
begin
  textattr:=7;
  gotoxy(30,21);
  write('                    ')
end;
procedure kunc;
begin
  if sco[1]>sco[2]
    then komunikat(1,'EL-IXIR')
    else if sco[1]<sco[2]
           then komunikat(2,'EL-IXIR')
           else komunikat(0,'EL-IXIR');
 repeat until bylklawisz(false,0);
 kon:=true
end;
procedure oznaczgracza(gr:byte);
var
  x:byte;
begin
  x:=71*gr-69;
  move(polez[gr],screen^[6,x,0],6);
  move(polez[gr],screen^[6,x+2,0],6);
  move(polez[gr],screen^[7,x,0],6);
  move(polez[gr],screen^[7,x+2,0],6);
  x:=71*(3-gr)-69;
  move(pustka,screen^[6,x,0],6);
  move(pustka,screen^[6,x+2,0],6);
  move(pustka,screen^[7,x,0],6);
  move(pustka,screen^[7,x+2,0],6)
end;
procedure score(gr:byte);
var
  n:byte;
begin
  if gr=1
    then textattr:=byte(c1)
    else textattr:=byte(c2);
  gotoxy(gr*65-60,2);
  write('Score');
  textattr:=7;
  if sco[gr]>99
    then n:=0
    else if sco[gr]>9
           then n:=1
           else n:=2;
  if sco[gr]>99
    then begin
           gotoxy(gr*65-58,4);
           write(1)
         end;
  if sco[gr]>9
    then begin
           gotoxy(gr*65-58,5-n);
           write(sco[gr] div 10 mod 10)
         end;
  gotoxy(gr*65-58,6-n);
  write(sco[gr] mod 10)
end;
procedure przejedzizapal(gr:byte;kom:string);
  procedure sprawdz(x,y:byte);
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
procedure completeembrance(gr:byte);
var
  b:boolean;
  x1,y1:byte;
  procedure sprawdz(x,y:byte);
  begin
    if tabl1[x,y]=0
      then begin
             poloznastos(x,y);
             tabl1[x,y]:=-1
           end
  end;
  procedure sprawdz1(x,y:byte);
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
           komunikat(gr,'Complete Embrance');
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
           przejedzizapal(gr,'Complete Embrance');
           czkom
         end;
end;
procedure anchorembrance(gr:byte);
var
  b:boolean;
  x1,y1:byte;
  procedure sprawdz(x,y:byte);
  begin
    if tabl1[x,y]=-3
      then begin
             poloznastos(x,y);
             tabl1[x,y]:=-1
           end
  end;
  procedure sprawdz1(x,y:byte);
  begin
    if tabl[x,y]=gr*2-1
      then begin
             poloznastos(x,y);
             tabl1[x,y]:=gr*2
           end
  end;
  procedure sprawdz2(x,y:byte);
  begin
    if tabl1[x,y]=-3
      then begin
             poloznastos(x,y);
             tabl1[x,y]:=-2
           end
  end;
begin
  tabl1:=tabl;
  if (tabl1[1,1]=gr*2) and (tabl1[1,14]=gr*2)
    then for x:=1 to 14
           do tabl1[0,x]:=gr*2;
  if (tabl1[14,1]=gr*2) and (tabl1[14,14]=gr*2)
    then for x:=1 to 14
           do tabl1[15,x]:=gr*2;
  if (tabl1[1,1]=gr*2) and (tabl1[14,1]=gr*2)
    then for x:=1 to 14
           do tabl1[x,0]:=gr*2;
  if (tabl1[1,14]=gr*2) and (tabl1[14,14]=gr*2)
    then for x:=1 to 14
           do tabl1[x,15]:=gr*2;
  for x:=1 to 14
    do for y:=1 to 14
         do if (tabl1[x,y]=gr*2)
              then tabl1[x,y]:=gr*2-1;
  czyscstos;
  sprawdz1(1,1);
  sprawdz1(1,14);
  sprawdz1(14,1);
  sprawdz1(14,14);
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
           komunikat(gr,'Anchoring Embrance');
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
           przejedzizapal(gr,'Anchoring Embrance');
           czkom
         end;
end;
procedure ruch(gr:byte);
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
            n:=random(4);
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
  completeembrance(gr);
  anchorembrance(3-gr);
  anchorembrance(gr);
  if em
    then goto emb;
end;
var
  kolor:byte;
procedure menu;
var
  m,n:byte;
  ch:char;
  play:boolean;
  sel:boolean;
  gr:byte;
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
                       '',
                       'Player 1',
                       'Player 2',
                       '',
                       'TIME:',
                       'For one move',
                       'For all game',
                       'No time',
                       '',
                       'Black&White',
                       'Monochorome',
                       'Standard colors',
                       '',
                       'Play game',
                       'Exit to DOS');
  opcje:array[boolean] of set of byte=
                 ([11,12,15,16,17,19,20,21,23,24],
                  [2,3,4,5,6,7,8,9,11,12,19,20,21,24]);
begin
  n:=23;
  sel:=false;
  repeat
   textattr:=7;
   clrscr;
   cursorout;
   for m:=11 to 24
     do begin
          gotoxy(42-length(wybory[m]) div 2,m);
          write(wybory[m])
        end;
   for m:=2 to 9
     do begin
          textattr:=col[m-2];
          gotoxy(42-length(wybory[m]) div 2,m);
          write(wybory[m])
        end;
   gotoxy(22,23);
   textattr:=byte(c1);
   if sel and (gr=1)
     then write(' ??????? ')
     else write(' EL-IXIR ');
   gotoxy(22,11);
   textattr:=byte(c1);
   if sel and (gr=1)
     then write(' ??????? ')
     else write(' EL-IXIR ');
   gotoxy(12,23);
   textattr:=7;
   write('player 1');
   gotoxy(54,23);
   textattr:=byte(c2);
   if sel and (gr=2)
     then write(' ??????? ')
     else write(' EL-IXIR ');
   gotoxy(54,12);
   textattr:=byte(c2);
   if sel and (gr=2)
     then write(' ??????? ')
     else write(' EL-IXIR ');
   gotoxy(65,23);
   textattr:=7;
   write('player 2');
   play:=false;
   repeat
    gotoxy(35,n);
    textattr:=$70;
    write('               ');
    gotoxy(42-length(wybory[n]) div 2,n);
    write(wybory[n]);
    ch:=readkey;
    gotoxy(35,n);
    textattr:=$07;
    write('               ');
    if n<10
      then textattr:=col[n-2];
    gotoxy(42-length(wybory[n]) div 2,n);
    write(wybory[n]);
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
            clrscr;
            cursorin;
            halt
          end;
     end;
   until (ch=#13) or (ch=' ');
   textattr:=7;
   clrscr;
   case n of
    24:begin
         cursorin;
         halt
       end;
    23:play:=true;
    21:begin
         c1:=char(col[pc1]);
         c2:=char(col[pc2]);
         c1w:=char(colw[pc1]);
         c2w:=char(colw[pc2]);
         setcolors(2);
         sel:=false
       end;
    20:begin
         setcolors(1);
         sel:=false
       end;
    19:begin
         setcolors(0);
         sel:=false
       end;
    17:rczasu:=0;
    16:rczasu:=2;
    15:rczasu:=1;
    12:begin
         sel:=true;
         gr:=2
       end;
    11:begin
         sel:=true;
         gr:=1
       end;
    2..9:if ((gr=1) and (c2<>char(col[n-2]))) or
            ((gr=2) and (c1<>char(col[n-2])))
           then begin
                  sel:=false;
                  if gr=1
                    then begin
                           c1:=char(col[n-2]);
                           n:=12;
                           setcolors(2)
                         end
                    else begin
                           c2:=char(col[n-2]);
                           n:=11;
                           setcolors(2)
                         end
                end;
    end;
  until play
end;
label gameover;
begin
  rczasu:=1;
  asm
   MOV AX,0
   INT $33
   CMP AX,0
   JZ @a;
   MOV mjest,1
   JMP @b;
  @a:
   MOV mjest,0
  @b:
  end;
  if lastmode=mono
    then screen:=ptr($b000,0)
    else screen:=ptr($b800,0);
  c1:=char(col[pc1]);
  c2:=char(col[pc2]);
  c1w:=char(colw[pc1]);
  c2w:=char(colw[pc2]);
  if lastmode=mono
    then kolor:=0
    else if paramstr(1)='/m'
           then kolor:=1
           else kolor:=2;
  setcolors(kolor);
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
    for x:=-1 to 16
      do for y:=-1 to 16
           do tabl[x,y]:=126;
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
      repeat until bylklawisz(false,0);
      czkom;
      ruch(1);
      if kon or (polaw=0) or (sco[1]>98) or (sco[2]>98)
        then begin
               kunc;
               goto gameover
             end;
      komunikat(2,'Press any key');
      oznaczgracza(2);
      repeat until bylklawisz(false,0);
      czkom;
      ruch(2);
    until kon or (polaw=0) or (sco[1]>98) or (sco[2]>98);
    kunc;
    gameover:
  until false
end.
