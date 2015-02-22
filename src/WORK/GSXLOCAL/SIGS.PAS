{$I DEFINES.INC}
UNIT Sigs;


INTERFACE


PROCEDURE GetUseOfSignature;
PROCEDURE AddAnsiSig;


IMPLEMENTATION


USES Globals,BsString,MsgParam,Special,BsFile;


PROCEDURE GetUseOfSignature;
BEGIN
     UseSignature := False;
     IF _FileExists(SIG_Directory+'\'+_String(UserRecord.User_Number)+'.SIG') THEN
     BEGIN
          IF Write_Sig=True THEN UseSignature := True
                            ELSE UseSignature := False;
     END;
END;


PROCEDURE AddAnsiSig;
VAR  MsgText  : MessageTextLines;
     Sig_File : Text;
     Temp     : String;
BEGIN
     ASSIGN(FMsgText,NODE_Directory+'\WRITE.$$$');
     ASSIGN(Sig_File,SIG_Directory+'\'+_String(UserRecord.User_Number)+'.SIG');
     RESET(FMsgText);
     RESET(Sig_File);
     SEEK(FMsgText,FileSize(FMsgText));
     REPEAT
           READLN(Sig_File,Temp);
           FillChar(MsgText.Line,SizeOf(MsgText.Line),0);
           IF MessageAreas.DoGraphics=1 THEN MsgText.Line := Temp
                                        ELSE MsgText.Line := Remove_Special(Temp);
           WRITE(FMsgText,MsgText);
     UNTIL EOF(Sig_File);
     CLOSE(FMsgText);
     CLOSE(Sig_File);
END;


END.
