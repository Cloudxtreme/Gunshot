{$I DEFINES.INC}
UNIT AreaSort;


INTERFACE


PROCEDURE SortTheFileArea(AreaDosName: String; Method: Byte);


IMPLEMENTATION


USES Gunshot,BsFile,BsString;


PROCEDURE SortTheFileArea(AreaDosName: String; Method: Byte);
TYPE FFFF          = RECORD
     OrigIndex     : Word;
     Info          : String[12];
     InfoNum       : Longint;
     END;
TYPE File_Info2    = Array[1..1000] OF FFFF;
VAR  FileInfo2     : ^File_Info2;
     NumberOfFiles : Longint;
     _FFileDefs    : File Of _FileDefinitions;
     _FFileDefs2   : File Of _FileDefinitions;
     _FFileDesc    : File Of _FileDescriptions;
     _FFileDesc2   : File Of _FileDescriptions;
     _FileDefs     : _FileDefinitions;
     _FileDesc     : Array[1..18] Of _FileDescriptions;
     TextPos       : Longint;
     Counter       : Longint;
     I,J           : Longint;
     Loop          : Word;
     Loop2         : Word;
     Temp          : FFFF;
BEGIN
     IF NOT(_FileExists(AreaDosName+'.FIL')) THEN Exit;
     IF (_FileSize(AreaDosName+'.FIL')>(SizeOf(_FileDefinitions)*1000)) THEN Exit;
     IF ((Method<2) OR (Method>7)) THEN Exit;
     New(FileInfo2);
     {LOAD THE SORT INFORMATION REQUIRED}
     ASSIGN(_FFileDefs,AreaDosName+'.FIL');
     RESET(_FFileDefs);
     NumberOfFiles := FileSize(_FFileDefs);
     Counter       := 0;
     REPEAT
       READ(_FFileDefs,_FileDefs);
       INC(Counter);
       CASE Method OF
       2,3: BEGIN
              FileInfo2^[Counter].OrigIndex := Counter;
              FileInfo2^[Counter].Info      := _UpperCase(_RemoveSpaces(_FileDefs.File_Name));
            END;
       4,5: BEGIN
              FileInfo2^[Counter].OrigIndex := Counter;
              FileInfo2^[Counter].InfoNum   := _FileDefs.File_Date;
            END;
       6,7: BEGIN
              FileInfo2^[Counter].OrigIndex := Counter;
              FileInfo2^[Counter].InfoNum   := _FileDefs.File_Size;
            END;
       END;
     UNTIL EOF(_FFileDefs);
     CLOSE(_FFileDefs);
     {SORT THE INDEXES}
     CASE Method OF
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
     _EraseFile(AreaDosName+'.FIB');
     _EraseFile(AreaDosName+'.TXB');
     _RenameFile(AreaDosName+'.FIL',AreaDosName+'.FIB');
     _RenameFile(AreaDosName+'.TXT',AreaDosName+'.TXB');
     ASSIGN(_FFileDefs2,AreaDosName+'.FIB');
     ASSIGN(_FFileDesc2,AreaDosName+'.TXB');
     ASSIGN(_FFileDefs,AreaDosName+'.FIL');
     ASSIGN(_FFileDesc,AreaDosName+'.TXT');
     REWRITE(_FFileDesc);
     REWRITE(_FFileDefs);
     RESET(_FFileDesc2);
     RESET(_FFileDefs2);
     TextPos := 1;
     FOR Loop := 1 TO NumberOfFiles DO
     BEGIN
       {READ IN THE RECORDS}
       SEEK(_FFileDefs2,FileInfo2^[Loop].OrigIndex-1);
       READ(_FFileDefs2,_FileDefs);
       SEEK(_FFileDesc2,_FileDefs.First_Desc-1);
       FOR Loop2 := 1 TO _FileDefs.Desc_Lines DO READ(_FFileDesc2,_FileDesc[Loop2]);
       {ADJUST THE TEXT POINTER}
       _FileDefs.First_Desc := TextPos;
       INC(TextPos,_FileDefs.Desc_Lines);
       {WRITE THE NEW RECORDS}
       WRITE(_FFileDefs,_FileDefs);
       FOR Loop2 := 1 TO _FileDefs.Desc_Lines DO WRITE(_FFileDesc,_FileDesc[Loop2]);
     END;
     CLOSE(_FFileDesc);
     CLOSE(_FFileDefs);
     CLOSE(_FFileDesc2);
     CLOSE(_FFileDefs2);
     ERASE(_FFileDesc2);
     ERASE(_FFileDefs2);
     Dispose(FileInfo2);
END;


END.