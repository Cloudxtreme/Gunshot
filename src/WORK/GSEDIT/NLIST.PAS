{$I DEFINES.INC}
UNIT NList;


INTERFACE


USES Gunshot;


FUNCTION  GetNodeInfo (InAddress: AddrType): String;
FUNCTION  GetNetInfo  (InAddress: AddrType): String;
FUNCTION  GetBBSName  (InAddress: AddrType): String;


IMPLEMENTATION


USES Misc,FMode,MkFFile,Globals,BsAkas,BsFile,BsString;


PROCEDURE LoadFromNodeList(ByteStart: Longint);
VAR  BytesRead : Word;
BEGIN
     IF FNodeList.OpenFile(MailerInfo.NodeList+'NODELIST.SG',SetFileMode) THEN
     BEGIN
       FNodeList.SeekFile(ByteStart+2);
       FNodeList.BlkRead(NodeListAka,SizeOf(NodeListAka),BytesRead);
       FNodeList.BlkRead(NodeListBaud,SizeOf(NodeListBaud),BytesRead);
       FNodeList.BlkRead(NodeListSysop[0],1,BytesRead);
       FNodeList.BlkRead(NodeListSysop[1],Ord(NodeListSysop[0]),BytesRead);
       FNodeList.BlkRead(NodeListSystem[0],1,BytesRead);
       FNodeList.BlkRead(NodeListSystem[1],Ord(NodeListSystem[0]),BytesRead);
       FNodeList.BlkRead(NodeListPhone[0],1,BytesRead);
       FNodeList.BlkRead(NodeListPhone[1],Ord(NodeListPhone[0]),BytesRead);
       FNodeList.BlkRead(NodeListLocation[0],1,BytesRead);
       FNodeList.BlkRead(NodeListLocation[1],Ord(NodeListLocation[0]),BytesRead);
       FNodeList.BlkRead(NodeListFlags[0],1,BytesRead);
       FNodeList.BlkRead(NodeListFlags[1],Ord(NodeListFlags[0]),BytesRead);
       FNodeList.CloseFile;
     END;
END;


FUNCTION GetBBSName(InAddress: AddrType): String;
VAR  BytesRead : Word;
BEGIN
     {Check Including Point}
     GetBBSName := '-Unlisted-';
     IF NOT(_FileExists(MailerInfo.NodeList+'NODEINDX.SG')) THEN Exit;
     IF FNodeIndx.OpenFile(MailerInfo.NodeList+'NODEINDX.SG',SetFileMode) THEN
     BEGIN
       REPEAT
         FNodeIndx.BlkRead(NodeIndx,SizeOf(NodeIndx),BytesRead);
         IF (BytesRead<>0) THEN
         BEGIN
           IF AkasMatch(NodeIndx.Aka,InAddress) THEN
           BEGIN
             FNodeIndx.CloseFile;
             LoadFromNodeList(NodeIndx.ByteOffSet);
             GetBBSName := NodeListSystem;
             Exit;
           END;
         END;
       UNTIL BytesRead=0;
       FNodeIndx.CloseFile;
     END;
     {Check Without Point}
     GetBBSName := '-Unlisted-';
     IF FNodeIndx.OpenFile(MailerInfo.NodeList+'NODEINDX.SG',SetFileMode) THEN
     BEGIN
       REPEAT
         FNodeIndx.BlkRead(NodeIndx,SizeOf(NodeIndx),BytesRead);
         IF ((BytesRead<>0) AND (NodeIndx.Aka.Point=0)) THEN
         BEGIN
           IF AkasMatchNoPoint(NodeIndx.Aka,InAddress) THEN
           BEGIN
             FNodeIndx.CloseFile;
             LoadFromNodeList(NodeIndx.ByteOffSet);
             GetBBSName := NodeListSystem;
             Exit;
           END;
         END;
       UNTIL BytesRead=0;
       FNodeIndx.CloseFile;
     END;
END;


FUNCTION GetNodeInfo(InAddress: AddrType): String;
VAR  BytesRead : Word;
BEGIN
     GetNodeInfo := '';
     IF NOT(_FileExists(MailerInfo.NodeList+'NODEINDX.SG')) THEN Exit;
     IF FNodeIndx.OpenFile(MailerInfo.NodeList+'NODEINDX.SG',SetFileMode) THEN
     BEGIN
       REPEAT
         FNodeIndx.BlkRead(NodeIndx,SizeOf(NodeIndx),BytesRead);
         IF (BytesRead<>0) THEN
         BEGIN
           IF AkasMatch(NodeIndx.Aka,InAddress) THEN
           BEGIN
             FNodeIndx.CloseFile;
             LoadFromNodeList(NodeIndx.ByteOffSet);
             IF NodeListPhone='-UNPUBLISHED-'
                THEN GetNodeInfo := ''
                ELSE GetNodeInfo := NodeListPhone;
             Exit;
           END;
         END;
       UNTIL BytesRead=0;
       FNodeIndx.CloseFile;
     END;
     GetNodeInfo := '';
     IF FNodeIndx.OpenFile(MailerInfo.NodeList+'NODEINDX.SG',SetFileMode) THEN
     BEGIN
       REPEAT
         FNodeIndx.BlkRead(NodeIndx,SizeOf(NodeIndx),BytesRead);
         IF ((BytesRead<>0) AND (NodeIndx.Aka.Point=0)) THEN
         BEGIN
           IF AkasMatchNoPoint(NodeIndx.Aka,InAddress) THEN
           BEGIN
             FNodeIndx.CloseFile;
             LoadFromNodeList(NodeIndx.ByteOffSet);
             IF NodeListPhone='-UNPUBLISHED-'
                THEN GetNodeInfo := ''
                ELSE GetNodeInfo := NodeListPhone;
             Exit;
           END;
         END;
       UNTIL BytesRead=0;
       FNodeIndx.CloseFile;
     END;
END;


FUNCTION GetNetInfo(InAddress: AddrType): String;
VAR  BytesRead : Word;
BEGIN
     GetNetInfo := '';
     IF NOT(_FileExists(MailerInfo.NodeList+'NODEINDX.SG')) THEN Exit;
     IF FNodeIndx.OpenFile(MailerInfo.NodeList+'NODEINDX.SG',SetFileMode) THEN
     BEGIN
       REPEAT
         FNodeIndx.BlkRead(NodeIndx,SizeOf(NodeIndx),BytesRead);
         IF (BytesRead<>0) THEN
         BEGIN
           IF ((NodeIndx.Aka.Net=InAddress.Net) AND (NodeIndx.Aka.Zone=InAddress.Zone)) THEN
           BEGIN
             FNodeIndx.CloseFile;
             LoadFromNodeList(NodeIndx.ByteOffSet);
             IF NodeListPhone='-UNPUBLISHED-'
                THEN GetNetInfo := ''
                ELSE GetNetInfo := NodeListPhone;
             Exit;
           END;
         END;
       UNTIL BytesRead=0;
       FNodeIndx.CloseFile;
     END;
END;


END.