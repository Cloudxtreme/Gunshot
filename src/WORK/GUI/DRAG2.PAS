{$I DEFINES.INC}
UNIT Drag2;


INTERFACE


FUNCTION  GetSeededCircleDraw (x1,y1,x2,y2: Word) : Boolean;
FUNCTION  GetSeededFillDraw   (x,y: Word)         : Boolean;
FUNCTION  GetSeededLineDraw   (x,y: Word)         : Boolean;
FUNCTION  GetSeededDragBox    (x1,y1,x2,y2: Word) : Boolean;
FUNCTION  GetSeededBoxDraw    (x,y: Word)         : Boolean;
FUNCTION  GetDragBox          (x1,y1,x2,y2: Word) : Boolean;
FUNCTION  GetTextDraw                             : Boolean;
FUNCTION  GetCircleDraw                           : Boolean;
FUNCTION  GetLineDraw                             : Boolean;
FUNCTION  GetBoxDraw                              : Boolean;
FUNCTION  GetChangeText                           : Boolean;
FUNCTION  GetChangeTextFile                       : Boolean;


IMPLEMENTATION


USES Globals,Gr2_Bp,BsGraph,Gx2_Bp,_Keys,BHandler,
     _Text,PickLst,_Icons,Crt,BsKeys,BsString,_Win;


FUNCTION GetBoxDraw: Boolean;
VAR  Bootit : Boolean;
     Work   : Word;
BEGIN
     xxx1 := GetMouseXG(Grid);
     yyy1 := GetMouseYG(Grid);
     xxx2 := XXX1;
     yyy2 := YYY1;
     GrSetColor(XORLine);
     GrSetOp(GxXOR);
     GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     BootIt := False;
     REPEAT
           CheckKeys;
           IF GetMouseYG(Grid)<=YWindow THEN Position;
           IF ((GetMouseXG(Grid)<>XXx2) OR (GetMouseYG(Grid)<>YYy2)) THEN
           BEGIN
                GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
                xxx2 := GetMouseXG(Grid);
                yyy2 := GetMouseYG(Grid);
                GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
           END;
           IF GrGetMouseButtons=GrRButton THEN BootIt := True;
     UNTIL ((GrGetMouseButtons=GrLButton) OR (BootIt) OR (yyy2>YWindow));
     GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     GrSetOp(GxSet);
     IF yyy2>YWindow THEN GetBoxDraw := False
                     ELSE GetBoxDraw := True;
     IF BootIt THEN GetBoxDraw := False;
     IF xxx1>xxx2 THEN
     BEGIN
          Work := xxx2;
          xxx2 := xxx1;
          xxx1 := Work;
     END;
     IF yyy1>yyy2 THEN
     BEGIN
          Work := yyy2;
          yyy2 := yyy1;
          yyy1 := Work;
     END;
END;


FUNCTION GetSeededBoxDraw(x,y: Word): Boolean;
VAR  Bootit : Boolean;
     Work   : Word;
BEGIN
     xxx1 := x;
     yyy1 := y;
     xxx2 := GetMouseXG(Grid);
     yyy2 := GetMouseYG(Grid);
     GrSetColor(9);
     GrSetOp(GxXOR);
     GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     BootIt := False;
     REPEAT
           CheckKeys;
           IF GetMouseYG(Grid)<=YWindow THEN Position;
           IF ((GetMouseXG(Grid)<>XXx2) OR (GetMouseYG(Grid)<>YYy2)) THEN
           BEGIN
                GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
                xxx2 := GetMouseXG(Grid);
                yyy2 := GetMouseYG(Grid);
                GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
           END;
           IF GrGetMouseButtons=GrRButton THEN BootIt := True;
     UNTIL ((GrGetMouseButtons=GrLButton) OR (BootIt) OR (yyy2>YWindow));
     GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     GrSetOp(GxSet);
     IF yyy2>YWindow THEN GetSeededBoxDraw := False
                     ELSE GetSeededBoxDraw := True;
     IF BootIt THEN GetSeededBoxDraw := False;
     IF xxx1>xxx2 THEN
     BEGIN
          Work := xxx2;
          xxx2 := xxx1;
          xxx1 := Work;
     END;
     IF yyy1>yyy2 THEN
     BEGIN
          Work := yyy2;
          yyy2 := yyy1;
          yyy1 := Work;
     END;
END;


FUNCTION GetLineDraw: Boolean;
VAR  Bootit : Boolean;
BEGIN
     xxx1 := GetMouseXG(Grid);
     yyy1 := GetMouseYG(Grid);
     xxx2 := XXX1;
     yyy2 := YYY1;
     GrSetColor(XORLine);
     GrSetOp(GxXOR);
     GrDrawLine(xxx1,yyy1,xxx2,yyy2);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     BootIt := False;
     REPEAT
           CheckKeys;
           IF GetMouseYG(Grid)<=YWindow THEN Position;
           IF ((GetMouseXG(Grid)<>XXx2) OR (GetMouseYG(Grid)<>YYy2)) THEN
           BEGIN
                GrDrawLine(xxx1,yyy1,xxx2,yyy2);
                xxx2 := GetMouseXG(Grid);
                yyy2 := GetMouseYG(Grid);
                GrDrawLine(xxx1,yyy1,xxx2,yyy2);
           END;
           IF GrGetMouseButtons=GrRButton THEN BootIt := True;
     UNTIL ((GrGetMouseButtons=GrLButton) OR (BootIt) OR (yyy2>YWindow));
     GrDrawLine(xxx1,yyy1,xxx2,yyy2);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     GrSetOp(GxSet);
     IF yyy2>YWindow THEN GetLineDraw := False
                     ELSE GetLineDraw := True;
     IF BootIt THEN GetLineDraw := False;
