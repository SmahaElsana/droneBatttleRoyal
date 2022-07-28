

%macro PRINTINT 1
pushad
pushfd
push %1
push decFRMT
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
    push printflt
    call printf
    add esp,12
    popad
%endmacro


global droneFunc

extern moveDrone ,currID, DRONES, X180,X120,X100,X10,X20,X60,X360,seed,maxnumber, target_X
extern target_Y, staticCos,resume,X0,generateNum,xDifference,yDifference,d,printf,printflt,createTarget

section .data

xOffset  equ 4
yOffset  equ 8

newAngle: dd 0
newSpeed: dd 0

tmpAngle: dd 0
tmpSpeed: dd 0
tmpX: dd 0
tmpY: dd 0

flagDestroy: dd 0
decFRMT: db "%d",10,0

tmpMe: dd 0
tmpQword: dq 0



section .text

droneFunc:
 pushad
 call genDirection ;; newAngle holds the generated angle
 popad
 pushad
 call genSpeed ;; newSpeed holds the generated speed
 popad
 pushad
 call moveDrone
 popad
 pushad
 call updateAngle
 popad
 pushad
 call updateSpeed
 popad

 

alwaysDestroy: 
    pushad
    call mayDestroy
    popad
    mov eax,[flagDestroy]
    cmp eax,1 ;;1 -> can destroy
    ; jne backtoSched
    jne keepMoving
    ; pushad
    call Destroy
    ; popad
    ;resume Target co-routine
    mov ebx, [staticCos+8] ;;ebx points to target cor
    call resume
    ; call createTarget

keepMoving:
    call genDirection
    call genSpeed
    call moveDrone
    call updateAngle
    call updateSpeed

    mov ebx,[staticCos] ;; resuming to scheduler
    call resume
    
    jmp alwaysDestroy


; backtoSched:
; mov ebx,[staticCos] ;; resuming to scheduler
; call resume
; jmp alwaysDestroy


moveDrone:
    push ebp
    mov ebp,esp
    pushad
    call updateX
    call updateY
    popad
    mov esp,ebp
    pop ebp
    ret     


updateX:
    push ebp
    mov ebp,esp
    pushad

    mov edx, [currID]
    mov esi,[DRONES]
    mov eax,[esi+4*edx]

    finit
    ;;CALCULATING NEW X
    fld dword[eax+12] ;;loading the angle
    fldpi
    fmul
    fild dword[X180]
    fdiv ;;calculated rads
    fcos

    fld dword[eax+16] ;; speed
    fmul
    fld dword[eax+4] ;; x mikorei
    fadd
    
    fst dword[tmpX]

    fld dword[tmpX]

    fstp dword[eax+4]

    fild dword[X100]
    fld dword[tmpX]
    fcomi
    jae Xabove

    fild dword[X0]
    fld dword[tmpX]
    fcomi
    jb Xbelow

    jmp doneUpdX

Xabove:  
    fld dword[tmpX]
    fild dword[X100]
    fsub
    fstp dword[eax + xOffset]
    jmp doneUpdX

Xbelow:
    fld dword[tmpX]
    fild dword[X100]
    fadd
    fstp dword[eax+xOffset]

doneUpdX:
    popad
    mov esp,ebp
    pop ebp
    ret   



updateY:
    push ebp
    mov ebp,esp
    pushad

    mov edx, [currID]
    mov esi,[DRONES]
    mov eax,[esi+4*edx]
    

    ;;CALCULATING NEW Y
    finit
    fld dword[eax+12] ;;loading the angle
    fldpi
    fmul
    fild dword[X180]
    fdiv
    fsin

    fld dword[eax+16];;speed
    fmul
    fld dword[eax+8];;y
    fadd
    fst dword[tmpY]
    fstp dword[eax+8]

    fild dword[X100]
    fld dword[tmpY]
    fcomi
    jae Yabove

    fild dword[X0]
    fld dword[tmpY]
    fcomi
    jb Ybelow

    jmp doneUpdY

Yabove:
    fld dword[tmpY]
    fild dword[X100]
    fsub
    fstp dword[eax + yOffset]
    jmp doneUpdY

Ybelow:
    fld dword[tmpY]
    fild dword[X100]
    fadd
    fstp dword [eax+yOffset]

doneUpdY:
   
    popad
    mov esp,ebp
    pop ebp
    ret   


