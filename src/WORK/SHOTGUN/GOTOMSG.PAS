{$I DEFINES.INC}
UNIT GotoMsg;


INTERFACE


PROCEDURE goto_message(goto_message_override: word);


IMPLEMENTATION


USES MsgHeadr,MFireUp,Globals,ANSIMisc,KeyInput,ReadMail,Screens;


PROCEDURE goto_message(goto_message_override: word);
VAR  goto_message_msg_numbr  : word;
     Code                    : Integer;
BEGIN
     Header2(CurrentMessageSub,CurrentMessageArea,True);
     JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
     IF goto_message_override=0 THEN
     BEGIN
          SendCrLf(1);
          System_Prompt('',74,false,true);
          Get_Number(4,'',False);
          VAL(input_string,goto_message_msg_numbr,code);
     END
     ELSE goto_message_msg_numbr := goto_message_override;
     IF (goto_message_msg_numbr=0) THEN Exit;
     IF TotalMessages=0 THEN
     BEGIN
          SendCrLf(2);
          System_Prompt('',75,true,false);
          Get_Enter;
     END
     ELSE IF (goto_message_msg_numbr>TotalMessages) THEN
     BEGIN
          SendCrLf(2);
          System_Prompt('',76,true,false);
          Get_Enter;
     END
     ELSE read_message(CurrentMessageArea,goto_message_msg_numbr,False);
END;


END.