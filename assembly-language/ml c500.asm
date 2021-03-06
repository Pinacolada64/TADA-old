{asm}
orig $c500 ; 50432
; c64list4_03.exe "ml c500.asm" -prg -sym:"ml c500.sym" -ovr
; \scripts\build-ml-c500.bat takes care of this

; tabs are 8 spaces

; 06/09/2007 "crflag" addition

; 02/26/2011 added more labels

; 02/28/2011 added compile date string

; 07/12/2011 added bracket reader, popstack

; 04/16/2014 reassemble at $c200, for compatability with agentfriday's
;		modbasic at $c000

; 05/19/2014 add more labels & comments, swap date & comment columns,
;		removed extraneous spaces

; 12/30/2014	* reassemble at $c500 for v1.01 of agentfriday's modbasic
;		* inputany now accepts variables in sys parameter
;			(was issuing ?syntax error if params were not strictly numeric)
;		* "comnum" routine incorporates checking for comma
;			as next byte, returns numeric param in .x

; 04/3/2015:
;	* now prints assembly date

; 11/22/2016:
;	* added "chrout" label

; 05/08/2017:
;	* use common buffer for Input Any & Sliding Input @ $cd00
;	* assemble for casm4 beta

; 08/25/2017:
;	* added error-trapping routine, exported symbols for use by
;		"boot" and "t.main"

	; zero-page:

index	= $22	; Miscellaneous Temporary Pointers and Save Area ($22-$25)
vartab	= $2d	; start of basic variables
FRESPC	= $35	; $35/$36: Temporary Pointer for Strings
curlin	= $39	; $39/$3a: Current BASIC line number being executed
varname = $45	; $45/$46: variable name for string assignment
VARPNT	= $47	; temporary pointer for reading variable
chrget	= $0073 ; force c64list to jsr to zp addr
fnaddr	= $bb	; current filename ptr
main	= $fb	; string search ptr
key	= $fd	; substring search ptr

	; error-trap stuff:

BUF	= $0200 ; BASIC Line Editor Input Buffer ($200-$258)
ierror	= $0300 ; Vector to the Print BASIC Error Message Routine

	; basic interpreter routines:

strout	= $ab1e ; load .a/.y: address of zero-terminated string to output
require_string	= $ad8f ; ensure param is a string variable
frmeval = $ad9e ; evaluate string/math expressions
chkcom	= $aefd ; check basic text for comma, return ?syntax error
		; if not found
get_var = $b08b ; read variable name from basic text, return address
		; of byte following variable name in .a/.y.
		; returns variable name in (varname)
makdes	= $b0e7 ; set up descriptor stored in (varname)
		; returns address in (varpnt)
ALLOC_STRING	= $B4F4 ; Allocates space on string heap; pass length in .A;
			; address returned in .X/.Y and $35
movstr	= $b688 ; copy string to pool, from ($22) to ($35)
frestr	= $b6a6 ; returns .a: len, $22/$23: addr
comnum	= $b7f1 ; checks for a comma (jsr chkcom), evaluates numeric
		; expression (returns type mismatch if string var),
		; returns .x: 0-255, returns ?illegal quantity error
		; if param is out of range

inbuf	= $cd00 ; common input buffer shared among Input Any & Sliding Input

	; kernal routines:

error	= $e38b	; standard BASIC error entry point
setlfs	= $ffba ; set logical, file #, secondary addrs
setnam	= $ffbd ; set filename
chkin	= $ffc6 ; change input device
chrout	= $ffd2 ; output char in .a
load	= $ffd5 ; load memory
clrchn	= $ffcc ; restore default i/o devices
chrin	= $ffcf ; input a character

		jmp instring		; 50432
		jmp inputany		; 50435
		jmp module64		; 50438
		jmp bracketxt		; 50441
		jmp popstack		; 50444
;		jmp err_trap_install	; 50447

	; print assembly date:
asm_date:
		lda #<t_asm_date	; 50447
		ldy #>t_asm_date
		jmp strout

t_asm_date:
		ascii 08/25/2017
		byte $0d ; cr
		byte $00 ; null terminator

	; variables:

main_length:
	byte $ff	; length of string to search through
key_length:
	byte $ff	; length of string to search for

	; subroutines:

chkparam:
	jsr chkcom
	jsr frmeval
	jmp frestr
	; returns 256*y+x=string addr, .a=length

instring:
	jsr chkparam
	sta main_length
	sty main+1
	stx main

	jsr chkparam
	sta key_length
	sty key+1
	stx key

	; thanks to nikoniko and bob cederlof for this instring routine.
	; syntax: sys is,"search_thru","search_for"
	; (both params can be variables or literals thanks to frmeval)
	; returns result in i% (which must be set up in basic first)
	; i%=0 for no match / search_thru > search_for

s1:
	ldx #0

s2:
	lda main_length
	cmp key_length	; substring > amt of remaining string to search?
	bcc s8		; yes, exit

	ldy #0
s3:
	lda (key),y
	cmp (main),y
	bne s6
	iny
	cpy key_length
	bcc s3
	inx
	jmp store
