{$I DEFINES.INC}
UNIT Intro;


INTERFACE


PROCEDURE DoIntro;
PROCEDURE DrawMainScr;
PROCEDURE GiveWarning;
FUNCTION  Path(Work: String): String;


IMPLEMENTATION


USES __Gfx,BsGraph,BsMulti,Globals,Version,BsString,
     {$IFDEF DPMI}
     Gr2_Bp;
     {$ELSE}
     Gr_Tp;
     {$ENDIF}


PROCEDURE DoIntro;
BEGIN
     GrSetFillStyle(GrFSolid,0,GrOpaque);
     GrDrawRect(0,0,GraphMaxX,GraphMaxY,GrFill);
     GrSetFillStyle(GrFSolid,7,GrOpaque);
     GrSetColor(8);
     GrDrawRect(200,150,440,250,GrFill+GrOutline);
     RaisedBox(201,151,439,249);
     RaisedBox(202,152,438,248);
     OutTextXY(255,164,0,255,1,'SGT Services Manager');
     OutTextXY(210,184,0,255,5,'Copyright (C) 1994-1996 GUNN Data Systems');
     SystemIcon(235,205,101);
     SystemIcon(265,205,102);
     SystemIcon(295,205,103);
     SystemIcon(325,205,104);
     SystemIcon(355,205,105);
     SystemIcon(385,205,106);
     SystemIcon(235,235,107);
     SystemIcon(265,235,108);
     SystemIcon(295,235,109);
     SystemIcon(325,235,110);
     SystemIcon(355,235,111);
     SystemIcon(385,235,112);
     Fade_In;
     _Delay(2500);
     Fade_Out;
     CreateVirtual(P,8,2,TheDisplay);
     GrSetFillStyle(GrFSolid,56,GrOpaque);
     GrDrawRect(0,0,GraphMaxX,GraphMaxY,GrFill);
     GrSetFillStyle(GrFSolid,1,GrOpaque);
     GrDrawRect(0,0,GraphMaxX,20,GrFill); GrDrawRect(0,GraphMaxY-20,GraphMaxX,GraphMaxY,GrFill);
     GrSetColor(9);  GrDrawLine(0,0,GraphMaxX,0);   GrDrawLine(0,GraphMaxY-20,GraphMaxX,GraphMaxY-20);
     GrSetColor(33); GrDrawLine(0,20,GraphMaxX,20); GrDrawLine(0,GraphMaxY,GraphMaxX,GraphMaxY);
     OutTextXY(185,3,15,1,2,'SGT Services Manager - '+ShotgunVersion);
     OutTextXY(70,GraphMaxY-17,15,1,2,ShotgunCopyright);
     OutTextXY(425,GraphMaxY-52,35,255,1,'GUNN Data Systems Support System');
     OutTextXY(455,GraphMaxY-38,35,255,5,'(306)652-0288 [33.6k V34+/VFC]');
     OutTextXY(590,GraphMaxY-16,7,255,5,_String(MemAvail));
END;


PROCEDURE DrawMainScr;
BEGIN
     DrawWindow(10,180,270,415,'MAIN MENU',1);
     InvertedBox(15,210,265,410);
     SystemButton(25,222,255,262,1,False,True);
     SystemButton(25,267,255,307,1,False,True);
     SystemButton(25,312,255,352,1,False,True);
     SystemButton(25,357,255,397,1,False,True);
     SystemIcon(35,227,93);
     SystemIcon(35,272,94);
     SystemIcon(35,317,95);
     SystemIcon(35,362,96);
     OutTextXY(85,235,0,255,1,'Service Dialer');
     OutTextXY(85,280,0,255,1,'Fax Manager/Dialer');
     OutTextXY(85,325,0,255,1,'Configuration & Setup');
     OutTextXY(85,370,0,255,1,'Exit Back To DOS');
     grDisplayMouse(GrShow);
     Fade_In;
END;


PROCEDURE GiveWarning;
VAR  C : Word;
BEGIN
     grDisplayMouse(GrHide);
     WindowHeaderC := 4;
     WindowHighC   := 12;
     WindowLowC    := 0;
     DrawWindow(200,150,460,290,'MODEM CONFIGURATION NOT FOUND!',0);
     OutTextXY(215,180,0,255,1,'You need to set up your system! Please');
     OutTextXY(215,195,0,255,1,'review your settings in the setup &');
     OutTextXY(215,210,0,255,1,'configuration on the main menu.');
     DoOkButton(370,240);
     grDisplayMouse(GrShow);
     REPEAT
           c := MouseHandler(False);
           IF c=0 THEN TimeSlice;
     UNTIL C=NButtons;
     WindowHeaderC := 57;
     WindowHighC   := 60;
     WindowLowC    := 54;
     KillWindow;
END;


FUNCTION Path(Work: String): String;
BEGIN
     IF Work<>'' THEN
     BEGIN
          IF Work[LENGTH(Work)]='\' THEN Work := _Mid(Work,1,LENGTH(Work)-1);
     END;
     Path := Work;
END;


END.