END;


FUNCTION GetSeededLineDraw(x,y: Word): Boolean;
VAR  Bootit : Boolean;
BEGIN
     xxx1 := x;
     yyy1 := y;
     xxx2 := GetMouseXG(Grid);
     yyy2 := GetMouseYG(Grid);
     GrSetColor(9);
     GrSetOp(GxXOR);
     GrDrawLine(xxx1,yyy1,xxx2,yyy2);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     BootIt := False;
     REPEAT
           CheckKeys;
           IF GetMouseYG(Grid)<=YWindow THEN Position;
           IF ((GetMouseXG(Grid)<>XXx2) OR (GetMouseYG(Grid)<>YYy2)) THEN
           BEGIN
                GrDrawLine(xxx1,yyy1,xxx2,yyy2);
                xxx2 := GetMouseXG(Grid);
                yyy2 := GetMouseYG(Grid);
                GrDrawLine(xxx1,yyy1,xxx2,yyy2);
           END;
           IF GrGetMouseButtons=GrRButton THEN BootIt := True;
     UNTIL ((GrGetMouseButtons=GrLButton) OR (BootIt) OR (yyy2>YWindow));
     GrDrawLine(xxx1,yyy1,xxx2,yyy2);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     GrSetOp(GxSet);
     IF yyy2>YWindow THEN GetSeededLineDraw := False
                     ELSE GetSeededLineDraw := True;
     IF BootIt THEN GetSeededLineDraw := False;
END;


FUNCTION GetCircleDraw: Boolean;
VAR  Bootit : Boolean;
     XAxis  : Integer;
     YAxis  : Integer;
BEGIN
     xxx1 := GetMouseXG(Grid);
     yyy1 := GetMouseYG(Grid);
     xxx2 := 0;
     yyy2 := 0;
     GrSetClipRegion(0,0,GraphMaxX,YWindow);
     GrSetClipping(GrClip);
     GrSetColor(XORLine);
     GrSetOp(GxXOR);
     GrDrawEllipse(xxx1,yyy1,xxx2,yyy2,GrOutline);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     BootIt := False;
     REPEAT
           CheckKeys;
           IF GetMouseYG(Grid)<=YWindow THEN Position;
           XAxis := GetMouseXG(Grid)-xxx1;
           YAxis := GetMouseYG(Grid)-yyy1;
           IF XAxis<0 THEN XAxis := XAxis*(-1);
           IF YAxis<0 THEN YAxis := YAxis*(-1);
           IF ((XAxis<>xxx2) OR (YAxis<>yyy2)) THEN
           BEGIN
                GrDrawEllipse(xxx1,yyy1,xxx2,yyy2,GrOutline);
                xxx2 := XAxis;
                yyy2 := YAxis;
                GrDrawEllipse(xxx1,yyy1,xxx2,yyy2,GrOutline);
           END;
           IF GrGetMouseButtons=GrRButton THEN BootIt := True;
     UNTIL ((GrGetMouseButtons=GrLButton) OR (BootIt) OR (yyy2>YWindow));
     GrDrawEllipse(xxx1,yyy1,xxx2,yyy2,GrOutline);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     GrSetOp(GxSet);
     IF yyy2>YWindow THEN GetCircleDraw := False
                     ELSE GetCircleDraw := True;
     IF BootIt THEN GetCircleDraw := False;
     GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
     GrSetClipping(GrClip);
END;


FUNCTION GetSeededCircleDraw(x1,y1,x2,y2: Word): Boolean;
VAR  Bootit : Boolean;
     XAxis  : Integer;
     YAxis  : Integer;
BEGIN
     xxx1 := x1;
     yyy1 := y1;
     xxx2 := x2;
     yyy2 := y2;
     GrSetMousePos(xxx1+xxx2,yyy1+yyy2);
     GrSetClipRegion(0,0,GraphMaxX,YWindow);
     GrSetClipping(GrClip);
     GrSetColor(9);
     GrSetOp(GxXOR);
     GrDrawEllipse(xxx1,yyy1,xxx2,yyy2,GrOutline);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     BootIt := False;
     REPEAT
           CheckKeys;
           IF GetMouseYG(Grid)<=YWindow THEN Position;
           XAxis := GetMouseXG(Grid)-xxx1;
           YAxis := GetMouseYG(Grid)-yyy1;
           IF XAxis<0 THEN XAxis := XAxis*(-1);
           IF YAxis<0 THEN YAxis := YAxis*(-1);
           IF ((XAxis<>xxx2) OR (YAxis<>yyy2)) THEN
           BEGIN
                GrDrawEllipse(xxx1,yyy1,xxx2,yyy2,GrOutline);
                xxx2 := XAxis;
                yyy2 := YAxis;
                GrDrawEllipse(xxx1,yyy1,xxx2,yyy2,GrOutline);
           END;
           IF GrGetMouseButtons=GrRButton THEN BootIt := True;
     UNTIL ((GrGetMouseButtons=GrLButton) OR (BootIt) OR (yyy2>YWindow));
     GrDrawEllipse(xxx1,yyy1,xxx2,yyy2,GrOutline);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     GrSetOp(GxSet);
     IF yyy2>YWindow THEN GetSeededCircleDraw := False
                     ELSE GetSeededCircleDraw := True;
     IF BootIt THEN GetSeededCircleDraw := False;
     GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
     GrSetClipping(GrClip);
END;


