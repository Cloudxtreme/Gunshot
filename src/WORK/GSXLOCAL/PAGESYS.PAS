{$I DEFINES.INC}
UNIT PageSys;


INTERFACE


PROCEDURE page;


IMPLEMENTATION


USES Globals,Crt,Screens,BsLog,KeyInput,Execute,
     Time,_Save,_Mouse,BsMulti,BsFile;


PROCEDURE page;
VAR  GoodTime : Boolean;

     PROCEDURE PlaySpeaker;
     VAR  Loop : Word;
     BEGIN
          IF ((NodeInfo^.UseBlaster) AND (_FileExists(Gunshot_Directory+'\SOUND\PAGE.VOC'))) THEN
          BEGIN
               Save_Mouse;
               ExecuteDOSCommand(Bin_Directory+'\PLAYVOC.EXE '+
                                 Gunshot_Directory+'\SOUND\PAGE.VOC $$BB$$SS$$');
               Load_Mouse;
          END
          ELSE
          BEGIN
               ChangeMouse(BusyMouse);
               FOR Loop := 1 TO 3 DO
               BEGIN
                    sound(1600);  delay(30);
                    sound(1900);  delay(30);
                    nosound;
                    delay(350);
               END;
               ChangeMouse(DefaultMouse);
          END;
     END;

BEGIN
     bsWriteLog('User is paging the sysop',False);
     IF (user_pages<system_info.Page_Max) THEN
     BEGIN
          INC(user_pages);
          IF UserRecord.page=1 THEN
          BEGIN
               GoodTime := False;
               IF (system_info.page_start<system_info.page_end) THEN
               BEGIN
                    IF ((Getting_Time>system_info.page_start) AND
                       (Getting_Time<system_info.Page_end))
                       THEN GoodTime := True;
               END
               ELSE IF (system_info.page_start=system_info.page_end) THEN
               BEGIN
                    GoodTime := True;
               END
               ELSE
               BEGIN
                    IF ((Getting_Time>system_info.page_start) OR
                       (Getting_Time<system_info.Page_end))
                       THEN GoodTime := True;
               END;
               IF GoodTime THEN
               BEGIN
                    System_Prompt('',112);
                    PlaySpeaker;
                    IF DisplayGraphicFile('DONEPAGE',false,True,True) THEN Get_Enter;
               END
               ELSE
               BEGIN
                    bsWriteLog('Current time is outside of paging hours',False);
                    System_Prompt('',142);
                    Get_Enter;
               END;
          END
          ELSE
          BEGIN
               bsWriteLog('User does not have paging rights',False);
               System_Prompt('',143);
               Get_Enter;
          END;
     END
     ELSE
     BEGIN
          bsWriteLog('The user has paged too many times for this session',False);
          System_Prompt('',144);
          Get_Enter;
     END;
END;


END.
