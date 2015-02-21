{$I DEFINES.INC}
UNIT BsFile;


INTERFACE


PROCEDURE _EraseFile(FName: String);
PROCEDURE _EraseFileRecord(FName: String; RecSize: Word; RecNum: Longint);
FUNCTION  _MoveFileSafe(FName,FPath,TPath: String): String;
FUNCTION  _MoveFileQuick(FName,FPath,TPath: String): Boolean;
FUNCTION  _FileDate(FName: String): Longint;
FUNCTION  _Path(Work: String): String;
FUNCTION  _FileSize(FName: String): Longint;
FUNCTION  _GetFilePath(InString: String): String;
FUNCTION  _GetFileExtension(InString: String): String;
FUNCTION  _GetFileName(InString: String): String;
FUNCTION  _FileExists(FName: String): Boolean;
PROCEDURE _NukeDir(DirStart: String; DisplayProgress: Boolean);
FUNCTION  _NoExtension(InString: String): String;
FUNCTION  _NoPath(InString: String): String;
PROCEDURE _CreatePath(FPath: String);
FUNCTION  _CopyFile(FName,FPath,TPath: String): Boolean;
FUNCTION  _Copy(FPath,TPath: String): Boolean;
FUNCTION  _GetArcType(FName : String): String;
FUNCTION  _MoveFile(FName,FPath,TPath: String): Boolean;
FUNCTION  _CopyFileSafe(FName,FPath,TPath: String): String;
PROCEDURE _TruncateFile(FName: String);
PROCEDURE _RenameFile(Source,Dest: String);
PROCEDURE _ChangeDirectory(FPath: String);
FUNCTION  GetDrives: String;
FUNCTION  GetDiskType(wDrive: Char): String;
FUNCTION  GetDiskLabel(wDrive: Char): String;


IMPLEMENTATION


USES Dos,BsString,BsCrc;


