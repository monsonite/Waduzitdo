						; A Tiny Language for text based games
						; This version for Z80 to run on the RC2014 Micro SBC
						
						; The main program is just 256 bytes long
						; starting at $8000 in RAM
						
						; The text storage are begins at $8100
						; and the getchar and putchar routines for the serial
						; ACIA are at $9000
						
						
						
						
						.ORG $8000
 
 
 
  start:                 ld hl,(loc)
  eget:                  call jin
                         cp 0x5c            ; Is it a \ ?
                         jp z,start         ; Go back to start
                         
                         
                         cp 0x24            ; Is it a $
                         jp z,exec          ; start execution
                         
                         cp 0x5f            ; Is it a backspace ?
                         jp nz,dis
                         dec hl
                         jp eget
                         
                         ; Process display of next line
                         
 dis:                    cp 0x2f          ; Is it a / ?
                         jp nz,pad
                         call prta        ; print the line
                         jp eget
                         
                         ; Do line replacement
                         ; pad to end of statement with nulls
                         
 pad:                    cp 0x25
                         jp nz,char
                         ld b,0x0d
                         ld a,b
                         call jout
                         ld c,0x40
 padl:                   cp (hl)
                         jp z,char
                         ld (hl),0x00
                         inc hl
                         dec c
                         jp nz,padl
                         
                         ; store entered source characters in program
                         
 char:                   ld (hl),a
                         inc hl
                         cp 0x0d
                         call z,plfl
                         jp eget
                         
                         
 jin:                    call getchar      ; call get_char
                         jp z,jin
                         ld b,a
 jout:                   call putchar      ; call put_char
                         ld a,b
                         ret
                         
                         
                         ; begin execution of program
                         
 exec:                   ld hl,(loc)
                         dec hl
 loopi:                  inc hl
 loop:                   ld a,(hl)
                         cp 0x2b
                         jp m,loopi
                         
                         ; Process Y or N flags
                         
                         cp 0x59        ; is it a Y ?
                         jp z,tflg
                         cp 0x4e        ; is it an N ?
                         jp nz,xa
 tflg:                   inc hl
                         cp d
                         jp z,loop
                         
                         ; It's a flag failure - skip over the statement
                         
 skip:                   inc hl
                         ld a,(hl)
                         cp 0x0d
                         jp nz,skip
                         jp loopi
                         
                         ; Process the Accept statement
                         
 XA:                     cp 0x41       ; Is it an A ?
                         jp nz,XM
                         ld (lst),hl
                         call jin
					     ld e,a
                         inc hl
                         ld b, 0x0d    ; Carriage return
                         call jout
                         call plfl
                         jp loopi
                         
                         ; Process the Match Statement
                         
 XM:                     cp 0x4d        ; Is it an M ?
                         jp nz,XJ
                         inc hl
                         inc hl
                         ld a,(hl)
                         ld d,0x59
                         cp e
                         jp z,MX
                         ld d,0x4e
 MX:                     jp loopi
                         
                         ; Process the Jump Statement 
                         
 XJ:                     cp 0x4a        ; Is it a J ?
                         jp nz,XS
                         inc hl
						 inc hl
                         ld a,(hl)
                         and 0x0f
                         ld b,a
                         jp nz,JF
                         ld hl,(lst)
                         jp loop
						 
						 ; Skip forward 
						 
 JF:                     inc hl
                         ld a,(hl)
                         cp 0x2a
                         jp nz,JF
                         dec b
                         jp nz,JF
                         jp loopi
                         
                         ; Process the Stop/Subroutine statement
                         
 XS:                     cp 0x53        ; is is an S ?
                         jp nz,XT
                         inc hl
                         inc hl
                         ld a,(hl)
                         inc hl
						 jp start
                         jp loop
                         
                         ; Process the Type statement
                         
 XT:                     cp 0x54        ; Is it a T ?
                         jp nz,TE
                         inc hl
                         inc hl
 TE:                     call prt
                         jp loop
                         
                         
                         ; Print a line of text
                         
 prt:                    ld c,0x40
 prta:                   ld b,(hl)
                         dec c
                         jp z,plfl
                         call jout
                         ld a,(hl)
                         inc hl
                         cp 0x0d
                         jp nz,prta
                         
                         ; Print a line feed
                         
 plf:                    ld c,0x00
 plfl:                   ld b,0x00
                         call jout
                         dec c
                         jp p,plfl
                         ld b,0x0a
                         jp jout
						 
						 
loc:                     db 0x81
                         db 0x06    
lst:					 nop 
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop 
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop 
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop 
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop 
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop 
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         nop
                         
                         
                         .ORG $9000
                         
