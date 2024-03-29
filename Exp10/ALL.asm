PA_8255 EQU 0600H
PB_8255 EQU 0602H
PC_8255 EQU 0604H
CTR_8255 EQU 0606H

PORT0_8254 EQU 0640H
PORT1_8254 EQU 0642H
CTR_8254 EQU 0646H

ICW1_8259 EQU 0020H
ICW2_8259 EQU 0021H
ICW4_8259 EQU 0021H
OCW1_8259 EQU 0021H

IR6_INTR_ADDR EQU 38H
IR7_INTR_ADDR EQU 3CH

START_CANCEL EQU 0AH
PAUSE_CONTINUE EQU 0BH
EXIT_P EQU 0CH

DATA SEGMENT
    LEDMAP DB 10111111B
    LEDTABLE    DB 03FH
                DB 006H
                DB 05BH
                DB 04FH
                DB 066H
                DB 06DH
                DB 07DH
                DB 007H
                DB 07FH
                DB 06FH
                DB 077H
                DB 07CH
                DB 039H
                DB 05EH
                DB 079H
                DB 071H
                
    KEYTABLE    DB 11101110B    ;0
                DB 11011110B    ;1
                DB 10111110B    ;2
                DB 01111110B    ;3
                DB 11101101B    ;4
                DB 11011101B    ;5
                DB 10111101B    ;6
                DB 01111101B    ;7
                DB 11101011B    ;8
                DB 11011011B    ;9
                DB 10111011B    ;A
                DB 01111011B    ;B
                DB 11100111B    ;C
                DB 11010111B    ;D
                DB 10110111B    ;E
                DB 01110111B    ;F
    
    MINU DB 20H ;分钟BCD
    SECO DB 00H ;秒BCD
    
    LEDDAT DB 0, 0, 0, 0, 0, 0  ;LED显示缓存
    
    KEYBUF DB 0 ;输入缓冲
    
    COUNTING DB 0
    
DATA ENDS
CODE SEGMENT
    ASSUME CS: CODE, DS: DATA
START:
    MOV AX, DATA
    MOV DS, AX
    
    ;JMP IR6
    
    CALL MAIN_INIT
	;CALL START_COUNT
	;MOV MINU, 20
KK1:
    PUSH CX
    MOV CX, 005FH
KP1:
    CALL DISPLAY
    LOOP KP1
    ;JMP KK1
    POP CX  
    CALL KEY_INPUT
    CMP KEYBUF, START_CANCEL
    JZ STTCAN
    CMP KEYBUF, PAUSE_CONTINUE
    JZ PSCONT
    CMP KEYBUF, EXIT_P
    JZ EXP
    
    CMP KEYBUF, 09H
    JA KK1
    CALL SAVENUM
    JMP KK1

STTCAN:
    CMP COUNTING, 0
    JE STT1
    JMP START
STT1:
    CALL START_COUNT 
    JMP KK1
    
PSCONT:
    CMP COUNTING, 1
    JE PS1
    CALL START_COUNT
    JMP KK1
PS1:
    CALL PAUSE_COUNT
    JMP KK1
    
EXP:
	MOV AH, 4CH
	INT 21H
    JMP KK1    

START_COUNT PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV COUNTING, 1
    
    CLI
	
	MOV DX, OCW1_8259
	MOV AL, 00101111B
	OUT DX, AL
	
	STI
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
START_COUNT ENDP

PAUSE_COUNT PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    CLI
	
	MOV DX, OCW1_8259
	MOV AL, 11101111B
	OUT DX, AL
	
	STI
    
    MOV COUNTING, 0
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PAUSE_COUNT ENDP

MAIN_INIT PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    CALL CHIP_INIT
    CALL DAT_INIT
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
MAIN_INIT ENDP

DAT_INIT PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ;LEA BX, LEDDAT
    ;MOV [BX + 2], 03FH
    ;MOV [BX + 3], 03FH
    
    LEA BX, LEDDAT
    MOV SI, 0
    MOV CX, 6
    
DAT1:
    MOV BYTE PTR[BX + SI], 0
    INC SI
    LOOP DAT1
    
    MOV MINU, 0
    MOV SECO, 0
    MOV KEYBUF, 0
    MOV COUNTING, 0
        
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DAT_INIT ENDP
    
