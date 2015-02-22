{$I DEFINES.INC}
UNIT Archiver;


INTERFACE


PROCEDURE CleanArc(FName: String; ArcType: String);
FUNCTION  GetArcType(FName : String): String;
FUNCTION  GetArcName(TheOne: Word): String;


IMPLEMENTATION


USES ErrorLog,Globals,BsFile;


PROCEDURE CleanArc(FName: String; ArcType: String);
VAR  Source  : Text;
     Dest    : Text;
     Temp    : String;
     Proceed : Boolean;
BEGIN
     ASSIGN(Source,FName);
     ASSIGN(Dest,_NoExtension(FName)+'.BAK');
     {$I-}RESET(Source);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REWRITE(Dest);
          Proceed := False;
          REPEAT
                READLN(Source,Temp);
                IF ArcType='ARJ' THEN
                BEGIN
                     IF Temp='Filename       Original Compressed Ratio DateTime modified CRC-32   AttrBTPMGVX'
                        THEN Proceed := True;
                END
                ELSE IF ArcType='ZIP' THEN
                BEGIN
                     IF Temp=' Length  Method   Size  Ratio   Date    Time    CRC-32  Attr  Name'
                        THEN Proceed := True;
                END
                ELSE IF ArcType='LZH' THEN
                BEGIN
                     IF Temp='  Name          Original    Packed  Ratio   Date     Time   Attr Type  CRC'
                        THEN Proceed := True;
                END
                ELSE IF ArcType='ZOO' THEN
                BEGIN
                     IF Temp='Length    CF  Size Now  Date      Time'
                        THEN Proceed := True;
                END
                ELSE IF ArcType='PAK' THEN
                BEGIN
                     IF Temp='Name          Length    Date      Time    Storage    SF   Size now  CRC'
                        THEN Proceed := True;
                END
                ELSE IF ArcType='ARC' THEN
                BEGIN
                     IF Temp='Filename        Length   Method     Size   Ratio    Date      Time    CRC'
                        THEN Proceed := True;
                END
                ELSE IF ArcType='RAR' THEN
                BEGIN
                     IF Temp=' Name             Size   Packed  Ratio   Date   Time  Attr   CRC-32   Meth Ver'
                        THEN Proceed := True;
                END
                ELSE Proceed := True;
                IF EOF(Source) THEN Proceed := True;
          UNTIL Proceed;
          IF EOF(Source) THEN
          BEGIN
               CLOSE(Source);
               CLOSE(Dest);
               ERASE(Dest);
               Exit;
          END;
          WRITELN(Dest,Temp);
          REPEAT
                READLN(Source,Temp);
                WRITELN(Dest,Temp);
          UNTIL EOF(Source);
          CLOSE(Source);
          CLOSE(Dest);
          ERASE(Source);
          RENAME(Dest,_NoExtension(FName)+'.$$$');
     END
     ELSE DoErrorLog(6,FName);
END;


FUNCTION GetArcType(FName : String): String;
VAR  ArcFile : File;
     i       : Integer;
     Gat     : String;
     c       : Array[1..7] Of Byte;
BEGIN
     FillChar(C,SizeOf(C),0);
     IF NOT(_FileExists(FName)) THEN
     BEGIN
          DoErrorLog(19,FName);
          GetArcType := '';
          Exit;
     END;
     ASSIGN(ArcFile,FName);
     RESET(ArcFile,1);
     IF FileSize(ArcFile)<7 THEN
     BEGIN
          CLOSE(ArcFile);
          GetArcType := '';
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
          ELSE IF ((c[1]=$1a) AND (c[2]=$0b)) THEN Gat := 'PAK'
          ELSE Gat := '';
     END;
     GetArcType := Gat;
END;


FUNCTION GetArcName(TheOne: Word): String;
BEGIN
     ASSIGN(FArcUtils,DATA_Directory+'\ARCUTILS.DAT');
     RESET(FArcUtils);
     {$I-}
     SEEK(FArcUtils,TheOne-1);
     READ(FArcUtils,ArcUtils);
     {$I+}
     IF IOResult=0 THEN GetArcName := ArcUtils.Extension
                   ELSE GetArcName := 'None';
     CLOSE(FArcUtils);
END;


END.