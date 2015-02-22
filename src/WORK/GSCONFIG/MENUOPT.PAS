{$I DEFINES.INC}
UNIT MenuOpt;


INTERFACE


VAR  TheFunction : String;


FUNCTION SelectNewOption : Boolean;
FUNCTION EditOption1     : Boolean;
FUNCTION EditOption6     : Boolean;
FUNCTION EditOption8     : Boolean;
FUNCTION EditOption15    : Boolean;
FUNCTION EditOption18    : Boolean;
FUNCTION EditOption35    : Boolean;
FUNCTION EditOption39    : Boolean;
FUNCTION EditOption44    : Boolean;
FUNCTION EditOption95    : Boolean;
FUNCTION EditOption96    : Boolean;
FUNCTION EditOption106   : Boolean;
FUNCTION EditOption108   : Boolean;
FUNCTION EditOption110   : Boolean;
FUNCTION EditOption111   : Boolean;
FUNCTION EditOption112   : Boolean;
FUNCTION EditOption113   : Boolean;
FUNCTION EditOption114   : Boolean;
FUNCTION EditOption115   : Boolean;
FUNCTION EditOption122   : Boolean;
FUNCTION EditOptionAll   : Boolean;


IMPLEMENTATION


USES IntrFace,Pick,Options,CnfgVars,BsString,BsMouse,Crt,Valid;


FUNCTION SelectNewOption: Boolean;
VAR  Action      : Word;
     Loop        : Word;
     OldOption   : Word;
     WhatItDid   : Boolean;
BEGIN
     WhatItDid := False;
     OldOption := Menu.Option;
     _SaveWindow(WorkDir+'\PICKING.SCR');
     SetUpPickingList('SELECT MENU OPTION FUNCTION');
     Action := DoPickingList;
     LoadWindow(WorkDir+'\PICKING.SCR');
     IF Action=1 THEN
     BEGIN
          GetOption(PickingItem);
          Menu.Option := O.N;
          IF Menu.Option<>OldOption THEN WhatItDid := True;
          TheFunction := '';
          FOR Loop := 1 TO NumberOfOptions DO
          BEGIN
               GetOption(Loop);
               IF O.N=Menu.Option THEN TheFunction := _Mid(O.V,15,LENGTH(O.V));
          END;
     END;
     SelectNewOption := WhatItDid;
END;


{LOAD MENU}
FUNCTION EditOption1: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
     Crap       : Byte;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,20,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(35,14,1,12,Menu.Second,True);
     AddButton(60,18,' QUIT ',True,1,16);
     AddButton(48,18,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,15); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('Menu File (With .MNU)');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                        ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Second := _UpperCase(Objects^[8].Stuff);
     ClearObjects;
     ClearButtons;
     EditOption1 := ChangeFunc;
END;


{DISPLAY GRAPHICS FILE}
FUNCTION EditOption6: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
     Crap       : Byte;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,20,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(35,14,1,8,Menu.Second,True);
     IF Menu.Third='YES' THEN Crap := 1
                         ELSE Crap := 0;
     AddObject(35,15,6,3,_String(Crap),True);
     AddButton(60,18,' QUIT ',True,1,16);
     AddButton(48,18,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,16); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('  ASC/ANS/RIP/SG File');
     GotoXY(12,15); WRITE('    Wait For Keypress');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                        ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Second := _UpperCase(Objects^[8].Stuff);
     IF Objects^[9].Stuff='1' THEN Menu.Third := 'YES'
                              ELSE Menu.Third := 'NO';
     ClearObjects;
     ClearButtons;
     EditOption6 := ChangeFunc;
END;


{DOS DOORS}
FUNCTION EditOption8: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
     NameType   : Byte;
     BaudType   : Byte;
