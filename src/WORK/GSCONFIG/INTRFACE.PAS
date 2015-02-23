{$I DEFINES.INC}
UNIT Intrface;


INTERFACE


USES {$IFNDEF MSDOS}VideoUtils,{$ENDIF}Dos,BsMouse,CNFGVARS,Dispatch,DosShell,Crt,FastW1,BsMulti,BsEditor,BsKeys,BsVideo;

{ÄÂ³ÅÁÚ¿ÀÙ´ÃÛ²±}

TYPE Button_Info = Record
     x1           : Word;
     y1           : Word;
     x2           : Word;
     y2           : Word;
     Title        : String[20];
     Enabled      : Boolean;
     cc1          : Byte;    {ALT KEY STATUS}
     cc2          : Byte;    {NORM KEY STATUS}
     END;
TYPE Object_Info = Record
     x1           : Word;
     y1           : Word;
     x2           : Word;
     y2           : Word;
     ObjectType   : Word;
     ObjectLength : Word;
     Stuff        : String[80];
     Enabled      : Boolean;
     END;
TYPE Menu_Object = Record
     ObjectType   : Word;
     Title        : String[24];
     cc1          : Byte;
     cc2          : Byte;
     END;
TYPE ColourScheme = Record
     MenuBackGround          : Byte;
     MenuForeGround          : Byte;
     MenuHotKey              : Byte;
     MenuHighLightBackGround : Byte;
     MenuHighLightForeGround : Byte;
     MenuHighLightHotKey     : Byte;
     MenuBorder              : Byte;
     MenuDisabled            : Byte;
     DeskTopColour           : Byte;
     WindowBackGround        : Byte;
     WindowFrame             : Byte;
     WindowHeader            : Byte;
     WindowHeaderText        : Byte;
     WindowClose             : Byte;
     EditDisabled            : Byte;
     EditEnabled             : Byte;
     EditBackGround          : Byte;
     END;
TYPE Pick_List=RECORD
     A        : String[40];
     B        : String[10];
     END;
TYPE Flip = RECORD
     Flips   : Byte;
     Current : Byte;
     Flip    : ARRAY[1..12] Of String[20];
     END;
CONST MaxMenus           = 8;
      SpaceColour        = 8;
      SpaceChar          = '_';
      Header             = 1;
      Item               = 2;
      SBar               = 3;
      Enabled            = True;
      Disabled           = False;
      LongInteger        = 2147483647;
      WordInteger        = 65535;
      ByteInteger        = 255;
      AddressField       = 18;
      OriginField        = 19;
      ChangeAddressField = 11;
      ChangeOriginField  = 12;
      SubAddressField    = 12;
      SubOriginField     = 13;
      LinksAddressField  = 3;
      PollAddressField   = 5;
TYPE Object_Record = Array[1..128] Of Object_Info;
TYPE Button_Record = Array[1..20] Of Button_Info;
VAR  Toggle                   : Array[1..8] OF Flip;
     Mouse_X                  : Word;
     Mouse_Y                  : Word;
     MouseB                   : Byte;
     OriginalMode             : Word;
{$IFDEF MSDOS}
     SavedScreen              : Array[1..4000] Of Byte;
{$ENDIF}
{$IFNDEF MSDOS}
     SavedScreen              : TScreenBuffer;
{$ENDIF}
     ProgramFinished          : Boolean;
     Colour                   : ColourScheme;
     MenuUsed                 : Array[1..MaxMenus,1..19] Of Boolean;
     MenuHelp                 : Array[1..MaxMenus,1..19] Of String[50];
     MenuObjects              : Array[1..MaxMenus,1..19] Of Menu_Object;
     MenuHeaders              : Array[1..MaxMenus] Of String[24];
     MenuHeaderKeyPresses     : Array[1..MaxMenus,1..2] Of Byte;
     HighestMenu              : Word;
     MenuFirst                : Array[1..MaxMenus] Of Byte;
     MenuItems                : Array[1..MaxMenus] Of Byte;
     Objects                  : ^Object_Record;
     Buttons                  : ^Button_Record;
     NumberOfObjects          : Word;
     NumberOfButtons          : Word;
     ActiveMenu               : Word;
     SelectItem               : Integer;
     CurrentObject            : Word;
     DoingInputField          : Boolean;
     PickList_A_Title         : String[41];
     PickList_B_Title         : String[10];
     PickListX                : Word;
     PickListY                : Word;
     PickListPerPage          : Word;
     UseTwoColumn             : Boolean;
     UseEditButton            : Boolean;
     UseFileButton            : Boolean;
     UseDeleteButton          : Boolean;
     UseSelectButton          : Boolean;
     UseInsertButton          : Boolean;
     UseAddButton             : Boolean;
     EditButtonX1             : Word;
     EditButtonX2             : Word;
     EditButtonY1             : Word;
     FileButtonX1             : Word;
     FileButtonX2             : Word;
     FileButtonY1             : Word;
     AddButtonX1              : Word;
     AddButtonX2              : Word;
     AddButtonY1              : Word;
     DeleteButtonX1           : Word;
     DeleteButtonX2           : Word;
     DeleteButtonY1           : Word;
     SelectButtonX1           : Word;
     SelectButtonX2           : Word;
     SelectButtonY1           : Word;
     InsertButtonX1           : Word;
     InsertButtonX2           : Word;
     InsertButtonY1           : Word;
     QuitButtonX1             : Word;
     QuitButtonX2             : Word;
     QuitButtonY1             : Word;
     PickListItems            : Longint;
     PickItem                 : Longint;
     ScrollBarX               : Word;
     ScrollBarY1              : Word;
     ScrollBarY2              : Word;
     ScrollPadY               : Word;
     PickListFile             : Pick_List;
     FPickListFile            : File Of Pick_List;
     PickTop                  : Longint;
     EditPos                  : Word;
     Escaped                  : Boolean;
     SaveAddress              : String[20];
     SaveOrigin               : String[20];
     CurrentBackGround        : Byte;
     CurrentForeGround        : Byte;


FUNCTION  PROPER_DATE                                                 : Longint;
FUNCTION  PROPER_DATE_NOTIME                                          : Longint;
FUNCTION  DoObjects                                                   : Word;
FUNCTION  DoPickList                                                  : Word;
FUNCTION  Confirmed                                                   : Boolean;
FUNCTION  Confirmed2       (FName: String)                            : Boolean;
FUNCTION  NoDrive          (InString: String)                         : String;
FUNCTION  Numeric          (Number: String; Limit: Longint)           : Longint;
FUNCTION  TimeStrng        (Number: Longint)                          : String;
FUNCTION  ReturnTime       (Number: String)                           : Longint;
FUNCTION  FromBoolean      (YesNo: Boolean)                           : String;
FUNCTION  ToBoolean        (YesNo: String)                            : Boolean;
FUNCTION  FindButton       (x,y: word)                                : Word;
FUNCTION  FindField        (x,y: word)                                : Word;
FUNCTION  noextension      (str: string)                              : string;
FUNCTION  Tags             (Worker: Array Of Byte)                    : String;
FUNCTION  UnpackedDate     (Work: Longint)                            : String;
FUNCTION  UnpackedDate2    (Work: Longint)                            : String;
FUNCTION  PackedDate       (InString: String)                         : Longint;
PROCEDURE DrawWindow       (x1,y1,x2,y2: Word; Title: String; Shad: Boolean);
PROCEDURE AddObject        (x1,y1,ObjectType,ObjectLength: Word; Stuff: String; Enabled: Boolean);
PROCEDURE AddButton        (x1,y1: Word; Title: String; Enabled: Boolean; cc1,cc2: Byte);
PROCEDURE AddMenuObject    (xx,yy: Byte; ObjectType: Word;Title: String; cc1,cc2: Byte; Help: String);
PROCEDURE PressPickListButton(Number: Byte);
PROCEDURE ReleasePickListButton(Number: Byte);
PROCEDURE Shadow           (xx1,yy1,xx2,yy2 : Word);
PROCEDURE SetUpPickList    (WindowTitle: String);
PROCEDURE InvertedBox      (x1,y1,x2,y2: Word);
PROCEDURE _SaveWindow      (FileName: String);
PROCEDURE LoadWindowNoKill (FileName: String);
PROCEDURE LoadWindow       (FileName: String);
PROCEDURE DrawSelected     (Number,Y: Word);
PROCEDURE ClearSelected    (Number,Y: Word);
PROCEDURE Activate         (Number: Word);
PROCEDURE DeActivate       (Number: Word);
PROCEDURE DisableObject    (Number: Word);
PROCEDURE EnableObject     (Number: Word);
PROCEDURE DisableButton    (Number: Word);
PROCEDURE EnableButton     (Number: Word);
PROCEDURE UpdateObject     (Number: Word);
PROCEDURE PressButton      (Number: Word);
PROCEDURE ReleaseButton    (Number: Word);
PROCEDURE InfoBox          (Title,InString1,InString2,InString3: String);
PROCEDURE TextColor_BS(Fore: Byte);
PROCEDURE TextBackGround_BS(Back: Byte);
PROCEDURE DrawPickListButtons;
PROCEDURE DrawPullDownMenu;
PROCEDURE UpdatePickList;
PROCEDURE DumpTheScreen;
PROCEDURE ClearObjects;
PROCEDURE ClearButtons;
PROCEDURE DrawObjects;
PROCEDURE DrawButtons;
PROCEDURE DoMenus;
PROCEDURE Memory;


IMPLEMENTATION


USES Misc,Version,BsString,BsFile;


PROCEDURE TextColor_BS(Fore: Byte);
BEGIN
     CurrentForeGround := Fore;
     TextAttr := (CurrentForeGround+CurrentBackGround*16);
END;


PROCEDURE TextBackGround_BS(Back: Byte);
BEGIN
     CurrentBackGround := Back;
     TextAttr := (CurrentForeGround+CurrentBackGround*16);
END;


PROCEDURE DumpTheScreen;
VAR  Count  : Word;
     Name   : String;
     Loop   : Word;
     Loop1  : Word;
     Loop2  : Word;
     Temp   : String;
     TFile  : Text;
BEGIN
     Count := 0;
     REPEAT
           INC(Count);
           Name := 'CAPTURE.'+_String(Count);
     UNTIL NOT(_FileExists(Name));
     Loop := 0;
     ASSIGN(TFile,Name);
     REWRITE(TFile);
     FOR Loop1 := 1 TO 25 DO
     BEGIN
          Temp := '';
          FOR Loop2 := 1 TO 80 DO
          BEGIN
{$IFDEF MSDOS}
               Temp := Temp+Chr(Mem[SegB800:Loop]);
               INC(Loop,2);
{$ENDIF}
{$IFNDEF MSDOS}
               Temp := Temp+VideoUtils.GetCharAt(Loop2, Loop1);
{$ENDIF}
          END;
          WRITELN(TFile,Temp);
     END;
     CLOSE(TFile);
END;


PROCEDURE InfoBox(Title,InString1,InString2,InString3: String);
BEGIN
     _HideMouse;
     IF InString2='' THEN
     BEGIN
          InString1 := _PadBoth(InString1,50);
          DrawWindow(12,10,66,14,Title,True);
          TextColor_BS(15);
          TextBackGround_BS(Colour.WindowBackGround);
          GotoXY(14,12); WRITE(InString1);
          _ShowMouse;
          Exit;
     END;
     IF InString3='' THEN
     BEGIN
          InString1 := _PadBoth(InString1,50);
          InString2 := _PadBoth(InString2,50);
          DrawWindow(12,10,66,15,Title,True);
          TextColor_BS(15);
          TextBackGround_BS(Colour.WindowBackGround);
          GotoXY(14,12); WRITE(InString1);
          GotoXY(14,13); WRITE(InString2);
          _ShowMouse;
          Exit;
     END;
     InString1 := _PadBoth(InString1,50);
     InString2 := _PadBoth(InString2,50);
     InString3 := _PadBoth(InString3,50);
     DrawWindow(12,10,66,16,Title,True);
     TextColor_BS(15);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(14,12); WRITE(InString1);
     GotoXY(14,13); WRITE(InString2);
     GotoXY(14,14); WRITE(InString3);
     _ShowMouse;
END;


FUNCTION Confirmed: Boolean;
VAR  C : Char;
BEGIN
     _HideMouse;
     _SaveWindow(WorkDir+'\DELCON.SCR');
     DrawWindow(25,10,55,14,'CONFIRM...',True);
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(29,12); WRITE('Delete this item? [Y/N]');
     _ShowMouse;
     WHILE KeyPressed DO C := ReadKey;
     C := #0;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := UpCase(ReadKey);
                IF C=#0 THEN
                BEGIN
                     C := ReadKey;
                     C := #0;
                END;
           END
           ELSE TimeSlice;
     UNTIL ((C='Y') OR (C='N'));
     LoadWindow(WorkDir+'\DELCON.SCR');
     IF C='Y' THEN Confirmed := True
              ELSE Confirmed := False;
END;


FUNCTION Confirmed2(FName: String): Boolean;
VAR  C : Char;
BEGIN
     _HideMouse;
     _SaveWindow(WorkDir+'\DELCON2.SCR');
     DrawWindow(25,12,55,16,FName+' Already Exists!',True);
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(28,14); WRITE('Copy over original? [Y/N]');
     _ShowMouse;
     WHILE KeyPressed DO C := ReadKey;
     C := #0;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := UpCase(ReadKey);
                IF C=#0 THEN
                BEGIN
                     C := ReadKey;
                     C := #0;
                END;
           END
           ELSE TimeSlice;
     UNTIL ((C='Y') OR (C='N'));
     LoadWindow(WorkDir+'\DELCON2.SCR');
     IF C='Y' THEN Confirmed2 := True
              ELSE Confirmed2 := False;
END;


FUNCTION noextension(str: string): string;
VAR  loop        : word;
     work_it     : string;
