{$IFNDEF DPMI}
  DPMI ONLY!!!!!!!
{$ENDIF}

{$I DEFINES.INC}
{$M 64000}
PROGRAM GUIEditor;


USES Dos,Gx2_Bp,Globals,_Win,BHandler,_Icons,FMode,_Text,Gr2_Bp,ScrnEdit,
     IconEdit,RatEdit,Intro,BsString,BsFile,BsMouse,BsGraph;


PROCEDURE DoMainMenu;
VAR  AllDone : Boolean;
     DoJob   : Word;

     PROCEDURE DrawMainMenu;
     BEGIN
          NButtons := 0;
          DrawWindow(10,180,250,415,'MAIN MENU',MainWindow);
          InvertedBox(15,210,245,410);
          SystemButton(25,222,235,262,1,False,True);
          SystemButton(25,267,235,307,1,False,True);
          SystemButton(25,312,235,352,1,False,True);
          SystemButton(25,357,235,397,1,False,True);
          SystemIcon(35,227,43);
          SystemIcon(35,272,42);
          SystemIcon(35,317,69);
          SystemIcon(35,362,9);
          OutTextXY(85,235,0,255,1,'Screen Editor');
          OutTextXY(85,280,0,255,1,'Icon Editor');
          OutTextXY(85,325,0,255,1,'Mouse Cursor Editor');
          OutTextXY(85,370,0,255,1,'Exit The GUI Editor');
          GrDisplayMouse(GrShow);
          GetFreeMem;
     END;

BEGIN
     DrawMainMenu;
     AllDone := False;
     REPEAT
           DoJob := MouseHandler(False);
           IF DoJob<>0 THEN
           BEGIN
                CASE DoJob OF
                1:   BEGIN
                          KillWindow;
                          ScreenEditor;
                          GrDisplayMouse(GrHide);
                          DrawMainMenu;
                     END;
                2:   BEGIN
                          KillWindow;
                          IconEditor;
                          GrDisplayMouse(GrHide);
                          DrawMainMenu;
                     END;
                3:   BEGIN
                          KillWindow;
                          MouseEditor;
                          GrDisplayMouse(GrHide);
                          DrawMainMenu;
                     END;
                4:   BEGIN
                          KillWindow;
                          AllDone := True;
                     END;
                END;
           END;
     UNTIL AllDone;
END;


PROCEDURE GetParams;
VAR  Temp : String;
     Loop : Word;
BEGIN
     FOR Loop := 1 TO ParamCount DO
     BEGIN
          Temp := _UpperCase(ParamStr(Loop));
          IF Temp='-NOROM' THEN
          BEGIN

          END
          ELSE IF _Mid(Temp,1,5)='-WORK' THEN
          BEGIN
               Delete(Temp,1,5);
               WorkDir := _Path(Temp);
          END
          ELSE LangDir := Temp;
     END;
END;


BEGIN
     FileMode := SetFileMode;
     IF NOT(IsMouseInstalled) THEN
     BEGIN
          WRITELN; WRITELN;
          WRITELN('Mouse not installed! Aborting.');
          WRITELN;
          Halt;
     END;
     GetParams;
     YWindow     := 429;
     Gunshot_Dir := _GetFilePath(ParamStr(0));
     Dec(Gunshot_Dir[0]);
     ChDir(Gunshot_Dir);
     ICONDir     := Gunshot_Dir+'\ICONS\';
     FONTDir     := Gunshot_Dir+'\FONTS\';
     SOUNDDir    := Gunshot_Dir+'\SOUND\';
     JPEGDir     := Gunshot_Dir+'\IMAGES\';
     IF (WorkDir<>'') THEN
     BEGIN
          _CopyFile('GUI.GXL',Gunshot_Dir+'\BIN\',WorkDir);
          GraphicsLibrary := WorkDir+'GUI.GXL';
     END
     ELSE GraphicsLibrary := Gunshot_Dir+'\BIN\GUI.GXL';
     IF LangDir='' THEN LangDir := Gunshot_Dir+'\SG\';
     LangDir := _Path(LangDir);
     SGDir       := LangDir;
     _CreatePath(SGDir);
     _CreatePath(ICONDir);
     _CreatePath(FONTDir);
     _CreatePath(SOUNDDir);
     _CreatePath(JPEGDir);
     _CreatePath(WorkDir);
     LoadSystem;
     Fade_In;
     DoAbout;
     DoMainMenu;
     Fade_Out;
     IF (WorkDir<>'') THEN _EraseFile(WorkDir+'GUI.GXL');
     ShutDownSystem;
END.
