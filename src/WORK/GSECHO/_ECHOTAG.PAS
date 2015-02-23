{$I DEFINES.INC}
UNIT _EchoTag;


INTERFACE


USES MkFFile;


VAR  FEchoTag          : FFileObj;
     IsEchoTagFileOpen : Boolean;


PROCEDURE OpenGSEchoDat;
PROCEDURE CloseGSEchoDat;


IMPLEMENTATION


USES BsFile,Globals,FMode;


PROCEDURE OpenGSEchoDat;
BEGIN
     IF NOT(IsEchoTagFileOpen) THEN
     BEGIN
       IF _FileExists(BaseDirectory+'\DATA\GSECHO.DAT') THEN
       BEGIN
         FEchoTag.OpenFile(BaseDirectory+'\DATA\GSECHO.DAT',SetFileMode);
         IsEchoTagFileOpen := True;
       END;
     END
     ELSE FEchoTag.SeekFile(0);
END;


PROCEDURE CloseGSEchoDat;
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