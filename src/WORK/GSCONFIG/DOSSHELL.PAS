{$I DEFINES.INC}
UNIT DosShell;


INTERFACE


PROCEDURE ShellToDos;


IMPLEMENTATION


USES IntrFace,Crt,Dos,CnfgVars,Dispatch,BsMouse,BsExec,BsKeys,BsVideo;


PROCEDURE ShellToDos;
BEGIN
     _SaveWindow(WorkDir+'\DOSSHELL.SCR');
     _HideMouse;
     TextColor_BS(7);
     TextBackGround_BS(0);
     ClrScr;
     _ShowCursor;
     _HighBackGrounds(False);
     PutEnviro('PROMPT=Enter EXIT to return to Shotgun Professional!!$_$p$g');
     DoExec(GetEnv('COMSPEC'),' /C '+GetEnv('COMSPEC'),USE_ALL,WorkDir);
     ChDir(BaseDirectory);
     _HighBackGrounds(True);
     _HideCursor;
     LoadWindow(WorkDir+'\DOSSHELL.SCR');
     _ShowMouse;
     MouseSpeed;
END;


END.