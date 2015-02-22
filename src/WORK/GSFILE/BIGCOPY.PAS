{$I DEFINES.INC}
UNIT BigCopy;


INTERFACE


FUNCTION _BigCopyFile(FName,FPath,TPath: String): Boolean;


IMPLEMENTATION


USES Globals;


FUNCTION _BigCopyFile(FName,FPath,TPath: String): Boolean;
VAR  Source     : File;
     Dest       : File;
     NumRead    : Word;
     NumWritten : Word;
     Tries      : Byte;
LABEL             Redo;
BEGIN
     IF FPath[LENGTH(FPath)]<>'\' THEN FPath := FPath+'\';
     IF TPath[LENGTH(TPath)]<>'\' THEN TPath := TPath+'\';
     FPath := FPath+FName;
     TPath := TPath+FName;
     Tries := 0;
     Redo:
     ASSIGN(Source,FPath);
     {$I-}RESET(Source,1);{$I+}
     IF IOResult=0 THEN
     BEGIN
          ASSIGN(Dest,TPath);
          {$I-}REWRITE(Dest,1);{$I+}
          IF IOResult=0 THEN
          BEGIN
               REPEAT
                     BlockRead(Source,MassiveBuffer^,SizeOf(MassiveBuffer^),NumRead);
                     BlockWrite(Dest,MassiveBuffer^,NumRead,NumWritten);
               UNTIL ((NumRead=0) OR (NumWritten<>NumRead));
               CLOSE(Source);
               CLOSE(Dest);
               IF NumWritten<>NumRead THEN
               BEGIN
                    INC(Tries);
                    IF Tries<3 THEN GOTO Redo;
                    _BigCopyFile := False;
               END
               ELSE _BigCopyFile := True;
          END
          ELSE
          BEGIN
               CLOSE(Source);
               _BigCopyFile := False;
          END;
     END
     ELSE _BigCopyFile := False;
END;


END.