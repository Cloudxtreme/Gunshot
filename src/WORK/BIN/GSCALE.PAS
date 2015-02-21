{$M 16384,0,655360}
PROGRAM ThumbprintMaker;


{$I DEFINES.INC}


USES GXM,Gx_Tp,Img_Tp,Gx_TpVc,BsComp,Crt,BsString,BsGraph,BsFile;


TYPE ReturnRecord = RECORD
     W            : Word;
     H            : Word;
     Success      : Boolean;
     END;
VAR  Error    : Integer;
     imghdr   : IMGINHDR;
     BMPFile  : GXHeader;
     gxctype  : Integer;
     gxtype   : Integer;
     dipal    : Array[0..767] Of Byte;
     NodeDir  : String;
     Source   : String;
     Dest     : String;
     ReturnR  : ReturnRecord;
     FReturnR : File Of ReturnRecord;
     Width    : Word;
     Height   : Word;


PROCEDURE QuitProgram;
BEGIN
     gxRemoveDMM;
     gxDone;
     gxSetUserMalloc(pointer(0),pointer(0),pointer(0));
     Halt;
END;


BEGIN
     NodeDir := ParamStr(1);
     Source  := ParamStr(2);
     IF (ParamStr(3)<>'$$BB$$SS$$') THEN
     BEGIN
          ClrScr;
          TEXTCOLOR(10);
          WRITELN('This program is a component of the Shotgun Professional package.');
          WRITELN('You do not directly execute this program manually yourself.');
          TEXTCOLOR(7);
          WRITELN;
          Halt;
     END;
     Width  := _Numeric(ParamStr(4));
     Height := _Numeric(ParamStr(5));
     gxSetUserMalloc(@MyFarMalloc,@MyFarFree,@MyFarCoreLeft);
     Dest   := NodeDir+'\IMAGE.$$$';
     FillChar(ReturnR,SizeOf(ReturnR),0);
     GraphicsMode_BS(256,640,True,False);
     gxInstallDMM(NodeDir,gxNULL);
     Error := imgFileGetHeader(Source,0,imghdr,@dipal[0]);
     IF ((Width=32000) AND (Height=32000)) THEN
     BEGIN
          IF Error=GxSuccess THEN
          BEGIN
               ASSIGN(FReturnR,NodeDir+'\IMGSCALE.$$$');
               REWRITE(FReturnR);
               WRITE(FReturnR,ReturnR);
               CLOSE(FReturnR);
          END;
          QuitProgram;
     END
     ELSE
     BEGIN
          IF (Error<>GxSuccess) THEN QuitProgram;
     END;
     ReturnR.W := imghdr.width;
     ReturnR.H := imghdr.height;
     gxCType := gxGetColorType(imghdr.BitsPerPixel);
     gxType  := gxMatchDisplayType(imghdr.Width,imghdr.Height,gxctype,gxMATCHANY);
     gxCreateVirtual(gxDMM,BMPFile,gxType,Width,Height);
     imgFileScale(Source,0,BMPFile);
     imgVirtualFile(BMPFile,0,0,Width-1,Height-1,Dest,imgBMP,imgTRUNC,@dipal[0]);
     gxDestroyVirtual(BMPFile);
     CompressFile(Dest,_NoExtension(Dest)+'.CMP');
     ReturnR.Success := True;
     ASSIGN(FReturnR,NodeDir+'\IMGSCALE.$$$');
     REWRITE(FReturnR);
     WRITE(FReturnR,ReturnR);
     CLOSE(FReturnR);
     QuitProgram;
END.
