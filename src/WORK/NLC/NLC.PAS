{$M 32000,0,655360}
PROGRAM ShotgunNodelistCompiler;

{$I DEFINES.INC}
USES Dos,Crt,ApTimer,FastW1,BsVideo,FMode,Version,
     Shotgun,MkFFile,BsString,BsFile,BsKeys,BsAkas;


TYPE MassiveBuffer    = Array[1..32768] Of Char;
TYPE Nodelist_Record  = RECORD
     NList            : String[60];
     IsPoint          : Boolean;
     END;
TYPE PhoneList_Record = RECORD
     Aka              : AddrType;
     Phone            : String[30];
     END;
VAR  DialTable        : Array[1..1000,1..2] Of String[20];
     PvtLists         : Array[1..100] Of Nodelist_Record;
     PhoneTrans       : Array[1..100] Of PhoneList_Record;
     NumberLists      : Word;
     DialEntries      : Word;
     DoAllZones       : Boolean;
     NumberPhones     : Word;
     CountryCode      : String[6];
     ZoneList         : Array[1..1000] Of Word;
     NumZones         : Word;
     GotConfig        : Boolean;
     ProcessList      : String;
     TheTimer         : EventTimer;
     FNodeList        : FFileObj;
     FNodeIndx        : FFileObj;
     FUserList        : FFileObj;
     CountingIndex    : Longint;
     Buf              : ^MassiveBuffer;
     MainLoop         : Word;
     MainDirInfo      : SearchRec;
     CurrentZone      : Longint;
     CurrentNet       : Longint;
     CurrentNode      : Longint;
     LastZone         : Longint;
     LastNet          : Longint;
     FProcessList     : Text;
     BigTemp          : String;
     WorkAka          : AddrType;
     NodeIndx         : _NodeIndx_Sg;
     UserList         : _UserList_Sg;
     FPrivateNodes    : File Of _PrivateNode_Sg;
     PrivateNodes     : _PrivateNode_Sg;


{_NewNodelist_SG}
{     BytesOfRecord       Word             }
{     Aka                 AddrType         }
{     Baud                Longint          }
{     Sysop               LengthByte String}
{     System              LengthByte String}
{     Phone               LengthByte String}
{     Location            LengthByte String}
{     NodelistFlags       LengthByte String}

{_NewNodeIndx_SG}
{     Aka                 AddrType         }
{     ByteOffset          Longint          }


PROCEDURE GoGetDefault;
VAR  LastList : String[12];
     LastDate : Longint;
     DirInfo  : SearchRec;

     FUNCTION IsNumeric(Str: String): Boolean;
     VAR  i: Word;
     BEGIN
          FOR i := 1 TO Length(Str) DO
          BEGIN
            IF NOT(Str[i] IN ['0'..'9']) THEN
            BEGIN
              IsNumeric := False;
              Exit;
            END;
          END;
          IsNumeric := True;
     END;

