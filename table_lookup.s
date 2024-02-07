@ looks up the code for the given char within the lookup table

.cpu    cortex-a53
.fpu    neon-fp-armv8

@ constants
.equ    LOCALS, 28

@ parameters
.equ    table, -16
.equ    table_len, -20
.equ    char, -24

@ local variables
.equ    index, -8

@ struct Node   (20 bytes)
.equ    nodeSize, 20
.equ    nodeFreq, 0         @ 4 bytes (char)
.equ    nodeChar, 4         @ 4 bytes (int)
.equ    nodeCode, 8         @ 1 byte  (unsigned int)
.equ    nodeLeft, 12         @ 4 bytes (addr)
.equ    nodeRight, 16       @ 4 bytes (addr)

.align  2
.text
.global table_lookup
.type   table_lookup, %function

table_lookup:
    push {fp, lr}
    add fp, sp, #4
    sub sp, sp, #LOCALS
    str r0, [fp, #table]
    str r1, [fp, #table_len]
    str r2, [fp, #char]
@ search for the character within the table
    mov r0, #0
    str r0, [fp, #index]
search_loop:
        @ if i >= table_len : break
        ldr r0, [fp, #index]
        ldr r1, [fp, #table_len]
        cmp r0, r1
        bge exit_loop

    @ grab the table[i] and check if its character matches the input char
        ldr r1, [fp, #index]
        mov r2, #nodeSize
        mul r1, r1, r2
        ldr r0, [fp, #table]
        add r0, r0, r1
        ldrb r1, [r0, #nodeChar]
        ldrb r2, [fp, #char]
        cmp r1, r2
        beq found_char

        @ i++
        ldr r0, [fp, #index]
        add r0, r0, #1
        str r0, [fp, #index]
        b search_loop
exit_loop:
    mov r0, #0
    b finish
found_char:
    ldr r0, [r0, #nodeCode]
finish:
    sub sp, fp, #4
    pop {fp, pc}
