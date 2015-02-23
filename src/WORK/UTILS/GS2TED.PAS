USES Gunshot,BsString,BsAkas,BsVideo;


VAR  MsgAreas    : _MessageArea_Record;
     MsgSubs     : _MessageSub_Record;
     Network     : _Network_Record;
     SystemDat   : _SystemDat_Record;
     FMsgAreas   : File Of _MessageArea_Record;
     FMsgSubs    : File Of _MessageSub_Record;
     FNetwork    : File Of _Network_Record;
     FSystemDat  : File Of _SystemDat_Record;
     User_Number : Longint;
     DoTagged    : Boolean;
     Temp        : String;
     TFile       : Text;


FUNCTION ZeroPadded(Number: Word): String;
VAR  Temp : String;
     Loop : Word;
BEGIN
     Temp := _String(Number);
     FOR Loop := LENGTH(Temp) TO 5 DO Temp := '0'+Temp;
     ZeroPadded := Temp;
END;


PROCEDURE DoSysopName;
BEGIN
     ASSIGN(FSystemDat,'\GUNSHOT\DATA\SYSTEM.DAT');
     {$I-}RESET(FSystemDat);{$I+}
     IF IOResult=0 THEN
     BEGIN
          READ(FSystemDat,SystemDat);
          CLOSE(FSystemDat);
          Temp := 'Name               "'+SystemDat.Sysop+'"';
          WRITELN(TFile,Temp);
          IF (SystemDat.Alias<>'') THEN
          BEGIN
               Temp := 'Name               "'+SystemDat.Alias+'"';
               WRITELN(TFile,Temp);
          END;
     END;
END;


PROCEDURE DoAkas;
BEGIN
     ASSIGN(FNetwork,'\GUNSHOT\DATA\NETWORK.DAT');
     {$I-}RESET(FNetwork);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FNetwork,Network);
                Temp := 'Address            '+AddressToString(Network.Net_Address);
                WRITELN(TFile,Temp);
          UNTIL EOF(FNetwork);
          CLOSE(FNetwork);
     END;
END;


FUNCTION GetAka(Num: Word): String;
BEGIN
     ASSIGN(FNetwork,'\GUNSHOT\DATA\NETWORK.DAT');
     {$I-}RESET(FNetwork);{$I+}
     IF IOResult=0 THEN
     BEGIN
          IF FileSize(FNetwork)>=Num THEN
          BEGIN
               SEEK(FNetwork,Num-1);
               READ(FNetwork,Network);
               CLOSE(FNetwork);
               GetAka := AddressToString(Network.Net_Address);
               Exit;
          END;
          CLOSE(FNetwork);
     END;
     GetAka := '';
END;


FUNCTION IsMsgTagged(SearchFile: Word): Boolean;
VAR  FFile  : File;
     Tagged : Boolean;
     Loop   : Word;
     FSize  : Longint;