FUNCTION GetSeededFillDraw(x,y: Word): Boolean;
VAR  Bootit : Boolean;
BEGIN
     GrSetMousePos(x,y);
     GrSetClipRegion(0,0,GraphMaxX,YWindow);
     GrSetClipping(GrClip);
     GrSetColor(9);
     GrSetOp(GxXOR);
     GrDrawRect(x-2,y-2,x+2,y+2,GrOutline);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     BootIt := False;
     REPEAT
           CheckKeys;
           IF GetMouseYG(Grid)<=YWindow THEN Position;
           IF ((GetMouseXG(Grid)<>x) OR (GetMouseYG(Grid)<>y)) THEN
           BEGIN
                GrDrawRect(x-2,y-2,x+2,y+2,GrOutline);
                x := GetMouseXG(Grid);
                y := GetMouseYG(Grid);
                GrDrawRect(x-2,y-2,x+2,y+2,GrOutline);
           END;
           IF GrGetMouseButtons=GrRButton THEN BootIt := True;
     UNTIL ((GrGetMouseButtons=GrLButton) OR (BootIt) OR (y>YWindow));
     GrDrawRect(x-2,y-2,x+2,y+2,GrOutline);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     GrSetOp(GxSet);
     IF y>YWindow THEN GetSeededFillDraw := False
                  ELSE GetSeededFillDraw := True;
     IF BootIt THEN GetSeededFillDraw := False;
     GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
     GrSetClipping(GrClip);
     xxx1 := x;
     yyy1 := y;
END;


FUNCTION GetDragBox(x1,y1,x2,y2: Word): Boolean;
VAR  Bootit   : Boolean;
     Work     : Word;
     Width    : Word;
     Height   : Word;
     OldMouse : Boolean;
BEGIN
     xxx1   := x1;
     yyy1   := y1;
     xxx2   := x2;
     yyy2   := y2;
     IF MouseOn THEN GrDisplayMouse(GrHide);
     OldMouse := MouseOn;
     MouseOn  := False;
     GrSetMousePos(xxx1,yyy1);
     Width  := x2-x1+1;
     Height := y2-y1+1;
     GrSetColor(XORLine);
     GrSetOp(GxXOR);
     GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
     BootIt := False;
     REPEAT
           CheckKeys;
           IF GetMouseYG(Grid)<=YWindow-Height THEN Position;
           IF ((GetMouseXG(Grid)<>XXX1) OR (GetMouseYG(Grid)<>YYY1)) THEN
           BEGIN
                GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
                xxx1 := GetMouseXG(Grid);
                yyy1 := GetMouseYG(Grid);
                xxx2 := xxx1+Width-1;
                yyy2 := yyy1+Height-1;
                GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
           END;
           IF GrGetMouseButtons=GrRButton THEN BootIt := True;
     UNTIL ((GrGetMouseButtons=GrLButton) OR (BootIt) OR (yyy2>YWindow));
     GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     GrSetOp(GxSet);
     IF yyy2>YWindow THEN GetDragBox := False
                     ELSE GetDragBox := True;
     IF BootIt THEN GetDragBox := False;
     IF xxx1>xxx2 THEN
     BEGIN
          Work := xxx2;
          xxx2 := xxx1;
          xxx1 := Work;
     END;
     IF yyy1>yyy2 THEN
     BEGIN
          Work := yyy2;
          yyy2 := yyy1;
          yyy1 := Work;
     END;
     MouseOn := OldMouse;
     IF MouseOn THEN GrDisplayMouse(GrShow);
     IF yyy2>YWindow THEN GrSetMousePos(xxx1,yyy2+2);
END;


FUNCTION GetSeededDragBox(x1,y1,x2,y2: Word): Boolean;
VAR  Bootit   : Boolean;
     Work     : Word;
     Width    : Word;
     Height   : Word;
     OldMouse : Boolean;
BEGIN
     xxx1   := x1;
     yyy1   := y1;
     xxx2   := x2;
     yyy2   := y2;
     IF MouseOn THEN GrDisplayMouse(GrHide);
     OldMouse := MouseOn;
     MouseOn  := False;
     GrSetMousePos(xxx1,yyy1);
     Width  := x2-x1+1;
     Height := y2-y1+1;
     GrSetColor(XORLine);
     GrSetOp(GxXOR);
     GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     BootIt := False;
     REPEAT
           CheckKeys;
           IF GetMouseYG(Grid)<=YWindow-Height THEN Position;
           IF ((GetMouseXG(Grid)<>XXX1) OR (GetMouseYG(Grid)<>YYY1)) THEN
           BEGIN
                GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
                xxx1 := GetMouseXG(Grid);
                yyy1 := GetMouseYG(Grid);
                xxx2 := xxx1+Width-1;
                yyy2 := yyy1+Height-1;
                GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
           END;
           IF GrGetMouseButtons=GrRButton THEN BootIt := True;
     UNTIL ((GrGetMouseButtons=GrLButton) OR (BootIt) OR (yyy2>YWindow));
     GrDrawRect(xxx1,yyy1,xxx2,yyy2,GrOutline);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     GrSetOp(GxSet);
     IF yyy2>YWindow THEN GetSeededDragBox := False
                     ELSE GetSeededDragBox := True;
     IF BootIt THEN GetSeededDragBox := False;
     IF xxx1>xxx2 THEN
     BEGIN
          Work := xxx2;
          xxx2 := xxx1;
          xxx1 := Work;
     END;
     IF yyy1>yyy2 THEN
     BEGIN
          Work := yyy2;
          yyy2 := yyy1;
          yyy1 := Work;
     END;
     MouseOn := OldMouse;
     IF MouseOn THEN GrDisplayMouse(GrShow);
     IF yyy2>YWindow THEN GrSetMousePos(xxx1,yyy2+2);
END;


