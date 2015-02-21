{$I DEFINES.INC}
{$M 32000,0,512000}
PROGRAM GIPDecompiler;


USES Dos,ApMisc,Crt,FastW1,BsComp,BsVideo,Version,Shotgun,BsString,BsKeys,BsFile;


TYPE BigBuffer       = Array[1..8192] Of Byte;
TYPE SAVESCRNAScreen = Array[1..4000] Of Byte;
VAR  SAVESCRNScr     : SAVESCRNAScreen;
     FFile           : File;
     FFile2          : File;
     Buffer          : ^BigBuffer;
     GIPHeader       : _GIPHeader;
     GIPFileHeader   : _GIPFileHeader;
     ShotgunDir      : String[40];
     SOUNDDir        : String[40];
     ICONDir         : String[40];
     FONTDir         : String[40];
     JPEGDir         : String[40];
     WorkDir         : String[40];
     SavedX          : Word;
     SavedY          : Word;
     SavedAttr       : Byte;
     OutDir          : String;
     InFile          : String;
     Ext             : String[3];
     OutFile         : String;
     GetBytes        : Longint;


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


BEGIN
     ShotgunDir  := ParamStr(1);
     OutDir      := ParamStr(2);
     InFile      := ParamStr(3);
     IF ShotgunDir[LENGTH(ShotgunDir)]='\' THEN Delete(ShotgunDir,LENGTH(ShotgunDir),1);
     IF OutDir[LENGTH(OutDir)]='\' THEN Delete(OutDir,LENGTH(OutDir),1);
     IF ((ShotgunDir='') OR (OutDir='') OR NOT(_FileExists(InFile))) THEN
     BEGIN
          AppHeader('GIP Decompiler For Shotgun Professional');
          WRITELN('   Syntax:   UNPAKGIP.EXE <basedir> <langdir> <gipfile>');
          WRITELN('');
          WRITELN('   <basedir>   Main Shotgun or Gui directory. ie: C:\SHOTGUN');
          WRITELN('   <langdir>   Full path of destination SG file. ie: C:\SHOTGUN\ENGLISH\SG\');
          WRITELN('   <gipfile>   Full path/file name of GIP file. ie: C:\SHOTGUN\TEST.GIP');
          WRITELN('');
          HALT;
     END;

     SaveTheScreen;
     DrawWindow(15,10,65,14,'GIP Decompiler '+ShotgunVersion);
     InvertedBox(17,11,63,13);
     SOUNDDir    := ShotgunDir+'\SOUND\';
     FONTDir     := ShotgunDir+'\FONTS\';
     ICONDir     := ShotgunDir+'\ICONS\';
     JPEGDir     := ShotgunDir+'\IMAGES\';
     WorkDir     := ShotgunDir+'\!1\';
     _CreatePath(WorkDir);
     _CreatePath(OutDir);
     ChDir(ShotgunDir);
     New(Buffer);
     FastWrite('     Decompiling:                  ',12,25,31);
     FastWrite(_PadRight(_NoPath(InFile),12),12,44,27);
     ASSIGN(FFile,InFile);
     RESET(FFile,1);
     BLOCKREAD(FFile,GIPHeader,SizeOf(GIPHeader));
     REPEAT
           BLOCKREAD(FFile,GIPFileHeader,SizeOf(GIPFileHeader));
           GetBytes := GIPFileHeader.FileLength;
           ASSIGN(FFile2,WorkDir+'COMPRESS.TMP');
           REWRITE(FFile2,1);
           REPEAT
                 IF GetBytes>SizeOf(Buffer^) THEN
                 BEGIN
                      BLOCKREAD(FFile,Buffer^,SizeOf(Buffer^));
                      BLOCKWRITE(FFile2,Buffer^,SizeOf(Buffer^));
                      DEC(GetBytes,SizeOf(Buffer^));
                 END
                 ELSE
                 BEGIN
                      BLOCKREAD(FFile,Buffer^,GetBytes);
                      BLOCKWRITE(FFile2,Buffer^,GetBytes);
                      GetBytes := 0;
                 END;
           UNTIL (GetBytes=0);
           CLOSE(FFile2);
           OutFile := '';
           Ext     := _GetFileExtension(GIPFileHeader.FName);
                IF Ext='SG'  THEN OutFile := OutDir+'\'+GIPFileHeader.FName
           ELSE IF Ext='CC'  THEN OutFile := ICONDir+GIPFileHeader.FName
           ELSE IF Ext='ANI' THEN OutFile := ICONDir+GIPFileHeader.FName
           ELSE IF Ext='VOC' THEN OutFile := SOUNDDir+GIPFileHeader.FName
           ELSE IF Ext='IMG' THEN OutFile := JPEGDir+GIPFileHeader.FName
           ELSE IF Ext='FNT' THEN OutFile := FONTDir+GIPFileHeader.FName
           ELSE IF Ext='ICO' THEN OutFile := ICONDir+GIPFileHeader.FName
           ELSE IF Ext='MSE' THEN OutFile := ICONDir+GIPFileHeader.FName
           ELSE IF Ext='TXT' THEN OutFile := ShotgunDir+'\'+GIPFileHeader.FName;
           IF (OutFile<>'') THEN DecompressFile(WorkDir+'COMPRESS.TMP',OutFile);
           _EraseFile(WorkDir+'COMPRESS.TMP');
     UNTIL EOF(FFile);
     CLOSE(FFile);
     ChDir(ShotgunDir);
     Dec(WorkDir[0]);
     _NukeDir(WorkDir,False);
     Dispose(Buffer);
     RestoreTheScreen;
END.
