.model tiny
.286
.code
org 100h
		StartOffset EQU 160d;       160 bytes in one string
		ShadowColor EQU 01100000b;  shade color
		EmptyCell EQU 00h

	NEXTSTR MACRO 
		add BX, StartOffset
		mov DI, BX
		ENDM

Start:
    call ParseCL;       parsing the command line
	COMMENT * FrameData:
		Len - frame length
		Hight - frame hight
		TextLen - length of included text
		Style - address of the style
		Text - address of the text 
		Color - frame color *

	mov BX, 0B800h;
	mov ES, BX;         ES = B800h (address of text segment)
	mov BX, 80d;        BX = length of all string
	sub BL, Len;        BL -= frame length
	TEST BX, 1b;        Check whether BX is even
	je print;           no->go to print
	inc BX;             else->make it even (BX++)

print:
    add BX, StartOffset*2;  DI = BX += 160*2 (skip 2 strings above)
	mov DI, BX
	call PrintFrame;        go to PrintFrame

	mov AX, 4C00h
	int 21h

;----------PrintFrame-----------------------
;ASSUME:Len - lenght,
;	Hight - hight,
;	Style - style,
;	Color - color,
;	Text - text;
;-------------------------------------------
PrintFrame:
    xor CX, CX;         CX = 0
	mov CL, Len;        CL = frame length
	mov AH, Color;      AH = frame color
	mov AL, EmptyCell;  AL = empty cell
	REP STOSW;          print emtpy line

	NEXTSTR

	mov SI, Style;      SI = address of Style
	call PrintTitle;    print title
		
	NEXTSTR

	mov CL, Height;     print middle part
	sub CL, 4d
		
printMiddle:
    mov DH, CL;         save CX
	mov CL, Len;        CL = frame length
	call PrintLine

	NEXTSTR

	mov CL, DH
	sub SI, 2d;         return SI
	LOOP printMiddle

	add SI, 3d;         SI = address of third Style
	mov CL, Len
		
	call PrintLine;     print ending string

	NEXTSTR

	mov CL, Len;        print the last empty line
	mov AL, EmptyCell
	REP STOSW

	NEXTSTR

	mov CL, Len;        DRAW SHADOW
	mov DH, Height
	mov AL, ShadowColor
	call DrawShadow

	ret
		
;------------ PRINT TITLE -------------------
;	PRINT FRAME LINE WITH TITLE
;ASSUME:AL - frame color
;	TextLen - the length of included text
;	Len - the length of frame
;	SI - address of Style
;	Style - address of Style
;	ES:[DI] - destination address
;	EmptyCell - outer frame symb
;DESTROY:AH, CX, DH
;RETURN:ES:[DI] - next destination address
;	SI - address of next 3 Style symb
;--------------------------------------------
PrintTitle:
    mov CL, Len
	sub CL, 6d
	cmp TextLen, CL
	jbe notcutLen
	mov TextLen, CL

notcutLen:
    mov AL, EmptyCell
	STOSW
	
	mov AL, BYTE PTR [SI];  AH = firts Style symb
	STOSW

	mov CL, Len
	sub CL, TextLen
	sub CL, 6d;             2 empty, 2 first Style, 2 between Text
	shr CL, 1;              CL = 1/2 len of second Style symbs
	mov DH, CL;             save CL
		
	inc SI;                 print second Style symb (1 part)
	mov AL, BYTE PTR [SI];  AH = second Style symb
	REP STOSW

	mov AL, EmptyCell
	STOSW
	
	mov CL, TextLen;        CX = text length
	mov Style, SI;          Style update
	mov SI, Text;           SI = address of Text
		
printText:
    mov AL, BYTE PTR [SI]
	STOSW
	inc SI
	LOOP printText

	mov AL, EmptyCell;      after text space
	STOSW

	mov CL, Len;            CL = number of second Style symb
	sub CL, DH
	sub CL, 6d
	sub CL, TextLen
		
	mov SI, Style;          print second Style symbs (2 part)
	mov AL, BYTE PTR [SI]
	REP STOSW

    inc SI;                 print third Style syb
    mov AL, BYTE PTR [SI]
    STOSW

    mov AL, EmptyCell;      print empty cell
    STOSW

    inc SI;
    ret

;-------------- PRINT LINE -------------------------------
;	PRINT CX IDENTICAL LINES
;ASSUME:CX = string length,
;	SI = Style address,
;	ES:[DI] = destination address,
;	AL = frame color,
;	EmptyCell = outer frame symb;
;	;DH = number of LOOPS (number of repeated lines),
;DESTROYS:AH (EmptyCell), CX
;----------------------------------------------------------
PrintLine:
    mov AL, EmptyCell;      fisrt cell - the empty one
    STOSW

    mov AL, BYTE PTR [SI];  second cell - fist sybm from Style
    STOSW
    
    inc SI;                 SI = second Style symb
    sub CX, 4d;             CL -= 4 (2 empty and 2 end symb)
    mov AL, BYTE PTR [SI];  AH = second Style symb
    REP STOSW;              fill inner part of the string

    inc SI;                 SI = third Style symb
    mov AL, BYTE PTR [SI];  AH = third Style symb
    STOSW

    mov AL, EmptyCell;      last frame cell - empty
    STOSW;

    ret

;---------- DRAW SHADOW --------------------
;ASSUME:AL - shadow color,
;	CL - frame length,
;	DH - frame hight
;
;DESTROY:CX(=0), DI, BX
;-------------------------------------------
DrawShadow:
    add DI, 4d;         shift from the edge

