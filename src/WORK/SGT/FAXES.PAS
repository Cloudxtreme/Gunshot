{$I DEFINES.INC}
UNIT Faxes;


INTERFACE


PROCEDURE DoFaxes;


IMPLEMENTATION


USES Dos,Crt,ApAbsFax,ApFax12,BsMulti,__Gfx,ApFaxCvt,Globals,
     ApPort,ApCom,ApMisc,Comm,BsGraph,Config,BsString,BsFile,
     {$IFDEF DPMI}
     Gr2_Bp;
     {$ELSE}
     Gr_Tp;
     {$ENDIF}


{$F+}
FUNCTION MyFaxAbort : Boolean;
VAR  C : Char;
BEGIN
     MyFaxAbort := False;
     IF KeyPressed THEN
     BEGIN
          C := ReadKey;
          IF C=#27 THEN MyFaxAbort := True
          ELSE
          BEGIN
               IF C=#0 THEN C := ReadKey;
          END;
     END;
END;
{$F-}

{$F+}
PROCEDURE MyFaxStatus(FP: FaxRecPtr; Starting,Ending: Boolean);
VAR   L            : LongInt;
      Pages        : Word;
      Page         : Word;
      Bytes        : LongInt;
      Total        : LongInt;
      BPS          : LongInt;
      Res          : Boolean;
      ECM          : Boolean;
      Progress     : Word;

     PROCEDURE draw_status(InString: String; Level: Word);
     BEGIN
          CASE Level OF
          0:   OutTextXY(210,160,9,7,1,_PadRight(InString,38));
          1:   OutTextXY(210,180,9,7,1,_PadRight(InString,38));
          2:   OutTextXY(210,200,9,7,2,_PadRight(InString,38));
          3:   OutTextXY(210,220,4,7,2,_PadRight(InString,38));
          END;
     END;

BEGIN
     IF Ending THEN
     BEGIN
          GrSetFillStyle(GrFSolid,7,GrOpaque);
          GrDrawRect(210,155,520,245,GrFill);
          Draw_Status('Waiting for next call',2);
     END
     ELSE IF NOT(Starting) THEN
     BEGIN
          Progress := GetFaxProgress(FP);
          CASE Progress OF
          fpAnswer         : Draw_Status('Answering incoming call',2);
          fpWaiting        : Draw_Status('Waiting for next call',2);
          fpIncoming       : Draw_Status('Incoming FAX call',2);
          fpInitModem      : Draw_Status('Initializing fax modem',2);
          fpDialing        : Draw_Status('Dialing/waiting for connection',2);
          fpGotRemoteID    : Draw_Status(GetRemoteID(FP),0);
          fpSessionParams  : BEGIN
                                  GetSessionParams(FP,BPS,Res,ECM);
                                  Draw_Status(_String(BPS)+' bps',1);
                             END;
          fpSendPage :       BEGIN
                                  GetPageInfoC12(FP,Pages,Page,Bytes,Total);
                                  IF Page = 0 THEN Draw_Status('Sending cover: '+_String(Bytes),2)
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
          fpSendPageStatus : Draw_Status('Sending end-of-page',2);
          fpPageOK         : Draw_Status('Page accepted',2);
          fpGetPageResult  : BEGIN
                                  IF GetLastPageStatus(FP)
                                     THEN Draw_Status('Page accepted',2)
                                     ELSE Draw_Status('Page rejected',2);
                             END;
          fpCheckMorePages : Draw_Status('Checking for more pages',2);
          fpGetHangup      : Draw_Status('Disconnecting',2);
          fpGotHangup      : Draw_Status('Waiting for next call',2);
          END;
     END;
END;
{$F-}

{$F+}
PROCEDURE MyFaxLog(FP: FaxRecPtr; Number: String; FName: PathStr; Log: TLogFaxCode);
VAR  UFP : UnpackToPcxPtr;
BEGIN
     CASE Log OF
     lfaxReceiveOk   : BEGIN
                            _EraseFile(_NoExtension(FName)+'.DCX');
                            InitUnpackToDcx(UFP);
                            UnpackFileToDcx(UFP,FName,_NoExtension(FName)+'.DCX');
                            DoneUnpackToDcx(UFP);
                            _EraseFile(FName);
                       END;
     lfaxReceiveSkip,
     lfaxReceiveFail : _EraseFile(FName);
     END;
END;
{$F-}

