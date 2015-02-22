{$I DEFINES.INC}
UNIT MENU6A;


INTERFACE


FUNCTION  DoLanguage                          : String;
FUNCTION  DoSelectMenu     (Language: String) : String;
PROCEDURE DoEditMenu       (FullFile: String);
PROCEDURE DoDumpMenus;
PROCEDURE DoAnsiColours;
PROCEDURE DoVgaColours;
PROCEDURE DoKeyCommands;


IMPLEMENTATION


USES IntrFace,BsMouse,BsString,BsFile,Crt,Defaults,CnfgVars,Dos,
     Pick,MenuOpt,Options,Dispatch,BsExec,Valid,EComms;


PROCEDURE EditLanguage(Number: Longint);
VAR  Loop : Word;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
     RESET(FLangDir);
     SEEK(FLangDir,Number-1);
     READ(FLangDir,LangDir);
     CLOSE(FLangDir);
     DrawWindow(23,9,78,16,'EDIT LANGUAGE',True);
     AddObject(36,11,1,40,LangDir.Name,True);
     AddObject(36,12,1,40,LangDir.Directory,True);
     AddButton(68,14,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(25,11); WRITE('Lang Name');
     GotoXY(25,12); WRITE('Directory');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     LangDir.Name      := Objects^[1].Stuff;
     LangDir.Directory := ValidateIt(Objects^[2].Stuff,'PATH');
     ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
     RESET(FLangDir);
     SEEK(FLangDir,Number-1);
     WRITE(FLangDir,LangDir);
     CLOSE(FLangDir);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE InsertLanguage(Number: Longint);
VAR  Counting : Longint;
BEGIN
     ASSIGN(FLangDir2,BaseDirectory+'\DATA\LANGUAGE.DAT');
     RENAME(FLangDir2,BaseDirectory+'\DATA\LANGUAGE.BAK');
     ASSIGN(FLangDir2,BaseDirectory+'\DATA\LANGUAGE.BAK');
     ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
     RESET(FLangDir2);
     REWRITE(FLangDir);
     Counting := 0;
     REPEAT
           READ(FLangDir2,LangDir);
           INC(Counting);
           IF Counting=Number THEN WRITE(FLangDir,LangDir2);
           WRITE(FLangDir,LangDir);
     UNTIL EOF(FLangDir2);
     CLOSE(FLangDir);
     CLOSE(FLangDir2);
     ERASE(FLangDir2);
END;


PROCEDURE DeleteLanguage(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\LANGUAGE.DAT',SizeOf(LangDir),Number);
END;


PROCEDURE AddLanguage;
BEGIN
     ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
     RESET(FLangDir);
     SEEK(FLangDir,FileSize(FLangDir));
     WRITE(FLangDir,LangDir2);
     CLOSE(FLangDir);
END;


FUNCTION DoLanguage: String;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
BEGIN
     DoLanguage      := '';
     PickListPerPage := 16;
     PickItem        := 1;
     PickTop         := 1;
     CheckFile('LANGUAGE.DAT');
     ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
     RESET(FLangDir);
     PickListItems := FileSize(FLangDir);
     CLOSE(FLangDir);
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := True;
     PickList_A_Title := _PadRight(' Language Name',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
     RESET(FLangDir);
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     REPEAT
           Read(FLangDir,LangDir);
           PickListFile.A := LangDir.Name;
           PickListFile.B := '';
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FLangDir);
     CLOSE(FLangDir);
     CLOSE(FPickListFile);
     SetUpPickList('LANGUAGE DIRECTORY EDITOR');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN {EDIT}
                     EditLanguage(PickItem);
                     ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
                     RESET(FLangDir);
                     PickListItems := FileSize(FLangDir);
                     CLOSE(FLangDir);
                     ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
                     RESET(FLangDir);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FLangDir,LangDir);
                           PickListFile.A := LangDir.Name;
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FLangDir);
                     CLOSE(FLangDir);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteLanguage(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
                          RESET(FLangDir);
                          PickListItems := FileSize(FLangDir);
                          CLOSE(FLangDir);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
                          RESET(FLangDir);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          REPEAT
                                Read(FLangDir,LangDir);
                                PickListFile.A := LangDir.Name;
                                PickListFile.B := '';
                                WRITE(FPickListFile,PickListFile);
                          UNTIL EOF(FLangDir);
                          CLOSE(FLangDir);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     InsertLanguage(PickItem);
                     EditLanguage(PickItem);
                     ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
                     RESET(FLangDir);
                     PickListItems := FileSize(FLangDir);
                     CLOSE(FLangDir);
                     ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
                     RESET(FLangDir);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FLangDir,LangDir);
                           PickListFile.A := LangDir.Name;
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FLangDir);
                     CLOSE(FLangDir);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     AddLanguage;
                     EditLanguage(PickListItems+1);
                     ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
                     RESET(FLangDir);
                     PickListItems := FileSize(FLangDir);
                     CLOSE(FLangDir);
                     ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
                     RESET(FLangDir);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FLangDir,LangDir);
                           PickListFile.A := LangDir.Name;
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FLangDir);
                     CLOSE(FLangDir);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           6:   BEGIN {SELECT}
                     ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
                     RESET(FLangDir);
                     SEEK(FLangDir,PickItem-1);
                     READ(FLangDir,LangDir);
                     CLOSE(FLangDir);
                     DoLanguage := LangDir.Directory;
                     OuttaHere  := True;
                END;
           45:  BEGIN                      {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


FUNCTION GetNewMenuName: String;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     DrawWindow(23,9,62,15,'NEW MENU NAME',True);
     AddObject(52,11,1,8,'',True);
     AddButton(52,13,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(25,11); WRITE('File Name (No Extension!)');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     GetNewMenuName := ValidateIt(Objects^[1].Stuff,'FILE');
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE EditMenuOption(TheMenuFile: String; Number: Word);
VAR  MadeChanges : Boolean;
     Loop        : Word;
BEGIN
     PickingListPerPage  := 16;
     PickingItem         := 1;
     PickingTop          := 1;
     PickingListTitle    := _PadRight(' Function Name',41);
     PickingListX        := 21;
     PickingListY        := 4;
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FMenu,TheMenuFile);
     RESET(FMenu);
     SEEK(FMenu,Number-1);
     READ(FMenu,Menu);
     CLOSE(FMenu);
     IF Menu.Option=0 THEN Menu.Option := 1;
     TheFunction := '';
     ASSIGN(FPickingListFile,WorkDir+'\PICKING.LST');
     REWRITE(FPickingListFile);
     FOR Loop := 1 TO NumberOfOptions DO
     BEGIN
          GetOption(Loop);
          IF O.N=Menu.Option THEN TheFunction := _Mid(O.V,15,LENGTH(O.V));
          PickingListFile.A := O.V;
          WRITE(FPickingListFile,PickingListFile);
     END;
     CLOSE(FPickingListFile);
     ASSIGN(FPickingListFile,WorkDir+'\PICKING.LST');
     RESET(FPickingListFile);
     PickingListItems := FileSize(FPickingListFile);
     CLOSE(FPickingListFile);
     REPEAT
           CASE Menu.Option OF
           1:   MadeChanges := EditOption1;
           6:   MadeChanges := EditOption6;
           8:   MadeChanges := EditOption8;
           15:  MadeChanges := EditOption15;
           18:  MadeChanges := EditOption18;
           35:  MadeChanges := EditOption35;
           39:  MadeChanges := EditOption39;
           44:  MadeChanges := EditOption44;
           95:  MadeChanges := EditOption95;
           96:  MadeChanges := EditOption96;
           102: MadeChanges := EditOption35;
           106: MadeChanges := EditOption106;
           108: MadeChanges := EditOption108;
           110: MadeChanges := EditOption110;
           111: MadeChanges := EditOption111;
           112: MadeChanges := EditOption112;
           113: MadeChanges := EditOption113;
           114: MadeChanges := EditOption114;
           115: MadeChanges := EditOption115;
           122: MadeChanges := EditOption122;
           ELSE BEGIN
                     MadeChanges := EditOptionAll;
                END;
           END;
     UNTIL NOT(MadeChanges);
     ASSIGN(FMenu,TheMenuFile);
     RESET(FMenu);
     SEEK(FMenu,Number-1);
     WRITE(FMenu,Menu);
     CLOSE(FMenu);
     LoadWindow(WorkDir+'\EDITACC.SCR');
     ERASE(FPickingListFile);
END;


PROCEDURE ClearMenuRecord;
BEGIN
     FillChar(Menu2,SizeOf(Menu2),0);
     Menu2.HotKey   := 'A';
     Menu2.Option   := 1;
     Menu2.Ansi     := 1;
     Menu2.Rip      := 1;
     Menu2.Svga     := 1;
END;


PROCEDURE CaptureDirectory(FullPath: String);
VAR  DirInfo   : SearchRec;
     MenuFound : String;
     GotOne    : Boolean;
     Menus     : Array[1..500] Of String[12];
     Counter   : Word;
     Loop      : Word;
     i,j       : Word;
     Temp      : String[12];
BEGIN
     Counter := 0;
     GotOne := False;
     FindFirst(FullPath+'\MENUS\*.MNU',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          INC(Counter);
          Menus[Counter] := DirInfo.Name;
          GotOne := True;
          FindNext(DirInfo);
     END;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF GotOne THEN
     BEGIN
          FOR i := 1 TO Counter DO
          BEGIN
               FOR j := 1 TO Counter DO
               BEGIN
                    IF (Menus[i]<Menus[j]) THEN
                    BEGIN
                         Temp     := Menus[i];
                         Menus[i] := Menus[j];
                         Menus[j] := Temp;
                    END;
               END;
          END;
          FOR Loop := 1 TO Counter DO
          BEGIN
               PickListFile.A := Menus[Loop];
               PickListFile.B := '';
               WRITE(FPickListFile,PickListFile);
          END;
          CLOSE(FPickListFile);
     END
     ELSE
     BEGIN
          CLOSE(FPickListFile);
          ERASE(FPickListFile);
     END;
END;


PROCEDURE EditGlobalMenu(TheMenuFile: String);
VAR  Loop : Word;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FMenu,TheMenuFile);
     RESET(FMenu);
     READ(FMenu,Menu);
     CLOSE(FMenu);
     Toggle[1].Flips   := 3;
     Toggle[1].Current := Menu.Tags[1];
     Toggle[1].Flip[1] := 'PLAIN COLUMNS';
     Toggle[1].Flip[2] := 'MULTI-GRID';
     Toggle[1].Flip[3] := 'SOLID GRID';
     Toggle[2].Flips   := 3;
     Toggle[2].Current := Menu.Tags[2];
     Toggle[2].Flip[1] := 'NORMAL';
     Toggle[2].Flip[2] := 'FILE AREA';
     Toggle[2].Flip[3] := 'MESSAGE AREA';
     DrawWindow(10,4,70,21,'MENU GLOBAL OPTIONS',True);
     AddObject(38,6 ,1,30,Menu.Title,True);
     AddObject(38,7 ,8,20,'1',True);
     AddObject(38,8 ,8,20,'2',True);
     AddObject(38,10,2,2 ,_String(Menu.Tags[3]),True);
     AddObject(38,11,2,2 ,_String(Menu.Tags[4]),True);
     AddObject(38,12,2,2 ,_String(Menu.Tags[5]),True);
     AddObject(38,13,2,2 ,_String(Menu.Tags[6]),True);
     AddObject(38,14,2,2 ,_String(Menu.Tags[7]),True);
     AddButton(60,19,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(18,6);  WRITE('   Menu Title Name');
     GotoXY(18,7);  WRITE('     Screen Layout');
     GotoXY(18,8);  WRITE('      Prompt Style');
     GotoXY(18,10); WRITE(' Header Foreground');
     GotoXY(18,11); WRITE(' Header BackGround');
     GotoXY(18,12); WRITE('     HotKey Colour');
     GotoXY(18,13); WRITE('    Bracket Colour');
     GotoXY(18,14); WRITE('Option Text Colour');
     GotoXY(16,16); WRITE(' 0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15  ');
     GotoXY(16,17);
     TextColor_BS(0);
     FOR Loop := 0 TO 15 DO
     BEGIN
          TextColor_BS(Loop);
          WRITE('ÛÛÛ');
     END;
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     Menu.Title   := Objects^[1].Stuff;
     Menu.Tags[1] := Toggle[1].Current;
     Menu.Tags[2] := Toggle[2].Current;
     Menu.Tags[3] := Numeric(Objects^[4].Stuff,ByteInteger);
     Menu.Tags[4] := Numeric(Objects^[5].Stuff,ByteInteger);
     Menu.Tags[5] := Numeric(Objects^[6].Stuff,ByteInteger);
     Menu.Tags[6] := Numeric(Objects^[7].Stuff,ByteInteger);
     Menu.Tags[7] := Numeric(Objects^[8].Stuff,ByteInteger);
     ASSIGN(FMenu,TheMenuFile);
     RESET(FMenu);
     WRITE(FMenu,Menu);
     CLOSE(FMenu);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteMenuOption(Number: Longint; FileName: String);
BEGIN
     _EraseFileRecord(FileName,SizeOf(Menu),Number);
END;


PROCEDURE InsertMenuOption(Number: Longint; FileName: String);
VAR  Counting : Longint;
BEGIN
     ClearMenuRecord;
     ASSIGN(FMenu,FileName);
     RENAME(FMenu,NoExtension(FileName)+'.BAK');
     ASSIGN(FMenu2,NoExtension(FileName)+'.BAK');
     ASSIGN(FMenu,FileName);
     RESET(FMenu2);
     REWRITE(FMenu);
     Counting := 0;
     REPEAT
           READ(FMenu2,Menu);
           INC(Counting);
           IF (Counting=Number) THEN WRITE(FMenu,Menu2);
           WRITE(FMenu,Menu);
     UNTIL EOF(FMenu2);
     CLOSE(FMenu);
     CLOSE(FMenu2);
     ERASE(FMenu2);
END;


PROCEDURE AddMenuOption(FileName: String);
VAR  Counting : Longint;
BEGIN
     ClearMenuRecord;
     ASSIGN(FMenu,FileName);
     RESET(FMenu);
     SEEK(FMenu,FileSize(FMenu));
     WRITE(FMenu,Menu2);
     CLOSE(FMenu);
END;


FUNCTION DoSelectMenu(Language: String): String;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
     Crap      : String;
BEGIN
     DoSelectMenu    := '';
     PickListPerPage := 16;
     PickItem        := 1;
     PickTop         := 1;
     CaptureDirectory(Language);
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     {$I-}RESET(FPickListFile);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FPickListFile);
          CLOSE(FPickListFile);
     END
     ELSE
     BEGIN
          ASSIGN(FMenu,Language+'\MENUS\MAIN.MNU');
          REWRITE(FMenu);
          WRITE(FMenu,Menu2);
          WRITE(FMenu,Menu2);
          CLOSE(FMenu);
          CaptureDirectory(Language);
          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
          RESET(FPickListFile);
          PickListItems := FileSize(FPickListFile);
          CLOSE(FPickListFile);
     END;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := False;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Menu Name',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     SetUpPickList('MENU EDITOR');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN {EDIT}
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     RESET(FPickListFile);
                     SEEK(FPickListFile,PickItem-1);
                     READ(FPickListFile,PickListFile);
                     CLOSE(FPickListFile);
                     DoSelectMenu := PickListFile.A;
                     OuttaHere    := True;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          RESET(FPickListFile);
                          SEEK(FPickListFile,PickItem-1);
                          READ(FPickListFile,PickListFile);
                          CLOSE(FPickListFile);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          Crap := Language+'\MENUS\'+PickListFile.A;
                          ASSIGN(FMenu,Crap);
                          ERASE(FMenu);
                          CaptureDirectory(Language);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          RESET(FPickListFile);
                          PickListItems := FileSize(FPickListFile);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           5:   BEGIN {ADD}
                     Crap := GetNewMenuName;
                     IF Crap<>'' THEN
                     BEGIN
                          Crap := Crap+'.MNU';
                          ASSIGN(FMenu,Language+'\MENUS\'+Crap);
                          REWRITE(FMenu);
                          Menu2.Title    := '';
                          Menu2.HotKey   := Chr(0);
                          Menu2.Option   := 0;
                          Menu2.Second   := '';
                          Menu2.Third    := '';
                          Menu2.Access   := 0;
                          Menu2.Tags[1]  := 1;
                          Menu2.Tags[2]  := 1;
                          Menu2.Tags[3]  := 15;
                          Menu2.Tags[4]  := 1;
                          Menu2.Tags[5]  := 14;
                          Menu2.Tags[6]  := 8;
                          Menu2.Tags[7]  := 7;
                          Menu2.Tags[8]  := 0;
                          Menu2.Tags[9]  := 0;
                          Menu2.Tags[10] := 0;
                          Menu2.Sub      := 0;
                          Menu2.Area     := 0;
                          WRITE(FMenu,Menu2);
                          CLOSE(FMenu);
                          DoSelectMenu := Crap;
                          OuttaHere    := True;
                     END;
                END;
           45:  BEGIN                      {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE DoEditMenu(FullFile: String);
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
BEGIN
     PickListPerPage  := 16;
     PickItem         := 1;
     PickTop          := 1;
     ASSIGN(FMenu,FullFile);
     RESET(FMenu);
     PickListItems := FileSize(FMenu);
     CLOSE(FMenu);
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Menu Option Name',41);
     PickList_B_Title := 'KeyPress  ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FMenu,FullFile);
     RESET(FMenu);
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     REPEAT
           Read(FMenu,Menu);
           IF FilePos(FMenu)=1 THEN
           BEGIN
                PickListFile.A := '<<GLOBAL MENU OPTIONS>>';
                PickListFile.B := '';
           END
           ELSE
           BEGIN
                PickListFile.A := Menu.Title;
                PickListFile.B := UpCase(Menu.HotKey);
           END;
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FMenu);
     CLOSE(FMenu);
     CLOSE(FPickListFile);
     SetUpPickList('MENU EDITOR - '+EditMenuFile);
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN                      {EDIT}
                     IF PickItem=1 THEN
                     BEGIN
                          EditGlobalMenu(FullFile);
                     END
                     ELSE
                     BEGIN
                          EditMenuOption(FullFile,PickItem);
                     END;
                     ASSIGN(FMenu,FullFile);
                     RESET(FMenu);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FMenu,Menu);
                           IF FilePos(FMenu)=1 THEN
                           BEGIN
                                PickListFile.A := '<<GLOBAL MENU OPTIONS>>';
                                PickListFile.B := '';
                           END
                           ELSE
                           BEGIN
                                PickListFile.A := Menu.Title;
                                PickListFile.B := UpCase(Menu.HotKey);
                           END;
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FMenu);
                     CLOSE(FMenu);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           2:   IF PickItem>1 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteMenuOption(PickItem,FullFile);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          ASSIGN(FMenu,FullFile);
                          RESET(FMenu);
                          PickListItems := FileSize(FMenu);
                          CLOSE(FMenu);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FMenu,FullFile);
                          RESET(FMenu);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          REPEAT
                                Read(FMenu,Menu);
                                IF FilePos(FMenu)=1 THEN
                                BEGIN
                                     PickListFile.A := '<<GLOBAL MENU OPTIONS>>';
                                     PickListFile.B := '';
                                END
                                ELSE
                                BEGIN
                                     PickListFile.A := Menu.Title;
                                     PickListFile.B := UpCase(Menu.HotKey);
                                END;
                                WRITE(FPickListFile,PickListFile);
                          UNTIL EOF(FMenu);
                          CLOSE(FMenu);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   IF PickItem>1 THEN
                BEGIN {INSERT}
                     InsertMenuOption(PickItem,FullFile);
                     EditMenuOption(FullFile,PickItem);
                     ASSIGN(FMenu,FullFile);
                     RESET(FMenu);
                     PickListItems := FileSize(FMenu);
                     CLOSE(FMenu);
                     IF PickTop>PickListItems THEN DEC(PickTop);
                     ASSIGN(FMenu,FullFile);
                     RESET(FMenu);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FMenu,Menu);
                           IF FilePos(FMenu)=1 THEN
                           BEGIN
                                PickListFile.A := '<<GLOBAL MENU OPTIONS>>';
                                PickListFile.B := '';
                           END
                           ELSE
                           BEGIN
                                PickListFile.A := Menu.Title;
                                PickListFile.B := UpCase(Menu.HotKey);
                           END;
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FMenu);
                     CLOSE(FMenu);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     AddMenuOption(FullFile);
                     EditMenuOption(FullFile,PickListItems+1);
                     ASSIGN(FMenu,FullFile);
                     RESET(FMenu);
                     PickListItems := FileSize(FMenu);
                     CLOSE(FMenu);
                     IF PickTop>PickListItems THEN DEC(PickTop);
                     ASSIGN(FMenu,FullFile);
                     RESET(FMenu);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FMenu,Menu);
                           IF FilePos(FMenu)=1 THEN
                           BEGIN
                                PickListFile.A := '<<GLOBAL MENU OPTIONS>>';
                                PickListFile.B := '';
                           END
                           ELSE
                           BEGIN
                                PickListFile.A := Menu.Title;
                                PickListFile.B := UpCase(Menu.HotKey);
                           END;
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FMenu);
                     CLOSE(FMenu);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           6:   ;
           45:  BEGIN                      {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE DoDumpMenus;
VAR  FFile   : Text;
     Temp    : String;
     DirInfo : SearchRec;
     AMenu   : String;
     SAnsi   : Array[0..1] Of String[10];
     SRip    : Array[0..1] Of String[10];
     SSVga   : Array[0..1] Of String[10];
BEGIN
     SAnsi[0] := '----  '; SAnsi[1] := 'ANSI  ';
     SRip[0]  := '----  '; SRip[1]  := 'RIP!  ';
     SSvga[0] := '----  '; SSvga[1] := 'SVGA  ';
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     DrawWindow(11,9,68,15,'DUMP MENU DEFINITIONS',True);
     AddObject(26,11,1,40,'',True);
     AddButton(58,13,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(13,11); WRITE('  Text File');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     IF Objects^[1].Stuff<>'' THEN
     BEGIN
          Temp := Objects^[1].Stuff;
          ASSIGN(FFile,Temp);
          REWRITE(FFile);
          FindFirst(SelectedLanguage+'\MENUS\*.MNU',Anyfile-Directory-VolumeID,DirInfo);
          WHILE DosError = 0 DO
          BEGIN
               AMenu := DirInfo.Name;
               ASSIGN(FMenu,SelectedLanguage+'\MENUS\'+AMenu);
               {$I-}RESET(FMenu);{$I+}
               IF IOResult=0 THEN
               BEGIN
                    READ(FMenu,Menu2);
                    WRITELN(FFile,'Menu Name: '+Menu2.Title+'  ('+AMenu+')');
                    WRITELN(FFile,'--------------------------------------------------------------------------------');
                    REPEAT
                          READ(FMenu,Menu2);
                          Temp := _PadRight(Menu2.Hotkey,4)+
                                  _PadRight(Menu2.Title,30)+
                                  _PadRight(_String(Menu2.Access),6)+
                                  SAnsi[Menu2.Ansi]+
                                  SRip[Menu2.Rip]+
                                  SSVga[Menu2.Svga];
                          WRITELN(FFile,Temp);
                    UNTIL EOF(FMenu);
                    CLOSE(FMenu);
                    WRITELN(FFile,'');
                    WRITELN(FFile,'');
               END;
               FindNext(DirInfo);
          END;
          CLOSE(FFile);
     END;
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DoAnsiColours;
VAR  Loop : Word;
BEGIN
     _SaveWindow(WorkDir+'\EDITUSER.SCR');
     CheckFile('COLOURS.ANS');
     ASSIGN(FColours,SelectedLanguage+'\LANG\COLOURS.ANS');
     RESET(FColours);
     READ(FColours,Colours);
     CLOSE(FColours);
     DrawWindow(1,2,80,24,'ANSI COLOUR CONFIGURATION - '+SelectedLanguage,False);
     AddObject(35,4 ,2,2,_String(Colours.InputFieldForeground),True);
     AddObject(35,5 ,2,2,_String(Colours.InputFieldBackGround),True);
     AddObject(35,6 ,2,2,_String(Colours.ChatSysop),True);
     AddObject(35,7 ,2,2,_String(Colours.ChatUser),True);
     AddObject(73,4 ,2,2,_String(Colours.OptionHotKey),True);
     AddObject(73,5 ,2,2,_String(Colours.OptionBracket),True);
     AddObject(73,6 ,2,2,_String(Colours.OptionText),True);
     AddObject(73,7 ,2,2,_String(Colours.SpinCursor),True);
     AddObject(35,9 ,2,2,_String(Colours.FileListNumber),True);
     AddObject(35,10,2,2,_String(Colours.FileListBracket),True);
     AddObject(35,11,2,2,_String(Colours.FileListFileName),True);
     AddObject(35,12,2,2,_String(Colours.FileListFileSize),True);
     AddObject(35,13,2,2,_String(Colours.FileListFileDate),True);
     AddObject(35,14,2,2,_String(Colours.FileListDescription1),True);
     AddObject(35,15,2,2,_String(Colours.FileListDescriptions),True);
     AddObject(35,16,2,2,_String(Colours.FileListTaggedFile),True);
     AddObject(35,17,2,2,_String(Colours.FileListOfflineFile),True);
     AddObject(35,18,2,2,_String(Colours.FileListSeperator),True);
     AddObject(73,9 ,2,2,_String(Colours.ViewQuoteMSGNumber),True);
     AddObject(73,10,2,2,_String(Colours.ViewQuoteMSGBracket),True);
     AddObject(73,11,2,2,_String(Colours.ViewQuoteMSGText),True);
     AddObject(73,12,2,2,_String(Colours.ReadMSGBodyColour),True);
     AddObject(73,13,2,2,_String(Colours.ReadMSGQuoteColour),True);
     AddObject(73,14,2,2,_String(Colours.ReadMSGTearColour),True);
     AddObject(73,15,2,2,_String(Colours.LineEditorFrame),True);
     AddObject(73,16,2,2,_String(Colours.LineEditorLineNumbers),True);
     AddObject(73,17,2,2,_String(Colours.LineEditorInfoText),True);
     AddObject(73,18,2,2,_String(Colours.LineEditorInfoData),True);
     AddObject(73,19,2,2,_String(Colours.LineEditorHeaderFore),True);
     AddObject(73,20,2,2,_String(Colours.LineEditorHeaderBack),True);
     AddButton(70,22,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(5,4);   WRITE(' User InputÄÂÄÄÄÄ Foreground');
     GotoXY(5,5);   WRITE('            ÀÄÄÄÄ Background');
     GotoXY(5,6);   WRITE(' Chat ModeÄÄÂÄÄÄÄÄÄÄÄÄ Sysop');
     GotoXY(5,7);   WRITE('            ÀÄÄÄÄÄÄÄÄÄÄ User');
     GotoXY(5,9);   WRITE('File ListsÄÄÂÄÄÄÄÄÄÄÄ Number');
     GotoXY(5,10);  WRITE('            ÃÄÄÄÄÄÄÄ Bracket');
     GotoXY(5,11);  WRITE('            ÃÄÄÄÄÄ File Name');
     GotoXY(5,12);  WRITE('            ÃÄÄÄÄÄ File Size');
     GotoXY(5,13);  WRITE('            ÃÄÄÄÄÄ File Date');
     GotoXY(5,14);  WRITE('            ÃÄÄÄ Desc Line 1');
     GotoXY(5,15);  WRITE('            ÃÄÄÄÄ Desc Lines');
     GotoXY(5,16);  WRITE('            ÃÄÄ Tagged Files');
     GotoXY(5,17);  WRITE('            ÃÄ Offline Files');
     GotoXY(5,18);  WRITE('            À File Seperator');
     GotoXY(44,4);  WRITE('System PromptsÄÂÄÄÄÄ HotKey');
     GotoXY(44,5);  WRITE('               ÃÄÄÄ Bracket');
     GotoXY(44,6);  WRITE('               ÀÄÄÄÄÄÄ Text');
     GotoXY(44,7);  WRITE('Spin CursorÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(44,9);  WRITE('View QuotesÄÂÄÄÄ MSG Number');
     GotoXY(44,10); WRITE('            ÃÄÄÄÄÄÄ Bracket');
     GotoXY(44,11); WRITE('            ÀÄÄÄ Quote Text');
     GotoXY(44,12); WRITE('Read MSGÄÄÄÄÂÄÄÄÄ Body Text');
     GotoXY(44,13); WRITE('            ÃÄÄÄ Quote Text');
     GotoXY(44,14); WRITE('            ÀÄÄ Tear/Kludge');
     GotoXY(44,15); WRITE('Line EditorÄÂÄÄÄÄÄÄÄÄ Frame');
     GotoXY(44,16); WRITE('            ÃÄ Line Numbers');
     GotoXY(44,17); WRITE('            ÃÄÄ Descriptors');
     GotoXY(44,18); WRITE('            ÃÄ Message Info');
     GotoXY(44,19); WRITE('            ÃÄÄ Header Fore');
     GotoXY(44,20); WRITE('            ÀÄÄ Header Back');
     TextColor_BS(9);
     GotoXY(2,8);   WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(2,21);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(12,22); WRITE(' 0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15  ');
     GotoXY(12,23);
     TextColor_BS(0);
     FOR Loop := 0 TO 15 DO
     BEGIN
          TextColor_BS(Loop);
          WRITE('ÛÛÛ');
     END;
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     Colours.InputFieldForeground  := Numeric(Objects^[1].Stuff,ByteInteger);
     Colours.InputFieldBackGround  := Numeric(Objects^[2].Stuff,ByteInteger);
     Colours.ChatSysop             := Numeric(Objects^[3].Stuff,ByteInteger);
     Colours.ChatUser              := Numeric(Objects^[4].Stuff,ByteInteger);
     Colours.OptionHotKey          := Numeric(Objects^[5].Stuff,ByteInteger);
     Colours.OptionBracket         := Numeric(Objects^[6].Stuff,ByteInteger);
     Colours.OptionText            := Numeric(Objects^[7].Stuff,ByteInteger);
     Colours.SpinCursor            := Numeric(Objects^[8].Stuff,ByteInteger);
     Colours.FileListNumber        := Numeric(Objects^[9].Stuff,ByteInteger);
     Colours.FileListBracket       := Numeric(Objects^[10].Stuff,ByteInteger);
     Colours.FileListFileName      := Numeric(Objects^[11].Stuff,ByteInteger);
     Colours.FileListFileSize      := Numeric(Objects^[12].Stuff,ByteInteger);
     Colours.FileListFileDate      := Numeric(Objects^[13].Stuff,ByteInteger);
     Colours.FileListDescription1  := Numeric(Objects^[14].Stuff,ByteInteger);
     Colours.FileListDescriptions  := Numeric(Objects^[15].Stuff,ByteInteger);
     Colours.FileListTaggedFile    := Numeric(Objects^[16].Stuff,ByteInteger);
     Colours.FileListOfflineFile   := Numeric(Objects^[17].Stuff,ByteInteger);
     Colours.FileListSeperator     := Numeric(Objects^[18].Stuff,ByteInteger);
     Colours.ViewQuoteMSGNumber    := Numeric(Objects^[19].Stuff,ByteInteger);
     Colours.ViewQuoteMSGBracket   := Numeric(Objects^[20].Stuff,ByteInteger);
     Colours.ViewQuoteMSGText      := Numeric(Objects^[21].Stuff,ByteInteger);
     Colours.ReadMSGBodyColour     := Numeric(Objects^[22].Stuff,ByteInteger);
     Colours.ReadMSGQuoteColour    := Numeric(Objects^[23].Stuff,ByteInteger);
     Colours.ReadMSGTearColour     := Numeric(Objects^[24].Stuff,ByteInteger);
     Colours.LineEditorFrame       := Numeric(Objects^[25].Stuff,ByteInteger);
     Colours.LineEditorLineNumbers := Numeric(Objects^[26].Stuff,ByteInteger);
     Colours.LineEditorInfoText    := Numeric(Objects^[27].Stuff,ByteInteger);
     Colours.LineEditorInfoData    := Numeric(Objects^[28].Stuff,ByteInteger);
     Colours.LineEditorHeaderFore  := Numeric(Objects^[29].Stuff,ByteInteger);
     Colours.LineEditorHeaderBack  := Numeric(Objects^[30].Stuff,ByteInteger);
     ASSIGN(FColours,SelectedLanguage+'\LANG\COLOURS.ANS');
     REWRITE(FColours);
     WRITE(FColours,Colours);
     CLOSE(FColours);
     LoadWindow(WorkDir+'\EDITUSER.SCR');
END;


PROCEDURE DoVgaColours;
VAR  Loop : Word;
BEGIN
     _SaveWindow(WorkDir+'\EDITUSER.SCR');
     CheckFile('COLOURS.VGA');
     ASSIGN(FColours2,SelectedLanguage+'\LANG\COLOURS.VGA');
     RESET(FColours2);
     READ(FColours2,Colours2);
     CLOSE(FColours2);
     Toggle[1].Flips   := 5;
     Toggle[1].Current := Colours2.InternalImage+1;
     Toggle[1].Flip[1] := 'NONE';
     Toggle[1].Flip[2] := 'CHECKER BOARD';
     Toggle[1].Flip[3] := 'OCEAN VIEW';
     Toggle[1].Flip[4] := 'DESERT';
     Toggle[1].Flip[5] := 'SPACE';
     DrawWindow(1,2,80,24,'SVGA COLOUR CONFIGURATION - '+SelectedLanguage,False);
     AddObject(27,4 ,2,2,_String(Colours2.ReadMsgBody),True);
     AddObject(27,5 ,2,2,_String(Colours2.ReadMsgQuote),True);
     AddObject(27,6 ,2,2,_String(Colours2.ReadMSGTearColour),True);
     AddObject(27,8 ,2,2,_String(Colours2.FileListFileName),True);
     AddObject(27,9 ,2,2,_String(Colours2.FileListFileSize),True);
     AddObject(27,10,2,2,_String(Colours2.FileListFileDate),True);
     AddObject(27,11,2,2,_String(Colours2.FileListDescription1),True);
     AddObject(27,12,2,2,_String(Colours2.FileListDescriptions),True);
     AddObject(27,13,2,2,_String(Colours2.FileListTaggedFile),True);
     AddObject(27,14,2,2,_String(Colours2.FileListOfflineFile),True);
     AddObject(27,16,2,2,_String(Colours2.PickListBack),True);
     AddObject(27,17,2,2,_String(Colours2.PickListFore),True);
     AddObject(27,18,2,2,_String(Colours2.PickHighlightBack),True);
     AddObject(27,19,2,2,_String(Colours2.PickHighlightFore),True);
     AddObject(57,4,8,20,'1',True);
     AddObject(57,6,2,2,_String(Colours2.DisabledBackground),True);
     AddObject(57,7,2,2,_String(Colours2.DisabledHighlight),True);
     AddObject(57,8,2,2,_String(Colours2.DisabledShadow),True);
     AddObject(57,9,2,2,_String(Colours2.DisabledText),True);
     AddObject(57,11,2,2,_String(Colours2.FileQueueName),True);
     AddObject(57,12,2,2,_String(Colours2.FileQueueDesc),True);
     AddObject(57,13,2,2,_String(Colours2.FileQueueSize),True);
     AddObject(57,14,2,2,_String(Colours2.FileQueueTime),True);
     AddObject(57,16,2,2,_String(Colours2.MsgListFrom),True);
     AddObject(57,17,2,2,_String(Colours2.MsgListTo),True);
     AddObject(57,18,2,2,_String(Colours2.MsgListSubject),True);
     AddObject(57,19,2,2,_String(Colours2.MsgListPrivate),True);
     AddButton(70,22,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(3,4);   WRITE('Read MSGÄÂÄÄ Body Text');
     GotoXY(3,5);   WRITE('         ÃÄ Quote Text');
     GotoXY(3,6);   WRITE('         À Tear/Kludge');
     GotoXY(3,8);   WRITE('File ÄÂÄÄÄÄÄ File Name');
     GotoXY(3,9);   WRITE('Lists ÃÄÄÄÄÄ File Size');
     GotoXY(3,10);  WRITE('      ÃÄÄÄÄÄ File Date');
     GotoXY(3,11);  WRITE('      ÃÄÄÄ Desc Line 1');
     GotoXY(3,12);  WRITE('      ÃÄÄÄÄ Desc Lines');
     GotoXY(3,13);  WRITE('      ÃÄÄ Tagged Files');
     GotoXY(3,14);  WRITE('      ÀÄ Offline Files');
     GotoXY(3,16);  WRITE('Pick ÄÂÄÄÄ Normal Back');
     GotoXY(3,17);  WRITE('Lists ÃÄÄÄ Normal Fore');
     GotoXY(3,18);  WRITE('      ÃÄ Selected Back');
     GotoXY(3,19);  WRITE('      ÀÄ Selected Fore');
     GotoXY(33,4);  WRITE('Background ImageÄÄÄÄÄÄ');
     GotoXY(33,6);  WRITE('Disabled ÄÂ Background');
     GotoXY(33,7);  WRITE('Windows   ÃÄ Highlight');
     GotoXY(33,8);  WRITE('          ÃÄÄÄÄ Shadow');
     GotoXY(33,9);  WRITE('          ÀÄÄÄÄÄÄ Text');
     GotoXY(33,11); WRITE('File ÄÄÄÂÄÄÄ File Name');
     GotoXY(33,12); WRITE('Queue   ÃÄ Description');
     GotoXY(33,13); WRITE('        ÃÄÄÄ File Size');
     GotoXY(33,14); WRITE('        ÀÄÄÄÄÄ DL Time');
     GotoXY(33,16); WRITE('MSG  ÄÄÄÂÄÄÄÄ Msg From');
     GotoXY(33,17); WRITE('Lists   ÃÄÄÄÄÄÄ Msg To');
     GotoXY(33,18); WRITE('        ÃÄ Msg Subject');
     GotoXY(33,19); WRITE('        ÀÄ Msg Private');
     TextColor_BS(9);
     GotoXY(2,21);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(12,22); WRITE(' 0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15  ');
     GotoXY(12,23);
     FOR Loop := 0 TO 15 DO
     BEGIN
          TextColor_BS(Loop);
          WRITE('ÛÛÛ');
     END;
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     Colours2.ReadMsgBody          := Numeric(Objects^[1].Stuff,ByteInteger);
     Colours2.ReadMsgQuote         := Numeric(Objects^[2].Stuff,ByteInteger);
     Colours2.ReadMSGTearColour    := Numeric(Objects^[3].Stuff,ByteInteger);
     Colours2.FileListFileName     := Numeric(Objects^[4].Stuff,ByteInteger);
     Colours2.FileListFileSize     := Numeric(Objects^[5].Stuff,ByteInteger);
     Colours2.FileListFileDate     := Numeric(Objects^[6].Stuff,ByteInteger);
     Colours2.FileListDescription1 := Numeric(Objects^[7].Stuff,ByteInteger);
     Colours2.FileListDescriptions := Numeric(Objects^[8].Stuff,ByteInteger);
     Colours2.FileListTaggedFile   := Numeric(Objects^[9].Stuff,ByteInteger);
     Colours2.FileListOfflineFile  := Numeric(Objects^[10].Stuff,ByteInteger);
     Colours2.PickListBack         := Numeric(Objects^[11].Stuff,ByteInteger);
     Colours2.PickListFore         := Numeric(Objects^[12].Stuff,ByteInteger);
     Colours2.PickHighlightBack    := Numeric(Objects^[13].Stuff,ByteInteger);
     Colours2.PickHighlightFore    := Numeric(Objects^[14].Stuff,ByteInteger);
     Colours2.InternalImage        := Toggle[1].Current-1;
     Colours2.DisabledBackground   := Numeric(Objects^[16].Stuff,ByteInteger);
     Colours2.DisabledHighlight    := Numeric(Objects^[17].Stuff,ByteInteger);
     Colours2.DisabledShadow       := Numeric(Objects^[18].Stuff,ByteInteger);
     Colours2.DisabledText         := Numeric(Objects^[19].Stuff,ByteInteger);
     Colours2.FileQueueName        := Numeric(Objects^[20].Stuff,ByteInteger);
     Colours2.FileQueueDesc        := Numeric(Objects^[21].Stuff,ByteInteger);
     Colours2.FileQueueSize        := Numeric(Objects^[22].Stuff,ByteInteger);
     Colours2.FileQueueTime        := Numeric(Objects^[23].Stuff,ByteInteger);
     Colours2.MsgListFrom          := Numeric(Objects^[24].Stuff,ByteInteger);
     Colours2.MsgListTo            := Numeric(Objects^[25].Stuff,ByteInteger);
     Colours2.MsgListSubject       := Numeric(Objects^[26].Stuff,ByteInteger);
     Colours2.MsgListPrivate       := Numeric(Objects^[27].Stuff,ByteInteger);
     ASSIGN(FColours2,SelectedLanguage+'\LANG\COLOURS.VGA');
     REWRITE(FColours2);
     WRITE(FColours2,Colours2);
     CLOSE(FColours2);
     LoadWindow(WorkDir+'\EDITUSER.SCR');
END;


PROCEDURE DoKeyCommands;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
BEGIN
     PickListPerPage  := 16;
     PickItem         := 1;
     PickTop          := 1;
     PickListItems    := 17;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := False;
     UseInsertButton  := False;
     UseAddButton     := False;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Screen File',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     PickListFile.B   := '';
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     PickListFile.A := 'File Area Selection';     WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'File Group Selection';    WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'File Area Listing';       WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'File Download Queue';     WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'Message Area Selection';  WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'Message Group Selection'; WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'Message Reader - Main';   WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'Message Reader - Search'; WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'Line Editor - Main';      WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'Line Editor - Msg Edit';  WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'Message Listing';         WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'Users Online';            WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'User List';               WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'User FileBox';            WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'Text File Viewer';        WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'Misc Prompts';            WRITE(FPickListFile,PickListFile);
     PickListFile.A := 'CD Rom Manager';          WRITE(FPickListFile,PickListFile);
     CLOSE(FPickListFile);
     SetUpPickList('KEY COMMAND EDITOR');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN {EDIT}
                     CASE PickItem OF
                     1:   Edit_FAREAS_CMD;
                     2:   Edit_FGROUPS_CMD;
                     3:   Edit_FLISTHDR_CMD;
                     4:   Edit_DLQUEUE_CMD;
                     5:   Edit_MAREAS_CMD;
                     6:   Edit_MGROUPS_CMD;
                     7:   Edit_READMAIL_CMD;
                     8:   Edit_READNEW_CMD;
                     9:   Edit_LINEEDIT_CMD;
                     10:  Edit_LEDIT_E_CMD;
                     11:  Edit_LISTMSGS_CMD;
                     12:  Edit_PAGEUSER_CMD;
                     13:  Edit_USERLIST_CMD;
                     14:  Edit_FILEBOX_CMD;
                     15:  Edit_READFILE_CMD;
                     16:  Edit_MISC_CMD;
                     17:  Edit_CDROMMAN_CMD;
                     END;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


END.
