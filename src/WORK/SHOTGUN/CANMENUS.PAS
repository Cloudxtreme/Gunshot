{$I DEFINES.INC}
UNIT CanMenus;


INTERFACE


PROCEDURE display_menu;
PROCEDURE do_header(DoAll: Boolean);


IMPLEMENTATION


USES Globals,FilHeadr,MsgHeadr,ANSIMisc,BaseInfo,TagArea,Screens,
     Special,Time,BsString,BsFile,BsKeys,BsTime;


PROCEDURE do_header(DoAll: Boolean);
BEGIN
     IF Menu^[1].Tags[2]=2 THEN
     BEGIN
          Header(CurrentFileSub,CurrentFileArea,True);
          IF DoAll THEN
          BEGIN
               fore(Menu^[1].Tags[6]); WRITEANSI('GROUP ',false,False);
               fore(Menu^[1].Tags[5]); WRITEANSI(_String(CurrentFileSub)+': ',false,False);
               fore(Menu^[1].Tags[7]); WRITEANSI(FileSubs.Sub_Name,True,True);
          END;
          IF IsFileTagged(FileAreas.AreaId) THEN
          BEGIN
               fore(Menu^[1].Tags[5]);
               WRITECHAR('*');
          END;
          fore(Menu^[1].Tags[6]); WRITEANSI(' AREA ',false,False);
          fore(Menu^[1].Tags[5]); WRITEANSI(_String(CurrentFileArea)+': ',false,False);
          fore(Menu^[1].Tags[7]); WRITEANSI(fileareas.area_name+' ',False,True);
     END
     ELSE IF Menu^[1].Tags[2]=3 THEN
     BEGIN
          Header2(CurrentMessageSub,CurrentMessageArea,True);
          JamBase_MessageBaseInfo(MessageAreas.Dos_Name);
          IF DoAll THEN
          BEGIN
               fore(Menu^[1].Tags[6]); WRITEANSI('GROUP ',false,False);
               fore(Menu^[1].Tags[5]); WRITEANSI(_String(CurrentMessageSub)+': ',false,False);
               fore(Menu^[1].Tags[7]); WRITEANSI(MessageSubs.Sub_Name,True,True);
          END;
          IF IsMsgTagged(MessageAreas.AreaId) THEN
          BEGIN
               fore(Menu^[1].Tags[5]);
               WRITECHAR('*');
          END;
          fore(Menu^[1].Tags[6]); WRITEANSI(' AREA ',false,False);
          fore(Menu^[1].Tags[5]); WRITEANSI(_String(CurrentMessageArea)+': ',false,False);
          fore(Menu^[1].Tags[7]); WRITEANSI(Messageareas.area_name+' ',False,True);
          FORE(Menu^[1].Tags[6]); WRITECHAR('[');
          FORE(Menu^[1].Tags[5]);
          IF UserLastReadMSG<HighMSGNumber THEN WRITECHAR('*');
          WRITEANSI(_String(TotalMessages),false,False);
          FORE(Menu^[1].Tags[6]); WRITEANSI('] ',false,false);
     END;
END;


PROCEDURE display_menu;
CONST Menu_Grid = 8;
VAR  loop                : word;
     loop2               : word;
     x                   : byte;
     cc                  : byte;
     sg                  : string;
     xx                  : word;
     yy                  : word;
     LastCommand         : Char;
     SystemTime          : String;

     PROCEDURE RedrawFooter;
     VAR  Looper : Word;
     BEGIN
          AnsiLeft(80);
          ClrEolANSI;
          do_header(False);
          system_prompt('',1,false,true);
          fore(7);
     END;

