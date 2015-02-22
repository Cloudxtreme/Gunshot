{$I DEFINES.INC}
UNIT FileKill;


INTERFACE


PROCEDURE KillFile(OPath: String; FSub,FArea: Word);


IMPLEMENTATION


USES Globals,MiscStr,BsFile,BsString,FilHeadr;


{FFileDesc & FFileDefs Intact Globally}
PROCEDURE KillFile(OPath: String; FSub,FArea: Word);
VAR  OldArea    : Word;
     OldSub     : Word;
     Success    : Boolean;
     Position   : Longint;
     Loop       : Word;
BEGIN
     OldArea := CurrentFileArea;
     OldSub  := CurrentFileSub;
     IF FSub=0 THEN
     BEGIN
          {DO THE MAIN FA000000.DAT FILE}
          ASSIGN(FFileArea,DATA_Directory+'\FA000000.DAT');
          RESET(FFileArea);
          SEEK(FFileArea,FArea-1);
          READ(FFileArea,FileAreas);
          DEC(FileAreas.Num_Files);
          DEC(FileAreas.Num_Bytes,FileDefs^.File_Size);
          SEEK(FFileArea,FArea-1);
          WRITE(FFileArea,FileAreas);
          CLOSE(FFileArea);
          {DO THE FAxxxxxx.DAT FILE}
          Success := False;
          ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(FileAreas.Sub)+'.DAT');
          RESET(FFileArea);
          REPEAT
                READ(FFileArea,FileAreas2);
                IF (FileAreas2.Dos_Name=FileAreas.Dos_Name) THEN
                BEGIN
                     Success := True;
                     Position := FilePos(FFileArea);
                     DEC(FileAreas2.Num_Files);
                     DEC(FileAreas2.Num_Bytes,FileDefs^.File_Size);
                     SEEK(FFileArea,Position-1);
                     WRITE(FFileArea,FileAreas2);
                END;
          UNTIL ((Success) OR (EOF(FFileArea)));
          CLOSE(FFileArea);
     END
     ELSE
     BEGIN
          {DO THE FAxxxxxx.DAT FILE}
          ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(FSub)+'.DAT');
          RESET(FFileArea);
          SEEK(FFileArea,FArea-1);
          READ(FFileArea,FileAreas);
          DEC(FileAreas.Num_Files);
          DEC(FileAreas.Num_Bytes,FileDefs^.File_Size);
          SEEK(FFileArea,FArea-1);
          WRITE(FFileArea,FileAreas);
          CLOSE(FFileArea);
          {DO THE MAIN FA000000.DAT FILE}
          Success := False;
          ASSIGN(FFileArea,DATA_Directory+'\FA000000.DAT');
          RESET(FFileArea);
          REPEAT
                READ(FFileArea,FileAreas2);
                IF (FileAreas2.Dos_Name=FileAreas.Dos_Name) THEN
                BEGIN
                     Success := True;
                     Position := FilePos(FFileArea);
                     DEC(FileAreas2.Num_Files);
                     DEC(FileAreas2.Num_Bytes,FileDefs^.File_Size);
                     SEEK(FFileArea,Position-1);
                     WRITE(FFileArea,FileAreas2);
                END;
          UNTIL ((Success) OR (EOF(FFileArea)));
          CLOSE(FFileArea);
     END;
     {REMOVE FROM THE FILE AREAS DATABASE}
     ASSIGN(FFileDefs2,FileAreas.Dos_Name+'.FIL');
     ASSIGN(FFileDesc2,FileAreas.Dos_Name+'.TXT');
     RENAME(FFileDefs2,FileAreas.Dos_Name+'.FIB');
     RENAME(FFileDesc2,FileAreas.Dos_Name+'.TXB');
     ASSIGN(FFileDefs2,FileAreas.Dos_Name+'.FIB');
     ASSIGN(FFileDesc2,FileAreas.Dos_Name+'.TXB');
     ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL');
     ASSIGN(FFileDesc,FileAreas.Dos_Name+'.TXT');
     REWRITE(FFileDefs);
     REWRITE(FFileDesc);
     RESET(FFileDefs2);
     RESET(FFileDesc2);
     Success := False;
     REPEAT
           READ(FFileDefs2,FileDefs2^);
           FOR Loop := 1 TO FileDefs2^.Desc_Lines DO
               READ(FFileDesc2,FileDesc^[Loop]);
           IF FileDefs2^.File_Name=FileDefs^.File_Name THEN
           BEGIN
                Success := True;
           END
           ELSE
           BEGIN
                IF Success THEN
                BEGIN
                     DEC(FileDefs2^.First_Desc,FileDefs^.Desc_Lines);
                     WRITE(FFileDefs,FileDefs2^);
                     FOR Loop := 1 TO FileDefs2^.Desc_Lines DO
                         WRITE(FFileDesc,FileDesc^[Loop]);
                END
                ELSE
                BEGIN
                     WRITE(FFileDefs,FileDefs2^);
                     FOR Loop := 1 TO FileDefs2^.Desc_Lines DO
                         WRITE(FFileDesc,FileDesc^[Loop]);
                END;
           END;
     UNTIL EOF(FFileDefs2);
     CLOSE(FFileDefs);
     CLOSE(FFileDesc);
     CLOSE(FFileDefs2);
     CLOSE(FFileDesc2);
     ERASE(FFileDefs2);
     ERASE(FFileDesc2);
     IF _FileSize(FileAreas.Dos_Name+'.FIL')=0 THEN
     BEGIN
          ERASE(FFileDefs);
          ERASE(FFileDesc);
     END;
     {ERASE THE FILE}
     IF OPath[LENGTH(OPath)]<>'\' THEN OPath := OPath+'\';
     _EraseFile(OPath+FileDefs^.File_Name);
     {DONE!}
     Header(OldSub,OldArea,True);
END;


END.
