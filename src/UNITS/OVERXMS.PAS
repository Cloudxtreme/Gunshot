Unit OverXMS;

{$O-}

Interface


uses Overlay;


Const ovrNoXMSDriver = -7;
      ovrNoXMSMemory = -8;


Procedure OvrInitXMS;


Implementation


Procedure OvrInitXMS; External;
{$L OVERXMS.OBJ }

end.
