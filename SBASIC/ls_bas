1000 :
1010 REMark A 'ls' procedure to produce a directory listing similar to the Unix 'ls' command
1020 REMark Usage: ls <dirspec> where <dirspec> may be any device+wildcard specification
1030 REMark    or: lsr <dirspec> to list directories recursively
1040 REMark  e.g.: ls win1_, ls win1_DOCS_, lsr _doc etc.
1050 REMark Recognises TKII default data directory and hard subdirectories on V2 devices
1060 REMark Requirements: Native QL or emulator with TK2+Minerva, or SMSQ/E system
1070 REMark Bugs: Wildcard match is simple INSTR operation, may need improvement
1080 :
1090 REMark v1.0 Jan Bredenbeek, 29 January 2017. Licensed under GPL v3.
1100 REMark v1.1 JB 20170212: DEV device redirects are now handled, # lines adjusts to window size
1110 REMark      Now also compatible with native QL systems if TK2 and Minerva ROM present
1120 REMark      But see remarks in ls procedure on FNAME$ when using non-V2 device drivers!
1130 :
1140 REMark cdef_addr(#chan) returns address of channel definition block or -1 if invalid chan
1150 :
1160 DEFine FuNction cdef_addr(chan)
1170 LOCal chid%,cdef
1180   IF chan*40 >= PEEK_L(\\52)-PEEK_L(\\48) THEN RETurn -1
1190   chid%=PEEK_W(\48\chan*40+2):IF chid%<0 THEN RETurn -1
1200   cdef=PEEK_L(!120!chid%*4):IF cdef<=0 THEN RETurn -1
1210   IF PEEK_W(\48\chan*40)<>PEEK_W(cdef+16) THEN RETurn -1:REMark chan tag mismatch
1220   RETurn cdef
1230 END DEFine cdef_addr
1240 :
1250 REMark dev_name$(#chan) returns name of device where chan is attached to
1260 :
1270 DEFine FuNction dev_name$(chan)
1280 LOCal cdef,pdef,drvr,dname$,i
1290   cdef=cdef_addr(chan):IF cdef<=0 THEN RETurn ""
1300   IF PEEK_L(cdef)<>160 THEN RETurn "":REMark not a directory device
1310   dname$=""
1320   drvr=PEEK_L(cdef+4):FOR i=1 TO PEEK_W(drvr+36):dname$=dname$&CHR$(PEEK(drvr+37+i)):REMark dev name from driver def block
1330   pdef=PEEK_L(!!256+4*PEEK(cdef+29)):REMark physical definition block
1340   dname$=dname$&CHR$(48+PEEK(pdef+20)):REMark append drive number
1350   RETurn dname$
1360 END DEFine dev_name$
1370 :
1380 REMark winsize (#chan) returns number of text lines in window
1390 :
1400 DEFine FuNction winsize(chan)
1410 LOCal chdef,base,i,mc$,lines
1420   chdef=cdef_addr(chan):IF chdef<0 THEN RETurn -1
1430   base=ALCHP(32):IF base<=0 THEN RETurn -1
1440   mc$="0000000000000000204176FF43FAFFF2700B4E434E75":REMark SD.CHENQ
1450   FOR i=0 TO LEN(mc$)-2 STEP 2:POKE base+i DIV 2,HEX(mc$(i+1 TO i+2))
1460   CALL base+8,PEEK_L(\48\chan*40)
1470   lines=PEEK_W(base+2)
1480   RECHP base:RETurn lines
1490 END DEFine winsize
1500 :
1510 REMark smart_date$() returns either MMM DD YYYY or MMM DD hh:mm depending on how long ago
1520 :
1530 DEFine FuNction smart_date$(d)
1540 LOCal d$,y$,t$
1550   d$=DATE$(d):y$=d$(1 TO 4):t$=d$(13 TO 17):d$=d$(6 TO 12)
1560   IF DATE-d < 365*86400: RETurn d$&t$:ELSE RETurn d$&" "&y$
1570 END DEFine smart_date$
1580 :
1590 REMark Main procedure
1600 :
1610 DEFine PROCedure ls(d$,r$)
1620 LOCal ch,fnr,fl,ud,lh%,ll%,uh%,ul%,dev$,dir$,dn$,fnm$,wc$,t%,t$,i$,r,ls_lp,dir_printed
1630   wc$=PARSTR$(d$,1)
1640   ch=FOP_DIR(wc$):IF ch<0:REPORT#0;ch:RETurn
1650   REMark make dir$ hold full device+subdir
1660   dev$=dev_name$(#ch)&"_"
1670   :
1680   REMark FNAME$ gets subdir name from channel, but on non-V2 drivers gives "bad parameter"!
1690   REMark in this case, replace following line with 'dn$=""'!
1700   :
1710   dn$=FNAME$(#ch):IF dn$<>"":dn$=dn$&"_":REMark subdir name if hard subdir
1720   dir$=dev$&dn$
1730   REMark check for DEV device redirects (dev$ holds real device name)
1740   REMark NOTE: This fails if the DEV device has been renamed!
1750   IF LEN(wc$)>=5
1760     IF wc$(1 TO 3)=="DEV" AND wc$(4) INSTR "12345678" AND wc$(5)="_"
1770       t%=wc$(4):IF LEN(wc$)>5 THEN wc$=wc$(6 TO):ELSE wc$=""
1780       wc$=DEV_USE$(t%)&wc$
1790     END IF
1800   END IF
1810   REMark make wc$ canonical
1820   IF dn$ INSTR wc$ <> 1 AND dev$ INSTR wc$ <> 1:wc$=DATAD$&wc$
1830   IF dev$ INSTR wc$ <> 1:wc$=DATAD$&wc$
1840   REMark remainder of wc$ after dev+subdir is wildcard
1850   IF LEN(wc$)>LEN(dir$):wc$=wc$(LEN(dir$) TO):ELSE wc$=""
1860   IF wc$<>""
1870     IF wc$(1)="_" THEN IF LEN(wc$)>1:wc$=wc$(2 TO):ELSE wc$=""
1880   END IF
1890   IF PARSTR$(r$,2)<>"" THEN r=PARSTR$(r$,2):ELSE r=0:REMark recursive depth
1900   REMark for debugging: PRINT "dn=";dn$;" wc=";wc$;" r=";PARSTR$(r$,2)
1910   dir_printed=0
1920   fnr=-1:IF r<2 THEN lc=1:wh=winsize(#1)
1930   REPeat ls_lp
1940     fnr=fnr+1
1950     GET#ch\fnr*64:IF EOF(#ch):EXIT ls_lp
1960     GET#ch;lh%,ll%:fl=65536*(lh%+(ll%<0))+ll%:IF fl=0 THEN NEXT ls_lp:REMark empty dir entry
1970     fl=fl-64:REMark subtract header length
1980     GET#ch;t%:GET#ch\fnr*64+14;fnm$:REMark type,filename
1990     t%=t% && 255:REMark FIX: only test lower 8 bits of type
2000     GET#ch\fnr*64+52;uh%,ul%:ud=65536*(uh%+(ul%<0))+ul%:REMark update date(l)
2010     IF LEN(dn$)>0: fnm$=fnm$(LEN(dn$)+1 TO):REMark chop off directory name
2020     REMark filter on wildcard unless traversing directories recursively
2030     IF (NOT r OR t%<>255) AND wc$<>"" AND NOT wc$ INSTR fnm$: NEXT ls_lp
2040     SELect ON t%
2050       =0:t$=" ":REMark normal file
2060       =1:t$="E":REMark executable file
2070       =2:t$="R":REMark relocatable file
2080       =255:
2090         IF NOT r
2100           t$="D":fnm$=fnm$&" ->"
2110         ELSE
2120           ls dir$&fnm$&"_"&wc$,IDEC$(r+1,1,0)
2130           IF lc<0 THEN EXIT ls_lp:ELSE NEXT ls_lp
2140         END IF
2150       =REMAINDER :t$="?"
2160     END SELect
2170     lc=lc+1
2180     IF lc>=wh
2190       i$=INKEY$(-1):IF i$=="q" OR i$=CHR$(27) THEN lc=-lc:EXIT ls_lp
2200       lc=1
2210     END IF
2220     IF NOT dir_printed:PRINT dir$;":":lc=lc+1:dir_printed=1
2230     PRINT t$;IDEC$(fl,11,0);" ";smart_date$(ud);" ";fnm$
2240   END REPeat ls_lp
2250   CLOSE#ch
2260 END DEFine ls
2270 :
2280 REMark list directories recursively
2290 :
2300 DEFine PROCedure lsr(d$)
2310   ls PARSTR$(d$,1),"1"
2320 END DEFine lsr
2330 :
2340 REMark -- end of ls --
