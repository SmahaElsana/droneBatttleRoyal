
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

global createTarget, target_X,target_Y,targetFunc,xDifference,yDifference
extern seed, generateNum,maxnumber,X100, DRONES,d,msg2,staticCos,resume,strFRMT,printf,hello,X0
section .bss


section .data
;; sscanf(input,format, destination );
toInt: db "%d",0 ;; sscanf int format
target_X: dd 0
target_Y: dd 0

xDifference: dd 0
yDifference: dd 0
distance: dd 0


section .rodata

section .text
    ; align 16
     global main
    extern printf
    extern sscanf
    extern scanf
    ; extern seed

; main:

targetFunc:
    pushad
    call createTarget
    popad
    mov ebx,[staticCos] ;;ebx points to scheduler co-routine
	call resume
	jmp targetFunc


createTarget: ;; function which generates x y coordinates

    push ebp
    mov ebp,esp
    pushad

    pushad
    call generateNum
    popad
    fild dword [seed] ; st1 = randomized
    fild dword [maxnumber] ;st0 = 65535
    fdiv ; st0 = randomized/65535 
    fild dword [X100]
    fmul
    fstp dword [target_X]

    pushad
    call generateNum
    popad
    fild dword [seed] ; st1 = randomized
    fild dword [maxnumber] ;st0 = 65535
    fdiv ; st0 = randomized/65535 
    fild dword [X100]
    fmul
    fstp dword [target_Y]

    call updateTargetY
    call updateTargetX


    popad
    mov esp,ebp
    pop ebp
    ret     

updateTargetX:
    push ebp
    mov ebp,esp
    pushad

    finit

    fild dword[X100]
    fld dword[target_X]
    fcomi
    jae xTarAbv

    fild dword[X0]
    fld dword[target_X]
    fcomi
    jb xTarBlw

    jmp dnUbdTarX

    xTarAbv:
    fld dword[target_X]
    fild dword[X100]
    fsub
    fstp dword[target_X]
    jmp dnUbdTarX

    xTarBlw:
    fld dword[target_X]
    fild dword[X100]
    fadd
    fstp dword[target_X]

    dnUbdTarX:
    popad
    mov esp,ebp
    pop ebp
    ret  



updateTargetY:
    push ebp
    mov ebp,esp
    pushad

    finit

    fild dword[X100]
    fld dword[target_Y]
    fcomi
    jae yTarAbv

    fild dword[X0]
    fld dword[target_Y]
    fcomi
    jb yTarBlw

    jmp dnUbdTarY

    yTarAbv:
    fld dword[target_Y]
    fild dword[X100]
    fsub
    fstp dword[target_Y]
    jmp dnUbdTarY

    yTarBlw:
    fld dword[target_Y]
    fild dword[X100]
    fadd
    fstp dword[target_Y]

    dnUbdTarY:
    popad
    mov esp,ebp
    pop ebp
    ret  

mayDestroy:
    push ebp
	mov ebp,esp
	mov ebx,[ebp+8]

    mov esi,[DRONES] ;;esi points to drones array
    mov eax,[esi+ 4*ebx] ;;eax points to drone struct

    fld dword[eax+4] ;;loading the drone's x
    fld dword[target_X] 
    fsub 
    fst dword[xDifference]
    fld dword[xDifference]
    fmul

    fld dword[eax+8] ;; loading the drone's y
    fld dword[target_Y]
    fsub
    fst dword[yDifference]
    fld dword[yDifference]
    fmul

    fadd
    fsqrt
    ; fstp dword[distance]
    fld dword[d] ;;given max distance
    fcomi
    ja dontDestroy ;; if the distance is greater than d then jump to end and dont destroy
    mov edx,[eax+20]
    inc edx ;;incerement nummber of destroyed targets for the calling drone
    mov dword[eax+20],edx
    ; call createTarget ;; creating new target

    dontDestroy:
    mov esp,ebp
    pop ebp
    ret

