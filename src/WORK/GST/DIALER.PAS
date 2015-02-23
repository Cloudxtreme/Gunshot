{$I DEFINES.INC}
UNIT Dialer;


INTERFACE


PROCEDURE DoServiceDialer;


IMPLEMENTATION


USES __Gfx,Comm,BsMulti,SysDial,GSession,EService,AService,IService,
     DService,SService,ApCom,ApPort,BsGraph,Config,Globals,BsFile,BsString,
     {$IFDEF DPMI}
     Gr2_Bp,Gx2_Bp,Gx2_BpVC;
     {$ELSE}
     Gr_Tp,Gx_Tp,Gx_TpVC;
     {$ENDIF}


PROCEDURE DoServiceDialer;
VAR  C     : Word;
     Loop  : Word;
     FFile : File;
     BRead : Word;
     Temp  : String;
LABEL       AllOverAgain;
BEGIN
     LoadConfiguration;
     IF NOT(Comm_init) THEN
     BEGIN
          grDisplayMouse(GrHide);
          WindowHeaderC := 4;
          WindowHighC   := 12;
          WindowLowC    := 0;
          DrawWindow(200,150,440,290,'MODEM SETUP ERROR!',0);
          OutTextXY(215,180,0,255,1,'Could not open the com port! Please');
          OutTextXY(215,195,0,255,1,'review your settings in the setup &');
          OutTextXY(215,210,0,255,1,'configuration on the main menu.');
          DoOkButton(350,240);
          grDisplayMouse(GrShow);
          REPEAT
                c := MouseHandler(False);
                IF c=0 THEN TimeSlice;
          UNTIL C=NButtons;
          WindowHeaderC := 57;
          WindowHighC   := 60;
          WindowLowC    := 54;
          KillWindow;
          Exit;
     END;
     AllOverAgain:
     grDisplayMouse(GrHide);
     DrawWindow(25,40,595,440,'SERVICE DIALER',0);
     GrSetFillStyle(GrFSolid,242,GrOpaque);
     GrDrawRect(35,75,475,90,GrFill);
     OutTextXY(45,75,15,255,1,'System Name');
     OutTextXY(285,75,15,255,1,'Phone Number');
     NewPickList(35,95,22,50,True);
     IF NOT(_FileExists('GST.DIR')) THEN
     BEGIN
          FillChar(DialDir,SizeOf(DialDir),0);
          ASSIGN(FDialDir,'GST.DIR');
          REWRITE(FDialDir);
          DialDir.Name    := 'GUNN Data Systems I [33.6k]';
          DialDir.Phone   := '1-250-365-3693';
          DialDir.DoESCs  := True;
          DialDir.Sound   := True;
          WRITE(FDialDir,DialDir);
          AddToPickList(' '+_PadRight(DialDir.Name,30)+_PadRight(DialDir.Phone,20));
          CLOSE(FDialDir);
     END
     ELSE
     BEGIN
          ASSIGN(FDialDir,'GST.DIR');
          RESET(FDialDir);
          REPEAT
                READ(FDialDir,DialDir);
                AddToPickList(' '+_PadRight(DialDir.Name,30)+_PadRight(DialDir.Phone,20));
          UNTIL EOF(FDialDir);
          CLOSE(FDialDir);
     END;
     SetUpPickList;
     Loop := 75;
     SystemButton(485,Loop,585,Loop+40,1,False,True);
       SystemIcon(490,Loop+5,76); OutTextXY(530,Loop+13,0,255,1,'Dial'); INC(Loop,45);
     SystemButton(485,Loop,585,Loop+40,1,False,True);
       SystemIcon(490,Loop+5,64); OutTextXY(530,Loop+13,0,255,1,'Mark'); INC(Loop,45);
     SystemButton(485,Loop,585,Loop+40,1,False,True);
       SystemIcon(490,Loop+5,31); OutTextXY(530,Loop+13,0,255,1,'Edit'); INC(Loop,45);
     SystemButton(485,Loop,585,Loop+40,1,False,True);
       SystemIcon(490,Loop+5,15); OutTextXY(530,Loop+13,0,255,1,'Add'); INC(Loop,45);
     SystemButton(485,Loop,585,Loop+40,1,False,True);
       SystemIcon(490,Loop+5,16); OutTextXY(530,Loop+13,0,255,1,'Insert'); INC(Loop,45);
     SystemButton(485,Loop,585,Loop+40,1,False,True);
       SystemIcon(490,Loop+5,8); OutTextXY(530,Loop+13,0,255,1,'Delete'); INC(Loop,45);
     SystemButton(485,Loop,585,Loop+40,1,False,True);
       SystemIcon(490,Loop+5,71); OutTextXY(530,Loop+13,0,255,1,'Sort'); INC(Loop,45);
     SystemButton(485,Loop,585,Loop+40,1,False,True);
       SystemIcon(490,Loop+5,9); OutTextXY(530,Loop+13,0,255,1,'Quit'); INC(Loop,45);
     grDisplayMouse(GrShow);
     REPEAT
           c := MouseHandler(False);
           CASE C OF
           0:   TimeSlice;
           3:   IF (PickInfo.Current<>0) THEN
                BEGIN
                     NumInQueue := 0;
                     FOR Loop := 1 TO PickInfo.NumItems DO
                     BEGIN
                          Temp := PickContents(Loop);
                          IF Temp[1]=#254 THEN
                          BEGIN
                               INC(NumInQueue);
                               CallQueue[NumInQueue] := Loop;
                          END;
                     END;
                     IF NumInQueue=0 THEN
                     BEGIN
                          INC(NumInQueue);
                          CallQueue[NumInQueue] := PickInfo.Current;
                     END;
                     IF SystemDialed THEN
                     BEGIN
                          GrDisplayMouse(GrHide);
                          Save_Screen;
                          Fade_Out;
                          GrTrackMouse(GrNoTrack);
                          GrStopMouse;
                          gxSetMode(gxText);
                          DoTerminal;
                          gxSetMode(gxGraphics);
                          gxSetConvertPalette(GxPAL5,@P256);
                          GxSetDisplayPalette(@P256);
                          GrSetMouseMode(gxGraphics);
                          GrInitMouse;
                          GrSetMouseMode(gxGraphics);
                          GrTrackMouse(GrTrack);
                          GrSetMouseBounds(0,0,GraphMaxX-10,GraphMaxY-10);
                          SetPixeltoMickey(3,5);
                          Fade_Out;
                          Load_Screen;
                          GrSetMouseBounds(0,0,GraphMaxX-10,GraphMaxY-10);
                          GrDisplayMouse(GrShow);
                          Fade_In;
                     END;
                END;
           4:   IF (PickInfo.Current<>0) THEN
                BEGIN
                     Temp := PickContents(PickInfo.Current);
                     IF Temp[1]=' ' THEN Temp[1] := #254
                                    ELSE Temp[1] := ' ';
                     SetPickList(PickInfo.Current,Temp);
                     grDisplayMouse(GrHide);
                     SetUpPickList;
                     grDisplayMouse(GrShow);
                END;
           5:   IF (PickInfo.Current<>0) THEN EditService(PickInfo.Current);
           6:   AddService;
           7:   IF PickInfo.Current=0
                   THEN AddService
                   ELSE InsertService(PickInfo.Current);
           8:   IF (PickInfo.Current<>0) THEN
                BEGIN
                     IF (PickInfo.NumItems>1) THEN DeleteService(PickInfo.Current);
                END;
           9:   IF (PickInfo.Current<>0) THEN SortServices;
           END;
     UNTIL c=NButtons;
     KillWindow;
     ptOptionsOn(BBSPort,ptRestoreOnClose OR ptDropModemOnClose);
     Comm_Deinit;
END;


END.