BEGIN
     SystemTime := _PadLeft(_GetPrettyTime,7);
     IF ((IsRip) AND (_FileExists(RIPDirectory+'\'+Loaded_Menu+'.RIP'))) THEN
     BEGIN
          IF (((Menu^[1].Tags[2]=2) OR (Menu^[1].Tags[2]=3)) AND NOT(Redraw_Menu)) THEN RedrawFooter
          ELSE
          BEGIN
               IF ((Menu^[1].Tags[2]=2) OR (Menu^[1].Tags[2]=3)) THEN
               BEGIN
                    DisplayGraphicsFile(Loaded_Menu,false,false,True,False,False);
                    AnsiHideEveryThing;
                    do_header(True);
                    AnsiShowEveryThing;
               END
               ELSE DisplayGraphicsFile(Loaded_Menu,false,false,True,False,False);
               system_prompt('',1,false,true);
               fore(7);
          END;
     END
     ELSE IF _FileExists(ANSIDirectory+'\'+Loaded_Menu+'.ANS') THEN
     BEGIN
          IF (((Menu^[1].Tags[2]=2) OR (Menu^[1].Tags[2]=3)) AND NOT(Redraw_Menu)) THEN RedrawFooter
          ELSE
          BEGIN
               IF ((Menu^[1].Tags[2]=2) OR (Menu^[1].Tags[2]=3)) THEN
               BEGIN
                    DisplayGraphicsFile(Loaded_Menu,True,false,True,False,False);
                    do_header(True);
                    AnsiHideEveryThing;
                    system_prompt('',1,false,true);
                    fore(7);
                    AnsiShowEveryThing;
               END
               ELSE DisplayGraphicsFile(Loaded_Menu,false,false,True,False,False);
          END;
     END
     ELSE
     BEGIN
          IF redraw_menu THEN
          BEGIN
               IF IsRip THEN ResetRip;
               AnsiHideEveryThing;
               WITH Menu^[1] DO
               BEGIN
                    CLRPORTSCR;
                    IF Tags[1]=1 THEN
                    BEGIN {PLAIN COLUMNS - DONE}
                         fore(Tags[4]);  WRITEANSI(#176#177#178,false,False);
                         fore(Tags[3]);
                         BACK(Tags[4]);  WRITEANSI(' '+Title,false,True);
                         WRITEANSI(_Replicate(' ',70-length(Process_Special(Title,True))-length(SystemTime)),False,False);
                         WRITEANSI(SystemTime+' ',false,False);
                         BACK(0);  fore(Tags[4]);
                         WRITEANSI(#178#177#176,true,False);
                         SendCrLf(1);
                         x := 0;
                         LastCommand := Chr(0);
                         FOR loop := 2 TO menu_count DO
                         BEGIN
                              IF MenuActive[Loop] THEN
                              BEGIN
                                   IF Menu^[loop].HotKey<>LastCommand THEN
                                   BEGIN
                                        LastCommand := Menu^[loop].HotKey;
                                        INC(x);
                                        IF x=3 THEN
                                        BEGIN
                                             x := 1;
                                             SendCrLf(1);
                                        END;
                                        fore(Tags[5]); WRITECHAR(Menu^[loop].HotKey);
                                        fore(Tags[6]); WRITEANSI('] ',false,False);
                                        fore(Tags[7]); WRITEANSI(Menu^[loop].Title,false,True);
                                        IF x=1 THEN
                                        BEGIN
                                             space(36-LENGTH(Process_Special(Menu^[loop].Title,True)));
                                        END;
                                   END;
                              END;
                         END;
                         SendCrLf(2);
                    END
                    ELSE IF Tags[1]=2 THEN
                    BEGIN {MULTI FRAME}
                         {MENU HEADING}
                         fore(8);  WRITEANSI(chr(196),false,False);
                         fore(7);  WRITECHAR(chr(196));
                         fore(15); WRITECHAR(chr(196)); WRITECHAR(chr(180));
                         fore(Tags[4]); WRITEANSI(#176#177#178,false,False);
                         fore(Tags[3]); BACK(Tags[4]);
                         WRITEANSI(' '+Title+' ',false,True);
                         BACK(0);  fore(Tags[4]);
                         WRITEANSI(#178#177#176,false,False);
                         fore(15); WRITECHAR(chr(195)); WRITECHAR(chr(196));
                         fore(7);  WRITECHAR(chr(196));
                         fore(8);  WRITECHAR(chr(196));
                         space(62-(length(Process_Special(Title,True))+length(SystemTime)));
                         fore(Tags[3]); WRITEANSI(SystemTime,true,False);
                         {TOP BAR}
                         fore(15);
                         WRITECHAR(chr(218));
                         FOR loop := 1 TO 19 DO
                         BEGIN
                              fore(15); WRITEANSI(chr(196)+chr(194),false,False);
                              WRITECHAR(chr(196));
                              fore(7);  WRITECHAR(chr(194));
                         END;
                         fore(15); WRITECHAR(chr(196));
                         fore(7);  WRITEANSI(chr(191),true,False);
                         {TOP WINDOW}
                         fore(15); WRITEANSI(chr(195)+chr(196),false,False);
                         fore(7);  WRITECHAR(chr(197));
                         fore(15); WRITECHAR(chr(196));
                         fore(7);  WRITECHAR(chr(201));
                         WRITEANSI(_Replicate(chr(205),69),False,False);
                         fore(8);  WRITECHAR(chr(187));
                         fore(8);  WRITECHAR(chr(196));
                         fore(15); WRITEANSI(chr(197)+chr(196)+chr(180),true,False);
                         {HERE!!}
                         fore(15); WRITEANSI(chr(195)+chr(196),false,False);
                         WRITECHAR(chr(197));
                         fore(15); WRITECHAR(chr(196));
                         fore(7);  WRITEANSI(chr(186)+' ',false,False);
                         x  := 0;
                         cc := 1;
                         LastCommand := Chr(0);
                         FOR loop := 2 TO menu_count DO
                         BEGIN
                              IF MenuActive[Loop] THEN
                              BEGIN
                                   IF Menu^[loop].HotKey<>LastCommand THEN
                                   BEGIN
                                        LastCommand := Menu^[loop].HotKey;
                                        INC(x);
                                        IF x=3 THEN
                                        BEGIN
                                             IF (cc=1) THEN cc := 2 ELSE cc := 1;
                                             x := 1;
                                             IF cc=1 THEN
                                             BEGIN
                                                  fore(8);  WRITEANSI(chr(186)+chr(196),false,False);
                                                  fore(15); WRITECHAR(chr(197));
                                                  WRITECHAR(chr(196)); fore(15);
                                                  WRITEANSI(chr(180),true,False);
                                                  fore(15); WRITEANSI(chr(195)+chr(196),false,False);
                                                  WRITECHAR(chr(197));
                                                  fore(15); WRITECHAR(chr(196));
                                                  fore(7);  WRITEANSI(chr(186)+' ',false,False);
                                             END
                                             ELSE
                                             BEGIN
                                                  fore(8);  WRITEANSI(chr(186)+chr(196),false,False);
                                                  fore(7);  WRITECHAR(chr(197));
                                                  fore(15); WRITECHAR(chr(196));
                                                  fore(7);  WRITEANSI(chr(180),true,False);
                                                  fore(15); WRITEANSI(chr(195)+chr(196),false,False);
                                                  fore(7);  WRITECHAR(chr(197));
                                                  fore(15); WRITECHAR(chr(196));
                                                  fore(7);  WRITEANSI(chr(186)+' ',false,False);
                                             END;
                                        END;
                                        fore(Tags[5]); WRITECHAR(Menu^[loop].HotKey);
                                        fore(Tags[6]); WRITEANSI('] ',false,False);
                                        fore(Tags[7]); WRITEANSI(Menu^[loop].Title,false,True);
                                        Space(31-LENGTH(Process_Special(Menu^[loop].Title,True)));
                                   END;
                              END;
                         END;
                         IF x=1 THEN Space(34);
                         IF cc=2 THEN
                         BEGIN
                              cc := 1;
                              fore(8);  WRITEANSI(chr(186)+chr(196),false,False);
                              fore(15); WRITECHAR(chr(197));
                              WRITECHAR(chr(196));
                              fore(15); WRITEANSI(chr(180),true,False);
                              fore(15); WRITEANSI(chr(195)+chr(196),false,False);
                              WRITECHAR(chr(197));
                              fore(15); WRITECHAR(chr(196));
                         END
                         ELSE
                         BEGIN
                              cc := 2;
                              fore(8);  WRITEANSI(chr(186)+chr(196),false,False);
                              fore(7);  WRITECHAR(chr(197));
                              fore(15); WRITECHAR(chr(196));
                              fore(7);  WRITEANSI(chr(180),true,False);
                              fore(15); WRITEANSI(chr(195)+chr(196),false,False);
                              fore(7);  WRITECHAR(chr(197));
                              fore(15); WRITECHAR(chr(196));
                         END;
                         {BOTTOM WINDOW}
                         fore(7); WRITECHAR(chr(200));
                         fore(8);
                         WRITEANSI(_Replicate(chr(205),69),False,False);
                         WRITECHAR(chr(188));
                         IF cc=2 THEN
                         BEGIN
                              cc := 1;
                              fore(8);  WRITECHAR(chr(196));
                              fore(15); WRITECHAR(chr(197));
                              WRITECHAR(chr(196));
                              fore(15); WRITEANSI(chr(180),true,False);
                         END
                         ELSE
                         BEGIN
                              cc := 2;
                              fore(8);  WRITECHAR(chr(196));
                              fore(7);  WRITECHAR(chr(197));
                              fore(15); WRITECHAR(chr(196));
                              fore(7);  WRITEANSI(chr(180),true,False);
                         END;
                         {BOTTOM BAR}
                         fore(15);
                         WRITECHAR(chr(192));
                         FOR loop := 1 TO 19 DO
                         BEGIN
                              fore(7);  WRITEANSI(chr(196)+chr(193),false,False);
                              WRITECHAR(chr(196));
                              fore(8);  WRITECHAR(chr(193));
                         END;
                         fore(15); WRITECHAR(chr(196));
                         fore(7);  WRITEANSI(chr(217),true,False);
                    END
                    ELSE IF Tags[1]=3 THEN
                    BEGIN {SOLID FRAME}
                         {MENU HEADING}
                         fore(8);  WRITEANSI(chr(196),false,False);
                         fore(7);  WRITECHAR(chr(196));
                         fore(15); WRITECHAR(chr(196));
                         WRITECHAR(chr(180));
                         fore(Tags[4]); WRITEANSI(#176#177#178,false,False);
                         fore(Tags[3]);
                         BACK(Tags[4]); WRITEANSI(' '+Title+' ',false,True);
                         BACK(0);
                         fore(Tags[4]); WRITEANSI(#178#177#176,false,False);
                         fore(15); WRITECHAR(chr(195)); WRITECHAR(chr(196));
                         fore(7);  WRITECHAR(chr(196));
                         fore(8);  WRITECHAR(chr(196));
                         space(62-(length(Process_Special(Title,True))+length(SystemTime)));
                         fore(Tags[3]);
                         WRITEANSI(SystemTime,true,False);
                         {TOP BAR}
                         fore(Menu_Grid);
                         WRITECHAR(chr(218));
                         FOR loop := 1 TO 38 DO
                         BEGIN
                              WRITECHAR(chr(196));
                              WRITECHAR(chr(194));
                         END;
                         WRITECHAR(chr(196));
                         WRITEANSI(chr(191),true,False);
                         {TOP WINDOW}
                         WRITEANSI(#195#196#197#196,false,False);
                         fore(7);         WRITECHAR(chr(201));
                         WRITEANSI(_Replicate(chr(205),69),False,False);
                         fore(8);         WRITECHAR(chr(187));
                         fore(menu_grid); WRITEANSI(#196#197#196#180,true,False);
                         fore(menu_grid); WRITEANSI(#195#196#197#196,false,False);
                         fore(7);         WRITEANSI(chr(186)+' ',false,False);
                         x  := 0;
                         LastCommand := Chr(0);
                         FOR loop := 2 TO menu_count DO
                         BEGIN
                              IF MenuActive[Loop] THEN
                              BEGIN
                                   IF Menu^[loop].HotKey<>LastCommand THEN
                                   BEGIN
                                        LastCommand := Menu^[loop].HotKey;
                                        INC(x);
                                        IF x=3 THEN
                                        BEGIN
                                             x := 1;
                                             fore(8);         WRITECHAR(chr(186));
                                             fore(menu_grid); WRITEANSI(#196#197#196#180,true,False);
                                             WRITEANSI(#195#196#197#196,false,False);
                                             fore(7);         WRITEANSI(chr(186)+' ',false,False);
                                        END;
                                        fore(Tags[5]); WRITECHAR(Menu^[loop].HotKey);
                                        fore(Tags[6]); WRITEANSI('] ',false,False);
                                        fore(Tags[7]); WRITEANSI(Menu^[loop].Title,false,True);
                                        Space(31-LENGTH(Process_Special(Menu^[loop].Title,True)));
                                   END;
                              END;
                         END;
                         IF x=1 THEN Space(34);
                         fore(8);         WRITECHAR(chr(186));
                         fore(menu_grid); WRITEANSI(#196#197#196#180,true,False);
                         WRITEANSI(#195#196#197#196,false,False);
                         {BOTTOM WINDOW}
                         fore(7); WRITECHAR(chr(200));
                         fore(8);
                         WRITEANSI(_Replicate(chr(205),69),False,False);
                         WRITECHAR(chr(188));
                         fore(menu_grid); WRITEANSI(#196#197#196#180,true,False);
                         {BOTTOM BAR}
                         fore(menu_grid); WRITECHAR(chr(192));
                         FOR loop := 1 TO 38 DO
                         BEGIN
                              WRITEANSI(chr(196)+chr(193),false,False);
                         END;
                         WRITECHAR(chr(196));
                         WRITEANSI(chr(217),true,False);
                    END;
                    do_header(True);
                    system_prompt('',1,false,true);
                    fore(7);
               END;
               AnsiShowEveryThing;
          END
          ELSE
          BEGIN
               AnsiHideEveryThing;
               RedrawFooter;
               AnsiShowEveryThing;
          END;
     END;
END;


END.
