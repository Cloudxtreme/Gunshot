{$I DEFINES.INC}
UNIT MENU3;


INTERFACE


PROCEDURE DoUserBaseEditor;
PROCEDURE DoAccessLevels;
PROCEDURE DoNewUser;
PROCEDURE DoVerifiedUsers;
PROCEDURE SearchVerifiedUsers;
PROCEDURE DoSystemNames;
PROCEDURE DoFindUser;


IMPLEMENTATION


USES IntrFace,BsMouse,BsString,BsFile,Crt,Defaults,CnfgVars,Shotgun;


PROCEDURE EditSubsciption;
VAR  WhichOne : Word;
BEGIN
     _SaveWindow(WorkDir+'\SUBUSER.SCR');
     Toggle[1].Flips   := 5;
     Toggle[1].Current := UserRecord.SubModel+1;
     Toggle[1].Flip[1] := 'NONE';
     Toggle[1].Flip[2] := 'BY CALENDAR DAYS';
     Toggle[1].Flip[3] := 'BY CALL DAYS';
     Toggle[1].Flip[4] := 'BY MINUTES USED';
     Toggle[1].Flip[5] := 'SPECIFIC DATE';
     DrawWindow(15,5,65,18,'USER #'+_String(UserRecord.User_Number)+' - '+UserRecord.Name,True);
     AddObject(40,7,8,20,'1',True);
     AddObject(40,9,4,6,UnpackedDate(UserRecord.Sub_Expiry),True);
     AddObject(40,10,2,5,_String(UserRecord.Expiry_Adjust),True);
     AddObject(40,12,2,9,_String(UserRecord.SubMinutesUsed),True);
     AddObject(40,13,2,9,_String(UserRecord.SubCalendarDaysUsed),True);
     AddObject(40,14,2,9,_String(UserRecord.SubCallDaysUsed),True);
     AddButton(46,16,' QUIT ',True,1,16);
     AddButton(54,16,' RESET ',True,1,19);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(20,7);  WRITE('Subscription Model');
     GotoXY(20,9);  WRITE('       Expiry Date');
     GotoXY(20,10); WRITE('     Expiry Access');
     GotoXY(20,12); WRITE('      Minutes Used');
     GotoXy(20,13); WRITE('Calendar Days Used');
     GotoXy(20,14); WRITE('    Call Days Used');
     _ShowMouse;
     REPEAT
           WhichOne := DoObjects;
           IF WhichOne=2 THEN UserRecord.SubLastChange := PROPER_DATE_NOTIME;
     UNTIL WhichOne=1;
     ClearObjects;
     ClearButtons;
     UserRecord.SubModel            := Toggle[1].Current-1;
     UserRecord.Sub_Expiry          := PackedDate(Objects^[2].Stuff);
     UserRecord.Expiry_Adjust       := Numeric(Objects^[3].Stuff,WordInteger);
     UserRecord.SubMinutesUsed      := Numeric(Objects^[4].Stuff,WordInteger);
     UserRecord.SubCalendarDaysUsed := Numeric(Objects^[5].Stuff,WordInteger);
     UserRecord.SubCallDaysUsed     := Numeric(Objects^[6].Stuff,WordInteger);
     LoadWindow(WorkDir+'\SUBUSER.SCR');
END;


FUNCTION EditUser(Number: Longint): Boolean;
VAR  DoAgain  : Boolean;
     WhichOne : Word;
LABEL           OverAgain;

     PROCEDURE ReLoad;
     VAR  Loop : Word;
     BEGIN
          ClearObjects;
          ClearButtons;
          UserRecord.name             := Objects^[1].Stuff;
          UserRecord.alias            := Objects^[2].Stuff;
          UserRecord.password         := _UpperCase(Objects^[3].Stuff);
          UserRecord.street           := Objects^[4].Stuff;
          UserRecord.city             := Objects^[5].Stuff;
          UserRecord.prov             := Objects^[6].Stuff;
          UserRecord.country          := Objects^[7].Stuff;
          UserRecord.postal           := Objects^[8].Stuff;
          UserRecord.voice            := Objects^[9].Stuff;
          UserRecord.data             := Objects^[10].Stuff;
          UserRecord.bbs              := Objects^[11].Stuff;
          UserRecord.bbs_phone        := Objects^[12].Stuff;
          UserRecord.bbs_net          := Objects^[13].Stuff;
          UserRecord.Birth            := Objects^[14].Stuff;
          UserRecord.Sex              := Numeric(Objects^[15].Stuff,ByteInteger);
          UserRecord.first_call       := PackedDate(Objects^[16].Stuff);
          UserRecord.last_call        := PackedDate(Objects^[17].Stuff);
          UserRecord.Total_Calls      := Numeric(Objects^[18].Stuff,LongInteger);
          UserRecord.PageFlag         := Numeric(Objects^[19].Stuff,ByteInteger);
          UserRecord.UserList         := Numeric(Objects^[20].Stuff,ByteInteger);
          UserRecord.Ver_User         := Numeric(Objects^[21].Stuff,ByteInteger);
          UserRecord.Page             := Numeric(Objects^[22].Stuff,ByteInteger);
          UserRecord.Punt             := Numeric(Objects^[23].Stuff,ByteInteger);
          UserRecord.uploads          := Numeric(Objects^[24].Stuff,LongInteger);
          UserRecord.DLBytesToday     := Numeric(Objects^[25].Stuff,LongInteger);
          UserRecord.dl_total         := Numeric(Objects^[26].Stuff,LongInteger);
          UserRecord.files_uploaded   := Numeric(Objects^[27].Stuff,LongInteger);
          UserRecord.files_downloaded := Numeric(Objects^[28].Stuff,LongInteger);
          UserRecord.SecondsInBank    := Numeric(Objects^[29].Stuff,LongInteger)*60;
          UserRecord.ByteBankBalance  := Numeric(Objects^[30].Stuff,LongInteger);
          UserRecord.SecondsRemaining := Numeric(Objects^[31].Stuff,LongInteger)*60;
          UserRecord.Security         := Numeric(Objects^[32].Stuff,WordInteger);
          FOR Loop := 1 TO 10 DO
          BEGIN
               IF Objects^[33].Stuff[Loop]='1' THEN UserRecord.Tags[Loop] := 1
                                               ELSE UserRecord.Tags[Loop] := 0;
          END;
          UserRecord.Note             := Objects^[34].Stuff;
     END;

