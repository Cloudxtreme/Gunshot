Unit MKOpen; {Open a message area using an MsgAreaId}

{$I MKB.Def}

{
     MKOpen - Copyright 1993 by Mark May - MK Software
     You are free to use this code in your programs, however
     it may not be included in Source/TPU function libraries
     without my permission.

     Mythical Kingom Tech BBS (513)237-7737 HST/v32
     FidoNet: 1:110/290
     Rime: ->MYTHKING
     You may also reach me at maym@dmapub.dma.org
}


Interface


Uses MKMsgAbs;


Function OpenOrCreateMsgArea(Var Msg: AbsMsgPtr; MsgAreaId: String; MaxMsgs: Word): Boolean;
Function CloseMsgArea(Var Msg: AbsMsgPtr): Boolean;


Implementation


{Uses MKMsgHud, MKMsgFid, MKMsgSqu, MKMsgEzy, MKMsgJam;}
Uses MKMsgFid, MKMsgSqu, MKMsgJam, FMode;

{ Area ids begin with identifier for msg base type }
{ The following characters are already reserved    }
{   B = PC-Board            }
{   E = Ezycomm             }
{   F = Fido *.Msg          }
{   H = Hudson              }
{   I = ISR - msg fossil    }
{   J = JAM                 }
{   M = MK-Merlin           }
{   P = *.PKT               }
{   Q = QWK/REP             }
{   R = Renegade            }
{   S = Squish              }
{   W = Wildcat             }


Function InitMsgPtr(Var Msg: AbsMsgPtr; MsgAreaId: String): Boolean;
Begin
     Msg := Nil;
     InitMsgPtr := True;
     Case UpCase(MsgAreaId[1]) of
     {'E': Msg := New(EzyMsgPtr, Init);}
     {'H': Msg := New(HudsonMsgPtr, Init);}
     'S': Msg := New(SqMsgPtr, Init);
     'F': Msg := New(FidoMsgPtr, Init);
     'J': Msg := New(JamMsgPtr, Init);
     Else InitMsgPtr := False;
     End;
     If Msg <> Nil Then Msg^.SetMsgPath(Copy(MsgAreaId, 2, 128));
End;


Function DoneMsgPtr(Var Msg: AbsMsgPtr): Boolean;
Begin
     If Msg <> Nil Then Dispose(Msg, Done);
     Msg := Nil;
End;


Function OpenOrCreateMsgArea(Var Msg: AbsMsgPtr; MsgAreaId: String; MaxMsgs: Word): Boolean;
Begin
     If InitMsgPtr(Msg, MsgAreaId) Then
     Begin
          OpenOrCreateMsgArea := True;
          If Not Msg^.MsgBaseExists Then
          Begin
               If Not Msg^.CreateMsgBase(MaxMsgs,30) = 0 Then
               Begin
                    OpenOrCreateMsgArea := False;
               End;
          End;
          If Msg^.OpenMsgBase <> 0 Then
          Begin
               OpenOrCreateMsgArea := False;
               If DoneMsgPtr(Msg) Then;
          End;
     End;
     IF IoResult=0 THEN;
     FileMode := SetFileMode;
End;


Function CloseMsgArea(Var Msg: AbsMsgPtr): Boolean;
Begin
     If Msg <> Nil Then
     Begin
          CloseMsgArea := (Msg^.CloseMsgBase = 0);
          If DoneMsgPtr(Msg) Then;
     End
     Else CloseMsgArea := False;
     IF IoResult=0 THEN;
     FileMode := SetFileMode;
End;


End.