PROCEDURE SendTHEFAX;
CONST FaxClass  : ClassType = ctClass2;
VAR  THEFAX     : FaxRecPtr;
     FCP        : FaxConverterPtr;
     Ext        : String;
     TheFaxFile : String;
     c          : Char;
     Class      : Char;
     Model      : String;
     Chip       : String;
     Rev        : String;
     BitRate    : LongInt;
     Check      : Char;
     TheInit    : String;

     PROCEDURE draw_status(InString: String; Level: Word);
     BEGIN
          CASE Level OF
          2:   OutTextXY(210,200,9,7,2,_PadRight(InString,39));
          3:   OutTextXY(210,220,4,7,2,_PadRight(InString,39));
          END;
     END;

BEGIN
     Ext := _UpperCase(_GetFileExtension(FaxDir.SendFile));
     IF Ext<>'APF' THEN
     BEGIN
          _EraseFile(_NoExtension(FaxDir.SendFile)+'.APF');
          IF IOResult=0 THEN;
     END;
     IF Ext='PCX' THEN
     BEGIN
          InitPcxConverter(FCP);
          ConvertFaxPcx(FCP,FaxDir.SendFile);
          DonePcxConverter(FCP);
     END
     ELSE IF Ext='DCX' THEN
     BEGIN
          InitDcxConverter(FCP);
          ConvertFaxDcx(FCP,FaxDir.SendFile);
          DoneDcxConverter(FCP);
     END
     ELSE IF Ext='TIF' THEN
     BEGIN
          InitTiffConverter(FCP);
          ConvertFaxTiff(FCP,FaxDir.SendFile);
          DoneTiffConverter(FCP);
     END
     ELSE
     BEGIN
          InitTextConverter(FCP);
          ConvertFaxText(FCP,FaxDir.SendFile);
          DoneTextConverter(FCP);
     END;
     TheFaxFile := _NoExtension(FaxDir.SendFile)+'.APF';
     TheInit    := _UpperCase(CommDef.FaxInit);
     IF _Mid(TheInit,1,2)='AT' THEN Delete(TheInit,1,2);
     InitC12SendFax(THEFAX,FaxDir.StationID,BBSPort);
     SetModemInit(THEFAX,TheInit);
     _Delay(1000);
     FlushInBuffer(BBSPort);
     IF GetModemInfo(THEFAX,Class,Model,Chip,Rev,True) THEN
     BEGIN
          IF Class='1' THEN FaxClass := ctClass1;
          IF Class='B' THEN FaxClass := ctClass1;
          IF Class='2' THEN FaxClass := ctClass2;
     END;
     IF Model='' THEN Model := 'Unknown';
     IF Chip=''  THEN Chip  := 'Unknown';
     IF Rev=''   THEN Rev   := 'Unknown';
     OutTextXYFR(220,85,0,7,5,'Fax Class:');
     CASE Class OF
     '1': OutTextXY(235,85,0,7,5,'Class 1');
     '2': OutTextXY(235,85,0,7,5,'Class 2');
     'B': OutTextXY(235,85,0,7,5,'Class 1');
     END;
     OutTextXYFR(220,100,0,7,5,'Model:');    OutTextXY(235,100,0,7,5,Model);
     OutTextXYFR(220,115,0,7,5,'Chipset:');  OutTextXY(235,115,0,7,5,Chip);
     OutTextXYFR(220,130,0,7,5,'Revision:'); OutTextXY(235,130,0,7,5,Rev);
     SetClassType(THEFAX,FaxClass);
     SetMaxRetries(THEFAX,30);
     SetSenderName(THEFAX,FaxDir.YourName);
     SetRecipientName(THEFAX,FaxDir.Recipient);
     SetStationID(THEFAX,FaxDir.StationId);
     SetTitle(THEFAX,FaxDir.Title);
     SetFaxStatusProc(THEFAX,MyFaxStatus);
     SetAbortFunc(BBSPort,MyFaxAbort);
     SetFaxLogProc(THEFAX,MyFaxLog);
     AddFaxEntry(THEFAX,FaxDir.DialPhone,TheFaxFile,FaxDir.CoverPage);
     FaxDialString := CommDef.DPrefix;
     FaxTransmitC12(THEFAX);
     CASE GetAsyncStatus OF
     ecOk               : Draw_Status('Fax transmit session complete',2);
     ecTimeout          : Draw_Status('Timeout waiting for data',3);
     ecUserAbort        : Draw_Status('Fax aborted by user',3);
     ecFaxVoiceCall     : Draw_Status('Voice answered phone',3);
     ecFaxDataCall      : Draw_Status('Data modem answered phone',3);
     ecFaxBusy          : Draw_Status('Line was busy',3);
     ecFaxNoFontFile    : Draw_Status('Font file not found',3);
     ecFaxInitError     : Draw_Status('Error initializing modem',3);
     ecFaxTrainError    : Draw_Status('Error during modem training',3);
     ecFaxSessionError  : Draw_Status('Error during session: '+_String(GetHangupResult(THEFAX)),3);
     ELSE                 Draw_Status('Unknown error: '+_String(GetAsyncStatus),3);
     END;
     DoneC12SendFax(THEFAX);
     Hangup;
     SendCommandString(CommDef.Hangup,True,True);
     _Delay(500);
     FlushInBuffer(BBSPort);
     SetAbortFunc(BBSPort,NoAbortFunc);
