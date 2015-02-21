{$I DEFINES.INC}
USES Crt,BsString,BsVideo,BsFile;


CONST BackColour = 15;
CONST BarColour  = 3;
CONST TextColour = 0;
CONST StatColour = 0;
TYPE  Big_Buffer  = Array[1..800] Of String[80];
VAR   BigBuffer   : ^Big_Buffer;
      TFile       : Text;
      Lines       : Word;
      AllDone     : Boolean;
      Top         : Integer;
      C           : Char;


PROCEDURE LoadFile;
VAR  Temp : String;
     BBuf : Array[1..8192] Of Char;
BEGIN
     Lines := 0;
     ASSIGN(TFile,'README');
     SetTextBuf(TFile,BBuf);
     RESET(TFile);
     REPEAT
           READLN(TFile,Temp);
           INC(Lines);
           BigBuffer^[Lines] := _PadRight(Temp,80);
     UNTIL EOF(TFile);
     CLOSE(TFile);
END;


PROCEDURE DrawMain;
VAR  Loop : Word;
BEGIN
     HighVideo;
     TextMode(C80);
     Window(1,1,80,25);
     _HighBackGrounds(True);
     FOR Loop := 1 TO 25 DO
     BEGIN
       CASE Loop OF
       1:   FastWrite(_PadRight('',80),Loop,1,BarColour*16);
       25:  FastWrite(_PadRight('',80),Loop,1,BarColour*16);
       ELSE FastWrite(_PadRight('',80),Loop,1,BackColour*16);
       END;
     END;
     FastWrite('    README  IMPORTANT LAST MINUTE INFORMATION ',1,1,(BarColour*16)+StatColour);
     FastWrite(' Command                ³   Keys:  /  PgUp/PgDn  ESC=Exit  Home/End   ³',25,1,(BarColour*16)+StatColour);
     GotoXY(10,25);
END;


PROCEDURE DrawFromCursor;
VAR  TheAttr : Byte;
BEGIN
     TheAttr := (BackColour*16)+TextColour;
     FastWrite(BigBuffer^[Top],2,1,TheAttr);
     FastWrite(BigBuffer^[Top+1],3,1,TheAttr);
     FastWrite(BigBuffer^[Top+2],4,1,TheAttr);
     FastWrite(BigBuffer^[Top+3],5,1,TheAttr);
     FastWrite(BigBuffer^[Top+4],6,1,TheAttr);
     FastWrite(BigBuffer^[Top+5],7,1,TheAttr);
     FastWrite(BigBuffer^[Top+6],8,1,TheAttr);
     FastWrite(BigBuffer^[Top+7],9,1,TheAttr);
     FastWrite(BigBuffer^[Top+8],10,1,TheAttr);
     FastWrite(BigBuffer^[Top+9],11,1,TheAttr);
     FastWrite(BigBuffer^[Top+10],12,1,TheAttr);
     FastWrite(BigBuffer^[Top+11],13,1,TheAttr);
     FastWrite(BigBuffer^[Top+12],14,1,TheAttr);
     FastWrite(BigBuffer^[Top+13],15,1,TheAttr);
     FastWrite(BigBuffer^[Top+14],16,1,TheAttr);
     FastWrite(BigBuffer^[Top+15],17,1,TheAttr);
     FastWrite(BigBuffer^[Top+16],18,1,TheAttr);
     FastWrite(BigBuffer^[Top+17],19,1,TheAttr);
     FastWrite(BigBuffer^[Top+18],20,1,TheAttr);
     FastWrite(BigBuffer^[Top+19],21,1,TheAttr);
     FastWrite(BigBuffer^[Top+20],22,1,TheAttr);
     FastWrite(BigBuffer^[Top+21],23,1,TheAttr);
     FastWrite(BigBuffer^[Top+22],24,1,TheAttr);
END;


BEGIN
     IF NOT(_FileExists('README')) THEN Halt;
     New(BigBuffer);
     FillChar(BigBuffer^,SizeOf(BigBuffer^),32);
     LoadFile;
     DrawMain;
     Top := 1;
     AllDone := False;
     DrawFromCursor;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                IF Ord(C)=0 THEN
                BEGIN
                     C := ReadKey;
                     CASE ORD(c) OF
                     72:  BEGIN {UP}
                               IF Top>1 THEN
                               BEGIN
                                    DEC(Top);
                                    DrawFromCursor;
                               END;
                          END;
                     80:  BEGIN {DOWN}
                               IF Top+22<Lines THEN
                               BEGIN
                                    INC(Top);
                                    DrawFromCursor;
                               END;
                          END;
                     73:  BEGIN {PGUP}
                               IF Top>1 THEN
                               BEGIN
                                    DEC(Top,23);
                                    IF Top<1 THEN Top := 1;
                                    DrawFromCursor;
                               END;
                          END;
                     81:  BEGIN {PGDN}
                               IF Top+22<Lines THEN
                               BEGIN
                                    INC(Top,23);
                                    IF Top+22>Lines THEN Top := Lines-22;
                                    DrawFromCursor;
                               END;
                          END;
                     71,
                     132: BEGIN {HOME/CRTL-PGUP}
                               Top := 1;
                               DrawFromCursor;
                          END;
                     79,
                     118: BEGIN {END/CTRL-PGDN}
                               Top := Lines-22;
                               DrawFromCursor;
                          END;
                     END;
                END
                ELSE
                BEGIN
                     CASE ORD(C) OF
                     27,
                     13:  AllDone := True;
                     END;
                END;
           END;
     UNTIL AllDone;
     Dispose(BigBuffer);
     TextBackground(0);
     ClrScr;
     _HighBackGrounds(False);
     TextMode(C80);
END.