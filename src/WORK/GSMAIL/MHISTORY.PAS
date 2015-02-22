{$I DEFINES.INC}
UNIT MHistory;


INTERFACE


PROCEDURE ShowMailHistory;


IMPLEMENTATION


USES SaveScrn,Crt,FastW1,DrawScrn,BsMulti,Globals,BsString,BsKeys,BsVideo;


PROCEDURE ShowMailHistory;
VAR  OldXY   : Word;
     AllDone : Boolean;
     C       : Char;
     Current : Byte;
     TopLine : Byte;

     PROCEDURE RedrawHistory;
     VAR  Temp : String;
     BEGIN
          ASSIGN(FMailHistory,Shotgun_Directory+'\DATA\MAILHIST.'+_String(SimNode));
          RESET(FMailHistory);
          SEEK(FMailHistory,Current);
          READ(FMailHistory,MailHistory);
          CLOSE(FMailHistory);
          FastWrite(_PadRight(_String(MailHistory.InboundMailCalls),9),TopLine+5,30,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.CompleteInSessions),9),TopLine+6,30,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.FailedInSessions),9),TopLine+7,30,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.InboundFaxCalls),9),TopLine+9,30,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.InboundFileRequests),9),TopLine+11,30,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.ReceivedTotalBytes),9),TopLine+12,30,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.ReceivedBundleBytes),9),TopLine+13,30,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.ReceivedNetmailBytes),9),TopLine+14,30,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.ReceivedOtherBytes),9),TopLine+15,30,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.HumanCallers),9),TopLine+20,30,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.RejectedHumanCallers),9),TopLine+21,30,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.AllowedHumanCallers),9),TopLine+22,30,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.OutboundMailCalls),9),TopLine+5,68,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.CompleteOutSessions),9),TopLine+6,68,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.FailedOutSessions),9),TopLine+7,68,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.OutboundFaxCalls),9),TopLine+9,68,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.OutboundFileRequests),9),TopLine+11,68,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.SentTotalBytes),9),TopLine+12,68,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.SentBundleBytes),9),TopLine+13,68,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.SentNetmailBytes),9),TopLine+14,68,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.SentFreqBytes),9),TopLine+15,68,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(_String(MailHistory.SentOtherBytes),9),TopLine+16,68,ShotgunColours.SGMailWindowHighlight);
          CASE Current OF
          5:   Temp := 'Yesterday ['+_String(Current+1)+'/7]';
          6:   Temp := '    Today ['+_String(Current+1)+'/7]';
          ELSE Temp := '          ['+_String(Current+1)+'/7]';
          END;
          FastWrite(Temp,TopLine+1,61,ShotgunColours.SGMailWindowTitle);
     END;

