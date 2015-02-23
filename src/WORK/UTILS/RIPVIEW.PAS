{$I DEFINES.INC}
USES RipLink,Crt,Dos,BsVideo,Version,BsFile,BsKeys,BsString,FMode,BsMulti;

VAR  FileSpec : String;
     TFile    : Text;
     Temp     : String;
     DirInfo  : SearchRec;
     C        : Char;
     Buf      : Array[1..16384] Of Char;
     RIP      : ^RIPobj;
     AllDone  : Boolean;

BEGIN
     FileMode := SetFileMode;
     FileSpec := ParamStr(1);
     IF ((FileSpec='') OR (NOT(_FileExists(FileSpec)))) THEN
     BEGIN
          AppHeader('RIPView - RIP File Viewer For Gunshot Professional');
          WriteLn('No file spec specified.');
          Halt
     END;
     New(RIP,Init(True,'\GUNSHOT\BIN\GFXPACK'));
     FindFirst(FileSpec,Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          RIP^.DoTextStr(#13#10);
          RIP^.RipResetWindows;
          ASSIGN(TFile,_GetFilePath(FileSpec)+DirInfo.Name);
          SetTextBuf(TFile,Buf);
          {$I-}RESET(TFile);{$I+}
          IF IOResult=0 THEN
          BEGIN
               RIP^.MouseOff;
               RIPMouseOverride := True;
               REPEAT
                     READLN(TFile,Temp);
                     IF Temp[Ord(Temp[0])]='\' THEN
                     BEGIN
                          DEC(Temp[0]);
                          RIP^.ParseRipStr(Temp,False);
                     END
                     ELSE RIP^.ParseRipStr(Temp+#13#10,False);
               UNTIL EOF(TFile);
               CLOSE(TFile);
               RIP^.DoTextStr(_GetFilePath(FileSpec)+DirInfo.Name);
               RIPMouseOverride := False;
               RIP^.MouseOn;
               AllDone := False;
               REPEAT
                     IF KeyPressed THEN
                     BEGIN
                          C := ReadKey;
                          CASE C OF
                          #0:  BEGIN
                                    C := ReadKey;
                                    C := #0;
                               END;
                          ELSE AllDone := True;
                          END;
                     END
                     ELSE
                     BEGIN
                          RIP^.CheckMouse;
                          IF RIP^.CharInBuffer THEN
                          BEGIN
                               C := RIP^.GetNextChar;
                               AllDone := True;
                          END
                          ELSE TimeSlice;
                     END;
               UNTIL AllDone;
               IF C=#27 THEN
               BEGIN
                    Dispose(RIP,Done);
                    TextBackground(0);
                    TextColor(7);
                    ClrScr;
                    Halt;
               END;
          END;
          FindNext(DirInfo);
     END;
     Dispose(RIP,Done);
     TextBackground(0);
     TextColor(7);
     ClrScr;
END.