BEGIN
     work_it := '';
     loop    := length(str);
     REPEAT
           IF _Mid(str,loop,loop)='.' THEN
           BEGIN
                work_it := _Mid(str,1,loop-1);
                loop    := 1;
           END;
           DEC(loop);
     UNTIL loop=0;
     noextension := work_it;
END;


FUNCTION Numeric(Number: String; Limit: Longint): Longint;
VAR  Temp    : Longint;
     Code    : Integer;
BEGIN
     VAL(Number,Temp,Code);
     IF Temp>Limit THEN Temp := Limit;
     Numeric := Temp;
END;


PROCEDURE AddMenuObject(xx,yy: Byte; ObjectType: Word;Title: String; cc1,cc2: Byte; Help: String);
VAR  Loop1 : Word;
     Loop2 : Word;
BEGIN
     CASE ObjectType OF
     1:   BEGIN {HEADER}
               MenuHeaders[xx] := Title;
               MenuHeaderKeyPresses[xx,1] := cc1;
               MenuHeaderKeyPresses[xx,2] := cc2;
               IF xx>HighestMenu THEN HighestMenu := xx;
          END;
     2:   BEGIN {NORMAL}
               MenuUsed[xx,yy] := True;
               INC(MenuItems[xx]);
               MenuObjects[xx,yy].ObjectType := ObjectType;
               MenuObjects[xx,yy].Title      := Title;
               MenuObjects[xx,yy].cc1        := cc1;
               MenuObjects[xx,yy].cc2        := cc2;
               MenuHelp[xx,yy] := _PadRight(Help,50);
          END;
     3:   BEGIN {SEPERATOR BAR}
               MenuUsed[xx,yy] := True;
               INC(MenuItems[xx]);
               MenuObjects[xx,yy].ObjectType := ObjectType;
          END;
     END;
END;


{ ObjectType  1 - String      }
{             2 - Numeric     }
{             3 - Time        }
{             4 - Date        }
{             5 - Gender      }
{             6 - Yes/No      }
{             7 - Tags        }
{             8 - Flip        }
PROCEDURE AddObject(x1,y1,ObjectType,ObjectLength: Word; Stuff: String; Enabled: Boolean);
BEGIN
     INC(NumberOfObjects);
     IF NumberOfObjects=129 THEN Halt;
     Objects^[NumberOfObjects].x1 := x1;
     Objects^[NumberOfObjects].y1 := y1;
     IF ObjectType=4 THEN
     BEGIN
       ObjectLength := 8;
       Objects^[NumberOfObjects].x2 := x1+ObjectLength+1;
     END
     ELSE IF ObjectType=3 THEN Objects^[NumberOfObjects].x2 := x1+ObjectLength
     ELSE Objects^[NumberOfObjects].x2 := x1+ObjectLength-1;
     Objects^[NumberOfObjects].y2           := y1;
     Objects^[NumberOfObjects].ObjectType   := ObjectType;
     Objects^[NumberOfObjects].ObjectLength := ObjectLength;
     Objects^[NumberOfObjects].Stuff        := Stuff;
     Objects^[NumberOfObjects].Enabled      := Enabled;
END;


PROCEDURE DrawObjects;
VAR  Loop   : Word;
     Loop2  : Word;
     Poop   : Word;
     Temp   : String;
BEGIN
     _HideMouse;
     TextBackGround_BS(Colour.EditBackGround);
     TextColor_BS(Colour.EditDisabled);
     FOR Loop := 1 TO NumberOfObjects DO
     BEGIN
          GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
          IF Objects^[Loop].ObjectType=3 THEN
          BEGIN
               TextColor_BS(SpaceColour);
               FOR Loop2 := 1 TO 5 DO WRITE(SpaceChar);
               TextColor_BS(Colour.EditDisabled);
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               WRITE(_Mid(Objects^[Loop].Stuff,1,2));
               TextColor_BS(SpaceColour);
               GotoXY(Objects^[Loop].x1+2,Objects^[Loop].y1);
               WRITE(':');
               TextColor_BS(Colour.EditDisabled);
               GotoXY(Objects^[Loop].x1+3,Objects^[Loop].y1);
               WRITE(_Mid(Objects^[Loop].Stuff,3,4));
          END
          ELSE IF Objects^[Loop].ObjectType=5 THEN
          BEGIN
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               TextColor_BS(Colour.EditDisabled);
               IF Objects^[Loop].Stuff='1' THEN WRITE('MALE  ')
                                          ELSE WRITE('FEMALE');
          END
          ELSE IF Objects^[Loop].ObjectType=6 THEN
          BEGIN
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               TextColor_BS(Colour.EditDisabled);
               IF Objects^[Loop].Stuff='1' THEN WRITE('YES')
                                          ELSE WRITE('NO ');
          END
          ELSE IF Objects^[Loop].ObjectType=8 THEN
          BEGIN
               TextColor_BS(SpaceColour);
               FOR Loop2 := 1 TO Objects^[Loop].ObjectLength DO WRITE(SpaceChar);
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               TextColor_BS(Colour.EditDisabled);
               Poop := Numeric(Objects^[Loop].Stuff,ByteInteger);
               WRITE(Toggle[Poop].Flip[Toggle[Poop].Current]);
          END
          ELSE IF Objects^[Loop].ObjectType=7 THEN
          BEGIN
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               FOR Poop := 1 TO 10 DO
               BEGIN
                    IF Objects^[Loop].Stuff[Poop]='1' THEN
                    BEGIN
                         TextColor_BS(Colour.EditDisabled);
                         WRITE(CHR(254));
                    END
                    ELSE
                    BEGIN
                         TextColor_BS(SpaceColour);
                         WRITE(SpaceChar);
                    END;
               END;
          END
          ELSE IF Objects^[Loop].ObjectType=4 THEN
          BEGIN
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               TextColor_BS(SpaceColour);
               WRITE('  /  /    ');
               TextColor_BS(Colour.EditDisabled);
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               WRITE(_Mid(Objects^[Loop].Stuff,1,2));
               GotoXY(Objects^[Loop].x1+3,Objects^[Loop].y1);
               WRITE(_Mid(Objects^[Loop].Stuff,3,4));
               GotoXY(Objects^[Loop].x1+6,Objects^[Loop].y1);
               WRITE(_Mid(Objects^[Loop].Stuff,5,8));
          END
          ELSE
          BEGIN
               TextColor_BS(SpaceColour);
               FOR Loop2 := 1 TO Objects^[Loop].ObjectLength DO WRITE(SpaceChar);
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               TextColor_BS(Colour.EditDisabled);
               WRITE(Objects^[Loop].Stuff);
          END;
     END;
     _ShowMouse;
     SaveAddress := '@!#!@!#!@!$#';
     SaveOrigin  := '@!#!@!#!@!$#';
END;


PROCEDURE AddButton(x1,y1: Word; Title: String; Enabled: Boolean; cc1,cc2: Byte);
BEGIN
     INC(NumberOfButtons);
     IF NumberOfButtons=21 THEN Halt;
     Buttons^[NumberOfButtons].x1           := x1;
     Buttons^[NumberOfButtons].y1           := y1;
     Buttons^[NumberOfButtons].x2           := x1+LENGTH(Title)-1;
     Buttons^[NumberOfButtons].y2           := y1;
     Buttons^[NumberOfButtons].Title        := Title;
     Buttons^[NumberOfButtons].Enabled      := Enabled;
     Buttons^[NumberOfButtons].cc1          := cc1;
     Buttons^[NumberOfButtons].cc2          := cc2;
END;


PROCEDURE DrawButtons;
VAR
     Loop   : Word;
     Loop2  : Word;
     Loop3  : Word;
BEGIN
     _HideMouse;
     FOR Loop := 1 TO NumberOfButtons DO
     BEGIN
          Loop3 := LENGTH(Buttons^[Loop].Title);
          {BUTTON FACE}
          TextBackGround_BS(7);
          GotoXY(Buttons^[Loop].x1,Buttons^[Loop].y1);
          FOR Loop2 := 1 TO Loop3 DO WRITE(' ');
          {BUTTON TEXT}
          GotoXY(Buttons^[Loop].x1,Buttons^[Loop].y1);
          TextColor_BS(4); WRITE(_Mid(Buttons^[Loop].Title,1,2));
          TextColor_BS(0); WRITE(_Mid(Buttons^[Loop].Title,3,Loop3));
          {BUTTON SHADOW}
          TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
          GotoXY(Buttons^[Loop].x1+Loop3,Buttons^[Loop].y1);
          WRITE('Ü');
          GotoXY(Buttons^[Loop].x1+1,Buttons^[Loop].y1+1);
          FOR Loop2 := 1 TO Loop3 DO WRITE('ß');
     END;
     _ShowMouse;
END;


PROCEDURE ClearObjects;
BEGIN
     NumberOfObjects := 0;
END;


PROCEDURE ClearButtons;
BEGIN
     NumberOfButtons := 0;
END;


PROCEDURE DrawPullDownMenu;
VAR
     Loop1  : Word;
BEGIN
     _HideMouse;
     TextBackGround_BS(0);
     ClrScr;
     TextBackGround_BS(Colour.DeskTopColour);
     FOR Loop1 := 2 TO 24 DO
     BEGIN
          GotoXY(1,Loop1);
          ClrEol;
     END;
     TextColor_BS(15);
     TextBackGround_BS(Colour.DeskTopColour);
     GotoXY(59,21); WRITE('*  Language Dependent');
     GotoXY(59,22); WRITE('** Node Dependent');
     {°±²}
     GotoXY(1,2);
     TextBackGround_BS(Colour.MenuBackGround);
     ClrEol;
     GotoXY(2,2);
     FOR Loop1 := 1 TO MaxMenus DO
     BEGIN
          TextColor_BS(Colour.MenuHotKey);
          MenuFirst[Loop1] := WhereX;
          WRITE(_Mid(MenuHeaders[Loop1],1,2));
          TextColor_BS(Colour.MenuForeGround);
          WRITE(_Mid(MenuHeaders[Loop1],3,Length(MenuHeaders[Loop1])));
     END;
     GotoXY(1,25);
     TextBackGround_BS(7);
     ClrEol;
     TextColor_BS(15);
     TextBackGround_BS(Colour.DeskTopColour);
     GotoXY(1,1);
     WRITE(_PadBoth('GUNSHOT PROFESSIONAL '+GunshotVersion+' - Configuration Module',80));
     GotoXY(1,1);
{$IFDEF MSDOS}
     Move(MEM[SegB800:0],SavedScreen,160*25);
{$ENDIF}
{$IFNDEF MSDOS}
     VideoUtils.ScreenSave(SavedScreen);
{$ENDIF}
     _ShowMouse;
END;


{$IFDEF MSDOS}
PROCEDURE _SaveWindow(FileName: String);
VAR  FFile        : File;
     SavedScreen2 : Array[1..4000] Of Byte;
BEGIN
     _HideMouse;
     Move(MEM[SegB800:0],SavedScreen2,160*25);
     ASSIGN(FFile,FileName);
     REWRITE(FFile,1);
     BLOCKWRITE(FFile,SavedScreen2,160*25);
     CLOSE(FFile);
     _ShowMouse;
END;
{$ENDIF}
{$IFNDEF MSDOS}
PROCEDURE _SaveWindow(FileName: String);
VAR  FFile        : File;
     SavedScreen2  : TScreenBuffer;
BEGIN
     _HideMouse;
     VideoUtils.ScreenSave(SavedScreen2);
     ASSIGN(FFile,FileName);
     REWRITE(FFile,1);
     BLOCKWRITE(FFile,SavedScreen2,SizeOf(TScreenBuffer));
     CLOSE(FFile);
     _ShowMouse;
END;
{$ENDIF}


{$IFDEF MSDOS}
PROCEDURE LoadWindow(FileName: String);
VAR  FFile        : File;
     SavedScreen2 : Array[1..4000] Of Byte;
BEGIN
     ASSIGN(FFile,FileName);
     RESET(FFile,1);
     BLOCKREAD(FFile,SavedScreen2,160*25);
     CLOSE(FFile);
     ERASE(FFile);
     _HideMouse;
     Move(SavedScreen2,Mem[SegB800:0],160*25);
     _ShowMouse;
END;
{$ENDIF}
{$IFNDEF MSDOS}
PROCEDURE LoadWindow(FileName: String);
VAR  FFile        : File;
     SavedScreen2  : TScreenBuffer;
BEGIN
     ASSIGN(FFile,FileName);
     RESET(FFile,1);
     BLOCKREAD(FFile,SavedScreen2,SizeOf(TScreenBuffer));
     CLOSE(FFile);
     ERASE(FFile);
     _HideMouse;
     VideoUtils.ScreenRestore(SavedScreen2);
     _ShowMouse;
END;
{$ENDIF}


{$IFDEF MSDOS}
PROCEDURE LoadWindowNoKill(FileName: String);
VAR  FFile        : File;
     SavedScreen2 : Array[1..4000] Of Byte;
BEGIN
     ASSIGN(FFile,FileName);
     RESET(FFile,1);
     BLOCKREAD(FFile,SavedScreen2,160*25);
     CLOSE(FFile);
     _HideMouse;
     Move(SavedScreen2,Mem[SegB800:0],160*25);
     _ShowMouse;
END;
{$ENDIF}
{$IFNDEF MSDOS}
PROCEDURE LoadWindowNoKill(FileName: String);
VAR  FFile        : File;
     SavedScreen2  : TScreenBuffer;
BEGIN
     ASSIGN(FFile,FileName);
     RESET(FFile,1);
     BLOCKREAD(FFile,SavedScreen2,SizeOf(TScreenBuffer));
     CLOSE(FFile);
     _HideMouse;
     VideoUtils.ScreenRestore(SavedScreen2);
     _ShowMouse;
END;
{$ENDIF}


