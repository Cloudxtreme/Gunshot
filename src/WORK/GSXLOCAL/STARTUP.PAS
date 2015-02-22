{$I DEFINES.INC}
UNIT StartUp;


INTERFACE


PROCEDURE FireUpSystem;
PROCEDURE Intro;


IMPLEMENTATION


USES Globals,UserFile,Screens,KeyInput,Gr2_Bp,_Fields,Report,Gx2_Bp,
     Gx2_BpVC,Tx2_Bp,DoFreqs,BsGraph,ErrorLog,_Virtual,_Images,_Icons,
     _Win,_Mouse,SysScrn,MsgSrch2,FileSrch,ListFile,Crt,ApTimer,ExtDos,
     AllGone,BsMulti,Dos,_Extern,_Buffers,SBuffer,BsLog,GotKeys,CDs,
     Time,NodeFile,Reload,Execute,Calls,FilHeadr,MsgHeadr,DoorFile,
     HeapVars,CheckUsr,Version,BsFile,BsString,BsTime,KeyCheck;


VAR  NodeSelected : Boolean;
     ModeSelected : Word;


PROCEDURE new_user;
VAR  Work       : Word;
     OldPW      : String;
LABEL             OverAgain1,OverAgain2;
BEGIN
     OldPW := UserRecord.Password;
     FillChar(UserRecord,SizeOf(UserRecord),0);
     SetUsersAccessDefaults(system_info.access_new_user);
     UserRecord.Password := OldPw;
     UserRecord.name := user_name;
     UserRecord.user_number := new_user_number;
     UserRecord.Birth := '000000';
     ASSIGN(FNewUserVga,LANG_Directory+'\NEWUSER.VGA');
     RESET(FNewUserVga);
     REPEAT
           READ(FNewUserVga,NewUserVga);
           IF _FileExists(SGDirectory+'\'+NewUserVga.FileName+'.SG') THEN
           BEGIN
               FillChar(Fields^,SizeOf(Fields^),0);
               OverAgain1:
               DisplayGraphicFile(NewUserVga.FileName,False,True,True);
               OverAgain2:
               Get_Enter;
               FOR Work := 1 TO NFields DO
               BEGIN
                    IF Fields^[Work].Text='' THEN
                    BEGIN
                         HideTheMouse;
                         ChangeField(Work);
                         ShowTheMouse;
                         GOTO OverAgain2;
                    END;
                    IF Fields^[Work].EntryType=2 THEN
                    BEGIN
                         IF AliasExists THEN
                         BEGIN
                              DisplayGraphicFile('QUEST2',False,True,True);
                              Get_Enter;
                              GOTO OverAgain1;
                         END;
                    END;
               END;
          END;
     UNTIL EOF(FNewUserVga);
     CLOSE(FNewUserVga);
     WriteNewUser;
     DoNewUserReport;
END;


PROCEDURE SetDefaultPalette;
VAR  Ct : Word;
BEGIN
     gxGetConvertPalette(GxPAL5,@P256);
     Ct    := 0;
     {Basic Palette}
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     {Purple}
     P256[Ct] := 15; INC(ct);  P256[Ct] := 3;  INC(ct);  P256[Ct] := 12; INC(ct);
     P256[Ct] := 18; INC(ct);  P256[Ct] := 6;  INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 9;  INC(ct);  P256[Ct] := 18; INC(ct);
     P256[Ct] := 24; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 28; INC(ct);  P256[Ct] := 16; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 32; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 29; INC(ct);
     P256[Ct] := 36; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 33; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 28; INC(ct);  P256[Ct] := 37; INC(ct);
     P256[Ct] := 44; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 41; INC(ct);
     P256[Ct] := 48; INC(ct);  P256[Ct] := 36; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 52; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 49; INC(ct);
     P256[Ct] := 56; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 53; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 46; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 60; INC(ct);  P256[Ct] := 48; INC(ct);  P256[Ct] := 57; INC(ct);
     P256[Ct] := 62; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 59; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 54; INC(ct);  P256[Ct] := 60; INC(ct);
     {Blues}
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 18; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 23; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 28; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 33; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 38; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 43; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 48; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 53; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 58; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 8;  INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     {Dusty Blues}
     P256[Ct] := 7;  INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 31; INC(ct);
     P256[Ct] := 12; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 41; INC(ct);
     P256[Ct] := 17; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 41; INC(ct);
     P256[Ct] := 22; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 46; INC(ct);
     P256[Ct] := 27; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 51; INC(ct);
     P256[Ct] := 32; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 56; INC(ct);
     P256[Ct] := 37; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 61; INC(ct);
     P256[Ct] := 41; INC(ct);  P256[Ct] := 48; INC(ct);  P256[Ct] := 63; INC(ct);

     P256[Ct] := 15; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 31; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 5; INC(ct);  P256[Ct] := 22; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 10; INC(ct);  P256[Ct] := 27; INC(ct);  P256[Ct] := 5; INC(ct);
     P256[Ct] := 15; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 37; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 47; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 57; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 62; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 5; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 26; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 34; INC(ct);
     P256[Ct] := 18; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 43; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 48; INC(ct);
     P256[Ct] := 52; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 54; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 34; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 38; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 46; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 54; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 62; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 22; INC(ct);  P256[Ct] := 22; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 32; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 43; INC(ct);  P256[Ct] := 43; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 52; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 57; INC(ct);  P256[Ct] := 57; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 9; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 14; INC(ct);  P256[Ct] := 5; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 19; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 29; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 34; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 39; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 60; INC(ct);  P256[Ct] := 49; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 43; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 48; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 57; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 29; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 37; INC(ct);  P256[Ct] := 16; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 41; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 48; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 53; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 56; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 3; INC(ct);
     P256[Ct] := 59; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 6; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 28; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 38; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 43; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 49; INC(ct);  P256[Ct] := 18; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 54; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 56; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 58; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 60; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 41; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 52; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 43; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 27; INC(ct);
     P256[Ct] := 46; INC(ct);  P256[Ct] := 1; INC(ct);  P256[Ct] := 29; INC(ct);
     P256[Ct] := 53; INC(ct);  P256[Ct] := 2; INC(ct);  P256[Ct] := 34; INC(ct);
     P256[Ct] := 59; INC(ct);  P256[Ct] := 8; INC(ct);  P256[Ct] := 36; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 41; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 44; INC(ct);
     P256[Ct] := 62; INC(ct);  P256[Ct] := 31; INC(ct);  P256[Ct] := 47; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 49; INC(ct);
     P256[Ct] := 62; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 56; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 49; INC(ct);  P256[Ct] := 60; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 5;  INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 60; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 58; INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 17; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 10; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 15; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 5;  INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 60; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 45; INC(ct);
     {Grays}
     P256[Ct] := 2;  INC(ct);  P256[Ct] := 2;  INC(ct);  P256[Ct] := 2;  INC(ct);
     P256[Ct] := 5;  INC(ct);  P256[Ct] := 5;  INC(ct);  P256[Ct] := 5;  INC(ct);
     P256[Ct] := 8;  INC(ct);  P256[Ct] := 8;  INC(ct);  P256[Ct] := 8;  INC(ct);
     P256[Ct] := 10; INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 12; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 12; INC(ct);
     P256[Ct] := 14; INC(ct);  P256[Ct] := 14; INC(ct);  P256[Ct] := 14; INC(ct);
     P256[Ct] := 16; INC(ct);  P256[Ct] := 16; INC(ct);  P256[Ct] := 16; INC(ct);
     P256[Ct] := 18; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 18; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 22; INC(ct);  P256[Ct] := 22; INC(ct);  P256[Ct] := 22; INC(ct);
     P256[Ct] := 24; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 24; INC(ct);
     P256[Ct] := 26; INC(ct);  P256[Ct] := 26; INC(ct);  P256[Ct] := 26; INC(ct);
     P256[Ct] := 28; INC(ct);  P256[Ct] := 28; INC(ct);  P256[Ct] := 28; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 32; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 32; INC(ct);
     P256[Ct] := 34; INC(ct);  P256[Ct] := 34; INC(ct);  P256[Ct] := 34; INC(ct);
     P256[Ct] := 36; INC(ct);  P256[Ct] := 36; INC(ct);  P256[Ct] := 36; INC(ct);
     P256[Ct] := 38; INC(ct);  P256[Ct] := 38; INC(ct);  P256[Ct] := 38; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 44; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 44; INC(ct);
     P256[Ct] := 46; INC(ct);  P256[Ct] := 46; INC(ct);  P256[Ct] := 46; INC(ct);
     P256[Ct] := 48; INC(ct);  P256[Ct] := 48; INC(ct);  P256[Ct] := 48; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 52; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 52; INC(ct);
     P256[Ct] := 54; INC(ct);  P256[Ct] := 54; INC(ct);  P256[Ct] := 54; INC(ct);
     P256[Ct] := 56; INC(ct);  P256[Ct] := 56; INC(ct);  P256[Ct] := 56; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 58; INC(ct);  P256[Ct] := 58; INC(ct);
     P256[Ct] := 61; INC(ct);  P256[Ct] := 61; INC(ct);  P256[Ct] := 61; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     gxSetConvertPalette(GxPAL5,@P256);
     GxSetDisplayPalette(@P256);
     {Grayscale palette}
     FillChar(G256,SizeOf(G256),0);
     FOR Ct := 678 TO 767 DO G256[Ct] := P256[Ct];
END;


PROCEDURE LoadGraphicsSystem;
VAR  Error : Integer;
BEGIN
     GxSetBuffer(@GFXBuffer^,SizeOf(GFXBuffer^));
     GraphicsMode_BS(256,ModeSelected,True,True);
     IF NOT(GraphicsInitialized) THEN
     BEGIN
          DoErrorLog(101,'');
          Halt;
     END;
     YWindow := GraphMaxY-50;
     SetDefaultPalette;
     CreateVirtual(IconHdr,30,30,TheDisplay);
     CreateVirtual(OffScreen,GraphMaxX+1,YWindow+1,TheDisplay);
     CreateVirtual(WindowBack,GraphMaxX+1,YWindow+1,TheDisplay);
     GrSetClipRegion(0,0,GraphMaxX,GraphMaxY); GrSetClipping(GrClip);
     TxSetClipRegion(0,0,GraphMaxX,GraphMaxY); TxSetClipping(TxClip);
     Fade_Off;
     gxOpenLib(gxGXL,GraphicsLibrary,GraphLib,Nil,0);
     txLibFont(gxCMM,GraphLib,'GUI_____.GFT',SystemFont);
     txLibFont(gxCMM,GraphLib,'HELV____.GFT',HelvFont);
     txLibFont(gxCMM,GraphLib,'ROMAN___.GFT',RomanFont);
     txLibFont(gxCMM,GraphLib,'BIT8X16.GFT',BitFont8x16);
     txLibFont(gxCMM,GraphLib,'BIT8X14.GFT',BitFont8x14);
     txLibFont(gxCMM,GraphLib,'BIT8X8.GFT',BitFont8x8);
     gxCloseLib(GraphLib);
     txSetFont(SystemFont);
     {Draw the sysop bar}
     GrSetFillStyle(GrFSolid,7,GrOpaque);
     GrDrawRect(0,YWindow+1,GraphMaxX,GraphMaxY,GrFill);
     GrSetColor(15); GrDrawLine(0,YWindow+1,GraphMaxX,YWindow+1);
     GrSetColor(8);  GrDrawLine(0,GraphMaxY,GraphMaxX,GraphMaxY);
     LoadGraphicLib('YAPP____.$$$',GraphMaxX-180,GraphMaxY-40,GraphMaxX,GraphMaxY-2);
     IF NodeInfo^.UseBlaster THEN SystemIcon(GraphMaxX-174,GraphMaxY-38,73);
     SystemIcon(10,YWindow+10,81);
     SystemIcon(45,YWindow+10,90);
     RaisedBox(9,YWindow+9,41,YWindow+41);
     RaisedBox(44,YWindow+9,76,YWindow+41);
     IF NOT(InitTheMouse) THEN
     BEGIN
          DoErrorLog(104,'');
          Halt;
     END;
     ASSIGN(FMouse,Shotgun_Directory+'\ICONS\DEFAULT.MSE');
     {$I-}
     RESET(FMouse);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          READ(FMouse,DefaultMouse);
          CLOSE(FMouse);
     END;
     ASSIGN(FMouse,Shotgun_Directory+'\ICONS\BUSY.MSE');
     {$I-}
     RESET(FMouse);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          READ(FMouse,BusyMouse);
          CLOSE(FMouse);
     END;
     ASSIGN(FMouse,Shotgun_Directory+'\ICONS\INSERT.MSE');
     {$I-}
     RESET(FMouse);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          READ(FMouse,InsertMouse);
          CLOSE(FMouse);
     END;
     ASSIGN(FMouse,Shotgun_Directory+'\ICONS\BPRESS.MSE');
     {$I-}
     RESET(FMouse);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          READ(FMouse,BPressMouse);
          CLOSE(FMouse);
     END;
     ASSIGN(FMouse,Shotgun_Directory+'\ICONS\MSGDRAG.MSE');
     {$I-}
     RESET(FMouse);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          READ(FMouse,MsgDragMouse);
          CLOSE(FMouse);
     END;
     ASSIGN(FMouse,Shotgun_Directory+'\ICONS\FILEDRAG.MSE');
     {$I-}
     RESET(FMouse);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          READ(FMouse,FileDragMouse);
          CLOSE(FMouse);
     END;
     ASSIGN(FMouse,Shotgun_Directory+'\ICONS\WINMOVE.MSE');
     {$I-}
     RESET(FMouse);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          READ(FMouse,WinMoveMouse);
          CLOSE(FMouse);
     END;
     ShowTheMouse;
     ChangeMouse(DefaultMouse);
     Fade_In;
END;


PROCEDURE DoOpeningFile;
BEGIN
     ASSIGN(FOpening,LANG_Directory+'\OPENING.DAT');
     RESET(FOpening);
     REPEAT
           READ(FOpening,Opening);
           CASE Opening.FunctionType OF
           1:   ShowLastComment;
           2:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',126);
                          IF GET_YES_NO=true THEN Do_Welcome;
                     END;
                1:   do_welcome;
                END;
           3:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',127);
                          IF GET_YES_NO=true THEN Do_Once_Only;
                     END;
                1:   do_once_only;
                END;
           4:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',128);
                          IF GET_YES_NO=true THEN Do_News;
                     END;
                1:   do_news;
                END;
           5:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',129);
                          IF GET_YES_NO=true THEN show_last_Callers;
                     END;
                1:   show_last_Callers;
                END;
           6:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',118);
                          IF GET_YES_NO=true THEN
                          BEGIN
                               CurrentMessageSub := 0;
                               New_Mail_Logon;
                               CurrentMessageSub := 1;
                          END;
                     END;
                1:   BEGIN
                          CurrentMessageSub := 0;
                          New_Mail_Logon;
                          CurrentMessageSub := 1;
                     END;
                END;
           7:   CASE Opening.Forced OF
                0:   BEGIN
                          IF UserRecord.Total_Calls<>0 THEN
                          BEGIN
                               System_Prompt('',117);
                               IF GET_YES_NO=true THEN
                               BEGIN
                                    CurrentFileSub := 0;
                                    search_new(True);
                                    List_Files(NODE_Directory+'\SEARCH$$');
                                    CurrentFileSub := 1;
                               END;
                          END;
                     END;
                1:   BEGIN
                          IF UserRecord.Total_Calls<>0 THEN
                          BEGIN
                               CurrentFileSub := 0;
                               search_new(True);
                               List_Files(NODE_Directory+'\SEARCH$$');
                               CurrentFileSub := 1;
                          END;
                     END;
                END;
           9:   show_user_specific;
           10:  do_user_access;
           11:  do_date_specific;
           12:  do_birthday;
           END;
     UNTIL EOF(FOpening);
     CLOSE(FOpening);
END;


PROCEDURE CantDoIt(TheOne: Longint);
BEGIN
     DoErrorLog(40,_String(TheOne));
     TextMode(co80);
     TEXTCOLOR(7);
     ClrScr;
     WRITELN('CRITICAL ERROR!!! Shotgun can only handle 255 lines!');
     WRITELN;
     Halt;
END;


PROCEDURE Hey;
BEGIN
     DoErrorLog(39,'');
     TextMode(co80);
     ClrScr;
     TEXTCOLOR(10);
     WRITELN('This program is a component of the Shotgun Professional package.');
     WRITELN('You do not directly execute this program manually yourself.');
     TEXTCOLOR(7);
     WRITELN;
     Halt;
END;


PROCEDURE get_params;
VAR  loop         : word;
     parameters   : array[1..10] of string[10];
     param        : char;
     code         : integer;
     Before       : String;
BEGIN
     NodeNumber     := 1;
     NodeSelected   := False;
     SysopLogon     := False;
     EventMinutes   := 32000; {No Event}
     ModeSelected   := 640;
     DoQuickLogon   := False;
     LogonUser      := 999999999;
     IF (ParamStr(1)<>'$$BB$$SS') THEN Hey;
     FOR loop := 2 TO paramcount DO
     BEGIN
          parameters[loop] := paramstr(loop);
          IF ((parameters[loop,1]='-') OR (parameters[loop,1]='/')) THEN
          BEGIN
               DELETE(parameters[loop],1,1);
               IF _UpperCase(parameters[loop])='SYSOP' THEN
               BEGIN
                    SysopLogon := true;
               END
               ELSE IF _UpperCase(parameters[loop])='NOROM' THEN
               BEGIN

               END
               ELSE IF _UpperCase(parameters[loop])='QUICK' THEN
               BEGIN
                    DoQuickLogon := True;
               END
               ELSE IF _UpperCase(parameters[loop])='640' THEN
               BEGIN
                    ModeSelected := 640;
               END
               ELSE IF _UpperCase(parameters[loop])='800' THEN
               BEGIN
                    ModeSelected := 800;
               END
               ELSE IF _UpperCase(parameters[loop])='1024' THEN
               BEGIN
                    ModeSelected := 1024;
               END
               ELSE
               BEGIN
                    Before := parameters[loop];
                    param := parameters[loop,1];
                    DELETE(parameters[loop],1,1);
                    CASE Upcase(param) OF
{BAUD}              'B' : ;
{NODE NUMBER}       'N' : BEGIN
                               VAL(parameters[loop],NodeNumber,code);
                               Str(NodeNumber,NodeString);
                               NodeSelected := True;
                          END;
{EVENT PENDING}     'E' : VAL(parameters[loop],EventMinutes,code);
{FAST USER LOGON}   'U' : VAL(parameters[loop],LogonUser,code);
                    ELSE  DoErrorLog(39,Before);
                    END;
               END;
          END;
     END;
     IF (EventMinutes<>32000) THEN
     BEGIN
          BigCrap := EventMinutes;
          BigCrap := BigCrap*60;
          NewTimerSecs(EventTicker,BigCrap);
     END;
END;


PROCEDURE defines;
VAR  Loop       : Word;
     Temp       : String;
BEGIN
     LoadHeapVars;
     FillChar(UserRecord,SizeOf(UserRecord),0);
     tagged                := 0;
     user_name             := '';
     full_day              := 24;
     full_day              := full_day*60;
     full_day              := full_day*60;
     user_pages            := 0;
     time_for_downloads    := 0;
     DATA_Directory        := Shotgun_Directory+'\DATA';
     INTR_Directory        := Shotgun_Directory+'\INTRNODE';
     BIN_Directory         := Shotgun_Directory+'\BIN';
     GraphicsLibrary       := BIN_Directory+'\GUI.GXL';
     LastFont              := '$%@$#^!%sf@$';
     ASSIGN(FSystemInfo,DATA_Directory+'\SYSTEM.DAT');
     RESET(FSystemInfo);
     READ(FSystemInfo,system_info);
     CLOSE(FSystemInfo);
     _CreatePath(INTR_Directory);
     IF NodeSelected=False THEN
     BEGIN
          DoErrorLog(38,'');
          TEXTCOLOR(7);
          ClrScr;
          WRITELN('CRITICAL ERROR!!! No node number was specified. Please use the');
          WRITELN('command switch -Nxx (where xx is the node number you wish to use)');
          WRITELN;
          Halt;
     END;
     IF System_Info.NodeDrive='' THEN
     BEGIN
          NODE_Directory := Shotgun_Directory+'\NODE'+NodeString;
     END
     ELSE
     BEGIN
          Temp := Shotgun_Directory;
          Delete(Temp,1,1);
          NODE_Directory := System_Info.NodeDrive+Temp+'\NODE'+NodeString;
     END;
     SIG_Directory  := Shotgun_Directory+'\ANSISIGS';
     HOLD_Directory := NODE_Directory+'\HOLDFILE';
     SCAN_Directory := NODE_Directory+'\SCAN_DIR';
     GIP_Directory  := NODE_Directory+'\GIP';
     CD_Directory   := NODE_Directory+'\CD_TEMP';
     RESOURCES      := Shotgun_Directory+'\RESLOCAL\';

     _CreatePath(NODE_Directory);
     _CreatePath(HOLD_Directory);
     _CreatePath(SCAN_Directory);
     _CreatePath(SIG_Directory);
     _CreatePath(BIN_Directory);
     _CreatePath(GIP_Directory);
     _CreatePath(CD_Directory);
     _CreatePath(Shotgun_Directory+'\MSGTAGS');
     _CreatePath(Shotgun_Directory+'\FILETAGS');
END;


PROCEDURE read_system_data;
BEGIN
     ASSIGN(FNodeInfo,DATA_Directory+'\NODES.DAT');
     RESET(FNodeInfo);
     SEEK(FNodeInfo,NodeNumber-1);
     READ(FNodeInfo,NodeInfo^);
     CLOSE(FNodeInfo);
     ASSIGN(FNames,DATA_Directory+'\NAMES.DAT');
     RESET(FNames);
     READ(FNames,Names);
     CLOSE(FNames);
     ASSIGN(FUUCP,DATA_Directory+'\UUCP.DAT');
     RESET(FUUCP);
     READ(FUUCP,UUCP);
     CLOSE(FUUCP);
     ASSIGN(FFreqs,DATA_Directory+'\FREQ.DAT');
     RESET(FFreqs);
     READ(FFreqs,Freqs);
     CLOSE(FFreqs);
     ASSIGN(FArcDefs,DATA_Directory+'\ARCHIVE.DAT');
     RESET(FArcDefs);
     READ(FArcDefs,ArcDefs);
     CLOSE(FArcDefs);
END;


FUNCTION got_all_files: boolean;
VAR  yup        : boolean;
BEGIN
     yup := true;
     IF NOT(_FileExists(DATA_Directory+'\ACCESS.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\ACCESS.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\ARCHIVE.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\ARCHIVE.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\FA000000.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\FA000000.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\FILEAREA.SUB')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\FILEAREA.SUB');
          yup := false;
     END;
     IF NOT(_FileExists(GraphicsLibrary)) THEN
     BEGIN
          DoErrorLog(37,GraphicsLibrary);
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\LANGUAGE.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\LANGUAGE.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\MA000000.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\MA000000.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\MSGAREA.SUB')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\MSGAREA.SUB');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\NAMES.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\NAMES.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\PROTOCOL.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\PROTOCOL.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\SCANNERS.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\SCANNERS.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\SYSTEM.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\SYSTEM.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\USERS.BBS')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\USERS.BBS');
          yup := false;
     END;
     got_all_files := yup;
