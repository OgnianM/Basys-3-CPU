mov r4, array1
mov r5, array2
mov r6, 0xa

call dot_product

d7sd r0

;hlt

jmp main_loop


array1:
dw 0xa 1,2,3,4,5,6,7,8,9

array2:
dw 0xa 5,10, 11, 23, 22, 1

main_loop:
call listen_switches

mov r4, r0
call collatz
d7sd r0

jmp main_loop
hlt



; r4 = A, r5 = B, r6 = length
dot_product:
add r6, r4
xor r3, r3

dot_product_loop:
lda r0, r4
lda r1, r5

mul r0, r1
add r3, r0

add r4, 1
add r5, 1

cmp r4, r6
jne dot_product_loop

mov r0, r3
ret


; r4 = N
factorial:

mov r0, r4

fact_loop:
cmp r4, 2
jle factorial_done
sub r4, 1
mul r0, r4
jmp fact_loop

factorial_done:
ret


; r4 = N, r5 = M
gcd_iterative:

cmp r5, 0
je gcd_iterative_end

div r4, r5
mov r4, r5
mov r5, r1

jmp gcd_iterative

gcd_iterative_end:
mov r0, r4
ret

; r4 = N, r5 = M
gcd_recursive:

cmp r4, 0
je gcd_ret_r5

cmp r5, 0
je gcd_ret_r5

cmp r4, r5
je gcd_ret_r5

jg gcd_NGM

sub r5, r4
call gcd_recursive
ret

gcd_NGM:
sub r4, r5
call gcd_recursive
ret

gcd_ret_r4:
mov r0, r4
ret

gcd_ret_r5:
mov r0, r5
ret



; --- FIBONACCI ---

; r4 = max element
fibonacci:

mov r0, 1
mov r1, 1

fib_loop:
mov r2, r0
add r0, r1
swap r1, r2

cmp r0, r4
jl fib_loop
; last iteration exceeded max, undo last addition
sub r0, r2
ret

; --- FIBONACCI ---

; --- COLLATZ ---
; r4 = N
collatz:
cmp r4, 0
je collatz_end

mov r0, r4
xor r5, r5

collatz_loop:
cmp r0, 1
je collatz_end

add r5, 1
; check if even
mov r3, r0
and r3, 1
cmp r3, 1

je collatz_3xp1

div r0, 2 ; shr r0, 1
jmp collatz_loop

collatz_3xp1:
mul r0, 3
add r0, 1
jmp collatz_loop

collatz_end:
mov r0, r5
ret
; --- COLLATZ ---



; ---- UTILS ----


; r4 = src, r5 = dst, r6 = count
memcpy:
add r6, r4

memcpy_loop:

lda r0, r4
sta r5, r0
add r4, 1
add r5, 1

cmp r4, r6
jl memcpy_loop

ret


; r4 = dst, r5 = value, r6 = count
memset:
pop r7 ; store return address in case it gets overwritten
add r6, r4

memset_loop:
sta r4, r5
add r4, 1
cmp r4, r6
jne memset_loop

jmp r7


listen_switches:
ldsw r4
dled r4

listen_loop:
ldsw r0
cmp r0, r4
je listen_loop

ret


stall_cpu:
sub r4, 1
cmp r4, 0
jne stall_cpu
ret

