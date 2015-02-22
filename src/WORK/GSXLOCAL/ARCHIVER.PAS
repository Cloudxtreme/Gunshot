{$I DEFINES.INC}
UNIT Archiver;


INTERFACE


PROCEDURE CleanArc(FName: String; ArcType: String);
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