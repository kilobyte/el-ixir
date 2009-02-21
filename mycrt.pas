unit mycrt;
interface

procedure gotoxy(x,y:integer);
procedure cursorin;
procedure cursorout;
procedure delay(ms:integer);
procedure crtwrite(txt:string);
function keypressed:boolean;
function readkey:char;
procedure clrscr;

var
  TextAttr:byte;
  ScreenWidth,ScreenHeight:integer;

implementation
uses oldlinux, unix, baseunix;

var
  RealAttr:byte;

procedure gotoxy(x,y:integer);
begin
  write(#27'[',y-1,';',x-1,'f');
end;

procedure cursorout;
begin
  write(#27'[?25l')
end;

procedure cursorin;
begin
  write(#27'[?25h')
end;

procedure delay(ms:integer);
var
  tv:timeval;
begin
  tv.tv_sec:=ms div 1000;
  tv.tv_usec:=(ms mod 1000)*1000;
  SelectText(input, @tv);
end;

procedure SetAttr;
const
  cols:array[0..7] of integer=(0,4,2,6,1,5,3,7);
begin
  if RealAttr<>TextAttr
    then begin
           RealAttr:=TextAttr;
           write(#27'[0;',(TextAttr shr 3) and 1,
               ';3',cols[TextAttr and 7],
               ';4',cols[(TextAttr shr 4) and 7],
               'm');
         end;
end;

procedure crtwrite(txt:string);
begin
  SetAttr;
  write(txt);
end;

function keypressed:boolean;
begin
  keypressed:=SelectText(input, 0)<>0;
end;

function readkey:char;
var
  r:char;
begin
  FpRead(0, r, 1);
  readkey:=r;
end;

procedure clrscr;
begin
  SetAttr;
  write(#27'[2J'#27'[0;0f');
end;

var
  oldta, curta: TermIOS;
  WinInfo : TWinSize;
initialization
  TextAttr:=7;
  RealAttr:=255;
  TCGetAttr(0, oldta);
  curta:=oldta;
  CFMakeRaw(curta);
  TCSetAttr(0, TCSANOW, curta);
  if fpIOCtl(1,TIOCGWINSZ,@Wininfo)>=0
    then begin
           ScreenWidth:=WinInfo.ws_col;
           ScreenHeight:=WinInfo.ws_row;
           if ScreenWidth<=0
             then ScreenWidth:=80;
           if ScreenHeight<=0
             then ScreenHeight:=25;
         end
    else begin    
           ScreenWidth:=80;    
           ScreenHeight:=25;
         end; 
finalization
  TCSetAttr(0, TCSANOW, oldta);
end.