BEGIN
     Tagged := False;
     IF SearchFile=0 THEN
     BEGIN
          IsMsgTagged := False;
          Exit;
     END;
     ASSIGN(FFile,'\GUNSHOT\MSGTAGS\'+_String(User_Number)+'.BBS');
     {$I-}RESET(FFile,1);{$I+}
     IF IOResult=0 THEN
     BEGIN
          FSize := FileSize(FFile);
          IF (FSize>=SearchFile) THEN
          BEGIN
               SEEK(FFile,SearchFile-1);
               BlockRead(FFile,Tagged,1);
               IsMsgTagged := Tagged;
          END
          ELSE
          BEGIN
               CLOSE(FFile);
               IsMsgTagged := False;
               Exit;
          END;
          CLOSE(FFile);
     END
     ELSE IsMsgTagged := False;
END;


PROCEDURE DoMessageAreas;
VAR  EchoId   : String;
     Desc     : String;
     MsgBase  : String;
     BaseType : String;
     Loc      : String;
     AkaNo    : String;
LABEL           SkipIt;
BEGIN
     ASSIGN(FMsgSubs,'\GUNSHOT\DATA\MSGAREA.SUB');
     {$I-}RESET(FMsgSubs);{$I+}
     IF IOResult=0 THEN
     BEGIN
       REPEAT
         READ(FMsgSubs,MsgSubs);
         ASSIGN(FMsgAreas,'\GUNSHOT\DATA\MA'+ZeroPadded(MsgSubs.Sub_Num)+'.DAT');
         {$I-}RESET(FMsgAreas);{$I+}
         IF IOResult=0 THEN
         BEGIN
           REPEAT
             READ(FMsgAreas,MsgAreas);
             IF ((DoTagged) AND (NOT(IsMsgTagged(MsgAreas.AreaID)))) THEN GOTO SkipIt;
             IF ((MsgAreas.Area_Type>=1) AND (MsgAreas.Area_Type<=3))   THEN BaseType := 'LocalArea ';
             IF ((MsgAreas.Area_Type>=10) AND (MsgAreas.Area_Type<=12)) THEN BaseType := 'EchoArea ';
             IF ((MsgAreas.Area_Type>=20) AND (MsgAreas.Area_Type<=22)) THEN BaseType := 'NetArea ';
             IF ((MsgAreas.Area_Type>=30) AND (MsgAreas.Area_Type<=32)) THEN BaseType := 'NetArea ';
             Desc   := '"'+MsgAreas.Area_Name+'" ';
             EchoId := MsgAreas.Area_Tag+' ';
             IF EchoId=' ' THEN EchoId := _String(MsgAreas.AreaId)+' ';
             IF MsgAreas.Dos_Name[LENGTH(MsgAreas.Dos_Name)]='\' THEN Dec(MsgAreas.Dos_Name[0]);
             Loc := MsgAreas.Dos_Name+' ';
             CASE MsgAreas.Base_Type OF
             1:   MsgBase := '-J ';
             2:   MsgBase := '-$ ';
             ELSE MsgBase := '';
             END;
             AkaNo := GetAka(MsgAreas.Address);
             IF (AkaNo<>'') THEN AkaNo := '-P'+AkaNo;
             Temp := BaseType+Desc+EchoID+Loc+MsgBase+AkaNo;
             WRITELN(TFile,Temp);
             SkipIt:
           UNTIL EOF(FMsgAreas);
           CLOSE(FMsgAreas);
         END;
       UNTIL EOF(FMsgSubs);
       CLOSE(FMsgSubs);
     END;
END;


BEGIN
     User_Number := 0;
     DoTagged    := False;
     Temp        := _UpperCase(ParamStr(1));
     IF _Mid(Temp,1,7)='-TAGGED' THEN
     BEGIN
          Delete(Temp,1,7);
          User_Number := _Numeric(Temp);
          DoTagged    := True;
     END;
     AppHeader('Gunshot To TimEd Config Utility');
     IF (Temp='-?') THEN
     BEGIN
          WRITELN;
          WRITELN('  Syntax:       GS2TED.EXE -TAGGED<usernum>');
          WRITELN;
          WRITELN('                    -TAGGED    Optionally list only user tagged areas');
          WRITELN;
          Halt;
     END;
     WRITE('Creating TIMED.CFG in the current directory...');
     ASSIGN(TFile,'TIMED.CFG');
     REWRITE(TFile);
     DoAkas;
     DoSysopName;
     WRITELN(TFile,'ArcMailAttach      Yes');
     WRITELN(TFile,'Editor             Internal');
     WRITELN(TFile,'Hello              "Hello %fto!"');
     WRITELN(TFile,'RepHello           "%from wrote in a message to %to:"');
     WRITELN(TFile,'FollowHello        "following up a message from %from to %to:"');
     WRITELN(TFile,'AreaListSort       G');
     WRITELN(TFile,'Swap_on_Edit       Yes');
     WRITELN(TFile,'Swap_on_Shell      Yes');
     WRITELN(TFile,'Confirm_Exit       Yes');
     DoMessageAreas;
     CLOSE(TFile);
     WRITELN('Done!');
END.