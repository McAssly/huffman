@ encodes the message based on the given lookup table

.cpu    cortex-a53
.fpu    neon-fp-armv8

@ constants
.equ    LOCALS, 44
.equ    ENCODING_WIDTH, 32

@ parameters
.equ    table, -32
.equ    table_len, -36
.equ    text, -40
.equ    encoding_len, -44

@ local variables
.equ    msg_len, -8
.equ    i, -12
.equ    index, -16
.equ    char, -21
.equ    code, -28
.equ    encoding, -20

@ struct Node   (20 bytes)
.equ    nodeSize, 20
.equ    nodeFreq, 0         @ 4 bytes (char)
.equ    nodeChar, 4         @ 4 bytes (int)
.equ    nodeCode, 8         @ 4 bytes  (unsigned int)
.equ    nodeLeft, 12        @ 4 bytes (addr)
.equ    nodeRight, 16       @ 4 bytes (addr)

.align  2
.text
.global encode
.type   encode, %function

encode:
    push {fp, lr}
    add fp, sp, #4
    sub sp, sp, #LOCALS         @ store parameters
    str r0, [fp, #table]
    str r1, [fp, #table_len]
    str r2, [fp, #text]
    str r3, [fp, #encoding_len]

@ initialize the message length, (needs to be calculated)
    mov r0, #0
    str r0, [fp, #msg_len]
msg_counter:
    ldr r0, [fp, #text]
    ldr r1, [fp, #msg_len]
    ldrb r0, [r0, r1]
    add r1, r1, #1
    str r1, [fp, #msg_len]
    cmp r0, #0
    bne msg_counter

@ initialize the encoded message
    ldr r0, [fp, #msg_len]
    lsl r0, r0, #2          @ 4 bytes per code string
    bl malloc
    ldr r2, [fp, #msg_len]
    lsl r2, r2, #2
    mov r1, #0
    bl memset
    str r0, [fp, #encoding]

@ encode the message based on table lookup
    mov r0, #0
    str r0, [fp, #index]
    str r0, [fp, #i]
encode_loop:
        ldr r0, [fp, #i]
        ldr r1, [fp, #msg_len]
        cmp r0, r1
        bge exit_eloop

    @ get the character within the message
        ldr r0, [fp, #i]
        ldr r1, [fp, #text]
        add r0, r1, r0
        ldrb r0, [r0]
        strb r0, [fp, #char]        @ c = message[i]

        @ code = table_lookup(table, table_len, c);
    @ look up the code for the character within the table
        mov r2, r0                  @ move c into param2
        ldr r1, [fp, #table_len]
        ldr r0, [fp, #table]
        bl table_lookup
        str r0, [fp, #code]

    @ if the current encoding no longer has room, move to the next one
        ldr r1, [fp, #index]
        lsl r1, r1, #2
        ldr r2, [fp, #encoding]
        ldr r0, [r2, r1]            @ encoding[index]
        mov r3, #ENCODING_WIDTH
        cmp r0, r3
        ble append                  @ if encoding[i] > width : no more room
    @ move to next encoding
        ldr r1, [fp, #index]
        add r1, r1, #1
        str r1, [fp, #index]
    @ append the code to the current encoding
    append:
        @ append the code to the encoding's code
        ldr r1, [fp, #index]
        lsl r1, r1, #2
        ldr r2, [fp, #encoding]
        ldr r0, [r2, r1]            @ encoding[i]
        ldr r1, [fp, #code]
        bl append_bits

        @ set the new code
        ldr r2, [fp, #index]
        lsl r2, r2, #2
        ldr r3, [fp, #encoding]
        str r0, [r3, r2]

        @ i++
        ldr r0, [fp, #i]
        add r0, r0, #1
        str r0, [fp, #i]
        b encode_loop
exit_eloop:
@ set the encoding length
    ldr r1, [fp, #index]
    ldr r0, [fp, #encoding_len]
    str r1, [r0]

@ return encoding
    ldr r0, [fp, #encoding]
    sub sp, fp, #4
    pop {fp, pc}