BEGIN
     LastList := '';
     LastDate := 0;
     FindFirst('NODELIST.*',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
       IF IsNumeric(_GetFileExtension(DirInfo.Name)) THEN
       BEGIN
         IF DirInfo.Time>=LastDate THEN
         BEGIN
           LastDate := DirInfo.Time;
           LastList := DirInfo.Name;
         END;
       END;
       FindNext(DirInfo);
     END;
     ProcessList := LastList;
END;


PROCEDURE ReadInCfg;
VAR  StartDialTable : Boolean;
     EndDialTable   : Boolean;
     AllDone        : Boolean;
     Work           : Word;
     Temp           : String;
     Temp2          : String;
     TFile          : Text;
BEGIN
     StartDialTable := False;
     EndDialTable   := False;
     NumberLists    := 0;
     DialEntries    := 0;
     NumberPhones   := 0;
     DoAllZones     := True;
     CountryCode    := '1-';
     NumZones       := 0;
     GotConfig      := False;
     ASSIGN(TFile,'NLC.CFG');
     {$I-}RESET(TFile);{$I+}
     IF IOResult=0 THEN
     BEGIN
       GotConfig := True;
       REPEAT
         READLN(TFile,Temp);
         Temp := _UpperCase(_RemoveLeftSpaces(Temp));
         IF _Mid(Temp,1,9)='POINTLIST' THEN
         BEGIN
           INC(NumberLists);
           PvtLists[NumberLists].NList   := _Mid(Temp,(Pos(' ',Temp)+1),Length(Temp));
           PvtLists[NumberLists].IsPoint := True;
         END
         ELSE IF _Mid(Temp,1,5)='PHONE' THEN
         BEGIN
           Delete(Temp,1,5);
           Temp := _RemoveLeftSpaces(Temp);
           Work := Pos(' ',Temp);
           Temp2 := _Mid(Temp,1,Work-1);
           Delete(Temp,1,Work);
           Temp := _RemoveLeftSpaces(Temp);
           IF ((Temp<>'') AND (Temp2<>'')) THEN
           BEGIN
             INC(NumberPhones);
             PhoneTrans[NumberPhones].Phone := Temp;
             StringToAddress(Temp2,PhoneTrans[NumberPhones].Aka);
           END;
         END
         ELSE IF _Mid(Temp,1,7)='PVTLIST' THEN
         BEGIN
           INC(NumberLists);
           PvtLists[NumberLists].NList   := _Mid(Temp,(Pos(' ',Temp)+1),Length(Temp));
           PvtLists[NumberLists].IsPoint := False;
         END
         ELSE IF _Mid(Temp,1,7)='COUNTRY' THEN
         BEGIN
           CountryCode := _Mid(Temp,(Pos(' ',Temp)+1),Length(Temp))+'-';
         END
         ELSE IF Temp='DIAL' THEN
         BEGIN
           StartDialTable := True;
         END
         ELSE IF _Mid(Temp,1,12)='INCLUDEZONES' THEN
         BEGIN
           DoAllZones := False;
           Delete(Temp,1,13);
           AllDone := False;
           REPEAT
             Work := Pos(',',Temp);
             IF (Work<>0) THEN
             BEGIN
               Temp2 := _Mid(Temp,1,Work-1);
               Delete(Temp,1,Work);
               IF ((Temp2='*') OR (Temp2='ALL')) THEN
               BEGIN
                 DoAllZones := True;
               END
               ELSE
               BEGIN
                 INC(NumZones);
                 ZoneList[NumZones] := _Numeric(Temp2);
               END;
             END
             ELSE
             BEGIN
               IF ((Temp='*') OR (Temp='ALL')) THEN
               BEGIN
                 DoAllZones := True;
               END
               ELSE
               BEGIN
                 INC(NumZones);
                 ZoneList[NumZones] := _Numeric(Temp);
               END;
               AllDone := True;
             END;
           UNTIL AllDone;
         END
         ELSE IF Temp='END' THEN
         BEGIN
           EndDialTable := True;
         END
         ELSE IF ((Temp<>'') AND (Temp[1]<>';')) THEN
         BEGIN
           IF ((StartDialTable) AND (NOT(EndDialTable))) THEN
           BEGIN
             Work := Pos(' ',Temp);
             IF Work=0 THEN
             BEGIN
               INC(DialEntries);
               DialTable[DialEntries,1] := Temp;
               DialTable[DialEntries,2] := '';
             END
             ELSE
             BEGIN
               INC(DialEntries);
               DialTable[DialEntries,1] := _Mid(Temp,1,Work-1);
               Delete(Temp,1,Work);
               Temp := _RemoveLeftSpaces(Temp);
               DialTable[DialEntries,2] := Temp;
             END;
           END;
         END;
       UNTIL EOF(TFile);
       CLOSE(TFile);
     END;
END;


PROCEDURE StartUp;
BEGIN
     FileMode := SetFileMode;
     ClrScr;
     AppHeader('NLC - Shotgun Professional Nodelist Compiler - Type II');
     GotoXY(1,9);
     ReadInCfg;
     ProcessList := ParamStr(1);
     IF ProcessList='' THEN GoGetDefault;
     IF (ProcessList<>'') THEN
     BEGIN
       INC(NumberLists);
       PvtLists[NumberLists].NList   := ProcessList;
       PvtLists[NumberLists].IsPoint := False;
     END;
END;


FUNCTION ZoneOk(Num: Word): Boolean;
VAR  Loop : Word;
BEGIN
     IF DoAllZones THEN
     BEGIN
       ZoneOk := True;
       Exit;
     END;
     FOR Loop := 1 TO NumZones DO
     BEGIN
       IF ZoneList[Loop]=Num THEN
       BEGIN
         ZoneOk := True;
         Exit;
       END;
     END;
     ZoneOk := False;
END;


FUNCTION OurCountry(InStr: String): Boolean;
BEGIN
     IF Pos(CountryCode,InStr)=1
        THEN OurCountry := True
        ELSE OurCountry := False;
END;


FUNCTION ProcessPhone(InString: String): String;
VAR  Loop2 : Word;
BEGIN
     FOR Loop2 := 1 TO DialEntries DO
     BEGIN
       IF DialTable[Loop2,1]='/' THEN
       BEGIN
         IF NOT(OurCountry(InString)) THEN
         BEGIN
           ProcessPhone := DialTable[Loop2,2]+InString;
           Exit;
         END;
       END
       ELSE
       BEGIN
         IF Pos(DialTable[Loop2,1],InString)=1 THEN
         BEGIN
           Delete(InString,1,LENGTH(DialTable[Loop2,1]));
           ProcessPhone := DialTable[Loop2,2]+InString;
           Exit;
         END;
       END;
     END;
     ProcessPhone := _UpperCase(InString);
END;


FUNCTION TranslatePhone(OrigNum: String; InAddress: AddrType): String;
VAR  Crap : Word;
BEGIN
     IF (NumberPhones>0) THEN
     BEGIN
       FOR Crap := 1 TO NumberPhones DO
       BEGIN
         IF AkasMatch(InAddress,PhoneTrans[Crap].Aka) THEN OrigNum := PhoneTrans[Crap].Phone;
       END;
     END;
     TranslatePhone := OrigNum;
END;


PROCEDURE ProcessSystem(InString: String; SystemType: Byte);
VAR  NodeSystem     : String;
     NodeSysop      : String;
     NodeLocation   : String;
     NodePhone      : String;
     NodeFlags      : String;
     NodeBaud       : Longint;
     Work           : Word;
     Crap           : Word;
     L1,L2,L3,L4,L5 : Byte;
     BytesOfRecord  : Word;
BEGIN
     CASE SystemType OF
     1:   BEGIN {Point}
            NodeIndx.Aka.Zone := CurrentZone;
            NodeIndx.Aka.Net  := CurrentNet;
            NodeIndx.Aka.Node := CurrentNode;
            Work := Pos(',',InString);
            NodeIndx.Aka.Point := _Numeric(_Mid(InString,1,Work-1));
            Delete(InString,1,Work);
          END;
     2:   BEGIN {Node}
            Work := Pos(',',InString);
            CurrentNode := _Numeric(_Mid(InString,1,Work-1));
            Delete(InString,1,Work);
            NodeIndx.Aka.Zone  := CurrentZone;
            NodeIndx.Aka.Net   := CurrentNet;
            NodeIndx.Aka.Point := 0;
            NodeIndx.Aka.Node  := CurrentNode;
          END;
     3:   BEGIN {Host/Region}
            Work := Pos(',',InString);
            CurrentNet := _Numeric(_Mid(InString,1,Work-1));
            Delete(InString,1,Work);
            NodeIndx.Aka.Zone  := CurrentZone;
            NodeIndx.Aka.Net   := CurrentNet;
            NodeIndx.Aka.Node  := CurrentNode;
            NodeIndx.Aka.Point := 0;
          END;
     4:   BEGIN {Zone}
            Work := Pos(',',InString);
            Crap := _Numeric(_Mid(InString,1,Work-1));
            CurrentZone := Crap;
            CurrentNet  := Crap;
            Delete(InString,1,Work);
            NodeIndx.Aka.Zone  := CurrentZone;
            NodeIndx.Aka.Net   := CurrentNet;
            NodeIndx.Aka.Node  := CurrentNode;
            NodeIndx.Aka.Point := 0;
          END;
     END;
     {Don't Process It If We Don't Want It}
     IF NOT(ZoneOk(NodeIndx.Aka.Zone)) THEN Exit;
     {Do The System Name}
     Work := Pos(',',InString);
     NodeSystem := _Mid(InString,1,Work-1);
     Delete(InString,1,Work);
     {Do The System Location}
     Work := Pos(',',InString);
     NodeLocation := _Mid(InString,1,Work-1);
     Delete(InString,1,Work);
     {Do The System Operator}
     Work := Pos(',',InString);
     NodeSysop := _Mid(InString,1,Work-1);
     Delete(InString,1,Work);
     {Do The System Phone Number}
     Work := Pos(',',InString);
     NodePhone := ProcessPhone(_Mid(InString,1,Work-1));
     NodePhone := TranslatePhone(NodePhone,NodeIndx.Aka);
     Delete(InString,1,Work);
     {Do The System Baud Rate}
     Work := Pos(',',InString);
     NodeBaud := _Numeric(_Mid(InString,1,Work-1));
     Delete(InString,1,Work);
     {Do Flags}
     NodeFlags := _UpperCase(InString);
     {Display Status}
     IF (LastZone<>CurrentZone) THEN
     BEGIN
       LastZone := CurrentZone;
       FastWrite(_PadRight(_String(CurrentZone),10),9,11,7);
     END;
     IF (LastNet<>CurrentNet) THEN
     BEGIN
       LastNet := CurrentNet;
       FastWrite(_PadRight(_String(CurrentNet),10),10,11,7);
     END;
     {USERLIST.SG}
     UserList.SysopName := _UpperCase(NodeSysop);
     FUserList.BlkWrite(UserList,SizeOf(UserList));
     {NODEINDX.SG}
     FNodeIndx.BlkWrite(NodeIndx,SizeOf(NodeIndx));
     {NODELIST.SG}
     L1 := Ord(NodeSysop[0])+1;
     L2 := Ord(NodeSystem[0])+1;
     L3 := Ord(NodePhone[0])+1;
     L4 := Ord(NodeLocation[0])+1;
     L5 := Ord(NodeFlags[0])+1;
     BytesOfRecord := L1+L2+L3+L4+L5+SizeOf(NodeIndx.Aka)+SizeOf(NodeBaud);
     FNodeList.BlkWrite(BytesOfRecord,SizeOf(BytesOfRecord));
     FNodeList.BlkWrite(NodeIndx.Aka,SizeOf(NodeIndx.Aka));
     FNodeList.BlkWrite(NodeBaud,SizeOf(NodeBaud));
     FNodeList.BlkWrite(NodeSysop[0],L1);
     FNodeList.BlkWrite(NodeSystem[0],L2);
     FNodeList.BlkWrite(NodePhone[0],L3);
     FNodeList.BlkWrite(NodeLocation[0],L4);
     FNodeList.BlkWrite(NodeFlags[0],L5);
     INC(NodeIndx.ByteOffSet,BytesOfRecord+2);
     INC(UserList.ByteOffSet,BytesOfRecord+2);
     INC(CountingIndex);
END;


PROCEDURE AddPrivateNodes;
BEGIN
     FastWrite(_PadRight('NODELIST.PVT',60),8,11,7);
     ASSIGN(FPrivateNodes,'NODELIST.PVT');
     RESET(FPrivateNodes);
     REPEAT
       READ(FPrivateNodes,PrivateNodes);
       CurrentZone := PrivateNodes.Aka.Zone;
       CurrentNet  := PrivateNodes.Aka.Net;
       CurrentNode := PrivateNodes.Aka.Node;
       BigTemp := _String(PrivateNodes.Aka.Point)+','+
                  PrivateNodes.System+','+
                  PrivateNodes.Location+','+
                  PrivateNodes.Sysop+','+
                  PrivateNodes.Phone+','+
                  _String(PrivateNodes.Baud)+','+
                  PrivateNodes.NodelistFlags;
       ProcessSystem(BigTemp,1);
     UNTIL EOF(FPrivateNodes);
     CLOSE(FPrivateNodes);
END;


BEGIN
     StartUp;
     FNodeList.Init(32768);
     FNodeIndx.Init(32768);
     FUserList.Init(32768);
     New(Buf);
     IF (NumberLists<>0) THEN
     BEGIN
       NewTimerSecs(TheTimer,1440*60);
       _HideCursor;
       GotoXY(1,8);  WRITE('NODELIST:');
       GotoXY(1,9);  WRITE('    ZONE:');
       GotoXY(1,10); WRITE('     NET:');
       _EraseFile('Nodelist.Sg');
       _EraseFile('NodeIndx.Sg');
       FNodeList.OpenFile('Nodelist.Sg',SetFileMode);
       FNodeIndx.OpenFile('NodeIndx.Sg',SetFileMode);
       FUserList.OpenFile('UserList.Sg',SetFileMode);
       IF _FileExists('NodeList.Pvt') THEN AddPrivateNodes;
       FOR MainLoop := 1 TO NumberLists DO
       BEGIN
         ProcessList := _UpperCase(PvtLists[MainLoop].NList);
         FindFirst(ProcessList,Anyfile-Directory-VolumeID,MainDirInfo);
         WHILE DosError=0 DO
         BEGIN
           CurrentZone := 0;
           CurrentNet  := 1;
           CurrentNode := 0;
           LastZone    := 0;
           LastNet     := 0;
           ProcessList := _GetFilePath(ProcessList)+MainDirInfo.Name;
           FastWrite(_PadRight(ProcessList,60),8,11,7);
           ASSIGN(FProcessList,ProcessList);
           SetTextBuf(FProcessList,Buf^);
           RESET(FProcessList);
           REPEAT
             READLN(FProcessList,BigTemp);
             BigTemp := _RemoveUnderScores(BigTemp);
             IF PvtLists[MainLoop].IsPoint THEN
             BEGIN
               IF BigTemp[1]=',' THEN
               BEGIN
                 Delete(BigTemp,1,1);
                 ProcessSystem(BigTemp,1);
               END
               ELSE IF _UpperCase(_Mid(BigTemp,1,4))='BOSS' THEN
               BEGIN
                 Delete(BigTemp,1,5);
                 StringToAddress(BigTemp,WorkAka);
                 CurrentZone := WorkAka.Zone;
                 CurrentNet  := WorkAka.Net;
                 CurrentNode := WorkAka.Node;
               END;
             END
             ELSE
             BEGIN
               IF BigTemp[1]=',' THEN
               BEGIN
                 Delete(BigTemp,1,1);
                 ProcessSystem(BigTemp,2);
               END
               ELSE IF _UpperCase(_Mid(BigTemp,1,3))='PVT' THEN
               BEGIN
                 Delete(BigTemp,1,4);
                 ProcessSystem(BigTemp,2);
               END
               ELSE IF _UpperCase(_Mid(BigTemp,1,3))='HUB' THEN
               BEGIN
                 Delete(BigTemp,1,4);
                 ProcessSystem(BigTemp,2);
               END
               ELSE IF _UpperCase(_Mid(BigTemp,1,4))='HOST' THEN
               BEGIN
                 CurrentNode := 0;
                 Delete(BigTemp,1,5);
                 ProcessSystem(BigTemp,3);
               END
               ELSE IF _UpperCase(_Mid(BigTemp,1,6))='REGION' THEN
               BEGIN
                 CurrentNode := 0;
                 Delete(BigTemp,1,7);
                 ProcessSystem(BigTemp,3);
               END
               ELSE IF _UpperCase(_Mid(BigTemp,1,4))='ZONE' THEN
               BEGIN
                 CurrentNode := 0;
                 Delete(BigTemp,1,5);
                 ProcessSystem(BigTemp,4);
               END;
             END;
           UNTIL EOF(FProcessList);
           CLOSE(FProcessList);
           FindNext(MainDirInfo);
         END;
       END;
       FNodeList.CloseFile;
       FNodeIndx.CloseFile;
       FUserList.CloseFile;
       GotoXY(1,12);
       TextColor(1);
       WRITELN('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
       TextColor(14);
       WRITELN(' Total Nodes Processed: '+_String(CountingIndex));
       WRITELN(' Total Elapsed Seconds: '+_String(ElapsedTimeInSecs(TheTimer)));
       TextColor(7);
       WRITELN;
       _ShowCursor;
     END
     ELSE
     BEGIN
       TextColor(12);
       WRITELN('Raw nodelist "'+ProcessList+'" was not found.');
       WRITELN('Nodelist compilation aborted.');
       TextColor(7);
       WRITELN;
     END;
     FNodeList.Done;
     FNodeIndx.Done;
     Dispose(Buf);
END.