END;


PROCEDURE ReceiveTHEFAX;
CONST FaxClass  : ClassType = ctClass2;
VAR  THEFAX     : FaxRecPtr;
     FCP        : FaxConverterPtr;
     c          : Char;
     Class      : Char;
     Model      : String;
     Chip       : String;
     Rev        : String;
     BitRate    : LongInt;
     Check      : Char;
     TheInit    : String;

     PROCEDURE draw_status(InString: String; Level: Word);
     BEGIN
          CASE Level OF
          2:   OutTextXY(210,200,9,7,2,_PadRight(InString,39));
          3:   OutTextXY(210,220,4,7,2,_PadRight(InString,39));
          END;
     END;

BEGIN
     TheInit := _UpperCase(CommDef.FaxInit);
     IF _Mid(TheInit,1,2)='AT' THEN Delete(TheInit,1,2);
     InitC12ReceiveFax(THEFAX,FaxDir.StationID,BBSPort);
     SetModemInit(THEFAX,TheInit);
     _Delay(1000);
     FlushInBuffer(BBSPort);
     IF GetModemInfo(THEFAX,Class,Model,Chip,Rev,True) THEN
     BEGIN
          IF Class='1' THEN FaxClass := ctClass1;
          IF Class='B' THEN FaxClass := ctClass1;
          IF Class='2' THEN FaxClass := ctClass2;
     END;
     IF Model='' THEN Model := 'Unknown';
     IF Chip=''  THEN Chip  := 'Unknown';
     IF Rev=''   THEN Rev   := 'Unknown';
     OutTextXYFR(220,85,0,7,5,'Fax Class:');
     CASE Class OF
     '1': OutTextXY(235,85,0,7,5,'Class 1');
     '2': OutTextXY(235,85,0,7,5,'Class 2');
     'B': OutTextXY(235,85,0,7,5,'Class 1');
     END;
     OutTextXYFR(220,100,0,7,5,'Model:');    OutTextXY(235,100,0,7,5,Model);
     OutTextXYFR(220,115,0,7,5,'Chipset:');  OutTextXY(235,115,0,7,5,Chip);
     OutTextXYFR(220,130,0,7,5,'Revision:'); OutTextXY(235,130,0,7,5,Rev);
     SetClassType(THEFAX,FaxClass);
     SetStationID(THEFAX,FaxDir.StationId);
     SetFaxStatusProc(THEFAX,MyFaxStatus);
     SetAbortFunc(BBSPort,MyFaxAbort);
     SetFaxNameFunc(THEFAX,FaxNameCount);
     SetAnswerOnRing(THEFAX,1);
     SetFaxLogProc(THEFAX,MyFaxLog);
     SetDestinationDir(THEFAX,_Mid(FaxDir.InPath,1,LENGTH(FaxDir.InPath)-1));
     Draw_Status('Waiting for next call',2);
     InitModemForFaxReceive(THEFAX);
     FaxReceiveC12(THEFAX);
     CASE GetAsyncStatus OF
     ecOk               : Draw_Status('Fax transmit session complete',2);
     ecTimeout          : Draw_Status('Timeout waiting for data',3);
     ecUserAbort        : Draw_Status('Fax aborted by user',3);
     ecFaxVoiceCall     : Draw_Status('Voice answered phone',3);
     ecFaxDataCall      : Draw_Status('Data modem answered phone',3);
     ecFaxBusy          : Draw_Status('Line was busy',3);
     ecFaxNoFontFile    : Draw_Status('Font file not found',3);
     ecFaxInitError     : Draw_Status('Error initializing modem',3);
     ecFaxTrainError    : Draw_Status('Error during modem training',3);
     ecFaxSessionError  : Draw_Status('Error during session: '+_String(GetHangupResult(THEFAX)),3);
     ELSE                 Draw_Status('Unknown error: '+_String(GetAsyncStatus),3);
     END;
     DoneC12ReceiveFax(THEFAX);
     Hangup;
     SendCommandString(CommDef.Hangup,True,True);
     _Delay(500);
     FlushInBuffer(BBSPort);
     SetAbortFunc(BBSPort,NoAbortFunc);