FUNCTION GetGlobalVariable(Num: Word): String;
BEGIN
     CASE Num OF
     1:   GetGlobalVariable := '{BBSNAME}';
     2:   GetGlobalVariable := '{BBSLOCATION}';
     3:   GetGlobalVariable := '{SYSOPSREALNAME}';
     4:   GetGlobalVariable := '{SYSOPSALIASNAME}';
     5:   GetGlobalVariable := '{TCALLS}';
     6:   GetGlobalVariable := '{CALLST}';
     7:   GetGlobalVariable := '{BAUD}';
     8:   GetGlobalVariable := '{COM}';
     9:   GetGlobalVariable := '{NODE}';
     10:  GetGlobalVariable := '{OPERATINGSYSTEM}';
     11:  GetGlobalVariable := '{CBVS}';
     12:  GetGlobalVariable := '{CBVE}';
     13:  GetGlobalVariable := '{EVT}';
     14:  GetGlobalVariable := '{FMONTHDAYYEAR}';
     15:  GetGlobalVariable := '{MMDDYYYY}';
     16:  GetGlobalVariable := '{STIME}';
     17:  GetGlobalVariable := '{ANS}';
     18:  GetGlobalVariable := '{IBM}';
     19:  GetGlobalVariable := '{CLR}';
     20:  GetGlobalVariable := '{FSE}';
     21:  GetGlobalVariable := '{FDL}';
     22:  GetGlobalVariable := '{SEP}';
     23:  GetGlobalVariable := '{IUL}';
     24:  GetGlobalVariable := '{PAGE}';
     25:  GetGlobalVariable := '{UPROTOCOL}';
     26:  GetGlobalVariable := '{UARCHIVER}';
     27:  GetGlobalVariable := '{UQUOTE}';
     28:  GetGlobalVariable := '{USERSREALNAME}';
     29:  GetGlobalVariable := '{USERSALIASNAME}';
     30:  GetGlobalVariable := '{USERSFNAME}';
     31:  GetGlobalVariable := '{USERSLNAME}';
     32:  GetGlobalVariable := '{USERSPASSWORD}';
     33:  GetGlobalVariable := '{USEX}';
     34:  GetGlobalVariable := '{BIRTHD}';
     35:  GetGlobalVariable := '{USERSDATANUM}';
     36:  GetGlobalVariable := '{USERSVOICENUM}';
     37:  GetGlobalVariable := '{USERSSTREETADDRESS}';
     38:  GetGlobalVariable := '{USERSCITY}';
     39:  GetGlobalVariable := '{USERSPROVINCE}';
     40:  GetGlobalVariable := '{USERSCOUNTRY}';
     41:  GetGlobalVariable := '{USERSPOSTALCODE}';
     42:  GetGlobalVariable := '{USERACC}';
     43:  GetGlobalVariable := '{SUBMODEL}';
     44:  GetGlobalVariable := '{SUBTIME1}';
     45:  GetGlobalVariable := '{SUBTIME2}';
     46:  GetGlobalVariable := '{SUBTIME3}';
     47:  GetGlobalVariable := '{USETIME1}';
     48:  GetGlobalVariable := '{USETIME2}';
     49:  GetGlobalVariable := '{USETIME3}';
     50:  GetGlobalVariable := '{USEREX}';
     51:  GetGlobalVariable := '{MR}';
     52:  GetGlobalVariable := '{REMAIN}';
     53:  GetGlobalVariable := '{TO}';
     54:  GetGlobalVariable := '{BDNLOAD}';
     55:  GetGlobalVariable := '{FDNLOAD}';
     56:  GetGlobalVariable := '{BUPLOAD}';
     57:  GetGlobalVariable := '{FUPLOAD}';
     58:  GetGlobalVariable := '{BINBANK}';
     59:  GetGlobalVariable := '{TB}';
     60:  GetGlobalVariable := '{BREMAIN}';
     61:  GetGlobalVariable := '{FRATIO}';
     62:  GetGlobalVariable := '{SYSBYTE}';
     63:  GetGlobalVariable := '{CURRENTFILEAREA}';
     64:  GetGlobalVariable := '{CURRENTFILEGROUP}';
     65:  GetGlobalVariable := '{CURRENTMESSAGEAREA}';
     66:  GetGlobalVariable := '{CURRENTMESSAGEGROUP}';
     67:  GetGlobalVariable := '{FAREA}';
     68:  GetGlobalVariable := '{FSUB}';
     69:  GetGlobalVariable := '{FTAG}';
     70:  GetGlobalVariable := '{MAREA}';
     71:  GetGlobalVariable := '{MSUB}';
     72:  GetGlobalVariable := '{MTAG}';
     73:  GetGlobalVariable := '{MSGS}';
     74:  GetGlobalVariable := '{MNEW}';
     ELSE GetGlobalVariable := '';
     END;
END;


