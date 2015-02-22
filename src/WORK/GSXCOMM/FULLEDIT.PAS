{$I DEFINES.INC}
UNIT FullEdit;


INTERFACE


FUNCTION Full_Editor(replying: boolean) : boolean;


IMPLEMENTATION


USES Globals,ApTimer,AllGone,ApPort,ApCom,ApMisc,Carrier,Crt,QBack,GetQuote,
     BsMulti,ErrorLog,BsString,SBuffer,Screens,KeyInput,NList,Dos,SaveScrn,
     ExtDos,Upload,ReplyFil,Gfx,Time,Commands,MkGlobT,MiscMsg,Shotgun,BsAkas,
     BsFile;


TYPE MessageBody = Array[1..MaxMsgBuffer] Of Char;
TYPE OnScreen1   = Array[1..17] Of String[88];
TYPE Locators1   = Array[1..3000] Of Word;
VAR  OuttaHere          : Boolean;
     c                  : Char;
     GoodMessage        : Boolean;
     Loop               : Word;
     Scrap              : Word;
     Temp               : String;
     DestinationAddress : AddrType;
     CanToggle          : Boolean;
     UserX              : Word;
     UserY              : Word;
     MsgText            : ^MessageBody;
     TopCharNum         : Word;
     Current            : Word;
     Total              : Word;
     OnScreen           : ^OnScreen1;
     ReplyText          : MessageTextLines;
     Locators           : ^Locators1;
     TotalLines         : Word;
     IsOnScreen         : Boolean;
     TopLine            : Word;
     LastPosX           : Word;
     LastPosY           : Word;
     WorkName           : String[80];


PROCEDURE GotoXYAnsi(X,Y: Word);
BEGIN
     DrawChar(LastPosX,LastPosY,Colours.PickListBack,'_');
     LastPosX := X;
     LastPosY := Y;
     DrawChar(LastPosX,LastPosY,Colours.PickListFore,'_');
END;


PROCEDURE RedrawMessage(JustLocateCursor,ForceRedraw: Boolean);
VAR  LineNum    : Word;
     AllDone    : Boolean;
     Loop2      : Word;
     Good       : Boolean;
     LastSpace  : Word;
     Start      : Word;
     OldScreen  : Array[1..17] Of String[88];
     OldUserY   : Word;
BEGIN
     OldUserY := UserY;
     Move(OnScreen^,OldScreen,SizeOf(OnScreen^));
     FillChar(OnScreen^,SizeOf(OnScreen^),0);
     LineNum    := 1;
     Loop       := TopCharNum-1;
     AllDone    := False;
     IsOnScreen := False;
     REPEAT
           INC(Loop);
           IF MsgText^[Loop]=#255 THEN
           BEGIN
                {End of message}
                IF Loop=Current THEN
                BEGIN
                     UserX := 1;
                     UserY := LineNum;
                     IsOnScreen := True;
                END;
                AllDone := True;
           END
           ELSE IF MsgText^[Loop]=#13 THEN
           BEGIN
                {Hard Cr/Lf}
                IF Loop=Current THEN
                BEGIN
                     UserX := 1;
                     UserY := LineNum;
                     IsOnScreen := True;
                END;
                INC(LineNum);
                IF LineNum=18 THEN AllDone := True;
           END
           ELSE
           BEGIN
                Loop2     := Loop;
                Good      := False;
                LastSpace := Loop;
                Start     := Loop;
                REPEAT
                      OnScreen^[LineNum] := OnScreen^[LineNum]+MsgText^[Loop2];
                      IF LENGTH(OnScreen^[LineNum])<=MaxMsgWidth THEN
                      BEGIN
                           IF MsgText^[Loop2]=#32 THEN LastSpace := Loop2;
                      END;
                      CASE Ord(MsgText^[Loop2]) OF
                      13:  BEGIN
                                {Hard Cr/Lf}
                                IF Loop2=Current THEN
                                BEGIN
                                     UserX := Length(OnScreen^[LineNum]);
                                     UserY := LineNum;
                                     IsOnScreen := True;
                                END;
                                Delete(OnScreen^[LineNum],Length(OnScreen^[LineNum]),1);
                                INC(LineNum);
                                IF LineNum=18 THEN AllDone := True;
                                Good := True;
                                Loop := Loop2;
                           END;
                      255: BEGIN
                                {End of message}
                                IF Loop2=Current THEN
                                BEGIN
                                     UserX := Length(OnScreen^[LineNum]);
                                     UserY := LineNum;
                                     IsOnScreen := True;
                                END;
                                Delete(OnScreen^[LineNum],Length(OnScreen^[LineNum]),1);
                                AllDone := True;
                                Good    := True;
                                Loop    := Loop2;
                           END;
                      ELSE BEGIN
                                IF LENGTH(OnScreen^[LineNum])>MaxMsgWidth THEN
                                BEGIN
                                     OnScreen^[LineNum] := '';
                                     FOR Loop2 := Start TO LastSpace DO
                                     BEGIN
                                          OnScreen^[LineNum] := OnScreen^[LineNum]+MsgText^[Loop2];
                                          IF Loop2=Current THEN
                                          BEGIN
                                               UserX := Length(OnScreen^[LineNum]);
                                               UserY := LineNum;
                                               IsOnScreen := True;
                                          END;
                                     END;
                                     Loop := LastSpace;
                                     Good := True;
                                     INC(LineNum);
                                     IF LineNum=18 THEN AllDone := True;
                                END
                                ELSE
                                BEGIN
                                     IF Loop2=Current THEN
                                     BEGIN
                                          UserX := Length(OnScreen^[LineNum]);
                                          UserY := LineNum;
                                          IsOnScreen := True;
                                     END;
                                END;
                           END;
                      END;
                      INC(Loop2);
                UNTIL Good;
           END;
     UNTIL AllDone;
     IF NOT(JustLocateCursor) THEN
     BEGIN
          FOR Loop := 1 TO 17 DO
          BEGIN
               IF ((OldScreen[Loop]<>OnScreen^[Loop]) OR (Loop=OldUserY) OR (ForceRedraw)) THEN
               BEGIN
                    DrawText(1,Loop,Colours.PickListFore,Colours.PickListBack,_PadRight(OnScreen^[Loop],MaxMsgWidth));
               END;
          END;
     END;
     GotoXYAnsi(UserX,UserY);
