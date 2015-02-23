{$I DEFINES.INC}
UNIT AnsiSide;


INTERFACE


PROCEDURE GraphicsSession;
FUNCTION  NoCarrier: Boolean;


IMPLEMENTATION


USES ApTimer,Globals,ApCom,ApPort,BsMulti,_Token,_Pick,Gr2_Bp,_Fields,
     Fx,GfxProto,BsComp,_Main,_Mouse,BsPrint,_Save,_Images,_Buffers,
     BsGraph,Ansi,_Text,_Extern,Selectr,Gx2_Bp,_Toggle,_BHandle,Crt,
     Startup,_Keys,Dos,BsFile,BsString,BsKeys,Version;


FUNCTION NoCarrier: Boolean;
BEGIN
     IF TimerExpired(CarrierTimer) THEN
     BEGIN
          NewTimerSecs(CarrierTimer,8);
          IF CheckDCD(BBSPort) THEN
          BEGIN
               NoCarrier := False;
          END
          ELSE
          BEGIN
               Disconnected := True;
               NoCarrier := True;
          END;
     END
     ELSE NoCarrier := False;
     TimeSlice;
END;


PROCEDURE GraphicsSession;
VAR  ccc         : Char;
     OuttaHere   : Boolean;
     Temp        : String;
     Temp999     : String[30];
     Loop        : Word;
     FFile       : File;
     Work        : Longint;
     Scrap       : Char;
     BBytesSent  : Word;
     BytesRead   : Word;
     XShift      : Word;
     YShift      : Word;
     WorkX       : Word;
     WorkY       : Word;
     TFile       : Text;
     dos_ver     : word;
     x1,y1,x2,y2 : Word;
     OldRes      : String[40];
     B1          : Array[1..4] Of Byte;
