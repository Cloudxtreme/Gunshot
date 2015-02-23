{$I DEFINES.INC}
UNIT BsMenu;


INTERFACE


TYPE dtDrawDesktop     = PROCEDURE;
VAR  dtUserDrawDesktop : dtDrawDesktop;


PROCEDURE dtShutDownDesktop;
PROCEDURE dtSetUserDesktopDraw(SProc : dtDrawDesktop);
PROCEDURE dtStartUpDesktop(AppName: String; VidMode,VideoStyle,AppId: Byte);
FUNCTION  menuExecute(VAR Menu,Option: Word): Boolean;
PROCEDURE menuNew(Title: String);
PROCEDURE menuNewOption(Title,KeyHelp: String; Enabled,SubLink: Boolean);
PROCEDURE menuStart(FirstMenu: Word);
PROCEDURE menuToggleOption(Menu,Option: Byte; OnOff: Boolean);


IMPLEMENTATION


USES BsMisc,BsFile,BsFrames,BsGlobal,BsKeys,BsMouse,BsMulti,BsString,BsVideo,Crt;


PROCEDURE dtNoDrawDesktop;
BEGIN
     {NIL}
END;


PROCEDURE dtStartUpDesktop(AppName: String; VidMode,VideoStyle,AppId: Byte);
CONST DeskTopFill    : String[80] = '°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°';
      DeskTopBorder1 : String[80] = 'ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ';
      DeskTopBorder2 : String[80] = 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ';
      DeskTopMenu    : String[80] = '                                                                                ';
VAR   Loop           : Byte;
      Temp           : String;