genDirection:
;; new angle should be [-60,60]
    push ebp
    mov ebp,esp
    pushad
    finit

    call generateNum

    ; fild dword[seed]
    fild dword[seed]
    fild dword[maxnumber]
    fdiv
    fild dword[X120]
    fmul
    fild dword[X60]
    fsub
    fstp dword[newAngle]
    

    popad
    mov esp,ebp
    pop ebp
    ret  

updateAngle:
    push ebp
    mov ebp,esp
    pushad

    finit
    mov edx, [currID]
    mov esi,[DRONES]
    mov eax,[esi+4*edx]
   
    fld dword[eax+12]
    fld dword[newAngle]
    fadd
    fst dword[tmpAngle]

    fild dword[X360]
    fld dword[tmpAngle]
    fcomi
    jae above360

    fild dword[X0]
    fld dword[tmpAngle]
    fcomi
    jb under0

    jmp didntchange

above360:
    fld dword[tmpAngle]
    fild dword[X360]
    fsub
    fstp dword[eax+12]
    jmp doneAngle

under0:
    fld dword[tmpAngle]
    fild dword[X360]
    fadd
    fstp dword[eax+12]
    jmp doneAngle

didntchange:
    fld dword[tmpAngle]
    fstp dword[eax+12]

doneAngle:
    popad
    mov esp,ebp
    pop ebp
    ret  


    genSpeed:
;; new speed should be [-10,10]
    push ebp
    mov ebp,esp
    finit
    pushad
    call generateNum
    popad
    
    
    fild dword[seed]
    fild dword[maxnumber]
    fdiv 
    fild dword[X20]
    fmul
    fild dword[X10]
    fsub
    fstp dword[newSpeed]
    
    mov esp,ebp
    pop ebp
    ret  

updateSpeed:
    push ebp
    mov ebp,esp

    mov edx, [currID]
    mov esi,[DRONES]
    mov eax,[esi+4*edx]
   
    finit
    fld dword[eax+16]
    fld dword[newSpeed]
    fadd
    fst dword[tmpSpeed]
    
    fild dword[X100]
    fld dword[tmpSpeed]
    fcomi 
    jae above100

    fild dword[X0]
    fld dword[tmpSpeed]
    fcomi 
    jb speedUnder0
    fld dword[tmpSpeed]
    fstp dword[eax+16]
    
    jmp doneSpeed

speedUnder0:
    ;;the x87 already contains zero on top of the stack
    fild dword[X0]
    fstp dword[eax+16]
    jmp doneSpeed

above100:
    ;;the x87 already contains 100 on top of the stack
    fild dword[X100]
    fstp dword[eax+16]
       
doneSpeed:
    mov esp,ebp
    pop ebp
    ret  



mayDestroy:
    push ebp
	mov ebp,esp
    pushad

    finit

	; mov ebx,[ebp+8]
    mov edi,0 ;;restarting flag destroy
    mov dword[flagDestroy],edi

    mov ebx,dword[currID]
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
    jb cantDestroy ;; if the distance is greater than d then jump to end and dont destroy

    mov edi,1
    mov dword[flagDestroy],edi ;;make the destroy flag =1 which means can destroy

    cantDestroy:
    popad
    mov esp,ebp
    pop ebp
    ret



Destroy:
    push ebp
	mov ebp,esp
	; mov ebx,[ebp+8]
    mov ebx,dword[currID]

    mov esi,[DRONES] ;;esi points to drones array
    mov eax,[esi+ 4*ebx] ;;eax points to drone struct

    ; fld dword[eax+4] ;;loading the drone's x
    ; fld dword[target_X] 
    ; fsub 
    ; fst dword[xDifference]
    ; fld dword[xDifference]
    ; fmul

    ; fld dword[eax+8] ;; loading the drone's y
    ; fld dword[target_Y]
    ; fsub
    ; fst dword[yDifference]
    ; fld dword[yDifference]
    ; fmul

    ; fadd
    ; fsqrt
    ; ; fstp dword[distance]
    ; fld dword[d] ;;given max distance
    ; fcomi
    ; ja dontDestroy ;; if the distance is greater than d then jump to end and dont destroy

    mov edx,[eax+20]
    inc edx ;;incerement nummber of destroyed targets for the calling drone
    mov dword[eax+20],edx
    mov dword[flagDestroy],0

    ; call createTarget ;; creating new target ;;should resume the target co-routine

    ; dontDestroy: 
    mov esp,ebp
    pop ebp
    ret

