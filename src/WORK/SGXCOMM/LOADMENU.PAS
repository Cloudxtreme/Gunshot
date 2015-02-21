{$I DEFINES.INC}
UNIT LoadMenu;


INTERFACE


PROCEDURE load_menu(TheMenu: string);


IMPLEMENTATION


USES Globals,GotKeys,BsFile,BsString;


PROCEDURE load_menu(TheMenu: string);
VAR  FMenu   : File;
     NumRead : Word;
     Loop    : Word;
BEGIN
     LastMenuLoaded := TheMenu;
     loaded_menu    := _NoExtension(TheMenu);
     TheMenu        := Menu_Directory+'\'+TheMenu;
     FillChar(MenuActive,SizeOf(MenuActive),0);
     ASSIGN(FMenu,TheMenu);
     {$I-}
     RESET(FMenu,1);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          BLOCKREAD(FMenu,Menu^,SizeOf(Menu^),NumRead);
          CLOSE(FMenu);
          Menu_Count := Trunc(NumRead/SizeOf(Menu^[1]));
          FOR Loop := 2 TO Menu_Count DO
          BEGIN
               IF (UserRecord.security>=Menu^[Loop].Access) THEN
               BEGIN
                    IF GotTheKeys(UserRecord.Tags,Menu^[Loop].Tags) THEN
                    BEGIN
                         IF Menu^[Loop].SVGA=1 THEN MenuActive[Loop] := True;
                    END;
               END;
          END;
     END;
END;


END.