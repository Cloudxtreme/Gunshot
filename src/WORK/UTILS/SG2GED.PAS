USES Shotgun,BsString,BsAkas,BsVideo;


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
     ASSIGN(FSystemDat,'\SHOTGUN\DATA\SYSTEM.DAT');
     {$I-}RESET(FSystemDat);{$I+}
     IF IOResult=0 THEN
     BEGIN
          READ(FSystemDat,SystemDat);
          CLOSE(FSystemDat);
          Temp := 'USERNAME '+SystemDat.Sysop;
          WRITELN(TFile,Temp);
          IF (SystemDat.Alias<>'') THEN
          BEGIN
               Temp := 'USERNAME '+SystemDat.Alias;
               WRITELN(TFile,Temp);
          END;
     END;
END;


PROCEDURE DoAkas;
BEGIN
     ASSIGN(FNetwork,'\SHOTGUN\DATA\NETWORK.DAT');
     {$I-}RESET(FNetwork);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FNetwork,Network);
                Temp := 'ADDRESS '+AddressToString(Network.Net_Address)+'@'+Network.Net_Domain;
                WRITELN(TFile,Temp);
          UNTIL EOF(FNetwork);
          CLOSE(FNetwork);
     END;
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
     ASSIGN(FFile,'\SHOTGUN\MSGTAGS\'+_String(User_Number)+'.BBS');
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
     ASSIGN(FMsgSubs,'\SHOTGUN\DATA\MSGAREA.SUB');
     {$I-}RESET(FMsgSubs);{$I+}
     IF IOResult=0 THEN
     BEGIN
       REPEAT
         READ(FMsgSubs,MsgSubs);
         ASSIGN(FMsgAreas,'\SHOTGUN\DATA\MA'+ZeroPadded(MsgSubs.Sub_Num)+'.DAT');
         {$I-}RESET(FMsgAreas);{$I+}
         IF IOResult=0 THEN
         BEGIN
           WRITELN(TFile,'GROUP #'+_String(MsgSubs.Sub_Num)+':');
           REPEAT
             READ(FMsgAreas,MsgAreas);
             IF ((DoTagged) AND (NOT(IsMsgTagged(MsgAreas.AreaID)))) THEN GOTO SkipIt;
             EchoId := MsgAreas.Area_Tag;
             IF EchoId='' THEN EchoId := _String(MsgAreas.AreaId);
             Desc   := '"'+MsgAreas.Area_Name+'"';
             CASE MsgAreas.Base_Type OF
             1:   MsgBase := 'J';
             2:   MsgBase := 'M';
             3:   MsgBase := 'O';
             END;
             IF ((MsgAreas.Area_Type>=1) AND (MsgAreas.Area_Type<=3)) THEN BaseType := 'L';
             IF ((MsgAreas.Area_Type>=10) AND (MsgAreas.Area_Type<=12)) THEN BaseType := 'E';
             IF ((MsgAreas.Area_Type>=20) AND (MsgAreas.Area_Type<=22)) THEN BaseType := 'N';
             IF ((MsgAreas.Area_Type>=30) AND (MsgAreas.Area_Type<=32)) THEN BaseType := 'N';
             Loc   := MsgAreas.Dos_Name;
             AkaNo := _String(MsgAreas.Address-1);
             Temp := '  AREA '+EchoId+' '+Desc+' '+MsgBase+BaseType+' '+Loc+' '+AkaNo+' Loc';
             WRITELN(TFile,Temp);
             SkipIt:
           UNTIL EOF(FMsgAreas);
           CLOSE(FMsgAreas);
           WRITELN(TFile,'ENDGROUP');
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
     AppHeader('Shotgun To GoldED Config Utility');
     IF (Temp='-?') THEN
     BEGIN
          WRITELN;
          WRITELN('  Syntax:       SG2GED.EXE -TAGGED<usernum>');
          WRITELN;
          WRITELN('                    -TAGGED    Optionally list only user tagged areas');
          WRITELN;
          Halt;
     END;
     WRITE('Creating GOLDED.CFG in the current directory...');
     ASSIGN(TFile,'GOLDED.CFG');
     REWRITE(TFile);
     WRITELN(TFile,'BEEPNOISES NO');
     WRITELN(TFile,'AREALISTSORT GO');
     WRITELN(TFile,'AREAFILEGROUPS YES');
     DoSysopName;
     DoAkas;
     DoMessageAreas;
     CLOSE(TFile);
     WRITELN('Done!');
END.
