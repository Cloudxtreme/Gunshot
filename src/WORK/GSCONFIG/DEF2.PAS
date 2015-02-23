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
     ELSE IF FileName='GSSCHEME.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\GSSCHEME.DAT')) THEN
          BEGIN
               ASSIGN(FGunshotColours,BaseDirectory+'\DATA\GSSCHEME.DAT');
               REWRITE(FGunshotColours);
               FillChar(GunshotColours,SizeOf(GunshotColours),0);

               GunshotColours.GSMailNormalText        := 7;
               GunshotColours.GSMailErrorText         := 12;
               GunshotColours.GSMailToggles           := 14;
               GunshotColours.GSMailToggleBrackets    := 8;
               GunshotColours.GSMailFrame             := 1;
               GunshotColours.GSMailFrameLabels       := 9;
               GunshotColours.GSMailInfo              := 7;
               GunshotColours.GSMailInfoHighlight     := 15;
               GunshotColours.GSMailTimeDateLabels    := 2;
               GunshotColours.GSMailTimeDateData      := 10;
               GunshotColours.GSMailStatusText        := 27;
               GunshotColours.GSMailStatusHighlight   := 31;
               GunshotColours.GSMailWindowText        := 27;
               GunshotColours.GSMailWindowHighlight   := 31;
               GunshotColours.GSMailWindowFrameHigh   := 25;
               GunshotColours.GSMailWindowFrameLow    := 16;
               GunshotColours.GSMailWindowFrameStyle  := 1;
               GunshotColours.GSMailWindowShadow      := 8;
               GunshotColours.GSMailWindowTitle       := 31;
               GunshotColours.GSMailMenuSelected      := 48;
               GunshotColours.GSMailDataEntry         := 31;
               GunshotColours.GSMailDataEntryBack     := 1;
               GunshotColours.GSMailProgressBar       := 9;
               GunshotColours.GSMailProgressBarBack   := 1;
               GunshotColours.GSMailProgressChar      := 'Û';
               GunshotColours.GSMailNewMailLight      := 10;

               GunshotColours.GSEditMsgText           := 7;
               GunshotColours.GSEditMsgQuote          := 2;
               GunshotColours.GSEditMsgKludge         := 8;
               GunshotColours.GSEditFrame             := 1;
               GunshotColours.GSEditStatusText        := 27;
               GunshotColours.GSEditStatusHighlight   := 31;
               GunshotColours.GSEditStatusBrackets    := 23;
               GunshotColours.GSEditInfo              := 3;
               GunshotColours.GSEditInfoData          := 11;
               GunshotColours.GSEditInfoHighlight     := 14;
               GunshotColours.GSEditWindowText        := 27;
               GunshotColours.GSEditWindowHighlight   := 31;
               GunshotColours.GSEditWindowFrameHigh   := 25;
               GunshotColours.GSEditWindowFrameLow    := 16;
               GunshotColours.GSEditWindowFrameStyle  := 1;
               GunshotColours.GSEditWindowShadow      := 8;
               GunshotColours.GSEditWindowTitle       := 31;
               GunshotColours.GSEditDataEntry         := 31;
               GunshotColours.GSEditDataEntryBack     := 1;
               GunshotColours.GSEditMenuSelected      := 48;
               GunshotColours.GSEditProgressBar       := 9;
               GunshotColours.GSEditProgressBarBack   := 1;
               GunshotColours.GSEditProgressChar      := 'Û';

               WRITE(FGunshotColours,GunshotColours);
               CLOSE(FGunshotColours);
          END;
     END
     ELSE IF FileName='MAILER.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\MAILER.DAT')) THEN
          BEGIN
               FillChar(MailerInfo,SizeOf(MailerInfo),0);
               MailerInfo.HandleFaxes   := False;
               MailerInfo.Semaphores    := NoDrive(BaseDirectory)+'\SEMA\';
               MailerInfo.NetMail       := NoDrive(BaseDirectory)+'\GSMAIL\NETMAIL\';
               MailerInfo.InBound       := NoDrive(BaseDirectory)+'\GSMAIL\INBOUND\';
               MailerInfo.OutBound      := NoDrive(BaseDirectory)+'\GSMAIL\OUTBOUND\';
               MailerInfo.OutPkts       := NoDrive(BaseDirectory)+'\GSMAIL\OUTPKTS\';
               MailerInfo.NodeList      := NoDrive(BaseDirectory)+'\GSMAIL\NODELIST\';
               MailerInfo.NodeName      := 'The unknown BBS';
               MailerInfo.Banner        := NoDrive(BaseDirectory)+'\GSMAIL\HELLO.TXT';
               MailerInfo.InEvent       := NoDrive(BaseDirectory)+'\GSMAIL\MAIL.TXT';
               MailerInfo.AliasList     := NoDrive(BaseDirectory)+'\GSMAIL\ALIAS.LST';
               MailerInfo.DirList       := NoDrive(BaseDirectory)+'\GSMAIL\DIR.LST';
               MailerInfo.NoMatch       := NoDrive(BaseDirectory)+'\GSMAIL\BADREQ.TXT';
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
               MailerInfo.BBSSoftware   := 'Gunshot '+GunshotVersion;
               MailerInfo.SecondsToBBS  := 15;
               _CreatePath(NoDrive(BaseDirectory)+'\GSMAIL');
               _CreatePath(NoDrive(BaseDirectory)+'\GSMAIL\NODELIST');
               _CreatePath(NoDrive(BaseDirectory)+'\GSMAIL\INBOUND');
               _CreatePath(NoDrive(BaseDirectory)+'\GSMAIL\OUTBOUND');
               _CreatePath(NoDrive(BaseDirectory)+'\GSMAIL\OUTPKTS');
               _CreatePath(NoDrive(BaseDirectory)+'\GSMAIL\NETMAIL');
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
                    MailerInfo.NetMail       := NoDrive(BaseDirectory)+'\GSMAIL\NETMAIL\';
                    MailerInfo.InBound       := NoDrive(BaseDirectory)+'\GSMAIL\INBOUND\';
                    MailerInfo.OutBound      := NoDrive(BaseDirectory)+'\GSMAIL\OUTBOUND\';
                    MailerInfo.OutPkts       := NoDrive(BaseDirectory)+'\GSMAIL\OUTPKTS\';
                    MailerInfo.NodeList      := NoDrive(BaseDirectory)+'\GSMAIL\NODELIST\';
                    MailerInfo.NodeName      := 'The unknown BBS';
                    MailerInfo.Banner        := NoDrive(BaseDirectory)+'\GSMAIL\HELLO.TXT';
                    MailerInfo.InEvent       := NoDrive(BaseDirectory)+'\GSMAIL\MAIL.TXT';
                    MailerInfo.AliasList     := NoDrive(BaseDirectory)+'\GSMAIL\ALIAS.LST';
                    MailerInfo.DirList       := NoDrive(BaseDirectory)+'\GSMAIL\DIR.LST';
                    MailerInfo.NoMatch       := NoDrive(BaseDirectory)+'\GSMAIL\BADREQ.TXT';
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
                    MailerInfo.BBSSoftware   := 'Gunshot '+GunshotVersion;
                    MailerInfo.SecondsToBBS  := 15;
                    _CreatePath(NoDrive(BaseDirectory)+'\GSMAIL');
                    _CreatePath(NoDrive(BaseDirectory)+'\GSMAIL\NODELIST');
                    _CreatePath(NoDrive(BaseDirectory)+'\GSMAIL\INBOUND');
                    _CreatePath(NoDrive(BaseDirectory)+'\GSMAIL\OUTBOUND');
                    _CreatePath(NoDrive(BaseDirectory)+'\GSMAIL\OUTPKTS');
                    _CreatePath(NoDrive(BaseDirectory)+'\GSMAIL\NETMAIL');
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
               Mailer2Info.InSecureInbound         := NoDrive(BaseDirectory)+'\GSMAIL\NOSEC\';
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
               _CreatePath(NoDrive(BaseDirectory)+'\GSMAIL\NOSEC');
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
                    Mailer2Info.InSecureInbound         := NoDrive(BaseDirectory)+'\GSMAIL\NOSEC\';
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
                    _CreatePath(NoDrive(BaseDirectory)+'\GSMAIL\NOSEC');
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
