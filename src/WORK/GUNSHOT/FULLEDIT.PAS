{$I DEFINES.INC}
UNIT FullEdit;


INTERFACE


FUNCTION Full_Editor(replying: boolean): boolean;


IMPLEMENTATION


USES Globals,ANSIMisc,ApTimer,AllGone,ApPort,ApCom,ApMisc,Carrier,Crt,
     GetQuote,QBack,BsMulti,ErrorLog,SBuffer,Screens,KeyInput,NList,Dos,
     Gunshot,SaveScrn,ExtDos,Upload,ReplyFil,BsKeys,Commands,MiscMsg,
     MkGlobT,BsString,BsAkas,BsFile;


TYPE MessageBody = Array[1..MaxMsgBuffer] Of Char;
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
     OnScreen           : Array[1..17] Of String[88];
     ReplyText          : MessageTextLines;
     Locators           : Array[1..3000] Of Word;
     TotalLines         : Word;
     IsOnScreen         : Boolean;
     TopLine            : Word;


FUNCTION GetCtrlKeyPress: char;
VAR  cc         : char;
     done       : Boolean;
     TimerInfo  : EventTimer;
BEGIN
     cc     := chr(0);
     NewTimerSecs(TimerInfo,system_info.Sys_Idle);
     AltKey := False;
     Done   := False;
     REPEAT
           IF TimerExpired(TimerInfo) THEN
           BEGIN
                IF ((NOT(NodeInfo.NoTimeout)) OR (NOT(LocalLogon))) THEN
                BEGIN
                     SendCrLf(2);
                     DisplayGraphicsFile('TIMEOUT',true,false,True,True,False);
                     dispatcher(4);
                END;
           END;
           IF NOT(LocalLogon) THEN
           BEGIN
                IF CharReady(BBSPort) THEN
                BEGIN
                     GetChar(BBSPort,cc);
                     CASE ORD(cc) OF
                     0:   BEGIN
                               GetCharTimeout(BBSPort,cc,2);
                               AltKey := True;
                          END;
                     27:  BEGIN
                               GetCharTimeout(BBSPort,cc,2);
                               IF AsyncStatus=ecOk THEN
                               BEGIN
                                    IF cc=#91 THEN
                                    BEGIN
                                         AltKey := True;
                                         GetCharTimeout(BBSPort,cc,2);
                                         IF AsyncStatus=ecOk THEN
                                         BEGIN
                                              CASE ORD(cc) OF
                                              68  : cc := Chr(75);
                                              67  : cc := Chr(77);
                                              65  : cc := Chr(72);
                                              66  : cc := Chr(80);
                                              72  : cc := Chr(71);
                                              75  : cc := Chr(79);
                                              76  : cc := Chr(119);
                                              77  : cc := Chr(132);
                                              ELSE  cc := Chr(0);
                                              END;
                                         END;
                                    END
                                    ELSE cc := #27;
                               END
                               ELSE cc := #00;
                          END;
                     127: BEGIN
                               cc := Chr(83);
                               AltKey := True;
                          END;
                     END;
                     Done := True;
                     GetCtrlKeyPress := cc;
                     Exit;
                END
                ELSE CheckForCarrier;
           END;
           IF keypressed THEN
           BEGIN
                cc := ReadKey;
                IF ORD(cc)=0 THEN
                BEGIN
                     cc := ReadKey;
                     IF DoSysopPress(CC) THEN NewTimerSecs(TimerInfo,system_info.Sys_Idle);
                     AltKey := True;
                     IF ((ORD(cc)>0) AND (ORD(cc)<27)) THEN AltKey := False;
                END;
                Done := True;
                GetCtrlKeyPress := cc;
                Exit;
           END
           ELSE IF LocalLogon THEN TimeSlice;
     UNTIL Done;
     GetCtrlKeyPress := cc;
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
     OldUserY := UserY-5;
     Move(OnScreen,OldScreen,SizeOf(OnScreen));
     FillChar(OnScreen,SizeOf(OnScreen),0);
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
                     UserY := LineNum+5;
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
                     UserY := LineNum+5;
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
                      OnScreen[LineNum] := OnScreen[LineNum]+MsgText^[Loop2];
                      IF LENGTH(OnScreen[LineNum])<=MaxMsgWidth THEN
                      BEGIN
                           IF MsgText^[Loop2]=#32 THEN LastSpace := Loop2;
                      END;
                      CASE Ord(MsgText^[Loop2]) OF
                      13:  BEGIN
                                {Hard Cr/Lf}
                                IF Loop2=Current THEN
                                BEGIN
                                     UserX := Length(OnScreen[LineNum]);
                                     UserY := LineNum+5;
                                     IsOnScreen := True;
                                END;
                                Delete(OnScreen[LineNum],Length(OnScreen[LineNum]),1);
                                INC(LineNum);
                                IF LineNum=18 THEN AllDone := True;
                                Good := True;
                                Loop := Loop2;
                           END;
                      255: BEGIN
                                {End of message}
                                IF Loop2=Current THEN
                                BEGIN
                                     UserX := Length(OnScreen[LineNum]);
                                     UserY := LineNum+5;
                                     IsOnScreen := True;
                                END;
                                Delete(OnScreen[LineNum],Length(OnScreen[LineNum]),1);
                                AllDone := True;
                                Good    := True;
                                Loop    := Loop2;
                           END;
                      ELSE BEGIN
                                IF LENGTH(OnScreen[LineNum])>MaxMsgWidth THEN
                                BEGIN
                                     OnScreen[LineNum] := '';
                                     FOR Loop2 := Start TO LastSpace DO
                                     BEGIN
                                          OnScreen[LineNum] := OnScreen[LineNum]+MsgText^[Loop2];
                                          IF Loop2=Current THEN
                                          BEGIN
                                               UserX := Length(OnScreen[LineNum]);
                                               UserY := LineNum+5;
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
                                          UserX := Length(OnScreen[LineNum]);
                                          UserY := LineNum+5;
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
               IF ((OldScreen[Loop]<>OnScreen[Loop]) OR (Loop=OldUserY) OR (ForceRedraw)) THEN
               BEGIN
                    GotoXYANSI(1,Loop+5);
                    WRITEANSI(OnScreen[Loop],False,False);
                    ClrEOLANSI;
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
     OnScreen[UserY-5] := _Mid(OnScreen[UserY-5],1,UserX-1)+Ch+
                          _Mid(OnScreen[UserY-5],UserX,LENGTH(OnScreen[UserY-5]));
     MsgText^[MaxMsgBuffer] := #255;
