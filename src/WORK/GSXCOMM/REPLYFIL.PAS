{$I DEFINES.INC}
UNIT ReplyFil;


INTERFACE


PROCEDURE ProcessReplyFile(Method: Byte);


IMPLEMENTATION


USES Globals,Initials,Special,WhatLine,BsString,MiscStr,MiscMsg;


PROCEDURE ProcessReplyFile(Method: Byte);
VAR  FMsgText2     : File Of MessageTextLines;
     MsgText       : MessageTextLines;
     MsgText2      : MessageTextLines;
     Temp          : String;
     Temp1         : String;
     Temp2         : String;
     WBuffer       : Array[1..8192] Of Char;
     LastSpace     : Word;
     LastKept      : Word;
     Loop          : Word;
     AllDone       : Boolean;
     CharCount     : Word;
     LastWasBlank  : Boolean;
LABEL                OneMoreTry;

     PROCEDURE ProcessAndDump;
     VAR  Poop : Word;
     LABEL       Again;
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
                     IF (LastSpace<=MaxMsgWidth-LengthOfInitials) THEN LastKept := Poop;
                END;
                Temp := Temp+WBuffer[Poop];
                IF (LENGTH(Temp)+LengthOfInitials>MaxMsgWidth) THEN
                BEGIN
                     IF LastKept=0 THEN
                     BEGIN
                          LastWasBlank := False;
                          MsgText2.Line := _Mid(ReplyingInitials+Temp,1,MaxMsgWidth);
                          WRITE(FMsgText,MsgText2);
                          DEC(CharCount,LENGTH(Temp)-1);
                          MOVE(WBuffer[LENGTH(Temp)],WBuffer[1],CharCount);
                          GOTO Again;
                     END
                     ELSE
                     BEGIN
                          LastWasBlank := False;
                          Temp[0] := Chr(LastKept-1);
                          MsgText2.Line := ReplyingInitials+Temp;
                          WRITE(FMsgText,MsgText2);
                          DEC(CharCount,LastKept);
                          MOVE(WBuffer[LastKept+1],WBuffer[1],CharCount);
                          GOTO Again;
                     END;
                END;
                INC(Poop);
          UNTIL (Poop>CharCount);
          Temp[0] := Chr(CharCount);
          MsgText2.Line := ReplyingInitials+Temp;
          WRITE(FMsgText,MsgText2);
          LastWasBlank := False;
     END;

BEGIN
     IF ((Method=0) OR (Method=3)) THEN Exit;
     LastWasBlank := False;
     ReplyingInitials := #32+Reply_Initials(FastBaseHdr.MsgTo)+'> ';
     LengthOfInitials := LENGTH(ReplyingInitials);
     ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
     RENAME(FMsgText,NODE_Directory+'\READ.BAK');
     ASSIGN(FMsgText2,NODE_Directory+'\READ.BAK');
     ASSIGN(FMsgText,NODE_Directory+'\READ.$$$');
     REWRITE(FMsgText);
     RESET(FMsgText2);
     REPEAT
           READ(FMsgText2,MsgText);
           MsgText.Line := Remove_Special(MsgText.Line);
           MsgText.Line := Remove_Kludge(MsgText.Line);
           StripTrailingSpaces(MsgText.Line);
           OneMoreTry:
           IF MsgText.Line='' THEN
           BEGIN
                IF Method=2 THEN
                BEGIN
                     MsgText.Line := ReplyingInitials;
                     WRITE(FMsgText,MsgText);
                END
                ELSE IF NOT(LastWasBlank) THEN WRITE(FMsgText,MsgText);
                LastWasBlank := True;
           END
           ELSE IF NOT(Is_Quote(MsgText.Line)) THEN
           BEGIN
                IF LENGTH(MsgText.Line)+LengthOfInitials<=MaxMsgWidth THEN
                BEGIN
                     LastWasBlank := False;
                     MsgText.Line := ReplyingInitials+MsgText.Line;
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
                                MsgText.Line := Remove_Special(MsgText.Line);
                                MsgText.Line := Remove_Kludge(MsgText.Line);
                                StripTrailingSpaces(MsgText.Line);
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
                                IF (LENGTH(MsgText.Line)+LengthOfInitials<MaxMsgWidth-10) THEN AllDone := True;
                           END
                           ELSE AllDone := True;
                     UNTIL AllDone;
                     ProcessAndDump;
                END;
           END
           ELSE IF Method=2 THEN
           BEGIN
                Temp := ReplyingInitials+_RemoveLeftSpaces(MsgText.Line);
                MsgText.Line := _Mid(Temp,1,MaxMsgWidth);
                WRITE(FMsgText,MsgText);
                LastWasBlank := False;
           END;
     UNTIL EOF(FMsgText2);
     CLOSE(FMsgText2);
     CLOSE(FMsgText);
     ERASE(FMsgText2);
END;


END.