program ExTimer;  {EXTIMER.PAS}
uses
  Crt, ApTimer;
var
  ET : EventTimer;
begin
  NewTimer(ET, Secs2Tics(60));
  WriteLn('Press any key to abort');
  repeat
    Write(^M'Elapsed ticks: ', ElapsedTime(ET),
          '    Remaining ticks: ', RemainingTime(ET));
  until KeyPressed or TimerExpired(ET);
  WriteLn;
  if not KeyPressed then
    WriteLn(^G, 'Timer expired')
  else
    WriteLn(^G, 'Aborted');
end.
