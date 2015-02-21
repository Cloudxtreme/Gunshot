{$M 16384,0,16384}
{$I DEFINES.INC}
PROGRAM PlayVoc;

{$IFDEF DPMI}
REAL MODE ONLY!
{$ENDIF}

USES Fx_Tp;


VAR  VocFile  : FXSOUND;
     ssize    : Longint;
     rc       : Integer;
     FileName : String;
     Loop     : Word;


BEGIN
     FileName  := ParamStr(1);
     IF (ParamStr(2)<>'$$BB$$SS$$') THEN Halt;
     IF (fxSBInstalled=fxSUCCESS) THEN
     BEGIN
          IF (fxInstallSound(fxSOUNDBLASTER)=fxSUCCESS) THEN
          BEGIN
               ssize := fxFileSoundSize(FileName,fxVOC);
               IF (ssize>0) THEN
               BEGIN
                    rc := fxCreateSound(VocFile,fxVOC,ssize);
                    IF (rc=fxSUCCESS) THEN
                    BEGIN
                         rc := fxFileSound(FileName,VocFile);
                         IF (rc=fxSUCCESS) THEN
                         BEGIN
                              rc := fxPlaySound(VocFile,0,1,fxFORE);
                              rc := fxDestroySound(VocFile);
                              rc := fxRemoveSound(fxSOUNDBLASTER);
                         END
                         ELSE
                         BEGIN
                              rc := fxDestroySound(VocFile);
                              rc := fxRemoveSound(fxSOUNDBLASTER);
                         END;
                    END
                    ELSE rc := fxRemoveSound(fxSOUNDBLASTER);
               END
               ELSE rc := fxRemoveSound(fxSOUNDBLASTER);
          END;
     END;
END.