PROCEDURE DoMenus;
VAR  OuttaHere    : Boolean;
     cc1          : Byte;
     cc2          : Byte;
     C            : Char;
     Loop         : Word;
     LeftBox      : Boolean;
     wx1,wx2,wy1  : Word;
LABEL               DoneIt;
LABEL               DoneIt2;
BEGIN
     OuttaHere := False;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                c := UpCase(ReadKey);
                IF ORD(c)=0 THEN
                BEGIN
                     c := UpCase(ReadKey);
                     cc1 := 1;
                     cc2 := ORD(c);
                     CASE cc2 OF
                     15 : BEGIN
                               IF ActiveMenu<>0 THEN
                               BEGIN
                                    DeActivate(ActiveMenu);
                                    DEC(ActiveMenu);
                                    IF ActiveMenu=0 THEN ActiveMenu := HighestMenu;
                                    Activate(ActiveMenu);
                                    SelectItem  := 1;
                                    DrawSelected(ActiveMenu,SelectItem);
                               END;
                          END;
                     45 : ShutDown;
                     60 : ShellToDos;
                     59 : BEGIN
                               (* HELP! *)
                          END;
                     68 : DumpTheScreen;
                     75 : BEGIN
                               IF ActiveMenu<>0 THEN
                               BEGIN
                                    DeActivate(ActiveMenu);
                                    DEC(ActiveMenu);
                                    IF ActiveMenu=0 THEN ActiveMenu := HighestMenu;
                                    Activate(ActiveMenu);
                                    SelectItem  := 1;
                                    DrawSelected(ActiveMenu,SelectItem);
                               END;
                          END;
                     77 : BEGIN
                               IF ActiveMenu<>0 THEN
                               BEGIN
                                    DeActivate(ActiveMenu);
                                    INC(ActiveMenu);
                                    IF ActiveMenu>HighestMenu THEN ActiveMenu := 1;
                                    Activate(ActiveMenu);
                                    SelectItem  := 1;
                                    DrawSelected(ActiveMenu,SelectItem);
                               END;
                          END;
                     72 : BEGIN
                               IF ActiveMenu<>0 THEN
                               BEGIN
                                    ClearSelected(ActiveMenu,SelectItem);
                                    DEC(SelectItem);
                                    IF MenuObjects[ActiveMenu,SelectItem].ObjectType<>Item THEN DEC(SelectItem);
                                    IF SelectItem<1 THEN SelectItem := MenuItems[ActiveMenu];
                                    DrawSelected(ActiveMenu,SelectItem);
                               END;
                          END;
                     80 : BEGIN
                               IF ActiveMenu<>0 THEN
                               BEGIN
                                    ClearSelected(ActiveMenu,SelectItem);
                                    INC(SelectItem);
                                    IF MenuObjects[ActiveMenu,SelectItem].ObjectType<>Item THEN INC(SelectItem);
                                    IF SelectItem>MenuItems[ActiveMenu] THEN SelectItem := 1;
                                    DrawSelected(ActiveMenu,SelectItem);
                               END;
                          END;
                     ELSE
                          FOR Loop := 1 TO MaxMenus DO
                          BEGIN
                               IF ((MenuHeaderKeyPresses[Loop,1] = cc1) AND
                                  (MenuHeaderKeyPresses[Loop,2] = cc2)) THEN
                               BEGIN
                                    IF Loop<>ActiveMenu THEN
                                    BEGIN
                                         IF ActiveMenu<>0 THEN DeActivate(ActiveMenu);
                                         ActiveMenu := Loop;
                                         Activate(ActiveMenu);
                                         SelectItem  := 1;
                                         DrawSelected(ActiveMenu,SelectItem);
                                    END;
                               END;
                          END;
                     END;
                     DoneIt2:
                END
                ELSE
                BEGIN
                     cc1 := 0;
                     cc2 := ORD(c);
                     CASE cc2 OF
                     13:  IF ActiveMenu<>0 THEN OuttaHere := True;
                     9 :  IF ActiveMenu<>0 THEN
                          BEGIN
                               DeActivate(ActiveMenu);
                               INC(ActiveMenu);
                               IF ActiveMenu>HighestMenu THEN ActiveMenu := 1;
                               Activate(ActiveMenu);
                               SelectItem  := 1;
                               DrawSelected(ActiveMenu,SelectItem);
                          END;
                     27:  BEGIN
                               IF ActiveMenu<>0 THEN
                               BEGIN
                                    Deactivate(ActiveMenu);
                                    ActiveMenu := 0;
                               END;
                          END;
                     ELSE IF ActiveMenu<>0 THEN FOR Loop := 1 TO MenuItems[ActiveMenu] DO
                          BEGIN
                               IF ((MenuObjects[ActiveMenu,Loop].CC1 = cc1) AND
                                   (MenuObjects[ActiveMenu,Loop].CC2 = cc2)) THEN
                               BEGIN
                                    ClearSelected(ActiveMenu,SelectItem);
                                    SelectItem := Loop;
                                    DrawSelected(ActiveMenu,SelectItem);
                                    Exit;
                               END;
                          END;
                     END;
                END;
           END
           ELSE
           BEGIN
                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                CASE MouseB OF
                0:   TimeSlice;
                1:   BEGIN
                          IF Mouse_Y=2 THEN FOR Loop := 1 TO MaxMenus DO
                          BEGIN
                               IF (MenuHeaders[Loop]<>'') THEN
                               BEGIN
                                    IF ((Mouse_X>=MenuFirst[Loop]) AND
                                       (Mouse_X<MenuFirst[Loop]+LENGTH(MenuHeaders[Loop]))) THEN
                                    BEGIN
                                         IF Loop<>ActiveMenu THEN
                                         BEGIN
                                              IF ActiveMenu<>0 THEN DeActivate(ActiveMenu);
                                              ActiveMenu := Loop;
                                              Activate(ActiveMenu);
                                              SelectItem  := 1;
                                              DrawSelected(ActiveMenu,SelectItem);
                                              GOTO DoneIt;
                                         END;
                                    END;
                               END;
                          END
                          ELSE IF (ActiveMenu<>0) THEN
                          BEGIN
                               wx1 := MenuFirst[ActiveMenu]+2;
                               wy1 := Mouse_Y;
                               wx2 := Wx1+LENGTH(MenuObjects[ActiveMenu,1].Title)-1;
                               IF ((Mouse_X>=wx1) AND (Mouse_X<=wx2) AND (Mouse_Y>3) AND
                                  (Mouse_Y<4+MenuItems[ActiveMenu])) THEN
                               BEGIN
                                    IF MenuObjects[ActiveMenu,Mouse_Y-3].ObjectType=Item THEN
                                    BEGIN
                                         ClearSelected(ActiveMenu,SelectItem);
                                         SelectItem := Mouse_Y-3;
                                         DrawSelected(ActiveMenu,SelectItem);
                                         LeftBox := False;
                                         REPEAT
                                               MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                               IF ((Mouse_X<wx1) OR (Mouse_X>wx2) OR (Mouse_Y<>wy1)) THEN LeftBox := True;
                                         UNTIL ((MouseB<>1) OR (LeftBox=True));
                                         IF LeftBox=False THEN OuttaHere := True;
                                    END;
                               END;
                          END;
                          DoneIt:
                     END;
                2:   BEGIN
                          IF ActiveMenu<>0 THEN
                          BEGIN
                               Deactivate(ActiveMenu);
                               ActiveMenu := 0;
                          END;
                     END;
                END;
           END;
     UNTIL OuttaHere;
END;


PROCEDURE DrawSelected(Number,Y: Word);
VAR  L : Word;
BEGIN
     _HideMouse;
     L := LENGTH(MenuObjects[Number,1].Title);
     FastWrite(_Mid(MenuObjects[Number,y].Title,1,2),3+Y,MenuFirst[Number]+2,
              (Colour.MenuHighLightBackGround*16)+Colour.MenuHighLightHotKey);
     FastWrite(_Mid(MenuObjects[Number,y].Title,3,L),3+Y,MenuFirst[Number]+4,
              (Colour.MenuHighLightBackGround*16)+Colour.MenuHighLightForeGround);
     FastWrite(MenuHelp[Number,Y],25,2,(7*16));
     _ShowMouse;
     Memory;
END;


PROCEDURE Memory;
{$IFNDEF MSDOS}
CONST MemAvail: LongInt = 640 * 1024; // Pretend we have 640k
{$ENDIF}    
BEGIN
     FastWrite('MEM: '+_PadRight(_String(MemAvail),6),25,69,(7*16));
END;


PROCEDURE ClearSelected(Number,Y: Word);
VAR  L : Word;
BEGIN
     _HideMouse;
     L := LENGTH(MenuObjects[Number,1].Title);
     FastWrite(_Mid(MenuObjects[Number,y].Title,1,2),3+Y,MenuFirst[Number]+2,
              (Colour.MenuBackGround*16)+Colour.MenuHotKey);
     FastWrite(_Mid(MenuObjects[Number,y].Title,3,L),3+Y,MenuFirst[Number]+4,
              (Colour.MenuBackGround*16)+Colour.MenuForeGround);
     _ShowMouse;
END;


PROCEDURE Activate(Number: Word);
VAR  x    : Word;
     y    : Word;
     Loop : Word;
     L    : Word;
BEGIN
     _HideMouse;
     x := MenuFirst[Number];

     Shadow(x,3,x+LENGTH(MenuObjects[Number,1].Title)+3,4+MenuItems[Number]);

     {MENU HEADER}
     TextBackGround_BS(Colour.MenuHighLightBackGround);
     GotoXy(x,2);
     TextColor_BS(Colour.MenuHighLightHotKey);
     WRITE(_Mid(MenuHeaders[Number],1,2));
     TextColor_BS(Colour.MenuHighLightForeGround);
     WRITE(_Mid(MenuHeaders[Number],3,Length(MenuHeaders[Number])));

     {PULLDOWN}
     L := LENGTH(MenuObjects[Number,1].Title);
     TextBackGround_BS(Colour.MenuBackGround);
     TextColor_BS(Colour.MenuBorder);
     GotoXY(x,3); WRITE(' Ú'); FOR Loop := 1 TO L DO WRITE('Ä'); WRITE('¿ ');
     FOR y := 1 TO MenuItems[Number] DO
     BEGIN
          GotoXY(x,3+y);
          IF MenuObjects[Number,y].ObjectType=Item THEN
          BEGIN
               TextColor_BS(Colour.MenuBorder);     WRITE(' ³');
               TextColor_BS(Colour.MenuHotKey);     WRITE(_Mid(MenuObjects[Number,y].Title,1,2));
               TextColor_BS(Colour.MenuForeGround); WRITE(_Mid(MenuObjects[Number,y].Title,3,L));
               TextColor_BS(Colour.MenuBorder);     WRITE('³ ');
          END
          ELSE IF MenuObjects[Number,y].ObjectType=SBar THEN
          BEGIN
               TextColor_BS(Colour.MenuBorder);
               WRITE(' Ã');
               FOR Loop := 1 TO L DO WRITE('Ä');
               WRITE('´ ');
          END;
     END;
     GotoXY(x,3+y+1);
     WRITE(' À'); FOR Loop := 1 TO L DO WRITE('Ä'); WRITE('Ù ');
     _ShowMouse;
END;


PROCEDURE DeActivate(Number: Word);
BEGIN
     _HideMouse;
{$IFDEF MSDOS}
     Move(SavedScreen,Mem[SegB800:0],160*25);
{$ENDIF}
{$IFNDEF MSDOS}
     VideoUtils.ScreenRestore(SavedScreen);
{$ENDIF}
     DrawLanguage;
     _ShowMouse;
END;


PROCEDURE Shadow(xx1,yy1,xx2,yy2 : Word);
VAR  xshad   : Word;
     yshad   : Word;
     x       : Word;
     y       : Word;
     Loop    : Word;
BEGIN
     _HideMouse;
     x := ((yy2*160)+(xx1*2))+1;
     FOR Loop := xx1 to xx2 DO
     BEGIN
{$IFDEF MSDOS}
          Mem[SegB800:x] := 8;
{$ENDIF}
{$IFNDEF MSDOS}
          VideoUtils.SetAttrAt(8, Loop+1, yy2+1);
{$ENDIF}
          INC(x,2);
     END;
     y := ((yy1*160)+((xx2)*2))+1;
     FOR Loop := yy1 to yy2 DO
     BEGIN
{$IFDEF MSDOS}
          Mem[SegB800:y] := 8;
{$ENDIF}
{$IFNDEF MSDOS}
          VideoUtils.SetAttrAt(8, xx2+1, Loop+1);
{$ENDIF}
          INC(y,160);
     END;
     _ShowMouse;
END;


PROCEDURE EnableButton(Number: Word);
VAR
     sx1,sx2,sy1     : Word;
     Loop3           : Word;
     Loop2           : Word;
BEGIN
     _HideMouse;
     Loop3 := LENGTH(Buttons^[Number].Title);
     {BUTTON FACE}
     TextBackGround_BS(7);
     GotoXY(Buttons^[Number].x1,Buttons^[Number].y1);
     FOR Loop2 := 1 TO Loop3 DO WRITE(' ');
     {BUTTON TEXT}
     GotoXY(Buttons^[Number].x1,Buttons^[Number].y1);
     TextColor_BS(4);  WRITE(_Mid(Buttons^[Number].Title,1,2));
     TextColor_BS(0);  WRITE(_Mid(Buttons^[Number].Title,3,Loop3));
     TextColor_BS(0);
     GotoXY(Buttons^[Number].x1,Buttons^[Number].y1); WRITE('[');
     GotoXY(Buttons^[Number].x2,Buttons^[Number].y1); WRITE(']');
     _ShowMouse;
END;


PROCEDURE DisableButton(Number: Word);
VAR  sx1,sx2,sy1     : Word;
     Loop3           : Word;
     Loop2           : Word;
