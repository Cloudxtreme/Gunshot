#
#                            APRO.MAK 2.03
#             Make file used to build Async Professional 2.03
#                        (non-OOP interface)
#
# This make file is designed to be used only with Borland's MAKE utility; it
# does NOT work with Microsoft's MAKE. To use this file, enter
#
#     MAKE -fAPRO.MAK
#
# at the DOS command line.
#
# --------------------------------------------------------------------- Defines

# Set this to 1 for Turbo Assembler, or comment it out for Microsoft Assembler.
tasm=1

# Set this (in addition to the above) to use TASM 2.0 or later
tasm2=1

# Uncomment the following line if you have an assembler.
HaveAssembler=1

# Uncomment the next line to build protected mode units and demos
# pmode=1

# Uncommenting the next line forces the creation of the protected
# mode DLLs. However you must first set the appropriate defines in
# APDEFINE.INC (UsePModeDLL on, UseOOP, UseOPRO and UseTPRO off).
# MakeDLL=1

# ------------------------------------------------------------------- Macros
# If your assembler or compiler is not located in a directory on the DOS path,
# or if you are running under DOS 2.x, insert the complete pathname of the
# relevant executable file in the following definitions. For example, if
# your copy of BPC.EXE is located in the directory C:\BP\BIN then you would
# change the following line to
#
#     compile=C:\BP\BIN\BPC.EXE /M /$D- /$L- /L
#
# You may also want to change the default compilation directives by adding them
# at the end of command line.

!if $d(tasm)
assemble=TASM.EXE
!else
assemble=MASM.EXE
!endif

!if $d(tasm2)
mpass=/m2
!else
mpass=
!endif

# You may wish to modify these command line options or compiler names.
# Note that if you switch BPC to TPC you must remove the /CD option below.
!if $d(pmode)
compile=BPC.EXE /CP /M /$D- /$L- /L
!else
compile=BPC.EXE /CD /M /$D- /$L- /L
!endif

# Specify the path of the utility used to convert a binary file into an
# OBJ file suitable for linking. This is used only for APFAX.FNT here.

binobj=BINOBJ.EXE

# ---------------------------------------- Force evaluation of all dependencies

!if $d(pmode)
!if $d(MakeDLL)
dummy: allobj alltpp alldemo alldll
!else
dummy: allobj alltpp alldemo
!endif
!else
dummy: allobj alltpu alldemo
!endif

allobj: apuart1.obj apuart2.obj apuart3.obj apuart4.obj apuart5.obj \
        apuart6.obj apuart7.obj apuart9.obj aplzh.obj \
        fastw1.obj aplha.obj apfax.obj

!if $d(pmode)
alldll: apcomd.dll approtd.dll apfaxd.dll apzipd.dll aplzhd.dll

alltpp: apmisc.tpp apport.tpp apuart.tpp apint14.tpp apcom.tpp \
        apmodem.tpp apabspcl.tpp apxmodem.tpp apymodem.tpp \
        apzmodem.tpp apkermit.tpp apascii.tpp \
        aptimer.tpp aparchiv.tpp aplzh.tpp apmisc.tpp apzip.tpp \
        apcour.tpp apmcom.tpp apansi.tpp \
        aptfdd.tpp apdigi14.tpp apfossil.tpp \
        apfaxcvt.tpp apabsfax.tpp apfax12.tpp apfaxcas.tpp apfaxprn.tpp \
        apini.tpp apinidb.tpp apmoddb.tpp apmodem2.tpp

!else
alltpu: apmisc.tpu apport.tpu apuart.tpu apint14.tpu apcom.tpu \
        apmodem.tpu apabspcl.tpu apxmodem.tpu apymodem.tpu \
        apzmodem.tpu apkermit.tpu apascii.tpu \
        aptimer.tpu aparchiv.tpu aplzh.tpu apmisc.tpu apzip.tpu \
        apcour.tpu apmcom.tpu apansi.tpu \
        aptfdd.tpu apdigi14.tpu apfossil.tpu \
        apfaxcvt.tpu apabsfax.tpu apfax12.tpu apfaxcas.tpu apfaxprn.tpu \
        apini.tpu apinidb.tpu apmoddb.tpu apmodem2.tpu

