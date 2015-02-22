Gunshot PRO
===========

32bit port of Shotgun BBS Professional version 2 alpha 10.<br />  
Shotgun BBS Professional is Copyright Brent Shellenberg<br />
Gunshot PRO is being ported by Rick Parrish<br />
<br />
The original FILE_ID.DIZ described it as:<br />
<br />
Shotgun BBS Professional version 2 alpha 10.<br />
Complete SVGA/ANSI/ASCII/RIP source of Shotgun Professional. <br />
Bring the touch of high quality Super-VGA to your online service or BBS. <br />
Everything is included that you would normally pay extra for:<br /> 
  * SQUISH/JAM/FIDO Support<br /> 
  * Front End Mailer Software<br /> 
  * TIC File Echo Processor<br /> 
  * Echomail processor<br /> 
  * Multiple Interface (SVGA/ANSI/TTY/RIP) <br />
  * Shotgun GUI Editor included!<br /> 
  * XModem/YModem/ZModem and much much more! <br />
Requires 540k of RAM, 1024k of EMS/XMS, SVGA monitor & mouse.<br />

<hr />

TODO List
=========

<ul>
  <li>IFDEF out anything that doesn't compile and make a placeholder that does a "WriteLn('REEPORT UNIT FUNCTION'); Halt;" (then you can grep the executables for REEPORT to see which REEPORTs actually need to be implemented)</li>
  <li>IFDEF out any ASM code blocks and handle the same as noncompiling code</li>
  <li>Implement any REEPORTs that appear in compiled executables</li>
  <li>Handle any REETODOs that need handling</li>
  <li>VP needed FindFirst to pass AnyFile instead of 0 -- is this an issue with FPC?</li>
  <li>Ensure all calls to FindFirst have a matching FindClose (memory leaks if FindClose is not called)</li>
  <li>Rename executables mentioned in code (ie SGECHO to GSECHO in a string in a code file)</li>
  <li>/ instead of \ for paths in Linux</li>
  <li>"Registers" usage</li>
  <li>"Port[]" usage</li>
  <li>APFOSSIL.PAS</li>
  <li>FASTW1.PAS</li>
  <li>BSMOUSE.PAS</li>
  <li>MKFILE.PAS (add routines from EleBBS)</li>
  <li>SHOTGUN -> GUNSHOT renames</li>
  <li>SG -> GS renames</li>
  <li>QWK mail packer menu not displaying correctly</li>
  <li>Not quitting after local login</li>
</ul>

Completed List
==============

<ul>
  <li>Make it all compile (or as much as possible) with BP</li>
</ul>

<hr />

Compiling
=========

Windows: Install the 32bit version of FreePascal (the 64bit version may work, but is untested at this time).  Execute src\build-win32.cmd<br />
NOTE: You'll likely need to adjust some paths in the .cmd file first<br />
<br />
Linux: Install FreePascal (the 64bit version may work, but is untested at this time).  Execute src\build-linux.sh<br />
NOTE: You'll likely need to adjust some paths in the .sh file first<br />
NOTE: On my test server, Ubuntu 13.10, I installed this: fp-compiler fp-units-fcl fp-units-gfx libc6-dev<br />