PROCEDURE LoadPickList;
BEGIN
     GrDisplayMouse(GrHide);
     SaveWindow(3);
     NButtons := 0;
     DrawWindow(20,70,580,400,'GLOBAL VARIABLES',FloatingMenu);
     SystemButton(440,360,505,390,1,False,True);
     SystemButton(505,360,570,390,1,False,True);
     OutTextXY(455,367,0,255,1,'Cancel');
     OutTextXY(520,367,0,255,1,'Accept');
     NewPickList(40,110,15,60);
     AddToPickList('BBS Info ÄÄÄÄÄÄÂ The BBS name.');
     AddToPickList('               Ã The BBS location.');
     AddToPickList('               Ã Sysops real name.');
     AddToPickList('               Ã Sysops alias name.');
     AddToPickList('               Ã Total calls to the system.');
     AddToPickList('               À Calls for current day.');
     AddToPickList('Connect Info ÄÄÂ Connection baud rate.');
     AddToPickList('               Ã Com port being used.');
     AddToPickList('               À Current node being used.');
     AddToPickList('System Info ÄÄÄÂ Current operating system/environment.');
     AddToPickList('               Ã CBV - Start time for verifications.');
     AddToPickList('               Ã CBV - End time for verifications.');
     AddToPickList('               Ã Number of minutes to the next event.');
     AddToPickList('               Ã Date : "April 21,1970".');
     AddToPickList('               Ã Date : "04-21-1970".');
     AddToPickList('               À Time : "hh:mm[am/pm]".');
     AddToPickList('User Settings ÄÂ Does user have ANSI?');
     AddToPickList('               Ã Does user have IBM characters?');
     AddToPickList('               Ã Does user have clear screen codes?');
     AddToPickList('               Ã Does user want the full-screen editor?');
     AddToPickList('               Ã Number of file lines the user wants.');
     AddToPickList('               Ã Does user want file seperator bars?');
     AddToPickList('               Ã Is user in the userlist?');
     AddToPickList('               Ã Is user available for chat?');
     AddToPickList('               Ã Users selected protocol');
     AddToPickList('               Ã Users selected archiver');
     AddToPickList('               À Users message quoting');
     AddToPickList('User Personal ÄÂ Users real name.');
     AddToPickList('               Ã Users alias name.');
     AddToPickList('               Ã Users first name.');
     AddToPickList('               Ã Users last name.');
     AddToPickList('               Ã Users password.');
     AddToPickList('               Ã Users gender.');
     AddToPickList('               Ã Users birthdate.');
     AddToPickList('               Ã Users data phone number.');
     AddToPickList('               Ã Users voice phone number.');
     AddToPickList('               Ã Users street address.');
     AddToPickList('               Ã Users city.');
     AddToPickList('               Ã Users province/state/territory.');
     AddToPickList('               Ã Users country.');
     AddToPickList('               Ã Users postal/zip code.');
     AddToPickList('               À Users numeric access level.');
     AddToPickList('Subscription ÄÄÂ Subscription model.');
     AddToPickList('               Ã Sub minutes.');
     AddToPickList('               Ã Sub calendar days.');
     AddToPickList('               Ã Sub call days.');
     AddToPickList('               Ã Minutes used.');
     AddToPickList('               Ã Calendar days used.');
     AddToPickList('               Ã Call days used.');
     AddToPickList('               À Exclusive expiry date.');
     AddToPickList('File/Time Info Â Time remaining : Minutes.');
     AddToPickList('               Ã Time remaining : "hh:mm:ss".');
     AddToPickList('               Ã Time online : Minutes.');
     AddToPickList('               Ã Bytes the user has downloaded.');
     AddToPickList('               Ã Files the user has downloaded.');
     AddToPickList('               Ã Bytes the user has uploaded.');
     AddToPickList('               Ã Files the user has uploaded.');
     AddToPickList('               Ã Bank balance : Bytes.');
     AddToPickList('               Ã Bank balance : Minutes.');
     AddToPickList('               Ã Bytes remaining that the user can DL today.');
     AddToPickList('               Ã Users current file ratio : "ul:dl".');
     AddToPickList('               À Users daily byte limit.');
     AddToPickList('Current Areas ÄÂ Current file area.');
     AddToPickList('               Ã Current file group.');
     AddToPickList('               Ã Current message area.');
     AddToPickList('               À Current message group.');
     AddToPickList('Area Info ÄÄÄÄÄÂ Numeric file area.');
     AddToPickList('               Ã Numeric file group.');
     AddToPickList('               Ã File area is tagged.');
     AddToPickList('               Ã Numeric message area.');
     AddToPickList('               Ã Numeric message group.');
     AddToPickList('               Ã Message area is tagged.');
     AddToPickList('               Ã Messages in current area.');
     AddToPickList('               À New messages in current area.');
     SetUpPickList;
END;


FUNCTION GetTextDraw: Boolean;
VAR  Bootit      : Boolean;
     Work        : Word;
     Width       : Word;
     Height      : Word;
     OldMouse    : Boolean;
     C           : Word;
     CC          : Char;
     TypeWindowX : Word;
     TypeWindowY : Word;
     EditPos     : Word;
     CCC         : Word;
     AllDone     : Boolean;
     Temp        : String;