END;


PROCEDURE MessageEditor_Delete;
BEGIN
     IF MsgText^[Current]=#255 THEN Exit;
     Move(MsgText^[Current+1],MsgText^[Current],Total-Current+1);
     DEC(Total);
     MsgText^[MaxMsgBuffer] := #255;
     RedrawMessage(False,False);
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
           Locators[TotalLines] := Loop;
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
     Locators[TotalLines+1] := Loop+1;
END;


PROCEDURE MessageEditor_TopOfMessage;
BEGIN
     UserX       := 1;
     UserY       := 6;
     TopCharNum  := 1;
     Current     := 1;
     TopLine     := 1;
     RedrawMessage(False,True);
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


PROCEDURE MessageEditor_Netmail;
VAR  Loop2     : Word;
     Str1,Str2 : String;
BEGIN
     Str1 := GetCommandString('MISC',1);
     Str2 := GetCommandString('MISC',2);
     IF (LENGTH(Str1)>LENGTH(Str2)) THEN
     BEGIN
          Str2 := _PadRight(Str2,LENGTH(Str1));
     END
     ELSE IF (LENGTH(Str2)>LENGTH(Str1)) THEN
     BEGIN
          Str1 := _PadRight(Str1,LENGTH(Str2));
     END;
     IF MessageAreas.Area_Type>19 THEN
     BEGIN
          c := Chr(0);
          REPEAT
                FOR Loop2 := 6 TO 22 DO
                BEGIN
                     GotoXYAnsi(1,Loop2);
                     ClrEolANSI;
                END;
                GotoXYAnsi(1,7);
                ClearBuffer;
                IF FastBaseHdr.Priv THEN AddToBuffer('@P',Str1)
                                    ELSE AddToBuffer('@P',Str2);
                IF Msg_File_Request THEN AddToBuffer('@R',Str1)
                                    ELSE AddToBuffer('@R',Str2);
                IF Msg_File_Attach  THEN AddToBuffer('@F',Str1)
                                    ELSE AddToBuffer('@F',Str2);
                IF Msg_Crash        THEN AddToBuffer('@C',Str1)
                                    ELSE AddToBuffer('@C',Str2);
                IF Msg_Hold         THEN AddToBuffer('@H',Str1)
                                    ELSE AddToBuffer('@H',Str2);
                DisplayGraphicsFile('NETOPT',False,True,True,True,False);
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
          FORE(Colours.ReadMSGBodyColour);
          RedrawMessage(False,True);
          GotoXYAnsi(UserX,UserY);
     END;
