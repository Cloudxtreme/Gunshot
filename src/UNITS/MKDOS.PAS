Unit MKDos;
{$I MKB.Def}

Interface


Function GetDosDate: LongInt;
Function GetDOW: Word;
Function GetResultCode: Integer;
Function TimeOut(Time:LongInt):Boolean; {If time is later than current time
  in timerticks}

{$IFDEF MSDOS}
Var
  TimeCounter: LongInt Absolute $40:$6C;
{$ENDIF}
{$IFNDEF MSDOS}
Function TimeCounter: LongInt;
{$ENDIF}


Implementation


Uses
  Dos;


{$IFNDEF MSDOS}
Function TimeCounter: LongInt;
  Begin
    WriteLn('REEPORT MKDOS TimeCounter'); Halt;
  End;
{$ENDIF}


Function TimeOut(Time:LongInt):Boolean;
  Var
    TimeDiff: LongInt;

  Begin
  TimeDiff := Time - TimeCounter;
  If TimeDiff < 0 Then
    TimeOut := True
  Else
    Begin
    If (TimeDiff > 780000) Then
    Dec(TimeDiff, 1572480);
    If TimeDiff < 0 Then
      TimeOut := True
    Else
      TimeOut := False;
    End;
  End;


{$IFDEF MSDOS}
Function GetResultCode: Integer;
  Var
    Result: Byte;
  {$IFNDEF BASMINT}
    Regs: Registers;
  {$ENDIF}

  Begin
  {$IFDEF BASMINT}
  Asm
    Mov ah, $4d;
    Int $21;
    Cmp ah, $00;
    je @JRes;
    Neg ah;
    Mov Result, ah;
    jmp @JRes2;
    @JRes:
    Mov Result, al;
    @JRes2:
    End;
  {$ELSE}
  Regs.ah := $4d;
  MsDos(Regs);
  If Regs.ah <> 0 Then
    Result := - Regs.ah
  Else
    Result := Regs.al;
  {$ENDIF}
  GetResultCode := Result;
  End;
{$ENDIF}
{$IFNDEF MSDOS}
Function GetResultCode: Integer;
  Begin
    WriteLn('REEPORT MKDOS GetResultCode'); Halt;
  End;
{$ENDIF}


Function GetDosDate: LongInt;
  Var
    DT: DateTime;
    DosDate: LongInt;
    DOW: Word;

  Begin
  GetDate(DT.Year, DT.Month, DT.Day, DOW);
  GetTime(DT.Hour, DT.Min, DT.Sec, DOW);
  PackTime(DT, DosDate);
  GetDosDate := DosDate;
  End;


Function GetDOW: Word;
  Var
    DT: DateTime;
    DOW: Word;

  Begin
  GetDate(DT.Year, DT.Month, DT.Day, DOW);
  GetDOW := DOW;
  End;


End.