END;


PROCEDURE InsertBuffer(Ch: Char);
BEGIN
     IF Total>=MaxMsgBuffer THEN DoErrorLog(26,'');
     Move(MsgText^[Current],MsgText^[Current+1],(Total+1)-Current+1);
     MsgText^[Current] := Ch;
     INC(Current);
     INC(Total);
     IF ((ord(ch)>31) AND (Ord(ch)<128)) THEN
     OnScreen^[UserY] := _Mid(OnScreen^[UserY],1,UserX-1)+Ch+
                         _Mid(OnScreen^[UserY],UserX,LENGTH(OnScreen^[UserY]));
     MsgText^[MaxMsgBuffer] := #255;
END;


PROCEDURE GetLocators;
VAR  AllDone    : Boolean;
     Loop2      : Word;
     Good       : Boolean;
     LastSpace  : Word;
     Start      : Word;
     NumChars   : Byte;
BEGIN
     Loop       := 0;
     AllDone    := False;
     TotalLines := 0;
     REPEAT
           INC(Loop);
           INC(TotalLines);
           IF TotalLines=3000 THEN DoErrorLog(27,'');
           Locators^[TotalLines] := Loop;
           IF MsgText^[Loop]=#255 THEN
           BEGIN
                {End of message}
                AllDone := True;
           END
           ELSE IF MsgText^[Loop]=#13 THEN
           BEGIN
                {Hard Cr/Lf}
           END
           ELSE
           BEGIN
                Loop2     := Loop;
                Good      := False;
                LastSpace := Loop;
                Start     := Loop;
                NumChars  := 0;
                REPEAT
                      INC(NumChars);
                      CASE Ord(MsgText^[Loop2]) OF
                      13:  BEGIN
                                {Hard Cr/Lf}
                                Good := True;
                                Loop := Loop2;
                           END;
                      255: BEGIN
                                {End of message}
                                AllDone := True;
                                Good    := True;
                                Loop    := Loop2;
                           END;
                      ELSE BEGIN
                                IF NumChars>MaxMsgWidth THEN
                                BEGIN
                                     Loop := LastSpace;
                                     Good := True;
                                END
                                ELSE
                                BEGIN
                                     IF MsgText^[Loop2]=#32 THEN LastSpace := Loop2;
                                END;
                           END;
                      END;
                      INC(Loop2);
                UNTIL Good;
           END;
     UNTIL AllDone;
     Locators^[TotalLines+1] := Loop+1;
END;


PROCEDURE MessageEditor_Save;
BEGIN
     GoodMessage := True;
     OuttaHere   := True;
END;


PROCEDURE MessageEditor_Abort;
BEGIN
     GoodMessage := False;
     OuttaHere   := True;
END;


PROCEDURE MessageEditor_Backspace;
BEGIN
     IF Current=1 THEN Exit;
     Move(MsgText^[Current],MsgText^[Current-1],(Total+1)-Current+1);
     DEC(Total);
     DEC(Current);
     MsgText^[MaxMsgBuffer] := #255;
     RedrawMessage(False,False);
     IF NOT(IsOnScreen) THEN
     BEGIN
          GetLocators;
          DEC(TopLine);
          TopCharNum := Locators^[TopLine];
          RedrawMessage(False,True);
     END;
END;


PROCEDURE MessageEditor_DumpMessage;
VAR  AllDone    : Boolean;
     Loop2      : Word;
     Good       : Boolean;
     LastSpace  : Word;
     Start      : Word;
     Msg_Text   : MessageTextLines;
     Temp       : String;
