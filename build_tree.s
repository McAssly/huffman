@ builds the huffman binary tree

.cpu    cortex-a53
.fpu    neon-fp-armv8

.equ    LOCALS, 44

.equ    table, -48          @ 4 bytes
.equ    table_len, -52      @ 4 bytes

.equ    tree, -28           @ 4 bytes
.equ    index, -16          @ 4 bytes
.equ    tree_size, -20      @ 4 bytes
.equ    left, -32           @ 4 bytes
.equ    right, -36          @ 4 bytes
.equ    combined, -40       @ 4 bytes
.equ    node, -44           @ 4 bytes
.equ    insert_index, -24   @ 4 bytes

@ struct Node   (20 bytes)
.equ    nodeSize, 20
.equ    nodeFreq, 0         @ 4 bytes (char)
.equ    nodeChar, 4         @ 4 bytes (int)
.equ    nodeCode, 8         @ 4 byte  (unsigned int)
.equ    nodeLeft, 12        @ 4 bytes (addr)
.equ    nodeRight, 16       @ 4 bytes (addr)

.align  2
.text
.global build_tree
.type   build_tree, %function

build_tree:
    push {fp, lr}
    add fp, sp, #8      @ parameters
    sub sp, sp, #LOCALS
    str r0, [fp, #table]
    str r1, [fp, #table_len]

@ allocate the tree
    @ addr* tree = (addr*) malloc(sizeof(addr) * table_len)     (Node**)
    mov r0, #4
    ldr r1, [fp, #table_len]
    mul r0, r0, r1
    bl malloc       @ allocating addr*
    str r0, [fp, #tree]

@ copy the table into the tree
    @ int i = 0
    mov r0, #0
    str r0, [fp, #index]
    @ while (i < table_len) {
init_tree_loop:
        ldr r0, [fp, #index]
        ldr r1, [fp, #table_len]
        cmp r0, r1
        bge exit_itloop

        @ tree[i] = new Node
        @ make sure to remove any excess that might be there
        ldr r3, [fp, #tree]
        ldr r2, [fp, #index]
        lsl r2, r2, #2
        add r0, r3, r2
        mov r1, #0
        mov r2, #4
        bl memset

        @ construct the new node (memory)
        mov r0, #nodeSize
        bl malloc                   @ node's addr   (r0)
        mov r1, #0
        mov r2, #nodeSize
        bl memset
        ldr r3, [fp, #table]
        ldr r2, [fp, #index]
        mov r1, #nodeSize
        mul r2, r2, r1
        add r2, r3, r2              @ table[i]      (r2)
        ldr r1, [r2, #nodeFreq]     @ table[i].f    (r1)
        str r1, [r0, #nodeFreq]     @ node.f = ...
        ldrb r1, [r2, #nodeChar]    @ table[i].c    (r1)
        strb r1, [r0, #nodeChar]    @ node.c = ...

        @ store the node within the tree
        ldr r3, [fp, #tree]
        ldr r2, [fp, #index]
        lsl r2, r2, #2
        str r0, [r3, r2]            @ tree[i] = node

        @ i++
        ldr r0, [fp, #index]
        add r0, r0, #1
        str r0, [fp, #index]
        b init_tree_loop
    @ }
exit_itloop:

@ build the tree
    @ tree_size = table_len + 1
    ldr r0, [fp, #table_len]
    str r0, [fp, #tree_size]
    @ while (tree_size > 1) {
tree_loop:
        ldr r0, [fp, #tree_size]
        mov r1, #1
        cmp r0, r1
        ble exit_tloop

    @ pop the two bottom nodes
        @ left = tree[0]        @ pop
        ldr r0, [fp, #tree]
        ldr r0, [r0]
        str r0, [fp, #left]     @ lower is left
        @ right = tree[1]       @ pop
        ldr r0, [fp, #tree]
        ldr r0, [r0, #4]
        str r0, [fp, #right]    @ next is right

    @ get their combined frequencies
        @ combined = left->f + right->f
        ldr r0, [fp, #left]     @ left
        ldr r1, [r0]            @ ->f
        ldr r0, [fp, #right]    @ right
        ldr r2, [r0]            @ ->f
        add r0, r1, r2          @ combined
        str r0, [fp, #combined]

    @ create the new leaf
        @ Node* node = (Node*)malloc(sizeof(Node))      @ create a new leaf
        mov r0, #nodeSize
        bl malloc
        mov r1, #0
        mov r2, #nodeSize
        bl memset
        mov r3, r0          @ Node* (temp) in r3
        @ node->left = left
        ldr r0, [fp, #left]
        str r0, [r3, #nodeLeft]
        @ node->right = right
        ldr r0, [fp, #right]
        str r0, [r3, #nodeRight]
        @ node->f = combined
        ldr r0, [fp, #combined]
        str r0, [r3, #nodeFreq]
        str r3, [fp, #node]

    @ shift the tree array to the left to properly pop
        @ for i in range of tree_size       shift the queue left by 2 (popped top twice)
        mov r0, #0
        str r0, [fp, #index]
    shift_loop:
            ldr r0, [fp, #index]
            ldr r1, [fp, #tree_size]
            sub r1, r1, #2              @ tree_size - 2
            cmp r0, r1
            bge exit_sloop

            @ tree[i - 2] = tree[i]
            @ memset tree[i] to 0 : remove it
            ldr r3, [fp, #index]
            lsl r3, r3, #2
            ldr r0, [fp, #tree]
            add r0, r0, r3       @ tree[i] (not dereferenced)
            mov r1, #0           @ set to 0
            mov r2, #4           @ 4 byte address
            bl memset
            @ memset returns the next address in alignment in r3, so we will abuse that
            @ since its i - 2, not i - 1 and r3 return i + 1, we need to move one more forward
            add r3, r3, #4
            ldr r2, [r3]         @ need to dereference the pointer to the pointer
            str r2, [r0]         @ memset returns the original address in r0 so we will store it there
            @ we need to then clear the old position (r3)
            mov r0, r3
            mov r1, #0
            mov r2, #4
            bl memset

            ldr r0, [fp, #index]
            add r0, r0, #1
            str r0, [fp, #index]
            b shift_loop
    exit_sloop:

        @ tree_size -= 2        @ we removed two elements from the front
        ldr r0, [fp, #tree_size]
        sub r0, r0, #2
        str r0, [fp, #tree_size]

    @ find the index to insert the new leaf
        @ insert_index = 0      @ we now need to insert the new node into the queue but in order of frequencies
                                @ this is so we don't need to sort it, we'll just do it at the same time
                                @ we need to first find the index where we'll insert the node
        mov r0, #0
        str r0, [fp, #insert_index]
        b start_insertion
    insert_loop:                         @ REVIEW THIS
            @ insert_index++
            ldr r0, [fp, #insert_index]
            add r0, r0, #1
            str r0, [fp, #insert_index]
            start_insertion:
            @ if (insert_index >= tree_size) break
            ldr r0, [fp, #insert_index]
            ldr r1, [fp, #tree_size]
            cmp r0, r1
            bge exit_insertion
            @ if (tree[insert_index]->f < combined) continue
            ldr r1, [fp, #combined]
            ldr r2, [fp, #tree]
            lsl r0, r0, #2
            add r0, r2, r0
            ldr r0, [r0]
            ldr r0, [r0, #nodeFreq]
            cmp r0, r1
            blt insert_loop
    exit_insertion:

    @ move the tree array to fit the new leaf for insertion
        @ shift all the nodes to the right from the insert position
        @ i = tree_size
        ldr r0, [fp, #tree_size]
        str r0, [fp, #index]
    shift_r_loop:                               @ review this
            @ if i <= insert_index: break
            ldr r0, [fp, #index]
            ldr r1, [fp, #insert_index]
            cmp r0, r1
            ble exit_srloop

            @ tree[i] = tree[i - 1]
            @ employing the same strategy when shifting left, but instead in reverse to shift right
            @ memset tree[i] to remove it
            ldr r3, [fp, #index]
            lsl r3, r3, #2
            ldr r0, [fp, #tree]
            add r0, r0, r3      @ tree[i]
            mov r1, #0
            mov r2, #4
            bl memset           @ tree[i] stored in r0 : tree[i+1] stored in r3
            @ we need to move tree[i - 1] into tree[i], so we will shift r3 back by 2 indexes
            sub r3, r3, #8      @ 2 * 4 is 8
            ldr r2, [r3]        @ we need to derefernece it
            @ finally store this address in tree[i]
            str r2, [r0]
            mov r0, r3
            mov r1, #0
            mov r2, #4
            bl memset

            @ i--
            ldr r0, [fp, #index]
            sub r0, r0, #1
            str r0, [fp, #index]
            b shift_r_loop
    exit_srloop:

    @ finally insert the new leaf
        @ tree[insert_index] = node
        ldr r0, [fp, #insert_index]
        lsl r0, r0, #2              @ in_i
        ldr r1, [fp, #tree]         @ tree
        ldr r2, [fp, #node]         @ node
        str r2, [r1, r0]            @ tree[in_i] = node

        @ tree_size++
        ldr r0, [fp, #tree_size]
        add r0, r0, #1
        str r0, [fp, #tree_size]
        b tree_loop
    @ }
exit_tloop:

@ return tree;
    ldr r0, [fp, #tree]
    ldr r0, [r0]        @ return just the top of the tree, not the whole array
    sub sp, fp, #8
    pop {fp, pc}