END;


PROCEDURE CreateFaxSetup;
BEGIN
     ASSIGN(FFaxDir,'SGT.FAX');
     {$I-}
     RESET(FFaxDir);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          READ(FFaxDir,FaxDir);
     END
     ELSE
     BEGIN
          FaxDir.SendFile  := 'Full path & filename of text file!';
          FaxDir.InPath    := 'INFAX\';
          FaxDir.CoverPage := 'COVER.TXT';
          FaxDir.Title     := '-Untitled-';
          FaxDir.YourName  := 'Your name goes here';
          FaxDir.Recipient := 'Recipient''s name goes here';
          FaxDir.StationID := '0-000-000-0000';
          FaxDir.DialPhone := '0-000-000-0000';
          REWRITE(FFaxDir);
          WRITE(FFaxDir,FaxDir);
     END;
     CLOSE(FFaxDir);
     _CreatePath(FaxDir.InPath);
     _CreatePath('OUTFAX');
END;


PROCEDURE DoFaxes;
VAR  GetMouse    : Word;
     GaveUp      : Boolean;
     yy          : Word;
     OldBaud     : Word;
     OldCom      : Word;
     TheFileName : String[80];
     FFile       : File;
     BRead       : Word;

     PROCEDURE LoadUpVars;
     BEGIN
          FaxDir.InPath    := _Path(Fields[1].Text);
          FaxDir.CoverPage := Fields[2].Text;
          FaxDir.StationID := Fields[3].Text;
          FaxDir.SendFile  := Fields[4].Text;
          FaxDir.Title     := Fields[5].Text;
          FaxDir.YourName  := Fields[6].Text;
          FaxDir.Recipient := Fields[7].Text;
          FaxDir.DialPhone := Fields[8].Text;
          _CreatePath(FaxDir.InPath);
          _CreatePath('OUTFAX');
          ASSIGN(FFaxDir,'SGT.FAX');
          REWRITE(FFaxDir);
          WRITE(FFaxDir,FaxDir);
          CLOSE(FFaxDir);
     END;

