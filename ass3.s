CODEP equ 0
SPP equ 4


%macro printStr 1
pushad
pushfd
push %1
push strFRMT
call printf
add esp, 8
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

global DRONES,generateNum,X100,maxnumber,d,msg2, staticCos, activatedDrones, CORS,N,R,K,resume,X0,X180,X120,X60,X360,X20,X10,strFRMT,hello,do_resume, printflt,end_Sched,freeMem
extern target_X, target_Y, printBoard, schedulerFunc, targetFunc, droneFunc,createTarget,free
section .bss
global N
global R
global K
; global d
global seed

N: resd 1 ;; 4bytes
R: resd 1
K: resd 1
d: resd 1
seed: resd 1

CURR: resd 1
SPT: resd 1
SPMAIN: resd 1

STKSZ equ 16*1024

STKprint: resb STKSZ
STKscheduler: resb STKSZ
STKtarget: resb STKSZ

; tmp: resd 1


section .data
intFRMT: db "%d",10,0

;; sscanf(input,format, destination );
toInt: db "%d" ;; sscanf int format
tofloat: db "%f"
toStr: db "arg = %s",10,0
printHex: db "%x",10,0
printflt: db "%.2f",10,0
hello: db 'hello',10,0

DRONES: dd 0
CORS: dd 0
STKS: dd 0

coScheduler: dd schedulerFunc
             dd STKscheduler + STKSZ

coPrinter:  dd printBoard
            dd STKprint + STKSZ

coTarget:   dd targetFunc
            dd STKtarget +STKSZ

staticCos:  dd coScheduler
            dd coPrinter
            dd coTarget

STRUC1: dd 0

struc drone
    id:resd 1
    x: resd 1
    y: resd 1
    alpha: resd 1
    speed: resd 1
    traget: resd 1
    flag: resd 1
endstruc

maxnumber: dd 65535
X_gen: dd 0
Y_gen: dd 0
Angle_gen: dd 0
speed_gen: dd 0
X100: dd 100
X120: dd 120
X180: dd 180
X60: dd 60
X20: dd 20
X10: dd 10
X360: dd 360
X0: dd 0
; currID: dd 0
; newAngle: dd 0
; newSpeed: dd 0

; tmpAngle: dd 0
; tmpSpeed: dd 0
; tmpX: dd 0
; tmpY: dd 0

M: dd 0

activatedDrones: dd 0

; target_X: dd 0
; target_Y: dd 0

xDifference: dd 0
yDifference: dd 0
distance: dd 0
tmpptr: dd 0



msg2:   db     'pStru + b = %d', 10, 0
tar:    db   "X= %.2lf , Y= %.2lf",10,0


section .rodata

printInt: db "%d",10,0
myint: db "2",0

printId: db "%d",0
printgen: db "%.2f      %.2f        %.2f        %.2f"
; hello: db "hello",10,0
strFRMT: db "%s",10,0


idOffset equ 0
xOffset  equ 4
yOffset  equ 8
alphaOffset  equ 12
speedOffset  equ 16
targetOffset  equ 20
flagOffset  equ 24




section .text
    ; align 16
    extern printf
    extern sscanf
    ; extern scanf
    global main
    extern calloc
    extern malloc


main:

    push ebp
	mov ebp, esp	

    ; mov eax, dword[ebp+8] ;;num of args
    mov ebx, dword[ebp+12] ;; first arg
    ; mov ecx, 0
    
    pushad
	pushfd
    mov eax,[ebx+4]
    push N 
    push toInt
    push eax
    call sscanf
    add esp,12
    popfd
    popad

    pushad
	pushfd
    mov eax,[ebx+8]
    push R
    push toInt
    push eax
    call sscanf
    add esp,12
    popfd
    popad
    
    pushad
	pushfd
    mov eax,[ebx+12]
    push K
    push toInt
    push eax
    call sscanf
    add esp,12
    popfd
    popad

   
    pushad
	pushfd
    mov eax,[ebx+20]
    push seed
    push toInt
    push eax
    call sscanf
    add esp,12
    popfd
    popad
    
    pushad
	pushfd
    mov eax,[ebx+16]
    push d
    push tofloat
    push eax
    call sscanf
    add esp,12
    popfd
    popad
    ;;ALL INPUT ARGUMENTS ARE READ

    call init_game

    call createTarget

    ; call printDrones

  
   
    pushad
    pushfd
    call start_Sched
    popfd
    popad

    
    pushad
    pushfd
    call end_Sched
    popfd
    popad

    call freeMem


    jmp end
    end:
    mov esp, ebp			; free function activation frame
    pop ebp			; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret	