s6:
	inc main
	bne s7
	inc main+1
s7:
	inx
	dec main_length
	bne s2
s8:
	ldx #0

store:
	stx $fb ; store length in $fb (251)

; thanks to jim radiks & steve bell for this routine:

intvar:
	lda vartab
	sta fnaddr
	lda vartab+1
	sta fnaddr+1

str1:
	ldy #$00
	lda (fnaddr),y
	cmp #$c9 ; i + bit 7 set=integer
	bne str2
	iny
	lda (fnaddr),y
	cmp #$80 ;	bit 7 set=integer
	beq str3

str2:
	clc
	lda fnaddr
	adc #$07
	sta fnaddr
	lda fnaddr+1
	adc #$00
	sta fnaddr+1
	jmp str1

str3:
	iny
	lda #$00	; hi byte=0
	sta (fnaddr),y
	iny
	lda $fb		; lo byte=$fb
	sta (fnaddr),y

done:
	rts

	; thanks to jim butterfield + dave moorman for this routine.
	; gets data from disk files which can ordinarily cause input#x in basic
	; to choke (commas, colons).

	; syntax:
	; sys ia,<channel_number>,<number_of_bytes>,<skip_cr>,<string_variable>

	; new (12/31/2014): params can be literals or numeric variables
	; thanks to 'jsr comnum' doing evaluation

inputany:
; get comma followed by 'channel' param:
	jsr comnum	; returns in .x
	stx channel

; get comma followed by 'bytes' param:
	jsr comnum
	stx bytes

; pinacolada's addition: crflag param to ignore carriage returns in data.
; 1=stop at carriage return 0=add cr to data read (binary mode)
	jsr comnum
	stx crflag

