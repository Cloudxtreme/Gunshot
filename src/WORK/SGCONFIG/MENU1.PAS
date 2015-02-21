{$I DEFINES.INC}
UNIT MENU1;


INTERFACE


PROCEDURE DoAbout;
PROCEDURE DoConfigSetup;


IMPLEMENTATION


USES IntrFace,BsMouse,Crt,Defaults,CnfgVars,Valid,Version,BsString,KeyCheck;


PROCEDURE DoAbout;
BEGIN
     DrawWindow(15,4,65,21,'ABOUT SHOTGUN',True);
     AddButton(56,19,' QUIT ',True,1,16);
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(15); GotoXY(16,6);  WRITE('           SHOTGUN PROFESSIONAL '+ShotgunVersion);
     TextColor_BS(11); GotoXY(16,8);  WRITE('   Copyright (C) 1994,1997 GUNN Data Systems');
     TextColor_BS(9);  GotoXY(16,9);  WRITE('              All Rights Reserved');
     TextColor_BS(14); GotoXY(16,11); WRITE('                 REGISTERED TO:');
     TextColor_BS(11);
     GotoXY(20,13); WRITE('    Sysop: '+Client.Sysop);
     GotoXY(20,14); WRITE(' BBS Name: '+Client.BBS);
     GotoXY(20,15); WRITE('BBS Phone: '+Client.BBSPhone);
     GotoXY(20,16); WRITE('    Voice: '+Client.Phone);
     GotoXY(20,17); WRITE('      S/N: '+Client.Sn);
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
END;


PROCEDURE DoConfigSetup;
BEGIN
     CheckFile('SGCONFIG.DAT');
     CheckFile('EXTERNAL.DAT');
     ASSIGN(FConfigSetup,BaseDirectory+'\DATA\SGCONFIG.DAT');
     RESET(FConfigSetup);
     READ(FConfigSetup,ConfigSetup);
     CLOSE(FConfigSetup);
     ASSIGN(FExternalApps,BaseDirectory+'\DATA\EXTERNAL.DAT');
     RESET(FExternalApps);
     READ(FExternalApps,ExternalApps);
     CLOSE(FExternalApps);
     Toggle[1].Flips   := 4;
     Toggle[1].Current := ConfigSetup.Printer;
     Toggle[1].Flip[1] := 'LPT1';
     Toggle[1].Flip[2] := 'LPT2';
     Toggle[1].Flip[3] := 'LPT3';
     Toggle[1].Flip[4] := 'NONE';
     IF ((ConfigSetup.PrinterModel<1) OR (ConfigSetup.PrinterModel>5)) THEN ConfigSetup.PrinterModel := 1;
     Toggle[2].Flips   := 5;
     Toggle[2].Current := ConfigSetup.PrinterModel;
     Toggle[2].Flip[1] := 'EPSON';
     Toggle[2].Flip[2] := 'EPSON24';
     Toggle[2].Flip[3] := 'HP150';
     Toggle[2].Flip[4] := 'HP300';
     Toggle[2].Flip[5] := 'HP300/PCL5';
     DrawWindow(10,6,71,20,'CONFIGURATION SETUP',True);
     AddObject(28,8,2,3,_String(ConfigSetup.Horizontal),True);
     AddObject(28,9,2,3,_String(ConfigSetup.Vertical),True);
     AddObject(28,10,8,20,'1',True);
     AddObject(28,11,8,20,'2',True);
     AddObject(28,12,1,40,ConfigSetup.AnsiEditor,True);
     AddObject(28,13,1,40,ConfigSetup.RipEditor,True);
     AddObject(28,14,1,40,ExternalApps.FaxReceiver,True);
     AddObject(28,15,1,40,ExternalApps.SpellChecker,True);
     AddObject(28,16,1,40,ExternalApps.THDProScan,True);
     AddButton(61,18,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(11,8);  WRITE('   MouseÄÄÄÄÄÂX');
     GotoXY(11,9);  WRITE('    Tracking ÀY');
     GotoXY(11,10); WRITE('   Printer Port');
     GotoXY(11,11); WRITE('  Printer Model');
     GotoXY(11,12); WRITE('    ANSI Editor');
     GotoXY(11,13); WRITE('     RIP Editor');
     GotoXY(11,14); WRITE('    Fax Receive');
     GotoXY(11,15); WRITE('  Spell Checker');
     GotoXY(11,16); WRITE('  Virus Checker');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     ConfigSetup.Horizontal    := Numeric(Objects^[1].Stuff,ByteInteger);
     ConfigSetup.Vertical      := Numeric(Objects^[2].Stuff,ByteInteger);
     ConfigSetup.Printer       := Toggle[1].Current;
     ConfigSetup.PrinterModel  := Toggle[2].Current;
     ConfigSetup.ANSIEditor    := ValidateIt(Objects^[5].Stuff,'FILE');
     ConfigSetup.RIPEditor     := ValidateIt(Objects^[6].Stuff,'FILE');
     ExternalApps.FaxReceiver  := _RemoveLeftSpaces(Objects^[7].Stuff);
     ExternalApps.SpellChecker := _RemoveLeftSpaces(Objects^[8].Stuff);
     ExternalApps.THDProScan   := _RemoveLeftSpaces(Objects^[9].Stuff);
     _SetPixelToMickey(ConfigSetup.Horizontal,ConfigSetup.Vertical);
     ASSIGN(FConfigSetup,BaseDirectory+'\DATA\SGCONFIG.DAT');
     REWRITE(FConfigSetup);
     WRITE(FConfigSetup,ConfigSetup);
     CLOSE(FConfigSetup);
     ASSIGN(FExternalApps,BaseDirectory+'\DATA\EXTERNAL.DAT');
     REWRITE(FExternalApps);
     WRITE(FExternalApps,ExternalApps);
     CLOSE(FExternalApps);
END;


END.
