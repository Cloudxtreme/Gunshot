{$I DEFINES.INC}
UNIT Def2;


INTERFACE


PROCEDURE CheckCommands;
PROCEDURE CheckFile3(FileName: String);


IMPLEMENTATION


USES CnfgVars,IntrFace,Version,BsFile;


PROCEDURE CheckCommands;
BEGIN
     IF NOT(_FileExists(SelectedLanguage+'\LANG\MISC.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\MISC.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'Y';
          CommandFile.ANSIString := 'Yes';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'N';
          CommandFile.ANSIString := 'No';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'M';
          CommandFile.ANSIString := 'Male';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'F';
          CommandFile.ANSIString := 'Female';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\FAREAS.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\FAREAS.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'N';
          CommandFile.ANSIString := '{8}[{14}N{8}]{7}ext';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'P';
          CommandFile.ANSIString := '{8}[{14}P{8}]{7}revious';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'T';
          CommandFile.ANSIString := '{8}[{14}T{8}]{7}op';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'B';
          CommandFile.ANSIString := '{8}[{14}B{8}]{7}ottom';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := '+';
          CommandFile.ANSIString := '{8}[{14}+{8}]{7}Tag';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := '-';
          CommandFile.ANSIString := '{8}[{14}-{8}]{7}Untag';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := '*';
          CommandFile.ANSIString := '{8}[{14}*{8}]{7}All';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uit';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\CDROMMAN.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\CDROMMAN.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'N';
          CommandFile.ANSIString := '{8}[{14}N{8}]{7}ext';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'P';
          CommandFile.ANSIString := '{8}[{14}P{8}]{7}revious';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'T';
          CommandFile.ANSIString := '{8}[{14}T{8}]{7}op';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'B';
          CommandFile.ANSIString := '{8}[{14}B{8}]{7}ottom';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := '+';
          CommandFile.ANSIString := '{8}[{14}+{8}]{7}On';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := '-';
          CommandFile.ANSIString := '{8}[{14}-{8}]{7}Off';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := '*';
          CommandFile.ANSIString := '{8}[{14}*{8}]{7}All';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uit';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\FGROUPS.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\FGROUPS.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'N';
          CommandFile.ANSIString := '{8}[{14}N{8}]{7}ext';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'P';
          CommandFile.ANSIString := '{8}[{14}P{8}]{7}revious';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'T';
          CommandFile.ANSIString := '{8}[{14}T{8}]{7}op';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'B';
          CommandFile.ANSIString := '{8}[{14}B{8}]{7}ottom';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uit';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\MAREAS.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\MAREAS.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'N';
          CommandFile.ANSIString := '{8}[{14}N{8}]{7}ext';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'P';
          CommandFile.ANSIString := '{8}[{14}P{8}]{7}revious';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'T';
          CommandFile.ANSIString := '{8}[{14}T{8}]{7}op';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'B';
          CommandFile.ANSIString := '{8}[{14}B{8}]{7}ottom';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := '+';
          CommandFile.ANSIString := '{8}[{14}+{8}]{7}Tag';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := '-';
          CommandFile.ANSIString := '{8}[{14}-{8}]{7}Untag';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := '*';
          CommandFile.ANSIString := '{8}[{14}*{8}]{7}All';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uit';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\MGROUPS.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\MGROUPS.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'N';
          CommandFile.ANSIString := '{8}[{14}N{8}]{7}ext';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'P';
          CommandFile.ANSIString := '{8}[{14}P{8}]{7}revious';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'T';
          CommandFile.ANSIString := '{8}[{14}T{8}]{7}op';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'B';
          CommandFile.ANSIString := '{8}[{14}B{8}]{7}ottom';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uit';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\DLQUEUE.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\DLQUEUE.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'A';
          CommandFile.ANSIString := '{8}[{14}A{8}]{7}dd';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'R';
          CommandFile.ANSIString := '{8}[{14}R{8}]{7}emove';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'E';
          CommandFile.ANSIString := '{8}[{14}E{8}]{7}rase Queue';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'D';
          CommandFile.ANSIString := '{8}[{14}D{8}]{7}ownload';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'K';
          CommandFile.ANSIString := '{8}[{14}K{8}]{7}ill';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'C';
          CommandFile.ANSIString := '{8}[{14}C{8}]{7}opy';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'M';
          CommandFile.ANSIString := '{8}[{14}M{8}]{7}ove';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uit';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\FILEBOX.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\FILEBOX.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'D';
          CommandFile.ANSIString := '{8}[{14}D{8}]{7}ownload';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uit';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\LINEEDIT.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\LINEEDIT.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'C';
          CommandFile.ANSIString := '{8}[{14}C{8}]{7}ontinue';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'S';
          CommandFile.ANSIString := '{8}[{14}S{8}]{7}ave';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'E';
          CommandFile.ANSIString := '{8}[{14}E{8}]{7}dit';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'V';
          CommandFile.ANSIString := '{8}[{14}V{8}]{7}iew';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'A';
          CommandFile.ANSIString := '{8}[{14}A{8}]{7}bort';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'N';
          CommandFile.ANSIString := '{8}[{14}N{8}]{7}etmail Options';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uote';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\LEDIT_E.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\LEDIT_E.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'E';
          CommandFile.ANSIString := '{8}[{14}E{8}]{7}dit Line';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'D';
          CommandFile.ANSIString := '{8}[{14}D{8}]{7}elete Line';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'I';
          CommandFile.ANSIString := '{8}[{14}I{8}]{7}nsert Line';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'C';
          CommandFile.ANSIString := '{8}[{14}C{8}]{7}ancel';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\FLISTHDR.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\FLISTHDR.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'N';
          CommandFile.ANSIString := '{8}[{14}N{8}]{7}ext';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'P';
          CommandFile.ANSIString := '{8}[{14}P{8}]{7}revious';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'T';
          CommandFile.ANSIString := '{8}[{14}T{8}]{7}op';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'B';
          CommandFile.ANSIString := '{8}[{14}B{8}]{7}ottom';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uit';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'M';
          CommandFile.ANSIString := '{8}[{14}M{8}]{7}ark File';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'E';
          CommandFile.ANSIString := '{8}[{14}E{8}]{7}xtended Info';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'V';
          CommandFile.ANSIString := '{8}[{14}V{8}]{7}iew File';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\LISTMSGS.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\LISTMSGS.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'N';
          CommandFile.ANSIString := '{8}[{14}N{8}]{7}ext';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'P';
          CommandFile.ANSIString := '{8}[{14}P{8}]{7}revious';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'T';
          CommandFile.ANSIString := '{8}[{14}T{8}]{7}op';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'B';
          CommandFile.ANSIString := '{8}[{14}B{8}]{7}ottom';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uit';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'R';
          CommandFile.ANSIString := '{8}[{14}R{8}]{7}ead Message';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\PAGEUSER.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\PAGEUSER.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'N';
          CommandFile.ANSIString := '{8}[{14}N{8}]{7}ext';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'P';
          CommandFile.ANSIString := '{8}[{14}P{8}]{7}revious';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'T';
          CommandFile.ANSIString := '{8}[{14}T{8}]{7}op';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'B';
          CommandFile.ANSIString := '{8}[{14}B{8}]{7}ottom';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uit';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\READMAIL.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\READMAIL.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'B';
          CommandFile.ANSIString := '{8}[{14}B{8}]{7}ack';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'M';
          CommandFile.ANSIString := '{8}[{14}M{8}]{7}ore';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'N';
          CommandFile.ANSIString := '{8}[{14}N{8}]{7}ext';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'P';
          CommandFile.ANSIString := '{8}[{14}P{8}]{7}rev';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'R';
          CommandFile.ANSIString := '{8}[{14}R{8}]{7}eply';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'D';
          CommandFile.ANSIString := '{8}[{14}D{8}]{7}L';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'K';
          CommandFile.ANSIString := '{8}[{14}K{8}]{7}ill';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'C';
          CommandFile.ANSIString := '{8}[{14}C{8}]{7}opy';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'H';
          CommandFile.ANSIString := '{8}[{14}H{8}]{7}url';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'F';
          CommandFile.ANSIString := '{8}[{14}F{8}]{7}orward';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uit';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\READNEW.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\READNEW.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'B';
          CommandFile.ANSIString := '{8}[{14}B{8}]{7}ack';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'M';
          CommandFile.ANSIString := '{8}[{14}M{8}]{7}ore';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'N';
          CommandFile.ANSIString := '{8}[{14}N{8}]{7}ext';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'R';
          CommandFile.ANSIString := '{8}[{14}R{8}]{7}eply To Msg';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'D';
          CommandFile.ANSIString := '{8}[{14}D{8}]{7}L';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'S';
          CommandFile.ANSIString := '{8}[{14}S{8}]{7}kip Area';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uit Search';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\USERLIST.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\USERLIST.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'N';
          CommandFile.ANSIString := '{8}[{14}N{8}]{7}ext';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'P';
          CommandFile.ANSIString := '{8}[{14}P{8}]{7}revious';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'T';
          CommandFile.ANSIString := '{8}[{14}T{8}]{7}op';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'B';
          CommandFile.ANSIString := '{8}[{14}B{8}]{7}ottom';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uit';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
     IF NOT(_FileExists(SelectedLanguage+'\LANG\READFILE.CMD')) THEN
     BEGIN
          ASSIGN(FCommandFile,SelectedLanguage+'\LANG\READFILE.CMD');
          REWRITE(FCommandFile);
          CommandFile.KeyPress := 'N';
          CommandFile.ANSIString := '{8}[{14}N{8}]{7}ext';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'P';
          CommandFile.ANSIString := '{8}[{14}P{8}]{7}revious';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'T';
          CommandFile.ANSIString := '{8}[{14}T{8}]{7}op';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'B';
          CommandFile.ANSIString := '{8}[{14}B{8}]{7}ottom';
          WRITE(FCommandFile,CommandFile);
          CommandFile.KeyPress := 'Q';
          CommandFile.ANSIString := '{8}[{14}Q{8}]{7}uit';
          WRITE(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
     END;
END;


PROCEDURE CheckFile3(FileName: String);
VAR  Work       : Word;
     Work2      : Word;
BEGIN
     IF FileName='HIDDEN.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\HIDDEN.DAT')) THEN
          BEGIN
               FillChar(HiddenDial,SizeOf(HiddenDial),0);
               ASSIGN(FHiddenDial,BaseDirectory+'\DATA\HIDDEN.DAT');
               REWRITE(FHiddenDial);
               WRITE(FHiddenDial,HiddenDial);
               CLOSE(FHiddenDial);
          END;
     END
     ELSE IF FileName='SGSCHEME.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\SGSCHEME.DAT')) THEN
          BEGIN
               ASSIGN(FShotgunColours,BaseDirectory+'\DATA\SGSCHEME.DAT');
               REWRITE(FShotgunColours);
               FillChar(ShotgunColours,SizeOf(ShotgunColours),0);

               ShotgunColours.SGMailNormalText        := 7;
               ShotgunColours.SGMailErrorText         := 12;
               ShotgunColours.SGMailToggles           := 14;
               ShotgunColours.SGMailToggleBrackets    := 8;
               ShotgunColours.SGMailFrame             := 1;
               ShotgunColours.SGMailFrameLabels       := 9;
               ShotgunColours.SGMailInfo              := 7;
               ShotgunColours.SGMailInfoHighlight     := 15;
               ShotgunColours.SGMailTimeDateLabels    := 2;
               ShotgunColours.SGMailTimeDateData      := 10;
               ShotgunColours.SGMailStatusText        := 27;
               ShotgunColours.SGMailStatusHighlight   := 31;
               ShotgunColours.SGMailWindowText        := 27;
               ShotgunColours.SGMailWindowHighlight   := 31;
               ShotgunColours.SGMailWindowFrameHigh   := 25;
               ShotgunColours.SGMailWindowFrameLow    := 16;
               ShotgunColours.SGMailWindowFrameStyle  := 1;
               ShotgunColours.SGMailWindowShadow      := 8;
               ShotgunColours.SGMailWindowTitle       := 31;
               ShotgunColours.SGMailMenuSelected      := 48;
               ShotgunColours.SGMailDataEntry         := 31;
               ShotgunColours.SGMailDataEntryBack     := 1;
               ShotgunColours.SGMailProgressBar       := 9;
               ShotgunColours.SGMailProgressBarBack   := 1;
               ShotgunColours.SGMailProgressChar      := 'Û';
               ShotgunColours.SGMailNewMailLight      := 10;

               ShotgunColours.SGEditMsgText           := 7;
               ShotgunColours.SGEditMsgQuote          := 2;
               ShotgunColours.SGEditMsgKludge         := 8;
               ShotgunColours.SGEditFrame             := 1;
               ShotgunColours.SGEditStatusText        := 27;
               ShotgunColours.SGEditStatusHighlight   := 31;
               ShotgunColours.SGEditStatusBrackets    := 23;
               ShotgunColours.SGEditInfo              := 3;
               ShotgunColours.SGEditInfoData          := 11;
               ShotgunColours.SGEditInfoHighlight     := 14;
               ShotgunColours.SGEditWindowText        := 27;
               ShotgunColours.SGEditWindowHighlight   := 31;
               ShotgunColours.SGEditWindowFrameHigh   := 25;
               ShotgunColours.SGEditWindowFrameLow    := 16;
               ShotgunColours.SGEditWindowFrameStyle  := 1;
               ShotgunColours.SGEditWindowShadow      := 8;
               ShotgunColours.SGEditWindowTitle       := 31;
               ShotgunColours.SGEditDataEntry         := 31;
               ShotgunColours.SGEditDataEntryBack     := 1;
               ShotgunColours.SGEditMenuSelected      := 48;
               ShotgunColours.SGEditProgressBar       := 9;
               ShotgunColours.SGEditProgressBarBack   := 1;
               ShotgunColours.SGEditProgressChar      := 'Û';

               WRITE(FShotgunColours,ShotgunColours);
               CLOSE(FShotgunColours);
          END;
     END
     ELSE IF FileName='MAILER.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\MAILER.DAT')) THEN
          BEGIN
               FillChar(MailerInfo,SizeOf(MailerInfo),0);
               MailerInfo.HandleFaxes   := False;
               MailerInfo.Semaphores    := NoDrive(BaseDirectory)+'\SEMA\';
               MailerInfo.NetMail       := NoDrive(BaseDirectory)+'\SGMAIL\NETMAIL\';
               MailerInfo.InBound       := NoDrive(BaseDirectory)+'\SGMAIL\INBOUND\';
               MailerInfo.OutBound      := NoDrive(BaseDirectory)+'\SGMAIL\OUTBOUND\';
               MailerInfo.OutPkts       := NoDrive(BaseDirectory)+'\SGMAIL\OUTPKTS\';
               MailerInfo.NodeList      := NoDrive(BaseDirectory)+'\SGMAIL\NODELIST\';
               MailerInfo.NodeName      := 'The unknown BBS';
               MailerInfo.Banner        := NoDrive(BaseDirectory)+'\SGMAIL\HELLO.TXT';
               MailerInfo.InEvent       := NoDrive(BaseDirectory)+'\SGMAIL\MAIL.TXT';
               MailerInfo.AliasList     := NoDrive(BaseDirectory)+'\SGMAIL\ALIAS.LST';
               MailerInfo.DirList       := NoDrive(BaseDirectory)+'\SGMAIL\DIR.LST';
               MailerInfo.NoMatch       := NoDrive(BaseDirectory)+'\SGMAIL\BADREQ.TXT';
               MailerInfo.Phone         := '-unlisted-';
               MailerInfo.Flags         := 'CM,XA';
               MailerInfo.BaudRate      := 9600;
               MailerInfo.AllowFreqs    := True;
               MailerInfo.FreqBaud      := 2400;
               MailerInfo.FreqStart     := 1;
               MailerInfo.FreqEnd       := 1440*60;
               MailerInfo.MailOnly      := False;
               MailerInfo.DelayFirst    := True;
               MailerInfo.MatchZones    := True;
               MailerInfo.PresentAkas   := True;
               MailerInfo.MailExit      := 200;
               MailerInfo.EnableEMSI    := True;
               MailerInfo.EnableYooHoo  := True;
               MailerInfo.RetryDelay    := 30;
               MailerInfo.AnswerOnRing  := 1;
               MailerInfo.BBSSoftware   := 'Shotgun '+ShotgunVersion;
               MailerInfo.SecondsToBBS  := 15;
               _CreatePath(NoDrive(BaseDirectory)+'\SGMAIL');
               _CreatePath(NoDrive(BaseDirectory)+'\SGMAIL\NODELIST');
               _CreatePath(NoDrive(BaseDirectory)+'\SGMAIL\INBOUND');
               _CreatePath(NoDrive(BaseDirectory)+'\SGMAIL\OUTBOUND');
               _CreatePath(NoDrive(BaseDirectory)+'\SGMAIL\OUTPKTS');
               _CreatePath(NoDrive(BaseDirectory)+'\SGMAIL\NETMAIL');
               _CreatePath(NoDrive(BaseDirectory)+'\SEMA');
               ASSIGN(FMailerInfo,BaseDirectory+'\DATA\MAILER.DAT');
               REWRITE(FMailerInfo);
               FOR Work := 1 TO 255 DO WRITE(FMailerInfo,MailerInfo);
               CLOSE(FMailerInfo);
          END
          ELSE
          BEGIN
               ASSIGN(FMailerInfo,BaseDirectory+'\DATA\MAILER.DAT');
               RESET(FMailerInfo);
               Work2 := FileSize(FMailerInfo);
               CLOSE(FMailerInfo);
               IF Work2<255 THEN
               BEGIN
                    FillChar(MailerInfo,SizeOf(MailerInfo),0);
                    MailerInfo.HandleFaxes   := False;
                    MailerInfo.Semaphores    := NoDrive(BaseDirectory)+'\SEMA\';
                    MailerInfo.NetMail       := NoDrive(BaseDirectory)+'\SGMAIL\NETMAIL\';
                    MailerInfo.InBound       := NoDrive(BaseDirectory)+'\SGMAIL\INBOUND\';
                    MailerInfo.OutBound      := NoDrive(BaseDirectory)+'\SGMAIL\OUTBOUND\';
                    MailerInfo.OutPkts       := NoDrive(BaseDirectory)+'\SGMAIL\OUTPKTS\';
                    MailerInfo.NodeList      := NoDrive(BaseDirectory)+'\SGMAIL\NODELIST\';
                    MailerInfo.NodeName      := 'The unknown BBS';
                    MailerInfo.Banner        := NoDrive(BaseDirectory)+'\SGMAIL\HELLO.TXT';
                    MailerInfo.InEvent       := NoDrive(BaseDirectory)+'\SGMAIL\MAIL.TXT';
                    MailerInfo.AliasList     := NoDrive(BaseDirectory)+'\SGMAIL\ALIAS.LST';
                    MailerInfo.DirList       := NoDrive(BaseDirectory)+'\SGMAIL\DIR.LST';
                    MailerInfo.NoMatch       := NoDrive(BaseDirectory)+'\SGMAIL\BADREQ.TXT';
                    MailerInfo.Phone         := '-unlisted-';
                    MailerInfo.Flags         := 'CM,XA';
                    MailerInfo.BaudRate      := 9600;
                    MailerInfo.AllowFreqs    := True;
                    MailerInfo.FreqBaud      := 2400;
                    MailerInfo.FreqStart     := 1;
                    MailerInfo.FreqEnd       := 1440*60;
                    MailerInfo.MailOnly      := False;
                    MailerInfo.DelayFirst    := True;
                    MailerInfo.MatchZones    := True;
                    MailerInfo.PresentAkas   := True;
                    MailerInfo.MailExit      := 200;
                    MailerInfo.EnableEMSI    := True;
                    MailerInfo.EnableYooHoo  := True;
                    MailerInfo.RetryDelay    := 30;
                    MailerInfo.AnswerOnRing  := 1;
                    MailerInfo.BBSSoftware   := 'Shotgun '+ShotgunVersion;
                    MailerInfo.SecondsToBBS  := 15;
                    _CreatePath(NoDrive(BaseDirectory)+'\SGMAIL');
                    _CreatePath(NoDrive(BaseDirectory)+'\SGMAIL\NODELIST');
                    _CreatePath(NoDrive(BaseDirectory)+'\SGMAIL\INBOUND');
                    _CreatePath(NoDrive(BaseDirectory)+'\SGMAIL\OUTBOUND');
                    _CreatePath(NoDrive(BaseDirectory)+'\SGMAIL\OUTPKTS');
                    _CreatePath(NoDrive(BaseDirectory)+'\SGMAIL\NETMAIL');
                    _CreatePath(NoDrive(BaseDirectory)+'\SEMA');
                    ASSIGN(FMailerInfo,BaseDirectory+'\DATA\MAILER.DAT');
                    RESET(FMailerInfo);
                    SEEK(FMailerInfo,FileSize(FMailerInfo));
                    FOR Work := (Work2+1) TO 255 DO WRITE(FMailerInfo,MailerInfo);
                    CLOSE(FMailerInfo);
               END;
          END;
     END
     ELSE IF FileName='MAILER2.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\MAILER2.DAT')) THEN
          BEGIN
               FillChar(Mailer2Info,SizeOf(Mailer2Info),0);
               Mailer2Info.BlankerTimeout          := 20;
               Mailer2Info.UseBlanker              := True;
               Mailer2Info.UseVideoLines           := 0;
               Mailer2Info.UseSound                := True;
               Mailer2Info.UseZedZapTransfers      := True;
               Mailer2Info.InSecureInbound         := NoDrive(BaseDirectory)+'\SGMAIL\NOSEC\';
               Mailer2Info.UnpackInSecurePkts      := True;
               Mailer2Info.CallsBeforeFail         := 20;
               Mailer2Info.SoundStart              := 0;
               Mailer2Info.SoundEnd                := 86340;
               Mailer2Info.UseSpeakerToggle        := False;
               Mailer2Info.SpeakerStart            := 0;
               Mailer2Info.SpeakerEnd              := 86340;
               Mailer2Info.UnpackPackets           := True;
               Mailer2Info.AllowNodeToDial         := True;
               Mailer2Info.MailFromUnlistedSystems := True;
               Mailer2Info.UseHyrdaTransfers       := True;
               _CreatePath(NoDrive(BaseDirectory)+'\SGMAIL\NOSEC');
               ASSIGN(FMailer2Info,BaseDirectory+'\DATA\MAILER2.DAT');
               REWRITE(FMailer2Info);
               FOR Work := 1 TO 255 DO WRITE(FMailer2Info,Mailer2Info);
               CLOSE(FMailer2Info);
          END
          ELSE
          BEGIN
               ASSIGN(FMailer2Info,BaseDirectory+'\DATA\MAILER2.DAT');
               RESET(FMailer2Info);
               Work2 := FileSize(FMailer2Info);
               CLOSE(FMailer2Info);
               IF Work2<255 THEN
               BEGIN
                    FillChar(Mailer2Info,SizeOf(Mailer2Info),0);
                    Mailer2Info.BlankerTimeout          := 20;
                    Mailer2Info.UseBlanker              := True;
                    Mailer2Info.UseVideoLines           := 0;
                    Mailer2Info.UseSound                := True;
                    Mailer2Info.UseZedZapTransfers      := True;
                    Mailer2Info.InSecureInbound         := NoDrive(BaseDirectory)+'\SGMAIL\NOSEC\';
                    Mailer2Info.CallsBeforeFail         := 20;
                    Mailer2Info.SoundStart              := 0;
                    Mailer2Info.SoundEnd                := 86340;
                    Mailer2Info.UseSpeakerToggle        := False;
                    Mailer2Info.SpeakerStart            := 0;
                    Mailer2Info.SpeakerEnd              := 86340;
                    Mailer2Info.UnpackPackets           := True;
                    Mailer2Info.AllowNodeToDial         := True;
                    Mailer2Info.UnpackInSecurePkts      := True;
                    Mailer2Info.MailFromUnlistedSystems := True;
                    Mailer2Info.UseHyrdaTransfers       := True;
                    _CreatePath(NoDrive(BaseDirectory)+'\SGMAIL\NOSEC');
                    ASSIGN(FMailer2Info,BaseDirectory+'\DATA\MAILER2.DAT');
                    RESET(FMailer2Info);
                    SEEK(FMailer2Info,FileSize(FMailer2Info));
                    FOR Work := (Work2+1) TO 255 DO WRITE(FMailer2Info,Mailer2Info);
                    CLOSE(FMailer2Info);
               END;
          END;
     END
     ELSE IF FileName='EXTERNAL.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\EXTERNAL.DAT')) THEN
          BEGIN
               FillChar(ExternalApps,SizeOf(ExternalApps),0);
               ExternalApps.FaxReceiver  := '\BGFAX\BGFAX.EXE /fco:4 \BGFAX %1 z';
               ExternalApps.SpellChecker := '\GDSPELL\SPELL.EXE %1 /nb';
               ExternalApps.THDProScan   := '\THDPRO\THDPRO.EXE %1 %2';
               ASSIGN(FExternalApps,BaseDirectory+'\DATA\EXTERNAL.DAT');
               REWRITE(FExternalApps);
               WRITE(FExternalApps,ExternalApps);
               CLOSE(FExternalApps);
          END;
     END
     ELSE IF FileName='NODES.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\NODES.DAT')) THEN
          BEGIN
               FillChar(NodeInfo,SizeOf(NodeInfo),0);
               NodeInfo.ANSIOk            := 1;
               NodeInfo.TTYOk             := 1;
               NodeInfo.SVGAOk            := 1;
               NodeInfo.RIPOk             := 1;
               NodeInfo.ComDevice         := 1;
               NodeInfo.ComPort           := 1;
               NodeInfo.BaudRate          := 8;
               NodeInfo.FlowControl       := 1;
               NodeInfo.CommandDelay      := 500;
               NodeInfo.InitString[1]     := 'ATZ';
               NodeInfo.InitString[2]     := 'AT&C1&D2X4E1M0H0';
               NodeInfo.OnHook            := 'ATH0';
               NodeInfo.OffHook           := 'ATH1';
               NodeInfo.Dial              := 'ATDT';
               NodeInfo.Answer            := 'ATA';
               NodeInfo.AllowNewUsers     := 1;
               NodeInfo.Fifos             := 4;
               NodeInfo.ptBufferGetChar   := False;
               NodeInfo.ptHandleFossilBug := True;
               NodeInfo.ptTrueOutBuffFree := False;
               NodeInfo.ptPutCharWait     := True;
               NodeInfo.ptReadWriteWait   := False;
               NodeInfo.ptClearFlow       := True;
               ASSIGN(FNodeInfo,BaseDirectory+'\DATA\NODES.DAT');
               REWRITE(FNodeInfo);
               FOR Work := 1 TO 255 DO WRITE(FNodeInfo,NodeInfo);
               CLOSE(FNodeInfo);
          END
          ELSE
          BEGIN
               ASSIGN(FNodeInfo,BaseDirectory+'\DATA\NODES.DAT');
               RESET(FNodeInfo);
               Work2 := FileSize(FNodeInfo);
               CLOSE(FNodeInfo);
               IF Work2<255 THEN
               BEGIN
                    FillChar(NodeInfo,SizeOf(NodeInfo),0);
                    NodeInfo.ANSIOk            := 1;
                    NodeInfo.TTYOk             := 1;
                    NodeInfo.SVGAOk            := 1;
                    NodeInfo.RIPOk             := 1;
                    NodeInfo.ComDevice         := 1;
                    NodeInfo.ComPort           := 1;
                    NodeInfo.BaudRate          := 8;
                    NodeInfo.FlowControl       := 1;
                    NodeInfo.CommandDelay      := 500;
                    NodeInfo.InitString[1]     := 'ATZ';
                    NodeInfo.InitString[2]     := 'AT&C1&D2X4E1M0H0';
                    NodeInfo.OnHook            := 'ATH0';
                    NodeInfo.OffHook           := 'ATH1';
                    NodeInfo.Dial              := 'ATDT';
                    NodeInfo.Answer            := 'ATA';
                    NodeInfo.AllowNewUsers     := 1;
                    NodeInfo.Fifos             := 4;
                    NodeInfo.ptBufferGetChar   := False;
                    NodeInfo.ptHandleFossilBug := True;
                    NodeInfo.ptTrueOutBuffFree := False;
                    NodeInfo.ptPutCharWait     := True;
                    NodeInfo.ptReadWriteWait   := False;
                    NodeInfo.ptClearFlow       := True;
                    ASSIGN(FNodeInfo,BaseDirectory+'\DATA\NODES.DAT');
                    RESET(FNodeInfo);
                    SEEK(FNodeInfo,FileSize(FNodeInfo));
                    FOR Work := (Work2+1) TO 255 DO WRITE(FNodeInfo,NodeInfo);
                    CLOSE(FNodeInfo);
               END;
          END;
     END;
END;


END.
