;  Project name : base32enc
;  Version         : 1.0
;  Created date    : 14/11/2018
;  Last update     : 16/12/2018
;  Author          : Sascha Ledermann
;  Description     : A simple program in assembly for Linux, using NASM 2.05.
;   Its purpose is to convert an Input String into Base32
;
;  Run it this way:
;    base32enc < (input file)
;       or
;    base32enc <<< (Input String)
;
;  Build using these commands:
;    nasm -f elf64 -g -F stabs base32enc.asm
;    ld -o base32enc base32enc.o
;
SECTION .bss                  ;Section containing uninitialized data

  inp   resb 1                ;Variable to store the value of an input character

SECTION .data                 ;Section containing initialized data

  OutStr:  db "========"      ;Format of the output String
  Digits: db "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567" ;All possible output characters of Base32

SECTION .text                 ;Section containing code

global _start                 ;Entry point for the Linker!

_start:                       ;Startsection where registers get initialized
  nop
  mov r15,0                   ;Counter for the Number of converted characters
  mov r14,0                   ;Counter for the Number of scanned Inputs
  mov r13,1                   ;Register used to check if the input was empty inside the shift procedures
  jmp Jump

Input:                        ;Section used to read 1 Byte of Input Data
  nop
  push r14                    ;push r14 on the Stack
  mov rax,3
  mov rbx,0
  mov rcx,inp
  mov rdx,1
  int 80h                     ;Specify Sys_read with File Descriptor: Standard Input
  cmp rax,0                   ;If there was no Input rax is 0
  je EOF
PostInput:                    ;Section used to Jump back to the correct Shifting procedure
  mov r13,rax
  pop r14
  inc r14
  cmp r14,1
  je Shift10
  cmp r14,2
  je Shift20
  cmp r14,3
  je Shift30
  cmp r14,4
  je Shift40
  cmp r14,5
  je Shift50

EOF:                          ;Section used to reset the inp variable
  mov byte [inp],0
  jmp PostInput

Encode:                       ;Section used to convert and write the character to the Output String
  and al,1FH                  ;Mask the highest 3 Bits
  mov al,byte [Digits+rax]    ;Move the value of the corresponding Base32 character to al
  mov byte [OutStr+r15],al    ;Copy the Base32 character to the correct position in the Output String
  inc r15                     ;Increment the String Pointer
  cmp r13,0                   ;If there was no Input ..
  je Output                   ;.. Jump to the Output Section
Jump:                         ;Section used to jump to the correct shifting procedure
  cmp r15,0
  je Shift1
  cmp r15,1
  je Shift2
  cmp r15,2
  je Shift21
  cmp r15,3
  je Shift3
  cmp r15,4
  je Shift4
  cmp r15,5
  je Shift41
  cmp r15,6
  je Shift5
  cmp r15,7
  je Shift51
  cmp r15,8
  je Output
  jmp Exit

Shift1:                       ;Shifting procedure for the first Input Byte
  nop
  jmp Input
Shift10:                      ;Jumppoint after Sys_read
  cmp r13,0
  je Exit
  mov rbx,[inp]               ;Move the Input value into rbx
  shl rbx,5                   ;Shift rbx 5 positions to the left
  mov al,bh                   ;Copy the Byte in bh to al
  shl rbx,3                   ;Push the remaining bits into bh
  push rbx                    ;Push rbx on the stack
  jmp Encode                  ;Jump to Encode

Shift2:                       ;Shifting procedure for the second Input Byte
  nop
  jmp Input
Shift20:
  pop rbx
  mov bl,[inp]
  shl rbx,2
  mov al,bh
  jmp Encode
Shift21:
  shl rbx,5
  mov al,bh
  shl rbx,1
  push rbx
  jmp Encode

Shift3:                       ;Shifting procedure for the third Input Byte
  nop
  jmp Input
Shift30:
  pop rbx
  mov bl,[inp]
  shl rbx,4
  mov al,bh
  shl rbx,4
  push rbx
  jmp Encode

Shift4:                       ;Shifting procedure for the fourth Input Byte
  nop
  jmp Input
Shift40:
  pop rbx
  mov bl,[inp]
  shl rbx,1
  mov al,bh
  jmp Encode
Shift41:
  shl rbx,5
  mov al,bh
  shl rbx,2
  push rbx
  jmp Encode

Shift5:                       ;Shifting procedure for the fifth Input Byte
  nop
  jmp Input
Shift50:
  pop rbx
  mov bl,[inp]
  shl rbx,3
  mov al,bh
  jmp Encode
Shift51:
  shl rbx,5
  mov al,bh
  jmp Encode

Output:                       ;Section used to write the Output String
  nop
  push r13
  mov rax,4
  mov rbx,1
  mov rcx,OutStr
  mov rdx,8
  int 80h                     ;Specify Sys_write with File Descriptor: Standard Output
  pop r13
  cmp r13,0                   ;If there was no Input then the Program can end..
  je Exit
  mov rcx,8                   ;Set rcx to the length of the Base32 Output String
Reset:                        ;.. Otherwise the Output String gets reset
  mov byte [OutStr+rcx],3DH   ;Fill the Output string with equal signs
  dec rcx
  cmp rcx,0
  jg Reset
  jmp _start                  ;Afterwards jump to the start Section of the program

Exit:                         ;Exitsection of the program
  nop
  mov byte [OutStr],0AH       ;Write a new line character to the end of the Output
  mov rax,4
  mov rbx,1
  mov rcx,OutStr
  mov rdx,1
  int 80h
  nop
  mov rax,1                   ;Exitcode
  mov rbx,0                   ;Return 0
  int 80H                     ;Syscall
