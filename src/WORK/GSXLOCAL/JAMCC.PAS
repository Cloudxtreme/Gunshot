{$I DEFINES.INC}
UNIT JamCC;


INTERFACE


PROCEDURE JamBase_CarbonCopy;


IMPLEMENTATION


USES Globals,JamStore;


PROCEDURE JamBase_CarbonCopy;
VAR  FMsgText2  : File Of MessageTextLines;
     MsgText    : MessageTextLines;
BEGIN
     ASSIGN(FMsgText,NODE_Directory+'\WRITE.$$$');
     RENAME(FMsgText,NODE_Directory+'\WRITE.$$X');
     ASSIGN(FMsgText,NODE_Directory+'\WRITE.$$$');
     ASSIGN(FMsgText2,NODE_Directory+'\WRITE.$$X');
     REWRITE(FMsgText);
     RESET(FMsgText2);
     MsgText.Line := ' *   Original By:  '+FastBaseHdr.MsgFrom;
     WRITE(FMsgText,MsgText);
     MsgText.Line := ' *   Original To:  '+FastBaseHdr.MsgTo;
     WRITE(FMsgText,MsgText);
     MsgText.Line := '--------------------------------------------------------------------------';
     WRITE(FMsgText,MsgText);
     REPEAT
           READ(FMsgText2,MsgText);
           WRITE(FMsgText,MsgText);
     UNTIL EOF(FMsgText2);
     CLOSE(FMsgText);
     CLOSE(FMsgText2);
     ERASE(FMsgText2);
     ASSIGN(FCarbonCopy,NODE_Directory+'\CC.DAT');
     RESET(FCarbonCopy);
     REPEAT
           READ(FCarbonCopy,CarbonCopy);
           FastBaseHdr.MsgTo := CarbonCopy.UserName;
           JamBase_StoreMessage(False);
           IF IOResult=0 THEN;
     UNTIL EOF(FCarbonCopy);
     CLOSE(FCarbonCopy);
     IF IOResult=0 THEN;
END;


END.
