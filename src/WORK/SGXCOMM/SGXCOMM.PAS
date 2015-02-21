{$IFDEF DPMI}
  NO DPMI!
{$ENDIF}
{$M 60000,0,655360}
PROGRAM ShotgunClientServer;
{$I DEFINES.INC}


USES BsOvr,Extend,Comm,Globals,KeyInput,Startup,LoadMenu,BsLog,NodeFile,
     Time,UserFile,CanMenus,BsFile,MultNode,Screens,ApTimer,ListFile,
     ErrorLog,PageSys,AllGone,CommNext,DosDoor,Special,FilHeadr,MsgHeadr,
     ChangeFA,ChangeMA,Download,Upload,ExtDos,FileID,MsgID,MsgSrch1,
     MsgSrch2,MsgSrch3,MsgSrch4,MsgSrch5,MsgSrch6,WriteMsg,ReadMail,
     KillOld,GotoMsg,ULMsg,Report,SysScrn,FileSrch,ViewTFil,ListMsgs,CBV,
     FileList,UserEdit,ByteBank,TimeBank,ChatFull,CheckSig,ResetLR,QWKDL,
     QWKUL,UserList,GroupMsg,FileBoxs,DEntry,Dial_Out,DoorFile,Crt,Chat,
     BsMulti,Gfx,Carrier,MiscStr,FilGroup,MsgGroup,ChangeMG,ChangeFG,
     GetArc,SaveIt,Gip,FMode,CDRomMan,GetQuote,BsString;


{$I OVRS.INC}


VAR  MainLoop : Byte;
     MainWork : Word;
LABEL           DoItOverAgain;


PROCEDURE do_main_event;
VAR  Find_Option : Word;
     C           : Char;
BEGIN
     CheckForCarrier;
     CurCount := 0;
     WaitingAtMenu := True;
     REPEAT
           C := UpCase(GetKeyPress);
           IF c=#13 THEN
           BEGIN
                C := Chr(0);
                Redraw_Menu := True;
                WaitingAtMenu := False;
                Exit;
           END;
           FOR find_option := 2 TO menu_count DO
           BEGIN
                IF (C=UpCase(Menu^[find_option].HotKey)) THEN
                BEGIN
                     IF MenuActive[find_option] THEN
                     BEGIN
                          INC(CurCount);
                          Reserve[CurCount] := find_option;
                     END;
                END;
           END;
     UNTIL (CurCount<>0);
     WaitingAtMenu := False;
END;


