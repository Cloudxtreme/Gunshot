{$I DEFINES.INC}
UNIT Sema;


INTERFACE


PROCEDURE AddToSemaphores(MsgBase: String; MsgNumber: Word);


IMPLEMENTATION


USES Globals,BsString,BsFile;


PROCEDURE AddToSemaphores(MsgBase: String; MsgNumber: Word);
VAR  TFile         : Text;
     Temp          : String;
     FileName      : String;
BEGIN
     ASSIGN(FMailerInfo,DATA_Directory+'\MAILER.DAT');
     {$I-}
     RESET(FMailerInfo);
     SEEK(FMailerInfo,NodeNumber-1);
     READ(FMailerInfo,MailerInfo);
     CLOSE(FMailerInfo);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          Temp := _UpperCase(MsgBase)+' '+_String(MsgNumber);
          IF _FileExists(MailerInfo.Semaphores+'ECHOMAIL.BBS') THEN
          BEGIN
               ASSIGN(TFile,MailerInfo.Semaphores+'ECHOMAIL.BBS');
               APPEND(TFile);
               WRITELN(TFile,Temp);
               CLOSE(TFile);
          END
          ELSE
          BEGIN
               ASSIGN(TFile,MailerInfo.Semaphores+'ECHOMAIL.BBS');
               REWRITE(TFile);
               WRITELN(TFile,Temp);
               CLOSE(TFile);
          END;
     END;
END;


END.