BEGIN
     _HideMouse;
     Loop3 := LENGTH(Buttons^[Number].Title);
     {BUTTON FACE}
     TextBackGround_BS(7);
     GotoXY(Buttons^[Number].x1,Buttons^[Number].y1);
     FOR Loop2 := 1 TO Loop3 DO WRITE(' ');
     {BUTTON TEXT}
     GotoXY(Buttons^[Number].x1,Buttons^[Number].y1);
     TextColor_BS(4); WRITE(_Mid(Buttons^[Number].Title,1,2));
     TextColor_BS(0); WRITE(_Mid(Buttons^[Number].Title,3,Loop3));
     _ShowMouse;
END;


FUNCTION FindButton(x,y: word): Word;
VAR  Loop   : Word;
BEGIN
     FOR Loop := 1 TO NumberOfButtons DO
     BEGIN
          IF y=Buttons^[Loop].Y1 THEN
          BEGIN
               IF ((x>=Buttons^[Loop].x1) AND (x<=Buttons^[Loop].x2)) THEN
               BEGIN
                    FindButton := Loop;
                    Exit;
               END;
          END;
     END;
     FindButton := 0;
END;


FUNCTION FindField(x,y: word): Word;
VAR  Loop   : Word;
BEGIN
     FOR Loop := 1 TO NumberOfObjects DO
     BEGIN
          IF y=Objects^[Loop].Y1 THEN
          BEGIN
               IF ((x>=Objects^[Loop].x1) AND (x<=Objects^[Loop].x2)) THEN
               BEGIN
                    FindField := Loop;
                    Exit;
               END;
          END;
     END;
     FindField := 0;
END;


PROCEDURE PressButton(Number: Word);
VAR  sx1,sx2,sy1     : Word;
     Loop3           : Word;
     Loop2           : Word;
     Loop1           : Word;
BEGIN
     _HideMouse;
     Loop3 := LENGTH(Buttons^[Number].Title);
     sx1   := Buttons^[Number].x1;
     sy1   := Buttons^[Number].y1;
     TextBackGround_BS(Colour.WindowBackGround);
     FOR Loop1 := sx1 TO sx1+Loop3 DO
     BEGIN
          GotoXY(Loop1,sy1);   WRITE(' ');
          GotoXY(Loop1,sy1+1); WRITE(' ');
     END;
     {BUTTON FACE}
     TextBackGround_BS(7);
     GotoXY(sx1+1,sy1);
     FOR Loop2 := 1 TO Loop3 DO WRITE(' ');
     {BUTTON TEXT}
     GotoXY(sx1+1,sy1);
     TextColor_BS(4);  WRITE(_Mid(Buttons^[Number].Title,1,2));
     TextColor_BS(0);  WRITE(_Mid(Buttons^[Number].Title,3,Loop3));
     _ShowMouse;
END;


PROCEDURE ReleaseButton(Number: Word);
VAR  Loop2  : Word;
     Loop3  : Word;
BEGIN
     _HideMouse;
     Loop3 := LENGTH(Buttons^[Number].Title);
     {BUTTON FACE}
     TextBackGround_BS(7);
     GotoXY(Buttons^[Number].x1,Buttons^[Number].y1);
     FOR Loop2 := 1 TO Loop3 DO WRITE(' ');
     {BUTTON TEXT}
     GotoXY(Buttons^[Number].x1,Buttons^[Number].y1);
     TextColor_BS(4); WRITE(_Mid(Buttons^[Number].Title,1,2));
     TextColor_BS(0); WRITE(_Mid(Buttons^[Number].Title,3,Loop3));
     {BUTTON SHADOW}
     TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(Buttons^[Number].x1+Loop3,Buttons^[Number].y1);
     WRITE('Ü');
     GotoXY(Buttons^[Number].x1+1,Buttons^[Number].y1+1);
     FOR Loop2 := 1 TO Loop3 DO WRITE('ß');
     _ShowMouse;
END;


FUNCTION TimeStrng(Number: Longint): String;
VAR  Hours        : Word;
     Minutes      : Word;
     TotalMinutes : Longint;
     HourStrng    : String;
     MinStrng     : String;
BEGIN
     TotalMinutes := TRUNC(Number/60);
     Hours        := TRUNC(TotalMinutes/60);
     Minutes      := TotalMinutes-(Hours*60);

     STR(Hours,HourStrng);
     STR(Minutes,MinStrng);
     IF LENGTH(HourStrng)=1 THEN HourStrng := '0'+HourStrng;
     IF LENGTH(MinStrng)=1  THEN MinStrng  := '0'+MinStrng;
     TimeStrng := HourStrng+MinStrng;
END;


FUNCTION ReturnTime(Number: String): Longint;
VAR  Hours        : Longint;
     Minutes      : Longint;
     Total        : Longint;
BEGIN
     WHILE (LENGTH(Number)<4) DO Number := Number+'0';
     Hours   := _Numeric(_Mid(Number,1,2));
     Minutes := _Numeric(_Mid(Number,3,4));
     Total := Hours*3600;
     Total := Total+(Minutes*60);
     ReturnTime := Total;
END;


PROCEDURE DrawPickListButtons;
VAR  Loop : Word;
BEGIN
     EditButtonY1   := 0;
     FileButtonY1   := 0;
     AddButtonY1    := 0;
     DeleteButtonY1 := 0;
     SelectButtonY1 := 0;
     InsertButtonY1 := 0;
     QuitButtonY1   := 0;
     _HideMouse;
     Loop := 1;
     IF UseAddButton THEN
     BEGIN
          AddButtonX1    := PickListX+54;
          AddButtonX2    := PickListX+61;
          AddButtonY1    := PickListY+PickListPerPage-Loop;
          INC(Loop,2);
     END;
     IF UseInsertButton THEN
     BEGIN
          InsertButtonX1 := PickListX+54;
          InsertButtonX2 := PickListX+61;
          InsertButtonY1 := PickListY+PickListPerPage-Loop;
          INC(Loop,2);
     END;
     IF UseDeleteButton THEN
     BEGIN
          DeleteButtonX1 := PickListX+54;
          DeleteButtonX2 := PickListX+61;
          DeleteButtonY1 := PickListY+PickListPerPage-Loop;
          INC(Loop,2);
     END;
     IF UseEditButton THEN
     BEGIN
          EditButtonX1   := PickListX+54;
          EditButtonX2   := PickListX+61;
          EditButtonY1   := PickListY+PickListPerPage-Loop;
          INC(Loop,2);
     END;
     IF UseSelectButton THEN
     BEGIN
          SelectButtonX1 := PickListX+54;
          SelectButtonX2 := PickListX+61;
          SelectButtonY1 := PickListY+PickListPerPage-Loop;
          INC(Loop,2);
     END;
     IF UseFileButton THEN
     BEGIN
          FileButtonX1   := PickListX+54;
          FileButtonX2   := PickListX+61;
          FileButtonY1   := PickListY+PickListPerPage-Loop;
          INC(Loop,2);
     END;
     QuitButtonX1   := PickListX+54;
     QuitButtonX2   := PickListX+61;
     QuitButtonY1   := PickListY+PickListPerPage+1;

     IF UseSelectButton=True THEN
     BEGIN
          FOR Loop := SelectButtonX1 TO SelectButtonX2 DO
          BEGIN
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(Loop,SelectButtonY1);
               WRITE(' ');
               {BUTTON SHADOW}
               TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(Loop+1,SelectButtonY1+1);
               WRITE('ß');
          END;
          GotoXY(SelectButtonX2+1,SelectButtonY1);
          WRITE('Ü');
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(SelectButtonX1,SelectButtonY1); WRITE(' S');
          TextColor_BS(0); WRITE('elect');
     END;

     IF UseAddButton=True THEN
     BEGIN
          FOR Loop := AddButtonX1 TO AddButtonX2 DO
          BEGIN
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(Loop,AddButtonY1);
               WRITE(' ');
               {BUTTON SHADOW}
               TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(Loop+1,AddButtonY1+1);
               WRITE('ß');
          END;
          GotoXY(AddButtonX2+1,AddButtonY1);
          WRITE('Ü');
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(AddButtonX1,AddButtonY1); WRITE('  A');
          TextColor_BS(0); WRITE('dd');
     END;

     IF UseEditButton=True THEN
     BEGIN
          FOR Loop := EditButtonX1 TO EditButtonX2 DO
          BEGIN
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(Loop,EditButtonY1);
               WRITE(' ');
               {BUTTON SHADOW}
               TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(Loop+1,EditButtonY1+1);
               WRITE('ß');
          END;
          GotoXY(EditButtonX2+1,EditButtonY1);
          WRITE('Ü');
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(EditButtonX1,EditButtonY1); WRITE('  E');
          TextColor_BS(0); WRITE('dit');
     END;

     IF UseFileButton=True THEN
     BEGIN
          FOR Loop := FileButtonX1 TO FileButtonX2 DO
          BEGIN
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(Loop,FileButtonY1);
               WRITE(' ');
               {BUTTON SHADOW}
               TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(Loop+1,FileButtonY1+1);
               WRITE('ß');
          END;
          GotoXY(FileButtonX2+1,FileButtonY1);
          WRITE('Ü');
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(FileButtonX1,FileButtonY1); WRITE(' F');
          TextColor_BS(0); WRITE('iles');
     END;

     IF UseDeleteButton=True THEN
     BEGIN
          FOR Loop := DeleteButtonX1 TO DeleteButtonX2 DO
          BEGIN
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(Loop,DeleteButtonY1);
               WRITE(' ');
               {BUTTON SHADOW}
               TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(Loop+1,DeleteButtonY1+1);
               WRITE('ß');
          END;
          GotoXY(DeleteButtonX2+1,DeleteButtonY1);
          WRITE('Ü');
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(DeleteButtonX1,DeleteButtonY1); WRITE(' D');
          TextColor_BS(0); WRITE('elete');
     END;

     IF UseInsertButton=True THEN
     BEGIN
          FOR Loop := InsertButtonX1 TO InsertButtonX2 DO
          BEGIN
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(Loop,InsertButtonY1);
               WRITE(' ');
               {BUTTON SHADOW}
               TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(Loop+1,InsertButtonY1+1);
               WRITE('ß');
          END;
          GotoXY(InsertButtonX2+1,InsertButtonY1);
          WRITE('Ü');
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(InsertButtonX1,InsertButtonY1); WRITE(' I');
          TextColor_BS(0); WRITE('nsert');
     END;

     FOR Loop := QuitButtonX1 TO QuitButtonX2 DO
     BEGIN
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(Loop,QuitButtonY1);
          WRITE(' ');
          {BUTTON SHADOW}
          TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
          GotoXY(Loop+1,QuitButtonY1+1);
          WRITE('ß');
     END;
     GotoXY(QuitButtonX2+1,QuitButtonY1);
     WRITE('Ü');
     TextBackGround_BS(7);
     TextColor_BS(4);
     GotoXY(QuitButtonX1,QuitButtonY1); WRITE('  Q');
     TextColor_BS(0); WRITE('uit');
     _ShowMouse;
END;


PROCEDURE ReleasePickListButton(Number: Byte);
VAR
     Loop         : Word;
