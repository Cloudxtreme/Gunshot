{$I DEFINES.INC}
UNIT ExtDos;


INTERFACE


PROCEDURE clear_hold_dir;
PROCEDURE clear_scan_dir;
PROCEDURE clear_dirs;
PROCEDURE clearnode;


IMPLEMENTATION


USES Globals,Dos;


PROCEDURE clear_hold_dir;
VAR  DirInfo           : SearchRec;
     crap              : file;
BEGIN
     FindFirst(HOLD_Directory+'\*.*',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          {$I-}
          ASSIGN(crap,HOLD_Directory+'\'+DirInfo.Name);
          ERASE(crap);
          {$I+}
          IF IOResult=0 THEN;
          FindNext(DirInfo);
     END;
END;


PROCEDURE clear_scan_dir;
VAR  DirInfo           : SearchRec;
     crap              : file;
BEGIN
     FindFirst(SCAN_Directory+'\*.*',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          {$I-}
          ASSIGN(crap,SCAN_Directory+'\'+DirInfo.Name);
          ERASE(crap);
          {$I+}
          IF IOResult=0 THEN;
          FindNext(DirInfo);
     END;
END;


PROCEDURE clear_dirs;
VAR  DirInfo           : SearchRec;
     crap              : file;
BEGIN
     Clear_Scan_Dir;
     Clear_Hold_Dir;
     FindFirst(CD_Directory+'\*.*',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          {$I-}
          ASSIGN(crap,CD_Directory+'\'+DirInfo.Name);
          ERASE(crap);
          {$I+}
          IF IOResult=0 THEN;
          FindNext(DirInfo);
     END;
END;


PROCEDURE clearnode;
VAR  DirInfo           : SearchRec;
     crap              : file;
BEGIN
     FindFirst(NODE_Directory+'\*.*',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          {$I-}
          ASSIGN(crap,NODE_Directory+'\'+DirInfo.Name);
          ERASE(crap);
          {$I+}
          IF IOResult=0 THEN;
          FindNext(DirInfo);
     END;
END;


END.