{$I DEFINES.INC}
UNIT UserEdit;


INTERFACE


PROCEDURE UsersComment;
PROCEDURE UsersRealName;
PROCEDURE UsersAliasName;
PROCEDURE UsersPassword;
PROCEDURE UsersVoiceNumber;
PROCEDURE UsersDataNumber;
PROCEDURE UsersStreetAdress;
PROCEDURE UsersCity;
PROCEDURE UsersProvinceState;
PROCEDURE UsersCountry;
PROCEDURE UsersPostalZIPCode;
PROCEDURE UsersBBSName;
PROCEDURE UsersBBSNetworkNumber;
PROCEDURE UsersBBSPhoneNumber;
PROCEDURE UsersBirthday;
PROCEDURE IBMCharacterToggle;
PROCEDURE ANSIGraphicsToggle;
PROCEDURE ClearScreenToggle;
PROCEDURE MessageEditorToggle;
PROCEDURE NumberOfFileDescLines;
PROCEDURE UsersGender;
PROCEDURE PageFlagToggle;
PROCEDURE InUserlistToggle;
PROCEDURE FileAreaSeperatorToggle;


IMPLEMENTATION


USES Screens,KeyInput,Globals,MiscStr;


PROCEDURE UsersGender;
BEGIN
     IF UserRecord.sex=0 THEN UserRecord.sex := 1
                         ELSE UserRecord.sex := 0;
END;


PROCEDURE PageFlagToggle;
BEGIN
     IF UserRecord.PageFlag=1 THEN UserRecord.PageFlag := 0
                              ELSE UserRecord.PageFlag := 1;
END;


PROCEDURE InUserlistToggle;
BEGIN
     IF UserRecord.UserList=1 THEN UserRecord.UserList := 0
                              ELSE UserRecord.UserList := 1;
END;


PROCEDURE FileAreaSeperatorToggle;
BEGIN
     IF UserRecord.seperator=1 THEN UserRecord.seperator := 0
                               ELSE UserRecord.seperator := 1;
END;


PROCEDURE UsersComment;
BEGIN
     System_Prompt('',176);
     Get_Enter;
END;


PROCEDURE UsersBBSName;
BEGIN
     System_Prompt('',134);
     Get_Enter;
END;


PROCEDURE UsersBBSNetworkNumber;
BEGIN
     System_Prompt('',136);
     Get_Enter;
END;


PROCEDURE UsersBBSPhoneNumber;
BEGIN
     System_Prompt('',135);
     Get_Enter;
END;


PROCEDURE UsersRealName;
BEGIN
     System_Prompt('',132);
     Get_Enter;
END;


PROCEDURE UsersAliasName;
BEGIN
     System_Prompt('',133);
     Get_Enter;
END;


PROCEDURE UsersPassword;
BEGIN
     System_Prompt('',101);
     Get_Enter;
END;


PROCEDURE UsersVoiceNumber;
BEGIN
     System_Prompt('',104);
     Get_Enter;
END;


PROCEDURE UsersDataNumber;
BEGIN
     System_Prompt('',103);
     Get_Enter;
END;


PROCEDURE UsersStreetAdress;
BEGIN
     System_Prompt('',105);
     Get_Enter;
END;


PROCEDURE UsersCity;
BEGIN
     System_Prompt('',106);
     Get_Enter;
END;


PROCEDURE UsersProvinceState;
BEGIN
     System_Prompt('',107);
     Get_Enter;
END;


PROCEDURE UsersCountry;
BEGIN
     System_Prompt('',108);
     Get_Enter;
END;


PROCEDURE UsersPostalZIPCode;
BEGIN
     System_Prompt('',109);
     Get_Enter;
END;


PROCEDURE UsersBirthday;
BEGIN
     System_Prompt('',102);
     Get_Enter;
END;


PROCEDURE IBMCharacterToggle;
BEGIN
     IF UserRecord.IBM=1 THEN UserRecord.IBM := 0
                         ELSE UserRecord.IBM := 1;
END;


PROCEDURE ANSIGraphicsToggle;
BEGIN
END;


PROCEDURE ClearScreenToggle;
BEGIN
END;


PROCEDURE MessageEditorToggle;
BEGIN
END;


PROCEDURE NumberOfFileDescLines;
BEGIN
     System_Prompt('',110);
     Get_Enter;
END;


END.