END;


PROCEDURE FireUpSystem;
VAR  Loop : Word;
     Temp : String;
BEGIN
     GetDir(0,Temp);
     CurrentDrive := Temp[1];
     ClrScr;
     doing_logon  := true;
     doing_logoff := false;
     NodeNumber   := 1;
     STR(NodeNumber,NodeString);
     Temp := _UpperCase(_GetFilePath(ParamStr(0)));
     Shotgun_Directory := Temp[1]+':\SHOTGUN';
     ChDir(shotgun_directory);
     get_params;
     _CreatePath(shotgun_directory+'\NODE'+NodeString);
     IF (NodeNumber>255) THEN CantDoIt(NodeNumber);
     CheckRegistered(shotgun_directory+'\NODE'+NodeString,'Shotgun');
     bsSetLog(OurAppName,'',NodeNumber);
     defines;
     read_system_data;
     clear_dirs;
     IF Got_All_Files=False THEN
     BEGIN
          TextMode(Co80);
          ClrScr;
          TEXTCOLOR(4);
          WRITELN('CRITICAL ERROR!!! Missing a required data file in the '+DATA_Directory+'\');
          WRITELN('directory. Please run SGCONFIG.EXE to correct the problem.');
          WRITELN;
          TEXTCOLOR(7);
          Halt;
     END;
END;


PROCEDURE SelectLanguage;
VAR  TFile : Text;
     Temp  : String;
     Work  : Word;
BEGIN
     ASSIGN(TFile,NODE_Directory+'\LANGUAGE.SEL');
     {$I-}
     RESET(TFile);
     {$I+}
     IF IOResult<>0 THEN Dispatch(8);
     READLN(TFile,Temp);
     CLOSE(TFile);
     Work := _Numeric(Temp);

     ASSIGN(FLangDir,Shotgun_Directory+'\DATA\LANGUAGE.DAT');
     RESET(FLangDir);
     {$I-}
     SEEK(FLangDir,Work-1);
     {$I+}
     IF IOResult<>0 THEN
     BEGIN
          CLOSE(FLangDir);
          Dispatch(8);
     END;
     READ(FLangDir,LangDir);
     CLOSE(FLangDir);

     LanguageDirectory := LangDir.Directory;
     SGDirectory       := LanguageDirectory+'SG';
     LANG_Directory    := LanguageDirectory+'LANG';
     MENU_Directory    := LanguageDirectory+'MENUS';
     NEWS_Directory    := LanguageDirectory+'NEWS';
     ASSIGN(FColours,LANG_Directory+'\COLOURS.VGA');
     RESET(FColours);
     READ(FColours,Colours);
     CLOSE(FColours);
END;


PROCEDURE bbs_header;
VAR  dos_ver : word;
     temp999 : string;
     XShift  : Word;
     YShift  : Word;
     C       : Char;
BEGIN
     CASE Task.Os OF
     0:   multi_tasker := 'DOS';
     1:   multi_tasker := 'Windows';
     2:   multi_tasker := 'OS/2';
     3:   multi_tasker := 'DESQview';
     4:   multi_tasker := 'TopView';
     END;
     multi_tasker := _PadRight(multi_tasker,30);
     HideTheMouse;
     XShift := Trunc((GraphMaxX-639)/2);
     YShift := Trunc((GraphMaxY-479)/2);
     GrSetFillStyle(GrFSolid,0,GrOpaque);
     GrDrawRect(0,0,GraphMaxX,YWindow,GrFill);
     CASE Colours.InternalImage OF
     1:   LoadGraphicLib('BACK____.$$$',1+XShift,1+YShift,639+XShift,YWindow+YShift);
     2:   LoadGraphicLib('OCEAN___.$$$',1+XShift,1+YShift,639+XShift,YWindow+YShift);
     3:   LoadGraphicLib('DESERT__.$$$',1+XShift,1+YShift,639+XShift,YWindow+YShift);
     4:   LoadGraphicLib('PLANET__.$$$',1+XShift,1+YShift,639+XShift,YWindow+YShift);
     END;
     ShowTheMouse;
     IF _FileExists(Shotgun_Directory+'\FLICS\BACKGRND.FLI')
        THEN PlayFLIFile(Shotgun_Directory+'\FLICS\BACKGRND.FLI');
     DisplayGraphicFile('BACKGRND',False,True,True);
     HideTheMouse;
     SaveBackDrop;
     ShowTheMouse;
END;


PROCEDURE CheckLogonAccess(NewUser: Boolean);
BEGIN
     IF NewUser THEN
     BEGIN
          IF NodeInfo^.AllowNewUsers=1 THEN
          BEGIN
               Exit;
          END
          ELSE
          BEGIN
               bsWriteLog('No new users allowed to this node',False);
               DisplayGraphicFile('NONEW',False,True,True);
               Dispatch(5);
          END;
     END
     ELSE
     BEGIN
          IF ((UserRecord.Security>=NodeInfo^.AccessMinimum) AND
             (GotTheKeys(UserRecord.Tags,NodeInfo^.Tags))) THEN
          BEGIN
               IF UserIsAlreadyOnline THEN
               BEGIN
                    bsWriteLog('User is already logged in on another node',False);
                    DisplayGraphicFile('NODOUBLE',False,True,True);
                    Dispatch(5);
               END
               ELSE Exit;
          END
          ELSE
          BEGIN
               bsWriteLog('User doesn''t have high enough access for this node',False);
               DisplayGraphicFile('NOACCESS',False,True,True);
               Dispatch(5);
          END;
     END;
END;


PROCEDURE do_logon;
VAR  bad_pass       : byte;
     old_time_left  : longint;
     c              : Char;
     User_Password  : String;
LABEL                 redo;
BEGIN
     bsWriteLog('User logging on at 0 BPS',False);
     bsWriteLog('Using disk loaded fonts',False);
     bad_pass := 0;
     redo:
     IF ((NOT(SysopLogon)) AND (LogonUser=999999999)) THEN DisplayGraphicFile('PRELOG',false,True,True);
     SuccessfulLogon := False;
     IF (LogonUser<>999999999) THEN
     BEGIN
          User_Name := GetUserName(LogonUser);
     END
     ELSE IF SysopLogon THEN
     BEGIN
          User_Name := system_info.Sysop;
     END
     ELSE
     BEGIN
          User_Name := '';
          REPEAT
                C := GetKeyPress;
                IF C=#13 THEN
                BEGIN
                     user_name     := UserRecord.Name;
                     user_password := UserRecord.Password;
                     IF _UpperCase(user_name)='SYSOP' THEN user_name := '';
                     IF Pos(' ',user_name)=0 THEN
                     BEGIN
                          IF NOT(system_info.alias_system) THEN user_name := '';
                     END;
                END;
          UNTIL ((user_name<>'') AND (User_Password<>''));
     END;
     bsWriteLog('User claims to be '+user_name,False);
     IF UserFound THEN
     BEGIN
          CheckLogonAccess(False);
          old_time_left := UserRecord.SecondsRemaining;
          IF ((SysopLogon) OR (LogonUser<>999999999)) THEN User_Password := UserRecord.password;
          IF User_Password=UserRecord.password THEN
          BEGIN
               INC(UserRecord.total_calls);
               RealLastCall := UserRecord.last_call;
               UserRecord.last_call := _ProperDate;
               bad_pass := 0;
          END
          ELSE
          BEGIN
               INC(bad_pass);
               IF Bad_Pass<>3 THEN
               BEGIN
                    bsWriteLog('Guessing at password',False);
                    System_Prompt('',64);
                    Get_Enter;
                    UserRecord.Password := '';
                    GOTO Redo;
               END
               ELSE
               BEGIN
                    UserRecord.bad_logon := 1;
                    UserRecord.SecondsRemaining := old_time_left;
                    WriteUser;
                    dispatch(6);
               END;
          END;
          IF UserRecord.bad_logon<>0 THEN
          BEGIN
               bsWriteLog('Last logon was unsuccessful',False);
               DisplayGraphicFile('BADLOGON',False,True,True);
               Get_Enter;
          END;
          IF UserRecord.Punt=1 THEN
          BEGIN
               bsWriteLog('User is not allowed on the system',False);
               DisplayGraphicFile('BOOTUSER',False,True,True);
               dispatch(5);
          END;
          UserRecord.bad_logon := 0;
          GetAccessLevelDefaults(UserRecord.Security);
          IF RemoveTime(RealLastCall)<>_ProperDateNoTime THEN
          BEGIN
               UserRecord.SecondsRemaining   := UserAccess.Time;
               UserRecord.DLBytesRemaining   := UserAccess.Daily_Bytes;
               UserRecord.DLBytesToday       := 0;
               UserRecord.TimeBankWithdrawls := 0;
               UserRecord.ByteBankWithdrawls := 0;
               IF UserRecord.SubModel=2 THEN INC(UserRecord.SubCallDaysUsed);
               IF UserRecord.SubModel=1 THEN UserRecord.SubCalendarDaysUsed :=
                                             DaysBetween(UserRecord.SubLastChange,_ProperDateNoTime);
          END;
     END
     ELSE
     BEGIN
          CheckLogonAccess(True);
          System_Prompt(user_name,114);
          IF Get_Yes_No=False THEN
          BEGIN
               bsWriteLog('User is guessing at his/her name. Entered: '+user_name,False);
               UserRecord.Name     := '';
               UserRecord.Password := '';
               GOTO redo;
          END;
          bsWriteLog('New user logging on',False);
          UserRecord.Name := user_name;
          UserRecord.Password := User_Password;
          new_user;
     END;
     DoNodeActivity(0,'');
     LastUserOnline.TimeOn := _GetPrettyDate+' - '+_GetPrettyTime;
     IF UserRecord.SecondsRemaining=0 THEN dispatch(3);
     Subscription;
     doing_logon := false;
     NewTimerSecs(UsersTicker,UserRecord.SecondsRemaining);
     TimeLimit;
     IF Pos(' ',User_Name)=0 THEN user_name := user_name+' NLN';
     SuccessfulLogon := True;
     bsWriteLog('Successful log on as: '+user_name,False);
     IF (EventMinutes<>32000) THEN
     BEGIN
          bsWriteLog('Next event in '+_String(EventMinutes)+' minutes',False);
          bsWriteLog('Event timer set at '+_String(BigCrap),False);
     END;
     IF _FileExists('PRELOG.BAT') THEN
     BEGIN
          DumpUser;
          make_door_files(0,1);
          ExecuteDosCommand('PRELOG.BAT '+NodeString+' 0 0');
          Chdir(Shotgun_Directory);
          ReloadUser;
     END;
END;


PROCEDURE Intro;
BEGIN
     SelectLanguage;
     LoadGraphicsSystem;
     bbs_header;
     bsWriteLog('SVGA interface selected',False);
     do_logon;
     doing_logon := false;
     get_call_totals;
     Header2(1,1,True);
     Header(1,1,True);
     UpdateDlRatio;
     IF NOT(DoQuickLogon) THEN DoOpeningFile;
     CheckYourFreqs;
     StartCDToggle;
     LastMenuLoaded := UserAccess.first_menu;
     redraw_menu := true;
END;


END.
