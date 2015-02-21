{$I DEFINES.INC}
UNIT BsMisc;


INTERFACE


PROCEDURE winShellToDos;


IMPLEMENTATION


USES BsExec,BsGlobal,BsKeys,BsMouse,BsVideo,Crt,Dos;


PROCEDURE winShellToDos;
VAR  SaveScreen : Array[1..8000] Of Byte;
BEGIN
     _HideMouse;
     Move(MEM[SegB800:0],SaveScreen,dtApp^.VideoBytes);
     _ShowCursor;
     TextMode(dtApp^.VideoOrig);
     TextColor(7);
     TextBackGround(0);
     ClrScr;
     IF dtApp^.AppStyle=VideoNU THEN _HighBackGrounds(False);
     IF dtApp^.AppStyle=VideoSG THEN _HighBackGrounds(False);
     PutEnviro('PROMPT=Enter "EXIT" to return to '+dtApp^.AppName+'$_$_$p$g');
     DoExec(GetEnv('COMSPEC'),' /C '+GetEnv('COMSPEC'),USE_ALL,dtApp^.StartUpDir);
     ChDir(dtApp^.StartUpDir);
     CASE dtApp^.VideoMode OF
     25:  TextMode(CO80);
     28:  ExtendedVideoMode(28);
     30:  ExtendedVideoMode(30);
     50:  TextMode(CO80+Font8x8);
     END;
     CheckSnow := False;
     HighVideo;
     TextColor(7);
     TextBackGround(0);
     ClrScr;
     IF dtApp^.AppStyle=VideoNU THEN _HighBackGrounds(True);
     IF dtApp^.AppStyle=VideoSG THEN _HighBackGrounds(True);
     _HideCursor;
     Move(SaveScreen,MEM[SegB800:0],dtApp^.VideoBytes);
     _ShowMouse;
END;


END.