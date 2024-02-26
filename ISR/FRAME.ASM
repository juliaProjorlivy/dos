.model tiny
.286
.code
org 100h
	
FRAMEPROG	PROC
		StartOffset EQU 160d;		160 bytes in one string
		ShadowColor EQU 01100000b;	shade color	
		EmptyCell EQU 00h

	NEXTSTR MACRO ;				shift on next string
		add BX, StartOffset
		mov DI, BX
		ENDM

Start:		mov Text,offset TitleText
		mov Style, offset Style1

		MOV AH, 05H
		MOV AL, 0
		INT 10H

		PUSH 0B800H
		POP ES
		MOV DI, 0
		MOV AX, 7103H
		MOV CX, 80*25
		REP STOSW

		;MOV AH, 05H
		;MOV AL, 0
		;INT 10H

	
	
		mov AX, 001Bh
		mov BX, 0000h	
		int 10h	

		COMMENT * FrameData:
			Len - frame length
			Hight - frame hight
			TextLen - length of included text
			Style - address of the style
			Text - address of the text 
			Color - frame color *

		mov BX, 0B800h;
		mov ES, BX;		ES = B800h (address of text segment)
		mov BX, 80d;		BX = length of all string
		sub BL, Len;		BL -= frame length
		TEST BX, 1b;		Check whether BX is even
		je print;		no->go to print
		inc BX;			else->make it even (BX++)

print:		add BX, StartOffset*2;	DI = BX += 160*2 (skip 2 strings above)
		mov DI, BX
		call PrintFrame;	go to PrintFrame

		mov AX, 4C00h
		int 21h

;----------PrintFrame-----------------------
;ASSUME:Len - lenght,
;	Hight - hight,
;	Style - style,
;	Color - color,
;	Text - text;
;-------------------------------------------
PrintFrame:	xor CX, CX;		CX = 0
		mov CL, Len;		CL = frame length
		mov AH, Color;		AH = frame color
		mov AL, EmptyCell;	AL = empty cell
		REP STOSW;		print emtpy line

		NEXTSTR		

		mov SI, Style;		SI = address of Style
		call PrintTitle;	print title
		
		NEXTSTR

		mov CL, Height;		print middle part
		sub CL, 4d
		
printMiddle:	mov DH, CL;		save CX
		mov CL, Len;		CL = frame length
		call PrintLine

		NEXTSTR

		mov CL, DH
		sub SI, 2d;		return SI
		LOOP printMiddle

		add SI, 3d;		SI = address of third Style
		mov CL, Len
		
		call PrintLine;		print ending string

		NEXTSTR

		mov CL, Len;		print the last empty line
		mov AL, EmptyCell
		REP STOSW

		NEXTSTR

		mov CL, Len;		DRAW SHADOW
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
PrintTitle:	mov CL, Len
		sub CL, 6d
		cmp TextLen, CL
		jbe notcutLen
		mov TextLen, CL

notcutLen:	mov AL, EmptyCell
		STOSW
	
		mov AL, BYTE PTR [SI];	AH = firts Style symb
		STOSW

		mov CL, Len
		sub CL, TextLen
		sub CL, 6d;		2 empty, 2 first Style, 2 between Text
		shr CL, 1;		CL = 1/2 len of second Style symbs
		mov DH, CL;		save CL
		
		inc SI;			print second Style symb (1 part)
		mov AL, BYTE PTR [SI];	AH = second Style symb
		REP STOSW

		mov AL, EmptyCell
		STOSW
	
		mov CL, TextLen;	CX = text length
		mov Style, SI;		Style update
		mov SI, Text;		SI = address of Text
		
printText:	mov AL, BYTE PTR [SI]
		STOSW
		inc SI
		LOOP printText

		mov AL, EmptyCell;	after text space
		STOSW

		mov CL, Len;		CL = number of second Style symb
		sub CL, DH
		sub CL, 6d
		sub CL, TextLen
		
		mov SI, Style;		print second Style symbs (2 part)
		mov AL, BYTE PTR [SI]
		REP STOSW

		inc SI;			print third Style syb 
		mov AL, BYTE PTR [SI]
		STOSW

		mov AL, EmptyCell;	print empty cell
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
PrintLine:	mov AL, EmptyCell;	fisrt cell - the empty one
		STOSW

		mov AL, BYTE PTR [SI]; second cell - fist sybm from Style
		STOSW
		
		inc SI;			SI = second Style symb
		sub CX, 4d;		CL -= 4 (2 empty and 2 end symb)
		mov AL, BYTE PTR [SI];	AH = second Style symb
		REP STOSW;		fill inner part of the string

		inc SI;			SI = third Style symb
		mov AL, BYTE PTR [SI];	AH = third Style symb
		STOSW

		mov AL, EmptyCell;	last frame cell - empty
		STOSW;

		ret

;---------- DRAW SHADOW --------------------
;ASSUME:AL - shadow color,
;	CL - frame length,
;	DH - frame hight
;
;DESTROY:CX(=0), DI, BX
;-------------------------------------------
DrawShadow:	add DI, 4d;		shift from the edge

shadowLine:	inc DI;			skip DI
		STOSB
		LOOP shadowLine;	print shadow line 

		sub DI, 4d
		mov BX, DI
		
		mov CL, DH;		CL = frame hight
		dec CL

loopShadow:	sub BX, StartOffset;	address of upper string
		mov DI, BX
		inc DI;			skip byte
		STOSB
		inc DI;			skip byte
		STOSB
		LOOP loopShadow;	fill shadow around the string
		
		ret


.data
	TitleText DB 'Registers'
	Style1 DB 0DAh, 011h, 0BFh, 01Eh, 0B1h, 01Fh, 0C0h, 010h, 0D9h	

	Style DW ?
	Color DB 4Ah
	Text DW ?
	TextLen DB 9d
	Len DB 20d
	Height DB 20d
		ENDP
	
end Start

