{$I DEFINES.INC}
UNIT UnDial;


INTERFACE


USES Shotgun;


PROCEDURE AddUndialable(InAddress: AddrType);
PROCEDURE ClearUndialable(InAddress: AddrType);
FUNCTION  CanDialThisOne(InAddress: AddrType): Boolean;
PROCEDURE UndialableSystems;


IMPLEMENTATION


USES BsFile,BsAkas,Globals,BsVideo,FastW1,SaveScrn,
     NList,BsString,DrawScrn,BsKeys,Crt,BsMulti;


PROCEDURE AddUndialable(InAddress: AddrType);
VAR  Undialable  : _Undialable_Systems;
     FUndialable : File Of _Undialable_Systems;
     Locate      : Longint;
BEGIN
     IF _FileExists(Shotgun_Directory+'\DATA\UNDIAL.DAT') THEN
     BEGIN
       Locate := 0;
       ASSIGN(FUndialable,Shotgun_Directory+'\DATA\UNDIAL.DAT');
       RESET(FUndialable);
       REPEAT
         READ(FUndialable,Undialable);
         INC(Locate);
         IF AkasMatch(Undialable.Net_Address,InAddress) THEN
         BEGIN
           INC(Undialable.Retries);
           SEEK(FUndialable,Locate-1);
           WRITE(FUndialable,Undialable);
           CLOSE(FUndialable);
           Exit;
         END;
       UNTIL EOF(FUndialable);
       CLOSE(FUndialable);
       Undialable.Net_Address := InAddress;
       Undialable.Retries := 1;
       ASSIGN(FUndialable,Shotgun_Directory+'\DATA\UNDIAL.DAT');
       RESET(FUndialable);
       SEEK(FUndialable,FileSize(FUndialable));
       WRITE(FUndialable,Undialable);
       CLOSE(FUndialable);
     END
     ELSE
     BEGIN
       Undialable.Net_Address := InAddress;
       Undialable.Retries := 1;
       ASSIGN(FUndialable,Shotgun_Directory+'\DATA\UNDIAL.DAT');
       REWRITE(FUndialable);
       WRITE(FUndialable,Undialable);
       CLOSE(FUndialable);
     END;
END;


FUNCTION CanDialThisOne(InAddress: AddrType): Boolean;
VAR  Undialable  : _Undialable_Systems;
     FUndialable : File Of _Undialable_Systems;
BEGIN
     IF _FileExists(Shotgun_Directory+'\DATA\UNDIAL.DAT') THEN
     BEGIN
       ASSIGN(FUndialable,Shotgun_Directory+'\DATA\UNDIAL.DAT');
       RESET(FUndialable);
       REPEAT
         READ(FUndialable,Undialable);
         IF AkasMatch(Undialable.Net_Address,InAddress) THEN
         BEGIN
           CLOSE(FUndialable);
           IF (Undialable.Retries<Mailer2Info.CallsBeforeFail)
              THEN CanDialThisOne := True
              ELSE CanDialThisOne := False;
           Exit;
         END;
       UNTIL EOF(FUndialable);
       CLOSE(FUndialable);
     END;
     CanDialThisOne := True;
END;


PROCEDURE UndialableSystems;
TYPE Pick_List   = RECORD
     Text        : String[75];
     END;
TYPE BigPick     = Array[1..800] Of Pick_List;
VAR  Undialable  : _Undialable_Systems;
     FUndialable : File Of _Undialable_Systems;
     OldXY       : Word;
     PickList    : ^BigPick;
     NumItems    : Word;
     YYPos       : Word;
     Top         : Word;
     Current     : Word;
     TheOne      : Word;
     OnScreen    : Word;
     C           : Char;
     Loop        : Word;
     Loop2       : Word;
     IsItThere   : Boolean;
     Temp        : String;
     Temp2       : String;
     Work1       : Integer;
LABEL              OverAgain,Skip1,Skip2;

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
                    IF TheOne=Current THEN FastWrite(TTemp,LLoop,3,ShotgunColours.SGMailMenuSelected)
                                      ELSE FastWrite(TTemp,LLoop,3,ShotgunColours.SGMailWindowText);
               END;
               INC(TheOne);
          END;
     END;