BEGIN
     Loop       := 0;
     AllDone    := False;
     ASSIGN(FMsgText,NODE_Directory+'\WRITE.$$$');
     REWRITE(FMsgText);
     Msg_Text.Line := '';
     REPEAT
           INC(Loop);
           IF MsgText^[Loop]=#255 THEN
           BEGIN
                WRITE(FMsgText,Msg_Text);
                AllDone := True;
           END
           ELSE IF MsgText^[Loop]=#13 THEN
           BEGIN
                WRITE(FMsgText,Msg_Text);
           END
           ELSE
           BEGIN
                Loop2     := Loop;
                Good      := False;
                LastSpace := Loop;
                Start     := Loop;
                Temp      := '';
                REPEAT
                      Temp := Temp+MsgText^[Loop2];
                      IF LENGTH(Temp)<=MaxMsgWidth THEN
                      BEGIN
                           IF MsgText^[Loop2]=#32 THEN LastSpace := Loop2;
                      END;
                      CASE Ord(MsgText^[Loop2]) OF
                      13:  BEGIN
                                Delete(Temp,Length(Temp),1);
                                Msg_Text.Line := Temp;
                                WRITE(FMsgText,Msg_Text);
                                Msg_Text.Line := '';
                                Good := True;
                                Loop := Loop2;
                           END;
                      255: BEGIN
                                Delete(Temp,Length(Temp),1);
                                Msg_Text.Line := Temp;
                                WRITE(FMsgText,Msg_Text);
                                Msg_Text.Line := '';
                                AllDone := True;
                                Good    := True;
                                Loop    := Loop2;
                           END;
                      ELSE BEGIN
                                IF LENGTH(Temp)>MaxMsgWidth THEN
                                BEGIN
                                     Temp := '';
                                     FOR Loop2 := Start TO LastSpace DO
                                         Temp := Temp+MsgText^[Loop2];
                                     Loop := LastSpace;
                                     Good := True;
                                     Msg_Text.Line := Temp;
                                     WRITE(FMsgText,Msg_Text);
                                     Msg_Text.Line := '';
                                END;
                           END;
                      END;
                      INC(Loop2);
                UNTIL Good;
           END;
     UNTIL AllDone;
     CLOSE(FMsgText);
END;


PROCEDURE MessageEditor_StartOfLine;
BEGIN
     IF UserX<>1 THEN
     BEGIN
          Current := Current-UserX+1;
          UserX   := 1;
          GotoXYAnsi(UserX,UserY);
     END;
END;


PROCEDURE MessageEditor_EndOfLine;
BEGIN
     IF (UserX<>LENGTH(OnScreen^[UserY])+1) THEN
     BEGIN
          GetLocators;
          Current := Locators^[TopLine+UserY]-1;
          RedrawMessage(True,False);
     END;
END;


PROCEDURE MessageEditor_InsertTab;
BEGIN
     IF LENGTH(OnScreen^[UserY])+6>MaxMsgWidth THEN Exit;
     Move(MsgText^[Current],MsgText^[Current+6],MaxMsgBuffer-Current-6);
     MsgText^[Current]   := ' ';
     MsgText^[Current+1] := ' ';
     MsgText^[Current+2] := ' ';
     MsgText^[Current+3] := ' ';
     MsgText^[Current+4] := ' ';
     MsgText^[Current+5] := ' ';
     INC(Current,6);
     INC(Total,6);
     OnScreen^[UserY] := _Mid(OnScreen^[UserY],1,UserX-1)+'      '+
                         _Mid(OnScreen^[UserY],UserX,LENGTH(OnScreen^[UserY]));
     MsgText^[MaxMsgBuffer] := #255;
     DrawText(UserX,UserY,Colours.PickListFore,Colours.PickListBack,_Mid(OnScreen^[UserY],UserX,Length(OnScreen^[UserY])));
     INC(UserX,6);
     GotoXYANSI(UserX,UserY);
END;


PROCEDURE MessageEditor_LeftArrow;
BEGIN
     IF Current>1 THEN
     BEGIN
          Dec(Current);
          RedrawMessage(True,False);
          IF NOT(IsOnScreen) THEN
          BEGIN
               GetLocators;
               DEC(TopLine);
               TopCharNum := Locators^[TopLine];
               RedrawMessage(False,True);
          END;
     END;
END;


PROCEDURE MessageEditor_RightArrow;
BEGIN
     IF Current<=Total THEN
     BEGIN
          Inc(Current);
          RedrawMessage(True,False);
          IF NOT(IsOnScreen) THEN
          BEGIN
               GetLocators;
               INC(TopLine);
               TopCharNum := Locators^[TopLine];
               RedrawMessage(False,True);
          END;
     END;
END;


PROCEDURE MessageEditor_PageUp;
VAR  Temporary : Integer;
BEGIN
     GetLocators;
     IF TopLine>1 THEN
     BEGIN
          Temporary := TopLine;
          Temporary := Temporary-17;
          IF Temporary<1 THEN Temporary := 1;
          TopLine := Temporary;
          TopCharNum := Locators^[TopLine];
          Current    := Locators^[TopLine];
          RedrawMessage(False,True);
     END;
END;


PROCEDURE MessageEditor_PageDown;
BEGIN
     GetLocators;
     IF TopLine<TotalLines THEN
     BEGIN
          INC(TopLine,17);
          IF TopLine>TotalLines THEN TopLine := TotalLines;
          TopCharNum := Locators^[TopLine];
          Current    := Locators^[TopLine];
          RedrawMessage(False,True);
     END;
END;


PROCEDURE MessageEditor_UpArrow;
BEGIN
     GetLocators;
     IF TopLine+UserY-1>1 THEN
     BEGIN
          Current := Locators^[TopLine+UserY-2]+UserX-1;
          IF Current>=Locators^[TopLine+UserY-1] THEN
             Current := Locators^[TopLine+UserY-1]-1;
          RedrawMessage(True,False);
          IF NOT(IsOnScreen) THEN
          BEGIN
               DEC(TopLine);
               TopCharNum := Locators^[TopLine];
               RedrawMessage(False,True);
          END;
     END;
END;


