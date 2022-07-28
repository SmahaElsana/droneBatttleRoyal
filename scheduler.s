

%macro PRINTWINER 1
    pushad
    pushfd
    push %1
    push winnerStr
    call printf
    add esp,8
    popfd
    popad
%endmacro

%macro PRINTHELLO 0
    pushad
    pushfd
    push strFRMT
    push hello
    call printf
    add esp,8
    popfd
    popad
%endmacro


%macro PRINTINT 1
pushad
pushfd
push %1
push intF
call printf
add esp, 8
popfd
popad
%endmacro


global schedulerFunc, currID,M

; section .bss
; SPMAIN: resd 1
; CURR: resd 1
; SPT: resd 1
extern DRONES, activatedDrones,CORS,N,R,K, staticCos,resume,strFRMT,hello,printf,strFRMT,end_Sched

section .data

winnerStr: db "WINNER   %d ",10,0
winnerId: dd 2
intF: db "%d",10,0



round: dd 0
turns: dd 0

M: dd 1000 ;; holds the mminimum number of targets

currID: dd 0
flagOffset  equ 24
targetOffset  equ 20

section .text

mov edi, 0
schedulerFunc:
   

    mov edi, dword[currID]
    mov esi,[DRONES]
    mov ebx,[CORS]
    
    mov ebx,[ebx+4*edi] ;; ebx is the current coroutine
    mov edx,[esi + edi*4];;edx holds the pointer to a drone struct number edi
    mov edx,[edx+flagOffset] ;; flag offset holds activation flag
    cmp edx,0 ;; if the flag is 1 then the drone is off
    jne notActive

    call resume ;; resume to ebx-> cuurent co-routine 
    inc dword[turns]

notActive:
    mov eax,[turns]
    cmp eax, dword[K]
    jl noPrint
    mov eax,-1
    mov dword[turns],eax

    mov ebx,[staticCos+4] ;;points to printer co-routine
    call resume

noPrint:
    ;check if turns is 0 and rounds is 0
    mov eax,dword[turns]
    cmp eax,0
    jne noEliminate

    mov eax,0
    cmp eax, dword[round]
    jne noEliminate
    ;;else eleminate
    call findMinTargets
    call  eliminate
    
noEliminate:
    inc edi
    mov dword[currID],edi
    cmp edi,[N]
    jl notLastDrn
    mov edi,0
    mov [currID],edi
    inc dword[round]
    ; mov dword[turns],0

notLastDrn:
    mov ecx, dword[round]
    cmp ecx, dword[R] ;;comparing cuurent rounds with R
    jl noRRoundsYet

    mov ecx,0
    mov dword[round],ecx ;; setting rounds to 0 which means we reached R rounds

noRRoundsYet:
    mov ecx, dword[activatedDrones]
    cmp ecx,1
    jne p5
    ; ;winner found
    ; mov ebx,[staticCos+4] ;;points to printer co-routine
    ; call resume

    call findWinnerId
    PRINTWINER dword[winnerId] ;;print winner
    call end_Sched ;;return to main or exit
p5:
    jmp schedulerFunc


findWinnerId:
    push ebp
    mov ebp,esp
    pushad

    mov ebx,[DRONES]
    mov ecx,[N]
    mov esi,0
    
loopDrones:
    mov edx,[ebx + 4*esi] ;; edx contains the drone
    mov eax, [edx + 24] ;; eax contains the drone's flag
    cmp eax,0
    jne keeplooping
    mov dword[winnerId],esi
keeplooping:
    inc esi
    loop loopDrones,ecx
foundWinner:
    ; mov [winnerId],esi
    popad
    mov esp,ebp
    pop ebp
    ret

;; ^^ findMinTargets 
findMinTargets:
;;minimum targets destroyed by all the drone
    push ebp
    mov ebp,esp

    pushad
    ;resetting the M -> minimum targets destroyed
    mov edi ,1000
    mov dword[M],edi
   
    mov edx,0
    mov esi,[DRONES]
    mov ecx, dword[N]
findMin:
    mov eax,[esi+4*edx]
    mov ebx, [eax + flagOffset]
    mov edi ,[eax + targetOffset]
    cmp ebx,0
    jne next
    ;; active -> then try find min
    cmp edi,dword[M]
    ja next
    ;; the current drone's num of targets is less than M
    mov dword[M],edi
next:
    inc edx
    loop findMin,ecx

    popad
    mov esp,ebp
    pop ebp
    ret

    eliminate:
    push ebp
    mov ebp,esp

    pushad

    mov edx,0
    mov esi,[DRONES]
    mov ecx, dword[N]
    ; dec dword[activatedDrones]
    
    findMinDrone:
        mov eax,[esi+4*edx]
        mov ebx, [eax + flagOffset]
        mov edi ,[eax + targetOffset]
        cmp ebx,0 ;; che drone is on
        jne nextDrone
        ;; active -> then try find min
        cmp edi,dword[M]
        jne nextDrone
        ;; eleminate the current drone
        mov edi,1 ;; turn off the activation flag
        mov dword[eax + flagOffset],edi
        dec dword[activatedDrones]
        jmp getOut ;; found a drone to eleminate then break the loop

        nextDrone:
        inc edx
        loop findMinDrone,ecx

    popad
    getOut:
    mov esp,ebp
    pop ebp
    ret


