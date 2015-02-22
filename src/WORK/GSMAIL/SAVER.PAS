{$I DEFINES.INC}
UNIT Saver;


INTERFACE


USES ApTimer;


VAR  SaverTimer    : EventTimer;
     SaverActive   : Boolean;
     SaverAdvance  : EventTimer;
     BannerAdvance : EventTimer;
     SaverX        : Word;
     SaverY        : Word;
     SaverCurXY    : Word;
     SaverCurB     : Byte;
     WhichSaver    : Byte;


PROCEDURE CheckSaver;
PROCEDURE KillSaver;


IMPLEMENTATION


USES BsMulti,SaveScrn,Crt,FastW1,Globals,Time,BsString,BsTime,BsKeys,BsVideo;


PROCEDURE KillSaver;
BEGIN
     IF NOT(Mailer2Info.UseBlanker) THEN Exit;
     IF SaverActive THEN
     BEGIN
          RestoreScreen(93);
          FastWrite(_PadRight(_DayOfWeek+' '+_GetPrettyDate,27),Window2+5,23,ShotgunColours.SGMailTimeDateData);
          FastWrite(_PadRight(_GetPrettyTime,8),Window2+5,9,ShotgunColours.SGMailTimeDateData);
          GotoXYAbs(SaverCurXY);
          IF NOT(DialWindowActive) THEN _ShowCursor;
          NewTimerSecs(SaverTimer,Mailer2Info.BlankerTimeout);
          SaverActive := False;
     END
     ELSE
     BEGIN
          NewTimerSecs(SaverTimer,Mailer2Info.BlankerTimeout);
          TimeSlice;
     END;
END;


