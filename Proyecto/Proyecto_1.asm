.model small                      ; Modelo 
.data                             ;Inicia declaracion de variables

.stack                            ; segmento de pila
.code                             ; segmento de codigo
programa:   
     Mov AX,@DATA
	 Mov DS, AX	
      Mov AH, 4Ch 		            
      INT 21h		             ;llamada a ejecutar la interrupcion anterior
END programa    