PORT_0832 EQU 0600H
PORT_0809 EQU 06C0H

CYCLE1 EQU 0FFFFH
CYCLE2 EQU 0FFFFH

CODE SEGMENT
	ASSUME CS:CODE
START:
	
AA1:
	MOV DX, PORT_0832
	MOV AL, 0FFH
	OUT DX, AL
	
	MOV CX, CYCLE1
	LOOP $
	MOV CX, CYCLE1
	LOOP $
	
	MOV AL, 00H
	OUT DX, AL
	
	MOV CX, CYCLE2
	LOOP $
	MOV CX, CYCLE2
	LOOP $
	JMP AA1
CODE ENDS
	END START