BEGIN
     PutString(BBSPort,#255#255#13);
     OuttaHere := False;
     Disconnected := False;
     GrDisplayMouse(GrShow);
     REPEAT
       IF CharReady(BBSPort) THEN
       BEGIN
         GetChar(BBSPort,ccc);
         IF ccc=#255 THEN
         BEGIN
           GetStringTimeout(BBSPort,Temp,255,[#13],YappDelay);
           DEC(Temp[0]);
           CASE ORD(Temp[1]) OF
           0:   BEGIN {JUST ACK THAT WE'RE HERE!}
                  PutString(BBSPort,#255#255#13);
                END;
           2:   BEGIN {END SESSION}
                  OuttaHere := True;
                END;
           6:   BEGIN {INCOMING SCREEN FILE}
                  MsgEditorKludge := False;
                  MsgOldX         := 0;
                  MsgOldY         := 0;
                  FilesInQueue    := 0;
                  ScreenNumber    := 0;
                  Delete(Temp,1,1);
                  IF NOT(_FileExists(SESSION_Directory+'\'+Temp)) THEN
                  BEGIN
                    PutChar(BBSPort,#255);
                    ReceiveYAPP(SESSION_Directory+'\'+Temp,False);
                    pDecompressFile(SESSION_Directory+'\'+Temp,SESSION_Directory+'\'+_NoExtension(Temp)+'.SG');
                  END
                  ELSE PutChar(BBSPort,#254);
                  RedrawScreen(SESSION_Directory+'\'+_NoExtension(Temp)+'.SG');
                  PutChar(BBSPort,#252);
                END;
           7:   BEGIN {INCOMING SYSTEM FILE}
                  Delete(Temp,1,1);
                  ChangeMouse(BusyMouse);
                  PutChar(BBSPort,#255);
                  IF ((Temp='IMAGE.CMP') OR (Temp='PRNFILE.CMP'))
                     THEN ReceiveYAPP(SESSION_Directory+'\'+Temp,True)
                     ELSE ReceiveYAPP(SESSION_Directory+'\'+Temp,False);
                  IF Temp='BUFFER.CMP' THEN
                  BEGIN
                    pDecompressFile(SESSION_Directory+'\BUFFER.CMP',SESSION_Directory+'\BUFFER.DAT');
                    LoadBuffer;
                  END
                  ELSE IF Temp='PRNFILE.CMP' THEN
                  BEGIN
                    pDecompressFile(SESSION_Directory+'\PRNFILE.CMP',SESSION_Directory+'\PRNFILE.$$$');
                    ASSIGN(TFile,SESSION_Directory+'\PRNFILE.$$$');
                    {$I-}RESET(TFile);{$I+}
                    IF IOResult=0 THEN
                    BEGIN
                      PrintStart(FixedLPT);
                      REPEAT
                        READLN(TFile,Temp);
                        PrintLine('  '+Temp);
                      UNTIL EOF(TFile);
                      CLOSE(TFile);
                      ERASE(TFile);
                      PrintEnd;
                    END;
                  END
                  ELSE IF Temp='IMAGE.CMP' THEN
                  BEGIN
                    pDecompressFile(SESSION_Directory+'\IMAGE.CMP',SESSION_Directory+'\IMAGE.$$$');
                  END
                  ELSE IF Temp='COLOURS.VGA' THEN
                  BEGIN
                    ASSIGN(FFile,SESSION_Directory+'\'+Temp);
                    {$I-}RESET(FFile,1);{$I+}
                    IF IOResult=0 THEN
                    BEGIN
                      BLOCKREAD(FFile,Colours,SizeOf(Colours),BytesRead);
                      CLOSE(FFile);
                    END;
                  END
                  ELSE IF _GetFileExtension(Temp)='MSE' THEN
                  BEGIN
                    ASSIGN(FFile,SESSION_Directory+'\'+Temp);
                    {$I-}RESET(FFile,1);{$I+}
                    IF IOResult=0 THEN
                    BEGIN
                      IF Temp='BPRESS.MSE'   THEN BLOCKREAD(FFile,BPressMouse,SizeOf(BPressMouse),BytesRead);
                      IF Temp='BUSY.MSE'     THEN BLOCKREAD(FFile,BusyMouse,SizeOf(BusyMouse),BytesRead);
                      IF Temp='DEFAULT.MSE'  THEN BLOCKREAD(FFile,DefaultMouse,SizeOf(DefaultMouse),BytesRead);
                      IF Temp='INSERT.MSE'   THEN BLOCKREAD(FFile,InsertMouse,SizeOf(InsertMouse),BytesRead);
                      IF Temp='FILEDRAG.MSE' THEN BLOCKREAD(FFile,FileDragMouse,SizeOf(FileDragMouse),BytesRead);
                      IF Temp='MSGDRAG.MSE'  THEN BLOCKREAD(FFile,MsgDragMouse,SizeOf(MsgDragMouse),BytesRead);
                      IF Temp='WINMOVE.MSE'  THEN BLOCKREAD(FFile,WinMoveMouse,SizeOf(WinMoveMouse),BytesRead);
                      CLOSE(FFile);
                    END;
                  END;
                  ChangeMouse(DefaultMouse);
                  PutChar(BBSPort,#252);
                END;
           8:   BEGIN {INCOMING GIP FILE}
                  MsgEditorKludge := False;
                  MsgOldX         := 0;
                  MsgOldY         := 0;
                  FilesInQueue    := 0;
                  ScreenNumber    := 0;
                  Delete(Temp,1,1);
                  Temp := GIP_Directory+Temp;
                  IF NOT(_FileExists(Temp)) THEN
                  BEGIN
                    ChangeMouse(BusyMouse);
                    PutChar(BBSPort,#255);
                    ReceiveYAPP(Temp,False);
                    UnpackTheGIP(Temp);
                    ChangeMouse(DefaultMouse);
                  END
                  ELSE
                  BEGIN
                    PutChar(BBSPort,#254);
                    Temp := _NoExtension(Temp)+'.SG';
                  END;
                  OldRes := RESOURCES;
                  RESOURCES := GIP_Directory;
                  RedrawScreen(Temp);
                  RESOURCES := OldRes;
                  PutChar(BBSPort,#252);
                END;
           100: BEGIN {REMOTE PAUSED}
                  ChangeMouse(BusyMouse);
                  ccc := #0;
                  REPEAT
                    IF CharReady(BBSPort) THEN GetChar(BBSPort,ccc);
                  UNTIL ccc=#13;
                  ChangeMouse(DefaultMouse);
                END;
           110: BEGIN {NEW PICKLIST}
                  X1 := PickInfo.x1;
                  Y1 := PickInfo.y1;
                  X2 := PickInfo.x2;
                  Y2 := PickInfo.y2;
                  GetBlockTimeOut(BBSPort,PickInfo,SizeOf(PickInfo),BBytesSent,[],YappDelay);
                  PickInfo.x1 := X1;
                  PickInfo.y1 := Y1;
                  PickInfo.x2 := X2;
                  PickInfo.y2 := Y2;
                  NewPickList;
                  GrDisplayMouse(GrHide);
                  SetUpPickList;
                  GrDisplayMouse(GrShow);
                END;
           111: BEGIN {DESTROY LAST PICKLIST}
                  KillPickList;
                END;
           112: BEGIN {SAVE THIS WINDOW}
                  Delete(Temp,1,1);
                  SaveCurrentWindow(Temp);
                END;
           113: BEGIN {LOAD LAST WINDOW}
                  Delete(Temp,1,1);
                  LoadCurrentWindow(Temp);
                END;
           114: BEGIN {IMAGE PREVIEW}
                  GrDisplayMouse(GrHide);
                  CASE Temp[2] OF
                  '1': LoadGraphicFile(SESSION_Directory+'\IMAGE.$$$',PadX1,PadY1,PadX2,PadY2,1,0,0,False);
                  '2': LoadGraphicFile(SESSION_Directory+'\IMAGE.$$$',PadX1,PadY1,PadX2,PadY2,4,0,0,False);
                  '3': LoadGraphicFile(SESSION_Directory+'\IMAGE.$$$',PadX1,PadY1,PadX2,PadY2,4,1,0,False);
                  END;
                  IF ScreenInfo.x1<>32000 THEN
                  BEGIN
                    KillCutout(1);
                    SaveCutout(ScreenInfo.X1,ScreenInfo.Y1,ScreenInfo.X2,ScreenInfo.Y2,1);
                  END;
                  GrDisplayMouse(GrShow);
                END;
           115: BEGIN {STUFF A FIELD}
                  GetBlockTimeOut(BBSPort,Loop,2,BBytesSent,[],YappDelay);
                  GetStringTimeout(BBSPort,Temp,255,[#13],YappDelay);
                  DEC(Temp[0]);
                  Fields[Loop].Text := Temp;
                  CASE Fields[Loop].EntryType OF
                  4:   Fields[Loop].CursorPos := 1;
                  18:  Fields[Loop].CursorPos := 1;
                  ELSE Fields[Loop].CursorPos := Length(Fields[Loop].Text)+1;
                  END;
                  GrDisplayMouse(GrHide);
                  DrawFields;
                  GrDisplayMouse(GrShow);
                END;
           116: BEGIN {REDRAW THE PICKLIST}
                  RedrawThePickList;
                  PutChar(BBSPort,#252);
                END;
           117: BEGIN {REDRAW THE PICKLIST AFTER CHANGING PARAMS}
                  GetBlockTimeOut(BBSPort,PickInfo.NumItems,2,BBytesSent,[],YappDelay);
                  GetBlockTimeOut(BBSPort,PickInfo.Top,2,BBytesSent,[],YappDelay);
                  RedrawThePickList;
                  PutChar(BBSPort,#252);
                END;
           118: BEGIN {RECEIVE FILES}
                  ChangeMouse(BusyMouse);
                  IsGfx := True;
                  ReceiveFiles(YappDef.DlDir);
                  ChangeMouse(DefaultMouse);
                END;
           119: BEGIN {DO THE BACKGROUND IF REQUESTED}
                  Delete(Temp,1,1);
                  GrDisplayMouse(GrHide);
                  XShift := Trunc((GraphMaxX-639)/2);
                  YShift := Trunc((GraphMaxY-479)/2);
                  GrSetFillStyle(GrFSolid,0,GrOpaque);
                  GrDrawRect(0,0,GraphMaxX,YWindow,GrFill);
                  CASE Ord(Temp[1]) OF
                  1:   LoadGraphicLib('BACK____.$$$',1+XShift,1+YShift,639+XShift,YWindow+YShift);
                  2:   LoadGraphicLib('OCEAN___.$$$',1+XShift,1+YShift,639+XShift,YWindow+YShift);
                  3:   LoadGraphicLib('DESERT__.$$$',1+XShift,1+YShift,639+XShift,YWindow+YShift);
                  4:   LoadGraphicLib('PLANET__.$$$',1+XShift,1+YShift,639+XShift,YWindow+YShift);
                  END;
                  PutChar(BBSPort,#255);
                  GrDisplayMouse(GrShow);
                END;
           120: BEGIN {RUN AN ANSI DOOR}
                  RunningDosDoor;
                END;
           121: BEGIN {FOR THE MESSAGE EDITOR!}
                  MsgEditorKludge := True;
                  Delete(Temp,1,1);
                  GetBlockTimeOut(BBSPort,B1[1],3,BBytesSent,[],YappDelay);
                  WorkX := PickInfo.x1+(8+((B1[1]-1)*7));
                  WorkY := PickInfo.y1+(10+((B1[2]-1)*14));
                  DrawChar(WorkX,WorkY,B1[3],Temp[1]);
                END;
           122: BEGIN {FOR THE MESSAGE EDITOR!}
                  MsgEditorKludge := True;
                  Delete(Temp,1,1);
                  GetBlockTimeOut(BBSPort,B1[1],4,BBytesSent,[],YappDelay);
                  WorkX := PickInfo.x1+(8+((B1[1]-1)*7));
                  WorkY := PickInfo.y1+(8+((B1[2]-1)*14));
                  DrawText(WorkX,WorkY,B1[3],B1[4],Temp);
                END;
           123: BEGIN {HOLD WITH MESSAGE}
                  Delete(Temp,1,1);
                  GrDisplayMouse(GrHide);
                  Get(10,YWindow-20,260,YWindow+30);
                  DrawShellWindow(Temp);
                  GrDisplayMouse(GrShow);
                  ChangeMouse(BusyMouse);
                  ccc := #0;
                  REPEAT
                    IF CharReady(BBSPort) THEN GetChar(BBSPort,ccc);
                  UNTIL ccc=#13;
                  GrDisplayMouse(GrHide);
                  Put(10,YWindow-20,False,True);
                  GrDisplayMouse(GrShow);
                  ChangeMouse(DefaultMouse);
                END;
           124: BEGIN {INCOMING SOUND FILE}
                  ChangeMouse(BusyMouse);
                  IF YappDef.Sound THEN
                  BEGIN
                    Delete(Temp,1,1);
                    IF NOT(_FileExists(RESOURCES+Temp)) THEN
                    BEGIN
                      PutChar(BBSPort,#255);
                      ReceiveYAPP(SESSION_Directory+'\'+Temp,True);
                      pDecompressFile(SESSION_Directory+'\'+Temp,RESOURCES+Temp);
                    END
                    ELSE PutChar(BBSPort,#254);
                    PlayVocFile(RESOURCES+Temp);
                    PutChar(BBSPort,#252);
                  END
                  ELSE PutString(BBSPort,#254#252);
                  ChangeMouse(DefaultMouse);
                END;
           126: BEGIN {SEND FILES WE QUEUED UP FOR UPLOAD}
                  ChangeMouse(BusyMouse);
                  IsGfx := True;
                  TransmitFiles;
                  ChangeMouse(DefaultMouse);
                END;
           127: BEGIN {RETURN THE YAPP VERSION NUMBER}
                  PutString(BBSPort,_String(YappVersion)+'P'+#13);
                END;
           128: BEGIN {CREATE OUR LIST OF UPLOADS FOR THE REMOTE}
                  IF DoFileQueue
                    THEN PutString(BBSPort,#13#255)
                    ELSE PutString(BBSPort,#13#254);
                END;
           129: BEGIN {UPDATE YAPP}
                  Delete(Temp,1,1);
                  _EraseFile(GST_Directory+'\'+Temp);
                  ChangeMouse(BusyMouse);
                  IsGfx := True;
                  ReceiveFiles(GST_Directory);
                  ChangeMouse(DefaultMouse);
                END;
           130: BEGIN {DO THE UPDATE NOW}
                  OuttaHere := True;
                END;
           131: BEGIN {RESELECT A PICKLIST}
                  GrDisplayMouse(GrHide);
                  ReSelectPickList(PickInfo.Current,PickInfo.Current);
                  GrDisplayMouse(GrShow);
                END;
           132: BEGIN {SET OUR SCREEN NUMBER}
                  Delete(Temp,1,1);
                  ScreenNumber := _Numeric(Temp);
                END;
           133: BEGIN {SET OUR PRINTER PORT}
                  Delete(Temp,1,1);
                  FixedLPT := _Numeric(Temp);
                END;
           134: BEGIN {REQUEST USER NAME & PASSWORD}
                  IF ((YappDef.Logon<>'') AND (YappDef.Password<>'')) THEN
                  BEGIN
                    PutString(BBSPort,YappDef.Logon+#13);
                    PutString(BBSPort,YappDef.Password+#13);
                  END
                  ELSE PutString(BBSPort,#13#13);
                END;
           135: BEGIN {PLAY A FLI}
                  ChangeMouse(BusyMouse);
                  Delete(Temp,1,1);
                  IF NOT(_FileExists(RESOURCES+Temp)) THEN
                  BEGIN
                    PutChar(BBSPort,#255);
                    ReceiveYAPP(SESSION_Directory+'\'+Temp,True);
                    pDecompressFile(SESSION_Directory+'\'+Temp,RESOURCES+Temp);
                  END
                  ELSE PutChar(BBSPort,#254);
                  PlayFLIFile(RESOURCES+Temp);
                  PutChar(BBSPort,#252);
                  ChangeMouse(DefaultMouse);
                END;
           136: BEGIN {RETURN OUR MEMORY STATS}
                  Temp := _String(MemAvail);
                  PutString(BBSPort,Temp+#13);
                  PutString(BBSPort,Temp+#13);
                END;
           137: BEGIN {RETURN OUR VIDEO RESOLUTION}
                  PutString(BBSPort,_String(ModeSelected)+#13);
                END;
           138: BEGIN {RETURN OUR OPERATING SYSTEM}
                  CASE Task.Os OF
                  0:   Temp := 'DOS';
                  1:   Temp := 'Windows';
                  2:   Temp := 'OS/2';
                  3:   Temp := 'DESQview';
                  4:   Temp := 'TopView';
                  END;
                  PutString(BBSPort,Temp+#13);
                END;
           139: BEGIN {CLEAR OUR GIP DIRECTORY}
                  EraseGIPDir;
                END;

           140: BEGIN {START SVGA DOOR PROGRAM}
                  PutChar(BBSPort,#252);
                END;
           141: BEGIN {SVGA DOOR PROGRAM COMMAND INCOMING}
                  Delete(Temp,1,1);
                  {DoSVGADoorProgramCommand(Temp);}
                  PutChar(BBSPort,#252);
                END;
           142: BEGIN {END SVGA DOOR PROGRAM}
                  PutChar(BBSPort,#252);
                END;

           200: BEGIN {GET READY TO DO THE TOGGLE}
                  StartToggle(False);
                END;
           201: BEGIN {DO ONE TOGGLE LEVEL}
                  GetBlockTimeOut(BBSPort,Toggle.Percent,2,BBytesSent,[],YappDelay);
                  DoToggle;
                END;
           202: BEGIN {DONE WITH THE TOGGLE}
                  EndToggle;
                END;
           203: BEGIN {RESUME A PREVIOUS TOGGLE}
                  GetBlockTimeOut(BBSPort,Toggle.Percent,2,BBytesSent,[],YappDelay);
                  StartToggle(True);
                END;
           END;
         END;
       END
       ELSE
       BEGIN
         IF NFields=0 THEN
         BEGIN
           ccc := ButtonHandler;
           IF ccc<>#0 THEN
           BEGIN
             PutChar(BBSPort,ccc);
           END
           ELSE
           BEGIN
             IF keypressed THEN
             BEGIN
               ccc := ReadKey;
               IF ORD(ccc)=0 THEN
               BEGIN
                 ccc := ReadKey;
                 CASE Ord(ccc) OF
                 35:     BEGIN
                           Hangup;
                           OuttaHere := True;
                         END;
                 59..69: DoFunctionKey(ccc);
                 ELSE BEGIN
                           HandleKeys(ccc,True);
                           PutString(BBSPort,#0+ccc);
                      END;
                 END;
               END
               ELSE PutChar(BBSPort,ccc);
             END
             ELSE IF NoCarrier THEN OuttaHere := True;
           END;
         END
         ELSE
         BEGIN
           ccc := ButtonHandler;
           IF ccc<>#0 THEN
           BEGIN
             Scrap := _NormalToAlt(ccc);
             IF (Scrap<>ccc) THEN PutString(BBSPort,#0+Scrap)
                             ELSE PutChar(BBSPort,ccc);
           END
           ELSE
           BEGIN
             IF keypressed THEN
             BEGIN
               ccc := ReadKey;
               IF ORD(ccc)=0 THEN
               BEGIN
                 ccc := ReadKey;
                 CASE Ord(ccc) OF
                 35:     BEGIN
                           Hangup;
                           OuttaHere := True;
                         END;
                 59..69: DoFunctionKey(ccc);
                 ELSE BEGIN
                           HandleKeys(ccc,True);
                           PutString(BBSPort,#0+ccc);
                      END;
                 END;
               END
               ELSE
               BEGIN
                 PutChar(BBSPort,ccc);
                 HandleKeys(ccc,False);
               END;
             END
             ELSE IF NoCarrier THEN OuttaHere := True;
           END;
         END;
       END;
     UNTIL OuttaHere;
     GrDisplayMouse(GrHide);
     HangUp;
END;


END.
