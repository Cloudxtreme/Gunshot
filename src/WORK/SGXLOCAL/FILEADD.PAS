{$I DEFINES.INC}
UNIT FileAdd;


INTERFACE


PROCEDURE AddFile(OPath: String; FSub,FArea: Word);


IMPLEMENTATION


USES Globals,MiscStr,BsFile,FilHeadr,BsString;


{FILE MUST ALREADY BE CONVERTED AND FFileDesc & FFileDefs Intact Globally}
PROCEDURE AddFile(OPath: String; FSub,FArea: Word);
TYPE FFFF = RECORD
     OrigIndex : Word;
     Info      : String[16];
     InfoNum   : Longint;
     END;
TYPE File_Info2 = Array[1..1000] OF FFFF;
VAR  FileInfo2     : ^File_Info2;
     OldArea       : Word;
     OldSub        : Word;
     Success       : Boolean;
     Position      : Longint;
     Loop          : Word;
     i,j           : Word;
     Temp          : FFFF;  {Info : String[16]; OrigIndex : Word; InfoNum : Longint}
     NumberOfFiles : Word;
     Counter       : Word;
     Month         : Word;
     Day           : Word;
     Year          : Word;
     RealDate      : Longint;
     Loop2         : Word;
     TextPos       : Word;
     IsItThere     : Boolean;