BEGIN
     _SaveWindow(WorkDir+'\EDITUSER.SCR');
     ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
     RESET(FUserRecord);
     SEEK(FUserRecord,Number);
     READ(FUserRecord,UserRecord);
     CLOSE(FUserRecord);
     OverAgain:
     DrawWindow(1,1,80,25,'USER #'+_String(UserRecord.User_Number)+' - '+UserRecord.Name,False);
     AddObject(18,3,1,30,UserRecord.name,True);
     AddObject(18,4,1,30,UserRecord.alias,True);
     AddObject(18,5,1,20,UserRecord.password,True);
     AddObject(18,6,1,30,UserRecord.street,True);
     AddObject(18,7,1,30,UserRecord.city,True);
     AddObject(18,8,1,30,UserRecord.prov,True);
     AddObject(18,9,1,30,UserRecord.country,True);
     AddObject(18,10,1,20,UserRecord.postal,True);
     AddObject(18,11,1,20,UserRecord.voice,True);
     AddObject(18,12,1,20,UserRecord.data,True);
     AddObject(18,13,1,30,UserRecord.bbs,True);
     AddObject(18,14,1,20,UserRecord.bbs_phone,True);
     AddObject(18,15,1,20,UserRecord.bbs_net,True);
     AddObject(18,16,4,6,UserRecord.Birth,True);
     AddObject(18,17,5,6,_String(UserRecord.Sex),True);
     AddObject(18,18,4,6,UnpackedDate(UserRecord.first_call),True);
     AddObject(18,19,4,6,UnpackedDate(UserRecord.last_call),True);
     AddObject(18,20,2,9,_String(UserRecord.Total_Calls),True);
     AddObject(68,3,6,3,_String(UserRecord.PageFlag),True);
     AddObject(68,4,6,3,_String(UserRecord.UserList),True);
     AddObject(68,5,6,3,_String(UserRecord.Ver_User),True);
     AddObject(68,6,6,3,_String(UserRecord.Page),True);
     AddObject(68,7,6,3,_String(UserRecord.Punt),True);
     AddObject(68,8,2,9,_String(UserRecord.uploads),True);
     AddObject(68,9,2,9,_String(UserRecord.DLBytesToday),True);
     AddObject(68,10,2,9,_String(UserRecord.dl_total),True);
     AddObject(68,11,2,9,_String(UserRecord.files_uploaded),True);
     AddObject(68,12,2,9,_String(UserRecord.files_downloaded),True);
     AddObject(68,13,2,9,_String(Trunc(UserRecord.SecondsInBank/60)),True);
     AddObject(68,14,2,9,_String(UserRecord.ByteBankBalance),True);
     AddObject(68,15,2,9,_String(Trunc(UserRecord.SecondsRemaining/60)),True);
     AddObject(68,16,2,5,_String(UserRecord.Security),True);
     AddObject(68,17,7,10,Tags(UserRecord.Tags),True);
     AddObject(7,24,1,60,UserRecord.Note,True);
     AddButton(55,20,' QUIT ',True,1,16);
     AddButton(63,20,' SUBSCRIPTION ',True,1,31);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(2,22);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor_BS(11);
     GotoXY(3,3);   WRITE('NameÄÂÄÄÄReal');
     GotoXY(3,4);   WRITE('     ÀÄÄAlias');
     GotoXY(3,5);   WRITE('     Password');
     GotoXy(3,6);   WRITE('       Street');
     GotoXy(3,7);   WRITE('    City/Town');
     GotoXy(3,8);   WRITE('   Prov/State');
     GotoXy(3,9);   WRITE('      Country');
     GotoXy(3,10);  WRITE('   Postal/Zip');
     GotoXy(3,11);  WRITE('PhoneÄÂÄVoice');
     GotoXy(3,12);  WRITE('      ÀÄÄData');
     GotoXY(3,13);  WRITE('BBSÄÂÄÄÄÄName');
     GotoXY(3,14);  WRITE('    ÃÄÄÄPhone');
     GotoXY(3,15);  WRITE('    ÀÄAddress');
     GotoXY(3,16);  WRITE('   Birth Date');
     GotoXY(3,17);  WRITE('       Gender');
     GotoXY(3,18);  WRITE('CallsÄÂÄFirst');
     GotoXY(3,19);  WRITE('      ÃÄÄLast');
     GotoXY(3,20);  WRITE('      ÀÄTotal');
     GotoXY(50,3);  WRITE('    Can Be Paged');
     GotoXY(50,4);  WRITE('     In Userlist');
     GotoXY(50,5);  WRITE('     Is Verified');
     GotoXY(50,6);  WRITE('  Can Page Sysop');
     GotoXY(50,7);  WRITE('      Locked Out');
     GotoXY(50,8);  WRITE('  Bytes Uploaded');
     GotoXY(50,9);  WRITE('DL BytesÄÂÄToday');
     GotoXY(50,10); WRITE('         ÀÄTotal');
     GotoXY(50,11); WRITE('FilesÄÂÄÄÄUpload');
     GotoXY(50,12); WRITE('      ÀÄDownload');
     GotoXY(50,13); WRITE('BankÄÂÄÄÄMinutes');
     GotoXY(50,14); WRITE('     ÀÄÄÄÄÄBytes');
     GotoXY(50,15); WRITE('    Minutes Left');
     GotoXY(50,16); WRITE('AccessÄÂÄÄÄLevel');
     GotoXY(50,17); WRITE('       ÀÄÄÄÄTags');
     GotoXY(7,23);  WRITE('General comment about this user:');
     _ShowMouse;
     DoAgain := False;
     REPEAT
           WhichOne := DoObjects;
           IF WhichOne=2 THEN
           BEGIN
                ReLoad;
                EditSubsciption;
                GOTO OverAgain;
           END;
     UNTIL WhichOne=1;
     IF Escaped THEN DoAgain := False
                ELSE DoAgain := True;
     ReLoad;
     ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
     RESET(FUserRecord);
     SEEK(FUserRecord,Number);
     WRITE(FUserRecord,UserRecord);
     CLOSE(FUserRecord);
     LoadWindow(WorkDir+'\EDITUSER.SCR');
     EditUser := DoAgain;
