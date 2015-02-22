{$I DEFINES.INC}
UNIT Banner;


INTERFACE


PROCEDURE SendBanner;
PROCEDURE SendMailOnlyBanner;
PROCEDURE SendTooSlowBanner;


IMPLEMENTATION


USES ApCom,Globals,ApTimer,BsMulti,BsFile,BsCom,Misc;


PROCEDURE SendBanner;
VAR  TFile : Text;
     Temp  : String;
BEGIN
     PutString(bsBBSPort,#13#10#13#10);
     IF _FileExists(MailerInfo.Banner) THEN
     BEGIN
       ASSIGN(TFile,MailerInfo.Banner);
       RESET(TFile);
       REPEAT
         READLN(TFile,Temp);
         PutString(bsBBSPort,Temp+#13#10);
       UNTIL EOF(TFile);
       CLOSE(TFile);
     END
     ELSE PutString(bsBBSPort,'Please wait while '+MailerInfo.BBSSoftware+' is being loaded...'+#13#10);
     PutString(bsBBSPort,#13#10);
     DrainOutBuffer(bsBBSPort,Secs2Tics(60));
END;


PROCEDURE SendMailOnlyBanner;
VAR  TFile : Text;
     Temp  : String;
BEGIN
     PutString(bsBBSPort,#13#10#13#10);
     IF _FileExists(MailerInfo.InEvent) THEN
     BEGIN
       ASSIGN(TFile,MailerInfo.InEvent);
       RESET(TFile);
       REPEAT
         READLN(TFile,Temp);
         PutString(bsBBSPort,TakeOutTheC(Temp+#13#10));
       UNTIL EOF(TFile);
       CLOSE(TFile);
     END
     ELSE PutString(bsBBSPort,'Receiving network mail only...'+#13#10);
     PutString(bsBBSPort,#13#10);
     DrainOutBuffer(bsBBSPort,Secs2Tics(60));
END;


PROCEDURE SendTooSlowBanner;
VAR  TFile : Text;
     Temp  : String;
BEGIN
     PutString(bsBBSPort,#13#10#13#10);
     IF _FileExists(Shotgun_Directory+'\SGMAIL\TOOSLOW.TXT') THEN
     BEGIN
       ASSIGN(TFile,Shotgun_Directory+'\SGMAIL\TOOSLOW.TXT');
       RESET(TFile);
       REPEAT
         READLN(TFile,Temp);
         PutString(bsBBSPort,Temp+#13#10);
       UNTIL EOF(TFile);
       CLOSE(TFile);
     END
     ELSE PutString(bsBBSPort,'Your modem is too slow to use this system...'+#13#10);
     PutString(bsBBSPort,#13#10);
     DrainOutBuffer(bsBBSPort,Secs2Tics(60));
END;


END.
