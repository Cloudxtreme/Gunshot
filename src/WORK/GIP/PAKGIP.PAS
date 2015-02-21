{$I DEFINES.INC}
{$M 32000,0,512000}
PROGRAM GIPCompiler;


USES Dos,ApMisc,Crt,FastW1,BsVideo,Version,Shotgun,BsKeys,BsString,BsFile,BsComp;


TYPE BigBuffer       = Array[1..8192] Of Byte;
TYPE SAVESCRNAScreen = Array[1..4000] Of Byte;
VAR  SAVESCRNScr     : SAVESCRNAScreen;
     LotsaFiles      : Array[1..1000] Of String[12];
     NumFiles        : Word;
     FFile           : File;
     FFile2          : File;
     Work            : Longint;
     Buffer          : ^BigBuffer;
     BytesRead       : Word;
     Loop            : Word;
     DirInfo         : SearchRec;
     LoopX           : Word;
     LoopY           : Word;
     X               : Word;
     Y               : Word;
     Scrap           : Word;
     WorkSg          : _Raw_File;
     WorkSg2         : _Raw_File;
     Icon30          : _Icon30x30;
     Icon16          : _Icon16x16;
     MouseDef        : _Mouse_Def;
     FWorkSg         : File Of _Raw_File;
     FWorkSg2        : File Of _Raw_File;
     FIcon30         : File Of _Icon30x30;
     FIcon302        : File Of _Icon30x30;
     FIcon16         : File Of _Icon16x16;
     FIcon162        : File Of _Icon16x16;
     FMouseDef       : File Of _Mouse_Def;
     FMouseDef2      : File Of _Mouse_Def;
     GIPHeader       : _GIPHeader;
     GIPFileHeader   : _GIPFileHeader;
     ShotgunDir      : String[40];
     TheFileName     : String[40];
     SOUNDDir        : String[40];
     FLICSDir        : String[40];
     ICONDir         : String[40];
     FONTDir         : String[40];
     JPEGDir         : String[40];
     WorkDir         : String[40];
     SavedX          : Word;
     SavedY          : Word;
     SavedAttr       : Byte;
     CompFile        : String;
     UseRealName     : Boolean;


PROCEDURE SaveTheScreen;
BEGIN
     SavedX := WhereX;
     SavedY := WhereY;
     SavedAttr := TextAttr;
     _HideCursor;
     Move(MEM[SegB800:0],SAVESCRNScr[1],4000);
END;


PROCEDURE RestoreTheScreen;
BEGIN
     Move(SAVESCRNScr[1],MEM[SegB800:0],4000);
     GotoXy(SavedX,SavedY);
     TextAttr := SavedAttr;
     _ShowCursor;
END;


PROCEDURE Shadow(xx1,yy1,xx2,yy2 : Word);
VAR  xshad   : Word;
     yshad   : Word;
     x       : Word;
     y       : Word;
     Loop    : Word;
BEGIN
     x := ((yy2*160)+(xx1*2))+1;
     FOR Loop := xx1 to xx2 DO
     BEGIN
          Mem[SegB800:x] := 8;
          INC(x,2);
     END;
     y := ((yy1*160)+((xx2)*2))+1;
     FOR Loop := yy1 to yy2 DO
     BEGIN
          Mem[SegB800:y] := 8;
          INC(y,160);
     END;
END;


PROCEDURE DrawWindow(x1,y1,x2,y2: Word; Title: String);
VAR  LoopY  : Word;
     LoopX  : Word;
     Loop2  : Word;
BEGIN
     Shadow(x1,y1,x2,y2);
     TextBackGround(1);
     FOR LoopY := y1 TO y2 DO
     BEGIN
          GOTOXY(x1,LoopY);
          IF LoopY=y1 THEN
          BEGIN
               TextColor(9);
               WRITE('Ú');
               FOR Loop2 := x1+1 TO x2-1 DO WRITE('Ä');
               TextColor(0);
               WRITE('¿');
          END
          ELSE IF LoopY=y2 THEN
          BEGIN
               TextColor(9);
               WRITE('À');
               TextColor(0);
               FOR Loop2 := x1+1 TO x2-1 DO WRITE('Ä');
               WRITE('Ù');
          END
          ELSE
          BEGIN
               TextColor(9);
               WRITE('³');
               TextColor(0);
               FOR Loop2 := x1+1 TO x2-1 DO WRITE(' ');
               WRITE('³');
          END;
     END;
     Title := ' '+Title+' ';
     GotoXy(x1+2,y1);
     TextBackGround(1);
     TextColor(15);
     WRITE(Title);
END;


