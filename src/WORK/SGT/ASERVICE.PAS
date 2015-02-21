{$I DEFINES.INC}
UNIT AService;


INTERFACE


PROCEDURE AddService;


IMPLEMENTATION


USES Globals,__Gfx,EService,BsString;


PROCEDURE AddService;
VAR  LastOne : Word;
BEGIN
     FillChar(DialDir,SizeOf(DialDir),0);
     DialDir.DoESCs := True;
     DialDir.Sound  := True;
     ASSIGN(FDialDir,'SGT.DIR');
     {$I-}RESET(FDialDir);{$I+}
     IF IOResult<>0 THEN REWRITE(FDialDir);
     SEEK(FDialDir,FileSize(FDialDir));
     WRITE(FDialDir,DialDir);
     LastOne := FileSize(FDialDir);
     CLOSE(FDialDir);
     AddToPickList(' '+_PadRight(DialDir.Name,30)+_PadRight(DialDir.Phone,20));
     EditService(LastOne);
END;


END.