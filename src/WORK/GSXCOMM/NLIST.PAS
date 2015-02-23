{$I DEFINES.INC}
UNIT NList;


INTERFACE


USES Gunshot;


FUNCTION NodeListEntryFound(InAddr: AddrType): Boolean;


IMPLEMENTATION


USES Globals,ErrorLog,MkFFile,FMode,BsAkas,BsFile;


FUNCTION NodeListEntryFound(InAddr: AddrType): Boolean;
VAR  BytesRead        : Word;
     NodeIndx         : _NodeIndx_Sg;
     FNodeIndx        : FFileObj;
     FNodeList        : FFileObj;
     NodeListAka      : AddrType;
     NodeListBaud     : Longint;
     NodeListSysop    : String;
BEGIN
     IF _FileExists(MessageAreas.NodeList+'NODEINDX.SG') THEN
     BEGIN
       FNodeIndx.Init(8192);
       IF FNodeIndx.OpenFile(MessageAreas.NodeList+'NODEINDX.SG',SetFileMode) THEN
       BEGIN
         REPEAT
           FNodeIndx.BlkRead(NodeIndx,SizeOf(NodeIndx),BytesRead);
           IF (BytesRead<>0) THEN
           BEGIN
             IF AkasMatch(NodeIndx.Aka,InAddr) THEN
             BEGIN
               FNodeIndx.CloseFile;
               FNodeIndx.Done;
               FNodeList.Init(8192);
               IF FNodeList.OpenFile(MessageAreas.NodeList+'NODELIST.SG',SetFileMode) THEN
               BEGIN
                 FNodeList.SeekFile(NodeIndx.ByteOffSet+2);
                 FNodeList.BlkRead(NodeListAka,SizeOf(NodeListAka),BytesRead);
                 FNodeList.BlkRead(NodeListBaud,SizeOf(NodeListBaud),BytesRead);
                 FNodeList.BlkRead(NodeListSysop[0],1,BytesRead);
                 FNodeList.BlkRead(NodeListSysop[1],Ord(NodeListSysop[0]),BytesRead);
                 FNodeList.BlkRead(NodeListSystem[0],1,BytesRead);
                 FNodeList.BlkRead(NodeListSystem[1],Ord(NodeListSystem[0]),BytesRead);
                 FNodeList.CloseFile;
               END;
               FNodeList.Done;
               NodeListEntryFound := True;
               Exit;
             END;
           END;
         UNTIL BytesRead=0;
         FNodeIndx.CloseFile;
       END;
       FNodeIndx.Done;
     END
     ELSE
     BEGIN
       DoErrorLog(16,MessageAreas.NodeList+'NODEINDX.SG');
       DoErrorLog(16,MessageAreas.NodeList+'NODELIST.SG');
     END;
     NodeListEntryFound := False;
END;


END.