PROCEDURE InvertedBox(x1,y1,x2,y2: Word);
VAR  Loop : Word;
BEGIN
     TextBackground(1);
     TextColor(0);
     GotoXY(x1,y1);
     WRITE('Ú');
     FOR Loop := x1+1 TO x2-1 DO WRITE('Ä');
     TextColor(9);
     WRITE('¿');
     FOR Loop := y1+1 TO y2-1 DO
     BEGIN
          GotoXY(x1,loop);
          TextColor(0);  WRITE('³');
          GotoXY(x2,loop);
          TextColor(9); WRITE('³');
     END;
     GotoXY(x1,y2);
     TextColor(0);  WRITE('À');
     TextColor(9);
     FOR Loop := x1+1 TO x2-1 DO WRITE('Ä');
     WRITE('Ù');
END;


FUNCTION Byte2Hex(numb : Byte): String;
CONST HexChars : Array[0..15] of Char = '0123456789ABCDEF';
BEGIN
     Byte2Hex[0] := #2;
     Byte2Hex[1] := HexChars[numb shr  4];
     Byte2Hex[2] := HexChars[numb and 15];
END;


FUNCTION Numb2Hex(numb: Word): String;
BEGIN
     Numb2Hex := Byte2Hex(hi(numb))+Byte2Hex(lo(numb));
END;


FUNCTION Long2Hex(L: LongInt): String;
BEGIN
     Long2Hex := Numb2Hex(L shr 16) + Numb2Hex(L);
END;


FUNCTION ProperDate: Longint;
VAR  DT           : DateTime;
     WorkDate     : Longint;
     yy,mm,dd,dow : Word;
     h,m,s,s100   : Word;
BEGIN
     GetDate(yy,mm,dd,dow);
     GetTime(h,m,s,s100);
     FillChar(DT,SizeOf(DT),0);
     DT.Year  := yy;
     DT.Month := mm;
     DT.Day   := dd;
     DT.Hour  := h;
     DT.Min   := m;
     DT.Sec   := s;
     PackTime(DT,WorkDate);
     ProperDate := WorkDate;
END;


