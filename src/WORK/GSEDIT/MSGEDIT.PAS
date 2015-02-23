{$I DEFINES.INC}
UNIT MsgEdit;


INTERFACE


PROCEDURE InitEditor(X1,Y1,X2,Y2: Word);
FUNCTION  FullEditor(Replying,Inserting: Boolean): Byte;


IMPLEMENTATION


USES FastW1,Globals,SaveScrn,NList,NetMail,Sema,Misc,Crt,BsMulti,
     Time,Editor,NetEdit,BsExec,DrawScrn,BsString,BsKeys,BsFile,
     Dos,BsVideo;


CONST EditWindowBack : Byte = 0;
      EditWindowFore : Byte = 7;
VAR   EditorAttr     : Byte;


FUNCTION Remove_Kludge(St: String): String;
VAR  Work : Word;
BEGIN
     {^A LINES}
     REPEAT
           Work := Pos(#1,St);
           IF (Work<>0) THEN St[Work] := '@';
     UNTIL Work=0;
     {SEEN-BY LINES}
     IF Pos('SEEN-BY',St)=1 THEN
     BEGIN
          St[5] := '@';
     END;
     {TEAR LINES}
     IF Pos('--- ',St)=1 THEN
     BEGIN
          St[2] := '+';
     END;
     {TEAR LINES}
     IF Pos(' * Origin',St)=1 THEN
     BEGIN
          St[2] := '+';
     END;
     Remove_Kludge := St;
END;


PROCEDURE ProcessReplyFile;
TYPE MessageTextLines = RECORD
     Line             : String[80];
     END;
VAR  FMsgText2        : File Of MessageTextLines;
     FMsgText         : File Of MessageTextLines;
     MsgText2         : MessageTextLines;
     MsgText          : MessageTextLines;
     Temp             : String;
     Temp1            : String;
     Temp2            : String;
     WBuffer          : Array[1..8192] Of Char;
     LastSpace        : Word;
     LastKept         : Word;
     Loop             : Word;
     AllDone          : Boolean;
     CharCount        : Word;
LABEL                   OneMoreTry;

     PROCEDURE ProcessAndDump;
     VAR  Poop : Word;
     LABEL       Again;
     BEGIN
          WITH EditorObject^ DO
          BEGIN
               DEC(CharCount);
               Again:
               IF WBuffer[1]=#32 THEN
               BEGIN
                    DEC(CharCount);
                    MOVE(WBuffer[2],WBuffer[1],CharCount);
               END;
               Temp := '';
               Poop := 1;
               LastSpace := 0;
               LastKept  := 0;
               REPEAT
                     IF WBuffer[Poop]=#32 THEN
                     BEGIN
                          LastSpace := Poop;
                          IF (LastSpace<=CharsOnScrn-2) THEN LastKept := Poop;
                     END;
                     Temp := Temp+WBuffer[Poop];
                     IF (LENGTH(Temp)+2>CharsOnScrn) THEN
                     BEGIN
                          IF LastKept=0 THEN
                          BEGIN
                               MsgText2.Line := _Mid(' >'+Temp,1,CharsOnScrn);
                               WRITE(FMsgText,MsgText2);
                               DEC(CharCount,LENGTH(Temp)-1);
                               MOVE(WBuffer[LENGTH(Temp)],WBuffer[1],CharCount);
                               GOTO Again;
                          END
                          ELSE
                          BEGIN
                               Temp[0] := Chr(LastKept-1);
                               MsgText2.Line := ' >'+Temp;
                               WRITE(FMsgText,MsgText2);
                               DEC(CharCount,LastKept);
                               MOVE(WBuffer[LastKept+1],WBuffer[1],CharCount);
                               GOTO Again;
                          END;
                     END;
                     INC(Poop);
               UNTIL (Poop>CharCount);
               Temp[0] := Chr(CharCount);
               MsgText2.Line := ' >'+Temp;
               WRITE(FMsgText,MsgText2);
          END;
     END;

BEGIN
     WITH EditorObject^ DO
     BEGIN
          ASSIGN(FMsgText,MailerInfo.OutPkts+'READ.$$$');
          RENAME(FMsgText,MailerInfo.OutPkts+'READ.BAK');
          ASSIGN(FMsgText2,MailerInfo.OutPkts+'READ.BAK');
          ASSIGN(FMsgText,MailerInfo.OutPkts+'READ.$$$');
          REWRITE(FMsgText);
          RESET(FMsgText2);
          REPEAT
                READ(FMsgText2,MsgText);
                MsgText.Line := Remove_Kludge(MsgText.Line);
                MsgText.Line := _RemoveRightSpaces(MsgText.Line);
                OneMoreTry:
                IF MsgText.Line='' THEN
                BEGIN
                     MsgText.Line := ' >';
                     WRITE(FMsgText,MsgText);
                END
                ELSE IF NOT(Is_Quote(MsgText.Line)) THEN
                BEGIN
                     IF LENGTH(MsgText.Line)+2<=CharsOnScrn THEN
                     BEGIN
                          MsgText.Line := ' >'+MsgText.Line;
                          WRITE(FMsgText,MsgText);
                     END
                     ELSE
                     BEGIN
                          AllDone   := False;
                          CharCount := 1;
                          MOVE(MsgText.Line[1],WBuffer[CharCount],LENGTH(MsgText.Line));
                          INC(CharCount,LENGTH(MsgText.Line));
                          IF (WBuffer[CharCount-1]<>#32) THEN
                          BEGIN
                               WBuffer[CharCount] := #32;
                               INC(CharCount);
                          END;
                          REPEAT
                                IF NOT(EOF(FMsgText2)) THEN
                                BEGIN
                                     READ(FMsgText2,MsgText);
                                     MsgText.Line := Remove_Kludge(MsgText.Line);
                                     MsgText.Line := _RemoveRightSpaces(MsgText.Line);
                                     IF ((MsgText.Line='') OR (Is_Quote(MsgText.Line))) THEN
                                     BEGIN
                                          ProcessAndDump;
                                          GOTO OneMoreTry;
                                     END;
                                     MOVE(MsgText.Line[1],WBuffer[CharCount],LENGTH(MsgText.Line));
                                     INC(CharCount,LENGTH(MsgText.Line));
                                     IF (WBuffer[CharCount-1]<>#32) THEN
                                     BEGIN
                                          WBuffer[CharCount] := #32;
                                          INC(CharCount);
                                     END;
                                     IF (LENGTH(MsgText.Line)+2<CharsOnScrn-10) THEN AllDone := True;
                                END
                                ELSE AllDone := True;
                          UNTIL AllDone;
                          ProcessAndDump;
                     END;
                END
                ELSE
                BEGIN
                     Temp := ' >'+_RemoveLeftSpaces(MsgText.Line);
                     MsgText.Line := _Mid(Temp,1,CharsOnScrn);
                     WRITE(FMsgText,MsgText);
                END;
          UNTIL EOF(FMsgText2);
          CLOSE(FMsgText2);
          CLOSE(FMsgText);
          ERASE(FMsgText2);
     END;
END;


PROCEDURE EditorGetLocators;
VAR  AllDone    : Boolean;
     Loop2      : Word;
     Good       : Boolean;
     LastSpace  : Word;
     Start      : Word;
     NumChars   : Byte;
     Loop       : Word;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          Loop       := 0;
          AllDone    := False;
          TotalLines := 0;
          REPEAT
                INC(Loop);
                INC(TotalLines);
                IF TotalLines=3000 THEN Exit;
                Locators[TotalLines] := Loop;
                IF BodyText[Loop]=#255 THEN
                BEGIN
                     AllDone := True;
                END
                ELSE IF (BodyText[Loop]<>#13) THEN
                BEGIN
                     Loop2     := Loop;
                     Good      := False;
                     LastSpace := Loop;
                     Start     := Loop;
                     NumChars  := 0;
                     REPEAT
                           INC(NumChars);
                           CASE Ord(BodyText[Loop2]) OF
                           13:  BEGIN
                                     Good := True;
                                     Loop := Loop2;
                                END;
                           255: BEGIN
                                     AllDone := True;
                                     Good    := True;
                                     Loop    := Loop2;
                                END;
                           ELSE BEGIN
                                     IF NumChars>CharsOnScrn THEN
                                     BEGIN
                                          Loop := LastSpace;
                                          Good := True;
                                     END
                                     ELSE IF BodyText[Loop2]=#32 THEN LastSpace := Loop2;
                                END;
                           END;
                           INC(Loop2);
                     UNTIL Good;
                END;
          UNTIL AllDone;
          Locators[TotalLines+1] := Loop+1;
     END;
END;


PROCEDURE EditorGotoXY(X,Y: Word);
VAR  WorkX : Word;
     WorkY : Word;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          LastPosX := X;
          LastPosY := Y;
          WorkX := XStart+(LastPosX-1);
          WorkY := YStart+(LastPosY-1);
          GotoXY(WorkX,WorkY);
     END;
END;


PROCEDURE EditorRedraw(JustLocateCursor,ForceRedraw: Boolean);
VAR  LineNum    : Word;
     AllDone    : Boolean;
     Loop2      : Word;
     Good       : Boolean;
     LastSpace  : Word;
     Start      : Word;
     OldScreen  : Array[1..25] Of String[88];
     OldUserY   : Word;
     WorkY      : Word;
     Loop       : Word;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          OldUserY := UserY;
          Move(OnScreen,OldScreen,SizeOf(OnScreen));
          FillChar(OnScreen,SizeOf(OnScreen),0);
          LineNum    := 1;
          Loop       := TopCharNum-1;
          AllDone    := False;
          IsOnScreen := False;
          REPEAT
                INC(Loop);
                IF BodyText[Loop]=#255 THEN
                BEGIN
                     IF Loop=Current THEN
                     BEGIN
                          UserX := 1;
                          UserY := LineNum;
                          IsOnScreen := True;
                     END;
                     AllDone := True;
                END
                ELSE IF BodyText[Loop]=#13 THEN
                BEGIN
                     IF Loop=Current THEN
                     BEGIN
                          UserX := 1;
                          UserY := LineNum;
                          IsOnScreen := True;
                     END;
                     INC(LineNum);
                     IF LineNum=(LinesOnScrn+1) THEN AllDone := True;
                END
                ELSE
                BEGIN
                     Loop2     := Loop;
                     Good      := False;
                     LastSpace := Loop;
                     Start     := Loop;
                     REPEAT
                           OnScreen[LineNum] := OnScreen[LineNum]+BodyText[Loop2];
                           IF LENGTH(OnScreen[LineNum])<=CharsOnScrn THEN
                           BEGIN
                                IF BodyText[Loop2]=#32 THEN LastSpace := Loop2;
                           END;
                           CASE Ord(BodyText[Loop2]) OF
                           13:  BEGIN
                                     IF Loop2=Current THEN
                                     BEGIN
                                          UserX := Length(OnScreen[LineNum]);
                                          UserY := LineNum;
                                          IsOnScreen := True;
                                     END;
                                     Delete(OnScreen[LineNum],Length(OnScreen[LineNum]),1);
                                     INC(LineNum);
                                     IF LineNum=(LinesOnScrn+1) THEN AllDone := True;
                                     Good := True;
                                     Loop := Loop2;
                                END;
                           255: BEGIN
                                     IF Loop2=Current THEN
                                     BEGIN
                                          UserX := Length(OnScreen[LineNum]);
                                          UserY := LineNum;
                                          IsOnScreen := True;
                                     END;
                                     Delete(OnScreen[LineNum],Length(OnScreen[LineNum]),1);
                                     AllDone := True;
                                     Good    := True;
                                     Loop    := Loop2;
                                END;
                           ELSE BEGIN
                                     IF LENGTH(OnScreen[LineNum])>CharsOnScrn THEN
                                     BEGIN
                                          OnScreen[LineNum] := '';
                                          FOR Loop2 := Start TO LastSpace DO
                                          BEGIN
                                               OnScreen[LineNum] := OnScreen[LineNum]+BodyText[Loop2];
                                               IF Loop2=Current THEN
                                               BEGIN
                                                    UserX := Length(OnScreen[LineNum]);
                                                    UserY := LineNum;
                                                    IsOnScreen := True;
                                               END;
                                          END;
                                          Loop := LastSpace;
                                          Good := True;
                                          INC(LineNum);
                                          IF LineNum=(LinesOnScrn+1) THEN AllDone := True;
                                     END
                                     ELSE
                                     BEGIN
                                          IF Loop2=Current THEN
                                          BEGIN
                                               UserX := Length(OnScreen[LineNum]);
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
               FOR Loop := 1 TO LinesOnScrn DO
               BEGIN
                    IF ((OldScreen[Loop]<>OnScreen[Loop]) OR (Loop=OldUserY) OR (ForceRedraw)) THEN
                    BEGIN
                         WorkY := YStart+(Loop-1);
                         FastWrite(_PadRight(OnScreen[Loop],CharsOnScrn),WorkY,XStart,EditorAttr);
                    END;
               END;
          END;
          EditorGotoXY(UserX,UserY);
     END;
END;


FUNCTION EditorGetKeyPress: char;
VAR  cc   : Char;
     done : Boolean;
BEGIN
     EditorObject^.AltKey := False;
     Done   := False;
     REPEAT
           IF keypressed THEN
           BEGIN
                cc := ReadKey;
                IF ORD(cc)=0 THEN
                BEGIN
                     cc := ReadKey;
                     EditorObject^.AltKey := True;
                END;
                Done := True;
           END
           ELSE TimeSlice;
     UNTIL Done;
     EditorGetKeyPress := cc;
END;


PROCEDURE EditorInsert(Ch: Char);
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF Total>=48000 THEN Exit;
          Move(BodyText[Current],BodyText[Current+1],(Total+1)-Current+1);
          BodyText[Current] := Ch;
          INC(Current);
          INC(Total);
          OnScreen[UserY] := _Mid(OnScreen[UserY],1,UserX-1)+Ch+
                             _Mid(OnScreen[UserY],UserX,LENGTH(OnScreen[UserY]));
          BodyText[48000] := #255;
     END;
END;


PROCEDURE EditorInsertTab;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF ((Total+6)>=48000) THEN Exit;
          Move(BodyText[Current],BodyText[Current+6],(Total+1)-Current+1);
          BodyText[Current]   := ' ';
          BodyText[Current+1] := ' ';
          BodyText[Current+2] := ' ';
          BodyText[Current+3] := ' ';
          BodyText[Current+4] := ' ';
          BodyText[Current+5] := ' ';
          INC(Current,6);
          INC(Total,6);
          OnScreen[UserY] := _Mid(OnScreen[UserY],1,UserX-1)+'      '+
                             _Mid(OnScreen[UserY],UserX,LENGTH(OnScreen[UserY]));
          BodyText[48000] := #255;
     END;
END;


PROCEDURE EditorDelete;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF BodyText[Current]=#255 THEN Exit;
          Move(BodyText[Current+1],BodyText[Current],Total-Current+1);
          DEC(Total);
          BodyText[48000] := #255;
          EditorRedraw(False,False);
     END;
END;


PROCEDURE EditorBackspace;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF Current=1 THEN Exit;
          Move(BodyText[Current],BodyText[Current-1],(Total+1)-Current+1);
          DEC(Total);
          DEC(Current);
          BodyText[48000] := #255;
          EditorRedraw(False,False);
          IF NOT(IsOnScreen) THEN
          BEGIN
               EditorGetLocators;
               DEC(TopLine);
               TopCharNum := Locators[TopLine];
               EditorRedraw(False,True);
          END;
     END;
END;


PROCEDURE EditorStartOfLine;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF UserX<>1 THEN
          BEGIN
               Current := Current-UserX+1;
               UserX   := 1;
               EditorGotoXY(UserX,UserY);
          END;
     END;
END;


PROCEDURE EditorEndOfLine;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF (UserX<>LENGTH(OnScreen[UserY])+1) THEN
          BEGIN
               EditorGetLocators;
               Current := Locators[TopLine+UserY]-1;
               EditorRedraw(True,False);
          END;
     END;
END;


PROCEDURE EditorDeleteLine;
VAR  NumBytes : Word;
     LStart   : Word;
     LEnd     : Word;
     Looper   : Word;
     Moving   : Word;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          EditorGetLocators;
          LStart   := Locators[TopLine+UserY-1];
          LEnd     := Locators[TopLine+UserY]-1;
          NumBytes := LEnd-LStart+1;
          Moving   := Total-LStart+1;
          FOR Looper := 1 TO NumBytes DO
          BEGIN
               IF BodyText[LStart]<>#255 THEN
               BEGIN
                    Move(BodyText[LStart+1],BodyText[LStart],Moving);
                    DEC(Total);
               END;
          END;
          BodyText[Total+1] := #255;
          EditorGetLocators;
          IF (Current>=Locators[TopLine+UserY]) THEN Current := Locators[TopLine+UserY]-1;
          EditorRedraw(False,False);
     END;
END;


PROCEDURE EditorLeftArrow;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF Current>1 THEN
          BEGIN
               Dec(Current);
               EditorRedraw(True,False);
               IF NOT(IsOnScreen) THEN
               BEGIN
                    EditorGetLocators;
                    DEC(TopLine);
                    TopCharNum := Locators[TopLine];
                    EditorRedraw(False,True);
               END;
          END;
     END;
END;


PROCEDURE EditorRightArrow;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF Current<=Total THEN
          BEGIN
               Inc(Current);
               EditorRedraw(True,False);
               IF NOT(IsOnScreen) THEN
               BEGIN
                    EditorGetLocators;
                    INC(TopLine);
                    TopCharNum := Locators[TopLine];
                    EditorRedraw(False,True);
               END;
          END;
     END;
END;


PROCEDURE EditorUpArrow;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          EditorGetLocators;
          IF TopLine+UserY-1>1 THEN
          BEGIN
               Current := Locators[TopLine+UserY-2]+UserX-1;
               IF Current>=Locators[TopLine+UserY-1] THEN Current := Locators[TopLine+UserY-1]-1;
               EditorRedraw(True,False);
               IF NOT(IsOnScreen) THEN
               BEGIN
                    DEC(TopLine);
                    TopCharNum := Locators[TopLine];
                    EditorRedraw(False,True);
               END;
          END;
     END;
END;


PROCEDURE EditorDownArrow;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          EditorGetLocators;
          IF TopLine+UserY-1<TotalLines THEN
          BEGIN
               Current := Locators[TopLine+UserY]+UserX-1;
               IF Current>=Locators[TopLine+UserY+1] THEN Current := Locators[TopLine+UserY+1]-1;
               EditorRedraw(True,False);
               IF NOT(IsOnScreen) THEN
               BEGIN
                    INC(TopLine);
                    TopCharNum := Locators[TopLine];
                    EditorRedraw(False,True);
               END;
          END;
     END;
END;


PROCEDURE EditorPageUp;
VAR  Temporary : Integer;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          EditorGetLocators;
          IF TopLine>1 THEN
          BEGIN
               Temporary := TopLine;
               Temporary := Temporary-LinesOnScrn;
               IF Temporary<1 THEN Temporary := 1;
               TopLine := Temporary;
               TopCharNum := Locators[TopLine];
               Current    := Locators[TopLine];
               EditorRedraw(False,True);
          END;
     END;
END;


PROCEDURE EditorPageDown;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          EditorGetLocators;
          IF TopLine<TotalLines THEN
          BEGIN
               INC(TopLine,LinesOnScrn);
               IF TopLine>TotalLines THEN TopLine := TotalLines;
               TopCharNum := Locators[TopLine];
               Current    := Locators[TopLine];
               EditorRedraw(False,True);
          END;
     END;
END;


PROCEDURE EditorTop;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          UserX       := 1;
          UserY       := 1;
          TopCharNum  := 1;
          Current     := 1;
          TopLine     := 1;
          EditorRedraw(False,True);
     END;
END;


PROCEDURE EditorEnd;
VAR  Good   : Boolean;
     TheTop : Word;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          EditorGetLocators;
          Good   := False;
          TheTop := TotalLines;
          IF TheTop<>TopLine THEN
          BEGIN
               TopCharNum  := Locators[TheTop];
               Current     := Locators[TheTop];
               TopLine     := TheTop;
               EditorRedraw(False,True);
          END;
     END;
END;


PROCEDURE EditorDumpFile;
VAR  AllDone    : Boolean;
     Loop2      : Word;
     Good       : Boolean;
     LastSpace  : Word;
     Start      : Word;
     FBodyText  : Text;
     Msg_Text   : String;
     Temp       : String;
     Loop       : Word;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          Loop       := 0;
          AllDone    := False;
          ASSIGN(FBodyText,MailerInfo.OutPkts+'EDITOR.$$$');
          REWRITE(FBodyText);
          Msg_Text := '';
          REPEAT
                INC(Loop);
                IF BodyText[Loop]=#255 THEN
                BEGIN
                     WRITELN(FBodyText,Msg_Text);
                     AllDone := True;
                END
                ELSE IF BodyText[Loop]=#13 THEN
                BEGIN
                     WRITELN(FBodyText,Msg_Text);
                END
                ELSE
                BEGIN
                     Loop2     := Loop;
                     Good      := False;
                     LastSpace := Loop;
                     Start     := Loop;
                     Temp      := '';
                     REPEAT
                           Temp := Temp+BodyText[Loop2];
                           IF LENGTH(Temp)<=CharsOnScrn THEN
                           BEGIN
                                IF BodyText[Loop2]=#32 THEN LastSpace := Loop2;
                           END;
                           CASE Ord(BodyText[Loop2]) OF
                           13:  BEGIN
                                     Delete(Temp,Length(Temp),1);
                                     Msg_Text := Temp;
                                     WRITELN(FBodyText,Msg_Text);
                                     Msg_Text := '';
                                     Good     := True;
                                     Loop     := Loop2;
                                END;
                           255: BEGIN
                                     Delete(Temp,Length(Temp),1);
                                     Msg_Text := Temp;
                                     WRITELN(FBodyText,Msg_Text);
                                     Msg_Text := '';
                                     AllDone  := True;
                                     Good     := True;
                                     Loop     := Loop2;
                                END;
                           ELSE BEGIN
                                     IF LENGTH(Temp)>CharsOnScrn THEN
                                     BEGIN
                                          Temp := '';
                                          FOR Loop2 := Start TO LastSpace DO Temp := Temp+BodyText[Loop2];
                                          Loop := LastSpace;
                                          Good := True;
                                          Msg_Text := Temp;
                                          WRITELN(FBodyText,Msg_Text);
                                          Msg_Text := '';
                                     END;
                                END;
                           END;
                           INC(Loop2);
                     UNTIL Good;
                END;
          UNTIL AllDone;
          CLOSE(FBodyText);
     END;
END;


PROCEDURE EditorClearWindow;
VAR  Loop : Word;
     Temp : String;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          Temp := _PadRight('',CharsOnScrn);
          FOR Loop := YStart TO (YStart+LinesOnScrn-1) DO
              FastWrite(Temp,Loop,XStart,EditorAttr);
     END;
END;


PROCEDURE InitEditor(X1,Y1,X2,Y2: Word);
BEGIN
     FillChar(EditorObject^,SizeOf(EditorObject^),0);
     WITH EditorObject^ DO
     BEGIN
          XStart      := X1;
          YStart      := Y1;
          CharsOnScrn := X2-X1+1;
          LinesOnScrn := Y2-Y1+1;
          EditorClearWindow;
          BodyText[1] := #255;
          UserX       := 1;
          UserY       := 1;
          TopCharNum  := 1;
          Current     := 1;
          TopLine     := 1;
          TotalLines  := 1;
          LastPosX    := 1;
          LastPosY    := 1;
     END;
END;


PROCEDURE EditorHelp;
VAR  C : Char;
BEGIN
     _HideCursor;
     Save_Screen;
     DrawWindow(18,7,61,23,'EDITOR KEY COMMANDS',True);
     InvertedBox(20,8,59,22);
     FastWrite('CTRL-A [/A].. Abort Message         ',9,22,27);
     FastWrite('CTRL-S [/S].. Save Message          ',10,22,27);
     FastWrite('CTRL-Y ...... Delete Current Line   ',11,22,27);
     FastWrite('CTRL-PgUp ... Top Of Message        ',12,22,27);
     FastWrite('CTRL-PgDn ... End Of Message        ',13,22,27);
     FastWrite('ALT-F ....... Message From          ',15,22,27);
     FastWrite('ALT-T ....... Message To            ',16,22,27);
     FastWrite('ALT-S ....... Message Subject/Status',17,22,27);
     FastWrite('ALT-I ....... Import Text File      ',18,22,27);
     FastWrite('F1 .......... Editor Help Screen    ',20,22,27);
     FastWrite('F2 .......... DOS Shell             ',21,22,27);
     C := ReadKey;
     IF Ord(C)=0 THEN C := ReadKey;
     Restore_Screen;
     _ShowCursor;
END;


PROCEDURE ImportTextFile;
VAR  OldX    : Word;
     OldY    : Word;
     TheFile : String;
     TFile   : Text;
     Temp    : String;
     Loop    : Word;
     Counter : Word;
BEGIN
     OldX := WhereX;
     OldY := WhereY;
     Save_Screen;
     DrawWindow(12,10,73,16,'IMPORT TEXT FILE',True);
     InvertedBox(14,11,71,15);
     TheFile := GetInput(16,13,54,63,'',True);
     IF _FileExists(TheFile) THEN
     BEGIN
          WITH EditorObject^ DO
          BEGIN
               Counter := Current;
               ASSIGN(TFile,TheFile);
               RESET(TFile);
               REPEAT
                     READLN(TFile,Temp);
                     Temp := Remove_Kludge(Temp);
                     Temp := _Mid(Temp,1,78)+#13;
                     FOR Loop := 1 TO LENGTH(Temp) DO
                     BEGIN
                          IF Total<48000 THEN
                          BEGIN
                               Move(BodyText[Counter],BodyText[Counter+1],(Total+1)-Counter+1);
                               BodyText[Counter] := Temp[Loop];
                               INC(Counter);
                               INC(Total);
                          END;
                     END;
               UNTIL EOF(TFile);
               CLOSE(TFile);
               BodyText[48000] := #255;
          END;
     END;
     Restore_Screen;
     GotoXY(OldX,OldY);
     _ShowCursor;
END;


PROCEDURE LoadUpReply(QuoteIt: Boolean);
TYPE MessageTextLines = RECORD
     Line             : String[80];
     END;
VAR  MsgText     : MessageTextLines;
     FMsgText    : File Of MessageTextLines;
     Loop        : Word;
LABEL              Skip;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF _FileExists(MailerInfo.OutPkts+'READ.$$$') THEN
          BEGIN
               Total := 1;
               IF QuoteIt THEN ProcessReplyFile;
               ASSIGN(FMsgText,MailerInfo.OutPkts+'READ.$$$');
               RESET(FMsgText);
               REPEAT
                     READ(FMsgText,MsgText);
                     IF MsgText.Line='' THEN
                     BEGIN
                          BodyText[Total] := #13;
                          INC(Total);
                     END
                     ELSE
                     BEGIN
                          IF QuoteIt THEN
                          BEGIN
                               FOR Loop := 1 TO LENGTH(MsgText.Line) DO
                               BEGIN
                                    BodyText[Total] := MsgText.Line[Loop];
                                    INC(Total);
                               END;
                               BodyText[Total] := #13;
                               INC(Total);
                          END
                          ELSE
                          BEGIN
                               {Skip Kludges That Are Added Anyways}
                               IF Pos(#1,MsgText.Line)=1 THEN GOTO Skip;
                               FOR Loop := 1 TO LENGTH(MsgText.Line) DO
                               BEGIN
                                    BodyText[Total] := MsgText.Line[Loop];
                                    INC(Total);
                               END;
                               BodyText[Total] := #13;
                               INC(Total);
                               Skip:
                          END;
                     END;
               UNTIL EOF(FMsgText);
               CLOSE(FMsgText);
               Dec(Total);
               BodyText[Total+1] := #255;
          END;
     END;
END;


FUNCTION FullEditor(Replying,Inserting: Boolean): Byte;
VAR  OuttaHere : Boolean;
     C         : Char;
     OldX      : Word;
     OldY      : Word;
LABEL            OverHere;
BEGIN
     _ShowCursor;
     EditorAttr := (EditWindowBack*16)+EditWindowFore;
     WITH EditorObject^ DO
     BEGIN
          IF Replying THEN LoadUpReply(True)
                      ELSE ReplyDomain := '';
          IF Inserting THEN LoadUpReply(False);
          OuttaHere := False;
          EditorRedraw(False,True);
          EditorGotoXY(UserX,UserY);
          REPEAT
                c := EditorGetKeyPress;
                IF AltKey THEN
                BEGIN
                     CASE ORD(c) OF
                     23   : BEGIN {Import Text File}
                                 ImportTextFile;
                                 EditorRedraw(False,True);
                            END;
                     20   : BEGIN {MsgTo}
                                 IF NOT(WriterMsgTo(FastBaseHdr.MsgTo)) THEN
                                 BEGIN
                                      FullEditor := edAbort;
                                      OuttaHere  := True;
                                 END;
                            END;
                     31   : BEGIN {MsgSubject/Status}
                                 IF NOT(WriterMsgSubject(FastBaseHdr.MsgSubject)) THEN
                                 BEGIN
                                      FullEditor := edAbort;
                                      OuttaHere  := True;
                                 END;
                            END;
                     33   : BEGIN {MsgFrom}
                                 IF NOT(WriterMsgFrom(FastBaseHdr.MsgFrom)) THEN
                                 BEGIN
                                      FullEditor := edAbort;
                                      OuttaHere  := True;
                                 END;
                            END;
                     59   : EditorHelp;
                     73   : EditorPageUp;
                     81   : EditorPageDown;
                     72   : EditorUpArrow;
                     80   : EditorDownArrow;
                     75   : EditorLeftArrow;
                     77   : EditorRightArrow;
                     71   : EditorStartOfLine;
                     79   : EditorEndOfLine;
                     83   : EditorDelete;
                     132  : EditorTop;
                     118  : EditorEnd;
                     60   : BEGIN
                                 OldX := WhereX;
                                 OldY := WhereY;
                                 Save_Screen;
                                 ClrScr;
                                 PutEnviro('PROMPT=Enter EXIT to return to GSEdit!!$_$p$g');
                                 DoExec(GetEnv('COMSPEC'),' /C '+GetEnv('COMSPEC'),SwapMethod,MailerInfo.Outpkts);
                                 ChDir(Shotgun_Directory);
                                 Restore_Screen;
                                 GotoXY(OldX,OldY);
                            END;
                     ELSE   BEGIN
                                 C := Chr(Ord(C)+128);
                                 GOTO OverHere;
                            END;
                     END;
                END
                ELSE
                BEGIN
                     OverHere:
                     CASE ORD(c) OF
                     1   : BEGIN {Abort}
                                FullEditor := edAbort;
                                OuttaHere  := True;
                           END;
                     27  : BEGIN {Abort}
                                FullEditor := edAbort;
                                OuttaHere  := True;
                           END;
                     8   : EditorBackspace;
                     9   : BEGIN {Tab}
                                EditorInsertTab;
                                EditorRedraw(False,False);
                                IF NOT(IsOnScreen) THEN
                                BEGIN
                                     EditorGetLocators;
                                     INC(TopLine);
                                     TopCharNum := Locators[TopLine];
                                     EditorRedraw(False,True);
                                END;
                           END;
                     13  : BEGIN
                                IF _UpperCase(OnScreen[UserY])='/A' THEN
                                BEGIN
                                     FullEditor := edAbort;
                                     OuttaHere  := True;
                                END
                                ELSE IF _UpperCase(OnScreen[UserY])='/S' THEN
                                BEGIN
                                     EditorBackspace;
                                     EditorBackspace;
                                     EditorDumpFile;
                                     FullEditor := edSave;
                                     OuttaHere  := True;
                                END
                                ELSE
                                BEGIN
                                     EditorInsert(C);
                                     EditorRedraw(False,False);
                                     IF NOT(IsOnScreen) THEN
                                     BEGIN
                                          EditorGetLocators;
                                          INC(TopLine);
                                          TopCharNum := Locators[TopLine];
                                          EditorRedraw(False,True);
                                     END;
                                END;
                           END;
                     19  : BEGIN {Save}
                                EditorDumpFile;
                                FullEditor := edSave;
                                OuttaHere  := True;
                           END;
                     25  : EditorDeleteLine;
                     ELSE  BEGIN
                                EditorInsert(C);
                                IF ((LENGTH(OnScreen[UserY])>CharsOnScrn) OR (UserX=80)) THEN
                                BEGIN
                                     EditorRedraw(False,False);
                                     IF NOT(IsOnScreen) THEN
                                     BEGIN
                                          EditorGetLocators;
                                          INC(TopLine);
                                          TopCharNum := Locators[TopLine];
                                          EditorRedraw(False,True);
                                     END;
                                END
                                ELSE
                                BEGIN
                                     IF (UserX=LENGTH(OnScreen[UserY])+1) THEN
                                     BEGIN
                                          FastWrite(C,UserY+(YStart-1),UserX+(XStart-1),EditorAttr);
                                          INC(UserX);
                                     END
                                     ELSE
                                     BEGIN
                                          FastWrite(_Mid(OnScreen[UserY],UserX,Length(OnScreen[UserY])),
                                                    UserY+(YStart-1),UserX+(XStart-1),EditorAttr);
                                          INC(UserX);
                                     END;
                                     EditorGotoXY(UserX,UserY);
                                END;
                           END;
                     END;
                END;
          UNTIL OuttaHere;
     END;
     _HideCursor;
END;


END.