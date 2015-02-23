{$I DEFINES.INC}
UNIT CBV;


INTERFACE


PROCEDURE CallBackVerifier;


IMPLEMENTATION


USES ApTimer,BsLog,Globals,Time,Screens,KeyInput,Crt,ErrorLog,
     UserFile,SaveScrn,Comm,BsMulti,ApPort,ApCom,AllGone,Yapp,
     Gfx,Gunshot;


PROCEDURE CallBackVerifier;
VAR  FCBVSetup     : File Of _CallBack_Record;
     CBVSetup      : _CallBack_Record;
     Translation   : _CallBack_Translation;
     FTranslation  : File Of _CallBack_Translation;
     long_distance : boolean;
     in_byte       : Char;
     attempts      : byte;
     c             : char;
     ccc           : char;
     success       : boolean;
     dial_number   : string;
     loop          : word;
     bad_pass      : byte;
     duplicate_num : boolean;
     CBV_temp      : string;
     Counter       : Word;
     GotSomething  : Boolean;
     CheckIt       : Boolean;
     GoodTime      : Boolean;
     DialTimer     : EventTimer;
     SavedPass     : String;
     Temp          : String;
LABEL                retry,Done,ScrewIt;
BEGIN
     bsWriteLog('Running call back verifier',True);
     IF UserRecord.Ver_User=1 THEN
     BEGIN
          DoErrorLog(8,'');
          Exit;
     END;
     IF ((CallerIdRecord.UseCID) AND (CallerIdRecord.CBVOverRide)) THEN
     BEGIN
          UserRecord.Data := CIDSemaphore.Number;
          UserRecord.bad_logon := 0;
          UpdateAccess(CBVSetup.VAccess);
          WriteUser;
          ASSIGN(FVerifier,DATA_Directory+'\VERIFY.DAT');
          {$I-}RESET(FVerifier);{$I+}
          IF IOResult<>0 THEN REWRITE(FVerifier);
          SEEK(FVerifier,FileSize(FVerifier));
          Verifier.Name   := UserRecord.Name;
          Verifier.Number := UserRecord.Data;
          WRITE(FVerifier,Verifier);
          CLOSE(FVerifier);
          bsWriteLog('CBV: User verified at '+UserRecord.Data,True);
          Exit;
     END;
     ASSIGN(FCBVSetup,DATA_Directory+'\CALLBACK.DAT');
     {$I-}RESET(FCBVSetup);{$I+}
     IF IOResult=0 THEN
     BEGIN
          READ(FCBVSetup,CBVSetup);
          CLOSE(FCBVSetup);
     END
     ELSE
     BEGIN
          DoErrorLog(9,'');
          Exit;
     END;
     {=====================================================================}
     { CHECK IF ITS A GOOD TIME TO BE CALLING OUT                          }
     {=====================================================================}
           GoodTime := False;
           IF (CBVSetup.CBVStart<CBVSetup.CBVEnd) THEN
           BEGIN
                IF ((Getting_Time>CBVSetup.CBVStart) AND
                   (Getting_Time<CBVSetup.CBVEnd))
                   THEN GoodTime := True;
           END
           ELSE IF (CBVSetup.CBVStart=CBVSetup.CBVEnd) THEN
           BEGIN
                GoodTime := True;
           END
           ELSE
           BEGIN
                IF ((Getting_Time>CBVSetup.CBVStart) OR
                   (Getting_Time<CBVSetup.CBVEnd))
                   THEN GoodTime := True;
           END;
     {=====================================================================}
     { NOT A GOOD TIME, TELL THE USER                                      }
     {=====================================================================}
           IF NOT(GoodTime) THEN
           BEGIN
                bsWriteLog('CBV: Outside call back verifier hours',True);
                DisplayGraphicFile('NOCBV',False,True,True);
                Get_Enter;
                Exit;
           END;
     {=====================================================================}
     { LET THE USER SELECT THE NUMBER TO CALL                              }
     {=====================================================================}
           DOOR_EXECUTED := True;
           attempts := 0;
           DisplayGraphicFile('CALLBACK',False,True,True);
           c := Get_Menu_Selection('12Q',chr(0));
           CASE C OF
           '1': dial_number := UserRecord.data;
           '2': dial_number := UserRecord.voice;
           'Q': Exit;
           END;
     {=====================================================================}
     { CHECK THE NUMBER AND SEE IF ITS LONG DISTANCE OR NOT. IF WE ARE     }
     { VERIFYING LONG DISTANCE NUMBERS, THEN DON'T WORRY ABOUT IT.         }
     {=====================================================================}
           long_distance := True;
           ASSIGN(FTranslation,DATA_Directory+'\TRANSLAT.DAT');
           {$I-}RESET(FTranslation);{$I+}
           IF IOResult=0 THEN
           BEGIN
                REPEAT
                      READ(FTranslation,Translation);
                      IF Translation.LookFor<>'' THEN
                      BEGIN
                           Counter := POS(Translation.LookFor,dial_number);
                           IF Counter<>0 THEN
                           BEGIN
                                long_distance := False;
                                Delete(dial_number,Counter,LENGTH(Translation.LookFor));
                                Insert(Translation.Replacement,dial_number,Counter);
                                GOTO Done;
                           END;
                      END;
                UNTIL EOF(FTranslation);
                CLOSE(FTranslation);
           END;
           bsWriteLog('CBV: Caller is in a long distance exchange',True);
           Done:
     {=====================================================================}
     { IF ITS LONG DISTANCE AND WE AREN PASSING THE CALLER, LETS DO IT     }
     {=====================================================================}
           IF ((CBVSetup.LDPass=1) AND (long_distance)) THEN
           BEGIN
                bsWriteLog('CBV: Long distance caller is passed through',True);
                UpdateAccess(CBVSetup.VAccess);
                WriteUser;
                Exit;
           END;
     {=====================================================================}
     { IF ITS LONG DISTANCE AND WE AREN'T DOING IT, TELL THE USER          }
     {=====================================================================}
           IF ((long_distance) AND (CBVSetup.VerifyLD=0)) THEN
           BEGIN
                bsWriteLog('CBV: Not verifying long distance caller',True);
                DisplayGraphicFile('NOLONGD',False,True,True);
                Get_Enter;
                Exit;
           END;
     {=====================================================================}
     { CHECK FOR DUPLICATES                                                }
     {=====================================================================}
           duplicate_num := false;
           ASSIGN(FVerifier,DATA_Directory+'\VERIFY.DAT');
           {$I-} RESET(FVerifier); {$I+}
           IF IOResult=0 THEN
           BEGIN
                REPEAT
                      READ(FVerifier,Verifier);
                      IF (Pos(dial_number,Verifier.Number)<>0) THEN duplicate_num := true;
                      IF (Pos(Verifier.Number,dial_number)<>0) THEN duplicate_num := true;
                UNTIL EOF(FVerifier);
                CLOSE(FVerifier);
           END
           ELSE
           BEGIN
                REWRITE(FVerifier);
                CLOSE(FVerifier);
           END;
     {=====================================================================}
     { IF ITS A DUPE, THEN TELL THE USER AND ABORT                         }
     {=====================================================================}
           IF duplicate_num THEN
           BEGIN
                bsWriteLog('CBV: User entered a duplicate phone number',True);
                DisplayGraphicFile('CBVDUPE',False,True,True);
                Get_Enter;
                EXIT;
           END;
     {=====================================================================}
     { SET UP THE SCREEN TO GET GOING                                      }
     {=====================================================================}
           System_Prompt('',62);
           Get_Enter;
           PutStringTimeout(BBSPort,#255#2#13,YappDelay);
           CBV_temp := 'Calling:  '+dial_number;
           bsWriteLog('CBV: Calling '+dial_number,True);
           Save_Screen2;
           TEXTBACKGROUND(1);
           TEXTCOLOR(9);
           GOTOXY(25,7);  WRITE('ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»');
           GOTOXY(25,8);  WRITE('º                             º');
           GOTOXY(25,9);  WRITE('ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº');
           GOTOXY(25,10); WRITE('º                             º');
           GOTOXY(25,11); WRITE('º                             º');
           GOTOXY(25,12); WRITE('º                             º');
           GOTOXY(25,13); WRITE('º                             º');
           GOTOXY(25,14); WRITE('º                             º');
           GOTOXY(25,15); WRITE('ºÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄº');
           GOTOXY(25,16); WRITE('º                             º');
           GOTOXY(25,17); WRITE('ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼');
           TEXTCOLOR(15);
           GOTOXY(32,8);  WRITE('CALL BACK VERIFIER');
           GOTOXY(28,16); WRITE(CBV_temp);
           WINDOW(27,10,54,14);
           TEXTBACKGROUND(1); TEXTCOLOR(11); CLRSCR;
     {=====================================================================}
     { HANGUP THE MODEM REALLY HARD                                        }
     {=====================================================================}
           WRITELN('Hanging up modem.');
           retry:
           Counter := 0;
           REPEAT
                 Hangup;
                 _Delay(500);
                 INC(Counter);
                 TimeSlice;
           UNTIL ((NOT(CheckDCD(BBSPort))) OR (Counter=30));
           IF Counter=30 THEN
           BEGIN
                DoErrorLog(10,'');
                Dispatcher(5);
           END;
     {=====================================================================}
     { INITIALIZE AND DIAL THE MODEM                                       }
     {=====================================================================}
           _Delay(2000);
           WRITELN('Initializing modem.');
           FlushInBuffer(BBSPort);
           SetDtr(BBSPort,True);
           _Delay(NodeInfo.CommandDelay);
           FOR Counter := 1 TO 3 DO
           BEGIN
                IF NodeInfo.InitString[Counter]<>'' THEN
                BEGIN
                     PutStringTimeout(BBSPort,NodeInfo.InitString[Counter]+#13,YappDelay);
                     _Delay(NodeInfo.CommandDelay);
                     FlushInBuffer(BBSPort);
                END;
           END;
           WRITELN('Dialing the modem.');
           PutStringTimeout(BBSPort,NodeInfo.Dial+dial_number+#13,YappDelay);
           _Delay(NodeInfo.CommandDelay);
           FlushInBuffer(BBSPort);
           INC(attempts);
     {=====================================================================}
     { WAIT FOR SOMETHING BACK FROM THE MODEM                              }
     {=====================================================================}
           CBV_temp := '';
           GotSomething := False;
           NewTimerSecs(DialTimer,60);
           REPEAT
                 CBV_temp := '';
                 IF CharReady(BBSPort) THEN
                 BEGIN
                      REPEAT
                            IF CharReady(BBSPort) THEN
                            BEGIN
                                 GetChar(BBSPort,in_byte);
                                 IF ((ORD(in_byte)>31) AND (ORD(in_byte)<91)) THEN CBV_temp := CBV_temp+in_byte;
                                 Delay(20);
                            END;
                      UNTIL ((in_byte=#13) OR (KeyPressed) OR NOT(CharReady(BBSPort)));
                      IF CBV_temp<>'' THEN WRITELN(CBV_temp);
                 END
                 ELSE TimeSlice;
                 {SYSOP ABORT}
                 IF KeyPressed THEN
                 BEGIN
                      bsWriteLog('CBV: Aborted by sysop',True);
                      DoErrorLog(11,'');
                      c := ReadKey;
                      IF ORD(c)=0 THEN c := Readkey;
                      GOTO ScrewIt;
                 END;
                 IF Pos('NO CARRIER',CBV_Temp)<>0 THEN
                 BEGIN
                      IF attempts<CBVSetup.CallRetries THEN GOTO retry
                                                       ELSE GOTO ScrewIt;
                 END;
                 IF Pos('CONNECT',CBV_Temp)<>0 THEN GotSomething := True;
                 IF Pos('CARRIER',CBV_Temp)<>0 THEN GotSomething := True;
                 IF TimerExpired(DialTimer) THEN
                 BEGIN
                      IF attempts<CBVSetup.CallRetries THEN GOTO retry
                                                       ELSE GOTO ScrewIt;
                 END;
           UNTIL GotSomething;
           _Delay(2000);
     {=====================================================================}
     { GOT A CONNECT                                                       }
     {=====================================================================}
           SetDTR(BBSPort,True);
           SetRTS(BBSPort,True);
           bsWriteLog('Attempting graphics session',True);
           FlushInBuffer(BBSPort);
           PutStringTimeout(BBSPort,#255#0#13,YappDelay);
           _DELAY(2000);
           temp := '';
           C    := #0;
           NewTimerSecs(DialTimer,30);
           REPEAT
                 IF CharReady(BBSPort) THEN
                 BEGIN
                      GetChar(BBSPort,c);
                      temp := temp+c;
                 END
                 ELSE TimeSlice;
           UNTIL ((Pos(#255#255,Temp)<>0) OR (TimerExpired(DialTimer)));
           IF Pos(#255#255,Temp)=0 THEN
           BEGIN
                HangUp;
                bsWriteLog('Graphics session lost on return',True);
                GOTO ScrewIt;
           END;
           bsWriteLog('CBV: Prompting user for password',True);
           Restore_Screen2;
           bad_pass := 0;
           success  := false;
           WINDOW(1,1,80,24);
           TEXTBACKGROUND(0);
           TEXTCOLOR(7);

           {SEND OUR INITIAL SYSTEM PACKS}
           SendSystemFile(LANG_Directory+'\COLOURS.VGA');
           SendSystemFile(Gunshot_Directory+'\ICONS\BPRESS.MSE');
           SendSystemFile(Gunshot_Directory+'\ICONS\BUSY.MSE');
           SendSystemFile(Gunshot_Directory+'\ICONS\DEFAULT.MSE');
           SendSystemFile(Gunshot_Directory+'\ICONS\INSERT.MSE');
           SendSystemFile(Gunshot_Directory+'\ICONS\MSGDRAG.MSE');
           SendSystemFile(Gunshot_Directory+'\ICONS\FILEDRAG.MSE');
           SendSystemFile(Gunshot_Directory+'\ICONS\WINMOVE.MSE');
           IF ((Colours.InternalImage>0) AND (Colours.InternalImage<6)) THEN
           BEGIN
                PutStringTimeout(BBSPort,#255#119+Chr(Colours.InternalImage)+#13,YappDelay);
                GetYAPPAck;
           END;
           DisplayGraphicFile('BACKGRND',False,True,True);

           SavedPass := UserRecord.Password;
           UserRecord.Password := '';
           REPEAT
                 System_Prompt('',63);
                 Get_Enter;
                 IF UserRecord.password=SavedPass THEN
                 BEGIN
                      bad_pass := 0;
                      success  := true;
                 END
                 ELSE
                 BEGIN
                      bsWriteLog('Guessing at password',True);
                      success := false;
                      INC(bad_pass);
                      UserRecord.Password := '';
                      System_Prompt('',64);
                      Get_Enter;
                 END;
           UNTIL ((success) OR (bad_pass=3));
           IF bad_pass=3 THEN
           BEGIN
                UserRecord.Password := SavedPass;
                UserRecord.bad_logon := 1;
                dispatcher(6);
           END;
           UserRecord.bad_logon := 0;
           UpdateAccess(CBVSetup.VAccess);
           WriteUser;
           ASSIGN(FVerifier,DATA_Directory+'\VERIFY.DAT');
           {$I-}RESET(FVerifier);{$I+}
           IF IOResult<>0 THEN REWRITE(FVerifier);
           SEEK(FVerifier,FileSize(FVerifier));
           Verifier.Name   := UserRecord.Name;
           Verifier.Number := dial_number;
           WRITE(FVerifier,Verifier);
           CLOSE(FVerifier);
           bsWriteLog('CBV: User verified at '+dial_number,True);

           IF CBVSetup.UserToLogBackIn=1 THEN
           BEGIN
                DisplayGraphicFile('CBV_BACK',False,True,True);
                _Delay(8000);
                dispatcher(5);
           END;

           Exit;
     {=====================================================================}
     { APPEARS THAT THE USER DOESN'T KNOW HOW TO TYPE ATA, SO ABORT        }
     {=====================================================================}
           ScrewIt:
           ASSIGN(FVerifier,DATA_Directory+'\VERIFY.DAT');
           {$I-}RESET(FVerifier);{$I+}
           IF IOResult<>0 THEN REWRITE(FVerifier);
           SEEK(FVerifier,FileSize(FVerifier));
           Verifier.Name   := UserRecord.Name;
           Verifier.Number := dial_number;
           WRITE(FVerifier,Verifier);
           CLOSE(FVerifier);
           bsWriteLog('CBV: Call back verification failed',True);
           bsWriteLog('CBV: Number is now undialable: '+dial_number,True);
           Restore_Screen2;
           WINDOW(1,1,80,24);
           TEXTBACKGROUND(0);
           TEXTCOLOR(7);
           dispatcher(2);
END;


END.