!endif

# Note: comtest.exe is not in the following list so that the supplied
#       version won't be overwritten during a make. Add it back to the
#       list and uncomment its rule near the end of this file if you
#       want to make it.

alldemo: fx.exe uartid.exe \
         lzhv.exe lzhx.exe lzh.exe \
         zipv.exe zipx.exe zip.exe \
         simprcv.exe simpsnd.exe \
         cvt2fax.exe prnfax.exe \
         showfax.exe fax2pcx.exe

# -------------------------------------------------------------- Implicit rules

!if $d(HaveAssembler)
.asm.obj:
  $(assemble) $.;
!endif

.pas.exe:
  $(compile) $*

.pas.tpp:
  $(compile) $*

.pas.tpu:
  $(compile) $*

.pad.dll:
  $(compile) $<

# ---------------------------------------------------- Assembly Language Source

!if $d(HaveAssembler)

apuart1.obj : apuart.asm apconfig.1
  copy apconfig.1 apconfig.asm
  $(assemble) $(mpass) apuart.asm, apuart1.obj ;

apuart2.obj : apuart.asm apconfig.2
  copy apconfig.2 apconfig.asm
  $(assemble) $(mpass) apuart.asm, apuart2.obj ;

apuart3.obj : apuart.asm apconfig.3
  copy apconfig.3 apconfig.asm
  $(assemble) $(mpass) apuart.asm, apuart3.obj ;

apuart4.obj : apuart.asm apconfig.4
  copy apconfig.4 apconfig.asm
  $(assemble) $(mpass) apuart.asm, apuart4.obj ;

apuart5.obj : apuart.asm apconfig.5
  copy apconfig.5 apconfig.asm
  $(assemble) $(mpass) apuart.asm, apuart5.obj ;

apuart6.obj : apuart.asm apconfig.6
  copy apconfig.6 apconfig.asm
  $(assemble) $(mpass) apuart.asm, apuart6.obj ;

apuart7.obj : apuart.asm apconfig.7
  copy apconfig.7 apconfig.asm
  $(assemble) $(mpass) apuart.asm, apuart7.obj ;

apuart9.obj : apuart.asm apconfig.9
  copy apconfig.9 apconfig.asm
  $(assemble) $(mpass) apuart.asm, apuart9.obj ;

fastw1.obj: fastw1.asm

aplzh.obj: aplzh.asm

aplha.obj: aplha.asm

apfax.obj: apfax.fnt
  $(binobj) apfax.fnt apfax.obj BoundFont

!endif

# ---------------------------------------------------- Library Units

!if $d(pmode)
apmisc.tpp: apmisc.pas apmisc.pa0 apmisc.pa1 apdefine.inc

aptimer.tpp: aptimer.pas aptimer.pa0 apdefine.inc

apport.tpp: apport.pas apport.pa0 apmisc.tpp apdefine.inc

apuart.tpp: apuart.pas apuart.pa0 apuart1.obj apuart2.obj apuart3.obj \
            apuart4.obj apuart5.obj apuart6.obj apuart7.obj apuart9.obj \
            apdefine.inc apmisc.tpp apport.tpp

apint14.tpp: apint14.pas apint14.pa0 apdefine.inc apmisc.tpp apport.tpp

apfossil.tpp: apfossil.pas apfossil.pa0 apdefine.inc apmisc.tpp apport.tpp

apdigi14.tpp: apdigi14.pas apdigi14.pa0 apdefine.inc apmisc.tpp apport.tpp

apansi.tpp: apansi.pas apmisc.tpp apport.tpp