shadowLine:
    inc DI;             skip DI
    STOSB
    LOOP shadowLine;    print shadow line 

    sub DI, 4d
    mov BX, DI
    
    mov CL, DH;         CL = frame hight
    dec CL

loopShadow:
    sub BX, StartOffset;    address of upper string
    mov DI, BX
    inc DI;             skip byte
    STOSB
    inc DI;             skip byte
    STOSB
    LOOP loopShadow;    fill shadow around the string
    
    ret

;----------SKIP SPACES----------------------
;ASSUMES:ES[DI] - address of current char;
;	 CX - com line length;
;DESTROY:AL
;-------------------------------------------
SkipSpaces:
    mov AL, 20h;        AL - space char
    REPE SCASB;         continue until equal space char
    dec DI;             extra incrision of DI in SCASB
    inc CX;
    ret
;----------GET COLOR-----------------------
;	CONVERT STRING TO HEX
;ASSUME:SI - address of char
;	CX - number of chars left in ComLine
;RETURN:AH - result color
;DESTROY:AL
;-------------------------------------------
GetColor:
    LODSB
    cmp AL, 20h
    je endGetColor

    cmp AL, '9'
    ja alphabet

    sub AL, '0'
    jmp SHORT nextColor
 
alphabet:
    sub AL, 'A'-10d
nextColor:
    cmp AH, 00h
	jne mulHex
	mov AH, AL
	jmp GetColor

mulHex:
    shl AH, 4
	add AH, AL
	jmp GetColor
		
endGetColor:
    ret

;----------SCAN DIGIT(d)--------------------
;ASSUME:SI - address of char,
;	CX - number of chars left in ComLine;
;RETURN:AH - result digit
;DESTROY:AX; BH
;-------------------------------------------
ScanDigit:
    xor AH, AH;         AH = 0(set counter to 0)

getDigit:
    LODSB;              AL = DS:[SI]
    dec CX;
    cmp AL, 20h;
    je endScanDigit;	if space->end

    sub AL, '0';        get digit
    cmp AH, 00h;        if not first encounter of digit
    jne mulTen;         need to multiply on 10
    mov AH, AL;         AH = AL
    jmp getDigit;

mulTen:
    mov BH, AH;         BH = AH
    shl AH, 1;          AL = x*2
    shl BH, 3;          BH = x*8
    add AH, BH;         AH = x*10
    add AH, AL;         AH = x*10+newDigit
    jmp getDigit

endScanDigit:
    ret

;----------GetFStyle----------------------
;	GET THE INFO ABOUT FRAME STYLE
;ASSUME:ES:[DI] - address of frame style
;	CX = number of chars left in com line		
;DESTROY:BX, AX (result address)
;-------------------------------------------
GetFStyle:
    mov AL, '*';        custom style start symbol
    dec CX;             CX--
    SCASB;              cmp AL, ES:[DI++]
    je setStyle;        if starts with '*'->next symb set style

    dec DI;             DI--(first char not '*')
    mov AL, BYTE PTR [DI];AL = frame style code(in string)
    sub AL, '1';        AL = frame style code

    xor BX, BX
    mov AH, AL;         BL = AL
    shl AH, 3;          AH*=8
    add AL, AH;         AL+=AL
    xor AH, AH
    LEA BX, Style1;     AX = Style1 + 9*offset
    add AX, BX

    inc DI
    jmp endStyle

setStyle:
    mov AX, DI;         AH - address of custom style
    mov AH, AL;         AH = AL(up to 100h, AH enough)
    mov AL, 20h;        AL - space char
    REPNE SCASB;        DI++ until AL != space char
    mov AL, AH
    xor AH, AH
endStyle:
    ret

;----------PARSE COMMAND LINE---------------
;DESTROY: AX, DX, 
;RETURNS: Len - frame length
;	Height - frame hight
;	Color - frame color
;	Style - address of frame style
;	TextLen - text length
;	Text - address of Text
;	SI = DI - address of Text
;-------------------------------------------
ParseCL:
    xor CX, CX;             CX = 0
    xor SI, SI;             SI = 0 xor DI, DI;
    mov DI, 80h;            DI = 80h(address of com line length)
    mov CL, BYTE PTR [DI];  CL = com line length
    mov DI, 81h;            DI = 81h(address of com line start)

    call SkipSpaces;        skip spaces
    mov SI, DI;            align SI and DI

    call ScanDigit;         get length of frame
    mov Len, AH;            Length = frame length
    mov DI, SI;             align SI and DI

    call SkipSpaces;        skip spaces
    mov SI, DI;             align SI and DI

    call ScanDigit;         get width of frame
    mov Height, AH;         Hight = frame hight
    mov DI, SI;             align SI and DI

    call SkipSpaces;        skip spaces
    mov SI, DI;             align SI and DI
    mov SI, DI;             align SI and DI
    xor AX, AX
    call GetColor;          AH - frame color
    mov Color, AH;          Color - frame color
    mov DI, SI;             align SI and DI
    sub CL, 3
    
    call GetFStyle;         AX - frame style
    mov Style, AX;          Style = frame style	
    call SkipSpaces;        skip spaces
    mov SI, DI;             align SI and DI
    
    mov Text, SI
    mov TextLen, CL
    
    ;SI, DI - address of inserted text
    ret

.data
	Style DW ?
	Color DB ?
	Text DW ?
	TextLen DB ?
	Len DB ?
	Height DB ?
	
	Style1 DB 0C9h, 0CDh, 0BBh, 0BAh, 0B0h, 0BAh, 0C8h, 0CDh, 0BCh
	Style2 DB 0DAh, 011h, 0BFh, 01Eh, 0B1h, 01Fh, 0C0h, 010h, 0D9h
		
end Start

