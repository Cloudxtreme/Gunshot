{$I DEFINES.INC}
UNIT BsGlobal;


INTERFACE


{
1 - ! Button
2 - ! On/Off Toggle
3 - ! Dropdown Picklist
4 - ! Colour Palette - Background
5 - ! Colour Palette - Foreground
6 - ! Pick List
7 - ! Editor Box
      Data Entry - Time
                   Proper String
                   Plain String
                   Numeric
                   Phone Number
                   File Name
                   Date
                   File Path
                   Upper Case String
                   Network Aka
}

CONST Video25           : Byte = 25;
      Video28           : Byte = 28;
      Video30           : Byte = 30;
      Video50           : Byte = 50;
      VideoFD           : Byte = 1;
      VideoTV           : Byte = 2;
      VideoNU           : Byte = 3;
      VideoSG           : Byte = 4;
      VideoIM           : Byte = 5;
      eNormalText       : Byte = 1;
      eProperText       : Byte = 2;
      eUpperText        : Byte = 3;
      eNumeric          : Byte = 4;
      eDate             : Byte = 5;
      ePassword         : Byte = 6;
      ePhoneNumber      : Byte = 7;
      eFileName         : Byte = 8;
      eTime             : Byte = 9;
      eTags             : Byte = 10;
      OnOffConfine      : String[4] = '[ ] ';
      OnOffToggle       : Char = 'þ';
      evtExitWindow     : Word = 9999;
      ApplicationClosed : Boolean = False;
      directionUP       : Byte = 1;
      directionDOWN     : Byte = 2;
      directionLEFT     : Byte = 3;
      directionRIGHT    : Byte = 4;
{$IFDEF DPMI}
CONST MaxMenus          = 15;
      MaxOptions        = 25;
      MaxWindows        = 30;
      MaxButtons        = 50;
      MaxOnOff          = 50;
      MaxDropList       = 50;
      MaxPickList       = 15;
      MaxBackGround     = 50;
      MaxForeGround     = 50;
      MaxEditor         = 5;
{$ELSE}
CONST MaxMenus          = 10;
      MaxOptions        = 20;
      MaxWindows        = 10;
      MaxButtons        = 20;
      MaxOnOff          = 20;
      MaxDropList       = 10;
      MaxPickList       = 5;
      MaxBackGround     = 10;
      MaxForeGround     = 10;
      MaxEditor         = 5;
{$ENDIF}
TYPE  PickListText      = RECORD
      Line              : String[78];
      END;
TYPE  dt_Application    = RECORD
      VideoMode         : Byte;
      VideoBytes        : Word;
      VideoOrig         : Word;
      AppName           : String[40];
      AppStyle          : Byte;
      AppMenus          : Byte;
      MenuBarY          : Byte;
      SavedDesktop      : Array[1..8000] Of Byte;
      CurrentMenu       : Byte;
      CurrentSelect     : Byte;
      StartUpDir        : String[80];
      WorkDir           : String[80];
      END;
TYPE  dt_Colours        = RECORD
      MenuNormal        : Byte;
      MenuHighlight     : Byte;
      MenuSNormal       : Byte;
      MenuSHighlight    : Byte;
      MenuDisabled      : Byte;
      MenuSDisabled     : Byte;
      MenuFrame         : Byte;
      MenuSeperator     : Byte;
      StatusNormal      : Byte;
      StatusSeperator   : Byte;
      StatusHighlight   : Byte;
      StatusSelected    : Byte;
      DeskTopFill       : Byte;
      DeskTopBorder     : Byte;
      AppName           : Byte;
      WindowTitle       : Byte;
      WindowBorderH     : Byte;
      WindowBorderL     : Byte;
      WindowText        : Byte;
      WindowHighlight   : Byte;
      WindowBack        : Byte;
      ButtonNormal      : Byte;
      ButtonHighlight   : Byte;
      ButtonSNormal     : Byte;
      ButtonSHighlight  : Byte;
      ButtonDisabled    : Byte;
      ButtonSDisabled   : Byte;
      ButtonShadow      : Byte;
      OnOffNormal       : Byte;
      OnOffHighlight    : Byte;
      OnOffSNormal      : Byte;
      OnOffSHighlight   : Byte;
      OnOffDisabled     : Byte;
      OnOffSDisabled    : Byte;
      DropListText      : Byte;
      DropListDisabled  : Byte;
      DropListSText     : Byte;
      DropListSDisabled : Byte;
      DropListBars      : Byte;
      DropListSBars     : Byte;
      ScrollBarH        : Byte;
      ScrollBarL        : Byte;
      FrameHigh         : Byte;
      FrameLow          : Byte;
      PickNormal        : Byte;
      PickHighlight     : Byte;
      PickSNormal       : Byte;
      PickSHighlight    : Byte;
      EditText          : Byte;
      EditTextDisabled  : Byte;
      EditorText        : Byte;
      EditorSText       : Byte;
      EditorSBackground : Byte;
      EditorDisabled    : Byte;
      EditorSDisabled   : Byte;
      END;