BEGIN
     {$IFDEF OS2}
       AppName := AppName+'/OS2';
     {$ELSE}
       {$IFDEF DPMI}
       AppName := AppName+'/DPMI';
       {$ELSE}
       AppName := AppName+'/DOS';
       {$ENDIF}
     {$ENDIF}
     New(dtApp);
     New(dtBackGround);
     New(dtButtons);
     New(dtColours);
     New(dtDropList);
     New(dtEditor);
     New(dtPickList);
     New(dtForeGround);
     New(dtMenus);
     New(dtOnOff);
     New(dtWindows);
     FillChar(dtApp^,SizeOf(dtApp^),0);
     FillChar(dtColours^,SizeOf(dtColours^),0);
     FillChar(dtMenus^,SizeOf(dtMenus^),0);
     FillChar(dtWindows^,SizeOf(dtWindows^),0);
     CASE VideoStyle OF
     1: BEGIN {Front Door}
          dtColours^.MenuNormal        := (0*16)+7;
          dtColours^.MenuHighlight     := (0*16)+15;
          dtColours^.MenuSNormal       := (7*16)+1;
          dtColours^.MenuSHighlight    := (7*16)+9;
          dtColours^.MenuDisabled      := (0*16)+8;
          dtColours^.MenuSDisabled     := (7*16)+8;
          dtColours^.MenuFrame         := (0*16)+11;
          dtColours^.MenuSeperator     := (0*16)+11;
          dtColours^.StatusNormal      := (0*16)+7;
          dtColours^.StatusSeperator   := (0*16)+8;
          dtColours^.StatusHighlight   := (0*16)+14;
          dtColours^.StatusSelected    := (7*16)+1;
          dtColours^.DeskTopFill       := (0*16)+7;
          dtColours^.DeskTopBorder     := (0*16)+1;
          dtColours^.AppName           := (7*16)+0;
          dtColours^.WindowTitle       := (1*16)+14;
          dtColours^.WindowBorderH     := (0*16)+1;
          dtColours^.WindowBorderL     := (0*16)+1;
          dtColours^.WindowText        := (0*16)+7;
          dtColours^.WindowHighlight   := (0*16)+3;
          dtColours^.WindowBack        := (0*16)+0;
          dtColours^.ButtonNormal      := (7*16)+0;
          dtColours^.ButtonHighlight   := (7*16)+14;
          dtColours^.ButtonSNormal     := (3*16)+0;
          dtColours^.ButtonSHighlight  := (3*16)+14;
          dtColours^.ButtonDisabled    := (7*16)+8;
          dtColours^.ButtonSDisabled   := (3*16)+8;
          dtColours^.ButtonShadow      := (0*16)+1;
          dtColours^.OnOffNormal       := (0*16)+7;
          dtColours^.OnOffHighlight    := (0*16)+14;
          dtColours^.OnOffSNormal      := (3*16)+0;
          dtColours^.OnOffSHighlight   := (3*16)+14;
          dtColours^.OnOffDisabled     := (0*16)+8;
          dtColours^.OnOffSDisabled    := (3*16)+8;
          dtColours^.DropListText      := (7*16)+0;
          dtColours^.DropListDisabled  := (7*16)+8;
          dtColours^.DropListBars      := (0*16)+7;
          dtColours^.DropListSText     := (3*16)+0;
          dtColours^.DropListSDisabled := (3*16)+8;
          dtColours^.DropListSBars     := (0*16)+3;
          dtColours^.ScrollBarH        := (7*16)+0;
          dtColours^.ScrollBarL        := (0*16)+8;
          dtColours^.FrameHigh         := (0*16)+7;
          dtColours^.FrameLow          := (0*16)+8;
          dtColours^.PickNormal        := (0*16)+7;
          dtColours^.PickHighlight     := (3*16)+0;
          dtColours^.PickSNormal       := (0*16)+7;
          dtColours^.PickSHighlight    := (3*16)+0;
          dtColours^.EditText          := (0*16)+7;
          dtColours^.EditTextDisabled  := (0*16)+8;

          dtColours^.EditorText        := (0*16)+7;
          dtColours^.EditorSText       := (3*16)+0;
          dtColours^.EditorSBackground := (0*16)+3;
          dtColours^.EditorDisabled    := (0*16)+8;
          dtColours^.EditorSDisabled   := (3*16)+8;

          dtApp^.MenuBarY              := 1;
        END;
     2: BEGIN {Turbo Vision}
          dtColours^.MenuNormal        := (7*16)+0;
          dtColours^.MenuHighlight     := (7*16)+4;
          dtColours^.MenuSNormal       := (2*16)+0;
          dtColours^.MenuSHighlight    := (2*16)+4;
          dtColours^.MenuDisabled      := (7*16)+8;
          dtColours^.MenuSDisabled     := (2*16)+8;
          dtColours^.MenuFrame         := (7*16)+0;
          dtColours^.MenuSeperator     := (7*16)+0;
          dtColours^.StatusNormal      := (7*16)+0;
          dtColours^.StatusSeperator   := (7*16)+0;
          dtColours^.StatusHighlight   := (7*16)+4;
          dtColours^.StatusSelected    := (2*16)+0;
          dtColours^.DeskTopFill       := (7*16)+1;
          dtColours^.AppName           := (7*16)+1;
          dtColours^.WindowTitle       := (7*16)+15;
          dtColours^.WindowBorderH     := (7*16)+15;
          dtColours^.WindowBorderL     := (7*16)+15;
          dtColours^.WindowText        := (7*16)+0;
          dtColours^.WindowHighlight   := (7*16)+14;
          dtColours^.WindowBack        := (7*16)+7;
          dtColours^.ButtonNormal      := (2*16)+0;
          dtColours^.ButtonHighlight   := (2*16)+14;
          dtColours^.ButtonSNormal     := (2*16)+15;
          dtColours^.ButtonSHighlight  := (2*16)+15;
          dtColours^.ButtonDisabled    := (2*16)+8;
          dtColours^.ButtonSDisabled   := (2*16)+8;
          dtColours^.ButtonShadow      := (7*16)+0;
          dtColours^.OnOffNormal       := (7*16)+0;
          dtColours^.OnOffHighlight    := (7*16)+14;
          dtColours^.OnOffSNormal      := (3*16)+0;
          dtColours^.OnOffSHighlight   := (3*16)+14;
          dtColours^.OnOffDisabled     := (7*16)+8;
          dtColours^.OnOffSDisabled    := (3*16)+8;
          dtColours^.DropListText      := (3*16)+0;
          dtColours^.DropListDisabled  := (3*16)+8;
          dtColours^.DropListSText     := (2*16)+15;
          dtColours^.DropListSDisabled := (2*16)+8;
          dtColours^.DropListBars      := (7*16)+3;
          dtColours^.DropListSBars     := (7*16)+2;
          dtColours^.ScrollBarH        := (3*16)+1;
          dtColours^.ScrollBarL        := (1*16)+3;
          dtColours^.FrameHigh         := (7*16)+15;
          dtColours^.FrameLow          := (7*16)+8;
          dtColours^.PickNormal        := (3*16)+0;
          dtColours^.PickHighlight     := (3*16)+14;
          dtColours^.PickSNormal       := (3*16)+0;
          dtColours^.PickSHighlight    := (2*16)+15;
          dtColours^.EditText          := (7*16)+0;
          dtColours^.EditTextDisabled  := (7*16)+8;
          dtApp^.MenuBarY              := 1;
        END;
     3: BEGIN {Norton Utilities}
          dtColours^.MenuNormal        := (15*16)+0;
          dtColours^.MenuHighlight     := (15*16)+4;
          dtColours^.MenuSNormal       := (0*16)+15;
          dtColours^.MenuSHighlight    := (0*16)+4;
          dtColours^.MenuDisabled      := (15*16)+7;
          dtColours^.MenuSDisabled     := (0*16)+7;
          dtColours^.MenuFrame         := (15*16)+15;
          dtColours^.MenuSeperator     := (15*16)+0;
          dtColours^.StatusNormal      := (15*16)+0;
          dtColours^.StatusSeperator   := (15*16)+0;
          dtColours^.StatusHighlight   := (15*16)+4;
          dtColours^.StatusSelected    := (0*16)+4;
          dtColours^.DeskTopFill       := (8*16)+8;
          dtColours^.DeskTopBorder     := (9*16)+15;
          dtColours^.AppName           := (9*16)+15;
          dtColours^.WindowTitle       := (15*16)+1;
          dtColours^.WindowBorderH     := (9*16)+9;
          dtColours^.WindowBorderL     := (9*16)+9;
          dtColours^.WindowText        := (9*16)+15;
          dtColours^.WindowHighlight   := (9*16)+14;
          dtColours^.WindowBack        := (9*16)+9;
          dtColours^.ButtonNormal      := (7*16)+0;
          dtColours^.ButtonHighlight   := (7*16)+4;
          dtColours^.ButtonSNormal     := (15*16)+0;
          dtColours^.ButtonSHighlight  := (15*16)+4;
          dtColours^.ButtonDisabled    := (7*16)+8;
          dtColours^.ButtonSDisabled   := (15*16)+7;
          dtColours^.ButtonShadow      := (9*16)+0;
          dtColours^.OnOffNormal       := (9*16)+15;
          dtColours^.OnOffHighlight    := (9*16)+14;
          dtColours^.OnOffSNormal      := (15*16)+0;
          dtColours^.OnOffSHighlight   := (15*16)+4;
          dtColours^.OnOffDisabled     := (9*16)+1;
          dtColours^.OnOffSDisabled    := (15*16)+7;
          dtColours^.DropListText      := (7*16)+0;
          dtColours^.DropListDisabled  := (7*16)+8;
          dtColours^.DropListBars      := (9*16)+7;
          dtColours^.DropListSBars     := (9*16)+15;
          dtColours^.DropListSText     := (15*16)+0;
          dtColours^.DropListSDisabled := (15*16)+7;
          dtColours^.ScrollBarH        := (15*16)+0;
          dtColours^.ScrollBarL        := (7*16)+7;
          dtColours^.FrameHigh         := (9*16)+11;
          dtColours^.FrameLow          := (9*16)+1;
          dtColours^.PickNormal        := (9*16)+15;
          dtColours^.PickHighlight     := (15*16)+0;
          dtColours^.PickSNormal       := (9*16)+15;
          dtColours^.PickSHighlight    := (15*16)+0;
          dtColours^.EditText          := (7*16)+0;
          dtColours^.EditTextDisabled  := (7*16)+8;
          dtApp^.MenuBarY              := 2;
        END;
     4: BEGIN {Gunshot Professional}
          dtColours^.MenuNormal        := (7*16)+0;
          dtColours^.MenuHighlight     := (7*16)+4;
          dtColours^.MenuSNormal       := (15*16)+0;
          dtColours^.MenuSHighlight    := (15*16)+4;
          dtColours^.MenuDisabled      := (7*16)+8;
          dtColours^.MenuSDisabled     := (15*16)+8;
          dtColours^.MenuFrame         := (7*16)+0;
          dtColours^.MenuSeperator     := (7*16)+0;
          dtColours^.StatusNormal      := (7*16)+0;
          dtColours^.StatusSeperator   := (7*16)+0;
          dtColours^.StatusHighlight   := (7*16)+4;
          dtColours^.StatusSelected    := (15*16)+0;
          dtColours^.DeskTopFill       := (8*16)+8;
          dtColours^.AppName           := (8*16)+15;
          dtColours^.WindowTitle       := (9*16)+15;
          dtColours^.WindowBorderH     := (1*16)+9;
          dtColours^.WindowBorderL     := (1*16)+0;
          dtColours^.WindowText        := (1*16)+11;
          dtColours^.WindowHighlight   := (1*16)+15;
          dtColours^.WindowBack        := (1*16)+1;
          dtColours^.ButtonNormal      := (7*16)+0;
          dtColours^.ButtonHighlight   := (7*16)+4;
          dtColours^.ButtonSNormal     := (15*16)+0;
          dtColours^.ButtonSHighlight  := (15*16)+4;
          dtColours^.ButtonDisabled    := (7*16)+8;
          dtColours^.ButtonSDisabled   := (7*16)+8;
          dtColours^.ButtonShadow      := (1*16)+0;
          dtColours^.OnOffNormal       := (1*16)+11;
          dtColours^.OnOffHighlight    := (1*16)+14;
          dtColours^.OnOffSNormal      := (0*16)+7;
          dtColours^.OnOffSHighlight   := (0*16)+14;
          dtColours^.OnOffDisabled     := (1*16)+7;
          dtColours^.OnOffSDisabled    := (0*16)+8;
          dtColours^.DropListText      := (7*16)+0;
          dtColours^.DropListDisabled  := (7*16)+8;
          dtColours^.DropListBars      := (1*16)+7;
          dtColours^.DropListSBars     := (1*16)+15;
          dtColours^.DropListSText     := (15*16)+0;
          dtColours^.DropListSDisabled := (15*16)+7;
          dtColours^.ScrollBarH        := (3*16)+15;
          dtColours^.ScrollBarL        := (0*16)+1;
          dtColours^.FrameHigh         := (1*16)+9;
          dtColours^.FrameLow          := (1*16)+0;
          dtColours^.PickNormal        := (1*16)+7;
          dtColours^.PickHighlight     := (1*16)+15;
          dtColours^.PickSNormal       := (1*16)+15;
          dtColours^.PickSHighlight    := (3*16)+0;
          dtColours^.EditText          := (1*16)+15;
          dtColours^.EditTextDisabled  := (1*16)+7;
          dtApp^.MenuBarY              := 2;
        END;
     5: BEGIN {InterMail}
          dtColours^.MenuNormal        := (7*16)+0;
          dtColours^.MenuHighlight     := (7*16)+1;
          dtColours^.MenuSNormal       := (3*16)+1;
          dtColours^.MenuSHighlight    := (3*16)+14;
          dtColours^.MenuDisabled      := (7*16)+8;
          dtColours^.MenuSDisabled     := (3*16)+8;
          dtColours^.MenuFrame         := (7*16)+0;
          dtColours^.MenuSeperator     := (7*16)+0;
          dtColours^.StatusNormal      := (7*16)+0;
          dtColours^.StatusSeperator   := (7*16)+0;
          dtColours^.StatusHighlight   := (7*16)+1;
          dtColours^.StatusSelected    := (3*16)+0;
          dtColours^.DeskTopFill       := (1*16)+7;
          dtColours^.AppName           := (7*16)+1;
          dtColours^.WindowTitle       := (7*16)+1;
          dtColours^.WindowBorderH     := (7*16)+1;
          dtColours^.WindowBorderL     := (7*16)+1;
          dtColours^.WindowText        := (7*16)+0;
          dtColours^.WindowHighlight   := (7*16)+14;
          dtColours^.WindowBack        := (7*16)+7;
          dtColours^.ButtonNormal      := (1*16)+7;
          dtColours^.ButtonHighlight   := (1*16)+14;
          dtColours^.ButtonSNormal     := (1*16)+15;
          dtColours^.ButtonSHighlight  := (1*16)+15;
          dtColours^.ButtonDisabled    := (1*16)+8;
          dtColours^.ButtonSDisabled   := (1*16)+0;
          dtColours^.ButtonShadow      := (7*16)+0;
          dtColours^.OnOffNormal       := (3*16)+0;
          dtColours^.OnOffHighlight    := (3*16)+14;
          dtColours^.OnOffSNormal      := (3*16)+15;
          dtColours^.OnOffSHighlight   := (3*16)+14;
          dtColours^.OnOffDisabled     := (3*16)+8;
          dtColours^.OnOffSDisabled    := (3*16)+11;
          dtColours^.DropListText      := (1*16)+7;
          dtColours^.DropListDisabled  := (1*16)+8;
          dtColours^.DropListSText     := (1*16)+15;
          dtColours^.DropListSDisabled := (1*16)+0;
          dtColours^.DropListBars      := (7*16)+1;
          dtColours^.DropListSBars     := (7*16)+1;
          dtColours^.ScrollBarH        := (3*16)+1;
          dtColours^.ScrollBarL        := (7*16)+1;
          dtColours^.FrameHigh         := (7*16)+15;
          dtColours^.FrameLow          := (7*16)+8;
          dtColours^.PickNormal        := (7*16)+0;
          dtColours^.PickHighlight     := (3*16)+0;
          dtColours^.PickSNormal       := (7*16)+0;
          dtColours^.PickSHighlight    := (3*16)+0;
          dtColours^.EditText          := (7*16)+0;
          dtColours^.EditTextDisabled  := (7*16)+8;
          dtApp^.MenuBarY              := 1;
        END;
     END;
     dtApp^.StartUpDir := _GetFilePath(ParamStr(0));
     DEC(dtApp^.StartUpDir[0]);
     dtApp^.WorkDir    := dtApp^.StartUpDir+'\!'+_String(AppId);
     _CreatePath(dtApp^.WorkDir);
     dtApp^.VideoOrig  := LastMode;
     dtApp^.VideoMode  := VidMode;
     dtApp^.VideoBytes := (160*VidMode);
     dtApp^.AppName    := AppName;
     dtApp^.AppStyle   := VideoStyle;
     dtApp^.AppMenus   := 0;
     CASE VidMode OF
     25:  TextMode(CO80);
     28:  ExtendedVideoMode(28);
     30:  ExtendedVideoMode(30);
     50:  TextMode(CO80+Font8x8);
     END;
     CheckSnow := False;
     HighVideo;
     _InitMouse;
     TextColor(7);
     TextBackGround(0);
     ClrScr;
     IF dtApp^.AppStyle=VideoNU THEN _HighBackGrounds(True);
     IF dtApp^.AppStyle=VideoSG THEN _HighBackGrounds(True);
     _HideCursor;
     {Paint The Desktop}
     FastWrite(DeskTopMenu,dtApp^.MenuBarY,1,dtColours^.MenuNormal);
     CASE VideoStyle OF
     1: BEGIN {Front Door}
          FastWrite(DeskTopBorder1,dtApp^.MenuBarY+1,1,dtColours^.DesktopBorder);
          FOR Loop := dtApp^.MenuBarY+2 TO (dtApp^.VideoMode-2) DO FastWrite(DeskTopFill,Loop,1,dtColours^.DeskTopFill);
          FastWrite(DeskTopBorder2,dtApp^.VideoMode-1,1,dtColours^.DesktopBorder);
        END;
     2,5:
        BEGIN {Turbo Vision, InterMail}
          FOR Loop := dtApp^.MenuBarY+1 TO (dtApp^.VideoMode-1) DO FastWrite(DeskTopFill,Loop,1,dtColours^.DeskTopFill);
        END;
     3,4:
        BEGIN {Norton Utilities, Gunshot Professional}
          FOR Loop := dtApp^.MenuBarY+1 TO (dtApp^.VideoMode-1) DO FastWrite(DeskTopMenu,Loop,1,dtColours^.DeskTopFill);
        END;
     END;
     FastWrite(DeskTopMenu,dtApp^.VideoMode,1,dtColours^.MenuNormal);
     CASE VideoStyle OF
     1:   BEGIN
            Temp := ' '+dtApp^.AppName+' ';
            FastWrite(Temp,Trunc(dtApp^.VideoMode/2),Trunc((80-LENGTH(Temp))/2),dtColours^.AppName);
          END;
     3,4: FastWrite(_PadBoth(dtApp^.AppName,80),1,1,dtColours^.AppName);
     2,5: FastWrite(dtApp^.AppName,1,80-LENGTH(dtApp^.AppName),dtColours^.AppName);
     END;
     dtUserDrawDesktop;
     Move(MEM[SegB800:(dtApp^.MenuBarY*160)],dtApp^.SavedDesktop,(dtApp^.VideoMode-(dtApp^.MenuBarY+1))*160);