END;


PROCEDURE MessageEditor_Help;
VAR  Loop2 : Word;
BEGIN
     FOR Loop2 := 6 TO 22 DO
     BEGIN
          GotoXYAnsi(1,Loop2);
          ClrEolANSI;
     END;
     GotoXYAnsi(1,7);
     DisplayGraphicsFile('EDITHELP',True,False,True,True,False);
     Get_Enter;
     FORE(Colours.ReadMSGBodyColour);
     RedrawMessage(False,True);
     GotoXYAnsi(UserX,UserY);
END;


PROCEDURE MessageEditor_TogglePrivate;
VAR  Str1,Str2 : String;
BEGIN
     Str1 := GetCommandString('MISC',1);
     Str2 := GetCommandString('MISC',2);
     IF (LENGTH(Str1)>LENGTH(Str2)) THEN
     BEGIN
          Str2 := _PadRight(Str2,LENGTH(Str1));
     END
     ELSE IF (LENGTH(Str2)>LENGTH(Str1)) THEN
     BEGIN
          Str1 := _PadRight(Str1,LENGTH(Str2));
     END;
     IF CanToggle THEN
     BEGIN
          IF FastBaseHdr.Priv=False THEN FastBaseHdr.Priv := True
                                    ELSE FastBaseHdr.Priv := False;
          Fore(Colours.LineEditorInfoData);
          GotoXYAnsi(69,4);
          IF FastBaseHdr.Priv=False THEN WRITEANSI(Str2,False,False)
                                    ELSE WRITEANSI(Str1,False,False);
          FORE(Colours.ReadMSGBodyColour);
          GotoXYAnsi(UserX,UserY);
     END;
END;


PROCEDURE MessageEditor_ChangeSubject;
BEGIN
     GotoXYAnsi(12,4);
     Get_String(40,FastBaseHdr.MsgSubject,True,false,false,False);
     IF INPUT_STRING<>'' THEN FastBaseHdr.MsgSubject := Input_String;
     Fore(Colours.LineEditorInfoData);
     GotoXYAnsi(12,4);
     WRITEANSI(_PadRight(FastBaseHdr.MsgSubject,40),False,False);
     FORE(Colours.ReadMSGBodyColour);
     GotoXYAnsi(UserX,UserY);
END;


