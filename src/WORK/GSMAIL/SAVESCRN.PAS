{$I DEFINES.INC}
UNIT SaveScrn;


INTERFACE


PROCEDURE SaveScreen    (Num: Word);
PROCEDURE RestoreScreen (Num: Word);


IMPLEMENTATION


USES Globals,BsString,BsFile;


PROCEDURE SaveScreen(Num: Word);
TYPE WorkScreen = Array[1..8000] Of Byte;
VAR  Work       : ^WorkScreen;
     FFile      : File;
BEGIN
     New(Work);
     Move(MEM[SegB800:0],Work^,ScreenBytes);
     ASSIGN(FFile,Shotgun_Directory+'\TEMP\SGM'+_String(SimNode)+'.'+_String(Num));
     REWRITE(FFile,1);
     BLOCKWRITE(FFile,Work^,SizeOf(Work^));
     CLOSE(FFile);
     Dispose(Work);
END;


PROCEDURE RestoreScreen(Num: Word);
TYPE WorkScreen = Array[1..8000] Of Byte;
VAR  Work       : ^WorkScreen;
     FFile      : File;
BEGIN
     IF _FileExists(Shotgun_Directory+'\TEMP\SGM'+_String(SimNode)+'.'+_String(Num)) THEN
     BEGIN
          New(Work);
          ASSIGN(FFile,Shotgun_Directory+'\TEMP\SGM'+_String(SimNode)+'.'+_String(Num));
          RESET(FFile,1);
          BLOCKREAD(FFile,Work^,SizeOf(Work^));
          CLOSE(FFile);
          Move(Work^,MEM[SegB800:0],ScreenBytes);
          Dispose(Work);
     END;
END;


END.