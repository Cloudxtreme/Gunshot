{******************************************************}
{*                  TPFERROR.PAS  2.03                *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

{$I OPDEFINE.INC}
{$IFDEF Ver70}
{$I APDEFINE.INC}
{$ENDIF}

{$V-,B-,R-,S-,F-,O-,A+,I-,X+}

unit TpfError;

interface

uses
  OpCrt;

{$IFDEF Ver60}
{$I APDEFINE.INC}
{$ENDIF}

procedure AbortWithMessage(Msg : String; Code : Word);
procedure Abort(Msg : String);

{ for use in the ShowError procedure }
procedure Error_Table;
procedure GetErrorMessage(Code : Word; Table : Pointer; var Dest : String);

implementation

var
  SM : Word;

procedure Restore;
begin
  TextMode(SM);
  Window(1, 1, ScreenWidth, ScreenHeight);
  TextAttr := 7;
end;

procedure AbortWithMessage(Msg : String; Code : Word);
begin
  Restore;
  WriteLn(Msg, '  Error #: ', Code);
  WriteLn;
  Halt;
end;

procedure Abort(Msg : String);
begin
  Restore;
  WriteLn(Msg);
  WriteLn;
  Halt;
end;

procedure Error_Table; external;
{$L ERRORS.OBJ}

  { find an error message string in a table }
  procedure GetErrorMessage(Code : Word; Table : Pointer; var Dest : String); assembler;
  asm
    push    ds
    lds     si,Table    { DS:SI points to error table        }
    les     di,Dest     { ES:DI points to destination string }
    cld                 { go forward }
    mov     bx,Code     { BX = error code, for faster cmps   }

@1: lodsw               { load the first error code in table }
    or      ax,ax       { end of the table reached?          }
    jz      @2          { yes, return a null string          }
    cmp     ax,bx       { is this the error code we want?    }
    je      @4          { if so, do something with it        }
    xor     ax,ax       { if not, skip to the next code...   }
    lodsb               { ...by loading this length byte...  }
    add     si,ax       { ...and skipping the string         }
    jmp     @1

@4: xor     cx,cx
    lodsb               { load the length byte               }
    mov     cl,al       { store it in CL                     }
    stosb               { store it in the dest string        }
    jcxz    @3          { if the string is empty, exit       }
    rep     movsb       { store the error string             }

    jmp     @3          { get the heck out of here           }

@2: xor     ax,ax       { store a null string                }
    stosb

@3: pop     ds
  end;

begin
  SM := LastMode;
end.
