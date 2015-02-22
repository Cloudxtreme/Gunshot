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
PROCEDURE UsersGender;
PROCEDURE IBMCharacterToggle;
PROCEDURE ANSIGraphicsToggle;
PROCEDURE ClearScreenToggle;
PROCEDURE MessageEditorToggle;
PROCEDURE PageFlagToggle;
PROCEDURE InUserlistToggle;
PROCEDURE NumberOfFileDescLines;
PROCEDURE FileAreaSeperatorToggle;


IMPLEMENTATION


USES ANSIMisc,Screens,KeyInput,Globals,MiscStr,BsString;


PROCEDURE UsersComment;
BEGIN
     SendCrLf(2);
     System_Prompt('',176,false,true);
     Get_String(60,UserRecord.Note,true,false,false,True);
     SendCrLf(1);
     UserRecord.Note := input_string;
END;


PROCEDURE UsersBBSName;
BEGIN
     SendCrLf(2);
     System_Prompt('',134,false,true);
     Get_Name(30,UserRecord.BBS,true,True);
     SendCrLf(1);
     UserRecord.BBS := input_string;
END;


PROCEDURE UsersBBSNetworkNumber;
BEGIN
     SendCrLf(2);
     System_Prompt('',136,false,true);
     Get_String(20,UserRecord.BBS_Net,true,false,false,True);
     SendCrLf(1);
     UserRecord.BBS_Net := input_string;
END;


PROCEDURE UsersBBSPhoneNumber;
BEGIN
     SendCrLf(2);
     System_Prompt('',135,false,true);
     Get_String(20,UserRecord.BBS_Phone,true,true,false,True);
     SendCrLf(1);
     UserRecord.BBS_Phone := input_string;
END;


PROCEDURE UsersRealName;
BEGIN
     SendCrLf(2);
     System_Prompt('',132,false,true);
     Get_Name(30,UserRecord.Name,true,True);
     SendCrLf(1);
     IF Input_String<>'' THEN UserRecord.Name := input_string;
END;


PROCEDURE UsersAliasName;
BEGIN
     SendCrLf(2);
     System_Prompt('',133,false,true);
     Get_Name(30,UserRecord.Alias,true,True);
     SendCrLf(1);
     IF Input_String<>'' THEN UserRecord.Alias := input_string;
END;


PROCEDURE UsersPassword;
BEGIN
     SendCrLf(2);
     System_Prompt('',101,false,true);
     Get_Password(20,UserRecord.password,true,true);
     SendCrLf(1);
     UserRecord.password := _UpperCase(input_string);
END;


PROCEDURE UsersVoiceNumber;
BEGIN
     SendCrLf(2);
     System_Prompt('',104,false,true);
     Get_String(20,UserRecord.voice,true,true,false,True);
     SendCrLf(1);
     UserRecord.voice := PhoneNumber(input_string);
END;


PROCEDURE UsersDataNumber;
BEGIN
     SendCrLf(2);
     System_Prompt('',103,false,true);
     Get_String(20,UserRecord.data,true,true,false,True);
     SendCrLf(1);
     UserRecord.data := PhoneNumber(input_string);
END;


PROCEDURE UsersStreetAdress;
BEGIN
     SendCrLf(2);
     System_Prompt('',105,false,true);
     Get_Name(30,UserRecord.street,true,True);
     SendCrLf(1);
     UserRecord.street := input_string;
END;


PROCEDURE UsersCity;
BEGIN
     SendCrLf(2);
     System_Prompt('',106,false,true);
     Get_Name(30,UserRecord.city,true,True);
     SendCrLf(1);
     UserRecord.city := input_string;
END;


PROCEDURE UsersProvinceState;
BEGIN
     SendCrLf(2);
     System_Prompt('',107,false,true);
     Get_Name(30,UserRecord.prov,true,True);
     SendCrLf(1);
     UserRecord.prov := input_string;
END;


PROCEDURE UsersCountry;
BEGIN
     SendCrLf(2);
     System_Prompt('',108,false,true);
     Get_Name(30,UserRecord.country,true,True);
     SendCrLf(1);
     UserRecord.country := input_string;
END;


PROCEDURE UsersPostalZIPCode;
BEGIN
     SendCrLf(2);
     System_Prompt('',109,false,true);
     Get_String(20,UserRecord.postal,true,false,true,True);
     SendCrLf(1);
     UserRecord.postal := input_string;
END;


PROCEDURE UsersBirthday;
VAR  Temp : String;
BEGIN
     (*FUCK!*)
     Temp := _Mid(UserRecord.birth,1,4)+'19'+_Mid(UserRecord.birth,5,6);
     SendCrLf(2);
     System_Prompt('',102,false,true);
     GetADate(Temp,True);
     SendCrLf(1);
     UserRecord.birth := _Mid(input_string,1,4)+_Mid(input_string,7,8);
END;


PROCEDURE UsersGender;
BEGIN
     IF UserRecord.sex=0 THEN UserRecord.sex := 1
                         ELSE UserRecord.sex := 0;
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


PROCEDURE NumberOfFileDescLines;
VAR  Shit       : Word;
     Code       : Integer;
BEGIN
     SendCrLf(2);
     System_Prompt('',110,false,true);
     Get_Number(2,_String(UserRecord.file_lines),True);
     SendCrLf(1);
     VAL(input_string,shit,code);
     IF ((shit>0) AND (shit<19)) THEN UserRecord.file_lines := shit;
END;


PROCEDURE FileAreaSeperatorToggle;
BEGIN
     IF UserRecord.seperator=1 THEN UserRecord.seperator := 0
                               ELSE UserRecord.seperator := 1;
END;


END.
