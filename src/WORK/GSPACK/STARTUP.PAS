{$I DEFINES.INC}
UNIT Startup;


INTERFACE


PROCEDURE FireUp;


IMPLEMENTATION


USES Globals,Crt,BsVideo,BsString,BsFile,BsTime,KeyCheck,BsLog;


PROCEDURE FireUp;
VAR  Temp : String;
     Code : Integer;
     Loop : Word;
BEGIN
     AppHeader('SGPack - Message Base Packer For Shotgun Professional');
     BaseDirectory := _UpperCase(_GetFilePath(ParamStr(0)));
     IF BaseDirectory[LENGTH(BaseDirectory)]='\' THEN Delete(BaseDirectory,LENGTH(BaseDirectory),1);
     ChDir(BaseDirectory);
     CleanAllReceived  := False;
     CleanPrivReceived := False;
     StripKludges      := False;
     OverLimit         := False;
     PurgeDays         := 0;
     TodaysDate        := _ProperDate;
     BeforeDate        := 0;
     NodeNumber        := 1;
     FOR loop := 1 TO paramcount DO
     BEGIN
          Temp := _UpperCase(paramstr(loop));
          IF Temp='-NORECV' THEN
          BEGIN
               CleanAllReceived := True;
          END
          ELSE IF _Mid(Temp,1,5)='-DAYS' THEN
          BEGIN
            Delete(Temp,1,5);
            PurgeDays := _Numeric(Temp);
          END
          ELSE IF _Mid(Temp,1,5)='-DATE' THEN
          BEGIN
            Delete(Temp,1,5);
            IF LENGTH(Temp)=10 THEN
            BEGIN
              IF ((Temp[3]='-') AND (Temp[6]='-')) THEN
              BEGIN
                BeforeDate := _PackedDate(Temp);
              END;
            END;
          END
          ELSE IF Temp='-NOPRIVRECV' THEN
          BEGIN
               CleanPrivReceived := True;
          END
          ELSE IF Temp='-STRIP' THEN
          BEGIN
               StripKludges := True;
          END
          ELSE IF Temp='-OVERLIMIT' THEN
          BEGIN
               OverLimit := True;
          END
          ELSE IF _Mid(Temp,1,2)='-N' THEN
          BEGIN
               Delete(Temp,1,2);
               NodeNumber := _Numeric(Temp);
          END
          ELSE IF ((Temp='-?') OR (Temp='?')) THEN
          BEGIN
               Window(1,1,80,25);
               GotoXY(1,7);
               TextColor(7);
               WriteLn('SGPack Command Line Options:');
               WriteLn;
               WriteLn('      SGPACK.EXE <arg> <arg> ...');
               WriteLn;
               WriteLn('             -N<xxx>           : xxx is the node number to use.');
               WriteLn('             -NORECV           : Deletes all messages marked as received.');
               WriteLn('             -NOPRIVRECV       : Deletes all private messages marked as received.');
               WriteLn('             -STRIP            : Strips all ^A kludges from messages.');
               WriteLn('             -OVERLIMIT        : Only touch areas that are over flowing.');
               WriteLn('             -DAYS<xxx>        : Kill all messages older than <xxx> days.');
               WriteLn('             -DATE<mm-dd-yyyy> : Kill all messages older than the <mmddyyyy> date.');
               TextColor(7);
               Halt;
          END;
     END;
     FastWrite('Current:',7,4,7);
     FastWrite('Progress:',7,25,7);
     FastWrite('같같같같같같같같같같같같같같같같같같같같',7,35,7);
     FastWrite(_Replicate('�',80),8,1,1);
     CheckRegistered(BaseDirectory,'SGPack');
     bsSetLog(OurAppName,'',NodeNumber);
END;


END.