PROCEDURE MessageEditor_DownArrow;
BEGIN
     GetLocators;
     IF TopLine+UserY-1<TotalLines THEN
     BEGIN
          Current := Locators^[TopLine+UserY]+UserX-1;
          IF Current>=Locators^[TopLine+UserY+1] THEN
             Current := Locators^[TopLine+UserY+1]-1;
          RedrawMessage(True,False);
          IF NOT(IsOnScreen) THEN
          BEGIN
               INC(TopLine);
               TopCharNum := Locators^[TopLine];
               RedrawMessage(False,True);
          END;
     END;
END;


PROCEDURE MessageEditor_EndOfMessage;
VAR  Good   : Boolean;
     TheTop : Word;
BEGIN
     GetLocators;
     Good   := False;
     TheTop := TotalLines;
     IF TheTop<>TopLine THEN
     BEGIN
          TopCharNum  := Locators^[TheTop];
          Current     := Locators^[TheTop];
          TopLine     := TheTop;
          RedrawMessage(False,True);
     END;
END;


PROCEDURE MessageEditor_DeleteLine;
VAR  NumBytes : Word;
     LStart   : Word;
     LEnd     : Word;
     Looper   : Word;
     Moving   : Word;
BEGIN
     GetLocators;
     LStart   := Locators^[TopLine+UserY-1];
     LEnd     := Locators^[TopLine+UserY]-1;
     NumBytes := LEnd-LStart+1;
     Moving   := Total-LStart+1;
     FOR Looper := 1 TO NumBytes DO
     BEGIN
          IF MsgText^[LStart]<>#255 THEN
          BEGIN
               Move(MsgText^[LStart+1],MsgText^[LStart],Moving);
               DEC(Total);
          END;
     END;
     MsgText^[Total+1] := #255;
     GetLocators;
     IF (Current>=Locators^[TopLine+UserY]) THEN
        Current := Locators^[TopLine+UserY]-1;
     RedrawMessage(False,False);
END;


PROCEDURE MessageEditor_Delete;
BEGIN
     IF MsgText^[Current]=#255 THEN Exit;
     Move(MsgText^[Current+1],MsgText^[Current],Total-Current+1);
     DEC(Total);
     MsgText^[MaxMsgBuffer] := #255;
     RedrawMessage(False,False);
END;


PROCEDURE MessageEditor_TopOfMessage;
BEGIN
     UserX       := 1;
     UserY       := 1;
     TopCharNum  := 1;
     Current     := 1;
     TopLine     := 1;
     RedrawMessage(False,True);
END;


PROCEDURE MessageEditor_TogglePrivate;
BEGIN
     IF CanToggle THEN
     BEGIN
          IF FastBaseHdr.Priv=False
             THEN FastBaseHdr.Priv := True
             ELSE FastBaseHdr.Priv := False;
     END;
END;


FUNCTION GetCtrlKeyPress: char;
VAR  c          : char;
     done       : Boolean;
     TimerInfo  : EventTimer;
     NewXY      : Array[1..2] Of Byte;
     NewOne     : Word;
     BB         : Word;