FUNCTION _QualifiedPath(InString: String): String;
VAR  Temp : String;
BEGIN
     {Skip Blank Paths}
     IF InString='' THEN
     BEGIN
       _QualifiedPath := '';
       Exit;
     END;
     {Add A Backslash}
     IF (InString[LENGTH(InString)]<>'\') THEN InString := InString+'\';
     {Add Drive Letter If Needed}
     IF (InString[2]<>':') THEN
     BEGIN
       GetDir(0,Temp);
       IF Temp[2]=':' THEN InString := Temp[1]+':'+InString;
     END;
     _QualifiedPath := InString;
END;


PROCEDURE WakeUp(FName: String);
VAR  DirInfo : SearchRec;
     Counts  : Byte;
BEGIN
     Counts := 0;
     REPEAT
       FindFirst(FName,AnyFile-Directory-VolumeID,DirInfo);
       IF DosError=0 THEN Exit
                     ELSE INC(Counts);
     UNTIL (Counts=2);
     IF IOResult=0 THEN;
END;


FUNCTION _GetFilePath(InString: String): String;
VAR  Loop : Byte;
BEGIN
     Loop := Length(InString)+1;
     REPEAT
       DEC(Loop);
     UNTIL ((Loop=0) OR (InString[Loop]='\'));
     IF Loop<>0 THEN InString[0] := Chr(Loop)
                ELSE InString := '';
     _GetFilePath := InString;
END;


PROCEDURE _EraseFile(FName: String);
VAR  F       : File;
     DirInfo : SearchRec;
BEGIN
     WakeUp(FName);
     FindFirst(FName,AnyFile-Directory-VolumeID,DirInfo);
     WHILE DosError=0 DO
     BEGIN
       ASSIGN(F,_GetFilePath(FName)+DirInfo.Name);
       {$I-}ERASE(F);{$I+}
       IF IOResult<>0 THEN
       BEGIN
            {$I-}
            SetFAttr(F,0);
            ERASE(F);
            {$I+}
            IF IOResult<>0 THEN;
       END;
       FindNext(DirInfo);
     END;
     IF IOResult=0 THEN;
END;


FUNCTION _GetFileExtension(InString: String): String;
VAR  Work : Byte;
BEGIN
     Work := Pos('.',InString);
     IF Work<>0 THEN Delete(InString,1,Work);
     _GetFileExtension := InString;
END;


FUNCTION _FileExists(FName: String): Boolean;
VAR  DirInfo : SearchRec;
     Counts  : Byte;
     YesMan  : Boolean;
BEGIN
     Counts := 0;
     YesMan := False;
     REPEAT
       FindFirst(FName,AnyFile-Directory-VolumeID,DirInfo);
       IF DosError=0 THEN YesMan := True
                     ELSE INC(Counts);
     UNTIL ((YesMan) OR (Counts=2));
     IF IOResult=0 THEN;
     _FileExists := YesMan;
END;


PROCEDURE _NukeDir(DirStart: String; DisplayProgress: Boolean);

     PROCEDURE SubVisit(DirPath: String);
     VAR Looking4 : SearchRec;
         Temp     : String;
     BEGIN
          FindFirst(DirPath+'*.*',AnyFile,looking4);
          WHILE DosError=0 DO
          BEGIN
            IF looking4.attr AND (VolumeID+Directory)=0 THEN
            BEGIN
              IF DisplayProgress THEN WRITE('Deleting: '+Concat(DirPath,looking4.name));
              _EraseFile(Concat(DirPath,looking4.name));
              IF DisplayProgress THEN WRITELN;
            END;
            FindNext(Looking4);
          END;
          FindFirst(Concat(DirPath,'*.*'),AnyFile,looking4);
          WHILE DosError=0 DO
          BEGIN
            IF ((looking4.name[1]='.') OR (Looking4.Attr=VolumeID)) THEN
            BEGIN
              {SKIP THESE}
            END
            ELSE IF ((looking4.attr AND Directory)=Directory) THEN
            BEGIN
              SubVisit(DirPath+looking4.name+'\');
            END;
            FindNext(looking4);
          END;
          Temp := DirPath;
          Dec(Temp[0]);
          IF DisplayProgress THEN WRITE('Removing: '+Temp);
          {$I-}RmDir(Temp);{$I+}
          IF IOResult=0 THEN;
          IF DisplayProgress THEN WRITELN;
     END;

BEGIN
     IF (DirStart[LENGTH(DirStart)]<>'\') THEN DirStart := DirStart+'\';
     SubVisit(DirStart);
END;


FUNCTION _NoExtension(InString: String): String;
VAR  Work : Byte;
BEGIN
     Work := Pos('.',InString);
     IF Work<>0 THEN InString[0] := Chr(Work-1);
     _NoExtension := InString;
END;


FUNCTION _NoPath(InString: String): String;
VAR  Work : Byte;
BEGIN
     REPEAT
       Work := Pos('\',InString);
       IF Work<>0 THEN Delete(InString,1,Work);
     UNTIL Work=0;
     _NoPath := InString;
END;


PROCEDURE _CreatePath(FPath: String);
VAR  Loop : Byte;
BEGIN
     IF Pos('.',FPath)<>0 THEN
     BEGIN
       Loop := Length(FPath);
       REPEAT
         DEC(Loop);
       UNTIL ((Loop=0) OR (FPath[Loop]='\'));
       IF Loop=0 THEN Delete(FPath,Loop,Length(FPath)-Loop+1)
                 ELSE Exit; {No Path}
     END;
     IF FPath[LENGTH(FPath)]='\' THEN Dec(FPath[0]);
     FOR Loop := 1 TO LENGTH(FPath) DO
     BEGIN
       IF FPath[Loop]='\' THEN
       BEGIN
         {$I-}
         MkDir(_Mid(FPath,1,Loop-1));
         {$I+}
         IF IOResult=0 THEN;
       END
       ELSE IF Loop=LENGTH(FPath) THEN
       BEGIN
         {$I-}
         MkDir(_Mid(FPath,1,Loop));
         {$I+}
         IF IOResult=0 THEN;
       END;
     END;
END;


FUNCTION _CopyFile(FName,FPath,TPath: String): Boolean;
{$IFDEF DPMI}
TYPE  BigFileCopyBuffer = Array[1..32768] Of Byte;
{$ELSE}
TYPE  BigFileCopyBuffer = Array[1..16384] Of Byte;
{$ENDIF}
VAR  Status         : Word;
     Source         : File;
     Dest           : File;
     NumRead        : Word;
     NumWritten     : Word;
     SourceCrc      : String[8];
     DestCrc        : String[8];
     Tries          : Byte;
     FileCopyBuffer : ^BigFileCopyBuffer;
LABEL                 Redo;
BEGIN
     IF FPath[LENGTH(FPath)]<>'\' THEN FPath := FPath+'\';
     IF TPath[LENGTH(TPath)]<>'\' THEN TPath := TPath+'\';
     FPath := FPath+FName;
     TPath := TPath+FName;
     WakeUp(FPath+FName);
     SourceCrc := FileCrc32(FPath);
     NEW(FileCopyBuffer);
     Tries := 0;
     Redo:
     ASSIGN(Source,FPath);
     {$I-}RESET(Source,1);{$I+}
     IF IOResult=0 THEN
     BEGIN
       ASSIGN(Dest,TPath);
       {$I-}REWRITE(Dest,1);{$I+}
       IF IOResult=0 THEN
       BEGIN
         REPEAT
           BlockRead(Source,FileCopyBuffer^,SizeOf(FileCopyBuffer^),NumRead);
           BlockWrite(Dest,FileCopyBuffer^,NumRead,NumWritten);
         UNTIL (NumRead=0) OR (NumWritten<>NumRead);
         CLOSE(Source);
         CLOSE(Dest);
         DestCrc := FileCrc32(TPath);
         IF DestCrc<>SourceCrc THEN
         BEGIN
           INC(Tries);
           IF Tries<3 THEN GOTO Redo;
           _CopyFile := False;
         END
         ELSE _CopyFile := True;
       END
       ELSE
       BEGIN
         CLOSE(Source);
         _CopyFile := False;
       END;
     END
     ELSE _CopyFile := False;
     DISPOSE(FileCopyBuffer);
     IF IOResult=0 THEN;
END;


FUNCTION _Copy(FPath,TPath: String): Boolean;
{$IFDEF DPMI}
TYPE  BigFileCopyBuffer = Array[1..32768] Of Byte;
{$ELSE}
TYPE  BigFileCopyBuffer = Array[1..16384] Of Byte;
{$ENDIF}
VAR  Source         : File;
     Dest           : File;
     NumRead        : Word;
     NumWritten     : Word;
     FileCopyBuffer : ^BigFileCopyBuffer;
BEGIN
     WakeUp(FPath);
     NEW(FileCopyBuffer);
     ASSIGN(Source,FPath);
     {$I-}RESET(Source,1);{$I+}
     IF IOResult=0 THEN
     BEGIN
       ASSIGN(Dest,TPath);
       REWRITE(Dest,1);
       REPEAT
         BlockRead(Source,FileCopyBuffer^,SizeOf(FileCopyBuffer^),NumRead);
         BlockWrite(Dest,FileCopyBuffer^,NumRead,NumWritten);
       UNTIL (NumRead=0) OR (NumWritten<>NumRead);
       CLOSE(Source);
       CLOSE(Dest);
       _Copy := True;
     END
     ELSE _Copy := False;
     DISPOSE(FileCopyBuffer);
     IF IOResult=0 THEN;
END;


FUNCTION _GetArcType(FName : String): String;
VAR  ArcFile : File;
     i       : Integer;
     Gat     : String;
     c       : Array[1..7] Of Byte;
BEGIN
     FillChar(C,SizeOf(C),0);
     IF NOT(_FileExists(FName)) THEN
     BEGIN
       _GetArcType := '';
       Exit;
     END;
     ASSIGN(ArcFile,FName);
     RESET(ArcFile,1);
     IF FileSize(ArcFile)<7 THEN
     BEGIN
       CLOSE(ArcFile);
       _GetArcType := '';
       Exit;
     END
     ELSE
     BEGIN
       BlockRead(ArcFile,C,SizeOf(C));
       CLOSE(ArcFile);
            IF ((c[1]=$52) AND (c[2]=$61) AND (c[3]=$72) AND (c[4]=$21) AND
                (c[5]=$1A) AND (c[6]=$07) AND (c[7]=$00)) THEN Gat := 'RAR'
       ELSE IF ((c[1]=$50) AND (c[2]=$4B)) THEN Gat := 'ZIP'
       ELSE IF ((c[1]=$60) AND (c[2]=$EA)) THEN Gat := 'ARJ'
       ELSE IF ((c[4]=$6c) AND (c[5]=$68)) THEN Gat := 'LZH'
       ELSE IF ((c[1]=$5a) AND (c[2]=$4f) AND (c[3]=$4f)) THEN Gat := 'ZOO'
       ELSE IF ((c[1]=$1a) AND (c[2]=$08)) THEN Gat := 'ARC'
       ELSE IF ((c[1]=$1a) AND (c[2]=$09)) THEN Gat := 'ARC'
       ELSE IF ((c[1]=$1a) AND (c[2]=$0b)) THEN Gat := 'PAK'
       ELSE Gat := '';
     END;
     _GetArcType := Gat;
END;


FUNCTION _MoveFile(FName,FPath,TPath: String): Boolean;
BEGIN
     FPath := _QualifiedPath(FPath);
     TPath := _QualifiedPath(TPath);
     IF FPath[1]=TPath[1] THEN
     BEGIN
       _MoveFile := _MoveFileQuick(FName,FPath,TPath);
     END
     ELSE
     BEGIN
       IF _CopyFile(FName,FPath,TPath) THEN
       BEGIN
         _EraseFile(FPath+FName);
         _MoveFile := True;
       END
       ELSE _MoveFile := False;
     END;
END;


PROCEDURE _RenameFile(Source,Dest: String);
VAR  FFile : File;
BEGIN
     {$I-}
     ASSIGN(FFile,Source);
     RENAME(FFile,Dest);
     {$I+}
     IF (IOResult<>0) THEN
     BEGIN
          _EraseFile(Dest);
          {$I-}
          ASSIGN(FFile,Source);
          RENAME(FFile,Dest);
          {$I+}
          IF IOResult=0 THEN;
     END;
END;


FUNCTION _FileSize(FName: String): Longint;
VAR  DirInfo : SearchRec;
BEGIN
     WakeUp(FName);
     FindFirst(FName,AnyFile-Directory-VolumeID,DirInfo);
     IF DosError=0 THEN _FileSize := DirInfo.Size
                   ELSE _FileSize := 0;
     IF IOResult=0 THEN;
END;


FUNCTION _Path(Work: String): String;
BEGIN
     IF Work='' THEN Work := '\'
     ELSE
     BEGIN
          IF Work[Length(Work)]<>'\' THEN Work := Work+'\';
     END;
     Work := _UpperCase(Work);
     _Path := Work;
END;


FUNCTION _FileDate(FName: String): Longint;
VAR  DirInfo : SearchRec;
BEGIN
     WakeUp(FName);
     FindFirst(FName,AnyFile-Directory-VolumeID,DirInfo);
     IF DosError=0 THEN _FileDate := DirInfo.Time
                   ELSE _FileDate := 0;
     IF IOResult=0 THEN;
END;


FUNCTION _CopyFileSafe(FName,FPath,TPath: String): String;
{$IFDEF DPMI}
TYPE  BigFileCopyBuffer = Array[1..32768] Of Byte;
{$ELSE}
TYPE  BigFileCopyBuffer = Array[1..16384] Of Byte;
{$ENDIF}
VAR  DestFile         : String;
     Counter          : Byte;
     DigitNumber      : Byte;
     Temp             : String;
     Status           : Word;
     NumRead          : Word;
     NumWritten       : Word;
     Source           : File;
     Dest             : File;
     DirInfo          : SearchRec;
     FileCopyBuffer   : ^BigFileCopyBuffer;
BEGIN
     NEW(FileCopyBuffer);
     IF FPath[LENGTH(FPath)]<>'\' THEN FPath := FPath+'\';
     IF TPath[LENGTH(TPath)]<>'\' THEN TPath := TPath+'\';
     WakeUp(FPath+FName);
     DestFile    := FName;
     Counter     := 0;
     DigitNumber := LENGTH(FName);
     WHILE _FileExists(TPath+DestFile) DO
     BEGIN
          Temp := _String(Counter);
          DestFile[DigitNumber] := Temp[1];
          INC(Counter);
          IF Counter=10 THEN
          BEGIN
               Counter := 0;
               DEC(DigitNumber);
               IF DestFile[DigitNumber]='.' THEN DEC(DigitNumber);
          END;
     END;
     FPath  := FPath+FName;
     TPath  := TPath+DestFile;
     Status := 0;
     ASSIGN(Source,FPath);
     {$I-}RESET(Source,1);{$I+}
     IF IOResult=0 THEN
     BEGIN
          ASSIGN(Dest,TPath);
          REWRITE(Dest,1);
          REPEAT
                BlockRead(Source,FileCopyBuffer^,SizeOf(FileCopyBuffer^),NumRead);
                BlockWrite(Dest,FileCopyBuffer^,NumRead,NumWritten);
          UNTIL (NumRead=0) OR (NumWritten<>NumRead);
          CLOSE(Source);
          CLOSE(Dest);
          Status := 1;
     END;
     IF Status=1 THEN _CopyFileSafe := DestFile
                 ELSE _CopyFileSafe := '';
     DISPOSE(FileCopyBuffer);
     IF IOResult=0 THEN;
END;


FUNCTION _MoveFileSafe(FName,FPath,TPath: String): String;
VAR  DestFile         : String;
     Counter          : Byte;
     DigitNumber      : Byte;
     Temp             : String;
     DirInfo          : SearchRec;
BEGIN
     FPath := _QualifiedPath(FPath);
     TPath := _QualifiedPath(TPath);
     WakeUp(FPath+FName);
     DestFile    := FName;
     Counter     := 0;
     DigitNumber := LENGTH(FName);
     WHILE _FileExists(TPath+DestFile) DO
     BEGIN
       Temp := _String(Counter);
       DestFile[DigitNumber] := Temp[1];
       INC(Counter);
       IF Counter=10 THEN
       BEGIN
         Counter := 0;
         DEC(DigitNumber);
         IF DestFile[DigitNumber]='.' THEN DEC(DigitNumber);
       END;
     END;
     FPath  := FPath+FName;
     TPath  := TPath+DestFile;
     IF _Copy(FPath,TPath) THEN _EraseFile(FPath);
     _MoveFileSafe := DestFile;
END;


FUNCTION GetDrives: String;
VAR  Temp : String;
     Loop : Word;
BEGIN
     Temp := '';
     FOR Loop := 67 TO 90 DO
     BEGIN
       IF DiskSize(Byte(Chr(Loop))-64)>0 THEN Temp := Temp+Chr(Loop);
     END;
     GetDrives := Temp;
END;


FUNCTION GetDiskLabel(wDrive: Char): String;
VAR  DirInfo : SearchRec;
     Work    : Word;
BEGIN
     FindFirst(wDrive+':\*.*',VolumeID,DirInfo);
     REPEAT
       Work := Pos('.',DirInfo.Name);
       IF (Work<>0) THEN Delete(DirInfo.Name,Work,1);
     UNTIL Work=0;
     IF DosError=0 THEN GetDiskLabel := DirInfo.Name
                   ELSE GetDiskLAbel := '';
END;


FUNCTION IsCDROMDrive(wDrive: Word): Boolean; ASSEMBLER;
VAR  wTempDrive: word;
ASM  mov  ax,wDrive
     or   ax,ax
     jnz  @not_default
     mov  ah,19h
     int  21h
     xor  ah,ah
     mov  wTempDrive,ax
     jmp  @test_it
@not_default:
     dec  ax
     mov  wTempDrive,ax
@test_it:
     mov  ax,1500h
     xor  bx,bx
     int  2fh
     mov  ax,bx
     or   ax,ax
     jz   @no_mscdex
     mov  ax,150bh
     mov  cx,wTempDrive
     int  2fh
     or   ax,ax
@no_mscdex:
END;


FUNCTION NetworkDrive(wDrive: Char): Boolean;
VAR  Reg   : Registers;
     IsNet : Boolean;
BEGIN
     IsNet  := False;
     wDrive := UpCase(wDrive);
     IF (wDrive IN ['A'..'Z']) THEN
     BEGIN
       Reg.BL := Ord(wDrive)-64;
       Reg.AX := $4409;
       MsDos(Reg);
       IF NOT(Odd(Reg.FLAGS)) THEN
       BEGIN
         IF Odd(Reg.DX SHR 12) THEN IsNet := True
                               ELSE IsNet := False;
       END;
     END;
     NetworkDrive := IsNet;
END;


FUNCTION GetDiskType(wDrive: Char): String;
VAR  TmpDrive : Word;
     Temp     : String;
BEGIN
     wDrive := UpCase(wDrive);
     Temp := 'HDD';
     TmpDrive := Ord(wDrive)-64;
          IF IsCDROMDrive(TmpDrive) THEN Temp := 'CD-ROM'
     ELSE IF NetworkDrive(wDrive) THEN Temp := 'NETWORK';
     GetDiskType := Temp;
END;


FUNCTION _MoveFileQuick(FName,FPath,TPath: String): Boolean;
VAR  FFile : File;
BEGIN
     FPath := _QualifiedPath(FPath);
     TPath := _QualifiedPath(TPath);
     IF _FileExists(FPath+FName) THEN
     BEGIN
       _EraseFile(TPath+FName);
       ASSIGN(FFile,FPath+FName);
       {$I-}RENAME(FFile,TPath+FName);{$I+}
       IF IOResult=0 THEN _MoveFileQuick := True
                     ELSE _MoveFileQuick := False;

     END
     ELSE _MoveFileQuick := False;
END;


PROCEDURE _TruncateFile(FName: String);
VAR  FFile : File;
BEGIN
     WakeUp(FName);
     IF _FileExists(FName) THEN
     BEGIN
          ASSIGN(FFile,FName);
          {$I-}
          RESET(FFile,1);
          TRUNCATE(FFile);
          CLOSE(FFile);
          {$I+}
          IF IOResult=0 THEN;
     END;
END;


{First Record Is #1!}
PROCEDURE _EraseFileRecord(FName: String; RecSize: Word; RecNum: Longint);
{$IFDEF DPMI}
TYPE  BigFileCopyBuffer = Array[1..32768] Of Byte;
{$ELSE}
TYPE  BigFileCopyBuffer = Array[1..16384] Of Byte;
{$ENDIF}
VAR  FFile          : File;
     StartRegion    : Longint;
     EndRegion      : Longint;
     BytesRead      : Word;
     BytesWritten   : Word;
     AllDone        : Boolean;
     SSize          : Word;
     FileCopyBuffer : ^BigFileCopyBuffer;
BEGIN
     StartRegion := (RecNum-1)*RecSize;
     EndRegion   := (RecNum)*RecSize;
     WakeUp(FName);
     NEW(FileCopyBuffer);
     SSize := SizeOf(FileCopyBuffer^);
     AllDone := False;
     ASSIGN(FFile,FName);
     {$I-}RESET(FFile,1);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                SEEK(FFile,EndRegion);
                BLOCKREAD(FFile,FileCopyBuffer^,SSize,BytesRead);
                SEEK(FFile,StartRegion);
                BLOCKWRITE(FFile,FileCopyBuffer^,BytesRead,BytesWritten);
                INC(EndRegion,BytesRead);
                INC(StartRegion,BytesRead);
                IF (BytesRead<>SSize) THEN
                BEGIN
                     SEEK(FFile,StartRegion);
                     TRUNCATE(FFile);
                     CLOSE(FFile);
                     AllDone := True;
                END;
          UNTIL AllDone;
     END;
     DISPOSE(FileCopyBuffer);
     IF IOResult=0 THEN;
     IF _FileSize(FName)=0 THEN _EraseFile(FName);
END;


FUNCTION _GetFileName(InString: String): String;
BEGIN
     InString := _NoExtension(InString);
     InString := _NoPath(InString);
     _GetFileName := InString;
END;


PROCEDURE _ChangeDirectory(FPath: String);
BEGIN
     IF ((FPath[LENGTH(FPath)]='\') AND (FPath<>'\')) THEN Dec(FPath[0]);
     {$I-}ChDir(FPath);{$I+}
     IF IOResult=0 THEN;
END;


END.