BEGIN
     WhereXYAbs(OldXY);
     SaveScreen(1);
     New(PickList);
     OverAgain:
     FillChar(PickList^,SizeOf(PickList^),0);
     NumItems := 0;
     IF _FileExists(Shotgun_Directory+'\DATA\UNDIAL.DAT') THEN
     BEGIN
       ASSIGN(FUndialable,Shotgun_Directory+'\DATA\UNDIAL.DAT');
       RESET(FUndialable);
       REPEAT
         READ(FUndialable,Undialable);
         Temp2 := GetBBSName(Undialable.Net_Address);
         Temp  := '  '+_PadRight(AddressToString(Undialable.Net_Address),25);
         Temp  := Temp+_PadRight(Temp2,34);
         IF Undialable.Retries=1
            THEN Temp  := Temp+_PadRight(_String(Undialable.Retries)+' Try',14)
            ELSE Temp  := Temp+_PadRight(_String(Undialable.Retries)+' Tries',14);
         INC(NumItems);
         PickList^[NumItems].Text := Temp;
       UNTIL EOF(FUndialable);
       CLOSE(FUndialable);
     END;
     IF NumItems<=21 THEN
     BEGIN
          OnScreen := NumItems;
          YYPos := Trunc((25-NumItems)/2);
          DrawWindow(2,YYPos,78,YYPos+NumItems+1,'Undialable Systems',True);
     END
     ELSE
     BEGIN
          OnScreen := 21;
          YYPos := 2;
          DrawWindow(2,2,78,24,'Undialable Systems',True);
     END;
     FastWrite(_PadRight('  [   ]',80),Window2+7,1,ShotgunColours.SGMailWindowText);
     FastWrite('DEL',Window2+7,4,ShotgunColours.SGMailWindowHighlight);
     FastWrite('Delete Entry',Window2+7,9,ShotgunColours.SGMailWindowText);
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
                     83:  BEGIN {Delete}
                            IF ((NumItems>0) AND (Current<>0)) THEN
                            BEGIN
                              _EraseFileRecord(Shotgun_Directory+'\DATA\UNDIAL.DAT',
                                               SizeOf(_Undialable_Systems),Current);
                              RestoreScreen(1);
                              GOTO OverAgain;
                            END;
                          END;
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
                               IF ((NumItems>21) AND (Current=NumItems)) THEN GOTO Skip2;
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
     Dispose(PickList);
     RestoreScreen(1);
     GotoXYAbs(OldXY);
     _ShowCursor;
END;


PROCEDURE ClearUndialable(InAddress: AddrType);
VAR  Undialable   : _Undialable_Systems;
     FUndialable  : File Of _Undialable_Systems;
     FUndialable2 : File Of _Undialable_Systems;
BEGIN
     IF _FileExists(Shotgun_Directory+'\DATA\UNDIAL.DAT') THEN
     BEGIN
       ASSIGN(FUndialable,Shotgun_Directory+'\DATA\UNDIAL.DAT');
       RENAME(FUndialable,Shotgun_Directory+'\DATA\UNDIAL.BAK');
       ASSIGN(FUndialable2,Shotgun_Directory+'\DATA\UNDIAL.BAK');
       ASSIGN(FUndialable,Shotgun_Directory+'\DATA\UNDIAL.DAT');
       REWRITE(FUndialable);
       RESET(FUndialable2);
       REPEAT
         READ(FUndialable2,Undialable);
         IF NOT(AkasMatch(Undialable.Net_Address,InAddress))
            THEN WRITE(FUndialable,Undialable);
       UNTIL EOF(FUndialable2);
       CLOSE(FUndialable);
       CLOSE(FUndialable2);
       ERASE(FUndialable2);
       IF _FileSize(Shotgun_Directory+'\DATA\UNDIAL.DAT')=0
          THEN _EraseFile(Shotgun_Directory+'\DATA\UNDIAL.DAT');
     END;
END;


END.