BEGIN
     ChangeFunc := False;
     IF (Menu.Sub>1) THEN Menu.Sub := 0;
     NameType := Hi(Menu.Area)+1;
     BaudType := Lo(Menu.Area)+1;
     Toggle[1].Flips   := 2;
     Toggle[1].Current := NameType;
     Toggle[1].Flip[1] := 'REAL NAME';
     Toggle[1].Flip[2] := 'ALIAS NAME';
     Toggle[2].Flips   := 2;
     Toggle[2].Current := BaudType;
     Toggle[2].Flip[1] := 'CONNECT SPEED';
     Toggle[2].Flip[2] := 'LOCKED RATE';
     DrawWindow(10,3,70,22,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,5,6,3,_String(Menu.Ansi),True);
     AddObject(43,5,6,3,_String(Menu.Svga),True);
     AddObject(61,5,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,7,1,1,'',True)
                           ELSE AddObject(35,7,1,1,Menu.HotKey,True);
     AddObject(35,8 ,1,30,Menu.Title,True);
     AddObject(35,10,2,5 ,_String(Menu.Access),True);
     AddObject(35,11,7,10,Tags(Menu.Tags),True);
     AddObject(28,13,1,40,Menu.Second,True);
     AddObject(28,14,1,40,Menu.Third,True);
     AddObject(35,16,6,3 ,_String(Menu.Sub),True);
     AddObject(35,17,8,20,'1',True);
     AddObject(35,18,8,20,'2',True);
     AddButton(60,20,' QUIT ',True,1,16);
     AddButton(48,20,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,6);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,9);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,12); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,15); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,19); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,5);  WRITE('Ansi/TTY');
     GotoXY(31,5);  WRITE('Svga/ModeX');
     GotoXY(49,5);  WRITE('Rip Script');
     GotoXY(12,7);  WRITE('        Option Hotkey');
     GotoXY(12,8);  WRITE('    Menu Option Title');
     GotoXY(12,10); WRITE('  Option Access Level');
     GotoXY(12,11); WRITE('   Option Access Tags');
     GotoXY(12,13); WRITE('  Path To Door');
     GotoXY(12,14); WRITE('DOS Executable');
     GotoXY(12,16); WRITE('        Use BUSY Flag');
     GotoXY(12,17); WRITE('  Name For Drop Files');
     GotoXY(12,18); WRITE(' Speed For Drop Files');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Second := ValidateIt(Objects^[8].Stuff,'PATH');
     Menu.Third  := Objects^[9].Stuff;
     Menu.Sub    := Numeric(Objects^[10].Stuff,WordInteger);
     Menu.Area   := ((Toggle[1].Current-1)*256)+Toggle[2].Current-1;
     ClearObjects;
     ClearButtons;
     EditOption8 := ChangeFunc;
END;


{UPLOAD FILES SET AREA}
FUNCTION EditOption15: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,20,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(35,14,2,5 ,_String(Menu.Area),True);
     AddButton(60,18,' QUIT ',True,1,16);
     AddButton(48,18,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,15); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('         File Area ID');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Area := Numeric(Objects^[8].Stuff,WordInteger);
     ClearObjects;
     ClearButtons;
     EditOption15 := ChangeFunc;
END;


{DL FILE WITH PATH}
FUNCTION EditOption18: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,20,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(28,14,1,40,Menu.Second,True);
     AddButton(60,18,' QUIT ',True,1,16);
     AddButton(48,18,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,15); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('Full Path/File');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Second := ValidateIt(Objects^[8].Stuff,'FILE');
     ClearObjects;
     ClearButtons;
     EditOption18 := ChangeFunc;
END;


{WRITE MESSAGE SPECIFIC AREA}
FUNCTION EditOption35: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,20,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(35,14,2,5 ,_String(Menu.Area),True);
     AddButton(60,18,' QUIT ',True,1,16);
     AddButton(48,18,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,15); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('      Message Area ID');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Area := Numeric(Objects^[8].Stuff,WordInteger);
     ClearObjects;
     ClearButtons;
     EditOption35 := ChangeFunc;
END;


{PRIVATE UL}
FUNCTION EditOption39: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,20,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(28,14,1,40,Menu.Second,True);
     AddButton(60,18,' QUIT ',True,1,16);
     AddButton(48,18,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,15); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('  UL Directory');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Second := ValidateIt(Objects^[8].Stuff,'PATH');
     ClearObjects;
     ClearButtons;
     EditOption39 := ChangeFunc;
END;


{READ TEXT FILE}
FUNCTION EditOption44: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,20,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(28,14,1,40,Menu.Second,True);
     AddObject(28,15,1,40,Menu.Third,True);
     AddButton(60,18,' QUIT ',True,1,16);
     AddButton(48,18,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,16); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('  Reader Title');
     GotoXY(12,15); WRITE('     Text File');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Second := Objects^[8].Stuff;
     Menu.Third  := ValidateIt(Objects^[9].Stuff,'FILE');
     ClearObjects;
     ClearButtons;
     EditOption44 := ChangeFunc;
END;


{CHANGE FILE SUB}
FUNCTION EditOption95: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,20,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(35,14,2,5 ,_String(Menu.Sub),True);
     AddButton(60,18,' QUIT ',True,1,16);
     AddButton(48,18,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,15); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('       File Sub Group');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Sub := Numeric(Objects^[8].Stuff,WordInteger);
     ClearObjects;
     ClearButtons;
     EditOption95 := ChangeFunc;
