@ reads a given text file

.cpu    cortex-a53
.fpu    neon-fp-armv8

.equ    LOCALS, 24

.equ    fileloc, -24
.equ    file, -8
.equ    file_size, -12
.equ    buffer, -16

.data
read_access:    .asciz  "r"

.align  2
.text
.global read_file
.type   read_file, %function

read_file:
    push {fp, lr}
    add fp, sp, #4
    sub sp, sp, #LOCALS
    str r0, [fp, #fileloc]
@ open the file
    ldr r1, =read_access
    ldr r0, [fp, #fileloc]
    bl fopen
    str r0, [fp, #file]
@ DOES NOT CHECK IF FILE CANNOT BE OPENED : UNSAFE
    @ fseek(file, 0, SEEK_END)
    mov r2, #2
    mov r1, #0
    ldr r0, [fp, #file]
    bl fseek
    ldr r0, [fp, #file]
    bl ftell
    str r0, [fp, #file_size]
    mov r2, #0
    mov r1, #0
    ldr r0, [fp, #file]
    bl fseek
@ get the character buffer
    ldr r3, [fp, #file_size]
    add r3, r3, #1
    mov r0, r3
    bl malloc
    mov r3, r0
    str r3, [fp, #buffer]
    @ fread(buffer, 1, file_size, file);
    ldr r2, [fp, #file_size]
    ldr r3, [fp, #file]
    mov r1, #1
    ldr r0, [fp, #buffer]
    bl fread
    @ buffer[file_size] = '\0';
    ldr r3, [fp, #file_size]
    ldr r2, [fp, #buffer]
    mov r1, #0
    strb r1, [r2, r3]
@ fclose(file);
    ldr r0, [fp, #file]
    bl fclose
@ return buffer;
    ldr r0, [fp, #buffer]
    sub sp, fp, #4
    pop {fp, pc}
