{$I DEFINES.INC}
UNIT _Extern;


INTERFACE


PROCEDURE PlayFLIFile(FileName: String);


IMPLEMENTATION


USES BsLog,Globals,Gx2_Bp,Gx2_BpVC,BsGraph,Execute,_Save,_Virtual,Crt,
     BsFile;
(*
USES LogFile,Bs,Globals,Gx2_Bp,Gx2_BpVC,Graphics,Execute,_Save,_Virtual,
     Effects,Crt,Fx2_Bp;


FUNCTION DisplayNextFrame(VAR ffile: FLICFILE; VAR fframe: FLICFRAME): Integer;
VAR  retcode : Integer;
BEGIN
     retcode := flicFileFrame(ffile,fframe);
     IF (retcode=fxSUCCESS) THEN
     BEGIN
          retcode := flicFrameDisplay(fframe,0,0,0);
          IF ((retcode=fxSUCCESS) OR (retcode=fxERR_UNKNOWNCHUNK)) THEN retcode := fxSUCCESS;
     END;
     DisplayNextFrame := retcode;
END;


PROCEDURE PlayFLIFile(FileName: String);
TYPE f_buffer = Array [0..31999] Of Byte;
VAR  flichdr  : FLICHEADER;
     ch       : Char;
     fbuffer  : ^f_buffer;
     RetCode  : Integer;
     nframes  : Integer;
     i        : Integer;
     fsize    : Longint;
     fframe   : FLICFRAME;
     ffile    : FLICFILE;
BEGIN
     NEW(fbuffer);
     retcode := flicOpenFile(FileName,ffile,@fbuffer^,32000);
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
                         REPEAT
                               i := 0;
                               WHILE ((i<nframes) AND (retcode=gxSUCCESS) AND NOT(KeyPressed)) DO
                               BEGIN
                                    retcode := DisplayNextFrame(ffile,fframe);
                                    retcode := gxDelay(ffile.speed);
                                    i:= i + 1;
                               END;
                         UNTIL KeyPressed;
                         WHILE KeyPressed DO Ch := ReadKey;
                    END;
                    retcode := flicDestroyFrame(fframe);
               END;
          END;
          retcode := flicCloseFile(ffile);
     END;
     DISPOSE(fbuffer);
END;
*)


PROCEDURE PlayFLIFile(FileName: String);
VAR  C : Char;
BEGIN
     bsWriteLog('Viewing FLI file: '+_NoPath(FileName),False);
     Save_Mouse;
     CreateVirtual(SvScreen,GraphMaxX+1,GraphMaxY+1,TheDisplay);
     gxDisplayVirtual(0,0,GraphMaxX,GraphMaxY,0,SvScreen,0,0);
     Fade_Out;
     gxClearDisplay(0,0);
     ExecuteDOSCommand(Bin_Directory+'\PLAYFLI.EXE '+FileName+' $$BB$$SS$$ 0');
     GxSetDisplay(TheDisplay);
     GxSetMode(GxGraphics);
     gxSetConvertPalette(GxPAL5,@P256);
     GxSetDisplayPalette(@P256);
     Fade_Off;
     gxVirtualDisplay(SvScreen,0,0,0,0,GraphMaxX,GraphMaxY,0);
     Fade_In;
     DestroyVirtual(SvScreen);
     load_mouse;
     REPEAT IF KeyPressed THEN c := ReadKey; UNTIL NOT(KeyPressed);
END;



END.
