{$I DEFINES.INC}
UNIT Faxes;


INTERFACE


PROCEDURE GoGetTheFax;
FUNCTION  RunExternalFax: Boolean;


IMPLEMENTATION


USES Crt,Globals,ApPort,ApCom,BsLog,ApAbsFax,ApFax12,ApFaxCvt,ApTimer,
     ApMisc,FastW1,SaveScrn,DrawScrn,BsMulti,Comm,Dos,Shotgun,
     BsFile,BsString,BsKeys,BsCom,BsExec,Scan,Sema,BsVideo,Misc;


{$F+}
FUNCTION MyFaxAbort : Boolean;
VAR  C : Char;
BEGIN
     MyFaxAbort := False;
     IF KeyPressed THEN
     BEGIN
          C := ReadKey;
          CASE Ord(c) OF
          27:  MyFaxAbort := True;
          0:   C := ReadKey;
          END;
     END
     ELSE TimeSlice;
END;
{$F-}

{$F+}
FUNCTION MyAcceptFax(FP: FaxRecPtr; RemoteName: Str20): Boolean;
BEGIN
     MyAcceptFax := True;
END;
{$F-}

{$F+}
PROCEDURE MyFaxLog(FP: FaxRecPtr; Number: String; FName: PathStr; Log: TLogFaxCode);
VAR  FFaxBase      : File Of _FaxBaseHeader_Record;
     FaxBase       : _FaxBaseHeader_Record;
BEGIN
     CASE Log OF
     lfaxReceiveOk   : BEGIN
                            UpdateFAX;
                            UpdateHistory;
                            bsWriteLog('Fax received successfully:',False);
                            bsWriteLog('ÃÄ Fax File: '+FName,False);
                            bsWriteLog('ÀÄ Fax From: '+StationID,False);
                            FaxBase.FaxFile   := _NoPath(FName);
                            FaxBase.Received  := False;
                            FaxBase.StationID := StationID;
                            GetDate(FaxBase.Year,FaxBase.Month,FaxBase.Day,FaxBase.DayOfWeek);
                            GetTime(FaxBase.Hour,FaxBase.Minute,FaxBase.Second,FaxBase.Sec100);
                            ASSIGN(FFaxBase,_NoExtension(FName)+'.FAX');
                            REWRITE(FFaxBase);
                            WRITE(FFaxBase,FaxBase);
                            CLOSE(FFaxBase);
                            IF FaxCodes.PrintFaxes THEN
                            BEGIN
                              {FUCK}
                            END;
                       END;
     lfaxReceiveSkip,
     lfaxReceiveFail : _EraseFile(FName);
     END;
END;
{$F-}

{$F+}
PROCEDURE MyFaxStatus(FP: FaxRecPtr; Starting,Ending: Boolean);
VAR  L            : LongInt;
     Pages        : Word;
     Page         : Word;
     Bytes        : LongInt;
     Total        : LongInt;
     BPS          : LongInt;
     Res          : Boolean;
     ECM          : Boolean;
     FaxProgress  : Word;
     Temp         : String;

     PROCEDURE draw_status(InString: String; Level: Word);
     BEGIN
          CASE Level OF
          0:   FastWrite(_PadRight(InString,35),10,33,ShotgunColours.GSMailWindowHighlight);
          1:   FastWrite(_PadRight(InString,35),11,33,ShotgunColours.GSMailWindowHighlight);
          2:   FastWrite(_PadRight(InString,35),12,33,ShotgunColours.GSMailWindowHighlight);
          3:   FastWrite(_PadRight(InString,35),13,33,ShotgunColours.GSMailWindowHighlight);
          END;
     END;

