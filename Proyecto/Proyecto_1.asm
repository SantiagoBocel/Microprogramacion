.model compact
.data 
    case_1_msg                  DB  "Generar UUID:      (1)	 $"
	case_2_msg                  DB  "Validar UUID:      (2)  $"
	case_3_msg                  DB  "Salir:             (3)  $"
	ask_UUID_msg                DB  "Ingrese su UUID a validar (las letras van en minuscula)	$"   
	not_valid_option_msg        DB  "Ingrese una opcion valida (enter para continuar) $"
	error_Validate_UUID_msg     DB  "Cadena ingresada no valida $"
	error_byte_7                DB  "El grupo de los cuatro bits mas significativos del septimo byte debera iniciar siempre con 1 (enter para continuar) $"
	error_second_bit_msg        DB  "El segundo grupo de bits mas significativo debera iniciar con un numero aleatorio entre 8,9,A o B en hexadecimal (enter para continuar) $"
	error_hyphen_msg            DB  "El UUID debe estar separado por guiones (enter para continuar) $"
	valid_UUID_msg              DB  "El UUID ingresado es valido (enter para continuar) $"
	input                       DB  0
	user_UUID_index       	             	DW  0
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
	m							DW  0Fh ;variable to simulate modular operation
	a_by_Xn						DW  ? ;max value = E 69EE h
	a_by_Xn_plus_c				DW  ? ;max value = 12 A4E1 h
	numbers_generated_counter	DB  32d 
	Xn							DW	? ;variable to store random value generated
.stack
.code
.386
main:
	MOV AX,@DATA
	MOV DS, AX
;menu 
	;print enter
	XOR AX, AX
	XOR DX, DX
    MOV AH,02              
	MOV DL, 0Ah
	INT 21h	
	
	;print enter
	XOR AX, AX
	XOR DX, DX
    MOV AH,02              
	MOV DL, 0Ah
	INT 21h
	
	;print case 1
	MOV DX, OFFSET case_1_msg
	MOV AH, 09h
	INT 21h	
	
	;print enter
	XOR AX, AX
	XOR DX, DX
    MOV AH,02              
	MOV DL, 0Ah
	INT 21h
	
	;print case 2
	MOV DX, OFFSET case_2_msg
	MOV AH, 09h
	INT 21h
	
	;print enter
	XOR AX, AX
	XOR DX, DX
	MOV AH,02              
	MOV DL, 0Ah
	INT 21h
	
	;print case 3
	MOV DX, OFFSET case_3_msg
	MOV AH, 09h
	INT 21h
	
	;print enter
	XOR AX, AX
	XOR DX, DX
	MOV AH,02              
	MOV DL, 0Ah
	INT 21h
	
	;read input from user
	XOR AX, AX
	XOR DX, DX
	MOV AH, 01h             
    INT 21h
	SUB AL, 30h
	MOV input, AL
	
	;jump to user selection 
	CMP input, 01h
    JE Generate_UUID
    CMP input, 02h
    JE  Validate_UUID
	CMP input, 03h
    JE  END_PROGRAM
	
	;in case of error in menu selection show error and ask for input again
	JG Error_return 
    CMP input, 00h
    JLE	Error_return
	
Error_return:

	;print two enters
    MOV AH,02              
    MOV DL, 0Ah
    INT 21h
	MOV AH,02              
    MOV DL, 0Ah
    INT 21h
	
	;print error message
  	MOV DX, OFFSET not_valid_option_msg
	MOV AH, 09h
	INT 21h	
	
	;print two enters
	MOV AH,02              
    MOV DL, 0Ah
    INT 21h
	MOV AH,02              
    MOV DL, 0Ah
    INT 21h
	
    JMP main
	
Validate_UUID:	
	;print two enters
    MOV AH,02              
    MOV DL, 0Ah
    INT 21h
	MOV AH,02              
    MOV DL, 0Ah
    INT 21h
	
	;print ask_UUID_msg
    MOV DX, OFFSET ask_UUID_msg
	MOV AH, 09h
	INT 21h	
	
	;print two enters
	MOV AH,02              
    MOV DL, 0Ah
    INT 21h
	MOV AH,02              
    MOV DL, 0Ah
    INT 21h
	
    CALL Analyze_user_UUID_sp
	JMP main
	
	
	
Analyze_user_UUID_sp proc near
        MOV user_UUID_index, 00h	
		 
