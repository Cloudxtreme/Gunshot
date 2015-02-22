{$I DEFINES.INC}
UNIT Screens;


INTERFACE


FUNCTION  DisplayGIPFile     (ATemp: String)                                  : Boolean;
FUNCTION  DisplayGraphicFile (ATemp: String; UseBuf,IsTemporary,Log: Boolean) : Boolean;
PROCEDURE system_prompt      (insert_text: string; file_index: word);


IMPLEMENTATION


USES Status,Globals,_Main,ErrorLog,SBuffer,_Pick,_Mouse,
     Gr2_Bp,ExtDos,BsComp,Shotgun,BsFile,BsString;


PROCEDURE SetUpTextFile;
VAR  FFile : Text;
     Temp  : String;
     Work  : Word;
BEGIN
     ScreenNumber := 2;
     NewPickList(False);
     ChangeMouse(BusyMouse);
     ASSIGN(ffile,ThePickFile);
     RESET(ffile);
     REPEAT
           READLN(ffile,temp);
           REPEAT
                 Work := Pos(#9,temp);
                 IF work<>0 THEN
                 BEGIN
                      Delete(temp,work,1);
                      Insert('        ',temp,work);
                 END;
           UNTIL work=0;
           AddToPickList(' '+temp,0,False);
     UNTIL EOF(ffile);
     CLOSE(ffile);
     ChangeMouse(DefaultMouse);
     HideTheMouse;
     BeginPickList;
     SetUpPickList;
     ShowTheMouse;
END;


FUNCTION DisplayGraphicFile(ATemp: String; UseBuf,IsTemporary,Log: Boolean): Boolean;
BEGIN
     ATemp              := SGDirectory+'\'+ATemp+'.SG';
     UsingBuffer        := UseBuf;
     DidHeader          := False;
     DidHeader2         := False;
     DidMsgInfo         := False;
     DoingMessageEditor := False;
     IF (ThePickFile<>'') THEN KillPickList;
     ThePickFile        := '';
     IF _FileExists(ATemp) THEN
     BEGIN
          ScreenNumber := 0;
          RedrawScreen(Atemp,IsTemporary);
          Status_Line;
          DisplayGraphicFile := True;
          IF ((ThePickFile<>'') AND (_FileExists(ThePickFile))) THEN SetUpTextFile;
          Exit;
     END;
     IF Log THEN DoErrorLog(13,atemp);
     DisplayGraphicFile := False;
END;


FUNCTION UnpackTheGIP(VAR FName: String): Boolean;
TYPE DecompBuffer  = Array[1..8192] Of Byte;
VAR  Buffer        : ^DecompBuffer;
     FFile         : File;
     FFile2        : File;
     GIPHeader     : _GIPHeader;
     GIPFileHeader : _GIPFileHeader;
     GetBytes      : Longint;
     OutFile       : String;
BEGIN
     IF _FileExists(FName) THEN
     BEGIN
          clear_gip_dir;
          New(Buffer);
          ASSIGN(FFile,FName);
          RESET(FFile,1);
          BLOCKREAD(FFile,GIPHeader,SizeOf(GIPHeader));
          REPEAT
                BLOCKREAD(FFile,GIPFileHeader,SizeOf(GIPFileHeader));
                GetBytes := GIPFileHeader.FileLength;
                ASSIGN(FFile2,GIP_Directory+'\COMPRESS.TMP');
                REWRITE(FFile2,1);
                REPEAT
                      IF GetBytes>SizeOf(Buffer^) THEN
                      BEGIN
                           BLOCKREAD(FFile,Buffer^,SizeOf(Buffer^));
                           BLOCKWRITE(FFile2,Buffer^,SizeOf(Buffer^));
                           DEC(GetBytes,SizeOf(Buffer^));
                      END
                      ELSE
                      BEGIN
                           BLOCKREAD(FFile,Buffer^,GetBytes);
                           BLOCKWRITE(FFile2,Buffer^,GetBytes);
                           GetBytes := 0;
                      END;
                UNTIL (GetBytes=0);
                CLOSE(FFile2);
                OutFile := GIP_Directory+'\'+GIPFileHeader.FName;
                IF _GetFileExtension(GIPFileHeader.FName)='SG'
                   THEN FName := GIP_Directory+'\'+GIPFileHeader.FName;
                DecompressFile(GIP_Directory+'\COMPRESS.TMP',OutFile);
                _EraseFile(GIP_Directory+'\COMPRESS.TMP');
          UNTIL EOF(FFile);
          CLOSE(FFile);
          Dispose(Buffer);
          UnpackTheGIP := True;
     END
     ELSE UnpackTheGIP := False;
END;


FUNCTION DisplayGIPFile(ATemp: String): Boolean;
VAR  OldRes : String;
BEGIN
     IF UnpackTheGIP(ATemp) THEN
     BEGIN
          UsingBuffer        := False;
          DidHeader          := False;
          DidHeader2         := False;
          DidMsgInfo         := False;
          DoingMessageEditor := False;
          IF (ThePickFile<>'') THEN KillPickList;
          ThePickFile        := '';
          ScreenNumber := 0;
          OldRes := RESOURCES;
          RESOURCES := GIP_Directory+'\';
          RedrawScreen(Atemp,True);
          RESOURCES := OldRes;
          Status_Line;
          DisplayGIPFile := True;
          IF ((ThePickFile<>'') AND (_FileExists(ThePickFile))) THEN SetUpTextFile;
          Exit;
     END;
     DoErrorLog(13,atemp);
     DisplayGIPFile := False;
END;


PROCEDURE system_prompt(insert_text: string;file_index: word);
VAR  Temp          : String;
BEGIN
     Temp := '_P'+_String(file_index);
     ClearBuffer;
     AddToBuffer('@INSERT',Insert_text);
     DisplayGraphicFile(Temp,True,True,True);
END;


END.
