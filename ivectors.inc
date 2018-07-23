;=== BEGIN "ivectors.inc" ==================================================
; Тут располагается "таблица векторов на обработчики прерываний" - важнейшая вещь! 
; Если про нее забыть, то можно огрести такие неразрешимые глюки, что просто капец. Так что не забываем...
; (Вынесено из общего кода в отдельный файл - для облегчения портирования программы на другой камень...)
;
; КАК СДЕЛАТЬ: 
; Скопировать секцию "INTERRUPT VECTORS" из HAL-файла Микроконтроллера (например, "tn85def.inc"),
; Заменить все ".equ" на ".org"... и дописать ко всем точкам входа команду RETI.
; (Это на тот случай, если Прерывание случайно вылезет - чтобы вернуть управление туда, откуда прервалось.)


; ***** INTERRUPT VECTORS ************************************************
; Используем HAL Микроконтроллера "ATtiny85"

		.ORG	INT0addr	; External Interrupt 0
		RETI
		.ORG	PCI0addr	; Pin change Interrupt Request 0
		RETI
		.ORG	OVF0addr	; Timer/Counter0 Overflow
		RJMP	TIMER0_OVERFLOW_HANDLER
		.ORG	ERDYaddr	; EEPROM Ready
		RETI
		.ORG	ACIaddr		; Analog comparator
		RETI
		.ORG	OC0Aaddr	; Timer/Counter0 Compare Match A
		RETI
		.ORG	OC0Baddr	; Timer/Counter0 Compare Match B
		RETI
		.ORG	WDTaddr		; Watchdog Time-out
		RETI
		.ORG	ADCCaddr	; ADC Conversion complete
		RETI
		
		.ORG	INT_VECTORS_SIZE	; Êîíåö òàáëèöû ïðåðûâàíèé


;=== END "ivectors.inc" ====================================================
