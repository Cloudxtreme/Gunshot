{$I DEFINES.INC}
UNIT Defaults;


INTERFACE


PROCEDURE CheckFile(FileName: String);
PROCEDURE CheckAllFiles;


IMPLEMENTATION


USES CnfgVars,IntrFace,Version,Def2,BsFile,BsString;


PROCEDURE CheckFile2(FileName: String);
BEGIN
     IF FileName='FREQ.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\FREQ.DAT')) THEN
          BEGIN
               FillChar(Freqs,SizeOf(Freqs),0);
               Freqs.AllowFreqs         := True;
               Freqs.DaysToKeepRequests := 30;
               Freqs.SysopMessageAreaID := 1;
               Freqs.SysopMessageTo     := 'Sysop';
               ASSIGN(FFreqs,BaseDirectory+'\DATA\FREQ.DAT');
               REWRITE(FFreqs);
               WRITE(FFreqs,Freqs);
               CLOSE(FFreqs);
          END;
     END
     ELSE IF FileName='FKEYS.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\FKEYS.DAT')) THEN
          BEGIN
               FillChar(FunctionKeys,SizeOf(FunctionKeys),0);
               FunctionKeys.GSMail_F1 := '%MENU';
               FunctionKeys.GSMail_F2 := '%SHELL';
               ASSIGN(FFunctionKeys,BaseDirectory+'\DATA\FKEYS.DAT');
               REWRITE(FFunctionKeys);
               WRITE(FFunctionKeys,FunctionKeys);
               CLOSE(FFunctionKeys);
          END;
     END
     ELSE IF FileName='SHUTTLE.DAT' THEN
     BEGIN
          IF NOT(_FileExists(SelectedLanguage+'\LANG\SHUTTLE.DAT')) THEN
          BEGIN
               ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
               REWRITE(FShuttle);
               Shuttle.KeyPress := '1';
               Shuttle.Action   := 1;
               WRITE(FShuttle,Shuttle);
               Shuttle.KeyPress := '2';
               Shuttle.Action   := 2;
               WRITE(FShuttle,Shuttle);
               Shuttle.KeyPress := 'R';
               Shuttle.Action   := 3;
               WRITE(FShuttle,Shuttle);
               Shuttle.KeyPress := 'V';
               Shuttle.Action   := 4;
               WRITE(FShuttle,Shuttle);
               Shuttle.KeyPress := 'D';
               Shuttle.Action   := 5;
               Shuttle.Text     := '\SHOTGUN\SGT_120.EXE';
               WRITE(FShuttle,Shuttle);
               CLOSE(FShuttle);
          END;
     END
     ELSE IF FileName='OPENING.DAT' THEN
     BEGIN
          IF NOT(_FileExists(SelectedLanguage+'\LANG\OPENING.DAT')) THEN
          BEGIN
               FillChar(Opening,SizeOf(Opening),0);
               ASSIGN(FOpening,SelectedLanguage+'\LANG\OPENING.DAT');
               REWRITE(FOpening);
               {Welcome}
               Opening.FunctionType := 2;
               Opening.Forced       := 1;
               WRITE(FOpening,Opening);
               {Callback Verifier}
               Opening.FunctionType := 8;
               Opening.Forced       := 1;
               WRITE(FOpening,Opening);
               {User Birthday Screen}
               Opening.FunctionType := 12;
               Opening.Forced       := 1;
               WRITE(FOpening,Opening);
               {User Specific Screen}
               Opening.FunctionType := 9;
               Opening.Forced       := 1;
               WRITE(FOpening,Opening);
               {User Access Screen}
               Opening.FunctionType := 10;
               Opening.Forced       := 1;
               WRITE(FOpening,Opening);
               {Once Only Screens}
               Opening.FunctionType := 3;
               Opening.Forced       := 1;
               WRITE(FOpening,Opening);
               {Date Specific Screens}
               Opening.FunctionType := 11;
               Opening.Forced       := 1;
               WRITE(FOpening,Opening);
               {News Screens}
               Opening.FunctionType := 4;
               Opening.Forced       := 1;
               WRITE(FOpening,Opening);
               {Last Callers Screen}
               Opening.FunctionType := 5;
               Opening.Forced       := 1;
               WRITE(FOpening,Opening);
               {Ask New Mail Scan}
               Opening.FunctionType := 6;
               Opening.Forced       := 0;
               WRITE(FOpening,Opening);
               {Ask New File Scan}
               Opening.FunctionType := 7;
               Opening.Forced       := 0;
               WRITE(FOpening,Opening);
               {Comment From Last Caller}
               Opening.FunctionType := 1;
               Opening.Forced       := 1;
               WRITE(FOpening,Opening);
               CLOSE(FOpening);
          END;
     END
     ELSE IF FileName='NEWUSER.VGA' THEN
     BEGIN
          IF NOT(_FileExists(SelectedLanguage+'\LANG\NEWUSER.VGA')) THEN
          BEGIN
               ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
               REWRITE(FNewUserVga);
               NewUserVga.FileName := 'NEWUSER1'; WRITE(FNewUserVga,NewUserVga);
               NewUserVga.FileName := 'NEWUSER2'; WRITE(FNewUserVga,NewUserVga);
               NewUserVga.FileName := 'NEWUSER3'; WRITE(FNewUserVga,NewUserVga);
               CLOSE(FNewUserVga);
          END;
     END
     ELSE IF FileName='NEWUSER.ANS' THEN
     BEGIN
          IF NOT(_FileExists(SelectedLanguage+'\LANG\NEWUSER.ANS')) THEN
          BEGIN
               FillChar(NewUserANSI,SizeOf(NewUserANSI),0);
               ASSIGN(FNewUserANSI,SelectedLanguage+'\LANG\NEWUSER.ANS');
               REWRITE(FNewUserANSI);
               {Enter the user's password}
               NewUserANSI.FunctionType := 1;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := 'NEWUSER1';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 2;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 3;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               {Enter the user's tele information}
               NewUserANSI.FunctionType := 1;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := 'NEWUSER2';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 4;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 5;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               {Get User's Address}
               NewUserANSI.FunctionType := 1;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := 'NEWUSER3';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 6;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 7;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 8;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 9;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 10;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               {Get Misc info}
               NewUserANSI.FunctionType := 1;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := 'NEWUSER4';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 11;
               NewUserANSI.Required     := 0;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 12;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 13;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 14;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               {Sysop Information}
               NewUserANSI.FunctionType := 1;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := 'NEWUSER5';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 15;
               NewUserANSI.Required     := 0;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 16;
               NewUserANSI.Required     := 0;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 17;
               NewUserANSI.Required     := 0;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               {All Done}
               NewUserANSI.FunctionType := 1;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := 'NEWUSER6';
               WRITE(FNewUserANSI,NewUserANSI);
               NewUserANSI.FunctionType := 18;
               NewUserANSI.Required     := 1;
               NewUserANSI.FileName     := '';
               WRITE(FNewUserANSI,NewUserANSI);
               CLOSE(FNewUserANSI);
          END;
     END
     ELSE IF FileName='CALLERID.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\CALLERID.DAT')) THEN
          BEGIN
               CallerId.UseCID              := False;
               CallerId.AccessLevelForcing  := False;
               CallerId.AccessLevelNoNumber := 10;
               CallerId.CBVOverRide         := False;
               ASSIGN(FCallerId,BaseDirectory+'\DATA\CALLERID.DAT');
               REWRITE(FCallerId);
               WRITE(FCallerId,CallerId);
               CLOSE(FCallerId);
          END;
     END
     ELSE CheckFile3(FileName);
END;


PROCEDURE CheckFile(FileName: String);
VAR  Work       : Word;
     Work2      : Word;
BEGIN
     _CreatePath(BaseDirectory+'\DATA');
     IF FileName='ACCESS.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\ACCESS.DAT')) THEN
          BEGIN
               FillChar(UserAccess,SizeOf(UserAccess),0);
               UserAccess.time         := 3600;
               UserAccess.first_menu   := '#MAIN.MNU';
               UserAccess.ul_credit    := 50;
               UserAccess.page         := 1;
               UserAccess.verified     := 1;
               UserAccess.QWKBytes     := 512000;
               UserAccess.QWKMessages  := 600;
               UserAccess.QWKFree      := 1;
               UserAccess.NoFileRatio  := 1;
               ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
               REWRITE(FUserAccess);
               WRITE(FUserAccess,UserAccess);
               CLOSE(FUserAccess);
          END;
     END
     ELSE IF FileName='ARCHIVE.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\ARCHIVE.DAT')) THEN
          BEGIN
               FillChar(ArcDefs,SizeOf(ArcDefs),0);
               ArcDefs.DefaultArc  := 'LZH';
               ArcDefs.ArcPath     := '\UTILS\';
               ArcDefs.ConvertArcs := 0;
               ASSIGN(FArcDefs,BaseDirectory+'\DATA\ARCHIVE.DAT');
               REWRITE(FArcDefs);
               WRITE(FArcDefs,ArcDefs);
               CLOSE(FArcDefs);
          END;
     END
     ELSE IF FileName='ARCUTILS.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\ARCUTILS.DAT')) THEN
          BEGIN
               ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
               REWRITE(FArcUtils);
               ArcUtils.Extension        := 'ARJ';
               ArcUtils.CopyArc          := 'ARJ.EXE a -r -y';
               ArcUtils.MoveArc          := 'ARJ.EXE m -r -y';
               ArcUtils.ExtractArc       := 'ARJ.EXE x -r -y';
               ArcUtils.ViewArc          := 'ARJ.EXE l';
               ArcUtils.ExtractArcNoPath := 'ARJ.EXE e -r -y';
               WRITE(FArcUtils,ArcUtils);
               ArcUtils.Extension        := 'ZIP';
               ArcUtils.CopyArc          := 'PKZIP.EXE -a -r -)';
               ArcUtils.MoveArc          := 'PKZIP.EXE -m -r -)';
               ArcUtils.ExtractArc       := 'PKUNZIP.EXE -d -o -)';
               ArcUtils.ViewArc          := 'PKUNZIP.EXE -v -)';
               ArcUtils.ExtractArcNoPath := 'PKUNZIP.EXE -o -)';
               WRITE(FArcUtils,ArcUtils);
               ArcUtils.Extension        := 'LZH';
               ArcUtils.CopyArc          := 'LHA.EXE a -m -n1 -n2';
               ArcUtils.MoveArc          := 'LHA.EXE m -m -n1 -n2';
               ArcUtils.ExtractArc       := 'LHA.EXE x -m -n1 -n2';
               ArcUtils.ViewArc          := 'LHA.EXE l';
               ArcUtils.ExtractArcNoPath := 'LHA.EXE e -m -n1 -n2';
               WRITE(FArcUtils,ArcUtils);
               ArcUtils.Extension        := 'ARC';
               ArcUtils.CopyArc          := 'PKARC.COM a';
               ArcUtils.MoveArc          := 'PKARC.COM m';
               ArcUtils.ExtractArc       := 'PKXARC.COM -e';
               ArcUtils.ViewArc          := 'PKXARC.COM -v';
               ArcUtils.ExtractArcNoPath := 'PKXARC.COM -e';
               WRITE(FArcUtils,ArcUtils);
               ArcUtils.Extension        := 'ZOO';
               ArcUtils.CopyArc          := 'ZOO.EXE -add';
               ArcUtils.MoveArc          := 'ZOO.EXE -move';
               ArcUtils.ExtractArc       := 'ZOO.EXE -extract';
               ArcUtils.ViewArc          := 'ZOO.EXE -list';
               ArcUtils.ExtractArcNoPath := 'ZOO.EXE -extract';
               WRITE(FArcUtils,ArcUtils);
               ArcUtils.Extension        := 'RAR';
               ArcUtils.CopyArc          := 'RAR.EXE a -r -y -av -m5 -c-';
               ArcUtils.MoveArc          := 'RAR.EXE m -r -y -av -m5';
               ArcUtils.ExtractArc       := 'RAR.EXE x -r -y -o+ -c- -av-';
               ArcUtils.ViewArc          := 'RAR.EXE l -c- -av-';
               ArcUtils.ExtractArcNoPath := 'RAR.EXE e -r -y -o+ -c- -av-';
               WRITE(FArcUtils,ArcUtils);
               CLOSE(FArcUtils);
          END;
     END
     ELSE IF FileName='SCANNERS.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\SCANNERS.DAT')) THEN
          BEGIN
               FillChar(Scanners,SizeOf(Scanners),0);
               ASSIGN(FScanners,BaseDirectory+'\DATA\SCANNERS.DAT');
               REWRITE(FScanners);
               WRITE(FScanners,Scanners);
               CLOSE(FScanners);
          END;
     END
     ELSE IF FileName='BADLANG.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\BADLANG.DAT')) THEN
          BEGIN
               BadLang.Phrase := 'SHIT';
               ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
               REWRITE(FBadLang);
               WRITE(FBadLang,BadLang);
               CLOSE(FBadLang);
          END;
     END
     ELSE IF FileName='SYSCALLS.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\SYSCALLS.DAT')) THEN
          BEGIN
               FillChar(Totals,SizeOf(Totals),0);
               ASSIGN(FTotals,BaseDirectory+'\DATA\SYSCALLS.DAT');
               REWRITE(FTotals);
               WRITE(FTotals,Totals);
               CLOSE(FTotals);
          END;
     END
     ELSE IF FileName='USERS.BBS' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\USERS.BBS')) THEN
          BEGIN
               ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
               REWRITE(FUserRecord);
               FillChar(UserRecord,SizeOf(UserRecord),0);
               UserRecord.user_number       := 1;
               UserRecord.birth             := '000000';
               WRITE(FUserRecord,UserRecord);
               UserRecord.name              := 'NEW SYSOP';
               UserRecord.user_number       := 0;
               UserRecord.password          := 'PASSWORD';
               UserRecord.security          := 32000;
               UserRecord.birth             := '000000';
               UserRecord.sex               := 1;
               UserRecord.page              := 1;
               FOR Work := 1 TO 10 DO
               UserRecord.tags[Work]        := 1;
               UserRecord.seperator         := 0;
               UserRecord.file_lines        := 18;
               UserRecord.SecondsRemaining  := 1440*60;
               UserRecord.userlist          := 1;
               UserRecord.PageFlag          := 1;
               UserRecord.ibm               := 1;
               UserRecord.ver_user          := 1;
               WRITE(FUserRecord,UserRecord);
               CLOSE(FUserRecord);
          END;
     END
     ELSE IF FileName='VERIFY.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\VERIFY.DAT')) THEN
          BEGIN
               Verifier.name   := '9-1-1 Emergency';
               Verifier.number := '911';
               ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
               REWRITE(FVerifier);
               WRITE(FVerifier,Verifier);
               CLOSE(FVerifier);
          END;
     END
     ELSE IF FileName='SYSTEM.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\SYSTEM.DAT')) THEN
          BEGIN
               FillChar(System_Info,SizeOf(System_Info),0);
               System_Info.sysop             := 'NEW SYSOP';
               System_Info.alias             := '';
               System_Info.bbs_name          := 'NEW SHOTGUN SYSTEM';
               System_Info.location          := 'SOMEWHERE';
               System_Info.sys_idle          := 5*60;
               System_Info.page_start        := 10*3600;
               System_Info.page_end          := 20*3600;
               System_Info.page_max          := 3;
               System_Info.dateformat        := 0;
               System_Info.show_empty        := 1;
               System_Info.access_new_user   := 5;
               System_Info.tbank_max         := 120*60;
               System_Info.bbank_max         := 512000;
               System_Info.tbank_trans       := 30*60;
               System_Info.bbank_trans       := 256000;
               System_Info.alias_system      := False;
               System_Info.CD_ROMS           := 0;
               System_Info.use_cd_temp       := 0;
               System_Info.FileListName      := 'FILELIST';
               System_Info.Suspend_FList     := 1;
               System_Info.MessageCarbonCopy := 32000;
               System_Info.MessageCopy       := 32000;
               System_Info.MessageMove       := 32000;
               System_Info.MessageForward    := 32000;
               System_Info.MessageKill       := 32000;
               System_Info.FileMove          := 32000;
               System_Info.FileCopy          := 32000;
               System_Info.FileKill          := 32000;
               System_Info.PrivateRead       := 32000;
               System_Info.MessageInfo       := 32000;
               System_Info.EchoExit          := 200;
               System_Info.LocalExit         := 199;
               System_Info.ANSIExit          := 0;
               System_Info.BadQWK            := NoDrive(BaseDirectory)+'\BADQWK\';
               System_Info.FileAttach        := NoDrive(BaseDirectory)+'\ATTACH\';
               System_Info.CheckDupes        := 1;
               System_Info.CheckDupesCD      := 0;
               System_Info.QWKPacketName     := 'SHOTGUN';
               System_Info.QWKBBSId          := 'Unknown system';
               System_Info.QWKBBSPhone       := '-unpublished-';
               System_Info.QWKWelcome        := 'WELCOME';
               System_Info.QWKNews           := 'NEWS';
               System_Info.QWKGoodBye        := 'GOODBYE';
               System_Info.BadFiles          := NoDrive(BaseDirectory)+'\BADFILES\';
               System_Info.NodeDrive         := '';
               System_Info.SwapMethod        := 2;
               ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
               REWRITE(FSystem_Info);
               WRITE(FSystem_Info,System_Info);
               CLOSE(FSystem_Info);
          END;
     END
     ELSE IF FileName='LANGUAGE.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\LANGUAGE.DAT')) THEN
          BEGIN
               LangDir.Name      := 'English';
               LangDir.Directory := NoDrive(BaseDirectory)+'\ENGLISH\';
               ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
               REWRITE(FLangDir);
               WRITE(FLangDir,LangDir);
               CLOSE(FLangDir);
               _CreatePath(BaseDirectory+'\ENGLISH');
               _CreatePath(BaseDirectory+'\ENGLISH\ANSI');
               _CreatePath(BaseDirectory+'\ENGLISH\MENUS');
               _CreatePath(BaseDirectory+'\ENGLISH\NEWS');
               _CreatePath(BaseDirectory+'\ENGLISH\LANG');
               _CreatePath(BaseDirectory+'\ENGLISH\SG');
               _CreatePath(BaseDirectory+'\ENGLISH\RIP');
               _CreatePath(BaseDirectory+'\ENGLISH\SGX');
          END;
     END
     ELSE IF FileName='MSGAREA.SUB' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\MSGAREA.SUB')) THEN
          BEGIN
               FillChar(MessageSubs,SizeOf(MessageSubs),0);
               MessageSubs.sub_num           := 1;
               MessageSubs.sub_name          := 'Default Message Group';
               MessageSubs.dos_name          := NoDrive(BaseDirectory)+'\MAIL\';
               MessageSubs.base_type         := 2;
               MessageSubs.area_type         := 1;
               MessageSubs.msg_type          := 1;
               MessageSubs.file_attaches_sec := 32000;
               MessageSubs.origin            := 1;
               MessageSubs.address           := 1;
               MessageSubs.CleanLanguage     := 1;
               MessageSubs.ScanAtLogon       := True;
               ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
               REWRITE(FMessageSubs);
               WRITE(FMessageSubs,MessageSubs);
               CLOSE(FMessageSubs);
          END;
     END
     ELSE IF FileName='FILEAREA.SUB' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\FILEAREA.SUB')) THEN
          BEGIN
               FillChar(FileSubs,SizeOf(FileSubs),0);
               FileSubs.sub_num         := 1;
               FileSubs.sub_name        := 'Default File Group';
               FileSubs.sort            := 1;
               FileSubs.area_path       := NoDrive(BaseDirectory)+'\';
               FileSubs.TicConvertArcs  := True;
               FileSubs.TicDestFormat   := 'LZH';
               FileSubs.TicImportDiz    := True;
               FileSubs.TicReportNumber := 1;
               FileSubs.ScanAtLogon     := True;
               ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
               REWRITE(FFileSubs);
               WRITE(FFileSubs,FileSubs);
               CLOSE(FFileSubs);
          END;
     END
     ELSE IF FileName='FA000000.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\FA000000.DAT')) THEN
          BEGIN
               FillChar(FileArea,SizeOf(FileArea),0);
               FileArea.area_name       := 'New Uploads';
               FileArea.sub             := 1;
               FileArea.dos_name        := NoDrive(BaseDirectory)+'\UPLOADS\UPLOADS';
               FileArea.sort            := 1;
               FileArea.area_path       := NoDrive(BaseDirectory)+'\UPLOADS\';
               FileArea.AreaId          := 1;
               FileArea.Area_Tag        := '';
               FileArea.TicConvertArcs  := True;
               FileArea.TicDestFormat   := 'LZH';
               FileArea.TicImportDiz    := True;
               FileArea.TicReportNumber := 0;
               ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
               REWRITE(FFileArea);
               WRITE(FFileArea,FileArea);
               CLOSE(FFileArea);
               ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000001.DAT');
               REWRITE(FFileArea);
               WRITE(FFileArea,FileArea);
               CLOSE(FFileArea);
               _CreatePath(BaseDirectory+'\UPLOADS');
          END;
     END
     ELSE IF FileName='MA000000.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\MA000000.DAT')) THEN
          BEGIN
               FillChar(MessageArea,SizeOf(MessageArea),0);
               MessageArea.area_name         := 'Comment To Sysop';
               MessageArea.sub               := 1;
               MessageArea.dos_name          := NoDrive(BaseDirectory)+'\MAIL\COMMENT';
               MessageArea.base_type         := 2;
               MessageArea.area_type         := 2;
               MessageArea.msg_type          := 1;
               MessageArea.file_attaches_sec := 32000;
               MessageArea.origin            := 1;
               MessageArea.address           := 1;
               MessageArea.AreaId            := 1;
               ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
               REWRITE(FMessageArea);
               WRITE(FMessageArea,MessageArea);
               CLOSE(FMessageArea);
               ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000001.DAT');
               REWRITE(FMessageArea);
               WRITE(FMessageArea,MessageArea);
               CLOSE(FMessageArea);
          END;
     END
     ELSE IF FileName='PROTOCOL.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\PROTOCOL.DAT')) THEN
          BEGIN
               ProtocolInfo.EnableZ     := 1;
               ProtocolInfo.EnableX     := 1;
               ProtocolInfo.EnableX1k   := 1;
               ProtocolInfo.EnableY     := 1;
               ProtocolInfo.EnableYG    := 1;
               ProtocolInfo.EnableZ8K   := 0;
               ProtocolInfo.ZKey        := 'Z';
               ProtocolInfo.XKey        := 'X';
               ProtocolInfo.X1kKey      := '1';
               ProtocolInfo.YKey        := 'Y';
               ProtocolInfo.YGKey       := 'G';
               ProtocolInfo.Z8KKey      := '8';
               ASSIGN(FProtocolInfo,BaseDirectory+'\DATA\PROTOCOL.DAT');
               REWRITE(FProtocolInfo);
               WRITE(FProtocolInfo,ProtocolInfo);
               CLOSE(FProtocolInfo);
          END;
     END
     ELSE IF FileName='ERRLEVEL' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\ERRLEVEL.'+_String(CurrentNode))) THEN
          BEGIN
               FillChar(ErrorLevelInfo,SizeOf(ErrorLevelInfo),0);
               ErrorLevelInfo.ErrorLevel     := 100;
               ErrorLevelInfo.AllowHumans    := True;
               ASSIGN(FErrorLevelInfo,BaseDirectory+'\DATA\ERRLEVEL.'+_String(CurrentNode));
               REWRITE(FErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 300;
               ErrorLevelInfo.ConnectMessage := 'CONNECT';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 300;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 300';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 600;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 600';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 1200;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 1200';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 2400;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 2400';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 4800;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 4800';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 7200;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 7200';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 9600;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 9600';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 12000;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 12000';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 14400;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 14400';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 16800;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 16800';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 19200;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 19200';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 21600;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 21600';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 24000;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 24000';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 26400;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 26400';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 28800;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 28800';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 31200;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 31200';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 33600;
               ErrorLevelInfo.ConnectMessage := 'CONNECT 33600';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               ErrorLevelInfo.ConnectSpeed   := 19200;
               ErrorLevelInfo.ConnectMessage := 'FAX';
               WRITE(FErrorLevelInfo,ErrorLevelInfo);
               CLOSE(FErrorLevelInfo);
          END;
     END
     ELSE IF FileName='EXTCODES' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\EXTCODES.'+_String(CurrentNode))) THEN
          BEGIN
               FillChar(ExtCodes,SizeOf(ExtCodes),0);
               ExtCodes.Busy       := 'BUSY';
               ExtCodes.Error      := 'ERROR';
               ExtCodes.Fax        := 'FAX';
               ExtCodes.NoAnswer   := 'NO ANSWER';
               ExtCodes.NoCarrier  := 'NO CARRIER';
               ExtCodes.NoDialTone := 'NO DIAL TONE';
               ExtCodes.Ok         := 'OK';
               ExtCodes.Ring       := 'RING';
               ExtCodes.Ringing    := 'RINGING';
               ExtCodes.Voice      := 'VOICE';
               ExtCodes.CIDDate    := 'DATE = ';
               ExtCodes.CIDTime    := 'TIME = ';
               ExtCodes.CIDName    := 'NAME = ';
               ExtCodes.CIDNumber  := 'NMBR = ';
               ASSIGN(FExtCodes,BaseDirectory+'\DATA\EXTCODES.'+_String(CurrentNode));
               REWRITE(FExtCodes);
               WRITE(FExtCodes,ExtCodes);
               CLOSE(FExtCodes);
          END;
     END
     ELSE IF FileName='FAXCODES' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\FAXCODES.'+_String(CurrentNode))) THEN
          BEGIN
               FillChar(FaxCodes,SizeOf(FaxCodes),0);
               FaxCodes.FaxSendClass           := 1;
               FaxCodes.FaxRecvClass           := 3;
               FaxCodes.FaxID                  := '000 000 0000';
               FaxCodes.FaxSendBPS             := 4;
               FaxCodes.FaxRecvBPS             := 4;
               FaxCodes.FaxCoverPage           := '\SHOTGUN\DATA\COVER.TXT';
               FaxCodes.FaxPageHeader          := '$D   $T   From: $S   $I                            Page: $P/$N';
               FaxCodes.SetHardwareCompression := 'AT&H1&I0';
               ASSIGN(FFaxCodes,BaseDirectory+'\DATA\FAXCODES.'+_String(CurrentNode));
               REWRITE(FFaxCodes);
               WRITE(FFaxCodes,FaxCodes);
               CLOSE(FFaxCodes);
          END;
     END
     ELSE IF FileName='COLOURS.ANS' THEN
     BEGIN
          IF NOT(_FileExists(SelectedLanguage+'\LANG\COLOURS.ANS')) THEN
          BEGIN
               _CreatePath(SelectedLanguage+'\LANG\');
               Colours.InputFieldForeground  := 15;
               Colours.InputFieldBackGround  := 1;
               Colours.OptionBracket         := 8;
               Colours.OptionHotKey          := 14;
               Colours.OptionText            := 7;
               Colours.ChatSysop             := 3;
               Colours.ChatUser              := 14;
               Colours.FileListNumber        := 11;
               Colours.FileListBracket       := 9;
               Colours.FileListFileName      := 10;
               Colours.FileListFileSize      := 9;
               Colours.FileListFileDate      := 1;
               Colours.FileListDescription1  := 11;
               Colours.FileListDescriptions  := 3;
               Colours.FileListTaggedFile    := 4;
               Colours.FileListOfflineFile   := 8;
               Colours.FileListSeperator     := 8;
               Colours.ViewQuoteMSGNumber    := 15;
               Colours.ViewQuoteMSGBracket   := 1;
               Colours.ViewQuoteMSGText      := 3;
               Colours.ReadMSGQuoteColour    := 2;
               Colours.ReadMSGBodyColour     := 7;
               Colours.ReadMSGTearColour     := 8;
               Colours.LineEditorFrame       := 1;
               Colours.LineEditorLineNumbers := 15;
               Colours.LineEditorInfoText    := 3;
               Colours.LineEditorInfoData    := 11;
               Colours.LineEditorHeaderFore  := 15;
               Colours.LineEditorHeaderBack  := 1;
               Colours.SpinCursor            := 8;
               ASSIGN(FColours,SelectedLanguage+'\LANG\COLOURS.ANS');
               REWRITE(FColours);
               WRITE(FColours,Colours);
               CLOSE(FColours);
          END;
     END
     ELSE IF FileName='COLOURS.VGA' THEN
     BEGIN
          IF NOT(_FileExists(SelectedLanguage+'\LANG\COLOURS.VGA')) THEN
          BEGIN
               _CreatePath(SelectedLanguage+'\LANG\');
               Colours2.ReadMsgBody          := 0;
               Colours2.ReadMsgQuote         := 9;
               Colours2.ReadMSGTearColour    := 8;
               Colours2.FileListFileName     := 1;
               Colours2.FileListFileSize     := 9;
               Colours2.FileListFileDate     := 9;
               Colours2.FileListDescription1 := 0;
               Colours2.FileListDescriptions := 0;
               Colours2.FileListTaggedFile   := 4;
               Colours2.FileListOfflineFile  := 8;
               Colours2.PickListBack         := 7;
               Colours2.PickListFore         := 0;
               Colours2.PickHighlightBack    := 9;
               Colours2.PickHighlightFore    := 15;
               Colours2.InternalImage        := 1;
               Colours2.DisabledBackground   := 7;
               Colours2.DisabledHighlight    := 15;
               Colours2.DisabledShadow       := 8;
               Colours2.DisabledText         := 8;
               Colours2.FileQueueName        := 1;
               Colours2.FileQueueDesc        := 9;
               Colours2.FileQueueSize        := 0;
               Colours2.FileQueueTime        := 0;
               Colours2.MsgListFrom          := 1;
               Colours2.MsgListTo            := 9;
               Colours2.MsgListSubject       := 0;
               Colours2.MsgListPrivate       := 4;
               ASSIGN(FColours2,SelectedLanguage+'\LANG\COLOURS.VGA');
               REWRITE(FColours2);
               WRITE(FColours2,Colours2);
               CLOSE(FColours2);
          END;
     END
     ELSE IF FileName='GSCONFIG.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\GSCONFIG.DAT')) THEN
          BEGIN
               ConfigSetup.Vertical     := 20;
               ConfigSetup.Horizontal   := 10;
               ConfigSetup.Printer      := 1;
               ConfigSetup.AnsiEditor   := '';
               ConfigSetup.RipEditor    := '';
               ConfigSetup.PrinterModel := 1;
               ASSIGN(FConfigSetup,BaseDirectory+'\DATA\GSCONFIG.DAT');
               REWRITE(FConfigSetup);
               WRITE(FConfigSetup,ConfigSetup);
               CLOSE(FConfigSetup);
          END;
     END
     ELSE IF FileName='CALLBACK.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\CALLBACK.DAT')) THEN
          BEGIN
               FillChar(CBVSetup^,SizeOf(CBVSetup^),0);
               CBVSetup^.CBVStart        := 10*3600;
               CBVSetup^.CBVEnd          := 20*3600;
               CBVSetup^.VAccess         := 10;
               CBVSetup^.LDPass          := 1;
               CBVSetup^.UserToLogBackIn := 1;
               CBVSetup^.CallRetries     := 3;
               ASSIGN(FCBVSetup,BaseDirectory+'\DATA\CALLBACK.DAT');
               REWRITE(FCBVSetup);
               WRITE(FCBVSetup,CBVSetup^);
               CLOSE(FCBVSetup);
          END;
     END
     ELSE IF FileName='NETWORK.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\NETWORK.DAT')) THEN
          BEGIN
               FillChar(NetWorkInfo,SizeOf(NetWorkInfo),0);
               ASSIGN(FNetWorkInfo,BaseDirectory+'\DATA\NETWORK.DAT');
               REWRITE(FNetWorkInfo);
               WRITE(FNetWorkInfo,NetWorkInfo);
               CLOSE(FNetWorkInfo);
          END;
     END
     ELSE IF FileName='ORIGINS.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\ORIGINS.DAT')) THEN
          BEGIN
               FillChar(NetOrigins,SizeOf(NetOrigins),0);
               NetOrigins.Net_Origin := 'Shotgun Professional SVGA Communications!';
               ASSIGN(FNetOrigins,BaseDirectory+'\DATA\ORIGINS.DAT');
               REWRITE(FNetOrigins);
               WRITE(FNetOrigins,NetOrigins);
               CLOSE(FNetOrigins);
          END;
     END
     ELSE IF FileName='NAMES.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\NAMES.DAT')) THEN
          BEGIN
               FillChar(Names,SizeOf(Names),0);
               ASSIGN(FNames,BaseDirectory+'\DATA\NAMES.DAT');
               REWRITE(FNames);
               WRITE(FNames,Names);
               CLOSE(FNames);
          END;
     END
     ELSE IF FileName='UUCP.DAT' THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\UUCP.DAT')) THEN
          BEGIN
               FillChar(UUCP,SizeOf(UUCP),0);
               UUCP.HostName         := 'uucp';
               UUCP.HostAddress.Zone := 1;
               UUCP.HostAddress.Net  := 999;
               UUCP.HostAddress.Node := 0;
               UUCP.YourAddress.Zone := 1;
               UUCP.YourAddress.Net  := 999;
               UUCP.YourAddress.Node := 3;
               ASSIGN(FUUCP,BaseDirectory+'\DATA\UUCP.DAT');
               REWRITE(FUUCP);
               WRITE(FUUCP,UUCP);
               CLOSE(FUUCP);
          END;
     END
     ELSE CheckFile2(FileName);
