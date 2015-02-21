{$I DEFINES.INC}
UNIT CommNext;


INTERFACE


PROCEDURE CommentToNextCaller;


IMPLEMENTATION


USES ANSIMisc,Screens,KeyInput,Globals,BsLog;


PROCEDURE CommentToNextCaller;
BEGIN
     SendCrLf(2);
     System_Prompt('',163,True,false);
     Get_String(60,'',True,false,false,False);
     SendCrLf(1);
     IF Input_String<>'' THEN
     BEGIN
          bsWriteLog('Comment to next caller: '+Input_String,False);
          ASSIGN(FCommentToNext,INTR_Directory+'\COMMENT.MSG');
          REWRITE(FCommentToNext);
          CommentToNext.UserName  := UserRecord.Name;
          CommentToNext.UserAlias := UserRecord.Alias;
          CommentToNext.Line      := Input_String;
          WRITE(FCommentToNext,CommentToNext);
          CLOSE(FCommentToNext);
     END;
END;


END.