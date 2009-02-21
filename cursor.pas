unit cursor;
interface
procedure cursorin;
procedure cursorout;
implementation
procedure cursorout;
begin
  asm
   MOV AH,1
   MOV CX,$1000
   INT 16
  end
end;
procedure cursorin;
begin
  asm
   MOV AH,1
   MOV CH,13
   MOV CL,14
   INT 16
  end
end;
end.