;; ^^ init_game -> initalizes the game sructures
    init_game:
    	push ebp
	    mov ebp,esp
        ;;can push registers here
        pushad

        ;;CREATE THE DRONES ARRAY
        push dword 4
        push dword[N]
        call calloc
        add esp,8
        mov dword[DRONES],eax ;;DRONES points to drones array
       
        ;;CREATE CORS ARRAY
        pushad
        push dword 4
        push dword [N]
        call calloc
        add esp,8
        mov dword[CORS],eax
        popad
        
        ;;CREATE STKS ARRAY
        pushad
        push dword STKSZ
        push dword[N]
        call calloc
        add esp,8
        mov dword[STKS],eax
        popad
        
        mov ecx,dword[N]
        mov dword[activatedDrones],ecx

        call init_Drones 

        call fill_Drone_Cors

        call init_Drone_Cors

        call init_Static_Cors

    popad
    mov esp,ebp
    pop ebp
    ret

;;INITIALIZING THE STATIC CORS
init_Static_Cors:
    push ebp
	mov ebp,esp
    pushad

    mov ecx,3
    mov edx,0
lp:
    push edx
    call init_static
    add esp,4
    inc edx
    loop lp,ecx
    
    mov esp,ebp
    pop ebp
    ret


;; ^^ init_Drones 
init_Drones:
    push ebp
    mov ebp,esp
    pushad

    mov ebx,[DRONES]
    mov ecx,dword[N]
    mov esi,0

        ;;FILLING THE DRONES WITH DATA
    fillDrones:
        pushad
        push dword 28;; size of drone struct
        call malloc
        add esp, 4
        mov dword[STRUC1],eax
        popad

        mov eax,[STRUC1]
        mov dword[ebx+esi*4],eax
      
        pushad
        call generateX_Y_ALPHA_SPEED
        popad
        
        mov dword[eax],esi         ;;id

        mov edi,[X_gen]
        mov dword[eax +4],edi      ;;x

        mov edi,[Y_gen]
        mov dword[eax +8],edi   ;;y

        mov edi,[Angle_gen]
        mov dword[eax+12],edi   ;;alpha

        mov edi,[speed_gen]
        mov dword[eax+16],edi   ;;speed
        mov dword[eax+20],dword 0 ;;targets
        mov dword[eax+24],dword 0 ;;flag

        inc esi
        loop fillDrones, ecx

        popad
        mov esp,ebp
        pop ebp
        ret




    printDrones:
        push ebp
	    mov ebp,esp
        pushad

        mov ebx,[DRONES]
        mov esi,0
        mov ecx, dword[N]
    printAll:
        push ebx
        mov ebx,[ebx + esi*4] ;; contains the current drone address

        PRINTINT dword [ebx] ;; print the id
        PRINTFLT [ebx +4]
        PRINTFLT [ebx +8]
        PRINTFLT [ebx +12]
        PRINTFLT [ebx +1]
        pop ebx
        inc esi
        loop printAll,ecx

        popad
        mov esp,ebp
        pop ebp
        ret

    ;FILLING THE DRONES WITH ALLOCATED SPACE FOR CODEP AND SPP
    fill_Drone_Cors:
        push ebp
	    mov ebp,esp
        pushad
        
        mov ecx,dword[N]
        mov ebx,[CORS]
        mov esi,0
        mov edx, [STKS]
        add edx, STKSZ
    fill:
        pushad
        pushfd
        push dword 8
        call malloc
        mov [tmpptr],eax
        add esp, 4
        popfd
        popad

        mov eax, dword[tmpptr]
        mov [ebx+ 4*esi],eax
        mov dword[eax],droneFunc
        mov [eax +4], edx
        add edx, STKSZ
        inc esi
        loop fill,ecx

        popad
        mov esp,ebp
        pop ebp
        ret


;;^^ init_CORS:  
;;INITIALIZING THE DRONE'S CO-ROUTINES
init_Drone_Cors:
    push ebp
	mov ebp,esp
    pushad

    mov edx,0
    mov ecx,[N]   
init:
    push edx
    call initCo
    add esp,4

    inc edx
    loop init,ecx

    popad
    mov esp,ebp
    pop ebp
    ret





 


   

    ;  pushad
    ; fld dword [target_X]
    ; sub esp,8
    ; fstp qword [esp]
    ; push printflt
    ; call printf
    ; add esp,8
    ; popad

  




    


   
