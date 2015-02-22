{$I DEFINES.INC}
UNIT CBV;


INTERFACE


PROCEDURE CallBackVerifier;


IMPLEMENTATION


USES ApTimer,BsLog,Globals,Time,Screens,KeyInput,ANSIMisc,Crt,ErrorLog,
     UserFile,SaveScrn,Comm,BsMulti,ApPort,ApCom,AllGone,Shotgun,BsString;


PROCEDURE CallBackVerifier;
VAR  CBVSetup      : _CallBack_Record;
     FCBVSetup     : File Of _CallBack_Record;
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
     OldX,OldY     : Word;
     GoodTime      : Boolean;
     DialTimer     : EventTimer;
LABEL                retry,Done,ScrewIt;
BEGIN
     bsWriteLog('Running call back verifier',False);
     IF LocalLogon THEN
     BEGIN
          DoErrorLog(7,'');
          Exit;
     END;
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
          bsWriteLog('CBV: User verified at '+UserRecord.Data,False);
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
                bsWriteLog('CBV: Outside call back verifier hours',False);
                SendCrLf(1);
                DisplayGraphicsFile('NOCBV',true,true,True,True,False);
                Get_Enter;
                Exit;
           END;
     {=====================================================================}
     { LET THE USER SELECT THE NUMBER TO CALL                              }
     {=====================================================================}
           attempts := 0;
           DisplayGraphicsFile('CALLBACK',false,true,True,True,False);
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
           bsWriteLog('CBV: Caller is in a long distance exchange',False);
           Done:
     {=====================================================================}
     { IF ITS LONG DISTANCE AND WE AREN PASSING THE CALLER, LETS DO IT     }
     {=====================================================================}
           IF ((CBVSetup.LDPass=1) AND (long_distance)) THEN
           BEGIN
                bsWriteLog('CBV: Long distance caller is passed through',False);
                UpdateAccess(CBVSetup.VAccess);
                WriteUser;
                Exit;
           END;
     {=====================================================================}
     { IF ITS LONG DISTANCE AND WE AREN'T DOING IT, TELL THE USER          }
     {=====================================================================}
           IF ((long_distance) AND (CBVSetup.VerifyLD=0)) THEN
           BEGIN
                bsWriteLog('CBV: Not verifying long distance caller',False);
                SendCrLf(2);
                DisplayGraphicsFile('NOLONGD',true,false,True,True,False);
                SendCrLf(1);
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
                bsWriteLog('CBV: User entered a duplicate phone number',False);
                SendCrLf(2);
                DisplayGraphicsFile('CBVDUPE',true,false,True,True,False);
                SendCrLf(1);
                Get_Enter;
                EXIT;
           END;
     {=====================================================================}
     { SET UP THE SCREEN TO GET GOING                                      }
     {=====================================================================}
           SendCrLf(2);
           System_Prompt('',62,true,false);
           Get_Enter;
           CBV_temp := 'Calling:  '+dial_number;
           bsWriteLog('CBV: Calling '+dial_number,False);
           Save_Screen2;
           OldX := WhereX;
           OldY := WhereY;
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
                     PutStringTimeout(BBSPort,NodeInfo.InitString[Counter]+#13,182);
                     _Delay(NodeInfo.CommandDelay);
                     FlushInBuffer(BBSPort);
                END;
           END;
           WRITELN('Dialing the modem.');
           PutStringTimeout(BBSPort,NodeInfo.Dial+dial_number+#13,182);
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
                                 _Delay(20);
                            END;
                      UNTIL ((in_byte=#13) OR (KeyPressed) OR NOT(CharReady(BBSPort)));
                      IF CBV_temp<>'' THEN WRITELN(CBV_temp);
                 END;
                 {SYSOP ABORT}
                 IF KeyPressed THEN
                 BEGIN
                      bsWriteLog('CBV: Aborted by sysop',False);
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
           _Delay(1000);
     {=====================================================================}
     { GOT A CONNECT                                                       }
     {=====================================================================}
           SetDTR(BBSPort,True);
           SetRTS(BBSPort,True);
           bsWriteLog('CBV: Prompting user for password',False);
           Restore_Screen2;
           bad_pass := 0;
           success  := false;
           WINDOW(1,1,80,24);
           TEXTBACKGROUND(0);
           TEXTCOLOR(8);
           GotoXY(OldX,OldY);
           REPEAT
                 Fore(10);
                 SendCrLf(2);
                 System_Prompt('',63,false,true);
                 Get_Password(20,'',true,true);
                 input_string := _UpperCase(input_string);
                 IF input_string=UserRecord.password THEN
                 BEGIN
                      bad_pass := 0;
                      success  := true;
                      SendCrLf(1);
                 END
                 ELSE
                 BEGIN
                      success := false;
                      INC(bad_pass);
                      SendCrLf(1);
                      System_Prompt('',64,true,false);
                 END;
           UNTIL ((success) OR (bad_pass=3));
           IF bad_pass=3 THEN
           BEGIN
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
           bsWriteLog('CBV: User verified at '+dial_number,False);

           IF CBVSetup.UserToLogBackIn=1 THEN
           BEGIN
                DisplayGraphicsFile('CBV_BACK',False,False,False,True,False);
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
           bsWriteLog('CBV: Call back verification failed',False);
           bsWriteLog('CBV: Number is now undialable: '+dial_number,False);
           Restore_Screen2;
           WINDOW(1,1,80,24);
           TEXTBACKGROUND(0);
           TEXTCOLOR(8);
           GotoXY(OldX,OldY);
           dispatcher(2);
END;


END.
