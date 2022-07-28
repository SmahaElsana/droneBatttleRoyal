
%macro newLine 0
        pushad
        pushfd
        push new_line
        call printf
        add esp ,4
        popfd
        popad
%endmacro      


%macro PRINTINT 1
pushad
pushfd
push %1
push intFRMT
call printf
add esp, 8
popfd
popad
%endmacro

%macro PRINTID 1
pushad
pushfd
push %1
push idFRMT
call printf
add esp, 8
popfd
popad
%endmacro

%macro PRINTFLT 1
    pushad
    fld dword %1
    sub esp,8
    fstp qword [esp]
    push fltFRMT
    call printf
    add esp,12
    popad
%endmacro

%macro print_format 2
       pushad
       pushfd
       push %2
       push %1
       call printf
       add esp , 8
       popfd
       popad
%endmacro

global printBoard
extern staticCos, target_X,target_Y,N,DRONES,resume,printf,strFRMT,hello,printflt

section .rodata

string_format:    db   "%s",10,0
idFRMT: db "[ %d ] ",0
intFRMT: db "%d ",10,0
fltFRMT: db "%.2f ",0
new_line:           db   10,0

section .text

printBoard:
PRINTFLT dword[target_X]
PRINTFLT dword[target_Y]
newLine

mov ecx,[N]
mov ebx, 0

 allDrns:
        pushad
        mov esi,[DRONES]
        push dword [esi+4*ebx] ;; pushing a pointer to a drone
        call printDrn
        add esp, 4
        popad
        inc ebx
        loop allDrns, ecx
        newLine ;;jumping a line
mov ebx, [staticCos] ;; the first co in the staticCos is the scheduler
call resume
jmp printBoard


printDrn:
    push ebp
    mov ebp,esp
    mov ecx,[ebp+8] ;; ecx points to drone
    PRINTID dword[ecx]
    PRINTFLT [ecx + 4]
    PRINTFLT [ecx + 8]
    PRINTFLT [ecx + 12]
    PRINTFLT [ecx + 16]
    PRINTINT dword[ecx +20] ;; destroyed targets
    newLine

    mov esp,ebp
    pop ebp
    ret     