PROCEDURE CheckSaver;
VAR  Loop : Word;

     PROCEDURE DrawSaver;
     VAR  ForeC   : Byte;
          BackC   : Byte;
          TheAttr : Byte;
     BEGIN
          REPEAT
                BackC := Random(7);
          UNTIL (BackC<>SaverCurB);
          SaverCurB := BackC;
          ForeC := BackC+8;
          TheAttr := (BackC*16)+ForeC;
          SaverX := Random(59)+1;
          SaverY := Random((NumLines-3))+1;
          IF MailerInfo.HandleFaxes THEN
          BEGIN
            CASE WhichSaver OF
            0:   BEGIN
                   FastWrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',SaverY,SaverX,TheAttr);
                   FastWrite('³ SGMail Waiting... ³',SaverY+1,SaverX,TheAttr);
                   FastWrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',SaverY+2,SaverX,TheAttr);
                 END;
            1:   BEGIN
                   IF ThereAreMsgs THEN
                   BEGIN
                     FastWrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',SaverY,SaverX,TheAttr);
                     FastWrite('³ YOU HAVE MAIL.... ³',SaverY+1,SaverX,TheAttr);
                     FastWrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',SaverY+2,SaverX,TheAttr);
                   END
                   ELSE
                   BEGIN
                     FastWrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',SaverY,SaverX,TheAttr);
                     FastWrite('³ No New Mail...... ³',SaverY+1,SaverX,TheAttr);
                     FastWrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',SaverY+2,SaverX,TheAttr);
                   END;
                 END;
            2:   BEGIN
                   IF ThereAreFaxes THEN
                   BEGIN
                     FastWrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',SaverY,SaverX,TheAttr);
                     FastWrite('³ YOU HAVE FAXES... ³',SaverY+1,SaverX,TheAttr);
                     FastWrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',SaverY+2,SaverX,TheAttr);
                   END
                   ELSE
                   BEGIN
                     FastWrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',SaverY,SaverX,TheAttr);
                     FastWrite('³ No New Faxes..... ³',SaverY+1,SaverX,TheAttr);
                     FastWrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',SaverY+2,SaverX,TheAttr);
                   END;
                 END;
            3:   BEGIN
                   FastWrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',SaverY,SaverX,TheAttr);
                   FastWrite('³ Mail Calls: '+_PadRight(_String(LCallers.MailCalls),6)+'³',SaverY+1,SaverX,TheAttr);
                   FastWrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',SaverY+2,SaverX,TheAttr);
                 END;
            4:   BEGIN
                   FastWrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',SaverY,SaverX,TheAttr);
                   FastWrite('³ BBS Calls: '+_PadRight(_String(LCallers.BBSCalls),7)+'³',SaverY+1,SaverX,TheAttr);
                   FastWrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',SaverY+2,SaverX,TheAttr);
                 END;
            5:   BEGIN
                   FastWrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',SaverY,SaverX,TheAttr);
                   FastWrite('³ Fax Calls: '+_PadRight(_String(LCallers.FaxCalls),7)+'³',SaverY+1,SaverX,TheAttr);
                   FastWrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',SaverY+2,SaverX,TheAttr);
                 END;
            END;
            NewTimerSecs(SaverAdvance,5);
            INC(WhichSaver);
            IF WhichSaver=6 THEN WhichSaver := 0;
          END
          ELSE
          BEGIN
            CASE WhichSaver OF
            0:   BEGIN
                   FastWrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',SaverY,SaverX,TheAttr);
                   FastWrite('³ SGMail Waiting... ³',SaverY+1,SaverX,TheAttr);
                   FastWrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',SaverY+2,SaverX,TheAttr);
                 END;
            1:   BEGIN
                   IF ThereAreMsgs THEN
                   BEGIN
                     FastWrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',SaverY,SaverX,TheAttr);
                     FastWrite('³ YOU HAVE MAIL.... ³',SaverY+1,SaverX,TheAttr);
                     FastWrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',SaverY+2,SaverX,TheAttr);
                   END
                   ELSE
                   BEGIN
                     FastWrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',SaverY,SaverX,TheAttr);
                     FastWrite('³ No New Mail...... ³',SaverY+1,SaverX,TheAttr);
                     FastWrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',SaverY+2,SaverX,TheAttr);
                   END;
                 END;
            2:   BEGIN
                   FastWrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',SaverY,SaverX,TheAttr);
                   FastWrite('³ Mail Calls: '+_PadRight(_String(LCallers.MailCalls),6)+'³',SaverY+1,SaverX,TheAttr);
                   FastWrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',SaverY+2,SaverX,TheAttr);
                 END;
            3:   BEGIN
                   FastWrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',SaverY,SaverX,TheAttr);
                   FastWrite('³ BBS Calls: '+_PadRight(_String(LCallers.BBSCalls),7)+'³',SaverY+1,SaverX,TheAttr);
                   FastWrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',SaverY+2,SaverX,TheAttr);
                 END;
            END;
            NewTimerSecs(SaverAdvance,5);
            INC(WhichSaver);
            IF WhichSaver=4 THEN WhichSaver := 0;
          END;
     END;

BEGIN
     IF NOT(Mailer2Info.UseBlanker) THEN Exit;
     IF NOT(SaverActive) THEN
     BEGIN
          IF TimerExpired(SaverTimer) THEN
          BEGIN
               WhereXYAbs(SaverCurXY);
               SaveScreen(93);
               _HideCursor;
               TextBackGround(0);
               TextColor(7);
               FOR Loop := 1 TO NumLines DO FastWrite(_PadRight('',80),Loop,1,7);
               DrawSaver;
               SaverActive := True;
          END
          ELSE TimeSlice;
     END
     ELSE
     BEGIN
          IF TimerExpired(SaverAdvance) THEN
          BEGIN
               FastWrite('                     ',SaverY,SaverX,7);
               FastWrite('                     ',SaverY+1,SaverX,7);
               FastWrite('                     ',SaverY+2,SaverX,7);
               DrawSaver;
          END
          ELSE TimeSlice;
     END;
END;


END.
