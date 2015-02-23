{$I DEFINES.INC}
UNIT GFX;


INTERFACE


USES ApTimer,Globals,Gunshot;


TYPE Pick_Info    = RECORD
     Active       : Boolean;
     x1           : Word;
     y1           : Word;
     x2           : Word;
     y2           : Word;
     Top          : Word;
     NumItems     : Word;
     ItemsOnScrn  : Word;
     Current      : Word;
     MaxChars     : Word;
     Locator      : Word;
     Pickable     : Boolean;
     END;
TYPE Pick_List    = RECORD
     Line         : String[100];
     Pickable     : Boolean;
     TrueIndex    : Word;
     END;
TYPE FieldInfo    = RECORD
     x1           : Word;
     y1           : Word;
     x2           : Word;
     y2           : Word;
     Text         : String[70];
     CursorPos    : Byte;
     EntryType    : Byte;
     Length       : Byte;
     Active       : Boolean;
     TextBack     : Byte;
     TextEnabled  : Byte;
     TextDisabled : Byte;
     END;
TYPE Field_Record = Array[1..15] Of FieldInfo;
VAR  Fields       : Field_Record;
     NFields      : Byte;
     RawFile      : _Raw_File;
     FRawFile     : File Of _Raw_File;
     RESOURCES    : String[40];
     LastFont     : String[12];
     LastPressed  : Word;
     LastScreen   : String[60];
     UsingBuffer  : Boolean;
     FieldNum     : Word;
     ATimer       : EventTimer;
     PickList     : Pick_List;
     FPickList    : File Of Pick_List;
     PickInfo     : Pick_Info;
     ScreenNumber : Word;
     ThePickFile  : String[70];


FUNCTION  GetAck                                                  : Boolean;
FUNCTION  GetEOFAck                                               : Boolean;
FUNCTION  IsImage            (Source: String)                     : Boolean;
FUNCTION  GetStringWidth     (VarNumber: Byte)                    : Word;
FUNCTION  ConvertColourCodes (InString: String)                   : String;
PROCEDURE SystemField        (Raw: _Raw_File);
PROCEDURE RedrawScreen       (FName: String; IsTemporary: Boolean);
FUNCTION  AltToNormal        (C: Char)                            : Char;
FUNCTION  HandleKeys         (C: Char; Alt_Key: Boolean)          : Boolean;
FUNCTION  ScaleImage         (Source: String; Var W,H: Word; SetW,SetH: Word): Boolean;
PROCEDURE SaveCurrentWindow  (FName: String);
PROCEDURE LoadCurrentWindow  (FName: String);
PROCEDURE ChangeField        (Number: Word);
FUNCTION  TrueIndex          (Index: Word): Word;
PROCEDURE AddToPickList      (InString: String; Index: Word; Pickable: Boolean);
PROCEDURE NewPickList        (Pickable: Boolean);
PROCEDURE DrawText           (x,y,f,b: Byte; InString: String);
PROCEDURE FieldText          (Index: Word; InString: String);
PROCEDURE DrawChar           (x,y,f: Byte; C: Char);
PROCEDURE PlayVOCFile        (FileName: String);
PROCEDURE PlayFLIFile        (FileName: String);
PROCEDURE AppendToPickList   (InString: String);
PROCEDURE SendScreenFile     (FName: String);
PROCEDURE SendGipFile        (FName: String);
PROCEDURE SendSystemFile     (FName: String);
PROCEDURE SendVariable       (Work: Char);
PROCEDURE SetScreenNumber    (Num: Word);
PROCEDURE HandleIt           (ccc: Char);
PROCEDURE WaitForTheEnd;
PROCEDURE BeginPickList;
PROCEDURE KillPickList;
PROCEDURE SendPickRequest;
PROCEDURE SendPickableRequest;
PROCEDURE RedrawThePickList;
PROCEDURE ReselectPickList;
PROCEDURE DoPickListRedraw;


IMPLEMENTATION


USES BsString,Screens,Execute,ApCom,ApPort,Special,Carrier,Yapp,Time,
     CBVMisc,CDS,FilHeadr,MsgHeadr,TagArea,BaseInfo,MiscStr,ApMisc,
     BsLog,AllGone,Archiver,Dates,Commands,Version,BsFile,BsTime,
     BsMulti;


VAR  WorkWord    : Longint;
     NumActive   : Word;


{==========================================================================}
{                                                                          }
{    Redraws the screen                                                    }
{                                                                          }
{==========================================================================}
PROCEDURE RedrawScreen(FName: String; IsTemporary: Boolean);
BEGIN
     IF LastScreen<>FName THEN
     BEGIN
          LastScreen := FName;
          NFields    := 0;
          ASSIGN(FRawFile,FName);
          RESET(FRawFile);
          REPEAT
                READ(FRawFile,RawFile);
                CASE RawFile.Number OF
                14,15,16,17:
                     BEGIN
                          REPEAT
                                READ(FRawFile,RawFile);
                          UNTIL RawFile.Style=255;
                     END;
                18:  BEGIN {Progress Indicators}
                          ToggleInfo.x1     := RawFile.x1;
                          ToggleInfo.y1     := RawFile.y1;
                          ToggleInfo.x2     := RawFile.x2;
                          ToggleInfo.y2     := RawFile.y2;
                          ToggleInfo.Colour := RawFile.Colour1;
                     END;
                19:  SystemField(RawFile);
                21,
                28:  BEGIN {WORK AREAS}
                          PickInfo.x1 := RawFile.x1;
                          PickInfo.y1 := RawFile.y1;
                          PickInfo.x2 := RawFile.x2-21;
                          PickInfo.y2 := RawFile.y2;
                          IF RawFile.Number=28 THEN ThePickFile := RawFile.Text;
                     END;
                END;
          UNTIL EOF(FRawFile);
          CLOSE(FRawFile);
     END;
END;
{==========================================================================}
{                                                                          }
{         CONVERTS COLOUR CODES TO A USEABLE FORMAT                        }
{                                                                          }
{==========================================================================}
FUNCTION ConvertColourCodes(InString: String): String;
VAR  Work : Word;
     Loop : Word;
     Temp : String;
     SS   : String;
