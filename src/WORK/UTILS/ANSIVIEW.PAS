{$I DEFINES.INC}
USES ApAnsi,Crt,Dos,BsVideo,Version,BsFile,BsKeys,BsString,FMode;

VAR  FileSpec : String;
     TFile    : Text;
     Temp     : String;
     DirInfo  : SearchRec;
     C        : Char;
     Buf      : Array[1..16384] Of Char;

BEGIN
     FileMode := SetFileMode;
     FileSpec := ParamStr(1);
     IF ((FileSpec='') OR (NOT(_FileExists(FileSpec)))) THEN
     BEGIN
          AppHeader('ANSIView - ANSI File Viewer For Gunshot Professional');
          WriteLn('No file spec specified.');
          Halt
     END;
     Window(1,1,80,24);
     _HideCursor;
     FindFirst(FileSpec,Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          ASSIGN(TFile,_GetFilePath(FileSpec)+DirInfo.Name);
          SetTextBuf(TFile,Buf);
          {$I-}RESET(TFile);{$I+}
          IF IOResult=0 THEN
          BEGIN
               TextBackground(0);
               TextColor(7);
               ClrScr;
               REPEAT
                     READLN(TFile,Temp);
                     IF EOF(TFile) THEN WriteStringAnsi(Temp)
                                   ELSE WriteStringAnsi(Temp+#$0D#$0A);
               UNTIL EOF(TFile);
               CLOSE(TFile);
               FastWrite(_PadRight(' '+_GetFilePath(FileSpec)+DirInfo.Name,80),25,1,31);
               REPEAT
               UNTIL KeyPressed;
               C := ReadKey;
                    IF C=#0 THEN C := ReadKey
               ELSE IF C=#27 THEN
               BEGIN
                    Window(1,1,80,25);
                    TextBackground(0);
                    TextColor(7);
                    ClrScr;
                    _ShowCursor;
                    Halt;
               END;
          END;
          FindNext(DirInfo);
     END;
     Window(1,1,80,25);
     TextBackground(0);
     TextColor(7);
     ClrScr;
     _ShowCursor;
END.