END;


{CHANGE MSG SUB}
FUNCTION EditOption96: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,20,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(35,14,2,5 ,_String(Menu.Sub),True);
     AddButton(60,18,' QUIT ',True,1,16);
     AddButton(48,18,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,15); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('    Message Sub Group');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Sub := Numeric(Objects^[8].Stuff,WordInteger);
     ClearObjects;
     ClearButtons;
     EditOption96 := ChangeFunc;
END;


{EVERYTHING ELSE}
FUNCTION EditOptionAll: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,20,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddButton(60,18,' QUIT ',True,1,16);
     AddButton(48,18,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     ClearObjects;
     ClearButtons;
     EditOptionAll := ChangeFunc;
END;


{USER FILE BOX}
FUNCTION EditOption106: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,20,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(27,14,1,40,Menu.Second,True);
     AddButton(60,18,' QUIT ',True,1,16);
     AddButton(48,18,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,15); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('  Config File');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Second := ValidateIt(Objects^[8].Stuff,'FILE');
     ClearObjects;
     ClearButtons;
     EditOption106 := ChangeFunc;
END;


{PLAY VOC FILE}
FUNCTION EditOption108: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
     Crap       : Byte;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,19,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(35,14,1,12,Menu.Second,True);
     AddButton(60,17,' QUIT ',True,1,16);
     AddButton(48,17,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,15); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('           Audio File');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Second := _UpperCase(Objects^[8].Stuff);
     ClearObjects;
     ClearButtons;
     EditOption108 := ChangeFunc;
END;


{DATA ENTRY SCREEN}
FUNCTION EditOption110: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,20,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(27,14,1,40,Menu.Second,True);
     AddButton(60,18,' QUIT ',True,1,16);
     AddButton(48,18,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,15); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('  Script File');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Second := ValidateIt(Objects^[8].Stuff,'FILE');
     ClearObjects;
     ClearButtons;
     EditOption110 := ChangeFunc;
END;


{DIAL THROUGH}
FUNCTION EditOption111: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,21,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(27,14,1,40,Menu.Second,True);
     AddObject(27,15,1,40,Menu.Third,True);
     AddObject(27,16,2,5,_String(Menu.Sub),True);
     AddButton(60,19,' QUIT ',True,1,16);
     AddButton(48,19,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,17); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('  System Name');
     GotoXY(12,15); WRITE(' System Phone');
     GotoXY(12,16); WRITE('  Node To Use');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Second := Objects^[8].Stuff;
     Menu.Third  := Objects^[9].Stuff;
     Menu.Sub    := Numeric(Objects^[10].Stuff,WordInteger);
     ClearObjects;
     ClearButtons;
     EditOption111 := ChangeFunc;
END;


{CUSTOM DROP FILES}
FUNCTION EditOption112: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,20,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(27,14,1,40,Menu.Second,True);
     AddObject(27,15,1,40,Menu.Third,True);
     AddButton(60,18,' QUIT ',True,1,16);
     AddButton(48,18,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,16); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('     Raw File');
     GotoXY(12,15); WRITE('  Result File');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Second := ValidateIt(Objects^[8].Stuff,'FILE');
     Menu.Third  := ValidateIt(Objects^[9].Stuff,'FILE');
     ClearObjects;
     ClearButtons;
     EditOption112 := ChangeFunc;
END;


{PLAY FLI FILE}
FUNCTION EditOption113: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
     Crap       : Byte;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,19,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(35,14,1,12,Menu.Second,True);
     AddButton(60,17,' QUIT ',True,1,16);
     AddButton(48,17,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,15); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('           Video File');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Second := _UpperCase(Objects^[8].Stuff);
     ClearObjects;
     ClearButtons;
     EditOption113 := ChangeFunc;
END;


{WRITE MESSAGE SPECIFIED AREA/USER}
FUNCTION EditOption114: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,21,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(35,14,2,5 ,_String(Menu.Area),True);
     AddObject(35,15,1,30,Menu.Second,True);
     AddButton(60,19,' QUIT ',True,1,16);
     AddButton(48,19,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,16); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('      Message Area ID');
     GotoXY(12,15); WRITE('     Recipient Of Msg');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Area   := Numeric(Objects^[8].Stuff,WordInteger);
     Menu.Second := Objects^[9].Stuff;
     ClearObjects;
     ClearButtons;
     EditOption114 := ChangeFunc;
END;


{SVGA DOORS}
FUNCTION EditOption115: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,3,70,22,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,5,6,3,_String(Menu.Ansi),True);
     AddObject(43,5,6,3,_String(Menu.Svga),True);
     AddObject(61,5,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,7,1,1,'',True)
                           ELSE AddObject(35,7,1,1,Menu.HotKey,True);
     AddObject(35,8 ,1,30,Menu.Title,True);
     AddObject(35,10,2,5 ,_String(Menu.Access),True);
     AddObject(35,11,7,10,Tags(Menu.Tags),True);
     AddObject(28,13,1,40,Menu.Second,True);
     AddObject(28,14,1,40,Menu.Third,True);
     AddObject(35,16,6,3 ,_String(Menu.Sub),True);
     AddButton(60,20,' QUIT ',True,1,16);
     AddButton(48,20,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,6);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,9);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,12); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,15); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,19); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,5);  WRITE('Ansi/TTY');
     GotoXY(31,5);  WRITE('Svga/ModeX');
     GotoXY(49,5);  WRITE('Rip Script');
     GotoXY(12,7);  WRITE('        Option Hotkey');
     GotoXY(12,8);  WRITE('    Menu Option Title');
     GotoXY(12,10); WRITE('  Option Access Level');
     GotoXY(12,11); WRITE('   Option Access Tags');
     GotoXY(12,13); WRITE('  Path To Door');
     GotoXY(12,14); WRITE('DOS Executable');
     GotoXY(12,16); WRITE('        Use BUSY Flag');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Second := ValidateIt(Objects^[8].Stuff,'PATH');
     Menu.Third  := Objects^[9].Stuff;
     Menu.Sub    := Numeric(Objects^[10].Stuff,WordInteger);
     ClearObjects;
     ClearButtons;
     EditOption115 := ChangeFunc;