END;


PROCEDURE CheckAllFiles;
BEGIN
     CheckFile('FREQ.DAT');
     CheckFile('ACCESS.DAT');
     CheckFile('ARCHIVE.DAT');
     CheckFile('ARCUTILS.DAT');
     CheckFile('BADLANG.DAT');
     CheckFile('SYSCALLS.DAT');
     CheckFile('SCANNERS.DAT');
     CheckFile('USERS.BBS');
     CheckFile('VERIFY.DAT');
     CheckFile('SYSTEM.DAT');
     CheckFile('LANGUAGE.DAT');
     CheckFile('MSGAREA.SUB');
     CheckFile('FILEAREA.SUB');
     CheckFile('FA000000.DAT');
     CheckFile('MA000000.DAT');
     CheckFile('NODES.DAT');
     CheckFile('PROTOCOL.DAT');
     CheckFile('ERRLEVEL');
     CheckFile('EXTCODES');
     CheckFile('FAXCODES');
     CheckFile('MAILER.DAT');
     CheckFile('MAILER2.DAT');
     CheckFile('COLOURS.ANS');
     CheckFile('COLOURS.VGA');
     CheckFile('GSCONFIG.DAT');
     CheckFile('CALLBACK.DAT');
     CheckFile('NETWORK.DAT');
     CheckFile('ORIGINS.DAT');
     CheckFile('NAMES.DAT');
     CheckFile('UUCP.DAT');
     CheckFile('SHUTTLE.DAT');
     CheckFile('CALLERID.DAT');
     CheckFile('OPENING.DAT');
     CheckFile('NEWUSER.VGA');
     CheckFile('NEWUSER.ANS');
     CheckFile('SGSCHEME.DAT');
     CheckFile('FKEYS.DAT');
     CheckFile('EXTERNAL.DAT');
     CheckFile('HIDDEN.DAT');
     CheckCommands;
END;


END.
