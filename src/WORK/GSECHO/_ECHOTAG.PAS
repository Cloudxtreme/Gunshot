{$I DEFINES.INC}
UNIT _EchoTag;


INTERFACE


USES MkFFile;


VAR  FEchoTag          : FFileObj;
     IsEchoTagFileOpen : Boolean;


PROCEDURE OpenSGEchoDat;
PROCEDURE CloseSGEchoDat;


IMPLEMENTATION


USES BsFile,Globals,FMode;


PROCEDURE OpenSGEchoDat;
BEGIN
     IF NOT(IsEchoTagFileOpen) THEN
     BEGIN
       IF _FileExists(BaseDirectory+'\DATA\SGECHO.DAT') THEN
       BEGIN
         FEchoTag.OpenFile(BaseDirectory+'\DATA\SGECHO.DAT',SetFileMode);
         IsEchoTagFileOpen := True;
       END;
     END
     ELSE FEchoTag.SeekFile(0);
END;


PROCEDURE CloseSGEchoDat;
BEGIN
     IF IsEchoTagFileOpen THEN
     BEGIN
       FEchoTag.CloseFile;
       IsEchoTagFileOpen := False;
     END;
END;


BEGIN
     IsEchoTagFileOpen := False;
END.