; **********************************************************************
; **  Device Driver                             by Stephen C Cousins  **
; **  Hardware:  RC2014                                               **
; **  Interface: Serial 6850 ACIA                                     **
; **********************************************************************

; This module is the driver for the RC2014 serial I/O interface which is
; based on the 6850 Asynchronous Communications Interface Adapter (ACIA)
;
; Base addresses for ACIA externally defined. eg:
kACIA1:    .EQU 0x80           ;Base address of serial ACIA #1
kACIA2:    .EQU 0x80           ;Base address of serial ACIA #2
;
; RC2014 addresses for 68B50 number 2:
; 0x40   Control registers (read and write)
; 0x41   Data registers (read and write)
;
; 6850 #1 registers derived from base address (above)
kACIA1Cont: .EQU kACIA1+0       ;I/O address of control register
kACIA1Data: .EQU kACIA1+1       ;I/O address of data register
; 6850 #2 registers derived from base address (above)
kACIA2Cont: .EQU kACIA2+0       ;I/O address of control register
kACIA2Data: .EQU kACIA2+1       ;I/O address of data register

; Control register values
k6850Reset: .EQU 0b00000011     ;Master reset
k6850Init:  .EQU 0b00010110     ;No int, RTS low, 8+1, /64

; Status (control) register bit numbers
k6850RxRdy: .EQU 0              ;Receive data available bit number
k6850TxRdy: .EQU 1              ;Transmit data empty bit number

; Device detection, test 1
; This test just reads from the devices' status (control) register
; and looks for register bits in known states:
; /CTS input bit = low
; /DCD input bit = low
; WARNING
; Sometimes at power up the Tx data reg empty bit is zero, but
; recovers after device initialised. So test 1 excludes this bit.
k6850Mask1: .EQU  0b00001100    ;Mask for known bits in control reg
k6850Test1: .EQU  0b00000000    ;Test value following masking

; Device detection, test 2
; This test just reads from the devices' status (control) register
; and looks for register bits in known states:
; /CTS input bit = low
; /DCD input bit = low
; Transmit data register empty bit = high
k6850Mask2: .EQU  0b00001110    ;Mask for known bits in control reg
k6850Test2: .EQU  0b00000010    ;Test value following masking

; RC2014 serial 6850 initialise
;   On entry: No parameters required
;   On exit:  Z flagged if device is found and initialised
;             AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
; If the device is found it is initialised
serial_init:
; First look to see if the device is present
; Test 1, just read from chip, do not write anything
            IN   A,(kACIA1Cont) ;Read status (control) register
            AND  k6850Mask1     ;Mask for known bits in control reg
            CP   k6850Test1     ;and check for known values
            RET  NZ             ;If not found return with NZ flag
; Attempt to initialise the chip
            LD   A,k6850Reset   ;Master reset
            OUT  (kACIA1Cont),A ;Write to ACIA control register
            LD   A,k6850Init    ;No int, RTS low, 8+1, /64
            OUT  (kACIA1Cont),A ;Write to ACIA control register
; Test 2, perform tests on chip following initialisation
            IN   A,(kACIA1Cont) ;Read status (control) register
            AND  k6850Mask2     ;Mask for known bits in control reg
            CP   k6850Test2     ;Test value following masking
;           RET  NZ             ;Return not found NZ flagged
            RET                 ;Return Z if found, NZ if not


; RC2014 serial 6850 input character
;   On entry: No parameters required
;   On exit:  A = Character input from the device
;             NZ flagged if character input
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
; This function does not return until a character is available
getchar:
            IN   A,(kACIA1Cont) ;Address of status register
            AND  $01            ;Receive byte available
            JR   Z, getchar     ;Return Z if no character
            IN   A,(kACIA1Data) ;Read data byte
            RET                 ;NZ flagged if character input


; RC2014 serial 6850 output character
; On entry: A = Character to be output to the device
; On exit:  If character output successful (eg. device was ready)
; NZ flagged and A != 0
; If character output failed (eg. device busy)
; Z flagged and A = Character to output
; BC DE HL IX IY I AF' BC' DE' HL' preserved

putchar:
            LD   A,B
            PUSH BC
            LD   C,kACIA1Cont   ;ACIA control register
            IN   B,(C)          ;Read ACIA control register
            BIT  k6850TxRdy,B   ;Transmit register full?
            POP  BC
            JR  Z, putchar      ;Return Z as character not output
            OUT  (kACIA1Data),A ;Write data byte
            OR   0xFF           ;Return success A=0xFF and NZ flagged
            RET