BEGIN
     _HideMouse;

     CASE Number Of
     7:   IF UseFileButton THEN BEGIN
               FOR Loop := FileButtonX1 TO FileButtonX2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,FileButtonY1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
                    GotoXY(Loop+1,FileButtonY1+1);
                    WRITE('ß');
               END;
               GotoXY(FileButtonX2+1,FileButtonY1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(FileButtonX1,FileButtonY1); WRITE(' F');
               TextColor_BS(0); WRITE('iles');
          END;
     1:   IF UseEditButton THEN BEGIN
               FOR Loop := EditButtonX1 TO EditButtonX2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,EditButtonY1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
                    GotoXY(Loop+1,EditButtonY1+1);
                    WRITE('ß');
               END;
               GotoXY(EditButtonX2+1,EditButtonY1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(EditButtonX1,EditButtonY1); WRITE('  E');
               TextColor_BS(0); WRITE('dit');
          END;
     2:   IF UseDeleteButton THEN BEGIN
               FOR Loop := DeleteButtonX1 TO DeleteButtonX2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,DeleteButtonY1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
                    GotoXY(Loop+1,DeleteButtonY1+1);
                    WRITE('ß');
               END;
               GotoXY(DeleteButtonX2+1,DeleteButtonY1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(DeleteButtonX1,DeleteButtonY1); WRITE(' D');
               TextColor_BS(0); WRITE('elete');
          END;
     3:   IF UseInsertButton THEN BEGIN
               FOR Loop := InsertButtonX1 TO InsertButtonX2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,InsertButtonY1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
                    GotoXY(Loop+1,InsertButtonY1+1);
                    WRITE('ß');
               END;
               GotoXY(InsertButtonX2+1,InsertButtonY1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(InsertButtonX1,InsertButtonY1); WRITE(' I');
               TextColor_BS(0); WRITE('nsert');
          END;
     5:   IF UseAddButton THEN BEGIN
               FOR Loop := AddButtonX1 TO AddButtonX2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,AddButtonY1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
                    GotoXY(Loop+1,AddButtonY1+1);
                    WRITE('ß');
               END;
               GotoXY(AddButtonX2+1,AddButtonY1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(AddButtonX1,AddButtonY1); WRITE('  A');
               TextColor_BS(0); WRITE('dd');
          END;
     4:   BEGIN
               FOR Loop := QuitButtonX1 TO QuitButtonX2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,QuitButtonY1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
                    GotoXY(Loop+1,QuitButtonY1+1);
                    WRITE('ß');
               END;
               GotoXY(QuitButtonX2+1,QuitButtonY1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(QuitButtonX1,QuitButtonY1); WRITE('  Q');
               TextColor_BS(0); WRITE('uit');
          END;
     6:   IF UseSelectButton THEN BEGIN
               FOR Loop := SelectButtonX1 TO SelectButtonX2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,SelectButtonY1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
                    GotoXY(Loop+1,SelectButtonY1+1);
                    WRITE('ß');
               END;
               GotoXY(SelectButtonX2+1,SelectButtonY1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(SelectButtonX1,SelectButtonY1); WRITE(' S');
               TextColor_BS(0); WRITE('elect');
          END;
     END;
     _ShowMouse;
END;


PROCEDURE PressPickListButton(Number: Byte);
VAR  Loop         : Word;
BEGIN
     _HideMouse;
     CASE Number OF
     7:   IF UseFileButton THEN BEGIN
               TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(FileButtonX1,FileButtonY1); WRITE('         ');
               GotoXY(FileButtonX1,FileButtonY1+1); WRITE('         ');
               TextBackGround_BS(7);
               GotoXY(FileButtonX1+1,FileButtonY1);
               TextColor_BS(4); WRITE(' F');
               TextColor_BS(0); WRITE('iles  ');
          END;
     1:   IF UseEditButton THEN BEGIN
               TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(EditButtonX1,EditButtonY1); WRITE('         ');
               GotoXY(EditButtonX1,EditButtonY1+1); WRITE('         ');
               TextBackGround_BS(7);
               GotoXY(EditButtonX1+1,EditButtonY1);
               TextColor_BS(4); WRITE('  E');
               TextColor_BS(0); WRITE('dit  ');
          END;
     2:   IF UseDeleteButton THEN BEGIN
               TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(DeleteButtonX1,DeleteButtonY1); WRITE('         ');
               GotoXY(DeleteButtonX1,DeleteButtonY1+1); WRITE('         ');
               TextBackGround_BS(7);
               GotoXY(DeleteButtonX1+1,DeleteButtonY1);
               TextColor_BS(4); WRITE(' D');
               TextColor_BS(0); WRITE('elete ');
          END;
     3:   IF UseInsertButton THEN BEGIN
               TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(InsertButtonX1,InsertButtonY1); WRITE('         ');
               GotoXY(InsertButtonX1,InsertButtonY1+1); WRITE('         ');
               TextBackGround_BS(7);
               GotoXY(InsertButtonX1+1,InsertButtonY1);
               TextColor_BS(4); WRITE(' I');
               TextColor_BS(0); WRITE('nsert ');
          END;
     4:   BEGIN
               TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(QuitButtonX1,QuitButtonY1); WRITE('         ');
               GotoXY(QuitButtonX1,QuitButtonY1+1); WRITE('         ');
               TextBackGround_BS(7);
               GotoXY(QuitButtonX1+1,QuitButtonY1);
               TextColor_BS(4); WRITE('  Q');
               TextColor_BS(0); WRITE('uit  ');
          END;
     5:   IF UseAddButton THEN BEGIN
               TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(AddButtonX1,AddButtonY1); WRITE('         ');
               GotoXY(AddButtonX1,AddButtonY1+1); WRITE('         ');
               TextBackGround_BS(7);
               GotoXY(AddButtonX1+1,AddButtonY1);
               TextColor_BS(4); WRITE('  A');
               TextColor_BS(0); WRITE('dd   ');
          END;
     6:   IF UseSelectButton THEN BEGIN
               TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(SelectButtonX1,SelectButtonY1); WRITE('         ');
               GotoXY(SelectButtonX1,SelectButtonY1+1); WRITE('         ');
               TextBackGround_BS(7);
               GotoXY(SelectButtonX1+1,SelectButtonY1);
               TextColor_BS(4); WRITE(' S');
               TextColor_BS(0); WRITE('elect ');
          END;
     END;
     _ShowMouse;
END;


PROCEDURE SetUpPickList(WindowTitle: String);
VAR
     Loop         : Word;
BEGIN
     IF UseTwoColumn=True THEN
     BEGIN
          DrawWindow(PickListX-5,PickListY,PickListX+64,PickListY+PickListPerPage+3,WindowTitle,True);
          _HideMouse;
          TextBackGround_BS(0);
          TextColor_BS(14);
          GotoXY(PickListX-4,PickListY+2);
          WRITE('###  ');
          WRITE(PickList_A_Title);
          WRITE(PickList_B_Title);
          TextBackGround_BS(Colour.WindowBackGround);
          ScrollBarX  := PickListX+52;
          ScrollBarY1 := PickListY+3;
          ScrollBarY2 := PickListY+2+PickListPerPage;
          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
          RESET(FPickListFile);
          SEEK(FPickListFile,PickTop-1);
          FOR Loop := 1 TO PickListPerPage DO
          BEGIN
               IF NOT(EOF(FPickListFile)) THEN
               BEGIN
                    IF (PickTop-1+Loop)=PickItem THEN TextBackGround_BS(3);
                    TextColor_BS(14);
                    GotoXY(PickListX-4,PickListY+2+Loop);
                    WRITE(_PadRight(_String(PickTop-1+Loop),6));
                    READ(FPickListFile,PickListFile);
               END
               ELSE
               BEGIN
                    GotoXY(PickListX-4,PickListY+2+Loop);
                    WRITE('      ');
                    PickListFile.A := '';
                    PickListFile.B := '';
               END;
               TextColor_BS(15);
               GotoXY(PickListX+2,PickListY+2+Loop);
               WRITE(_PadRight(PickListFile.A,40));
               TextColor_BS(11);
               GotoXY(PickListX+42,PickListY+2+Loop);
               WRITE(_PadRight(PickListFile.B,10));
               IF ((Loop<>1) AND (Loop<>PickListPerPage)) THEN
               BEGIN
                    TextColor_BS(8);
                    TextBackGround_BS(0);
                    GotoXY(PickListX+52,PickListY+2+Loop);
                    WRITE('²');
               END;
               TextBackGround_BS(Colour.WindowBackGround);
          END;
          CLOSE(FPickListFile);
          TextColor_BS(15);
          TextBackGround_BS(7);
          GotoXY(ScrollBarX,ScrollBarY1);
          WRITE(CHR(30));
          GotoXY(ScrollBarX,ScrollBarY2);
          WRITE(CHR(31));
          ScrollPadY := (ScrollBarY2-1)-(ScrollBarY1+1);
          ScrollPadY := ScrollPadY*(PickItem-1);
          IF PickListItems>1 THEN ScrollPadY := Round(ScrollPadY/(PickListItems-1))
                             ELSE ScrollPadY := 0;
          GotoXY(ScrollBarX,ScrollBarY1+1+ScrollPadY);
          TextColor_BS(15);
          TextBackGround_BS(7);
          WRITE(CHR(254));
          DrawPickListButtons;
          _ShowMouse;
     END;
END;


PROCEDURE UpdatePickList;
VAR  Loop    : Word;
     OldPadY : Word;
     CurBack : Byte;
     Temp    : String;
BEGIN
     OldPadY    := ScrollPadY;
     ScrollPadY := (ScrollBarY2-1)-(ScrollBarY1+1);
     ScrollPadY := ScrollPadY*(PickItem-1);
     IF PickListItems>1 THEN ScrollPadY := Round(ScrollPadY/(PickListItems-1))
                        ELSE ScrollPadY := 0;
     IF UseTwoColumn=True THEN
     BEGIN
          _HideMouse;
          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
          RESET(FPickListFile);
          SEEK(FPickListFile,PickTop-1);
          FOR Loop := 1 TO PickListPerPage DO
          BEGIN
               IF EOF(FPickListFile) THEN
               BEGIN
                    PickListFile.A := '';
                    PickListFile.B := '';
                    Temp           := '      ';
                    CurBack        := (Colour.WindowBackGround*16);
               END
               ELSE
               BEGIN
                    READ(FPickListFile,PickListFile);
                    IF (PickTop-1+Loop)=PickItem THEN CurBack := (3*16)
                                                 ELSE CurBack := (Colour.WindowBackGround*16);
                    Temp := _PadRight(_String(PickTop-1+Loop),6);
               END;
               FastWrite(Temp,PickListY+2+Loop,PickListX-4,CurBack+14);
               FastWrite(_PadRight(PickListFile.A,40),PickListY+2+Loop,PickListX+2,CurBack+15);
               FastWrite(_PadRight(PickListFile.B,10),PickListY+2+Loop,PickListX+42,CurBack+11);
               IF (OldPadY<>ScrollPadY) THEN
               BEGIN
                    IF ((Loop<>1) AND (Loop<>PickListPerPage)) THEN
                    BEGIN
                         FastWrite('²',PickListY+2+Loop,PickListX+52,8);
                    END;
               END;
          END;
          CLOSE(FPickListFile);
          IF (OldPadY<>ScrollPadY) THEN FastWrite(Chr(254),ScrollBarY1+1+ScrollPadY,ScrollBarX,(7*16)+15);
          _ShowMouse;
     END;
END;


FUNCTION DoPickList: Word;
VAR  Changes      : Boolean;
     c            : Char;
     Number       : Longint;
     Work         : Longint;
     LeftBox      : Boolean;
LABEL               ArrowUp,ArrowDown;
LABEL               PushButton1,PushButton2;
LABEL               PushButton3,PushButton4;
LABEL               PushButton5,PushButton6;
LABEL               PushButton7;
BEGIN
     Changes := False;
     Number  := 0;
     REPEAT
           MouseB := _MousePosition(Mouse_X,Mouse_Y);
           IF MouseB=1 THEN
           BEGIN
                IF ((Mouse_X>PickListX-5) AND (Mouse_X<PickListX+52)) THEN
                BEGIN
                     IF ((Mouse_Y>PickListY+2) AND (Mouse_Y<PickListY+PickListPerPage+3)) THEN
                     BEGIN
                          Work := Mouse_Y-(PickListY+2);
                          IF ((Work+PickTop-1<>PickItem) AND (Work+PickTop-1<=PickListItems)) THEN
                          BEGIN
                               PickItem := Work+PickTop-1;
                               UpdatePickList;
                          END;
                     END;
                END
                ELSE IF Mouse_X=ScrollBarX THEN
                BEGIN
                     IF Mouse_Y=ScrollBarY1 THEN GOTO ArrowUp
                        ELSE IF Mouse_Y=ScrollBarY2 THEN GOTO ArrowDown;
                END
                ELSE IF ((Mouse_X>=QuitButtonX1) AND (Mouse_X<=QuitButtonX2)) THEN
                BEGIN
                     IF (Mouse_Y=FileButtonY1) THEN
                     BEGIN
                          PressPickListButton(7);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>FileButtonY1) OR (Mouse_X<FileButtonX1) OR (Mouse_X>FileButtonX2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickListButton(7);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton7:
                               Number  := 7;
                               Changes := True;
                          END;
                     END
                     ELSE IF (Mouse_Y=EditButtonY1) THEN
                     BEGIN
                          PressPickListButton(1);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>EditButtonY1) OR (Mouse_X<EditButtonX1) OR (Mouse_X>EditButtonX2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickListButton(1);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton1:
                               Number  := 1;
                               Changes := True;
                          END;
                     END
                     ELSE IF (Mouse_Y=DeleteButtonY1) THEN
                     BEGIN
                          PressPickListButton(2);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>DeleteButtonY1) OR (Mouse_X<DeleteButtonX1) OR (Mouse_X>DeleteButtonX2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickListButton(2);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton2:
                               Number  := 2;
                               Changes := True;
                          END;
                     END
                     ELSE IF (Mouse_Y=SelectButtonY1) THEN
                     BEGIN
                          PressPickListButton(6);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>SelectButtonY1) OR (Mouse_X<SelectButtonX1) OR (Mouse_X>SelectButtonX2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickListButton(6);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton6:
                               Number  := 6;
                               Changes := True;
                          END;
                     END
                     ELSE IF (Mouse_Y=InsertButtonY1) THEN
                     BEGIN
                          PressPickListButton(3);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>InsertButtonY1) OR (Mouse_X<InsertButtonX1) OR (Mouse_X>InsertButtonX2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickListButton(3);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton3:
                               Number  := 3;
                               Changes := True;
                          END;
                     END
                     ELSE IF (Mouse_Y=AddButtonY1) THEN
                     BEGIN
                          PressPickListButton(5);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>AddButtonY1) OR (Mouse_X<AddButtonX1) OR (Mouse_X>AddButtonX2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickListButton(5);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton5:
                               Number  := 5;
                               Changes := True;
                          END;
                     END
                     ELSE IF (Mouse_Y=QuitButtonY1) THEN
                     BEGIN
                          PressPickListButton(4);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>QuitButtonY1) OR (Mouse_X<QuitButtonX1) OR (Mouse_X>QuitButtonX2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickListButton(4);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton4:
                               Number  := 0;
                               Changes := True;
                          END;
                     END;
                END;
           END;
           IF Keypressed THEN
           BEGIN
                c := ReadKey;
                IF ORD(c)=0 THEN
                BEGIN
                     c := ReadKey;
                     CASE ORD(c) OF
                     68 : DumpTheScreen;
                     60 : ShellToDos;
                     45:  ShutDown;
                     73:  BEGIN {PageUp}
                               IF (PickTop>PickListPerPage)
                                  THEN PickTop := (PickTop-PickListPerPage)
                                  ELSE PickTop := 1;
                               IF (PickItem<PickTop)
                                  THEN PickItem := PickTop
                                  ELSE IF (PickItem>(PickTop-1+PickListPerPage))
                                  THEN PickItem := PickTop-1+PickListPerPage;
                               UpdatePickList;
                          END;
                     81:  BEGIN {PageDown}
                               IF (PickTop<(PickListItems-PickListPerPage))
                                  THEN PickTop := (PickTop+PickListPerPage)
                                  ELSE PickTop := PickListItems;
                               IF (PickItem<PickTop)
                                  THEN PickItem := PickTop
                                  ELSE IF (PickItem>(PickTop-1+PickListPerPage))
                                  THEN PickItem := PickTop-1+PickListPerPage;
                               UpdatePickList;
                          END;
                     72:  BEGIN {ArrowUp}
                               ArrowUp:
                               IF PickItem>1 THEN
                               BEGIN
                                    DEC(PickItem);
                                    IF (PickItem<PickTop) THEN DEC(PickTop);
                                    UpdatePickList;
                               END;
                          END;
                     80:  BEGIN {ArrowDown}
                               ArrowDown:
                               IF PickItem<PickListItems THEN
                               BEGIN
                                    INC(PickItem);
                                    IF (PickItem>(PickTop-1+PickListPerPage)) THEN INC(PickTop);
                                    UpdatePickList;
                               END;
                          END;
                     132: BEGIN {CTRL-PgUp}
                               PickItem := 1;
                               PickTop  := 1;
                               UpdatePickList;
                          END;
                     118: BEGIN {CTRL-PgDn}
                               PickItem := PickListItems;
                               PickTop  := PickListItems;
                               UpdatePickList;
                          END;
                     82:  GOTO PushButton3;
                     83:  GOTO PushButton2;
                     18:  GOTO PushButton1;
                     32:  GOTO PushButton2;
                     23:  GOTO PushButton3;
                     16:  GOTO PushButton4;
                     30:  GOTO PushButton5;
                     31:  GOTO PushButton6;
                     33:  GOTO PushButton7;
                     END;
                END
                ELSE
                BEGIN
                     CASE ORD(c) OF
                     13,
                     32:  BEGIN
                               Number  := 1;
                               Changes := True;
                          END;
                     27:  BEGIN
                               Changes := True;
                               Number  := 0;
                          END;
                     END;
                END;
           END
           ELSE TimeSlice;
     UNTIL Changes;
     DoPickList := Number;
     IF PickItem>PickListItems THEN PickItem := PickListItems;
END;


FUNCTION Tags(Worker: Array Of Byte): String;
VAR
     Temp         : String;
     Loop         : Word;
BEGIN
     Temp := '';
     FOR Loop := 0 TO 9 DO
     BEGIN
          IF Worker[Loop]=1 THEN Temp := Temp+'1'
                            ELSE Temp := Temp+'0';
     END;
     Tags := Temp;
END;


FUNCTION FromBoolean(YesNo: Boolean): String;
BEGIN
     IF YesNo=True THEN FromBoolean := '1'
                   ELSE FromBoolean := '0';
END;


FUNCTION ToBoolean(YesNo: String): Boolean;
BEGIN
     IF YesNo='1' THEN ToBoolean := True
                  ELSE ToBoolean := False;
END;


PROCEDURE DisableObject(Number: Word);
VAR  sx1,sx2,sy1     : Word;
     Poop            : Word;
     Temp            : String;
BEGIN
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     sx1 := Objects^[Number].x1;
     sx2 := Objects^[Number].x2;
     sy1 := Objects^[Number].y1;
     GotoXY(sx1-1,sy1); WRITE(' ');
     GotoXY(sx2+1,sy1); WRITE(' ');

     TextBackGround_BS(Colour.EditBackGround);
     TextColor_BS(Colour.EditDisabled);
     GotoXY(sx1,sy1);
     IF Objects^[Number].ObjectType=3 THEN
     BEGIN
          WRITE(_Mid(Objects^[Number].Stuff,1,2));
          TextColor_BS(SpaceColour);
          GotoXY(Objects^[Number].x1+2,Objects^[Number].y1);
          WRITE(':');
          TextColor_BS(Colour.EditDisabled);
          GotoXY(Objects^[Number].x1+3,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,3,4));
     END
     ELSE IF Objects^[Number].ObjectType=5 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor_BS(Colour.EditDisabled);
          IF Objects^[Number].Stuff='1' THEN WRITE('MALE  ')
                                       ELSE WRITE('FEMALE');
     END
     ELSE IF Objects^[Number].ObjectType=6 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor_BS(Colour.EditDisabled);
          IF Objects^[Number].Stuff='1' THEN WRITE('YES')
                                       ELSE WRITE('NO ');
     END
     ELSE IF Objects^[Number].ObjectType=8 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor_BS(Colour.EditDisabled);
          Poop := Numeric(Objects^[Number].Stuff,ByteInteger);
          WRITE(Toggle[Poop].Flip[Toggle[Poop].Current]);
     END
     ELSE IF Objects^[Number].ObjectType=7 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          FOR Poop := 1 TO 10 DO
          BEGIN
               IF Objects^[Number].Stuff[Poop]='1' THEN
               BEGIN
                    TextColor_BS(Colour.EditDisabled);
                    WRITE(CHR(254));
               END
               ELSE
               BEGIN
                    TextColor_BS(SpaceColour);
                    WRITE(SpaceChar);
               END;
          END;
     END
     ELSE IF Objects^[Number].ObjectType=4 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor_BS(SpaceColour);
          WRITE('  /  /    ');
          TextColor_BS(Colour.EditDisabled);
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,1,2));
          GotoXY(Objects^[Number].x1+3,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,3,4));
          GotoXY(Objects^[Number].x1+6,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,5,8));
     END
     ELSE WRITE(Objects^[Number].Stuff);
     _ShowMouse;
END;


PROCEDURE EnableObject(Number: Word);
VAR  sx1,sx2,sy1     : Word;
     Poop            : Word;
BEGIN
     IF Objects^[Number].ObjectType=9 THEN
     BEGIN
          _HideCursor;
          Exit;
     END;
     EditPos := Length(Objects^[Number].Stuff)+1;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     sx1 := Objects^[Number].x1;
     sx2 := Objects^[Number].x2;
     sy1 := Objects^[Number].y1;
     GotoXY(sx1-1,sy1); WRITE('[');
     GotoXY(sx2+1,sy1); WRITE(']');
     TextBackGround_BS(Colour.EditBackGround);
     TextColor_BS(Colour.EditEnabled);
     GotoXY(sx1,sy1);
     IF Objects^[Number].ObjectType=3 THEN
     BEGIN
          WRITE(_Mid(Objects^[Number].Stuff,1,2));
          TextColor_BS(SpaceColour);
          GotoXY(Objects^[Number].x1+2,Objects^[Number].y1);
          WRITE(':');
          TextColor_BS(Colour.EditEnabled);
          GotoXY(Objects^[Number].x1+3,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,3,4));
               IF LENGTH(Objects^[Number].Stuff)=0 THEN GotoXY(sx1+0,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=1 THEN GotoXY(sx1+1,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=2 THEN GotoXY(sx1+3,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=3 THEN GotoXY(sx1+4,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=4 THEN GotoXY(sx1+5,sy1);
     END
     ELSE IF Objects^[Number].ObjectType=5 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor_BS(Colour.EditEnabled);
          IF Objects^[Number].Stuff='1' THEN WRITE('MALE  ')
                                       ELSE WRITE('FEMALE');
     END
     ELSE IF Objects^[Number].ObjectType=6 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor_BS(Colour.EditEnabled);
          IF Objects^[Number].Stuff='1' THEN WRITE('YES')
                                       ELSE WRITE('NO ');
     END
     ELSE IF Objects^[Number].ObjectType=7 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          FOR Poop := 1 TO 10 DO
          BEGIN
               IF Objects^[Number].Stuff[Poop]='1' THEN
               BEGIN
                    TextColor_BS(Colour.EditEnabled);
                    WRITE(CHR(254));
               END
               ELSE
               BEGIN
                    TextColor_BS(SpaceColour);
                    WRITE(SpaceChar);
               END;
          END;
     END
     ELSE IF Objects^[Number].ObjectType=8 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor_BS(Colour.EditEnabled);
          Poop := Numeric(Objects^[Number].Stuff,ByteInteger);
          WRITE(Toggle[Poop].Flip[Toggle[Poop].Current]);
     END
     ELSE IF Objects^[Number].ObjectType=4 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor_BS(SpaceColour);
          WRITE('  /  /    ');
          TextColor_BS(Colour.EditEnabled);
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,1,2));
          GotoXY(Objects^[Number].x1+3,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,3,4));
          GotoXY(Objects^[Number].x1+6,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,5,8));
               IF LENGTH(Objects^[Number].Stuff)=0 THEN GotoXY(sx1+0,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=1 THEN GotoXY(sx1+1,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=2 THEN GotoXY(sx1+3,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=3 THEN GotoXY(sx1+4,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=4 THEN GotoXY(sx1+6,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=5 THEN GotoXY(sx1+7,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=6 THEN GotoXY(sx1+8,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=7 THEN GotoXY(sx1+9,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=8 THEN GotoXY(sx1+10,sy1);
     END
     ELSE WRITE(Objects^[Number].Stuff);
     _ShowMouse;
          IF Objects^[Number].ObjectType=5 THEN _HideCursor
     ELSE IF Objects^[Number].ObjectType=6 THEN _HideCursor
     ELSE IF Objects^[Number].ObjectType=7 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          _ShowCursor
     END
     ELSE IF Objects^[Number].ObjectType=8 THEN _HideCursor
                                           ELSE _ShowCursor;
END;


PROCEDURE UpdateObject(Number: Word);
VAR  sx1,sx2,sx3,sy1     : Word;
     Loop                : Word;
     Poop                : Word;
     xxx                 : Word;
     yyy                 : Word;
     Temp                : String;
BEGIN
     IF Objects^[Number].ObjectType=9 THEN
     BEGIN
          _HideCursor;
          Exit;
     END;
     xxx := WhereX;
     yyy := WhereY;
     _HideMouse;
     _HideCursor;
     IF DoingMessageEdit THEN
     BEGIN
          TextBackGround_BS(Colour.WindowBackGround);
          TextColor_BS(14);
          GotoXY(28,18);
          IF Objects^[AddressField].Stuff<>'' THEN
          BEGIN
               IF (SaveAddress<>Objects^[AddressField].Stuff) THEN
               BEGIN
                    SaveAddress := Objects^[AddressField].Stuff;
                    WRITE(_PadRight(GetNetAddress(Numeric(Objects^[AddressField].Stuff,WordInteger))+
                         '@'+GetNetDomain(Numeric(Objects^[AddressField].Stuff,WordInteger)),45));
               END;
          END
          ELSE WRITE(_PadRight('',45));
          GotoXY(28,19);
          IF Objects^[OriginField].Stuff<>'' THEN
          BEGIN
               IF (SaveOrigin<>Objects^[OriginField].Stuff) THEN
               BEGIN
                    SaveOrigin := Objects^[OriginField].Stuff;
                    Temp := _Mid(GetNetOrigin(Numeric(Objects^[OriginField].Stuff,WordInteger)),1,43);
                    IF LENGTH(GetNetOrigin(Numeric(Objects^[OriginField].Stuff,WordInteger)))>43
                       THEN Temp := Temp+CHR(16);
                    WRITE(_PadRight(Temp,45));
               END;
          END
          ELSE WRITE(_PadRight('',45));
     END;
     IF DoingSubChange THEN
     BEGIN
          TextBackGround_BS(Colour.WindowBackGround);
          TextColor_BS(14);
          GotoXY(31,18);
          IF Objects^[SubAddressField].Stuff<>'' THEN
          BEGIN
               IF (SaveAddress<>Objects^[SubAddressField].Stuff) THEN
               BEGIN
                    SaveAddress := Objects^[SubAddressField].Stuff;
                    WRITE(_PadRight(GetNetAddress(Numeric(Objects^[SubAddressField].Stuff,WordInteger))+
                         '@'+GetNetDomain(Numeric(Objects^[SubAddressField].Stuff,WordInteger)),45));
               END;
          END
          ELSE WRITE(_PadRight('',45));
          GotoXY(31,19);
          IF Objects^[SubOriginField].Stuff<>'' THEN
          BEGIN
               IF (SaveOrigin<>Objects^[SubOriginField].Stuff) THEN
               BEGIN
                    SaveOrigin := Objects^[SubOriginField].Stuff;
                    Temp := _Mid(GetNetOrigin(Numeric(Objects^[SubOriginField].Stuff,WordInteger)),1,43);
                    IF LENGTH(GetNetOrigin(Numeric(Objects^[SubOriginField].Stuff,WordInteger)))>43
                       THEN Temp := Temp+CHR(16);
                    WRITE(_PadRight(Temp,45));
               END;
          END
          ELSE WRITE(_PadRight('',45));
     END;
     IF DoingMessageChange THEN
     BEGIN
          TextBackGround_BS(Colour.WindowBackGround);
          TextColor_BS(14);
          GotoXY(31,17);
          IF Objects^[ChangeAddressField].Stuff<>'' THEN
          BEGIN
               IF (SaveAddress<>Objects^[ChangeAddressField].Stuff) THEN
               BEGIN
                    SaveAddress := Objects^[ChangeAddressField].Stuff;
                    WRITE(_PadRight(GetNetAddress(Numeric(Objects^[ChangeAddressField].Stuff,WordInteger))+
                         '@'+GetNetDomain(Numeric(Objects^[ChangeAddressField].Stuff,WordInteger)),45));
               END;
          END
          ELSE WRITE(_PadRight('',45));
          GotoXY(31,18);
          IF Objects^[ChangeOriginField].Stuff<>'' THEN
          BEGIN
               IF (SaveOrigin<>Objects^[ChangeOriginField].Stuff) THEN
               BEGIN
                    SaveOrigin := Objects^[ChangeOriginField].Stuff;
                    Temp := _Mid(GetNetOrigin(Numeric(Objects^[ChangeOriginField].Stuff,WordInteger)),1,43);
                    IF LENGTH(GetNetOrigin(Numeric(Objects^[ChangeOriginField].Stuff,WordInteger)))>43
                       THEN Temp := Temp+CHR(16);
                    WRITE(_PadRight(Temp,45));
               END;
          END
          ELSE WRITE(_PadRight('',45));
     END;
     IF DoingLinksEdit THEN
     BEGIN
          TextBackGround_BS(Colour.WindowBackGround);
          TextColor_BS(14);
          GotoXY(26,5);
          IF Objects^[LinksAddressField].Stuff<>'' THEN
          BEGIN
               IF (SaveAddress<>Objects^[LinksAddressField].Stuff) THEN
               BEGIN
                    SaveAddress := Objects^[LinksAddressField].Stuff;
                    WRITE(_PadRight(GetNetAddress(Numeric(Objects^[LinksAddressField].Stuff,WordInteger))+
                         '@'+GetNetDomain(Numeric(Objects^[LinksAddressField].Stuff,WordInteger)),28));
               END;
          END
          ELSE WRITE(_PadRight('',28));
     END;
     sx1 := Objects^[Number].x1;
     sx2 := Objects^[Number].x2;
     sy1 := Objects^[Number].y1;
     TextBackGround_BS(Colour.EditBackGround);
     TextColor_BS(Colour.EditEnabled);
     GotoXY(sx1,sy1);
     IF Objects^[Number].ObjectType=3 THEN
     BEGIN
          TextColor_BS(SpaceColour);
          FOR Loop := sx1 TO sx2 DO WRITE(SpaceChar);
          TextColor_BS(Colour.EditEnabled);
          GotoXY(sx1,sy1); WRITE(_Mid(Objects^[Number].Stuff,1,2));
          TextColor_BS(SpaceColour);
          GotoXY(sx1+2,sy1); WRITE(':');
          TextColor_BS(Colour.EditEnabled);
          GotoXY(sx1+3,sy1); WRITE(_Mid(Objects^[Number].Stuff,3,4));
               IF LENGTH(Objects^[Number].Stuff)=0 THEN GotoXY(sx1+0,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=1 THEN GotoXY(sx1+1,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=2 THEN GotoXY(sx1+3,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=3 THEN GotoXY(sx1+4,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=4 THEN GotoXY(sx1+5,sy1);
     END
     ELSE IF Objects^[Number].ObjectType=5 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor_BS(Colour.EditEnabled);
          IF Objects^[Number].Stuff='1' THEN WRITE('MALE  ')
                                       ELSE WRITE('FEMALE');
     END
     ELSE IF Objects^[Number].ObjectType=6 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor_BS(Colour.EditEnabled);
          IF Objects^[Number].Stuff='1' THEN WRITE('YES')
                                       ELSE WRITE('NO ');
     END
     ELSE IF Objects^[Number].ObjectType=8 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          Poop := Numeric(Objects^[Number].Stuff,ByteInteger);
          TextColor_BS(SpaceColour);
          FOR Loop := 1 TO 20 DO WRITE(SpaceChar);
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor_BS(Colour.EditEnabled);
          WRITE(Toggle[Poop].Flip[Toggle[Poop].Current]);
     END
     ELSE IF Objects^[Number].ObjectType=7 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          FOR Poop := 1 TO 10 DO
          BEGIN
               IF Objects^[Number].Stuff[Poop]='1' THEN
               BEGIN
                    TextColor_BS(Colour.EditEnabled);
                    WRITE(CHR(254));
               END
               ELSE
               BEGIN
                    TextColor_BS(SpaceColour);
                    WRITE(SpaceChar);
               END;
          END;
     END
     ELSE IF Objects^[Number].ObjectType=4 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor_BS(SpaceColour);
          WRITE('  /  /    ');
          TextColor_BS(Colour.EditEnabled);
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,1,2));
          GotoXY(Objects^[Number].x1+3,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,3,4));
          GotoXY(Objects^[Number].x1+6,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,5,8));
               IF LENGTH(Objects^[Number].Stuff)=0 THEN GotoXY(sx1+0,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=1 THEN GotoXY(sx1+1,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=2 THEN GotoXY(sx1+3,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=3 THEN GotoXY(sx1+4,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=4 THEN GotoXY(sx1+6,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=5 THEN GotoXY(sx1+7,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=6 THEN GotoXY(sx1+8,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=7 THEN GotoXY(sx1+9,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=8 THEN GotoXY(sx1+10,sy1);
     END
     ELSE
     BEGIN
          WRITE(Objects^[Number].Stuff);
          sx3 := WhereX;
          TextColor_BS(SpaceColour);
          IF sx3<=sx2 THEN FOR Loop := sx3 TO sx2 DO WRITE(SpaceChar);
          GotoXY(sx3,sy1);
     END;
          IF Objects^[Number].ObjectType=5 THEN _HideCursor
     ELSE IF Objects^[Number].ObjectType=6 THEN _HideCursor
     ELSE IF Objects^[Number].ObjectType=7 THEN
     BEGIN
          GotoXY(xxx,yyy);
          _ShowCursor;
     END
     ELSE IF Objects^[Number].ObjectType=8 THEN _HideCursor
                                           ELSE _ShowCursor;
     _ShowMouse;
END;


FUNCTION DoObjects: Word;
VAR  OuttaHere    : Boolean;
     x1,x2,y1     : Word;
     CursorX      : Word;
     c            : Char;
     work         : Word;
     TagNumber    : Word;
     OldX         : Word;
     OldY         : Word;
     LeftBox      : Boolean;
     xx1,yy1,xx2  : Word;
     FirstPart    : String;
     LastPart     : String;
     WhatToDo     : Word;
LABEL               MoveDown,Finished,JumpIn;
LABEL               ToggleGender,ToggleTags;
LABEL               ToggleFlips,UpToTop;
BEGIN
     CurrentObject   := 1;
     OuttaHere       := False;
     Escaped         := False;

     IF NumberOfObjects=0 THEN
     BEGIN
          DoingInputField := False;
          EnableButton(CurrentObject);
          _HideCursor;
     END
     ELSE
     BEGIN
          DoingInputField := True;
          EnableObject(CurrentObject);
     END;

     REPEAT
           UpToTop:
           MouseB := _MousePosition(Mouse_X,Mouse_Y);
           CASE MouseB OF
           1:   BEGIN
                     work   := FindButton(Mouse_X,Mouse_Y);
                     IF Work<>0 THEN
                     BEGIN
                          OldX := WhereX;
                          OldY := WhereY;
                          _HideCursor;
                          PressButton(Work);
                          LeftBox := False;
                          xx1 := Buttons^[Work].x1;
                          yy1 := Buttons^[Work].y1;
                          xx2 := Buttons^[Work].x2;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_X<xx1) OR (Mouse_X>xx2) OR (Mouse_Y<>yy1)) THEN LeftBox := True;
                          UNTIL ((MouseB=0) OR (LeftBox));
                          ReleaseButton(Work);
                          GotoXY(OldX,OldY);
                          IF DoingInputField THEN _ShowCursor;
                          IF NOT(LeftBox) THEN
                          BEGIN
                               DisableButton(Work);
                               DoObjects := Work;
                               OuttaHere := True;
                          END
                          ELSE IF ((Work=CurrentObject) AND (DoingInputField=False)) THEN EnableButton(CurrentObject);
                     END
                     ELSE
                     BEGIN
                          work := FindField(Mouse_X,Mouse_Y);
                          IF ((work=currentobject) AND (DoingInputField=True)) THEN
                          BEGIN
                               IF ((Objects^[CurrentObject].ObjectType=5) OR
                                  (Objects^[CurrentObject].ObjectType=6)) THEN
                               BEGIN
                                    GOTO ToggleGender;
                               END;
                               IF Objects^[CurrentObject].ObjectType=7 THEN GOTO ToggleTags;
                               IF Objects^[CurrentObject].ObjectType=8 THEN GOTO ToggleFlips;
                          END
                          ELSE IF (Work<>0) THEN
                          BEGIN
                               IF DoingInputField THEN DisableObject(CurrentObject)
                                                  ELSE DisableButton(CurrentObject);
                               CurrentObject   := Work;
                               DoingInputField := True;
                               EnableObject(CurrentObject);
                               IF ((Objects^[CurrentObject].ObjectType=5) OR
                                  (Objects^[CurrentObject].ObjectType=6) OR
                                  (Objects^[CurrentObject].ObjectType=8) OR
                                  (Objects^[CurrentObject].ObjectType=7)) THEN Delay(200);
                          END;
                     END;
                END;
           END;
           IF KeyPressed THEN
           BEGIN
                c := ReadKey;
                IF ORD(c)=0 THEN
                BEGIN
                     c := ReadKey;
                     CASE ORD(c) OF
                     71:  BEGIN {HOME}
                               IF ((Objects^[CurrentObject].ObjectType=1) OR
                                  (Objects^[CurrentObject].ObjectType=2)) THEN
                               BEGIN
                                    EditPos := 1;
                                    GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                               END;
                          END;
                     15,
                     72 : BEGIN
                               IF DoingInputField THEN
                               BEGIN
                                    DisableObject(CurrentObject);
                                    DEC(CurrentObject);
                                    IF CurrentObject=0 THEN
                                    BEGIN
                                         CurrentObject   := NumberOfButtons;
                                         DoingInputField := False;
                                         _HideCursor;
                                         EnableButton(CurrentObject);
                                    END
                                    ELSE EnableObject(CurrentObject);
                               END
                               ELSE
                               BEGIN
                                    DisableButton(CurrentObject);
                                    DEC(CurrentObject);
                                    IF CurrentObject=0 THEN
                                    BEGIN
                                         IF NumberOfObjects=0 THEN
                                         BEGIN
                                              CurrentObject   := NumberOfButtons;
                                              DoingInputField := False;
                                              EnableButton(CurrentObject);
                                         END
                                         ELSE
                                         BEGIN
                                              IF EditorActive THEN
                                              BEGIN
                                                   _HideMouse;
                                                   WhatToDo := FullEditor;
                                                   _ShowMouse;
                                                   CASE WhatToDo OF
                                                   3 :  BEGIN
                                                             INC(CurrentObject);
                                                             EnableButton(CurrentObject);
                                                             GOTO UpToTop;
                                                        END;
                                                   END;
                                              END;
                                              CurrentObject   := NumberOfObjects;
                                              DoingInputField := True;
                                              EnableObject(CurrentObject);
                                         END;
                                    END
                                    ELSE EnableButton(CurrentObject);
                               END;
                          END;
                     80 : GOTO MoveDown;
                     75 : BEGIN {LEFT ARROW}
                               IF (Objects^[CurrentObject].ObjectType=7) THEN
                               BEGIN
                                    Work := WhereX;
                                    IF Work>Objects^[CurrentObject].x1 THEN
                                    BEGIN
                                         DEC(Work);
                                         GotoXY(Work,Objects^[CurrentObject].y1);
                                    END;
                               END
                               ELSE IF ((Objects^[CurrentObject].ObjectType=1) OR
                                       (Objects^[CurrentObject].ObjectType=2)) THEN
                               BEGIN
                                    IF (EditPos>1) THEN
                                    BEGIN
                                         DEC(EditPos);
                                         GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                                    END;
                               END;
                          END;
                     77 : BEGIN {RIGHT ARROW}
                               IF (Objects^[CurrentObject].ObjectType=7) THEN
                               BEGIN
                                    Work := WhereX;
                                    IF Work<(Objects^[CurrentObject].x1+9) THEN
                                    BEGIN
                                         INC(Work);
                                         GotoXY(Work,Objects^[CurrentObject].y1);
                                    END;
                               END
                               ELSE IF ((Objects^[CurrentObject].ObjectType=1) OR
                                       (Objects^[CurrentObject].ObjectType=2)) THEN
                               BEGIN
                                    IF (EditPos<Length(Objects^[CurrentObject].Stuff)+1) THEN
                                    BEGIN
                                         INC(EditPos);
                                         GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                                    END;
                               END;
                          END;
                     79:  BEGIN {END}
                               IF ((Objects^[CurrentObject].ObjectType=1) OR
                                  (Objects^[CurrentObject].ObjectType=2)) THEN
                               BEGIN
                                    EditPos := Length(Objects^[CurrentObject].Stuff)+1;
                                    GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                               END;
                          END;
                     83 : BEGIN {DELETE}
                               IF ((Objects^[CurrentObject].ObjectType=1) OR
                                  (Objects^[CurrentObject].ObjectType=2)) THEN
                               BEGIN
                                    IF LENGTH(Objects^[CurrentObject].Stuff)=1 THEN
                                    BEGIN
                                         EditPos := 1;
                                         Objects^[CurrentObject].Stuff := '';
                                         UpdateObject(CurrentObject);
                                    END
                                    ELSE
                                    BEGIN
                                         FirstPart := _Mid(Objects^[CurrentObject].Stuff,1,EditPos-1);
                                         LastPart  := _Mid(Objects^[CurrentObject].Stuff,EditPos+1,
                                                           Length(Objects^[CurrentObject].Stuff));
                                         Objects^[CurrentObject].Stuff := FirstPart+LastPart;
                                         UpdateObject(CurrentObject);
                                         GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                                    END;
                               END;
                          END;
                     45 : ShutDown;
                     60 : ShellToDos;
                     68 : DumpTheScreen;
                     ELSE BEGIN
                               IF NumberOfButtons<>0 THEN
                               BEGIN
                                    FOR Work := 1 TO NumberOfButtons DO
                                    BEGIN
                                         IF ((Buttons^[Work].cc1=1) AND (Buttons^[Work].cc2=ORD(c))) THEN
                                         BEGIN
                                              IF DoingInputField THEN
                                              BEGIN
                                                   DisableObject(CurrentObject);
                                                   DoObjects := Work;
                                                   OuttaHere := True;
                                              END
                                              ELSE
                                              BEGIN
                                                   DisableButton(CurrentObject);
                                                   DoObjects := Work;
                                                   OuttaHere := True;
                                              END;
                                         END;
                                    END;
                               END;
                               IF NOT(OuttaHere) THEN
                               BEGIN
                                    C := IsTheKeyOk(C,True);
                                    IF (C<>#0) THEN GOTO JumpIn;
                               END;
                          END;
                     END;
                END
                ELSE
                BEGIN
                     CASE ORD(c) OF
                     8  : IF ((Objects^[CurrentObject].ObjectType<5) AND (DoingInputField)) THEN
                          BEGIN {BACKSPACE}
                               IF LENGTH(Objects^[CurrentObject].Stuff)=1 THEN
                               BEGIN
                                    EditPos := 1;
                                    Objects^[CurrentObject].Stuff := '';
                                    UpdateObject(CurrentObject);
                               END
                               ELSE
                               BEGIN
                                    IF ((Objects^[CurrentObject].ObjectType=1) OR
                                       (Objects^[CurrentObject].ObjectType=2)) THEN
                                    BEGIN
                                         IF (EditPos>1) THEN
                                         BEGIN
                                              FirstPart := _Mid(Objects^[CurrentObject].Stuff,1,EditPos-2);
                                              LastPart  := _Mid(Objects^[CurrentObject].Stuff,EditPos,
                                                           Length(Objects^[CurrentObject].Stuff));
                                              Objects^[CurrentObject].Stuff := FirstPart+LastPart;
                                              UpdateObject(CurrentObject);
                                              DEC(EditPos);
                                              GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                                         END;
                                    END
                                    ELSE
                                    BEGIN
                                         IF LENGTH(Objects^[CurrentObject].Stuff)>0 THEN
                                         BEGIN
                                              Objects^[CurrentObject].Stuff := _Mid(Objects^[CurrentObject].Stuff,1,
                                                                              Length(Objects^[CurrentObject].Stuff)-1);
                                              UpdateObject(CurrentObject);
                                         END;
                                    END;
                               END;
                          END;
                     9  : BEGIN {TAB}
                               MoveDown:
                               IF DoingInputField THEN
                               BEGIN
                                    DisableObject(CurrentObject);
                                    INC(CurrentObject);
                                    IF CurrentObject>NumberOfObjects THEN
                                    BEGIN
                                         IF EditorActive THEN
                                         BEGIN
                                              _HideMouse;
                                              WhatToDo := FullEditor;
                                              _ShowMouse;
                                              CASE WhatToDo OF
                                              4 :  BEGIN
                                                        DEC(CurrentObject);
                                                        EnableObject(CurrentObject);
                                                        GOTO UpToTop;
                                                   END;
                                              END;
                                         END;
                                         CurrentObject   := 1;
                                         DoingInputField := False;
                                         _HideCursor;
                                         EnableButton(CurrentObject);
                                    END
                                    ELSE EnableObject(CurrentObject);
                               END
                               ELSE
                               BEGIN
                                    DisableButton(CurrentObject);
                                    INC(CurrentObject);
                                    IF CurrentObject>NumberOfButtons THEN
                                    BEGIN
                                         IF NumberOfObjects=0 THEN
                                         BEGIN
                                              CurrentObject   := 1;
                                              DoingInputField := False;
                                              EnableButton(CurrentObject);
                                         END
                                         ELSE
                                         BEGIN
                                              CurrentObject   := 1;
                                              DoingInputField := True;
                                              EnableObject(CurrentObject);
                                         END;
                                    END
                                    ELSE EnableButton(CurrentObject);
                               END;
                          END;
                     13 : BEGIN
                               IF DoingInputField THEN
                               BEGIN
                                    GOTO MoveDown;
                               END
                               ELSE
                               BEGIN
                                    DisableButton(CurrentObject);
                                    DoObjects := CurrentObject;
                                    OuttaHere := True;
                               END;
                          END;
                     27 : BEGIN
                               Escaped := True;
                               Finished:
                               IF DoingInputField THEN
                               BEGIN
                                    DisableObject(CurrentObject);
                                    DoObjects := 1;
                                    OuttaHere := True;
                               END
                               ELSE
                               BEGIN
                                    DisableButton(CurrentObject);
                                    DoObjects := 1;
                                    OuttaHere := True;
                               END;
                          END;
                     127: IF ((Objects^[CurrentObject].ObjectType<5) AND (DoingInputField)) THEN
                          BEGIN
                               EditPos := 1;
                               Objects^[CurrentObject].Stuff := '';
                               UpdateObject(CurrentObject);
                          END;
                     ELSE BEGIN
                            C := IsTheKeyOk(C,False);
                            IF (C<>#0) THEN
                            BEGIN
                              JumpIn:
                              IF (Objects^[CurrentObject].ObjectType=1) THEN
                              BEGIN
                                IF LENGTH(Objects^[CurrentObject].Stuff)<Objects^[CurrentObject].ObjectLength THEN
                                BEGIN
                                  FirstPart := _Mid(Objects^[CurrentObject].Stuff,1,EditPos-1);
                                  LastPart  := _Mid(Objects^[CurrentObject].Stuff,EditPos,
                                               Length(Objects^[CurrentObject].Stuff));
                                  Objects^[CurrentObject].Stuff := FirstPart+C+LastPart;
                                  UpdateObject(CurrentObject);
                                  INC(EditPos);
                                  GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                                END;
                              END
                              ELSE IF (Objects^[CurrentObject].ObjectType=2) THEN
                              BEGIN
                                IF ((ORD(c)>47) AND (ORD(c)<58)) THEN
                                BEGIN
                                  IF LENGTH(Objects^[CurrentObject].Stuff)<Objects^[CurrentObject].ObjectLength THEN
                                  BEGIN
                                    FirstPart := _Mid(Objects^[CurrentObject].Stuff,1,EditPos-1);
                                    LastPart  := _Mid(Objects^[CurrentObject].Stuff,EditPos,
                                                 Length(Objects^[CurrentObject].Stuff));
                                    Objects^[CurrentObject].Stuff := FirstPart+C+LastPart;
                                    UpdateObject(CurrentObject);
                                    INC(EditPos);
                                    GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                                  END;
                                END;
                              END
                              ELSE IF ((Objects^[CurrentObject].ObjectType>2) AND
                                      (Objects^[CurrentObject].ObjectType<5)) THEN
                              BEGIN
                                IF ((ORD(c)>47) AND (ORD(c)<58)) THEN
                                BEGIN
                                  IF LENGTH(Objects^[CurrentObject].Stuff)<Objects^[CurrentObject].ObjectLength THEN
                                  BEGIN
                                    Objects^[CurrentObject].Stuff := Objects^[CurrentObject].Stuff+C;
                                    UpdateObject(CurrentObject);
                                  END;
                                END;
                              END
                              ELSE IF ((Objects^[CurrentObject].ObjectType=5) OR
                                      (Objects^[CurrentObject].ObjectType=6)) THEN
                              BEGIN
                                IF ORD(c)=32 THEN
                                BEGIN
                                  ToggleGender:
                                  IF Objects^[CurrentObject].Stuff='1' THEN Objects^[CurrentObject].Stuff := '0'
                                                                       ELSE Objects^[CurrentObject].Stuff := '1';
                                  UpdateObject(CurrentObject);
                                  Delay(200);
                                END;
                              END
                              ELSE IF (Objects^[CurrentObject].ObjectType=7) THEN
                              BEGIN
                                ToggleTags:
                                IF MouseB<>0 THEN
                                BEGIN
                                  GotoXY(Mouse_X,Mouse_Y);
                                  TagNumber := (Mouse_X-Objects^[CurrentObject].x1)+1;
                                  IF Objects^[CurrentObject].Stuff[TagNumber]='1'
                                    THEN Objects^[CurrentObject].Stuff[TagNumber] := '0'
                                    ELSE Objects^[CurrentObject].Stuff[TagNumber] := '1';
                                  UpdateObject(CurrentObject);
                                  Delay(200);
                                END
                                ELSE
                                BEGIN
                                  TagNumber := (WhereX-Objects^[CurrentObject].x1)+1;
                                  IF Objects^[CurrentObject].Stuff[TagNumber]='1'
                                    THEN Objects^[CurrentObject].Stuff[TagNumber] := '0'
                                    ELSE Objects^[CurrentObject].Stuff[TagNumber] := '1';
                                  UpdateObject(CurrentObject);
                                  Delay(200);
                                END;
                              END
                              ELSE IF (Objects^[CurrentObject].ObjectType=8) THEN
                              BEGIN
                                IF ORD(c)=32 THEN
                                BEGIN
                                  ToggleFlips:
                                  TagNumber := Numeric(Objects^[CurrentObject].Stuff,ByteInteger);
                                  INC(Toggle[TagNumber].Current);
                                  IF Toggle[TagNumber].Current>Toggle[TagNumber].Flips
                                     THEN Toggle[TagNumber].Current := 1;
                                  UpdateObject(CurrentObject);
                                  Delay(200);
                                  IF DoingOpeningEdit THEN
                                  BEGIN
                                    DoObjects := 0;
                                    OuttaHere := True;
                                  END;
                                END;
                              END;
                            END;
                          END;
                     END;
                END;
           END
           ELSE TimeSlice;
     UNTIL OuttaHere;
     _HideCursor;
END;


{Unpacks DateTime record into a MMDDYY string}
FUNCTION UnpackedDate(Work: Longint): String;
VAR  DT       : DateTime;
     DD,MM,YY : String;
BEGIN
     UnpackTime(Work,DT);
     WITH DT DO
     BEGIN
          DD := _String(Day);
          MM := _String(Month);
          YY := _String(Year);
     END;
     IF Length(MM)=1 THEN MM := '0'+MM;
     IF Length(DD)=1 THEN DD := '0'+DD;
     UnpackedDate := MM+DD+YY;
END;


{Unpacks DateTime record into a MM-DD-YY string}
FUNCTION UnpackedDate2(Work: Longint): String;
VAR  DT       : DateTime;
     DD,MM,YY : String;
BEGIN
     UnpackTime(Work,DT);
     WITH DT DO
     BEGIN
          DD := _String(Day);
          MM := _String(Month);
          YY := _String(Year);
     END;
     IF Length(MM)=1 THEN MM := '0'+MM;
     IF Length(DD)=1 THEN DD := '0'+DD;
     UnpackedDate2 := MM+'-'+DD+'-'+YY;
END;


FUNCTION PackedDate(InString: String): Longint;
VAR  WorkTime : Longint;
     DT       : DateTime;
BEGIN
     FillChar(DT,SizeOf(DT),0);
     WITH DT DO
     BEGIN
          Year  := _Numeric(_Mid(InString,5,8));
          Month := _Numeric(_Mid(InString,1,2));
          Day   := _Numeric(_Mid(InString,3,4));
     END;
     PackTime(DT,WorkTime);
     PackedDate := WorkTime;
END;


{GET DATE FOR FILES}
FUNCTION PROPER_DATE: Longint;
VAR  DT           : DateTime;
     WorkDate     : Longint;
     yy,mm,dd,dow : Word;
     h,m,s,s100   : Word;
BEGIN
     GetDate(yy,mm,dd,dow);
     GetTime(h,m,s,s100);
     FillChar(DT,SizeOf(DT),0);
     DT.Year  := yy;
     DT.Month := mm;
     DT.Day   := dd;
     DT.Hour  := h;
     DT.Min   := m;
     DT.Sec   := s;
     PackTime(DT,WorkDate);
     proper_date := WorkDate;
END;


FUNCTION PROPER_DATE_NOTIME: Longint;
VAR  DT           : DateTime;
     WorkDate     : Longint;
     yy,mm,dd,dow : Word;
BEGIN
     GetDate(yy,mm,dd,dow);
     FillChar(DT,SizeOf(DT),0);
     DT.Year  := yy;
     DT.Month := mm;
     DT.Day   := dd;
     PackTime(DT,WorkDate);
     proper_date_notime := WorkDate;
END;


FUNCTION NoDrive(InString: String): String;
BEGIN
     IF InString[2]=':' THEN Delete(InString,1,2);
     NoDrive := InString;
END;


PROCEDURE DrawWindow(x1,y1,x2,y2: Word; Title: String; Shad: Boolean);
VAR  LoopY  : Word;
BEGIN
     _HideMouse;
     IF Shad THEN Shadow(x1,y1,x2,y2);
     FOR LoopY := y1 TO y2 DO
     BEGIN
          IF LoopY=y1 THEN
          BEGIN
               FastWrite('Ú',LoopY,x1,25);
               FastWrite('¿',LoopY,x2,16);
          END
          ELSE IF LoopY=y2 THEN
          BEGIN
               FastWrite('À',LoopY,x1,25);
               FastWrite(_Replicate('Ä',x2-x1-1),LoopY,x1+1,16);
               FastWrite('Ù',LoopY,x2,16);
          END
          ELSE
          BEGIN
               FastWrite('³',LoopY,x1,25);
               FastWrite(_PadRight('',x2-x1-1),LoopY,x1+1,16);
               FastWrite('³',LoopY,x2,16);
          END;
     END;
     Title := '  '+Title;
     Title := _PadRight(Title,x2-x1-1);
     FastWrite(Title,y1,x1+1,(Colour.WindowHeader*16)+Colour.WindowHeaderText);
     _ShowMouse;
END;


PROCEDURE InvertedBox(x1,y1,x2,y2: Word);
VAR  Loop : Word;
BEGIN
     TextBackground_BS(1);
     TextColor_BS(0);
     GotoXY(x1,y1);
     WRITE('Ú');
     FOR Loop := x1+1 TO x2-1 DO WRITE('Ä');
     TextColor_BS(9);
     WRITE('¿');
     FOR Loop := y1+1 TO y2-1 DO
     BEGIN
          GotoXY(x1,loop);
          TextColor_BS(0);  WRITE('³');
          GotoXY(x2,loop);
          TextColor_BS(9); WRITE('³');
     END;
     GotoXY(x1,y2);
     TextColor_BS(0);  WRITE('À');
     TextColor_BS(9);
     FOR Loop := x1+1 TO x2-1 DO WRITE('Ä');
     WRITE('Ù');
END;


END.