END;


PROCEDURE dtShutDownDesktop;
BEGIN
     _HideMouse;
     TextMode(dtApp^.VideoOrig);
     TextColor(7);
     TextBackGround(0);
     ClrScr;
     IF dtApp^.AppStyle=VideoNU THEN _HighBackGrounds(False);
     IF dtApp^.AppStyle=VideoSG THEN _HighBackGrounds(False);
     _NukeDir(dtApp^.WorkDir,False);
     _ShowCursor;
     Dispose(dtApp);
     Dispose(dtBackGround);
     Dispose(dtButtons);
     Dispose(dtColours);
     Dispose(dtDropList);
     Dispose(dtEditor);
     Dispose(dtPickList);
     Dispose(dtForeGround);
     Dispose(dtMenus);
     Dispose(dtOnOff);
     Dispose(dtWindows);
END;


PROCEDURE menuNew(Title: String);
VAR  Work : Byte;
BEGIN
     INC(dtApp^.AppMenus);
     dtMenus^.Menu[dtApp^.AppMenus].Title := Title;
     dtMenus^.Menu[dtApp^.AppMenus].NumOpt := 0;
     Work := Pos('~',Title);
     dtMenus^.Menu[dtApp^.AppMenus].KeyPress := UpCase(Title[Work+1]);
     IF dtApp^.AppMenus=1 THEN
     BEGIN
       dtMenus^.Menu[dtApp^.AppMenus].XPos := 3;
     END
     ELSE
     BEGIN
       dtMenus^.Menu[dtApp^.AppMenus].XPos :=
         dtMenus^.Menu[dtApp^.AppMenus-1].XPos+
         LENGTH(dtMenus^.Menu[dtApp^.AppMenus-1].Title)+1;
     END;