LABEL              SkipIt,SkipOnIn;
BEGIN
     SaveWindow(1);
     NButtons := 0;
     IF MouseOn THEN GrDisplayMouse(GrHide);
     DrawWindow(5,120,635,250,'TEXT STRING',EditWindow);
     SystemButton(465,200,545,240,1,False,True);
     SystemButton(545,200,625,240,1,False,True);
     SystemButton(100,205,230,235,1,False,True);
     SystemIcon(470,205,64);
     SystemIcon(550,205,65);
     OutTextXY(500,215,0,255,1,'Cancel');
     OutTextXY(590,215,0,255,1,'Ok');
     OutTextXY(120,213,0,255,1,'Global Variables');
     {TEXT ENTRY}
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(15,165,625,185,GrOutline+GrFill);
     InvertedBox(14,164,626,186);
     OutTextXY(15,149,0,255,1,'Edit');
     {STUFFED TEXT ENTRY}
     TypeWindowX := ScreenInfo.OrigX1+ScreenInfo.XOffset+15;
     TypeWindowY := ScreenInfo.OrigY1+ScreenInfo.YOffset+48;
     OutTextXY(TypeWindowX,TypeWindowY,0,15,2,HoldRaw.Text);
     OutTextXY(TypeWindowX+(Length(HoldRaw.Text)*8),TypeWindowY+1,0,15,2,'_');
     EditPos := Length(HoldRaw.Text)+1;
     IF NOT(MouseOn) THEN
     BEGIN
          GrDisplayMouse(GrSHow);
          MouseOn := True;
     END;
     REPEAT
           TypeWindowX := ScreenInfo.OrigX1+ScreenInfo.XOffset+15;
           TypeWindowY := ScreenInfo.OrigY1+ScreenInfo.YOffset+48;
           IF KeyPressed THEN
           BEGIN
                CC := ReadKey;
                IF Ord(CC)=0 THEN
                BEGIN
                     CC := ReadKey;
                     CASE ORD(CC) OF
                     71:  BEGIN {HOME}
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               EditPos := 1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                          END;
                     79:  BEGIN {END}
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               EditPos := Length(HoldRaw.Text)+1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                          END;
                     83:  BEGIN {DELETE}
                               IF (EditPos<=Length(HoldRaw.Text)) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    Delete(HoldRaw.Text,EditPos,1);
                                    OutTextXY(TypeWindowX,TypeWindowY,0,15,2,HoldRaw.Text+' ');
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     75:  BEGIN {LEFT ARROW}
                               IF EditPos>1 THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    DEC(EditPos);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     77:  BEGIN {RIGHT ARROW}
                               IF (EditPos<=LENGTH(HoldRaw.Text)) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    INC(EditPos);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     ELSE BEGIN
                               CC := IsTheKeyOk(CC,True);
                               IF (CC<>#0) THEN GOTO SkipOnIn;
                          END;
                     END;
                END
                ELSE
                BEGIN
                     CASE Ord(CC) OF
                     8:   BEGIN
                               IF (EditPos>1) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    Delete(HoldRaw.Text,EditPos-1,1);
                                    DEC(EditPos);
                                    OutTextXY(TypeWindowX,TypeWindowY,0,15,2,HoldRaw.Text+' ');
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     13:  BEGIN
                               c := 2;
                               GOTO SkipIt;
                          END;
                     27:  BEGIN
                               c := 1;
                               GOTO SkipIt;
                          END;
                     127: BEGIN
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               OutTextXY(TypeWindowX,TypeWindowY,15,15,2,HoldRaw.Text);
                               HoldRaw.Text := '';
                               EditPos := 1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                          END;
                     ELSE BEGIN
                               CC := IsTheKeyOk(CC,False);
                               IF (CC<>#0) THEN
                               BEGIN
                                    SkipOnIn:
                                    IF LENGTH(HoldRaw.Text)<74 THEN
                                    BEGIN
                                         GrDisplayMouse(GrHide);
                                         OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                         HoldRaw.Text := _Mid(HoldRaw.Text,1,EditPos-1)+CC+
                                                         _Mid(HoldRaw.Text,EditPos,LENGTH(HoldRaw.Text));
                                         INC(EditPos);
                                         OutTextXY(TypeWindowX,TypeWindowY,0,15,2,HoldRaw.Text);
                                         OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                         GrDisplayMouse(GrShow);
                                    END;
                               END;
                          END;
                     END;
                END;
           END;
           C := MouseHandler(False);
           CASE C OF
           3:   BEGIN
                     WindowHeader('TEXT STRING',False);
                     LoadPickList;
                     GrDisplayMouse(GrShow);
                     AllDone := False;
                     Temp    := '';
                     REPEAT
                           CCC := MouseHandler(False);
                           CASE CCC OF
                           1:   AllDone := True;
                           2:   BEGIN
                                     AllDone := True;
                                     Temp    := GetGlobalVariable(PickInfo.Current);
                                END;
                           END;
                     UNTIL AllDone;
                     KillWindow;
                     ReloadWindow(3);
                     KillPickList;
                     WindowHeader('TEXT STRING',True);
                     IF Temp<>'' THEN
                     BEGIN
                          GrDisplayMouse(GrHide);
                          OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                          HoldRaw.Text := _Mid(HoldRaw.Text,1,EditPos-1)+Temp+
                                          _Mid(HoldRaw.Text,EditPos,LENGTH(HoldRaw.Text));
                          IF Length(HoldRaw.Text)>74 THEN HoldRaw.Text := _Mid(HoldRaw.Text,1,74);
                          OutTextXY(TypeWindowX,TypeWindowY,0,15,2,HoldRaw.Text);
                          OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                          GrDisplayMouse(GrShow);
                     END;
                END;
           END;
           SkipIt:
     UNTIL ((C=1) OR (c=2));
     KillWindow;
     ReloadWindow(1);
     GrDisplayMouse(GrHide);
     MouseOn := False;
     IF ((c=1) OR (HoldRaw.Text='')) THEN
     BEGIN
          GetTextDraw := False;
          Exit;
     END;
     xxx1   := GetMouseXG(Grid);
     yyy1   := GetMouseYG(Grid);
     GrSetMousePos(xxx1,yyy1);
     GetFontSize(HoldRaw.Colour7,HoldRaw.ObjFile,HoldRaw.Text,Width,Height);
     GrSetColor(XORLine);
     GrSetOp(GxXOR);
     GrDrawRect(xxx1,yyy1,xxx1+Width-1,yyy1+Height-1,GrOutline);
     BootIt := False;
     REPEAT
           CheckKeys;
           IF GetMouseYG(Grid)<=YWindow-Height THEN Position;
           IF ((GetMouseXG(Grid)<>XXX1) OR (GetMouseYG(Grid)<>YYY1)) THEN
           BEGIN
                GrDrawRect(xxx1,yyy1,xxx1+Width-1,yyy1+Height-1,GrOutline);
                xxx1 := GetMouseXG(Grid);
                yyy1 := GetMouseYG(Grid);
                GrDrawRect(xxx1,yyy1,xxx1+Width-1,yyy1+Height-1,GrOutline);
           END;
           IF GrGetMouseButtons=GrRButton THEN BootIt := True;
     UNTIL ((GrGetMouseButtons=GrLButton) OR (BootIt) OR (yyy1+Height-1>YWindow));
     GrDrawRect(xxx1,yyy1,xxx1+Width-1,yyy1+Height-1,GrOutline);
     REPEAT
     UNTIL GrGetMouseButtons<>GrLButton;
     GrSetOp(GxSet);
     IF yyy1+Height-1>YWindow THEN GetTextDraw := False
                              ELSE GetTextDraw := True;
     IF BootIt THEN GetTextDraw := False;
     IF yyy1+Height-1>YWindow THEN GrSetMousePos(xxx1,yyy1+Height+2);
END;


FUNCTION GetChangeText: Boolean;
VAR  Bootit      : Boolean;
     Work        : Word;
     Width       : Word;
     Height      : Word;
     OldMouse    : Boolean;
     C           : Word;
     CC          : Char;
     TypeWindowX : Word;
     TypeWindowY : Word;
     EditPos     : Word;
     WorkText    : String;
     CCC         : Word;
     AllDone     : Boolean;
     Temp        : String;
LABEL              SkipIt,SkipOnIn;
BEGIN
     WorkText := HoldRaw.Text;
     SaveWindow(1);
     NButtons := 0;
     GrDisplayMouse(GrHide);
     DrawWindow(5,120,635,250,'TEXT STRING',EditWindow);
     SystemButton(465,200,545,240,1,False,True);
     SystemButton(545,200,625,240,1,False,True);
     SystemButton(100,205,230,235,1,False,True);
     SystemIcon(470,205,64);
     SystemIcon(550,205,65);
     OutTextXY(500,215,0,255,1,'Cancel');
     OutTextXY(590,215,0,255,1,'Ok');
     OutTextXY(120,213,0,255,1,'Global Variables');
     {TEXT ENTRY}
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(15,165,625,185,GrOutline+GrFill);
     InvertedBox(14,164,626,186);
     OutTextXY(15,149,0,255,1,'Edit');
     {STUFFED TEXT ENTRY}
     TypeWindowX := ScreenInfo.OrigX1+ScreenInfo.XOffset+15;
     TypeWindowY := ScreenInfo.OrigY1+ScreenInfo.YOffset+48;
     OutTextXY(TypeWindowX,TypeWindowY,0,15,2,WorkText);
     OutTextXY(TypeWindowX+(Length(WorkText)*8),TypeWindowY+1,0,15,2,'_');
     EditPos := Length(WorkText)+1;
     GrDisplayMouse(GrSHow);
     MouseOn := True;
     REPEAT
           TypeWindowX := ScreenInfo.OrigX1+ScreenInfo.XOffset+15;
           TypeWindowY := ScreenInfo.OrigY1+ScreenInfo.YOffset+48;
           IF KeyPressed THEN
           BEGIN
                CC := ReadKey;
                IF Ord(CC)=0 THEN
                BEGIN
                     CC := ReadKey;
                     CASE ORD(CC) OF
                     71:  BEGIN {HOME}
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               EditPos := 1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                          END;
                     79:  BEGIN {END}
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               EditPos := Length(WorkText)+1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                          END;
                     83:  BEGIN {DELETE}
                               IF (EditPos<=Length(WorkText)) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    Delete(WorkText,EditPos,1);
                                    OutTextXY(TypeWindowX,TypeWindowY,0,15,2,WorkText+' ');
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     75:  BEGIN {LEFT ARROW}
                               IF EditPos>1 THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    DEC(EditPos);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     77:  BEGIN {RIGHT ARROW}
                               IF (EditPos<=LENGTH(WorkText)) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    INC(EditPos);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     ELSE BEGIN
                               CC := IsTheKeyOk(CC,True);
                               IF (CC<>#0) THEN GOTO SkipOnIn;
                          END;
                     END;
                END
                ELSE
                BEGIN
                     CASE Ord(CC) OF
                     8:   BEGIN
                               IF (EditPos>1) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    Delete(WorkText,EditPos-1,1);
                                    DEC(EditPos);
                                    OutTextXY(TypeWindowX,TypeWindowY,0,15,2,WorkText+' ');
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     13:  BEGIN
                               c := 2;
                               GOTO SkipIt;
                          END;
                     27:  BEGIN
                               c := 1;
                               GOTO SkipIt;
                          END;
                     127: BEGIN
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               OutTextXY(TypeWindowX,TypeWindowY,15,15,2,WorkText);
                               WorkText := '';
                               EditPos := 1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                          END;
                     ELSE BEGIN
                               CC := IsTheKeyOk(CC,False);
                               IF (CC<>#0) THEN
                               BEGIN
                                    SkipOnIn:
                                    IF LENGTH(WorkText)<74 THEN
                                    BEGIN
                                         GrDisplayMouse(GrHide);
                                         OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                         WorkText := _Mid(WorkText,1,EditPos-1)+CC+
                                                     _Mid(WorkText,EditPos,LENGTH(WorkText));
                                         INC(EditPos);
                                         OutTextXY(TypeWindowX,TypeWindowY,0,15,2,WorkText);
                                         OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                         GrDisplayMouse(GrShow);
                                    END;
                               END;
                          END;
                     END;
                END;
           END;
           C := MouseHandler(False);
           CASE C OF
           3:   BEGIN
                     WindowHeader('TEXT STRING',False);
                     LoadPickList;
                     GrDisplayMouse(GrShow);
                     AllDone := False;
                     Temp    := '';
                     REPEAT
                           CCC := MouseHandler(False);
                           CASE CCC OF
                           1:   AllDone := True;
                           2:   BEGIN
                                     AllDone := True;
                                     Temp    := GetGlobalVariable(PickInfo.Current);
                                END;
                           END;
                     UNTIL AllDone;
                     KillWindow;
                     ReloadWindow(3);
                     KillPickList;
                     WindowHeader('TEXT STRING',True);
                     IF Temp<>'' THEN
                     BEGIN
                          GrDisplayMouse(GrHide);
                          OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                          WorkText := _Mid(WorkText,1,EditPos-1)+Temp+
                                      _Mid(WorkText,EditPos,LENGTH(WorkText));
                          IF Length(WorkText)>74 THEN WorkText := _Mid(WorkText,1,74);
                          OutTextXY(TypeWindowX,TypeWindowY,0,15,2,WorkText);
                          OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                          GrDisplayMouse(GrShow);
                     END;
                END;
           END;
           SkipIt:
     UNTIL ((C=1) OR (c=2));
     KillWindow;
     ReloadWindow(1);
     IF ((c=1) OR (WorkText='')) THEN
     BEGIN
          GetChangeText := False;
          Exit;
     END;
     HoldRaw.Text  := WorkText;
     GetChangeText := True;
END;


FUNCTION GetChangeTextFile: Boolean;
VAR  Bootit      : Boolean;
     Work        : Word;
     Width       : Word;
     Height      : Word;
     OldMouse    : Boolean;
     C           : Word;
     CC          : Char;
     TypeWindowX : Word;
     TypeWindowY : Word;
     EditPos     : Word;
     WorkText    : String;
     CCC         : Word;
     AllDone     : Boolean;
     Temp        : String;
LABEL              SkipIt,SkipOnIn;
BEGIN
     WorkText := HoldRaw.Text;
     SaveWindow(1);
     NButtons := 0;
     GrDisplayMouse(GrHide);
     DrawWindow(5,120,635,250,'TEXT FILE',EditWindow);
     SystemButton(465,200,545,240,1,False,True);
     SystemButton(545,200,625,240,1,False,True);
     SystemIcon(470,205,64);
     SystemIcon(550,205,65);
     OutTextXY(500,215,0,255,1,'Cancel');
     OutTextXY(590,215,0,255,1,'Ok');
     {TEXT ENTRY}
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(15,165,625,185,GrOutline+GrFill);
     InvertedBox(14,164,626,186);
     OutTextXY(15,149,0,255,1,'Edit');
     {STUFFED TEXT ENTRY}
     TypeWindowX := ScreenInfo.OrigX1+ScreenInfo.XOffset+15;
     TypeWindowY := ScreenInfo.OrigY1+ScreenInfo.YOffset+48;
     OutTextXY(TypeWindowX,TypeWindowY,0,15,2,WorkText);
     OutTextXY(TypeWindowX+(Length(WorkText)*8),TypeWindowY+1,0,15,2,'_');
     EditPos := Length(WorkText)+1;
     GrDisplayMouse(GrSHow);
     MouseOn := True;
     REPEAT
           TypeWindowX := ScreenInfo.OrigX1+ScreenInfo.XOffset+15;
           TypeWindowY := ScreenInfo.OrigY1+ScreenInfo.YOffset+48;
           IF KeyPressed THEN
           BEGIN
                CC := ReadKey;
                IF Ord(CC)=0 THEN
                BEGIN
                     CC := ReadKey;
                     CASE ORD(CC) OF
                     71:  BEGIN {HOME}
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               EditPos := 1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                          END;
                     79:  BEGIN {END}
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               EditPos := Length(WorkText)+1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                          END;
                     83:  BEGIN {DELETE}
                               IF (EditPos<=Length(WorkText)) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    Delete(WorkText,EditPos,1);
                                    OutTextXY(TypeWindowX,TypeWindowY,0,15,2,WorkText+' ');
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     75:  BEGIN {LEFT ARROW}
                               IF EditPos>1 THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    DEC(EditPos);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     77:  BEGIN {RIGHT ARROW}
                               IF (EditPos<=LENGTH(WorkText)) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    INC(EditPos);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     ELSE BEGIN
                               CC := IsTheKeyOk(CC,True);
                               IF (CC<>#0) THEN GOTO SkipOnIn;
                          END;
                     END;
                END
                ELSE
                BEGIN
                     CASE Ord(CC) OF
                     8:   BEGIN
                               IF (EditPos>1) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    Delete(WorkText,EditPos-1,1);
                                    DEC(EditPos);
                                    OutTextXY(TypeWindowX,TypeWindowY,0,15,2,WorkText+' ');
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     13:  BEGIN
                               c := 2;
                               GOTO SkipIt;
                          END;
                     27:  BEGIN
                               c := 1;
                               GOTO SkipIt;
                          END;
                     127: BEGIN
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               OutTextXY(TypeWindowX,TypeWindowY,15,15,2,WorkText);
                               WorkText := '';
                               EditPos := 1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                          END;
                     ELSE BEGIN
                               CC := IsTheKeyOk(CC,False);
                               IF (CC<>#0) THEN
                               BEGIN
                                    SkipOnIn:
                                    IF LENGTH(WorkText)<74 THEN
                                    BEGIN
                                         GrDisplayMouse(GrHide);
                                         OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                         WorkText := _Mid(WorkText,1,EditPos-1)+CC+
                                                     _Mid(WorkText,EditPos,LENGTH(WorkText));
                                         INC(EditPos);
                                         OutTextXY(TypeWindowX,TypeWindowY,0,15,2,WorkText);
                                         OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                         GrDisplayMouse(GrShow);
                                    END;
                               END;
                          END;
                     END;
                END;
           END;
           C := MouseHandler(False);
           SkipIt:
     UNTIL ((C=1) OR (c=2));
     KillWindow;
     ReloadWindow(1);
     IF ((c=1) OR (WorkText='')) THEN
     BEGIN
          GetChangeTextFile := False;
          Exit;
     END;
     HoldRaw.Text      := WorkText;
     GetChangeTextFile := True;
END;


END.