apcom.tpp: apcom.pas apcom.pa0 apcom.pa1 apcom.pa2 apdefine.inc \
           apmisc.tpp apport.tpp aptimer.tpp

apabspcl.tpp: apabspcl.pas apabspcl.pa0 apdefine.inc apport.tpp \
              apmisc.tpp aptimer.tpp apcom.tpp

apxmodem.tpp: apxmodem.pas apxmodem.pa0 apdefine.inc apport.tpp \
              apmisc.tpp aptimer.tpp apcom.tpp apabspcl.tpp

apymodem.tpp: apymodem.pas apymodem.pa0 apdefine.inc apport.tpp \
              apmisc.tpp aptimer.tpp apcom.tpp apabspcl.tpp apxmodem.tpp

apzmodem.tpp: apzmodem.pas apzmodem.pa0 apzmodem.pa1 apzmodem.pa2 \
              apdefine.inc apport.tpp apmisc.tpp \
              aptimer.tpp apcom.tpp apabspcl.tpp

apkermit.tpp: apkermit.pas apkermit.pa0 apkermit.pa1 apkermit.pa2 \
              apdefine.inc apport.tpp apmisc.tpp \
              aptimer.tpp apcom.tpp apabspcl.tpp

apascii.tpp: apascii.pas apascii.pa0 apdefine.inc apport.tpp \
             apmisc.tpp aptimer.tpp apcom.tpp apabspcl.tpp

apmodem.tpp: apmodem.pas apdefine.inc apport.tpp apmisc.tpp \
             aptimer.tpp apcom.tpp

apcour.tpp: apcour.pas apdefine.inc apmisc.tpp apport.tpp apmodem.tpp

apmcom.tpp: apmcom.pas apdefine.inc apmisc.tpp apport.tpp apmodem.tpp

aparchiv.tpp: aparchiv.pas apdefine.inc aparchiv.pa0 apmisc.tpp

aplzh.tpp: aplzh.pas apdefine.inc aplzh.pa0 aplzh.pa1 aplzh.pa2 \
           aplzh.pa3 aplzh.obj aplha.obj \
           apmisc.tpp aparchiv.tpp

apzip.tpp: apzip.pas apdefine.inc apzip.pa0 apzip.pa1 apzip.pa2 \
           apzip.pa3 apzip.pa4 apmisc.tpp aparchiv.tpp

aptfdd.tpp: aptfdd.pas apdefine.inc apmisc.tpp apport.tpp apcom.tpp

apfaxcvt.tpp: apfaxcvt.pas apdefine.inc apfaxcvt.pa0 apmisc.tpp

apabsfax.tpp: apabsfax.pas apdefine.inc apabsfax.pa0 \
              apmisc.tpp aptimer.tpp apport.tpp apcom.tpp apfaxcvt.tpp

apfax12.tpp: apfax12.pas apdefine.inc apfax12.pa0 \
             apmisc.tpp apport.tpp aptimer.tpp apcom.tpp \
             apfaxcvt.tpp apabsfax.tpp

apfaxprn.tpp: apfaxprn.pas apdefine.inc apmisc.tpp \
              apfaxcvt.tpp

apini.tpp: apini.pas apini.pa0 apmisc.tpp

apinidb.tpp: apinidb.pas apinidb.pa0 apmisc.tpp \
             apport.tpp apini.tpp

apmoddb.tpp: apmoddb.pas apmoddb.pa0 apmisc.tpp \
             apport.tpp apinidb.tpp

apmodem2.tpp: apmodem2.pas apmodem2.pa0 apmisc.tpp \
              apport.tpp aptimer.tpp apcom.tpp \
              apmoddb.tpp

!else
apmisc.tpu: apmisc.pas apmisc.pa0 apmisc.pa1 apdefine.inc

aptimer.tpu: aptimer.pas aptimer.pa0 apdefine.inc

apport.tpu: apport.pas apport.pa0 apmisc.tpu apdefine.inc