; 8/May/2017 23:29 - apparently lost string param changes :(
; get comma and string name to place received data into

; code from a copy i sent to robert eaglestone:
; c59f 20 f1 b7 jsr $b7f1 ; comnum - channel #
; c5a2 8e 24 c6 stx $c624
; c5a5 20 f1 b7 jsr $b7f1 ; comnum - #_bytes
; c5a8 8e 26 c6 stx $c626
; c5ab 20 f1 b7 jsr $b7f1 ; comnum - crflag
; c5ae 8e 27 c6 stx $c627
; c5b1 20 fd ae jsr $aefd ; chkcom - string name
; c5b4 20 8b b0 jsr $b08b ; get_var
; c5b7 20 8f ad jsr $ad8f ; require_string
; c5ba 20 e7 b0 jsr $b0e7 ; makdes

	jsr chkcom
	jsr get_var
; put variable name in descriptor:
	sta str_name
	sty str_name+1

	jsr require_string
	jsr makdes

; we now return you to your regularly scheduled programming:

	lda #$00
	sta $fb
	ldx channel

	jsr chkin
	ldx #$00
	ldy #$00
m0362:
	jsr chrin
	sta work2
	ldy $fb
	sta inbuf,y
	inc $fb

; here comes crflag stuff

	lda crflag
	beq m037b ; add cr to data

; continuing on...

	lda work2
	cmp #$0d
	bne m037b
	dec $fb
	jmp m0382
m037b:
; #_of_bytes:
	lda $fb
	cmp bytes
	bne m0362
m0382:
; put received data in string variable:

; this old code puts data in 1st variable defined:
;	ldy #$02
;	lda $fb
;	sta (vartab),y
;	iny
;	lda #<inbuf
;	sta (vartab),y
;	iny
;	lda #>inbuf
;	sta (vartab),y

; new code (6/19/2017):
; [00]: un-needed $00
;	inc $d021
	lda $fb		; c5f0 a5 fb
	jsr ALLOC_STRING; c5f2 20 f4 b4

; move string from ($22, index) to ($35, frespc):
	ldx #<str_name	; c5f5 ae 0f[00]
	stx index	; c5f8 86 22
	ldy #>str_name	; c5fa ac c7[00]
	sty index+1	; c5fd 84 23
	lda bytes	; c5ff ad 0a c7
	ldx #<inbuf	; c602 ae 0f[00]
	stx frespc	; c605 86 35
	ldy #>inbuf	; c607 ac c7[00]
	sty frespc+1	; c60a 84 36
	jsr movstr	; c60c 20 88 b6

; set up string address:
	ldy #$00	; c60f a0 00
	lda $fb		; c611 a5 fb
	sta (varpnt),y	; c613 91 47
	lda str_addr	; c615 ad 0b c7
	iny		; c618 c8
	sta (varpnt),y	; c619 91 47
	lda str_addr+1	; c61b ad 0c c7
	iny		; c61e c8
	sta (varpnt),y	; c61f 91 47

; restore I/O and return to BASIC:
	jmp clrchn

channel:
	byte 0
work2:
	byte 0
bytes:
	byte 0
crflag:
	byte 0

	; module64
	; thanks to michael j. gibbons for this routine

module64:
	lda #$03
	sta c083
	lda #$e8
	sta c082
	jsr c054
	lda $fb
	sta c084
	lda $fc
	sta c085
	jsr chkcom
	lda #$01
	ldx $ba ; current device
	tay
	jsr setlfs
	jsr frmeval
	lda #$0d
	bne c02e
	ldx #$16  ; type mismatch
	jmp $a437 ; display basic error
c02e:
	jsr frestr
	jsr setnam
	lda #$00
	jsr load
	lda #$03
	sta c083
	lda #$e7
	sta c082
	jsr c054
	lda c084
	ldy #$00
	sta ($fb),y
	lda c085
	iny
	sta ($fb),y
	rts
c054:
	lda #$08
	sta $fc
	lda #$01
	sta $fb
c05c:
	ldy #$02
	lda ($fb),y
	cmp c082
	bne c06e
	iny
	lda ($fb),y
	cmp c083
	bne c06e
	rts
c06e:
	ldy #$00
	lda ($fb),y
	pha
	iny
	lda ($fb),y
	sta $fc
	pla
	sta $fb
	lda $fc
	cmp #$00
	bne c05c
	rts
c082:
	byte 0
c083:
	byte 0
c084:
	byte 0
c085:
	byte 0

	; bracketxt - 7/12/2011
	; most code by anders carlsson
	; i added bracket coloring

	; main: zero-page pointer holds address of string
bracketxt:
	; get address of string to print:
	jsr chkparam

	stx main
	sty main+1
	tya

	php
	ldy #0
	lda lastcol
	sta 646

writetext2:
	lda (main),y
	cmp #0
	beq stringend ; 0=string end
	cmp #'['
	bne spec2
	lda hilite
setcol:
	sta lastcol
setcol2:
	sta 646
	jmp nextchar

spec2:
	cmp #']'
	bne print
	lda normal
	jmp setcol

print:
	jsr chrout
nextchar:
	iny
	bne writetext2
	inc main+1
	jmp writetext2
stringend:
	plp
	sta main+1
	rts

normal:
	byte 15
hilite:
	byte 1
lastcol:
	byte 15

	; gets rid of last return target
	; on stack (from ahoy! magazine)

popstack:
	pla
	pla
	lda #$ff
	sta $4a		; FORPNT+1
	jsr $a38a	; find 'FOR' on stack
	txs
	cmp #$8d	; GOSUB token
	beq pop2
	jmp $a8e0
pop2:
	pla
	pla
	pla
	pla
	pla
	rts

err_trap_install:
; original code, relocated and reorganized
sei
lda #<err_trap	; 036b	A9 3C
sta ierror	; 036d	8D 00 03	; point IERROR to err_trap
lda #>err_trap	; 0370	A9 03
sta ierror+1	; 0372	8D 01 03
cli
rts		; 0375	60

err_trap_uninstall:
sei
lda #<error	; 033c	A9 8B		; restore standard ierror address
sta ierror	; 033e	8D 00 03	; of $e38b
lda #>error	; 0341	A9 E3
sta ierror+1	; 0343	8D 01 03
cli
jmp (ierror)				; jump to now-standard error vector

err_trap:
cpx #$30				; error code?
bcc err_trap_entry			; yes, continue
jmp err_trap_standard

err_trap_entry:
lda curlin+1	; 0346	A5 3A		; get hi byte of current BASIC line #

cmp #$ff	; 034b	C9 FF		; in immediate mode?
beq err_trap_standard
		; 034d	F0 27		; yes, exit to standard error handler

sta err_line+1	; 0348	8D 7B 03	; store it
lda curlin	; 034f	A5 39		; get low byte of current BASIC line #
sta err_line	; 0351	8D 7A 03	; store it
stx err_num	; 0354	8E 79 03
ldy #$00	; 0357	A0 00
l0359:
lda err_action,y; 0359	B9 7C 03	; start of error trap recovery text
sta buf,y	; 035c	99 00 02	; put in BASIC Line Editor Input Buffer
beq l0364	; 035f	F0 03		; look for string terminator
iny		; 0361	C8
bne l0359	; 0362	D0 F5
l0364:
ldx #$ff	; 0364	A2 FF		; set immediate mode flag
ldy #$01	; 0366	A0 01
jmp $a486	; 0368	4C 86 A4	; partway into BASIC's MAIN loop

err_trap_standard:
jmp error	;			; jump to standard ierror vector of $e38b

err_trap_custom:
jmp (ierror)	; 0376	6C 00 03

err_num:
	byte $00

err_line:
	word $0000

; 0379: error #
; 037a: lo byte, line # which caused error
; 037b: hi byte, line # which caused error
; 0379	14 0b 00 47  4f 54 4f 20   ...GOTO
; 0381	34 30 30 30  00 00 00 00   4000....
err_action:
; 16 byte buffer: petscii text put in BASIC input buffer when runtime error
; occurs
	area 16,0

; 7-byte descriptor for "input any" string return:
str_name:
	word $0000
str_len:
	byte $00
str_addr:
	word inbuf
; unused by descriptor:
	word $0000
{endasm}
