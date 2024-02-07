@ creates a frequency table based on the given text

.cpu    cortex-a53
.fpu    neon-fp-armv8

@ constants
.equ    LOCALS, 60
.equ    ASCII_LIMIT, 1024   @ (ascii is 256 therefore 1024 bytes)

@ parameters
.equ    text, -40           @ 4 bytes - addr
.equ    table_len, -44      @ 4 bytes

@ local variables
.equ    text_len, -16       @ 4 bytes
.equ    table_index, -20    @ 4 bytes
.equ    index, -24          @ 4 bytes
.equ    freq, -28           @ 4 bytes - addr
.equ    table, -32          @ 4 bytes - addr
.equ    char, -33           @ 1 byte

@ struct Node   (17 bytes)
.equ    nodeSize, 20
.equ    nodeFreq, 0         @ 4 bytes (char)
.equ    nodeChar, 4         @ 4 bytes (int)
.equ    nodeCode, 8         @ 1 byte  (unsigned int)
.equ    nodeLeft, 12         @ 4 bytes (addr)
.equ    nodeRight, 16       @ 4 bytes (addr)

.align  2
.text
.global init_table
.type   init_table, %function

init_table:
    push {r4, fp, lr}
    add fp, sp, #8      @ fp and r4
    sub sp, sp, #LOCALS
    str r0, [fp, #text]         @ fp-40
    str r1, [fp, #table_len]    @ fp-44

@ allocate the frequency array for every possible character
    mov r0, #ASCII_LIMIT
    bl malloc
    str r0, [fp, #freq]

@ determine the length of the given text
    @ int text_len = 0
    mov r0, #0
    str r0, [fp, #text_len]
    @ int table_index = 0
    str r0, [fp, #table_index]

    @ while (text[text_len] != '\0') text_len++;
    text_counter:
        ldr r0, [fp, #text]
        ldr r1, [fp, #text_len]
        ldrb r0, [r0, r1]          @ text[text_len]
        add r1, r1, #1
        str r1, [fp, #text_len]     @ might cause a buffer overflow ;p
        cmp r0, #0
        bne text_counter

@ allocate the frequency table
    mov r0, #ASCII_LIMIT
    mov r1, #5              @ size of a node
    mul r0, r0, r1
    bl malloc
    str r0, [fp, #table]

    @ i = 0
    mov r0, #0
    str r0, [fp, #index]
    @ while
    charf_loop:
        @ if (i >= text_len) break
        ldr r0, [fp, #index]
        ldr r1, [fp, #text_len]
        cmp r0, r1
        bge exit_cfloop         @ exit loop

        @ c = text[i]
        ldr r2, [fp, #index]
        ldr r1, [fp, #text]
        ldrb r1, [r1, r2]
        strb r1, [fp, #char]
        @ if (freq[c] == 0) {
        ldrb r0, [fp, #char]
        lsl r0, r0, #2          @ align to 4 bytes
        ldr r1, [fp, #freq]
        ldr r0, [r1, r0]        @ freq[c] in r0
        cmp r0, #0
        bne else_nzero
    @ we found a NEW character, add it to the table
            @ table[table_index] = constr_node(c, 0);
            ldr r3, [fp, #table_index]
            mov r2, #nodeSize
            mul r2, r3, r2      @ offset index by 20 (size of node)
            ldr r1, [fp, #table]
            add r1, r1, r2      @ table[table_index]
            ldrb r0, [fp, #char]
            strb r0, [r1, #nodeChar]    @ table[index].char = char
            mov r0, #0
            str r0, [r1, #nodeFreq]     @ table[index].freq = 0
            @ table_index++
            ldr r0, [fp, #table_index]
            add r0, r0, #1
            str r0, [fp, #table_index]
        else_nzero:
    @ increase that characters frequency counter
        @ freq[c]++
        ldrb r1, [fp, #char]
        lsl r1, r1, #2          @ align to 4 bytes
        ldr r2, [fp, #freq]
        ldr r0, [r2, r1]
        add r0, r0, #1
        str r0, [r2, r1]
        @ i++
        ldr r0, [fp, #index]
        add r0, r0, #1
        str r0, [fp, #index]
        b charf_loop            @ loop back
    exit_cfloop:

@ set the frequency within the table
    @ i = 0
    mov r0, #0
    str r0, [fp, #index]
    @ while {
    freq_loop:
        @ if (i >= table_index) break
        ldr r0, [fp, #index]
        ldr r1, [fp, #table_index]
        cmp r0, r1
        bge exit_floop
    @ table[i].f = freq[table[i].c]
        @ c = table[i].c
        ldr r3, [fp, #index]
        mov r2, #nodeSize
        mul r2, r3, r2      @ offset index by 20 (size of node)
        ldr r1, [fp, #table]
        add r1, r1, r2      @ table[table_index]
        ldrb r0, [r1, #nodeChar]
        strb r0, [fp, #char]    @ char = table[index].char
        @ table[i].f = freq[c]
        mov r3, r1      @ table[index]
        ldrb r1, [fp, #char]
        lsl r1, r1, #2          @ align to 4 bytes
        ldr r2, [fp, #freq]
        ldr r0, [r2, r1]    @ r0 = f[c]
        str r0, [r3, #nodeFreq] @ table[index].f = f[c]
        @ i++
        ldr r0, [fp, #index]
        add r0, r0, #1
        str r0, [fp, #index]
        b freq_loop
    @ }
    exit_floop:
@ *table_len = table_index
    ldr r1, [fp, #table_len]
    ldr r0, [fp, #table_index]
    str r0, [r1]
@ free(freq)
    ldr r0, [fp, #freq]
    bl free
@ return table
    ldr r0, [fp, #table]
    sub sp, fp, #8
    pop {r4, fp, pc}

