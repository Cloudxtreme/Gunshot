{$I DEFINES.INC}
UNIT CheckUSR;


INTERFACE


FUNCTION UserIsAlreadyOnline: Boolean;


IMPLEMENTATION


USES Globals,Dos,BsString;


FUNCTION UserIsAlreadyOnline: Boolean;
VAR  DirInfo   : SearchRec;
     OurFile   : String;
     IsHeThere : Boolean;
BEGIN
     IsHeThere := False;
     OurFile   := 'NODE'+NodeString+'.$$$';
     FindFirst(INTR_Directory+'\NODE*.$$$',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError=0 DO
     BEGIN
          IF (DirInfo.Name<>OurFile) THEN
          BEGIN
               FillChar(NodeF,SizeOf(NodeF),0);
               {$I-}
               ASSIGN(FNodeF,INTR_Directory+'\'+DirInfo.Name);
               RESET(FNodeF);
               READ(FNodeF,NodeF);
               CLOSE(FNodeF);
               {$I+}
               IF IOResult=0 THEN
               BEGIN
                    IF _UpperCase(NodeF.User)=_UpperCase(UserRecord.Name) THEN IsHeThere := True;
               END;
          END;
          FindNext(DirInfo);
     END;
     UserIsAlreadyOnline := IsHeThere;
END;


END.
