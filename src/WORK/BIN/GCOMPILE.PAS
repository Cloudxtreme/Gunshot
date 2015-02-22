{$I DEFINES.INC}
{$M 32000,0,512000}
PROGRAM GraphicsCompiler;


USES Dos,ApMisc,BsFrames,BsComp,BsKeys,Crt,Shotgun,Version,BsString,BsFile,BsCrc,BsVideo,MkFFile,FMode;


TYPE BigBuffer = Array[1..8192] Of Byte;
TYPE FileNameBuffer = Array[1..3000] Of String[12];
TYPE SAVESCRNAScreen = Array[1..4000] Of Byte;
VAR  SAVESCRNScr   : SAVESCRNAScreen;
     FFile         : File;
     Work          : Longint;
     Buffer        : ^BigBuffer;
     BytesRead     : Word;
     Loop          : Word;
     DirInfo       : SearchRec;
     uploaded_file : string;
     Dest_file     : String;
     LoopX         : Word;
     LoopY         : Word;
     X             : Word;
     Y             : Word;
     FNames        : ^FileNameBuffer;
     NumFiles      : Word;
     BigLoop       : Word;
     Scrap         : Word;
     WorkSg        : _Raw_File;
     Icon30        : _Icon30x30;
     Icon16        : _Icon16x16;
     MouseDef      : _Mouse_Def;
     FWorkSg       : File Of _Raw_File;
     FWorkSg1      : FFileObj;
     FWorkSg2      : FFileObj;
     FIcon30       : File Of _Icon30x30;
     FIcon302      : File Of _Icon30x30;
     FIcon16       : File Of _Icon16x16;
     FIcon162      : File Of _Icon16x16;
     FMouseDef     : File Of _Mouse_Def;
     FMouseDef2    : File Of _Mouse_Def;
     ShotgunDir    : String[40];
     SGDir         : String[40];
     SGXDir        : String[40];
     FileSpec      : String[12];
     ResourceDir   : String[40];
     LocalDir      : String[40];
     SOUNDDir      : String[40];
     FLICSDir      : String[40];
     ICONDir       : String[40];
     FONTDir       : String[40];
     JPEGDir       : String[40];
     SavedX        : Word;
     SavedY        : Word;
     SavedAttr     : Byte;
     CompFile      : String;
     SkipEx        : Boolean;
     BBytesRead    : Word;


PROCEDURE SaveTheScreen;
BEGIN
     SavedX := WhereX;
     SavedY := WhereY;
     SavedAttr := TextAttr;
     _HideCursor;
{$IFDEF MSDOS}
     Move(MEM[SegB800:0],SAVESCRNScr[1],4000);
{$ENDIF}
{$IFNDEF MSDOS}
  WriteLn('REEPORT GCOMPILE SaveTheScreen'); Halt;
{$ENDIF}
END;


PROCEDURE RestoreTheScreen;
BEGIN
{$IFDEF MSDOS}
     Move(SAVESCRNScr[1],MEM[SegB800:0],4000);
{$ENDIF}
{$IFNDEF MSDOS}
  WriteLn('REEPORT GCOMPILE RestoreTheScreen'); Halt;
{$ENDIF}
     GotoXy(SavedX,SavedY);
     TextAttr := SavedAttr;
     _ShowCursor;
END;


PROCEDURE DrawWindow(x1,y1,x2,y2: Word; Title: String);
VAR  LoopYY : Word;
     LoopXX : Word;
     Loop2  : Word;
