{$I DEFINES.INC}
UNIT Keys;


INTERFACE


USES Shotgun;


FUNCTION  SelectedAName    (InString: String; VAR TheAka: AddrType): Boolean;
FUNCTION  InTheBook        (TheName: String)                       : Boolean;
FUNCTION  ChangeCurrentAKA                                         : Boolean;


IMPLEMENTATION


USES Globals,FastW1,Crt,SaveScrn,Misc,DrawScrn,BsFile,
     BsMulti,MkFFile,FMode,BsAkas,BsString,BsKeys,BsVideo;


FUNCTION ChangeCurrentAKA: Boolean;
TYPE Pick_List  = RECORD
     Text       : String[25];
     QueueNum   : Word;
     END;
TYPE BigPick    = Array[1..800] Of Pick_List;
VAR  OldX       : Word;
     OldY       : Word;
     PickList   : ^BigPick;
     NumItems   : Word;
     YYPos      : Word;
     Top        : Word;
     Current    : Word;
     TheOne     : Word;
     OnScreen   : Word;
     C          : Char;
     Loop       : Word;
     Loop2      : Word;
     Temp       : String;
     Temp2      : String;
     Work1      : Integer;
LABEL             Skip1,Skip2;

     PROCEDURE DoRedraw;
     VAR  LLoop : Word;
          ToDo  : Word;
          TTemp : String;
     BEGIN
          TheOne  := Top;
          IF NumItems<=21 THEN ToDo := YYPos+NumItems
                          ELSE ToDo := 23;
          FOR LLoop := (YYPos+1) TO ToDo DO
          BEGIN
               IF (TheOne<=NumItems) THEN
               BEGIN
                    TTemp := PickList^[TheOne].Text;
                    IF TheOne=Current THEN FastWrite(TTemp,LLoop,5,63)
                                      ELSE FastWrite(TTemp,LLoop,5,27);
               END;
               INC(TheOne);
          END;
     END;

