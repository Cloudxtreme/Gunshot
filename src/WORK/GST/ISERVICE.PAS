{$I DEFINES.INC}
UNIT IService;


INTERFACE


PROCEDURE InsertService(Index: Word);


IMPLEMENTATION


USES Globals,__Gfx,EService,BsString;


PROCEDURE InsertService(Index: Word);
VAR  FDialDir2 : File Of Dial_Dir;
     DialDir2  : Dial_Dir;
     Counter   : Word;
BEGIN
     FillChar(DialDir2,SizeOf(DialDir2),0);
     DialDir2.DoESCs := True;
     DialDir2.Sound  := True;
     ASSIGN(FDialDir,'GST.DIR');
     RENAME(FDialDir,'GST.BK$');
     Counter := 0;
     ASSIGN(FDialDir2,'GST.BK$');
     ASSIGN(FDialDir,'GST.DIR');
     REWRITE(FDialDir);
     RESET(FDialDir2);
     REPEAT
           READ(FDialDir2,DialDir);
           INC(Counter);
           IF Counter=Index THEN WRITE(FDialDir,DialDir2);
           WRITE(FDialDir,DialDir);
     UNTIL EOF(FDialDir2);
     CLOSE(FDialDir2);
     ERASE(FDialDir2);
     CLOSE(FDialDir);
     PickInfo.NumItems := 0;
     ASSIGN(FDialDir,'GST.DIR');
     RESET(FDialDir);
     REPEAT
           READ(FDialDir,DialDir);
           AddToPickList(' '+_PadRight(DialDir.Name,30)+_PadRight(DialDir.Phone,20));
     UNTIL EOF(FDialDir);
     CLOSE(FDialDir);
     EditService(Index);
END;


END.