BEGIN
     IF (NOT(Starting) AND NOT(Ending)) THEN
     BEGIN
       FaxProgress := GetFaxProgress(FP);
       CASE FaxProgress OF
       fpAnswer         : Draw_Status('Answering incoming call',2);
       fpWaiting        : Draw_Status('Waiting for next call',2);
       fpIncoming       : Draw_Status('Incoming FAX call',2);
       fpInitModem      : Draw_Status('Initializing fax modem',2);
       fpDialing        : Draw_Status('Dialing/waiting for connection',2);
       fpSendPage       : BEGIN
                            GetPageInfoC12(FP,Pages,Page,Bytes,Total);
                            IF Page = 0 THEN
                            BEGIN
                              Draw_Status('Sending cover: '+_String(Bytes),2)
                            END
                            ELSE
                            BEGIN
                              IF Total<>0 THEN L := Trunc(((Bytes*1.0)/Total)*100.0)
                                          ELSE L := 0;
                              Draw_Status('Sending page: '+_String(Page)+'  '+_String(Bytes)+' ('+_String(L)+'%)',2);
                            END;
                          END;
       fpGetPage        : BEGIN
                            GetPageInfoC12(FP,Pages,Page,Bytes,Total);
                            Draw_Status('FAX: '+_NoPath(GetFaxName(FP))+'  Page: '+_String(Page)+'  '+_String(Bytes),2);
                          END;
       fpGotHangup      : Draw_Status('Waiting for next call',2);
       END;
       IF (LastFaxStatus<>FaxProgress) THEN
       BEGIN
         LastFaxStatus := FaxProgress;
         CASE FaxProgress OF
         fpGotRemoteID    : BEGIN
                              StationID := GetRemoteID(FP);
                              Draw_Status(StationID,0);
                              bsWriteLog('Station ID: '+StationID,False);
                            END;
         fpSessionParams  : BEGIN
                              GetSessionParams(FP,BPS,Res,ECM);
                              Temp := _String(BPS)+' bps / ';
                              IF ECM THEN Temp := Temp+'ECM / '
                                     ELSE Temp := Temp+'NoECM / ';
                              IF Res THEN Temp := Temp+'High Res'
                                     ELSE Temp := Temp+'Standard Res';
                              Draw_Status(Temp,1);
                              bsWriteLog('Connection: '+Temp,False);
                            END;
         fpPageOK         : BEGIN
                              Draw_Status('Page accepted',2);
                              bsWriteLog('Page accepted',False);
                            END;
         fpGetPageResult  : BEGIN
                              IF GetLastPageStatus(FP) THEN
                              BEGIN
                                Draw_Status('Page accepted',2);
                                bsWriteLog('Page accepted',False);
                              END
                              ELSE
                              BEGIN
                                Draw_Status('Page rejected',2);
                                bsWriteLog('Page rejected',False);
                              END;
                            END;
         fpCheckMorePages : BEGIN
                              Draw_Status('Checking for more pages',2);
                              bsWriteLog('Checking for more pages',False);
                            END;
         END;
       END;
     END;
END;
{$F-}

PROCEDURE DrawTheFaxWindow;
BEGIN
     WhereXYAbs(KeepXY);
     SaveScreen(3);
     FastWrite(' Press Esc to abort the session                                         INBOUND ',
               Window2+7,1,ShotgunColours.GSMailStatusHighlight);
     DrawWindow(15,7,70,15,'',True);
     FastWrite(_PadBoth('INCOMING FAX CALL',53),8,16,ShotgunColours.GSMailWindowHighlight);
     InvertedBox(17,9,68,14);
     FastWrite(' Call From: ',10,20,ShotgunColours.GSMailWindowText);
     FastWrite(' Fax Speed: ',11,20,ShotgunColours.GSMailWindowText);
     FastWrite('    Status: ',12,20,ShotgunColours.GSMailWindowText);
     FastWrite('Last Error: ',13,20,ShotgunColours.GSMailWindowText);
END;


FUNCTION RunExternalFax: Boolean;
VAR  Temp    : String[80];
     Work    : Word;
     FaxComm : String;
     FaxFile : String[80];
     FName   : String[80];
     FPath   : String[80];
