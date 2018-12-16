;  Project name : base32dec
;  Version         : 1.0
;  Created date    : 28/11/2018
;  Last update     : 16/12/2018
;  Author          : Sascha Ledermann
;  Description     : A simple program in assembly for Linux, using NASM 2.05.
;   Its purpose is to convert a Base32 String to a 7-Bit ASCII String
;
;  Run it this way:
;    base32dec < (input file)
;       or
;    base32dec <<< (Input String)
;
;  Build using these commands:
;    nasm -f elf64 -g -F stabs base32dec.asm
;    ld -o base32dec base32dec.o
;
SECTION .bss			; Section containing uninitialized data

  inp   resb 1

SECTION .data			; Section containing initialised data

	NewLine: db 0AH
  Digits:  db "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567="
	OutStr:  db " "
  ErrorStr: db "Invalid Input, please check Inputstring! (Base32)"
  ErrorStrLng equ $-ErrorStr

SECTION .text			  ; Section containing code

global 	_start			; Linker needs this to find the entry point!

_start:
	nop
	mov r15,0         ;Loopcounter to check the character in "Digits"
	mov r11,0         ;Counter to Jump to the correct Decode Procedure
	push r11          ;Push r11 on the Stack

Input:
	nop
	mov rax,3         ;Specify sys_read call
	mov rbx,0         ;File Descriptor 0: Standard Input
	mov rcx,inp       ;Pass offset of the buffer to read
	mov rdx,1         ;Pass number of bytes to read at one pass
	int 80h           ;Syscall
	cmp rax,0         ;Jump to the Exit Section if there was no more Input
	je Exit
	mov al,[inp]      ;Copy the Input into the al register
	mov r15,0
	jmp Loop

Loop:
  cmp r15,33        ;If the value of r15 got to 33 then there was an error
  je Error
	mov bl,byte [Digits+r15]   ;Copy the character in the Digits String to bl
	cmp al,bl         ;Compare if the Input and the character of the Digits String are equal
	je Match          ;If so jump to Match
	inc r15           ;Otherwise increment r15 and repeat until there is a Match
	jmp Loop

Match:              ;Section used to jump to the correct decode procedure
	nop
	cmp r15,32        ;If r15 is 32 then we jump to Pad
	je Pad
	pop r11           ;Take a value from the stack and put it to r11
	mov rax,r15       ;Copy the Value of the Match to rax
	cmp r11,0
	je Decode1
  cmp r11,1
  je Decode2
  cmp r11,2
  je Decode3
  cmp r11,3
  je Decode31
  cmp r11,4
  je Decode4
  cmp r11,5
  je Decode5
  cmp r11,6
  je Decode51
  cmp r11,7
  je Decode6
	cmp r11,7
	jg Error

Decode1:            ;Section for the first character to decode
	nop               ;No decode here since we only have 5/8 Bits
	xor rax,rax
	mov rax,r15
	mov ah,al         ;Move the value of al to ah
	push rax          ;Push the value of rax on the Stack
	inc r11
	push r11          ;Push the value of r11 on the Stack
	jmp Input

Decode2:            ;Section for the second character to decode
	nop
	pop rax           ;Pop the value of rax from the Stack
	mov rbx,r15       ;Write the value of r15 to rbx
	shl bl,3          ;Shift bl 3 positions to the left
	mov al,bl         ;Move bl to al
	shl rax,3         ;Shift rax 3 Positions to the left
  mov byte [OutStr],ah    ;Move the value in ah to the Output String
	shl rax,2         ;Shift the reamining Bits in al to ah
	push rax          ;Push rax on the Stack
	inc r11           ;Increment r11
	push r11          ;Push r11 on the Stack
  push r14          ;Push r14 on the Stack
	jmp Output        ;Jump to the Ouput Section

Decode3:            ;Section for the third character to decode
  nop
  pop rax
  mov rbx,r15
  shl bl,3
  mov al,bl
  shl rax,5
  push rax
  inc r11
  push r11
  jmp Input
Decode31:
  pop rax
  mov rbx,r15
  shl rbx,3
  mov al,bl
  shl rax,1
  mov byte [OutStr],ah
  shl rax,4
  push rax
  inc r11
  push r11
  push r14
	jmp Output

Decode4:            ;Section for the fourth character to decode
	nop
	pop rax
	mov rbx,r15
	shl bl,3
	mov al,bl
	shl rax,4
	mov byte [OutStr],ah
	shl rax,1
	push rax
	inc r11
	push r11
  push r14
	jmp Output

Decode5:            ;Section for the fifth character to decode
  nop
  pop rax
  mov rbx,r15
  shl bl,3
  mov al,bl
  shl rax,5
  push rax
  inc r11
  push r11
  jmp Input
Decode51:
  pop rax
  mov rbx,r15
  shl rbx,3
  mov al,bl
  shl rax,2
  mov byte [OutStr],ah
  shl rax,3
  push rax
  inc r11
  push r11
  push r14
	jmp Output

Decode6:            ;Section for the sixth character to decode
	nop
	pop rax
	mov rbx,r15
	shl bl,3
	mov al,bl
	shl rax,5
	mov byte [OutStr],ah
	mov r11,0
	push r11
  push r14
	jmp Output

Output:           ;Section used to write the decoded character
	nop
	mov rax,4
	mov rbx,1
  mov rcx,OutStr
	mov rdx,1
	int 80H         ;Specify Sys_write with File Descriptor: Standard Output
	mov rcx,8
	pop r14
  cmp r14,1       ;If r14 is 1 then there is no more Input to decode and we can end the program
  je Exit
	jmp Input

Error:            ;Section used if there was an invalid Base32 Input String
  mov rax,4
  mov rbx,1
  mov rcx,ErrorStr
  mov rdx,ErrorStrLng
  int 80H         ;Write the errormessage then jump to Exit
	jmp Exit

Pad:              ;Section to set the correct value if we hit an equal character
	nop
	mov r15,0       ;Set r15 to 0
  mov r14,1       ;Set r14 to 1 so we know we can end the program afterwards
	jmp Match

Exit:
  mov rax,4
  mov rbx,1
  mov rcx,NewLine
  mov rdx,1
  int 80H         ;Write a Newline character to the Output
  mov eax,1		    ; Code for Exit Syscall
  mov ebx,0		    ; Return a code of zero
  int 80H			    ; Make kernel call