SAVENUM PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    LEA BX, LEDDAT
    MOV AL, [BX + 3]
    MOV [BX + 2], AL
    
    MOV AL, KEYBUF
    AND AX, 000FH
    MOV SI, AX
    
    LEA BX, LEDTABLE
    MOV AL, [BX + SI]
    LEA BX, LEDDAT
    MOV [BX + 3], AL
    
    MOV AL, KEYBUF
    AND AL, 0FH
    MOV CX, 4
    SHL MINU, 4
    OR MINU, AL
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SAVENUM ENDP    
    

    
DISPLAY PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV DX, PB_8255
    MOV AL, 0   ;熄灭
    OUT DX, AL
    
    LEA BX, LEDDAT
    MOV SI, 0
    
    MOV CX, 4
    MOV AL, 11111110B
    
LOP:
    PUSH AX
    
    MOV DX, PA_8255
    OUT DX, AL
    
    MOV AL, [BX + SI]
    MOV DX, PB_8255
    OUT DX, AL
        
    CALL DELAY
    CALL DELAY
    
    MOV DX, PB_8255
    MOV AL, 0   ;熄灭
    OUT DX, AL
    
    POP AX
    ROL AL, 1
    INC SI
    LOOP LOP
    
    MOV DX, PB_8255
    MOV AL, 0   ;熄灭
    OUT DX, AL
        
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DISPLAY ENDP
    
DELAY PROC NEAR
    PUSH CX
    MOV CX, 00FFH
    LOOP $
    POP CX
    RET
DELAY ENDP

RESET:
	PUSH AX
	PUSH DX
	MOV DX, PA_8255
    MOV AL, 11111111B
    OUT DX, AL
    
    MOV DX, PB_8255
    MOV AL, 0   ;熄灭
    OUT DX, AL
    
    POP DX
    POP AX
    RET


EXIT:
    MOV AH, 4CH
    INT 21H
    
KEY_INPUT PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
AA1:
	MOV DX, PB_8255
    MOV AL, 0   ;熄灭
    OUT DX, AL
    CALL DISPLAY
    MOV DX, PB_8255
    MOV AL, 0   ;熄灭
    OUT DX, AL
    ;CALL RESET
    
    MOV DX, PA_8255
    MOV AL, 00000000B
    OUT DX, AL
    
    MOV DX, PC_8255
    IN AL, DX
    AND AL, 00001111B
    
    CMP AL, 00001111B
    JE AA1
    
    PUSH CX
    MOV CX, 4
KKK1:    
    CALL DELAY  ;消抖
    CALL DELAY
    CALL DELAY
    CALL DELAY
    CALL DELAY
    CALL DELAY
    LOOP KKK1
    
    POP CX
    
    MOV DX, PB_8255
    MOV AL, 0   ;熄灭
    OUT DX, AL
    
    MOV DX, PA_8255
    MOV AL, 00000000B
    OUT DX, AL
    
    MOV DX, PC_8255
    IN AL, DX
    AND AL, 00001111B
    
    CMP AL, 00001111B
    JE AA1
    
    MOV CX, 4
    MOV AH, 11111110B
    
AA2:
    MOV DX, PA_8255
    MOV AL, AH
    OUT DX, AL
    
    MOV DX, PC_8255
    IN AL, DX
    
    AND AL, 00001111B
    CMP AL, 00001111B
    
    JNE AA3 ;已确定了行、列
    
    ROL AH, 1
    LOOP AA2
    
    JMP AA1 ;查询失败
    
AA3:
    MOV CX, 4
    SHL AH, CL  ;AH中低4位存的列号移到高4位
    OR AL, AH   ;AH的行号合并到AL，形成位置码与KEYTABLE对应
    
    LEA BX, KEYTABLE
    
    MOV SI, 0   ;设置初始键号
AA4:    
    CMP AL, [BX + SI]
    JE AA5
    INC SI
    CMP SI, 16  ;可能有重键
    JE AA1
    JMP AA4
    
AA5:
    AND SI, 0FH
    MOV AX, SI    
    MOV KEYBUF, AL        
    ;CALL DISPLAY    
    
    ;JMP AA1
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
KEY_INPUT ENDP

