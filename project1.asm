	.INCLUDEPATH "/usr/share/avra"
	.NOLIST				; Disable listfile generation.
	.include "tn13def.inc"		; Используем HAL Микроконтроллера.
	.include "macro.inc"	; Библиотека базовых Макроопределений.
	;.include "macroapp.inc"		; Прикладные Макроопределения, используемые при реализации логики приложения.
	.LIST				; Reenable listfile generation.


	;.include "data.inc"		; Данные программы: 
					;	Константы и псевдонимы Регистров; 
					;	Сегмент SRAM и Переменные; 
					;	Сегмент EEPROM.
;***************************************************************************
;*
;*  RAM (переменные)
;*
;***************************************************************************
				.DSEG
color:		.BYTE 1
wheel:		.BYTE 1
wheel_3:		.BYTE 1
wheel_255:	.BYTE 1


;***************************************************************************
;*
;*  FLASH (сегмент кода)
;*
;***************************************************************************
			.CSEG

		.ORG	0x0000		; (RESET) 
		RJMP	RESET
		.include "ivectors.inc"	; Таблица векторов на обработчики прерываний


;***** BEGIN Interrupt handlers section ************************************

;---------------------------------------------------------------------------
;
; Прерывание: отсчёт полусекунд
;
;---------------------------------------------------------------------------

TIMER0_OVERFLOW_HANDLER:
		PUSHF	; Сохранить регистры SREG и TEMP[1] в Стеке...
		PUSH	temp2
		;...

	Exit__TIMER0_OVERFLOW_HANDLER:
		POP temp2
		POPF
		RETI


;***** END Interrupt handlers section 


;***** ИНИЦИАЛИЗАЦИЯ *******************************************************
RESET:
		;WDTOFF		; Disable Watchdog timer permanently (ensure)
		STACKINIT	; Инициализация стека
		RAMFLUSH	; Очистка памяти
		GPRFLUSH	; Очистка РОН


;***** BEGIN Internal Hardware Init ****************************************

; Инициализация Портов...

	SBI DDRB, 2		; PB2 IS A OUTPUT
	CBI	DDRB, 0		;PB0 IS A INPUT
	SBI PORTB, 0	; PB0 PULLUP

; Инициализация Счётчиков...

;***** END Internal Hardware Init 


;***** BEGIN External Hardware Init ****************************************
;***** END External Hardware Init 


;***** BEGIN "Run once" section (запуск фоновых процессов) *****************

		SEI  ; Разрешаем глобальные прерывания

;***** END "Run once" section 


;***** BEGIN "Main" section ************************************************
		PUSH R21
		CLR R21
		STS color, R21	; CLEAR COLOR IN RAM
		POP R21
MAIN:
		
; REG18 - COUNTER FOR LOOP
; wheel - WHEEL_POSITION
; color - COLOR

		LDI R18, 6	; We used 6 LEDs
		;
;============= START FOR ====================================
FOR:
		PUSH R18	;SAVE R18 TO STACK
		LSL	 R18	; LED NUMBER * 16
		LSL	 R18
		LSL	 R18
		LSL	 R18
		PUSH R19	; SAVE R19 TO STACK
		LDS R19,color;LOAD COLOR FROM RAM
		ADD R18, R19; COLOR + LED_NUMBER*STEP1 (16)
		STS wheel, R18; MOVE DATA TO RAM (WHEEL_POSITION)
		;POP R19		; RESTORE R19
		;POP R18		; RESTORE R18
		
		;===== CALCULATE VARIABLES FOR LEDs ========
		MOV R19, R18		;COPY DATA (WHEEL_POSITION) TO R19
		LSL R19				; WHEEL_POSITION*2
		ADD R19, R18		; WHELL_POSITION*2 + WHEEL_POSITION
		STS wheel_3, R19	; LOAD DATA TO RAM
		
		NEG R19				; = -WHEEL_POSITION*3
		SUBI R19, (-128)	; = 255-WHEEL_POSITION*3
		SUBI R19, (-127)
		STS wheel_255, R19	;LOAD DATA TO RAM
		;=============================================
		POP R19		; RESTORE R19
		
		CPI R18, 0x55; IF WHEEL_POSITION < 85 (0X55)
		BRLO action_1; THEN GOTO ACTION_1
		CPI R18, 0xAA;ELSE IF WHEEL_POSITION < 170 (0XAA)
		BRLO action_2; THEN GOTO ACTION_2
					 ; ELSE
		
		SUBI R18, 0xAA; NEW_WHEEL_POSITION = WHEEL_POSITION - 170
		LDI R24, 0		;RED = 0
		
		MOV R23, R18
		LSL R23
		ADD R23, R18	;GREEN = NEW_WHEEL_POSITION*3
		
		MOV R25, R23
		NEG R25
		SUBI R25, (-128);BLUE = 255 - NEW_WHEEL_POSITION*3
		SUBI R25, (-127)
		RJMP routine_end