END;


PROCEDURE AddUser;
VAR  FUserRecord2 : File Of _UsersBBS_Record;
     Counting     : Longint;
BEGIN
     FillChar(UserRecord2,SizeOf(UserRecord2),0);
     UserRecord2.file_lines := 18;
     UserRecord2.birth      := '000000';
     UserRecord2.page       := 1;
     UserRecord2.userlist   := 1;
     UserRecord2.PageFlag   := 1;
     UserRecord2.ibm        := 1;
     ASSIGN(FUserRecord2,BaseDirectory+'\DATA\USERS.BBS');
     RESET(FUserRecord2);
     READ(FUserRecord2,UserRecord);
     CLOSE(FUserRecord2);
     UserRecord2.user_number := UserRecord.User_number;
     ASSIGN(FUserRecord2,BaseDirectory+'\DATA\USERS.BBS');
     RESET(FUserRecord2);
     SEEK(FUserRecord2,FileSize(FUserRecord2));
     WRITE(FUserRecord2,UserRecord2);
     CLOSE(FUserRecord2);
     ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
     RESET(FUserRecord);
     READ(FUserRecord,UserRecord);
     RESET(FUserRecord);
     INC(UserRecord.User_Number);
     WRITE(FUserRecord,UserRecord);
     CLOSE(FUserRecord);
END;


PROCEDURE DeleteUser(Number: Longint);
VAR  FUserRecord2 : File Of _UsersBBS_Record;
     Counting     : Longint;
