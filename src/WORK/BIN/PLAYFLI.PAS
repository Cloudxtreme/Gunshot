{$M 16384,0,16384}
{$I DEFINES.INC}
PROGRAM PlayFLI;


USES gx_tp,gx_tpvc,fx_tp,Crt,BsMouse;


CONST BUFMAX   = 10000;
VAR   flichdr  : FLICHEADER;
      buffer   : Array [0..BUFMAX-1] Of Byte;
      FileName : String;
      Error    : Integer;
      ch       : Char;
      Revs     : Word;
      x        : Word;
      y        : Word;
      gxtype   : Integer;
      di       : GXDINFO;


FUNCTION ITOS(num: Longint): String;
VAR  tempstr : String;
BEGIN
     Str(num,tempstr);
     ITOS := tempstr;
END;


FUNCTION _Numeric(InString: String): Longint;
VAR  Code : Integer;
     Temp : Longint;
BEGIN
     VAL(InString,Temp,Code);
     _Numeric := Temp;
END;


FUNCTION DisplayNextFrame(VAR ffile: FLICFILE; VAR fframe: FLICFRAME): Integer;
VAR  retcode : Integer;
BEGIN
     retcode := flicFileFrame(ffile,fframe);
     IF (retcode=fxSUCCESS) THEN
     BEGIN
          retcode := flicFrameDisplay(fframe,x,y,0);
          IF ((retcode=fxSUCCESS) OR (retcode=fxERR_UNKNOWNCHUNK)) THEN
          BEGIN
               retcode := fxSUCCESS;
          END;
     END;
     DisplayNextFrame := retcode;
END;


FUNCTION PlayFlic(fname: String): Integer;
VAR  retcode   : Integer;
     nframes   : Integer;
     i         : Integer;
     fsize     : Longint;
     fframe    : FLICFRAME;
     ffile     : FLICFILE;
     Loop      : Word;
     Barf      : Byte;
     x1,y1     : Word;
LABEL            SkipOut;
BEGIN
     IF Mouse_Installed THEN
     BEGIN
          REPEAT
          UNTIL _MousePosition(x1,y1)=0;
     END;
     retcode := flicOpenFile(fname,ffile,@buffer,BUFMAX);
     IF (retcode=fxSUCCESS) THEN
     BEGIN
          nframes := ffile.nframes;
          fsize := flicGetMaxFrameSize(ffile);
          IF (fsize>=0) THEN
          BEGIN
               retcode := flicCreateFrame(gxCMM,fframe,fsize);
               IF (retcode=fxSUCCESS) THEN
               BEGIN
                    retcode := DisplayNextFrame(ffile,fframe);
                    IF (retcode=fxSUCCESS) THEN
                    BEGIN
                         IF (Revs<>0) THEN
                         BEGIN
                              FOR Loop := 1 TO Revs DO
                              BEGIN
                                   i := 0;
                                   WHILE ((i<nframes) AND (retcode=gxSUCCESS)) DO
                                   BEGIN
                                        retcode := DisplayNextFrame(ffile,fframe);
                                        retcode := gxDelay(ffile.speed);
                                        i:= i + 1;
                                   END;
                              END;
                         END
                         ELSE
                         BEGIN
                              Barf := 0;
                              REPEAT
                                    i := 0;
                                    WHILE ((i<nframes) AND (retcode=gxSUCCESS)) DO
                                    BEGIN
                                         retcode := DisplayNextFrame(ffile,fframe);
                                         retcode := gxDelay(ffile.speed);
                                         i:= i + 1;
                                         IF Mouse_Installed THEN
                                         BEGIN
                                              IF (_MousePosition(x1,y1)<>0) THEN GOTO SkipOut;
                                         END;
                                         IF KeyPressed THEN
                                         BEGIN
                                              WHILE KeyPressed DO Ch := ReadKey;
                                              GOTO SkipOut;
                                         END;
                                    END;
                              UNTIL Barf=32768;
                         END;
                         SkipOut:
                    END;
                    retcode := flicDestroyFrame(fframe);
               END;
          END;
          retcode := flicCloseFile(ffile);
     END;
     PlayFlic := retcode;
END;


BEGIN
     FileName  := ParamStr(1);
     Revs      := _Numeric(ParamStr(3));
     IF (ParamStr(2)<>'$$BB$$SS$$') THEN Halt;
     gxInit;
     Error := flicGetFileHeader(filename,flichdr);
     IF Error=fxSUCCESS THEN
     BEGIN
          gxtype := gxVGA_13;
          IF ((flichdr.width>320) OR (flichdr.height>200)) THEN gxtype := gxVESA_101;
          Error := gxGetDisplayInfo(gxtype,di);
          x := (di.hres-flichdr.width) DIV 2;
          y := (di.vres-flichdr.height) DIV 2;
          Error := gxSetDisplay(gxtype);
          Error := gxSetMode(gxGRAPHICS);
          IF (Error=gxSUCCESS) THEN
          BEGIN
               _InitMouse;
               PlayFlic(filename);
               gxClearDisplay(0,0);
          END;
          gxSetMode(gxText);
     END;
     gxDone;
END.
