@ decodes the given encoding array into text

.cpu    cortex-a53
.fpu    neon-fp-armv8

@ constants
.equ    LOCALS, 52
.equ    MESSAGE_MAX, 1024       @ the maximum message size it can output

@ parameters
.equ    tree, -44
.equ    encoding, -48
.equ    encoding_len, -52

@ local variables
.equ    decoded, -24
.equ    index, -8
.equ    current, -12
.equ    i, -16
.equ    en, -28
.equ    char, -32
.equ    b_index, -36
.equ    bit, -40

@ struct Node   (20 bytes)
.equ    nodeSize, 20
.equ    nodeFreq, 0         @ 4 bytes (char)
.equ    nodeChar, 4         @ 4 bytes (int)
.equ    nodeCode, 8         @ 4 bytes (unsigned int)
.equ    nodeLeft, 12        @ 4 bytes (addr)
.equ    nodeRight, 16       @ 4 bytes (addr)

.align  2
.text
.global decode
.type   decode, %function

decode:
    push {fp, lr}
    add fp, sp, #4
    sub sp, sp, #LOCALS
    str r0, [fp, #tree]
    str r1, [fp, #encoding]
    str r2, [fp, #encoding_len]
@ allocate the decoded string
    mov r0, #MESSAGE_MAX
    bl malloc
    mov r1, #0
    mov r2, #MESSAGE_MAX
    bl memset
    str r0, [fp, #decoded]
@ decode the message
    mov r0, #0
    str r0, [fp, #index]
    str r0, [fp, #i]
    strb r0, [fp, #char]
    ldr r0, [fp, #tree]
    str r0, [fp, #current]
decode_loop:
        ldr r0, [fp, #i]
        ldr r1, [fp, #encoding_len]
        add r1, r1, #1
        cmp r0, r1
        bge exit_dloop

    @ get the current sub-encoding
        lsl r0, r0, #2
        ldr r1, [fp, #encoding]
        add r1, r1, r0
        ldr r1, [r1]
        str r1, [fp, #en]

    @ get the length of the bit
        mov r0, r1
        bl bit_length
        sub r0, r0, #1
        str r0, [fp, #b_index]
    @ loop through each bit (left to right, so reverse)
    bin_loop:
            ldr r0, [fp, #b_index]
            cmp r0, #0
            blt exit_bloop
            sub r0, r0, #1
            str r0, [fp, #b_index]
        @ determine the current bit
            ldr r1, [fp, #en]
            lsr r2, r1, r0
            and r2, r2, #1
            str r2, [fp, #bit]
        @ determine the current character within the tree
            ldr r0, [fp, #current]
            ldrb r0, [r0, #nodeChar]
            str r0, [fp, #char]
        @ traverse the tree in the direction of the current bit
            ldr r0, [fp, #bit]
            cmp r0, #0          @ left direction
            bne right
                ldr r0, [fp, #current]
                ldr r0, [r0, #nodeLeft]
                str r0, [fp, #current]
                b finish_traversal
            right:
                ldr r0, [fp, #current]
                ldr r0, [r0, #nodeRight]
                str r0, [fp, #current]
        @ if the current node no longer exists then add a character
        @ otherwise continue searching for the character
        finish_traversal:
            ldr r0, [fp, #current]
            cmp r0, #0
            bne bin_loop
                ldr r3, [fp, #index]
                ldr r1, [fp, #decoded]
                ldrb r0, [fp, #char]
                strb r0, [r1, r3]           @ decoded[index] = c
                add r3, r3, #1              @ index++
                str r3, [fp, #index]
            @ reset the tree back to the start
                ldr r0, [fp, #tree]
                str r0, [fp, #current]
        b bin_loop
    exit_bloop:
        ldr r0, [fp, #i]
        add r0, r0, #1
        str r0, [fp, #i]
        b decode_loop
exit_dloop:
@ nullify the end of the message
    ldr r3, [fp, #index]
    ldr r1, [fp, #decoded]
    mov r0, #0
    strb r0, [r1, r3]
    add r3, r3, #1
    str r3, [fp, #index]
@ return the decoded message
    ldr r0, [fp, #decoded]
    sub sp, fp, #4
    pop {fp, pc}
