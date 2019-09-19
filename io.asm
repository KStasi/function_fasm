format ELF executable 3
entry start
segment readable writable executable

macro putstr string, len
{
    pusha
    xor edx, edx
    mov eax, 4
    mov ebx, 1
    mov ecx, string
    mov dl, [len]
    int 0x80
    popa
}

macro readstr string, len
{
    pusha
    xor edx, edx
    mov eax, 3
    mov ebx, 0
    mov ecx, string
    mov dl, [len]
    int 0x80
    popa
}

macro strlen string, len
{
    pusha
    xor eax, eax
    mov [len], al
    mov esi, string
    cld
local .go_next
.go_next:
    inc [len]
    inc esi
    lodsb
    test al, 0x0a
    jnz .go_next
    popa
}

macro itoa_base number, base, dest_str
{
    pusha
    local .push_chars
    local .pop_chars
    local .less
    local .continue
    xor   eax, eax
    xor   ebx, ebx
    mov eax, [number]
    mov ebx, [base]
    mov edi, dest_str

    test eax, eax
    jns .push_chars
    neg eax
.push_chars:
    xor edx, edx
    div ebx
    cmp dl, 10
    jb .less
    add dl, 'A' - 10
    jmp .continue
.less:
    add dl, '0'
.continue:
    push edx
    inc esi
    test eax, eax
    jnz .push_chars

    mov eax, [number]
    test eax, eax
    jns .pop_chars
    mov edx, '-'
    push edx
    inc esi

    cld

.pop_chars:
    pop eax
    stosb
    dec esi
    test esi, esi
    jnz .pop_chars
    mov eax, 0x0a
    stosb
    popa
}

macro atoi_base string, dest_number
{
    pusha
    local .get_decimal
    local .atoi_continue1
    local .switch_sign
    local .ret_error
    local .atoi_continue2
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    mov esi, string
    push esi
    cmp byte [esi], '-'
    jnz .get_decimal
    inc esi
.get_decimal:
    lodsb
    cmp al, 48
    jl .atoi_continue1
    sub al, 48
    imul ebx, 10
    jc .ret_error
    jo .ret_error
    add ebx, eax
    xor eax, eax
    jmp .get_decimal
.atoi_continue1:
    xchg ebx,eax
    pop esi
    cmp byte [esi] , '-'
    jnz .switch_sign
    neg eax
.switch_sign:
    mov [dest_number], eax
    jmp .atoi_continue2
.ret_error:
    exit_error 1
.atoi_continue2:
    popa
}

macro exit_error error_code
{
    pusha
    mov eax, 1
    mov ebx, error_code
    int 0x80
    popa
}

start:
    pusha
    readstr input_str, input_len
    atoi_base input_str, x
;    itoa_base x, base, output_str
;    putstr output_str, input_len

    readstr input_str, input_len
    atoi_base input_str, y
;    itoa_base y, base, output_str
;    putstr output_str, input_len

    xor eax, eax
    add eax, [x]
    add eax, [y]

    cmp eax, 10
    jge gr_nine

    xor eax, eax
    xor ebx, ebx
    xor edx, edx
    mov eax, [y]
    imul eax, [y]
    add ebx, 10
    sub ebx, [x]
    add ebx, [y]
    cmp ebx, 0
    jne main_continue
    exit_error 1
main_continue:
    idiv ebx

    jmp print
gr_nine:
    xor eax, eax
    mov eax, [x]
    imul eax, [y]
    cmp eax, 100
    jge otherwise
    cmp eax, 25
    jle otherwise

    xor eax, eax
    xor ebx, ebx
    xor edx, edx
    mov eax, [x]
    imul eax, [x]
    imul eax, 35
    mov ebx, [y]
    idiv ebx

    jmp print
otherwise:
    xor eax, eax
    mov eax, 1
print:
    mov [result], eax
    itoa_base result, base, output_str
    putstr output_str, input_len
    mov eax, 1
    xor ebx, ebx
    int 0x80
    popa
    ret


segment readable writeable
input_str rb 11
output_str rb 11
input_len db 11
result dd 0
base dd 10
x dd 0
y dd 0