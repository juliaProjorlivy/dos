.model tiny
.286
.code
org 100h

Start:		lea DI, RandomStr
		call StrLen

		lea SI, RandomStr
		lea DI, SecondStr
		call MemCmp

		mov AH, 09h		
		mov DX, CX
		int 21h		

		mov AX, 4c00h
		int 21h

;----------STRLEN-----------
;ASSUME:str addres ES:[DI];
;	end symb is 0;
;RESULT:strlen in CL (consider maxlen=255)
;DESTROY: DI, AL, CL
;---------------------------
StrLen:		mov AL, 0d;	end of line symb
		mov CL, 255d;	maxlen = 255
		REPNE SCASB;
		inc CL	
		not CL
		ret
;----------MEMCHR------------
;ASSUME:AL - search symb;
;	ES:[DI] - address of str;
;	CX - n bytes to search in;
;RETURN:ES:[DI] - address of search symb; if not found return AL = 00h
;DESTROY:
;----------------------------
MemChr:		REPNE SCASB;
		jne NotFound
		dec DI				
		ret
NotFound:	mov AL, 00h
		ret
;----------MEMSET------------
;ASSUME:AL - symb to fill with;
;	CX - number of bytes to put into string;
;	ES:[DI] - address of string;
;RETURN:ES:[DI] - address of string
;DESTROY:BX
;----------------------------
MemSet:		mov BX, DI
		REP STOSB
		mov DI, BX
		ret
;-----------MEMCPY-----------
;ASSUMES:DS[SI] - src, ES[DI] - destination;
;	CX - number of copy bytes;
;RETURN: ES[DI] - destination address
;DESTROY:BX
;----------------------------
MemCpy:		mov BX, DI
		REP MOVSB
		mov DI, BX
		ret
;-----------MEMCMP-----------
;ASSUMES:ES[DI], DS[SI] - addresses of string1 and string2;
;	CX - number of bytes that are compared;
;RETURN:CX = 0 if S1=S2; 1 if S1>S2; -1 if S1<S2
;DESTROY: AL, SI, DI
;----------------------------
MemCmp:		XOR AL, AL
		LODSB
		SCASB
		jne EndMemCmp
		LOOP MemCmp
		mov CX, 0d
		ret
EndMemCmp:	ja S1MoreS2
		mov CX, -1d
		ret
S1MoreS2:	mov CX, 1d
		ret

data:
	RandomStr db 'here is 13 symbs', 0d
	SecondStr db 'here is 14 symbs', '$'
end Start