Analyze_user_UUID_Loop:
        ;read user input and star validation one by one
		XOR AX, AX
		MOV AH, 01h             
		INT 21h
		
        CMP user_UUID_index, 35d		
		JE valid_UUID					;if the analyzer hit this jump it means the UUID
		
		
		;all these validations are for positions with most restrictions
		;explanations are inside procedures
        CMP user_UUID_index, 14d
		JE Byte_7
		
		CMP user_UUID_index, 19d
		JE	Second_bit
		
        CMP user_UUID_index, 08d
        JE 	Hyphen_validation
		
        CMP user_UUID_index, 13d
        JE 	Hyphen_validation
		
        CMP user_UUID_index, 18d
        JE 	Hyphen_validation
		
        CMP user_UUID_index, 23d
        JE 	Hyphen_validation	
		
		;in case the analyzer reach this point it means
		;its an standard position to analyze
		CMP AL, 3Ah
        JL Digit_Validation ;in case is smaller than 3Ah then is a digit from 0-9
        JMP Letters_Validation  ;in case no is a letter from a-f
		
Hyphen_validation:
        INC user_UUID_index ; user_UUID_index++
		CALL Validate_Hyphen_sp
        JMP Analyze_user_UUID_Loop 
		
Byte_7:
        INC user_UUID_index ; user_UUID_index++
        CALL Validate_byte_7_sp
     	JMP Analyze_user_UUID_Loop
		
Second_bit:
        INC user_UUID_index ; user_UUID_index++
        CALL Validate_second_bit_sp
        JMP Analyze_user_UUID_Loop	
		
Digit_Validation:
        INC user_UUID_index ; user_UUID_index++			
        SUB AL, 30h 		
		CMP AL, 00h			; compare if the lower limit is ok
		JL Not_valid
        CMP AL, 09h     	; compare if upper limit is ok
		JLE Analyze_user_UUID_Loop 		
		JMP Not_valid
		
Letters_Validation:
        INC user_UUID_index ; user_UUID_index++
        SUB AL, 57h 		
		
		;compare the exact value of each case posible
        CMP AL, 0Ah
		JE Analyze_user_UUID_Loop 		
		CMP AL, 0Bh
		JE Analyze_user_UUID_Loop
		CMP AL, 0Ch
		JE Analyze_user_UUID_Loop
		CMP AL, 0Dh
		JE Analyze_user_UUID_Loop
		CMP AL, 0Eh
		JE Analyze_user_UUID_Loop
		CMP AL, 0Fh
		JE Analyze_user_UUID_Loop
		JMP Not_valid
		
	Not_valid:
		;print enter
      	MOV AH,02              
        MOV DL, 0Ah
        INT 21h
      	
		;print error message
  	    MOV DX, OFFSET error_Validate_UUID_msg
	    MOV AH, 09h
	    INT 21h	
	    JMP Exit 
		
	valid_UUID:
		;print two enters
	    MOV AH,02              
        MOV DL, 0Ah
        INT 21h
		
		MOV AH,02              
        MOV DL, 0Ah
        INT 21h
		
		;print error message
        MOV DX, OFFSET valid_UUID_msg
	    MOV AH, 09h
	    INT 21h	
	    JMP Exit        
Exit:	 
      RET
    Analyze_user_UUID_sp endp
	
	
	
Validate_byte_7_sp proc near
		;compare if the value is equal to 1
		CMP AL, 31h
		JE Exit_byte7	;continue if ok
		
		;print two enters		
        MOV AH,02              
        MOV DL, 0Ah
        INT 21h
		
	    MOV AH,02              
        MOV DL, 0Ah
        INT 21h
	
		;print error in case value is not ok
  	    MOV DX, OFFSET error_byte_7
	    MOV AH, 09h
	    INT 21h	
	    JMP main 
	   
Exit_byte7:	 
      RET
    Validate_byte_7_sp endp	


	
Validate_second_bit_sp proc near
        CMP AL, 38h ; == 8
	    JE Exit_second_bit
        CMP AL, 39h ; == 9
	    JE Exit_second_bit
        CMP AL, 61h ; == A
	    JE Exit_second_bit
        CMP AL, 62h ; == B
	    JE Exit_second_bit
 	   
		;print two enters
        MOV AH,02              
        MOV DL, 0Ah
        INT 21h
		
	    MOV AH,02              
        MOV DL, 0Ah
        INT 21h
	
		;print error in case value is not ok
  	    MOV DX, OFFSET error_second_bit_msg
	    MOV AH, 09h
	    INT 21h	
	    JMP Exit_second_bit 

Exit_second_bit:
      RET
	Validate_second_bit_sp endp 


	
Validate_Hyphen_sp proc near
       CMP AL, 2Dh ;== -
	   JE Exit_hyphen_validation
      
	   ;print two enters
	   MOV AH,02              
       MOV DL, 0Ah
       INT 21h
	   
	   MOV AH,02              
       MOV DL, 0Ah
       INT 21h
	
	   ;print error in case value is not ok
  	   MOV DX, OFFSET error_hyphen_msg
	   MOV AH, 09h
	   INT 21h	
	   JMP Exit_hyphen_validation 
	  
Exit_hyphen_validation:
      RET
	Validate_Hyphen_sp endp 
	
	
	
