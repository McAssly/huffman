.cpu    cortex-a53
.fpu    neon-fp-armv8

@ constants
.equ    LOCALS, 56
.equ    SPACER, 0           @ adds spacers when printing the encoding
.equ    newline, 10

@ local variables
.equ    text, -8            @ 4 bytes (char*)
.equ    table_len, -12      @ 4 bytes (int)
.equ    table, -16          @ 4 bytes (Node*)
.equ    tree, -20           @ 4 bytes (Node*)
.equ    index, -24          @ 4 bytes (int)
.equ    code, -28           @ 4 bytes (int)
.equ    encoding_len, -32   @ 4 bytes (int)
.equ    encoding, -36       @ 4 bytes (unsigned int*)
.equ    decoded, -40        @ 4 bytes (char*)

@ struct Node   (20 bytes)
.equ    nodeSize, 20
.equ    nodeFreq, 0         @ 4 bytes (char)
.equ    nodeChar, 4         @ 4 bytes (int)
.equ    nodeCode, 8         @ 1 byte  (unsigned int)
.equ    nodeLeft, 12        @ 4 bytes (addr)
.equ    nodeRight, 16       @ 4 bytes (addr)

.data
sample:         .asciz  "sample.txt"
number:         .asciz  "%u"
read_text:      .asciz  "read sample: \n"
encoded_msg:    .asciz  "encoded: \n"
decoded_msg:    .asciz  "decoded: \n"

.align  2
.text
.global main
.type   main, %function

main:
    push {fp, lr}
    add fp, sp, #4
    sub sp, sp, #LOCALS

    @ text = read_file("sample.txt")
    ldr r0, =sample
    bl read_file
    str r0, [fp, #text]

    @ printf(text)
    ldr r0, =read_text
    bl printf
    ldr r0, [fp, #text]
    bl printf
    @ printf('\n')
    mov r0, #newline    @ 10
    bl putchar

@ create the frequency table
    mov r0, #0
    str r0, [fp, #table_len]
    add r1, fp, #table_len      @ &table_len
    ldr r0, [fp, #text]         @ text
    bl init_table
    str r0, [fp, #table]

@ create the huffman binary tree
    ldr r1, [fp, #table_len]    @ table_len
    ldr r0, [fp, #table]        @ table
    bl build_tree
    str r0, [fp, #tree]

@ determine the code for each character
    @ i = 0
    mov r0, #0
    str r0, [fp, #index]
    @ while (1) {
tc_loop:
        @ if i >= table_len break
        ldr r0, [fp, #index]        @ index
        ldr r1, [fp, #table_len]    @ table_len
        cmp r0, r1
        bge exit_tcloop

        @ code = find_node(tree, table[i].c, 1)
        mov r2, #1              @ 1
        ldr r0, [fp, #tree]     @ tree
        ldr r1, [fp, #index]    @ need to offset index
        mov r3, #nodeSize
        mul r1, r1, r3
        ldr r3, [fp, #table]    @ table
        add r3, r3, r1
        ldrb r1, [r3, #nodeChar]@ table[i]->c
        bl find_node
        str r0, [fp, #code]
        @ table[i].code = code;
        ldr r2, [fp, #index]    @ index
        mov r3, #nodeSize
        mul r3, r2, r3
        ldr r2, [fp, #table]
        add r2, r2, r3          @ table[i]
        ldr r3, [fp, #code]     @ code
        str r3, [r2, #nodeCode] @ table[i].code = code

        @ i++
        ldr r0, [fp, #index]
        add r0, r0, #1
        str r0, [fp, #index]
        b tc_loop
    @ }
exit_tcloop:

@ encode the message using the frequency table (stores the tree code)
    @ encoding_len = 0
    mov r0, #0
    str r0, [fp, #encoding_len]
    @ encoding = encode(table, table_len, text, &encoding_len)
    ldr r1, [fp, #table_len]    @ table_len
    add r3, fp, #encoding_len    @ &encoding_len
    ldr r2, [fp, #text]         @ text
    ldr r0, [fp, #table]        @ table
    bl encode
    str r0, [fp, #encoding]

@ print out the encoded message
    ldr r0, =encoded_msg
    bl printf
    @ i = 0
    mov r0, #0
    str r0, [fp, #index]
    @ while (1) {
e_loop:
        ldr r0, [fp, #index]
        ldr r1, [fp, #encoding_len]
        cmp r0, r1
        bge exit_eloop
    @ print out the current encoding
        @ binary_out(encoding[i])
        ldr r0, [fp, #index]
        lsl r0, r0, #2
        ldr r1, [fp, #encoding]
        ldr r0, [r1, r0]        @ encoding[i]
        bl binary_out
    @    mov r1, r0
    @    ldr r0, =number
    @    bl printf
    @ spacer
        mov r0, #SPACER
        cmp r0, #0
        beq skip_spacer
            mov r0, #32
            bl putchar
        skip_spacer:
    @ i++
        ldr r0, [fp, #index]
        add r0, r0, #1
        str r0, [fp, #index]
        b e_loop
exit_eloop:
    @ printf('\n') x2
    mov r0, #newline
    bl putchar
    mov r0, #newline
    bl putchar

@ decode the message using the tree, and print out the result
    ldr r2, [fp, #encoding_len]
    ldr r1, [fp, #encoding]
    ldr r0, [fp, #tree]
    bl decode
    str r0, [fp, #decoded]
@ print out the decoded message
    ldr r0, =decoded_msg
    bl printf
    ldr r0, [fp, #decoded]
    bl printf
    @ printf('\n')
    mov r0, #newline
    bl putchar

@ free used memory
    ldr r0, [fp, #table]
    bl free
    ldr r0, [fp, #tree]
    bl free
    ldr r0, [fp, #encoding]
    bl free
    ldr r0, [fp, #text]
    bl free
    @ return 0;
    mov r0, #0
@ exit program
    sub sp, fp, #4
    pop {fp, pc}