TYPE  dt_MenuOptions    = RECORD
      KeyPress          : Char;
      Title             : String[30];
      Enabled           : Boolean;
      Seperator         : Boolean;
      KeyHelp           : String[40];
      END;
TYPE  dt_MenuMain       = RECORD
      KeyPress          : Char;
      XPos              : Byte;
      Title             : String[30];
      NumOpt            : Byte;
      MenuOpt           : Array[1..MaxOptions] Of dt_MenuOptions;
      MaxMenuWidth      : Byte;
      END;
TYPE  dt_Menus          = RECORD
      Menu              : Array[1..MaxMenus] Of dt_MenuMain;
      END;
TYPE  dt_WinMain        = RECORD
      XPos              : Word;
      YPos              : Word;
      END;
TYPE  dt_Windows        = RECORD
      Window            : Array[1..MaxWindows] Of dt_WinMain;
      NumWindows        : Byte;
      END;
TYPE  dt_ButtonMain     = RECORD
      KeyPress          : Char;
      XPos              : Word;
      YPos              : Word;
      LabelName         : String[20];
      Enabled           : Boolean;
      Len               : Byte;
      END;
TYPE  dt_Buttons        = RECORD
      Button            : Array[1..MaxButtons] Of dt_ButtonMain;
      NumButtons        : Byte;
      END;
TYPE  dt_EventQueue     = RECORD
      EventType         : Byte;
      IndexNum          : Word;
      HelpIndex         : Word;
      END;
TYPE  dt_OnOffMain      = RECORD
      KeyPress          : Char;
      XPos              : Word;
      YPos              : Word;
      LabelName         : String[30];
      Enabled           : Boolean;
      Len               : Byte;
      Status            : Boolean;
      END;
TYPE  dt_OnOff          = RECORD
      Button            : Array[1..MaxOnOff] Of dt_OnOffMain;
      NumOnOffs         : Byte;
      END;
TYPE  dt_DropListMain   = RECORD
      KeyPress          : Char;
      XPos              : Word;
      YPos              : Word;
      Enabled           : Boolean;
      Current           : Word;
      NumItems          : Word;
      Len               : Byte;
      OnScreen          : Word;
      FFile             : File Of PickListText;
      END;
TYPE  dt_DropList       = RECORD
      List              : Array[1..MaxDropList] Of dt_DropListMain;
      NumDropLists      : Byte;
      END;
TYPE  dt_BackGroundMain = RECORD
      KeyPress          : Char;
      XPos              : Word;
      YPos              : Word;
      Enabled           : Boolean;
      Current           : Word;
      END;
TYPE  dt_BackGround     = RECORD
      Palette           : Array[1..MaxBackGround] Of dt_BackGroundMain;
      NumBackGround     : Byte;
      END;
TYPE  dt_ForeGroundMain = RECORD
      KeyPress          : Char;
      XPos              : Word;
      YPos              : Word;
      Enabled           : Boolean;
      Current           : Word;
      END;
TYPE  dt_ForeGround     = RECORD
      Palette           : Array[1..MaxForeGround] Of dt_ForeGroundMain;
      NumForeGround     : Byte;
      END;
TYPE  dt_PickListMain   = RECORD
      XPos              : Word;
      YPos              : Word;
      Current           : Word;
      NumItems          : Word;
      Len               : Byte;
      OnScreen          : Word;
      Top               : Word;
      Scroller          : Word;
      FFile             : File Of PickListText;
      END;
TYPE  dt_PickList       = RECORD
      List              : Array[1..MaxPickList] Of dt_PickListMain;
      NumPickLists      : Byte;
      END;
TYPE  dt_EditorBuffer   = Array[1..48000] Of Char;
TYPE  dt_EditorMain     = RECORD
      XPos              : Word;
      YPos              : Word;
      UserX             : Word;
      UserY             : Word;
      TopCharNum        : Word;
      Current           : Word;
      Total             : Word;
      OnScreen          : Array[1..50] Of String[88];
      Locators          : Array[1..3000] Of Word;
      TotalLines        : Word;
      IsOnScreen        : Boolean;
      TopLine           : Word;
      CharsOnScrn       : Word;
      LinesOnScrn       : Byte;
      LastPosX          : Word;
      LastPosY          : Word;
      AltKey            : Boolean;
      BodyText          : ^dt_EditorBuffer;
      END;
TYPE  dt_Editor         = RECORD
      Editor            : Array[1..MaxEditor] Of dt_EditorMain;
      NumEditors        : Byte;
      END;
VAR   dtApp             : ^dt_Application;
      dtMenus           : ^dt_Menus;
      dtColours         : ^dt_Colours;
      dtWindows         : ^dt_Windows;
      dtButtons         : ^dt_Buttons;
      dtOnOff           : ^dt_OnOff;
      dtDropList        : ^dt_DropList;
      dtPickList        : ^dt_PickList;
      dtBackGround      : ^dt_BackGround;
      dtForeGround      : ^dt_ForeGround;
      dtEditor          : ^dt_Editor;
      dtEventQueue      : Array[1..100] Of dt_EventQueue;
      dtCurrentEvent    : Word;
      dtNumEvents       : Word;


IMPLEMENTATION


END.
