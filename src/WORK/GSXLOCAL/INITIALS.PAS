{$I DEFINES.INC}
UNIT Initials;


INTERFACE


FUNCTION reply_initials(reply_intitials_str: string): string;


IMPLEMENTATION


USES Globals;


FUNCTION reply_initials(reply_intitials_str: string): string;
VAR  reply_intitials_loop       : word;
     reply_intitials_work_str   : string;
BEGIN
     reply_intitials_work_str := UpCase(reply_intitials_str[1]);
     FOR reply_intitials_loop := 2 TO LENGTH(reply_intitials_str) DO
     BEGIN
          IF reply_intitials_str[reply_intitials_loop]=#32 THEN
          BEGIN
               IF reply_intitials_str[reply_intitials_loop+1]<>#32 THEN
                  reply_intitials_work_str := reply_intitials_work_str+UpCase(reply_intitials_str[reply_intitials_loop+1]);
          END;
     END;
     IF MessageAreas.Area_Type>19
        THEN Reply_initials := ''
        ELSE reply_initials := reply_intitials_work_str;
END;


END.
