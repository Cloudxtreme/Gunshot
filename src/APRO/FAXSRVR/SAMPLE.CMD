;** one CMD file for each fax request
;** currently only one possible section name [FaxSend]

[FaxSend]
;up to 20 full path and filenames to send as the fax
;multiple fax files are combined and sent as one (multi-page) fax
;prepend each path/filename with an "*" to indicate that it should
;be deleted after a successful send.
File1=
File2=
File3=
File4=
File5=

;the Station ID to use for this fax send (default is ID of FaxSrvr)
SenderID=260-7151 TPS

;the full path and file name of the cover page file (defaule is none)
;a "cover page only fax" can be sent by not specifing any file names
;above, and by specifying a cover page file name below.
CoverPage=

;usually the name of the sender (replaces $F in cover.txt}
;not used if a cover page is not specified (default is none)
Sender=

;usually the name of the recipient (replaces $R in cover.txt}
;not used if a cover page is not specified (default is none)
Recipient=

;true to print a header line at the top of the fax (default is "No")
UseHeaderLine=No

;text to place in the header line if selected (replaces the $S tag)
;used only if UseHeaderLine is true (default is none)
HeaderText=Attn: xxxxxxxxxxxxx

;baud rate used to send the fax (deafult is FaxBaudRate, this
;is set in the program ini file which defaults to 14400)
SendBaudRate=14400

;the complete phone number (no default)
Phone=260-7151

;date to attempt to send the fax -- (default is asap)
;format mm/dd/yy or mm/dd/yyyy (01/31/95 or 01/31/1995)
Date=

;time to send the fax -- (default is midnight)
;format hh:mm (24 hour format 14:00 for 2:00pm)
Time=