BEGIN
     INC(Number);
     ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
     RESET(FUserRecord);
     SEEK(FUserRecord,Number);
     READ(FUserRecord,UserRecord);
     CLOSE(FUserRecord);
     _EraseFile(BaseDirectory+'\FILETAGS\'+_String(UserRecord.User_Number)+'.BBS');
     _EraseFile(BaseDirectory+'\MSGTAGS\'+_String(UserRecord.User_Number)+'.BBS');
     _EraseFile(BaseDirectory+'\FREQ\'+_String(UserRecord.User_Number)+'.BBS');
     _EraseFileRecord(BaseDirectory+'\DATA\USERS.BBS',SizeOf(UserRecord),Number);
END;


PROCEDURE InsertUser(Number: Longint);
VAR  FUserRecord2 : File Of _UsersBBS_Record;
     Counting     : Longint;
BEGIN
     FillChar(UserRecord2,SizeOf(UserRecord2),0);
     UserRecord2.file_lines := 18;
     UserRecord2.birth      := '000000';
     UserRecord2.page       := 1;
     UserRecord2.userlist   := 1;
     UserRecord2.PageFlag   := 1;
     UserRecord2.ibm        := 1;
     ASSIGN(FUserRecord2,BaseDirectory+'\DATA\USERS.BBS');
     RENAME(FUserRecord2,BaseDirectory+'\DATA\USERS.BAK');
     ASSIGN(FUserRecord2,BaseDirectory+'\DATA\USERS.BAK');
     ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
     RESET(FUserRecord2);
     REWRITE(FUserRecord);
     READ(FUserRecord2,UserRecord);
     UserRecord2.user_number := UserRecord.User_number;
     WRITE(FUserRecord,UserRecord);
     Counting := 0;
     REPEAT
           READ(FUserRecord2,UserRecord);
           INC(Counting);
           IF Counting=Number THEN WRITE(FUserRecord,UserRecord2);
           WRITE(FUserRecord,UserRecord);
     UNTIL EOF(FUserRecord2);
     CLOSE(FUserRecord);
     CLOSE(FUserRecord2);
     ERASE(FUserRecord2);
     ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
     RESET(FUserRecord);
     READ(FUserRecord,UserRecord);
     RESET(FUserRecord);
     UserRecord.User_Number := UserRecord2.User_Number;
     INC(UserRecord.User_Number);
     WRITE(FUserRecord,UserRecord);
     CLOSE(FUserRecord);
END;


PROCEDURE DoUserBaseEditor;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
BEGIN
     PickListPerPage  := 16;
     PickItem         := 1;
     PickTop          := 1;
     CheckFile('USERS.BBS');
     ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
     RESET(FUserRecord);
     PickListItems := FileSize(FUserRecord)-1;
     CLOSE(FUserRecord);
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseFileButton    := False;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' User Name',41);
     PickList_B_Title := 'Security  ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
     RESET(FUserRecord);
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     SEEK(FUserRecord,1);
     REPEAT
           Read(FUserRecord,UserRecord);
           IF UserRecord.Alias=''
              THEN PickListFile.A := UserRecord.Name
              ELSE PickListFile.A := _Mid(UserRecord.Name+'  ('+UserRecord.Alias+')',1,40);
           PickListFile.B := _String(UserRecord.Security);
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FUserRecord);
     CLOSE(FUserRecord);
     CLOSE(FPickListFile);
     SetUpPickList('USERBASE EDITOR');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN                      {EDIT}
                     EditUser(PickItem);
                     ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
                     RESET(FUserRecord);
                     PickListItems := FileSize(FUserRecord)-1;
                     CLOSE(FUserRecord);
                     ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
                     RESET(FUserRecord);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     SEEK(FUserRecord,1);
                     REPEAT
                           Read(FUserRecord,UserRecord);
                           IF UserRecord.Alias=''
                              THEN PickListFile.A := UserRecord.Name
                              ELSE PickListFile.A := _Mid(UserRecord.Name+'  ('+UserRecord.Alias+')',1,40);
                           PickListFile.B := _String(UserRecord.Security);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FUserRecord);
                     CLOSE(FUserRecord);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN                      {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteUser(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
                          RESET(FUserRecord);
                          PickListItems := FileSize(FUserRecord)-1;
                          CLOSE(FUserRecord);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
                          RESET(FUserRecord);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          SEEK(FUserRecord,1);
                          REPEAT
                                Read(FUserRecord,UserRecord);
                                IF UserRecord.Alias=''
                                   THEN PickListFile.A := UserRecord.Name
                                   ELSE PickListFile.A := _Mid(UserRecord.Name+'  ('+UserRecord.Alias+')',1,40);
                                PickListFile.B := _String(UserRecord.Security);
                                WRITE(FPickListFile,PickListFile);
                          UNTIL EOF(FUserRecord);
                          CLOSE(FUserRecord);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN                      {INSERT}
                     InsertUser(PickItem);
                     EditUser(PickItem);
                     ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
                     RESET(FUserRecord);
                     PickListItems := FileSize(FUserRecord)-1;
                     CLOSE(FUserRecord);
                     ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
                     RESET(FUserRecord);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     SEEK(FUserRecord,1);
                     REPEAT
                           Read(FUserRecord,UserRecord);
                           IF UserRecord.Alias=''
                              THEN PickListFile.A := UserRecord.Name
                              ELSE PickListFile.A := _Mid(UserRecord.Name+'  ('+UserRecord.Alias+')',1,40);
                           PickListFile.B := _String(UserRecord.Security);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FUserRecord);
                     CLOSE(FUserRecord);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     AddUser;
                     EditUser(PickListItems+1);
                     ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
                     RESET(FUserRecord);
                     PickListItems := FileSize(FUserRecord)-1;
                     CLOSE(FUserRecord);
                     ASSIGN(FUserRecord,BaseDirectory+'\DATA\USERS.BBS');
                     RESET(FUserRecord);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     SEEK(FUserRecord,1);
                     REPEAT
                           Read(FUserRecord,UserRecord);
                           IF UserRecord.Alias=''
                              THEN PickListFile.A := UserRecord.Name
                              ELSE PickListFile.A := _Mid(UserRecord.Name+'  ('+UserRecord.Alias+')',1,40);
                           PickListFile.B := _String(UserRecord.Security);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FUserRecord);
                     CLOSE(FUserRecord);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           6:   ;
           45:  BEGIN                      {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE EditAccess(Number: Longint);
VAR  Loop : Word;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
     RESET(FUserAccess);
     SEEK(FUserAccess,Number-1);
     READ(FUserAccess,UserAccess);
     CLOSE(FUserAccess);
     Toggle[1].Flips   := 4;
     Toggle[1].Current := UserAccess.SubModel+1;
     Toggle[1].Flip[1] := 'NONE';
     Toggle[1].Flip[2] := 'BY CALENDAR DAYS';
     Toggle[1].Flip[3] := 'BY CALL DAYS';
     Toggle[1].Flip[4] := 'BY MINUTES USED';
     DrawWindow(2,2,78,24,'EDIT ACCESS PROFILE',True);
     AddObject(22,4 ,1,15,UserAccess.name,True);
     AddObject(22,5 ,2,5,_String(UserAccess.access_level),True);
     AddObject(22,6 ,1,12,UserAccess.First_Menu,True);
     AddObject(22,7 ,7,10,Tags(UserAccess.Tags),True);
     AddObject(22,8 ,2,9,_String(Trunc(UserAccess.Time/60)),True);
     AddObject(30,10,6,3,_String(UserAccess.Page),True);
     AddObject(30,11,6,3,_String(UserAccess.Verified),True);
     AddObject(30,13,2,2,_String(UserAccess.File_Ratio),True);
     AddObject(30,14,2,2,_String(UserAccess.Byte_Ratio),True);
     AddObject(30,15,2,9,_String(UserAccess.Ratio_Start),True);
     AddObject(30,16,2,9,_String(UserAccess.Daily_Bytes),True);
     AddObject(30,17,2,3,_String(UserAccess.Ul_Credit),True);
     AddObject(30,18,6,3,_String(UserAccess.NoFileRatio),True);
     AddObject(30,19,2,5,_String(UserAccess.QWKMessages),True);
     AddObject(30,21,2,9,_String(Trunc(UserAccess.TBank/60)),True);
     AddObject(30,22,2,9,_String(UserAccess.BBank),True);
     AddObject(55,4,8,20,'1',True);
     AddObject(55,5,2,9,_String(UserAccess.SubMinutes),True);
     AddObject(55,6,2,9,_String(UserAccess.SubCalendarDays),True);
     AddObject(55,7,2,9,_String(UserAccess.SubCallDays),True);
     AddObject(55,8,2,5,_String(UserAccess.ExpiryAccessLevel),True);
     AddButton(68,22,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(40,4);  WRITE(' Subscription');
     GotoXY(40,5);  WRITE('      Minutes');
     GotoXY(40,6);  WRITE('Calendar Days');
     GotoXY(40,7);  WRITE('    Call Days');
     GotoXY(40,8);  WRITE('Expiry Access');
     GotoXY(4,4);  WRITE('    Profile Name');
     GotoXY(4,5);  WRITE('    Access Level');
     GotoXY(4,6);  WRITE('      First Menu');
     GotoXY(4,7);  WRITE('User Access Tags');
     GotoXY(4,8);  WRITE('Daily Time Limit');
     GotoXY(4,10); WRITE('     Can User Page Sysop');
     GotoXY(4,11); WRITE('        Is User Verified');
     GotoXY(4,13); WRITE('    Ratios ÄÂÄ File   1 :');
     GotoXY(4,14); WRITE('    (UL:DL) ÀÄ Byte   1 :');
     GotoXY(4,15); WRITE(' DL Bytes To Start Ratio');
     GotoXY(4,16); WRITE('     Maximum Daily Bytes');
     GotoXY(4,17); WRITE('  Upload Time Credit (%)');
     GotoXY(4,18); WRITE('     Disable File Ratios');
     GotoXY(4,19); WRITE(' Max Messages For QWK DL');
     GotoXY(4,21); WRITE(' Time Bank Credit (mins)');
     GotoXY(4,22); WRITE('Byte Bank Credit (bytes)');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     UserAccess.name              := Objects^[1].Stuff;
     UserAccess.access_level      := Numeric(Objects^[2].Stuff,WordInteger);
     UserAccess.First_Menu        := Objects^[3].Stuff;
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[4].Stuff[Loop]='1' THEN UserAccess.Tags[Loop] := 1
                                         ELSE UserAccess.Tags[Loop] := 0;
     END;
     UserAccess.Time              := Numeric(Objects^[5].Stuff,LongInteger)*60;
     UserAccess.Page              := Numeric(Objects^[6].Stuff,ByteInteger);
     UserAccess.Verified          := Numeric(Objects^[7].Stuff,ByteInteger);
     UserAccess.File_Ratio        := Numeric(Objects^[8].Stuff,ByteInteger);
     UserAccess.Byte_Ratio        := Numeric(Objects^[9].Stuff,ByteInteger);
     UserAccess.Ratio_Start       := Numeric(Objects^[10].Stuff,LongInteger);
     UserAccess.Daily_Bytes       := Numeric(Objects^[11].Stuff,LongInteger);
     UserAccess.Ul_Credit         := Numeric(Objects^[12].Stuff,ByteInteger);
     UserAccess.NoFileRatio       := Numeric(Objects^[13].Stuff,ByteInteger);
     UserAccess.QWKMessages       := Numeric(Objects^[14].Stuff,WordInteger);
     UserAccess.TBank             := Numeric(Objects^[15].Stuff,LongInteger)*60;
     UserAccess.BBank             := Numeric(Objects^[16].Stuff,LongInteger);
     UserAccess.SubModel          := Toggle[1].Current-1;
     UserAccess.SubMinutes        := Numeric(Objects^[18].Stuff,LongInteger);
     UserAccess.SubCalendarDays   := Numeric(Objects^[19].Stuff,LongInteger);
     UserAccess.SubCallDays       := Numeric(Objects^[20].Stuff,LongInteger);
     UserAccess.ExpiryAccessLevel := Numeric(Objects^[21].Stuff,WordInteger);
     IF UserAccess.File_Ratio>15 THEN UserAccess.File_Ratio := 15;
     IF UserAccess.Byte_Ratio>15 THEN UserAccess.Byte_Ratio := 15;
     ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
     RESET(FUserAccess);
     SEEK(FUserAccess,Number-1);
     WRITE(FUserAccess,UserAccess);
     CLOSE(FUserAccess);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteAccess(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\ACCESS.DAT',SizeOf(UserAccess),Number);
END;


PROCEDURE InsertAccess(Number: Longint);
VAR  FUserAccess2 : File Of _Access_Record;
     Counting     : Longint;
BEGIN
     FillChar(UserAccess2,SizeOf(UserAccess2),0);
     UserAccess2.time            := 3600;
     UserAccess2.ratio_start     := 2048000;
     UserAccess2.first_menu      := '#MAIN.MNU';
     UserAccess2.daily_bytes     := 1024000;
     UserAccess2.ul_credit       := 50;
     UserAccess2.page            := 1;
     UserAccess2.verified        := 0;
     UserAccess2.QWKBytes        := 512000;
     UserAccess2.QWKMessages     := 600;
     UserAccess2.QWKFree         := 1;
     UserAccess2.NoFileRatio     := 1;
     ASSIGN(FUserAccess2,BaseDirectory+'\DATA\ACCESS.DAT');
     RENAME(FUserAccess2,BaseDirectory+'\DATA\ACCESS.BAK');
     ASSIGN(FUserAccess2,BaseDirectory+'\DATA\ACCESS.BAK');
     ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
     RESET(FUserAccess2);
     REWRITE(FUserAccess);
     Counting := 0;
     REPEAT
           READ(FUserAccess2,UserAccess);
           INC(Counting);
           IF Counting=Number THEN WRITE(FUserAccess,UserAccess2);
           WRITE(FUserAccess,UserAccess);
     UNTIL EOF(FUserAccess2);
     CLOSE(FUserAccess);
     CLOSE(FUserAccess2);
     ERASE(FUserAccess2);
END;


PROCEDURE AddAccess;
BEGIN
     FillChar(UserAccess2,SizeOf(UserAccess2),0);
     UserAccess2.time            := 3600;
     UserAccess2.ratio_start     := 2048000;
     UserAccess2.first_menu      := '#MAIN.MNU';
     UserAccess2.daily_bytes     := 1024000;
     UserAccess2.ul_credit       := 50;
     UserAccess2.page            := 1;
     UserAccess2.verified        := 0;
     UserAccess2.QWKBytes        := 512000;
     UserAccess2.QWKMessages     := 600;
     UserAccess2.QWKFree         := 1;
     UserAccess2.NoFileRatio     := 1;
     ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
     RESET(FUserAccess);
     SEEK(FUserAccess,FileSize(FUserAccess));
     WRITE(FUserAccess,UserAccess2);
     CLOSE(FUserAccess);
END;


PROCEDURE DoAccessLevels;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
BEGIN
     PickListPerPage  := 16;
     PickItem         := 1;
     PickTop          := 1;
     CheckFile('ACCESS.DAT');
     ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
     RESET(FUserAccess);
     PickListItems := FileSize(FUserAccess);
     CLOSE(FUserAccess);
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Profile Name',41);
     PickList_B_Title := 'Numeric   ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
     RESET(FUserAccess);
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     REPEAT
           Read(FUserAccess,UserAccess);
           PickListFile.A := _PadRight(UserAccess.Name,30);
           PickListFile.B := _String(UserAccess.Access_Level);
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FUserAccess);
     CLOSE(FUserAccess);
     CLOSE(FPickListFile);
     SetUpPickList('ACCESS PROFILE EDITOR');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN                      {EDIT}
                     EditAccess(PickItem);
                     ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
                     RESET(FUserAccess);
                     PickListItems := FileSize(FUserAccess);
                     CLOSE(FUserAccess);
                     ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
                     RESET(FUserAccess);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FUserAccess,UserAccess);
                           PickListFile.A := _PadRight(UserAccess.Name,30);
                           PickListFile.B := _String(UserAccess.Access_Level);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FUserAccess);
                     CLOSE(FUserAccess);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN                      {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteAccess(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
                          RESET(FUserAccess);
                          PickListItems := FileSize(FUserAccess);
                          CLOSE(FUserAccess);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
                          RESET(FUserAccess);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          REPEAT
                                Read(FUserAccess,UserAccess);
                                PickListFile.A := _PadRight(UserAccess.Name,30);
                                PickListFile.B := _String(UserAccess.Access_Level);
                                WRITE(FPickListFile,PickListFile);
                          UNTIL EOF(FUserAccess);
                          CLOSE(FUserAccess);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN                      {INSERT}
                     InsertAccess(PickItem);
                     EditAccess(PickItem);
                     ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
                     RESET(FUserAccess);
                     PickListItems := FileSize(FUserAccess);
                     CLOSE(FUserAccess);
                     ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
                     RESET(FUserAccess);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FUserAccess,UserAccess);
                           PickListFile.A := _PadRight(UserAccess.Name,30);
                           PickListFile.B := _String(UserAccess.Access_Level);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FUserAccess);
                     CLOSE(FUserAccess);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     AddAccess;
                     EditAccess(PickListItems+1);
                     ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
                     RESET(FUserAccess);
                     PickListItems := FileSize(FUserAccess);
                     CLOSE(FUserAccess);
                     ASSIGN(FUserAccess,BaseDirectory+'\DATA\ACCESS.DAT');
                     RESET(FUserAccess);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FUserAccess,UserAccess);
                           PickListFile.A := _PadRight(UserAccess.Name,30);
                           PickListFile.B := _String(UserAccess.Access_Level);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FUserAccess);
                     CLOSE(FUserAccess);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           6:   ;
           45:  BEGIN                      {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE DoNewUser;
BEGIN
     CheckFile('SYSTEM.DAT');
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     RESET(FSystem_Info);
     READ(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     DrawWindow(14,7,60,14,'NEW CALLER SETTINGS',True);
     AddObject(50,9 ,2,5 ,_String(System_Info.Access_New_User),True);
     AddObject(50,10,6,3 ,FromBoolean(System_Info.Alias_System),True);
     AddButton(50,12,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(16,9 ); WRITE('      Access Level For New Users');
     GotoXY(16,10); WRITE('   Permit The Use Of Alias Names');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     System_Info.Access_New_User := Numeric(Objects^[1].Stuff,WordInteger);
     System_Info.Alias_System    := ToBoolean(Objects^[2].Stuff);
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     REWRITE(FSystem_Info);
     WRITE(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
END;


FUNCTION EditVerifiedUsers(Number: Longint): Boolean;
VAR  Loop    : Word;
     DoAgain : Boolean;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
     RESET(FVerifier);
     SEEK(FVerifier,Number-1);
     READ(FVerifier,Verifier);
     CLOSE(FVerifier);
     DrawWindow(35,9,78,16,'EDIT VERIFIED USER',True);
     AddObject(46,11,1,30,Verifier.Name,True);
     AddObject(46,12,1,20,Verifier.Number,True);
     AddButton(68,14,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(37,11); WRITE('   User');
     GotoXY(37,12); WRITE(' Number');
     _ShowMouse;
     DoObjects;
     IF Escaped THEN DoAgain := False
                ELSE DoAgain := True;
     ClearObjects;
     ClearButtons;
     Verifier.Name   := Objects^[1].Stuff;
     Verifier.Number := Objects^[2].Stuff;
     ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
     RESET(FVerifier);
     SEEK(FVerifier,Number-1);
     WRITE(FVerifier,Verifier);
     CLOSE(FVerifier);
     LoadWindow(WorkDir+'\EDITACC.SCR');
     EditVerifiedUsers := DoAgain;
END;


PROCEDURE InsertVerifiedUsers(Number: Longint);
VAR  Counting : Longint;
BEGIN
     ASSIGN(FVerifier2,BaseDirectory+'\DATA\VERIFY.DAT');
     RENAME(FVerifier2,BaseDirectory+'\DATA\VERIFY.BAK');
     ASSIGN(FVerifier2,BaseDirectory+'\DATA\VERIFY.BAK');
     ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
     RESET(FVerifier2);
     REWRITE(FVerifier);
     Counting := 0;
     REPEAT
           READ(FVerifier2,Verifier);
           INC(Counting);
           IF Counting=Number THEN WRITE(FVerifier,Verifier2);
           WRITE(FVerifier,Verifier);
     UNTIL EOF(FVerifier2);
     CLOSE(FVerifier);
     CLOSE(FVerifier2);
     ERASE(FVerifier2);
END;


PROCEDURE DeleteVerifiedUsers(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\VERIFY.DAT',SizeOf(Verifier),Number);
END;


PROCEDURE AddVerifiedUsers;
BEGIN
     ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
     RESET(FVerifier);
     SEEK(FVerifier,FileSize(FVerifier));
     WRITE(FVerifier,Verifier2);
     CLOSE(FVerifier);
END;


PROCEDURE DoVerifiedUsers;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
BEGIN
     PickListPerPage  := 16;
     PickItem         := 1;
     PickTop          := 1;
     CheckFile('VERIFY.DAT');
     ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
     RESET(FVerifier);
     PickListItems := FileSize(FVerifier);
     CLOSE(FVerifier);
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' User Name',41);
     PickList_B_Title := ' Number   ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
     RESET(FVerifier);
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     REPEAT
           Read(FVerifier,Verifier);
           PickListFile.A := Verifier.Name;
           PickListFile.B := Verifier.Number;
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FVerifier);
     CLOSE(FVerifier);
     CLOSE(FPickListFile);
     SetUpPickList('VERIFIED USERS (VIA CBV)');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN                      {EDIT}
                     EditVerifiedUsers(PickItem);
                     ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
                     RESET(FVerifier);
                     PickListItems := FileSize(FVerifier);
                     CLOSE(FVerifier);
                     ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
                     RESET(FVerifier);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FVerifier,Verifier);
                           PickListFile.A := Verifier.Name;
                           PickListFile.B := Verifier.Number;
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FVerifier);
                     CLOSE(FVerifier);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN                      {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteVerifiedUsers(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
                          RESET(FVerifier);
                          PickListItems := FileSize(FVerifier);
                          CLOSE(FVerifier);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
                          RESET(FVerifier);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          REPEAT
                                Read(FVerifier,Verifier);
                                PickListFile.A := Verifier.Name;
                                PickListFile.B := Verifier.Number;
                                WRITE(FPickListFile,PickListFile);
                          UNTIL EOF(FVerifier);
                          CLOSE(FVerifier);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN                      {INSERT}
                     InsertVerifiedUsers(PickItem);
                     EditVerifiedUsers(PickItem);
                     ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
                     RESET(FVerifier);
                     PickListItems := FileSize(FVerifier);
                     CLOSE(FVerifier);
                     ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
                     RESET(FVerifier);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FVerifier,Verifier);
                           PickListFile.A := Verifier.Name;
                           PickListFile.B := Verifier.Number;
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FVerifier);
                     CLOSE(FVerifier);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     AddVerifiedUsers;
                     EditVerifiedUsers(PickListItems+1);
                     ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
                     RESET(FVerifier);
                     PickListItems := FileSize(FVerifier);
                     CLOSE(FVerifier);
                     ASSIGN(FVerifier,BaseDirectory+'\DATA\VERIFY.DAT');
                     RESET(FVerifier);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FVerifier,Verifier);
                           PickListFile.A := Verifier.Name;
                           PickListFile.B := Verifier.Number;
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FVerifier);
                     CLOSE(FVerifier);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           6:   ;
           45:  BEGIN                      {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE DoSystemNames;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     CheckFile('NAMES.DAT');
     ASSIGN(FNames,BaseDirectory+'\DATA\NAMES.DAT');
     RESET(FNames);
     READ(FNames,Names);
     CLOSE(FNames);
     {LASTCALL.*}
     Toggle[1].Flips   := 2;
     Toggle[1].Current := Names.LastCall+1;
     Toggle[1].Flip[1] := 'Real Name';
     Toggle[1].Flip[2] := 'Alias Name';
     {LASTCOMM.*}
     Toggle[2].Flips   := 2;
     Toggle[2].Current := Names.LastComm+1;
     Toggle[2].Flip[1] := 'Real Name';
     Toggle[2].Flip[2] := 'Alias Name';
     {PAGEUSER.*}
     Toggle[3].Flips   := 2;
     Toggle[3].Current := Names.PageUser+1;
     Toggle[3].Flip[1] := 'Real Name';
     Toggle[3].Flip[2] := 'Alias Name';
     {URPAGED.*}
     Toggle[4].Flips   := 2;
     Toggle[4].Current := Names.UrPaged+1;
     Toggle[4].Flip[1] := 'Real Name';
     Toggle[4].Flip[2] := 'Alias Name';
     {USERLIST.*}
     Toggle[5].Flips   := 2;
     Toggle[5].Current := Names.UserList+1;
     Toggle[5].Flip[1] := 'Real Name';
     Toggle[5].Flip[2] := 'Alias Name';
     DrawWindow(8,5,73,15,'NAMES FOR SYSTEM SCREENS',True);
     AddObject(50,7,8,20,'1',True);
     AddObject(50,8,8,20,'2',True);
     AddObject(50,9,8,20,'3',True);
     AddObject(50,10,8,20,'4',True);
     AddObject(50,11,8,20,'5',True);
     AddButton(63,13,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(11,7);  WRITE('     Last Callers Screen (LASTCALL.*)');
     GotoXY(11,8);  WRITE('Comment From Last Caller (LASTCOMM.*)');
     GotoXY(11,9);  WRITE('    List Of Online Users (PAGEUSER.*)');
     GotoXY(11,10); WRITE('      User Is Being Paged (URPAGED.*)');
     GotoXY(11,11); WRITE('    The User List Screen (USERLIST.*)');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     Names.LastCall := Toggle[1].Current-1;
     Names.LastComm := Toggle[2].Current-1;
     Names.PageUser := Toggle[3].Current-1;
     Names.UrPaged  := Toggle[4].Current-1;
     Names.UserList := Toggle[5].Current-1;
     ASSIGN(FNames,BaseDirectory+'\DATA\NAMES.DAT');
     REWRITE(FNames);
     WRITE(FNames,Names);
     CLOSE(FNames);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DoFindUser;
VAR  Temp         : String;
     LLoop        : Word;
     FUserRecord3 : File Of _UsersBBS_Record;
     UserRecord3  : _UsersBBS_Record;
LABEL               PassIt;
BEGIN
     _SaveWindow(WorkDir+'\FINDUSER.SCR');
     DrawWindow(20,8,60,14,'USER SEARCH STRING',True);
     AddObject(25,10,1,30,'',True);
     AddButton(50,12,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     DoObjects;
     ClearObjects;
     ClearButtons;
     Temp := _UpperCase(Objects^[1].Stuff);
     LoadWindow(WorkDir+'\FINDUSER.SCR');
     IF Temp<>'' THEN
     BEGIN
          LLoop := 0;
          ASSIGN(FUserRecord3,BaseDirectory+'\DATA\USERS.BBS');
          RESET(FUserRecord3);
          READ(FUserRecord3,UserRecord3);
          REPEAT
                READ(FUserRecord3,UserRecord3);
                INC(LLoop);
                IF ((Pos(Temp,_UpperCase(UserRecord3.Name))<>0) OR
                   (Pos(Temp,_UpperCase(UserRecord3.Alias))<>0) OR
                   (Pos(Temp,_UpperCase(UserRecord3.Data))<>0) OR
                   (Pos(Temp,_UpperCase(UserRecord3.Voice))<>0)) THEN
                BEGIN
                     IF NOT(EditUser(LLoop)) THEN GOTO PassIt;
                END;
          UNTIL EOF(FUserRecord3);
          PassIt:
          CLOSE(FUserRecord3);
     END;
END;


PROCEDURE SearchVerifiedUsers;
VAR  Temp         : String;
     LLoop        : Word;
     FVerifier3   : File Of _VerifyLog_Record;
     Verifier3    : _VerifyLog_Record;
LABEL               PassIt;
BEGIN
     _SaveWindow(WorkDir+'\FINDUSER.SCR');
     DrawWindow(20,8,60,14,'USER/PHONE SEARCH STRING',True);
     AddObject(25,10,1,30,'',True);
     AddButton(50,12,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     DoObjects;
     ClearObjects;
     ClearButtons;
     Temp := _UpperCase(Objects^[1].Stuff);
     LoadWindow(WorkDir+'\FINDUSER.SCR');
     IF Temp<>'' THEN
     BEGIN
          LLoop := 0;
          ASSIGN(FVerifier3,BaseDirectory+'\DATA\VERIFY.DAT');
          RESET(FVerifier3);
          REPEAT
                READ(FVerifier3,Verifier3);
                INC(LLoop);
                IF ((Pos(Temp,_UpperCase(Verifier3.Name))<>0) OR
                   (Pos(Temp,_UpperCase(Verifier3.Number))<>0)) THEN
                BEGIN
                     IF NOT(EditVerifiedUsers(LLoop)) THEN GOTO PassIt;
                END;
          UNTIL EOF(FVerifier3);
          PassIt:
          CLOSE(FVerifier3);
     END;
END;


END.
