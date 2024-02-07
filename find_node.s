@ recursively search the given binary tree to find the given character
@ returns the pathway code it took to find it

.cpu    cortex-a53
.fpu    neon-fp-armv8

.equ    LOCALS, 36

.equ    root, -8
.equ    path, -12
.equ    node, -16

@ struct Node   (20 bytes)
.equ    nodeFreq, 0         @ 4 bytes (char)
.equ    nodeChar, 4         @ 4 bytes (int)
.equ    nodeCode, 8         @ 1 byte  (unsigned int)
.equ    nodeLeft, 12        @ 4 bytes (addr)
.equ    nodeRight, 16       @ 4 bytes (addr)

.align  2
.text
.global find_node
.type   find_node, %function

find_node:
    push {fp, lr}
    add fp, sp, #4
    sub sp, sp, #LOCALS
    str r0, [fp, #root]
    strb r1, [fp, #node]
    str r2, [fp, #path]
@ first check if the given root node is null
    @ if root == null : return 0;
    cmp r0, #0
    beq fail_search
@ check if the root is the node we are searching for
    @ if root->c == node.c return path
    ldr r3, [fp, #root]
    ldrb r2, [r3, #nodeChar]   @ root->c
    ldrb r3, [fp, #node]       @ node.c
    cmp r2, r3
    bne keep_searching
    ldr r0, [fp, #path]
    b exit_search
keep_searching:
@ search the left path
    ldr r2, [fp, #root]
    ldr r3, [r2, #nodeLeft]     @ root->left
    cmp r3, #0                  @ if root->left is null
    beq skip_left               @ skip left
    mov r1, #0
    ldr r0, [fp, #path]
    bl add_bit                  @ add_bit(path, 0)
    ldrb r1, [fp, #node]
    mov r2, r0
    mov r0, r3
    bl find_node
    @ if left_path != 0 return left_path
    cmp r0, #0
    bne exit_search
skip_left:
@ search the right path
    ldr r2, [fp, #root]
    ldr r3, [r2, #nodeRight]    @ node->right
    cmp r3, #0
    beq fail_search             @ if node->right is null : end
    mov r1, #1
    ldr r0, [fp, #path]
    bl add_bit
    ldrb r1, [fp, #node]
    mov r2, r0
    mov r0, r3
    bl find_node
    @ if right_path != 0 return right_path
    cmp r0, #0
    bne exit_search
fail_search:
    @ return 0
    mov r0, #0
exit_search:
    sub sp, fp, #4
    pop {fp, pc}