apuart.tpu: apuart.pas apuart.pa0 apuart1.obj apuart2.obj apuart3.obj \
            apuart4.obj apuart5.obj apuart6.obj apuart7.obj apuart9.obj \
            apdefine.inc apmisc.tpu apport.tpu

apint14.tpu: apint14.pas apint14.pa0 apdefine.inc apmisc.tpu apport.tpu

apfossil.tpu: apfossil.pas apfossil.pa0 apdefine.inc apmisc.tpu apport.tpu

apdigi14.tpu: apdigi14.pas apdigi14.pa0 apdefine.inc apmisc.tpu apport.tpu

apansi.tpu: apansi.pas apmisc.tpu apport.tpu

apcom.tpu: apcom.pas apcom.pa0 apcom.pa1 apcom.pa2 apdefine.inc \
           apmisc.tpu apport.tpu aptimer.tpu

apabspcl.tpu: apabspcl.pas apabspcl.pa0 apdefine.inc apport.tpu \
              apmisc.tpu aptimer.tpu apcom.tpu

apxmodem.tpu: apxmodem.pas apxmodem.pa0 apdefine.inc apport.tpu \
              apmisc.tpu aptimer.tpu apcom.tpu apabspcl.tpu

apymodem.tpu: apymodem.pas apymodem.pa0 apdefine.inc apport.tpu \
              apmisc.tpu aptimer.tpu apcom.tpu apabspcl.tpu apxmodem.tpu

apzmodem.tpu: apzmodem.pas apzmodem.pa0 apzmodem.pa1 apzmodem.pa2 \
              apdefine.inc apport.tpu apmisc.tpu \
              aptimer.tpu apcom.tpu apabspcl.tpu

apkermit.tpu: apkermit.pas apkermit.pa0 apkermit.pa1 apkermit.pa2 \
              apdefine.inc apport.tpu apmisc.tpu \
              aptimer.tpu apcom.tpu apabspcl.tpu

apascii.tpu: apascii.pas apascii.pa0 apdefine.inc apport.tpu \
             apmisc.tpu aptimer.tpu apcom.tpu apabspcl.tpu

apmodem.tpu: apmodem.pas apdefine.inc apport.tpu apmisc.tpu \
             aptimer.tpu apcom.tpu

apcour.tpu: apcour.pas apdefine.inc apmisc.tpu apport.tpu apmodem.tpu

apmcom.tpu: apmcom.pas apdefine.inc apmisc.tpu apport.tpu apmodem.tpu

aparchiv.tpu: aparchiv.pas apdefine.inc aparchiv.pa0 apmisc.tpu

aplzh.tpu: aplzh.pas apdefine.inc aplzh.pa0 aplzh.pa1 aplzh.pa2 \
           aplzh.pa3 aplzh.obj \
           apmisc.tpu aparchiv.tpu

apzip.tpu: apzip.pas apdefine.inc apzip.pa0 apzip.pa1 apzip.pa2 apzip.pa3 \
           apmisc.tpu aparchiv.tpu

aptfdd.tpu: aptfdd.pas apdefine.inc apmisc.tpu apport.tpu apcom.tpu

apfaxcvt.tpu: apfaxcvt.pas apdefine.inc apfaxcvt.pa0 apmisc.tpu

apabsfax.tpu: apabsfax.pas apdefine.inc apabsfax.pa0 \
              apmisc.tpu aptimer.tpu apport.tpu apcom.tpu apfaxcvt.tpu

apfax12.tpu: apfax12.pas apdefine.inc apfax12.pa0 \
             apmisc.tpu apport.tpu aptimer.tpu apcom.tpu \
             apfaxcvt.tpu apabsfax.tpu

apfaxprn.tpu: apfaxprn.pas apdefine.inc apmisc.tpu \
              apfaxcvt.tpu

apini.tpu: apini.pas apini.pa0 apmisc.tpu