END;


{GIP DIRECTORY}
FUNCTION EditOption122: Boolean;
VAR  Pooper     : Word;
     Loop       : Word;
     ChangeFunc : Boolean;
BEGIN
     ChangeFunc := False;
     DrawWindow(10,4,70,18,'EDIT MENU OPTION - '+TheFunction,True);
     AddObject(25,6,6,3,_String(Menu.Ansi),True);
     AddObject(43,6,6,3,_String(Menu.Svga),True);
     AddObject(61,6,6,3,_String(Menu.Rip),True);
     IF Menu.Hotkey=Chr(0) THEN AddObject(35,8,1,1,'',True)
                           ELSE AddObject(35,8,1,1,Menu.HotKey,True);
     AddObject(35,9 ,1,30,Menu.Title,True);
     AddObject(35,11,2,5 ,_String(Menu.Access),True);
     AddObject(35,12,7,10,Tags(Menu.Tags),True);
     AddObject(28,14,1,40,Menu.Second,True);
     AddButton(60,16,' QUIT ',True,1,16);
     AddButton(48,16,' FUNCTION ',True,1,33);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(11,7);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,10); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,13); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     GotoXY(11,15); WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('Ansi/TTY');
     GotoXY(31,6);  WRITE('Svga/ModeX');
     GotoXY(49,6);  WRITE('Rip Script');
     GotoXY(12,8);  WRITE('        Option Hotkey');
     GotoXY(12,9);  WRITE('    Menu Option Title');
     GotoXY(12,11); WRITE('  Option Access Level');
     GotoXY(12,12); WRITE('   Option Access Tags');
     GotoXY(12,14); WRITE('Base Directory');
     _ShowMouse;
     REPEAT
           Pooper := DoObjects;
           IF Pooper=2 THEN
           BEGIN
                IF SelectNewOption THEN
                BEGIN
                     {NEW FUNCTION!}
                     Pooper := 1;
                     ChangeFunc := True;
                     LoadWindowNoKill(WorkDir+'\EDITACC.SCR');
                END;
           END;
     UNTIL Pooper=1;
     Menu.Ansi   := Numeric(Objects^[1].Stuff,ByteInteger);
     Menu.Svga   := Numeric(Objects^[2].Stuff,ByteInteger);
     Menu.Rip    := Numeric(Objects^[3].Stuff,ByteInteger);
     Menu.HotKey := Objects^[4].Stuff[1];
     Menu.Title  := Objects^[5].Stuff;
     Menu.Access := Numeric(Objects^[6].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[7].Stuff[Loop]='1' THEN Menu.Tags[Loop] := 1
                                         ELSE Menu.Tags[Loop] := 0;
     END;
     Menu.Second := ValidateIt(Objects^[8].Stuff,'PATH');
     ClearObjects;
     ClearButtons;
     EditOption122 := ChangeFunc;
END;


END.