BEGIN
     winDropShadow(x1,y1,x2,y2);
     TextBackGround(1);
     FOR LoopYY := y1 TO y2 DO
     BEGIN
          GOTOXY(x1,LoopYY);
          IF LoopYY=y1 THEN
          BEGIN
               TextColor(9);
               WRITE('Ú');
               FOR Loop2 := x1+1 TO x2-1 DO WRITE('Ä');
               TextColor(0);
               WRITE('¿');
          END
          ELSE IF LoopYY=y2 THEN
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
VAR  LLoop : Word;
BEGIN
     TextBackground(1);
     TextColor(0);
     GotoXY(x1,y1);
     WRITE('Ú');
     FOR LLoop := x1+1 TO x2-1 DO WRITE('Ä');
     TextColor(9);
     WRITE('¿');
     FOR LLoop := y1+1 TO y2-1 DO
     BEGIN
          GotoXY(x1,LLoop);
          TextColor(0);  WRITE('³');
          GotoXY(x2,LLoop);
          TextColor(9); WRITE('³');
     END;
     GotoXY(x1,y2);
     TextColor(0);  WRITE('À');
     TextColor(9);
     FOR LLoop := x1+1 TO x2-1 DO WRITE('Ä');
     WRITE('Ù');
END;


PROCEDURE GetSGXDir;
VAR  Temp  : String;
     LLoop : Word;
BEGIN
     Temp := '';
     IF SGDir<>'' THEN
     BEGIN
          FOR LLoop := LENGTH(SGDir)-1 DOWNTO 1 DO
          BEGIN
               IF SGDir[LLoop]='\' THEN
               BEGIN
                    SGXDir := _Mid(SGDir,1,LLoop)+'SGX\';
                    Exit;
               END;
          END;
     END;
     SGXDir := '';
END;


