{$I DEFINES.INC}
UNIT Queue;


INTERFACE


PROCEDURE RescanQueue;


IMPLEMENTATION


USES DrawScrn,Globals,Shotgun,Misc,FastW1,Saver,BsAkas,BsString,BsFile,BsVideo;


PROCEDURE RescanQueue;
TYPE Q_Type       = RECORD
     Aka          : AddrType;
     Stat         : Byte;
     END;
VAR  Loop         : Word;
     Q            : Q_Type;
     FQ           : File Of Q_Type;
     Counter      : Word;
     FoundIt      : Boolean;
     NewStat      : Byte;
     RewriteIt    : Boolean;
     TheQueueFile : String;

     PROCEDURE ClearQueueWindow;
     VAR  Loop2 : Word;
     BEGIN
       KillSaver;
       FOR Loop2 := QueueWindowTop TO (Window2-1) DO FastWrite(_Replicate(' ',22),Loop2,2,ShotgunColours.SGMailNormalText);
     END;

BEGIN
     TheQueueFile := Shotgun_Directory+'\INTRNODE\QUEUETMP.'+_String(SimNode);
     _EraseFile(TheQueueFile);
     IF (NumberOfQueues<>0) THEN
     BEGIN
       FOR Loop := 1 TO NumberOfQueues DO
       BEGIN
         IF (MailQueue^[Loop].MsgStat<>Sent) THEN
         BEGIN
           IF NOT(MailQueue^[Loop].Exclusive) THEN
           BEGIN
             CASE MailQueue^[Loop].MsgStat OF
             2:   NewStat := 2;
             3:   NewStat := 3;
             ELSE NewStat := 1;
             END;
           END
           ELSE NewStat := 4;
           ASSIGN(FQ,TheQueueFile);
           {$I-}RESET(FQ);{$I+}
           IF IOResult=0 THEN
           BEGIN
             Counter := 0;
             FoundIt := False;
             REPEAT
               READ(FQ,Q);
               INC(Counter);
               IF AkasMatch(Q.Aka,MailQueue^[Loop].DestAddr) THEN
               BEGIN
                 FoundIt := True;
                 RewriteIt := False;
                 CASE Q.Stat OF
                 1:   BEGIN
                        CASE NewStat OF
                        2:   RewriteIt := True;
                        4:   RewriteIt := True;
                        END;
                      END;
                 2:   BEGIN
                        CASE NewStat OF
                        4:   RewriteIt := True;
                        END;
                      END;
                 3:   BEGIN
                        CASE NewStat OF
                        1:   RewriteIt := True;
                        2:   RewriteIt := True;
                        4:   RewriteIt := True;
                        END;
                      END;
                 END;
                 IF RewriteIt THEN
                 BEGIN
                   Q.Stat := NewStat;
                   SEEK(FQ,Counter-1);
                   WRITE(FQ,Q);
                 END;
               END;
             UNTIL ((EOF(FQ)) OR (FoundIt));
             IF NOT(FoundIt) THEN
             BEGIN
               Q.Stat := NewStat;
               Q.Aka  := MailQueue^[Loop].DestAddr;
               SEEK(FQ,FileSize(FQ));
               WRITE(FQ,Q);
             END;
             CLOSE(FQ);
           END
           ELSE
           BEGIN
             Q.Aka  := MailQueue^[Loop].DestAddr;
             Q.Stat := NewStat;
             REWRITE(FQ);
             WRITE(FQ,Q);
             CLOSE(FQ);
           END;
         END;
       END;
       IF _FileSize(TheQueueFile)=0 THEN _EraseFile(TheQueueFile);
       ClearQueueWindow;
       ASSIGN(FQ,TheQueueFile);
       {$I-}RESET(FQ);{$I+}
       IF IOResult=0 THEN
       BEGIN
         REPEAT
           READ(FQ,Q);
           CASE Q.Stat OF
           1:   QueueWindow(_PadRight(AddressToString(Q.Aka),17)+'   ');
           2:   QueueWindow(_PadRight(AddressToString(Q.Aka),17)+'(C)');
           3:   QueueWindow(_PadRight(AddressToString(Q.Aka),17)+'(H)');
           4:   QueueWindow(_PadRight(AddressToString(Q.Aka),17)+'(E)');
           END;
         UNTIL EOF(FQ);
         CLOSE(FQ);
       END;
     END
     ELSE ClearQueueWindow;
END;


END.