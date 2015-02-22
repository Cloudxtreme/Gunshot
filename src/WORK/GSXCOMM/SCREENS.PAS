{$I DEFINES.INC}
UNIT Screens;


INTERFACE


FUNCTION  DisplayGIPFile     (ATemp: String)                                  : Boolean;
FUNCTION  DisplayGraphicFile (ATemp: String; UseBuf,IsTemporary,Log: Boolean) : Boolean;
PROCEDURE system_prompt      (insert_text: string; file_index: word);


IMPLEMENTATION


USES Globals,Gfx,BsFile,Status,BsComp,ErrorLog,SBuffer,BsString;


PROCEDURE SetUpTextFile;
VAR  FFile : Text;
     Temp  : String;
     Work  : Word;
BEGIN
     SetScreenNumber(2);
     NewPickList(False);
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
     BeginPickList;
END;


FUNCTION DisplayGraphicFile(ATemp: String; UseBuf,IsTemporary,Log: Boolean): Boolean;
VAR  CompScreen : String;
     FFile      : File;
BEGIN
     CompScreen  := SGXDirectory+'\'+ATemp+'.SGX';
     ATemp       := SGDirectory+'\'+ATemp+'.SG';
     UsingBuffer := UseBuf;
     DidHeader   := False;
     DidHeader2  := False;
     DidMsgInfo  := False;
     IF (ThePickFile<>'') THEN KillPickList;
     ThePickFile        := '';
     IF ((_FileExists(ATemp)) AND (_FileExists(CompScreen))) THEN
     BEGIN
          ScreenNumber := 0;
          Status_Line;
          IF UsingBuffer THEN
          BEGIN
               WorkBuffer[InBuffer+1].Token := '';
               WorkBuffer[InBuffer+1].Replacement := '';
               ASSIGN(FFile,NODE_Directory+'\BUFFER.DAT');
               REWRITE(FFile,1);
               BLOCKWRITE(FFile,WorkBuffer,SizeOf(BufferItem)*(InBuffer+1));
               CLOSE(FFile);
               pCompressFile(NODE_Directory+'\BUFFER.DAT',NODE_Directory+'\BUFFER.CMP');
               SendSystemFile(NODE_Directory+'\BUFFER.CMP');
          END;
          SendScreenFile(CompScreen);
          RedrawScreen(Atemp,IsTemporary);
          Status_Line;
          DisplayGraphicFile := True;
          IF ((ThePickFile<>'') AND (_FileExists(ThePickFile))) THEN SetUpTextFile;
          Exit;
     END;
     IF Log THEN DoErrorLog(13,atemp);
     DisplayGraphicFile := False;
END;


PROCEDURE system_prompt(insert_text: string;file_index: word);
VAR  Temp          : String;
BEGIN
     Temp := '_P'+_String(file_index);
     ClearBuffer;
     AddToBuffer('@INSERT',Insert_text);
     DisplayGraphicFile(Temp,True,True,True);
END;


FUNCTION DisplayGIPFile(ATemp: String): Boolean;
BEGIN
     UsingBuffer        := False;
     DidHeader          := False;
     DidHeader2         := False;
     DidMsgInfo         := False;
     IF (ThePickFile<>'') THEN KillPickList;
     ThePickFile        := '';
     IF _FileExists(ATemp) THEN
     BEGIN
          ScreenNumber := 0;
          Status_Line;
          SendGipFile(ATemp);
          Status_Line;
          DisplayGipFile := True;
          Exit;
     END;
     DoErrorLog(13,atemp);
     DisplayGIPFile := False;
END;


END.