{****************************************************}
{ Turbo Pascal 6.0 MkErr Unit Ver 1.01 1991 ManuSoft }
{****************************************************}

unit MKERR;                         {This is Public Domain}
{ Look for MkErr.doc file for      rbuf is store of these registers.
  explanation of this code          0: es                            
                                    1: bp                            
                                    2: sp                            
                                    3: ss                            
                                    4: [bp  ] 
                                    5: [bp+2]                        
                                    6: [bp+4]                        
}                                    

interface

{$DEFINE MkEVer101}

const

  Version : Word = 101;
  NestErr = 16; 
  {Number of nested error_handles available}
  
var 
  oldx    :pointer;
  {Save pointer for ExitProc routine}

  active  :word;
  {Active count of nesting level}

  nehalt  :Boolean;
  {Not error --> halt
   does the error device assume nonerror activation of
   errordevice is same as halt. Normally program never
   reaches the errh state without error, but if you
   forget the done/errfree clauses from program this
   happens on the end. With this boolean being TRUE
   (default) you can tell errorhandler to just say
   goodbye when occurred without error.}


procedure init;
{Initialize error device}

procedure done;
{Clear error device}

function  errset:boolean;
function  errh:boolean;
procedure errfree;
{Errset  setup error device error handler}
{Errh    errorhandler caller. Returns program to position saved by Errset}
{Errfree clears last level of errset information}

procedure halt;
{System unit halt procedure override}

procedure continue;
{Method to go back and continue program from next statement after error}

implementation

type
  rbuftype = array[0..6] of word;
  {Type of error device buffer, saves ES,BP,SP,SS,[BP],[BP+2],[BP+4]}
  
var
  rbuf     : array[0..NestErr-1] of rbuftype;
  {Nesting buffer of device error handlers}

  bpbuf    : word;
  bpchk    : word;

{Device initialization, clear all error handlers.}
procedure init;
begin
  active:=0;
  fillchar(rbuf,sizeof(rbuf),#0);
  oldx:=exitproc;
end;

{Device deactivation, clear all error handlers and return exitproc.}
procedure done;
begin
  exitproc:=oldx;
  active:=0;
end;

{THE Error Handler itself. Remember to keep this far call proc.
 errh Restores recorded program status from rbuf stack}
{$F+,S-}
function errh:boolean;
begin
  if (erroraddr=nil) and nehalt then halt;
  if active>0 then begin
    asm
      mov  bpbuf,bp;{Save state of bp reg for continue}
      mov  ax,bp
      neg  ax
      mov  bpchk,ax

      mov  ax,active;
      dec  ax;
      mov  bx,14; {NOTICE: sizeof(rgbuf);}
      mul  bx;
      lea  si,rbuf;
      add  si,ax
      lodsw
      mov  es,ax
      lodsw
      cli
      mov  bp,ax
      lodsw
      mov  sp,ax
      lodsw
      mov  ss,ax
      sti
      lodsw
      mov  [bp],ax;
      lodsw
      mov  [bp+2],ax
      lodsw
      mov  [bp+4],ax
    end;
    exitproc:=@errh;
  end else halt;
  errh:=true;
end;

{Error Handler setup function. Remember to keep this far call prog.
 errset saves its own return value to internal rbuf stack.
 when error occurs, Turbo Pascal ExitProc routine (=Errh) starts
 and restores the saved information from rbuf stack. This makes
 Turbo Pascal to continue code from inside the errset IF clause. }
{$S+}
function errset:boolean;
begin
  if (active=0) and (exitproc<>@errh) then oldx:=exitproc;
  if active<NestErr then begin
    exitproc:=@errh;
    asm
      mov  ax,active;
      mov  bx,14; {NOTICE This is sizeof(rgbuf), won't work in asm}
      mul  bx;
      lea  bx,rbuf
      add  bx,ax
      mov  di,bx
      cld;
      mov  ax,es
      push ds
      pop  es
      stosw
      cli
      mov  ax,bp
      stosw
      mov  ax,sp
      stosw
      mov  ax,ss
      stosw
      sti
      mov  ax,[bp]
      stosw
      mov  ax,[bp+2]
      stosw
      mov  ax,[bp+4]
      stosw
      mov  es,[bx];
    end;
    inc(active);
    errset:=false;
  end else errset:=true;
end;
{$F-}

{Free top level error handler, drop to previous level if none}
Procedure errfree;
begin
  if active>0 then dec(active);
  if (active=0) then exitproc:=oldx else exitproc:=@errh;
end;

procedure halt;
begin
  Done;
  system.halt;
end;

procedure continue; assembler;
asm
  pop   cx
  pop   dx
  mov   ax,word[prefixseg]
  add   ax,word[erroraddr+2]
  add   ax,$10; {Adding program header size ($100 bytes) to segment address}
  push  ax
  mov   bx,word[erroraddr]
  push  bx
  or    ax,bx
  jnz   @@1
  mov   al,nehalt;
  or    al,al
  jz    @@2
  call  halt;  {No continue address & nehalt true, halt}
@@2:
  push  dx     {No continue address & nehalt false, return to caller}
  push  cx
@@1:
  mov  ax,bpchk;
  neg  ax
  cmp  ax,bpbuf;
  jnz  @@3
  mov  bpchk,ax
  mov  bp,ax
@@3:
end;

begin
  nehalt:=True;
  init; {Clear the device on startup}
end.