BEGIN
     TheFileName := '';
     LoadConfiguration;
     IF NOT(Comm_init) THEN
     BEGIN
          grDisplayMouse(GrHide);
          WindowHeaderC := 4;
          WindowHighC   := 12;
          WindowLowC    := 0;
          DrawWindow(200,150,440,290,'MODEM SETUP ERROR!',0);
          OutTextXY(215,180,0,255,1,'Could not open the com port! Please');
          OutTextXY(215,195,0,255,1,'review your settings in the setup &');
          OutTextXY(215,210,0,255,1,'configuration on the main menu.');
          DoOkButton(350,240);
          grDisplayMouse(GrShow);
          REPEAT
                GetMouse := MouseHandler(False);
                IF GetMouse=0 THEN TimeSlice;
          UNTIL GetMouse=NButtons;
          WindowHeaderC := 57;
          WindowHighC   := 60;
          WindowLowC    := 54;
          KillWindow;
          Exit;
     END;
     CreateFaxSetup;
     GrDisplayMouse(GrHide);
     DrawWindow(20,20,GraphMaxX-20,GraphMaxY-80,'SGT Services Manager - Class 1 & 2 Fax Manager',5);
     DoOkButton(GraphMaxX-110,GraphMaxY-130);
     SystemButton(30,GraphMaxY-130,145,GraphMaxY-90,1,False,True);
     SystemIcon(35,GraphMaxY-125,76);
     OutTextXY(75,GraphMaxY-117,0,255,1,'Send Fax');
     SystemButton(155,GraphMaxY-130,285,GraphMaxY-90,1,False,True);
     SystemIcon(160,GraphMaxY-125,76);
     OutTextXY(200,GraphMaxY-117,0,255,1,'Receive Fax');
     GrSetFillStyle(GrFSolid,242,GrOpaque);
     GrDrawRect(30,55,GraphMaxX-30,70,GrFill);
     OutTextXY(35,55,15,255,1,'General Fax Setup');
     InvertedBox(30,75,GraphMaxX-30,170);
     YY := 85;
     SystemField(210,YY,5,40,FaxDir.InPath);    OutTextXYFR(200,YY+2,0,255,1,'Incoming Fax Path:');    INC(YY,24);
     SystemField(210,YY,5,40,FaxDir.CoverPage); OutTextXYFR(200,YY+2,0,255,1,'Fax Cover Page:');       INC(YY,24);
     SystemField(210,YY,4,20,FaxDir.StationId); OutTextXYFR(200,YY+2,0,255,1,'Station ID (Phone #):'); INC(YY,24);
     GrSetFillStyle(GrFSolid,242,GrOpaque);
     GrDrawRect(30,180,GraphMaxX-30,195,GrFill);
     OutTextXY(35,180,15,255,1,'Outgoing Fax');
     InvertedBox(30,200,GraphMaxX-30,GraphMaxY-140);
     YY := 210;
     SystemField(210,YY,5,40,FaxDir.SendFile);  OutTextXYFR(200,YY+2,0,255,1,'Text File To Send:');
     SystemButton(50,YY,90,YY+20,1,False,True);
     OutTextXY(60,YY+4,0,255,5,'Find');
     INC(YY,24);
     SystemField(210,YY,0,40,FaxDir.Title);     OutTextXYFR(200,YY+2,0,255,1,'Fax Title Name:');    INC(YY,24);
     SystemField(210,YY,2,30,FaxDir.YourName);  OutTextXYFR(200,YY+2,0,255,1,'Fax Sender:');        INC(YY,24);
     SystemField(210,YY,2,30,FaxDir.Recipient); OutTextXYFR(200,YY+2,0,255,1,'Fax Recipient:');     INC(YY,24);
     SystemField(210,YY,4,20,FaxDir.DialPhone); OutTextXYFR(200,YY+2,0,255,1,'Number To Call:');    INC(YY,24);
     GrDisplayMouse(GrShow);
     GaveUp := False;
     REPEAT
           GetMouse := MouseHandler(True);
           CASE GetMouse OF
           1:   GaveUp := True;
           2:   BEGIN
                     LoadUpVars;
                     GrDisplayMouse(GrHide);
                     DrawWindow(120,50,530,255,'Sending Fax - ESC Cancels',0);
                     InvertedBox(125,150,525,250);
                     OutTextXYFR(200,160,1,7,1,'Calling:');
                     OutTextXYFR(200,180,1,7,1,'Fax Speed:');
                     OutTextXYFR(200,200,1,7,1,'Status:');
                     OutTextXYFR(200,220,1,7,1,'Last Error:');
                     Hangup;
                     SendCommandString(CommDef.Hangup,True,True);
                     _Delay(1000);
                     FlushInBuffer(BBSPort);
                     SendTheFax;
                     KillWindow;
                     GrDisplayMouse(GrShow);
                END;
           3:   BEGIN
                     LoadUpVars;
                     GrDisplayMouse(GrHide);
                     DrawWindow(120,50,530,255,'Receiving Fax - ESC Cancels',0);
                     InvertedBox(125,150,525,250);
                     OutTextXYFR(200,160,1,7,1,'Call From:');
                     OutTextXYFR(200,180,1,7,1,'Fax Speed:');
                     OutTextXYFR(200,200,1,7,1,'Status:');
                     OutTextXYFR(200,220,1,7,1,'Last Error:');
                     Hangup;
                     SendCommandString(CommDef.Hangup,True,True);
                     _Delay(1000);
                     FlushInBuffer(BBSPort);
                     ReceiveTHEFAX;
                     KillWindow;
                     GrDisplayMouse(GrShow);
                END;
           4:   BEGIN
                     SelectedFile := TheFileName;
                     IF FileSelector(BaseDir+'\OUTFAX','*.*','',True,False,False)=1 THEN
                     BEGIN
                          TheFileName := SelectedFile;
                          GrDisplayMouse(GrHide);
                          ChangeField(4);
                          Fields[4].Text := BaseDir+'\OUTFAX\'+TheFileName;
                          Fields[4].CursorPos := LENGTH(Fields[4].Text)+1;
                          RedrawField;
                          GrDisplayMouse(GrShow);
                     END;
                END;
           END;
     UNTIL GaveUp;
     LoadUpVars;
     KillWindow;
     _Delay(500);
     SendCommandString('ATE1+FCLASS=0',True,True);
     _Delay(500);
     ptOptionsOn(BBSPort,ptRestoreOnClose OR ptDropModemOnClose);
     Comm_Deinit;
END;


END.