start_Sched:
    pushad           
    mov [SPMAIN], esp     
    mov ebx, [staticCos]       ; gets a pointer to a scheduler struct
    jmp do_resume                


end_Sched:
    mov esp, [SPMAIN]       ; restore ESP of main()
    popad                   ; restore registers of main()
    ret
               

resume: ; save state of current co-routine
    pushfd
    pushad
    mov EDX, [CURR]
    mov[EDX+SPP], ESP   ; save current ESP
    do_resume: ; load ESP for resumed co-routine
    mov ESP, [EBX+SPP]
    mov[CURR], EBX
    popad; restore resumed co-routine state
    popfd
    ret; "return" to resumed co-routine

;; ^^ init_static
init_static:
	push ebp
	mov ebp,esp
    pushad
	mov esi, [ebp+8] ; get co-routine ID number
	mov ebx, [staticCos + 4*esi] 
	mov eax, [ebx] ; pointer to CO function
	mov [SPT], esp ; save ESP value
	mov esp, [ebx+SPP] 
	push eax ; push initial “return” address the co-routine function
	pushfd ; push flags
	pushad ; push all other registers
	mov [ebx+SPP], esp ; save new SPi value (after all the pushes)
	mov esp, [SPT] ; restore ESP value

    popad
	mov esp,ebp
	pop ebp
	ret


generateNum:
    push ebp
	mov ebp,esp
    pushad

	mov ecx,[seed]
	and ecx, 1             
	shl ecx , 2   
       
	mov eax, [seed]
	and eax, 4             

	xor ecx, eax          

	shl ecx, 1          
	mov edx, [seed]
	and eax, 8            
	
	xor ecx, eax           

	shl ecx ,2
	mov eax, [seed]
	and eax, 32       
	
	xor ecx, eax          

	shl ecx, 10            
	mov ebx, [seed]
	shr ebx ,1             
	or ecx, ebx
	mov [seed], ecx

    popad
	mov esp, ebp
	pop ebp
	ret


generateX_Y_ALPHA_SPEED:
        push ebp
            mov ebp,esp

            call generateNum
         
            fild dword [seed] ; st1 = randomized
            fild dword [maxnumber] ;st0 = 65535
            fdiv ; st0 = randomized/65535 
            fild dword [X100]
            fmul
            fstp dword [X_gen]

            call generateNum

            fild dword [seed] ; st1 = randomized
            fild dword [maxnumber] ;st0 = 65535
            fdiv ; st0 = randomized/65535 
            fild dword [X100]
            fmul
            fstp dword [Y_gen]

            call generateNum

            fild dword [seed] ; st1 = randomized
            fild dword [maxnumber] ;st0 = 65535
            fdiv ; st0 = randomized/65535 
            fild dword [X100]
            fmul
            fstp dword [speed_gen]

            call generateNum

            finit
            fild dword [seed] ; st1 = randomized
            fild dword [maxnumber] ;st0 = 65535
            fdiv ; st0 = randomized/65535 
            fild dword [X120] ; st2 = 120
            fmul ; st1 = st2 * st1 = (randomized/65535)*120
            fstp dword [Angle_gen]

            mov esp,ebp
            pop ebp

            ret     



initCo: ;; same as in slides just added drone func
    push ebp
    mov ebp,esp
    pushad

    mov esi, [ebp+8]
    mov ebx, [CORS]
    mov ebx, [ebx + 4*esi]
    mov eax, [ebx]
    mov [SPT], ESP
    mov esp, [ebx+SPP]
    push eax; push initial “return” address
    pushfd; push flags
    pushad; push all other registers
    mov [ebx+SPP], esp              ; save new SPi value (after all the pushes)
    mov ESP, [SPT]; restore ESP value
    
    popad
    mov esp,ebp
    pop ebp
    ret


freeMem:
            push ebp
            mov ebp,esp
            pushad

            mov ecx,[N]
            mov esi,0
        freeDrns:

            mov ebx,[DRONES]
            mov ebx,[ebx + 4*esi]
            push ebx
            call free
            add esp,4

            inc esi
            loop freeDrns,ecx

            push dword [DRONES]
            call free
            add esp,4

            mov ecx,[N]
            mov esi,0
        freeCors:
            mov ebx,[CORS]
            mov ebx,[ebx + 4*esi]
            push ebx
            call free
            add esp,4
            inc esi
            loop freeCors,ecx

            push dword [CORS]
            call free
            add esp,4

            push dword [STKS]
            call free
            add esp,4

            popad
            mov esp,ebp
            pop ebp
            ret