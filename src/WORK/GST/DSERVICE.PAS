{$I DEFINES.INC}
UNIT DService;


INTERFACE


PROCEDURE DeleteService(Index: Word);


IMPLEMENTATION


USES Globals,__Gfx,BsString,
     {$IFDEF DPMI}
     Gr2_Bp;
     {$ELSE}
     Gr_Tp;
     {$ENDIF}


PROCEDURE DeleteService(Index: Word);
VAR  FDialDir2 : File Of Dial_Dir;
     Counter   : Word;
BEGIN
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
           IF (Counter<>Index) THEN WRITE(FDialDir,DialDir);
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
     IF (PickInfo.Current>PickInfo.NumItems) THEN DEC(PickInfo.Current);
     grDisplayMouse(GrHide);
     SetUpPickList;
     grDisplayMouse(GrShow);
END;


END.