Generate_UUID:	
		MOV numbers_generated_counter, 32d
		
	    ;print two enters
		MOV AH,02              
		MOV DL, 0Ah
		INT 21h
		
		MOV AH,02              
		MOV DL, 0Ah
		INT 21h
		
    ;The formula followed for RNG is Xn+1 = (a*Xn +c) mod (m)
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
		MOV c, AX				;The reason why DX is not considered is because is rarely used for this operations
		
				
;create X0 
		; a * X0
		XOR AX, AX
		MOV AL, a
		MUL X0
		MOV a_by_Xn, AX
		
		;add c 
		XOR AX, AX
		MOV AX, a_by_Xn
		ADD AX, c		
		MOV a_by_Xn_plus_c, AX
		
		;finally generate X0
		XOR AX, AX
		XOR DX, DX
		MOV AX, a_by_Xn_plus_c
		DIV m
		
		;save the modular 
		MOV Xn, DX
		
;loop for RNG, c changes for this point, now is minute per second per hundredth of a second
	RNG:
	;small delay formula found in https://stackoverflow.com/questions/15201955/how-to-set-1-second-time-delay-at-assembly-language-8086
		mov bp, 13690
		mov si, 13690
		delay2:
		dec bp
		nop
		jnz delay2
		dec si
		cmp si,0    
		jnz delay2
	;END OF DELAY FUNCTION 

		XOR AX, AX
		XOR DX, DX
		
		;print dash or hard coded positions
		CMP numbers_generated_counter, 24d
		JE write_dash
		
		CMP numbers_generated_counter, 20d
		JE write_1
		
		CMP numbers_generated_counter, 16d
		JE write_dash
		
		CMP numbers_generated_counter, 12d
		JE write_dash
		
		
		CONTINUE_RNG:
		; Clear registers
		XOR AX, AX
		XOR DX, DX
		
		;Save hour
		MOV AH,2Ch
		INT 21H			
		MOV minute, CL
		MOV second, DH
		MOV hundredth_of_a_second, DL
		
		
		XOR AX, AX				
		MOV AL, hundredth_of_a_second
		MUL minute				; hundredth_of_a_second * minute
		MUL second				; hundredth_of_a_second * minute * second
		MOV c, AX				; c = hundredth_of_a_second * minute * second
				
		XOR AX, AX
		XOR DX, DX
		MOV AL, a
		MOV DX, Xn
		MUL DX					; a*Xn
		MOV a_by_Xn, AX			; a_by_Xn = a*Xn
		
		;add c 
		XOR AX, AX
		MOV AX, a_by_Xn
		ADD AX, c		 		; a_by_Xn + c
		MOV a_by_Xn_plus_c, AX 	; a_by_Xn_plus_c = a_by_Xn + c
		
		;finally generate Xn, which is the MOD result
		XOR AX, AX
		XOR DX, DX
		MOV AX, a_by_Xn_plus_c
		DIV m
		
		;save the modular 
		MOV Xn, DX
		
		;Print Xn
		CMP numbers_generated_counter, 16d
		JE validate_rand_num_gen
		JMP write_Xn
		
	write_dash:
		MOV AH, 02h
		ADD DL, 2Dh
		INT 21h
		XOR AX, AX
		XOR DX, DX
	JMP CONTINUE_RNG
	
	
	write_1:
	;WRITE DASH BEFORE 
		XOR AX, AX
		XOR DX, DX
		MOV AH, 02h
		ADD DL, 2Dh
		INT 21h
		XOR AX, AX
		XOR DX, DX
		
		MOV Xn, 1h
		JMP write_Xn
				
	validate_rand_num_gen:
		CMP Xn, 08h ; Xn == 8
		JE write_Xn
		CMP Xn, 09h ; Xn == 9
		JE write_Xn
		CMP Xn, 0Ah ; Xn == a
		JE write_Xn
		CMP Xn, 0Bh ; Xn == b
		JE write_Xn ; in case is ok, write it
		JMP CONTINUE_RNG ;in case no the generator generates another random
	
	write_Xn:
		XOR AX, AX
		XOR DX, DX
		DEC numbers_generated_counter	
		MOV DX, Xn
		MOV AX, 0AH
		CMP DX, AX
		;evaluate if the value is a digit from 0-9 or a letter from a-f, 
		;this because the value added to print real ascii changes
        JL Less_Xn
        JMP Higher_Xn 

        Less_Xn:	
	    MOV AH, 02h
        ADD DL, 30h
        INT 21h		
		jmp Evaluate_continuing
		
		Higher_Xn:
		MOV AH, 02h
        ADD DL, 57h
        INT 21h
		jmp Evaluate_continuing
		
		Evaluate_continuing:
		
		XOR DX, DX
		;check if all values had been generated
		MOV DL, numbers_generated_counter
		CMP DL, 00h
		JNE RNG
		
	JMP main
END_PROGRAM:	
    
	MOV AH,02              
	MOV DL, 0Ah
	INT 21h
	
	;End of file
	MOV AH, 4Ch 		            
    INT 21h	
END main	 