{$I DEFINES.INC}
UNIT CommNext;


INTERFACE


PROCEDURE CommentToNextCaller;


IMPLEMENTATION


USES Screens,KeyInput,Globals,BsLog;


PROCEDURE CommentToNextCaller;
BEGIN
     System_Prompt('',163);
     Get_Enter;
     IF Fields^[1].Text<>'' THEN
     BEGIN
          bsWriteLog('Comment to next caller: '+Fields^[1].Text,False);
          ASSIGN(FCommentToNext,INTR_Directory+'\COMMENT.MSG');
          REWRITE(FCommentToNext);
          CommentToNext.UserName  := UserRecord.Name;
          CommentToNext.UserAlias := UserRecord.Alias;
          CommentToNext.Line      := Fields^[1].Text;
          WRITE(FCommentToNext,CommentToNext);
          CLOSE(FCommentToNext);
     END;
END;


END.