BEGIN
     FileMode    := SetFileMode;
     ShotgunDir  := ParamStr(1);
     SGDir       := ParamStr(2);
     IF _UpperCase(ParamStr(3))='SKIP'
        THEN SkipEx := True
        ELSE SkipEx := False;
     FileSpec    := _NoPath(SGDir);
     SGDir       := _GetFilePath(SGDir);
     GetSGXDir;
     IF ShotgunDir[LENGTH(ShotgunDir)]='\' THEN Dec(ShotgunDir[0]);
     IF SGDir[LENGTH(SGDir)]='\' THEN Dec(SGDir[0]);
     IF ((ShotgunDir='') OR (SGDir='') OR (SGXDir='')) THEN
     BEGIN
          TextColor(7);
          TextBackground(0);
          ClrScr;
          TextColor(11); WRITELN('SHOTGUN PROFESSIONAL '+ShotgunVersion);
          TextColor(9);  WRITELN('YAPP Resource Compiler');
          TextColor(1);  WRITELN(ShotgunCopyright);
          TextColor(10); WRITELN('');
          WRITELN('   Syntax:   GCOMPILE.EXE <basedir> <langspec> <SKIP>');
          TextColor(7);  WRITELN('');
          WRITELN('   <basedir>   Main Shotgun directory. ie: C:\SHOTGUN');
          WRITELN('   <langspec>  Full file spec of the *.SG files. ie: C:\SHOTGUN\ENGLISH\SG\*.SG');
          WRITELN('   <SKIP>      The optional SKIP paramater will inhibit compilation of some');
          WRITELN('               resource such as FLIs and VOCs.');
          WRITELN('');
          HALT;
     END;
     SaveTheScreen;
     DrawWindow(15,10,65,14,'YAPP Resource Compiler '+ShotgunVersion);
     InvertedBox(17,11,63,13);
     ResourceDir := ShotgunDir+'\RESOURCE';
     LocalDir    := ShotgunDir+'\RESLOCAL';
     SOUNDDir    := ShotgunDir+'\SOUND\';
     FONTDir     := ShotgunDir+'\FONTS\';
     ICONDir     := ShotgunDir+'\ICONS\';
     JPEGDir     := ShotgunDir+'\IMAGES\';
     FLICSDir    := ShotgunDir+'\FLICS\';
     _CreatePath(ResourceDir);
     _CreatePath(LocalDir);
     _CreatePath(SGDir);
     _CreatePath(SGXDir);
     New(Buffer);
     New(FNames);
     NEW(CBuffer);
     FWorkSg1.Init(32768);
     FWorkSg2.Init(32768);
     ChDir(SGDir);
     NumFiles := 0;
     FindFirst(FileSpec,Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          INC(NumFiles);
          FNames^[NumFiles] := DirInfo.Name;
          FindNext(DirInfo);
     END;
     FastWrite('Calculating CRCs:                  ',12,25,31);
     FOR BigLoop := 1 TO NumFiles DO
     BEGIN
          uploaded_file := FNames^[BigLoop];
          FastWrite(_PadRight(uploaded_file,12),12,44,27);
          _EraseFile(_NoExtension(uploaded_file)+'.BAK');
          ASSIGN(FWorkSg,uploaded_file);
          RENAME(FWorkSg,_NoExtension(uploaded_file)+'.BAK');
          FWorkSg1.OpenFile(uploaded_file,SetFileMode);
          FWorkSg2.OpenFile(_NoExtension(uploaded_file)+'.BAK',SetFileMode);
          REPEAT
                FWorkSg2.BlkRead(WorkSg,SizeOf(WorkSg),BBytesRead);
                IF (BBytesRead<>0) THEN
                BEGIN

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
                                    Work := $FFFFFFFF;
                                    Work := UpdateCrc32(0,Work);
                                    FOR LoopX := 1 TO 30 DO
                                    BEGIN
                                         FOR LoopY := 1 TO 30 DO
                                         BEGIN
                                              Work := UpdateCrc32(Icon30.matrix[LoopX,LoopY],Work);
                                         END;
                                    END;
                                    WorkSg.Crc32 := Long2Hex(Work);
                               END;
                          END
                          ELSE IF WorkSg.Style=3 THEN
                          BEGIN
                               IF _FileExists(JPEGDir+WorkSg.ObjFile) THEN
                               BEGIN
                                    Work := $FFFFFFFF;
                                    Work := UpdateCrc32(0,Work);
                                    ASSIGN(FFile,JPEGDir+WorkSg.ObjFile);
                                    RESET(FFile,1);
                                    REPEAT
                                          BlockRead(FFile,Buffer^,SizeOf(Buffer^),BytesRead);
                                          FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(Buffer^[Loop],Work);
                                    UNTIL EOF(FFile);
                                    CLOSE(FFile);
                                    WorkSg.Crc32 := Long2Hex(Work);
                               END;
                          END;
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
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
                                    Work := $FFFFFFFF;
                                    Work := UpdateCrc32(0,Work);
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
                               END;
                          END;
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                3:   BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          IF WorkSg.Style=1 THEN
                          BEGIN
                               IF _FileExists(SOUNDDir+WorkSg.ObjFile) THEN
                               BEGIN
                                    Work := $FFFFFFFF;
                                    Work := UpdateCrc32(0,Work);
                                    ASSIGN(FFile,SOUNDDir+WorkSg.ObjFile);
                                    RESET(FFile,1);
                                    REPEAT
                                          BlockRead(FFile,Buffer^,SizeOf(Buffer^),BytesRead);
                                          FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(Buffer^[Loop],Work);
                                    UNTIL EOF(FFile);
                                    CLOSE(FFile);
                                    WorkSg.Crc32 := Long2Hex(Work);
                               END;
                          END;
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                4:   BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                5:   BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                6:   BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                7:   BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                8:   BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                9:   BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                10:  BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                11:  BEGIN
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
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
                                    Work := $FFFFFFFF;
                                    Work := UpdateCrc32(0,Work);
                                    FOR LoopX := 1 TO 30 DO
                                    BEGIN
                                         FOR LoopY := 1 TO 30 DO
                                         BEGIN
                                              Work := UpdateCrc32(Icon30.matrix[LoopX,LoopY],Work);
                                         END;
                                    END;
                                    WorkSg.Crc32 := Long2Hex(Work);
                               END
                               ELSE IF WorkSg.Style=16 THEN
                               BEGIN
                                    ASSIGN(FIcon16,ICONDir+WorkSg.ObjFile);
                                    RESET(FIcon16);
                                    SEEK(FIcon16,WorkSg.Colour1-1);
                                    READ(FIcon16,Icon16);
                                    CLOSE(FIcon16);
                                    Work := $FFFFFFFF;
                                    Work := UpdateCrc32(0,Work);
                                    FOR LoopX := 1 TO 16 DO
                                    BEGIN
                                         FOR LoopY := 1 TO 16 DO
                                         BEGIN
                                              Work := UpdateCrc32(Icon16.matrix[LoopX,LoopY],Work);
                                         END;
                                    END;
                                    WorkSg.Crc32 := Long2Hex(Work);
                               END;
                          END;
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                13:  BEGIN
                          IF WorkSg.Colour7=0 THEN
                          BEGIN
                               IF _FileExists(FONTDir+WorkSg.ObjFile) THEN
                               BEGIN
                                    Work := $FFFFFFFF;
                                    Work := UpdateCrc32(0,Work);
                                    ASSIGN(FFile,FONTDir+WorkSg.ObjFile);
                                    RESET(FFile,1);
                                    REPEAT
                                          BlockRead(FFile,Buffer^,SizeOf(Buffer^),BytesRead);
                                          FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(Buffer^[Loop],Work);
                                    UNTIL EOF(FFile);
                                    CLOSE(FFile);
                                    WorkSg.Crc32 := Long2Hex(Work);
                               END;
                          END;
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                14,15,16,17:
                     BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                          REPEAT
                                FWorkSg2.BlkRead(WorkSg,SizeOf(WorkSg),BBytesRead);
                                FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                                FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                                FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                                FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                          UNTIL WorkSg.Style=255;
                     END;
                18:  BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                19:  BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                20:  BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                21:  BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                22:  BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          IF _FileExists(JPEGDir+WorkSg.ObjFile) THEN
                          BEGIN
                               Work := $FFFFFFFF;
                               Work := UpdateCrc32(0,Work);
                               ASSIGN(FFile,JPEGDir+WorkSg.ObjFile);
                               RESET(FFile,1);
                               REPEAT
                                     BlockRead(FFile,Buffer^,SizeOf(Buffer^),BytesRead);
                                     FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(Buffer^[Loop],Work);
                               UNTIL EOF(FFile);
                               CLOSE(FFile);
                               WorkSg.Crc32 := Long2Hex(Work);
                          END;
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                23:  BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                24:  BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                          BEGIN
                               IF WorkSg.Style=30 THEN
                               BEGIN
                                    Work := $FFFFFFFF;
                                    Work := UpdateCrc32(0,Work);
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
                               END
                               ELSE IF WorkSg.Style=16 THEN
                               BEGIN
                                    Work := $FFFFFFFF;
                                    Work := UpdateCrc32(0,Work);
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
                               END;
                          END;
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                25:  BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                          BEGIN
                               IF WorkSg.Style=30 THEN
                               BEGIN
                                    Work := $FFFFFFFF;
                                    Work := UpdateCrc32(0,Work);
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
                               END
                               ELSE IF WorkSg.Style=16 THEN
                               BEGIN
                                    Work := $FFFFFFFF;
                                    Work := UpdateCrc32(0,Work);
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
                               END;
                          END;
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                26:  BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                27:  BEGIN
                          FillChar(WorkSg.Text,SizeOf(WorkSg.Text),0);
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                28:  BEGIN
                          FillChar(WorkSg.ObjFile,SizeOf(WorkSg.ObjFile),0);
                          FillChar(WorkSg.Crc32,SizeOf(WorkSg.Crc32),0);
                          FWorkSg1.BlkWrite(WorkSg,SizeOf(WorkSg));
                     END;
                END;

                END;
          UNTIL BBytesRead=0;
          FWorkSg1.CloseFile;
          FWorkSg2.CloseFile;
          _EraseFile(_NoExtension(uploaded_file)+'.BAK');
     END;

     FastWrite('Compiling Screen:                  ',12,25,31);
     FOR BigLoop := 1 TO NumFiles DO
     BEGIN
          uploaded_file := FNames^[BigLoop];
          dest_file := _NoExtension(uploaded_file)+'.SGX';
          FastWrite(_PadRight(dest_file,12),12,44,27);
          pCompressFile(uploaded_file,SGXDir+dest_file);
     END;

     FastWrite('Migrating Primitives:                  ',12,21,31);
     FOR BigLoop := 1 TO NumFiles DO
     BEGIN
          uploaded_file := FNames^[BigLoop];
          FastWrite(_PadRight(uploaded_file,12),12,44,27);
          ASSIGN(FWorkSg,uploaded_file);
          RESET(FWorkSg);
          REPEAT
                READ(FWorkSg,WorkSg);
                CASE WorkSg.Number OF
                1:   BEGIN
                          IF WorkSg.Style=1 THEN
                          BEGIN
                               IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                               BEGIN
                                    IF NOT(_FileExists(ResourceDir+'\'+WorkSg.Crc32+'.ICO')) THEN
                                    BEGIN
                                         ASSIGN(FIcon30,ICONDir+WorkSg.ObjFile);
                                         ASSIGN(FIcon302,ResourceDir+'\'+WorkSg.Crc32+'.$$$');
                                         REWRITE(FIcon302);
                                         RESET(FIcon30);
                                         SEEK(FIcon30,WorkSg.Colour4-1);
                                         READ(FIcon30,Icon30);
                                         WRITE(FIcon302,Icon30);
                                         CLOSE(FIcon302);
                                         CLOSE(FIcon30);
                                         pCompressFile(ResourceDir+'\'+WorkSg.Crc32+'.$$$',
                                                      ResourceDir+'\'+WorkSg.Crc32+'.ICO');
                                         _Copy(ResourceDir+'\'+WorkSg.Crc32+'.$$$',LocalDir+'\'+WorkSg.Crc32+'.ICO');
                                         _EraseFile(ResourceDir+'\'+WorkSg.Crc32+'.$$$');
                                    END;
                               END;
                          END
                          ELSE IF WorkSg.Style=3 THEN
                          BEGIN
                               IF _FileExists(JPEGDir+WorkSg.ObjFile) THEN
                               BEGIN
                                    IF NOT(_FileExists(ResourceDir+'\'+WorkSg.Crc32+'.IMG')) THEN
                                    BEGIN
                                         pCompressFile(JPEGDir+WorkSg.ObjFile,ResourceDir+'\'+WorkSg.Crc32+'.IMG');
                                         _Copy(JPEGDir+WorkSg.ObjFile,LocalDir+'\'+WorkSg.Crc32+'.IMG');
                                    END;
                               END;
                          END;
                     END;
                2:   BEGIN
                          IF WorkSg.Style=1 THEN
                          BEGIN
                               IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                               BEGIN
                                    IF NOT(_FileExists(ResourceDir+'\'+WorkSg.Crc32+'.MSE')) THEN
                                    BEGIN
                                         ASSIGN(FMouseDef,ICONDir+WorkSg.ObjFile);
                                         ASSIGN(FMouseDef2,ResourceDir+'\'+WorkSg.Crc32+'.$$$');
                                         REWRITE(FMouseDef2);
                                         RESET(FMouseDef);
                                         SEEK(FMouseDef,WorkSg.Colour1-1);
                                         READ(FMouseDef,MouseDef);
                                         WRITE(FMouseDef2,MouseDef);
                                         CLOSE(FMouseDef2);
                                         CLOSE(FMouseDef);
                                         pCompressFile(ResourceDir+'\'+WorkSg.Crc32+'.$$$',
                                                      ResourceDir+'\'+WorkSg.Crc32+'.MSE');
                                         _Copy(ResourceDir+'\'+WorkSg.Crc32+'.$$$',LocalDir+'\'+WorkSg.Crc32+'.MSE');
                                         _EraseFile(ResourceDir+'\'+WorkSg.Crc32+'.$$$');
                                    END;
                               END;
                          END;
                     END;
                3:   IF WorkSg.Style=1 THEN
                     BEGIN
                          IF _FileExists(SOUNDDir+WorkSg.ObjFile) THEN
                          BEGIN
                               IF NOT(_FileExists(ResourceDir+'\'+WorkSg.Crc32+'.VOC')) THEN
                               BEGIN
                                    pCompressFile(SOUNDDir+WorkSg.ObjFile,ResourceDir+'\'+WorkSg.Crc32+'.VOC');
                                    _Copy(SOUNDDir+WorkSg.ObjFile,LocalDir+'\'+WorkSg.Crc32+'.VOC');
                               END;
                          END;
                     END;
                12:  BEGIN
                          IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                          BEGIN
                               IF NOT(_FileExists(ResourceDir+'\'+WorkSg.Crc32+'.ICO')) THEN
                               BEGIN
                                    IF WorkSg.Style=30 THEN
                                    BEGIN
                                         ASSIGN(FIcon30,ICONDir+WorkSg.ObjFile);
                                         ASSIGN(FIcon302,ResourceDir+'\'+WorkSg.Crc32+'.$$$');
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
                                         ASSIGN(FIcon162,ResourceDir+'\'+WorkSg.Crc32+'.$$$');
                                         REWRITE(FIcon162);
                                         RESET(FIcon16);
                                         SEEK(FIcon16,WorkSg.Colour1-1);
                                         READ(FIcon16,Icon16);
                                         WRITE(FIcon162,Icon16);
                                         CLOSE(FIcon162);
                                         CLOSE(FIcon16);
                                    END;
                                    pCompressFile(ResourceDir+'\'+WorkSg.Crc32+'.$$$',
                                                 ResourceDir+'\'+WorkSg.Crc32+'.ICO');
                                    _Copy(ResourceDir+'\'+WorkSg.Crc32+'.$$$',LocalDir+'\'+WorkSg.Crc32+'.ICO');
                                    _EraseFile(ResourceDir+'\'+WorkSg.Crc32+'.$$$');
                               END;
                          END;
                     END;
                13:  IF WorkSg.Colour7=0 THEN
                     BEGIN
                          IF _FileExists(FONTDir+WorkSg.ObjFile) THEN
                          BEGIN
                               IF NOT(_FileExists(ResourceDir+'\'+WorkSg.Crc32+'.FNT')) THEN
                               BEGIN
                                    pCompressFile(FONTDir+WorkSg.ObjFile,ResourceDir+'\'+WorkSg.Crc32+'.FNT');
                                    _Copy(FONTDir+WorkSg.ObjFile,LocalDir+'\'+WorkSg.Crc32+'.FNT');
                               END;
                          END;
                     END;
                14,15,16,17:
                     REPEAT
                           READ(FWorkSg,WorkSg);
                     UNTIL WorkSg.Style=255;
                22:  IF _FileExists(JPEGDir+WorkSg.ObjFile) THEN
                     BEGIN
                          IF NOT(_FileExists(ResourceDir+'\'+WorkSg.Crc32+'.IMG')) THEN
                          BEGIN
                               pCompressFile(JPEGDir+WorkSg.ObjFile,ResourceDir+'\'+WorkSg.Crc32+'.IMG');
                               _Copy(JPEGDir+WorkSg.ObjFile,LocalDir+'\'+WorkSg.Crc32+'.IMG');
                          END;
                     END;
                24:  BEGIN
                          IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                          BEGIN
                               IF NOT(_FileExists(ResourceDir+'\'+WorkSg.Crc32+'.CC')) THEN
                               BEGIN
                                    IF WorkSg.Style=30 THEN
                                    BEGIN
                                         ASSIGN(FIcon30,ICONDir+WorkSg.ObjFile);
                                         ASSIGN(FIcon302,ResourceDir+'\'+WorkSg.Crc32+'.$$$');
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
                                         ASSIGN(FIcon162,ResourceDir+'\'+WorkSg.Crc32+'.$$$');
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
                                    pCompressFile(ResourceDir+'\'+WorkSg.Crc32+'.$$$',
                                                 ResourceDir+'\'+WorkSg.Crc32+'.CC');
                                    _Copy(ResourceDir+'\'+WorkSg.Crc32+'.$$$',LocalDir+'\'+WorkSg.Crc32+'.CC');
                                    _EraseFile(ResourceDir+'\'+WorkSg.Crc32+'.$$$');
                               END;
                          END;
                     END;
                25:  BEGIN
                          IF _FileExists(ICONDir+WorkSg.ObjFile) THEN
                          BEGIN
                               IF NOT(_FileExists(ResourceDir+'\'+WorkSg.Crc32+'.ANI')) THEN
                               BEGIN
                                    IF WorkSg.Style=30 THEN
                                    BEGIN
                                         ASSIGN(FIcon30,ICONDir+WorkSg.ObjFile);
                                         ASSIGN(FIcon302,ResourceDir+'\'+WorkSg.Crc32+'.$$$');
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
                                         ASSIGN(FIcon162,ResourceDir+'\'+WorkSg.Crc32+'.$$$');
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
                                    pCompressFile(ResourceDir+'\'+WorkSg.Crc32+'.$$$',
                                                 ResourceDir+'\'+WorkSg.Crc32+'.ANI');
                                    _Copy(ResourceDir+'\'+WorkSg.Crc32+'.$$$',LocalDir+'\'+WorkSg.Crc32+'.ANI');
                                    _EraseFile(ResourceDir+'\'+WorkSg.Crc32+'.$$$');
                               END;
                          END;
                     END;
                END;
          UNTIL EOF(FWorkSg);
          CLOSE(FWorkSg);
     END;
     IF NOT(SkipEx) THEN
     BEGIN
          FastWrite('     Compiling FLICs:                  ',12,21,31);
          FindFirst(FLICSDir+'*.FLI',Anyfile-Directory-VolumeID,DirInfo);
          WHILE DosError = 0 DO
          BEGIN
               FastWrite(_PadRight(DirInfo.Name,12),12,44,27);
               Work := $FFFFFFFF;
               Work := UpdateCrc32(0,Work);
               ASSIGN(FFile,FLICSDir+DirInfo.Name);
               RESET(FFile,1);
               REPEAT
                     BlockRead(FFile,Buffer^,SizeOf(Buffer^),BytesRead);
                     FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(Buffer^[Loop],Work);
               UNTIL EOF(FFile);
               CLOSE(FFile);
               CompFile := Long2Hex(Work);
               IF NOT(_FileExists(ResourceDir+'\'+CompFile+'.FLI')) THEN
               BEGIN
                    pCompressFile(FLICSDir+DirInfo.Name,CompFile+'.FLI');
                    _MoveFile(CompFile+'.FLI',SGDir,ResourceDir);
               END;
               FindNext(DirInfo);
          END;
          FastWrite('      Compiling VOCs:                  ',12,21,31);
          FindFirst(SOUNDDir+'*.VOC',Anyfile-Directory-VolumeID,DirInfo);
          WHILE DosError = 0 DO
          BEGIN
               FastWrite(_PadRight(DirInfo.Name,12),12,44,27);
               Work := $FFFFFFFF;
               Work := UpdateCrc32(0,Work);
               ASSIGN(FFile,SOUNDDir+DirInfo.Name);
               RESET(FFile,1);
               REPEAT
                     BlockRead(FFile,Buffer^,SizeOf(Buffer^),BytesRead);
                     FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(Buffer^[Loop],Work);
               UNTIL EOF(FFile);
               CLOSE(FFile);
               CompFile := Long2Hex(Work);
               IF NOT(_FileExists(ResourceDir+'\'+CompFile+'.VOC')) THEN
               BEGIN
                    pCompressFile(SOUNDDir+DirInfo.Name,CompFile+'.VOC');
                    _MoveFile(CompFile+'.VOC',SGDir,ResourceDir);
               END;
               FindNext(DirInfo);
          END;
     END;
     ChDir(ShotgunDir);
     Dispose(CBuffer);
     Dispose(Buffer);
     Dispose(FNames);
     FWorkSg1.Done;
     FWorkSg2.Done;
     RestoreTheScreen;
END.