END;


PROCEDURE menuStart(FirstMenu: Word);
VAR  Loop   : Byte;
     Work   : Byte;
     Temp   : String;
     YPos   : Word;
     XPos   : Word;
     SWid   : Byte;
BEGIN
     dtApp^.CurrentMenu   := FirstMenu;
     dtApp^.CurrentSelect := 1;
     FOR Loop := 1 TO dtApp^.AppMenus DO
     BEGIN
       Temp := dtMenus^.Menu[Loop].Title;
       Work := Pos('~',Temp);
       Delete(Temp,Work,1);
       IF Loop=dtApp^.CurrentMenu THEN
       BEGIN
         FastWrite(' '+Temp+' ',dtApp^.MenuBarY,dtMenus^.Menu[Loop].XPos-1,dtColours^.MenuSNormal);
         FastWrite(Temp[Work],dtApp^.MenuBarY,dtMenus^.Menu[Loop].XPos+Work-1,dtColours^.MenuSHighlight);
       END
       ELSE
       BEGIN
         FastWrite(' '+Temp+' ',dtApp^.MenuBarY,dtMenus^.Menu[Loop].XPos-1,dtColours^.MenuNormal);
         FastWrite(Temp[Work],dtApp^.MenuBarY,dtMenus^.Menu[Loop].XPos+Work-1,dtColours^.MenuHighlight);
       END;
     END;
     IF ((dtApp^.AppMenus<>0) AND (dtApp^.CurrentMenu<>0)) THEN
     BEGIN
       XPos := dtMenus^.Menu[dtApp^.CurrentMenu].XPos;
       SWid := dtMenus^.Menu[dtApp^.CurrentMenu].MaxMenuWidth;
       winDropShadow(XPos-2,dtApp^.MenuBarY+1,XPos+SWid+5,dtApp^.MenuBarY+2+dtMenus^.Menu[dtApp^.CurrentMenu].NumOpt);
       FOR Loop := 0 TO (dtMenus^.Menu[dtApp^.CurrentMenu].NumOpt+1) DO
       BEGIN
         YPos := dtApp^.MenuBarY+Loop+1;
         IF Loop=0 THEN
         BEGIN
           CASE dtApp^.AppStyle OF
           1:   Temp := ' É'+_Replicate('Í',SWid+4)+'» ';
           2,5: Temp := ' Ú'+_Replicate('Ä',SWid+4)+'¿ ';
           3:   Temp := ' '+_Replicate('Ä',SWid+6)+' ';
           4:   Temp := ' Ú'+_Replicate('Ä',SWid+4)+'¿ ';
           END;
           FastWrite(Temp,YPos,XPos-2,dtColours^.MenuSeperator);
         END
         ELSE IF Loop=dtMenus^.Menu[dtApp^.CurrentMenu].NumOpt+1 THEN
         BEGIN
           CASE dtApp^.AppStyle OF
           1:   Temp := ' È'+_Replicate('Í',SWid+4)+'¼ ';
           2,5: Temp := ' À'+_Replicate('Ä',SWid+4)+'Ù ';
           3:   Temp := ' '+_Replicate('Ä',SWid+6)+' ';
           4:   Temp := ' À'+_Replicate('Ä',SWid+4)+'Ù ';
           END;
           FastWrite(Temp,YPos,XPos-2,dtColours^.MenuSeperator);
         END
         ELSE
         BEGIN
           IF dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[Loop].Seperator THEN
           BEGIN
             CASE dtApp^.AppStyle OF
             1:   Temp := ' Ç'+_Replicate('Ä',SWid+4)+'¶ ';
             2,5: Temp := ' Ã'+_Replicate('Ä',SWid+4)+'´ ';
             3:   Temp := ' '+_Replicate('Ä',SWid+6)+' ';
             4:   Temp := ' Ã'+_Replicate('Ä',SWid+4)+'´ ';
             END;
             FastWrite(Temp,YPos,XPos-2,dtColours^.MenuSeperator);
           END
           ELSE
           BEGIN
             IF dtApp^.AppStyle=1 THEN Temp := ' º'+_Replicate(#32,SWid+4)+'º '
                                  ELSE Temp := ' ³'+_Replicate(#32,SWid+4)+'³ ';
             FastWrite(Temp,YPos,XPos-2,dtColours^.MenuFrame);
             Temp := _PadRight('  '+dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[Loop].Title,SWid+5);
             Work := Pos('~',Temp);
             Delete(Temp,Work,1);
             IF NOT(dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[Loop].Enabled) THEN
             BEGIN
               FastWrite(Temp,YPos,XPos,dtColours^.MenuDisabled);
             END
             ELSE
             BEGIN
               IF Loop=dtApp^.CurrentSelect THEN
               BEGIN
                 FastWrite(Temp,YPos,XPos,dtColours^.MenuSNormal);
                 FastWrite(Temp[Work],YPos,XPos+Work-1,dtColours^.MenuSHighlight)
               END
               ELSE
               BEGIN
                 FastWrite(Temp,YPos,XPos,dtColours^.MenuNormal);
                 FastWrite(Temp[Work],YPos,XPos+Work-1,dtColours^.MenuHighlight);
               END;
             END;
           END;
         END;
       END;
     END;
     FastWrite('³',dtApp^.VideoMode,10,dtColours^.StatusSeperator);
     FastWrite('³',dtApp^.VideoMode,21,dtColours^.StatusSeperator);
     FastWrite('³',dtApp^.VideoMode,66,dtColours^.StatusSeperator);
     FastWrite('F1 ',dtApp^.VideoMode,2,dtColours^.StatusHighlight);
     FastWrite('Help ',dtApp^.VideoMode,5,dtColours^.StatusNormal);
     FastWrite('F2 ',dtApp^.VideoMode,12,dtColours^.StatusHighlight);
     FastWrite('Shell ',dtApp^.VideoMode,15,dtColours^.StatusNormal);
     FastWrite('Mem:',dtApp^.VideoMode,68,dtColours^.StatusNormal);
     FastWrite(_Mid(_String(Trunc(MemAvail/1024))+'kb',1,8),dtApp^.VideoMode,73,dtColours^.StatusHighlight);
     IF ((dtApp^.AppMenus<>0) AND (dtApp^.CurrentMenu<>0))
        THEN Temp := _PadRight(dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[dtApp^.CurrentSelect].KeyHelp,40)
        ELSE Temp := _Replicate(' ',40);
     FastWrite(Temp,dtApp^.VideoMode,23,dtColours^.StatusNormal);
     _ShowMouse;
END;


PROCEDURE dtDrawCurrent;
VAR  Work   : Byte;
     Temp   : String;
     YPos   : Word;
     XPos   : Word;
     SWid   : Byte;
BEGIN
     IF dtApp^.CurrentMenu=0 THEN Exit;
     _HideMouse;
     XPos := dtMenus^.Menu[dtApp^.CurrentMenu].XPos;
     SWid := dtMenus^.Menu[dtApp^.CurrentMenu].MaxMenuWidth;
     YPos := dtApp^.MenuBarY+dtApp^.CurrentSelect+1;
     Temp := _PadRight('  '+dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[dtApp^.CurrentSelect].Title,SWid+5);
     Work := Pos('~',Temp);
     Delete(Temp,Work,1);
     IF NOT(dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[dtApp^.CurrentSelect].Enabled) THEN
     BEGIN
       FastWrite(Temp,YPos,XPos,dtColours^.MenuSDisabled);
     END
     ELSE
     BEGIN
       FastWrite(Temp,YPos,XPos,dtColours^.MenuSNormal);
       FastWrite(Temp[Work],YPos,XPos+Work-1,dtColours^.MenuSHighlight);
     END;
     Temp := _PadRight(dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[dtApp^.CurrentSelect].KeyHelp,40);
     FastWrite(Temp,dtApp^.VideoMode,23,dtColours^.StatusNormal);
     _ShowMouse;
END;


PROCEDURE dtClearCurrent;
VAR  Work   : Byte;
     Temp   : String;
     YPos   : Word;
     XPos   : Word;
     SWid   : Byte;
BEGIN
     IF dtApp^.CurrentMenu=0 THEN Exit;
     _HideMouse;
     XPos := dtMenus^.Menu[dtApp^.CurrentMenu].XPos;
     SWid := dtMenus^.Menu[dtApp^.CurrentMenu].MaxMenuWidth;
     YPos := dtApp^.MenuBarY+dtApp^.CurrentSelect+1;
     Temp := _PadRight('  '+dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[dtApp^.CurrentSelect].Title,SWid+5);
     Work := Pos('~',Temp);
     Delete(Temp,Work,1);
     IF NOT(dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[dtApp^.CurrentSelect].Enabled) THEN
     BEGIN
       FastWrite(Temp,YPos,XPos,dtColours^.MenuDisabled);
     END
     ELSE
     BEGIN
       FastWrite(Temp,YPos,XPos,dtColours^.MenuNormal);
       FastWrite(Temp[Work],YPos,XPos+Work-1,dtColours^.MenuHighlight);
     END;
     _ShowMouse;
END;


PROCEDURE dtSwitchMenu;
VAR  Loop   : Byte;
     Work   : Byte;
     Temp   : String;
     YPos   : Word;
     XPos   : Word;
     SWid   : Byte;
BEGIN
     _HideMouse;
     FOR Loop := 1 TO dtApp^.AppMenus DO
     BEGIN
       Temp := dtMenus^.Menu[Loop].Title;
       Work := Pos('~',Temp);
       Delete(Temp,Work,1);
       IF Loop=dtApp^.CurrentMenu THEN
       BEGIN
         FastWrite(' '+Temp+' ',dtApp^.MenuBarY,dtMenus^.Menu[Loop].XPos-1,dtColours^.MenuSNormal);
         FastWrite(Temp[Work],dtApp^.MenuBarY,dtMenus^.Menu[Loop].XPos+Work-1,dtColours^.MenuSHighlight);
       END
       ELSE
       BEGIN
         FastWrite(' '+Temp+' ',dtApp^.MenuBarY,dtMenus^.Menu[Loop].XPos-1,dtColours^.MenuNormal);
         FastWrite(Temp[Work],dtApp^.MenuBarY,dtMenus^.Menu[Loop].XPos+Work-1,dtColours^.MenuHighlight);
       END;
     END;
     Move(dtApp^.SavedDesktop,MEM[SegB800:(dtApp^.MenuBarY*160)],(dtApp^.VideoMode-(dtApp^.MenuBarY+1))*160);
     IF (dtApp^.CurrentMenu<>0) THEN
     BEGIN
       XPos := dtMenus^.Menu[dtApp^.CurrentMenu].XPos;
       SWid := dtMenus^.Menu[dtApp^.CurrentMenu].MaxMenuWidth;
       winDropShadow(XPos-2,dtApp^.MenuBarY+1,XPos+SWid+5,dtApp^.MenuBarY+2+dtMenus^.Menu[dtApp^.CurrentMenu].NumOpt);
       FOR Loop := 0 TO (dtMenus^.Menu[dtApp^.CurrentMenu].NumOpt+1) DO
       BEGIN
         YPos := dtApp^.MenuBarY+Loop+1;
         IF Loop=0 THEN
         BEGIN
           CASE dtApp^.AppStyle OF
           1:   Temp := ' É'+_Replicate('Í',SWid+4)+'» ';
           2,5: Temp := ' Ú'+_Replicate('Ä',SWid+4)+'¿ ';
           3:   Temp := ' '+_Replicate('Ä',SWid+6)+' ';
           4:   Temp := ' Ú'+_Replicate('Ä',SWid+4)+'¿ ';
           END;
           FastWrite(Temp,YPos,XPos-2,dtColours^.MenuSeperator);
         END
         ELSE IF Loop=dtMenus^.Menu[dtApp^.CurrentMenu].NumOpt+1 THEN
         BEGIN
           CASE dtApp^.AppStyle OF
           1:   Temp := ' È'+_Replicate('Í',SWid+4)+'¼ ';
           2,5: Temp := ' À'+_Replicate('Ä',SWid+4)+'Ù ';
           3:   Temp := ' '+_Replicate('Ä',SWid+6)+' ';
           4:   Temp := ' À'+_Replicate('Ä',SWid+4)+'Ù ';
           END;
           FastWrite(Temp,YPos,XPos-2,dtColours^.MenuSeperator);
         END
         ELSE
         BEGIN
           IF dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[Loop].Seperator THEN
           BEGIN
             CASE dtApp^.AppStyle OF
             1:   Temp := ' Ç'+_Replicate('Ä',SWid+4)+'¶ ';
             2,5: Temp := ' Ã'+_Replicate('Ä',SWid+4)+'´ ';
             3:   Temp := ' '+_Replicate('Ä',SWid+6)+' ';
             4:   Temp := ' Ã'+_Replicate('Ä',SWid+4)+'´ ';
             END;
             FastWrite(Temp,YPos,XPos-2,dtColours^.MenuSeperator);
           END
           ELSE
           BEGIN
             IF dtApp^.AppStyle=1 THEN Temp := ' º'+_Replicate(#32,SWid+4)+'º '
                                  ELSE Temp := ' ³'+_Replicate(#32,SWid+4)+'³ ';
             FastWrite(Temp,YPos,XPos-2,dtColours^.MenuFrame);
             Temp := _PadRight('  '+dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[Loop].Title,SWid+5);
             Work := Pos('~',Temp);
             Delete(Temp,Work,1);
             IF NOT(dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[Loop].Enabled) THEN
             BEGIN
               FastWrite(Temp,YPos,XPos,dtColours^.MenuDisabled);
             END
             ELSE
             BEGIN
               IF Loop=dtApp^.CurrentSelect THEN
               BEGIN
                 FastWrite(Temp,YPos,XPos,dtColours^.MenuSNormal);
                 FastWrite(Temp[Work],YPos,XPos+Work-1,dtColours^.MenuSHighlight);
               END
               ELSE
               BEGIN
                 FastWrite(Temp,YPos,XPos,dtColours^.MenuNormal);
                 FastWrite(Temp[Work],YPos,XPos+Work-1,dtColours^.MenuHighlight);
               END;
             END;
           END;
         END;
       END;
       Temp := _PadRight(dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[dtApp^.CurrentSelect].KeyHelp,40);
     END
     ELSE Temp := _Replicate(' ',40);
     FastWrite(Temp,dtApp^.VideoMode,23,dtColours^.StatusNormal);
     _ShowMouse;
END;


PROCEDURE dtRepaintMenuOptions;
VAR  Loop   : Byte;
     Work   : Byte;
     Temp   : String;
     YPos   : Word;
     XPos   : Word;
     SWid   : Byte;
BEGIN
     IF dtApp^.CurrentMenu=0 THEN Exit;
     _HideMouse;
     XPos := dtMenus^.Menu[dtApp^.CurrentMenu].XPos;
     SWid := dtMenus^.Menu[dtApp^.CurrentMenu].MaxMenuWidth;
     FOR Loop := 1 TO dtMenus^.Menu[dtApp^.CurrentMenu].NumOpt DO
     BEGIN
       YPos := dtApp^.MenuBarY+Loop+1;
       IF NOT(dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[Loop].Seperator) THEN
       BEGIN
         Temp := _PadRight('  '+dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[Loop].Title,SWid+5);
         Work := Pos('~',Temp);
         Delete(Temp,Work,1);
         IF NOT(dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[Loop].Enabled) THEN
         BEGIN
           FastWrite(Temp,YPos,XPos,dtColours^.MenuDisabled);
         END
         ELSE
         BEGIN
           IF Loop=dtApp^.CurrentSelect THEN
           BEGIN
             FastWrite(Temp,YPos,XPos,dtColours^.MenuSNormal);
             FastWrite(Temp[Work],YPos,XPos+Work-1,dtColours^.MenuSHighlight);
           END
           ELSE
           BEGIN
             FastWrite(Temp,YPos,XPos,dtColours^.MenuNormal);
             FastWrite(Temp[Work],YPos,XPos+Work-1,dtColours^.MenuHighlight);
           END;
         END;
       END;
     END;
     _ShowMouse;
END;


PROCEDURE menuNewOption(Title,KeyHelp: String; Enabled,SubLink: Boolean);
VAR  Work   : Byte;
     NumOpt : Byte;
BEGIN
     INC(dtMenus^.Menu[dtApp^.AppMenus].NumOpt);
     NumOpt := dtMenus^.Menu[dtApp^.AppMenus].NumOpt;
     dtMenus^.Menu[dtApp^.AppMenus].MenuOpt[NumOpt].Seperator := False;
     IF Title='!' THEN
     BEGIN
       dtMenus^.Menu[dtApp^.AppMenus].MenuOpt[NumOpt].Seperator := True;
     END;
     Work := Pos('~',Title);
     dtMenus^.Menu[dtApp^.AppMenus].MenuOpt[NumOpt].KeyPress := UpCase(Title[Work+1]);
     dtMenus^.Menu[dtApp^.AppMenus].MenuOpt[NumOpt].Enabled  := Enabled;
     dtMenus^.Menu[dtApp^.AppMenus].MenuOpt[NumOpt].KeyHelp  := KeyHelp;
     dtMenus^.Menu[dtApp^.AppMenus].MenuOpt[NumOpt].Title    := Title;
     IF (LENGTH(Title)-1)>dtMenus^.Menu[dtApp^.AppMenus].MaxMenuWidth
        THEN dtMenus^.Menu[dtApp^.AppMenus].MaxMenuWidth := LENGTH(Title)-1;
END;


FUNCTION menuExecute(VAR Menu,Option: Word): Boolean;
VAR  C         : Char;
     Status    : Boolean;
     Loop      : Byte;
     MouseX    : Word;
     MouseY    : Word;
     MouseB    : Word;
     Work      : Word;
     x1        : Word;
     y1        : Word;
     x2        : Word;
     y2        : Word;
     TheOne    : Byte;
     OuttaHere : Boolean;
BEGIN
     Menu   := 0;
     Option := 0;
     Status := False;
     IF KeyPressed THEN
     BEGIN
       C := UpCase(ReadKey);
       IF C=#0 THEN
       BEGIN
         C := ReadKey;
         CASE C OF
         #45,
         #107: BEGIN {Exit Program}
                 Status := True;
                 ApplicationClosed := True;
               END;
         #59:  BEGIN {Help}
                 {FUCK}
               END;
         #60:  BEGIN {Dos}
                 winShellToDos;
               END;
         #72:  IF (dtApp^.CurrentMenu<>0) THEN
               BEGIN {Up}
                 dtClearCurrent;
                 DEC(dtApp^.CurrentSelect);
                 IF dtApp^.CurrentSelect=0 THEN dtApp^.CurrentSelect := dtMenus^.Menu[dtApp^.CurrentMenu].NumOpt;
                 IF dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[dtApp^.CurrentSelect].Seperator THEN DEC(dtApp^.CurrentSelect);
                 dtDrawCurrent;
               END;
         #80:  IF (dtApp^.CurrentMenu<>0) THEN
               BEGIN {Down}
                 dtClearCurrent;
                 INC(dtApp^.CurrentSelect);
                 IF dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[dtApp^.CurrentSelect].Seperator THEN INC(dtApp^.CurrentSelect);
                 IF dtApp^.CurrentSelect>dtMenus^.Menu[dtApp^.CurrentMenu].NumOpt THEN dtApp^.CurrentSelect := 1;
                 dtDrawCurrent;
               END;
         #75:  IF (dtApp^.CurrentMenu<>0) THEN
               BEGIN {Left}
                 DEC(dtApp^.CurrentMenu);
                 IF dtApp^.CurrentMenu=0 THEN dtApp^.CurrentMenu := dtApp^.AppMenus;
                 dtApp^.CurrentSelect := 1;
                 dtSwitchMenu;
               END;
         #77:  IF (dtApp^.CurrentMenu<>0) THEN
               BEGIN {Right}
                 INC(dtApp^.CurrentMenu);
                 IF dtApp^.CurrentMenu>dtApp^.AppMenus THEN dtApp^.CurrentMenu := 1;
                 dtApp^.CurrentSelect := 1;
                 dtSwitchMenu;
               END;
         ELSE  BEGIN
                 C := _AltToNormal(C);
                 FOR Loop := 1 TO dtApp^.AppMenus DO
                 BEGIN
                   IF (Loop<>dtApp^.CurrentMenu) THEN
                   BEGIN
                     IF dtMenus^.Menu[Loop].KeyPress=C THEN
                     BEGIN
                       dtApp^.CurrentMenu := Loop;
                       dtApp^.CurrentSelect := 1;
                       dtSwitchMenu;
                     END;
                   END;
                 END;
               END;
         END;
       END
       ELSE
       BEGIN
         CASE C OF
         #13: BEGIN
                Status := True;
                Menu   := dtApp^.CurrentMenu;
                Option := dtApp^.CurrentSelect;
              END;
         #27: BEGIN {Exit Program}
                IF dtApp^.CurrentMenu=0 THEN
                BEGIN
                  Status := True;
                  ApplicationClosed := True;
                END
                ELSE
                BEGIN
                  dtApp^.CurrentMenu := 0;
                  dtApp^.CurrentSelect := 1;
                  dtSwitchMenu;
                END;
              END;
         ELSE BEGIN
                FOR Loop := 1 TO dtMenus^.Menu[dtApp^.CurrentMenu].NumOpt DO
                BEGIN
                  IF dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[Loop].Enabled THEN
                  BEGIN
                    IF NOT(dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[Loop].Seperator) THEN
                    BEGIN
                      IF dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[Loop].KeyPress=C THEN
                      BEGIN
                        dtApp^.CurrentSelect := Loop;
                        dtDrawCurrent;
                        Status := True;
                        Menu   := dtApp^.CurrentMenu;
                        Option := dtApp^.CurrentSelect;
                      END;
                    END;
                  END;
                END;
              END;
         END;
       END;
     END
     ELSE
     BEGIN
       MouseB := _MousePosition(MouseX,MouseY);
       IF MouseB=1 THEN
       BEGIN
         IF MouseY=dtApp^.MenuBarY THEN
         BEGIN
           FOR Loop := 1 TO dtApp^.AppMenus DO
           BEGIN
             IF (Loop<>dtApp^.CurrentMenu) THEN
             BEGIN
               Work := dtMenus^.Menu[Loop].XPos;
               IF ((MouseX>=(Work-1)) AND (MouseX<Work+LENGTH(dtMenus^.Menu[Loop].Title))) THEN
               BEGIN
                 dtApp^.CurrentMenu := Loop;
                 dtApp^.CurrentSelect := 1;
                 dtSwitchMenu;
               END;
             END
             ELSE TimeSlice;
           END;
         END
         ELSE IF MouseY=dtApp^.VideoMode THEN
         BEGIN
           IF MouseX IN [1..9] THEN {Main Help}
           BEGIN
             {FUCK}
           END
           ELSE IF MouseX IN [11..20] THEN {Dos Shell}
           BEGIN
             winShellToDos;
           END
           ELSE TimeSlice;
         END
         ELSE
         BEGIN
           IF (dtApp^.CurrentMenu<>0) THEN
           BEGIN
             x1 := dtMenus^.Menu[dtApp^.CurrentMenu].XPos;
             y1 := dtApp^.MenuBarY+2;
             x2 := dtMenus^.Menu[dtApp^.CurrentMenu].XPos+dtMenus^.Menu[dtApp^.CurrentMenu].MaxMenuWidth+3;
             y2 := dtApp^.MenuBarY+dtMenus^.Menu[dtApp^.CurrentMenu].NumOpt+1;
             IF ((MouseX>=x1) AND (MouseX<=x2)) THEN
             BEGIN
               IF ((MouseY>=y1) AND (MouseY<=y2)) THEN
               BEGIN
                 TheOne    := 0;
                 OuttaHere := False;
                 REPEAT
                   MouseB := _MousePosition(MouseX,MouseY);
                   IF MouseB=1 THEN
                   BEGIN
                     IF ((MouseX>=x1) AND (MouseX<=x2)) THEN
                     BEGIN
                       IF ((MouseY>=y1) AND (MouseY<=y2)) THEN
                       BEGIN
                         TheOne := MouseY-y1+1;
                         IF (TheOne<>dtApp^.CurrentSelect) THEN
                         BEGIN
                           IF NOT(dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[TheOne].Seperator) THEN
                           BEGIN
                             dtClearCurrent;
                             dtApp^.CurrentSelect := TheOne;
                             dtDrawCurrent;
                           END;
                         END;
                       END;
                     END;
                     TimeSlice;
                   END
                   ELSE OuttaHere := True;
                   IF ((MouseX<x1) OR (MouseX>x2) OR (MouseY<y1) OR (MouseY>y2)) THEN
                   BEGIN
                     OuttaHere := True;
                     TheOne    := 0;
                   END;
                 UNTIL OuttaHere;
                 IF (TheOne<>0) THEN
                 BEGIN
                   IF dtMenus^.Menu[dtApp^.CurrentMenu].MenuOpt[dtApp^.CurrentSelect].Enabled THEN
                   BEGIN
                     Status := True;
                     Menu   := dtApp^.CurrentMenu;
                     Option := dtApp^.CurrentSelect;
                   END;
                 END;
               END;
             END;
           END;
         END;
       END
       ELSE IF MouseB=2 THEN
       BEGIN
         IF (dtApp^.CurrentMenu<>0) THEN
         BEGIN
           dtApp^.CurrentMenu := 0;
           dtApp^.CurrentSelect := 1;
           dtSwitchMenu;
         END
         ELSE TimeSlice;
       END
       ELSE TimeSlice;
     END;
     menuExecute := Status;
END;


PROCEDURE menuToggleOption(Menu,Option: Byte; OnOff: Boolean);
BEGIN
     IF (dtMenus^.Menu[Menu].MenuOpt[Option].Enabled<>OnOff) THEN
     BEGIN
       dtMenus^.Menu[Menu].MenuOpt[Option].Enabled := OnOff;
       IF Menu=dtApp^.CurrentMenu THEN
       BEGIN
         dtRepaintMenuOptions;
       END;
     END;
END;


PROCEDURE dtSetUserDesktopDraw(SProc : dtDrawDesktop);
BEGIN
     dtUserDrawDesktop := SProc;
END;


BEGIN
     dtUserDrawDesktop := dtNoDrawDesktop;
END.