BEGIN
     Temp := ExternalApps.FaxReceiver;
     Work := Pos(' ',Temp);
     FaxComm := '';
     IF (Work<>0) THEN
     BEGIN
          FaxFile := _Mid(Temp,1,Work-1);
          Delete(Temp,1,Work);
          FaxComm := _RemoveLeftSpaces(Temp);
     END
     ELSE FaxFile := Temp;
     FName := _NoPath(FaxFile);
     FPath := _GetFilePath(FaxFile);
     IF FPath='' THEN FPath := Shotgun_Directory+'\';
     Dec(FPath[0]);
     {%1 Com Port}
     Work := Pos('%1',FaxComm);
     IF (Work<>0) THEN
     BEGIN
          Delete(FaxComm,Work,2);
          Insert(_String(NodeInfo.ComPort),FaxComm,Work);
     END;
     {%2 Baud Rate}
     Work := Pos('%2',FaxComm);
     IF (Work<>0) THEN
     BEGIN
          Delete(FaxComm,Work,2);
          Insert(_String(NodeInfo.BaudRate),FaxComm,Work);
     END;
     {%3 Node Number}
     Work := Pos('%3',FaxComm);
     IF (Work<>0) THEN
     BEGIN
          Delete(FaxComm,Work,2);
          Insert(_String(SimNode),FaxComm,Work);
     END;
     IF _FileExists(FaxFile) THEN
     BEGIN
          IF (Pos('BGFAX',_UpperCase(FaxFile))<>0) THEN
          BEGIN
               StatusWindow('Starting BGFax to handle call');
               bsWriteLog('Starting BGFax to handle call',False);
          END
          ELSE
          BEGIN
               StatusWindow('Starting external fax to handle call');
               bsWriteLog('Starting external fax to handle call',False);
          END;
          WhereXYAbs(BGFaxXY);
          SaveScreen(1);
          SetOrigVideoMode;
          bsClosePort(True);
          ChDir(FPath);
          DoExec(FName,FaxComm,SwapMethod,Shotgun_Directory+'\NODE'+_String(SimNode));
          ChDir(Shotgun_Directory);
          bsOpenPort(NodeInfo.ComPort,NodeInfo.ComDevice,NodeInfo.BaudRate,
                     16384,False,NodeInfo.PortAddr,NodeInfo.IRQ,NodeInfo.Fifos,
                     NodeInfo.FlowControl,NodeInfo.ptBufferGetChar,
                     NodeInfo.ptHandleFossilBug,NodeInfo.ptTrueOutBuffFree,
                     NodeInfo.ptPutCharWait,NodeInfo.ptReadWriteWait,
                     NodeInfo.ptClearFlow);
          SetOurVideoMode;
          RestoreScreen(1);
          GotoXYAbs(BGFaxXY);
          ScanNewMail;
          ScanNewFaxes;
          StatusWindow('Initializing Modem');
          InitializeModem;
          StatusWindow('Waiting for a call or event');
          WriteNodeFile('GSMail','Waiting For A Caller','');
          TimerWait := 20;
          NewTimerSecs(InitTimer,TimerWait);
          ResetDialTimer;
          RunExternalFax := True;
     END
     ELSE RunExternalFax := False;
END;


PROCEDURE GoGetTheFax;
VAR  TheFaxClass : String[20];
     FaxBPS      : Longint;
     FaxEC       : Char;
BEGIN
     LastFaxStatus := 0;
     _HideCursor;
     DrawTheFaxWindow;
     CASE FaxCodes.FaxRecvClass OF
     1:   TheFaxClass := 'Class 1';
     2:   TheFaxClass := 'Class 2';
     3:   TheFaxClass := 'Class 2.0';
     END;
     CASE FaxCodes.FaxRecvBPS OF
     1:   FaxBPS := 2400;
     2:   FaxBPS := 4800;
     3:   FaxBPS := 7200;
     4:   FaxBPS := 9600;
     5:   FaxBPS := 12000;
     6:   FaxBPS := 14400;
     END;
     IF FaxCodes.FaxErrorCorrection THEN FaxEC := '1'
                                    ELSE FaxEC := '0';
     bsStartFax(FaxCodes.FaxID,MailerInfo.Netmail,TheFaxClass);
     SetModemFeatures(bsBBSFax,FaxBPS,FaxEC);
     SetFaxStatusProc(bsBBSFax,MyFaxStatus);
     SetFaxLogProc(bsBBSFax,MyFaxLog);
     SetAcceptFaxFunc(bsBBSFax,MyAcceptFax);
     SetConnectState(bsBBSFax);
     SetAbortFunc(bsBBSPort,MyFaxAbort);
     FaxReceiveC12(bsBBSFax);
     SetAbortFunc(bsBBSPort,NoAbortFunc);
     bsStopFax;
     bsOnHook(NodeInfo.OnHook);
     RestoreScreen(3);
     TextColor(7);
     TextBackGround(0);
     GotoXYAbs(KeepXY);
     _ShowCursor;
END;


END.
