{$I DEFINES.INC}
UNIT BsExec;


INTERFACE


CONST USE_EMS      =  $01;
      USE_XMS      =  $02;
      USE_FILE     =  $04;
      EMS_FIRST    =  $00;
      XMS_FIRST    =  $10;
      HIDE_FILE    =  $40;
      NO_PREALLOC  = $100;
      CHECK_NET    = $200;
      USE_ALL      = USE_EMS or USE_XMS or USE_FILE or CHECK_NET;


FUNCTION  DoExec(xfn: string; pars: string; spawn: integer; SwpDir: String): integer;
PROCEDURE PutEnviro(EnvVar: String);


IMPLEMENTATION

{$IFDEF DPMI}
USES Dos;
{$ELSE}
{$IFDEF MSDOS}
USES Exec;
{$ENDIF}
{$IFNDEF MSDOS}
USES Dos;
{$ENDIF}
{$ENDIF}


FUNCTION DoExec(xfn: string; pars: string; spawn: integer; SwpDir: String): integer;
VAR  RetCode : Integer;
BEGIN
     {$IFDEF DPMI}
     SwapVectors;
     Exec(xfn,pars);
     SwapVectors;
     DoExec := DosExitCode;
     {$ELSE}
{$IFDEF MSDOS}     
     IF SwpDir[LENGTH(SwpDir)]='\' THEN Dec(SwpDir[0]);
     TheSwapDirectory := SwpDir;
     DoExec := RunExec(xfn,pars,spawn,$ffff,True);
{$ENDIF}
{$IFNDEF MSDOS}
     Exec(xfn,pars);
     DoExec := DosExitCode;
{$ENDIF}
     {$ENDIF}
END;


PROCEDURE PutEnviro(EnvVar: String);
BEGIN
     {$IFNDEF DPMI}
{$IFDEF MSDOS}     
     PutEnv(EnvVar);
{$ENDIF}
     {$ENDIF}
END;


END.