PROCEDURE MessageEditor_ChangeTo(Replying: Boolean);
BEGIN
     {GET MESSAGE DESTINATION - INCLUDING NETMAIL ADDRESS}
     IF (MessageAreas.Area_Type<20) THEN
     BEGIN
          GotoXYAnsi(12,3);
          Get_Name(30,FastBaseHdr.MsgTo,True,False);
          IF INPUT_STRING<>'' THEN FastBaseHdr.MsgTo := Input_String;
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
          FOR Loop := 1 TO LENGTH(Input_String) DO WRITECHAR(#08);
          Fore(Colours.LineEditorInfoData);
          WRITEANSI(_PadRight(FastBaseHdr.MsgTo,30),true,false);
     END
     ELSE IF (MessageAreas.Area_Type>29) THEN
     BEGIN
          GotoXYAnsi(12,3);
          Get_String(50,FastBaseHdr.MsgTo,True,False,False,False);
          IF INPUT_STRING<>'' THEN FastBaseHdr.MsgTo := Input_String;
          FOR Loop := 1 TO LENGTH(Input_String) DO WRITECHAR(#08);
          Fore(Colours.LineEditorInfoData);
          WRITEANSI(_PadRight(FastBaseHdr.MsgTo,50),true,false);
     END
     ELSE
     BEGIN
          GotoXYAnsi(12,3);
          Get_Name(30,FastBaseHdr.MsgTo,True,False);
          IF INPUT_STRING<>'' THEN FastBaseHdr.MsgTo := Input_String;
          FOR Loop := 1 TO LENGTH(Input_String) DO WRITECHAR(#08);
          Fore(Colours.LineEditorInfoData);
          WRITEANSI(FastBaseHdr.MsgTo+', ',false,false);
          Fore(Colours.LineEditorInfoData);
          IF Replying THEN Get_Name(20,AddressToString(FastBaseHdr.Orig),True,False)
                      ELSE Get_Name(20,'',True,False);
          FillChar(DestinationAddress,SizeOf(DestinationAddress),0);
          IF INPUT_STRING<>'' THEN StringToAddress(Input_String,DestinationAddress);
          FOR Loop := 1 TO LENGTH(Input_String) DO WRITECHAR(#08);
          Fore(Colours.LineEditorInfoData);
          Back(0);
          IF NodeListEntryFound(DestinationAddress)
             THEN WRITEANSI(_PadRight(AddressToString(DestinationAddress)+' - '+NodeListSystem,40),true,true)
             ELSE WRITEANSI(_PadRight(AddressToString(DestinationAddress)+' - Unlisted Node',40),true,true);
          Msg_File_Request := False;
          Msg_File_Attach  := False;
          Msg_Crash        := False;
          Msg_Hold         := False;
     END;
     FORE(Colours.ReadMSGBodyColour);
     GotoXYAnsi(UserX,UserY);
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
     IF (UserX<>LENGTH(OnScreen[UserY-5])+1) THEN
     BEGIN
          GetLocators;
          Current := Locators[TopLine+(UserY-6)+1]-1;
          RedrawMessage(True,False);
     END;
END;


PROCEDURE MessageEditor_InsertTab;
BEGIN
     IF LENGTH(OnScreen[UserY-5])+6>MaxMsgWidth THEN Exit;
     Move(MsgText^[Current],MsgText^[Current+6],MaxMsgBuffer-Current-6);
     MsgText^[Current]   := ' ';
     MsgText^[Current+1] := ' ';
     MsgText^[Current+2] := ' ';
     MsgText^[Current+3] := ' ';
     MsgText^[Current+4] := ' ';
     MsgText^[Current+5] := ' ';
     INC(Current,6);
     INC(Total,6);
     OnScreen[UserY-5] := _Mid(OnScreen[UserY-5],1,UserX-1)+'      '+
                          _Mid(OnScreen[UserY-5],UserX,LENGTH(OnScreen[UserY-5]));
     MsgText^[MaxMsgBuffer] := #255;
     IF (UserX=LENGTH(OnScreen[UserY-5])+1) THEN
     BEGIN
          WRITEANSI('      ',False,False);
          INC(UserX,6);
     END
     ELSE
     BEGIN
          WRITEANSI(_Mid(OnScreen[UserY-5],UserX,
                    Length(OnScreen[UserY-5])),False,False);
          INC(UserX,6);
          GotoXYANSI(UserX,UserY);
     END;
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
          DEC(TopLine,17);
          TopCharNum := Locators[TopLine];
          RedrawMessage(False,True);
     END;
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
               DEC(TopLine,17);
               TopCharNum := Locators[TopLine];
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
               INC(TopLine,17);
               TopCharNum := Locators[TopLine];
               RedrawMessage(False,True);
          END;
     END;
END;


PROCEDURE MessageEditor_PageUp;
BEGIN
     GetLocators;
     IF TopLine>1 THEN
     BEGIN
          DEC(TopLine,17);
          TopCharNum := Locators[TopLine];
          Current    := Locators[TopLine];
          RedrawMessage(False,True);
     END;
END;


PROCEDURE MessageEditor_PageDown;
BEGIN
     GetLocators;
     IF TopLine+17<=TotalLines THEN
     BEGIN
          INC(TopLine,17);
          TopCharNum := Locators[TopLine];
          Current    := Locators[TopLine];
          RedrawMessage(False,True);
     END;
END;


PROCEDURE MessageEditor_UpArrow;
BEGIN
     GetLocators;
     IF TopLine+(UserY-6)>1 THEN
     BEGIN
          Current := Locators[TopLine+(UserY-6)-1]+UserX-1;
          IF Current>=Locators[TopLine+(UserY-6)] THEN
             Current := Locators[TopLine+(UserY-6)]-1;
          RedrawMessage(True,False);
          IF NOT(IsOnScreen) THEN
          BEGIN
               DEC(TopLine,17);
               TopCharNum := Locators[TopLine];
               RedrawMessage(False,True);
          END;
     END;
END;


PROCEDURE MessageEditor_DownArrow;
BEGIN
     GetLocators;
     IF TopLine+(UserY-6)<TotalLines THEN
     BEGIN
          Current := Locators[TopLine+(UserY-6)+1]+UserX-1;
          IF Current>=Locators[TopLine+(UserY-6)+2] THEN
             Current := Locators[TopLine+(UserY-6)+2]-1;
          RedrawMessage(True,False);
          IF NOT(IsOnScreen) THEN
          BEGIN
               INC(TopLine,17);
               TopCharNum := Locators[TopLine];
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
     TheTop := 1;
     REPEAT
           INC(TheTop,17);
           IF TheTop>TotalLines THEN Good := True;
     UNTIL Good;
     DEC(TheTop,17);
     IF TheTop<>TopLine THEN
     BEGIN
          TopCharNum  := Locators[TheTop];
          Current     := Locators[TheTop];
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
     LStart   := Locators[TopLine+(UserY-6)];
     LEnd     := Locators[TopLine+(UserY-6)+1]-1;
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
     IF (Current>=Locators[TopLine+(UserY-6)+1]) THEN
        Current := Locators[TopLine+(UserY-6)+1]-1;
     RedrawMessage(False,False);
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


PROCEDURE ImportTextFile;
VAR  Uploaded_File : String;
     Loop          : Word;
     Counter       : Word;
     DirInfo       : SearchRec;
     MessageFile   : Text;
     MessageGood   : Boolean;
LABEL                AllDone;
BEGIN
     Save_Screen;
     DisplayGraphicsFile('IMPTEXT',True,false,True,True,False);
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
                    DisplayGraphicsFile('MSGBAD',True,false,True,True,False);
                    Get_Enter;
               END;
          END;
     END;
     Clear_Scan_Dir;
     Chdir(Gunshot_Directory);
     Restore_Screen;
     RedrawMessage(False,True);
END;


FUNCTION Full_Editor(replying: boolean): boolean;
VAR   Str1,Str2 : String;
      WhatOne   : Byte;
LABEL PressedEnter,TryAgain,CtrlY,JumpIn;
BEGIN
     Str1 := GetCommandString('MISC',1);
     Str2 := GetCommandString('MISC',2);
     IF (LENGTH(Str1)>LENGTH(Str2)) THEN
     BEGIN
          Str2 := _PadRight(Str2,LENGTH(Str1));
     END
     ELSE IF (LENGTH(Str2)>LENGTH(Str1)) THEN
     BEGIN
          Str1 := _PadRight(Str1,LENGTH(Str2));
     END;
     NEW(MsgText);
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
     3,12,22,32 : CanToggle := True;
     END;
     DisplayGraphicsFile('FULLEDIT',False,False,False,True,False);
     Fore(Colours.LineEditorInfoData);
     GotoXYAnsi(69,4);
     IF FastBaseHdr.Priv=False THEN WRITEANSI(Str2,False,False)
                               ELSE WRITEANSI(Str1,False,False);
     GotoXYAnsi(12,2); IF Use_Alias THEN WRITEANSI(UserRecord.Alias,False,False)
                                    ELSE WRITEANSI(UserRecord.Name,False,False);
     {GET MESSAGE DESTINATION - INCLUDING NETMAIL ADDRESS}
     IF (MessageAreas.Area_Type<20) THEN
     BEGIN
          IF ((MessageAreas.ForcedTo=0) OR (FastBaseHdr.MsgTo='')) THEN
          BEGIN
               GotoXYAnsi(12,3);
               Get_Name(30,FastBaseHdr.MsgTo,True,False);
               IF INPUT_STRING='' THEN
               BEGIN
                    Full_Editor := False;
                    DISPOSE(MsgText);
                    EXIT;
               END;
               FastBaseHdr.MsgTo := Input_String;
          END;
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
          GotoXYAnsi(12,3);
          Fore(Colours.LineEditorInfoData);
          WRITEANSI(_PadRight(FastBaseHdr.MsgTo,30),true,false);
     END
     ELSE IF (MessageAreas.Area_Type>29) THEN
     BEGIN
          IF ((MessageAreas.ForcedTo=0) OR (FastBaseHdr.MsgTo='')) THEN
          BEGIN
               GotoXYAnsi(12,3);
               Get_String(50,FastBaseHdr.MsgTo,True,False,False,False);
               IF INPUT_STRING='' THEN
               BEGIN
                    Full_Editor := False;
                    DISPOSE(MsgText);
                    EXIT;
               END;
               FastBaseHdr.MsgTo := Input_String;
          END;
          GotoXYAnsi(12,3);
          Fore(Colours.LineEditorInfoData);
          WRITEANSI(_PadRight(FastBaseHdr.MsgTo,50),true,false);
     END
     ELSE
     BEGIN
          IF ((MessageAreas.ForcedTo=0) OR (FastBaseHdr.MsgTo='')) THEN
          BEGIN
               GotoXYAnsi(12,3);
               Get_Name(30,FastBaseHdr.MsgTo,True,False);
               IF INPUT_STRING='' THEN
               BEGIN
                    Full_Editor := False;
                    DISPOSE(MsgText);
                    EXIT;
               END;
               FastBaseHdr.MsgTo := Input_String;
          END;
          GotoXYAnsi(12,3);
          Fore(Colours.LineEditorInfoData);
          WRITEANSI(FastBaseHdr.MsgTo+', ',false,false);
          IF Replying THEN Get_Name(20,AddressToString(FastBaseHdr.Orig),True,False)
                      ELSE Get_Name(20,'',True,False);
          IF INPUT_STRING='' THEN
          BEGIN
               Full_Editor := False;
               DISPOSE(MsgText);
               EXIT;
          END;
          FOR Loop := 1 TO LENGTH(Input_String) DO WRITECHAR(#08);
          StringToAddress(Input_String,DestinationAddress);
          Fore(Colours.LineEditorInfoData);
          Back(0);
          IF NodeListEntryFound(DestinationAddress)
             THEN WRITEANSI(AddressToString(DestinationAddress)+' - '+NodeListSystem,true,true)
             ELSE WRITEANSI(AddressToString(DestinationAddress)+' - Unlisted Node',true,true);
          Msg_File_Request := False;
          Msg_File_Attach  := False;
          Msg_Crash        := False;
          Msg_Hold         := False;
     END;
     GotoXYAnsi(12,4);
     IF replying=false THEN Get_String(40,'',True,false,false,False)
                       ELSE Get_String(40,FastBaseHdr.MsgSubject,True,false,false,False);
     IF INPUT_STRING='' THEN
     BEGIN
          Full_Editor := False;
          DISPOSE(MsgText);
          EXIT;
     END;
     FastBaseHdr.MsgSubject := Input_String;
     Fore(Colours.LineEditorInfoData);
     GotoXYAnsi(12,4);
     WRITEANSI(_PadRight(FastBaseHdr.MsgSubject,40),False,False);
     FillChar(MsgText^,SizeOf(MsgText^),0);
     FOR Loop := 1 TO 17 DO OnScreen[Loop]  := '';
     ReplyingInitials := '@@#!@#';
     LengthOfInitials := 6;
     MsgText^[1] := #255;
     Total       := 0;
     UserX       := 1;
     UserY       := 6;
     TopCharNum  := 1;
     Current     := 1;
     TopLine     := 1;
     FORE(Colours.ReadMSGBodyColour);
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
                ELSE  BEGIN
                           C := IsTheKeyOk(C,True);
                           IF (C<>#0) THEN GOTO JumpIn;
                      END;
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
                10  : MessageEditor_ChangeSubject;
                20  : IF MessageAreas.ForcedTo=0 THEN MessageEditor_ChangeTo(Replying);
                25  : MessageEditor_DeleteLine;
                16  : MessageEditor_TogglePrivate;
                19  : MessageEditor_Save;
                1   : MessageEditor_Abort;
                9   : MessageEditor_InsertTab;
                8   : MessageEditor_Backspace;
                21  : ImportTextFile;
                13  : BEGIN
                           IF _UpperCase(OnScreen[UserY-5])='/S' THEN
                           BEGIN
                                MessageEditor_Backspace;
                                MessageEditor_Backspace;
                                GoodMessage := True;
                                OuttaHere   := True;
                           END
                           ELSE IF _UpperCase(OnScreen[UserY-5])='/A' THEN
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
                                     INC(TopLine,17);
                                     TopCharNum := Locators[TopLine];
                                     RedrawMessage(False,True);
                                END;
                           END;
                      END;
                14  : MessageEditor_Netmail;
                5   : MessageEditor_Help;
                ELSE  BEGIN
                           C := IsTheKeyOk(C,False);
                           IF (C<>#0) THEN
                           BEGIN
                                JumpIn:
                                InsertBuffer(C);
                                {Line is too long, and needs to be wrapped}
                                IF ((LENGTH(OnScreen[UserY-5])>MaxMsgWidth) OR (UserX=80)) THEN
                                BEGIN
                                     RedrawMessage(False,False);
                                     IF NOT(IsOnScreen) THEN
                                     BEGIN
                                          GetLocators;
                                          INC(TopLine,17);
                                          TopCharNum := Locators[TopLine];
                                          RedrawMessage(False,True);
                                     END;
                                END
                                ELSE
                                BEGIN
                                     IF (UserX=LENGTH(OnScreen[UserY-5])+1) THEN
                                     BEGIN
                                          WRITECHAR(c);
                                          INC(UserX);
                                     END
                                     ELSE
                                     BEGIN
                                          WRITEANSI(_Mid(OnScreen[UserY-5],UserX,
                                                    Length(OnScreen[UserY-5])),False,False);
                                          INC(UserX);
                                          GotoXYANSI(UserX,UserY);
                                     END;
                                END;
                           END;
                      END;
                END;
           END;
     UNTIL OuttaHere;
     MessageEditor_DumpMessage;
     DISPOSE(MsgText);
     Full_Editor := GoodMessage;
     GotoXYAnsi(79,24);
END;


END.
