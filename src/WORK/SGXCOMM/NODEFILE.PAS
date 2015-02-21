{$I DEFINES.INC}
UNIT NodeFile;


INTERFACE


PROCEDURE DoNodeActivity (Num: Word; Line: String);


IMPLEMENTATION


USES Globals,BsString;


PROCEDURE DoNodeActivity(Num: Word; Line: String);
BEGIN
     NodeF.User         := UserRecord.Name;
     NodeF.Alias        := UserRecord.Alias;
     NodeF.Baud         := _PadLeft(BAUDString,6);
     NodeF.Location     := _PadRight(UserRecord.City+', '+UserRecord.Prov,30);
     NodeF.PageFlag     := UserRecord.PageFlag;
     NodeF.Node         := NodeNumber;
     LastActivity       := Num;
     CASE Num OF
     0:   BEGIN
               NodeF.Activity  := 'Logging onto the system                 ';
               NodeF.Available := False;
          END;
     1:   BEGIN
               NodeF.Activity  := 'Browsing the menus                      ';
               NodeF.Available := True;
          END;
     2:   BEGIN
               NodeF.Activity  := 'Paging the sysop                        ';
               NodeF.Available := True;
          END;
     3:   BEGIN
               NodeF.Activity  := 'Logging off of the system               ';
               NodeF.Available := False;
          END;
     4:   BEGIN
               NodeF.Activity  := 'Writing a comment to the next caller    ';
               NodeF.Available := True;
          END;
     5:   BEGIN
               NodeF.Activity  := 'Viewing a text file                     ';
               NodeF.Available := True;
          END;
     6:   BEGIN
               NodeF.Activity  := 'Running an external door                ';
               NodeF.Available := False;
          END;
     7:   BEGIN
               NodeF.Activity  := 'Changing file areas                     ';
               NodeF.Available := True;
          END;
     8:   BEGIN
               NodeF.Activity  := 'Transferring file(s)                    ';
               NodeF.Available := False;
          END;
     9:   BEGIN
               NodeF.Activity  := 'Searching for mail                      ';
               NodeF.Available := True;
          END;
     10:  BEGIN
               NodeF.Activity  := 'Changing message areas                  ';
               NodeF.Available := True;
          END;
     11:  BEGIN
               NodeF.Activity  := 'Reading messages                        ';
               NodeF.Available := True;
          END;
     12:  BEGIN
               NodeF.Activity  := 'Writing a message                       ';
               NodeF.Available := True;
          END;
     13:  BEGIN
               NodeF.Activity  := 'Deleting old mail                       ';
               NodeF.Available := True;
          END;
     14:  BEGIN
               NodeF.Activity  := 'Browsing file areas                     ';
               NodeF.Available := True;
          END;
     15:  BEGIN
               NodeF.Activity  := 'Uploading a message                     ';
               NodeF.Available := False;
          END;
     16:  BEGIN
               NodeF.Activity  := 'Viewing the last callers                ';
               NodeF.Available := True;
          END;
     17:  BEGIN
               NodeF.Activity  := 'Searching for new files                 ';
               NodeF.Available := True;
          END;
     18:  BEGIN
               NodeF.Activity  := 'Viewing the news screens                ';
               NodeF.Available := True;
          END;
     19:  BEGIN
               NodeF.Activity  := 'Running the call-back verifier          ';
               NodeF.Available := False;
          END;
     20:  BEGIN
               NodeF.Activity  := 'Searching for files                     ';
               NodeF.Available := True;
          END;
     21:  BEGIN
               NodeF.Activity  := 'Generating a file listing               ';
               NodeF.Available := False;
          END;
     22:  BEGIN
               NodeF.Activity  := 'Using the time bank                     ';
               NodeF.Available := True;
          END;
     23:  BEGIN
               NodeF.Activity  := 'Using the byte bank                     ';
               NodeF.Available := True;
          END;
     24:  BEGIN
               NodeF.Activity  := 'Browsing online users                   ';
               NodeF.Available := True;
          END;
     25:  BEGIN
               NodeF.Activity  := 'Chatting with another user              ';
               NodeF.Available := True;
          END;
     26:  BEGIN
               NodeF.Activity  := 'Paging another user                     ';
               NodeF.Available := True;
          END;
     27:  BEGIN
               NodeF.Activity  := 'Adjusting user settings                 ';
               NodeF.Available := True;
          END;
     28:  BEGIN
               NodeF.Activity  := 'Uploading a message                     ';
               NodeF.Available := False;
          END;
     29:  BEGIN
               NodeF.Activity  := 'Uploading a signature file              ';
               NodeF.Available := False;
          END;
     30:  BEGIN
               NodeF.Activity  := 'Resetting last read pointers            ';
               NodeF.Available := True;
          END;
     31:  BEGIN
               NodeF.Activity  := 'Downloading a QWK packet                ';
               NodeF.Available := False;
          END;
     32:  BEGIN
               NodeF.Activity  := 'Changing file sub-groups                ';
               NodeF.Available := True;
          END;
     33:  BEGIN
               NodeF.Activity  := 'Changing message sub-groups             ';
               NodeF.Available := True;
          END;
     34:  BEGIN
               NodeF.Activity  := 'Uploading QWK replies                   ';
               NodeF.Available := False;
          END;
     35:  BEGIN
               NodeF.Activity  := 'Shelled to DOS                          ';
               NodeF.Available := False;
          END;
     36:  BEGIN
               NodeF.Activity  := 'Writing a comment to the sysop          ';
               NodeF.Available := True;
          END;
     37:  BEGIN
               NodeF.Activity  := 'Browsing the user list                  ';
               NodeF.Available := True;
          END;
     38:  BEGIN
               NodeF.Activity  := 'Writing a group message                 ';
               NodeF.Available := True;
          END;
     39:  BEGIN
               NodeF.Activity  := 'Chatting with the sysop                 ';
               NodeF.Available := False;
          END;
     40:  BEGIN
               NodeF.Activity  := 'Filling a data entry screen             ';
               NodeF.Available := True;
          END;
     41:  BEGIN
               NodeF.Activity  := 'Using a dial through service            ';
               NodeF.Available := False;
          END;
     99:  BEGIN
               NodeF.User      := 'System';
               NodeF.Alias     := '';
               NodeF.Baud      := '';
               NodeF.Location  := '';
               NodeF.PageFlag  := 0;
               NodeF.Node      := NodeNumber;
               NodeF.Available := False;
               NodeF.Activity  := 'Waiting For A Caller                    ';
          END;
     END;
     ASSIGN(FNodeF,INTR_Directory+'\NODE'+NodeString+'.$$$');
     {$I-}RESET(FNodeF);{$I+}
     IF (IOResult<>0) THEN REWRITE(FNodeF);
     WRITE(FNodeF,NodeF);
     CLOSE(FNodeF);
END;


END.