BEGIN
     FileMode := SetFileMode;
     FireUpSystem;
     Check_It := Comm_Init(NodeInfo.ComPort,NodeInfo.ComDevice);
     IF Check_It THEN
     BEGIN
       Intro;
       load_menu(LastMenuLoaded);
       bsWriteLog('Loading menu: '+LastMenuLoaded+' ['+Menu^[1].Title+']',True);
       DoNodeActivity(1,'');
       REPEAT
         DoItOverAgain:
         UpdateDlRatio;
         display_menu;
         do_main_event;
         {Chat with user kludge}
         IF RunTheChat THEN
         BEGIN
           SysopFullChat;
           GOTO DoItOverAgain;
         END;
         {CHECK FOR PAGING}
         CheckIntrNode;
         {CHECK FOR TIME WARNING}
         IF ((NOT(UsersTimeWarning)) AND (MinutesRemaining<=5)) THEN
         BEGIN
           UsersTimeWarning := True;
           System_Prompt('',111);
           Get_Enter;
         END
         ELSE IF MinutesRemaining>5 THEN UsersTimeWarning := False;
         {CHECK FOR EVENT WARNING}
         IF ((NOT(EventTimeWarning)) AND (EventMinutes<>32000)) THEN
         BEGIN
           IF (Round(RemainingTimeInSecs(EventTicker)/60)<=5) THEN
           BEGIN
             EventTimeWarning := True;
             System_Prompt('',120);
             Get_Enter;
           END;
         END;
         redraw_menu := true;
         IF CurCount<>0 THEN
         BEGIN
           FOR MainLoop := 1 TO CurCount DO
           BEGIN
             check_it := true;
             CASE Menu^[Reserve[MainLoop]].Option OF
             1:   BEGIN
                    DoNodeActivity(1,'');
                    IF _FileExists(MENU_Directory+'\'+Menu^[Reserve[MainLoop]].Second) THEN
                    BEGIN
                      load_menu(Menu^[Reserve[MainLoop]].Second);
                      bsWriteLog('Loading menu: '+LastMenuLoaded+' ['+Menu^[1].Title+']',True);
                    END
                    ELSE DoErrorLog(12,MENU_Directory+'\'+Menu^[Reserve[MainLoop]].Second);
                  END;
             2:   BEGIN
                    DoNodeActivity(2,'');
                    page;
                  END;
             3:   BEGIN
                    DoNodeActivity(3,'');
                    dispatcher(1);
                  END;
             4:   BEGIN
                    DoNodeActivity(3,'');
                    System_Prompt('',177);
                    IF Get_Yes_No=True THEN
                    BEGIN
                      DisplayGraphicFile('GOODBYE',false,True,True);
                      dispatcher(0);
                    END;
                  END;
             5:   BEGIN
                    DoNodeActivity(4,'');
                    CommentToNextCaller;
                  END;
             6:   BEGIN
                    bsWriteLog('Viewing screen: '+SGDirectory+'\'+Menu^[Reserve[MainLoop]].Second,True);
                    DoNodeActivity(5,'');
                    IF Menu^[Reserve[MainLoop]].Third='YES' THEN
                    BEGIN
                      IF DisplayGraphicFile(Menu^[Reserve[MainLoop]].Second,false,True,True) THEN Get_Enter;
                    END
                    ELSE
                    BEGIN
                      IF DisplayGraphicFile(Menu^[Reserve[MainLoop]].Second,false,True,True) THEN _Delay(8000);
                    END;
                  END;
             8:   BEGIN
                    DoNodeActivity(6,'');
                    dos_door(Menu^[Reserve[MainLoop]].Second,
                             Process_Special(Menu^[Reserve[MainLoop]].Third,False),
                             Menu^[Reserve[MainLoop]].Sub,
                             Hi(Menu^[Reserve[MainLoop]].Area),
                             Lo(Menu^[Reserve[MainLoop]].Area));
                  END;
             10:  BEGIN
                    DoNodeActivity(7,'');
                    Header(CurrentFileSub,CurrentFileArea+1,True);
                    redraw_menu := false;
                  END;
             11:  BEGIN
                    DoNodeActivity(7,'');
                    Header(CurrentFileSub,CurrentFileArea-1,False);
                    redraw_menu := false;
                  END;
             12:  BEGIN
                    DoNodeActivity(7,'');
                    change_farea;
                  END;
             13:  BEGIN
                    DoNodeActivity(8,'');
                    dl_queue;
                    clear_dirs;
                  END;
             15:  BEGIN
                    DoNodeActivity(8,'');
                    FileUploadArea := GetFromFileId(Menu^[Reserve[MainLoop]].Area);
                    FileUploadSub  := 0;
                    ul_file;
                  END;
             16:  BEGIN
                    DoNodeActivity(8,'');
                    FileUploadArea := CurrentFileArea;
                    FileUploadSub  := CurrentFileSub;
                    ul_file;
                  END;
             17:  BEGIN
                    DoNodeActivity(8,'');
                    IF Change_FArea=True THEN
                    BEGIN
                      FileUploadArea := CurrentFileArea;
                      FileUploadSub  := CurrentFileSub;
                      ul_file;
                    END;
                  END;
             18:  BEGIN
                    DoNodeActivity(8,'');
                    dl_file(Menu^[Reserve[MainLoop]].Second,False);
                  END;
             20:  BEGIN
                    DoNodeActivity(9,'');
                    all_new_mail;
                  END;
             21:  BEGIN
                    DoNodeActivity(9,'');
                    all_mail;
                  END;
             22:  BEGIN
                    DoNodeActivity(10,'');
                    Header2(CurrentMessageSub,CurrentMessageArea+1,True);
                    redraw_menu := false;
                  END;
             23:  BEGIN
                    DoNodeActivity(10,'');
                    Header2(CurrentMessageSub,CurrentMessageArea-1,False);
                    redraw_menu := false;
                  END;
             24:  BEGIN
                    DoNodeActivity(10,'');
                    ChangeMessageArea;
                  END;
             25:  BEGIN
                    DoNodeActivity(12,'');
                    ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
                    RESET(FMessageArea);
                    SEEK(FMessageArea,(CurrentMessageArea-1));
                    READ(FMessageArea,MessageAreas);
                    CLOSE(FMessageArea);
                    IF MessageAreas.ForcedTo=1
                       THEN WriteMessage(CurrentMessageSub,CurrentMessageArea,False,MessageAreas.Sysop)
                       ELSE WriteMessage(CurrentMessageSub,CurrentMessageArea,False,'');
                  END;
             26:  BEGIN
                    DoNodeActivity(11,'');
                    read_message(CurrentMessageArea,0,True);
                  END;
             27:  BEGIN
                    DoNodeActivity(11,'');
                    REPEAT
                      check_it := ChangeMessageArea;
                      IF check_it=true THEN read_message(CurrentMessageArea,0,True);
                    UNTIL check_it=false;
                  END;
             28:  BEGIN
                    DoNodeActivity(12,'');
                    REPEAT
                      check_it := ChangeMessageArea;
                      IF check_it=true THEN
                      BEGIN
                        ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
                        RESET(FMessageArea);
                        SEEK(FMessageArea,(CurrentMessageArea-1));
                        READ(FMessageArea,MessageAreas);
                        CLOSE(FMessageArea);
                        IF MessageAreas.ForcedTo=1
                           THEN WriteMessage(CurrentMessageSub,CurrentMessageArea,False,MessageAreas.Sysop)
                           ELSE WriteMessage(CurrentMessageSub,CurrentMessageArea,False,'');
                      END;
                    UNTIL check_it=false;
                  END;
             29:  BEGIN
                    DoNodeActivity(13,'');
                    kill_old_mail;
                  END;
             31:  BEGIN
                    DoNodeActivity(9,'');
                    new_mail;
                  END;
             32:  BEGIN
                    DoNodeActivity(9,'');
                    all_your_mail;
                  END;
             33:  BEGIN
                    DoNodeActivity(14,'');
                    REPEAT
                      check_it := change_farea;
                      IF check_it=true THEN list_files('');
                    UNTIL check_it=false;
                  END;
             34:  BEGIN
                    DoNodeActivity(14,'');
                    list_files('');
                  END;
             35:  BEGIN
                    DoNodeActivity(12,'');
                    WriteMessage(0,GetFromMsgId(Menu^[Reserve[MainLoop]].Area),False,'');
                  END;
             37:  BEGIN
                    DoNodeActivity(15,'');
                    UploadOneMessage(CurrentMessageArea);
                  END;
             39:  BEGIN
                    DoNodeActivity(8,'');
                    private_upload(Menu^[Reserve[MainLoop]].Second);
                    DoPrivateUploadReport;
                  END;
             40:  BEGIN
                    DoNodeActivity(16,'');
                    show_last_callers;
                  END;
             42:  BEGIN
                    DoNodeActivity(17,'');
                    search_new(False);
                    List_Files(NODE_Directory+'\SEARCH$$');
                  END;
             43:  BEGIN
                    DoNodeActivity(18,'');
                    do_news;
                  END;
             44:  BEGIN
                    bsWriteLog('Reading text file: '+Process_Special(Menu^[Reserve[MainLoop]].Second,False),True);
                    DoNodeActivity(5,'');
                    view_text_file(Process_Special(Menu^[Reserve[MainLoop]].Third,False),
                                   Process_Special(Menu^[Reserve[MainLoop]].Second,False));
                  END;
             45:  BEGIN
                    DoNodeActivity(11,'');
                    REPEAT
                      check_it := ChangeMessageArea;
                      IF check_it=true THEN List_Messages;
                    UNTIL Check_It=False;
                  END;
             46:  BEGIN
                    DoNodeActivity(19,'');
                    CallBackVerifier;
                    load_menu(LastMenuLoaded);
                  END;
             47:  BEGIN
                    DoNodeActivity(20,'');
                    file_search('F');
                  END;
             48:  BEGIN
                    DoNodeActivity(20,'');
                    file_search('D');
                  END;
             49:  BEGIN
                    DoNodeActivity(20,'');
                    file_search('T');
                  END;
             50:  BEGIN
                    DoNodeActivity(21,'');
                    generate_file_list;
                  END;
             52:  BEGIN
                    DoNodeActivity(22,'');
                    DepositTime;
                  END;
             53:  BEGIN
                    DoNodeActivity(22,'');
                    WithdrawTime;
                  END;
             54:  BEGIN
                    DoNodeActivity(23,'');
                    DepositBytes;
                  END;
             55:  BEGIN
                    DoNodeActivity(23,'');
                    WithdrawBytes;
                  END;
             60:  BEGIN
                    DoNodeActivity(24,'');
                    ShowOnlineUsers;
                  END;
             61:  BEGIN
                    DoNodeActivity(25,'');
                    FullScreenChat;
                  END;
             62:  BEGIN
                    DoNodeActivity(26,'');
                    PageAnotherUser;
                  END;
             63:  BEGIN
                    DoNodeActivity(27,'');
                    UsersRealName;
                  END;
             64:  BEGIN
                    DoNodeActivity(27,'');
                    UsersAliasName;
                  END;
             65:  BEGIN
                    DoNodeActivity(27,'');
                    UsersPassword;
                  END;
             66:  BEGIN
                    DoNodeActivity(27,'');
                    UsersVoiceNumber;
                  END;
             67:  BEGIN
                    DoNodeActivity(27,'');
                    UsersDataNumber;
                  END;
             68:  BEGIN
                    DoNodeActivity(27,'');
                    UsersStreetAdress;
                  END;
             69:  BEGIN
                    DoNodeActivity(27,'');
                    UsersCity;
                  END;
             70:  BEGIN
                    DoNodeActivity(27,'');
                    UsersProvinceState;
                  END;
             71:  BEGIN
                    DoNodeActivity(27,'');
                    UsersCountry;
                  END;
             72:  BEGIN
                    DoNodeActivity(27,'');
                    UsersPostalZIPCode;
                  END;
             73:  BEGIN
                    DoNodeActivity(27,'');
                    UsersBBSName;
                  END;
             74:  BEGIN
                    DoNodeActivity(27,'');
                    UsersBBSNetworkNumber;
                  END;
             75:  BEGIN
                    DoNodeActivity(27,'');
                    UsersBBSPhoneNumber;
                  END;
             76:  BEGIN
                    DoNodeActivity(27,'');
                    UsersBirthday;
                  END;
             77:  BEGIN
                    DoNodeActivity(27,'');
                    UsersGender;
                  END;
             78:  BEGIN
                    DoNodeActivity(27,'');
                    IBMCharacterToggle;
                  END;
             79:  BEGIN
                    DoNodeActivity(27,'');
                    ANSIGraphicsToggle;
                  END;
             80:  BEGIN
                    DoNodeActivity(27,'');
                    ClearScreenToggle;
                  END;
             81:  BEGIN
                    DoNodeActivity(27,'');
                    MessageEditorToggle;
                  END;
             82:  BEGIN
                    DoNodeActivity(27,'');
                    InUserlistToggle;
                  END;
             83:  BEGIN
                    DoNodeActivity(27,'');
                    NumberOfFileDescLines;
                  END;
             84:  BEGIN
                    DoNodeActivity(27,'');
                    FileAreaSeperatorToggle;
                  END;
             85:  BEGIN
                    DoNodeActivity(11,'');
                    List_Messages;
                  END;
             86:  BEGIN
                    DoNodeActivity(11,'');
                    goto_message(0);
                  END;
             87:  BEGIN
                    DoNodeActivity(28,'');
                    check_it := ChangeMessageArea;
                    IF check_it=true THEN UploadOneMessage(CurrentMessageArea);
                  END;
             88:  BEGIN
                    DoNodeActivity(29,'');
                    IF DisplayGraphicFile('ANSISIGS',False,True,True) THEN Get_Enter;
                    Private_Upload(SCAN_Directory);
                    IF ValidateSignature=2 THEN
                    BEGIN
                      IF DisplayGraphicFile('BADSIG',False,True,True) THEN Get_Enter;
                    END;
                  END;
             90:  BEGIN
                    DoNodeActivity(30,'');
                    ResetLastReadPointers(True);
                  END;
             91:  BEGIN
                    DoNodeActivity(31,'');
                    MakeQWKPacket('NEWPERSONAL');
                  END;
             92:  BEGIN
                    DoNodeActivity(31,'');
                    MakeQWKPacket('ALLPERSONAL');
                  END;
             93:  BEGIN
                    DoNodeActivity(31,'');
                    MakeQWKPacket('ALLNEW');
                  END;
             94:  BEGIN
                    DoNodeActivity(31,'');
                    MakeQWKPacket('ALL');
                  END;
             95:  BEGIN
                    DoNodeActivity(32,'');
                    IF GotAccessToSomeFileAreas(Menu^[Reserve[MainLoop]].Sub) THEN
                    BEGIN
                      Header(Menu^[Reserve[MainLoop]].Sub,1,True);
                    END;
                  END;
             96:  BEGIN
                    DoNodeActivity(33,'');
                    IF GotAccessToSomeMsgAreas(Menu^[Reserve[MainLoop]].Sub) THEN
                    BEGIN
                      Header2(Menu^[Reserve[MainLoop]].Sub,1,True);
                    END;
                  END;
             97:  BEGIN
                    DoNodeActivity(27,'');
                    UsersComment;
                  END;
             98:  BEGIN
                    DoNodeActivity(34,'');
                    Private_Upload(SCAN_Directory);
                    ULTossREPPacket;
                    Clear_Scan_Dir;
                  END;
             101: BEGIN
                    DoNodeActivity(27,'');
                    PageFlagToggle;
                  END;
             102: BEGIN
                    DoNodeActivity(36,'');
                    WriteMessage(0,GetFromMsgId(Menu^[Reserve[MainLoop]].Area),False,'Sysop');
                  END;
             103: BEGIN
                    DoNodeActivity(37,'');
                    ShowUserList;
                  END;
             104: BEGIN
                    DoNodeActivity(38,'');
                    system_prompt('',25);
                    Get_Enter;
                    IF Fields[1].Text<>'' THEN
                    BEGIN
                      CrapString := Fields[1].Text;
                      WriteGroupMessage(CurrentMessageSub,CurrentMessageArea);
                    END;
                  END;
             105: BEGIN
                    DoNodeActivity(38,'');
                    system_prompt('',25);
                    Get_Enter;
                    IF Fields[1].Text<>'' THEN
                    BEGIN
                      CrapString := Fields[1].Text;
                      REPEAT
                        check_it := ChangeMessageArea;
                        IF check_it=true THEN WriteGroupMessage(CurrentMessageSub,CurrentMessageArea);
                      UNTIL check_it=false;
                    END;
                  END;
             106: BEGIN
                    DoNodeActivity(8,'');
                    FileBox(Menu^[Reserve[MainLoop]].Second);
                  END;
             107: BEGIN
                    DoNodeActivity(9,'');
                    Search_String;
                  END;
             108: BEGIN
                    IF _FileExists(Shotgun_Directory+'\SOUND\'+Menu^[Reserve[MainLoop]].Second) THEN
                    BEGIN
                      bsWriteLog('Playing audio file: '+Menu^[Reserve[MainLoop]].Second,True);
                      PlayVOCFile(Shotgun_Directory+'\SOUND\'+Menu^[Reserve[MainLoop]].Second);
                    END;
                  END;
             109: BEGIN
                    DoNodeActivity(30,'');
                    ResetLastReadPointers(False);
                  END;
             110: BEGIN
                    DoNodeActivity(40,'');
                    DoDataEntryScreen(Menu^[Reserve[MainLoop]].Second);
                  END;
             111: BEGIN
                    DoNodeActivity(41,'');
                    DialOut(Menu^[Reserve[MainLoop]].Third,
                            Menu^[Reserve[MainLoop]].Second,
                            Menu^[Reserve[MainLoop]].Sub);
                  END;
             112: BEGIN
                    CreateCustomDropFile(Menu^[Reserve[MainLoop]].Second,Menu^[Reserve[MainLoop]].Third);
                  END;
             113: BEGIN
                    IF _FileExists(Shotgun_Directory+'\FLICS\'+Menu^[Reserve[MainLoop]].Second)
                       THEN PlayFLIFile(Shotgun_Directory+'\FLICS\'+Menu^[Reserve[MainLoop]].Second);
                  END;
             114: BEGIN
                    DoNodeActivity(12,'');
                    WriteMessage(0,GetFromMsgId(Menu^[Reserve[MainLoop]].Area),
                                 False,Menu^[Reserve[MainLoop]].Second);
                  END;
             115: BEGIN
                    DoNodeActivity(6,'');
                    svga_door(Menu^[Reserve[MainLoop]].Second,
                              Process_Special(Menu^[Reserve[MainLoop]].Third,False),
                              Menu^[Reserve[MainLoop]].Sub);
                  END;
             116: BEGIN
                    DoNodeActivity(10,'');
                    NextMessageGroup;
                  END;
             117: BEGIN
                    DoNodeActivity(10,'');
                    PreviousMessageGroup;
                  END;
             118: BEGIN
                    DoNodeActivity(10,'');
                    ChangeMessageGroup;
                  END;
             119: BEGIN
                    DoNodeActivity(7,'');
                    NextFileGroup;
                  END;
             120: BEGIN
                    DoNodeActivity(7,'');
                    PreviousFileGroup;
                  END;
             121: BEGIN
                    DoNodeActivity(7,'');
                    ChangeFileGroup;
                  END;
             122: BEGIN
                    DoNodeActivity(42,'');
                    DoGipDirectory(Menu^[Reserve[MainLoop]].Second);
                  END;
             124: BEGIN
                    MainWork := select_archiver;
                    IF (MainWork<>0) THEN UserRecord.DefaultArchiver := MainWork;
                  END;
             125: BEGIN
                    DoNodeActivity(30,'');
                    ResetLRPsLastXXXMsgs;
                  END;
             126: BEGIN
                    DoNodeActivity(30,'');
                    ResetLRPsSkipXXXMsgs;
                  END;
             127: SaveCurrentMsgGroupArea;
             128: LoadCurrentMsgGroupArea;
             129: SaveCurrentFileGroupArea;
             130: LoadCurrentFileGroupArea;
             131: SaveCurrentMenu;
             132: BEGIN
                    IF _FileExists(MENU_Directory+'\'+SSavedMenu+'.MNU') THEN
                    BEGIN
                      load_menu(SSavedMenu+'.MNU');
                      bsWriteLog('Loading menu: '+LastMenuLoaded+' ['+Menu^[1].Title+']',True);
                    END;
                  END;
             133: BEGIN
                    CDRomManager;
                  END;
             134: BEGIN
                    MainWork := select_quote;
                    IF (MainWork<>0) THEN UserRecord.DefaultQuote := MainWork;
                  END;
             END;
           END;
         END
         ELSE load_menu(LastMenuLoaded);
       UNTIL CurCount=32768;
     END
     ELSE
     BEGIN
       DoErrorLog(14,_String(NodeInfo.ComPort));
       TextMode(co80);
       ClrScr;
       WRITELN('Cannot initialize port!!!!');
       WRITELN('Shotgun is shutting down.');
       WRITELN;
     END;
END.
