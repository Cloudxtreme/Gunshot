{$I DEFINES.INC}
UNIT ViewTFil;


INTERFACE


PROCEDURE view_text_file(work_file,title: string);


IMPLEMENTATION


USES Globals,KeyInput,Screens,SBuffer,ErrorLog,BsLog,BsString,
     Special,_Pick,_Mouse,Gr2_Bp,BsPrint,Download,BsFile;


PROCEDURE view_text_file(work_file,title: string);
VAR  ffile     : Text;
     outtahere : Boolean;
     temp      : String;
     work      : Word;
     c         : Char;
     TFile     : Text;
LABEL            OneMoreTime;
BEGIN
     IF _FileExists(work_file) THEN
     BEGIN
          OneMoreTime:
          ClearBuffer;
          AddToBuffer('@HEADER',title);
          IF DisplayGraphicFile('READFILE',True,True,True) THEN
          BEGIN
               ScreenNumber := 2;
               NewPickList(False);
               ChangeMouse(BusyMouse);
               ASSIGN(ffile,work_file);
               RESET(ffile);
               REPEAT
                     READLN(ffile,temp);
                     REPEAT
                           Work := Pos(#9,temp);
                           IF work<>0 THEN
                           BEGIN
                                Delete(temp,work,1);
                                Insert('        ',temp,work);
                           END;
                     UNTIL work=0;
                     REPEAT
                           Work := Pos(#12,temp);
                           IF work<>0 THEN Temp[Work] := #32;
                     UNTIL work=0;
                     AddToPickList(' '+temp,0,False);
               UNTIL EOF(ffile);
               CLOSE(ffile);
               ChangeMouse(DefaultMouse);
               HideTheMouse;
               BeginPickList;
               SetUpPickList;
               ShowTheMouse;
               OuttaHere := False;
               REPEAT
                     c := GetKeyPress;
                     CASE Ord(c) OF
                     13:  OuttaHere := True;
                     2:   BEGIN {PRINT MESSAGE}
                               bsWriteLog('Printing a file to the printer '+Title,False);
                               KillPickList;
                               ASSIGN(FFile,work_file);
                               ASSIGN(TFile,CD_Directory+'\PRNMSG.$$$');
                               RESET(FFile);
                               REWRITE(TFile);
                               WRITELN(TFile,'--------------------------------------------------------------------------');
                               WRITELN(TFile,Title);
                               WRITELN(TFile,'--------------------------------------------------------------------------');
                               REPEAT
                                     READLN(FFile,Temp);
                                     WRITELN(TFile,Remove_Special(Temp));
                               UNTIL EOF(FFile);
                               CLOSE(FFile);
                               CLOSE(TFile);
                               IF FixedLPT=0 THEN
                               BEGIN
                                    DisplayGraphicFile('PRNSEL',True,True,True);
                                    c := UpCase(Get_Menu_Selection('123Q'+#27,#27));
                                    CASE c OF
                                    '1': FixedLPT := 1;
                                    '2': FixedLPT := 2;
                                    '3': FixedLPT := 3;
                                    END;
                               END;
                               IF (FixedLPT<>0) THEN
                               BEGIN
                                    PrintStart(FixedLPT);
                                    ASSIGN(TFile,CD_Directory+'\PRNMSG.$$$');
                                    RESET(TFile);
                                    REPEAT
                                          READLN(TFile,Temp);
                                          PrintLine('  '+Temp);
                                    UNTIL EOF(TFile);
                                    CLOSE(TFile);
                                    PrintEnd;
                               END;
                               ERASE(TFile);
                               GOTO OneMoreTime;
                          END;
                     1:   BEGIN {DOWNLOAD TEXT FILE}
                               bsWriteLog('Downloading a text view '+Title,False);
                               KillPickList;
                               ASSIGN(FFile,work_file);
                               ASSIGN(TFile,CD_Directory+'\MSG'+_String(RunningMessageDL)+'.TXT');
                               RESET(FFile);
                               REWRITE(TFile);
                               WRITELN(TFile,'--------------------------------------------------------------------------');
                               WRITELN(TFile,Title);
                               WRITELN(TFile,'--------------------------------------------------------------------------');
                               REPEAT
                                     READLN(FFile,Temp);
                                     WRITELN(TFile,Remove_Special(Temp));
                               UNTIL EOF(FFile);
                               CLOSE(FFile);
                               CLOSE(TFile);
                               dl_file(CD_Directory+'\MSG'+_String(RunningMessageDL)+'.TXT');
                               ERASE(TFile);
                               INC(RunningMessageDL);
                               GOTO OneMoreTime;
                          END;
                     END;
               UNTIL OuttaHere;
               KillPickList;
          END;
     END
     ELSE DoErrorLog(34,work_file);
END;


END.