action_1:
		LDI R25, 0			; BLUE = 0
		LDS R23, wheel_255	; GREEN = 255 - WHEEL_POSITION*3 (FROM RAM)
		LDS R24, wheel_3	; RED = WHEEL_POSITION*3 (FROM RAM)
		RJMP routine_end
action_2:
		LDI R23, 0			; GREEN = 0
		LDS R24, wheel_255	; RED = 255 - WHEEL_POSITION*3 (FROM RAM)
		LDS R25, wheel_3	; BLUE = WHEEL_POSITION*3 (FROM RAM)
		RJMP routine_end
			
routine_end:
		POP R18		; RESTORE R18 FROM STACK
		;WE NEED ADRESSES OF LEDs COLOUR REGISTERS
		;FIRST NUMBER OF REGISTER = (LED_NUMBER - 1)*3
		MOV R22, R18
		DEC R22		;LED_NUMBER - 1
		MOV R21, R22
		LSL R22
		ADD R22, R21; R22 = (LED_NUMBER - 1)*3
		
		MOV	YL, R22	;THIS IS L PART OF ADDRESS 
		LDI	YH,  0	; H PART IS ZERO ALLWAYS
		
		ST Y+, R23	;COPY GREEN REGISTER
		ST Y+, R24	;COPY RED REGISTER
		ST Y+, R25	;COPY BLUE REGISTER
		
		LDS R21, color;WE NEED INCREASE COLOR TO 2 (STEP2)
		INC R21
		INC R21
		CLC				; REMOVE C-FLAG, IF COLOR > 255
		STS color, R21	; WRITE COLOR TO RAM

		DEC R18		; R18 --
		BRNE island	; RETURN TO FOR LOOP WHILE R18 NOT ZERO
		RJMP pause
island:
		RJMP FOR
;=========== END OF FOR ===================================
pause:
		NOP
		NOP ; WE NEED DELAY IN THIS PLACE
		
;======= SET LEDs COLOR ====================================
		LDI R18, 0	;START REG COUNTER
		LDI YL, 0
		LDI YH, 0	;SET R0 ADDRESS
register_loop:
		;DEC R18 	; R18--
		LD R20, Y+	; READ BYTE WITH DATA TO TEMPORARY REGISTER R20
		LDI R19, 8	; START BIT COUNTER
	bit_loop:
		SBI PORTB, 2; SET BIT2 HIGH ON PORTB, t0
		NOP			; WE NEED SMALL DELAY
		SBRS R20, 7	; IF BIT7 ON THE R20 == 1, THEN SKIP 
		CBI PORTB, 2; SET BIT2 LOW ON PORTB, t1
		LSL R20		; SHIFT OUT NEXT BIT IN REG20
		NOP			; WE NEED SMALL DELAY
		CBI PORTB, 2; SET BIT2 LOW ON PORTB, t2
		NOP			; WE NEED SMALL DELAY
		DEC R19		; R19--
	BRNE bit_loop; END OF BIT LOOP
		INC R18		; R18 ++
		CPI R18, 18	; END LOOP IF R18==18
	BRNE register_loop; END OF REG LOOP
	
;===============================================================

;====================== DELAY====================================
		
		
		
		
		
		
		NOP		; Всё делается в прерываниях...
		RJMP	MAIN


;***** END "Main" section 

;***** BEGIN Procedures section ********************************************

	; Внимание! В отличие от Макросов, Код процедур, всегда и полностью, 
	; включается в сегмент данных программы - занимает место! 
	; Поэтому, здесь должны быть включены только те процедуры, которые 
	; реально используются. (Остальные - следует /* закомментировать */.)

	;.include "genproclib.inc"	; Библиотека стандартных Подпрограмм.





;***** END Procedures section 
; coded by (c) Celeron, 2013  http://inventproject.info/


		
		
