{$I DEFINES.INC}
UNIT FaxEdit;


INTERFACE


PROCEDURE FaxEditor;


IMPLEMENTATION


USES Dos,Globals,FastW1,SaveScrn,Gunshot,DrawScrn,
     BsExec,BsMulti,Crt,BsString,BsKeys,BsFile,BsVideo;


PROCEDURE FaxEditor;
TYPE Pick_List     = RECORD
     Text          : String[75];
     END;
VAR  PickList      : Pick_List;
     FPickList     : File Of Pick_List;
     OldXY         : Word;
     TheOne        : Word;
     Top           : Word;
     NumItems      : Word;
     OnScreen      : Word;
     YYPos         : Word;
     FFaxBase      : File Of _FaxBaseHeader_Record;
     FaxBase       : _FaxBaseHeader_Record;
     DirInfo       : SearchRec;
     Temp          : String;
     Temp2         : String;
     Prefix        : String[2];
     C             : Char;
     Work1         : Word;
     Loop          : Word;
     M             : String[2];
     D             : String[2];
     Y             : String[4];
     Crap          : Char;
LABEL                Skip1,Skip2;

     PROCEDURE DoRedraw;
     VAR  LLoop : Word;
          ToDo  : Word;
     BEGIN
          TheOne  := Top-1;
          SEEK(FPickList,Top-1);
          IF NumItems<=21 THEN ToDo := YYPos+NumItems
                          ELSE ToDo := 23;
          FOR LLoop := (YYPos+1) TO ToDo DO
          BEGIN
               IF NOT(EOF(FPickList)) THEN
               BEGIN
                    READ(FPickList,PickList);
                    INC(TheOne);
                    IF TheOne=Current THEN FastWrite(PickList.Text,LLoop,3,GunshotColours.GSMailMenuSelected)
                                      ELSE FastWrite(PickList.Text,LLoop,3,GunshotColours.GSMailWindowText);
               END;
          END;
     END;

     PROCEDURE DrawHelpBar;
     BEGIN
          FastWrite(_PadRight('  [     ]           [   ]',80),Window2+7,1,GunshotColours.GSMailStatusText);
          FastWrite('SPACE',Window2+7,4,GunshotColours.GSMailStatusHighlight);
          FastWrite('F10',Window2+7,22,GunshotColours.GSMailStatusHighlight);
          FastWrite('View Fax',Window2+7,11,GunshotColours.GSMailStatusText);
          FastWrite('Print Fax',Window2+7,27,GunshotColours.GSMailStatusText);
     END;

BEGIN
     SaveScreen(1);
     WhereXYAbs(OldXY);
     _HideCursor;
     DrawHelpBar;
     NumItems := 0;
     ASSIGN(FPickList,MailerInfo.OutPkts+'PICKLIST.$$$');
     REWRITE(FPickList);

     FindFirst(MailerInfo.NetMail+'*.FAX',AnyFile-Directory-VolumeID,DirInfo);
     Loop := 0;
     WHILE DosError=0 DO
     BEGIN
          INC(Loop);
          ASSIGN(FFaxBase,MailerInfo.NetMail+DirInfo.Name);
          RESET(FFaxBase);
          READ(FFaxBase,FaxBase);
          CLOSE(FFaxBase);
          WITH FaxBase DO
          BEGIN
               IF Received THEN Temp := _PadLeft(_String(Loop),3)+']   '
                           ELSE Temp := _PadLeft(_String(Loop),3)+'] * ';
               Temp := Temp+_PadRight(StationID,32)+
                       _PadRight(_NoPath(FaxFile),14);
               M     := _String(Month); IF M[0]=#1 THEN M := '0'+M;
               D     := _String(Day);   IF D[0]=#1 THEN D := '0'+D;
               Y     := _String(Year);
               Temp2 := _PadRight(M+'/'+D+'/'+Y,12);
               Temp  := Temp+Temp2;
               IF Hour>12 THEN
               BEGIN
                    Prefix := 'pm';
                    DEC(Hour,12);
               END
               ELSE Prefix := 'am';
               IF (Minute<10) THEN Temp2 := _String(Hour)+':0'+_String(Minute)+Prefix
                              ELSE Temp2 := _String(Hour)+':'+_String(Minute)+Prefix;
               Temp  := Temp+_PadRight(Temp2,7);
          END;
          PickList.Text := Temp+'   ';
          INC(NumItems);
          WRITE(FPickList,PickList);
          FindNext(DirInfo);
     END;
     IF NumItems<=21 THEN
     BEGIN
          OnScreen := NumItems;
          YYPos := Trunc((25-NumItems)/2);
          DrawWindow(2,YYPos,78,YYPos+NumItems+1,'Gunshot Professional - Fax Base',True);
     END
     ELSE
     BEGIN
          OnScreen := 21;
          YYPos := 2;
          DrawWindow(2,2,78,24,'Gunshot Professional - Fax Base',True);
     END;
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
                     68:  BEGIN {PRINT}
                               SEEK(FPickList,Top+Current-2);
                               READ(FPickList,PickList);
                               Temp := MailerInfo.Netmail+_Mid(PickList.Text,40,52);
                               Temp := _RemoveSpaces(Temp);
                               SaveScreen(3);
                               _ShowCursor;
                               SetOrigVideoMode;
                               DoExec(Gunshot_Directory+'\BIN\GSFAXP.EXE',_String(ConfigSetup.Printer)+
                                      ' '+_String(ConfigSetup.PrinterModel)+' '+Temp,SwapMethod,
                                       Gunshot_Directory+'\NODE'+_String(SimNode));
                               SetOurVideoMode;
                               _HideCursor;
                               RestoreScreen(3);
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
                ELSE IF (NumItems<>0) THEN
                BEGIN
                     CASE C OF
                     #13,
                     #32: BEGIN
                               SEEK(FPickList,Top+Current-2);
                               READ(FPickList,PickList);
                               Temp := MailerInfo.Netmail+_Mid(PickList.Text,40,52);
                               Temp := _RemoveSpaces(Temp);
                               SaveScreen(3);
                               _ShowCursor;
                               SetOrigVideoMode;
                               WHILE KeyPressed DO Crap := ReadKey;
                               DoExec(Gunshot_Directory+'\BIN\GSFAXV.EXE',Temp,
                                      SwapMethod,Gunshot_Directory+'\NODE'+_String(SimNode));
                               SetOurVideoMode;
                               _HideCursor;
                               RestoreScreen(3);
                               ASSIGN(FFaxBase,_NoExtension(Temp)+'.FAX');
                               RESET(FFaxBase);
                               READ(FFaxBase,FaxBase);
                               CLOSE(FFaxBase);
                               FaxBase.Received := True;
                               ASSIGN(FFaxBase,_NoExtension(Temp)+'.FAX');
                               REWRITE(FFaxBase);
                               WRITE(FFaxBase,FaxBase);
                               CLOSE(FFaxBase);
                          END;
                     END;
                END;
           END
           ELSE TimeSlice;
     UNTIL (C=#27);
     CLOSE(FPickList);
     ERASE(FPickList);
     RestoreScreen(1);
     GotoXYAbs(OldXY);
     _ShowCursor;
     TextColor(7);
     TextBackGround(0);
END;


END.
