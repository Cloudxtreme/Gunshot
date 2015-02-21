UNIT Need_386;


INTERFACE


{$R-,S-,I-,Q-,O-,F-,G-,A+}


IMPLEMENTATION


BEGIN
     IF Test8086<2 THEN
     BEGIN
          Writeln('This software requires a 386 cpu or higher.');
          Halt($FC);
     END;
END.