apinidb.tpu: apinidb.pas apinidb.pa0 apmisc.tpu \
             apport.tpu apini.tpu

apmoddb.tpu: apmoddb.pas apmoddb.pa0 apmisc.tpu \
             apport.tpu apinidb.tpu

apmodem2.tpu: apmodem2.pas apmodem2.pa0 apmisc.tpu \
              apport.tpu aptimer.tpu apcom.tpu \
              apmoddb.tpu

!endif

# ---------------------------------------------------- DLLs

!if $d(MakeDLL)
apcomd.dll: apdefine.inc apport.tpp apmisc.tpp aptimer.tpp \
            apuart.tpp apint14.tpp apfossil.tpp apdigi14.tpp \
            apcom.tpp apcomd.pad

apcomd.tpp: apcomd.dll apdefine.inc apcomd.pas \
            apmisc.pa0 apport.pa0 aptimer.pa0 apuart.pa0 \
            apfossil.pa0 apdigi14.pa0 apint14.pa0 apcom.pa0

approtd.dll: apdefine.inc apabspcl.tpp apxmodem.tpp \
             apymodem.tpp apzmodem.tpp apkermit.tpp \
             apascii.tpp apbplus.tpp \
             approtd.pad

approtd.tpp: approtd.dll apdefine.inc approtd.pas apcomd.tpp \
             apabspcl.pa0 apxmodem.pa0 apymodem.pa0 apzmodem.pa0 \
             apkermit.pa0 apascii.pa0 apbplus.pa0

apzipd.dll: apdefine.inc apmisc.tpp aparchiv.tpp apzip.tpp apzipd.pad

aplzhd.dll: apdefine.inc apmisc.tpp aparchiv.tpp aplzh.tpp aplzhd.pad

apzipd.tpp: apzipd.dll apdefine.inc apzipd.pas \
            apmisc.pa0 aparchiv.pa0 apzip.pa0

aplzhd.tpp: aplzhd.dll apdefine.inc aplzhd.pas \
            apmisc.pa0 aparchiv.pa0 aplzh.pa0

apfaxd.dll: apdefine.inc apfaxcvt.tpp apabsfax.tpp apfax12.tpp \
            apfaxcas.tpp apfaxd.pad

apfaxd.tpp: apfaxd.dll apdefine.inc apfaxd.pas apcomd.tpp \
            apfaxcvt.pa0 apabsfax.pa0 apfax12.pa0 apfaxcas.pa0
!endif

# ---------------------------------------------------- Demo Programs

!if $d(pmode)
# comtest is commented out here so that the make
# won't overwrite the supplied comtest.exe
#
#comtest.exe: apport.tpp apuart.tpp apint14.tpp apuart1.obj \
#             apuart2.obj apuart3.obj apuart4.obj apuart5.obj \
#             apuart6.obj apuart7.obj apuart9.obj \
#             apmisc.tpp aptimer.tpp apdefine.inc apcom.tpp \
#             comtest.pas

fx.exe: apuart1.obj apuart2.obj apuart3.obj apuart4.obj \
        apuart5.obj apuart6.obj apuart7.obj apuart9.obj \
        apport.tpp apuart.tpp apmisc.tpp aptimer.tpp apcom.tpp apabspcl.tpp \
        apxmodem.tpp apymodem.tpp apzmodem.tpp apkermit.tpp apbplus.tpp \
        apdefine.inc fx.pas

uartid.exe: apport.tpp apdefine.inc apuart.tpp uartid.pas

lzhv.exe: lzhv.pas apdefine.inc apmisc.tpp aparchiv.tpp aplzh.tpp

lzhx.exe: lzhx.pas apdefine.inc apmisc.tpp aparchiv.tpp aplzh.tpp

lzh.exe:  lzh.pas apdefine.inc apmisc.tpp aparchiv.tpp aplzh.tpp

