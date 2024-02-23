.model tiny
.386
.data
		counter DB 00h
.code
org 100h
		lucorn EQU 0C9h; left upper corner = 0c9h
		rucorn EQU 0BBh; right upper corner = 0bbh
		llcorn EQU 0C8h; left lower corner = 0c8h
		rlcorn EQU 0BCh; rigth lower corner = 0bch
		midframe EQU 0CDh; horizontal middle frame = 0cdh
		verframe EQU 0BAh; vertical frame = 0bah

		fcolor EQU 01011100b; frame color set
		shcolor EQU 00111000b; shadow color set

		hight EQU 7d; frame hight = 5
		len EQU 60d; frame width = 60
		shsize EQU 2d; shadow size = 4
		startadd EQU 139+2*160
		maxl EQU 160d; max lenth of string in bytes

VMode:		mov AH, 03h;
		int 10h;

Start:		mov BX, 0B800h
		mov ES, BX

;--OPEN FRAME LINE-----------------------------------
		mov BX, startadd; BX = start address
		mov AH, lucorn
		mov AL, midframe
		mov DH, rucorn
		mov DL, 00h
		call WriteStr
		inc counter
		
		;MOV AX, 4C00h
		;INT 21h	

;--NO SHADOW LINES-----------------------------------
		mov CX, shsize-1; set counter
		jcxz MixedL; check if cx is zero	

PrintNSh:	call ChangeBX

		mov AH, verframe
		mov AL, 00h
		mov DH, verframe
		call WriteStr
		inc counter
		LOOP PrintNSh

		;mov ax, 4c13h
		;int 21h

;--MIXED LINES---------------------------------------
MixedL:		mov DL, shsize
		call ChangeBX
		mov CX, hight-shsize-1
		jcxz CloseFr

PrintML:	mov AH, verframe
		mov AL, 00h
		mov DH, verframe
		call WriteStr
		inc counter
		mov DL, shsize
		call ChangeBX	
		LOOP PrintML;
		
		;MOV AX, 4C13h
		;INT 21h

;--CLOSE FRAME LINE----------------------------------
CloseFr:	mov AH, llcorn
		mov AL, midframe
		mov DH, rlcorn
		mov DL, shsize
		call WriteStr
		inc counter

;--SHADOW LINES--------------------------------------
		mov CX, shsize
		mov DL, len
		call ChangeBX
		jcxz EndOfProg
		
PrintSh:	call WriteStr
		mov DL, len
		inc counter
		call ChangeBX
		LOOP PrintSh		

EndOfProg:	mov AX, 4c00h
		int 21h

;------------------------------------------
;	PUT NEXT ADDRESS INTO BX
;ASSUMES: DL - number of shadow bytes 
;DESTROY: AX
;------------------------------------------
ChangeBX:	mov AL, maxl
		mul counter
		add AX, startadd
		test DL, DL
		je WithoutSh
		add AX, shsize*2
WithoutSh:	mov BX, AX			
		ret

;-----------------------------------------
;	WRITES STR OF SYMBOLS TO VMEM
;ENTRY: BX is the start of offset relative to ES
;	AH, AL, DH are synbols, DL - shadow size
;ASSUMES: ES = 0B800h; BX is odd number
;DESTROY: DL (zero value), BX
;-----------------------------------------
WriteStr:	cmp DL, 00h	
		je NoShadow; case with no shadow (only frame)
		cmp DL, shsize
		jne DrawOnlyShadow; case with just a shadow
		jmp DrawShadow; case with both shadow and frame

DrawOnlyShadow:	mov BYTE PTR ES:[BX], shcolor
		dec BX
		dec BX
		dec DL
		cmp DL, 00h
		jne DrawOnlyShadow
		ret

DrawShadow:	mov BYTE PTR ES:[BX], shcolor; color shadow byte
		dec BX
		dec BX
		dec DL
		cmp DL, 00h
		jne DrawShadow
					

NoShadow:	mov BYTE PTR ES:[BX], fcolor
		dec BX
		mov BYTE PTR ES:[BX], 00h
		dec BX
		mov BYTE PTR ES:[BX], fcolor
		dec BX
		mov BYTE PTR ES:[BX], DH
		dec BX

		mov DL, len-4
MidPart:	mov BYTE PTR ES:[BX], fcolor
		dec BX
		mov BYTE PTR ES:[BX], AL
		dec BX
		dec DL
		cmp DL, 00h
		ja MidPart

		mov BYTE PTR ES:[BX], fcolor
		dec BX
		mov BYTE PTR ES:[BX], AH
		dec BX
		mov BYTE PTR ES:[BX], fcolor
		dec BX
		dec BX

		ret	
		

end VMode






