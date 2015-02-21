{$I DEFINES.INC}
UNIT HeapVars;


INTERFACE


PROCEDURE LoadHeapVars;
PROCEDURE DisposeHeapVars;


IMPLEMENTATION


USES Globals;


PROCEDURE LoadHeapVars;
BEGIN
     New(Animate);
     New(Buttons);
     New(Callers);
     New(Custom);
     New(Fields);
     New(FileDefs);
     New(FileDefs2);
     New(FileDesc);
     New(GFXBuffer);
     New(HugePick);
     New(Locators);
     New(MailerInfo);
     New(Menu);
     New(MsgIndex);
     New(MsgText);
     New(NodeInfo);
     New(OnScreen);
     New(PolyPoint);
     New(QWKTextBuffer);
     New(TaggedFiles);
     New(UserRecord2);
     New(WorkBuffer);
     FillChar(Animate^,SizeOf(Animate^),0);
     FillChar(Buttons^,SizeOf(Buttons^),0);
     FillChar(Callers^,SizeOf(Callers^),0);
     FillChar(Custom^,SizeOf(Custom^),0);
     FillChar(Fields^,SizeOf(Fields^),0);
     FillChar(FileDefs^,SizeOf(FileDefs^),0);
     FillChar(FileDefs2^,SizeOf(FileDefs2^),0);
     FillChar(FileDesc^,SizeOf(FileDesc^),0);
     FillChar(GFXBuffer^,SizeOf(GFXBuffer^),0);
     FillChar(HugePick^,SizeOf(HugePick^),0);
     FillChar(Locators^,SizeOf(Locators^),0);
     FillChar(MailerInfo^,SizeOf(MailerInfo^),0);
     FillChar(Menu^,SizeOf(Menu^),0);
     FillChar(MsgIndex^,SizeOf(MsgIndex^),0);
     FillChar(MsgText^,SizeOf(MsgText^),0);
     FillChar(NodeInfo^,SizeOf(NodeInfo^),0);
     FillChar(OnScreen^,SizeOf(OnScreen^),0);
     FillChar(PolyPoint^,SizeOf(PolyPoint^),0);
     FillChar(QWKTextBuffer^,SizeOf(QWKTextBuffer^),0);
     FillChar(TaggedFiles^,SizeOf(TaggedFiles^),0);
     FillChar(UserRecord2^,SizeOf(UserRecord2^),0);
     FillChar(WorkBuffer^,SizeOf(WorkBuffer^),0);
END;


PROCEDURE DisposeHeapVars;
BEGIN
     Dispose(Animate);
     Dispose(Buttons);
     Dispose(Callers);
     Dispose(Custom);
     Dispose(Fields);
     Dispose(FileDefs);
     Dispose(FileDefs2);
     Dispose(FileDesc);
     Dispose(GFXBuffer);
     Dispose(HugePick);
     Dispose(Locators);
     Dispose(MailerInfo);
     Dispose(Menu);
     Dispose(MsgIndex);
     Dispose(MsgText);
     Dispose(NodeInfo);
     Dispose(OnScreen);
     Dispose(PolyPoint);
     Dispose(QWKTextBuffer);
     Dispose(TaggedFiles);
     Dispose(UserRecord2);
     Dispose(WorkBuffer);
END;


END.
