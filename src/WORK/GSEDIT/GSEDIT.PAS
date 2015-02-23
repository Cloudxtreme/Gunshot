{$IFDEF DPMI}
 Duh, real mode stupid!
{$ENDIF}

{$I DEFINES.INC}
{$M 32000,0,655360}
PROGRAM GSEditMailEditor;


USES FMode,NetEdit,Crt,Globals,MkFFile,BsString,BsFile,BsExec,KeyCheck;


PROCEDURE LoadData;
VAR  Temp : String;
     loop : word;
BEGIN
     Temp := ParamStr(0);
     FNodeIndx.Init(32768);
     FNodeList.Init(32768);
     FUserList.Init(32768);
     New(SaveScreen2);
     New(SaveScreen3);
     Shotgun_Directory := Temp[1]+':\SHOTGUN';
     ChDir(Shotgun_Directory);
     SimNode         := 1;
     FOR loop := 1 TO Paramcount DO
     BEGIN
          Temp := _UpperCase(ParamStr(Loop));
          IF _Mid(Temp,1,2)='-N' THEN
          BEGIN
               Delete(Temp,1,2);
               SimNode := _Numeric(Temp);
          END;
     END;
     ASSIGN(FSystemInfo,Shotgun_Directory+'\DATA\SYSTEM.DAT');
     RESET(FSystemInfo);
     READ(FSystemInfo,SystemInfo);
     CLOSE(FSystemInfo);

     ASSIGN(FMailerInfo,Shotgun_Directory+'\DATA\MAILER.DAT');
     RESET(FMailerInfo);
     SEEK(FMailerInfo,SimNode-1);
     READ(FMailerInfo,MailerInfo);
     CLOSE(FMailerInfo);

     ASSIGN(FExternalApps,Shotgun_Directory+'\DATA\EXTERNAL.DAT');
     RESET(FExternalApps);
     READ(FExternalApps,ExternalApps);
     CLOSE(FExternalApps);

     CASE SystemInfo.SwapMethod OF
     1:   SwapMethod := USE_EMS or USE_XMS;
     2:   SwapMethod := USE_ALL;
     3:   SwapMethod := USE_FILE or CHECK_NET;
     END;

     _CreatePath(MailerInfo.Outpkts);
     CheckRegistered(MailerInfo.Outpkts,'GSEdit');
END;


PROCEDURE KillData;
BEGIN
     FNodeIndx.Done;
     FNodeList.Done;
     FUserList.Done;
     Dispose(SaveScreen2);
     Dispose(SaveScreen3);
END;


BEGIN
     FileMode := SetFileMode;
     LoadData;
     NetmailEditor;
     KillData;
     ClrScr;
END.
