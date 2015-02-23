{$I DEFINES.INC}
{$IFDEF DPMI}
  {$M 64000}
{$ELSE}
  {$M 32000,0,655360}
{$ENDIF}
PROGRAM GSTServicesManager;


{$IFDEF DPMI}
USES Extend,Dos,Globals,Intro,__Gfx,Dialer,Faxes,Config,
     Crt,BsString,BsMouse,BsFile,BsMulti,Gx2_BpVC;
{$ELSE}
USES Extend,BsOvr,Gx_TpVC,Dos,Globals,Intro,__Gfx,Dialer,
     Faxes,Config,Crt,BsString,BsMouse,BsFile,BsMulti;
{$ENDIF}


{$IFNDEF DPMI}
  {$I OVRS.INC}
{$ENDIF}


VAR  C : Word;


BEGIN
     HelpFile := 'GST.HLP';
     TextMode(Co80);
     Window(1,1,80,25);
     IF NOT(IsMouseInstalled) THEN
     BEGIN
          WRITELN; WRITELN;
          WRITELN('Mouse not installed! Aborting.');
          WRITELN;
          Halt;
     END;
     BaseDir := _UpperCase(_GetFilePath(ParamStr(0)));
     BaseDir := Path(BaseDir);
     ChDir(BaseDir);
     FireUpGfx(BaseDir+'\GST.GXL',BaseDir,640);
     DoIntro;
     DrawMainScr;
     REPEAT
           c := MouseHandler(False);
           CASE C OF
           0:   TimeSlice;
           1:   IF _FileExists('GST.CFG')
                   THEN DoServiceDialer
                   ELSE GiveWarning;
           2:   IF _FileExists('GST.CFG')
                   THEN DoFaxes
                   ELSE GiveWarning;
           3:   DoConfiguration;
           END;
     UNTIL c=4;
     KillWindow;
     gxDestroyVirtual(P);
     ShutdownGfx;
END.
