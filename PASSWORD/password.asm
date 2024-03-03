.model tiny
.286
.code
org 100h
Start:
    mov AH, 09h;                        print greeting
    mov DX, offset greeting
    int 21h

    mov AH, 0Ah;                        buffered string input
    push CS 
    pop DS
    mov DX, offset input;               data in input
    int 21h

    mov CL, CS:[input+1];                len of input str
    LEA DI, CS:[input+2];                start of input
    LEA BX, psw;
    push CS
    pop ES

    jmp compare;                        for input data
    input DB 254d, 11 dup(?)
    congrats DB 'Congratulations)))$'

    
compare:
    mov AL, [BX];                       cmp chars from password
    SCASB;                              and input
    jne intrusion;                      if not equal->intrusion
    inc BX
    LOOP compare

PrintCongrats:
    mov AX, 7103h;                      print congrats 
    call PrintBackground
    mov AH, 09h 
    mov DX, offset congrats
    int 21h

stop:
    mov AX, 4C00h
    int 21h

intrusion:;                             print error in case of 
    mov AX, 0C21h;                      incorrect password
    call PrintBackground 
    mov AH, 09h 
    mov DX, offset error
    int 21h
    jmp stop

PrintBackground:
    push 0B800h;                        print background
    pop ES
    mov DI, 00h 
    mov CX, 80*25

    rep STOSW

    ret


    greeting DB 'Enter the password', 0Ah, '$'
    error DB 'Incorrect password', 0Ah, '$'
    psw DB 'hihihaha'
.data

end Start
