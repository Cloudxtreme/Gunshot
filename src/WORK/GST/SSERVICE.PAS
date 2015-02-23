{$I DEFINES.INC}
UNIT SService;


INTERFACE


PROCEDURE SortServices;


IMPLEMENTATION


USES Globals,BsString,__Gfx,
     {$IFDEF DPMI}
     Gr2_Bp;
     {$ELSE}
     Gr_Tp;
     {$ENDIF}


PROCEDURE SortServices;
VAR  DialDir1  : Dial_Dir;
     DialDir2  : Dial_Dir;
     TempFile  : Dial_Dir;
     FFileSize : Longint;
     I,J       : Longint;
BEGIN
     ASSIGN(FDialDir,'GST.DIR');
     RESET(FDialDir);
     FFileSize := FileSize(FDialDir);
     FOR i := 1 TO FFileSize DO
     BEGIN
          FOR j := 1 TO FFileSize DO
          BEGIN
               SEEK(FDialDir,i-1); READ(FDialDir,DialDir1);
               SEEK(FDialDir,j-1); READ(FDialDir,DialDir2);
               IF (_UpperCase(DialDir1.Name)<_UpperCase(DialDir2.Name)) THEN
               BEGIN
                    TempFile := DialDir1;
                    DialDir1 := DialDir2;
                    DialDir2 := TempFile;
                    SEEK(FDialDir,i-1); WRITE(FDialDir,DialDir1);
                    SEEK(FDialDir,j-1); WRITE(FDialDir,DialDir2);
               END;
          END;
     END;
     CLOSE(FDialDir);
     PickInfo.NumItems := 0;
     ASSIGN(FDialDir,'GST.DIR');
     RESET(FDialDir);
     REPEAT
           READ(FDialDir,DialDir);
           AddToPickList(' '+_PadRight(DialDir.Name,30)+_PadRight(DialDir.Phone,20));
     UNTIL EOF(FDialDir);
     CLOSE(FDialDir);
     grDisplayMouse(GrHide);
     SetUpPickList;
     grDisplayMouse(GrShow);
END;


END.