CHIP_INIT PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    
    ; 8255 INIT
    MOV DX, CTR_8255
    MOV AL, 10001001B
    OUT DX, AL
    
    MOV DX, PB_8255
    MOV AL, 0   ;熄灭
    OUT DX, AL
    
    ; 8254 INIT
    ; CLK0 接 1 MHz
    ; OUT0 接 CLK1， OUT1 接 MIR6
    
    ; CNT0
    MOV DX, CTR_8254
	MOV AL, 00110110B
	OUT DX, AL
	
	MOV AX, 1000
	
	MOV DX, PORT0_8254
	OUT DX, AL
	
	MOV AL, AH
	
	MOV DX, PORT0_8254
	OUT DX, AL
	
	; CNT1	
	MOV DX, CTR_8254
	MOV AL, 01110110B
	OUT DX, AL
	
	MOV AX,  1000
	
	MOV DX, PORT1_8254
	OUT DX, AL
	
	MOV AL, AH
	
	MOV DX, PORT1_8254
	OUT DX, AL
	
	; 8259 INIT
	
	CLI
	
	MOV DX, ICW1_8259
	MOV AL, 00010011B
	OUT DX, AL
	
	MOV DX, ICW2_8259
	MOV AL, 00001000B
	OUT DX, AL
	
	MOV DX, ICW4_8259
	MOV AL, 00000111B
	OUT DX, AL
	
	MOV DX, OCW1_8259
	MOV AL, 11101111B
	OUT DX, AL
	
	STI

	CLI
	MOV AX, 0
	MOV ES, AX
	MOV DI, IR6_INTR_ADDR
	MOV AX, OFFSET IR6
	CLD
	STOSW
	MOV AX, SEG IR6
	STOSW
	STI
	
	CLI
	MOV AX, 0
	MOV ES, AX
	MOV DI, IR7_INTR_ADDR
	MOV AX, OFFSET IR7
	CLD
	STOSW
	MOV AX, SEG IR7
	STOSW
	STI
	
	POP DX
    POP CX
    POP BX
    POP AX
	
	RET
CHIP_INIT ENDP

DISPLAY3 PROC NEAR
	PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    CALL DISPLAY
    MOV CX, 00FFH
    
DPP1:
	CALL DISPLAY
	LOOP DPP1
	
	
	
	MOV DX, PB_8255
    MOV AL, 0   ;熄灭
    OUT DX, AL
    
    MOV CX, 02FFH
    
DPP2:
	CALL DELAY
	LOOP DPP2
	
	
	CALL DISPLAY
    MOV CX, 00FFH
    
DPP3:
	CALL DISPLAY
	LOOP DPP3
	
	
	
	MOV DX, PB_8255
    MOV AL, 0   ;熄灭
    OUT DX, AL
    
    MOV CX, 02FFH
    
DPP4:
	CALL DELAY
	LOOP DPP4
    
    CALL DISPLAY
    MOV CX, 00FFH
    
DPP5:
	CALL DISPLAY
	LOOP DPP5
	
	
	
	MOV DX, PB_8255
    MOV AL, 0   ;熄灭
    OUT DX, AL
    
    MOV CX, 02FFH
    
DPP6:
	CALL DELAY
    CALL DELAY
	LOOP DPP6
    
    CALL MAIN_INIT
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DISPLAY3 ENDP

    
IR6 PROC FAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	
	MOV DL, MINU
	AND DL, 0F0H
	MOV CX, 4
	SHR DL, CL
	AND DH, 00H
	MOV SI, DX
	
	LEA BX, LEDTABLE
	MOV AL, [BX + SI]
	
	LEA BX, LEDDAT
	MOV [BX], AL
	
	MOV DL, MINU
	AND DL, 0FH
	AND DH, 00H
	MOV SI, DX
	
	LEA BX, LEDTABLE
	MOV AL, [BX + SI]
	
	LEA BX, LEDDAT
	MOV [BX + 1], AL
	
	MOV DL, SECO
	AND DL, 0F0H
	MOV CX, 4
	SHR DL, CL
	AND DH, 00H
	MOV SI, DX
	
	LEA BX, LEDTABLE
	MOV AL, [BX + SI]
	
	LEA BX, LEDDAT
	MOV [BX + 2], AL
	
	MOV DL, SECO
	AND DL, 0FH
	AND DH, 00H
	MOV SI, DX
	
	LEA BX, LEDTABLE
	MOV AL, [BX + SI]
	
	LEA BX, LEDDAT
	MOV [BX + 3], AL
	
	CMP SECO, 00H
	JNE IR60
	CMP MINU, 00H
	JNE IR60
	CALL DISPLAY3
	JMP IR63
	
IR60:
	MOV AL, SECO	
	CMP AL, 00H
	JE IR61
	SUB AL, 01H
	DAS
	MOV SECO, AL
	JMP IR63
	
IR61:
    MOV SECO, 59H
    MOV AL, MINU
    SUB AL, 01H
    DAS
    MOV MINU, AL
    
IR62:	
	
	
IR63:	
	POP DX
    POP CX
    POP BX
    POP AX
	IRET
IR6 ENDP

IR7 PROC FAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	
	;CALL DISPLAY
	
	POP DX
    POP CX
    POP BX
    POP AX
	IRET
IR7 ENDP

CODE ENDS
    END START
