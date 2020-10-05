.model compact
.data 
	month						DB  ? 
	week_day					DB  ?
	month_day					DB  ?
	hour						DB  ?
	minute						DB  ?
	second						DB  ?
	hundredth_of_a_second		DB  ?
	;the max values below are considered for first iteration only
	a							DB  ? ;max value for this is 7E h    -- a  = month * week_day
	X0							DW  ? ;max value for this is BFD h  -- Xn = month_day * hundredth_of_a_second
	c							DW  ? ;max value = 4 3AF3 h			 -- c  = hour * minute * second
	m							DB  0Fh
	a_by_Xn						DW  ? ;max value = E 69EE h
	a_by_Xn_plus_c				DW  ? ;max value = 12 A4E1 h
	numbers_generated_counter	DB  32d 
	Xn							DB	?	
.stack
.code
.386
main:
   ;The formula followed for RNG is Xn+1 = (a*Xn +c) mod (m)
	MOV AX,@DATA
	MOV DS, AX
Calculate:	
	;Save date
		MOV AH, 2Ah
		INT 21h
		
		MOV month, DH
		MOV week_day, AL
		MOV month_day, DL	
		
			
	;Save hour
		MOV AH,2Ch
		INT 21H
		
		MOV hour, CH
		MOV minute, CL
		MOV second, DH
		MOV hundredth_of_a_second, DL
		
	;Prepare environment for RNG
		XOR AX, AX				
		MOV AL, month
		MUL week_day
		MOV a, AL
		
		XOR AX, AX				;Clear AX
		MOV AL, month_day
		MUL hundredth_of_a_second		
		MOV X0, AX
		
		XOR AX, AX				;Clear AX
		MOV AL, hour
		MUL minute		
		MUL second
		MOV c, AX				;No en todos los casos es usaba DX como doble palabra, por eso lo hicimos asì
		
				
;create X0 
		
		XOR AX, AX
		MOV AL, a
		MUL X0
		MOV a_by_Xn, AX
		
		;add c 
		XOR AX, AX
		MOV AX, a_by_Xn
		ADD AX, c		
		; AX is a_by_Xn_plus_c
		;finally generate Xn
		step:				
		MOV BX, 0Fh
		SUB AX,BX
		CMP AX, 00h
		JL Save
		JMP step
		
		;save the modular 
	    Save:
		ADD AX,BX
		MOV Xn, AL		     				       	
   		XOR CX,CX
	    MOV CL, numbers_generated_counter   ;veces en las que se repetira
	    XOR BX, BX						
	    XOR AX,AX
				     				       	
   				
		RNG:
		JMP Way
		RETURN:
		LOOP RNG
		
		Way:
		CMP CL, 20d
		JE write_1
		JMP Evaluate_Xn
		
	    write_1:
		MOV AH, 02h
        MOV DL, 01h
        ADD DL, 30h
        INT 21h
		JMP END_PROGRAM
		
		Evaluate_Xn:
        MOV AL, Xn		
		SUB AL, 0Ah	
		CMP AL,00h
        JL Less_Xn
        JMP Higher_Xn 

        Less_Xn:	
	    MOV AH, 02h
        MOV DL, Xn
        ADD DL, 30h
        INT 21h		
		jmp RETURN
		
		Higher_Xn:
		MOV AH, 02h
        MOV DL, AL
        ADD DL, 41h
        INT 21h
		jmp RETURN
				
END_PROGRAM:	
	;End of file
	MOV AH, 4Ch 		            
    INT 21h	
END main