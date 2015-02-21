{$I DEFINES.INC}
UNIT GotoMsg;


INTERFACE


PROCEDURE goto_message(goto_message_override: word);


IMPLEMENTATION


USES MsgHeadr,MFireUp,Globals,KeyInput,ReadMail,Screens,_Mouse;


PROCEDURE goto_message(goto_message_override: word);
VAR  goto_message_msg_numbr  : word;
     Code                    : Integer;
BEGIN
     Header2(CurrentMessageSub,CurrentMessageArea,True);
     ChangeMouse(BusyMouse);
     JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
     ChangeMouse(DefaultMouse);
     IF goto_message_override=0 THEN
     BEGIN
          System_Prompt('',74);
          Get_Enter;
          VAL(Fields^[1].Text,goto_message_msg_numbr,code);
     END
     ELSE goto_message_msg_numbr := goto_message_override;
     IF (goto_message_msg_numbr=0) THEN Exit;
     IF TotalMessages=0 THEN
     BEGIN
          System_Prompt('',75);
          Get_Enter;
     END
     ELSE IF (goto_message_msg_numbr>TotalMessages) THEN
     BEGIN
          System_Prompt('',76);
          Get_Enter;
     END
     ELSE read_message(CurrentMessageArea,goto_message_msg_numbr,False);
END;



END.