zipv.exe: zipv.pas apdefine.inc apmisc.tpp aparchiv.tpp apzip.tpp

zipx.exe: zipx.pas apdefine.inc apmisc.tpp aparchiv.tpp apzip.tpp

zip.exe:  zip.pas apdefine.inc apmisc.tpp aparchiv.tpp apzip.tpp

simpsnd.exe: simpsnd.pas apdefine.inc apmisc.tpp \
             aptimer.tpp apport.tpp apuart.tpp \
             apcom.tpp apfaxcvt.tpp apabsfax.tpp \
             apfax12.tpp apfaxcas.tpp

simprcv.exe: simprcv.pas apdefine.inc apmisc.tpp \
             apport.tpp apuart.tpp \
             apcom.tpp apfaxcvt.tpp apabsfax.tpp \
             apfax12.tpp apfaxcas.tpp

cvt2fax.exe: cvt2fax.pas apdefine.inc apmisc.tpp \
             apfaxcvt.tpp

showfax.exe: showfax.pas apdefine.inc apfaxcvt.tpp

prnfax.exe: prnfax.pas apdefine.inc apmisc.tpp apfaxcvt.tpp apfaxprn.tpp

fax2pcx.exe: fax2pcx.pas apdefine.inc apfaxcvt.tpp

!else

# comtest is commented out here so that the make
# won't overwrite the supplied comtest.exe
#
#comtest.exe: apport.tpu apuart.tpu apint14.tpu apuart1.obj \
#             apuart2.obj apuart3.obj apuart4.obj apuart5.obj \
#             apuart6.obj apuart7.obj apuart9.obj \
#             apmisc.tpu aptimer.tpu apdefine.inc apcom.tpu \
#             comtest.pas
#

fx.exe: apuart1.obj apuart2.obj apuart3.obj apuart4.obj \
        apuart5.obj apuart6.obj apuart7.obj apuart9.obj \
        apport.tpu apuart.tpu apmisc.tpu aptimer.tpu apcom.tpu apabspcl.tpu \
        apxmodem.tpu apymodem.tpu apzmodem.tpu apkermit.tpu apbplus.tpu \
        apdefine.inc fx.pas

uartid.exe: apport.tpu apdefine.inc apuart.tpu uartid.pas

lzhv.exe: lzhv.pas apdefine.inc apmisc.tpu aparchiv.tpu aplzh.tpu

lzhx.exe: lzhx.pas apdefine.inc apmisc.tpu aparchiv.tpu aplzh.tpu

lzh.exe:  lzh.pas apdefine.inc apmisc.tpu aparchiv.tpu aplzh.tpu

zipv.exe: zipv.pas apdefine.inc apmisc.tpu aparchiv.tpu apzip.tpu

zipx.exe: zipx.pas apdefine.inc apmisc.tpu aparchiv.tpu apzip.tpu

zip.exe:  zip.pas apdefine.inc apmisc.tpu aparchiv.tpu apzip.tpu

simpsnd.exe: simpsnd.pas apdefine.inc apmisc.tpu \
             aptimer.tpu apport.tpu apuart.tpu \
             apcom.tpu apfaxcvt.tpu apabsfax.tpu \
             apfax12.tpu apfaxcas.tpu

simprcv.exe: simprcv.pas apdefine.inc apmisc.tpu \
             apport.tpu apuart.tpu \
             apcom.tpu apfaxcvt.tpu apabsfax.tpu \
             apfax12.tpu apfaxcas.tpu

cvt2fax.exe: cvt2fax.pas apdefine.inc apmisc.tpu \
             apfaxcvt.tpu

showfax.exe: showfax.pas apdefine.inc apfaxcvt.tpu

prnfax.exe: prnfax.pas apdefine.inc apmisc.tpu apfaxcvt.tpu apfaxprn.tpu

fax2pcx.exe: fax2pcx.pas apdefine.inc apfaxcvt.tpu

!endif