BEGIN
     New(FileInfo2);
     OldArea := CurrentFileArea;
     OldSub  := CurrentFileSub;
     IF FSub=0 THEN
     BEGIN
          {DO THE MAIN FA000000.DAT FILE}
          ASSIGN(FFileArea,DATA_Directory+'\FA000000.DAT');
          RESET(FFileArea);
          SEEK(FFileArea,FArea-1);
          READ(FFileArea,FileAreas);
          INC(FileAreas.Num_Files);
          INC(FileAreas.Num_Bytes,FileDefs^.File_Size);
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
                     INC(FileAreas2.Num_Files);
                     INC(FileAreas2.Num_Bytes,FileDefs^.File_Size);
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
          INC(FileAreas.Num_Files);
          INC(FileAreas.Num_Bytes,FileDefs^.File_Size);
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
                     INC(FileAreas2.Num_Files);
                     INC(FileAreas2.Num_Bytes,FileDefs^.File_Size);
                     SEEK(FFileArea,Position-1);
                     WRITE(FFileArea,FileAreas2);
                END;
          UNTIL ((Success) OR (EOF(FFileArea)));
          CLOSE(FFileArea);
     END;
     {ADD TO FILE AREAS DATABASE}
     ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL');
     ASSIGN(FFileDesc,FileAreas.Dos_Name+'.TXT');
     {$I-}RESET(FFileDefs);{$I+}
     IF IOResult<>0 THEN REWRITE(FFileDefs);
     {$I-}RESET(FFileDesc);{$I+}
     IF IOResult<>0 THEN REWRITE(FFileDesc);
     FileDefs^.First_Desc := FileSize(FFileDesc)+1;
     SEEK(FFileDefs,FileSize(FFileDefs));
     SEEK(FFileDesc,FileSize(FFileDesc));
     FOR Loop := 1 TO FileDefs^.Desc_Lines DO
         WRITE(FFileDesc,FileDesc^[Loop]);
     WRITE(FFileDefs,FileDefs^);
     CLOSE(FFileDefs);
     CLOSE(FFileDesc);
     {COPY THE FILE}
     _CopyFile(FileDefs^.File_Name,OPath,FileAreas.Area_Path);
     {No Sort - Just Exit}
     IF FileAreas.Sort<>1 THEN
     BEGIN
          {LOAD THE SORT INFORMATION REQUIRED}
          CASE FileAreas.Sort OF
          2,3: BEGIN
                    ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL');
                    RESET(FFileDefs);
                    NumberOfFiles := FileSize(FFileDefs);
                    Counter       := 0;
                    REPEAT
                          READ(FFileDefs,FileDefs^);
                          INC(Counter);
                          FileInfo2^[Counter].OrigIndex := Counter;
                          FileInfo2^[Counter].Info      := _UpperCase(_RemoveSpaces(FileDefs^.File_Name));
                    UNTIL EOF(FFileDefs);
                    CLOSE(FFileDefs);
               END;
          4,5: BEGIN
                    ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL');
                    RESET(FFileDefs);
                    NumberOfFiles := FileSize(FFileDefs);
                    Counter       := 0;
                    REPEAT
                          READ(FFileDefs,FileDefs^);
                          INC(Counter);
                          FileInfo2^[Counter].OrigIndex := Counter;
                          FileInfo2^[Counter].InfoNum   := FileDefs^.File_Date;
                    UNTIL EOF(FFileDefs);
                    CLOSE(FFileDefs);
               END;
          6,7: BEGIN
                    ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL');
                    RESET(FFileDefs);
                    NumberOfFiles := FileSize(FFileDefs);
                    Counter       := 0;
                    REPEAT
                          READ(FFileDefs,FileDefs^);
                          INC(Counter);
                          FileInfo2^[Counter].OrigIndex := Counter;
                          FileInfo2^[Counter].InfoNum   := FileDefs^.File_Size;
                    UNTIL EOF(FFileDefs);
                    CLOSE(FFileDefs);
               END;
          END;
          {SORT THE INDEXES}
          CASE FileAreas.Sort OF
          2:   BEGIN {ALPHABETICAL (A-Z)}
                    FOR i := 1 TO NumberOfFiles DO
                    BEGIN
                         FOR j := 1 TO NumberOfFiles DO
                         BEGIN
                              IF FileInfo2^[i].Info<FileInfo2^[j].Info THEN
                              BEGIN
                                   Temp := FileInfo2^[i];
                                   FileInfo2^[i] := FileInfo2^[j];
                                   FileInfo2^[j] := temp;
                              END;
                         END;
                    END;
               END;
          3:   BEGIN {ALPHABETICAL (Z-A)}
                    FOR i := 1 TO NumberOfFiles DO
                    BEGIN
                         FOR j := 1 TO NumberOfFiles DO
                         BEGIN
                              IF FileInfo2^[i].Info>FileInfo2^[j].Info THEN
                              BEGIN
                                   Temp := FileInfo2^[i];
                                   FileInfo2^[i] := FileInfo2^[j];
                                   FileInfo2^[j] := temp;
                              END;
                         END;
                    END;
               END;
          4:   BEGIN {DATE (NEW-OLD)}
                    FOR i := 1 TO NumberOfFiles DO
                    BEGIN
                         FOR j := 1 TO NumberOfFiles DO
                         BEGIN
                              IF FileInfo2^[i].InfoNum>FileInfo2^[j].InfoNum THEN
                              BEGIN
                                   Temp := FileInfo2^[i];
                                   FileInfo2^[i] := FileInfo2^[j];
                                   FileInfo2^[j] := temp;
                              END;
                         END;
                    END;
               END;
          5:   BEGIN {DATE (OLD-NEW)}
                    FOR i := 1 TO NumberOfFiles DO
                    BEGIN
                         FOR j := 1 TO NumberOfFiles DO
                         BEGIN
                              IF FileInfo2^[i].InfoNum<FileInfo2^[j].InfoNum THEN
                              BEGIN
                                   Temp := FileInfo2^[i];
                                   FileInfo2^[i] := FileInfo2^[j];
                                   FileInfo2^[j] := temp;
                              END;
                         END;
                    END;
               END;
          6:   BEGIN {SIZE (LARGE-SMALL)}
                    FOR i := 1 TO NumberOfFiles DO
                    BEGIN
                         FOR j := 1 TO NumberOfFiles DO
                         BEGIN
                              IF FileInfo2^[i].InfoNum>FileInfo2^[j].InfoNum THEN
                              BEGIN
                                   Temp := FileInfo2^[i];
                                   FileInfo2^[i] := FileInfo2^[j];
                                   FileInfo2^[j] := temp;
                              END;
                         END;
                    END;
               END;
          7:   BEGIN {SIZE (SMALL-LARGE)}
                    FOR i := 1 TO NumberOfFiles DO
                    BEGIN
                         FOR j := 1 TO NumberOfFiles DO
                         BEGIN
                              IF FileInfo2^[i].InfoNum<FileInfo2^[j].InfoNum THEN
                              BEGIN
                                   Temp := FileInfo2^[i];
                                   FileInfo2^[i] := FileInfo2^[j];
                                   FileInfo2^[j] := temp;
                              END;
                         END;
                    END;
               END;
          END;
          {RENAME THE OLD DBASE FILES TO A TEMPORARY}
          ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL'); RENAME(FFileDefs,FileAreas.Dos_Name+'.FIB');
          ASSIGN(FFileDesc,FileAreas.Dos_Name+'.TXT'); RENAME(FFileDesc,FileAreas.Dos_Name+'.TXB');
          ASSIGN(FFileDefs2,FileAreas.Dos_Name+'.FIB');
          ASSIGN(FFileDesc2,FileAreas.Dos_Name+'.TXB');
          ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL');
          ASSIGN(FFileDesc,FileAreas.Dos_Name+'.TXT');
          REWRITE(FFileDesc);
          REWRITE(FFileDefs);
          RESET(FFileDesc2);
          RESET(FFileDefs2);
          TextPos := 1;
          FOR Loop := 1 TO NumberOfFiles DO
          BEGIN
               {READ IN THE RECORDS}
               SEEK(FFileDefs2,FileInfo2^[Loop].OrigIndex-1);
               READ(FFileDefs2,FileDefs^);
               SEEK(FFileDesc2,FileDefs^.First_Desc-1);
               FOR Loop2 := 1 TO FileDefs^.Desc_Lines DO
                   READ(FFileDesc2,FileDesc^[Loop2]);
               {ADJUST THE TEXT POINTER}
               FileDefs^.First_Desc := TextPos;
               INC(TextPos,FileDefs^.Desc_Lines);
               {WRITE THE NEW RECORDS}
               WRITE(FFileDefs,FileDefs^);
               FOR Loop2 := 1 TO FileDefs^.Desc_Lines DO
                   WRITE(FFileDesc,FileDesc^[Loop2]);
          END;
          CLOSE(FFileDesc);
          CLOSE(FFileDefs);
          CLOSE(FFileDesc2);
          CLOSE(FFileDefs2);
          ERASE(FFileDesc2);
          ERASE(FFileDefs2);
     END;
     Dispose(FileInfo2);
     {DONE!}
     Header(OldSub,OldArea,True);
END;


END.