BEGIN
     FOR Loop := 0 TO 15 DO
     BEGIN
          SS   := _String(Loop);
          Temp := '{'+SS+'}';
          REPEAT
                Work := Pos(Temp,InString);
                IF (Work<>0) THEN
                BEGIN
                     Delete(InString,Work,LENGTH(Temp));
                     Insert(#1+CHR(Loop),InString,Work);
                END;
          UNTIL Work=0;
          IF (Loop<10) THEN Temp := '|0'+SS
                       ELSE Temp := '|'+SS;
          REPEAT
                Work := Pos(Temp,InString);
                IF (Work<>0) THEN
                BEGIN
                     Delete(InString,Work,3);
                     Insert(#1+CHR(Loop),InString,Work);
                END;
          UNTIL Work=0;
     END;
     ConvertColourCodes := InString;
END;
{==========================================================================}
{                                                                          }
{         RETURNS THE WIDTH REQUIRED FOR PROMPT BOXES                      }
{                                                                          }
{==========================================================================}
FUNCTION GetStringWidth(VarNumber: Byte): Word;
BEGIN
     CASE VarNumber OF
     1:   GetStringWidth := 30; {user's real name}
     2:   GetStringWidth := 30; {user's alias}
     3:   GetStringWidth := 20; {user's password}
     4:   GetStringWidth := 8;  {user's birthdate}
     5:   GetStringWidth := 30; {user's street address}
     6:   GetStringWidth := 30; {user's city}
     7:   GetStringWidth := 30; {user's province}
     8:   GetStringWidth := 30; {user's country}
     9:   GetStringWidth := 20; {user's postal code}
     10:  GetStringWidth := 20; {user's data phone}
     11:  GetStringWidth := 20; {user's voice phone}
     12:  GetStringWidth := 9;  {deposit bytes}
     13:  GetStringWidth := 9;  {withdraw bytes}
     14:  GetStringWidth := 4;  {deposit minutes}
     15:  GetStringWidth := 4;  {withdraw minutes}
     16:  GetStringWidth := 2;  {# file display lines}
     17:  GetStringWidth := 12; {General File Name}
     18:  GetStringWidth := 8;  {General Date}
     19:  GetStringWidth := 9;  {General Numeric}
     20:  GetStringWidth := 30; {General Proper Name}
     21:  GetStringWidth := 10; {General String 10}
     22:  GetStringWidth := 20; {General String 20}
     23:  GetStringWidth := 30; {General String 30}
     24:  GetStringWidth := 40; {General String 40}
     25:  GetStringWidth := 50; {General String 50}
     26:  GetStringWidth := 60; {General String 60}
     27:  GetStringWidth := 70; {General String 70}
     28:  GetStringWidth := 30; {Users BBS Name}
     29:  GetStringWidth := 20; {Users BBS Address}
     30:  GetStringWidth := 20; {Users BBS Phone Number}
     31:  GetStringWidth := 60; {Users Comment}
     END;
END;
{==========================================================================}
{                                                                          }
{         PLACES AN ENTRY FIELD ON THE SCREEN FOR HANDLING - DOES NOT      }
{         DRAW THE BACKGROUND, JUST THE TEXT & DEFINES THE REST.           }
{                                                                          }
{==========================================================================}
PROCEDURE SystemField(Raw: _Raw_File);
VAR  x1,y1,
     x2,y2 : Word;
BEGIN
     FieldNum := 1;
     IF NFields=15 THEN Exit;
     INC(NFields);
     IF NFields=1
        THEN Fields[NFields].Active := True
        ELSE Fields[NFields].Active := False;
     Fields[NFields].EntryType      := Raw.Colour4;
     Fields[NFields].Length         := GetStringWidth(Raw.Colour4);
     Fields[NFields].x1             := Raw.x1;
     Fields[NFields].y1             := Raw.y1;
     Fields[NFields].x2             := Raw.x1+(Fields[NFields].Length*8)+20;
     Fields[NFields].y2             := Raw.y1+20;
     Fields[NFields].TextBack       := Raw.Colour1;
     Fields[NFields].TextEnabled    := Raw.Colour2;
     Fields[NFields].TextDisabled   := Raw.Colour3;
     Fields[NFields].Text           := '';
     CASE Raw.Colour4 OF
     1:   Fields[NFields].Text := UserRecord.Name;      {user's real name}
     2:   Fields[NFields].Text := UserRecord.Alias;     {user's alias}
     3:   Fields[NFields].Text := UserRecord.Password;  {user's password}
     4:   Fields[NFields].Text := TranslateDate1(UserRecord.birth[1]+
                                  UserRecord.birth[2]+'/'+
                                  UserRecord.birth[3]+UserRecord.birth[4]+'/'+
                                  UserRecord.birth[5]+UserRecord.birth[6]); {user's birthdate}
     5:   Fields[NFields].Text := UserRecord.Street;    {user's street address}
     6:   Fields[NFields].Text := UserRecord.City;      {user's city}
     7:   Fields[NFields].Text := UserRecord.Prov;      {user's province}
     8:   Fields[NFields].Text := UserRecord.Country;   {user's country}
     9:   Fields[NFields].Text := UserRecord.Postal;    {user's postal code}
     10:  Fields[NFields].Text := UserRecord.Data;      {user's data phone}
     11:  Fields[NFields].Text := UserRecord.Voice;     {user's voice phone}
     16:  Fields[NFields].Text := _String(UserRecord.File_Lines); {# file display lines}
     18:  Fields[NFields].Text := '  /  /  ';
     28:  Fields[NFields].Text := UserRecord.BBS;       {Users BBS Name}
     29:  Fields[NFields].Text := UserRecord.BBS_Net;   {Users BBS Address}
     30:  Fields[NFields].Text := UserRecord.BBS_Phone; {Users BBS Phone Number}
     31:  Fields[NFields].Text := UserRecord.Note;      {Users Comment}
     END;
     IF (LENGTH(Fields[NFields].Text)>Fields[NFields].Length)
        THEN Fields[NFields].Text[0] := Chr(Fields[NFields].Length);
     {Special Case For Dates}
     IF ((Fields[NFields].EntryType=4) OR (Fields[NFields].EntryType=18)) THEN
     BEGIN
          Fields[NFields].CursorPos := 1;
     END
     ELSE Fields[NFields].CursorPos := Length(Fields[NFields].Text)+1;
END;


FUNCTION ScaleImage(Source: String; Var W,H: Word; SetW,SetH: Word) : Boolean;
TYPE ReturnRecord = RECORD
     W            : Word;
     H            : Word;
     Success      : Boolean;
     END;
VAR  ReturnR      : ReturnRecord;
     FReturnR     : File Of ReturnRecord;
     CommandLine  : String;
BEGIN
     IF _GetFileExtension(Source)='JPG' THEN system_prompt('',180)
                                        ELSE system_prompt('',179);
     _EraseFile(NODE_Directory+'\IMGSCALE.$$$');
     CommandLine := Bin_Directory+'\GSCALE.EXE '+NODE_Directory+' '+Source+' $$BB$$SS$$ '+_String(SetW)+' '+_String(SetH);
     ExecuteDosCommand(CommandLine);
     IF _FileExists(NODE_Directory+'\IMGSCALE.$$$') THEN
     BEGIN
          ASSIGN(FReturnR,NODE_Directory+'\IMGSCALE.$$$');
          RESET(FReturnR);
          READ(FReturnR,ReturnR);
          CLOSE(FReturnR);
          ERASE(FReturnR);
          W := ReturnR.W;
          H := ReturnR.H;
          IF ReturnR.Success
             THEN ScaleImage := True
             ELSE ScaleImage := False;
     END
     ELSE ScaleImage := False;
END;


FUNCTION IsImage(Source: String): Boolean;
VAR  CommandLine  : String;
BEGIN
     _EraseFile(NODE_Directory+'\IMGSCALE.$$$');
     CommandLine := Bin_Directory+'\GSCALE.EXE '+NODE_Directory+' '+Source+' $$BB$$SS$$ 32000 32000';
     ExecuteDosCommand(CommandLine);
     IF _FileExists(NODE_Directory+'\IMGSCALE.$$$') THEN
     BEGIN
          _EraseFile(NODE_Directory+'\IMGSCALE.$$$');
          IsImage := True
     END
     ELSE IsImage := False;
END;
{==========================================================================}
{                                                                          }
{         ADVANCES TO THE NEXT, PREVIOUS OR RANDOM FIELD                   }
{                                                                          }
{==========================================================================}
PROCEDURE ChangeField(Number: Word);
VAR  x2,y2 : Word;
     Temp  : String;
BEGIN
     IF NFields<=1 THEN Exit;
     Fields[FieldNum].Active := False;
     FieldNum := Number;
     Fields[FieldNum].Active := True;
     IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
     BEGIN
          Fields[FieldNum].CursorPos := 1;
     END
     ELSE Fields[FieldNum].CursorPos := LENGTH(Fields[FieldNum].Text)+1;
END;


FUNCTION HandleKeys(C: Char; Alt_Key: Boolean): Boolean;
VAR  ThePos : Word;
LABEL         DnArrow;

     PROCEDURE ProcessProperName;
     BEGIN
          ThePos := Fields[FieldNum].CursorPos;
          IF ThePos<>1 THEN
          BEGIN
               IF (ThePos<>2) THEN
               BEGIN
                    IF Fields[FieldNum].Text[ThePos-1]=' ' THEN C := UpCase(C);
               END;
          END
          ELSE C := UpCase(C);
          Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                                    _Mid(Fields[FieldNum].Text,ThePos,
                                    LENGTH(Fields[FieldNum].Text));
          INC(Fields[FieldNum].CursorPos);
     END;

     PROCEDURE ProcessUpperCaseString;
     BEGIN
          ThePos := Fields[FieldNum].CursorPos;
          Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+
                                    UpCase(C)+_Mid(Fields[FieldNum].Text,
                                    ThePos,LENGTH(Fields[FieldNum].Text));
          INC(Fields[FieldNum].CursorPos);
     END;

     PROCEDURE ProcessDate;
     BEGIN
          IF ((ORD(c)>47) AND (ORD(c)<58)) THEN
          BEGIN
               ThePos := Fields[FieldNum].CursorPos;
               Fields[FieldNum].Text[ThePos] := C;
               IF (Fields[FieldNum].CursorPos<>8)
                  THEN INC(Fields[FieldNum].CursorPos);
               CASE Fields[FieldNum].CursorPos OF
               3:   INC(Fields[FieldNum].CursorPos);
               6:   INC(Fields[FieldNum].CursorPos);
               END;
          END;
     END;

     PROCEDURE ProcessPhoneNumber;
     BEGIN
          IF (((ORD(c)>47) AND (ORD(c)<58)) OR (c='-')) THEN
          BEGIN
               ThePos := Fields[FieldNum].CursorPos;
               Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                                        _Mid(Fields[FieldNum].Text,ThePos,
                                        LENGTH(Fields[FieldNum].Text));
               INC(Fields[FieldNum].CursorPos);
          END;
     END;

     PROCEDURE ProcessNumeric;
     BEGIN
          IF ((ORD(c)>47) AND (ORD(c)<58)) THEN
          BEGIN
               ThePos := Fields[FieldNum].CursorPos;
               Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                                        _Mid(Fields[FieldNum].Text,ThePos,
                                        LENGTH(Fields[FieldNum].Text));
               INC(Fields[FieldNum].CursorPos);
          END;
     END;

     PROCEDURE ProcessPlainString;
     BEGIN
          ThePos := Fields[FieldNum].CursorPos;
          Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+
                                   C+_Mid(Fields[FieldNum].Text,
                                   ThePos,LENGTH(Fields[FieldNum].Text));
          INC(Fields[FieldNum].CursorPos);
     END;

     PROCEDURE ProcessFileName;
     BEGIN
          C := UpCase(C);
          IF (((ORD(c)>47) AND (ORD(c)<58)) OR ((ORD(c)>64) AND (ORD(c)<91)) OR
             (c='~') OR (c='@') OR (c='#') OR (c='$') OR (c='-') OR (c='.') OR (c='_')) THEN
          BEGIN
               ThePos := Fields[FieldNum].CursorPos;
               Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+
                                        C+_Mid(Fields[FieldNum].Text,ThePos,
                                        LENGTH(Fields[FieldNum].Text));
               INC(Fields[FieldNum].CursorPos);
          END;
     END;

     PROCEDURE LoadVariable;
     BEGIN
          CASE Fields[FieldNum].EntryType OF
          1:   UserRecord.Name       := Fields[FieldNum].Text;
          2:   UserRecord.Alias      := Fields[FieldNum].Text;
          3:   UserRecord.Password   := Fields[FieldNum].Text;
          4:   UserRecord.Birth      := Fields[FieldNum].Text[1]+Fields[FieldNum].Text[2]+
                                        Fields[FieldNum].Text[4]+Fields[FieldNum].Text[5]+
                                        Fields[FieldNum].Text[7]+Fields[FieldNum].Text[8];
          5:   UserRecord.street     := Fields[FieldNum].Text;
          6:   UserRecord.city       := Fields[FieldNum].Text;
          7:   UserRecord.prov       := Fields[FieldNum].Text;
          8:   UserRecord.country    := Fields[FieldNum].Text;
          9:   UserRecord.postal     := Fields[FieldNum].Text;
          10:  UserRecord.Data       := Fields[FieldNum].Text;
          11:  UserRecord.Voice      := Fields[FieldNum].Text;
          16:  BEGIN
                    IF ((_Numeric(Fields[FieldNum].Text)>0) AND
                       (_Numeric(Fields[FieldNum].Text)<19))
                       THEN UserRecord.file_lines := _Numeric(Fields[FieldNum].Text);
               END;
          28:  UserRecord.BBS        := Fields[FieldNum].Text;
          29:  UserRecord.BBS_Net    := Fields[FieldNum].Text;
          30:  UserRecord.BBS_Phone  := Fields[FieldNum].Text;
          31:  UserRecord.Note       := Fields[FieldNum].Text;
          END;
     END;

BEGIN
     HandleKeys := False;
     IF NFields=0 THEN Exit;
     IF Alt_Key THEN
     BEGIN {Alt Keys}
          CASE ORD(c) OF
          15,72: BEGIN {SHIFT TAB & UpArrow}
                      IF (NFields<>1) THEN
                      BEGIN
                           IF FieldNum=1 THEN ChangeField(NFields)
                                         ELSE ChangeField(FieldNum-1);
                      END;
                      HandleKeys := True;
                 END;
          80:    BEGIN {DownArrow}
                      IF (NFields<>1) THEN
                      BEGIN
                           DnArrow:
                           IF FieldNum=NFields THEN ChangeField(1)
                                               ELSE ChangeField(FieldNum+1);
                      END;
                      HandleKeys := True;
                 END;
          71:    BEGIN {HOME}
                      IF (Fields[FieldNum].CursorPos<>1) THEN
                      BEGIN
                           Fields[FieldNum].CursorPos := 1;
                      END;
                      HandleKeys := True;
                 END;
          79:    BEGIN {END}
                      IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
                      BEGIN
                           IF (Fields[FieldNum].CursorPos<>Fields[FieldNum].Length) THEN
                           BEGIN
                                Fields[FieldNum].CursorPos := Fields[FieldNum].Length;
                           END;
                      END
                      ELSE
                      BEGIN
                           IF (Fields[FieldNum].CursorPos<>LENGTH(Fields[FieldNum].Text)+1) THEN
                           BEGIN
                                Fields[FieldNum].CursorPos := LENGTH(Fields[FieldNum].Text)+1;
                           END;
                      END;
                      HandleKeys := True;
                 END;
          75:    BEGIN {Left}
                      IF (Fields[FieldNum].CursorPos>1) THEN
                      BEGIN
                           DEC(Fields[FieldNum].CursorPos);
                           IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
                           BEGIN
                                CASE Fields[FieldNum].CursorPos OF
                                3:   DEC(Fields[FieldNum].CursorPos);
                                6:   DEC(Fields[FieldNum].CursorPos);
                                END;
                           END;
                      END;
                      HandleKeys := True;
                 END;
          77:    BEGIN {Right}
                      IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
                      BEGIN
                           IF (Fields[FieldNum].CursorPos<Fields[FieldNum].Length) THEN
                           BEGIN
                                INC(Fields[FieldNum].CursorPos);
                                CASE Fields[FieldNum].CursorPos OF
                                3:   INC(Fields[FieldNum].CursorPos);
                                6:   INC(Fields[FieldNum].CursorPos);
                                END;
                           END;
                      END
                      ELSE
                      BEGIN
                           IF (Fields[FieldNum].CursorPos<LENGTH(Fields[FieldNum].Text)+1) THEN
                           BEGIN
                                INC(Fields[FieldNum].CursorPos);
                           END;
                      END;
                      HandleKeys := True;
                 END;
          83:    BEGIN {DELETE}
                      ThePos := Fields[FieldNum].CursorPos;
                      IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
                      BEGIN
                           Fields[FieldNum].Text[ThePos] := ' ';
                      END
                      ELSE
                      BEGIN
                           IF (ThePos<=LENGTH(Fields[FieldNum].Text)) THEN
                           BEGIN
                                Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+
                                                         _Mid(Fields[FieldNum].Text,ThePos+1,
                                                         LENGTH(Fields[FieldNum].Text));
                           END;
                      END;
                      LoadVariable;
                      HandleKeys := True;
                 END;
          END;
     END
     ELSE
     BEGIN
          CASE ORD(c) OF
          13,27:  ;
          8:   BEGIN {BACKSPACE}
                    ThePos := Fields[FieldNum].CursorPos;
                    IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
                    BEGIN
                         CASE ThePos OF
                         2,5,8: BEGIN
                                     Fields[FieldNum].Text[ThePos-1] := ' ';
                                     DEC(Fields[FieldNum].CursorPos);
                                END;
                         4,7:   BEGIN
                                     Fields[FieldNum].Text[ThePos-2] := ' ';
                                     DEC(Fields[FieldNum].CursorPos,2);
                                END;
                         END;
                    END
                    ELSE
                    BEGIN
                         IF ThePos>1 THEN
                         BEGIN
                              Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-2)+
                                                       _Mid(Fields[FieldNum].Text,ThePos,
                                                       LENGTH(Fields[FieldNum].Text));
                              DEC(Fields[FieldNum].CursorPos);
                         END;
                    END;
                    LoadVariable;
                    HandleKeys := True;
               END;
          9:   BEGIN {TAB}
                    IF FieldNum=NFields THEN ChangeField(1)
                                        ELSE ChangeField(FieldNum+1);
                    HandleKeys := True;
               END;
          127: BEGIN {Ctrl-Backspace}
                    IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
                    BEGIN
                         Fields[FieldNum].Text := '  /  /  ';
                         Fields[FieldNum].CursorPos := 1;
                    END
                    ELSE
                    BEGIN
                         Fields[FieldNum].Text := '';
                         Fields[FieldNum].CursorPos := 1;
                    END;
                    LoadVariable;
                    HandleKeys := True;
               END;
          ELSE IF ((Ord(c)>31) AND (Ord(c)<128)) THEN
            BEGIN
              IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
              BEGIN
                   ProcessDate;
                   IF Fields[FieldNum].EntryType=4 THEN {user's birthday}
                   BEGIN
                        LoadVariable;
                   END;
              END
              ELSE IF (LENGTH(Fields[FieldNum].Text)<Fields[FieldNum].Length) THEN
              BEGIN
                   CASE Fields[FieldNum].EntryType OF
                   1:   ProcessProperName;      {user's real name}
                   2:   ProcessProperName;      {user's alias}
                   3:   ProcessUpperCaseString; {user's password}
                   5:   ProcessProperName;      {user's street address}
                   6:   ProcessProperName;      {user's city}
                   7:   ProcessProperName;      {user's province}
                   8:   ProcessProperName;      {user's country}
                   9:   ProcessUpperCaseString; {user's postal code}
                   10:  ProcessPhoneNumber;     {user's data phone}
                   11:  ProcessPhoneNumber;     {user's voice phone}
                   12:  ProcessNumeric;         {Deposit Bytes}
                   13:  ProcessNumeric;         {Withdraw Bytes}
                   14:  ProcessNumeric;         {Deposit Minutes}
                   15:  ProcessNumeric;         {Withdraw Minutes}
                   16:  ProcessNumeric;         {# file display lines}
                   17:  ProcessFileName;
                   19:  ProcessNumeric;
                   20:  ProcessProperName;
                   21,22,23,24,25,26,27:
                        ProcessPlainString;
                   28:  ProcessProperName;
                   29:  ProcessPlainString;
                   30:  ProcessPhoneNumber;
                   31:  ProcessPlainString;
                   END;
                   LoadVariable;
              END;
              HandleKeys := True;
            END;
          END;
     END;
END;


FUNCTION AltToNormal(C: Char): Char;
BEGIN
     CASE ORD(C) OF
     30:  AltToNormal := 'A';
     48:  AltToNormal := 'B';
     46:  AltToNormal := 'C';
     32:  AltToNormal := 'D';
     18:  AltToNormal := 'E';
     33:  AltToNormal := 'F';
     34:  AltToNormal := 'G';
     35:  AltToNormal := 'H';
     23:  AltToNormal := 'I';
     36:  AltToNormal := 'J';
     37:  AltToNormal := 'K';
     38:  AltToNormal := 'L';
     50:  AltToNormal := 'M';
     49:  AltToNormal := 'N';
     24:  AltToNormal := 'O';
     25:  AltToNormal := 'P';
     16:  AltToNormal := 'Q';
     19:  AltToNormal := 'R';
     31:  AltToNormal := 'S';
     20:  AltToNormal := 'T';
     22:  AltToNormal := 'U';
     47:  AltToNormal := 'V';
     17:  AltToNormal := 'W';
     45:  AltToNormal := 'X';
     21:  AltToNormal := 'Y';
     44:  AltToNormal := 'Z';
     120: AltToNormal := '1';
     121: AltToNormal := '2';
     122: AltToNormal := '3';
     123: AltToNormal := '4';
     124: AltToNormal := '5';
     125: AltToNormal := '6';
     126: AltToNormal := '7';
     127: AltToNormal := '8';
     128: AltToNormal := '9';
     129: AltToNormal := '0';
     ELSE AltToNormal := #0;
     END;
END;


PROCEDURE SaveCurrentWindow(FName: String);
VAR  FPickInfo : File Of Pick_Info;
BEGIN
     _EraseFile(NODE_Directory+'\'+FName+'.LST');
     ASSIGN(FPickList,NODE_Directory+'\PICK.LST');
     RENAME(FPickList,NODE_Directory+'\'+FName+'.LST');
     ASSIGN(FPickInfo,NODE_Directory+'\'+FName+'.INF');
     REWRITE(FPickInfo);
     WRITE(FPickInfo,PickInfo);
     CLOSE(FPickInfo);
     PickInfo.Active := False;
     PutStringTimeout(BBSPort,#255#112+FName+#13,YappDelay);
END;


PROCEDURE LoadCurrentWindow(FName: String);
VAR  FPickInfo : File Of Pick_Info;
BEGIN
     ASSIGN(FPickInfo,NODE_Directory+'\'+FName+'.INF');
     RESET(FPickInfo);
     READ(FPickInfo,PickInfo);
     CLOSE(FPickInfo);
     ERASE(FPickInfo);
     _EraseFile(NODE_Directory+'\PICK.LST');
     ASSIGN(FPickList,NODE_Directory+'\'+FName+'.LST');
     RENAME(FPickList,NODE_Directory+'\PICK.LST');
     PutStringTimeout(BBSPort,#255#113+FName+#13,YappDelay);
END;


FUNCTION TrueIndex(Index: Word): Word;
BEGIN
     ASSIGN(FPickList,NODE_Directory+'\PICK.LST');
     RESET(FPickList);
     SEEK(FPickList,Index-1);
     READ(FPickList,PickList);
     CLOSE(FPickList);
     TrueIndex := PickList.TrueIndex;
END;


PROCEDURE BeginPickList;
VAR  BBytesSent : Word;
BEGIN
     CLOSE(FPickList);
     PutStringTimeout(BBSPort,#13,YappDelay); {TELL REMOTE TO RESUME}
     PutStringTimeout(BBSPort,#255#110#13,YappDelay);
     PutBlockTimeOut(BBSPort,PickInfo,SizeOf(PickInfo),BBytesSent,YappDelay);
END;


PROCEDURE KillPickList;
BEGIN
     _EraseFile(NODE_Directory+'\PICK.LST');
     PickInfo.Active := False;
     PutStringTimeout(BBSPort,#255#111#13,YappDelay);
END;


PROCEDURE AddToPickList(InString: String; Index: Word; Pickable: Boolean);
VAR  NumPads    : Word;
     TotSize    : Word;
     FFile      : File;
BEGIN
     INC(PickInfo.NumItems);
     TotSize := LENGTH(Process_Special(InString,True));
     IF TotSize=PickInfo.MaxChars THEN
     BEGIN
          PickList.Line := InString;
     END
     ELSE IF TotSize<PickInfo.MaxChars THEN
     BEGIN
          NumPads       := PickInfo.MaxChars-TotSize;
          PickList.Line := InString+_PadRight('',NumPads);
     END
     ELSE
     BEGIN
          NumPads       := TotSize-PickInfo.MaxChars;
          PickList.Line := _Mid(InString,1,LENGTH(InString)-NumPads);
     END;
     PickList.Pickable  := Pickable;
     PickList.TrueIndex := Index;
     WRITE(FPickList,PickList);
END;


PROCEDURE NewPickList(Pickable: Boolean);
BEGIN
     PickInfo.ItemsOnScrn := Trunc((PickInfo.y2-PickInfo.y1-10)/14);
     PickInfo.MaxChars    := Trunc((PickInfo.x2-PickInfo.x1-10)/7);
     PickInfo.Active      := True;
     PickInfo.Top         := 1;
     PickInfo.NumItems    := 0;
     PickInfo.Current     := 1;
     PickInfo.Locator     := PickInfo.y1+21;
     PickInfo.Pickable    := Pickable;
     PutStringTimeout(BBSPort,#255#100#13,YappDelay); {TELL REMOTE TO WAIT}
     ASSIGN(FPickList,NODE_Directory+'\PICK.LST');
     REWRITE(FPickList);
END;


PROCEDURE FieldText(Index: Word; InString: String);
VAR  BBytesSent : Word;
BEGIN
     IF LENGTH(InString)>Fields[Index].Length THEN
        InString := _Mid(InString,1,Fields[Index].Length);
     Fields[Index].Text := InString;
     CASE Fields[Index].EntryType OF
     4:   Fields[Index].CursorPos := 1;
     18:  Fields[Index].CursorPos := 1;
     ELSE Fields[Index].CursorPos := Length(Fields[Index].Text)+1;
     END;
     PutStringTimeout(BBSPort,#255#115#13,YappDelay);
     PutBlockTimeOut(BBSPort,Index,2,BBytesSent,YappDelay);
     PutStringTimeout(BBSPort,InString+#13,YappDelay);
END;


PROCEDURE AppendToPickList(InString: String);
VAR  NumPads    : Word;
     TotSize    : Word;
     FFile      : File;
     BBytesSent : Word;
     c          : Char;
BEGIN
     INC(PickInfo.NumItems);
     TotSize := LENGTH(Process_Special(InString,True));
     IF TotSize=PickInfo.MaxChars THEN
     BEGIN
          PickList.Line := InString;
     END
     ELSE IF TotSize<PickInfo.MaxChars THEN
     BEGIN
          NumPads       := PickInfo.MaxChars-TotSize;
          PickList.Line := InString+_PadRight('',NumPads);
     END
     ELSE
     BEGIN
          NumPads       := TotSize-PickInfo.MaxChars;
          PickList.Line := _Mid(InString,1,LENGTH(InString)-NumPads);
     END;
     PickList.Pickable  := False;
     PickList.TrueIndex := 0;
     ASSIGN(FPickList,NODE_Directory+'\PICK.LST');
     RESET(FPickList);
     SEEK(FPickList,FileSize(FPickList));
     WRITE(FPickList,PickList);
     CLOSE(FPickList);
     IF IOResult=0 THEN;
     IF (PickInfo.NumItems>PickInfo.ItemsOnScrn) THEN
     BEGIN
          IF (PickInfo.Top<PickInfo.NumItems-PickInfo.ItemsOnScrn+1)
             THEN PickInfo.Top := PickInfo.NumItems-PickInfo.ItemsOnScrn+1;
     END;
     PutStringTimeout(BBSPort,#255#117#13,YappDelay);
     PutBlockTimeOut(BBSPort,PickInfo.NumItems,2,BBytesSent,YappDelay);
     PutBlockTimeOut(BBSPort,PickInfo.Top,2,BBytesSent,YappDelay);
     c := #0;
     REPEAT
           IF CharReady(BBSPort) THEN
           BEGIN
                GetChar(BBSPort,c);
                IF c=#255 THEN SendPickRequest;
           END
           ELSE CheckForCarrier;
     UNTIL c=#252;
END;


FUNCTION GetAck: Boolean;
VAR  C   : Char;
     TTT : EventTimer;
BEGIN
     NewTimer(TTT,YappDelay);
     C := #0;
     REPEAT
           IF CharReady(BBSPort) THEN GetChar(BBSPort,C)
                                 ELSE CheckForCarrier;
     UNTIL ((c=#254) OR (c=#255) OR (TimerExpired(TTT)));
     IF C=#255 THEN GetAck := True
               ELSE GetAck := False;
END;


FUNCTION GetEOFAck: Boolean;
VAR  C   : Char;
     TTT : EventTimer;
BEGIN
     NewTimer(TTT,YappDelay);
     C := #0;
     REPEAT
           IF CharReady(BBSPort) THEN GetChar(BBSPort,C)
                                 ELSE CheckForCarrier;
     UNTIL ((c=#252) OR (TimerExpired(TTT)));
     IF C=#252 THEN GetEOFAck := True
               ELSE GetEOFAck := False;
END;


PROCEDURE SendSystemFile(FName: String);
BEGIN
     PutStringTimeout(BBSPort,#255#7+_NoPath(FName)+#13,YappDelay);
     GetAck;
     TransmitYAPP(FName,False);
     GetEOFAck;
END;


PROCEDURE SendScreenFile(FName: String);
VAR  Temp : String;
     c    : Char;
BEGIN
     PutStringTimeout(BBSPort,#255#6+_NoPath(FName)+#13,YappDelay);
     IF GetAck THEN TransmitYAPP(FName,False);
     c := #0;
     REPEAT
           IF CharReady(BBSPort) THEN
           BEGIN
                GetChar(BBSPort,c);
                IF c=#255 THEN
                BEGIN
                     GetStringTimeout(BBSPort,Temp,255,[#13],YappDelay);
                     Delete(Temp,LENGTH(Temp),1);
                     IF Temp[1]=#205
                        THEN SendVariable(Temp[2])
                        ELSE SendSystemFile(RESOURCES+Temp);
                END;
           END
           ELSE CheckForCarrier;
     UNTIL c=#252;
END;


PROCEDURE SendGipFile(FName: String);
VAR  Temp : String;
     c    : Char;
BEGIN
     PutStringTimeout(BBSPort,#255#8+_NoPath(FName)+#13,YappDelay);
     IF GetAck THEN TransmitYAPP(FName,False);
     c := #0;
     REPEAT
           IF CharReady(BBSPort) THEN
           BEGIN
                GetChar(BBSPort,c);
                IF c=#255 THEN
                BEGIN
                     GetStringTimeout(BBSPort,Temp,255,[#13],YappDelay);
                     Delete(Temp,LENGTH(Temp),1);
                     IF Temp[1]=#205
                        THEN SendVariable(Temp[2])
                        ELSE SendSystemFile(RESOURCES+Temp);
                END;
           END
           ELSE CheckForCarrier;
     UNTIL c=#252;
END;


PROCEDURE SendVariable(Work: Char);
VAR  R       : String;
     WorkNum : Byte;
     BB      : Word;
     Scrap   : Word;
     Temp    : String;
BEGIN
     R := '';
     WorkNum := Ord(Work);
     CASE WorkNum OF
     1:   R := MessageSubs.Sub_Name;
     2:   R := MessageAreas.Area_Name;
     3:   R := UserRecord.street;
     4:   R := FileSubs.Sub_Name;
     5:   R := _GetOperatingSystem;
     6:   R := FileAreas.Area_Name;
     7:   R := UserRecord.postal;
     8:   R := system_info.alias;
     9:   R := UserRecord.alias;
     10:  R := system_info.sysop;
     11:  R := UserRecord.voice;
     12:  R := UserRecord.name;
     14:  R := UserRecord.prov;
     15:  R := _GetPrettyDate;
     16:  R := UserRecord.country;
     17:  R := UserRecord.data;
     18:  R := system_info.location;
     19:  R := UserRecord.city;
     20..39:   BEGIN
                    Scrap := WorkNum-19;
                    R := GetCDName(Scrap);
               END;
     40:  R := _MMDDYYYY;
     41:  STR(UserRecord.ByteBankBalance,R);
     42:  STR(UserRecord.DLBytesRemaining,R);
     43:  STR(UserRecord.uploads,R);
     44:  STR(UserRecord.dl_total,R);
     45:  STR(UserRecord.files_uploaded,R);
     46:  STR(UserRecord.files_downloaded,R);
     47:  STR(UserAccess.daily_bytes,R);
     48:  R := system_info.bbs_name;
     49:  STR(System_Info.TBank_Trans,R);
     50:  STR(System_Info.BBank_Trans,R);
     51:  R := TimeRemainingString;
     52:  R := TranslateDate1(_UnpackedDate(UserRecord.Sub_Expiry));
     53:  R := TranslateDate1(_Mid(UserRecord.birth,1,2)+'-'+_Mid(UserRecord.birth,3,4)+'-'+_Mid(UserRecord.birth,5,6));
     54:  IF UserAccess.NoFileRatio=1
             THEN R := 'None'
             ELSE R := '1:'+_String(UserAccess.Byte_Ratio);
     55:  R := _GetPrettyTime;
     56:  R := _String(CurrentMessageArea);
     57:  R := _String(CurrentFileArea);
     58:  R := LongToFormattedTime(GetCBVStart);
     59:  R := LongToFormattedTime(GetCBVEnd);
     60:  R := COMString;
     61:  R := BaudString;
     62:  R := NodeString;
     63:  R := _String(CurrentFileSub);
     64:  BEGIN
               IF NOT(DidHeader) THEN
               BEGIN
                    header(CurrentFileSub,CurrentFileArea,True);
                    DidHeader := True;
               END;
               IF IsFileTagged(FileAreas.AreaId)
                  THEN R := Chr(254)
                  ELSE R := ' ';
          END;
     65:  R := _String(CurrentMessageSub);
     66:  BEGIN
               IF NOT(DidHeader2) THEN
               BEGIN
                    header2(CurrentMessageSub,CurrentMessageArea,True);
                    DidHeader2 := True;
               END;
               IF IsMsgTagged(MessageAreas.AreaId)
                  THEN R := Chr(254)
                  ELSE R := ' ';
          END;
     67:  BEGIN
               IF NOT(DidHeader2) THEN
               BEGIN
                    header2(CurrentMessageSub,CurrentMessageArea,True);
                    DidHeader2 := True;
               END;
               IF NOT(DidMsgInfo) THEN
               BEGIN
                    JamBase_MessageBaseInfo(MessageAreas.Dos_Name);
                    DidMsgInfo := True;
               END;
               IF UserLastReadMSG<HighMSGNumber
                  THEN R := Chr(254)
                  ELSE R := ' ';
          END;
     68:  BEGIN
               IF NOT(DidHeader2) THEN
               BEGIN
                    header2(CurrentMessageSub,CurrentMessageArea,True);
                    DidHeader2 := True;
               END;
               IF NOT(DidMsgInfo) THEN
               BEGIN
                    JamBase_MessageBaseInfo(MessageAreas.Dos_Name);
                    DidMsgInfo := True;
               END;
               R := _String(TotalMessages);
          END;
     69:  IF UserRecord.sex=1
             THEN R := GetCommandString('MISC',3)
             ELSE R := GetCommandString('MISC',4);
     70:  IF UserRecord.PageFlag=1
             THEN R := GetCommandString('MISC',1)
             ELSE R := GetCommandString('MISC',2);
     71:  R := _String(UserRecord.file_lines);
     72:  R := ComString;
     73:  IF EventMinutes=32000
             THEN R := 'None'
             ELSE R := _String(Round(RemainingTimeInSecs(EventTicker)/60));
     75:  R := GetCommandString('MISC',1);
     76:  R := GetCommandString('MISC',1);
     77:  IF UserRecord.IBM=1
             THEN R := GetCommandString('MISC',1)
             ELSE R := GetCommandString('MISC',2);
     78:  R := GetCommandString('MISC',1);
     79:  IF UserRecord.seperator=1
             THEN R := GetCommandString('MISC',1)
             ELSE R := GetCommandString('MISC',2);
     80:  STR(MinutesRemaining,R);
     81:  STR(MinutesOn,R);
     82:  STR(Trunc(UserRecord.SecondsInBank/60),R);
     83:  R := UserRecord.BBS;
     84:  R := UserRecord.BBS_Net;
     85:  R := UserRecord.BBS_Phone;
     86:  R := UserRecord.Note;
     87..106:  BEGIN
                    Scrap := WorkNum-86;
                    IF IsCDOnline(Scrap) THEN R := 'Online'
                                         ELSE R := 'Offline';
               END;
     107: R := UserRecord.password;
     108: R := GunshotVersion;
     109: R := UsersFirstName;
     110: R := UsersLastName;
     111: STR(totals.total_calls,R);
     112: STR(totals.today_calls,R);
     113: STR(UserRecord.Security,R);
     114: BEGIN
               GetStringTimeout(BBSPort,Temp,255,[#13],YappDelay);
               Delete(Temp,LENGTH(Temp),1);
               Scrap := _Numeric(Temp);
               R := GetCDName(Scrap);
          END;
     115: BEGIN
               GetStringTimeout(BBSPort,Temp,255,[#13],YappDelay);
               Delete(Temp,LENGTH(Temp),1);
               Scrap := _Numeric(Temp);
               IF IsCDOnline(Scrap) THEN R := 'Online'
                                    ELSE R := 'Offline';
          END;
     116: STR(UserAccess.SubCalendarDays,R);
     117: STR(UserAccess.SubCallDays,R);
     118: STR(UserAccess.SubMinutes,R);
     119: STR(UserRecord.SubCalendarDaysUsed,R);
     120: STR(UserRecord.SubCallDaysUsed,R);
     121: STR(UserRecord.SubMinutesUsed,R);
     122: BEGIN
               CASE UserRecord.SubModel OF
               0:   R := 'None';
               1:   R := 'Calendar Day Expiry';
               2:   R := 'Call Day Expiry';
               3:   R := 'Minutes Used Expiry';
               ELSE R := 'Calendar Date Expiry';
               END;
          END;
     123: IF UserRecord.UserList=1
             THEN R := GetCommandString('MISC',1)
             ELSE R := GetCommandString('MISC',2);
     124: R := GetArcName(UserRecord.DefaultArchiver);
     125: BEGIN
               CASE UserRecord.DefaultProtocol OF
               1:   R := 'ZModem';
               2:   R := 'XModem';
               3:   R := 'XModem1K';
               4:   R := 'YModem';
               5:   R := 'YModemG';
               ELSE R := 'None';
               END;
          END;
     126: BEGIN
               CASE UserRecord.DefaultQuote OF
               1:   R := 'New Only';
               2:   R := 'All Text';
               3:   R := 'No Quote';
               ELSE R := 'None';
               END;
          END;
     END;
     R := R+#13;
     PutBlockTimeout(BBSPort,R[1],Ord(R[0]),BB,YappDelay);
END;


PROCEDURE HandleIt(ccc: Char);
VAR  Work : Word;
     BB   : Word;
BEGIN
     CASE Ord(ccc) OF
     250: BEGIN
               GetBlockTimeOut(BBSPort,Work,2,BB,[],YappDelay);
               PickInfo.Current := Work;
          END;
     251: BEGIN
               GetBlockTimeOut(BBSPort,Work,2,BB,[],YappDelay);
               ChangeField(Work);
          END;
     252: BEGIN
               GetBlockTimeOut(BBSPort,Work,2,BB,[],YappDelay);
               Fields[FieldNum].CursorPos := Work;
          END;
     END;
END;


PROCEDURE SendPickRequest;
VAR  PStart : Word;
     PEnd   : Word;
     BB     : Word;
     Loop   : Word;
BEGIN
     GetBlockTimeOut(BBSPort,PStart,2,BB,[],YappDelay);
     GetBlockTimeOut(BBSPort,PEnd,2,BB,[],YappDelay);
     ASSIGN(FPickList,NODE_Directory+'\PICK.LST');
     RESET(FPickList);
     SEEK(FPickList,PStart-1);
     FOR Loop := PStart TO PEnd DO
     BEGIN
          READ(FPickList,PickList);
          IF PickList.Line='' THEN PickList.Line := ' ';
          PutBlockTimeout(BBSPort,PickList.Pickable,1,BB,YappDelay);
          PutBlockTimeout(BBSPort,PickList.Line[0],Ord(PickList.Line[0])+1,BB,YappDelay);
     END;
     CLOSE(FPickList);
END;


PROCEDURE SendPickableRequest;
VAR  PStart : Word;
     BB     : Word;
BEGIN
     GetBlockTimeOut(BBSPort,PStart,2,BB,[],YappDelay);
     ASSIGN(FPickList,NODE_Directory+'\PICK.LST');
     RESET(FPickList);
     SEEK(FPickList,PStart-1);
     READ(FPickList,PickList);
     CLOSE(FPickList);
     PutBlockTimeOut(BBSPort,PickList.Pickable,1,BB,YappDelay);
END;


PROCEDURE DoPickListRedraw;
VAR  c : Char;
BEGIN
     PutStringTimeout(BBSPort,#255#116#13,YappDelay);
     c := #0;
     REPEAT
           IF CharReady(BBSPort) THEN
           BEGIN
                GetChar(BBSPort,c);
                IF c=#255 THEN SendPickRequest;
           END
           ELSE CheckForCarrier;
     UNTIL c=#252;
END;


PROCEDURE DrawChar(x,y,f: Byte; C: Char);
VAR  BB : Word;
     TT : Array[1..3] Of Byte;
BEGIN
     TT[1] := x;
     TT[2] := y;
     TT[3] := f;
     PutStringTimeout(BBSPort,#255#121+C+#13,YappDelay);
     PutBlockTimeOut(BBSPort,TT[1],3,BB,YappDelay);
END;


PROCEDURE DrawText(x,y,f,b: Byte; InString: String);
VAR  BB : Word;
     TT : Array[1..4] Of Byte;
BEGIN
     TT[1] := x;
     TT[2] := y;
     TT[3] := f;
     TT[4] := b;
     PutStringTimeout(BBSPort,#255#122+InString+#13,YappDelay);
     PutBlockTimeOut(BBSPort,TT[1],4,BB,YappDelay);
END;


PROCEDURE RedrawThePickList;
BEGIN
     PutStringTimeout(BBSPort,#255#116#13,YappDelay);
END;


PROCEDURE ReselectPickList;
BEGIN
     PutStringTimeout(BBSPort,#255#131#13,YappDelay);
END;


PROCEDURE SetScreenNumber(Num: Word);
BEGIN
     ScreenNumber := Num;
     PutStringTimeout(BBSPort,#255#132+_String(ScreenNumber)+#13,YappDelay);
END;


PROCEDURE WaitForTheEnd;
VAR  C         : Char;
     TimerInfo : EventTimer;
BEGIN
     NewTimerSecs(TimerInfo,system_info.Sys_Idle);
     C := #0;
     REPEAT
           IF CharReady(BBSPort) THEN GetChar(BBSPort,C)
                                 ELSE CheckForCarrier;
     UNTIL ((c=#252) OR (TimerExpired(TimerInfo)));
     IF TimerExpired(TimerInfo) THEN
     BEGIN
          DisplayGraphicFile('TIMEOUT',false,True,True);
          Dispatcher(4);
     END;
END;


PROCEDURE PlayFLIFile(FileName: String);
VAR  Work      : Longint;
     Loop      : Word;
     BytesRead : Word;
     FLIFile   : String;
     FFile     : File;
     BBuffer   : Array[1..8192] Of Byte;

     FUNCTION Byte2Hex(numb : Byte): String;
     CONST HexChars : Array[0..15] of Char = '0123456789ABCDEF';
     BEGIN
          Byte2Hex[0] := #2;
          Byte2Hex[1] := HexChars[numb shr  4];
          Byte2Hex[2] := HexChars[numb and 15];
     END;

     FUNCTION Numb2Hex(numb: Word): String;
     BEGIN
          Numb2Hex := Byte2Hex(hi(numb))+Byte2Hex(lo(numb));
     END;

     FUNCTION Long2Hex(L: LongInt): String;
     BEGIN
          Long2Hex := Numb2Hex(L shr 16) + Numb2Hex(L);
     END;

BEGIN
     Work := UpdateCrc32(0,$FFFFFFFF);
     ASSIGN(FFile,FileName);
     RESET(FFile,1);
     REPEAT
           BlockRead(FFile,BBuffer,SizeOf(BBuffer),BytesRead);
           FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(BBuffer[Loop],Work);
     UNTIL EOF(FFile);
     CLOSE(FFile);
     FLIFile := Long2Hex(Work)+'.FLI';
     IF _FileExists(RESOURCES+FLIFile) THEN
     BEGIN
          bsWriteLog('Viewing FLI file: '+_NoPath(FileName),True);
          PutStringTimeout(BBSPort,#255#135+FLIFile+#13,YappDelay);
          IF GetAck THEN TransmitYAPP(RESOURCES+FLIFile,True);
          WaitForTheEnd;
     END;
END;


PROCEDURE PlayVOCFile(FileName: String);
VAR  Work      : Longint;
     Loop      : Word;
     BytesRead : Word;
     VOCFile   : String;
     FFile     : File;
     BBuffer   : Array[1..8192] Of Byte;

     FUNCTION Byte2Hex(numb : Byte): String;
     CONST HexChars : Array[0..15] of Char = '0123456789ABCDEF';
     BEGIN
          Byte2Hex[0] := #2;
          Byte2Hex[1] := HexChars[numb shr  4];
          Byte2Hex[2] := HexChars[numb and 15];
     END;

     FUNCTION Numb2Hex(numb: Word): String;
     BEGIN
          Numb2Hex := Byte2Hex(hi(numb))+Byte2Hex(lo(numb));
     END;

     FUNCTION Long2Hex(L: LongInt): String;
     BEGIN
          Long2Hex := Numb2Hex(L shr 16) + Numb2Hex(L);
     END;

BEGIN
     Work := UpdateCrc32(0,$FFFFFFFF);
     ASSIGN(FFile,FileName);
     RESET(FFile,1);
     REPEAT
           BlockRead(FFile,BBuffer,SizeOf(BBuffer),BytesRead);
           FOR Loop := 1 TO BytesRead DO Work := UpdateCrc32(BBuffer[Loop],Work);
     UNTIL EOF(FFile);
     CLOSE(FFile);
     VOCFile := Long2Hex(Work)+'.VOC';
     IF _FileExists(RESOURCES+VOCFile) THEN
     BEGIN
          PutStringTimeout(BBSPort,#255#124+VOCFile+#13,YappDelay);
          IF GetAck THEN TransmitYAPP(RESOURCES+VOCFile,True);
          WaitForTheEnd;
     END;
END;


BEGIN
     ScreenNumber    := 0;
     PickInfo.Active := False;
     LastScreen      := '';
END.