BEGIN
     c := chr(0);
     NewTimerSecs(TimerInfo,system_info.Sys_Idle);
     AltKey      := False;
     Done        := False;
     REPEAT
           IF TimerExpired(TimerInfo) THEN
           BEGIN
                DisplayGraphicFile('TIMEOUT',false,True,True);
                dispatcher(4);
           END;
           TimeLimit;
           IF keypressed THEN
           BEGIN
                c := ReadKey;
                IF ORD(c)=0 THEN
                BEGIN
                     c := ReadKey;
                     IF DoSysopPress(C) THEN NewTimerSecs(TimerInfo,system_info.Sys_Idle);
                     AltKey := True;
                END;
           END;
           IF CharReady(BBSPort) THEN
           BEGIN
                GetChar(BBSPort,c);
                IF ord(c)=255 THEN
                BEGIN
                     SendPickRequest;
                     c := #0;
                END
                ELSE IF ord(c)=254 THEN
                BEGIN
                     GetCharTimeout(BBSPort,c,2);
                     HandleIt(c);
                     c := #0;
                END
                ELSE IF ord(c)=253 THEN
                BEGIN
                     SendPickableRequest;
                     c := #0;
                END
                ELSE IF ord(c)=251 THEN
                BEGIN
                     GetBlockTimeOut(BBSPort,NewXY[1],2,BB,[],YappDelay);
                     IF ((NewXY[2]>0) AND (NewXY[2]<18) AND (NewXY[1]>0) AND (NewXY[1]<MaxMsgWidth+1)) THEN
                     BEGIN
                          GetLocators;
                          IF NewXY[1]>=Length(OnScreen^[NewXY[2]])+1 THEN
                             NewXY[1] := Length(OnScreen^[NewXY[2]])+1;
                          IF NewXY[2]+TopLine-1>TotalLines THEN
                          BEGIN
                               NewOne := Locators^[TotalLines];
                               IF NewOne<>Current THEN
                               BEGIN
                                    Current := NewOne;
                                    RedrawMessage(True,False);
                               END;
                          END
                          ELSE
                          BEGIN
                               NewOne  := Locators^[TopLine+NewXY[2]-1]+NewXY[1]-1;
                               IF NewOne<>Current THEN
                               BEGIN
                                    Current := NewOne;
                                    RedrawMessage(True,False);
                               END;
                          END;
                     END;
                     c := #0;
                END
                ELSE IF ord(c)=0 THEN
                BEGIN
                     GetChar(BBSPort,c);
                     AltKey := True;
                END;
           END
           ELSE CheckForCarrier;
     UNTIL (c<>#0);
     GetCtrlKeyPress := c;
END;


FUNCTION Full_Editor(replying: boolean): boolean;
VAR   CharToSend  : String[1];
      WhatOne     : Byte;
LABEL PressedEnter,TryAgain,CtrlY;

     PROCEDURE DrawTheEditWindow;
     BEGIN
          ClearBuffer;
          CASE MessageAreas.Area_Type OF
          1..19:  AddToBuffer('@MESSAGETO',FastBaseHdr.MsgTo);
          20..29: AddToBuffer('@MESSAGETO',FastBaseHdr.MsgTo+' ('+WorkName+')');
          30..39: AddToBuffer('@MESSAGETO',FastBaseHdr.MsgTo);
          END;
          IF Use_Alias
             THEN AddToBuffer('@MESSAGEFROM',UserRecord.Alias)
             ELSE AddToBuffer('@MESSAGEFROM',UserRecord.Name);
          AddToBuffer('@MESSAGESUBJECT',FastBaseHdr.MsgSubject);
          IF FastBaseHdr.Priv=False
             THEN AddToBuffer('@PRIVATE',GetCommandString('MISC',2))
             ELSE AddToBuffer('@PRIVATE',GetCommandString('MISC',1));
          DisplayGraphicFile('FULLEDIT',True,True,True);
          NewPickList(False);
          PickInfo.Current := 0;
          BeginPickList;
     END;

     PROCEDURE StuffTheSysop;
     BEGIN
          IF _UpperCase(FastBaseHdr.MsgTo)='SYSOP' THEN
          BEGIN
               IF MessageAreas.Sysop<>'' THEN FastBaseHdr.MsgTo := MessageAreas.Sysop
               ELSE
               BEGIN
                    IF System_Info.Alias<>'' THEN
                    BEGIN
                         IF MessageAreas.Msg_Type>1
                            THEN FastBaseHdr.MsgTo := System_Info.Alias
                            ELSE FastBaseHdr.MsgTo := System_Info.Sysop;
                    END
                    ELSE FastBaseHdr.MsgTo := System_Info.Sysop;
               END;
          END;
     END;

     PROCEDURE MessageEditor_ChangeToSubject;
     BEGIN
          KillPickList;
          CASE MessageAreas.Area_Type OF
          1..9:   BEGIN {LOCAL}
                       IF (MessageAreas.ForcedTo=0) THEN
                       BEGIN
                            DisplayGraphicFile('FULLED1',False,True,True);
                            FieldText(1,FastBaseHdr.MsgTo);
                            FieldText(2,FastBaseHdr.MsgSubject);
                            Get_Enter;
                            IF Fields[1].Text<>'' THEN FastBaseHdr.MsgTo := Fields[1].Text;
                            IF Fields[2].Text<>'' THEN FastBaseHdr.MsgSubject := Fields[2].Text;
                            StuffTheSysop;
                       END
                       ELSE
                       BEGIN
                            ClearBuffer;
                            AddToBuffer('@MESSAGETO',FastBaseHdr.MsgTo);
                            DisplayGraphicFile('FULLED4',True,True,True);
                            FieldText(1,FastBaseHdr.MsgSubject);
                            Get_Enter;
                            IF Fields[1].Text<>'' THEN FastBaseHdr.MsgSubject := Fields[1].Text;
                            StuffTheSysop;
                       END;
                  END;
          10..19: BEGIN {ECHO}
                       DisplayGraphicFile('FULLED1',False,True,True);
                       FieldText(1,FastBaseHdr.MsgTo);
                       FieldText(2,FastBaseHdr.MsgSubject);
                       Get_Enter;
                       IF Fields[1].Text<>'' THEN FastBaseHdr.MsgTo := Fields[1].Text;
                       IF Fields[2].Text<>'' THEN FastBaseHdr.MsgSubject := Fields[2].Text;
                       StuffTheSysop;
                  END;
          20..29: BEGIN {NET}
                       DisplayGraphicFile('FULLED2',False,True,True);
                       FieldText(1,FastBaseHdr.MsgTo);
                       FieldText(2,AddressToString(DestinationAddress));
                       FieldText(3,FastBaseHdr.MsgSubject);
                       Get_Enter;
                       IF Fields[1].Text<>'' THEN FastBaseHdr.MsgTo := Fields[1].Text;
                       IF Fields[2].Text<>'' THEN StringToAddress(Fields[2].Text,DestinationAddress);
                       IF Fields[3].Text<>'' THEN FastBaseHdr.MsgSubject := Fields[3].Text;
                       IF NodeListEntryFound(DestinationAddress)
                          THEN WorkName := AddressToString(DestinationAddress)+' - '+NodeListSystem
                          ELSE WorkName := AddressToString(DestinationAddress)+' - Unlisted Node';
                       StuffTheSysop;
                  END;
          30..39: BEGIN {UUCP}
                       DisplayGraphicFile('FULLED3',False,True,True);
                       FieldText(1,FastBaseHdr.MsgTo);
                       FieldText(2,FastBaseHdr.MsgSubject);
                       Get_Enter;
                       IF Fields[1].Text<>'' THEN FastBaseHdr.MsgTo := Fields[1].Text;
                       IF Fields[2].Text<>'' THEN FastBaseHdr.MsgSubject := Fields[2].Text;
                       StuffTheSysop;
                  END;
          END;
          DrawTheEditWindow;
          RedrawMessage(False,True);
     END;

     PROCEDURE MessageEditor_Help;
     BEGIN
          KillPickList;
          DisplayGraphicFile('EDITHELP',False,True,True);
          Get_Enter;
          DrawTheEditWindow;
          RedrawMessage(False,True);
     END;

     PROCEDURE ImportTextFile;
     VAR  Uploaded_File : String;
          Loop          : Word;
          Counter       : Word;
          DirInfo       : SearchRec;
          MessageFile   : Text;
          MessageGood   : Boolean;
     LABEL                AllDone;
     BEGIN
          KillPickList;
          DisplayGraphicFile('IMPTEXT',False,True,True);
          Get_Enter;
          Clear_Scan_Dir;
          private_upload(SCAN_Directory);
          Uploaded_File := '';
          {SCAN_DIR}
          FindFirst(SCAN_Directory+'\*.*',Anyfile-Directory-VolumeID,DirInfo);
          IF DosError=0 THEN
          BEGIN
               uploaded_file := _UpperCase(DirInfo.Name);
               ASSIGN(MessageFile,SCAN_Directory+'\'+Uploaded_File);
               {$I-}RESET(MessageFile);{$I+}
               IF IOResult=0 THEN
               BEGIN
                    MessageGood := True;
                    Counter     := 0;
                    REPEAT
                          READLN(MessageFile,Temp);
                          INC(Counter);
                          IF LENGTH(Temp)>MaxMsgWidth THEN MessageGood := False;
                    UNTIL EOF(MessageFile);
                    CLOSE(MessageFile);
                    IF _FileSize(SCAN_Directory+'\'+Uploaded_File)>32000 THEN MessageGood := False;
                    IF MessageGood THEN
                    BEGIN
                         Counter := Current;
                         ASSIGN(MessageFile,SCAN_Directory+'\'+Uploaded_File);
                         RESET(MessageFile);
                         REPEAT
                               READLN(MessageFile,Temp);
                               Temp := Remove_Kludge(Temp);
                               Temp := _Mid(Temp,1,MaxMsgWidth-1)+#13;
                               FOR Loop := 1 TO LENGTH(Temp) DO
                               BEGIN
                                    IF Total>=MaxMsgBuffer THEN
                                    BEGIN
                                         DoErrorLog(26,'');
                                         GOTO AllDone;
                                    END;
                                    Move(MsgText^[Counter],MsgText^[Counter+1],(Total+1)-Counter+1);
                                    MsgText^[Counter] := Temp[Loop];
                                    INC(Counter);
                                    INC(Total);
                               END;
                         UNTIL EOF(MessageFile);
                         AllDone:
                         CLOSE(MessageFile);
                         MsgText^[MaxMsgBuffer] := #255;
                    END
                    ELSE
                    BEGIN
                         DisplayGraphicFile('MSGBAD',False,True,True);
                         Get_Enter;
                    END;
               END;
          END;
          Clear_Scan_Dir;
          Chdir(Shotgun_Directory);
          DrawTheEditWindow;
          RedrawMessage(False,True);
     END;

     PROCEDURE MessageEditor_Netmail;
     VAR  Loop2 : Word;
          C     : Char;
     BEGIN
          IF MessageAreas.Area_Type>19 THEN
          BEGIN
               KillPickList;
               c := Chr(0);
               REPEAT
                     ClearBuffer;
                     IF FastBaseHdr.Priv THEN AddToBuffer('@P',GetCommandString('MISC',1))
                                         ELSE AddToBuffer('@P',GetCommandString('MISC',2));
                     IF Msg_File_Request THEN AddToBuffer('@R',GetCommandString('MISC',1))
                                         ELSE AddToBuffer('@R',GetCommandString('MISC',2));
                     IF Msg_File_Attach  THEN AddToBuffer('@F',GetCommandString('MISC',1))
                                         ELSE AddToBuffer('@F',GetCommandString('MISC',2));
                     IF Msg_Crash        THEN AddToBuffer('@C',GetCommandString('MISC',1))
                                         ELSE AddToBuffer('@C',GetCommandString('MISC',2));
                     IF Msg_Hold         THEN AddToBuffer('@H',GetCommandString('MISC',1))
                                         ELSE AddToBuffer('@H',GetCommandString('MISC',2));
                     DisplayGraphicFile('NETOPT',True,True,True);
                     IF CanToggle THEN c := Get_Menu_Selection('QRFCHP','Q')
                                  ELSE c := Get_Menu_Selection('QRFCH','Q');
                     c := UpCase(c);
                     CASE c OF
                     'P': IF FastBaseHdr.Priv THEN FastBaseHdr.Priv := False
                                              ELSE FastBaseHdr.Priv := True;
                     'R': BEGIN
                               IF Msg_File_Request THEN Msg_File_Request := False
                                                   ELSE Msg_File_Request := True;
                               IF Msg_File_Request THEN Msg_File_Attach := False;
                          END;
                     'F': BEGIN
                               IF Msg_File_Attach THEN Msg_File_Attach := False
                                                  ELSE Msg_File_Attach := True;
                               IF Msg_File_Attach THEN Msg_File_Request := False;
                          END;
                     'C': BEGIN
                               IF Msg_Crash THEN Msg_Crash := False
                                            ELSE Msg_Crash := True;
                               IF Msg_Crash THEN Msg_Hold := False;
                          END;
                     'H': BEGIN
                               IF Msg_Hold THEN Msg_Hold := False
                                           ELSE Msg_Hold := True;
                               IF Msg_Hold THEN Msg_Crash := False;
                          END;
                     END;
               UNTIL c='Q';
               DrawTheEditWindow;
               RedrawMessage(False,True);
          END;
     END;

BEGIN
     NEW(MsgText);
     NEW(OnScreen);
     NEW(Locators);
     CanToggle := False;
     IF replying THEN
     BEGIN
          WhatOne := UserRecord.DefaultQuote;
          IF ((WhatOne=0) OR (WhatOne>3)) THEN WhatOne := Select_Quote;
          CASE WhatOne OF
          0:   WhatOne := 2;
          3:   BEGIN
                    ReplyText.Line := '';
                    ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
                    REWRITE(FMsgText);
                    WRITE(FMsgText,ReplyText);
                    CLOSE(FMsgText);
               END;
          END;
          ProcessReplyFile(WhatOne);
     END;
     CASE MessageAreas.area_type OF
     3,12,22 : CanToggle := True;
     END;
     CASE MessageAreas.Area_Type OF
     1..9:   BEGIN {LOCAL}
                  IF ((MessageAreas.ForcedTo=0) OR (FastBaseHdr.MsgTo='')) THEN
                  BEGIN
                       DisplayGraphicFile('FULLED1',False,True,True);
                       FieldText(1,FastBaseHdr.MsgTo);
                       IF Replying THEN FieldText(2,FastBaseHdr.MsgSubject);
                       Get_Enter;
                       IF ((Fields[1].Text='') OR (Fields[2].Text='')) THEN
                       BEGIN
                            Full_Editor := False;
                            DISPOSE(MsgText);
                            DISPOSE(OnScreen);
                            DISPOSE(Locators);
                            EXIT;
                       END;
                       FastBaseHdr.MsgTo := Fields[1].Text;
                       FastBaseHdr.MsgSubject := Fields[2].Text;
                       StuffTheSysop;
                  END
                  ELSE
                  BEGIN
                       ClearBuffer;
                       AddToBuffer('@MESSAGETO',FastBaseHdr.MsgTo);
                       DisplayGraphicFile('FULLED4',True,True,True);
                       IF Replying THEN FieldText(1,FastBaseHdr.MsgSubject);
                       Get_Enter;
                       IF (Fields[1].Text='') THEN
                       BEGIN
                            Full_Editor := False;
                            DISPOSE(MsgText);
                            DISPOSE(OnScreen);
                            DISPOSE(Locators);
                            EXIT;
                       END;
                       FastBaseHdr.MsgSubject := Fields[1].Text;
                       StuffTheSysop;
                  END;
             END;
     10..19: BEGIN {ECHO}
                  DisplayGraphicFile('FULLED1',False,True,True);
                  FieldText(1,FastBaseHdr.MsgTo);
                  IF Replying THEN FieldText(2,FastBaseHdr.MsgSubject);
                  Get_Enter;
                  IF ((Fields[1].Text='') OR (Fields[2].Text='')) THEN
                  BEGIN
                       Full_Editor := False;
                       DISPOSE(MsgText);
                       DISPOSE(OnScreen);
                       DISPOSE(Locators);
                       EXIT;
                  END;
                  FastBaseHdr.MsgTo := Fields[1].Text;
                  FastBaseHdr.MsgSubject := Fields[2].Text;
                  StuffTheSysop;
             END;
     20..29: BEGIN {NET}
                  DisplayGraphicFile('FULLED2',False,True,True);
                  FieldText(1,FastBaseHdr.MsgTo);
                  IF Replying THEN
                  BEGIN
                       FieldText(2,AddressToString(FastBaseHdr.Orig));
                       FieldText(3,FastBaseHdr.MsgSubject);
                  END;
                  Get_Enter;
                  IF ((Fields[1].Text='') OR (Fields[2].Text='') OR (Fields[3].Text='')) THEN
                  BEGIN
                       Full_Editor := False;
                       DISPOSE(MsgText);
                       DISPOSE(OnScreen);
                       DISPOSE(Locators);
                       EXIT;
                  END;
                  FastBaseHdr.MsgTo := Fields[1].Text;
                  StringToAddress(Fields[2].Text,DestinationAddress);
                  FastBaseHdr.MsgSubject := Fields[3].Text;
                  IF NodeListEntryFound(DestinationAddress)
                     THEN WorkName := AddressToString(DestinationAddress)+' - '+NodeListSystem
                     ELSE WorkName := AddressToString(DestinationAddress)+' - Unlisted Node';
                  Msg_File_Request := False;
                  Msg_File_Attach  := False;
                  Msg_Crash        := False;
                  Msg_Hold         := False;
                  StuffTheSysop;
             END;
     30..39: BEGIN {UUCP}
                  DisplayGraphicFile('FULLED3',False,True,True);
                  FieldText(1,FastBaseHdr.MsgTo);
                  IF Replying THEN FieldText(2,FastBaseHdr.MsgSubject);
                  Get_Enter;
                  IF ((Fields[1].Text='') OR (Fields[2].Text='')) THEN
                  BEGIN
                       Full_Editor := False;
                       DISPOSE(MsgText);
                       DISPOSE(OnScreen);
                       DISPOSE(Locators);
                       EXIT;
                  END;
                  FastBaseHdr.MsgTo := Fields[1].Text;
                  FastBaseHdr.MsgSubject := Fields[2].Text;
                  StuffTheSysop;
             END;
     END;
     FillChar(MsgText^,SizeOf(MsgText^),0);
     FillChar(OnScreen^,SizeOf(OnScreen^),0);
     DrawTheEditWindow;
     ReplyingInitials := '@@#!@#';
     LengthOfInitials := 6;
     MsgText^[1]      := #255;
     Total            := 0;
     UserX            := 1;
     UserY            := 1;
     TopCharNum       := 1;
     Current          := 1;
     TopLine          := 1;
     TotalLines       := 1;
     IF Replying=True THEN
     BEGIN
          Total := 1;
          ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
          RESET(FMsgText);
          REPEAT
                READ(FMsgText,ReplyText);
                IF ReplyText.Line='' THEN
                BEGIN
                     MsgText^[Total] := #13;
                     INC(Total);
                END
                ELSE
                BEGIN
                     FOR Loop := 1 TO LENGTH(ReplyText.Line) DO
                     BEGIN
                          MsgText^[Total] := ReplyText.Line[Loop];
                          INC(Total);
                     END;
                     MsgText^[Total] := #13;
                     INC(Total);
                END;
          UNTIL EOF(FMsgText);
          CLOSE(FMsgText);
          Dec(Total);
          MsgText^[Total+1] := #255;
          RedrawMessage(False,True);
     END;
     OuttaHere := False;
     LastPosX  := 1;
     LastPosY  := 1;
     GotoXYAnsi(UserX,UserY);
     REPEAT
           c := GetCtrlKeyPress;
           IF AltKey THEN
           BEGIN
                CASE ORD(c) OF
                73  : MessageEditor_PageUp;
                81  : MessageEditor_PageDown;
                72  : MessageEditor_UpArrow;
                80  : MessageEditor_DownArrow;
                75  : MessageEditor_LeftArrow;
                77  : MessageEditor_RightArrow;
                71  : MessageEditor_StartOfLine;
                79  : MessageEditor_EndOfLine;
                83  : MessageEditor_Delete;
                132 : MessageEditor_TopOfMessage;
                118 : MessageEditor_EndOfMessage;
                END;
           END
           ELSE
           BEGIN
                CASE ORD(c) OF
                18  : MessageEditor_UpArrow;
                22  : MessageEditor_DownArrow;
                4   : MessageEditor_LeftArrow;
                6   : MessageEditor_RightArrow;
                17  : MessageEditor_TopOfMessage;
                26  : MessageEditor_EndOfMessage;
                10  : MessageEditor_ChangeToSubject;
                20  : MessageEditor_ChangeToSubject;
                25  : MessageEditor_DeleteLine;
                16  : BEGIN
                           MessageEditor_TogglePrivate;
                           DrawTheEditWindow;
                           RedrawMessage(False,True);
                      END;
                19  : MessageEditor_Save;
                1   : MessageEditor_Abort;
                9   : MessageEditor_InsertTab;
                8   : MessageEditor_Backspace;
                21  : ImportTextFile;
                13  : BEGIN
                           IF _UpperCase(OnScreen^[UserY])='/S' THEN
                           BEGIN
                                MessageEditor_Backspace;
                                MessageEditor_Backspace;
                                GoodMessage := True;
                                OuttaHere   := True;
                           END
                           ELSE IF _UpperCase(OnScreen^[UserY])='/A' THEN
                           BEGIN
                                MessageEditor_Backspace;
                                MessageEditor_Backspace;
                                GoodMessage := False;
                                OuttaHere   := True;
                           END
                           ELSE
                           BEGIN
                                InsertBuffer(C);
                                RedrawMessage(False,False);
                                IF NOT(IsOnScreen) THEN
                                BEGIN
                                     GetLocators;
                                     INC(TopLine);
                                     TopCharNum := Locators^[TopLine];
                                     RedrawMessage(False,True);
                                END;
                           END;
                      END;
                14  : MessageEditor_Netmail;
                5   : MessageEditor_Help;
                ELSE  IF ((ord(c)>31) AND (Ord(c)<128)) THEN
                      BEGIN
                           InsertBuffer(C);
                           {Line is too long, and needs to be wrapped}
                           IF ((LENGTH(OnScreen^[UserY])>MaxMsgWidth) OR (UserX=80)) THEN
                           BEGIN
                                RedrawMessage(False,False);
                                IF NOT(IsOnScreen) THEN
                                BEGIN
                                     GetLocators;
                                     INC(TopLine);
                                     TopCharNum := Locators^[TopLine];
                                     RedrawMessage(False,True);
                                END;
                           END
                           ELSE
                           BEGIN
                                IF (UserX=LENGTH(OnScreen^[UserY])+1) THEN
                                BEGIN
                                     CharToSend := C;
                                     DrawText(UserX,UserY,Colours.PickListFore,Colours.PickListBack,CharToSend);
                                     INC(UserX);
                                END
                                ELSE
                                BEGIN
                                     DrawText(UserX,UserY,Colours.PickListFore,Colours.PickListBack,
                                              _Mid(OnScreen^[UserY],UserX,Length(OnScreen^[UserY])));
                                     INC(UserX);
                                END;
                                GotoXYAnsi(UserX,UserY);
                           END;
                      END;
                END;
           END;
     UNTIL OuttaHere;
     MessageEditor_DumpMessage;
     DISPOSE(MsgText);
     DISPOSE(OnScreen);
     DISPOSE(Locators);
     KillPickList;
     Full_Editor := GoodMessage;
END;


END.