BEGIN
     ShotgunDir  := ParamStr(1);
     TheFileName := ParamStr(2);
     IF _UpperCase(ParamStr(3))='-REALNAME'
        THEN UseRealName := True
        ELSE UseRealName := False;
     IF ShotgunDir[LENGTH(ShotgunDir)]='\' THEN Delete(ShotgunDir,LENGTH(ShotgunDir),1);
     IF ((ShotgunDir='') OR (TheFileName='') OR NOT(_FileExists(TheFileName))) THEN
     BEGIN
          AppHeader('GIP Compiler/Creator For Shotgun Professional');
          WRITELN('   Syntax:   PAKGIP.EXE <basedir> <filename> <arg> ... ');
          WRITELN;
          WRITELN('   <basedir>   Main Shotgun or Gui directory. ie: C:\SHOTGUN');
          WRITELN('   <filename>  Full path/file name of SG file. ie: C:\SHOTGUN\TEST.SG');
          WRITELN('   -REALNAME   Make the GIP have the same name as the *.SG file(s)');
          WRITELN('');
          HALT;
     END;
     WRITELN;
     WRITE('GIP Area Name: '); READLN(GIPHeader.Area);
     WRITE('    GIP Title: '); READLN(GIPHeader.Title);
     WRITE('   GIP Author: '); READLN(GIPHeader.Author);
     GIPHeader.Date := ProperDate;

     SaveTheScreen;
     DrawWindow(15,10,65,14,'GIP Compiler/Creator '+ShotgunVersion);
     InvertedBox(17,11,63,13);
     SOUNDDir    := ShotgunDir+'\SOUND\';
     FONTDir     := ShotgunDir+'\FONTS\';
     ICONDir     := ShotgunDir+'\ICONS\';
     JPEGDir     := ShotgunDir+'\IMAGES\';
     FLICSDir    := ShotgunDir+'\FLICS\';
     WorkDir     := ShotgunDir+'\!1\';
     _CreatePath(WorkDir);
     ChDir(ShotgunDir);
     New(Buffer);
     FastWrite('Calculating CRCs:                  ',12,25,31);
     FastWrite(_PadRight(_NoPath(TheFileName),12),12,44,27);

     ASSIGN(FWorkSg2,TheFileName);
     ASSIGN(FWorkSg,WorkDir+'TMPOUT.SG');
     REWRITE(FWorkSg);
     RESET(FWorkSg2);
     REPEAT
           READ(FWorkSg2,WorkSg);
           CASE WorkSg.Number OF
           1:   BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     IF WorkSg.Style=1 THEN
                     BEGIN
                          IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                          BEGIN
                               ASSIGN(FIcon30,ICONDir+WorkSg.ObjFile);
                               RESET(FIcon30);
                               SEEK(FIcon30,WorkSg.Colour4-1);
                               READ(FIcon30,Icon30);
                               CLOSE(FIcon30);
                               Work := UpdateCrc32(0,$FFFFFFFF);
                               FOR LoopX := 1 TO 30 DO
                               BEGIN
                                    FOR LoopY := 1 TO 30 DO
                                    BEGIN
                                         Work := UpdateCrc32(Icon30.matrix[LoopX,LoopY],Work);
                                    END;
                               END;
                               WorkSg.Crc32   := Long2Hex(Work);
                               WorkSg.Colour4 := 1;
                               WorkSg.ObjFile := WorkSg.Crc32+'.ICO';
                          END;
                     END
                     ELSE IF WorkSg.Style=3 THEN
                     BEGIN
                          IF _FileExists(JPEGDir+WorkSg.ObjFile) THEN
                          BEGIN
                               Work := UpdateCrc32(0,$FFFFFFFF);
                               ASSIGN(FFile,JPEGDir+WorkSg.ObjFile);
                               RESET(FFile,1);
                               REPEAT
                                     BlockRead(FFile,Buffer^,SizeOf(Buffer^),BytesRead);
                                     FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(Buffer^[Loop],Work);
                               UNTIL EOF(FFile);
                               CLOSE(FFile);
                               WorkSg.Crc32 := Long2Hex(Work);
                               WorkSg.ObjFile := WorkSg.Crc32+'.IMG';
                          END;
                     END;
                     WRITE(FWorkSg,WorkSg);
                END;
           2:   BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     IF WorkSg.Style=1 THEN
                     BEGIN
                          IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                          BEGIN
                               ASSIGN(FMouseDef,ICONDir+WorkSg.ObjFile);
                               RESET(FMouseDef);
                               SEEK(FMouseDef,WorkSg.Colour1-1);
                               READ(FMouseDef,MouseDef);
                               CLOSE(FMouseDef);
                               Work := UpdateCrc32(0,$FFFFFFFF);
                               Work := UpdateCrc32(MouseDef.Colour,Work);
                               Work := UpdateCrc32(MouseDef.HotX,Work);
                               Work := UpdateCrc32(MouseDef.HotY,Work);
                               FOR LoopX := 1 TO 16 DO
                               BEGIN
                                    FOR LoopY := 1 TO 16 DO
                                    BEGIN
                                         IF MouseDef.Cursor[LoopX,LoopY]
                                            THEN Work := UpdateCrc32(1,Work)
                                            ELSE Work := UpdateCrc32(0,Work);
                                    END;
                               END;
                               FOR LoopX := 1 TO 16 DO
                               BEGIN
                                    FOR LoopY := 1 TO 16 DO
                                    BEGIN
                                         IF MouseDef.Mask[LoopX,LoopY]
                                            THEN Work := UpdateCrc32(1,Work)
                                            ELSE Work := UpdateCrc32(0,Work);
                                    END;
                               END;
                               WorkSg.Crc32 := Long2Hex(Work);
                               WorkSg.Colour1 := 1;
                               WorkSg.ObjFile := WorkSg.Crc32+'.MSE';
                          END;
                     END;
                     WRITE(FWorkSg,WorkSg);
                END;
           3:   BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     IF WorkSg.Style=1 THEN
                     BEGIN
                          IF _FileExists(SOUNDDir+WorkSg.ObjFile) THEN
                          BEGIN
                               Work := UpdateCrc32(0,$FFFFFFFF);
                               ASSIGN(FFile,SOUNDDir+WorkSg.ObjFile);
                               RESET(FFile,1);
                               REPEAT
                                     BlockRead(FFile,Buffer^,SizeOf(Buffer^),BytesRead);
                                     FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(Buffer^[Loop],Work);
                               UNTIL EOF(FFile);
                               CLOSE(FFile);
                               WorkSg.Crc32 := Long2Hex(Work);
                               WorkSg.ObjFile := WorkSg.Crc32+'.VOC';
                          END;
                     END;
                     WRITE(FWorkSg,WorkSg);
                END;
           4:   BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           5:   BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           6:   BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           7:   BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           8:   BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           9:   BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           10:  BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           11:  BEGIN
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           12:  BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                     BEGIN
                          IF WorkSg.Style=30 THEN
                          BEGIN
                               ASSIGN(FIcon30,ICONDir+WorkSg.ObjFile);
                               RESET(FIcon30);
                               SEEK(FIcon30,WorkSg.Colour1-1);
                               READ(FIcon30,Icon30);
                               CLOSE(FIcon30);
                               Work := UpdateCrc32(0,$FFFFFFFF);
                               FOR LoopX := 1 TO 30 DO
                               BEGIN
                                    FOR LoopY := 1 TO 30 DO
                                    BEGIN
                                         Work := UpdateCrc32(Icon30.matrix[LoopX,LoopY],Work);
                                    END;
                               END;
                               WorkSg.Crc32 := Long2Hex(Work);
                               WorkSg.Colour1 := 1;
                               WorkSg.ObjFile := WorkSg.Crc32+'.ICO';
                          END
                          ELSE IF WorkSg.Style=16 THEN
                          BEGIN
                               ASSIGN(FIcon16,ICONDir+WorkSg.ObjFile);
                               RESET(FIcon16);
                               SEEK(FIcon16,WorkSg.Colour1-1);
                               READ(FIcon16,Icon16);
                               CLOSE(FIcon16);
                               Work := UpdateCrc32(0,$FFFFFFFF);
                               FOR LoopX := 1 TO 16 DO
                               BEGIN
                                    FOR LoopY := 1 TO 16 DO
                                    BEGIN
                                         Work := UpdateCrc32(Icon16.matrix[LoopX,LoopY],Work);
                                    END;
                               END;
                               WorkSg.Crc32 := Long2Hex(Work);
                               WorkSg.Colour1 := 1;
                               WorkSg.ObjFile := WorkSg.Crc32+'.ICO';
                          END;
                     END;
                     WRITE(FWorkSg,WorkSg);
                END;
           13:  BEGIN
                     IF WorkSg.Colour7=0 THEN
                     BEGIN
                          IF _FileExists(FONTDir+WorkSg.ObjFile) THEN
                          BEGIN
                               Work := UpdateCrc32(0,$FFFFFFFF);
                               ASSIGN(FFile,FONTDir+WorkSg.ObjFile);
                               RESET(FFile,1);
                               REPEAT
                                     BlockRead(FFile,Buffer^,SizeOf(Buffer^),BytesRead);
                                     FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(Buffer^[Loop],Work);
                               UNTIL EOF(FFile);
                               CLOSE(FFile);
                               WorkSg.Crc32 := Long2Hex(Work);
                               WorkSg.ObjFile := WorkSg.Crc32+'.FNT';
                          END;
                     END;
                     WRITE(FWorkSg,WorkSg);
                END;
           14,15,16,17:
                BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                     REPEAT
                           READ(FWorkSg2,WorkSg);
                           FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                           FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                           FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                           WRITE(FWorkSg,WorkSg);
                     UNTIL WorkSg.Style=255;
                END;
           18:  BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           19:  BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           20:  BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           21:  BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           22:  BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     IF _FileExists(JPEGDir+WorkSg.ObjFile) THEN
                     BEGIN
                          Work := UpdateCrc32(0,$FFFFFFFF);
                          ASSIGN(FFile,JPEGDir+WorkSg.ObjFile);
                          RESET(FFile,1);
                          REPEAT
                                BlockRead(FFile,Buffer^,SizeOf(Buffer^),BytesRead);
                                FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(Buffer^[Loop],Work);
                          UNTIL EOF(FFile);
                          CLOSE(FFile);
                          WorkSg.Crc32 := Long2Hex(Work);
                          WorkSg.ObjFile := WorkSg.Crc32+'.IMG';
                     END;
                     WRITE(FWorkSg,WorkSg);
                END;
           23:  BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           24:  BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                     BEGIN
                          IF WorkSg.Style=30 THEN
                          BEGIN
                               Work := UpdateCrc32(0,$FFFFFFFF);
                               ASSIGN(FIcon30,ICONDir+WorkSg.ObjFile);
                               RESET(FIcon30);
                               SEEK(FIcon30,WorkSg.Colour1-1);
                               READ(FIcon30,Icon30);
                               CLOSE(FIcon30);
                               FOR LoopX := 1 TO 30 DO
                               BEGIN
                                    FOR LoopY := 1 TO 30 DO
                                    BEGIN
                                         Work := UpdateCrc32(Icon30.matrix[LoopX,LoopY],Work);
                                    END;
                               END;
                               ASSIGN(FIcon30,ICONDir+WorkSg.ObjFile);
                               RESET(FIcon30);
                               SEEK(FIcon30,WorkSg.Colour2-1);
                               READ(FIcon30,Icon30);
                               CLOSE(FIcon30);
                               FOR LoopX := 1 TO 30 DO
                               BEGIN
                                    FOR LoopY := 1 TO 30 DO
                                    BEGIN
                                         Work := UpdateCrc32(Icon30.matrix[LoopX,LoopY],Work);
                                    END;
                               END;
                               WorkSg.Crc32 := Long2Hex(Work);
                               WorkSg.Colour1 := 1;
                               WorkSg.Colour2 := 2;
                               WorkSg.ObjFile := WorkSg.Crc32+'.CC';
                          END
                          ELSE IF WorkSg.Style=16 THEN
                          BEGIN
                               Work := UpdateCrc32(0,$FFFFFFFF);
                               ASSIGN(FIcon16,ICONDir+WorkSg.ObjFile);
                               RESET(FIcon16);
                               SEEK(FIcon16,WorkSg.Colour1-1);
                               READ(FIcon16,Icon16);
                               CLOSE(FIcon16);
                               FOR LoopX := 1 TO 16 DO
                               BEGIN
                                    FOR LoopY := 1 TO 16 DO
                                    BEGIN
                                         Work := UpdateCrc32(Icon16.matrix[LoopX,LoopY],Work);
                                    END;
                               END;
                               ASSIGN(FIcon16,ICONDir+WorkSg.ObjFile);
                               RESET(FIcon16);
                               SEEK(FIcon16,WorkSg.Colour2-1);
                               READ(FIcon16,Icon16);
                               CLOSE(FIcon16);
                               FOR LoopX := 1 TO 16 DO
                               BEGIN
                                    FOR LoopY := 1 TO 16 DO
                                    BEGIN
                                         Work := UpdateCrc32(Icon16.matrix[LoopX,LoopY],Work);
                                    END;
                               END;
                               WorkSg.Crc32 := Long2Hex(Work);
                               WorkSg.Colour1 := 1;
                               WorkSg.Colour2 := 2;
                               WorkSg.ObjFile := WorkSg.Crc32+'.CC';
                          END;
                     END;
                     WRITE(FWorkSg,WorkSg);
                END;
           25:  BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                     BEGIN
                          IF WorkSg.Style=30 THEN
                          BEGIN
                               Work := UpdateCrc32(0,$FFFFFFFF);
                               ASSIGN(FIcon30,ICONDir+WorkSg.ObjFile);
                               RESET(FIcon30);
                               FOR Scrap := 1 TO 8 DO
                               BEGIN
                                    CASE Scrap OF
                                    1:   SEEK(FIcon30,WorkSg.Colour1-1);
                                    2:   SEEK(FIcon30,WorkSg.Colour2-1);
                                    3:   SEEK(FIcon30,WorkSg.Colour3-1);
                                    4:   SEEK(FIcon30,WorkSg.Colour4-1);
                                    5:   SEEK(FIcon30,WorkSg.Colour5-1);
                                    6:   SEEK(FIcon30,WorkSg.Colour6-1);
                                    7:   SEEK(FIcon30,WorkSg.Colour7-1);
                                    8:   SEEK(FIcon30,WorkSg.Colour8-1);
                                    END;
                                    READ(FIcon30,Icon30);
                                    FOR LoopX := 1 TO 30 DO
                                    BEGIN
                                         FOR LoopY := 1 TO 30 DO
                                         BEGIN
                                              Work := UpdateCrc32(Icon30.matrix[LoopX,LoopY],Work);
                                         END;
                                    END;
                               END;
                               CLOSE(FIcon30);
                               WorkSg.Crc32 := Long2Hex(Work);
                               WorkSg.Colour1 := 1;
                               WorkSg.Colour2 := 2;
                               WorkSg.Colour3 := 3;
                               WorkSg.Colour4 := 4;
                               WorkSg.Colour5 := 5;
                               WorkSg.Colour6 := 6;
                               WorkSg.Colour7 := 7;
                               WorkSg.Colour8 := 8;
                               WorkSg.ObjFile := WorkSg.Crc32+'.ANI';
                          END
                          ELSE IF WorkSg.Style=16 THEN
                          BEGIN
                               Work := UpdateCrc32(0,$FFFFFFFF);
                               ASSIGN(FIcon16,ICONDir+WorkSg.ObjFile);
                               RESET(FIcon16);
                               FOR Scrap := 1 TO 8 DO
                               BEGIN
                                    CASE Scrap OF
                                    1:   SEEK(FIcon16,WorkSg.Colour1-1);
                                    2:   SEEK(FIcon16,WorkSg.Colour2-1);
                                    3:   SEEK(FIcon16,WorkSg.Colour3-1);
                                    4:   SEEK(FIcon16,WorkSg.Colour4-1);
                                    5:   SEEK(FIcon16,WorkSg.Colour5-1);
                                    6:   SEEK(FIcon16,WorkSg.Colour6-1);
                                    7:   SEEK(FIcon16,WorkSg.Colour7-1);
                                    8:   SEEK(FIcon16,WorkSg.Colour8-1);
                                    END;
                                    READ(FIcon16,Icon16);
                                    FOR LoopX := 1 TO 16 DO
                                    BEGIN
                                         FOR LoopY := 1 TO 16 DO
                                         BEGIN
                                              Work := UpdateCrc32(Icon16.matrix[LoopX,LoopY],Work);
                                         END;
                                    END;
                               END;
                               CLOSE(FIcon16);
                               WorkSg.Crc32 := Long2Hex(Work);
                               WorkSg.Colour1 := 1;
                               WorkSg.Colour2 := 2;
                               WorkSg.Colour3 := 3;
                               WorkSg.Colour4 := 4;
                               WorkSg.Colour5 := 5;
                               WorkSg.Colour6 := 6;
                               WorkSg.Colour7 := 7;
                               WorkSg.Colour8 := 8;
                               WorkSg.ObjFile := WorkSg.Crc32+'.ANI';
                          END;
                     END;
                     WRITE(FWorkSg,WorkSg);
                END;
           26:  BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           27:  BEGIN
                     FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                     FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                     FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                     WRITE(FWorkSg,WorkSg);
                END;
           28:  BEGIN
                     IF _FileExists(WorkSg.Text) THEN
                     BEGIN
                          Work := UpdateCrc32(0,$FFFFFFFF);
                          ASSIGN(FFile,WorkSg.Text);
                          RESET(FFile,1);
                          REPEAT
                                BlockRead(FFile,Buffer^,SizeOf(Buffer^),BytesRead);
                                FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(Buffer^[Loop],Work);
                          UNTIL EOF(FFile);
                          CLOSE(FFile);
                          WorkSg.Crc32 := Long2Hex(Work);
                          WorkSg.Text  := WorkSg.Crc32+'.TXT';
                     END;
                     WRITE(FWorkSg,WorkSg);
                END;
           END;
     UNTIL EOF(FWorkSg2);
     CLOSE(FWorkSg2);
     CLOSE(FWorkSg);

     FastWrite('Migrating Primitives:                  ',12,21,31);
     FastWrite(_PadRight(_NoPath(TheFileName),12),12,44,27);
     ASSIGN(FWorkSg,TheFileName);
     ASSIGN(FWorkSg2,WorkDir+'TMPOUT.SG');
     RESET(FWorkSg2);
     RESET(FWorkSg);
     REPEAT
           READ(FWorkSg,WorkSg);
           READ(FWorkSg2,WorkSg2);
           CASE WorkSg.Number OF
           1:   BEGIN
                     IF WorkSg.Style=1 THEN
                     BEGIN
                          IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                          BEGIN
                               IF NOT(_FileExists(WorkDir+WorkSg2.Crc32+'.ICO')) THEN
                               BEGIN
                                    ASSIGN(FIcon30,ICONDir+WorkSg.ObjFile);
                                    ASSIGN(FIcon302,WorkDir+WorkSg2.Crc32+'.ICO');
                                    REWRITE(FIcon302);
                                    RESET(FIcon30);
                                    SEEK(FIcon30,WorkSg.Colour4-1);
                                    READ(FIcon30,Icon30);
                                    WRITE(FIcon302,Icon30);
                                    CLOSE(FIcon302);
                                    CLOSE(FIcon30);
                               END;
                          END;
                     END
                     ELSE IF WorkSg.Style=3 THEN
                     BEGIN
                          IF _FileExists(JPEGDir+WorkSg.ObjFile) THEN
                          BEGIN
                               IF NOT(_FileExists(WorkDir+WorkSg2.Crc32+'.IMG')) THEN
                               BEGIN
                                    _Copy(JPEGDir+WorkSg.ObjFile,WorkDir+WorkSg2.Crc32+'.IMG');
                               END;
                          END;
                     END;
                END;
           2:   BEGIN
                     IF WorkSg.Style=1 THEN
                     BEGIN
                          IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                          BEGIN
                               IF NOT(_FileExists(WorkDir+WorkSg2.Crc32+'.MSE')) THEN
                               BEGIN
                                    ASSIGN(FMouseDef,ICONDir+WorkSg.ObjFile);
                                    ASSIGN(FMouseDef2,WorkDir+WorkSg2.Crc32+'.MSE');
                                    REWRITE(FMouseDef2);
                                    RESET(FMouseDef);
                                    SEEK(FMouseDef,WorkSg.Colour1-1);
                                    READ(FMouseDef,MouseDef);
                                    WRITE(FMouseDef2,MouseDef);
                                    CLOSE(FMouseDef2);
                                    CLOSE(FMouseDef);
                               END;
                          END;
                     END;
                END;
           3:   IF WorkSg.Style=1 THEN
                BEGIN
                     IF _FileExists(SOUNDDir+WorkSg.ObjFile) THEN
                     BEGIN
                          IF NOT(_FileExists(WorkDir+WorkSg2.Crc32+'.VOC')) THEN
                          BEGIN
                               _Copy(SOUNDDir+WorkSg.ObjFile,WorkDir+WorkSg2.Crc32+'.VOC');
                          END;
                     END;
                END;
           12:  BEGIN
                     IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                     BEGIN
                          IF NOT(_FileExists(WorkDir+WorkSg2.Crc32+'.ICO')) THEN
                          BEGIN
                               IF WorkSg.Style=30 THEN
                               BEGIN
                                    ASSIGN(FIcon30,ICONDir+WorkSg.ObjFile);
                                    ASSIGN(FIcon302,WorkDir+WorkSg2.Crc32+'.ICO');
                                    REWRITE(FIcon302);
                                    RESET(FIcon30);
                                    SEEK(FIcon30,WorkSg.Colour1-1);
                                    READ(FIcon30,Icon30);
                                    WRITE(FIcon302,Icon30);
                                    CLOSE(FIcon302);
                                    CLOSE(FIcon30);
                               END
                               ELSE IF WorkSg.Style=16 THEN
                               BEGIN
                                    ASSIGN(FIcon16,ICONDir+WorkSg.ObjFile);
                                    ASSIGN(FIcon162,WorkDir+WorkSg2.Crc32+'.ICO');
                                    REWRITE(FIcon162);
                                    RESET(FIcon16);
                                    SEEK(FIcon16,WorkSg.Colour1-1);
                                    READ(FIcon16,Icon16);
                                    WRITE(FIcon162,Icon16);
                                    CLOSE(FIcon162);
                                    CLOSE(FIcon16);
                               END;
                          END;
                     END;
                END;
           13:  IF WorkSg.Colour7=0 THEN
                BEGIN
                     IF _FileExists(FONTDir+WorkSg.ObjFile) THEN
                     BEGIN
                          IF NOT(_FileExists(WorkDir+WorkSg2.Crc32+'.FNT')) THEN
                          BEGIN
                               _Copy(FONTDir+WorkSg.ObjFile,WorkDir+WorkSg2.Crc32+'.FNT');
                          END;
                     END;
                END;
           14,15,16,17:
                REPEAT
                      READ(FWorkSg,WorkSg);
                      READ(FWorkSg2,WorkSg2);
                UNTIL WorkSg.Style=255;
           22:  IF _FileExists(JPEGDir+WorkSg.ObjFile) THEN
                BEGIN
                     IF NOT(_FileExists(WorkDir+WorkSg2.Crc32+'.IMG')) THEN
                     BEGIN
                          _Copy(JPEGDir+WorkSg.ObjFile,WorkDir+WorkSg2.Crc32+'.IMG');
                     END;
                END;
           24:  BEGIN
                     IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                     BEGIN
                          IF NOT(_FileExists(WorkDir+WorkSg2.Crc32+'.CC')) THEN
                          BEGIN
                               IF WorkSg.Style=30 THEN
                               BEGIN
                                    ASSIGN(FIcon30,ICONDir+WorkSg.ObjFile);
                                    ASSIGN(FIcon302,WorkDir+WorkSg2.Crc32+'.CC');
                                    REWRITE(FIcon302);
                                    RESET(FIcon30);
                                    SEEK(FIcon30,WorkSg.Colour1-1);
                                    READ(FIcon30,Icon30);
                                    WRITE(FIcon302,Icon30);
                                    SEEK(FIcon30,WorkSg.Colour2-1);
                                    READ(FIcon30,Icon30);
                                    WRITE(FIcon302,Icon30);
                                    CLOSE(FIcon302);
                                    CLOSE(FIcon30);
                               END
                               ELSE IF WorkSg.Style=16 THEN
                               BEGIN
                                    ASSIGN(FIcon16,ICONDir+WorkSg.ObjFile);
                                    ASSIGN(FIcon162,WorkDir+WorkSg2.Crc32+'.CC');
                                    REWRITE(FIcon162);
                                    RESET(FIcon16);
                                    SEEK(FIcon16,WorkSg.Colour1-1);
                                    READ(FIcon16,Icon16);
                                    WRITE(FIcon162,Icon16);
                                    SEEK(FIcon16,WorkSg.Colour2-1);
                                    READ(FIcon16,Icon16);
                                    WRITE(FIcon162,Icon16);
                                    CLOSE(FIcon162);
                                    CLOSE(FIcon16);
                               END;
                          END;
                     END;
                END;
           25:  BEGIN
                     IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                     BEGIN
                          IF NOT(_FileExists(WorkDir+WorkSg2.Crc32+'.ANI')) THEN
                          BEGIN
                               IF WorkSg.Style=30 THEN
                               BEGIN
                                    ASSIGN(FIcon30,ICONDir+WorkSg.ObjFile);
                                    ASSIGN(FIcon302,WorkDir+WorkSg2.Crc32+'.ANI');
                                    REWRITE(FIcon302);
                                    RESET(FIcon30);
                                    FOR Scrap := 1 TO 8 DO
                                    BEGIN
                                         CASE Scrap OF
                                         1:   SEEK(FIcon30,WorkSg.Colour1-1);
                                         2:   SEEK(FIcon30,WorkSg.Colour2-1);
                                         3:   SEEK(FIcon30,WorkSg.Colour3-1);
                                         4:   SEEK(FIcon30,WorkSg.Colour4-1);
                                         5:   SEEK(FIcon30,WorkSg.Colour5-1);
                                         6:   SEEK(FIcon30,WorkSg.Colour6-1);
                                         7:   SEEK(FIcon30,WorkSg.Colour7-1);
                                         8:   SEEK(FIcon30,WorkSg.Colour8-1);
                                         END;
                                         READ(FIcon30,Icon30);
                                         WRITE(FIcon302,Icon30);
                                    END;
                                    CLOSE(FIcon302);
                                    CLOSE(FIcon30);
                               END
                               ELSE IF WorkSg.Style=16 THEN
                               BEGIN
                                    ASSIGN(FIcon16,ICONDir+WorkSg.ObjFile);
                                    ASSIGN(FIcon162,WorkDir+WorkSg2.Crc32+'.ANI');
                                    REWRITE(FIcon162);
                                    RESET(FIcon16);
                                    FOR Scrap := 1 TO 8 DO
                                    BEGIN
                                         CASE Scrap OF
                                         1:   SEEK(FIcon16,WorkSg.Colour1-1);
                                         2:   SEEK(FIcon16,WorkSg.Colour2-1);
                                         3:   SEEK(FIcon16,WorkSg.Colour3-1);
                                         4:   SEEK(FIcon16,WorkSg.Colour4-1);
                                         5:   SEEK(FIcon16,WorkSg.Colour5-1);
                                         6:   SEEK(FIcon16,WorkSg.Colour6-1);
                                         7:   SEEK(FIcon16,WorkSg.Colour7-1);
                                         8:   SEEK(FIcon16,WorkSg.Colour8-1);
                                         END;
                                         READ(FIcon16,Icon16);
                                         WRITE(FIcon162,Icon16);
                                    END;
                                    CLOSE(FIcon162);
                                    CLOSE(FIcon16);
                               END;
                          END;
                     END;
                END;
           28:  BEGIN
                     IF _FileExists(WorkSg.Text) THEN
                     BEGIN
                          IF NOT(_FileExists(WorkDir+WorkSg2.Crc32+'.TXT')) THEN
                          BEGIN
                               _Copy(WorkSg.Text,WorkDir+WorkSg2.Crc32+'.TXT');
                          END;
                     END;
                END;
           END;
     UNTIL EOF(FWorkSg);
     CLOSE(FWorkSg2);
     CLOSE(FWorkSg);

     FastWrite(' Creating Screen CRC:                  ',12,21,31);
     FastWrite(_PadRight(_NoPath(TheFileName),12),12,44,27);
     Work := UpdateCrc32(0,$FFFFFFFF);
     ASSIGN(FFile,WorkDir+'TMPOUT.SG');
     RESET(FFile,1);
     REPEAT
           BlockRead(FFile,Buffer^,SizeOf(Buffer^),BytesRead);
           FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(Buffer^[Loop],Work);
     UNTIL EOF(FFile);
     CLOSE(FFile);
     ASSIGN(FFile,WorkDir+'TMPOUT.SG');
     IF UseRealName THEN RENAME(FFile,WorkDir+_NoExtension(_NoPath(TheFileName))+'.SG')
                    ELSE RENAME(FFile,WorkDir+Long2Hex(Work)+'.SG');
     FastWrite('   Creating GIP File:                  ',12,21,31);
     FastWrite(_PadRight(_NoPath(TheFileName),12),12,44,27);
     IF UseRealName THEN ASSIGN(FFile,_NoExtension(_NoPath(TheFileName))+'.GIP')
                    ELSE ASSIGN(FFile,Long2Hex(Work)+'.GIP');
     REWRITE(FFile,1);
     BLOCKWRITE(FFile,GIPHeader,SizeOf(GIPHeader));
     NumFiles := 0;
     FindFirst(WorkDir+'*.*',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          INC(NumFiles);
          LotsaFiles[NumFiles] := DirInfo.Name;
          FindNext(DirInfo);
     END;
     FOR Loop := 1 TO NumFiles DO
     BEGIN
          ASSIGN(FFile2,WorkDir+LotsaFiles[Loop]);
          RENAME(FFile2,WorkDir+'COMPRESS.TMP');
          CompressFile(WorkDir+'COMPRESS.TMP',WorkDir+LotsaFiles[Loop]);
          GIPFileHeader.FName      := LotsaFiles[Loop];
          GIPFileHeader.FileLength := _FileSize(WorkDir+LotsaFiles[Loop]);
          BLOCKWRITE(FFile,GIPFileHeader,SizeOf(GIPFileHeader));
          _EraseFile(WorkDir+'COMPRESS.TMP');
          ASSIGN(FFile2,WorkDir+LotsaFiles[Loop]);
          RESET(FFile2,1);
          REPEAT
                BlockRead(FFile2,Buffer^,SizeOf(Buffer^),BytesRead);
                BlockWrite(FFile,Buffer^,BytesRead);
          UNTIL EOF(FFile2);
          CLOSE(FFile2);
          ERASE(FFile2);
     END;
     CLOSE(FFile);
     ChDir(ShotgunDir);
     Dec(WorkDir[0]);
     _NukeDir(WorkDir,False);
     Dispose(Buffer);
     RestoreTheScreen;
END.