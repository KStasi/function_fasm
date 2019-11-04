format ELF executable 3
entry start
segment readable writable executable
macro read_str str_ptr, len
{
    pusha
    xor edx, edx
    mov eax, 3 ; #define __NR_read 3
    mov ebx, 0 ; fd
    mov ecx, str_ptr ; buffer_ptr
    mov dx, len ; length
    int 0x80 ; sys_cal
    popa
}

macro put_str str_ptr, len
{
    pusha
    xor edx, edx
    mov eax, 4 ; #define __NR_write 4
    mov ebx, 1 ; fd
    mov ecx, str_ptr ; buffer_ptr
    mov dx, len ; length
    int 0x80 ; sys_call
    popa
}

macro str_len str_ptr, len_ptr {
    pusha
    local .continue1
    local .loop1
    xor eax, eax ; length = 0
    lea edx, [str_ptr] ; point to first element
    jmp .continue1 ; skip iterator
    .loop1:
        inc edx ; next element
        inc eax ; increment length
    .continue1:
        cmp byte[edx], 0 ; check if pointed element is \0
        jnz .loop1 ; if not eq go to next
    mov [len_ptr], ax ; store len
    popa
}

macro exit code
{
    pusha
    mov eax, 1 ; #define __NR_exit 1
    mov ebx, code ; code
    int 0x80 ; sys_call
    popa
}


macro itoa num, str_ptr
{
    pusha
    local .push_chars
    local .pop_chars
    local .less
    local .continue
    xor   eax, eax
    xor   ebx, ebx
    xor   ecx, ecx
    mov ax, num ; copy value
    mov bx, 10 ; store snum base
    lea edi, [str_ptr] ; point to first element 

    test ax, ax ; check sign
    jns .push_chars ; if positive go to chars representation; test SF
    neg ax ; else switcch sign

    .push_chars:
        xor edx, edx ; clear dividend; note: num = [s1][s2][s3][s4] thus num / base = [s1][s2][s3] (r. [s4])
        div bx ; DX = 0, AX = num, BX = 10 => DX:AX / BX => AX = [s1][s2][s3], DX = [s4], BX = 10
        add dx, "0" ; convert number to symbol 

    .continue:
        push dx ; store in stack
        inc cx ; increment counter 
        test ax, ax ; logical and
        jnz .push_chars ; if all bits of number are not zeros, read next symbol; test ZF 

        mov ax, num ; copy value
        test ax, ax ; logical and 
        jns .pop_chars ; if number is  not negative, extract it's string value; test SF
    
    mov dx, '-' ; else store sign
    push dx ; push sign to stack
    inc cx ; increment counter

    cld ; reset DF

    .pop_chars:
        pop ax ; get symbol
        stosb ; load AL to ES:EDI; increment EDI
        dec cx ; increment counter
        test cx, cx ; logical and
        jnz .pop_chars ; if all bits of number are not zeros, read next symbol; test ZF
    
    mov ax, 0x0a ; add \n 
    stosb ; load AL to ES:EDI; increment EDI
    popa
}

macro atoi str_ptr, num_ptr
{
    pusha
    local .get_decimal
    local .continue1
    local .store_num
    local .ret_error
    local .continue2
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    cld ; set DF = 0
    mov esi, str_ptr ; point to first symbol
    cmp byte [esi], '-' ; check if negative
    jne .get_decimal ; if ZF = 0 start read string
    inc esi ; else skip one symbol
    .get_decimal:
        lodsb ; load DS:ESI to AL; increment ESI
        cmp al, 48 ; check if symbol is number
        jl .continue1 ; else stop reading num
        cmp al, 57 ; check if symbol is number
        jg .continue1 ; else stop reading num
        sub al, 48 ; convert to number
        imul bx, 10 ; shift <-
        jo .ret_error ; if OF = 1 throw error
        add bx, ax ; add extracted symbol
        jo .ret_error ; if OF = 1 throw error
        xor eax, eax
        jmp .get_decimal ; go to next symbol
    .continue1:
        xchg bx, ax ; exchnge registre's interiors
        mov esi, str_ptr ; point to first symbol
        cmp byte [esi] , '-' ; check if num is negative
        jnz .store_num ; continue if ZF=0
        neg ax ; else switch sign
    .store_num:
        mov [num_ptr], ax ; store num
        jmp .continue2 ; go to end
    .ret_error: 
        str_len overflow_str, len ; get string length
        put_str overflow_str, [len] ; print string
        exit 1 ; reserved for error
    .continue2:
        popa
}

macro print_num element {
    pusha
    zero_str element_str, 6 ; clear string
    zero_str element_str_out, 6 ; clear string
    itoa element, element_str_out ; convert number to string
    str_len element_str_out, len ; calculate string length 
    put_str element_str_out, [len] ; write string to fd=1
    zero_str element_str, 6 ; clear string
    zero_str element_str_out, 6 ; clear string
    popa
}

macro zero_str str_ptr, len {
    pusha
    local .continue1
    local .loop1
    xor ecx, ecx
    lea edi, [str_ptr] ; point to first element
    jmp .continue1 ; skip iterator
    .loop1:
        inc edi ; next symbol
        inc ecx ; increment counter
    .continue1:
        mov byte[edi], 0 ; put zero
        cmp cx, len ; compsre counters 
        jnz .loop1 ; next symbol, until counter != length
    popa
}

start:
    pusha
    str_len instr_str, len ; get string length
    put_str instr_str, [len] ; print string

    zero_str input_str, 6 ; clean string
    read_str input_str, 11
    atoi input_str, x

    zero_str input_str, 6 ; clean string
    read_str input_str, 11
    atoi input_str, y

    xor eax, eax
    add ax, [x]
    add ax, [y]

    cmp ax, 10
    jge .gr_nine

    xor eax, eax
    xor ebx, ebx
    xor edx, edx
    mov ax, [y]
    imul ax, [y]
    add bx, 10
    sub bx, [x]
    add bx, [y]
    cmp bx, 0
    jne .main_continue
    str_len overflow_str, len ; get string length
    put_str overflow_str, [len] ; print string
    exit 1 ; reserved for error

.main_continue:
    idiv bx

    jmp .print
.gr_nine:
    xor eax, eax
    mov ax, [x]
    imul ax, [y]
    cmp ax, 100
    jge .otherwise
    cmp ax, 25
    jle .otherwise

    xor eax, eax
    xor ebx, ebx
    xor edx, edx
    mov ax, [x]
    imul ax, [x]
    imul ax, 35
    mov bx, [y]
    idiv bx

    jmp .print
.otherwise:
    xor eax, eax
    mov ax, 1
.print:
    mov [result], ax
    itoa [result], output_str

    str_len output_str, len ; get string length
    put_str output_str, [len] ; print string
    exit 0

    popa
    ret


segment readable writeable
instr_str db "Put two numbers:", 0x0a, 0x00
result_str db "Min element:", 0x0a, 0x00
overflow_str db "Number overflow.", 0x0a, 0x00
element_str rb 6
element_str_out rb 6
array rw 100
len dw 0
el dw 0
input_str rb 11
output_str rb 11
result dw 0
x dw 0
y dw 0