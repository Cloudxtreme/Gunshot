{$I DEFINES.INC}
UNIT BsMulti;


INTERFACE


{ TaskRec.OS    0 : No MultiTasking  }
{               1 : Windows          }
{               2 : OS/2             }
{               3 : DESQview         }
{               4 : TopView          }


TYPE  TaskRec      = record
      OS           : Word;
      Version      : Word;
      END;
CONST Task         : TaskRec = (OS: 0; Version: 0);
VAR   GiveUpSlices : Boolean;


PROCEDURE TimeSlice;
PROCEDURE InitMulti;
PROCEDURE _Delay(MSecs: Word);
FUNCTION  _GetOperatingSystem: String;


IMPLEMENTATION


USES ApTimer,Dos,BsString,Crt;


{$IFDEF MSDOS}
PROCEDURE InitMulti; ASSEMBLER;
ASM
  mov  Task.OS, 0
  mov  Task.Version, 0
  mov  Ah, 30h
  mov  Al, 01h
  int  21h
  cmp  Al, 20
  je   @OS2
  mov  Ax, 160Ah
  int  2Fh
  cmp  Ax, 0
  je   @Windows
  mov  Ax, 1022h
  mov  Bx, 0000h
  int  15h
  cmp  Bx, 0
  jne  @DESQview
  mov  Ah, 2Bh
  mov  Al, 01h
  mov  Cx, 4445h
  mov  Dx, 5351h
  int  21h
  cmp  Al, $FF
  jne  @TopView
  jmp  @Fin
@Windows:
  Mov  Task.OS, 1
  Mov  Task.Version, BX
  jmp  @Fin
@OS2:
  Mov  Task.OS, 2
  Mov  Bh, Ah
  Xor  Ah, Ah
  Mov  Cl, 10
  Div  Cl
  Mov  Ah, Bh
  Xchg Ah, Al
  Mov  Task.Version, AX
  jmp  @Fin
@DESQview:
  mov  Task.OS, 3
  jmp  @Fin
@TopView:
  mov  Task.OS, 4
@Fin:
END;
{$ENDIF}
{$IFNDEF MSDOS}
PROCEDURE InitMulti;
BEGIN
     Task.OS := 1; // REETODO Windows, what about Linux, FreeBSD, etc?
     Task.Version := 0;
END;
{$ENDIF}


{$IFDEF MSDOS}
PROCEDURE TimeSlice; ASSEMBLER;
ASM
  cmp  GiveUpSlices,0
  je   @Fin
  cmp  Task.OS, 0
  je   @Fin
  cmp  Task.OS, 1
  je   @Win_OS2
  cmp  Task.OS, 2
  je   @Win_OS2
@DV_TV:
  mov  Ax, 1000h
  int  15h
  jmp  @Fin
@Win_OS2:
  mov  Ax, 1680h
  int  2Fh
@Fin:
END;
{$ENDIF}
{$IFNDEF MSDOS}
PROCEDURE TimeSlice;
BEGIN
     ThreadSwitch;
END;
{$ENDIF}


PROCEDURE _Delay(MSecs: Word);
VAR  Timer : EventTimer;
BEGIN
     IF GiveUpSlices THEN
     BEGIN
       NewTimer(Timer,1440*60);
       REPEAT
         TimeSlice;
       UNTIL (ElapsedTimeInMSecs(Timer)>=MSecs);
     END
     ELSE Delay(MSecs);
END;


FUNCTION _GetOperatingSystem: String;
BEGIN
     CASE Task.Os OF
     0:   _GetOperatingSystem := 'DOS';
     1:   _GetOperatingSystem := 'Windows';
     2:   _GetOperatingSystem := 'OS/2';
     3:   _GetOperatingSystem := 'DESQview';
     4:   _GetOperatingSystem := 'TopView';
     ELSE _GetOperatingSystem := 'Unknown';
     END;
END;


BEGIN
     InitMulti;
     IF (GetEnv('NOSLICES')<>'')
        THEN GiveUpSlices := False
        ELSE GiveUpSlices := True;
END.