BEGIN
     OldX := WhereX;
     OldY := WhereY;
     Save_Screen;
     New(PickList);
     NumItems := 0;

     ASSIGN(FNetwork,Shotgun_Directory+'\DATA\NETWORK.DAT');
     RESET(FNetwork);
     REPEAT
           READ(FNetwork,Network);
           Temp := _PadRight(' '+AddressToString(Network.Net_Address),25);
           INC(NumItems);
           PickList^[NumItems].Text := Temp;
           PickList^[NumItems].QueueNum := NumItems;
     UNTIL EOF(FNetwork);
     CLOSE(FNetwork);
     IF NumItems<=21 THEN
     BEGIN
          OnScreen := NumItems;
          YYPos := Trunc((25-NumItems)/2);
          DrawWindow(4,YYPos,30,YYPos+NumItems+1,'CHANGE CURRENT AKA',True);
     END
     ELSE
     BEGIN
          OnScreen := 21;
          YYPos := 2;
          DrawWindow(4,2,30,24,'CHANGE CURRENT AKA',True);
     END;
     _HideCursor;
     Top     := 1;
     Current := 1;
     DoRedraw;
     C := #0;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                IF C=#0 THEN
                BEGIN
                     C := ReadKey;
                     CASE ORD(C) OF
                     72:  BEGIN {UP ARROW}
                               IF ((NumItems>21) AND (Current=1)) THEN GOTO Skip1;
                               DEC(Current);
                               IF Current=0 THEN Current := NumItems;
                                    IF Current<Top THEN DEC(Top)
                               ELSE IF Current>=Top+OnScreen THEN Top := NumItems-20;
                               DoRedraw;
                               Skip1:
                          END;
                     80:  BEGIN {DOWN ARROW}
                               IF ((NumItems>21) AND (Current=NumItems)) THEN GOTO Skip1;
                               INC(Current);
                               IF Current>NumItems THEN Current := 1;
                                    IF Current<Top THEN Top := 1
                               ELSE IF Current>=Top+OnScreen THEN INC(Top);
                               DoRedraw;
                               Skip2:
                          END;
                     73:  BEGIN {PAGE UP}
                               IF NumItems>21 THEN
                               BEGIN
                                    Work1 := Top-21;
                                    IF Work1<1 THEN Work1 := 1;
                                    IF Top=Work1 THEN Current := 1;
                                    Top := Work1;
                                    IF ((Current<Top) OR (Current>=Top+OnScreen)) THEN Current := Top;
                                    DoRedraw;
                               END;
                          END;
                     81:  BEGIN {PAGE DOWN}
                               IF NumItems>21 THEN
                               BEGIN
                                    Work1 := Top+21;
                                    IF Work1>NumItems-20 THEN Work1 := NumItems-20;
                                    IF Top=Work1 THEN Current := NumItems;
                                    Top := Work1;
                                    IF ((Current<Top) OR (Current>=Top+OnScreen)) THEN Current := Top;
                                    DoRedraw;
                               END;
                          END;
                     132: BEGIN {CTRL-PAGE UP}
                               IF NumItems>21 THEN
                               BEGIN
                                    Current := 1;
                                    Top := 1;
                                    DoRedraw;
                               END;
                          END;
                     118: BEGIN {CTRL-PAGE DOWN}
                               IF NumItems>21 THEN
                               BEGIN
                                    Current := NumItems;
                                    Top := NumItems-20;
                                    DoRedraw;
                               END;
                          END;
                     END;
                     C := #0;
                END
                ELSE IF ((C=#13) OR (C=#32)) THEN
                BEGIN
                     IF (Current<>0) THEN
                     BEGIN
                          CurrentAka := Current;
                          Dispose(PickList);
                          Restore_Screen;
                          GotoXY(OldX,OldY);
                          _ShowCursor;
                          TextColor(7);
                          TextBackGround(0);
                          ChangeCurrentAKA := True;
                          Exit;
                     END;
                END;
           END
           ELSE TimeSlice;
     UNTIL C=#27;
     Dispose(PickList);
     Restore_Screen;
     GotoXY(OldX,OldY);
     _ShowCursor;
     TextColor(7);
     TextBackGround(0);
     CurrentAka := Current;
     ChangeCurrentAKA := False;
END;


FUNCTION SelectedAName(InString: String; VAR TheAka: AddrType): Boolean;
TYPE Pick_List  = RECORD
     Text       : String[75];
     END;
VAR  TempIndex  : Longint;
     Temp       : String;
     NodeRec    : AddrType;
     FNodeRec   : File Of AddrType;
     Work33     : Word;
     Code       : Integer;
     OldX       : Word;
     OldY       : Word;
     PickList   : Pick_List;
     FPickList  : File Of Pick_List;
     NumItems   : Word;
     YYPos      : Word;
     Top        : Word;
     Current    : Word;
     TheOne     : Word;
     OnScreen   : Word;
     C          : Char;
     Work1      : Integer;
     BytesRead  : Word;
     BBytesRead : Word;
     BOR        : Word;
LABEL             Skip1,Skip2;

     PROCEDURE DoRedraw;
     VAR  Loop : Word;
          ToDo : Word;
     BEGIN
          TheOne  := Top-1;
          SEEK(FPickList,Top-1);
          IF NumItems<=21 THEN ToDo := YYPos+NumItems
                          ELSE ToDo := 23;
          FOR Loop := (YYPos+1) TO ToDo DO
          BEGIN
            IF NOT(EOF(FPickList)) THEN
            BEGIN
              READ(FPickList,PickList);
              INC(TheOne);
              IF TheOne=Current THEN FastWrite(PickList.Text,Loop,3,63)
                                ELSE FastWrite(PickList.Text,Loop,3,27);
            END;
          END;
     END;

BEGIN
     OldX := WhereX;
     OldY := WhereY;
     Save_Screen;
     InString := _UpperCase(InString);
     NumItems := 0;
     IF ((NOT(_FileExists(MailerInfo.NodeList+'NODELIST.SG'))) OR
        (NOT(_FileExists(MailerInfo.NodeList+'USERLIST.SG')))) THEN
     BEGIN
       FillChar(TheAka,SizeOf(TheAka),0);
       SelectedAName := False;
       Exit;
     END;
     ASSIGN(FPickList,MailerInfo.OutPkts+'PICKLIST.$$$');
     ASSIGN(FNodeRec,MailerInfo.OutPkts+'NODELIST.$$$');
     REWRITE(FPickList);
     REWRITE(FNodeRec);
     IF FNodeList.OpenFile(MailerInfo.NodeList+'NODELIST.SG',SetFileMode) THEN
     BEGIN
       IF FUserList.OpenFile(MailerInfo.NodeList+'USERLIST.SG',SetFileMode) THEN
       BEGIN
         REPEAT
           FUserList.BlkRead(UserList,SizeOf(UserList),BBytesRead);
           IF (BBytesRead<>0) THEN
           BEGIN
             IF Pos(InString,UserList.SysopName)<>0 THEN
             BEGIN
               FNodeList.SeekFile(UserList.ByteOffSet+2);
               FNodeList.BlkRead(NodeListAka,SizeOf(NodeListAka),BytesRead);
               FNodeList.BlkRead(NodeListBaud,SizeOf(NodeListBaud),BytesRead);
               FNodeList.BlkRead(NodeListSysop[0],1,BytesRead);
               FNodeList.BlkRead(NodeListSysop[1],Ord(NodeListSysop[0]),BytesRead);
               FNodeList.BlkRead(NodeListSystem[0],1,BytesRead);
               FNodeList.BlkRead(NodeListSystem[1],Ord(NodeListSystem[0]),BytesRead);
               FNodeList.BlkRead(NodeListPhone[0],1,BytesRead);
               FNodeList.BlkRead(NodeListPhone[1],Ord(NodeListPhone[0]),BytesRead);
               FNodeList.BlkRead(NodeListLocation[0],1,BytesRead);
               FNodeList.BlkRead(NodeListLocation[1],Ord(NodeListLocation[0]),BytesRead);
               FNodeList.BlkRead(NodeListFlags[0],1,BytesRead);
               FNodeList.BlkRead(NodeListFlags[1],Ord(NodeListFlags[0]),BytesRead);
               PickList.Text := ' '+_PadRight(NodeListSysop,24)+
                                _PadRight(AddressToString(NodeListAka),20)+
                                _PadRight(NodeListSystem,30);
               NodeRec := NodeListAka;
               INC(NumItems);
               WRITE(FPickList,PickList);
               WRITE(FNodeRec,NodeRec);
             END;
           END;
         UNTIL BBytesRead=0;
         FUserList.CloseFile;
       END;
       FNodeList.CloseFile;
     END;
     CLOSE(FNodeRec);
     IF NumItems=0 THEN
     BEGIN
       CLOSE(FPickList);
       ERASE(FPickList);
       _EraseFile(MailerInfo.OutPkts+'NODELIST.$$$');
       SelectedAName := False;
       Exit;
     END
     ELSE IF NumItems<=21 THEN
     BEGIN
       OnScreen := NumItems;
       YYPos := Trunc((25-NumItems)/2);
       DrawWindow(2,YYPos,78,YYPos+NumItems+1,'',True);
     END
     ELSE
     BEGIN
       OnScreen := 21;
       YYPos := 2;
       DrawWindow(2,2,78,24,'',True);
     END;
     _HideCursor;
     Top     := 1;
     Current := 1;
     DoRedraw;
     C := #0;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                IF C=#0 THEN
                BEGIN
                     C := ReadKey;
                     CASE ORD(C) OF
                     72:  BEGIN {UP ARROW}
                               IF ((NumItems>21) AND (Current=1)) THEN GOTO Skip1;
                               DEC(Current);
                               IF Current=0 THEN Current := NumItems;
                                    IF Current<Top THEN DEC(Top)
                               ELSE IF Current>=Top+OnScreen THEN Top := NumItems-20;
                               DoRedraw;
                               Skip1:
                          END;
                     80:  BEGIN {DOWN ARROW}
                               IF ((NumItems>21) AND (Current=NumItems)) THEN GOTO Skip1;
                               INC(Current);
                               IF Current>NumItems THEN Current := 1;
                                    IF Current<Top THEN Top := 1
                               ELSE IF Current>=Top+OnScreen THEN INC(Top);
                               DoRedraw;
                               Skip2:
                          END;
                     73:  BEGIN {PAGE UP}
                               IF NumItems>21 THEN
                               BEGIN
                                    Work1 := Top-21;
                                    IF Work1<1 THEN Work1 := 1;
                                    IF Top=Work1 THEN Current := 1;
                                    Top := Work1;
                                    IF ((Current<Top) OR (Current>=Top+OnScreen)) THEN Current := Top;
                                    DoRedraw;
                               END;
                          END;
                     81:  BEGIN {PAGE DOWN}
                               IF NumItems>21 THEN
                               BEGIN
                                    Work1 := Top+21;
                                    IF Work1>NumItems-20 THEN Work1 := NumItems-20;
                                    IF Top=Work1 THEN Current := NumItems;
                                    Top := Work1;
                                    IF ((Current<Top) OR (Current>=Top+OnScreen)) THEN Current := Top;
                                    DoRedraw;
                               END;
                          END;
                     132: BEGIN {CTRL-PAGE UP}
                               IF NumItems>21 THEN
                               BEGIN
                                    Current := 1;
                                    Top := 1;
                                    DoRedraw;
                               END;
                          END;
                     118: BEGIN {CTRL-PAGE DOWN}
                               IF NumItems>21 THEN
                               BEGIN
                                    Current := NumItems;
                                    Top := NumItems-20;
                                    DoRedraw;
                               END;
                          END;
                     END;
                     C := #0;
                END;
           END
           ELSE TimeSlice;
     UNTIL ((C=#13) OR (C=#27));
     CLOSE(FPickList);
     ERASE(FPickList);
     Restore_Screen;
     GotoXY(OldX,OldY);
     _ShowCursor;
     TextColor(7);
     TextBackGround(0);
     IF C=#13 THEN
     BEGIN
       ASSIGN(FNodeRec,MailerInfo.OutPkts+'NODELIST.$$$');
       RESET(FNodeRec);
       SEEK(FNodeRec,Current-1);
       READ(FNodeRec,NodeRec);
       CLOSE(FNodeRec);
       ERASE(FNodeRec);
       TheAka := NodeRec;
       SelectedAName := True;
     END
     ELSE
     BEGIN
       FillChar(TheAka,SizeOf(TheAka),0);
       SelectedAName := False;
     END;
     _EraseFile(MailerInfo.OutPkts+'NODELIST.$$$');
END;


FUNCTION InTheBook(TheName: String): Boolean;
BEGIN
     TheName := _UpperCase(TheName);
     IF _FileExists(Shotgun_Directory+'\DATA\PBOOK.DAT') THEN
     BEGIN
          ASSIGN(FPhoneBook,Shotgun_Directory+'\DATA\PBOOK.DAT');
          RESET(FPhoneBook);
          REPEAT
                READ(FPhoneBook,PhoneBook);
                IF _UpperCase(PhoneBook.UserName)=TheName THEN
                BEGIN
                     CLOSE(FPhoneBook);
                     InTheBook := True;
                     Exit;
                END;
          UNTIL EOF(FPhoneBook);
          CLOSE(FPhoneBook);
     END;
     InTheBook := False;
END;


END.