BEGIN
     TopLine := Window1-12;
     AllDone := False;
     WhereXYAbs(OldXY);
     Current := 6;
     SaveScreen(1);
     _HideCursor;
     DrawWindow(2,TopLine,77,TopLine+2,'',True);
     FastWrite('MAIL HISTORY',TopLine+1,4,ShotgunColours.SGMailWindowTitle);
     DrawWindow(2,TopLine+3,39,TopLine+17,'Inbound',True);
     DrawWindow(40,TopLine+3,77,TopLine+17,'Outbound',True);
     DrawWindow(2,TopLine+18,77,TopLine+23,'BBS Users',True);
     FastWrite('Inbound Mail Calls.......',TopLine+5,4,ShotgunColours.SGMailWindowText);
     FastWrite('Complete Sessions........',TopLine+6,4,ShotgunColours.SGMailWindowText);
     FastWrite('Failed Sessions..........',TopLine+7,4,ShotgunColours.SGMailWindowText);
     FastWrite('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴',TopLine+8,3,ShotgunColours.SGMailWindowFrameLow);
     FastWrite('Inbound Fax Calls........',TopLine+9,4,ShotgunColours.SGMailWindowText);
     FastWrite('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴',TopLine+10,3,ShotgunColours.SGMailWindowFrameLow);
     FastWrite('Inbound File Requests....',TopLine+11,4,ShotgunColours.SGMailWindowText);
     FastWrite('Received Total Bytes.....',TopLine+12,4,ShotgunColours.SGMailWindowText);
     FastWrite('Received Echo Mail Bytes.',TopLine+13,4,ShotgunColours.SGMailWindowText);
     FastWrite('Received Netmail Bytes...',TopLine+14,4,ShotgunColours.SGMailWindowText);
     FastWrite('Received Other Bytes.....',TopLine+15,4,ShotgunColours.SGMailWindowText);
     FastWrite('Inbound Human Callers....',TopLine+20,4,ShotgunColours.SGMailWindowText);
     FastWrite('Rejected Human Callers...',TopLine+21,4,ShotgunColours.SGMailWindowText);
     FastWrite('Allowed Human Callers....',TopLine+22,4,ShotgunColours.SGMailWindowText);
     FastWrite('Outbound Mail Calls......',TopLine+5,42,ShotgunColours.SGMailWindowText);
     FastWrite('Completed Sessions.......',TopLine+6,42,ShotgunColours.SGMailWindowText);
     FastWrite('Failed Sessions..........',TopLine+7,42,ShotgunColours.SGMailWindowText);
     FastWrite('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴',TopLine+8,41,ShotgunColours.SGMailWindowFrameLow);
     FastWrite('Outbound Fax Calls.......',TopLine+9,42,ShotgunColours.SGMailWindowText);
     FastWrite('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴',TopLine+10,41,ShotgunColours.SGMailWindowFrameLow);
     FastWrite('Outbound File Requests...',TopLine+11,42,ShotgunColours.SGMailWindowText);
     FastWrite('Sent Total Bytes.........',TopLine+12,42,ShotgunColours.SGMailWindowText);
     FastWrite('Sent Echo Mail Bytes.....',TopLine+13,42,ShotgunColours.SGMailWindowText);
     FastWrite('Sent Netmail Bytes.......',TopLine+14,42,ShotgunColours.SGMailWindowText);
     FastWrite('Sent Freq Bytes..........',TopLine+15,42,ShotgunColours.SGMailWindowText);
     FastWrite('Sent Other Bytes.........',TopLine+16,42,ShotgunColours.SGMailWindowText);
     RedrawHistory;
     FastWrite('Last:',TopLine+20,40,ShotgunColours.SGMailWindowText);
     FastWrite('  On:',TopLine+21,40,ShotgunColours.SGMailWindowText);
     FastWrite(' Off:',TopLine+22,40,ShotgunColours.SGMailWindowText);
     FastWrite(LastUserOnline.Name,TopLine+20,46,ShotgunColours.SGMailWindowHighlight);
     FastWrite(LastUserOnline.TimeOn,TopLine+21,46,ShotgunColours.SGMailWindowHighlight);
     FastWrite(LastUserOnline.TimeOff,TopLine+22,46,ShotgunColours.SGMailWindowHighlight);
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                CASE C OF
                #0:  BEGIN
                          C := ReadKey;
                          CASE C OF
                          #75: IF (Current<>0) THEN
                               BEGIN
                                    DEC(Current);
                                    RedrawHistory;
                               END;
                          #77: IF (Current<>6) THEN
                               BEGIN
                                    INC(Current);
                                    RedrawHistory;
                               END;
                          END;
                     END;
                #27: AllDone := True;
                END;
           END
           ELSE TimeSlice;
     UNTIL AllDone;
     RestoreScreen(1);
     GotoXYAbs(OldXY);
     _ShowCursor;
     ASSIGN(FMailHistory,Shotgun_Directory+'\DATA\MAILHIST.'+_String(SimNode));
     RESET(FMailHistory);
     SEEK(FMailHistory,6);
     READ(FMailHistory,MailHistory);
     CLOSE(FMailHistory);
END;


END.