;  =========================================================================
; |   Sonic the Hedgehog 2 Early Prototype Disassembly for Sega Mega Drive  |
;  =========================================================================
;
; Disassembly originally created by drx, improved by LethalToxins
; thanks to Hivebrain and Rika_Chou

; ===========================================================================

                include "Variables.asm"
                include "Constants.asm"
                include "Macros.asm"

; Set this to 1 to remove some redundant jmptos in favor of saving 4 bytes
; per jmpto command removed.
; This will also save you cycles, 18 per bsr, 10 per bra.
removeJmpTos: equ 0

; Set this to 1 to fix DMA issues, Sonic 2 Nick Arcade manages to just barely
; slip by this issue, so if any modifications are made sonic's sprites will
; have a DMA overload due to how much art is using the DMA queue.
; This costs 30 bytes but ensures the DMA doesn't overload.
safeDMA128kb: equ 0

; ===========================================================================

StartOfRom:
Vectors:	dc.l v_systemstack	        ; Initial stack pointer value
		dc.l EntryPoint			; Start of program
		dc.l BusError			; Bus error
		dc.l AddressError		; Address error (4)
		dc.l IllegalInstr		; Illegal instruction
		dc.l ZeroDivide			; Division by zero
		dc.l ChkInstr			; CHK exception
		dc.l TrapvInstr			; TRAPV exception (8)
		dc.l PrivilegeViol		; Privilege violation
		dc.l Trace				; TRACE exception
		dc.l Line1010Emu		; Line-A emulator
		dc.l Line1111Emu		; Line-F emulator (12)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved) (16)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved) (20)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved) (24)
		dc.l ErrorExcept		; Spurious exception
		dc.l ErrorTrap			; IRQ level 1
		dc.l ErrorTrap			; IRQ level 2
		dc.l ErrorTrap			; IRQ level 3 (28)
		dc.l HBlank				; IRQ level 4 (horizontal retrace interrupt)
		dc.l ErrorTrap			; IRQ level 5
		dc.l VBlank				; IRQ level 6 (vertical retrace interrupt)
		dc.l ErrorTrap			; IRQ level 7 (32)
		dc.l ErrorTrap			; TRAP #00 exception
		dc.l ErrorTrap			; TRAP #01 exception
		dc.l ErrorTrap			; TRAP #02 exception
		dc.l ErrorTrap			; TRAP #03 exception (36)
		dc.l ErrorTrap			; TRAP #04 exception
		dc.l ErrorTrap			; TRAP #05 exception
		dc.l ErrorTrap			; TRAP #06 exception
		dc.l ErrorTrap			; TRAP #07 exception (40)
		dc.l ErrorTrap			; TRAP #08 exception
		dc.l ErrorTrap			; TRAP #09 exception
		dc.l ErrorTrap			; TRAP #10 exception
		dc.l ErrorTrap			; TRAP #11 exception (44)
		dc.l ErrorTrap			; TRAP #12 exception
		dc.l ErrorTrap			; TRAP #13 exception
		dc.l ErrorTrap			; TRAP #14 exception
		dc.l ErrorTrap			; TRAP #15 exception (48)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
Console:	dc.b "SEGA MEGA DRIVE " ; Console name
Date:		dc.b "(C)SEGA 1991.APR" ; Release date (leftover from Sonic 1)
Title_Local:	dc.b "SONIC THE             HEDGEHOG 2                " ; Domestic name
Title_In:	dc.b "SONIC THE             HEDGEHOG 2                " ; International name
Serial:		dc.b "GM 00004049-01"   ; Serial/version number (leftover from Sonic 1)
Checksum:	dc.w $AFC7		; ROM Checksum (leftover from Sonic 1)
IOSupport:	dc.b "J               " ; I/O support
ROMStart:	dc.l StartOfRom		; ROM start location
ROMEnd:		dc.l $7FFFF		; ROM end location (leftover from Sonic	1)
RAMStart:	dc.l $FF0000    	; RAM start location
RAMEnd:		dc.l $FFFFFF		; RAM end location
SRAMSupport:	dc.l $20202020
		dc.l $20202020
		dc.l $20202020
		dc.l $20202020
Notes:		dc.b "                                                "
Region:		dc.b "JUE             "
; ---------------------------------------------------------------------------

ErrorTrap:				; CODE XREF: ROM:00000204j
		nop
		nop
		bra.s	ErrorTrap
; ---------------------------------------------------------------------------

EntryPoint:				; DATA XREF: ROM:00000000o
		tst.l	(z80_port_1_control).l	; test Port A Ctrl
		bne.s	PortA_OK
		tst.w	(z80_expansion_control).l

PortA_OK:				; CODE XREF: ROM:0000020Cj
		bne.s	PortC_OK
		lea	InitValues(pc),a5
		movem.w	(a5)+,d5-d7
		movem.l	(a5)+,a0-a4
		move.b	-$10FF(a1),d0	; get hardware version
		andi.b	#$F,d0
		beq.s	SkipSecurity
		move.l	#'SEGA',$2F00(a1)

SkipSecurity:				; CODE XREF: ROM:0000022Aj
		move.w	(a4),d0
		moveq	#0,d0
		movea.l	d0,a6
		move.l	a6,usp
		moveq	#$17,d1

VDPInitLoop:				; CODE XREF: ROM:00000244j
		move.b	(a5)+,d5
		move.w	d5,(a4)
		add.w	d7,d5
		dbf	d1,VDPInitLoop
		move.l	(a5)+,(a4)
		move.w	d0,(a3)
		move.w	d7,(a1)
		move.w	d7,(a2)

WaitForZ80:				; CODE XREF: ROM:00000252j
		btst	d0,(a1)
		bne.s	WaitForZ80
		moveq	#$25,d2

Z80InitLoop:				; CODE XREF: ROM:00000258j
		move.b	(a5)+,(a0)+
		dbf	d2,Z80InitLoop
		move.w	d0,(a2)
		move.w	d0,(a1)
		move.w	d7,(a2)

ClearRAMLoop:				; CODE XREF: ROM:loc_264j
		move.l	d0,-(a6)
		dbf	d6,ClearRAMLoop
		move.l	(a5)+,(a4)
		move.l	(a5)+,(a4)
		moveq	#$1F,d3

ClearCRAMLoop:				; CODE XREF: ROM:00000270j
		move.l	d0,(a3)
		dbf	d3,ClearCRAMLoop
		move.l	(a5)+,(a4)
		moveq	#$13,d4

ClearVSRAMLoop:				; CODE XREF: ROM:0000027Aj
		move.l	d0,(a3)
		dbf	d4,ClearVSRAMLoop
		moveq	#3,d5

PSGInitLoop:				; CODE XREF: ROM:00000284j
		move.b	(a5)+,$11(a3)
		dbf	d5,PSGInitLoop
		move.w	d0,(a2)
		movem.l	(a6),d0-a6
		move	#$2700,sr

PortC_OK:				; DATA XREF: ROM:PortA_OKt
		bra.s	GameProgram
; ---------------------------------------------------------------------------
InitValues:	dc.w $8000		; DATA XREF: ROM:00000216t
		dc.w $3FFF
		dc.w $100

		dc.l z80_ram		; Z80 RAM start	location
        	dc.l z80_bus_request		; Z80 bus request
		dc.l z80_reset		; Z80 reset
		dc.l vdp_data_port		; VDP data port
		dc.l vdp_control_port		; VDP control port

		dc.b   4,$14,$30,$3C	; values for VDP registers
		dc.b   7,$6C,  0,  0
		dc.b   0,  0,$FF,  0
		dc.b $81,$37,  0,  1
		dc.b   1,  0,  0,$FF
		dc.b $FF,  0,  0,$80

		dc.l $40000080		; value	for VRAM fill

		dc.b $AF,  1,$D9,$1F,$11,$27,  0,$21,$26,  0,$F9,$77,$ED,$B0,$DD,$E1; Z80 instructions
		dc.b $FD,$E1,$ED,$47,$ED,$4F,$D1,$E1,$F1,  8,$D9,$C1,$D1,$E1,$F1,$F9
		dc.b $F3,$ED,$56,$36,$E9,$E9

		dc.w $8104		; VDP display mode
		dc.w $8F02		; VDP increment
		dc.l $C0000000		; value	for CRAM Write mode
		dc.l $40000010		; value	for VSRAM write	mode

		dc.b  $9F, $BF,	$DF, $FF; values for PSG channel volumes
; ---------------------------------------------------------------------------

GameProgram:				; CODE XREF: ROM:PortC_OKj
		tst.w	(vdp_control_port).l
		btst	#6,($A1000D).l
		beq.s	ChecksumCheck
		cmpi.l	#'init',($FFFFFFFC).w
		beq.w	AlreadyInit

ChecksumCheck:				; CODE XREF: ROM:0000030Ej
		movea.l	#ErrorTrap,a0
		movea.l	#ROMEnd,a1	; ROM end location (leftover from Sonic	1)
		move.l	(a1),d0

loc_32A:
		move.l	#$7FFFF,d0
		moveq	#0,d1

ChksumChkLoop:				; CODE XREF: ROM:00000336j
		add.w	(a0)+,d1
		cmp.l	a0,d0
		bcc.s	ChksumChkLoop
		movea.l	#Checksum,a1	; ROM Checksum (leftover from Sonic 1)
		cmp.w	(a1),d1
		nop
		nop
		lea	(v_systemstack).w,a6
		moveq	#0,d7
		move.w	#$7F,d6

ClearSomeRAMLoop:			; CODE XREF: ROM:00000350j
		move.l	d7,(a6)+
		dbf	d6,ClearSomeRAMLoop
		move.b	($A10001).l,d0
		andi.b	#$C0,d0
		move.b	d0,($FFFFFFF8).w
		move.l	#'init',($FFFFFFFC).w

AlreadyInit:				; CODE XREF: ROM:00000318j
		lea	($FF0000).l,a6
		moveq	#0,d7
		move.w	#$3F7F,d6

ClearRemainingRAMLoop:			; CODE XREF: ROM:00000378j
		move.l	d7,(a6)+
		dbf	d6,ClearRemainingRAMLoop
		bsr.w	VDPRegSetup
		bsr.w	SoundDriverLoad
		bsr.w	JoypadInit
		move.b	#0,(v_gamemode).w

MainGameLoop:				; CODE XREF: ROM:0000039Aj
		move.b	(v_gamemode).w,d0
		andi.w	#$1C,d0
		jsr	GameModeArray(pc,d0.w)
		bra.s	MainGameLoop
; ---------------------------------------------------------------------------

GameModeArray:
		bra.w	SegaScreen
; ---------------------------------------------------------------------------
		bra.w	TitleScreen
; ---------------------------------------------------------------------------
		bra.w	Level
; ---------------------------------------------------------------------------
		bra.w	Level
; ---------------------------------------------------------------------------
		bra.w	GM_Special
; ---------------------------------------------------------------------------

ChecksumError:
		bsr.w	VDPRegSetup
		move.l	#$C0000000,(vdp_control_port).l
		moveq	#$3F,d7

ChksumErr_RedFill:			; CODE XREF: ROM:000003C8j
		move.w	#$E,(vdp_data_port).l
		dbf	d7,ChksumErr_RedFill

ChksumErr_InfLoop:			; CODE XREF: ROM:ChksumErr_InfLoopj
		bra.s	*
; ---------------------------------------------------------------------------

BusError:				; DATA XREF: ROM:00000000o
		move.b	#2,($FFFFFC44).w
		bra.s	ErrorMsg_TwoAddresses
; ---------------------------------------------------------------------------

AddressError:				; DATA XREF: ROM:00000000o
		move.b	#4,($FFFFFC44).w
		bra.s	ErrorMsg_TwoAddresses
; ---------------------------------------------------------------------------

IllegalInstr:				; DATA XREF: ROM:00000000o
		move.b	#6,($FFFFFC44).w
		addq.l	#2,2(sp)
		bra.s	ErrorMessage
; ---------------------------------------------------------------------------

ZeroDivide:				; DATA XREF: ROM:00000000o
		move.b	#8,($FFFFFC44).w
		bra.s	ErrorMessage
; ---------------------------------------------------------------------------

ChkInstr:				; DATA XREF: ROM:00000000o
		move.b	#$A,($FFFFFC44).w
		bra.s	ErrorMessage
; ---------------------------------------------------------------------------

TrapvInstr:				; DATA XREF: ROM:00000000o
		move.b	#$C,($FFFFFC44).w
		bra.s	ErrorMessage
; ---------------------------------------------------------------------------

PrivilegeViol:			; DATA XREF: ROM:00000000o
		move.b	#$E,($FFFFFC44).w
		bra.s	ErrorMessage
; ---------------------------------------------------------------------------

Trace:					; DATA XREF: ROM:00000000o
		move.b	#$10,($FFFFFC44).w
		bra.s	ErrorMessage
; ---------------------------------------------------------------------------

Line1010Emu:				; DATA XREF: ROM:00000000o
		move.b	#$12,($FFFFFC44).w
		addq.l	#2,2(sp)
		bra.s	ErrorMessage
; ---------------------------------------------------------------------------

Line1111Emu:				; DATA XREF: ROM:00000000o
		move.b	#$14,($FFFFFC44).w
		addq.l	#2,2(sp)
		bra.s	ErrorMessage
; ---------------------------------------------------------------------------

ErrorExcept:				; DATA XREF: ROM:00000000o
		move.b	#0,($FFFFFC44).w
		bra.s	ErrorMessage
; ---------------------------------------------------------------------------

ErrorMsg_TwoAddresses:			; CODE XREF: ROM:000003D4j
		move	#$2700,sr
		addq.w	#2,sp
		move.l	(sp)+,($FFFFFC40).w
		addq.w	#2,sp
		movem.l	d0-a7,($FFFFFC00).w
		bsr.w	ShowErrorMsg
		move.l	2(sp),d0
		bsr.w	ShowErrAddress
		move.l	($FFFFFC40).w,d0
		bsr.w	ShowErrAddress
		bra.s	ErrorMsg_Wait
; ---------------------------------------------------------------------------

ErrorMessage:				; CODE XREF: ROM:000003E8j
		move	#$2700,sr
		movem.l	d0-a7,($FFFFFC00).w
		bsr.w	ShowErrorMsg
		move.l	2(sp),d0
		bsr.w	ShowErrAddress

ErrorMsg_Wait:				; CODE XREF: ROM:00000458j
		bsr.w	Error_WaitForC
		movem.l	($FFFFFC00).w,d0-a7
		move	#$2300,sr
		rte

; =============== S U B	R O U T	I N E =======================================


ShowErrorMsg:				; CODE XREF: ROM:00000444p
		lea	(vdp_data_port).l,a6
		move.l	#$78000003,(vdp_control_port).l
		lea	(Art_Text).l,a0
		move.w	#$27F,d1

Error_LoadGfx:				; CODE XREF: ShowErrorMsg+1Cj
		move.w	(a0)+,(a6)
		dbf	d1,Error_LoadGfx
		moveq	#0,d0
		move.b	($FFFFFC44).w,d0

loc_4A6:
		move.w	ErrorText(pc,d0.w),d0
		lea	ErrorText(pc,d0.w),a0
		move.l	#$46040003,(vdp_control_port).l
		moveq	#$12,d1

Error_CharsLoop:			; CODE XREF: ShowErrorMsg+44j
		moveq	#0,d0
		move.b	(a0)+,d0
		addi.w	#$790,d0
		move.w	d0,(a6)
		dbf	d1,Error_CharsLoop
		rts
; End of function ShowErrorMsg

; ---------------------------------------------------------------------------
ErrorText:	dc.w @exception-ErrorText, @bus-ErrorText
		dc.w @address-ErrorText, @illinstruct-ErrorText
		dc.w @zerodivide-ErrorText, @chkinstruct-ErrorText
		dc.w @trapv-ErrorText, @privilege-ErrorText
		dc.w @trace-ErrorText, @line1010-ErrorText
		dc.w @line1111-ErrorText
@exception:	dc.b "ERROR EXCEPTION    "
@bus:		dc.b "BUS ERROR          "
@address:	dc.b "ADDRESS ERROR      "
@illinstruct:	dc.b "ILLEGAL INSTRUCTION"
@zerodivide:	dc.b "@ERO DIVIDE        "
@chkinstruct:	dc.b "CHK INSTRUCTION    "
@trapv:		dc.b "TRAPV INSTRUCTION  "
@privilege:	dc.b "PRIVILEGE VIOLATION"
@trace:		dc.b "TRACE              "
@line1010:	dc.b "LINE 1010 EMULATOR "
@line1111:	dc.b "LINE 1111 EMULATOR "
		even

; =============== S U B	R O U T	I N E =======================================


ShowErrAddress:				; CODE XREF: ROM:0000044Cp
					; ROM:00000454p ...
		move.w	#$7CA,(a6)
		moveq	#7,d2

ShowErrAddress_DigitLoop:		; CODE XREF: ShowErrAddress+Aj
		rol.l	#4,d0
		bsr.s	ShowErrDigit
		dbf	d2,ShowErrAddress_DigitLoop
		rts
; End of function ShowErrAddress


; =============== S U B	R O U T	I N E =======================================


ShowErrDigit:				; CODE XREF: ShowErrAddress+8p
		move.w	d0,d1
		andi.w	#$F,d1
		cmpi.w	#$A,d1
		bcs.s	ShowErrDigit_NoOverflow
		addq.w	#7,d1

ShowErrDigit_NoOverflow:		; CODE XREF: ShowErrDigit+Aj
		addi.w	#$7C0,d1
		move.w	d1,(a6)
		rts
; End of function ShowErrDigit


; =============== S U B	R O U T	I N E =======================================


Error_WaitForC:				; CODE XREF: ROM:ErrorMsg_Waitp
					; Error_WaitForC+Aj
		bsr.w	ReadJoypads
		cmpi.b	#$20,(v_jpadpress1).w
		bne.w	Error_WaitForC
		rts
; End of function Error_WaitForC

; ---------------------------------------------------------------------------
Art_Text:	incbin "artunc\menutext.bin"
                even
; ---------------------------------------------------------------------------

VBlank:					; DATA XREF: ROM:00000000o
		movem.l	d0-a6,-(sp)
		tst.b	($FFFFF62A).w
		beq.s	VBla_00

loc_B12:				; CODE XREF: ROM:00000B1Cj
		move.w	(vdp_control_port).l,d0
		andi.w	#8,d0
		beq.s	loc_B12
		move.l	#$40000010,(vdp_control_port).l
		move.l	(v_scrposy_dup).w,(vdp_data_port).l
		btst	#6,($FFFFFFF8).w
		beq.s	loc_B40
		move.w	#$700,d0

loc_B3C:				; CODE XREF: ROM:loc_B3Cj
		dbf	d0,*

loc_B40:				; CODE XREF: ROM:00000B36j
		move.b	($FFFFF62A).w,d0
		move.b	#0,($FFFFF62A).w
		move.w	#1,($FFFFF644).w
		andi.w	#$3E,d0
		move.w	off_B6C(pc,d0.w),d0
		jsr	off_B6C(pc,d0.w)

loc_B5C:				; CODE XREF: ROM:00000B9Cj
					; ROM:00000C3Aj ...
		jsr	(UpdateMusic).l

loc_B62:				; CODE XREF: ROM:00000DE2j
		addq.l	#1,(v_vbla_count).w
		movem.l	(sp)+,d0-a6
		rte
; ---------------------------------------------------------------------------
off_B6C:	dc.w VBla_00-off_B6C
                dc.w VBla_02-off_B6C
		dc.w loc_CBC-off_B6C
                dc.w loc_CD2-off_B6C
		dc.w loc_CE2-off_B6C
                dc.w loc_E02-off_B6C
		dc.w loc_EA2-off_B6C
                dc.w loc_F88-off_B6C
		dc.w loc_CD8-off_B6C
                dc.w loc_F98-off_B6C
		dc.w loc_CAE-off_B6C
                dc.w loc_FA4-off_B6C
		dc.w loc_EA2-off_B6C
; ---------------------------------------------------------------------------

VBla_00:				; CODE XREF: ROM:00000B10j
					; DATA XREF: ROM:off_B6Co
		cmpi.b	#$8C,(v_gamemode).w
		beq.s	loc_BA0
		cmpi.b	#8,(v_gamemode).w
		beq.s	loc_BA0
		cmpi.b	#$C,(v_gamemode).w
		bne.w	loc_B5C

loc_BA0:				; CODE XREF: ROM:00000B8Cj
					; ROM:00000B94j
		tst.b	($FFFFF730).w
		beq.w	loc_C3E
		move.w	(vdp_control_port).l,d0
		btst	#6,($FFFFFFF8).w
		beq.s	loc_BBE
		move.w	#$700,d0

loc_BBA:				; CODE XREF: ROM:loc_BBAj
		dbf	d0,*

loc_BBE:				; CODE XREF: ROM:00000BB4j
		move.w	#1,($FFFFF644).w
		stopZ80
                waitZ80
		tst.b	($FFFFF64E).w
		bne.s	loc_C02
		lea	(vdp_control_port).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bra.s	loc_C26
; ---------------------------------------------------------------------------

loc_C02:				; CODE XREF: ROM:00000BDAj
		lea	(vdp_control_port).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)

loc_C26:				; CODE XREF: ROM:00000C00j
		move.w	($FFFFF624).w,(a5)
		move.w	#$8230,(vdp_control_port).l
		startZ80
		bra.w	loc_B5C
; ---------------------------------------------------------------------------

loc_C3E:				; CODE XREF: ROM:00000BA4j
		move.w	(vdp_control_port).l,d0
		move.l	#$40000010,(vdp_control_port).l
		move.l	(v_scrposy_dup).w,(vdp_data_port).l
		btst	#6,($FFFFFFF8).w
		beq.s	loc_C66
		move.w	#$700,d0

loc_C62:				; CODE XREF: ROM:loc_C62j
		dbf	d0,*

loc_C66:				; CODE XREF: ROM:00000C5Cj
		move.w	#1,($FFFFF644).w
		move.w	($FFFFF624).w,(vdp_control_port).l
		move.w	#$8230,(vdp_control_port).l
		move.l	($FFFFF61E).w,($FFFFEEF0).w
		lea	(vdp_control_port).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bra.w	loc_B5C
; ---------------------------------------------------------------------------

VBla_02:				; DATA XREF: ROM:off_B6Co
		bsr.w	sub_103C

loc_CAE:				; DATA XREF: ROM:off_B6Co
		tst.w	(v_demolength).w
		beq.w	locret_CBA
		subq.w	#1,(v_demolength).w

locret_CBA:				; CODE XREF: ROM:00000CB2j
		rts
; ---------------------------------------------------------------------------

loc_CBC:				; DATA XREF: ROM:off_B6Co
		bsr.w	sub_103C
		bsr.w	sub_1732
		tst.w	(v_demolength).w
		beq.w	locret_CD0
		subq.w	#1,(v_demolength).w

locret_CD0:				; CODE XREF: ROM:00000CC8j
		rts
; ---------------------------------------------------------------------------

loc_CD2:				; DATA XREF: ROM:off_B6Co
		bsr.w	sub_103C
		rts
; ---------------------------------------------------------------------------

loc_CD8:				; DATA XREF: ROM:off_B6Co
		cmpi.b	#$10,(v_gamemode).w
		beq.w	loc_E02

loc_CE2:				; DATA XREF: ROM:off_B6Co
		stopZ80
		waitZ80
		bsr.w	ReadJoypads
		tst.b	($FFFFF64E).w
		bne.s	loc_D24

loc_CFE:
		lea	(vdp_control_port).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bra.s	loc_D48
; ---------------------------------------------------------------------------

loc_D24:				; CODE XREF: ROM:00000CFCj
		lea	(vdp_control_port).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)

loc_D48:				; CODE XREF: ROM:00000D22j
		move.w	($FFFFF624).w,(a5)
		move.w	#$8230,(vdp_control_port).l
		lea	(vdp_control_port).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96F09500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	(vdp_control_port).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bsr.w	Process_DMA
		startZ80
		movem.l	(v_screenposx).w,d0-d7
		movem.l	d0-d7,($FFFFEE60).w
		movem.l	(v_screenposx_2p).w,d0-d7
		movem.l	d0-d7,($FFFFEE80).w
		movem.l	($FFFFEE50).w,d0-d3
		movem.l	d0-d3,($FFFFEEA0).w
		move.l	($FFFFF61E).w,($FFFFEEF0).w
		cmpi.b	#$5C,($FFFFF625).w
		bcc.s	DemoTime
		move.b	#1,($FFFFF64F).w
		addq.l	#4,sp
		bra.w	loc_B62

; =============== S U B	R O U T	I N E =======================================


DemoTime:
		bsr.w	LoadTilesAsYouMove

loc_DEA:
		jsr	(HudUpdate).l
		bsr.w	loc_174E
		tst.w	(v_demolength).w
		beq.w	DemoTime_End
		subq.w	#1,(v_demolength).w

DemoTime_End:
		rts
; End of function DemoTime

; ---------------------------------------------------------------------------

loc_E02:
		stopZ80
		waitZ80
		bsr.w	ReadJoypads
		lea	(vdp_control_port).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	(vdp_control_port).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	(vdp_control_port).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96F09500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bsr.w	Process_DMA
		startZ80
		bsr.w	PalCycle_S1SS
		tst.w	(v_demolength).w
		beq.w	locret_EA0
		subq.w	#1,(v_demolength).w

locret_EA0:				; CODE XREF: ROM:00000E98j
		rts
; ---------------------------------------------------------------------------

loc_EA2:				; DATA XREF: ROM:off_B6Co
		stopZ80
		waitZ80
		bsr.w	ReadJoypads
		tst.b	($FFFFF64E).w
		bne.s	loc_EE4
		lea	(vdp_control_port).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bra.s	loc_F08
; ---------------------------------------------------------------------------

loc_EE4:				; CODE XREF: ROM:00000EBCj
		lea	(vdp_control_port).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)

loc_F08:				; CODE XREF: ROM:00000EE2j
		move.w	($FFFFF624).w,(a5)
		lea	(vdp_control_port).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96F09500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	(vdp_control_port).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bsr.w	Process_DMA
		startZ80
		movem.l	(v_screenposx).w,d0-d7
		movem.l	d0-d7,($FFFFEE60).w
		movem.l	($FFFFEE50).w,d0-d1
		movem.l	d0-d1,($FFFFEEA0).w
		bsr.w	LoadTilesAsYouMove
		jsr	(HudUpdate).l
		bsr.w	sub_1732
		rts
; ---------------------------------------------------------------------------

loc_F88:				; DATA XREF: ROM:off_B6Co
		bsr.w	sub_103C
		addq.b	#1,($FFFFF628).w
		move.b	#$E,($FFFFF62A).w
		rts
; ---------------------------------------------------------------------------

loc_F98:				; DATA XREF: ROM:off_B6Co
		bsr.w	sub_103C
		move.w	($FFFFF624).w,(a5)
		bra.w	sub_1732
; ---------------------------------------------------------------------------

loc_FA4:				; DATA XREF: ROM:off_B6Co
		stopZ80
		waitZ80
		bsr.w	ReadJoypads
		lea	(vdp_control_port).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	(vdp_control_port).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	(vdp_control_port).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96F09500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		startZ80
		tst.w	(v_demolength).w
		beq.w	locret_103A
		subq.w	#1,(v_demolength).w

locret_103A:				; CODE XREF: ROM:00001032j
		rts

; =============== S U B	R O U T	I N E =======================================


sub_103C:				; CODE XREF: ROM:VBla_02p ROM:loc_CBCp ...
		stopZ80
		waitZ80
		bsr.w	ReadJoypads
		tst.b	($FFFFF64E).w
		bne.s	loc_107E
		lea	(vdp_control_port).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bra.s	loc_10A2
; ---------------------------------------------------------------------------

loc_107E:				; CODE XREF: sub_103C+1Aj
		lea	(vdp_control_port).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)

loc_10A2:				; CODE XREF: sub_103C+40j
		lea	(vdp_control_port).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	(vdp_control_port).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96F09500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		startZ80
		rts
; End of function sub_103C

; ---------------------------------------------------------------------------

HBlank:					; DATA XREF: ROM:00000000o
		tst.w	($FFFFF644).w
		beq.w	locret_1184
		tst.w	(f_2player).w
		beq.w	HBlank_Not2pMode
		move.w	#0,($FFFFF644).w
		move.l	a5,-(sp)
		move.l	d0,-(sp)

loc_110E:				; CODE XREF: ROM:00001118j
		move.w	(vdp_control_port).l,d0
		andi.w	#4,d0
		beq.s	loc_110E
		move.w	(v_vdp_buffer1).w,d0
		andi.b	#$BF,d0
		move.w	d0,(vdp_control_port).l
		move.w	#$8228,(vdp_control_port).l
		move.l	#$40000010,(vdp_control_port).l
		move.l	($FFFFEEF0).w,(vdp_data_port).l
		lea	(vdp_control_port).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96EE9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)

loc_1166:				; CODE XREF: ROM:00001170j
		move.w	(vdp_control_port).l,d0
		andi.w	#4,d0
		beq.s	loc_1166
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0
		move.w	d0,(vdp_control_port).l
		move.l	(sp)+,d0
		movea.l	(sp)+,a5

locret_1184:				; CODE XREF: ROM:000010F8j
		rte
; ---------------------------------------------------------------------------

HBlank_Not2pMode:			; CODE XREF: ROM:00001100j
		move	#$2700,sr
		move.w	#0,($FFFFF644).w
		movem.l	a0-a1,-(sp)
		lea	(vdp_data_port).l,a1
		lea	($FFFFFA80).w,a0
		move.l	#$C0000000,4(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.w	#$8ADF,4(a1)
		movem.l	(sp)+,a0-a1
		tst.b	($FFFFF64F).w
		bne.s	loc_11F8
		rte
; ---------------------------------------------------------------------------

loc_11F8:				; CODE XREF: ROM:000011F4j
		clr.b	($FFFFF64F).w
		movem.l	d0-a6,-(sp)
		bsr.w	DemoTime
		jsr	(UpdateMusic).l
		movem.l	(sp)+,d0-a6
		rte

; =============== S U B	R O U T	I N E =======================================


JoypadInit:				; CODE XREF: ROM:00000384p
		stopZ80
		waitZ80
		moveq	#$40,d0
		move.b	d0,($A10009).l
		move.b	d0,($A1000B).l
		move.b	d0,($A1000D).l
		startZ80
		rts
; End of function JoypadInit


; =============== S U B	R O U T	I N E =======================================


ReadJoypads:
		lea	(v_jpadhold1).w,a0
		lea	($A10003).l,a1
		bsr.s	Joypad_Read
		addq.w	#2,a1

Joypad_Read:
		move.b	#0,(a1)
		nop
		nop
		move.b	(a1),d0
		lsl.b	#2,d0
		andi.b	#$C0,d0
		move.b	#$40,(a1)
		nop
		nop
		move.b	(a1),d1
		andi.b	#$3F,d1
		or.b	d1,d0
		not.b	d0
		move.b	(a0),d1
		eor.b	d0,d1
		move.b	d0,(a0)+
		and.b	d0,d1
		move.b	d1,(a0)+
		rts
; End of function Joypad_Read


; =============== S U B	R O U T	I N E =======================================


VDPRegSetup:				; CODE XREF: ROM:0000037Cp
					; ROM:ChecksumErrorp
		lea	(vdp_control_port).l,a0
		lea	(vdp_data_port).l,a1
		lea	(VDPRegSetup_Array).l,a2
		moveq	#$12,d7

VDPRegSetup_Loop:			; CODE XREF: VDPRegSetup+16j
		move.w	(a2)+,(a0)
		dbf	d7,VDPRegSetup_Loop
		move.w	(VDPRegSetup_Array+2).l,d0
		move.w	d0,(v_vdp_buffer1).w
		move.w	#$8ADF,($FFFFF624).w
		moveq	#0,d0
		move.l	#$40000010,(vdp_control_port).l
		move.w	d0,(a1)
		move.w	d0,(a1)
		move.l	#$C0000000,(vdp_control_port).l
		move.w	#$3F,d7	

VDPRegSetup_ClearCRAM:			; CODE XREF: VDPRegSetup+4Aj
		move.w	d0,(a1)
		dbf	d7,VDPRegSetup_ClearCRAM
		clr.l	(v_scrposy_dup).w
		clr.l	(v_scrposx_dup).w
		move.l	d1,-(sp)
		lea	(vdp_control_port).l,a5
		move.w	#$8F01,(a5)
		move.l	#$94FF93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$40000080,(a5)
		move.w	#0,(vdp_data_port).l

VDPRegSetup_DMAWait:			; CODE XREF: VDPRegSetup+80j
		move.w	(a5),d1
		btst	#1,d1
		bne.s	VDPRegSetup_DMAWait

loc_12FE:
		move.w	#$8F02,(a5)
		move.l	(sp)+,d1
		rts
; End of function VDPRegSetup

; ---------------------------------------------------------------------------
VDPRegSetup_Array:dc.w $8004		; DATA XREF: VDPRegSetup+Co
              	dc.w $8134,$8230,$8328,$8407; 0	; DATA XREF: VDPRegSetup+1Ar
		dc.w $857C,$8600,$8700,$8800; 4
		dc.w $8900,$8A00,$8B00,$8C81; 8
		dc.w $8D3F,$8E00,$8F02,$9001; 12
		dc.w $9100,$9200	; 16

; =============== S U B	R O U T	I N E =======================================


ClearScreen:				; CODE XREF: ROM:000030FCp
					; ROM:00003222p ...
		lea	(vdp_control_port).l,a5
		move.w	#$8F01,(a5)
		move.l	#$940F93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$40000083,(a5)
		move.w	#0,(vdp_data_port).l

ClearScreen_DMAWait:			; CODE XREF: ClearScreen+28j
		move.w	(a5),d1
		btst	#1,d1
		bne.s	ClearScreen_DMAWait
		move.w	#$8F02,(a5)
		lea	(vdp_control_port).l,a5
		move.w	#$8F01,(a5)
		move.l	#$940F93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$60000083,(a5)
		move.w	#0,(vdp_data_port).l

ClearScreen_DMA2Wait:			; CODE XREF: ClearScreen+56j
		move.w	(a5),d1
		btst	#1,d1
		bne.s	ClearScreen_DMA2Wait
		move.w	#$8F02,(a5)

loc_1388:
		clr.l	(v_scrposy_dup).w
		clr.l	(v_scrposx_dup).w
		lea	($FFFFF800).w,a1
		moveq	#0,d0
		move.w	#$A0,d1	

ClearScreen_ClearBuffer1:		; CODE XREF: ClearScreen+70j
		move.l	d0,(a1)+
		dbf	d1,ClearScreen_ClearBuffer1
		lea	(v_hscrolltablebuffer).w,a1
		moveq	#0,d0
		move.w	#$100,d1

ClearScreen_ClearBuffer2:		; CODE XREF: ClearScreen+80j
		move.l	d0,(a1)+
		dbf	d1,ClearScreen_ClearBuffer2
		rts
; End of function ClearScreen


; =============== S U B	R O U T	I N E =======================================


SoundDriverLoad:			; CODE XREF: ROM:00000380p
		nop
		stopZ80
		resetZ80
		lea	(Kos_Z80).l,a0
		lea	(z80_ram).l,a1
		bsr.w	KosDec
		resetZ80a
		nop
		nop
		nop
		nop
		resetZ80
		startZ80
		rts
; End of function SoundDriverLoad


; =============== S U B	R O U T	I N E =======================================


PlaySound:				; CODE XREF: ROM:00003CF0p
					; ROM:0000510Ep ...
		move.b	d0,(v_snddriver_ram+v_soundqueue0).w
		rts
; End of function PlaySound


; =============== S U B	R O U T	I N E =======================================


PlaySound_Special:			; CODE XREF: ROM:000030BCp
					; ROM:000031AAp ...
		move.b	d0,(v_snddriver_ram+v_soundqueue1).w
		rts
; End of function PlaySound_Special

; ---------------------------------------------------------------------------

PlaySound_Unk:
		move.b	d0,(v_snddriver_ram+v_soundqueue2).w
		rts

; =============== S U B	R O U T	I N E =======================================


Pause:
		nop
		tst.b	($FFFFFE12).w
		beq.s	Unpause
		tst.w	($FFFFF63A).w
		bne.s	Pause_AlreadyPaused
		btst	#7,(v_jpadpress1).w
		beq.s	Pause_DoNothing

Pause_AlreadyPaused:			; CODE XREF: Pause+Cj
		move.w	#1,($FFFFF63A).w

loc_1424:
		move.b	#1,(v_snddriver_ram+f_pausemusic).w

Pause_Loop:				; CODE XREF: Pause+5Aj
		move.b	#$10,($FFFFF62A).w
		bsr.w	DelayProgram
		tst.b	($FFFFFFE1).w
		beq.s	Pause_CheckStart
		btst	#6,(v_jpadpress1).w
		beq.s	Pause_CheckBC
		move.b	#4,(v_gamemode).w
		nop
		bra.s	loc_1464
; ---------------------------------------------------------------------------

Pause_CheckBC:				; CODE XREF: Pause+38j
		btst	#4,(v_jpadhold1).w
		bne.s	loc_1472
		btst	#5,(v_jpadpress1).w
		bne.s	loc_1472

Pause_CheckStart:			; CODE XREF: Pause+30j
		btst	#7,(v_jpadpress1).w
		beq.s	Pause_Loop

loc_1464:				; CODE XREF: Pause+42j
		move.b	#$80,(v_snddriver_ram+f_pausemusic).w

Unpause:				; CODE XREF: Pause+6j
		move.w	#0,($FFFFF63A).w

Pause_DoNothing:			; CODE XREF: Pause+14j
		rts
; ---------------------------------------------------------------------------

loc_1472:				; CODE XREF: Pause+4Aj	Pause+52j
		move.w	#1,($FFFFF63A).w
		move.b	#$80,(v_snddriver_ram+f_pausemusic).w
		rts
; End of function Pause


; =============== S U B	R O U T	I N E =======================================


ShowVDPGraphics:			; CODE XREF: ROM:00003138p
					; ROM:0000314Cp ...
		lea	(vdp_data_port).l,a6
		move.l	#$800000,d4

ShowVDPGraphics_LineLoop:		; CODE XREF: ShowVDPGraphics+1Aj
		move.l	d0,4(a6)
		move.w	d1,d3

ShowVDPGraphics_TileLoop:		; CODE XREF: ShowVDPGraphics+14j
		move.w	(a1)+,(a6)
		dbf	d3,ShowVDPGraphics_TileLoop
		add.l	d4,d0
		dbf	d2,ShowVDPGraphics_LineLoop
		rts
; End of function ShowVDPGraphics


                include "_inc\DMA Queue.asm"
                include "_inc\Nemesis Decompression.asm"


; =============== S U B	R O U T	I N E =======================================


LoadPLC:				; CODE XREF: ROM:00003BACp
					; ROM:00003BB2p ...
		movem.l	a1-a2,-(sp)

loc_1674:
		lea	(ArtLoadCues).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		lea	($FFFFF680).w,a2

loc_1688:				; CODE XREF: LoadPLC+1Ej
		tst.l	(a2)
		beq.s	loc_1690
		addq.w	#6,a2
		bra.s	loc_1688
; ---------------------------------------------------------------------------

loc_1690:				; CODE XREF: LoadPLC+1Aj
		move.w	(a1)+,d0
		bmi.s	loc_169C

loc_1694:				; CODE XREF: LoadPLC+28j
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+
		dbf	d0,loc_1694

loc_169C:				; CODE XREF: LoadPLC+22j
		movem.l	(sp)+,a1-a2
		rts
; End of function LoadPLC


; =============== S U B	R O U T	I N E =======================================


LoadPLC2:				; CODE XREF: ROM:000033C0p
					; SignpostArtLoad+32j ...
		movem.l	a1-a2,-(sp)

loc_16A6:
		lea	(ArtLoadCues).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		bsr.s	ClearPLC
		lea	($FFFFF680).w,a2
		move.w	(a1)+,d0
		bmi.s	loc_16C8

loc_16C0:				; CODE XREF: LoadPLC2+22j
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+
		dbf	d0,loc_16C0

loc_16C8:				; CODE XREF: LoadPLC2+1Cj
		movem.l	(sp)+,a1-a2
		rts
; End of function LoadPLC2


; =============== S U B	R O U T	I N E =======================================


ClearPLC:				; CODE XREF: LoadPLC2+14p
					; ROM:000030C0p ...
		lea	($FFFFF680).w,a2
		moveq	#$1F,d0

loc_16D4:				; CODE XREF: ClearPLC+8j
		clr.l	(a2)+
		dbf	d0,loc_16D4
		rts
; End of function ClearPLC


; =============== S U B	R O U T	I N E =======================================


RunPLC:					; CODE XREF: Pal_FadeTo+2Ep
					; Pal_FadeFrom+16p ...
		tst.l	($FFFFF680).w
		beq.s	locret_1730
		tst.w	($FFFFF6F8).w
		bne.s	locret_1730
		movea.l	($FFFFF680).w,a0
		lea	NemPCD_WriteRowToVDP(pc),a3
		nop
		lea	(v_ngfx_buffer).w,a1
		move.w	(a0)+,d2
		bpl.s	loc_16FE
		adda.w	#$A,a3

loc_16FE:				; CODE XREF: RunPLC+1Cj
		andi.w	#$7FFF,d2
		move.w	d2,($FFFFF6F8).w
		bsr.w	NemDec_BuildCodeTable
		move.b	(a0)+,d5
		asl.w	#8,d5
		move.b	(a0)+,d5
		moveq	#$10,d6
		moveq	#0,d0
		move.l	a0,($FFFFF680).w
		move.l	a3,($FFFFF6E0).w
		move.l	d0,($FFFFF6E4).w
		move.l	d0,($FFFFF6E8).w
		move.l	d0,($FFFFF6EC).w
		move.l	d5,($FFFFF6F0).w
		move.l	d6,($FFFFF6F4).w

locret_1730:				; CODE XREF: RunPLC+4j	RunPLC+Aj
		rts
; End of function RunPLC


; =============== S U B	R O U T	I N E =======================================


sub_1732:				; CODE XREF: ROM:00000CC0p
					; ROM:00000F82p ...
		tst.w	($FFFFF6F8).w
		beq.w	locret_17CA
		move.w	#9,($FFFFF6FA).w
		moveq	#0,d0
		move.w	($FFFFF684).w,d0
		addi.w	#$120,($FFFFF684).w
		bra.s	loc_1766
; ---------------------------------------------------------------------------

loc_174E:				; CODE XREF: DemoTime+Ap
		tst.w	($FFFFF6F8).w
		beq.s	locret_17CA
		move.w	#3,($FFFFF6FA).w
		moveq	#0,d0
		move.w	($FFFFF684).w,d0
		addi.w	#$60,($FFFFF684).w 

loc_1766:				; CODE XREF: sub_1732+1Aj
		lea	(vdp_control_port).l,a4
		lsl.l	#2,d0
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,(a4)
		subq.w	#4,a4
		movea.l	($FFFFF680).w,a0
		movea.l	($FFFFF6E0).w,a3
		move.l	($FFFFF6E4).w,d0
		move.l	($FFFFF6E8).w,d1
		move.l	($FFFFF6EC).w,d2
		move.l	($FFFFF6F0).w,d5
		move.l	($FFFFF6F4).w,d6
		lea	($FFFFAA00).w,a1

loc_179A:				; CODE XREF: sub_1732+7Aj
		movea.w	#8,a5
		bsr.w	NemPCD_NewRow
		subq.w	#1,($FFFFF6F8).w
		beq.s	loc_17CC
		subq.w	#1,($FFFFF6FA).w
		bne.s	loc_179A
		move.l	a0,($FFFFF680).w
		move.l	a3,($FFFFF6E0).w
		move.l	d0,($FFFFF6E4).w
		move.l	d1,($FFFFF6E8).w
		move.l	d2,($FFFFF6EC).w
		move.l	d5,($FFFFF6F0).w
		move.l	d6,($FFFFF6F4).w

locret_17CA:				; CODE XREF: sub_1732+4j sub_1732+20j
		rts
; ---------------------------------------------------------------------------

loc_17CC:				; CODE XREF: sub_1732+74j
		lea	($FFFFF680).w,a0
		moveq	#$15,d0

loc_17D2:				; CODE XREF: sub_1732+A4j
		move.l	6(a0),(a0)+
		dbf	d0,loc_17D2
		rts
; End of function sub_1732


; =============== S U B	R O U T	I N E =======================================


RunPLC_ROM:				; CODE XREF: ROM:0000508Ep
		lea	(ArtLoadCues).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		move.w	(a1)+,d1

loc_17EE:				; CODE XREF: RunPLC_ROM+2Cj
		movea.l	(a1)+,a0
		moveq	#0,d0
		move.w	(a1)+,d0
		lsl.l	#2,d0
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,(vdp_control_port).l
		bsr.w	NemDec
		dbf	d1,loc_17EE
		rts
; End of function RunPLC_ROM


                include "_inc\Enigma Decompression.asm"
                include "_inc\Kosinski Decompression.asm"
                include "_inc\Kid Chameleon Decompression.asm"


; =============== S U B	R O U T	I N E =======================================


PalCycle_Load:				; CODE XREF: ROM:00003F62p
		moveq	#0,d2
		moveq	#0,d0
		move.b	(v_zone).w,d0
		add.w	d0,d0
		move.w	PalCycle(pc,d0.w),d0
		jmp	PalCycle(pc,d0.w)
		rts
; ---------------------------------------------------------------------------
PalCycle:	dc.w PalCycle_GHZ-PalCycle ; DATA XREF:	ROM:PalCycleo
		dc.w PalCycle_CPZ-PalCycle
		dc.w PalCycle_CPZ-PalCycle
		dc.w PalCycle_EHZ-PalCycle
		dc.w PalCycle_HPZ-PalCycle
		dc.w PalCycle_HTZ-PalCycle
		dc.w PalCycle_GHZ-PalCycle
; ---------------------------------------------------------------------------
;-------------------------------
; Leftover palette cycling subroutine
;  for Sonic 1 title screen
;-------------------------------

PalCycle_S1TitleScreen:
		lea	(Pal_S1TitleCyc).l,a0
		bra.s	loc_1E7C
; ---------------------------------------------------------------------------

PalCycle_GHZ:				; DATA XREF: ROM:PalCycleo
					; ROM:00001E6Co
		lea	(Pal_GHZCyc).l,a0

loc_1E7C:				; CODE XREF: ROM:00001E74j
		subq.w	#1,($FFFFF634).w
		bpl.s	locret_1EA2
		move.w	#5,($FFFFF634).w
		move.w	($FFFFF632).w,d0
		addq.w	#1,($FFFFF632).w
		andi.w	#3,d0
		lsl.w	#3,d0
		lea	($FFFFFB50).w,a1
		move.l	(a0,d0.w),(a1)+
		move.l	4(a0,d0.w),(a1)

locret_1EA2:				; CODE XREF: ROM:00001E80j
		rts
; ---------------------------------------------------------------------------

PalCycle_CPZ:				; DATA XREF: ROM:00001E62o
					; ROM:00001E64o
		subq.w	#1,($FFFFF634).w
		bpl.s	locret_1F14
		move.w	#7,($FFFFF634).w
		lea	(Pal_CPZCyc1).l,a0
		move.w	($FFFFF632).w,d0
		addq.w	#6,($FFFFF632).w
		cmpi.w	#$36,($FFFFF632).w 
		bcs.s	loc_1ECC
		move.w	#0,($FFFFF632).w

loc_1ECC:				; CODE XREF: ROM:00001EC4j
		lea	($FFFFFB78).w,a1
		move.l	(a0,d0.w),(a1)+
		move.w	4(a0,d0.w),(a1)
		lea	(Pal_CPZCyc2).l,a0
		move.w	($FFFFF652).w,d0
		addq.w	#2,($FFFFF652).w
		cmpi.w	#$2A,($FFFFF652).w 
		bcs.s	loc_1EF4
		move.w	#0,($FFFFF652).w

loc_1EF4:				; CODE XREF: ROM:00001EECj
		move.w	(a0,d0.w),($FFFFFB7E).w
		lea	(Pal_CPZCyc3).l,a0
		move.w	($FFFFF654).w,d0
		addq.w	#2,($FFFFF654).w
		andi.w	#$1E,($FFFFF654).w
		move.w	(a0,d0.w),($FFFFFB5E).w

locret_1F14:				; CODE XREF: ROM:00001EA8j
		rts
; ---------------------------------------------------------------------------

PalCycle_HPZ:				; DATA XREF: ROM:00001E68o
		subq.w	#1,($FFFFF634).w
		bpl.s	locret_1F56
		move.w	#4,($FFFFF634).w
		lea	(Pal_HPZCyc1).l,a0
		move.w	($FFFFF632).w,d0
		subq.w	#2,($FFFFF632).w
		bcc.s	loc_1F38
		move.w	#6,($FFFFF632).w

loc_1F38:				; CODE XREF: ROM:00001F30j
		lea	($FFFFFB72).w,a1
		move.l	(a0,d0.w),(a1)+
		move.l	4(a0,d0.w),(a1)
		lea	(Pal_HPZCyc2).l,a0
		lea	($FFFFFAF2).w,a1
		move.l	(a0,d0.w),(a1)+
		move.l	4(a0,d0.w),(a1)

locret_1F56:				; CODE XREF: ROM:00001F1Aj
		rts
; ---------------------------------------------------------------------------

PalCycle_EHZ:				; DATA XREF: ROM:00001E66o
		lea	(Pal_EHZCyc).l,a0
		subq.w	#1,($FFFFF634).w
		bpl.s	locret_1F84
		move.w	#7,($FFFFF634).w
		move.w	($FFFFF632).w,d0
		addq.w	#1,($FFFFF632).w
		andi.w	#3,d0
		lsl.w	#3,d0
		move.l	(a0,d0.w),($FFFFFB26).w
		move.l	4(a0,d0.w),($FFFFFB3C).w

locret_1F84:				; CODE XREF: ROM:00001F62j
		rts
; ---------------------------------------------------------------------------

PalCycle_HTZ:				; DATA XREF: ROM:00001E6Ao
		lea	(Pal_HTZCyc1).l,a0
		subq.w	#1,($FFFFF634).w
		bpl.s	locret_1FB8
		move.w	#0,($FFFFF634).w
		move.w	($FFFFF632).w,d0
		addq.w	#1,($FFFFF632).w
		andi.w	#$F,d0
		move.b	Pal_HTZCyc2(pc,d0.w),($FFFFF635).w
		lsl.w	#3,d0
		move.l	(a0,d0.w),($FFFFFB26).w
		move.l	4(a0,d0.w),($FFFFFB3C).w

locret_1FB8:				; CODE XREF: ROM:00001F90j
		rts
; ---------------------------------------------------------------------------
Pal_HTZCyc2:	dc.w  $B0B, $B0A, $80A,	$B0B, $B0B, $D0F, $D0B,	$B0B; 0
Pal_S1TitleCyc: incbin "palette\Cycle - Title Screen Water.bin"
                even
Pal_GHZCyc:	incbin "palette\Cycle - GHZ.bin"
                even
Pal_EHZCyc:	dc.b  $A,$86, $E,$86, $E,$A8, $E,$CA, $E,$CA, $A,$86, $E,$86, $E,$A8; 0
					; DATA XREF: ROM:PalCycle_EHZo
		dc.b  $E,$A8, $E,$CA, $A,$86, $E,$86, $E,$86, $E,$A8, $E,$CA, $A,$86; 16
Pal_HTZCyc1:	dc.w	$E,  $6E,  $AE,	 $EE,  $EE,   $E,  $6E,	 $AE, $2CE,  $EE,   $E,	 $6E,  $6E, $4EE, $8EE,	 $2E; 0
					; DATA XREF: ROM:PalCycle_HTZo
		dc.w   $4E,  $8E, $6EE,	$AEE, $8EE,  $2E,  $6E,	$4EE, $2CE,  $EE,   $E,	 $6E,  $6E, $2CE,  $EE,	  $E; 16
		dc.w	$E,  $6E,  $AE,	 $EE,  $CE,   $C,  $4E,	 $8E,  $6E,  $AC,   $A,	 $2E,	$C,  $4C,  $8E,	   8; 32
		dc.w	$A,  $2E,  $6E,	 $AC,  $CE,   $C,  $4E,	 $8E,  $AE,  $EE,   $E,	 $6E,  $6E,  $AE,  $EE,	  $E; 48
Pal_CPZCyc1:	dc.w  $E40, $C00, $C00,	$E60, $C20, $C00, $E40,	$E40, $C00, $C20, $E60,	$C20, $C00, $E40, $C40,	$C00; 0
					; DATA XREF: ROM:00001EB0o
		dc.w  $C20, $E40, $C00,	$C00, $E60, $C20, $C00,	$E40, $E20, $C00, $C20;	16
Pal_CPZCyc2:	dc.w   $E0,  $C2,  $A4,	 $86,  $68,  $4A,  $2C,	  $E, $20C, $40A, $608,	$806, $A04, $C02, $E00,	$C20; 0
					; DATA XREF: ROM:00001ED8o
		dc.w  $A40, $860, $680,	$4A0, $2C0; 16
Pal_CPZCyc3:	dc.w	$E,   $C,   $A,	   8,	 6,    4,    2,	   4,	 6,    8,   $A,	  $C,	$E,  $2E,  $4E,	 $2E; 0
					; DATA XREF: ROM:00001EFAo
Pal_HPZCyc1:	dc.w  $E44, $E82, $EA8,	$EEE, $E44, $E82, $EA8,	$EEE; 0
					; DATA XREF: ROM:00001F22o
Pal_HPZCyc2:	dc.w  $E84, $EA6, $EC6,	$EE6, $E84, $EA6, $EC6,	$EE6; 0
					; DATA XREF: ROM:00001F44o

; =============== S U B	R O U T	I N E =======================================


Pal_FadeTo:				; CODE XREF: ROM:0000327Cp
					; ROM:000033F0p
		move.w	#$3F,($FFFFF626).w 

Pal_FadeTo2:				; CODE XREF: ROM:00003EE0p
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		moveq	#0,d1
		move.b	($FFFFF627).w,d0

loc_2162:				; CODE XREF: Pal_FadeTo+1Aj
		move.w	d1,(a0)+
		dbf	d0,loc_2162
		move.w	#$15,d4

loc_216C:				; CODE XREF: Pal_FadeTo+32j
		move.b	#$12,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.s	Pal_FadeIn
		bsr.w	RunPLC
		dbf	d4,loc_216C
		rts
; End of function Pal_FadeTo


; =============== S U B	R O U T	I N E =======================================


Pal_FadeIn:				; CODE XREF: Pal_FadeTo+2Cp
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		lea	($FFFFFB80).w,a1
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	($FFFFF627).w,d0

loc_2198:				; CODE XREF: Pal_FadeIn+18j
		bsr.s	Pal_AddColor
		dbf	d0,loc_2198
		tst.b	($FFFFF730).w
		beq.s	locret_21C0
		moveq	#0,d0
		lea	($FFFFFA80).w,a0
		lea	($FFFFFA00).w,a1
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	($FFFFF627).w,d0

loc_21BA:				; CODE XREF: Pal_FadeIn+3Aj
		bsr.s	Pal_AddColor
		dbf	d0,loc_21BA

locret_21C0:				; CODE XREF: Pal_FadeIn+20j
		rts
; End of function Pal_FadeIn


; =============== S U B	R O U T	I N E =======================================


Pal_AddColor:				; CODE XREF: Pal_FadeIn:loc_2198p
					; Pal_FadeIn:loc_21BAp
		move.w	(a1)+,d2
		move.w	(a0),d3
		cmp.w	d2,d3
		beq.s	Pal_NoAdd
		move.w	d3,d1
		addi.w	#$200,d1
		cmp.w	d2,d1
		bhi.s	Pal_AddGreen
		move.w	d1,(a0)+
		rts
; ---------------------------------------------------------------------------

Pal_AddGreen:				; CODE XREF: Pal_AddColor+10j
		move.w	d3,d1
		addi.w	#$20,d1	
		cmp.w	d2,d1
		bhi.s	Pal_AddRed
		move.w	d1,(a0)+
		rts
; ---------------------------------------------------------------------------

Pal_AddRed:				; CODE XREF: Pal_AddColor+1Ej
		addq.w	#2,(a0)+
		rts
; ---------------------------------------------------------------------------

Pal_NoAdd:				; CODE XREF: Pal_AddColor+6j
		addq.w	#2,a0
		rts
; End of function Pal_AddColor


; =============== S U B	R O U T	I N E =======================================


Pal_FadeFrom:				; CODE XREF: ROM:000030C4p
					; ROM:000031ECp ...
		move.w	#$3F,($FFFFF626).w 
		move.w	#$15,d4

loc_21F8:				; CODE XREF: Pal_FadeFrom+1Aj
		move.b	#$12,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.s	Pal_FadeOut
		bsr.w	RunPLC
		dbf	d4,loc_21F8
		rts
; End of function Pal_FadeFrom


; =============== S U B	R O U T	I N E =======================================


Pal_FadeOut:				; CODE XREF: Pal_FadeFrom+14p
					; ROM:0000400Ap
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		move.b	($FFFFF627).w,d0

loc_221E:				; CODE XREF: Pal_FadeOut+12j
		bsr.s	Pal_DecColor
		dbf	d0,loc_221E
		moveq	#0,d0
		lea	($FFFFFA80).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		move.b	($FFFFF627).w,d0

loc_2234:				; CODE XREF: Pal_FadeOut+28j
		bsr.s	Pal_DecColor
		dbf	d0,loc_2234
		rts
; End of function Pal_FadeOut


; =============== S U B	R O U T	I N E =======================================


Pal_DecColor:				; CODE XREF: Pal_FadeOut:loc_221Ep
					; Pal_FadeOut:loc_2234p
		move.w	(a0),d2
		beq.s	Pal_NoDec
		move.w	d2,d1
		andi.w	#$E,d1
		beq.s	Pal_DecGreen
		subq.w	#2,(a0)+
		rts
; ---------------------------------------------------------------------------

Pal_DecGreen:				; CODE XREF: Pal_DecColor+Aj
		move.w	d2,d1
		andi.w	#$E0,d1	
		beq.s	Pal_DecBlue
		subi.w	#$20,(a0)+ 
		rts
; ---------------------------------------------------------------------------

Pal_DecBlue:				; CODE XREF: Pal_DecColor+16j
		move.w	d2,d1
		andi.w	#$E00,d1
		beq.s	Pal_NoDec
		subi.w	#$200,(a0)+
		rts
; ---------------------------------------------------------------------------

Pal_NoDec:				; CODE XREF: Pal_DecColor+2j
					; Pal_DecColor+24j
		addq.w	#2,a0
		rts
; End of function Pal_DecColor


; =============== S U B	R O U T	I N E =======================================


Pal_MakeWhite:				; CODE XREF: ROM:00005166p
		move.w	#$3F,($FFFFF626).w 
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		move.w	#$EEE,d1
		move.b	($FFFFF627).w,d0

loc_2286:				; CODE XREF: Pal_MakeWhite+1Cj
		move.w	d1,(a0)+
		dbf	d0,loc_2286
		move.w	#$15,d4

loc_2290:				; CODE XREF: Pal_MakeWhite+34j
		move.b	#$12,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.s	Pal_WhiteToBlack
		bsr.w	RunPLC
		dbf	d4,loc_2290
		rts
; End of function Pal_MakeWhite


; =============== S U B	R O U T	I N E =======================================


Pal_WhiteToBlack:			; CODE XREF: Pal_MakeWhite+2Ep
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		lea	($FFFFFB80).w,a1
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	($FFFFF627).w,d0

loc_22BC:				; CODE XREF: Pal_WhiteToBlack+18j
		bsr.s	Pal_DecColor2
		dbf	d0,loc_22BC
		tst.b	($FFFFF730).w
		beq.s	locret_22E4
		moveq	#0,d0
		lea	($FFFFFA80).w,a0
		lea	($FFFFFA00).w,a1
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	($FFFFF627).w,d0

loc_22DE:				; CODE XREF: Pal_WhiteToBlack+3Aj
		bsr.s	Pal_DecColor2
		dbf	d0,loc_22DE

locret_22E4:				; CODE XREF: Pal_WhiteToBlack+20j
		rts
; End of function Pal_WhiteToBlack


; =============== S U B	R O U T	I N E =======================================


Pal_DecColor2:				; CODE XREF: Pal_WhiteToBlack:loc_22BCp
					; Pal_WhiteToBlack:loc_22DEp
		move.w	(a1)+,d2
		move.w	(a0),d3
		cmp.w	d2,d3
		beq.s	loc_2312
		move.w	d3,d1
		subi.w	#$200,d1
		bcs.s	loc_22FE
		cmp.w	d2,d1
		bcs.s	loc_22FE
		move.w	d1,(a0)+
		rts
; ---------------------------------------------------------------------------

loc_22FE:				; CODE XREF: Pal_DecColor2+Ej
					; Pal_DecColor2+12j
		move.w	d3,d1
		subi.w	#$20,d1	
		bcs.s	loc_230E
		cmp.w	d2,d1
		bcs.s	loc_230E
		move.w	d1,(a0)+
		rts
; ---------------------------------------------------------------------------

loc_230E:				; CODE XREF: Pal_DecColor2+1Ej
					; Pal_DecColor2+22j
		subq.w	#2,(a0)+
		rts
; ---------------------------------------------------------------------------

loc_2312:				; CODE XREF: Pal_DecColor2+6j
		addq.w	#2,a0
		rts
; End of function Pal_DecColor2


; =============== S U B	R O U T	I N E =======================================


Pal_MakeFlash:				; CODE XREF: ROM:00005024p
					; ROM:000052CEp
		move.w	#$3F,($FFFFF626).w 
		move.w	#$15,d4

loc_2320:				; CODE XREF: Pal_MakeFlash+1Aj
		move.b	#$12,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.s	Pal_ToWhite
		bsr.w	RunPLC
		dbf	d4,loc_2320
		rts
; End of function Pal_MakeFlash


; =============== S U B	R O U T	I N E =======================================


Pal_ToWhite:				; CODE XREF: Pal_MakeFlash+14p
					; ROM:00005210p
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		move.b	($FFFFF627).w,d0

loc_2346:				; CODE XREF: Pal_ToWhite+12j
		bsr.s	Pal_AddColor2
		dbf	d0,loc_2346
		moveq	#0,d0

loc_234E:
		lea	($FFFFFA80).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		move.b	($FFFFF627).w,d0

loc_235C:				; CODE XREF: Pal_ToWhite+28j
		bsr.s	Pal_AddColor2
		dbf	d0,loc_235C
		rts
; End of function Pal_ToWhite


; =============== S U B	R O U T	I N E =======================================


Pal_AddColor2:				; CODE XREF: Pal_ToWhite:loc_2346p
					; Pal_ToWhite:loc_235Cp
		move.w	(a0),d2
		cmpi.w	#$EEE,d2
		beq.s	loc_23A0
		move.w	d2,d1
		andi.w	#$E,d1
		cmpi.w	#$E,d1
		beq.s	loc_237C
		addq.w	#2,(a0)+
		rts
; ---------------------------------------------------------------------------

loc_237C:				; CODE XREF: Pal_AddColor2+12j
		move.w	d2,d1
		andi.w	#$E0,d1	
		cmpi.w	#$E0,d1	
		beq.s	loc_238E

loc_2388:
		addi.w	#$20,(a0)+ 
		rts
; ---------------------------------------------------------------------------

loc_238E:				; CODE XREF: Pal_AddColor2+22j
		move.w	d2,d1
		andi.w	#$E00,d1
		cmpi.w	#$E00,d1
		beq.s	loc_23A0
		addi.w	#$200,(a0)+
		rts
; ---------------------------------------------------------------------------

loc_23A0:				; CODE XREF: Pal_AddColor2+6j
					; Pal_AddColor2+34j
		addq.w	#2,a0
		rts
; End of function Pal_AddColor2


; =============== S U B	R O U T	I N E =======================================


PalCycle_Sega:				; CODE XREF: ROM:000031A0p
		tst.b	($FFFFF635).w
		bne.s	loc_2404
		lea	($FFFFFB20).w,a1
		lea	(Pal_Sega1).l,a0
		moveq	#5,d1
		move.w	($FFFFF632).w,d0

loc_23BA:				; CODE XREF: PalCycle_Sega+1Ej
		bpl.s	loc_23C4
		addq.w	#2,a0
		subq.w	#1,d1
		addq.w	#2,d0
		bra.s	loc_23BA
; ---------------------------------------------------------------------------

loc_23C4:				; CODE XREF: PalCycle_Sega:loc_23BAj
					; PalCycle_Sega+36j
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_23CE
		addq.w	#2,d0

loc_23CE:				; CODE XREF: PalCycle_Sega+26j
		cmpi.w	#$60,d0	
		bcc.s	loc_23D8
		move.w	(a0)+,(a1,d0.w)

loc_23D8:				; CODE XREF: PalCycle_Sega+2Ej
		addq.w	#2,d0
		dbf	d1,loc_23C4
		move.w	($FFFFF632).w,d0
		addq.w	#2,d0
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_23EE
		addq.w	#2,d0

loc_23EE:				; CODE XREF: PalCycle_Sega+46j
		cmpi.w	#$64,d0	
		blt.s	loc_23FC
		move.w	#$401,($FFFFF634).w
		moveq	#$FFFFFFF4,d0

loc_23FC:				; CODE XREF: PalCycle_Sega+4Ej
		move.w	d0,($FFFFF632).w
		moveq	#1,d0
		rts
; ---------------------------------------------------------------------------

loc_2404:				; CODE XREF: PalCycle_Sega+4j
		subq.b	#1,($FFFFF634).w
		bpl.s	loc_2456
		move.b	#4,($FFFFF634).w
		move.w	($FFFFF632).w,d0
		addi.w	#$C,d0
		cmpi.w	#$30,d0	
		bcs.s	loc_2422
		moveq	#0,d0
		rts
; ---------------------------------------------------------------------------

loc_2422:				; CODE XREF: PalCycle_Sega+78j
		move.w	d0,($FFFFF632).w
		lea	(Pal_Sega2).l,a0
		lea	(a0,d0.w),a0
		lea	($FFFFFB04).w,a1
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.w	(a0)+,(a1)
		lea	($FFFFFB20).w,a1
		moveq	#0,d0
		moveq	#$2C,d1	

loc_2442:				; CODE XREF: PalCycle_Sega+AEj
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_244C
		addq.w	#2,d0

loc_244C:				; CODE XREF: PalCycle_Sega+A4j
		move.w	(a0),(a1,d0.w)
		addq.w	#2,d0
		dbf	d1,loc_2442

loc_2456:				; CODE XREF: PalCycle_Sega+64j
		moveq	#1,d0
		rts
; End of function PalCycle_Sega

; ---------------------------------------------------------------------------
Pal_Sega1:	incbin "palette\Sega1.bin"
                even
Pal_Sega2:	incbin "palette\Sega2.bin"
                even

; =============== S U B	R O U T	I N E =======================================


PalLoad1:				; CODE XREF: ROM:00003278p
					; ROM:00003372p ...
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		adda.w	#$80,a3
		move.w	(a1)+,d7

loc_24AA:				; CODE XREF: PalLoad1+16j
		move.l	(a2)+,(a3)+
		dbf	d7,loc_24AA
		rts
; End of function PalLoad1


; =============== S U B	R O U T	I N E =======================================


PalLoad2:				; CODE XREF: ROM:0000316Cp
					; ROM:000034A8p ...
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		move.w	(a1)+,d7

loc_24C2:				; CODE XREF: PalLoad2+12j
		move.l	(a2)+,(a3)+
		dbf	d7,loc_24C2
		rts
; End of function PalLoad2


; =============== S U B	R O U T	I N E =======================================


PalLoad3_Water:				; CODE XREF: ROM:loc_3CB6p
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		suba.w	#$80,a3
		move.w	(a1)+,d7

loc_24DE:				; CODE XREF: PalLoad3_Water+16j
		move.l	(a2)+,(a3)+
		dbf	d7,loc_24DE
		rts
; End of function PalLoad3_Water


; =============== S U B	R O U T	I N E =======================================


PalLoad4_Water:				; CODE XREF: ROM:loc_3EC4p
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		suba.w	#$100,a3
		move.w	(a1)+,d7

loc_24FA:				; CODE XREF: PalLoad4_Water+16j
		move.l	(a2)+,(a3)+
		dbf	d7,loc_24FA
		rts
; End of function PalLoad4_Water

; ---------------------------------------------------------------------------
PalPointers:	dc.l Pal_SegaBG		; DATA XREF: PalLoad1o	PalLoad2o ...
		dc.w $FB00
		dc.w $1F
		dc.l Pal_Title
		dc.w $FB00
		dc.w $1F
		dc.l Pal_LevelSelect
		dc.w $FB00
		dc.w $1F
		dc.l Pal_SonicTails
		dc.w $FB00
		dc.w 7
		dc.l Pal_GHZ
		dc.w $FB20
		dc.w $17
		dc.l Pal_CPZ
		dc.w $FB20
		dc.w $17
		dc.l Pal_CPZ
		dc.w $FB20
		dc.w $17
		dc.l Pal_EHZ
		dc.w $FB20
		dc.w $17
		dc.l Pal_HPZ
		dc.w $FB20
		dc.w $17
		dc.l Pal_HTZ
		dc.w $FB20
		dc.w $17
		dc.l Pal_SpecialStage
		dc.w $FB00
		dc.w $1F
		dc.l Pal_HPZWater
		dc.w $FB00
		dc.w $1F
		dc.l Pal_LZ
		dc.w $FB20
		dc.w $17
		dc.l Pal_LZ4
		dc.w $FB00
		dc.w $1F
		dc.l Pal_HTZ
		dc.w $FB20
		dc.w $17
		dc.l Pal_LZSonicWater
		dc.w $FB00
		dc.w 7
		dc.l Pal_LZ4SonicWater
		dc.w $FB00
		dc.w 7
		dc.l Pal_S1SpecialStageTC
		dc.w $FB00
		dc.w $1F
		dc.l Pal_S1Continue
		dc.w $FB00
		dc.w $F
		dc.l Pal_S1Ending
		dc.w $FB00
		dc.w $1F
Pal_SegaBG:	incbin "palette\Sega Background.bin"
                even
Pal_Title:	dc.w  $C00,    2, $800,	 $26,  $48,  $6C,  $8E,	 $AE, $4A0,  $40,  $60,	 $80,  $A0, $6A4,    0,	   0; 0
					; DATA XREF: ROM:0000250Ao
		dc.w  $C8C, $800,    0,	$A66, $EA8, $ECA, $EEE,	 $AE,  $8E,  $6C, $8CE,	$EEC,  $4A,    6,    0,	   0; 16
		dc.w  $C00, $C00, $E22,	$E44, $E66, $E88, $EEE,	$AAA, $888, $666,  $24,	$248, $8AE, $68C,    0,	$ECA; 32
		dc.w  $C00, $600, $C00,	$E44, $E66, $E88, $EEE,	 $AE,  $6A,  $26,  $EE,	$EAA,	$C,    6,    2,	   0; 48
Pal_LevelSelect:dc.w	 0,    0,    0,	   0,	 0,    0,    0,	   0,	 0,    0,    0,	   0,	 0,    0,    0,	$EEE; 0
					; DATA XREF: ROM:00002512o
		dc.w  $C00,  $24, $246,	$468, $68A, $8AC, $ACE,	$8AC, $68A, $468, $ACE,	$ACE, $246,  $24,    0,	   0; 16
		dc.w  $C00,  $24, $246,	$468, $68A, $8AC, $ACE,	$8AC, $68A, $468,  $24,	$246, $8AC, $68A,    0,	 $EE; 32
		dc.w  $C00,  $24, $246,	$468, $68A, $8AC, $ACE,	$8AC, $68A, $468, $ACE,	$ACE, $468, $246,    2,	   0; 48
Pal_SonicTails:	incbin "palette\Sonic.bin"
                even
Pal_GHZ:	incbin "palette\Green Hill Zone.bin"
                even
Pal_HPZWater:	dc.w	 0, $402, $A20,	$B40, $B60, $B80, $ECA,	$CA8, $A84, $860, $AA8,	$884, $428, $424, $8AA,	$88A; 0
					; DATA XREF: ROM:0000255Ao
		dc.w	 0, $202, $242,	$464, $686, $442, $EAA,	$D88, $D66, $A22, $666,	$46A, $6CA, $484, $EEE,	  $E; 16
		dc.w  $400, $A20, $C22,	$E26, $E28, $A22, $A40,	$C22, $A60, $E28, $E4A,	$E6A, $CAA, $E24, $E26,	$E8A; 32
		dc.w  $400, $440, $660,	$880, $8A0, $8C0, $AE4,	$EEA, $A60, $E84, $EA6,	$EC6, $EE6, $E6A, $E8A,	$CAA; 48
Pal_CPZ:	dc.w	 2,    0, $E64,	$A68, $E86,  $44, $EEE,	$AAA, $888, $444, $666,	   0,  $EE,  $88, $EA8,	$ECA; 0
					; DATA XREF: ROM:0000252Ao
					; ROM:00002532o
		dc.w	 2,    0,    6,	$A0A, $C4C, $E6E, $EAE,	 $CE,  $8E,  $4E,  $2C,	 $2A,	 8,    4, $EEE,	  $E; 16
		dc.w	 2,    0, $222,	$444, $888, $AAA, $EEE,	$E40, $C00, $800,  $CE,	$28E, $E40, $C00, $C00,	 $E0; 32
Pal_EHZ:	dc.w  $C20,    0, $E62,	$A86, $E86,  $44, $EEE,	$AAA, $888, $444, $666,	$E86,  $EE,  $88, $EA8,	$ECA; 0
					; DATA XREF: ROM:0000253Ao
		dc.w  $C20,    2, $800,	 $26,  $48,  $6C,  $8E,	 $AE, $4A0,  $40,  $60,	 $80,  $A0, $6A4,  $C6,	 $E8; 16
		dc.w  $C20, $800,    0,	$E86, $ECA, $20A, $EEE,	$E6E, $C4C, $A2A, $EEC,	 $80, $64E, $42C,  $A0,	 $E8; 32
Pal_HPZ:	dc.w  $800,    0, $242,	$464, $686,  $44, $EEE,	$AAA, $888, $444, $8EA,	$46A,  $EE,  $88,  $44,	  $E; 0
					; DATA XREF: ROM:00002542o
		dc.w  $200, $402, $604,	$806, $808, $602, $620,	$202, $640,  $26,  $68,	$28A, $6CE,  $24,  $46,	$4AC; 16
		dc.w  $200,  $20,  $40,	 $60,  $80,  $C0, $4E6,	$EEE, $602, $E44, $E82,	$EA8, $EEE,  $24,  $46,	$4AC; 32
Pal_HTZ:	dc.w  $C20,    0, $200,	  $E,  $6E,  $44, $EEE,	$AAA, $888, $444, $666,	$E86,  $EE,  $88,  $AE,	 $EE; 0
					; DATA XREF: ROM:0000254Ao
					; ROM:00002572o
		dc.w  $E42, $200, $E86,	$640, $860, $A82, $CA4,	$EC6,  $24,  $40,  $62,	 $82,  $A4,  $6C,  $C4,	 $E8; 16
		dc.w  $E42,    4, $E64,	$E86, $EA8,  $28, $EEC,	$E6E, $C4C, $A2A, $ECA,	 $80, $26E,  $4C,  $A4,	 $E8; 32
Pal_SpecialStage:dc.w  $400,	0, $822, $A44, $C66, $E88, $EEE, $AAA, $888, $444, $8AE, $46A,	 $E,	8,    4,  $EE; 0
					; DATA XREF: ROM:00002552o
		dc.w  $400,    0,  $24,	 $68,  $AC, $2EE, $EEE,	$AAA, $888, $444, $AE4,	$6A2,  $EE,  $88,  $44,	   0; 16
		dc.w  $400,    0, $204,	$628, $A4C, $C6E, $ECE,	$800, $C42, $E86, $ECA,	$EEC,	 0, $EE0, $AA0,	$440; 32
		dc.w  $400,    0,  $60,	 $A0,  $C6,  $EA, $AEC,	$EEA, $EE0, $AA0, $880,	$660, $440, $EE0, $AA0,	$440; 48
Pal_LZ:		dc.w  $800,    0, $626,	$A2A, $C4C, $E8E, $EEE,	$AAA, $888, $444, $8E0,	$260,  $EE,  $88,  $44,	  $E; 0
					; DATA XREF: ROM:00002562o
		dc.w	 0, $444, $666,	$888, $AAA, $CCC, $EEE,	   0, $C8C, $A6A, $848,	$ECE, $E8C, $A48, $826,	$EEE; 16
		dc.w	 0,    0,  $20,	$240, $462, $882, $CC6,	$EEA, $282, $4A4, $8E8,	$AAA, $666, $222, $684,	$EEE; 32
Pal_LZ4:	dc.w	 0,    0, $A26,	$C48, $E6A, $E8C, $ECE,	$CAC, $868, $646, $CAE,	$86C, $60C, $426,    4,	 $EE; 0
					; DATA XREF: ROM:0000256Ao
		dc.w  $800,    0, $226,	$22A, $44C, $88E, $EEE,	$AAA, $888, $444, $6C0,	$240,  $EA,  $84,  $40,	  $E; 16
		dc.w	 0, $202, $404,	$626, $848, $A6A, $C8C,	   0, $848, $626, $404,	$ECE, $E8C, $A48, $826,	$EEE; 32
		dc.w	 0,    0,    0,	$200, $402, $644, $866,	$A88, $264, $486, $6A8,	 $26,  $48,  $6A, $604,	$AAA; 48
Pal_LZSonicWater:incbin "palette\Sonic - LZ Underwater.bin"
                even
Pal_LZ4SonicWater:incbin "palette\Sonic - SBZ3 Underwater.bin"
                even
Pal_S1SpecialStageTC:dc.w  $EEE, $EAA, $EAA,  $EE,  $EE,  $EE, $8A0, $AC0, $CE0, $EAA,	$24,  $68,  $AC, $2EE, $EEE, $4C0; 0
					; DATA XREF: ROM:0000258Ao
		dc.w  $EEE,    0, $822,	$A44, $C66, $E88, $EEE,	$AAA, $888, $444, $8AE,	$46A,	$E,    8,    4,	   0; 16
		dc.w  $EEE,    0, $204,	$628, $A4C, $C6E, $ECE,	   0,	 0,    0,    0,	   0,	 0,    0,    0,	   0; 32
		dc.w  $EEE,    0,  $60,	 $A0,  $C6,  $EA, $AEC,	   0,	 0,    0,    0,	   0,	 0,    0,    0,	   0; 48
Pal_S1Continue:	dc.w	 0,    0, $822,	$A44, $C66, $E88, $EEE,	$AAA, $888, $444, $8AE,	$46A,	$E,    8,    4,	 $EE; 0
					; DATA XREF: ROM:00002592o
		dc.w	 0,    0, $424,	$848, $A6A, $E8E,    0,	   0,	 0,    0,    0,	   0,  $EE,  $88,  $44,	   0; 16
Pal_S1Ending:	dc.w  $E80,    0, $822,	$A44, $C66, $E88, $EEE,	$AAA, $888, $444, $8AE,	$46A,	$E,    8,    4,	 $EE; 0
					; DATA XREF: ROM:0000259Ao
		dc.w  $E80,    0, $608,	$82A, $A4C, $C6E, $EEE,	$AAE, $66C, $22A, $8EA,	$46A,  $EE,  $88,  $44,	  $E; 16
		dc.w  $E80,    2, $EEE,	 $26,  $48,  $6C,  $8E,	 $CE, $A86, $E86, $EA8,	$ECA,  $40,  $60,  $A4,	 $E8; 32
		dc.w  $C82, $A02, $C42,	$E86, $ECA, $EEC, $EEE,	$EAC, $E8A, $E68,  $E8,	 $A4,	 2,  $26,  $6C,	 $CE; 48
; ---------------------------------------------------------------------------
		nop

; =============== S U B	R O U T	I N E =======================================


DelayProgram:				; CODE XREF: Pause+28p	Pal_FadeTo+28p	...
		move	#$2300,sr

loc_2C88:				; CODE XREF: DelayProgram+8j
		tst.b	($FFFFF62A).w
		bne.s	loc_2C88
		rts
; End of function DelayProgram


; =============== S U B	R O U T	I N E =======================================


PseudoRandomNumber:			; CODE XREF: ROM:00009C04p
					; ROM:0001211Cp ...
		move.l	($FFFFF636).w,d1
		bne.s	loc_2C9C
		move.l	#$2A6D365A,d1

loc_2C9C:				; CODE XREF: PseudoRandomNumber+4j
		move.l	d1,d0
		asl.l	#2,d1
		add.l	d0,d1
		asl.l	#3,d1
		add.l	d0,d1
		move.w	d1,d0
		swap	d1
		add.w	d1,d0
		move.w	d0,d1
		swap	d1
		move.l	d1,($FFFFF636).w
		rts
; End of function PseudoRandomNumber


; =============== S U B	R O U T	I N E =======================================


CalcSine:				; CODE XREF: S1SS_BgAnimate+46p
					; sub_7F36+4p ...
		andi.w	#$FF,d0
		add.w	d0,d0
		addi.w	#$80,d0	
		move.w	Sine_Data(pc,d0.w),d1
		subi.w	#$80,d0	
		move.w	Sine_Data(pc,d0.w),d0
		rts
; End of function CalcSine

; ---------------------------------------------------------------------------
Sine_Data:	dc.w	  0,	 6,    $C,   $12,   $19,   $1F,	  $25,	 $2B; 0
		dc.w	$31,   $38,   $3E,   $44,   $4A,   $50,	  $56,	 $5C; 8
		dc.w	$61,   $67,   $6D,   $73,   $78,   $7E,	  $83,	 $88; 16
		dc.w	$8E,   $93,   $98,   $9D,   $A2,   $A7,	  $AB,	 $B0; 24
		dc.w	$B5,   $B9,   $BD,   $C1,   $C5,   $C9,	  $CD,	 $D1; 32
		dc.w	$D4,   $D8,   $DB,   $DE,   $E1,   $E4,	  $E7,	 $EA; 40
		dc.w	$EC,   $EE,   $F1,   $F3,   $F4,   $F6,	  $F8,	 $F9; 48
		dc.w	$FB,   $FC,   $FD,   $FE,   $FE,   $FF,	  $FF,	 $FF; 56
		dc.w   $100,   $FF,   $FF,   $FF,   $FE,   $FE,	  $FD,	 $FC; 64
		dc.w	$FB,   $F9,   $F8,   $F6,   $F4,   $F3,	  $F1,	 $EE; 72
		dc.w	$EC,   $EA,   $E7,   $E4,   $E1,   $DE,	  $DB,	 $D8; 80
		dc.w	$D4,   $D1,   $CD,   $C9,   $C5,   $C1,	  $BD,	 $B9; 88
		dc.w	$B5,   $B0,   $AB,   $A7,   $A2,   $9D,	  $98,	 $93; 96
		dc.w	$8E,   $88,   $83,   $7E,   $78,   $73,	  $6D,	 $67; 104
		dc.w	$61,   $5C,   $56,   $50,   $4A,   $44,	  $3E,	 $38; 112
		dc.w	$31,   $2B,   $25,   $1F,   $19,   $12,	   $C,	   6; 120
		dc.w	  0,	-6,   -$C,  -$12,  -$19,  -$1F,	 -$25,	-$2B; 128
		dc.w   -$31,  -$38,  -$3E,  -$44,  -$4A,  -$50,	 -$56,	-$5C; 136
		dc.w   -$61,  -$67,  -$6D,  -$75,  -$78,  -$7E,	 -$83,	-$88; 144
		dc.w   -$8E,  -$93,  -$98,  -$9D,  -$A2,  -$A7,	 -$AB,	-$B0; 152
		dc.w   -$B5,  -$B9,  -$BD,  -$C1,  -$C5,  -$C9,	 -$CD,	-$D1; 160
		dc.w   -$D4,  -$D8,  -$DB,  -$DE,  -$E1,  -$E4,	 -$E7,	-$EA; 168
		dc.w   -$EC,  -$EE,  -$F1,  -$F3,  -$F4,  -$F6,	 -$F8,	-$F9; 176
		dc.w   -$FB,  -$FC,  -$FD,  -$FE,  -$FE,  -$FF,	 -$FF,	-$FF; 184
		dc.w  -$100,  -$FF,  -$FF,  -$FF,  -$FE,  -$FE,	 -$FD,	-$FC; 192
		dc.w   -$FB,  -$F9,  -$F8,  -$F6,  -$F4,  -$F3,	 -$F1,	-$EE; 200
		dc.w   -$EC,  -$EA,  -$E7,  -$E4,  -$E1,  -$DE,	 -$DB,	-$D8; 208
		dc.w   -$D4,  -$D1,  -$CD,  -$C9,  -$C5,  -$C1,	 -$BD,	-$B9; 216
		dc.w   -$B5,  -$B0,  -$AB,  -$A7,  -$A2,  -$9D,	 -$98,	-$93; 224
		dc.w   -$8E,  -$88,  -$83,  -$7E,  -$78,  -$75,	 -$6D,	-$67; 232
		dc.w   -$61,  -$5C,  -$56,  -$50,  -$4A,  -$44,	 -$3E,	-$38; 240
		dc.w   -$31,  -$2B,  -$25,  -$1F,  -$19,  -$12,	  -$C,	  -6; 248
		dc.w	  0,	 6,    $C,   $12,   $19,   $1F,	  $25,	 $2B; 256
		dc.w	$31,   $38,   $3E,   $44,   $4A,   $50,	  $56,	 $5C; 264
		dc.w	$61,   $67,   $6D,   $73,   $78,   $7E,	  $83,	 $88; 272
		dc.w	$8E,   $93,   $98,   $9D,   $A2,   $A7,	  $AB,	 $B0; 280
		dc.w	$B5,   $B9,   $BD,   $C1,   $C5,   $C9,	  $CD,	 $D1; 288
		dc.w	$D4,   $D8,   $DB,   $DE,   $E1,   $E4,	  $E7,	 $EA; 296
		dc.w	$EC,   $EE,   $F1,   $F3,   $F4,   $F6,	  $F8,	 $F9; 304
		dc.w	$FB,   $FC,   $FD,   $FE,   $FE,   $FF,	  $FF,	 $FF; 312

; =============== S U B	R O U T	I N E =======================================


CalcAngle:				; CODE XREF: Sonic_Floor+24p
					; Tails_Floor+Cp ...
		movem.l	d3-d4,-(sp)
		moveq	#0,d3
		moveq	#0,d4
		move.w	d1,d3
		move.w	d2,d4
		or.w	d3,d4
		beq.s	loc_2FAA
		move.w	d2,d4
		tst.w	d3
		bpl.w	loc_2F68
		neg.w	d3

loc_2F68:				; CODE XREF: CalcAngle+14j
		tst.w	d4
		bpl.w	loc_2F70
		neg.w	d4

loc_2F70:				; CODE XREF: CalcAngle+1Cj
		cmp.w	d3,d4
		bcc.w	loc_2F82
		lsl.l	#8,d4
		divu.w	d3,d4
		moveq	#0,d0
		move.b	AngleData(pc,d4.w),d0
		bra.s	loc_2F8C
; ---------------------------------------------------------------------------

loc_2F82:				; CODE XREF: CalcAngle+24j
		lsl.l	#8,d3
		divu.w	d4,d3
		moveq	#$40,d0	
		sub.b	AngleData(pc,d3.w),d0

loc_2F8C:				; CODE XREF: CalcAngle+32j
		tst.w	d1
		bpl.w	loc_2F98
		neg.w	d0
		addi.w	#$80,d0	

loc_2F98:				; CODE XREF: CalcAngle+40j
		tst.w	d2
		bpl.w	loc_2FA4
		neg.w	d0
		addi.w	#$100,d0

loc_2FA4:				; CODE XREF: CalcAngle+4Cj
		movem.l	(sp)+,d3-d4
		rts
; ---------------------------------------------------------------------------

loc_2FAA:				; CODE XREF: CalcAngle+Ej
		move.w	#$40,d0	
		movem.l	(sp)+,d3-d4
		rts
; End of function CalcAngle

; ---------------------------------------------------------------------------
AngleData:	dc.b   0,  0,  0,  0,  1,  1,  1,  1; 0
		dc.b   1,  1,  2,  2,  2,  2,  2,  2; 8
		dc.b   3,  3,  3,  3,  3,  3,  3,  4; 16
		dc.b   4,  4,  4,  4,  4,  5,  5,  5; 24
		dc.b   5,  5,  5,  6,  6,  6,  6,  6; 32
		dc.b   6,  6,  7,  7,  7,  7,  7,  7; 40
		dc.b   8,  8,  8,  8,  8,  8,  8,  9; 48
		dc.b   9,  9,  9,  9,  9, $A, $A, $A; 56
		dc.b  $A, $A, $A, $A, $B, $B, $B, $B; 64
		dc.b  $B, $B, $B, $C, $C, $C, $C, $C; 72
		dc.b  $C, $C, $D, $D, $D, $D, $D, $D; 80
		dc.b  $D, $E, $E, $E, $E, $E, $E, $E; 88
		dc.b  $F, $F, $F, $F, $F, $F, $F,$10; 96
		dc.b $10,$10,$10,$10,$10,$10,$11,$11; 104
		dc.b $11,$11,$11,$11,$11,$11,$12,$12; 112
		dc.b $12,$12,$12,$12,$12,$13,$13,$13; 120
		dc.b $13,$13,$13,$13,$13,$14,$14,$14; 128
		dc.b $14,$14,$14,$14,$14,$15,$15,$15; 136
		dc.b $15,$15,$15,$15,$15,$15,$16,$16; 144
		dc.b $16,$16,$16,$16,$16,$16,$17,$17; 152
		dc.b $17,$17,$17,$17,$17,$17,$17,$18; 160
		dc.b $18,$18,$18,$18,$18,$18,$18,$18; 168
		dc.b $19,$19,$19,$19,$19,$19,$19,$19; 176
		dc.b $19,$19,$1A,$1A,$1A,$1A,$1A,$1A; 184
		dc.b $1A,$1A,$1A,$1B,$1B,$1B,$1B,$1B; 192
		dc.b $1B,$1B,$1B,$1B,$1B,$1C,$1C,$1C; 200
		dc.b $1C,$1C,$1C,$1C,$1C,$1C,$1C,$1C; 208
		dc.b $1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D; 216
		dc.b $1D,$1D,$1D,$1E,$1E,$1E,$1E,$1E; 224
		dc.b $1E,$1E,$1E,$1E,$1E,$1E,$1F,$1F; 232
		dc.b $1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F; 240
		dc.b $1F,$1F,$20,$20,$20,$20,$20,$20; 248
		dc.b $20,  0		; 256
; ---------------------------------------------------------------------------
		nop

SegaScreen:				; CODE XREF: ROM:GameModeArrayj
		move.b	#bgm_Stop,d0
		bsr.w	PlaySound_Special
		bsr.w	ClearPLC
		bsr.w	Pal_FadeFrom
		lea	(vdp_control_port).l,a6
		move.w	#$8004,(a6)
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$8700,(a6)
		move.w	#$8B00,(a6)
		move.w	#$8C81,(a6)
		clr.b	($FFFFF64E).w
		move	#$2700,sr
		move.w	(v_vdp_buffer1).w,d0
		andi.b	#$BF,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	ClearScreen
		move.l	#$40000000,(vdp_control_port).l
		lea	(Nem_SegaLogo).l,a0
		bsr.w	NemDec
		lea	($FFFF0000).l,a1
		lea	(Eni_SegaLogo).l,a0
		move.w	#0,d0
		bsr.w	EniDec
		lea	($FFFF0000).l,a1
		move.l	#$65100003,d0
		moveq	#$17,d1
		moveq	#7,d2
		bsr.w	ShowVDPGraphics
		lea	($FFFF0180).l,a1
		move.l	#$40000003,d0
		moveq	#$27,d1	
		moveq	#$1B,d2
		bsr.w	ShowVDPGraphics
		tst.b	($FFFFFFF8).w
		bmi.s	loc_316A
		lea	($FFFF0A40).l,a1
		move.l	#$453A0003,d0
		moveq	#2,d1
		moveq	#1,d2
		bsr.w	ShowVDPGraphics

loc_316A:				; CODE XREF: ROM:00003154j
		moveq	#0,d0
		bsr.w	PalLoad2
		move.w	#$FFF6,($FFFFF632).w
		move.w	#0,($FFFFF634).w
		move.w	#0,($FFFFF662).w
		move.w	#0,($FFFFF660).w
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0	
		move.w	d0,(vdp_control_port).l

Sega_WaitPalette:			; CODE XREF: ROM:000031A4j
		move.b	#2,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	PalCycle_Sega
		bne.s	Sega_WaitPalette
		move.b	#sfx_Sega,d0
		bsr.w	PlaySound_Special
		move.b	#$14,($FFFFF62A).w
		bsr.w	DelayProgram
		move.w	#$1E,(v_demolength).w

Sega_WaitEnd:				; CODE XREF: ROM:000031D4j
		move.b	#2,($FFFFF62A).w
		bsr.w	DelayProgram
		tst.w	(v_demolength).w
		beq.s	Sega_GoToTitleScreen
		andi.b	#$80,(v_jpadpress1).w
		beq.s	Sega_WaitEnd

Sega_GoToTitleScreen:			; CODE XREF: ROM:000031CCj
		move.b	#4,(v_gamemode).w
		rts
; ---------------------------------------------------------------------------
		align 2
; ---------------------------------------------------------------------------

TitleScreen:				; CODE XREF: ROM:000003A0j
		move.b	#bgm_Stop,d0
		bsr.w	PlaySound_Special
		bsr.w	ClearPLC
		bsr.w	Pal_FadeFrom
		move	#$2700,sr
		bsr.w	SoundDriverLoad
		lea	(vdp_control_port).l,a6
		move.w	#$8004,(a6)
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$9001,(a6)
		move.w	#$9200,(a6)
		move.w	#$8B03,(a6)
		move.w	#$8720,(a6)
		clr.b	($FFFFF64E).w
		move.w	#$8C81,(a6)
		bsr.w	ClearScreen
		lea	(v_spritequeue).w,a1
		moveq	#0,d0
		move.w	#$FF,d1

loc_3230:				; CODE XREF: ROM:00003232j
		move.l	d0,(a1)+
		dbf	d1,loc_3230
		lea	(v_objspace).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

loc_3240:				; CODE XREF: ROM:00003242j
		move.l	d0,(a1)+
		dbf	d1,loc_3240
		lea	($FFFFF700).w,a1
		moveq	#0,d0
		move.w	#$3F,d1	

loc_3250:				; CODE XREF: ROM:00003252j
		move.l	d0,(a1)+
		dbf	d1,loc_3250
		lea	(v_screenposx).w,a1
		moveq	#0,d0
		move.w	#$3F,d1	

loc_3260:				; CODE XREF: ROM:00003262j
		move.l	d0,(a1)+
		dbf	d1,loc_3260
		lea	($FFFFFB80).w,a1
		moveq	#0,d0
		move.w	#$1F,d1

loc_3270:				; CODE XREF: ROM:00003272j
		move.l	d0,(a1)+
		dbf	d1,loc_3270
		moveq	#3,d0
		bsr.w	PalLoad1
		bsr.w	Pal_FadeTo
		move	#$2700,sr
		move.l	#$40000000,(vdp_control_port).l
		lea	(Nem_Title).l,a0
		bsr.w	NemDec
		move.l	#$40000001,(vdp_control_port).l
		lea	(Nem_TitleSonicTails).l,a0
		bsr.w	NemDec
		lea	(vdp_data_port).l,a6
		move.l	#$50000003,4(a6)
		lea	(Art_Text).l,a5
		move.w	#$28F,d1

loc_32C4:				; CODE XREF: ROM:000032C6j
		move.w	(a5)+,(a6)
		dbf	d1,loc_32C4
		nop
		move.b	#0,($FFFFFE30).w
		move.w	#0,($FFFFFE08).w
		move.w	#0,($FFFFFFF0).w
		move.w	#0,($FFFFFFEA).w
		move.w	#0,(v_zone).w
		move.w	#0,($FFFFF634).w
		bsr.w	Pal_FadeFrom
		move	#$2700,sr
		lea	($FFFF0000).l,a1
		lea	(Eni_TitleMap).l,a0
		move.w	#0,d0
		bsr.w	EniDec
		lea	($FFFF0000).l,a1
		move.l	#$40000003,d0
		moveq	#$27,d1	
		moveq	#$1B,d2
		bsr.w	ShowVDPGraphics
		lea	($FFFF0000).l,a1
		lea	(Eni_TitleBg1).l,a0
		move.w	#0,d0
		bsr.w	EniDec
		lea	($FFFF0000).l,a1
		move.l	#$60000003,d0
		moveq	#$1F,d1
		moveq	#$1B,d2
		bsr.w	ShowVDPGraphics
		lea	($FFFF0000).l,a1
		lea	(Eni_TitleBg2).l,a0
		move.w	#0,d0
		bsr.w	EniDec
		lea	($FFFF0000).l,a1
		move.l	#$60400003,d0
		moveq	#$1F,d1
		moveq	#$1B,d2
		bsr.w	ShowVDPGraphics
		moveq	#1,d0
		bsr.w	PalLoad1
		move.b	#bgm_Title,d0
		bsr.w	PlaySound_Special
		move.b	#0,($FFFFFFFA).w
		move.w	#0,(f_2player).w
		move.w	#$178,(v_demolength).w
		lea	(v_objspace+$80).w,a1
		moveq	#0,d0
		move.w	#$F,d1

loc_339A:				; CODE XREF: ROM:0000339Cj
		move.l	d0,(a1)+
		dbf	d1,loc_339A
		move.b	#$E,(v_objspace+$40).w
		move.b	#$E,(v_objspace+$80).w
		move.b	#1,(v_objspace+$9A).w
		jsr	(ObjectsLoad).l
		jsr	(BuildSprites).l
		moveq	#0,d0
		bsr.w	LoadPLC2
		move.w	#0,($FFFFFFE4).w
		move.w	#0,($FFFFFFE6).w
		move.w	#$300,(v_zone).w
		move.w	#4,($FFFFEED2).w
		move.w	#0,(v_tracktails).w
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	Pal_FadeTo

TitleScreen_Loop:			; CODE XREF: ROM:0000349Aj
		move.b	#4,($FFFFF62A).w
		bsr.w	DelayProgram
		jsr	(ObjectsLoad).l
		bsr.w	Deform_TitleScreen
		jsr	(BuildSprites).l
		bsr.w	RunPLC
		tst.b	($FFFFFFF8).w
		bpl.s	Title_RegionJ
		lea	(LvlSelCode_US).l,a0
		bra.s	LevelSelectCheat
; ---------------------------------------------------------------------------

Title_RegionJ:				; CODE XREF: ROM:00003416j
		lea	(LvlSelCode_J).l,a0

LevelSelectCheat:			; CODE XREF: ROM:0000341Ej
		move.w	($FFFFFFE4).w,d0
		adda.w	d0,a0
		move.b	(v_jpadpress1).w,d0
		andi.b	#$F,d0
		cmp.b	(a0),d0
		bne.s	Title_Cheat_NoMatch
		addq.w	#1,($FFFFFFE4).w
		tst.b	d0
		bne.s	Title_Cheat_CountC
		lea	($FFFFFFE0).w,a0
		move.w	($FFFFFFE6).w,d1
		lsr.w	#1,d1
		andi.w	#3,d1
		beq.s	Title_Cheat_PlayRing
		tst.b	($FFFFFFF8).w
		bpl.s	Title_Cheat_PlayRing
		moveq	#1,d1
		move.b	d1,1(a0,d1.w)

Title_Cheat_PlayRing:			; CODE XREF: ROM:0000344Ej
					; ROM:00003454j
		move.b	#1,(a0,d1.w)
		move.b	#sfx_Ring,d0
		bsr.w	PlaySound_Special
		bra.s	Title_Cheat_CountC
; ---------------------------------------------------------------------------

Title_Cheat_NoMatch:			; CODE XREF: ROM:00003436j
		tst.b	d0
		beq.s	Title_Cheat_CountC
		cmpi.w	#9,($FFFFFFE4).w
		beq.s	Title_Cheat_CountC
		move.w	#0,($FFFFFFE4).w

Title_Cheat_CountC:			; CODE XREF: ROM:0000343Ej
					; ROM:0000346Aj ...
		move.b	(v_jpadpress1).w,d0
		andi.b	#$20,d0
		beq.s	Title_Cheat_NoC
		addq.w	#1,($FFFFFFE6).w

Title_Cheat_NoC:			; CODE XREF: ROM:00003486j
		tst.w	(v_demolength).w
		beq.w	Demo
		andi.b	#$80,(v_jpadpress1).w
		beq.w	TitleScreen_Loop

Title_CheckLvlSel:			; CODE XREF: ROM:0000365Cj
		tst.b	($FFFFFFE0).w
		beq.w	PlayLevel
		moveq	#2,d0
		bsr.w	PalLoad2
		lea	(v_hscrolltablebuffer).w,a1
		moveq	#0,d0
		move.w	#$DF,d1	

LevelSelect_ClearScroll:		; CODE XREF: ROM:000034B8j
		move.l	d0,(a1)+
		dbf	d1,LevelSelect_ClearScroll
		move.l	d0,(v_scrposy_dup).w
		move	#$2700,sr
		lea	(vdp_data_port).l,a6
		move.l	#$60000003,(vdp_control_port).l
		move.w	#$3FF,d1

LevelSelect_ClearVRAM:			; CODE XREF: ROM:000034DAj
		move.l	d0,(a6)
		dbf	d1,LevelSelect_ClearVRAM
		bsr.w	LevelSelect_TextLoad

LevelSelect_Loop:			; CODE XREF: ROM:000034F8j
					; ROM:00003500j ...
		move.b	#4,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	LevelSelect_Controls
		bsr.w	RunPLC
		tst.l	($FFFFF680).w
		bne.s	LevelSelect_Loop
		andi.b	#$F0,(v_jpadpress1).w
		beq.s	LevelSelect_Loop
		move.w	#0,(f_2player).w
		btst	#4,(v_jpadhold1).w
		beq.s	loc_3516
		move.w	#1,(f_2player).w

loc_3516:				; CODE XREF: ROM:0000350Ej
		move.w	($FFFFFF82).w,d0
		cmpi.w	#$14,d0
		bne.s	loc_3570
		move.w	($FFFFFF84).w,d0
		addi.w	#$80,d0
		tst.b	($FFFFFFE3).w
		beq.s	loc_353A
		cmpi.w	#$9F,d0
		beq.s	loc_354C
		cmpi.w	#$9E,d0	
		beq.s	loc_355A

loc_353A:				; CODE XREF: ROM:0000352Cj
		cmpi.w	#$94,d0
		bcs.s	loc_3546
		cmpi.w	#$A0,d0	
		bcs.s	LevelSelect_Loop

loc_3546:				; CODE XREF: ROM:0000353Ej
		bsr.w	PlaySound_Special
		bra.s	LevelSelect_Loop
; ---------------------------------------------------------------------------

loc_354C:				; CODE XREF: ROM:00003532j
		move.b	#$18,(v_gamemode).w
		move.w	#$600,(v_zone).w
		rts
; ---------------------------------------------------------------------------

loc_355A:				; CODE XREF: ROM:00003538j
		move.b	#$1C,(v_gamemode).w
		move.b	#bgm_Credits,d0
		bsr.w	PlaySound_Special
		move.w	#0,($FFFFFFF4).w
		rts
; ---------------------------------------------------------------------------

loc_3570:				; CODE XREF: ROM:0000351Ej
		add.w	d0,d0
		move.w	LevelSelect_LevelOrder(pc,d0.w),d0
		bmi.w	LevelSelect_Loop
		cmpi.w	#$700,d0
		bne.s	LevelSelect_Level
		move.b	#$10,(v_gamemode).w
		clr.w	(v_zone).w
		move.b	#3,($FFFFFE12).w
		moveq	#0,d0
		move.w	d0,($FFFFFE20).w
		move.l	d0,($FFFFFE22).w
		move.l	d0,($FFFFFE26).w
		move.l	#$1388,($FFFFFFC0).w
		rts
; ---------------------------------------------------------------------------
LevelSelect_LevelOrder:dc.w	0,    1,    2  ; 0
		dc.w  $200, $201, $202	; 3
		dc.w  $400, $401, $402	; 6
		dc.w  $100, $101, $102	; 9
		dc.w  $300, $301, $302	; 12
		dc.w  $500, $501, $103	; 15
		dc.w  $502, $700,$8000	; 18
; ---------------------------------------------------------------------------

LevelSelect_Level:			; CODE XREF: ROM:0000357Ej
		andi.w	#$3FFF,d0
		move.w	d0,(v_zone).w

PlayLevel:				; CODE XREF: ROM:000034A2j
		move.b	#$C,(v_gamemode).w
		move.b	#3,($FFFFFE12).w
		moveq	#0,d0
		move.w	d0,($FFFFFE20).w
		move.l	d0,($FFFFFE22).w
		move.l	d0,($FFFFFE26).w
		move.b	d0,($FFFFFE16).w
		move.b	d0,($FFFFFE57).w
		move.l	d0,($FFFFFE58).w
		move.l	d0,($FFFFFE5C).w
		move.b	d0,($FFFFFE18).w
		move.l	#$1388,($FFFFFFC0).w
		move.b	#bgm_Fade,d0
		bsr.w	PlaySound_Special
		rts
; ---------------------------------------------------------------------------
LvlSelCode_J:	dc.b   1,  2,  2,  2,  2,  1,  0,$FF; 0	; DATA XREF: ROM:Title_RegionJo
LvlSelCode_US:	dc.b   1,  2,  2,  2,  2,  1,  0,$FF; 0	; DATA XREF: ROM:00003418o
; ---------------------------------------------------------------------------

Demo:					; CODE XREF: ROM:00003490j
		move.w	#$1E,(v_demolength).w

loc_3630:				; CODE XREF: ROM:00003664j
		move.b	#4,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	RunPLC
		move.w	(v_objspace+8).w,d0
		addq.w	#2,d0
		move.w	d0,(v_objspace+8).w
		cmpi.w	#$1C00,d0
		bcs.s	RunDemo
		move.b	#0,(v_gamemode).w
		rts
; ---------------------------------------------------------------------------

RunDemo:				; CODE XREF: ROM:0000364Cj
		andi.b	#$80,(v_jpadpress1).w
		bne.w	Title_CheckLvlSel
		tst.w	(v_demolength).w
		bne.w	loc_3630
		move.b	#bgm_Fade,d0
		bsr.w	PlaySound_Special
		move.w	($FFFFFFF2).w,d0
		andi.w	#7,d0
		add.w	d0,d0
		move.w	Demo_Levels(pc,d0.w),d0
		move.w	d0,(v_zone).w
		addq.w	#1,($FFFFFFF2).w
		cmpi.w	#4,($FFFFFFF2).w
		bcs.s	loc_3694
		move.w	#0,($FFFFFFF2).w

loc_3694:				; CODE XREF: ROM:0000368Cj
		move.w	#1,($FFFFFFF0).w
		move.b	#8,(v_gamemode).w
		cmpi.w	#$300,d0
		bne.s	loc_36AC
		move.w	#1,(f_2player).w

loc_36AC:				; CODE XREF: ROM:000036A4j
		cmpi.w	#$600,d0
		bne.s	loc_36C0
		move.b	#$10,(v_gamemode).w
		clr.w	(v_zone).w
		clr.b	($FFFFFE16).w

loc_36C0:				; CODE XREF: ROM:000036B0j
		move.b	#3,($FFFFFE12).w
		moveq	#0,d0
		move.w	d0,($FFFFFE20).w
		move.l	d0,($FFFFFE22).w
		move.l	d0,($FFFFFE26).w
		move.l	#$1388,($FFFFFFC0).w
		rts
; ---------------------------------------------------------------------------
Demo_Levels:	dc.w  $200, $300	; 0
		dc.w  $400, $500	; 2
		dc.w  $500, $500	; 4
		dc.w  $500, $500	; 6
		dc.w  $400, $400	; 8
		dc.w  $400, $400	; 10

; =============== S U B	R O U T	I N E =======================================


LevelSelect_Controls:			; CODE XREF: ROM:000034ECp
		move.b	(v_jpadpress1).w,d1
		andi.b	#3,d1
		bne.s	loc_3706
		subq.w	#1,($FFFFFF80).w
		bpl.s	loc_3740

loc_3706:				; CODE XREF: LevelSelect_Controls+8j
		move.w	#$B,($FFFFFF80).w
		move.b	(v_jpadhold1).w,d1
		andi.b	#3,d1
		beq.s	loc_3740
		move.w	($FFFFFF82).w,d0
		btst	#0,d1
		beq.s	loc_3726
		subq.w	#1,d0
		bcc.s	loc_3726
		moveq	#$14,d0

loc_3726:				; CODE XREF: LevelSelect_Controls+28j
					; LevelSelect_Controls+2Cj
		btst	#1,d1
		beq.s	loc_3736
		addq.w	#1,d0
		cmpi.w	#$15,d0
		bcs.s	loc_3736
		moveq	#0,d0

loc_3736:				; CODE XREF: LevelSelect_Controls+34j
					; LevelSelect_Controls+3Cj
		move.w	d0,($FFFFFF82).w
		bsr.w	LevelSelect_TextLoad
		rts
; ---------------------------------------------------------------------------

loc_3740:				; CODE XREF: LevelSelect_Controls+Ej
					; LevelSelect_Controls+1Ej
		cmpi.w	#$14,($FFFFFF82).w
		bne.s	locret_377A
		move.b	(v_jpadpress1).w,d1
		andi.b	#$C,d1
		beq.s	locret_377A
		move.w	($FFFFFF84).w,d0
		btst	#2,d1
		beq.s	loc_3762
		subq.w	#1,d0
		bcc.s	loc_3762
		moveq	#$4F,d0

loc_3762:				; CODE XREF: LevelSelect_Controls+64j
					; LevelSelect_Controls+68j
		btst	#3,d1
		beq.s	loc_3772
		addq.w	#1,d0
		cmpi.w	#$50,d0	
		bcs.s	loc_3772
		moveq	#0,d0

loc_3772:				; CODE XREF: LevelSelect_Controls+70j
					; LevelSelect_Controls+78j
		move.w	d0,($FFFFFF84).w
		bsr.w	LevelSelect_TextLoad

locret_377A:				; CODE XREF: LevelSelect_Controls+50j
					; LevelSelect_Controls+5Aj
		rts
; End of function LevelSelect_Controls


; =============== S U B	R O U T	I N E =======================================


LevelSelect_TextLoad:			; CODE XREF: ROM:000034DEp
					; LevelSelect_Controls+44p ...
		lea	(LevelSelect_Text).l,a1
		lea	(vdp_data_port).l,a6
		move.l	#$62100003,d4
		move.w	#$8680,d3
		moveq	#$14,d1

loc_3794:				; CODE XREF: LevelSelect_TextLoad+26j
		move.l	d4,4(a6)
		bsr.w	sub_381C
		addi.l	#$800000,d4
		dbf	d1,loc_3794
		moveq	#0,d0
		move.w	($FFFFFF82).w,d0
		move.w	d0,d1
		move.l	#$62100003,d4
		lsl.w	#7,d0
		swap	d0
		add.l	d0,d4
		lea	(LevelSelect_Text).l,a1
		lsl.w	#3,d1
		move.w	d1,d0
		add.w	d1,d1
		add.w	d0,d1
		adda.w	d1,a1
		move.w	#$C680,d3
		move.l	d4,4(a6)
		bsr.w	sub_381C
		move.w	#$8680,d3
		cmpi.w	#$14,($FFFFFF82).w
		bne.s	loc_37E6
		move.w	#$C680,d3

loc_37E6:				; CODE XREF: LevelSelect_TextLoad+64j
		move.l	#$6C300003,(vdp_control_port).l
		move.w	($FFFFFF84).w,d0
		addi.w	#$80,d0	
		move.b	d0,d2
		lsr.b	#4,d0
		bsr.w	sub_3808
		move.b	d2,d0
		bsr.w	sub_3808
		rts
; End of function LevelSelect_TextLoad


; =============== S U B	R O U T	I N E =======================================


sub_3808:				; CODE XREF: LevelSelect_TextLoad+80p
					; LevelSelect_TextLoad+86p
		andi.w	#$F,d0
		cmpi.b	#$A,d0
		bcs.s	loc_3816
		addi.b	#7,d0

loc_3816:				; CODE XREF: sub_3808+8j
		add.w	d3,d0
		move.w	d0,(a6)
		rts
; End of function sub_3808


; =============== S U B	R O U T	I N E =======================================


sub_381C:				; CODE XREF: LevelSelect_TextLoad+1Cp
					; LevelSelect_TextLoad+56p
		moveq	#$17,d2

loc_381E:				; CODE XREF: sub_381C+Cj sub_381C+16j
		moveq	#0,d0
		move.b	(a1)+,d0
		bpl.s	loc_382E
		move.w	#0,(a6)
		dbf	d2,loc_381E
		rts
; ---------------------------------------------------------------------------

loc_382E:				; CODE XREF: sub_381C+6j
		add.w	d3,d0
		move.w	d0,(a6)
		dbf	d2,loc_381E
		rts
; End of function sub_381C

; ---------------------------------------------------------------------------
LevelSelect_Text:incbin "misc\Level Select Text.bin"
                even
; ---------------------------------------------------------------------------

UnknownSub_1:
		lea	($FFFF0000).l,a1
		move.w	#$2EB,d2

loc_3A3A:				; CODE XREF: ROM:00003A4Cj
		move.w	(a1),d0
		move.w	d0,d1
		andi.w	#$F800,d1
		andi.w	#$7FF,d0
		lsr.w	#1,d0
		or.w	d0,d1
		move.w	d1,(a1)+
		dbf	d2,loc_3A3A
		rts
; ---------------------------------------------------------------------------

UnknownSub_2:
		lea	($FE0000).l,a1
		lea	($FE0080).l,a2
		lea	($FFFF0000).l,a3
		move.w	#$3F,d1

loc_3A68:				; CODE XREF: ROM:00003A70j
		bsr.w	UnknownSub_4
		bsr.w	UnknownSub_4
		dbf	d1,loc_3A68
		lea	($FE0000).l,a1
		lea	($FF0000).l,a2
		move.w	#$3F,d1	

loc_3A84:				; CODE XREF: ROM:00003A88j
		move.w	#0,(a2)+
		dbf	d1,loc_3A84
		move.w	#$3FBF,d1

loc_3A90:				; CODE XREF: ROM:00003A92j
		move.w	(a1)+,(a2)+
		dbf	d1,loc_3A90
		rts
; ---------------------------------------------------------------------------

UnknownSub_3:
		lea	($FE0000).l,a1
		lea	($FFFF0000).l,a3
		moveq	#$1F,d0

loc_3AA6:				; CODE XREF: ROM:00003AA8j
		move.l	(a1)+,(a3)+
		dbf	d0,loc_3AA6
		moveq	#0,d7
		lea	($FE0000).l,a1
		move.w	#$FF,d5

loc_3AB8:				; CODE XREF: ROM:00003AD8j
					; ROM:00003AF4j
		lea	($FFFF0000).l,a3
		move.w	d7,d6

loc_3AC0:				; CODE XREF: ROM:00003AE6j
		movem.l	a1-a3,-(sp)
		move.w	#$3F,d0	

loc_3AC8:				; CODE XREF: ROM:00003ACCj
		cmpm.w	(a1)+,(a3)+
		bne.s	loc_3ADE
		dbf	d0,loc_3AC8
		movem.l	(sp)+,a1-a3
		adda.w	#$80,a1	
		dbf	d5,loc_3AB8
		bra.s	loc_3AF8
; ---------------------------------------------------------------------------

loc_3ADE:				; CODE XREF: ROM:00003ACAj
		movem.l	(sp)+,a1-a3
		adda.w	#$80,a3	
		dbf	d6,loc_3AC0
		moveq	#$1F,d0

loc_3AEC:				; CODE XREF: ROM:00003AEEj
		move.l	(a1)+,(a3)+
		dbf	d0,loc_3AEC
		addq.l	#1,d7
		dbf	d5,loc_3AB8

loc_3AF8:				; CODE XREF: ROM:00003ADCj
					; ROM:loc_3AF8j
		bra.s	loc_3AF8

; =============== S U B	R O U T	I N E =======================================


UnknownSub_4:				; CODE XREF: ROM:loc_3A68p
					; ROM:00003A6Cp
		moveq	#7,d0

loc_3AFC:				; CODE XREF: UnknownSub_4+12j
		move.l	(a3)+,(a1)+
		move.l	(a3)+,(a1)+
		move.l	(a3)+,(a1)+
		move.l	(a3)+,(a1)+
		move.l	(a3)+,(a2)+
		move.l	(a3)+,(a2)+
		move.l	(a3)+,(a2)+
		move.l	(a3)+,(a2)+
		dbf	d0,loc_3AFC
		adda.w	#$80,a1
		adda.w	#$80,a2
		rts
; End of function UnknownSub_4

; ---------------------------------------------------------------------------
		nop
; ---------------------------------------------------------------------------
MusicList:	dc.b bgm_GHZ
                dc.b bgm_LZ
                dc.b bgm_MZ
                dc.b bgm_SLZ
                dc.b bgm_SYZ
                dc.b bgm_SBZ
                dc.b bgm_FZ
                even
; ---------------------------------------------------------------------------

Level:					; CODE XREF: ROM:000003A4j
					; ROM:000003A8j ...
		bset	#7,(v_gamemode).w
		tst.w	($FFFFFFF0).w
		bmi.s	loc_3B38
		move.b	#bgm_Fade,d0
		bsr.w	PlaySound_Special

loc_3B38:				; CODE XREF: ROM:00003B2Ej
		bsr.w	ClearPLC
		bsr.w	Pal_FadeFrom
		tst.w	($FFFFFFF0).w
		bmi.s	loc_3BB6
		move	#$2700,sr
		move.l	#$70000002,(vdp_control_port).l
		lea	(Nem_S1TitleCard).l,a0
		bsr.w	NemDec
		bsr.w	ClearScreen
		lea	(vdp_control_port).l,a5
		move.w	#$8F01,(a5)
		move.l	#$940F93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$60000082,(a5)
		move.w	#0,(vdp_data_port).l

loc_3B84:				; CODE XREF: ROM:00003B8Aj
		move.w	(a5),d1
		btst	#1,d1
		bne.s	loc_3B84
		move.w	#$8F02,(a5)
		move	#$2300,sr
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#4,d0
		lea	(MainLoadBlocks).l,a2
		lea	(a2,d0.w),a2
		moveq	#0,d0
		move.b	(a2),d0
		beq.s	loc_3BB0
		bsr.w	LoadPLC

loc_3BB0:				; CODE XREF: ROM:00003BAAj
		moveq	#plcid_Main2,d0
		bsr.w	LoadPLC

loc_3BB6:				; CODE XREF: ROM:00003B44j
		lea	(v_spritequeue).w,a1
		moveq	#0,d0
		move.w	#$FF,d1

loc_3BC0:				; CODE XREF: ROM:00003BC2j
		move.l	d0,(a1)+
		dbf	d1,loc_3BC0
		lea	(v_objspace).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

loc_3BD0:				; CODE XREF: ROM:00003BD2j
		move.l	d0,(a1)+
		dbf	d1,loc_3BD0
		lea	($FFFFF628).w,a1
		moveq	#0,d0
		move.w	#$15,d1

loc_3BE0:				; CODE XREF: ROM:00003BE2j
		move.l	d0,(a1)+
		dbf	d1,loc_3BE0
		lea	($FFFFF700).w,a1
		moveq	#0,d0
		move.w	#$3F,d1

loc_3BF0:				; CODE XREF: ROM:00003BF2j
		move.l	d0,(a1)+
		dbf	d1,loc_3BF0
		lea	($FFFFFE60).w,a1
		moveq	#0,d0
		move.w	#$47,d1

loc_3C00:				; CODE XREF: ROM:00003C02j
		move.l	d0,(a1)+
		dbf	d1,loc_3C00
		cmpi.b	#4,(v_zone).w
		bne.s	loc_3C1A
		move.b	#1,($FFFFF730).w
		move.w	#0,(f_2player).w

loc_3C1A:				; CODE XREF: ROM:00003C0Cj
		lea	(vdp_control_port).l,a6
		move.w	#$8B03,(a6)
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$857C,(a6)
		move.w	#$9001,(a6)
		move.w	#$8004,(a6)
		move.w	#$8720,(a6)
		move.w	#$8ADF,($FFFFF624).w
		tst.w	(f_2player).w
		beq.s	loc_3C56
		move.w	#$8A6B,($FFFFF624).w
		move.w	#$8014,(a6)
		move.w	#$8C87,(a6)

loc_3C56:				; CODE XREF: ROM:00003C46j
		move.w	($FFFFF624).w,(a6)
		move.l	#v_vdp_cmdbuf,(v_vdp_cmdbufend).w
		tst.b	($FFFFF730).w
		beq.s	LevelInit_NoWater
		move.w	#$8014,(a6)
		moveq	#0,d0
		move.b	($FFFFFE11).w,d0
		add.w	d0,d0
		lea	(WaterHeight).l,a1
		move.w	(a1,d0.w),d0
		move.w	d0,($FFFFF646).w
		move.w	d0,($FFFFF648).w
		move.w	d0,($FFFFF64A).w
		clr.b	($FFFFF64D).w
		clr.b	($FFFFF64E).w
		move.b	#1,($FFFFF64C).w

LevelInit_NoWater:			; CODE XREF: ROM:00003C66j
		move.w	#$1E,($FFFFFE14).w
		moveq	#3,d0
		bsr.w	PalLoad2
		tst.b	($FFFFF730).w
		beq.s	loc_3CC6
		moveq	#$F,d0
		cmpi.b	#3,($FFFFFE11).w
		bne.s	loc_3CB6
		moveq	#$10,d0

loc_3CB6:				; CODE XREF: ROM:00003CB2j
		bsr.w	PalLoad3_Water
		tst.b	($FFFFFE30).w
		beq.s	loc_3CC6
		move.b	($FFFFFE53).w,($FFFFF64E).w

loc_3CC6:				; CODE XREF: ROM:00003CA8j
					; ROM:00003CBEj
		tst.w	($FFFFFFF0).w
		bmi.s	loc_3D2A
		moveq	#0,d0
		move.b	(v_zone).w,d0
		cmpi.w	#$103,(v_zone).w
		bne.s	loc_3CDC
		moveq	#5,d0

loc_3CDC:				; CODE XREF: ROM:00003CD8j
		cmpi.w	#$502,(v_zone).w
		bne.s	loc_3CE6
		moveq	#6,d0

loc_3CE6:				; CODE XREF: ROM:00003CE2j
		lea	MusicList(pc),a1
		nop
		move.b	(a1,d0.w),d0
		bsr.w	PlaySound
		move.b	#$34,(v_objspace+$80).w 

LevelInit_TitleCard:			; CODE XREF: ROM:00003D1Cj
					; ROM:00003D22j
		move.b	#$C,($FFFFF62A).w
		bsr.w	DelayProgram
		jsr	(ObjectsLoad).l
		jsr	(BuildSprites).l
		bsr.w	RunPLC
		move.w	(v_objspace+$108).w,d0
		cmp.w	(v_objspace+$130).w,d0
		bne.s	LevelInit_TitleCard
		tst.l	($FFFFF680).w
		bne.s	LevelInit_TitleCard
		jsr	(HUD_Base).l

loc_3D2A:				; CODE XREF: ROM:00003CCAj
		moveq	#3,d0
		bsr.w	PalLoad1
		bsr.w	LevelSizeLoad
		bsr.w	DeformBGLayer
		bset	#2,($FFFFEE50).w
		bsr.w	MainLevelLoadBlock
		jsr	(LoadMap16Delta).l
		bsr.w	LoadTilesFromStart
		jsr	(FloorLog_Unk).l
		bsr.w	ColIndexLoad
		bsr.w	WaterEffects
		move.b	#1,(v_objspace).w
		tst.w	($FFFFFFF0).w
		bmi.s	loc_3D6C
		move.b	#$21,(v_objspace+$380).w

loc_3D6C:				; CODE XREF: ROM:00003D64j
		tst.w	(f_2player).w
		bne.s	LevelInit_LoadTails
		cmpi.b	#3,(v_zone).w
		beq.s	LevelInit_SkipTails ; funny how	they skipped Tails in EHZ for the Nick Arcade show

LevelInit_LoadTails:			; CODE XREF: ROM:00003D70j
		move.b	#2,(v_objspace+$40).w
		move.w	(v_objspace+8).w,(v_objspace+$48).w
		move.w	(v_objspace+$C).w,(v_objspace+$4C).w
		subi.w	#$20,(v_objspace+$48).w

LevelInit_SkipTails:			; CODE XREF: ROM:00003D78j
		tst.b	($FFFFFFE2).w
		beq.s	loc_3DA6
		btst	#6,(v_jpadhold1).w
		beq.s	loc_3DA6
		move.b	#1,($FFFFFFFA).w

loc_3DA6:				; CODE XREF: ROM:00003D96j
					; ROM:00003D9Ej
		move.w	#0,(v_jpadhold2).w
		move.w	#0,(v_jpadhold1).w
		tst.b	($FFFFF730).w
		beq.s	loc_3DD0
		move.b	#4,(v_objspace+$780).w
		move.w	#$60,(v_objspace+$788).w
		move.b	#4,(v_objspace+$7C0).w
		move.w	#$120,(v_objspace+$7C8).w

loc_3DD0:				; CODE XREF: ROM:00003DB6j
		jsr	(ObjPosLoad).l
		jsr	(RingPosLoad).l
		jsr	(ObjectsLoad).l
		jsr	(BuildSprites).l
	if removeJmpTos=1
        	jsr     (DynamicArtCues).l
        else
                bsr.w	j_DynamicArtCues
        endif
		moveq	#0,d0
		tst.b	($FFFFFE30).w
		bne.s	loc_3E00
		move.w	d0,($FFFFFE20).w
		move.l	d0,($FFFFFE22).w
		move.b	d0,($FFFFFE1B).w

loc_3E00:				; CODE XREF: ROM:00003DF2j
		move.b	d0,($FFFFFE1A).w
		move.b	d0,($FFFFFE2C).w
		move.b	d0,($FFFFFE2D).w
		move.b	d0,($FFFFFE2E).w
		move.b	d0,($FFFFFE2F).w
		move.w	d0,($FFFFFE08).w
		move.w	d0,($FFFFFE02).w
		move.w	d0,($FFFFFE04).w
		bsr.w	OscillateNumInit
		move.b	#1,($FFFFFE1F).w
		move.b	#1,($FFFFFE1D).w
		move.b	#1,($FFFFFE1E).w
		move.w	#4,($FFFFEED2).w
		move.w	#0,(v_tracktails).w
		move.w	#0,($FFFFF790).w
		move.w	#0,($FFFFF740).w
		lea	(Demo_Index).l,a1
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1
		tst.w	($FFFFFFF0).w
		bpl.s	loc_3E78
		lea	(Demo_S1EndIndex).l,a1 ; garbage, leftover from	Sonic 1's ending sequence demos
		move.w	($FFFFFFF4).w,d0
		subq.w	#1,d0
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1

loc_3E78:				; CODE XREF: ROM:00003E64j
		move.b	1(a1),($FFFFF792).w
		subq.b	#1,($FFFFF792).w
		lea	(Demo_2P).l,a1
		move.b	1(a1),($FFFFF742).w
		subq.b	#1,($FFFFF742).w
		move.w	#$668,(v_demolength).w
		tst.w	($FFFFFFF0).w
		bpl.s	loc_3EB2
		move.w	#$21C,(v_demolength).w
		cmpi.w	#4,($FFFFFFF4).w
		bne.s	loc_3EB2
		move.w	#$1FE,(v_demolength).w

loc_3EB2:				; CODE XREF: ROM:00003E9Cj
					; ROM:00003EAAj
		tst.b	($FFFFF730).w
		beq.s	loc_3EC8
		moveq	#$B,d0
		cmpi.b	#3,($FFFFFE11).w
		bne.s	loc_3EC4
		moveq	#$D,d0

loc_3EC4:				; CODE XREF: ROM:00003EC0j
		bsr.w	PalLoad4_Water

loc_3EC8:				; CODE XREF: ROM:00003EB6j
		move.w	#3,d1

loc_3ECC:				; CODE XREF: ROM:00003ED6j
		move.b	#8,($FFFFF62A).w
		bsr.w	DelayProgram
		dbf	d1,loc_3ECC
		move.w	#$202F,($FFFFF626).w
		bsr.w	Pal_FadeTo2
		tst.w	($FFFFFFF0).w
		bmi.s	Level_ClrTitleCard
		addq.b	#2,(v_objspace+$A4).w
		addq.b	#4,(v_objspace+$E4).w
		addq.b	#4,(v_objspace+$124).w
		addq.b	#4,(v_objspace+$164).w
		bra.s	Level_StartGame
; ---------------------------------------------------------------------------

Level_ClrTitleCard:			; CODE XREF: ROM:00003EE8j
		moveq	#plcid_Explode,d0
		jsr	(LoadPLC).l
		moveq	#0,d0
		move.b	(v_zone).w,d0
		addi.w	#plcid_GHZAnimals,d0
		jsr	(LoadPLC).l

Level_StartGame:			; CODE XREF: ROM:00003EFAj
		bclr	#7,(v_gamemode).w

Level_MainLoop:				; CODE XREF: ROM:00003F90j
					; ROM:00003FA8j
		bsr.w	Pause
		move.b	#8,($FFFFF62A).w
		bsr.w	DelayProgram
		addq.w	#1,($FFFFFE04).w
		bsr.w	MoveSonicInDemo
		bsr.w	WaterEffects
		jsr	(ObjectsLoad).l
		tst.w	($FFFFFE02).w
		bne.w	Level
		tst.w	($FFFFFE08).w
		bne.s	loc_3F50
		cmpi.b	#6,(v_objspace+$24).w
		bcc.s	loc_3F54

loc_3F50:				; CODE XREF: ROM:00003F46j
		bsr.w	DeformBGLayer

loc_3F54:				; CODE XREF: ROM:00003F4Ej
		bsr.w	ChangeWaterSurfacePos
		jsr	(RingPosLoad).l
	if removeJmpTos=1
		jsr     (DynamicArtCues).l
        else
                bsr.w	j_DynamicArtCues
        endif
		bsr.w	PalCycle_Load
		bsr.w	RunPLC
		bsr.w	OscillateNumDo
		bsr.w	ChangeRingFrame
		bsr.w	SignpostArtLoad
		jsr	(BuildSprites).l
		jsr	(ObjPosLoad).l
		cmpi.b	#8,(v_gamemode).w
		beq.s	loc_3F96
		cmpi.b	#$C,(v_gamemode).w
		beq.w	Level_MainLoop
		rts
; ---------------------------------------------------------------------------

loc_3F96:				; CODE XREF: ROM:00003F88j
		tst.w	($FFFFFE02).w
		bne.s	loc_3FB4
		tst.w	(v_demolength).w
		beq.s	loc_3FB4
		cmpi.b	#8,(v_gamemode).w
		beq.w	Level_MainLoop
		move.b	#0,(v_gamemode).w
		rts
; ---------------------------------------------------------------------------

loc_3FB4:				; CODE XREF: ROM:00003F9Aj
					; ROM:00003FA0j
		cmpi.b	#8,(v_gamemode).w
		bne.s	loc_3FCE
		move.b	#0,(v_gamemode).w
		tst.w	($FFFFFFF0).w
		bpl.s	loc_3FCE
		move.b	#$1C,(v_gamemode).w

loc_3FCE:				; CODE XREF: ROM:00003FBAj
					; ROM:00003FC6j
		move.w	#$3C,(v_demolength).w 
		move.w	#$3F,($FFFFF626).w
		clr.w	($FFFFF794).w

loc_3FDE:				; CODE XREF: ROM:00004012j
		move.b	#8,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	MoveSonicInDemo
		jsr	(ObjectsLoad).l
		jsr	(BuildSprites).l
		jsr	(ObjPosLoad).l
		subq.w	#1,($FFFFF794).w
		bpl.s	loc_400E
		move.w	#2,($FFFFF794).w
		bsr.w	Pal_FadeOut

loc_400E:				; CODE XREF: ROM:00004002j
		tst.w	(v_demolength).w
		bne.s	loc_3FDE
		rts

; =============== S U B	R O U T	I N E =======================================


ChangeWaterSurfacePos:			; CODE XREF: ROM:loc_3F54p
		tst.b	($FFFFF730).w
		beq.s	locret_403E
		move.w	(v_screenposx).w,d1
		btst	#0,($FFFFFE05).w
		beq.s	loc_402C
		addi.w	#$20,d1

loc_402C:				; CODE XREF: ChangeWaterSurfacePos+10j
		move.w	d1,d0
		addi.w	#$60,d0
		move.w	d0,(v_objspace+$788).w
		addi.w	#$120,d1
		move.w	d1,(v_objspace+$7C8).w

locret_403E:				; CODE XREF: ChangeWaterSurfacePos+4j
		rts
; End of function ChangeWaterSurfacePos


; =============== S U B	R O U T	I N E =======================================


WaterEffects:				; CODE XREF: ROM:00003D56p
					; ROM:00003F30p
		tst.b	($FFFFF730).w
		beq.s	locret_4094
		tst.b	($FFFFEEDC).w
		bne.s	loc_4058
		cmpi.b	#6,(v_objspace+$24).w
		bcc.s	loc_4058
		bsr.w	DynamicWaterHeight

loc_4058:				; CODE XREF: WaterEffects+Aj
					; WaterEffects+12j
		clr.b	($FFFFF64E).w
		moveq	#0,d0
		move.b	($FFFFFE60).w,d0
		lsr.w	#1,d0
		add.w	($FFFFF648).w,d0
		move.w	d0,($FFFFF646).w
		move.w	($FFFFF646).w,d0
		sub.w	(v_screenposy).w,d0
		bcc.s	loc_4086
		tst.w	d0
		bpl.s	loc_4086
		move.b	#$DF,($FFFFF625).w
		move.b	#1,($FFFFF64E).w

loc_4086:				; CODE XREF: WaterEffects+34j
					; WaterEffects+38j
		cmpi.w	#$DF,d0	
		bcs.s	loc_4090
		move.w	#$DF,d0

loc_4090:				; CODE XREF: WaterEffects+4Aj
		move.b	d0,($FFFFF625).w

locret_4094:				; CODE XREF: WaterEffects+4j
		rts
; End of function WaterEffects

; ---------------------------------------------------------------------------
WaterHeight:	dc.w  $600, $328, $900,	$228; 0	; DATA XREF: ROM:00003C74o

; =============== S U B	R O U T	I N E =======================================


DynamicWaterHeight:			; CODE XREF: WaterEffects+14p
		moveq	#0,d0
		move.b	($FFFFFE11).w,d0
		add.w	d0,d0
		move.w	DynWater_Index(pc,d0.w),d0
		jsr	DynWater_Index(pc,d0.w)
		moveq	#0,d1
		move.b	($FFFFF64C).w,d1
		move.w	($FFFFF64A).w,d0
		sub.w	($FFFFF648).w,d0
		beq.s	locret_40C6
		bcc.s	loc_40C2
		neg.w	d1

loc_40C2:				; CODE XREF: DynamicWaterHeight+20j
		add.w	d1,($FFFFF648).w

locret_40C6:				; CODE XREF: DynamicWaterHeight+1Ej
		rts
; End of function DynamicWaterHeight

; ---------------------------------------------------------------------------
DynWater_Index:	dc.w DynWater_HPZ1-DynWater_Index; 0 ; DATA XREF: ROM:DynWater_Indexo
					; ROM:DynWater_Index+2o ...
		dc.w DynWater_HPZ2-DynWater_Index; 1 ; leftover	from Sonic 1"s LZ2
		dc.w DynWater_HPZ3-DynWater_Index; 2
		dc.w DynWater_HPZ4-DynWater_Index; 3
; ---------------------------------------------------------------------------

DynWater_HPZ1:				; DATA XREF: ROM:DynWater_Indexo
		btst	#0,($FFFFF606).w
		beq.s	loc_40E2
		tst.w	($FFFFF64A).w
		beq.s	loc_40E2
		subq.w	#1,($FFFFF64A).w

loc_40E2:				; CODE XREF: ROM:000040D6j
					; ROM:000040DCj
		btst	#1,($FFFFF606).w
		beq.s	locret_40F6
		cmpi.w	#$700,($FFFFF64A).w
		beq.s	locret_40F6
		addq.w	#1,($FFFFF64A).w

locret_40F6:				; CODE XREF: ROM:000040E8j
					; ROM:000040F0j
		rts
; ---------------------------------------------------------------------------

S1DynWater_LZ1:				; leftover from	Sonic 1
		move.w	(v_screenposx).w,d0
		move.b	($FFFFF64D).w,d2
		bne.s	loc_4164
		move.w	#$B8,d1	
		cmpi.w	#$600,d0
		bcs.s	loc_4148
		move.w	#$108,d1
		cmpi.w	#$200,(v_objspace+$C).w
		bcs.s	loc_414E
		cmpi.w	#$C00,d0
		bcs.s	loc_4148
		move.w	#$318,d1
		cmpi.w	#$1080,d0
		bcs.s	loc_4148
		move.b	#$80,($FFFFF7E5).w
		move.w	#$5C8,d1
		cmpi.w	#$1380,d0
		bcs.s	loc_4148
		move.w	#$3A8,d1
		cmp.w	($FFFFF648).w,d1
		bne.s	loc_4148
		move.b	#1,($FFFFF64D).w

loc_4148:				; CODE XREF: ROM:0000410Aj
					; ROM:0000411Cj ...
		move.w	d1,($FFFFF64A).w
		rts
; ---------------------------------------------------------------------------

loc_414E:				; CODE XREF: ROM:00004116j
		cmpi.w	#$C80,d0
		bcs.s	loc_4148
		move.w	#$E8,d1	
		cmpi.w	#$1500,d0
		bcs.s	loc_4148
		move.w	#$108,d1
		bra.s	loc_4148
; ---------------------------------------------------------------------------

loc_4164:				; CODE XREF: ROM:00004100j
		subq.b	#1,d2
		bne.s	locret_4188
		cmpi.w	#$2E0,(v_objspace+$C).w
		bcc.s	locret_4188
		move.w	#$3A8,d1
		cmpi.w	#$1300,d0
		bcs.s	loc_4184
		move.w	#$108,d1
		move.b	#2,($FFFFF64D).w

loc_4184:				; CODE XREF: ROM:00004178j
		move.w	d1,($FFFFF64A).w

locret_4188:				; CODE XREF: ROM:00004166j
					; ROM:0000416Ej
		rts
; ---------------------------------------------------------------------------

DynWater_HPZ2:				; DATA XREF: ROM:DynWater_Indexo
		move.w	(v_screenposx).w,d0 ; leftover from Sonic 1"s LZ2
		move.w	#$328,d1
		cmpi.w	#$500,d0
		bcs.s	loc_41A6
		move.w	#$3C8,d1
		cmpi.w	#$B00,d0
		bcs.s	loc_41A6
		move.w	#$428,d1

loc_41A6:				; CODE XREF: ROM:00004196j
					; ROM:000041A0j
		move.w	d1,($FFFFF64A).w
		rts
; ---------------------------------------------------------------------------

DynWater_HPZ3:				; DATA XREF: ROM:DynWater_Indexo
		move.w	(v_screenposx).w,d0 ; in fact, this is a leftover from Sonic 1"s LZ3
		move.b	($FFFFF64D).w,d2
		bne.s	loc_41F2
		move.w	#$900,d1
		cmpi.w	#$600,d0
		bcs.s	loc_41E8
		cmpi.w	#$3C0,(v_objspace+$C).w
		bcs.s	loc_41E8
		cmpi.w	#$600,(v_objspace+$C).w
		bcc.s	loc_41E8
		move.w	#$4C8,d1
		move.b	#$4B,(v_lvllayout+$206).w 
		move.b	#1,($FFFFF64D).w
		move.w	#sfx_Rumbling,d0	; "?"
		bsr.w	PlaySound_Special

loc_41E8:				; CODE XREF: ROM:000041BEj
					; ROM:000041C6j ...
		move.w	d1,($FFFFF64A).w
		move.w	d1,($FFFFF648).w
		rts
; ---------------------------------------------------------------------------

loc_41F2:				; CODE XREF: ROM:000041B4j
		subq.b	#1,d2
		bne.s	loc_423C
		move.w	#$4C8,d1
		cmpi.w	#$770,d0
		bcs.s	loc_4236
		move.w	#$308,d1
		cmpi.w	#$1400,d0
		bcs.s	loc_4236
		cmpi.w	#$508,($FFFFF64A).w
		beq.s	loc_4222
		cmpi.w	#$600,(v_objspace+$C).w
		bcc.s	loc_4222
		cmpi.w	#$280,(v_objspace+$C).w
		bcc.s	loc_4236

loc_4222:				; CODE XREF: ROM:00004210j
					; ROM:00004218j
		move.w	#$508,d1
		move.w	d1,($FFFFF648).w
		cmpi.w	#$1770,d0
		bcs.s	loc_4236
		move.b	#2,($FFFFF64D).w

loc_4236:				; CODE XREF: ROM:000041FEj
					; ROM:00004208j ...
		move.w	d1,($FFFFF64A).w
		rts
; ---------------------------------------------------------------------------

loc_423C:				; CODE XREF: ROM:000041F4j
		subq.b	#1,d2
		bne.s	loc_4266
		move.w	#$508,d1
		cmpi.w	#$1860,d0
		bcs.s	loc_4260
		move.w	#$188,d1
		cmpi.w	#$1AF0,d0
		bcc.s	loc_425A
		cmp.w	($FFFFF648).w,d1
		bne.s	loc_4260

loc_425A:				; CODE XREF: ROM:00004252j
		move.b	#3,($FFFFF64D).w

loc_4260:				; CODE XREF: ROM:00004248j
					; ROM:00004258j
		move.w	d1,($FFFFF64A).w
		rts
; ---------------------------------------------------------------------------

loc_4266:				; CODE XREF: ROM:0000423Ej
		subq.b	#1,d2
		bne.s	loc_42A2
		move.w	#$188,d1
		cmpi.w	#$1AF0,d0
		bcs.s	loc_4298
		move.w	#$900,d1
		cmpi.w	#$1BC0,d0
		bcs.s	loc_4298
		move.b	#4,($FFFFF64D).w
		move.w	#$608,($FFFFF64A).w
		move.w	#$7C0,($FFFFF648).w
		move.b	#1,($FFFFF7E8).w
		rts
; ---------------------------------------------------------------------------

loc_4298:				; CODE XREF: ROM:00004272j
					; ROM:0000427Cj
		move.w	d1,($FFFFF64A).w
		move.w	d1,($FFFFF648).w
		rts
; ---------------------------------------------------------------------------

loc_42A2:				; CODE XREF: ROM:00004268j
		cmpi.w	#$1E00,d0
		bcs.s	locret_42AE
		move.w	#$128,($FFFFF64A).w

locret_42AE:				; CODE XREF: ROM:000042A6j
		rts
; ---------------------------------------------------------------------------

DynWater_HPZ4:				; DATA XREF: ROM:DynWater_Indexo
		move.w	#$228,d1	; in fact, this	is a leftover from Sonic 1"s SBZ3
		cmpi.w	#$F00,(v_screenposx).w
		bcs.s	loc_42C0
		move.w	#$4C8,d1

loc_42C0:				; CODE XREF: ROM:000042BAj
		move.w	d1,($FFFFF64A).w
		rts
; ---------------------------------------------------------------------------

S1_LZWindTunnels:			; leftover from	Sonic 1"s LZ
		tst.w	($FFFFFE08).w
		bne.w	locret_43A2
		lea	(S1LZWind_Data).l,a2
		moveq	#0,d0
		move.b	($FFFFFE11).w,d0
		lsl.w	#3,d0
		adda.w	d0,a2
		moveq	#0,d1
		tst.b	($FFFFFE11).w
		bne.s	loc_42EA
		moveq	#1,d1
		subq.w	#8,a2

loc_42EA:				; CODE XREF: ROM:000042E4j
		lea	(v_objspace).w,a1

loc_42EE:				; CODE XREF: ROM:0000438Ej
		move.w	8(a1),d0
		cmp.w	(a2),d0
		bcs.w	loc_438C
		cmp.w	4(a2),d0
		bcc.w	loc_438C
		move.w	$C(a1),d2
		cmp.w	2(a2),d2
		bcs.w	loc_438C
		cmp.w	6(a2),d2
		bcc.s	loc_438C
		move.b	($FFFFFE0F).w,d0
		andi.b	#$3F,d0	
		bne.s	loc_4326
		move.w	#sfx_Waterfall,d0	; "?"
		jsr	(PlaySound_Special).l

loc_4326:				; CODE XREF: ROM:0000431Aj
		tst.b	($FFFFF7C9).w
		bne.w	locret_43A2
		cmpi.b	#4,$24(a1)
		bcc.s	loc_439E
		move.b	#1,($FFFFF7C7).w
		subi.w	#$80,d0	
		cmp.w	(a2),d0
		bcc.s	loc_4354
		moveq	#2,d0
		cmpi.b	#1,($FFFFFE11).w
		bne.s	loc_4350
		neg.w	d0

loc_4350:				; CODE XREF: ROM:0000434Cj
		add.w	d0,$C(a1)

loc_4354:				; CODE XREF: ROM:00004342j
		addi.w	#4,8(a1)
		move.w	#$400,$10(a1)
		move.w	#0,$12(a1)
		move.b	#$F,$1C(a1)
		bset	#1,$22(a1)
		btst	#0,(v_jpadhold1).w
		beq.s	loc_437E
		subq.w	#1,$C(a1)

loc_437E:				; CODE XREF: ROM:00004378j
		btst	#1,(v_jpadhold1).w
		beq.s	locret_438A
		addq.w	#1,$C(a1)

locret_438A:				; CODE XREF: ROM:00004384j
		rts
; ---------------------------------------------------------------------------

loc_438C:				; CODE XREF: ROM:000042F4j
					; ROM:000042FCj ...
		addq.w	#8,a2
		dbf	d1,loc_42EE
		tst.b	($FFFFF7C7).w
		beq.s	locret_43A2
		move.b	#0,$1C(a1)

loc_439E:				; CODE XREF: ROM:00004334j
		clr.b	($FFFFF7C7).w

locret_43A2:				; CODE XREF: ROM:000042CAj
					; ROM:0000432Aj ...
		rts
; ---------------------------------------------------------------------------
		dc.w  $A80, $300, $C10,	$380; 0
S1LZWind_Data:	dc.w  $F80, $100,$1410,	$180, $460, $400, $710,	$480, $A20, $600,$1610,	$6E0, $C80, $600,$13D0,	$680; 0
					; DATA XREF: ROM:000042CEo
; ---------------------------------------------------------------------------

S1_LZWaterSlides:
		lea	(v_objspace).w,a1
		btst	#1,$22(a1)
		bne.s	loc_4400
		move.w	$C(a1),d0
		andi.w	#$700,d0
		move.b	8(a1),d1

loc_43E4:
		andi.w	#$7F,d1	
		add.w	d1,d0
		lea	(v_lvllayout).w,a2
		move.b	(a2,d0.w),d0
		lea	byte_4465(pc),a2
		moveq	#6,d1

loc_43F8:				; CODE XREF: ROM:000043FAj
		cmp.b	-(a2),d0
		dbeq	d1,loc_43F8
		beq.s	loc_4412

loc_4400:				; CODE XREF: ROM:000043D6j
		tst.b	($FFFFF7CA).w
		beq.s	locret_4410
		move.w	#5,$2E(a1)
		clr.b	($FFFFF7CA).w

locret_4410:				; CODE XREF: ROM:00004404j
		rts
; ---------------------------------------------------------------------------

loc_4412:				; CODE XREF: ROM:000043FEj
		cmpi.w	#3,d1
		bcc.s	loc_441A
		nop

loc_441A:				; CODE XREF: ROM:00004416j
		bclr	#0,$22(a1)
		move.b	byte_4456(pc,d1.w),d0
		move.b	d0,$14(a1)
		bpl.s	loc_4430
		bset	#0,$22(a1)

loc_4430:				; CODE XREF: ROM:00004428j
		clr.b	$15(a1)
		move.b	#$1B,$1C(a1)
		move.b	#1,($FFFFF7CA).w
		move.b	($FFFFFE0F).w,d0
		andi.b	#$1F,d0
		bne.s	locret_4454
		move.w	#sfx_Waterfall,d0	; "?"
		jsr	(PlaySound_Special).l

locret_4454:				; CODE XREF: ROM:00004448j
		rts
; ---------------------------------------------------------------------------
byte_4456:	dc.b  $A,$F5, $A,$F6,$F5,$F4, $B,  0,  2,  7,  3,$4C,$4B,  8,  4; 0
byte_4465:	dc.b 0			; DATA XREF: ROM:000043F2t

; =============== S U B	R O U T	I N E =======================================


MoveSonicInDemo:			; CODE XREF: ROM:00003F2Cp
					; ROM:00003FE8p ...
		tst.w	($FFFFFFF0).w
		bne.s	MoveDemo_On
		rts
; ---------------------------------------------------------------------------

MoveSonic_DemoRecord:			; unused subroutine for	recording demos
		lea	($FE8000).l,a1

loc_4474:
		move.w	($FFFFF790).w,d0
		adda.w	d0,a1
		move.b	(v_jpadhold1).w,d0
		cmp.b	(a1),d0
		bne.s	loc_4490
		addq.b	#1,1(a1)
		cmpi.b	#$FF,1(a1)
		beq.s	loc_4490
		bra.s	loc_44A4
; ---------------------------------------------------------------------------

loc_4490:				; CODE XREF: MoveSonicInDemo+1Aj
					; MoveSonicInDemo+26j
		move.b	d0,2(a1)
		move.b	#0,3(a1)
		addq.w	#2,($FFFFF790).w
		andi.w	#$3FF,($FFFFF790).w

loc_44A4:				; CODE XREF: MoveSonicInDemo+28j
		cmpi.b	#3,(v_zone).w
		bne.s	locret_44E2
		lea	($FEC000).l,a1
		move.w	($FFFFF740).w,d0
		adda.w	d0,a1
		move.b	($FFFFF606).w,d0
		cmp.b	(a1),d0
		bne.s	loc_44CE
		addq.b	#1,1(a1)
		cmpi.b	#$FF,1(a1)
		beq.s	loc_44CE
		bra.s	locret_44E2
; ---------------------------------------------------------------------------

loc_44CE:				; CODE XREF: MoveSonicInDemo+58j
					; MoveSonicInDemo+64j
		move.b	d0,2(a1)
		move.b	#0,3(a1)
		addq.w	#2,($FFFFF740).w
		andi.w	#$3FF,($FFFFF740).w

locret_44E2:				; CODE XREF: MoveSonicInDemo+44j
					; MoveSonicInDemo+66j
		rts
; ---------------------------------------------------------------------------

MoveDemo_On:				; CODE XREF: MoveSonicInDemo+4j
		tst.b	(v_jpadhold1).w
		bpl.s	loc_44F6
		tst.w	($FFFFFFF0).w
		bmi.s	loc_44F6
		move.b	#4,(v_gamemode).w

loc_44F6:				; CODE XREF: MoveSonicInDemo+82j
					; MoveSonicInDemo+88j
		lea	(Demo_Index).l,a1
		moveq	#0,d0
		move.b	(v_zone).w,d0
		cmpi.b	#$10,(v_gamemode).w
		bne.s	loc_450C
		moveq	#6,d0

loc_450C:				; CODE XREF: MoveSonicInDemo+A2j
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1
		move.w	($FFFFF790).w,d0
		adda.w	d0,a1
		move.b	(a1),d0
		lea	(v_jpadhold1).w,a0
		move.b	d0,d1
		moveq	#0,d2
		eor.b	d2,d0
		move.b	d1,(a0)+
		and.b	d1,d0
		move.b	d0,(a0)+
		subq.b	#1,($FFFFF792).w
		bcc.s	loc_453A
		move.b	3(a1),($FFFFF792).w
		addq.w	#2,($FFFFF790).w

loc_453A:				; CODE XREF: MoveSonicInDemo+C8j
		cmpi.b	#3,(v_zone).w
		bne.s	loc_4572
		lea	(Demo_2P).l,a1
		move.w	($FFFFF740).w,d0
		adda.w	d0,a1
		move.b	(a1),d0
		lea	($FFFFF606).w,a0
		move.b	d0,d1
		moveq	#0,d2
		eor.b	d2,d0
		move.b	d1,(a0)+
		and.b	d1,d0
		move.b	d0,(a0)+
		subq.b	#1,($FFFFF742).w
		bcc.s	locret_4570
		move.b	3(a1),($FFFFF742).w
		addq.w	#2,($FFFFF740).w

locret_4570:				; CODE XREF: MoveSonicInDemo+FEj
		rts
; ---------------------------------------------------------------------------

loc_4572:				; CODE XREF: MoveSonicInDemo+DAj
		move.w	#0,($FFFFF606).w
		rts
; End of function MoveSonicInDemo

; ---------------------------------------------------------------------------
Demo_Index:	dc.l Demo_S1GHZ		; DATA XREF: ROM:00003E4Eo
					; MoveSonicInDemo:loc_44F6o ...
					; leftover demo	from Sonic 1 GHZ
		dc.l Demo_S1GHZ		; leftover demo	from Sonic 1 GHZ
		dc.l Demo_CPZ
		dc.l Demo_EHZ
		dc.l Demo_HPZ
		dc.l Demo_HTZ
		dc.l Demo_S1SS		; leftover demo	from Sonic 1 Special Stage
		dc.l Demo_S1SS		; leftover demo	from Sonic 1 Special Stage
		dc.l $FE8000
		dc.l $FE8000
		dc.l $FE8000
		dc.l $FE8000
		dc.l $FE8000
		dc.l $FE8000
		dc.l $FE8000
		dc.l $FE8000
		dc.l $FE8000
Demo_S1EndIndex:dc.l $8B0837		; DATA XREF: ROM:00003E66o
					; garbage, leftover from Sonic 1"s ending sequence demos
		dc.l $42085C
		dc.l $6A085F
		dc.l $2F082C
		dc.l $210803
		dc.l $28300808
		dc.l $2E0815
		dc.l $F0846
		dc.l $1A08FF
		dc.l $8CA0000
		dc.l 0
		dc.l 0

; =============== S U B	R O U T	I N E =======================================


ColIndexLoad:				; CODE XREF: ROM:00003D52p
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#2,d0
		move.l	#v_col1st,($FFFFF796).w
		movea.l	ColP_Index(pc,d0.w),a1
		lea	(v_col1st).w,a2
		bsr.s	Col_Load
		movea.l	ColS_Index(pc,d0.w),a1
		lea	(v_col2nd).w,a2
; End of function ColIndexLoad


; =============== S U B	R O U T	I N E =======================================


Col_Load:				; CODE XREF: ColIndexLoad+18p
		move.w	#$2FF,d1
		moveq	#0,d2

loc_4616:				; CODE XREF: Col_Load+Aj
		move.b	(a1)+,d2
		move.w	d2,(a2)+
		dbf	d1,loc_4616
		rts
; End of function Col_Load

; ---------------------------------------------------------------------------
ColP_Index:	dc.l ColP_GHZ		; 0
		dc.l ColP_CPZ		; 1
		dc.l ColP_CPZ		; 2
		dc.l ColP_EHZ		; 3
		dc.l ColP_HPZ		; 4
		dc.l ColP_EHZ		; 5
ColS_Index:	dc.l ColS_GHZ		; 0
		dc.l ColS_CPZ		; 1
		dc.l ColS_CPZ		; 2
		dc.l ColS_EHZ		; 3
		dc.l ColS_HPZ		; 4
		dc.l ColS_EHZ		; 5

; =============== S U B	R O U T	I N E =======================================


OscillateNumInit:			; CODE XREF: ROM:00003E20p
		lea	($FFFFFE5E).w,a1
		lea	(Osc_Data).l,a2
		moveq	#$20,d1	

loc_465C:				; CODE XREF: OscillateNumInit+Ej
		move.w	(a2)+,(a1)+
		dbf	d1,loc_465C
		rts
; End of function OscillateNumInit

; ---------------------------------------------------------------------------
Osc_Data:	dc.w   $7C,  $80	; 0 ; DATA XREF: OscillateNumInit+4o
		dc.w	 0,  $80	; 2
		dc.w	 0,  $80	; 4
		dc.w	 0,  $80	; 6
		dc.w	 0,  $80	; 8
		dc.w	 0,  $80	; 10
		dc.w	 0,  $80	; 12
		dc.w	 0,  $80	; 14
		dc.w	 0,  $80	; 16
		dc.w	 0,$50F0	; 18
		dc.w  $11E,$2080	; 20
		dc.w   $B4,$3080	; 22
		dc.w  $10E,$5080	; 24
		dc.w  $1C2,$7080	; 26
		dc.w  $276,  $80	; 28
		dc.w	 0,  $80	; 30
		align 2

; =============== S U B	R O U T	I N E =======================================


OscillateNumDo:				; CODE XREF: ROM:00003F6Ap
		cmpi.b	#6,(v_objspace+$24).w
		bcc.s	locret_46FC
		lea	($FFFFFE5E).w,a1
		lea	(OscData2).l,a2
		move.w	(a1)+,d3
		moveq	#$F,d1

loc_46BC:				; CODE XREF: OscillateNumDo+4Ej
		move.w	(a2)+,d2
		move.w	(a2)+,d4
		btst	d1,d3
		bne.s	loc_46DC
		move.w	2(a1),d0
		add.w	d2,d0
		move.w	d0,2(a1)
		add.w	d0,0(a1)
		cmp.b	0(a1),d4
		bhi.s	loc_46F2
		bset	d1,d3
		bra.s	loc_46F2
; ---------------------------------------------------------------------------

loc_46DC:				; CODE XREF: OscillateNumDo+1Cj
		move.w	2(a1),d0
		sub.w	d2,d0
		move.w	d0,2(a1)
		add.w	d0,0(a1)
		cmp.b	0(a1),d4
		bls.s	loc_46F2
		bclr	d1,d3

loc_46F2:				; CODE XREF: OscillateNumDo+30j
					; OscillateNumDo+34j ...
		addq.w	#4,a1
		dbf	d1,loc_46BC
		move.w	d3,($FFFFFE5E).w

locret_46FC:				; CODE XREF: OscillateNumDo+6j
		rts
; End of function OscillateNumDo

; ---------------------------------------------------------------------------
OscData2:	dc.w	 2,  $10	; 0 ; DATA XREF: OscillateNumDo+Co
		dc.w	 2,  $18	; 2
		dc.w	 2,  $20	; 4
		dc.w	 2,  $30	; 6
		dc.w	 4,  $20	; 8
		dc.w	 8,    8	; 10
		dc.w	 8,  $40	; 12
		dc.w	 4,  $40	; 14
		dc.w	 2,  $50	; 16
		dc.w	 2,  $50	; 18
		dc.w	 2,  $20	; 20
		dc.w	 3,  $30	; 22
		dc.w	 5,  $50	; 24
		dc.w	 7,  $70	; 26
		dc.w	 2,  $10	; 28
		dc.w	 2,  $10	; 30

; =============== S U B	R O U T	I N E =======================================


ChangeRingFrame:			; CODE XREF: ROM:00003F6Ep
		subq.b	#1,($FFFFFEC0).w
		bpl.s	loc_4754
		move.b	#$B,($FFFFFEC0).w
		subq.b	#1,($FFFFFEC1).w
		andi.b	#7,($FFFFFEC1).w

loc_4754:				; CODE XREF: ChangeRingFrame+4j
		subq.b	#1,($FFFFFEC2).w
		bpl.s	loc_476A
		move.b	#7,($FFFFFEC2).w
		addq.b	#1,($FFFFFEC3).w
		andi.b	#3,($FFFFFEC3).w

loc_476A:				; CODE XREF: ChangeRingFrame+1Aj
		subq.b	#1,($FFFFFEC4).w
		bpl.s	loc_4788
		move.b	#7,($FFFFFEC4).w
		addq.b	#1,($FFFFFEC5).w
		cmpi.b	#6,($FFFFFEC5).w
		bcs.s	loc_4788
		move.b	#0,($FFFFFEC5).w

loc_4788:				; CODE XREF: ChangeRingFrame+30j
					; ChangeRingFrame+42j
		tst.b	($FFFFFEC6).w
		beq.s	locret_47AA
		moveq	#0,d0
		move.b	($FFFFFEC6).w,d0
		add.w	($FFFFFEC8).w,d0
		move.w	d0,($FFFFFEC8).w
		rol.w	#7,d0
		andi.w	#3,d0
		move.b	d0,($FFFFFEC7).w
		subq.b	#1,($FFFFFEC6).w

locret_47AA:				; CODE XREF: ChangeRingFrame+4Ej
		rts
; End of function ChangeRingFrame


; =============== S U B	R O U T	I N E =======================================


SignpostArtLoad:			; CODE XREF: ROM:00003F72p
		tst.w	($FFFFFE08).w
		bne.w	locret_47E2
		cmpi.b	#1,($FFFFFE11).w
		beq.s	locret_47E2
		move.w	(v_screenposx).w,d0
		move.w	($FFFFEECA).w,d1
		subi.w	#$100,d1
		cmp.w	d1,d0
		blt.s	locret_47E2
		tst.b	($FFFFFE1E).w
		beq.s	locret_47E2
		cmp.w	($FFFFEEC8).w,d1
		beq.s	locret_47E2
		move.w	d1,($FFFFEEC8).w
		moveq	#plcid_Signpost,d0
		bra.w	LoadPLC2
; ---------------------------------------------------------------------------

locret_47E2:				; CODE XREF: SignpostArtLoad+4j
					; SignpostArtLoad+Ej ...
		rts
; End of function SignpostArtLoad

; ---------------------------------------------------------------------------
Demo_EHZ:	dc.b   0,$44,  8,  0,$28,  5,  8,$59,$28,  4,  8,$35,$28,  6,  8,$42; 0
					; DATA XREF: ROM:00004586o
		dc.b $28,  4,  8,$19,  0, $F,  8, $A,$28,  9,  8,$4A,$28,  9,  8,$10; 16
		dc.b   0,  5,  4,$1B,  2,  0,  8,$4B,$28,$2D,  8,$55,$28,  9,  8,$26; 32
		dc.b $28,$1C,  8,$19,$28,  8,  8,$FF,  8,$96,$28,$13,  8,$1D,$28,$19; 48
		dc.b   8,$2A,$28,  7,  9,  0,  1,  0,  5,$20,  4,  2,  5,  1,  0,  0; 64
		dc.b   8,$3A,  0,$25,  4, $A,$24,  9,  4,$1C,  0,  3,  8,$3A,$28,  6; 80
		dc.b   8, $C,  0,$16,  8,  0,$28, $F,  8,$33,$28,  7,  8,  4,  0,$46; 96
		dc.b   8,$6A,  0,$29,$80,  0,$C0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 112
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 128
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 144
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 160
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 176
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 192
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 208
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 224
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 240
Demo_2P:	dc.b   0,$46,  8,$1E,$28, $A,  8,$5E,$28,$30,  8,$66,  0, $F,  8, $F; 0
					; DATA XREF: ROM:00003E82o
					; MoveSonicInDemo+DCo
		dc.b $28,$2E,  8,  0,  0,$1F,  8,$12,  0,$13,  8, $A,  0,$16,  4, $D; 16
		dc.b   0,  8,  4,$10,  0,$30,  8,$6B,$28,$14,  8,$80, $A,  2,  2,$23; 32
		dc.b   0,  7,  8,$13,$28,$17,  8,  0,  0,  3,  4,  3,  5,  0,  1,  0; 48
		dc.b   9,  1,  8,$3C,$28,  7,  0,$18,  8,$4D,$28,$12,  8,  1,  0,  4; 64
		dc.b   8, $B,  0,  7,  8,$1B,  0,  9,$20,  5,$28,$13,  8,  4,  0,$21; 80
		dc.b   8,$11,  0,$20,  8,$51,  0, $B,  4,$57,  0, $D,  2,$27, $A,  0; 96
		dc.b   0,  2,  9,  1,  8,$2A,$28,$15,  8,  3,$28,$19,  8, $A,  0, $A; 112
		dc.b   8,  2,$28,$1B,  8,$33,  0,$27,  8,$3A,  9,$12,  1,  7,  0,$13; 128
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 144
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 160
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 176
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 192
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 208
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 224
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 240
Demo_HTZ:	dc.b   0,  5,  1,$1D,  9,  3,$29,  5,  9,$10,  1,  0,  0,$13,  4,  0; 0
					; DATA XREF: ROM:0000458Eo
		dc.b   5, $A,$25,  7,  5,$10,  4,  1,  0, $C,  8,  4,  9, $C,$29, $A; 16
		dc.b   9,$10,  8,  3,  0,$1C,$20,  7,  0, $B,  4,  6,  0,$25,$20,  6; 32
		dc.b   0,$22,  8,  5,  0,$25,  4, $E,  0,$33,  8,  7,  0,$39,  8, $A; 48
		dc.b $28,  8,  8,$16,  0,$24,  8,$74,$28,  2,$29,  7,  9,  3,  0, $F; 64
		dc.b   8, $D,  0,  5,  4, $C,  0,  1,$20,  2,$28,  0,$2A,  8,$28,  2; 80
		dc.b   8,$1E,  0,  4,  4,$13,  0,$12,  8,$18,$28, $B,  8,$11,  0,$2C; 96
		dc.b   8, $C,  0, $D,$20,  4,$28,  3,  8,  5,  0,$22,  4,$12,  0,  4; 112
		dc.b   8,$1A,  0, $D,  4,  6,  0,$37,  8, $C,  0,$19,  8, $D,  0, $C; 128
		dc.b   4,  9,  0,  3,  8,$20,  0,$1A,  4,  6,  0,$22,  8,  9,  0,  9; 144
		dc.b   8,$16,  0,$2F,  8, $E,$28,  4,$20,  2,  0,  8,  4,$19,  0,  5; 160
		dc.b   8,  6,$28,  8,  8,  8,  0,$24,  8,$72, $A,  9,  2, $E, $A,$6B; 176
		dc.b $8A,  0,$40,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 192
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 208
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 224
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 240
Demo_HPZ:	dc.b   0,$40,  8,$33,$28,  6,  8,$39,$28,  5,  8, $D,  0,$25,  8,$10; 0
					; DATA XREF: ROM:0000458Ao
		dc.b $28,$2A,  8,$1C,  2,  0,$26,  3,$22,  0,$2A,  0,$28,  6,  8,$22; 16
		dc.b   2,  0,  6, $F,  4,  8,  6,  0,  2, $E,  6,$2F,  2,$79,  6,  1; 32
		dc.b   4,$43,$24, $F,  4,$17,  0,  9,  8,$1C,$28,  3,  8,$45,  0,  5; 48
		dc.b   8,$1A,$28,$33,  8,$72,  0, $F,  4,$15,$24,$10,  4, $B,  0,$24; 64
		dc.b   4,  1,$24,  8,  4,  7,  0,  6,  4,  4,  0,$1E,$24, $E,  4,$15; 80
		dc.b   0,$1E,$20,  3,$24, $F,  4,  0,  0,  7,  8,$12,  4,  9,$24, $F; 96
		dc.b   4,  6,  0, $A,  4,$62,$24,$12,$20,  4,  0,$21,$28, $E,  8,$16; 112
		dc.b   0,$19,  8,$29,  0,$63,  4,$15,$24,  9,  4,$39,  0,$31,  8,$25; 128
		dc.b $28,  2,  8,$12,  0,$93,$80,  0,$C0,  0,  0,  0,  0,  0,  0,  0; 144
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 160
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 176
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 192
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 208
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 224
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 240
Demo_CPZ:	dc.b   0,$1B,  1,$30,  0,$19,  8,$29,$28,$13,  8,  3,  0,$1D,$20,  3; 0
					; DATA XREF: ROM:00004582o
		dc.b $28,$1E,  8,  2,  0,  9,  4,  5,  0,$2E,  8,$1E,$28,  5,$20,  3; 16
		dc.b   0, $B,  4,  1,  5,  7,  4,  0,  0,$2F,$28,  3,$2A,  4, $A,  0; 32
		dc.b   8,  6,  0,$24,  8,  2,$28,  6,  8,  1,  0,$26,  8,$FF,  8,$14; 48
		dc.b $28, $A,  8,  3,  0,$60,  8, $E,$28,  7,  8, $C,  0,  8,  4, $B; 64
		dc.b   0,$23,  8,  5,  0,$93,  8,$19,$28,$11,  8,$78,$28, $F,  8,$FF; 80
		dc.b   8,$83,$28, $D,  8,$82,  0,$1F,$80,  0,$40,  0,  0,  0,  0,  0; 96
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 112
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 128
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 144
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 160
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 176
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 192
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 208
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 224
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 240
Demo_S1GHZ:	dc.b   0,$4A,  8,$61,$28, $B,  8,$47,$28,  7,  8,$3B,$28,  8,  8,$D1; 0
					; DATA XREF: ROM:Demo_Indexo
					; ROM:0000457Eo
		dc.b $28,$10,  8, $A,  0, $E,$20,$12,$28,  4,  8,$1F,  0, $B,  6,  5; 16 ; leftover demo from Sonic 1 GHZ
		dc.b   4,  5,  0,  4,$20, $B,$28, $E,  8,$20,  0,  5,$20,  2,$28,$12; 32
		dc.b   8, $F,  0, $F,  8, $B,  0,  0,$20, $E,$28,  4,  8, $B,  0,$1A; 48
		dc.b   8, $C,  0,  6,$20,$12,$28,  7,  8,$77,$28,  0,$20, $C,$24,  4; 64
		dc.b $20,  7,$28,  6,  8,  4,  0, $F,  8,$39,  0,$11,  8, $D,$28, $A; 80
		dc.b   8,$50,$28, $F,  8,  5,  0,$14,  8,$FF,  8,$56,  0,$FF,  0,$3F; 96
		dc.b   8,  0,$28, $E,  8,$17,  0,$17,  8,  5,  0,  0,  0,  0,  0,  0; 112
		dc.b   0,  9,  8,$78,  0,  6,  8,  6,  0,  3,$20,  5,$28,$11,  8, $D; 128
		dc.b   0,$2B,  8,  2,$29,  7,  9,  2,  0,  7,  5, $F,  0,  8,  8, $D; 144
		dc.b $28,  7,  8, $B,  0,$28,  8,  0,  9,  2,$29,  2,$28,  4,  8,$12; 160
		dc.b   0,  9,  8,  0,$29,  2,$28,  4,  8,  9,  0, $F,  8, $C,  0, $E; 176
		dc.b   9,  0,$29,  8,  9,  2,  8,$18,  0,  9,$28,  0,$29, $A,  9,$12; 192
		dc.b   8,  0,  0,$18,$29,$10,  9,$10,  8,  3,  0,$2F,  5,  6,  0,  9; 208
		dc.b   8,  0,  9,  1,$29,$12,  9,  0,  8,  5,  0,$24,  8,  0,  9,  0; 224
		dc.b $29,  9,$28,  6,  8, $A,  0,$2A,  8,$1B,  0,$17,  4,  5,  0, $C; 240
		dc.b   8,$20,  0,  4,$20,  3,  0, $E,  9,  4,  1,  0,  0,$1E,  8,  5; 256
		dc.b   0,  1,$20,  6,$29,  1,  5,  7,  0,$13,  8,  5,  0,$15,$20,  1; 272
		dc.b $28,  2,$29,  4,  9,  1,  8,  0,  0,  7,  8, $B,  0,$19,  8, $B; 288
		dc.b $28,  6,  8,  5,  0,$12,  8,$11,  0, $C,$20,  2,$28,  4,  8,  4; 304
		dc.b   0,$15,  8, $C,  0,$14,$20,  4,$28,  0,  8,  2,  0,$18,  8,  3; 320
		dc.b   0,$2C,$20,  2,$28,  7,  8,  4,  0,$24,  6,$48,  4,$47,  0, $A; 336
		dc.b   4,  7,  0,$14,  4,$44,  5,  0,  4,  0,  0,$15,  8,$15, $A,  1; 352
		dc.b   0,  8,  4,  2,  5,$14,  0,  1,  5,  1,$25, $D,  5,$1B,  0,  7; 368
		dc.b   8,$23,  9,  0,  0,  7,  5,$22,$25, $B,  5,$52,  0,  6,  8,$26; 384
		dc.b   9,  1,  1,  0,  0,  0,  1,  0,  5,$17,$25,  8,  5,$1A,  0, $C; 400
		dc.b   8,  6,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 416
		dc.b   0,$11,  8,$37,$28,  4,  8, $A,  0,$12,  8, $B,  0,$1F,  8,$1B; 432
		dc.b   0,  9,  8,$20,  0,$14,  4,$16,$24,  0,$20, $F,  0,$13,  4,$17; 448
		dc.b   6,  4,  2,  0,  0,$24,  8, $D,  0,$46,  8,$77,  0,$60,  8,$17; 464
		dc.b   0,$16,  4,  3,  0,$22,  8,$19,$28,  2,$20,  1,  0,$26,$20,  9; 480
		dc.b   0,$3A,$20,$23,  0,  3,  8,  1,  0,$29,  4,$13,  0,$19,  4,$1B; 496
		dc.b   0,$91,  8,$21,  0,$19,  4,  4,  0,$67,  4,$23,  0, $A,  8,  5; 512
		dc.b   0,$87,  8,$21,  0,$2C,  8,$27,  0, $F,  8,$35,$28,  8,  8,$45; 528
		dc.b $28,  9,  8,$31,  0,$99,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 544
Demo_S1SS:	dc.b   0,$26,  4,  5,  0,$2A,  8,$1B,  0,  6,  4,  9,  0,  6,$20,  1; 0
					; DATA XREF: ROM:00004592o
					; ROM:00004596o
		dc.b $28,  1,$29,  2,  9,  0,  8,  8,  0,  6,  8,  7,  0,$49,  8, $B; 16 ; leftover demo from Sonic 1 Special Stage
		dc.b   0,  2,$20,  3,  0, $D,  8,$1D,  0,$13,  8,  6,  0,$21,  8,$21; 32
		dc.b   0,  6,  8,$36,  0,$1E,  8,$1A,  0,  6,$20,  0,$28,  4,  8,$19; 48
		dc.b   0,  4,  4,$11,  0,$1F,  4, $D,  0, $C,  4,$1E,  5,  1,  4,  0; 64
		dc.b   0,  9,  8, $C,  0,  6,  4,  5,  5,  1,  4,$87,$24,  7,  4,  4; 80
		dc.b   0,  4,  8, $D,  9,$14,  8,  4,  0,  3,  4,$17,$24,$13,  4, $A; 96
		dc.b   0,  4,  9,  9,  8,  2,  0,  6,  4,$18,$24, $B,$20,  4,  0,  2; 112
		dc.b   4,$2E,  5,  1,  4,  0,  0,$13,$20,$14,  0,  4,  8,$19,  0,$10; 128
		dc.b $20,$1D,$24,  7,  4, $E,  0, $B,$20,$1B,$24,  5,  4,$17,$24,  0; 144
		dc.b $20,$18,$24,  5,  4, $B,  0,  8,$20,$1F,$24,  1,  4,  8,  0, $B; 160
		dc.b $20,$12,$28,  7,$29, $C,$20,  0,  4,$18,  0,$1A,  8,  0,  9,  7; 176
		dc.b   8,  9,  9,$31,  8,  0,  0,  7,$20,  8,$24,$15,  4,  8,  0,$27; 192
		dc.b $20,  9,$24,$12,  4, $E,$24, $E,  4, $A,  0,  9,  8,$16,$28,  0; 208
		dc.b $20, $F,$28,  4,$29,$1B,  9,  5,$29, $C,  9,  0,  8,  7,  0,$A0; 224
		dc.b   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 240
; ---------------------------------------------------------------------------

        if removeJmpTos=0
j_DynamicArtCues:
		jmp	DynamicArtCues

		align 4
	endif

GM_Special:				; CODE XREF: ROM:000003ACj
		move.w	#sfx_EnterSS,d0	; "?"
		bsr.w	PlaySound_Special
		bsr.w	Pal_MakeFlash
		move	#$2700,sr
		lea	(vdp_control_port).l,a6
		move.w	#$8B03,(a6)
		move.w	#$8004,(a6)
		move.w	#$8AAF,($FFFFF624).w
		move.w	#$9011,(a6)
		move.w	(v_vdp_buffer1).w,d0
		andi.b	#$BF,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	ClearScreen
		move	#$2300,sr
		lea	(vdp_control_port).l,a5
		move.w	#$8F01,(a5)
		move.l	#$946F93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$50000081,(a5)
		move.w	#0,(vdp_data_port).l

loc_507C:				; CODE XREF: ROM:00005082j
		move.w	(a5),d1
		btst	#1,d1
		bne.s	loc_507C
		move.w	#$8F02,(a5)
		bsr.w	S1_SSBGLoad
		moveq	#$14,d0
		bsr.w	RunPLC_ROM
		lea	(v_objspace+$2000).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

loc_509C:				; CODE XREF: ROM:0000509Ej
		move.l	d0,(a1)+
		dbf	d1,loc_509C
		lea	($FFFFF700).w,a1
		moveq	#0,d0
		move.w	#$3F,d1

loc_50AC:				; CODE XREF: ROM:000050AEj
		move.l	d0,(a1)+
		dbf	d1,loc_50AC
		lea	($FFFFFE60).w,a1
		moveq	#0,d0
		move.w	#$27,d1	

loc_50BC:				; CODE XREF: ROM:000050BEj
		move.l	d0,(a1)+
		dbf	d1,loc_50BC
		lea	(v_ngfx_buffer).w,a1
		moveq	#0,d0
		move.w	#$7F,d1

loc_50CC:				; CODE XREF: ROM:000050CEj
		move.l	d0,(a1)+
		dbf	d1,loc_50CC
		clr.b	($FFFFF64E).w
		clr.w	($FFFFFE02).w
		moveq	#$A,d0
		bsr.w	PalLoad1
		jsr	(S1SS_Load).l
		move.l	#0,(v_screenposx).w
		move.l	#0,(v_screenposy).w
		move.b	#9,(v_objspace).w
		bsr.w	PalCycle_S1SS
		clr.w	($FFFFF780).w
		move.w	#$40,($FFFFF782).w 
		move.w	#bgm_SS,d0	; "?"
		bsr.w	PlaySound
		move.w	#0,($FFFFF790).w
		lea	(Demo_Index).l,a1
		moveq	#6,d0
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1
		move.b	1(a1),($FFFFF792).w
		subq.b	#1,($FFFFF792).w
		clr.w	($FFFFFE20).w
		clr.b	($FFFFFE1B).w
		move.w	#0,($FFFFFE08).w
		move.w	#$708,(v_demolength).w
		tst.b	($FFFFFFE2).w
		beq.s	loc_5158
		btst	#6,(v_jpadhold1).w
		beq.s	loc_5158
		move.b	#1,($FFFFFFFA).w

loc_5158:				; CODE XREF: ROM:00005148j
					; ROM:00005150j
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0	
		move.w	d0,(vdp_control_port).l
		bsr.w	Pal_MakeWhite

loc_516A:				; CODE XREF: ROM:000051ACj
		bsr.w	Pause
		move.b	#$A,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	MoveSonicInDemo
		move.w	(v_jpadhold1).w,(v_jpadhold2).w
		jsr	(ObjectsLoad).l
		jsr	(BuildSprites).l
		jsr	(S1SS_ShowLayout).l	; leftover from	Sonic 1
		bsr.w	S1SS_BgAnimate
		tst.w	($FFFFFFF0).w
		beq.s	loc_51A6
		tst.w	(v_demolength).w
		beq.w	loc_52D4

loc_51A6:				; CODE XREF: ROM:0000519Cj
		cmpi.b	#$10,(v_gamemode).w
		beq.w	loc_516A
		tst.w	($FFFFFFF0).w
		bne.w	loc_52DC
		move.b	#$C,(v_gamemode).w
		cmpi.w	#$503,(v_zone).w
		bcs.s	loc_51CA
		clr.w	(v_zone).w

loc_51CA:				; CODE XREF: ROM:000051C4j
		move.w	#$3C,(v_demolength).w 
		move.w	#$3F,($FFFFF626).w 
		clr.w	($FFFFF794).w

loc_51DA:				; CODE XREF: ROM:00005218j
		move.b	#$16,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	MoveSonicInDemo
		move.w	(v_jpadhold1).w,(v_jpadhold2).w
		jsr	(ObjectsLoad).l
		jsr	(BuildSprites).l
		jsr	(S1SS_ShowLayout).l	; leftover from	Sonic 1
		bsr.w	S1SS_BgAnimate
		subq.w	#1,($FFFFF794).w
		bpl.s	loc_5214
		move.w	#2,($FFFFF794).w
		bsr.w	Pal_ToWhite

loc_5214:				; CODE XREF: ROM:00005208j
		tst.w	(v_demolength).w
		bne.s	loc_51DA
		move	#$2700,sr
		lea	(vdp_control_port).l,a6
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$9001,(a6)
		bsr.w	ClearScreen
		move.l	#$70000002,(vdp_control_port).l
		lea	(Nem_S1TitleCard).l,a0
		bsr.w	NemDec
		jsr	(HUD_Base).l
		move	#$2300,sr
		moveq	#$11,d0
		bsr.w	PalLoad2
		moveq	#plcid_Main,d0
		bsr.w	LoadPLC2
		moveq	#plcid_SSResult,d0
		bsr.w	LoadPLC
		move.b	#1,($FFFFFE1F).w
		move.b	#1,($FFFFF7D6).w
		move.w	($FFFFFE20).w,d0
		mulu.w	#$A,d0
		move.w	d0,($FFFFF7D4).w
		move.w	#bgm_GotThrough,d0	
		jsr	(PlaySound_Special).l
		lea	(v_objspace).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

loc_5290:				; CODE XREF: ROM:00005292j
		move.l	d0,(a1)+
		dbf	d1,loc_5290
		move.b	#$7E,(v_objspace+$5C0).w ; "~"

loc_529C:				; CODE XREF: ROM:000052BEj
					; ROM:000052C4j
		bsr.w	Pause
		move.b	#$C,($FFFFF62A).w
		bsr.w	DelayProgram
		jsr	(ObjectsLoad).l
		jsr	(BuildSprites).l
		bsr.w	RunPLC
		tst.w	($FFFFFE02).w
		beq.s	loc_529C
		tst.l	($FFFFF680).w
		bne.s	loc_529C
		move.w	#sfx_EnterSS,d0	; "?"
		bsr.w	PlaySound_Special
		bsr.w	Pal_MakeFlash
		rts
; ---------------------------------------------------------------------------

loc_52D4:				; CODE XREF: ROM:000051A2j
					; ROM:000052E2j
		move.b	#0,(v_gamemode).w
		rts
; ---------------------------------------------------------------------------

loc_52DC:				; CODE XREF: ROM:000051B4j
		cmpi.b	#$C,(v_gamemode).w
		beq.s	loc_52D4
		rts

; =============== S U B	R O U T	I N E =======================================


S1_SSBGLoad:				; CODE XREF: ROM:00005088p
		lea	($FFFF0000).l,a1
		move.w	#$4051,d0
		bsr.w	EniDec
		move.l	#$50000001,d3
		lea	($FFFF0080).l,a2
		moveq	#6,d7

loc_5302:				; CODE XREF: S1_SSBGLoad+7Ej
		move.l	d3,d0
		moveq	#3,d6
		moveq	#0,d4
		cmpi.w	#3,d7
		bcc.s	loc_5310
		moveq	#1,d4

loc_5310:				; CODE XREF: S1_SSBGLoad+26j
					; S1_SSBGLoad+64j
		moveq	#7,d5

loc_5312:				; CODE XREF: S1_SSBGLoad+56j
		movea.l	a2,a1
		eori.b	#1,d4
		bne.s	loc_5326
		cmpi.w	#6,d7
		bne.s	loc_5336
		lea	($FFFF0000).l,a1

loc_5326:				; CODE XREF: S1_SSBGLoad+32j
		movem.l	d0-d4,-(sp)
		moveq	#7,d1
		moveq	#7,d2
		bsr.w	ShowVDPGraphics
		movem.l	(sp)+,d0-d4

loc_5336:				; CODE XREF: S1_SSBGLoad+38j
		addi.l	#$100000,d0
		dbf	d5,loc_5312
		addi.l	#$3800000,d0
		eori.b	#1,d4
		dbf	d6,loc_5310
		addi.l	#$10000000,d3
		bpl.s	loc_5360
		swap	d3
		addi.l	#$C000,d3
		swap	d3

loc_5360:				; CODE XREF: S1_SSBGLoad+6Ej
		adda.w	#$80,a2	
		dbf	d7,loc_5302
		lea	($FFFF0000).l,a1
		move.w	#$4000,d0
		bsr.w	EniDec
		lea	($FFFF0000).l,a1
		move.l	#$40000003,d0
		moveq	#$3F,d1
		moveq	#$1F,d2
		bsr.w	ShowVDPGraphics
		lea	($FFFF0000).l,a1
		move.l	#$50000003,d0
		moveq	#$3F,d1	
		moveq	#$3F,d2	
		bsr.w	ShowVDPGraphics
		rts
; End of function S1_SSBGLoad


; =============== S U B	R O U T	I N E =======================================


PalCycle_S1SS:				; CODE XREF: ROM:00000E90p
					; ROM:000050FCp
		tst.w	($FFFFF63A).w
		bne.s	locret_5424
		subq.w	#1,($FFFFF79C).w
		bpl.s	locret_5424
		lea	(vdp_control_port).l,a6
		move.w	($FFFFF79A).w,d0
		addq.w	#1,($FFFFF79A).w
		andi.w	#$1F,d0
		lsl.w	#2,d0
		lea	(word_547A).l,a0
		adda.w	d0,a0
		move.b	(a0)+,d0
		bpl.s	loc_53D0
		move.w	#$1FF,d0

loc_53D0:				; CODE XREF: PalCycle_S1SS+2Aj
		move.w	d0,($FFFFF79C).w
		moveq	#0,d0
		move.b	(a0)+,d0
		move.w	d0,($FFFFF7A0).w
		lea	(word_54FA).l,a1
		lea	(a1,d0.w),a1
		move.w	#$8200,d0
		move.b	(a1)+,d0
		move.w	d0,(a6)
		move.b	(a1),(v_scrposy_dup).w
		move.w	#$8400,d0
		move.b	(a0)+,d0
		move.w	d0,(a6)
		move.l	#$40000010,(vdp_control_port).l
		move.l	(v_scrposy_dup).w,(vdp_data_port).l
		moveq	#0,d0
		move.b	(a0)+,d0
		bmi.s	loc_5426
		lea	(Pal_S1SSCyc1).l,a1
		adda.w	d0,a1
		lea	($FFFFFB4E).w,a2
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+

locret_5424:				; CODE XREF: PalCycle_S1SS+4j
					; PalCycle_S1SS+Aj
		rts
; ---------------------------------------------------------------------------

loc_5426:				; CODE XREF: PalCycle_S1SS+70j
		move.w	($FFFFF79E).w,d1
		cmpi.w	#$8A,d0	; "?"
		bcs.s	loc_5432
		addq.w	#1,d1

loc_5432:				; CODE XREF: PalCycle_S1SS+8Ej
		mulu.w	#$2A,d1	
		lea	(Pal_S1SSCyc2).l,a1
		adda.w	d1,a1
		andi.w	#$7F,d0	
		bclr	#0,d0
		beq.s	loc_5456
		lea	($FFFFFB6E).w,a2
		move.l	(a1),(a2)+
		move.l	4(a1),(a2)+
		move.l	8(a1),(a2)+

loc_5456:				; CODE XREF: PalCycle_S1SS+A6j
		adda.w	#$C,a1
		lea	($FFFFFB5A).w,a2
		cmpi.w	#$A,d0
		bcs.s	loc_546C
		subi.w	#$A,d0
		lea	($FFFFFB7A).w,a2

loc_546C:				; CODE XREF: PalCycle_S1SS+C2j
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		adda.w	d0,a1
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+
		rts
; End of function PalCycle_S1SS

; ---------------------------------------------------------------------------
word_547A:	dc.w  $300, $792, $300,	$790, $300, $78E, $300,	$78C, $300, $78B, $300,	$780, $300, $782, $300,	$784; 0
					; DATA XREF: PalCycle_S1SS+20o
		dc.w  $300, $786, $300,	$788, $708, $700, $70A,	$70C,$FF0C, $718,$FF0C,	$718, $70A, $70C, $708,	$700; 16
		dc.w  $300, $688, $300,	$686, $300, $684, $300,	$682, $300, $681, $300,	$68A, $300, $68C, $300,	$68E; 32
		dc.w  $300, $690, $300,	$692, $702, $624, $704,	$630,$FF06, $63C,$FF06,	$63C, $704, $630, $702,	$624; 48
word_54FA:	dc.w $1001,$1800,$1801,$2000,$2001,$2800,$2801;	0
					; DATA XREF: PalCycle_S1SS+3Co
Pal_S1SSCyc1:	dc.w  $400, $600, $620,	$624, $664, $666, $600,	$820, $A64, $A68, $AA6,	$AAA, $800, $C42, $E86,	$ECA; 0
					; DATA XREF: PalCycle_S1SS+72o
		dc.w  $EEC, $EEE, $400,	$420, $620, $620, $864,	$666, $420, $620, $842,	$842, $A86, $AAA, $620,	$842; 16
		dc.w  $A64, $C86, $EA8,	$EEE; 32
Pal_S1SSCyc2:	dc.w  $EEA, $EE0, $AA0,	$880, $660, $440, $EE0,	$AA0, $440, $AA0, $AA0,	$AA0, $860, $860, $860,	$640; 0
					; DATA XREF: PalCycle_S1SS+96o
		dc.w  $640, $640, $400,	$400, $400, $AEC, $6EA,	$4C6, $2A4,  $82,  $60,	$6EA, $4C6,  $60, $4C6,	$4C6; 16
		dc.w  $4C6, $484, $484,	$484, $442, $442, $442,	$400, $400, $400, $ECC,	$E8A, $C68, $A46, $824,	$602; 32
		dc.w  $E8A, $C68, $602,	$C68, $C68, $C68, $846,	$846, $846, $624, $624,	$624, $400, $400, $400,	$AEC; 48
		dc.w  $8CA, $6A8, $486,	$264,  $42, $8CA, $6A8,	 $42, $6A8, $6A8, $6A8,	$684, $684, $684, $442,	$442; 64
		dc.w  $442, $400, $400,	$400, $EEC, $CCA, $AA8,	$886, $664, $442, $CCA,	$AA8, $442, $AA8, $AA8,	$AA8; 80
		dc.w  $864, $864, $864,	$642, $642, $642, $400,	$400, $400; 96

; =============== S U B	R O U T	I N E =======================================


S1SS_BgAnimate:				; CODE XREF: ROM:00005194p
					; ROM:00005200p
		move.w	($FFFFF7A0).w,d0
		bne.s	loc_5634
		move.w	#0,(v_bgscreenposy).w
		move.w	(v_bgscreenposy).w,(v_bgscrposy_dup).w

loc_5634:				; CODE XREF: S1SS_BgAnimate+4j
		cmpi.w	#8,d0
		bcc.s	loc_568C
		cmpi.w	#6,d0
		bne.s	loc_564E
		addq.w	#1,(v_bg3screenposx).w
		addq.w	#1,(v_bgscreenposy).w
		move.w	(v_bgscreenposy).w,(v_bgscrposy_dup).w

loc_564E:				; CODE XREF: S1SS_BgAnimate+1Cj
		moveq	#0,d0
		move.w	(v_bgscreenposx).w,d0
		neg.w	d0
		swap	d0
		lea	(byte_5709).l,a1
		lea	(v_ngfx_buffer).w,a3
		moveq	#9,d3

loc_5664:				; CODE XREF: S1SS_BgAnimate+5Aj
		move.w	2(a3),d0
		bsr.w	CalcSine
		moveq	#0,d2
		move.b	(a1)+,d2
		muls.w	d2,d0
		asr.l	#8,d0
		move.w	d0,(a3)+
		move.b	(a1)+,d2
		ext.w	d2
		add.w	d2,(a3)+
		dbf	d3,loc_5664
		lea	(v_ngfx_buffer).w,a3
		lea	(byte_56F6).l,a2
		bra.s	loc_56BC
; ---------------------------------------------------------------------------

loc_568C:				; CODE XREF: S1SS_BgAnimate+16j
		cmpi.w	#$C,d0
		bne.s	loc_56B2
		subq.w	#1,(v_bg3screenposx).w
		lea	($FFFFAB00).w,a3
		move.l	#$18000,d2
		moveq	#6,d1

loc_56A2:				; CODE XREF: S1SS_BgAnimate+8Cj
		move.l	(a3),d0
		sub.l	d2,d0
		move.l	d0,(a3)+
		subi.l	#$2000,d2
		dbf	d1,loc_56A2

loc_56B2:				; CODE XREF: S1SS_BgAnimate+6Ej
		lea	($FFFFAB00).w,a3
		lea	(byte_5701).l,a2

loc_56BC:				; CODE XREF: S1SS_BgAnimate+68j
		lea	(v_hscrolltablebuffer).w,a1
		move.w	(v_bg3screenposx).w,d0
		neg.w	d0
		swap	d0
		moveq	#0,d3
		move.b	(a2)+,d3
		move.w	(v_bgscreenposy).w,d2
		neg.w	d2
		andi.w	#$FF,d2
		lsl.w	#2,d2

loc_56D8:				; CODE XREF: S1SS_BgAnimate+CEj
		move.w	(a3)+,d0
		addq.w	#2,a3
		moveq	#0,d1
		move.b	(a2)+,d1
		subq.w	#1,d1

loc_56E2:				; CODE XREF: S1SS_BgAnimate+CAj
		move.l	d0,(a1,d2.w)
		addq.w	#4,d2
		andi.w	#$3FC,d2
		dbf	d1,loc_56E2
		dbf	d3,loc_56D8
		rts
; End of function S1SS_BgAnimate

; ---------------------------------------------------------------------------
byte_56F6:	dc.b   9,$28,$18,$10,$28,$18,$10,$30,$18,  8,$10; 0
					; DATA XREF: S1SS_BgAnimate+62o
byte_5701:	dc.b   6,$30,$30,$30,$28,$18,$18,$18; 0	; DATA XREF: S1SS_BgAnimate+94o
byte_5709:	dc.b   8,  2,  4,$FF,  2,  3,  8,$FF,  4,  2,  2,  3,  8,$FD,  4,  2; 0
					; DATA XREF: S1SS_BgAnimate+36o
		dc.b   2,  3,  2,$FF,  0; 16
; ---------------------------------------------------------------------------
		nop

                include "_inc\LevelSizeLoad & BgScrollSpeed.asm"
                include "_inc\DeformLayers.asm"

		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		lea	($FFFFEE52).w,a2
		lea	(v_bgscreenposx).w,a3
		lea	(v_lvllayout+$80).w,a4
		move.w	#$6000,d2
		bsr.w	sub_69B2
		lea	($FFFFEE54).w,a2
		lea	(v_bg2screenposx).w,a3
		bra.w	sub_6A82

; =============== S U B	R O U T	I N E =======================================


LoadTilesAsYouMove:			; CODE XREF: DemoTimep	ROM:00000F78p
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		lea	($FFFFEEA2).w,a2
		lea	($FFFFEE68).w,a3
		lea	(v_lvllayout+$80).w,a4
		move.w	#$6000,d2
		bsr.w	sub_69B2
		lea	($FFFFEEA4).w,a2
		lea	($FFFFEE70).w,a3
		bsr.w	sub_6A82
		lea	($FFFFEEA6).w,a2
		lea	($FFFFEE78).w,a3
		bsr.w	sub_6B7C
		tst.w	(f_2player).w
		beq.s	loc_689E
		lea	($FFFFEEA8).w,a2
		lea	($FFFFEE80).w,a3
		lea	(v_lvllayout).w,a4
		move.w	#$6000,d2
		bsr.w	sub_694C

loc_689E:				; CODE XREF: LoadTilesAsYouMove+3Cj
		lea	($FFFFEEA0).w,a2
		lea	($FFFFEE60).w,a3
		lea	(v_lvllayout).w,a4
		move.w	#$4000,d2
		tst.b	($FFFFF720).w
		beq.s	loc_68E6
		move.b	#0,($FFFFF720).w
		moveq	#$FFFFFFF0,d4
		moveq	#$F,d6

loc_68BE:				; CODE XREF: LoadTilesAsYouMove+8Ej
		movem.l	d4-d6,-(sp)
		moveq	#$FFFFFFF0,d5
		move.w	d4,d1
		bsr.w	sub_7084
		move.w	d1,d4
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_6D8C
		movem.l	(sp)+,d4-d6
		addi.w	#$10,d4
		dbf	d6,loc_68BE
		move.b	#0,($FFFFEEA0).w
		rts
; ---------------------------------------------------------------------------

loc_68E6:				; CODE XREF: LoadTilesAsYouMove+66j
		tst.b	(a2)
		beq.s	locret_694A
		bclr	#0,(a2)
		beq.s	loc_6900
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_7084
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_6D8C

loc_6900:				; CODE XREF: LoadTilesAsYouMove+A2j
		bclr	#1,(a2)
		beq.s	loc_691A
		move.w	#$E0,d4	
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_7084
		move.w	#$E0,d4	
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_6D8C

loc_691A:				; CODE XREF: LoadTilesAsYouMove+B8j
		bclr	#2,(a2)
		beq.s	loc_6930
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_7084
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_6CFE

loc_6930:				; CODE XREF: LoadTilesAsYouMove+D2j
		bclr	#3,(a2)
		beq.s	locret_694A
		moveq	#$FFFFFFF0,d4
		move.w	#$140,d5
		bsr.w	sub_7084
		moveq	#$FFFFFFF0,d4
		move.w	#$140,d5
		bsr.w	sub_6CFE

locret_694A:				; CODE XREF: LoadTilesAsYouMove+9Cj
					; LoadTilesAsYouMove+E8j
		rts
; End of function LoadTilesAsYouMove


; =============== S U B	R O U T	I N E =======================================


sub_694C:				; CODE XREF: LoadTilesAsYouMove+4Ep
		tst.b	(a2)
		beq.s	locret_69B0
		bclr	#0,(a2)
		beq.s	loc_6966
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_70C0
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_6D8C

loc_6966:				; CODE XREF: sub_694C+8j
		bclr	#1,(a2)
		beq.s	loc_6980
		move.w	#$E0,d4	
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_70C0
		move.w	#$E0,d4	
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_6D8C

loc_6980:				; CODE XREF: sub_694C+1Ej
		bclr	#2,(a2)
		beq.s	loc_6996
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_70C0
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_6CFE

loc_6996:				; CODE XREF: sub_694C+38j
		bclr	#3,(a2)
		beq.s	locret_69B0
		moveq	#$FFFFFFF0,d4
		move.w	#$140,d5
		bsr.w	sub_70C0
		moveq	#$FFFFFFF0,d4
		move.w	#$140,d5
		bsr.w	sub_6CFE

locret_69B0:				; CODE XREF: sub_694C+2j sub_694C+4Ej
		rts
; End of function sub_694C


; =============== S U B	R O U T	I N E =======================================


sub_69B2:				; CODE XREF: ROM:0000683Cp
					; LoadTilesAsYouMove+1Cp
		tst.b	(a2)
		beq.w	locret_6A80
		bclr	#0,(a2)
		beq.s	loc_69CE
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_7084
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_6D8C

loc_69CE:				; CODE XREF: sub_69B2+Aj
		bclr	#1,(a2)
		beq.s	loc_69E8
		move.w	#$E0,d4	
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_7084
		move.w	#$E0,d4	
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_6D8C

loc_69E8:				; CODE XREF: sub_69B2+20j
		bclr	#2,(a2)
		beq.s	loc_69FE
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_7084
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_6CFE

loc_69FE:				; CODE XREF: sub_69B2+3Aj
		bclr	#3,(a2)
		beq.s	loc_6A18
		moveq	#$FFFFFFF0,d4
		move.w	#$140,d5
		bsr.w	sub_7084
		moveq	#$FFFFFFF0,d4
		move.w	#$140,d5
		bsr.w	sub_6CFE

loc_6A18:				; CODE XREF: sub_69B2+50j
		bclr	#4,(a2)
		beq.s	loc_6A30
		moveq	#$FFFFFFF0,d4
		moveq	#0,d5
		bsr.w	sub_7086
		moveq	#$FFFFFFF0,d4
		moveq	#0,d5
		moveq	#$1F,d6
		bsr.w	sub_6D90

loc_6A30:				; CODE XREF: sub_69B2+6Aj
		bclr	#5,(a2)
		beq.s	loc_6A4C
		move.w	#$E0,d4	
		moveq	#0,d5
		bsr.w	sub_7086
		move.w	#$E0,d4	
		moveq	#0,d5
		moveq	#$1F,d6
		bsr.w	sub_6D90

loc_6A4C:				; CODE XREF: sub_69B2+82j
		bclr	#6,(a2)
		beq.s	loc_6A64
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_7084
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		moveq	#$1F,d6
		bsr.w	sub_6D84

loc_6A64:				; CODE XREF: sub_69B2+9Ej
		bclr	#7,(a2)
		beq.s	locret_6A80
		move.w	#$E0,d4	
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_7084
		move.w	#$E0,d4	
		moveq	#$FFFFFFF0,d5
		moveq	#$1F,d6
		bsr.w	sub_6D84

locret_6A80:				; CODE XREF: sub_69B2+2j sub_69B2+B6j
		rts
; End of function sub_69B2


; =============== S U B	R O U T	I N E =======================================


sub_6A82:				; CODE XREF: ROM:00006848j
					; LoadTilesAsYouMove+28p
		tst.b	(a2)
		beq.w	locret_6ACE
		cmpi.b	#5,(v_zone).w
		beq.w	loc_6AF2
		bclr	#0,(a2)
		beq.s	loc_6AAE
		move.w	#$70,d4	
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_7084
		move.w	#$70,d4	
		moveq	#$FFFFFFF0,d5
		moveq	#2,d6
		bsr.w	sub_6D00

loc_6AAE:				; CODE XREF: sub_6A82+14j
		bclr	#1,(a2)
		beq.s	locret_6ACE
		move.w	#$70,d4	
		move.w	#$140,d5
		bsr.w	sub_7084
		move.w	#$70,d4	
		move.w	#$140,d5
		moveq	#2,d6
		bsr.w	sub_6D00

locret_6ACE:				; CODE XREF: sub_6A82+2j sub_6A82+30j
		rts
; ---------------------------------------------------------------------------
byte_6AD0:	dc.b 0			; DATA XREF: sub_6A82:loc_6B66t
byte_6AD1:	dc.b   0,  0,  0,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  4,  4; 0
					; DATA XREF: sub_6A82:loc_6B04t
					; ROM:0000720At
		dc.b   4,  4,  4,  4,  4,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2; 16
		dc.b 0
; ---------------------------------------------------------------------------

loc_6AF2:				; CODE XREF: sub_6A82+Cj
		moveq	#$FFFFFFF0,d4
		bclr	#0,(a2)
		bne.s	loc_6B04
		bclr	#1,(a2)
		beq.s	loc_6B4C
		move.w	#$E0,d4	

loc_6B04:				; CODE XREF: sub_6A82+76j
		lea	byte_6AD1(pc),a0
		move.w	(v_bgscreenposy).w,d0
		add.w	d4,d0
		andi.w	#$1F0,d0
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		lea	(word_6C78).l,a3
		movea.w	(a3,d0.w),a3
		beq.s	loc_6B38
		moveq	#$FFFFFFF0,d5
		movem.l	d4-d5,-(sp)
		bsr.w	sub_7084
		movem.l	(sp)+,d4-d5
		bsr.w	sub_6D8C
		bra.s	loc_6B4C
; ---------------------------------------------------------------------------

loc_6B38:				; CODE XREF: sub_6A82+A0j
		moveq	#0,d5
		movem.l	d4-d5,-(sp)
		bsr.w	sub_7086
		movem.l	(sp)+,d4-d5
		moveq	#$1F,d6
		bsr.w	sub_6D90

loc_6B4C:				; CODE XREF: sub_6A82+7Cj sub_6A82+B4j
		tst.b	(a2)
		bne.s	loc_6B52
		rts
; ---------------------------------------------------------------------------

loc_6B52:				; CODE XREF: sub_6A82+CCj
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		move.b	(a2),d0
		andi.b	#$A8,d0
		beq.s	loc_6B66
		lsr.b	#1,d0
		move.b	d0,(a2)
		move.w	#$140,d5

loc_6B66:				; CODE XREF: sub_6A82+DAj
		lea	byte_6AD0(pc),a0
		move.w	(v_bgscreenposy).w,d0
		andi.w	#$1F0,d0
		lsr.w	#4,d0
		lea	(a0,d0.w),a0
		bra.w	loc_6C80
; End of function sub_6A82


; =============== S U B	R O U T	I N E =======================================


sub_6B7C:				; CODE XREF: LoadTilesAsYouMove+34p
		tst.b	(a2)
		beq.w	locret_6BC8
		cmpi.b	#2,(v_zone).w
		beq.w	loc_6C0C
		bclr	#0,(a2)
		beq.s	loc_6BA8
		move.w	#$40,d4	
		moveq	#$FFFFFFF0,d5
		bsr.w	sub_7084
		move.w	#$40,d4	
		moveq	#$FFFFFFF0,d5
		moveq	#2,d6
		bsr.w	sub_6D00

loc_6BA8:				; CODE XREF: sub_6B7C+14j
		bclr	#1,(a2)
		beq.s	locret_6BC8
		move.w	#$40,d4	
		move.w	#$140,d5
		bsr.w	sub_7084
		move.w	#$40,d4	
		move.w	#$140,d5
		moveq	#2,d6
		bsr.w	sub_6D00

locret_6BC8:				; CODE XREF: sub_6B7C+2j sub_6B7C+30j
		rts
; ---------------------------------------------------------------------------
byte_6BCA:	dc.b 0			; DATA XREF: sub_6B7C:loc_6C62t
byte_6BCB:	dc.b   2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2; 0
					; DATA XREF: sub_6B7C:loc_6C1Et
					; ROM:000071E2t
		dc.b   2,  2,  2,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4; 16
		dc.b   4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4; 32
		dc.b   4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4; 48
		dc.b 0
; ---------------------------------------------------------------------------

loc_6C0C:				; CODE XREF: sub_6B7C+Cj
		moveq	#$FFFFFFF0,d4
		bclr	#0,(a2)
		bne.s	loc_6C1E
		bclr	#1,(a2)
		beq.s	loc_6C48
		move.w	#$E0,d4	

loc_6C1E:				; CODE XREF: sub_6B7C+96j
		lea	byte_6BCB(pc),a0
		move.w	(v_bgscreenposy).w,d0
		add.w	d4,d0
		andi.w	#$3F0,d0
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		movea.w	word_6C78(pc,d0.w),a3
		moveq	#$FFFFFFF0,d5
		movem.l	d4-d5,-(sp)
		bsr.w	sub_7084
		movem.l	(sp)+,d4-d5
		bsr.w	sub_6D8C

loc_6C48:				; CODE XREF: sub_6B7C+9Cj
		tst.b	(a2)
		bne.s	loc_6C4E
		rts
; ---------------------------------------------------------------------------

loc_6C4E:				; CODE XREF: sub_6B7C+CEj
		moveq	#$FFFFFFF0,d4
		moveq	#$FFFFFFF0,d5
		move.b	(a2),d0
		andi.b	#$A8,d0
		beq.s	loc_6C62
		lsr.b	#1,d0
		move.b	d0,(a2)
		move.w	#$140,d5

loc_6C62:				; CODE XREF: sub_6B7C+DCj
		lea	byte_6BCA(pc),a0
		move.w	(v_bgscreenposy).w,d0
		andi.w	#$7F0,d0
		lsr.w	#4,d0
		lea	(a0,d0.w),a0
		bra.w	loc_6C80
; ---------------------------------------------------------------------------
word_6C78:	dc.w $EE68,$EE68,$EE70,$EE78; 0	; DATA XREF: sub_6A82+96o
; ---------------------------------------------------------------------------

loc_6C80:				; CODE XREF: sub_6A82+F6j sub_6B7C+F8j
		tst.w	(f_2player).w
		bne.s	loc_6CC2
		moveq	#$F,d6
		move.l	#$800000,d7

loc_6C8E:				; CODE XREF: sub_6B7C+13Ej
		moveq	#0,d0
		move.b	(a0)+,d0
		btst	d0,(a2)
		beq.s	loc_6CB6
		movea.w	word_6C78(pc,d0.w),a3
		movem.l	d4-d5/a0,-(sp)
		movem.l	d4-d5,-(sp)
		bsr.w	sub_7040
		movem.l	(sp)+,d4-d5
		bsr.w	sub_7084
		bsr.w	sub_6F70
		movem.l	(sp)+,d4-d5/a0

loc_6CB6:				; CODE XREF: sub_6B7C+118j
		addi.w	#$10,d4
		dbf	d6,loc_6C8E
		clr.b	(a2)
		rts
; ---------------------------------------------------------------------------

loc_6CC2:				; CODE XREF: sub_6B7C+108j
		moveq	#$F,d6
		move.l	#$800000,d7

loc_6CCA:				; CODE XREF: sub_6B7C+17Aj
		moveq	#0,d0
		move.b	(a0)+,d0
		btst	d0,(a2)
		beq.s	loc_6CF2
		movea.w	word_6C78(pc,d0.w),a3
		movem.l	d4-d5/a0,-(sp)
		movem.l	d4-d5,-(sp)
		bsr.w	sub_7040
		movem.l	(sp)+,d4-d5
		bsr.w	sub_7084
		bsr.w	sub_6FF6
		movem.l	(sp)+,d4-d5/a0

loc_6CF2:				; CODE XREF: sub_6B7C+154j
		addi.w	#$10,d4
		dbf	d6,loc_6CCA
		clr.b	(a2)
		rts
; End of function sub_6B7C


; =============== S U B	R O U T	I N E =======================================


sub_6CFE:				; CODE XREF: LoadTilesAsYouMove+E0p
					; LoadTilesAsYouMove+FAp ...
		moveq	#$F,d6
; End of function sub_6CFE


; =============== S U B	R O U T	I N E =======================================


sub_6D00:				; CODE XREF: sub_6A82+28p sub_6A82+48p ...
		add.w	(a3),d5
		add.w	4(a3),d4
		move.l	#$800000,d7
		move.l	d0,d1
		bsr.w	sub_6E98
		tst.w	(f_2player).w
		bne.s	loc_6D4E

loc_6D18:				; CODE XREF: sub_6D00:loc_6D48j
		move.w	(a0),d3
		andi.w	#$3FF,d3
		lsl.w	#3,d3
		lea	(v_16x16).w,a1
		adda.w	d3,a1
		move.l	d1,d0
		bsr.w	sub_6F70
		adda.w	#$10,a0
		addi.w	#$100,d1
		andi.w	#$FFF,d1
		addi.w	#$10,d4
		move.w	d4,d0
		andi.w	#$70,d0	
		bne.s	loc_6D48
		bsr.w	sub_6E98

loc_6D48:				; CODE XREF: sub_6D00+42j
		dbf	d6,loc_6D18
		rts
; ---------------------------------------------------------------------------

loc_6D4E:				; CODE XREF: sub_6D00+16j
					; sub_6D00:loc_6D7Ej
		move.w	(a0),d3
		andi.w	#$3FF,d3
		lsl.w	#3,d3
		lea	(v_16x16).w,a1
		adda.w	d3,a1
		move.l	d1,d0
		bsr.w	sub_6FF6
		adda.w	#$10,a0
		addi.w	#$80,d1	
		andi.w	#$FFF,d1
		addi.w	#$10,d4
		move.w	d4,d0
		andi.w	#$70,d0	
		bne.s	loc_6D7E
		bsr.w	sub_6E98

loc_6D7E:				; CODE XREF: sub_6D00+78j
		dbf	d6,loc_6D4E
		rts
; End of function sub_6D00


; =============== S U B	R O U T	I N E =======================================


sub_6D84:				; CODE XREF: sub_69B2+AEp sub_69B2+CAp ...
		add.w	(a3),d5
		add.w	4(a3),d4
		bra.s	loc_6D94
; End of function sub_6D84


; =============== S U B	R O U T	I N E =======================================


sub_6D8C:				; CODE XREF: LoadTilesAsYouMove+82p
					; LoadTilesAsYouMove+B0p ...
		moveq	#$15,d6
		add.w	(a3),d5
; End of function sub_6D8C


; =============== S U B	R O U T	I N E =======================================


sub_6D90:				; CODE XREF: sub_69B2+7Ap sub_69B2+96p ...
		add.w	4(a3),d4

loc_6D94:				; CODE XREF: sub_6D84+6j
		tst.w	(f_2player).w
		bne.s	loc_6E12
		move.l	a2,-(sp)
		move.w	d6,-(sp)
		lea	($FFFFEF00).w,a2
		move.l	d0,d1
		or.w	d2,d1
		swap	d1
		move.l	d1,-(sp)
		move.l	d1,(a5)
		swap	d1
		bsr.w	sub_6E98

loc_6DB2:				; CODE XREF: sub_6D90:loc_6DE4j
		move.w	(a0),d3
		andi.w	#$3FF,d3
		lsl.w	#3,d3
		lea	(v_16x16).w,a1
		adda.w	d3,a1
		bsr.w	sub_6ED0
		addq.w	#2,a0
		addq.b	#4,d1
		bpl.s	loc_6DD4
		andi.b	#$7F,d1	
		swap	d1
		move.l	d1,(a5)
		swap	d1

loc_6DD4:				; CODE XREF: sub_6D90+38j
		addi.w	#$10,d5
		move.w	d5,d0
		andi.w	#$70,d0	
		bne.s	loc_6DE4
		bsr.w	sub_6E98

loc_6DE4:				; CODE XREF: sub_6D90+4Ej
		dbf	d6,loc_6DB2
		move.l	(sp)+,d1
		addi.l	#$800000,d1
		lea	($FFFFEF00).w,a2
		move.l	d1,(a5)
		swap	d1
		move.w	(sp)+,d6

loc_6DFA:				; CODE XREF: sub_6D90:loc_6E0Aj
		move.l	(a2)+,(a6)
		addq.b	#4,d1
		bmi.s	loc_6E0A
		ori.b	#$80,d1
		swap	d1
		move.l	d1,(a5)
		swap	d1

loc_6E0A:				; CODE XREF: sub_6D90+6Ej
		dbf	d6,loc_6DFA
		movea.l	(sp)+,a2
		rts
; ---------------------------------------------------------------------------

loc_6E12:				; CODE XREF: sub_6D90+8j
		move.l	d0,d1
		or.w	d2,d1
		swap	d1
		move.l	d1,(a5)
		swap	d1
		tst.b	d1
		bmi.s	loc_6E5C
		bsr.w	sub_6E98

loc_6E24:				; CODE XREF: sub_6D90:loc_6E56j
		move.w	(a0),d3
		andi.w	#$3FF,d3
		lsl.w	#3,d3
		lea	(v_16x16).w,a1
		adda.w	d3,a1
		bsr.w	sub_6F32
		addq.w	#2,a0
		addq.b	#4,d1
		bpl.s	loc_6E46
		andi.b	#$7F,d1	
		swap	d1
		move.l	d1,(a5)
		swap	d1

loc_6E46:				; CODE XREF: sub_6D90+AAj
		addi.w	#$10,d5
		move.w	d5,d0
		andi.w	#$70,d0	
		bne.s	loc_6E56
		bsr.w	sub_6E98

loc_6E56:				; CODE XREF: sub_6D90+C0j
		dbf	d6,loc_6E24
		rts
; ---------------------------------------------------------------------------

loc_6E5C:				; CODE XREF: sub_6D90+8Ej
		bsr.w	sub_6E98

loc_6E60:				; CODE XREF: sub_6D90:loc_6E92j
		move.w	(a0),d3
		andi.w	#$3FF,d3
		lsl.w	#3,d3
		lea	(v_16x16).w,a1
		adda.w	d3,a1
		bsr.w	sub_6F32
		addq.w	#2,a0
		addq.b	#4,d1
		bmi.s	loc_6E82
		ori.b	#$80,d1
		swap	d1
		move.l	d1,(a5)
		swap	d1

loc_6E82:				; CODE XREF: sub_6D90+E6j
		addi.w	#$10,d5
		move.w	d5,d0
		andi.w	#$70,d0	
		bne.s	loc_6E92
		bsr.w	sub_6E98

loc_6E92:				; CODE XREF: sub_6D90+FCj
		dbf	d6,loc_6E60
		rts
; End of function sub_6D90


; =============== S U B	R O U T	I N E =======================================


sub_6E98:				; CODE XREF: sub_6D00+Ep sub_6D00+44p	...
		movem.l	d4-d5,-(sp)
		move.w	d4,d3
		add.w	d3,d3
		andi.w	#$F00,d3
		lsr.w	#3,d5
		move.w	d5,d0
		lsr.w	#4,d0
		andi.w	#$7F,d0	
		add.w	d3,d0
		moveq	#$FFFFFFFF,d3
		move.b	(a4,d0.w),d3
		andi.w	#$FF,d3
		lsl.w	#7,d3
		andi.w	#$70,d4	
		andi.w	#$E,d5
		add.w	d4,d3
		add.w	d5,d3
		movea.l	d3,a0
		movem.l	(sp)+,d4-d5
		rts
; End of function sub_6E98


; =============== S U B	R O U T	I N E =======================================


sub_6ED0:				; CODE XREF: sub_6D90+30p
		btst	#3,(a0)
		bne.s	loc_6EFC
		btst	#2,(a0)
		bne.s	loc_6EE2
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a2)+
		rts
; ---------------------------------------------------------------------------

loc_6EE2:				; CODE XREF: sub_6ED0+Aj
		move.l	(a1)+,d3
		eori.l	#$8000800,d3
		swap	d3
		move.l	d3,(a6)
		move.l	(a1)+,d3
		eori.l	#$8000800,d3
		swap	d3
		move.l	d3,(a2)+
		rts
; ---------------------------------------------------------------------------

loc_6EFC:				; CODE XREF: sub_6ED0+4j
		btst	#2,(a0)
		bne.s	loc_6F18
		move.l	(a1)+,d0
		move.l	(a1)+,d3
		eori.l	#$10001000,d3
		move.l	d3,(a6)
		eori.l	#$10001000,d0
		move.l	d0,(a2)+
		rts
; ---------------------------------------------------------------------------

loc_6F18:				; CODE XREF: sub_6ED0+30j
		move.l	(a1)+,d0
		move.l	(a1)+,d3
		eori.l	#$18001800,d3
		swap	d3
		move.l	d3,(a6)
		eori.l	#$18001800,d0
		swap	d0
		move.l	d0,(a2)+
		rts
; End of function sub_6ED0


; =============== S U B	R O U T	I N E =======================================


sub_6F32:				; CODE XREF: sub_6D90+A2p sub_6D90+DEp
		btst	#3,(a0)
		bne.s	loc_6F50
		btst	#2,(a0)
		bne.s	loc_6F42
		move.l	(a1)+,(a6)
		rts
; ---------------------------------------------------------------------------

loc_6F42:				; CODE XREF: sub_6F32+Aj
		move.l	(a1)+,d3
		eori.l	#$8000800,d3
		swap	d3
		move.l	d3,(a6)
		rts
; ---------------------------------------------------------------------------

loc_6F50:				; CODE XREF: sub_6F32+4j
		btst	#2,(a0)
		bne.s	loc_6F62
		move.l	(a1)+,d3
		eori.l	#$10001000,d3
		move.l	d3,(a6)
		rts
; ---------------------------------------------------------------------------

loc_6F62:				; CODE XREF: sub_6F32+22j
		move.l	(a1)+,d3
		eori.l	#$18001800,d3
		swap	d3
		move.l	d3,(a6)
		rts
; End of function sub_6F32


; =============== S U B	R O U T	I N E =======================================


sub_6F70:				; CODE XREF: sub_6B7C+132p
					; sub_6D00+28p
		or.w	d2,d0
		swap	d0
		btst	#3,(a0)
		bne.s	loc_6FAC
		btst	#2,(a0)
		bne.s	loc_6F8C
		move.l	d0,(a5)
		move.l	(a1)+,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		move.l	(a1)+,(a6)
		rts
; ---------------------------------------------------------------------------

loc_6F8C:				; CODE XREF: sub_6F70+Ej
		move.l	d0,(a5)
		move.l	(a1)+,d3
		eori.l	#$8000800,d3
		swap	d3
		move.l	d3,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		move.l	(a1)+,d3
		eori.l	#$8000800,d3
		swap	d3
		move.l	d3,(a6)
		rts
; ---------------------------------------------------------------------------

loc_6FAC:				; CODE XREF: sub_6F70+8j
		btst	#2,(a0)
		bne.s	loc_6FD2
		move.l	d5,-(sp)
		move.l	d0,(a5)
		move.l	(a1)+,d5
		move.l	(a1)+,d3
		eori.l	#$10001000,d3
		move.l	d3,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		eori.l	#$10001000,d5
		move.l	d5,(a6)
		move.l	(sp)+,d5
		rts
; ---------------------------------------------------------------------------

loc_6FD2:				; CODE XREF: sub_6F70+40j
		move.l	d5,-(sp)
		move.l	d0,(a5)
		move.l	(a1)+,d5
		move.l	(a1)+,d3
		eori.l	#$18001800,d3
		swap	d3
		move.l	d3,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		eori.l	#$18001800,d5
		swap	d5
		move.l	d5,(a6)
		move.l	(sp)+,d5
		rts
; End of function sub_6F70


; =============== S U B	R O U T	I N E =======================================


sub_6FF6:				; CODE XREF: sub_6B7C+16Ep
					; sub_6D00+5Ep
		or.w	d2,d0
		swap	d0
		btst	#3,(a0)
		bne.s	loc_701C
		btst	#2,(a0)
		bne.s	loc_700C
		move.l	d0,(a5)
		move.l	(a1)+,(a6)
		rts
; ---------------------------------------------------------------------------

loc_700C:				; CODE XREF: sub_6FF6+Ej
		move.l	d0,(a5)
		move.l	(a1)+,d3
		eori.l	#$8000800,d3
		swap	d3
		move.l	d3,(a6)
		rts
; ---------------------------------------------------------------------------

loc_701C:				; CODE XREF: sub_6FF6+8j
		btst	#2,(a0)
		bne.s	loc_7030
		move.l	d0,(a5)
		move.l	(a1)+,d3
		eori.l	#$10001000,d3
		move.l	d3,(a6)
		rts
; ---------------------------------------------------------------------------

loc_7030:				; CODE XREF: sub_6FF6+2Aj
		move.l	d0,(a5)
		move.l	(a1)+,d3
		eori.l	#$18001800,d3
		swap	d3
		move.l	d3,(a6)
		rts
; End of function sub_6FF6


; =============== S U B	R O U T	I N E =======================================


sub_7040:				; CODE XREF: sub_6B7C+126p
					; sub_6B7C+162p
		add.w	(a3),d5
		add.w	4(a3),d4
		lea	(v_16x16).w,a1
		move.w	d4,d3
		add.w	d3,d3
		andi.w	#$F00,d3
		lsr.w	#3,d5
		move.w	d5,d0
		lsr.w	#4,d0
		andi.w	#$7F,d0	
		add.w	d3,d0
		moveq	#$FFFFFFFF,d3
		move.b	(a4,d0.w),d3
		andi.w	#$FF,d3
		lsl.w	#7,d3
		andi.w	#$70,d4	
		andi.w	#$E,d5
		add.w	d4,d3
		add.w	d5,d3
		movea.l	d3,a0
		move.w	(a0),d3
		andi.w	#$3FF,d3
		lsl.w	#3,d3
		adda.w	d3,a1
		rts
; End of function sub_7040


; =============== S U B	R O U T	I N E =======================================


sub_7084:				; CODE XREF: LoadTilesAsYouMove+7Ap
					; LoadTilesAsYouMove+A8p ...
		add.w	(a3),d5
; End of function sub_7084


; =============== S U B	R O U T	I N E =======================================


sub_7086:				; CODE XREF: sub_69B2+70p sub_69B2+8Ap ...
		tst.w	(f_2player).w
		bne.s	loc_70A6
		add.w	4(a3),d4
		andi.w	#$F0,d4	; "?"
		andi.w	#$1F0,d5
		lsl.w	#4,d4
		lsr.w	#2,d5
		add.w	d5,d4
		moveq	#3,d0
		swap	d0
		move.w	d4,d0
		rts
; ---------------------------------------------------------------------------

loc_70A6:				; CODE XREF: sub_7086+4j
		add.w	4(a3),d4
		andi.w	#$1F0,d4
		andi.w	#$1F0,d5
		lsl.w	#3,d4
		lsr.w	#2,d5
		add.w	d5,d4
		moveq	#3,d0
		swap	d0
		move.w	d4,d0
		rts
; End of function sub_7086


; =============== S U B	R O U T	I N E =======================================


sub_70C0:				; CODE XREF: sub_694C+Ep sub_694C+26p	...
		tst.w	(f_2player).w
		bne.s	loc_70E2
		add.w	4(a3),d4
		add.w	(a3),d5
		andi.w	#$F0,d4	; "?"
		andi.w	#$1F0,d5
		lsl.w	#4,d4
		lsr.w	#2,d5
		add.w	d5,d4
		moveq	#2,d0
		swap	d0
		move.w	d4,d0
		rts
; ---------------------------------------------------------------------------

loc_70E2:				; CODE XREF: sub_70C0+4j
		add.w	4(a3),d4
		add.w	(a3),d5
		andi.w	#$1F0,d4
		andi.w	#$1F0,d5
		lsl.w	#3,d4
		lsr.w	#2,d5
		add.w	d5,d4
		moveq	#2,d0
		swap	d0
		move.w	d4,d0
		rts
; End of function sub_70C0


; =============== S U B	R O U T	I N E =======================================


LoadTilesFromStart:
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		tst.w	(f_2player).w
		beq.s	loc_711E
		lea	(v_screenposx_2p).w,a3
		lea	(v_lvllayout).w,a4
		move.w	#$6000,d2
		bsr.s	LoadTilesFromStart_2p

loc_711E:				; CODE XREF: LoadTilesFromStart+10j
		lea	(v_screenposx).w,a3
		lea	(v_lvllayout).w,a4
		move.w	#$4000,d2
		bsr.s	LoadTilesFromStart2
		lea	(v_bgscreenposx).w,a3
		lea	(v_lvllayout+$80).w,a4
		move.w	#$6000,d2
		tst.b	(v_zone).w
		beq.w	loc_71A0

LoadTilesFromStart2:			; CODE XREF: LoadTilesFromStart+2Cp
		moveq	#$FFFFFFF0,d4
		moveq	#$F,d6

loc_7144:				; CODE XREF: LoadTilesFromStart2+2Aj
		movem.l	d4-d6,-(sp)
		moveq	#0,d5
		move.w	d4,d1
		bsr.w	sub_7084
		move.w	d1,d4
		moveq	#0,d5
		moveq	#$1F,d6
		move	#$2700,sr
		bsr.w	sub_6D84
		move	#$2300,sr
		movem.l	(sp)+,d4-d6
		addi.w	#$10,d4
		dbf	d6,loc_7144
		rts
; End of function LoadTilesFromStart2


; =============== S U B	R O U T	I N E =======================================


LoadTilesFromStart_2p:			; CODE XREF: LoadTilesFromStart+1Ep
		moveq	#$FFFFFFF0,d4
		moveq	#$F,d6

loc_7174:				; CODE XREF: LoadTilesFromStart_2p+2Aj
		movem.l	d4-d6,-(sp)
		moveq	#0,d5
		move.w	d4,d1
		bsr.w	sub_70C0
		move.w	d1,d4
		moveq	#0,d5
		moveq	#$1F,d6
		move	#$2700,sr
		bsr.w	sub_6D84
		move	#$2300,sr
		movem.l	(sp)+,d4-d6
		addi.w	#$10,d4
		dbf	d6,loc_7174
		rts
; End of function LoadTilesFromStart_2p

; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR LoadTilesFromStart

loc_71A0:				; CODE XREF: LoadTilesFromStart+3Ej
		moveq	#0,d4
		moveq	#$F,d6

loc_71A4:				; CODE XREF: LoadTilesFromStart+C6j
		movem.l	d4-d6,-(sp)
		lea	(byte_71CA).l,a0
		move.w	(v_bgscreenposy).w,d0
		add.w	d4,d0
		andi.w	#$F0,d0	; "?"
		bsr.w	sub_7232
		movem.l	(sp)+,d4-d6
		addi.w	#$10,d4
		dbf	d6,loc_71A4
		rts
; END OF FUNCTION CHUNK	FOR LoadTilesFromStart
; ---------------------------------------------------------------------------
byte_71CA:	dc.b   0,  0,  0,  0,  6,  6,  6,  4,  4,  4,  0,  0,  0,  0,  0,  0; 0
					; DATA XREF: LoadTilesFromStart+AAo
; ---------------------------------------------------------------------------
		moveq	#$FFFFFFF0,d4
		moveq	#$F,d6

loc_71DE:				; CODE XREF: ROM:000071FCj
		movem.l	d4-d6,-(sp)
		lea	byte_6BCB(pc),a0
		move.w	(v_bgscreenposy).w,d0
		add.w	d4,d0
		andi.w	#$3F0,d0
		bsr.w	sub_7232
		movem.l	(sp)+,d4-d6
		addi.w	#$10,d4
		dbf	d6,loc_71DE
		rts
; ---------------------------------------------------------------------------
		moveq	#$FFFFFFF0,d4
		moveq	#$F,d6

loc_7206:				; CODE XREF: ROM:00007224j
		movem.l	d4-d6,-(sp)
		lea	byte_6AD1(pc),a0
		move.w	(v_bgscreenposy).w,d0
		add.w	d4,d0
		andi.w	#$1F0,d0
		bsr.w	sub_7232
		movem.l	(sp)+,d4-d6
		addi.w	#$10,d4
		dbf	d6,loc_7206
		rts
; ---------------------------------------------------------------------------
word_722A:	dc.w $EE08
		dc.w $EE08
		dc.w $EE10
		dc.w $EE18

; =============== S U B	R O U T	I N E =======================================


sub_7232:				; CODE XREF: LoadTilesFromStart+BAp
					; ROM:000071F0p ...
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		movea.w	word_722A(pc,d0.w),a3
		beq.s	loc_725A
		moveq	#$FFFFFFF0,d5
		movem.l	d4-d5,-(sp)
		bsr.w	sub_7084
		movem.l	(sp)+,d4-d5
		move	#$2700,sr
		bsr.w	sub_6D8C
		move	#$2300,sr
		rts
; ---------------------------------------------------------------------------

loc_725A:				; CODE XREF: sub_7232+Aj
		moveq	#0,d5
		movem.l	d4-d5,-(sp)
		bsr.w	sub_7086
		movem.l	(sp)+,d4-d5
		moveq	#$1F,d6
		bsr.w	sub_6D90
		rts
; End of function sub_7232


; =============== S U B	R O U T	I N E =======================================


MainLevelLoadBlock:			; CODE XREF: ROM:00003D3Ep
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#4,d0
		lea	(MainLoadBlocks).l,a2
		lea	(a2,d0.w),a2
		move.l	a2,-(sp)
		addq.l	#4,a2
		movea.l	(a2)+,a0
		tst.b	(v_zone).w
		beq.s	MainLevelLoadBlock_Convert16
		bra.s	MainLevelLoadBlock_Convert16
; ---------------------------------------------------------------------------

MainLevelLoadBlock_Skip16Convert:	; leftover from	a previous build
		lea	(v_16x16).w,a1
		move.w	#0,d0
		bsr.w	EniDec
		bra.s	loc_72C2
; ---------------------------------------------------------------------------

MainLevelLoadBlock_Convert16:		; CODE XREF: MainLevelLoadBlock+1Cj
					; MainLevelLoadBlock+1Ej
		lea	(v_16x16).w,a1
		move.w	#$BFF,d2

MainLevelLoadBlock_ConvertLoop:		; CODE XREF: MainLevelLoadBlock+4Ej
		move.w	(a0)+,d0
		tst.w	(f_2player).w
		beq.s	MainLevelLoadBlock_Not2p
		move.w	d0,d1
		andi.w	#$F800,d0
		andi.w	#$7FF,d1
		lsr.w	#1,d1
		or.w	d1,d0

MainLevelLoadBlock_Not2p:		; CODE XREF: MainLevelLoadBlock+3Cj
		move.w	d0,(a1)+
		dbf	d2,MainLevelLoadBlock_ConvertLoop

loc_72C2:				; CODE XREF: MainLevelLoadBlock+2Cj
		cmpi.b	#5,(v_zone).w
		bne.s	loc_72F4
		lea	(v_16x16+$980).w,a1
		lea	(Map16_HTZ).l,a0
		move.w	#$3FF,d2

loc_72D8:				; CODE XREF: MainLevelLoadBlock+80j
		move.w	(a0)+,d0
		tst.w	(f_2player).w
		beq.s	loc_72EE
		move.w	d0,d1
		andi.w	#$F800,d0
		andi.w	#$7FF,d1
		lsr.w	#1,d1
		or.w	d1,d0

loc_72EE:				; CODE XREF: MainLevelLoadBlock+6Ej
		move.w	d0,(a1)+
		dbf	d2,loc_72D8

loc_72F4:				; CODE XREF: MainLevelLoadBlock+58j
		movea.l	(a2)+,a0
		cmpi.b	#2,(v_zone).w
		beq.s	loc_7338
		cmpi.b	#3,(v_zone).w
		beq.s	loc_7338
		cmpi.b	#4,(v_zone).w
		beq.s	loc_7338
		cmpi.b	#5,(v_zone).w
		beq.s	loc_7338
		move.l	a2,-(sp)
		moveq	#0,d1
		moveq	#0,d2
		move.w	(a0)+,d0
		lea	(a0,d0.w),a1
		lea	(v_128x128).l,a2
		lea	($FFFF8000).w,a3

loc_732C:				; CODE XREF: MainLevelLoadBlock+C2j
		bsr.w	Decompress_Chunk
		tst.w	d0
		bmi.s	loc_732C
		movea.l	(sp)+,a2
		bra.s	loc_7348
; ---------------------------------------------------------------------------

loc_7338:				; CODE XREF: MainLevelLoadBlock+8Cj
					; MainLevelLoadBlock+94j ...
		lea	(v_128x128).l,a1
		move.w	#$3FFF,d0

loc_7342:				; CODE XREF: MainLevelLoadBlock+D4j
		move.w	(a0)+,(a1)+
		dbf	d0,loc_7342

loc_7348:				; CODE XREF: MainLevelLoadBlock+C6j
		bsr.w	LevelLayoutLoad
		move.w	(a2)+,d0
		move.w	(a2),d0
		andi.w	#$FF,d0
		cmpi.w	#$103,(v_zone).w
		bne.s	loc_735E
		moveq	#$C,d0

loc_735E:				; CODE XREF: MainLevelLoadBlock+EAj
		cmpi.w	#$501,(v_zone).w
		beq.s	loc_736E
		cmpi.w	#$502,(v_zone).w
		bne.s	loc_7370

loc_736E:				; CODE XREF: MainLevelLoadBlock+F4j
		moveq	#$E,d0

loc_7370:				; CODE XREF: MainLevelLoadBlock+FCj
		bsr.w	PalLoad1
		movea.l	(sp)+,a2
		addq.w	#4,a2
		moveq	#0,d0
		move.b	(a2),d0
		beq.s	locret_7382
		bsr.w	LoadPLC

locret_7382:				; CODE XREF: MainLevelLoadBlock+10Cj
		rts
; End of function MainLevelLoadBlock


; =============== S U B	R O U T	I N E =======================================


LevelLayoutLoad:			; CODE XREF: MainLevelLoadBlock:loc_7348p
		lea	(v_lvllayout).w,a3
		move.w	#$3FF,d1
		moveq	#0,d0

loc_738E:				; CODE XREF: LevelLayoutLoad+Cj
		move.l	d0,(a3)+
		dbf	d1,loc_738E
		lea	(v_lvllayout).w,a3
		moveq	#0,d1
		bsr.w	LevelLayoutLoad2
		lea	(v_lvllayout+$80).w,a3
		moveq	#2,d1
; End of function LevelLayoutLoad


; =============== S U B	R O U T	I N E =======================================


LevelLayoutLoad2:			; CODE XREF: LevelLayoutLoad+16p
		tst.b	(v_zone).w
		beq.s	LevelLayoutLoad_GHZ
		move.w	(v_zone).w,d0
		lsl.b	#6,d0
		lsr.w	#5,d0
		move.w	d0,d2
		add.w	d0,d0
		add.w	d2,d0
		add.w	d1,d0
		lea	(LevelLayout_Index).l,a1
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		moveq	#0,d1
		move.w	d1,d2
		move.b	(a1)+,d1
		move.b	(a1)+,d2
		move.l	d1,d5
		addq.l	#1,d5
		moveq	#0,d3
		move.w	#$80,d3
		divu.w	d5,d3
		subq.w	#1,d3

loc_73DE:				; CODE XREF: LevelLayoutLoad2+56j
		movea.l	a3,a0
		move.w	d3,d4

loc_73E2:				; CODE XREF: LevelLayoutLoad2+4Aj
		move.l	a1,-(sp)
		move.w	d1,d0

loc_73E6:				; CODE XREF: LevelLayoutLoad2+44j
		move.b	(a1)+,(a0)+
		dbf	d0,loc_73E6
		movea.l	(sp)+,a1
		dbf	d4,loc_73E2
		lea	(a1,d5.w),a1
		lea	$100(a3),a3
		dbf	d2,loc_73DE
		rts
; ---------------------------------------------------------------------------

LevelLayoutLoad_GHZ:			; CODE XREF: LevelLayoutLoad2+4j
		move.w	(v_zone).w,d0
		lsl.b	#6,d0
		lsr.w	#5,d0
		move.w	d0,d2
		add.w	d0,d0
		add.w	d2,d0
		add.w	d1,d0
		lea	(LevelLayout_Index).l,a1
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		moveq	#0,d1
		move.w	d1,d2
		move.b	(a1)+,d1
		move.b	(a1)+,d2

loc_7426:				; CODE XREF: LevelLayoutLoad2+BAj
		move.w	d1,d0
		movea.l	a3,a0

loc_742A:				; CODE XREF: LevelLayoutLoad2:loc_7456j
		move.b	(a1)+,d3
		subq.b	#1,d3
		bcc.s	loc_7440
		moveq	#0,d3
		move.b	d3,(a0)+
		move.b	d3,(a0)+
		move.b	d3,$FE(a0)
		move.b	d3,$FF(a0)
		bra.s	loc_7456
; ---------------------------------------------------------------------------

loc_7440:				; CODE XREF: LevelLayoutLoad2+8Aj
		lsl.b	#2,d3
		addq.b	#1,d3
		move.b	d3,(a0)+
		addq.b	#1,d3
		move.b	d3,(a0)+
		addq.b	#1,d3
		move.b	d3,$FE(a0)
		addq.b	#1,d3
		move.b	d3,$FF(a0)

loc_7456:				; CODE XREF: LevelLayoutLoad2+9Aj
		dbf	d0,loc_742A
		lea	$200(a3),a3
		dbf	d2,loc_7426
		rts
; End of function LevelLayoutLoad2

; ---------------------------------------------------------------------------

LevelLayout_Convert:			; leftover level layout	converting function (from raw to the way it"s stored in the game)
		lea	($FE0000).l,a1
		lea	($FE0080).l,a2
		lea	($FFFF0000).l,a3
		move.w	#$3F,d1

loc_747A:				; CODE XREF: ROM:00007482j
		bsr.w	sub_750C
		bsr.w	sub_750C
		dbf	d1,loc_747A
		lea	($FE0000).l,a1
		lea	($FF0000).l,a2
		move.w	#$3F,d1

loc_7496:				; CODE XREF: ROM:0000749Aj
		move.w	#0,(a2)+
		dbf	d1,loc_7496
		move.w	#$3FBF,d1

loc_74A2:				; CODE XREF: ROM:000074A4j
		move.w	(a1)+,(a2)+
		dbf	d1,loc_74A2
		rts
; ---------------------------------------------------------------------------
		lea	($FE0000).l,a1
		lea	($FFFF0000).l,a3
		moveq	#$1F,d0

loc_74B8:				; CODE XREF: ROM:000074BAj
		move.l	(a1)+,(a3)+
		dbf	d0,loc_74B8
		moveq	#0,d7
		lea	($FE0000).l,a1
		move.w	#$FF,d5

loc_74CA:				; CODE XREF: ROM:000074EAj
					; ROM:00007506j
		lea	($FFFF0000).l,a3
		move.w	d7,d6

loc_74D2:				; CODE XREF: ROM:000074F8j
		movem.l	a1-a3,-(sp)
		move.w	#$3F,d0	

loc_74DA:				; CODE XREF: ROM:000074DEj
		cmpm.w	(a1)+,(a3)+
		bne.s	loc_74F0
		dbf	d0,loc_74DA
		movem.l	(sp)+,a1-a3
		adda.w	#$80,a1	
		dbf	d5,loc_74CA
		bra.s	loc_750A
; ---------------------------------------------------------------------------

loc_74F0:				; CODE XREF: ROM:000074DCj
		movem.l	(sp)+,a1-a3
		adda.w	#$80,a3	
		dbf	d6,loc_74D2
		moveq	#$1F,d0

loc_74FE:				; CODE XREF: ROM:00007500j
		move.l	(a1)+,(a3)+
		dbf	d0,loc_74FE
		addq.l	#1,d7
		dbf	d5,loc_74CA

loc_750A:				; CODE XREF: ROM:000074EEj
					; ROM:loc_750Aj
		bra.s	loc_750A

; =============== S U B	R O U T	I N E =======================================


sub_750C:				; CODE XREF: ROM:loc_747Ap
					; ROM:0000747Ep
		moveq	#7,d0

loc_750E:				; CODE XREF: sub_750C+12j
		move.l	(a3)+,(a1)+
		move.l	(a3)+,(a1)+
		move.l	(a3)+,(a1)+
		move.l	(a3)+,(a1)+
		move.l	(a3)+,(a2)+
		move.l	(a3)+,(a2)+
		move.l	(a3)+,(a2)+
		move.l	(a3)+,(a2)+
		dbf	d0,loc_750E
		adda.w	#$80,a1
		adda.w	#$80,a2
		rts
; End of function sub_750C

                include "_inc\DynamicLevelEvents.asm"

; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 11 - Bridge
;----------------------------------------------------

Obj11:					; DATA XREF: ROM:Obj_Indexo
		btst	#6,1(a0)
		bne.w	loc_7BB8
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj11_Index(pc,d0.w),d1
		jmp	Obj11_Index(pc,d1.w)
; ---------------------------------------------------------------------------

loc_7BB8:				; CODE XREF: ROM:00007BA6j
		moveq	#3,d0
		bra.w	DisplaySprite_Param
; ---------------------------------------------------------------------------
Obj11_Index:	dc.w loc_7BC6-Obj11_Index ; DATA XREF: ROM:Obj11_Indexo
					; ROM:00007BC0o ...
		dc.w loc_7CC8-Obj11_Index
		dc.w loc_7D5A-Obj11_Index
		dc.w loc_7D5E-Obj11_Index
; ---------------------------------------------------------------------------

loc_7BC6:				; DATA XREF: ROM:Obj11_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj11,4(a0)
		move.w	#$44C6,2(a0)
		move.b	#3,$18(a0)
		cmpi.b	#3,(v_zone).w
		bne.s	loc_7BFA
		move.l	#Map_Obj11_EHZ,4(a0)
		move.w	#$43C6,2(a0)
		move.b	#3,$18(a0)

loc_7BFA:				; CODE XREF: ROM:00007BE4j
		cmpi.b	#4,(v_zone).w
		bne.s	loc_7C14
		addq.b	#4,$24(a0)
		move.l	#Map_Obj11_HPZ,4(a0)
		move.w	#$6300,2(a0)

loc_7C14:				; CODE XREF: ROM:00007C00j
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#$80,$19(a0)
		move.w	$C(a0),d2
		move.w	d2,$3C(a0)
		move.w	8(a0),d3
		lea	$28(a0),a2
		moveq	#0,d1
		move.b	(a2),d1
		move.w	d1,d0
		lsr.w	#1,d0
		lsl.w	#4,d0
		sub.w	d0,d3
		swap	d1
		move.w	#8,d1
		bsr.s	sub_7C76
		move.w	$28(a1),d0
		subq.w	#8,d0
		move.w	d0,8(a1)
		move.l	a1,$30(a0)
		swap	d1
		subq.w	#8,d1
		bls.s	loc_7C74
		move.w	d1,d4
		bsr.s	sub_7C76
		move.l	a1,$34(a0)
		move.w	d4,d0
		add.w	d0,d0
		add.w	d4,d0
		move.w	$10(a1,d0.w),d0
		subq.w	#8,d0
		move.w	d0,8(a1)

loc_7C74:				; CODE XREF: ROM:00007C5Aj
		bra.s	loc_7CC8

; =============== S U B	R O U T	I N E =======================================


sub_7C76:				; CODE XREF: ROM:00007C46p
					; ROM:00007C5Ep
		bsr.w	S1SingleObjectLoad2
		bne.s	locret_7CC6
		move.b	0(a0),0(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.l	4(a0),4(a1)
		move.w	2(a0),2(a1)
		move.b	1(a0),1(a1)
		bset	#6,1(a1)
		move.b	#$40,$E(a1) 
		move.b	d1,$F(a1)
		subq.b	#1,d1
		lea	$10(a1),a2

loc_7CB6:				; CODE XREF: sub_7C76+4Cj
		move.w	d3,(a2)+
		move.w	d2,(a2)+
		move.w	#0,(a2)+
		addi.w	#$10,d3
		dbf	d1,loc_7CB6

locret_7CC6:				; CODE XREF: sub_7C76+4j
		rts
; End of function sub_7C76

; ---------------------------------------------------------------------------

loc_7CC8:				; CODE XREF: ROM:loc_7C74j
					; DATA XREF: ROM:00007BC0o
		move.b	$22(a0),d0
		andi.b	#$18,d0
		bne.s	loc_7CDE
		tst.b	$3E(a0)
		beq.s	loc_7D0A
		subq.b	#4,$3E(a0)
		bra.s	loc_7D06
; ---------------------------------------------------------------------------

loc_7CDE:				; CODE XREF: ROM:00007CD0j
		andi.b	#$10,d0
		beq.s	loc_7CFA
		move.b	$3F(a0),d0
		sub.b	$3B(a0),d0
		beq.s	loc_7CFA
		bcc.s	loc_7CF6
		addq.b	#1,$3F(a0)
		bra.s	loc_7CFA
; ---------------------------------------------------------------------------

loc_7CF6:				; CODE XREF: ROM:00007CEEj
		subq.b	#1,$3F(a0)

loc_7CFA:				; CODE XREF: ROM:00007CE2j
					; ROM:00007CECj ...
		cmpi.b	#$40,$3E(a0) 
		beq.s	loc_7D06
		addq.b	#4,$3E(a0)

loc_7D06:				; CODE XREF: ROM:00007CDCj
					; ROM:00007D00j
		bsr.w	sub_7F36

loc_7D0A:				; CODE XREF: ROM:00007CD6j
		moveq	#0,d1
		move.b	$28(a0),d1
		lsl.w	#3,d1
		move.w	d1,d2
		addq.w	#8,d1
		add.w	d2,d2
		moveq	#8,d3
		move.w	8(a0),d4
		bsr.w	sub_7DC0

loc_7D22:				; CODE XREF: ROM:00007DBCj
		tst.w	(f_2player).w
		beq.s	loc_7D2A
		rts
; ---------------------------------------------------------------------------

loc_7D2A:				; CODE XREF: ROM:00007D26j
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.s	loc_7D3E
		rts
; ---------------------------------------------------------------------------

loc_7D3E:				; CODE XREF: ROM:00007D3Aj
		movea.l	$30(a0),a1
		bsr.w	sub_CF3C
		cmpi.b	#8,$28(a0)
		bls.s	loc_7D56
		movea.l	$34(a0),a1
		bsr.w	sub_CF3C

loc_7D56:				; CODE XREF: ROM:00007D4Cj
		bra.w	DeleteObject
; ---------------------------------------------------------------------------

loc_7D5A:				; DATA XREF: ROM:00007BC2o
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_7D5E:				; DATA XREF: ROM:00007BC4o
		move.b	$22(a0),d0
		andi.b	#$18,d0
		bne.s	loc_7D74
		tst.b	$3E(a0)
		beq.s	loc_7DA0
		subq.b	#4,$3E(a0)
		bra.s	loc_7D9C
; ---------------------------------------------------------------------------

loc_7D74:				; CODE XREF: ROM:00007D66j
		andi.b	#$10,d0
		beq.s	loc_7D90
		move.b	$3F(a0),d0
		sub.b	$3B(a0),d0
		beq.s	loc_7D90
		bcc.s	loc_7D8C
		addq.b	#1,$3F(a0)
		bra.s	loc_7D90
; ---------------------------------------------------------------------------

loc_7D8C:				; CODE XREF: ROM:00007D84j
		subq.b	#1,$3F(a0)

loc_7D90:				; CODE XREF: ROM:00007D78j
					; ROM:00007D82j ...
		cmpi.b	#$40,$3E(a0) 
		beq.s	loc_7D9C
		addq.b	#4,$3E(a0)

loc_7D9C:				; CODE XREF: ROM:00007D72j
					; ROM:00007D96j
		bsr.w	sub_7F36

loc_7DA0:				; CODE XREF: ROM:00007D6Cj
		moveq	#0,d1
		move.b	$28(a0),d1
		lsl.w	#3,d1
		move.w	d1,d2
		addq.w	#8,d1
		add.w	d2,d2
		moveq	#8,d3
		move.w	8(a0),d4
		bsr.w	sub_7DC0
		bsr.w	sub_7E60
		bra.w	loc_7D22

; =============== S U B	R O U T	I N E =======================================


sub_7DC0:				; CODE XREF: ROM:00007D1Ep
					; ROM:00007DB4p
		lea	(v_objspace+$40).w,a1
		moveq	#4,d6
		moveq	#$3B,d5	
		movem.l	d1-d4,-(sp)
		bsr.s	sub_7DDA
		movem.l	(sp)+,d1-d4
		lea	(v_objspace).w,a1
		subq.b	#1,d6
		moveq	#$3F,d5	
; End of function sub_7DC0


; =============== S U B	R O U T	I N E =======================================


sub_7DDA:				; CODE XREF: sub_7DC0+Cp
		btst	d6,$22(a0)
		beq.s	loc_7E3E
		btst	#1,$22(a1)
		bne.s	loc_7DFA
		moveq	#0,d0
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_7DFA
		cmp.w	d2,d0
		bcs.s	loc_7E08

loc_7DFA:				; CODE XREF: sub_7DDA+Cj sub_7DDA+1Aj
		bclr	#3,$22(a1)
		bclr	d6,$22(a0)
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------

loc_7E08:				; CODE XREF: sub_7DDA+1Ej
		lsr.w	#4,d0
		move.b	d0,(a0,d5.w)
		movea.l	$30(a0),a2
		cmpi.w	#8,d0
		bcs.s	loc_7E20
		movea.l	$34(a0),a2
		subi.w	#8,d0

loc_7E20:				; CODE XREF: sub_7DDA+3Cj
		add.w	d0,d0
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		move.w	$12(a2,d0.w),d0
		subq.w	#8,d0
		moveq	#0,d1
		move.b	$16(a1),d1
		sub.w	d1,d0
		move.w	d0,$C(a1)
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------

loc_7E3E:				; CODE XREF: sub_7DDA+4j
		move.w	d1,-(sp)
		bsr.w	sub_F880
		move.w	(sp)+,d1
		btst	d6,$22(a0)
		beq.s	locret_7E5E
		moveq	#0,d0
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		lsr.w	#4,d0
		move.b	d0,(a0,d5.w)

locret_7E5E:				; CODE XREF: sub_7DDA+70j
		rts
; End of function sub_7DDA


; =============== S U B	R O U T	I N E =======================================


sub_7E60:				; CODE XREF: ROM:00007DB8p
		moveq	#0,d0
		tst.w	(v_objspace+$10).w
		bne.s	loc_7E72
		move.b	($FFFFFE0F).w,d0
		andi.w	#$1C,d0
		lsr.w	#1,d0

loc_7E72:				; CODE XREF: sub_7E60+6j
		moveq	#0,d2
		move.b	byte_7E9F(pc,d0.w),d2
		swap	d2
		move.b	byte_7E9E(pc,d0.w),d2
		moveq	#0,d0
		tst.w	(v_objspace+$50).w
		bne.s	loc_7E90
		move.b	($FFFFFE0F).w,d0
		andi.w	#$1C,d0
		lsr.w	#1,d0

loc_7E90:				; CODE XREF: sub_7E60+24j
		moveq	#0,d6
		move.b	byte_7E9F(pc,d0.w),d6
		swap	d6
		move.b	byte_7E9E(pc,d0.w),d6
		bra.s	loc_7EAE
; ---------------------------------------------------------------------------
byte_7E9E:	dc.b 1
byte_7E9F:	dc.b   2,  1,  2,  1,  2,  1,  2,  0,  1,  0,  0,  0,  0,  0,  1; 0
; ---------------------------------------------------------------------------

loc_7EAE:				; CODE XREF: sub_7E60+3Cj
		moveq	#$FFFFFFFE,d3
		moveq	#$FFFFFFFE,d4
		move.b	$22(a0),d0
		andi.b	#8,d0
		beq.s	loc_7EC0
		move.b	$3F(a0),d3

loc_7EC0:				; CODE XREF: sub_7E60+5Aj
		move.b	$22(a0),d0
		andi.b	#$10,d0
		beq.s	loc_7ECE
		move.b	$3B(a0),d4

loc_7ECE:				; CODE XREF: sub_7E60+68j
		movea.l	$30(a0),a1
		lea	$45(a1),a2
		lea	$15(a1),a1
		moveq	#0,d1
		move.b	$28(a0),d1
		subq.b	#1,d1
		moveq	#0,d5

loc_7EE4:				; CODE XREF: sub_7E60:loc_7F30j
		moveq	#0,d0
		subq.w	#1,d3
		cmp.b	d3,d5
		bne.s	loc_7EEE
		move.w	d2,d0

loc_7EEE:				; CODE XREF: sub_7E60+8Aj
		addq.w	#2,d3
		cmp.b	d3,d5
		bne.s	loc_7EF6
		move.w	d2,d0

loc_7EF6:				; CODE XREF: sub_7E60+92j
		subq.w	#1,d3
		subq.w	#1,d4
		cmp.b	d4,d5
		bne.s	loc_7F00
		move.w	d6,d0

loc_7F00:				; CODE XREF: sub_7E60+9Cj
		addq.w	#2,d4
		cmp.b	d4,d5
		bne.s	loc_7F08
		move.w	d6,d0

loc_7F08:				; CODE XREF: sub_7E60+A4j
		subq.w	#1,d4
		cmp.b	d3,d5
		bne.s	loc_7F14
		swap	d2
		move.w	d2,d0
		swap	d2

loc_7F14:				; CODE XREF: sub_7E60+ACj
		cmp.b	d4,d5
		bne.s	loc_7F1E
		swap	d6
		move.w	d6,d0
		swap	d6

loc_7F1E:				; CODE XREF: sub_7E60+B6j
		move.b	d0,(a1)
		addq.w	#1,d5
		addq.w	#6,a1
		cmpa.w	a2,a1
		bne.s	loc_7F30
		movea.l	$34(a0),a1
		lea	$15(a1),a1

loc_7F30:				; CODE XREF: sub_7E60+C6j
		dbf	d1,loc_7EE4
		rts
; End of function sub_7E60


; =============== S U B	R O U T	I N E =======================================


sub_7F36:				; CODE XREF: ROM:loc_7D06p
					; ROM:loc_7D9Cp
		move.b	$3E(a0),d0
		bsr.w	CalcSine
		move.w	d0,d4
		lea	(Obj11_BendData2).l,a4
		moveq	#0,d0
		move.b	$28(a0),d0
		lsl.w	#4,d0
		moveq	#0,d3
		move.b	$3F(a0),d3
		move.w	d3,d2
		add.w	d0,d3
		moveq	#0,d5
		lea	(Obj11_BendData-$80).l,a5
		move.b	(a5,d3.w),d5

loc_7F64:
		andi.w	#$F,d3
		lsl.w	#4,d3
		lea	(a4,d3.w),a3
		movea.l	$30(a0),a1
		lea	$42(a1),a2
		lea	$12(a1),a1

loc_7F7A:				; CODE XREF: sub_7F36:loc_7F9Aj
		moveq	#0,d0
		move.b	(a3)+,d0
		addq.w	#1,d0
		mulu.w	d5,d0
		mulu.w	d4,d0
		swap	d0
		add.w	$3C(a0),d0
		move.w	d0,(a1)
		addq.w	#6,a1
		cmpa.w	a2,a1
		bne.s	loc_7F9A
		movea.l	$34(a0),a1
		lea	$12(a1),a1

loc_7F9A:				; CODE XREF: sub_7F36+5Aj
		dbf	d2,loc_7F7A
		moveq	#0,d0
		move.b	$28(a0),d0
		moveq	#0,d3
		move.b	$3F(a0),d3
		addq.b	#1,d3
		sub.b	d0,d3
		neg.b	d3
		bmi.s	locret_7FE4
		move.w	d3,d2
		lsl.w	#4,d3
		lea	(a4,d3.w),a3
		adda.w	d2,a3
		subq.w	#1,d2
		bcs.s	locret_7FE4

loc_7FC0:				; CODE XREF: sub_7F36:loc_7FE0j
		moveq	#0,d0
		move.b	-(a3),d0
		addq.w	#1,d0
		mulu.w	d5,d0
		mulu.w	d4,d0
		swap	d0
		add.w	$3C(a0),d0
		move.w	d0,(a1)
		addq.w	#6,a1
		cmpa.w	a2,a1
		bne.s	loc_7FE0
		movea.l	$34(a0),a1
		lea	$12(a1),a1

loc_7FE0:				; CODE XREF: sub_7F36+A0j
		dbf	d2,loc_7FC0

locret_7FE4:				; CODE XREF: sub_7F36+7Aj sub_7F36+88j
		rts
; End of function sub_7F36

; ---------------------------------------------------------------------------
Obj11_BendData:	dc.b   2,  4,  6,  8,  8,  6,  4,  2,  0,  0,  0,  0,  0,  0,  0,  0; 0
					; DATA XREF: sub_7F36+24t
		dc.b   2,  4,  6,  8, $A,  8,  6,  4,  2,  0,  0,  0,  0,  0,  0,  0; 16
		dc.b   2,  4,  6,  8, $A, $A,  8,  6,  4,  2,  0,  0,  0,  0,  0,  0; 32
		dc.b   2,  4,  6,  8, $A, $C, $A,  8,  6,  4,  2,  0,  0,  0,  0,  0; 48
		dc.b   2,  4,  6,  8, $A, $C, $C, $A,  8,  6,  4,  2,  0,  0,  0,  0; 64
		dc.b   2,  4,  6,  8, $A, $C, $E, $C, $A,  8,  6,  4,  2,  0,  0,  0; 80
		dc.b   2,  4,  6,  8, $A, $C, $E, $E, $C, $A,  8,  6,  4,  2,  0,  0; 96
		dc.b   2,  4,  6,  8, $A, $C, $E,$10, $E, $C, $A,  8,  6,  4,  2,  0; 112
		dc.b   2,  4,  6,  8, $A, $C, $E,$10,$10, $E, $C, $A,  8,  6,  4,  2; 128
Obj11_BendData2:dc.b $FF,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 0
					; DATA XREF: sub_7F36+Ao
		dc.b $B5,$FF,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 16
		dc.b $7E,$DB,$FF,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 32
		dc.b $61,$B5,$EC,$FF,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 48
		dc.b $4A,$93,$CD,$F3,$FF,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 64
		dc.b $3E,$7E,$B0,$DB,$F6,$FF,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0; 80
		dc.b $38,$6D,$9D,$C5,$E4,$F8,$FF,  0,  0,  0,  0,  0,  0,  0,  0,  0; 96
		dc.b $31,$61,$8E,$B5,$D4,$EC,$FB,$FF,  0,  0,  0,  0,  0,  0,  0,  0; 112
		dc.b $2B,$56,$7E,$A2,$C1,$DB,$EE,$FB,$FF,  0,  0,  0,  0,  0,  0,  0; 128
		dc.b $25,$4A,$73,$93,$B0,$CD,$E1,$F3,$FC,$FF,  0,  0,  0,  0,  0,  0; 144
		dc.b $1F,$44,$67,$88,$A7,$BD,$D4,$E7,$F4,$FD,$FF,  0,  0,  0,  0,  0; 160
		dc.b $1F,$3E,$5C,$7E,$98,$B0,$C9,$DB,$EA,$F6,$FD,$FF,  0,  0,  0,  0; 176
		dc.b $19,$38,$56,$73,$8E,$A7,$BD,$D1,$E1,$EE,$F8,$FE,$FF,  0,  0,  0; 192
		dc.b $19,$38,$50,$6D,$83,$9D,$B0,$C5,$D8,$E4,$F1,$F8,$FE,$FF,  0,  0; 208
		dc.b $19,$31,$4A,$67,$7E,$93,$A7,$BD,$CD,$DB,$E7,$F3,$F9,$FE,$FF,  0; 224
		dc.b $19,$31,$4A,$61,$78,$8E,$A2,$B5,$C5,$D4,$E1,$EC,$F4,$FB,$FE,$FF; 240
Map_Obj11:	dc.w word_817C-Map_Obj11 ; DATA	XREF: ROM:00007BCAo
					; ROM:Map_Obj11o ...
		dc.w word_8186-Map_Obj11
		dc.w word_8198-Map_Obj11
word_817C:	dc.w 1			; DATA XREF: ROM:Map_Obj11o
		dc.w $F805,    0,    0,$FFF8; 0
word_8186:	dc.w 2			; DATA XREF: ROM:00008178o
		dc.w $F804,    4,    2,$FFF0; 0
		dc.w	$C,    6,    3,$FFF0; 4
word_8198:	dc.w 1			; DATA XREF: ROM:0000817Ao
		dc.w $FC04,    8,    4,$FFF8; 0
Map_Obj11_HPZ:	dc.w word_81AE-Map_Obj11_HPZ ; DATA XREF: ROM:00007C06o
					; ROM:Map_Obj11_HPZo ...
		dc.w word_81B8-Map_Obj11_HPZ
		dc.w word_81C2-Map_Obj11_HPZ
		dc.w word_81CC-Map_Obj11_HPZ
		dc.w word_81D6-Map_Obj11_HPZ
		dc.w word_81E0-Map_Obj11_HPZ
word_81AE:	dc.w 1			; DATA XREF: ROM:Map_Obj11_HPZo
		dc.w $F805,    0,    0,$FFF8; 0
word_81B8:	dc.w 1			; DATA XREF: ROM:000081A4o
		dc.w $F805,    4,    2,$FFF8; 0
word_81C2:	dc.w 1			; DATA XREF: ROM:000081A6o
		dc.w $F805,    8,    4,$FFF8; 0
word_81CC:	dc.w 1			; DATA XREF: ROM:000081A8o
		dc.w $F402,   $C,    6,$FFFC; 0
word_81D6:	dc.w 1			; DATA XREF: ROM:000081AAo
		dc.w $F402,   $F,    7,$FFFC; 0
word_81E0:	dc.w 1			; DATA XREF: ROM:000081ACo
word_81E2:	dc.w $F402,  $12,    9,$FFFC; 0
Map_Obj11_EHZ:	dc.w word_81EE-Map_Obj11_EHZ ; DATA XREF: ROM:00007BE6o
					; ROM:Map_Obj11_EHZo ...
		dc.w word_81F8-Map_Obj11_EHZ
word_81EE:	dc.w 1			; DATA XREF: ROM:Map_Obj11_EHZo
		dc.w $F805,    4,    2,$FFF8; 0
word_81F8:	dc.w 1			; DATA XREF: ROM:000081ECo
		dc.w $F805,    0,    0,$FFF8; 0
; ---------------------------------------------------------------------------
		nop
;----------------------------------------------------
; Object 15 - swinging platforms
;----------------------------------------------------

Obj15:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj15_Index(pc,d0.w),d1
		jmp	Obj15_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj15_Index:	dc.w loc_821E-Obj15_Index ; DATA XREF: ROM:Obj15_Indexo
					; ROM:00008214o ...
		dc.w loc_83AA-Obj15_Index
		dc.w loc_8526-Obj15_Index
		dc.w loc_8526-Obj15_Index
		dc.w loc_852A-Obj15_Index
		dc.w loc_83CA-Obj15_Index
; ---------------------------------------------------------------------------

loc_821E:				; DATA XREF: ROM:Obj15_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj15,4(a0)
		move.w	#$44D0,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#$18,$19(a0)
		move.b	#8,$16(a0)
		move.w	$C(a0),$38(a0)
		move.w	8(a0),$3A(a0)
		cmpi.b	#3,(v_zone).w
		bne.s	loc_8284
		move.l	#Map_Obj15_EHZ,4(a0)
		move.w	#$43DC,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#$20,$19(a0) 
		move.b	#$10,$16(a0)
		move.b	#$99,$20(a0)

loc_8284:				; CODE XREF: ROM:0000825Ej
		cmpi.b	#2,(v_zone).w
		bne.s	loc_82BE
		move.l	#Map_Obj15_CPZ,4(a0)
		move.w	#$2418,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#$20,$19(a0) 
		move.b	#$10,$16(a0)
		lea	$28(a0),a2
		move.b	(a2),d0
		lsl.w	#4,d0
		move.b	d0,$3C(a0)
		move.b	#0,(a2)+
		bra.w	loc_8388
; ---------------------------------------------------------------------------

loc_82BE:				; CODE XREF: ROM:0000828Aj
		move.b	0(a0),d4
		moveq	#0,d1
		lea	$28(a0),a2
		move.b	(a2),d1
		move.w	d1,-(sp)
		andi.w	#$F,d1
		move.b	#0,(a2)+
		move.w	d1,d3
		lsl.w	#4,d3
		addi.b	#8,d3
		move.b	d3,$3C(a0)
		subi.b	#8,d3
		tst.b	$1A(a0)
		beq.s	loc_82F0
		addi.b	#8,d3
		subq.w	#1,d1

loc_82F0:				; CODE XREF: ROM:000082E8j
					; ROM:loc_8358j
		bsr.w	S1SingleObjectLoad2
		bne.s	loc_835C
		addq.b	#1,$28(a0)
		move.w	a1,d5
		subi.w	#$B000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5	
		move.b	d5,(a2)+
		move.b	#8,$24(a1)
		move.b	d4,0(a1)
		move.l	4(a0),4(a1)
		move.w	2(a0),2(a1)
		bclr	#6,2(a1)
		move.b	#4,1(a1)
		move.b	#4,$18(a1)
		move.b	#8,$19(a1)
		move.b	#1,$1A(a1)
		move.b	d3,$3C(a1)
		subi.b	#$10,d3
		bcc.s	loc_8358
		move.b	#2,$1A(a1)
		move.b	#3,$18(a1)
		bset	#6,2(a1)

loc_8358:				; CODE XREF: ROM:00008344j
		dbf	d1,loc_82F0

loc_835C:				; CODE XREF: ROM:000082F4j
		move.w	(sp)+,d1
		btst	#4,d1
		beq.s	loc_8388
		move.l	#Map_Obj48,4(a0)
		move.w	#$43AA,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#1,$1A(a0)
		move.b	#2,$18(a0)
		move.b	#$81,$20(a0)

loc_8388:				; CODE XREF: ROM:000082BAj
					; ROM:00008362j
		move.w	a0,d5
		subi.w	#$B000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5	
		move.b	d5,(a2)+
		move.w	#$4080,$26(a0)
		move.w	#$FE00,$3E(a0)
		cmpi.b	#5,(v_zone).w
		beq.s	loc_83CA

loc_83AA:				; DATA XREF: ROM:00008214o
		move.w	8(a0),-(sp)
		bsr.w	sub_83D2
		moveq	#0,d1
		move.b	$19(a0),d1
		moveq	#0,d3
		move.b	$16(a0),d3
		addq.b	#1,d3
		move.w	(sp)+,d4
		bsr.w	sub_F82E
		bra.w	loc_84EE
; ---------------------------------------------------------------------------

loc_83CA:				; CODE XREF: ROM:000083A8j
					; DATA XREF: ROM:0000821Co
		bsr.w	sub_83D2
		bra.w	loc_84EE

; =============== S U B	R O U T	I N E =======================================


sub_83D2:				; CODE XREF: ROM:000083AEp
					; ROM:loc_83CAp
		move.b	($FFFFFE78).w,d0
		move.w	#$80,d1	
		btst	#0,$22(a0)
		beq.s	loc_83E6
		neg.w	d0
		add.w	d1,d0

loc_83E6:				; CODE XREF: sub_83D2+Ej
		bra.w	loc_8472
; ---------------------------------------------------------------------------

loc_83EA:				; CODE XREF: ROM:0001922Ap
		tst.b	$3D(a0)
		bne.s	loc_840E
		move.w	$3E(a0),d0
		addi.w	#8,d0
		move.w	d0,$3E(a0)
		add.w	d0,$26(a0)
		cmpi.w	#$200,d0
		bne.s	loc_842A
		move.b	#1,$3D(a0)
		bra.s	loc_842A
; ---------------------------------------------------------------------------

loc_840E:				; CODE XREF: sub_83D2+1Cj
		move.w	$3E(a0),d0
		subi.w	#8,d0
		move.w	d0,$3E(a0)
		add.w	d0,$26(a0)
		cmpi.w	#$FE00,d0
		bne.s	loc_842A
		move.b	#0,$3D(a0)

loc_842A:				; CODE XREF: sub_83D2+32j sub_83D2+3Aj ...
		move.b	$26(a0),d0

loc_842E:				; CODE XREF: ROM:0001921Ap
		bsr.w	CalcSine
		move.w	$38(a0),d2
		move.w	$3A(a0),d3
		lea	$28(a0),a2
		moveq	#0,d6
		move.b	(a2)+,d6

loc_8442:				; CODE XREF: sub_83D2+9Aj
		moveq	#0,d4
		move.b	(a2)+,d4
		lsl.w	#6,d4
		addi.l	#v_objspace,d4
		movea.l	d4,a1
		moveq	#0,d4
		move.b	$3C(a1),d4
		move.l	d4,d5
		muls.w	d0,d4
		asr.l	#8,d4
		muls.w	d1,d5
		asr.l	#8,d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,$C(a1)
		move.w	d5,8(a1)
		dbf	d6,loc_8442
		rts
; ---------------------------------------------------------------------------

loc_8472:				; CODE XREF: sub_83D2:loc_83E6j
		bsr.w	CalcSine
		move.w	$38(a0),d2
		move.w	$3A(a0),d3
		moveq	#0,d4
		move.b	$3C(a0),d4
		move.l	d4,d5
		muls.w	d0,d4
		asr.l	#8,d4
		muls.w	d1,d5
		asr.l	#8,d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,$C(a0)
		move.w	d5,8(a0)
		lea	$28(a0),a2
		moveq	#0,d6
		move.b	(a2)+,d6
		adda.w	d6,a2
		subq.b	#1,d6
		bcs.s	locret_84EC
		move.w	d6,-(sp)
		asl.w	#4,d0
		ext.l	d0
		asl.l	#8,d0
		asl.w	#4,d1
		ext.l	d1
		asl.l	#8,d1
		moveq	#0,d4
		moveq	#0,d5

loc_84BA:				; CODE XREF: sub_83D2+114j
		moveq	#0,d6
		move.b	-(a2),d6
		lsl.w	#6,d6
		addi.l	#v_objspace,d6
		movea.l	d6,a1
		movem.l	d4-d5,-(sp)
		swap	d4
		swap	d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,$C(a1)
		move.w	d5,8(a1)
		movem.l	(sp)+,d4-d5
		add.l	d0,d4
		add.l	d1,d5
		subq.w	#1,(sp)
		bcc.w	loc_84BA
		addq.w	#2,sp

locret_84EC:				; CODE XREF: sub_83D2+D4j
		rts
; End of function sub_83D2

; ---------------------------------------------------------------------------

loc_84EE:				; CODE XREF: ROM:000083C6j
					; ROM:000083CEj
		move.w	$3A(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	loc_8506
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_8506:				; CODE XREF: ROM:000084FEj
		moveq	#0,d2
		lea	$28(a0),a2
		move.b	(a2)+,d2

loc_850E:				; CODE XREF: ROM:00008520j
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#v_objspace,d0
		movea.l	d0,a1
		bsr.w	sub_CF3C
		dbf	d2,loc_850E
		rts
; ---------------------------------------------------------------------------

loc_8526:				; DATA XREF: ROM:00008216o
					; ROM:00008218o
		bra.w	DeleteObject
; ---------------------------------------------------------------------------

loc_852A:				; DATA XREF: ROM:0000821Ao
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Map_Obj15:	dc.w word_8534-Map_Obj15 ; DATA	XREF: ROM:00008222o
					; ROM:Map_Obj15o ...
		dc.w word_8546-Map_Obj15
		dc.w word_8550-Map_Obj15
word_8534:	dc.w 2			; DATA XREF: ROM:Map_Obj15o
		dc.w $F809,    4,    2,$FFE8; 0
		dc.w $F809,    4,    2,	   0; 4
word_8546:	dc.w 1			; DATA XREF: ROM:00008530o
		dc.w $F805,    0,    0,$FFF8; 0
word_8550:	dc.w 1			; DATA XREF: ROM:00008532o
		dc.w $F805,   $A,    5,$FFF8; 0
Map_Obj15_CPZ:	dc.w word_855C-Map_Obj15_CPZ ; DATA XREF: ROM:0000828Co
					; ROM:Map_Obj15_CPZo ...
word_855C:	dc.w 2			; DATA XREF: ROM:Map_Obj15_CPZo
		dc.w $F00F,    8,    4,$FFE0; 0
		dc.w $F00F, $808, $804,	   0; 4
Map_Obj15_EHZ:	dc.w word_8574-Map_Obj15_EHZ ; DATA XREF: ROM:00008260o
					; ROM:Map_Obj15_EHZo ...
		dc.w word_85B6-Map_Obj15_EHZ
		dc.w word_85C0-Map_Obj15_EHZ
word_8574:	dc.w 8			; DATA XREF: ROM:Map_Obj15_EHZo
		dc.w $F00F,    4,    2,$FFE0; 0
		dc.w $F00F, $804, $802,	   0; 4
		dc.w $F005,  $14,   $A,$FFD0; 8
		dc.w $F005, $814, $80A,	 $20; 12
		dc.w $1004,  $18,   $C,$FFE0; 16
		dc.w $1004, $818, $80C,	 $10; 20
		dc.w $1001,  $1A,   $D,$FFF8; 24
		dc.w $1001, $81A, $80D,	   0; 28
word_85B6:	dc.w 1			; DATA XREF: ROM:00008570o
		dc.w $F805,$4000,$4000,$FFF8; 0
word_85C0:	dc.w 1			; DATA XREF: ROM:00008572o
		dc.w $F805,  $1C,   $E,$FFF8; 0
Map_Obj48:	dc.w word_85D2-Map_Obj48 ; DATA	XREF: ROM:00008364o
					; ROM:Map_Obj48o ...
		dc.w word_8604-Map_Obj48
		dc.w word_8626-Map_Obj48
		dc.w word_8648-Map_Obj48
word_85D2:	dc.w 6			; DATA XREF: ROM:Map_Obj48o
		dc.w $F004,  $24,  $12,$FFF0; 0
		dc.w $F804,$1024,$1012,$FFF0; 4
		dc.w $E80A,    0,    0,$FFE8; 8
		dc.w $E80A, $800, $800,	   0; 12
		dc.w	$A,$1000,$1000,$FFE8; 16
		dc.w	$A,$1800,$1800,	   0; 20
word_8604:	dc.w 4			; DATA XREF: ROM:000085CCo
		dc.w $E80A,    9,    4,$FFE8; 0
		dc.w $E80A, $809, $804,	   0; 4
		dc.w	$A,$1009,$1004,$FFE8; 8
		dc.w	$A,$1809,$1804,	   0; 12
word_8626:	dc.w 4			; DATA XREF: ROM:000085CEo
		dc.w $E80A,  $12,    9,$FFE8; 0
		dc.w $E80A,  $1B,   $D,	   0; 4
		dc.w	$A,$181B,$180D,$FFE8; 8
		dc.w	$A,$1812,$1809,	   0; 12
word_8648:	dc.w 4			; DATA XREF: ROM:000085D0o
		dc.w $E80A, $81B, $80D,$FFE8; 0
		dc.w $E80A, $812, $809,	   0; 4
		dc.w	$A,$1012,$1009,$FFE8; 8
		dc.w	$A,$101B,$100D,	   0; 12
; ---------------------------------------------------------------------------
		nop

Obj17:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj17_Index(pc,d0.w),d1
		jmp	Obj17_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj17_Index:	dc.w loc_8680-Obj17_Index ; DATA XREF: ROM:Obj17_Indexo
					; ROM:0000867Co ...
		dc.w loc_874A-Obj17_Index
		dc.w loc_87AC-Obj17_Index
; ---------------------------------------------------------------------------

loc_8680:				; DATA XREF: ROM:Obj17_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj17,4(a0)
		move.w	#$4398,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#7,$22(a0)
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#8,$19(a0)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		move.b	0(a0),d4
		lea	$28(a0),a2
		moveq	#0,d1
		move.b	(a2),d1
		move.b	#0,(a2)+
		move.w	d1,d0
		lsr.w	#1,d0
		lsl.w	#4,d0
		sub.w	d0,d3
		subq.b	#2,d1
		bcs.s	loc_874A
		moveq	#0,d6

loc_86D4:				; CODE XREF: ROM:loc_8746j
		bsr.w	S1SingleObjectLoad2
		bne.s	loc_874A
		addq.b	#1,$28(a0)
		move.w	a1,d5
		subi.w	#$B000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5	
		move.b	d5,(a2)+
		move.b	#4,$24(a1)
		move.b	d4,0(a1)
		move.w	d2,$C(a1)
		move.w	d3,8(a1)
		move.l	4(a0),4(a1)
		move.w	#$4398,2(a1)
		bsr.w	ModifyA1SpriteAttr_2P
		move.b	#4,1(a1)
		move.b	#3,$18(a1)
		move.b	#8,$19(a1)
		move.b	d6,$3E(a1)
		addq.b	#1,d6
		andi.b	#7,d6
		addi.w	#$10,d3
		cmp.w	8(a0),d3
		bne.s	loc_8746
		move.b	d6,$3E(a0)
		addq.b	#1,d6
		andi.b	#7,d6
		addi.w	#$10,d3
		addq.b	#1,$28(a0)

loc_8746:				; CODE XREF: ROM:00008732j
		dbf	d1,loc_86D4

loc_874A:				; CODE XREF: ROM:000086D0j
					; ROM:000086D8j
					; DATA XREF: ...
		bsr.w	sub_878C
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	loc_8766
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_8766:				; CODE XREF: ROM:0000875Ej
		moveq	#0,d2
		lea	$28(a0),a2
		move.b	(a2)+,d2
		subq.b	#2,d2
		bcs.s	loc_8788

loc_8772:				; CODE XREF: ROM:00008784j
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#v_objspace,d0
		movea.l	d0,a1
		bsr.w	sub_CF3C
		dbf	d2,loc_8772

loc_8788:				; CODE XREF: ROM:00008770j
		bra.w	DeleteObject

; =============== S U B	R O U T	I N E =======================================


sub_878C:				; CODE XREF: ROM:loc_874Ap
					; ROM:loc_87ACp
		move.b	($FFFFFEC1).w,d0
		move.b	#0,$20(a0)
		add.b	$3E(a0),d0
		andi.b	#7,d0
		move.b	d0,$1A(a0)
		bne.s	locret_87AA
		move.b	#$84,$20(a0)

locret_87AA:				; CODE XREF: sub_878C+16j
		rts
; End of function sub_878C

; ---------------------------------------------------------------------------

loc_87AC:				; DATA XREF: ROM:0000867Eo
		bsr.w	sub_878C
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Map_Obj17:	dc.w word_87C4-Map_Obj17 ; DATA	XREF: ROM:00008684o
					; ROM:Map_Obj17o ...
		dc.w word_87CE-Map_Obj17
		dc.w word_87D8-Map_Obj17
		dc.w word_87E2-Map_Obj17
		dc.w word_87EC-Map_Obj17
		dc.w word_87F6-Map_Obj17
		dc.w word_880A-Map_Obj17
		dc.w word_8800-Map_Obj17
word_87C4:	dc.w 1			; DATA XREF: ROM:Map_Obj17o
		dc.w $F001,    0,    0,$FFFC; 0
word_87CE:	dc.w 1			; DATA XREF: ROM:000087B6o
		dc.w $F505,    2,    1,$FFF8; 0
word_87D8:	dc.w 1			; DATA XREF: ROM:000087B8o
		dc.w $F805,    6,    3,$FFF8; 0
word_87E2:	dc.w 1			; DATA XREF: ROM:000087BAo
		dc.w $FB05,   $A,    5,$FFF8; 0
word_87EC:	dc.w 1			; DATA XREF: ROM:000087BCo
		dc.w	 1,   $E,    7,$FFFC; 0
word_87F6:	dc.w 1			; DATA XREF: ROM:000087BEo
		dc.w  $400,  $10,    8,$FFFD; 0
word_8800:	dc.w 1			; DATA XREF: ROM:000087C2o
		dc.w $F400,  $11,    8,$FFFD; 0
word_880A:	dc.w 0			; DATA XREF: ROM:000087C0o
; ---------------------------------------------------------------------------

Obj18:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj18_Index(pc,d0.w),d1
		jmp	Obj18_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj18_Index:	dc.w loc_882C-Obj18_Index ; DATA XREF: ROM:Obj18_Indexo
					; ROM:0000881Co ...
		dc.w loc_88A2-Obj18_Index
		dc.w loc_8908-Obj18_Index
		dc.w loc_88E0-Obj18_Index
Obj18_Conf:	dc.w $2000
		dc.w $2001
		dc.w $2002
		dc.w $4003
		dc.w $3004
; ---------------------------------------------------------------------------

loc_882C:				; DATA XREF: ROM:Obj18_Indexo
		addq.b	#2,$24(a0)
		moveq	#0,d0
		move.b	$28(a0),d0
		lsr.w	#3,d0
		andi.w	#$1E,d0
		lea	Obj18_Conf(pc,d0.w),a2
		move.b	(a2)+,$19(a0)
		move.b	(a2)+,$1A(a0)
		move.w	#$4000,2(a0)
		move.l	#Map_Obj18,4(a0)
		cmpi.b	#3,(v_zone).w
		beq.s	loc_8866
		cmpi.b	#5,(v_zone).w
		bne.s	loc_8874

loc_8866:				; CODE XREF: ROM:0000885Cj
		move.l	#Map_Obj18_EHZ,4(a0)
		move.w	#$4000,2(a0)

loc_8874:				; CODE XREF: ROM:00008864j
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.w	$C(a0),$2C(a0)
		move.w	$C(a0),$34(a0)
		move.w	8(a0),$32(a0)
		move.w	#$80,$26(a0) 
		andi.b	#$F,$28(a0)

loc_88A2:				; DATA XREF: ROM:0000881Co
		move.b	$22(a0),d0
		andi.b	#$18,d0
		bne.s	loc_88B8
		tst.b	$38(a0)
		beq.s	loc_88C4
		subq.b	#4,$38(a0)
		bra.s	loc_88C4
; ---------------------------------------------------------------------------

loc_88B8:				; CODE XREF: ROM:000088AAj
		cmpi.b	#$40,$38(a0) 
		beq.s	loc_88C4
		addq.b	#4,$38(a0)

loc_88C4:				; CODE XREF: ROM:000088B0j
					; ROM:000088B6j ...
		move.w	8(a0),-(sp)
		bsr.w	sub_8926
		bsr.w	sub_890C
		moveq	#0,d1
		move.b	$19(a0),d1
		moveq	#8,d3
		move.w	(sp)+,d4
		bsr.w	sub_F78A
		bra.s	loc_88E8
; ---------------------------------------------------------------------------

loc_88E0:				; DATA XREF: ROM:00008820o
		bsr.w	sub_8926
		bsr.w	sub_890C

loc_88E8:				; CODE XREF: ROM:000088DEj
		tst.w	(f_2player).w
		beq.s	loc_88F2
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_88F2:				; CODE XREF: ROM:000088ECj
		move.w	$32(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.s	loc_8908
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_8908:				; CODE XREF: ROM:00008902j
					; DATA XREF: ROM:0000881Eo
		bra.w	DeleteObject

; =============== S U B	R O U T	I N E =======================================


sub_890C:				; CODE XREF: ROM:000088CCp
					; ROM:000088E4p
		move.b	$38(a0),d0
		bsr.w	CalcSine
		move.w	#$400,d1
		muls.w	d1,d0
		swap	d0
		add.w	$2C(a0),d0
		move.w	d0,$C(a0)
		rts
; End of function sub_890C


; =============== S U B	R O U T	I N E =======================================


sub_8926:				; CODE XREF: ROM:000088C8p
					; ROM:loc_88E0p
		moveq	#0,d0
		move.b	$28(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	off_893A(pc,d0.w),d1
		jmp	off_893A(pc,d1.w)
; End of function sub_8926

; ---------------------------------------------------------------------------
off_893A:	dc.w locret_8956-off_893A ; DATA XREF: ROM:off_893Ao
					; ROM:0000893Co ...
		dc.w loc_8968-off_893A
		dc.w loc_89AE-off_893A
		dc.w loc_89C6-off_893A
		dc.w loc_89EE-off_893A
		dc.w loc_8958-off_893A
		dc.w loc_899E-off_893A
		dc.w loc_8A5C-off_893A
		dc.w loc_8A88-off_893A
		dc.w locret_8956-off_893A
		dc.w loc_8AA0-off_893A
		dc.w loc_8ABA-off_893A
		dc.w loc_8990-off_893A
		dc.w loc_8980-off_893A
; ---------------------------------------------------------------------------

locret_8956:				; DATA XREF: ROM:off_893Ao
					; ROM:0000894Co
		rts
; ---------------------------------------------------------------------------

loc_8958:				; DATA XREF: ROM:00008944o
		move.w	$32(a0),d0
		move.b	$26(a0),d1
		neg.b	d1
		addi.b	#$40,d1	
		bra.s	loc_8974
; ---------------------------------------------------------------------------

loc_8968:				; DATA XREF: ROM:0000893Co
		move.w	$32(a0),d0
		move.b	$26(a0),d1
		subi.b	#$40,d1	

loc_8974:				; CODE XREF: ROM:00008966j
		ext.w	d1
		add.w	d1,d0
		move.w	d0,8(a0)
		bra.w	loc_8AD2
; ---------------------------------------------------------------------------

loc_8980:				; DATA XREF: ROM:00008954o
		move.w	$34(a0),d0
		move.b	($FFFFFE6C).w,d1
		neg.b	d1
		addi.b	#$30,d1	
		bra.s	loc_89BA
; ---------------------------------------------------------------------------

loc_8990:				; DATA XREF: ROM:00008952o
		move.w	$34(a0),d0
		move.b	($FFFFFE6C).w,d1
		subi.b	#$30,d1	
		bra.s	loc_89BA
; ---------------------------------------------------------------------------

loc_899E:				; DATA XREF: ROM:00008946o
		move.w	$34(a0),d0
		move.b	$26(a0),d1
		neg.b	d1
		addi.b	#$40,d1	
		bra.s	loc_89BA
; ---------------------------------------------------------------------------

loc_89AE:				; DATA XREF: ROM:0000893Eo
		move.w	$34(a0),d0
		move.b	$26(a0),d1
		subi.b	#$40,d1	

loc_89BA:				; CODE XREF: ROM:0000898Ej
					; ROM:0000899Cj ...
		ext.w	d1
		add.w	d1,d0
		move.w	d0,$2C(a0)
		bra.w	loc_8AD2
; ---------------------------------------------------------------------------

loc_89C6:				; DATA XREF: ROM:00008940o
		tst.w	$3A(a0)
		bne.s	loc_89DC
		btst	#3,$22(a0)
		beq.s	locret_89DA
		move.w	#$1E,$3A(a0)

locret_89DA:				; CODE XREF: ROM:000089D2j
					; ROM:000089E0j
		rts
; ---------------------------------------------------------------------------

loc_89DC:				; CODE XREF: ROM:000089CAj
		subq.w	#1,$3A(a0)
		bne.s	locret_89DA
		move.w	#$20,$3A(a0) 
		addq.b	#1,$28(a0)
		rts
; ---------------------------------------------------------------------------

loc_89EE:				; DATA XREF: ROM:00008942o
		tst.w	$3A(a0)
		beq.s	loc_8A2E
		subq.w	#1,$3A(a0)
		bne.s	loc_8A2E
		btst	#3,$22(a0)
		beq.s	loc_8A28
		lea	(v_objspace).w,a1
		bset	#1,$22(a1)
		bclr	#3,$22(a1)
		move.b	#2,$24(a1)
		bclr	#3,$22(a0)
		clr.b	$25(a0)
		move.w	$12(a0),$12(a1)

loc_8A28:				; CODE XREF: ROM:00008A00j
		move.b	#6,$24(a0)

loc_8A2E:				; CODE XREF: ROM:000089F2j
					; ROM:000089F8j
		move.l	$2C(a0),d3
		move.w	$12(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d3,$2C(a0)
		addi.w	#$38,$12(a0) 
		move.w	($FFFFEECE).w,d0
		addi.w	#$E0,d0	
		cmp.w	$2C(a0),d0
		bcc.s	locret_8A5A
		move.b	#4,$24(a0)

locret_8A5A:				; CODE XREF: ROM:00008A52j
		rts
; ---------------------------------------------------------------------------

loc_8A5C:				; DATA XREF: ROM:00008948o
		tst.w	$3A(a0)
		bne.s	loc_8A7C
		lea	($FFFFF7E0).w,a2
		moveq	#0,d0
		move.b	$28(a0),d0
		lsr.w	#4,d0
		tst.b	(a2,d0.w)
		beq.s	locret_8A7A
		move.w	#$3C,$3A(a0) 

locret_8A7A:				; CODE XREF: ROM:00008A72j
					; ROM:00008A80j
		rts
; ---------------------------------------------------------------------------

loc_8A7C:				; CODE XREF: ROM:00008A60j
		subq.w	#1,$3A(a0)
		bne.s	locret_8A7A
		addq.b	#1,$28(a0)
		rts
; ---------------------------------------------------------------------------

loc_8A88:				; DATA XREF: ROM:0000894Ao
		subq.w	#2,$2C(a0)
		move.w	$34(a0),d0
		subi.w	#$200,d0
		cmp.w	$2C(a0),d0
		bne.s	locret_8A9E
		clr.b	$28(a0)

locret_8A9E:				; CODE XREF: ROM:00008A98j
		rts
; ---------------------------------------------------------------------------

loc_8AA0:				; DATA XREF: ROM:0000894Eo
		move.w	$34(a0),d0
		move.b	$26(a0),d1
		subi.b	#$40,d1	
		ext.w	d1
		asr.w	#1,d1
		add.w	d1,d0
		move.w	d0,$2C(a0)
		bra.w	loc_8AD2
; ---------------------------------------------------------------------------

loc_8ABA:				; DATA XREF: ROM:00008950o
		move.w	$34(a0),d0
		move.b	$26(a0),d1
		neg.b	d1
		addi.b	#$40,d1	
		ext.w	d1
		asr.w	#1,d1
		add.w	d1,d0
		move.w	d0,$2C(a0)

loc_8AD2:				; CODE XREF: ROM:0000897Cj
					; ROM:000089C2j ...
		move.b	($FFFFFE78).w,$26(a0)
		rts
; ---------------------------------------------------------------------------
Map_Obj18x:	dc.w word_8ADE-Map_Obj18x ; DATA XREF: ROM:Map_Obj18xo
					; ROM:00008ADCo
		dc.w word_8AF0-Map_Obj18x
word_8ADE:	dc.w 2			; DATA XREF: ROM:Map_Obj18xo
		dc.w $F40B,  $3C,  $1E,$FFE8; 0
		dc.w $F40B,  $48,  $24,	   0; 4
word_8AF0:	dc.w $A			; DATA XREF: ROM:00008ADCo
		dc.w $F40F,  $CA,  $65,$FFE0; 0
		dc.w  $40F,  $DA,  $6D,$FFE0; 4
		dc.w $240F,  $DA,  $6D,$FFE0; 8
		dc.w $440F,  $DA,  $6D,$FFE0; 12
		dc.w $640F,  $DA,  $6D,$FFE0; 16
		dc.w $F40F, $8CA, $865,	   0; 20
		dc.w  $40F, $8DA, $86D,	   0; 24
		dc.w $240F, $8DA, $86D,	   0; 28
		dc.w $440F, $8DA, $86D,	   0; 32
		dc.w $640F, $8DA, $86D,	   0; 36
Map_Obj18:	dc.w word_8B46-Map_Obj18 ; DATA	XREF: ROM:0000884Eo
					; ROM:Map_Obj18o ...
		dc.w word_8B68-Map_Obj18
word_8B46:	dc.w 4			; DATA XREF: ROM:Map_Obj18o
		dc.w $F40B,  $3B,  $1D,$FFE0; 0
		dc.w $F407,  $3F,  $1F,$FFF8; 4
		dc.w $F407,  $3F,  $1F,	   8; 8
		dc.w $F403,  $47,  $23,	 $18; 12
word_8B68:	dc.w $A			; DATA XREF: ROM:00008B44o
		dc.w $F40F,  $C5,  $62,$FFE0; 0
		dc.w  $40F,  $D5,  $6A,$FFE0; 4
		dc.w $240F,  $D5,  $6A,$FFE0; 8
		dc.w $440F,  $D5,  $6A,$FFE0; 12
		dc.w $640F,  $D5,  $6A,$FFE0; 16
		dc.w $F40F, $8C5, $862,	   0; 20
		dc.w  $40F, $8D5, $86A,	   0; 24
		dc.w $240F, $8D5, $86A,	   0; 28
		dc.w $440F, $8D5, $86A,	   0; 32
		dc.w $640F, $8D5, $86A,	   0; 36
		dc.w	 2,    3,$F60B,	 $49; 40
		dc.w   $24,$FFE0,$F607,	 $51; 44
		dc.w   $28,$FFF8,$F60B,	 $55; 48
		dc.w   $2A,    8,    2,	   2; 52
		dc.w $F80F,  $21,  $10,$FFE0; 56
		dc.w $F80F,  $21,  $10,	   0; 60
Map_Obj18_EHZ:	dc.w word_8BEE-Map_Obj18_EHZ ; DATA XREF: ROM:loc_8866o
					; ROM:Map_Obj18_EHZo ...
		dc.w word_8C00-Map_Obj18_EHZ
word_8BEE:	dc.w 2			; DATA XREF: ROM:Map_Obj18_EHZo
		dc.w $F40F,  $56,  $2B,$FFE0; 0
		dc.w $F40F, $856, $82B,	   0; 4
word_8C00:	dc.w 8			; DATA XREF: ROM:00008BECo
		dc.w $F407,   $A,    5,$FFE0; 0
		dc.w $F40D,  $12,    9,$FFF0; 4
		dc.w  $40D,  $1A,   $D,$FFF0; 8
		dc.w $F407,  $22,  $11,	 $10; 12
		dc.w $140F,  $2A,  $15,$FFE0; 16
		dc.w $140F, $82A, $815,	   0; 20
		dc.w $340F,  $3A,  $1D,$FFE0; 24
		dc.w $340F, $83A, $81D,	   0; 28
; ---------------------------------------------------------------------------
		nop

Obj1A:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj1A_Index(pc,d0.w),d1
		jmp	Obj1A_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj1A_Index:	dc.w loc_8C58-Obj1A_Index ; DATA XREF: ROM:Obj1A_Indexo
					; ROM:00008C54o ...
		dc.w loc_8CCA-Obj1A_Index
		dc.w loc_8D02-Obj1A_Index
; ---------------------------------------------------------------------------

loc_8C58:				; DATA XREF: ROM:Obj1A_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj1A,4(a0)
		move.w	#$4000,2(a0)
		bsr.w	ModifySpriteAttr_2P
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#7,$38(a0)
		move.b	$28(a0),$1A(a0)
		cmpi.b	#4,(v_zone).w
		bne.s	loc_8CB0
		move.l	#Map_Obj1A_HPZ,4(a0)
		move.w	#$434A,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#$30,$19(a0) 
		move.l	#Obj1A_Conf_HPZ,$3C(a0)
		bra.s	loc_8CCA
; ---------------------------------------------------------------------------

loc_8CB0:				; CODE XREF: ROM:00008C8Cj
		move.l	#Obj1A_Conf,$3C(a0)
		move.b	#$34,$19(a0) 
		move.b	#$38,$16(a0) 
		bset	#4,1(a0)

loc_8CCA:				; CODE XREF: ROM:00008CAEj
					; DATA XREF: ROM:00008C54o
		tst.b	$3A(a0)
		beq.s	loc_8CDC
		tst.b	$38(a0)
		beq.w	loc_8E58
		subq.b	#1,$38(a0)

loc_8CDC:				; CODE XREF: ROM:00008CCEj
		move.b	$22(a0),d0
		andi.b	#$18,d0
		beq.s	sub_8CEC
		move.b	#1,$3A(a0)

; =============== S U B	R O U T	I N E =======================================


sub_8CEC:				; CODE XREF: ROM:00008CE4j
					; ROM:loc_8D16p

; FUNCTION CHUNK AT 0000CE5A SIZE 00000038 BYTES
; FUNCTION CHUNK AT 0000CF3A SIZE 00000002 BYTES

		moveq	#0,d1
		move.b	$19(a0),d1
		movea.l	$3C(a0),a2
		move.w	8(a0),d4
		bsr.w	sub_F7DC
		bra.w	MarkObjGone
; End of function sub_8CEC

; ---------------------------------------------------------------------------

loc_8D02:				; DATA XREF: ROM:00008C56o
		tst.b	$38(a0)
		beq.s	loc_8D46
		tst.b	$3A(a0)
		bne.s	loc_8D16
		subq.b	#1,$38(a0)
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_8D16:				; CODE XREF: ROM:00008D0Cj
		bsr.w	sub_8CEC
		subq.b	#1,$38(a0)
		bne.s	locret_8D44
		lea	(v_objspace).w,a1
		bsr.s	sub_8D2A
		lea	(v_objspace+$40).w,a1

; =============== S U B	R O U T	I N E =======================================


sub_8D2A:				; CODE XREF: ROM:00008D24p
		btst	#3,$22(a1)
		beq.s	locret_8D44
		bclr	#3,$22(a1)
		bclr	#5,$22(a1)
		move.b	#1,$1D(a1)

locret_8D44:				; CODE XREF: ROM:00008D1Ej sub_8D2A+6j
		rts
; End of function sub_8D2A

; ---------------------------------------------------------------------------

loc_8D46:				; CODE XREF: ROM:00008D06j
		bsr.w	ObjectFall
		tst.b	1(a0)
		bpl.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

S1Obj_53:				; leftover object from Sonic 1
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	S1Obj_53_Index(pc,d0.w),d1
		jmp	S1Obj_53_Index(pc,d1.w)
; ---------------------------------------------------------------------------
S1Obj_53_Index:	dc.w loc_8D6A-S1Obj_53_Index ; DATA XREF: ROM:S1Obj_53_Indexo
					; ROM:00008D66o ...
		dc.w loc_8DB4-S1Obj_53_Index
		dc.w loc_8DEA-S1Obj_53_Index
; ---------------------------------------------------------------------------

loc_8D6A:				; DATA XREF: ROM:S1Obj_53_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_S1Obj53,4(a0)
		move.w	#$42B8,2(a0)
		cmpi.b	#3,(v_zone).w
		bne.s	loc_8D8E
		move.w	#$44E0,2(a0)
		addq.b	#2,$1A(a0)

loc_8D8E:				; CODE XREF: ROM:00008D82j
		cmpi.b	#5,(v_zone).w
		bne.s	loc_8D9C
		move.w	#$43F5,2(a0)

loc_8D9C:				; CODE XREF: ROM:00008D94j
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#7,$38(a0)
		move.b	#$44,$19(a0) 

loc_8DB4:				; DATA XREF: ROM:00008D66o
		tst.b	$3A(a0)
		beq.s	loc_8DC6
		tst.b	$38(a0)
		beq.w	loc_8E3E
		subq.b	#1,$38(a0)

loc_8DC6:				; CODE XREF: ROM:00008DB8j
		move.b	$22(a0),d0
		andi.b	#$18,d0
		beq.s	sub_8DD6
		move.b	#1,$3A(a0)

; =============== S U B	R O U T	I N E =======================================


sub_8DD6:				; CODE XREF: ROM:00008DCEj
					; ROM:loc_8DFEp
		move.w	#$20,d1	
		move.w	#8,d3
		move.w	8(a0),d4
		bsr.w	sub_F78A
		bra.w	MarkObjGone
; End of function sub_8DD6

; ---------------------------------------------------------------------------

loc_8DEA:				; DATA XREF: ROM:00008D68o
		tst.b	$38(a0)
		beq.s	loc_8E2E
		tst.b	$3A(a0)
		bne.s	loc_8DFE
		subq.b	#1,$38(a0)
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_8DFE:				; CODE XREF: ROM:00008DF4j
		bsr.w	sub_8DD6
		subq.b	#1,$38(a0)
		bne.s	locret_8E2C
		lea	(v_objspace).w,a1
		bsr.s	sub_8E12
		lea	(v_objspace+$40).w,a1

; =============== S U B	R O U T	I N E =======================================


sub_8E12:				; CODE XREF: ROM:00008E0Cp
		btst	#3,$22(a1)
		beq.s	locret_8E2C
		bclr	#3,$22(a1)
		bclr	#5,$22(a1)
		move.b	#1,$1D(a1)

locret_8E2C:				; CODE XREF: ROM:00008E06j sub_8E12+6j
		rts
; End of function sub_8E12

; ---------------------------------------------------------------------------

loc_8E2E:				; CODE XREF: ROM:00008DEEj
		bsr.w	ObjectFall
		tst.b	1(a0)
		bpl.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_8E3E:				; CODE XREF: ROM:00008DBEj
		lea	(byte_8F17).l,a4
		btst	#0,$28(a0)
		beq.s	loc_8E52
		lea	(byte_8F1F).l,a4

loc_8E52:				; CODE XREF: ROM:00008E4Aj
		addq.b	#1,$1A(a0)
		bra.s	loc_8E70
; ---------------------------------------------------------------------------

loc_8E58:				; CODE XREF: ROM:00008CD4j
		lea	(byte_8EF2).l,a4
		cmpi.b	#4,(v_zone).w
		bne.s	loc_8E6C
		lea	(byte_8F0B).l,a4

loc_8E6C:				; CODE XREF: ROM:00008E64j
		addq.b	#2,$1A(a0)

loc_8E70:				; CODE XREF: ROM:00008E56j
		moveq	#0,d0
		move.b	$1A(a0),d0
		add.w	d0,d0
		movea.l	4(a0),a3
		adda.w	(a3,d0.w),a3
		move.w	(a3)+,d1
		subq.w	#1,d1
		bset	#5,1(a0)
		move.b	0(a0),d4
		move.b	1(a0),d5
		movea.l	a0,a1
		bra.s	loc_8E9E
; ---------------------------------------------------------------------------

loc_8E96:				; CODE XREF: ROM:loc_8EE0j
		bsr.w	SingleObjectLoad
		bne.s	loc_8EE4
		addq.w	#8,a3

loc_8E9E:				; CODE XREF: ROM:00008E94j
		move.b	#4,$24(a1)
		move.b	d4,0(a1)
		move.l	a3,4(a1)
		move.b	d5,1(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	2(a0),2(a1)
		move.b	$18(a0),$18(a1)
		move.b	$19(a0),$19(a1)
		move.b	$16(a0),$16(a1)
		move.b	(a4)+,$38(a1)
		cmpa.l	a0,a1
		bcc.s	loc_8EE0
		bsr.w	DisplaySprite1

loc_8EE0:				; CODE XREF: ROM:00008EDAj
		dbf	d1,loc_8E96

loc_8EE4:				; CODE XREF: ROM:00008E9Aj
		bsr.w	DisplaySprite
		move.w	#sfx_Collapse,d0	; "?"
		jmp	(PlaySound_Special).l
; ---------------------------------------------------------------------------
byte_8EF2:	dc.b $1C,$18,$14,$10	; 0 ; DATA XREF: ROM:loc_8E58o
		dc.b $1A,$16,$12, $E	; 4
		dc.b  $A,  6,$18,$14	; 8
		dc.b $10, $C,  8,  4	; 12
		dc.b $16,$12, $E, $A	; 16
		dc.b   6,  2,$14,$10	; 20
		dc.b  $C		; 24
byte_8F0B:	dc.b $18,$1C,$20,$1E	; 0 ; DATA XREF: ROM:00008E66o
		dc.b $1A,$16,  6, $E	; 4
		dc.b $14,$12, $A,  2	; 8
byte_8F17:	dc.b $1E,$16, $E,  6	; 0 ; DATA XREF: ROM:loc_8E3Eo
		dc.b $1A,$12, $A,  2	; 4
byte_8F1F:	dc.b $16,$1E,$1A,$12	; 0 ; DATA XREF: ROM:00008E4Co
		dc.b   6, $E, $A,  2	; 4
		dc.b   0		; 8
Obj1A_Conf:	dc.b $20,$20,$20,$20	; 0 ; DATA XREF: ROM:loc_8CB0o
		dc.b $20,$20,$20,$20	; 4
		dc.b $21,$21,$22,$22	; 8
		dc.b $23,$23,$24,$24	; 12
		dc.b $25,$25,$26,$26	; 16
		dc.b $27,$27,$28,$28	; 20
		dc.b $29,$29,$2A,$2A	; 24
		dc.b $2B,$2B,$2C,$2C	; 28
		dc.b $2D,$2D,$2E,$2E	; 32
		dc.b $2F,$2F,$30,$30	; 36
		dc.b $30,$30,$30,$30	; 40
		dc.b $30,$30,$30,$30	; 44
Map_Obj1A:	dc.w word_8F60-Map_Obj1A ; DATA	XREF: ROM:00008C5Co
					; ROM:Map_Obj1Ao ...
		dc.w word_8FE2-Map_Obj1A
		dc.w word_9064-Map_Obj1A
		dc.w word_912E-Map_Obj1A
word_8F60:	dc.w $10		; DATA XREF: ROM:Map_Obj1Ao
		dc.w $C80E,  $57,  $2B,	 $10; 0
		dc.w $D00D,  $63,  $31,$FFF0; 4
		dc.w $E00D,  $6B,  $35,	 $10; 8
		dc.w $E00D,  $73,  $39,$FFF0; 12
		dc.w $D806,  $7B,  $3D,$FFE0; 16
		dc.w $D806,  $81,  $40,$FFD0; 20
		dc.w $F00D,  $87,  $43,	 $10; 24
		dc.w $F00D,  $8F,  $47,$FFF0; 28
		dc.w $F005,  $97,  $4B,$FFE0; 32
		dc.w $F005,  $9B,  $4D,$FFD0; 36
		dc.w	$D,  $9F,  $4F,	 $10; 40
		dc.w	 5,  $A7,  $53,	   0; 44
		dc.w	$D,  $AB,  $55,$FFE0; 48
		dc.w	 5,  $B3,  $59,$FFD0; 52
		dc.w $100D,  $AB,  $55,	 $10; 56
		dc.w $1005,  $B7,  $5B,	   0; 60
word_8FE2:	dc.w $10		; DATA XREF: ROM:00008F5Ao
		dc.w $C80E,  $57,  $2B,	 $10; 0
		dc.w $D00D,  $63,  $31,$FFF0; 4
		dc.w $E00D,  $6B,  $35,	 $10; 8
		dc.w $E00D,  $73,  $39,$FFF0; 12
		dc.w $D806,  $7B,  $3D,$FFE0; 16
		dc.w $D806,  $BB,  $5D,$FFD0; 20
		dc.w $F00D,  $87,  $43,	 $10; 24
		dc.w $F00D,  $8F,  $47,$FFF0; 28
		dc.w $F005,  $97,  $4B,$FFE0; 32
		dc.w $F005,  $C1,  $60,$FFD0; 36
		dc.w	$D,  $9F,  $4F,	 $10; 40
		dc.w	 5,  $A7,  $53,	   0; 44
		dc.w	$D,  $AB,  $55,$FFE0; 48
		dc.w	 5,  $B7,  $5B,$FFD0; 52
		dc.w $100D,  $AB,  $55,	 $10; 56
		dc.w $1005,  $B7,  $5B,	   0; 60
word_9064:	dc.w $19		; DATA XREF: ROM:00008F5Co
		dc.w $C806,  $5D,  $2E,	 $20; 0
		dc.w $C806,  $57,  $2B,	 $10; 4
		dc.w $D005,  $67,  $33,	   0; 8
		dc.w $D005,  $63,  $31,$FFF0; 12
		dc.w $E005,  $6F,  $37,	 $20; 16
		dc.w $E005,  $6B,  $35,	 $10; 20
		dc.w $E005,  $77,  $3B,	   0; 24
		dc.w $E005,  $73,  $39,$FFF0; 28
		dc.w $D806,  $7B,  $3D,$FFE0; 32
		dc.w $D806,  $81,  $40,$FFD0; 36
		dc.w $F005,  $8B,  $45,	 $20; 40
		dc.w $F005,  $87,  $43,	 $10; 44
		dc.w $F005,  $93,  $49,	   0; 48
		dc.w $F005,  $8F,  $47,$FFF0; 52
		dc.w $F005,  $97,  $4B,$FFE0; 56
		dc.w $F005,  $9B,  $4D,$FFD0; 60
		dc.w	 5,  $8B,  $45,	 $20; 64
		dc.w	 5,  $8B,  $45,	 $10; 68
		dc.w	 5,  $A7,  $53,	   0; 72
		dc.w	 5,  $AB,  $55,$FFF0; 76
		dc.w	 5,  $AB,  $55,$FFE0; 80
		dc.w	 5,  $B3,  $59,$FFD0; 84
		dc.w $1005,  $AB,  $55,	 $20; 88
		dc.w $1005,  $AB,  $55,	 $10; 92
		dc.w $1005,  $B7,  $5B,	   0; 96
word_912E:	dc.w $19		; DATA XREF: ROM:00008F5Eo
		dc.w $C806,  $5D,  $2E,	 $20; 0
		dc.w $C806,  $57,  $2B,	 $10; 4
		dc.w $D005,  $67,  $33,	   0; 8
		dc.w $D005,  $63,  $31,$FFF0; 12
		dc.w $E005,  $6F,  $37,	 $20; 16
		dc.w $E005,  $6B,  $35,	 $10; 20
		dc.w $E005,  $77,  $3B,	   0; 24
		dc.w $E005,  $73,  $39,$FFF0; 28
		dc.w $D806,  $7B,  $3D,$FFE0; 32
		dc.w $D806,  $BB,  $5D,$FFD0; 36
		dc.w $F005,  $8B,  $45,	 $20; 40
		dc.w $F005,  $87,  $43,	 $10; 44
		dc.w $F005,  $93,  $49,	   0; 48
		dc.w $F005,  $8F,  $47,$FFF0; 52
		dc.w $F005,  $97,  $4B,$FFE0; 56
		dc.w $F005,  $C1,  $60,$FFD0; 60
		dc.w	 5,  $8B,  $45,	 $20; 64
		dc.w	 5,  $8B,  $45,	 $10; 68
		dc.w	 5,  $A7,  $53,	   0; 72
		dc.w	 5,  $AB,  $55,$FFF0; 76
		dc.w	 5,  $AB,  $55,$FFE0; 80
		dc.w	 5,  $B7,  $5B,$FFD0; 84
		dc.w $1005,  $AB,  $55,	 $20; 88
		dc.w $1005,  $AB,  $55,	 $10; 92
		dc.w $1005,  $B7,  $5B,	   0; 96
Map_S1Obj53:	dc.w word_9200-Map_S1Obj53 ; DATA XREF:	ROM:00008D6Eo
					; ROM:Map_S1Obj53o ...
		dc.w word_9222-Map_S1Obj53
		dc.w word_9264-Map_S1Obj53
		dc.w word_9286-Map_S1Obj53
word_9200:	dc.w 4			; DATA XREF: ROM:Map_S1Obj53o
		dc.w $F80D,    0,    0,$FFE0; 0
		dc.w  $80D,    0,    0,$FFE0; 4
		dc.w $F80D,    0,    0,	   0; 8
		dc.w  $80D,    0,    0,	   0; 12
word_9222:	dc.w 8			; DATA XREF: ROM:000091FAo
		dc.w $F805,    0,    0,$FFE0; 0
		dc.w $F805,    0,    0,$FFF0; 4
		dc.w $F805,    0,    0,	   0; 8
		dc.w $F805,    0,    0,	 $10; 12
		dc.w  $805,    0,    0,$FFE0; 16
		dc.w  $805,    0,    0,$FFF0; 20
		dc.w  $805,    0,    0,	   0; 24
		dc.w  $805,    0,    0,	 $10; 28
word_9264:	dc.w 4			; DATA XREF: ROM:000091FCo
		dc.w $F80D,    0,    0,$FFE0; 0
		dc.w  $80D,    8,    4,$FFE0; 4
		dc.w $F80D,    0,    0,	   0; 8
		dc.w  $80D,    8,    4,	   0; 12
word_9286:	dc.w 8			; DATA XREF: ROM:000091FEo
		dc.w $F805,    0,    0,$FFE0; 0
		dc.w $F805,    4,    2,$FFF0; 4
		dc.w $F805,    0,    0,	   0; 8
		dc.w $F805,    4,    2,	 $10; 12
		dc.w  $805,    8,    4,$FFE0; 16
		dc.w  $805,   $C,    6,$FFF0; 20
		dc.w  $805,    8,    4,	   0; 24
		dc.w  $805,   $C,    6,	 $10; 28
Obj1A_Conf_HPZ:	dc.b $10,$10,$10,$10	; 0 ; DATA XREF: ROM:00008CA6o
		dc.b $10,$10,$10,$10	; 4
		dc.b $10,$10,$10,$10	; 8
		dc.b $10,$10,$10,$10	; 12
		dc.b $10,$10,$10,$10	; 16
		dc.b $10,$10,$10,$10	; 20
		dc.b $10,$10,$10,$10	; 24
		dc.b $10,$10,$10,$10	; 28
		dc.b $10,$10,$10,$10	; 32
		dc.b $10,$10,$10,$10	; 36
		dc.b $10,$10,$10,$10	; 40
		dc.b $10,$10,$10,$10	; 44
Map_Obj1A_HPZ:	dc.w word_92FE-Map_Obj1A_HPZ ; DATA XREF: ROM:00008C8Eo
					; ROM:Map_Obj1A_HPZo ...
		dc.w word_9340-Map_Obj1A_HPZ
		dc.w word_9340-Map_Obj1A_HPZ
word_92FE:	dc.w 8			; DATA XREF: ROM:Map_Obj1A_HPZo
		dc.w $F00D,    0,    0,$FFD0; 0
		dc.w	$D,    8,    4,$FFD0; 4
		dc.w $F005,    4,    2,$FFF0; 8
		dc.w $F005, $804, $802,	   0; 12
		dc.w	 5,   $C,    6,$FFF0; 16
		dc.w	 5, $80C, $806,	   0; 20
		dc.w $F00D, $800, $800,	 $10; 24
		dc.w	$D, $808, $804,	 $10; 28
word_9340:	dc.w $C			; DATA XREF: ROM:000092FAo
					; ROM:000092FCo
		dc.w $F005,    0,    0,$FFD0; 0
		dc.w $F005,    4,    2,$FFE0; 4
		dc.w $F005,    4,    2,$FFF0; 8
		dc.w $F005, $804, $802,	   0; 12
		dc.w $F005, $804, $802,	 $10; 16
		dc.w $F005, $800, $800,	 $20; 20
		dc.w	 5,    8,    4,$FFD0; 24
		dc.w	 5,   $C,    6,$FFE0; 28
		dc.w	 5,   $C,    6,$FFF0; 32
		dc.w	 5, $80C, $806,	   0; 36
		dc.w	 5, $80C, $806,	 $10; 40
		dc.w	 5, $808, $804,	 $20; 44
; ---------------------------------------------------------------------------
		nop

Obj1C:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj1C_Index(pc,d0.w),d1
		jmp	Obj1C_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj1C_Index:	dc.w loc_93F4-Obj1C_Index ; DATA XREF: ROM:Obj1C_Indexo
					; ROM:000093B4o ...
		dc.w loc_9442-Obj1C_Index
		dc.w loc_9464-Obj1C_Index
Obj1C_Conf:	dc.l Map_Obj11_HPZ
		dc.w $6300
		dc.b   3,  4,  1,  0	; 0
		dc.l Map_Obj1C_01
		dc.w $E35A
		dc.b   0,$10,  1,  0	; 0
		dc.l Map_Obj11_EHZ
		dc.w $43C6
		dc.b   1,  4,  1,  0	; 0
		dc.l Map_Obj11
		dc.w $44C6
		dc.b   1,$10,  1,  0	; 0
		dc.l Map_Obj16
		dc.w $43E6
		dc.b   1,  8,  4,  0	; 0
		dc.l Map_Obj16
		dc.w $43E6
		dc.b   2,  8,  4,  0	; 0
; ---------------------------------------------------------------------------

loc_93F4:				; DATA XREF: ROM:Obj1C_Indexo
		addq.b	#2,$24(a0)
		move.b	$28(a0),d0
		andi.w	#$F,d0
		mulu.w	#$A,d0
		lea	Obj1C_Conf(pc,d0.w),a1
		move.l	(a1)+,4(a0)
		move.w	(a1)+,2(a0)
		bsr.w	ModifySpriteAttr_2P
		ori.b	#4,1(a0)
		move.b	(a1)+,$1A(a0)
		move.b	(a1)+,$19(a0)
		move.b	(a1)+,$18(a0)
		move.b	(a1)+,$20(a0)
		move.b	$28(a0),d0
		andi.w	#$F0,d0	; "?"
		beq.s	loc_9442
		addq.b	#2,$24(a0)
		lsr.b	#4,d0
		subq.b	#1,d0
		move.b	d0,$1C(a0)
		bra.s	loc_9464
; ---------------------------------------------------------------------------

loc_9442:				; CODE XREF: ROM:00009432j
					; DATA XREF: ROM:000093B4o
		tst.w	(f_2player).w
		beq.s	loc_944C
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_944C:				; CODE XREF: ROM:00009446j
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_9464:				; CODE XREF: ROM:00009440j
					; DATA XREF: ROM:000093B6o
		lea	(Ani_Obj1C).l,a1
		bsr.w	AnimateSprite
		tst.w	(f_2player).w
		beq.s	loc_9478
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_9478:				; CODE XREF: ROM:00009472j
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Ani_Obj1C:	dc.w byte_9494-Ani_Obj1C ; DATA	XREF: ROM:loc_9464o
					; ROM:Ani_Obj1Co ...
		dc.w byte_949C-Ani_Obj1C
byte_9494:	dc.b   8,  3,  3,  4,  5,  5,  4,$FF; 0	; DATA XREF: ROM:Ani_Obj1Co
byte_949C:	dc.b   5,  0,  0,  0,  1,  2,  3,  3; 0	; DATA XREF: ROM:00009492o
		dc.b   2,  1,  2,  3,  3,  1,$FF,  0; 8
Map_Obj1C_01:	dc.w word_94B4-Map_Obj1C_01 ; DATA XREF: ROM:000093C2o
					; ROM:Map_Obj1C_01o ...
		dc.w word_94BE-Map_Obj1C_01
		dc.w word_94C8-Map_Obj1C_01
		dc.w word_94DA-Map_Obj1C_01
word_94B4:	dc.w 1			; DATA XREF: ROM:Map_Obj1C_01o
		dc.w $F40A,    0,    0,$FFF4; 0
word_94BE:	dc.w 1			; DATA XREF: ROM:000094AEo
		dc.w $F40A,    9,    4,$FFF4; 0
word_94C8:	dc.w 2			; DATA XREF: ROM:000094B0o
		dc.w $F00D,  $12,    9,$FFF0; 0
		dc.w	$D,$1812,$1809,$FFF0; 4
word_94DA:	dc.w 2			; DATA XREF: ROM:000094B2o
		dc.w $F00D,  $1A,   $D,$FFF0; 0
		dc.w	$D,$181A,$180D,$FFF0; 4
; ---------------------------------------------------------------------------

Obj2A:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj2A_Index(pc,d0.w),d1
		jmp	Obj2A_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj2A_Index:	dc.w loc_94FE-Obj2A_Index ; DATA XREF: ROM:Obj2A_Indexo
					; ROM:000094FCo
		dc.w loc_9526-Obj2A_Index
; ---------------------------------------------------------------------------

loc_94FE:				; DATA XREF: ROM:Obj2A_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj2A,4(a0)
		move.w	#$42E8,2(a0)
		bsr.w	ModifySpriteAttr_2P
		ori.b	#4,1(a0)
		move.b	#8,$19(a0)
		move.b	#4,$18(a0)

loc_9526:				; DATA XREF: ROM:000094FCo
		move.w	#$40,d1	
		clr.b	$1C(a0)
		move.w	(v_objspace+8).w,d0
		add.w	d1,d0
		cmp.w	8(a0),d0
		bcs.s	loc_9564
		sub.w	d1,d0
		sub.w	d1,d0
		cmp.w	8(a0),d0
		bcc.s	loc_9564
		add.w	d1,d0
		cmp.w	8(a0),d0
		bcc.s	loc_9556
		btst	#0,$22(a0)
		bne.s	loc_9564
		bra.s	loc_955E
; ---------------------------------------------------------------------------

loc_9556:				; CODE XREF: ROM:0000954Aj
		btst	#0,$22(a0)
		beq.s	loc_9564

loc_955E:				; CODE XREF: ROM:00009554j
		move.b	#1,$1C(a0)

loc_9564:				; CODE XREF: ROM:00009538j
					; ROM:00009542j ...
		lea	(Ani_Obj2A).l,a1
		bsr.w	AnimateSprite
		tst.b	$1A(a0)
		bne.s	loc_9588
		move.w	#$11,d1
		move.w	#$20,d2	
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		bsr.w	SolidObject

loc_9588:				; CODE XREF: ROM:00009572j
		bra.w	MarkObjGone
; ---------------------------------------------------------------------------
Ani_Obj2A:	dc.w byte_9590-Ani_Obj2A ; DATA	XREF: ROM:loc_9564o
					; ROM:Ani_Obj2Ao ...
		dc.w byte_959C-Ani_Obj2A
byte_9590:	dc.b   0,  8,  7,  6,  5,  4,  3,  2; 0	; DATA XREF: ROM:Ani_Obj2Ao
		dc.b   1,  0,$FE,  1	; 8
byte_959C:	dc.b   0,  0,  1,  2,  3,  4,  5,  6; 0	; DATA XREF: ROM:0000958Eo
		dc.b   7,  8,$FE,  1	; 8
Map_Obj2A:	dc.w word_95BA-Map_Obj2A ; DATA	XREF: ROM:00009502o
					; ROM:Map_Obj2Ao ...
		dc.w word_95CC-Map_Obj2A
		dc.w word_95DE-Map_Obj2A
		dc.w word_95F0-Map_Obj2A
		dc.w word_9602-Map_Obj2A
		dc.w word_9614-Map_Obj2A
		dc.w word_9626-Map_Obj2A
		dc.w word_9638-Map_Obj2A
		dc.w word_964A-Map_Obj2A
word_95BA:	dc.w 2			; DATA XREF: ROM:Map_Obj2Ao
		dc.w $E007, $800, $800,$FFF8; 0
		dc.w	 7, $800, $800,$FFF8; 4
word_95CC:	dc.w 2			; DATA XREF: ROM:000095AAo
		dc.w $DC07, $800, $800,$FFF8; 0
		dc.w  $407, $800, $800,$FFF8; 4
word_95DE:	dc.w 2			; DATA XREF: ROM:000095ACo
		dc.w $D807, $800, $800,$FFF8; 0
		dc.w  $807, $800, $800,$FFF8; 4
word_95F0:	dc.w 2			; DATA XREF: ROM:000095AEo
		dc.w $D407, $800, $800,$FFF8; 0
		dc.w  $C07, $800, $800,$FFF8; 4
word_9602:	dc.w 2			; DATA XREF: ROM:000095B0o
		dc.w $D007, $800, $800,$FFF8; 0
		dc.w $1007, $800, $800,$FFF8; 4
word_9614:	dc.w 2			; DATA XREF: ROM:000095B2o
		dc.w $CC07, $800, $800,$FFF8; 0
		dc.w $1407, $800, $800,$FFF8; 4
word_9626:	dc.w 2			; DATA XREF: ROM:000095B4o
		dc.w $C807, $800, $800,$FFF8; 0
		dc.w $1807, $800, $800,$FFF8; 4
word_9638:	dc.w 2			; DATA XREF: ROM:000095B6o
		dc.w $C407, $800, $800,$FFF8; 0
		dc.w $1C07, $800, $800,$FFF8; 4
word_964A:	dc.w 2			; DATA XREF: ROM:000095B8o
		dc.w $C007, $800, $800,$FFF8; 0
		dc.w $2007, $800, $800,$FFF8; 4
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Sonic	1 Object 1E - leftover Ballhog object
;----------------------------------------------------

S1Obj_1E:				; leftover from	Sonic 1
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	S1Obj_1E_Index(pc,d0.w),d1
		jmp	S1Obj_1E_Index(pc,d1.w)
; ---------------------------------------------------------------------------
S1Obj_1E_Index:	dc.w loc_966E-S1Obj_1E_Index ; DATA XREF: ROM:S1Obj_1E_Indexo
					; ROM:0000966Co
		dc.w loc_96C2-S1Obj_1E_Index
; ---------------------------------------------------------------------------

loc_966E:				; DATA XREF: ROM:S1Obj_1E_Indexo
		move.b	#$13,$16(a0)
		move.b	#8,$17(a0)
		move.l	#Map_S1Obj1E,4(a0)
		move.w	#$2302,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#5,$20(a0)
		move.b	#$C,$19(a0)
		bsr.w	ObjectFall
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	locret_96C0
		add.w	d1,$C(a0)
		move.w	#0,$12(a0)
		addq.b	#2,$24(a0)

locret_96C0:				; CODE XREF: ROM:000096B0j
		rts
; ---------------------------------------------------------------------------

loc_96C2:				; DATA XREF: ROM:0000966Co
		lea	(Ani_S1Obj1E).l,a1
		bsr.w	AnimateSprite
		cmpi.b	#1,$1A(a0)
		bne.s	loc_96DC
		tst.b	$32(a0)
		beq.s	loc_96E4
		bra.s	loc_96E0
; ---------------------------------------------------------------------------

loc_96DC:				; CODE XREF: ROM:000096D2j
		clr.b	$32(a0)

loc_96E0:				; CODE XREF: ROM:000096DAj
					; ROM:loc_972Ej
		bra.w	MarkObjGone
; ---------------------------------------------------------------------------

loc_96E4:				; CODE XREF: ROM:000096D8j
		move.b	#1,$32(a0)
		bsr.w	SingleObjectLoad
		bne.s	loc_972E
		move.b	#$20,0(a1) 
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	#$FF00,$10(a1)
		move.w	#0,$12(a1)
		moveq	#$FFFFFFFC,d0
		btst	#0,$22(a0)
		beq.s	loc_971E
		neg.w	d0
		neg.w	$10(a1)

loc_971E:				; CODE XREF: ROM:00009716j
		add.w	d0,8(a1)
		addi.w	#$C,$C(a1)
		move.b	$28(a0),$28(a1)

loc_972E:				; CODE XREF: ROM:000096EEj
		bra.s	loc_96E0
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Sonic	1 Object 20 - leftover object for the
;  ball	that S1	Ballhog	throws
;----------------------------------------------------

S1Obj20:
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	S1Obj20_Index(pc,d0.w),d1
		jmp	S1Obj20_Index(pc,d1.w)
; ---------------------------------------------------------------------------
S1Obj20_Index:	dc.w loc_9742-S1Obj20_Index ; DATA XREF: ROM:S1Obj20_Indexo
					; ROM:00009740o
		dc.w loc_978A-S1Obj20_Index
; ---------------------------------------------------------------------------

loc_9742:				; DATA XREF: ROM:S1Obj20_Indexo
		addq.b	#2,$24(a0)
		move.b	#7,$16(a0)
		move.l	#Map_S1Obj1E,4(a0)
		move.w	#$2302,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#$87,$20(a0)
		move.b	#8,$19(a0)
		moveq	#0,d0
		move.b	$28(a0),d0
		mulu.w	#$3C,d0	
		move.w	d0,$30(a0)
		move.b	#4,$1A(a0)

loc_978A:				; DATA XREF: ROM:00009740o
		jsr	(ObjectFall).l
		tst.w	$12(a0)
		bmi.s	loc_97C6
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	loc_97C6
		add.w	d1,$C(a0)
		move.w	#$FD00,$12(a0)
		tst.b	d3
		beq.s	loc_97C6
		bmi.s	loc_97BC
		tst.w	$10(a0)
		bpl.s	loc_97C6
		neg.w	$10(a0)
		bra.s	loc_97C6
; ---------------------------------------------------------------------------

loc_97BC:				; CODE XREF: ROM:000097AEj
		tst.w	$10(a0)
		bmi.s	loc_97C6
		neg.w	$10(a0)

loc_97C6:				; CODE XREF: ROM:00009794j
					; ROM:0000979Ej ...
		subq.w	#1,$30(a0)
		bpl.s	loc_97E2
		move.b	#$24,0(a0) 
		move.b	#$3F,0(a0) 
		move.b	#0,$24(a0)
		bra.w	Obj3F		; explosion object
; ---------------------------------------------------------------------------

loc_97E2:				; CODE XREF: ROM:000097CAj
		subq.b	#1,$1E(a0)
		bpl.s	loc_97F4
		move.b	#5,$1E(a0)
		bchg	#0,$1A(a0)

loc_97F4:				; CODE XREF: ROM:000097E6j
		move.w	($FFFFEECE).w,d0
		addi.w	#$E0,d0	
		cmp.w	$C(a0),d0
		bcs.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 24 - explosion	from a hit monitor
;----------------------------------------------------

Obj24:					; CODE XREF: ROM:0000A62Cj
					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj24_Index(pc,d0.w),d1
		jmp	Obj24_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj24_Index:	dc.w loc_981A-Obj24_Index ; DATA XREF: ROM:Obj24_Indexo
					; ROM:00009818o
		dc.w loc_985E-Obj24_Index
; ---------------------------------------------------------------------------

loc_981A:				; DATA XREF: ROM:Obj24_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj24,4(a0)
		move.w	#$41C,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#0,$20(a0)
		move.b	#$C,$19(a0)
		move.b	#9,$1E(a0)
		move.b	#0,$1A(a0)
		move.w	#sfx_A5,d0	; "?"
		jsr	(PlaySound_Special).l

loc_985E:				; DATA XREF: ROM:00009818o
		subq.b	#1,$1E(a0)
		bpl.s	loc_9878
		move.b	#9,$1E(a0)
		addq.b	#1,$1A(a0)
		cmpi.b	#4,$1A(a0)
		beq.w	DeleteObject

loc_9878:				; CODE XREF: ROM:00009862j
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 27 - explosion	from a hit enemy
;----------------------------------------------------

Obj27:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj27_Index(pc,d0.w),d1
		jmp	Obj27_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj27_Index:	dc.w loc_9890-Obj27_Index ; DATA XREF: ROM:Obj27_Indexo
					; ROM:0000988Co ...
		dc.w loc_98B2-Obj27_Index
		dc.w loc_98F6-Obj27_Index
; ---------------------------------------------------------------------------

loc_9890:				; DATA XREF: ROM:Obj27_Indexo
		addq.b	#2,$24(a0)
		bsr.w	SingleObjectLoad
		bne.s	loc_98B2
		move.b	#$28,0(a1) 
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	$3E(a0),$3E(a1)

loc_98B2:				; CODE XREF: ROM:00009898j
					; DATA XREF: ROM:0000988Co
		addq.b	#2,$24(a0)
		move.l	#Map_Obj27,4(a0)
		move.w	#$5A0,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#0,$20(a0)
		move.b	#$C,$19(a0)
		move.b	#7,$1E(a0)
		move.b	#0,$1A(a0)
		move.w	#sfx_BreakItem,d0	; "?"
		jsr	(PlaySound_Special).l

loc_98F6:				; DATA XREF: ROM:0000988Eo
					; ROM:00009924o
		subq.b	#1,$1E(a0)
		bpl.s	loc_9910
		move.b	#7,$1E(a0)
		addq.b	#1,$1A(a0)
		cmpi.b	#5,$1A(a0)
		beq.w	DeleteObject

loc_9910:				; CODE XREF: ROM:000098FAj
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 3F - Explosion
;----------------------------------------------------

Obj3F:					; CODE XREF: ROM:000097DEj
					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0		; explosion object
		move.b	$24(a0),d0
		move.w	Obj3F_Index(pc,d0.w),d1
		jmp	Obj3F_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj3F_Index:	dc.w loc_9926-Obj3F_Index ; DATA XREF: ROM:Obj3F_Indexo
					; ROM:00009924o
		dc.w loc_98F6-Obj3F_Index
; ---------------------------------------------------------------------------

loc_9926:				; DATA XREF: ROM:Obj3F_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj3F,4(a0)
		move.w	#$5A0,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#0,$20(a0)
		move.b	#$C,$19(a0)
		move.b	#7,$1E(a0)
		move.b	#0,$1A(a0)
		move.w	#sfx_Bomb,d0	
		jmp	(PlaySound_Special).l
; ---------------------------------------------------------------------------
Ani_S1Obj1E:	dc.w byte_996C-Ani_S1Obj1E ; DATA XREF:	ROM:loc_96C2o
					; ROM:Ani_S1Obj1Eo
byte_996C:	dc.b   9,  0,  0,  2,  2,  3,  2,  0 ; DATA XREF: ROM:Ani_S1Obj1Eo
		dc.b   0,  2,  2,  3,  2,  0,  0,  2
		dc.b   2,  3,  2,  0,  0,  1,$FF,  0
Map_S1Obj1E:	dc.w word_9990-Map_S1Obj1E ; DATA XREF:	ROM:0000967Ao
					; ROM:0000974Co ...
		dc.w word_99A2-Map_S1Obj1E
		dc.w word_99B4-Map_S1Obj1E
		dc.w word_99C6-Map_S1Obj1E
		dc.w word_99D8-Map_S1Obj1E
		dc.w word_99E2-Map_S1Obj1E
word_9990:	dc.w 2			; DATA XREF: ROM:Map_S1Obj1Eo
		dc.w $EF09,    0,    0,$FFF4; 0
		dc.w $FF0A,    6,    3,$FFF4; 4
word_99A2:	dc.w 2			; DATA XREF: ROM:00009986o
		dc.w $EF09,    0,    0,$FFF4; 0
		dc.w $FF0A,   $F,    7,$FFF4; 4
word_99B4:	dc.w 2			; DATA XREF: ROM:00009988o
		dc.w $F409,    0,    0,$FFF4; 0
		dc.w  $409,  $18,   $C,$FFF4; 4
word_99C6:	dc.w 2			; DATA XREF: ROM:0000998Ao
		dc.w $E409,    0,    0,$FFF4; 0
		dc.w $F40A,  $1E,   $F,$FFF4; 4
word_99D8:	dc.w 1			; DATA XREF: ROM:0000998Co
		dc.w $F805,  $27,  $13,$FFF8; 0
word_99E2:	dc.w 1			; DATA XREF: ROM:0000998Eo
		dc.w $F805,  $2B,  $15,$FFF8; 0
Map_Obj24:	dc.w word_99F4-Map_Obj24 ; DATA	XREF: ROM:0000981Eo
					; ROM:Map_Obj24o ...
		dc.w word_99FE-Map_Obj24
		dc.w word_9A08-Map_Obj24
		dc.w word_9A12-Map_Obj24
word_99F4:	dc.w 1			; DATA XREF: ROM:Map_Obj24o
		dc.w $F40A,    0,    0,$FFF4; 0
word_99FE:	dc.w 1			; DATA XREF: ROM:000099EEo
		dc.w $F40A,    9,    4,$FFF4; 0
word_9A08:	dc.w 1			; DATA XREF: ROM:000099F0o
		dc.w $F40A,  $12,    9,$FFF4; 0
word_9A12:	dc.w 1			; DATA XREF: ROM:000099F2o
		dc.w $F40A,  $1B,   $D,$FFF4; 0
Map_Obj27:	dc.w word_9A26-Map_Obj27 ; DATA	XREF: ROM:000098B6o
					; ROM:Map_Obj27o ...
		dc.w word_9A30-Map_Obj27
		dc.w word_9A3A-Map_Obj27
		dc.w word_9A44-Map_Obj27
		dc.w word_9A66-Map_Obj27
word_9A26:	dc.w 1			; DATA XREF: ROM:Map_Obj27o
					; ROM:Map_Obj3Fo
		dc.w $F809,    0,    0,$FFF4; 0
word_9A30:	dc.w 1			; DATA XREF: ROM:00009A1Eo
		dc.w $F00F,    6,    3,$FFF0; 0
word_9A3A:	dc.w 1			; DATA XREF: ROM:00009A20o
		dc.w $F00F,  $16,   $B,$FFF0; 0
word_9A44:	dc.w 4			; DATA XREF: ROM:00009A22o
					; ROM:00009A8Eo
		dc.w $EC0A,  $26,  $13,$FFEC; 0
		dc.w $EC05,  $2F,  $17,	   4; 4
		dc.w  $405,$182F,$1817,$FFEC; 8
		dc.w $FC0A,$1826,$1813,$FFFC; 12
word_9A66:	dc.w 4			; DATA XREF: ROM:00009A24o
					; ROM:00009A90o
		dc.w $EC0A,  $33,  $19,$FFEC; 0
		dc.w $EC05,  $3C,  $1E,	   4; 4
		dc.w  $405,$183C,$181E,$FFEC; 8
		dc.w $FC0A,$1833,$1819,$FFFC; 12
Map_Obj3F:	dc.w word_9A26-Map_Obj3F ; DATA	XREF: ROM:0000992Ao
					; ROM:Map_Obj3Fo ...
		dc.w word_9A92-Map_Obj3F
		dc.w word_9A9C-Map_Obj3F
		dc.w word_9A44-Map_Obj3F
		dc.w word_9A66-Map_Obj3F
word_9A92:	dc.w 1			; DATA XREF: ROM:00009A8Ao
		dc.w $F00F,  $40,  $20,$FFF0; 0
word_9A9C:	dc.w 1			; DATA XREF: ROM:00009A8Co
		dc.w $F00F,  $50,  $28,$FFF0; 0
; ---------------------------------------------------------------------------
		nop
;----------------------------------------------------
; Object 28 - animals
;----------------------------------------------------

Obj28:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	off_9AB6(pc,d0.w),d1
		jmp	off_9AB6(pc,d1.w)
; ---------------------------------------------------------------------------
off_9AB6:	dc.w loc_9B92-off_9AB6,loc_9CB8-off_9AB6,loc_9D12-off_9AB6; 0
					; DATA XREF: ROM:off_9AB6o
					; ROM:off_9AB6+2o ...
		dc.w loc_9D4E-off_9AB6,loc_9D12-off_9AB6,loc_9D12-off_9AB6; 3
		dc.w loc_9D12-off_9AB6,loc_9D4E-off_9AB6,loc_9D12-off_9AB6; 6
		dc.w loc_9DCE-off_9AB6,loc_9DEE-off_9AB6,loc_9DEE-off_9AB6; 9
		dc.w loc_9E0E-off_9AB6,loc_9E48-off_9AB6,loc_9EA2-off_9AB6; 12
		dc.w loc_9EC0-off_9AB6,loc_9EA2-off_9AB6,loc_9EC0-off_9AB6; 15
		dc.w loc_9EA2-off_9AB6,loc_9EFE-off_9AB6,loc_9E64-off_9AB6; 18
byte_9AE0:	dc.b   0,  5,  2,  3,  6,  3,  4,  5,  4,  1,  0,  1; 0
					; DATA XREF: ROM:00009C16t
word_9AEC:	dc.w $FE00		; DATA XREF: ROM:00009C24t
		dc.w $FC00
		dc.l Map_Obj28a
		dc.w $FE00
		dc.w $FD00
		dc.l Map_Obj28
		dc.w $FE80
		dc.w $FD00
		dc.l Map_Obj28a
		dc.w $FEC0
		dc.w $FE80
		dc.l Map_Obj28
		dc.w $FE40
		dc.w $FD00
		dc.l Map_Obj28b
		dc.w $FD00
		dc.w $FC00
		dc.l Map_Obj28
		dc.w $FD80
		dc.w $FC80
		dc.l Map_Obj28b
word_9B24:	dc.w $FBC0,$FC00,$FBC0,$FC00; 0	; DATA XREF: ROM:00009BB8t
		dc.w $FBC0,$FC00,$FD00,$FC00; 4
		dc.w $FD00,$FC00,$FE80,$FD00; 8
		dc.w $FE80,$FD00,$FEC0,$FE80; 12
		dc.w $FE40,$FD00,$FE00,$FD00; 16
		dc.w $FD80,$FC80	; 20
off_9B50:	dc.l Map_Obj28,Map_Obj28; 0
		dc.l Map_Obj28,Map_Obj28a; 2
		dc.l Map_Obj28a,Map_Obj28a; 4
		dc.l Map_Obj28a,Map_Obj28; 6
		dc.l Map_Obj28b,Map_Obj28; 8
		dc.l Map_Obj28b		; 10
word_9B7C:	dc.w  $5A5, $5A5, $5A5,	$553, $553, $573, $573,	$585, $593, $565, $5B3;	0
; ---------------------------------------------------------------------------

loc_9B92:				; DATA XREF: ROM:off_9AB6o
		tst.b	$28(a0)
		beq.w	loc_9C00
		moveq	#0,d0
		move.b	$28(a0),d0
		add.w	d0,d0
		move.b	d0,$24(a0)
		subi.w	#$14,d0
		move.w	word_9B7C(pc,d0.w),2(a0)
		add.w	d0,d0
		move.l	off_9B50(pc,d0.w),4(a0)
		lea	word_9B24(pc),a1
		move.w	(a1,d0.w),$32(a0)
		move.w	(a1,d0.w),$10(a0)
		move.w	2(a1,d0.w),$34(a0)
		move.w	2(a1,d0.w),$12(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#$C,$16(a0)
		move.b	#4,1(a0)
		bset	#0,1(a0)
		move.b	#6,$18(a0)
		move.b	#8,$19(a0)
		move.b	#7,$1E(a0)
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_9C00:				; CODE XREF: ROM:00009B96j
		addq.b	#2,$24(a0)
		bsr.w	PseudoRandomNumber
		andi.w	#1,d0
		moveq	#0,d1
		move.b	(v_zone).w,d1
		add.w	d1,d1
		add.w	d0,d1
		lea	byte_9AE0(pc),a1
		move.b	(a1,d1.w),d0
		move.b	d0,$30(a0)
		lsl.w	#3,d0
		lea	word_9AEC(pc),a1
		adda.w	d0,a1
		move.w	(a1)+,$32(a0)
		move.w	(a1)+,$34(a0)
		move.l	(a1)+,4(a0)
		move.w	#$580,2(a0)
		btst	#0,$30(a0)
		beq.s	loc_9C4A
		move.w	#$592,2(a0)

loc_9C4A:				; CODE XREF: ROM:00009C42j
		bsr.w	ModifySpriteAttr_2P
		move.b	#$C,$16(a0)
		move.b	#4,1(a0)
		bset	#0,1(a0)
		move.b	#6,$18(a0)
		move.b	#8,$19(a0)
		move.b	#7,$1E(a0)
		move.b	#2,$1A(a0)
		move.w	#$FC00,$12(a0)
		tst.b	($FFFFF7A7).w
		bne.s	loc_9CAA
		bsr.w	SingleObjectLoad
		bne.s	loc_9CA6
		move.b	#$29,0(a1) 
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	$3E(a0),d0
		lsr.w	#1,d0
		move.b	d0,$1A(a1)

loc_9CA6:				; CODE XREF: ROM:00009C88j
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_9CAA:				; CODE XREF: ROM:00009C82j
		move.b	#$12,$24(a0)
		clr.w	$10(a0)
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_9CB8:				; DATA XREF: ROM:off_9AB6o
		tst.b	1(a0)
		bpl.w	DeleteObject
		bsr.w	ObjectFall
		tst.w	$12(a0)
		bmi.s	loc_9D0E
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	loc_9D0E
		add.w	d1,$C(a0)
		move.w	$32(a0),$10(a0)
		move.w	$34(a0),$12(a0)
		move.b	#1,$1A(a0)
		move.b	$30(a0),d0
		add.b	d0,d0
		addq.b	#4,d0
		move.b	d0,$24(a0)
		tst.b	($FFFFF7A7).w
		beq.s	loc_9D0E
		btst	#4,($FFFFFE0F).w
		beq.s	loc_9D0E
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_9D0E:				; CODE XREF: ROM:00009CC8j
					; ROM:00009CD2j ...
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_9D12:				; CODE XREF: ROM:00009E60j
					; DATA XREF: ROM:off_9AB6o
		bsr.w	ObjectFall
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.s	loc_9D3C
		move.b	#0,$1A(a0)
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	loc_9D3C
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_9D3C:				; CODE XREF: ROM:00009D20j
					; ROM:00009D30j
		tst.b	$28(a0)
		bne.s	loc_9DB2
		tst.b	1(a0)
		bpl.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_9D4E:				; CODE XREF: ROM:00009E06j
					; DATA XREF: ROM:off_9AB6o
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		tst.w	$12(a0)
		bmi.s	loc_9D8A
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	loc_9D8A
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)
		tst.b	$28(a0)
		beq.s	loc_9D8A
		cmpi.b	#$A,$28(a0)
		beq.s	loc_9D8A
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_9D8A:				; CODE XREF: ROM:00009D5Cj
					; ROM:00009D66j ...
		subq.b	#1,$1E(a0)
		bpl.s	loc_9DA0
		move.b	#1,$1E(a0)
		addq.b	#1,$1A(a0)
		andi.b	#1,$1A(a0)

loc_9DA0:				; CODE XREF: ROM:00009D8Ej
		tst.b	$28(a0)
		bne.s	loc_9DB2
		tst.b	1(a0)
		bpl.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_9DB2:				; CODE XREF: ROM:00009D40j
					; ROM:00009DA4j ...
		move.w	8(a0),d0
		sub.w	(v_objspace+8).w,d0
		bcs.s	loc_9DCA
		subi.w	#$180,d0
		bpl.s	loc_9DCA
		tst.b	1(a0)
		bpl.w	DeleteObject

loc_9DCA:				; CODE XREF: ROM:00009DBAj
					; ROM:00009DC0j
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_9DCE:				; DATA XREF: ROM:off_9AB6o
		tst.b	1(a0)
		bpl.w	DeleteObject
		subq.w	#1,$36(a0)
		bne.w	loc_9DEA
		move.b	#2,$24(a0)
		move.b	#3,$18(a0)

loc_9DEA:				; CODE XREF: ROM:00009DDAj
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_9DEE:				; DATA XREF: ROM:off_9AB6o
		bsr.w	sub_9F92
		bcc.s	loc_9E0A
		move.w	$32(a0),$10(a0)
		move.w	$34(a0),$12(a0)
		move.b	#$E,$24(a0)
		bra.w	loc_9D4E
; ---------------------------------------------------------------------------

loc_9E0A:				; CODE XREF: ROM:00009DF2j
		bra.w	loc_9DB2
; ---------------------------------------------------------------------------

loc_9E0E:				; DATA XREF: ROM:off_9AB6o
		bsr.w	sub_9F92
		bpl.s	loc_9E44
		clr.w	$10(a0)
		clr.w	$32(a0)
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		bsr.w	sub_9F52
		bsr.w	sub_9F7A
		subq.b	#1,$1E(a0)
		bpl.s	loc_9E44
		move.b	#1,$1E(a0)
		addq.b	#1,$1A(a0)
		andi.b	#1,$1A(a0)

loc_9E44:				; CODE XREF: ROM:00009E12j
					; ROM:00009E32j
		bra.w	loc_9DB2
; ---------------------------------------------------------------------------

loc_9E48:				; DATA XREF: ROM:off_9AB6o
		bsr.w	sub_9F92
		bpl.s	loc_9E9E
		move.w	$32(a0),$10(a0)
		move.w	$34(a0),$12(a0)
		move.b	#4,$24(a0)
		bra.w	loc_9D12
; ---------------------------------------------------------------------------

loc_9E64:				; DATA XREF: ROM:off_9AB6o
		bsr.w	ObjectFall
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.s	loc_9E9E
		move.b	#0,$1A(a0)
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	loc_9E9E
		not.b	$29(a0)
		bne.s	loc_9E94
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_9E94:				; CODE XREF: ROM:00009E88j
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_9E9E:				; CODE XREF: ROM:00009E4Cj
					; ROM:00009E72j ...
		bra.w	loc_9DB2
; ---------------------------------------------------------------------------

loc_9EA2:				; DATA XREF: ROM:off_9AB6o
		bsr.w	sub_9F92
		bpl.s	loc_9EBC
		clr.w	$10(a0)
		clr.w	$32(a0)
		bsr.w	ObjectFall
		bsr.w	sub_9F52
		bsr.w	sub_9F7A

loc_9EBC:				; CODE XREF: ROM:00009EA6j
		bra.w	loc_9DB2
; ---------------------------------------------------------------------------

loc_9EC0:				; DATA XREF: ROM:off_9AB6o
		bsr.w	sub_9F92
		bpl.s	loc_9EFA
		bsr.w	ObjectFall
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.s	loc_9EFA
		move.b	#0,$1A(a0)
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	loc_9EFA
		neg.w	$10(a0)
		bchg	#0,1(a0)
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_9EFA:				; CODE XREF: ROM:00009EC4j
					; ROM:00009ED4j ...
		bra.w	loc_9DB2
; ---------------------------------------------------------------------------

loc_9EFE:				; DATA XREF: ROM:off_9AB6o
		bsr.w	sub_9F92
		bpl.s	loc_9F4E
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		tst.w	$12(a0)
		bmi.s	loc_9F38
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	loc_9F38
		not.b	$29(a0)
		bne.s	loc_9F2E
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_9F2E:				; CODE XREF: ROM:00009F22j
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_9F38:				; CODE XREF: ROM:00009F12j
					; ROM:00009F1Cj
		subq.b	#1,$1E(a0)
		bpl.s	loc_9F4E
		move.b	#1,$1E(a0)
		addq.b	#1,$1A(a0)
		andi.b	#1,$1A(a0)

loc_9F4E:				; CODE XREF: ROM:00009F02j
					; ROM:00009F3Cj
		bra.w	loc_9DB2

; =============== S U B	R O U T	I N E =======================================


sub_9F52:				; CODE XREF: ROM:00009E26p
					; ROM:00009EB4p
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.s	locret_9F78
		move.b	#0,$1A(a0)
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	locret_9F78
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

locret_9F78:				; CODE XREF: sub_9F52+Aj sub_9F52+1Aj
		rts
; End of function sub_9F52


; =============== S U B	R O U T	I N E =======================================


sub_9F7A:				; CODE XREF: ROM:00009E2Ap
					; ROM:00009EB8p
		bset	#0,1(a0)
		move.w	8(a0),d0
		sub.w	(v_objspace+8).w,d0
		bcc.s	locret_9F90
		bclr	#0,1(a0)

locret_9F90:				; CODE XREF: sub_9F7A+Ej
		rts
; End of function sub_9F7A


; =============== S U B	R O U T	I N E =======================================


sub_9F92:				; CODE XREF: ROM:loc_9DEEp
					; ROM:loc_9E0Ep ...
		move.w	(v_objspace+8).w,d0
		sub.w	8(a0),d0
		subi.w	#$B8,d0
		rts
; End of function sub_9F92

; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 29 - points that appear when you destroy something
;----------------------------------------------------

Obj29:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj29_Index(pc,d0.w),d1
		jmp	Obj29_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj29_Index:	dc.w loc_9FB2-Obj29_Index ; DATA XREF: ROM:Obj29_Indexo
					; ROM:00009FB0o
		dc.w loc_9FE0-Obj29_Index
; ---------------------------------------------------------------------------

loc_9FB2:				; DATA XREF: ROM:Obj29_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj29,4(a0)
		move.w	#$4AC,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#8,$19(a0)
		move.w	#$FD00,$12(a0)

loc_9FE0:				; DATA XREF: ROM:00009FB0o
		tst.w	$12(a0)
		bpl.w	DeleteObject
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Map_Obj28a:	dc.w word_A006-Map_Obj28a ; DATA XREF: ROM:00009AF0o
					; ROM:00009B00o ...
		dc.w word_A010-Map_Obj28a
		dc.w word_9FFC-Map_Obj28a
word_9FFC:	dc.w 1			; DATA XREF: ROM:00009FFAo
		dc.w $F406,    0,    0,$FFF8; 0
word_A006:	dc.w 1			; DATA XREF: ROM:Map_Obj28ao
		dc.w $F406,    6,    3,$FFF8; 0
word_A010:	dc.w 1			; DATA XREF: ROM:00009FF8o
		dc.w $F406,   $C,    6,$FFF8; 0
Map_Obj28:	dc.w word_A02A-Map_Obj28 ; DATA	XREF: ROM:00009AF8o
					; ROM:00009B08o ...
		dc.w word_A034-Map_Obj28
		dc.w word_A020-Map_Obj28
word_A020:	dc.w 1			; DATA XREF: ROM:0000A01Eo
		dc.w $F406,    0,    0,$FFF8; 0
word_A02A:	dc.w 1			; DATA XREF: ROM:Map_Obj28o
		dc.w $FC05,    6,    3,$FFF8; 0
word_A034:	dc.w 1			; DATA XREF: ROM:0000A01Co
		dc.w $FC05,   $A,    5,$FFF8; 0
Map_Obj28b:	dc.w word_A04E-Map_Obj28b ; DATA XREF: ROM:00009B10o
					; ROM:00009B20o ...
		dc.w word_A058-Map_Obj28b
		dc.w word_A044-Map_Obj28b
word_A044:	dc.w 1			; DATA XREF: ROM:0000A042o
		dc.w $F406,    0,    0,$FFF8; 0
word_A04E:	dc.w 1			; DATA XREF: ROM:Map_Obj28bo
		dc.w $FC09,    6,    3,$FFF4; 0
word_A058:	dc.w 1			; DATA XREF: ROM:0000A040o
		dc.w $FC09,   $C,    6,$FFF4; 0
Map_Obj29:	dc.w word_A070-Map_Obj29 ; DATA	XREF: ROM:00009FB6o
					; ROM:Map_Obj29o ...
		dc.w word_A07A-Map_Obj29
		dc.w word_A084-Map_Obj29
		dc.w word_A08E-Map_Obj29
		dc.w word_A0A0-Map_Obj29
		dc.w word_A0AA-Map_Obj29
		dc.w word_A0BC-Map_Obj29
word_A070:	dc.w 1			; DATA XREF: ROM:Map_Obj29o
		dc.w $F805,    2,    1,$FFF8; 0
word_A07A:	dc.w 1			; DATA XREF: ROM:0000A064o
		dc.w $F805,    6,    3,$FFF8; 0
word_A084:	dc.w 1			; DATA XREF: ROM:0000A066o
		dc.w $F805,   $A,    5,$FFF8; 0
word_A08E:	dc.w 2			; DATA XREF: ROM:0000A068o
		dc.w $F801,    0,    0,$FFF8; 0
		dc.w $F805,   $E,    7,	   0; 4
word_A0A0:	dc.w 1			; DATA XREF: ROM:0000A06Ao
		dc.w $F801,    0,    0,$FFFC; 0
word_A0AA:	dc.w 2			; DATA XREF: ROM:0000A06Co
		dc.w $F805,    2,    1,$FFF0; 0
		dc.w $F805,   $E,    7,	   0; 4
word_A0BC:	dc.w 2			; DATA XREF: ROM:0000A06Eo
		dc.w $F805,   $A,    5,$FFF0; 0
		dc.w $F805,   $E,    7,	   0; 4
; ---------------------------------------------------------------------------
		nop
;----------------------------------------------------
; Object 1F - GHZ Crabmeat
;----------------------------------------------------

Obj1F:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj1F_Index(pc,d0.w),d1
		jmp	Obj1F_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj1F_Index:	dc.w loc_A0E8-Obj1F_Index ; DATA XREF: ROM:Obj1F_Indexo
					; ROM:0000A0E0o ...
		dc.w loc_A140-Obj1F_Index
		dc.w loc_A29C-Obj1F_Index
		dc.w loc_A2A0-Obj1F_Index
		dc.w loc_A2DA-Obj1F_Index
; ---------------------------------------------------------------------------

loc_A0E8:				; DATA XREF: ROM:Obj1F_Indexo
		move.b	#$10,$16(a0)
		move.b	#8,$17(a0)
		move.l	#Map_Obj1F,4(a0)
		move.w	#$400,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#6,$20(a0)
		move.b	#$15,$19(a0)
		bsr.w	ObjectFall
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	locret_A13E
		add.w	d1,$C(a0)
		move.b	d3,$26(a0)
		move.w	#0,$12(a0)
		addq.b	#2,$24(a0)

locret_A13E:				; CODE XREF: ROM:0000A12Aj
		rts
; ---------------------------------------------------------------------------

loc_A140:				; DATA XREF: ROM:0000A0E0o
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	off_A15C(pc,d0.w),d1
		jsr	off_A15C(pc,d1.w)
		lea	(Ani_Obj1F).l,a1
		bsr.w	AnimateSprite
		bra.w	MarkObjGone
; ---------------------------------------------------------------------------
off_A15C:	dc.w loc_A160-off_A15C	; DATA XREF: ROM:off_A15Co
					; ROM:0000A15Eo
		dc.w loc_A1FE-off_A15C
; ---------------------------------------------------------------------------

loc_A160:				; DATA XREF: ROM:off_A15Co
		subq.w	#1,$30(a0)
		bpl.s	locret_A19A
		tst.b	1(a0)
		bpl.s	loc_A174
		bchg	#1,$32(a0)
		bne.s	loc_A19C

loc_A174:				; CODE XREF: ROM:0000A16Aj
		addq.b	#2,$25(a0)
		move.w	#$7F,$30(a0) 
		move.w	#$80,$10(a0) 
		bsr.w	sub_A26C
		addq.b	#3,d0
		move.b	d0,$1C(a0)
		bchg	#0,$22(a0)
		bne.s	locret_A19A
		neg.w	$10(a0)

locret_A19A:				; CODE XREF: ROM:0000A164j
					; ROM:0000A194j
		rts
; ---------------------------------------------------------------------------

loc_A19C:				; CODE XREF: ROM:0000A172j
		move.w	#$3B,$30(a0) 
		move.b	#6,$1C(a0)
		bsr.w	SingleObjectLoad
		bne.s	loc_A1D2
		move.b	#$1F,0(a1)
		move.b	#6,$24(a1)
		move.w	8(a0),8(a1)
		subi.w	#$10,8(a1)
		move.w	$C(a0),$C(a1)
		move.w	#$FF00,$10(a1)

loc_A1D2:				; CODE XREF: ROM:0000A1ACj
		bsr.w	SingleObjectLoad
		bne.s	locret_A1FC
		move.b	#$1F,0(a1)
		move.b	#6,$24(a1)
		move.w	8(a0),8(a1)
		addi.w	#$10,8(a1)
		move.w	$C(a0),$C(a1)
		move.w	#$100,$10(a1)

locret_A1FC:				; CODE XREF: ROM:0000A1D6j
		rts
; ---------------------------------------------------------------------------

loc_A1FE:				; DATA XREF: ROM:0000A15Eo
		subq.w	#1,$30(a0)
		bmi.s	loc_A252
		bsr.w	SpeedToPos
		bchg	#0,$32(a0)
		bne.s	loc_A238
		move.w	8(a0),d3
		addi.w	#$10,d3
		btst	#0,$22(a0)
		beq.s	loc_A224
		subi.w	#$20,d3	

loc_A224:				; CODE XREF: ROM:0000A21Ej
		jsr	(ObjHitFloor2).l
		cmpi.w	#$FFF8,d1
		blt.s	loc_A252
		cmpi.w	#$C,d1
		bge.s	loc_A252
		rts
; ---------------------------------------------------------------------------

loc_A238:				; CODE XREF: ROM:0000A20Ej
		jsr	(ObjHitFloor).l
		add.w	d1,$C(a0)
		move.b	d3,$26(a0)
		bsr.w	sub_A26C
		addq.b	#3,d0
		move.b	d0,$1C(a0)
		rts
; ---------------------------------------------------------------------------

loc_A252:				; CODE XREF: ROM:0000A202j
					; ROM:0000A22Ej ...
		subq.b	#2,$25(a0)
		move.w	#$3B,$30(a0) 
		move.w	#0,$10(a0)
		bsr.w	sub_A26C
		move.b	d0,$1C(a0)
		rts

; =============== S U B	R O U T	I N E =======================================


sub_A26C:				; CODE XREF: ROM:0000A184p
					; ROM:0000A246p ...
		moveq	#0,d0
		move.b	$26(a0),d3
		bmi.s	loc_A288
		cmpi.b	#6,d3
		bcs.s	locret_A286
		moveq	#1,d0
		btst	#0,$22(a0)
		bne.s	locret_A286
		moveq	#2,d0

locret_A286:				; CODE XREF: sub_A26C+Cj sub_A26C+16j
		rts
; ---------------------------------------------------------------------------

loc_A288:				; CODE XREF: sub_A26C+6j
		cmpi.b	#$FA,d3
		bhi.s	locret_A29A
		moveq	#2,d0
		btst	#0,$22(a0)
		bne.s	locret_A29A
		moveq	#1,d0

locret_A29A:				; CODE XREF: sub_A26C+20j sub_A26C+2Aj
		rts
; End of function sub_A26C

; ---------------------------------------------------------------------------

loc_A29C:				; DATA XREF: ROM:0000A0E2o
		bra.w	DeleteObject
; ---------------------------------------------------------------------------

loc_A2A0:				; DATA XREF: ROM:0000A0E4o
		addq.b	#2,$24(a0)
		move.l	#Map_Obj1F,4(a0)
		move.w	#$400,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#$87,$20(a0)
		move.b	#8,$19(a0)
		move.w	#$FC00,$12(a0)
		move.b	#7,$1C(a0)

loc_A2DA:				; DATA XREF: ROM:0000A0E6o
		lea	(Ani_Obj1F).l,a1
		bsr.w	AnimateSprite
		bsr.w	ObjectFall
		move.w	($FFFFEECE).w,d0
		addi.w	#$E0,d0	
		cmp.w	$C(a0),d0
		bcs.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Ani_Obj1F:	dc.w byte_A30C-Ani_Obj1F ; DATA	XREF: ROM:0000A14Eo
					; ROM:loc_A2DAo ...
		dc.w byte_A30F-Ani_Obj1F
		dc.w byte_A312-Ani_Obj1F
		dc.w byte_A315-Ani_Obj1F
		dc.w byte_A31A-Ani_Obj1F
		dc.w byte_A31F-Ani_Obj1F
		dc.w byte_A324-Ani_Obj1F
		dc.w byte_A327-Ani_Obj1F
byte_A30C:	dc.b  $F,  0,$FF	; 0 ; DATA XREF: ROM:Ani_Obj1Fo
byte_A30F:	dc.b  $F,  2,$FF	; 0 ; DATA XREF: ROM:0000A2FEo
byte_A312:	dc.b  $F,$22,$FF	; 0 ; DATA XREF: ROM:0000A300o
byte_A315:	dc.b  $F,  1,$21,  0,$FF; 0 ; DATA XREF: ROM:0000A302o
byte_A31A:	dc.b  $F,$21,  3,  2,$FF; 0 ; DATA XREF: ROM:0000A304o
byte_A31F:	dc.b  $F,  1,$23,$22,$FF; 0 ; DATA XREF: ROM:0000A306o
byte_A324:	dc.b  $F,  4,$FF	; 0 ; DATA XREF: ROM:0000A308o
byte_A327:	dc.b   1,  5,  6,$FF,  0; 0 ; DATA XREF: ROM:0000A30Ao
Map_Obj1F:	dc.w word_A33A-Map_Obj1F ; DATA	XREF: ROM:0000A0F4o
					; ROM:0000A2A4o ...
		dc.w word_A35C-Map_Obj1F
		dc.w word_A37E-Map_Obj1F
		dc.w word_A3A0-Map_Obj1F
		dc.w word_A3C2-Map_Obj1F
		dc.w word_A3F4-Map_Obj1F
		dc.w word_A3FE-Map_Obj1F
word_A33A:	dc.w 4			; DATA XREF: ROM:Map_Obj1Fo
		dc.w $F009,    0,    0,$FFE8; 0
		dc.w $F009, $800, $800,	   0; 4
		dc.w	 5,    6,    3,$FFF0; 8
		dc.w	 5, $806, $803,	   0; 12
word_A35C:	dc.w 4			; DATA XREF: ROM:0000A32Eo
		dc.w $F009,   $A,    5,$FFE8; 0
		dc.w $F009,  $10,    8,	   0; 4
		dc.w	 5,  $16,   $B,$FFF0; 8
		dc.w	 9,  $1A,   $D,	   0; 12
word_A37E:	dc.w 4			; DATA XREF: ROM:0000A330o
		dc.w $EC09,    0,    0,$FFE8; 0
		dc.w $EC09, $800, $800,	   0; 4
		dc.w $FC05, $806, $803,	   0; 8
		dc.w $FC06,  $20,  $10,$FFF0; 12
word_A3A0:	dc.w 4			; DATA XREF: ROM:0000A332o
		dc.w $EC09,   $A,    5,$FFE8; 0
		dc.w $EC09,  $10,    8,	   0; 4
		dc.w $FC09,  $26,  $13,	   0; 8
		dc.w $FC06,  $2C,  $16,$FFF0; 12
word_A3C2:	dc.w 6			; DATA XREF: ROM:0000A334o
		dc.w $F004,  $32,  $19,$FFF0; 0
		dc.w $F004, $832, $819,	   0; 4
		dc.w $F809,  $34,  $1A,$FFE8; 8
		dc.w $F809, $834, $81A,	   0; 12
		dc.w  $804,  $3A,  $1D,$FFF0; 16
		dc.w  $804, $83A, $81D,	   0; 20
word_A3F4:	dc.w 1			; DATA XREF: ROM:0000A336o
		dc.w $F805,  $3C,  $1E,$FFF8; 0
word_A3FE:	dc.w 1			; DATA XREF: ROM:0000A338o
		dc.w $F805,  $40,  $20,$FFF8; 0
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 22 - Buzzbomber
;----------------------------------------------------

Obj22:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	off_A416(pc,d0.w),d1
		jmp	off_A416(pc,d1.w)
; ---------------------------------------------------------------------------
off_A416:	dc.w loc_A41C-off_A416	; DATA XREF: ROM:off_A416o
					; ROM:0000A418o ...
		dc.w loc_A44A-off_A416
		dc.w loc_A55A-off_A416
; ---------------------------------------------------------------------------

loc_A41C:				; DATA XREF: ROM:off_A416o
		addq.b	#2,$24(a0)
		move.l	#Map_Obj22,4(a0)
		move.w	#$444,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#8,$20(a0)
		move.b	#$18,$19(a0)

loc_A44A:				; DATA XREF: ROM:0000A418o
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	off_A466(pc,d0.w),d1
		jsr	off_A466(pc,d1.w)
		lea	(Ani_Obj22).l,a1
		bsr.w	AnimateSprite
		bra.w	MarkObjGone
; ---------------------------------------------------------------------------
off_A466:	dc.w loc_A46A-off_A466	; DATA XREF: ROM:off_A466o
					; ROM:0000A468o
		dc.w loc_A500-off_A466
; ---------------------------------------------------------------------------

loc_A46A:				; DATA XREF: ROM:off_A466o
		subq.w	#1,$32(a0)
		bpl.s	locret_A49A
		btst	#1,$34(a0)
		bne.s	loc_A49C
		addq.b	#2,$25(a0)
		move.w	#$7F,$32(a0) 
		move.w	#$400,$10(a0)
		move.b	#1,$1C(a0)
		btst	#0,$22(a0)
		bne.s	locret_A49A
		neg.w	$10(a0)

locret_A49A:				; CODE XREF: ROM:0000A46Ej
					; ROM:0000A494j
		rts
; ---------------------------------------------------------------------------

loc_A49C:				; CODE XREF: ROM:0000A476j
		bsr.w	SingleObjectLoad
		bne.s	locret_A4FE
		move.b	#$23,0(a1) 
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		addi.w	#$1C,$C(a1)
		move.w	#$200,$12(a1)
		move.w	#$200,$10(a1)
		move.w	#$18,d0
		btst	#0,$22(a0)
		bne.s	loc_A4D8
		neg.w	d0
		neg.w	$10(a1)

loc_A4D8:				; CODE XREF: ROM:0000A4D0j
		add.w	d0,8(a1)
		move.b	$22(a0),$22(a1)
		move.w	#$E,$32(a1)
		move.l	a0,$3C(a1)
		move.b	#1,$34(a0)
		move.w	#$3B,$32(a0) 
		move.b	#2,$1C(a0)

locret_A4FE:				; CODE XREF: ROM:0000A4A0j
		rts
; ---------------------------------------------------------------------------

loc_A500:				; DATA XREF: ROM:0000A468o
		subq.w	#1,$32(a0)
		bmi.s	loc_A536
		bsr.w	SpeedToPos
		tst.b	$34(a0)
		bne.s	locret_A558
		move.w	(v_objspace+8).w,d0
		sub.w	8(a0),d0
		bpl.s	loc_A51C
		neg.w	d0

loc_A51C:				; CODE XREF: ROM:0000A518j
		cmpi.w	#$60,d0	
		bcc.s	locret_A558
		tst.b	1(a0)
		bpl.s	locret_A558
		move.b	#2,$34(a0)
		move.w	#$1D,$32(a0)
		bra.s	loc_A548
; ---------------------------------------------------------------------------

loc_A536:				; CODE XREF: ROM:0000A504j
		move.b	#0,$34(a0)
		bchg	#0,$22(a0)
		move.w	#$3B,$32(a0) 

loc_A548:				; CODE XREF: ROM:0000A534j
		subq.b	#2,$25(a0)
		move.w	#0,$10(a0)
		move.b	#0,$1C(a0)

locret_A558:				; CODE XREF: ROM:0000A50Ej
					; ROM:0000A520j ...
		rts
; ---------------------------------------------------------------------------

loc_A55A:				; DATA XREF: ROM:0000A41Ao
		bra.w	DeleteObject
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 23 - Missile that Buzzbomber throws
;----------------------------------------------------

Obj23:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	off_A56C(pc,d0.w),d1
		jmp	off_A56C(pc,d1.w)
; ---------------------------------------------------------------------------
off_A56C:	dc.w loc_A576-off_A56C	; DATA XREF: ROM:off_A56Co
					; ROM:0000A56Eo ...
		dc.w loc_A5C4-off_A56C
		dc.w loc_A5EC-off_A56C
		dc.w loc_A630-off_A56C
		dc.w loc_A634-off_A56C
; ---------------------------------------------------------------------------

loc_A576:				; DATA XREF: ROM:off_A56Co
		subq.w	#1,$32(a0)
		bpl.s	loc_A5DE
		addq.b	#2,$24(a0)
		move.l	#Map_Obj23,4(a0)
		move.w	#$2444,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#8,$19(a0)
		andi.b	#3,$22(a0)
		tst.b	$28(a0)
		beq.s	loc_A5C4
		move.b	#8,$24(a0)
		move.b	#$87,$20(a0)
		move.b	#1,$1C(a0)
		bra.s	loc_A63E
; ---------------------------------------------------------------------------

loc_A5C4:				; CODE XREF: ROM:0000A5AEj
					; DATA XREF: ROM:0000A56Eo
		movea.l	$3C(a0),a1
		cmpi.b	#$27,0(a1) 
		beq.s	loc_A630
		lea	(Ani_Obj33).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_A5DE:				; CODE XREF: ROM:0000A57Aj
		movea.l	$3C(a0),a1
		cmpi.b	#$27,0(a1) 
		beq.s	loc_A630
		rts
; ---------------------------------------------------------------------------

loc_A5EC:				; DATA XREF: ROM:0000A570o
		btst	#7,$22(a0)
		bne.s	loc_A620
		move.b	#$87,$20(a0)
		move.b	#1,$1C(a0)
		bsr.w	SpeedToPos
		lea	(Ani_Obj33).l,a1
		bsr.w	AnimateSprite
		move.w	($FFFFEECE).w,d0
		addi.w	#$E0,d0	
		cmp.w	$C(a0),d0
		bcs.s	loc_A630
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_A620:				; CODE XREF: ROM:0000A5F2j
		move.b	#$24,0(a0) 
		move.b	#0,$24(a0)
		bra.w	Obj24
; ---------------------------------------------------------------------------

loc_A630:				; CODE XREF: ROM:0000A5CEj
					; ROM:0000A5E8j ...
		bra.w	DeleteObject
; ---------------------------------------------------------------------------

loc_A634:				; DATA XREF: ROM:0000A574o
		tst.b	1(a0)
		bpl.s	loc_A630
		bsr.w	SpeedToPos

loc_A63E:				; CODE XREF: ROM:0000A5C2j
		lea	(Ani_Obj33).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Ani_Obj22:	dc.w byte_A652-Ani_Obj22 ; DATA	XREF: ROM:0000A458o
					; ROM:Ani_Obj22o ...
		dc.w byte_A656-Ani_Obj22
		dc.w byte_A65A-Ani_Obj22
byte_A652:	dc.b   1,  0,  1,$FF	; 0 ; DATA XREF: ROM:Ani_Obj22o
byte_A656:	dc.b   1,  2,  3,$FF	; 0 ; DATA XREF: ROM:0000A64Eo
byte_A65A:	dc.b   1,  4,  5,$FF	; 0 ; DATA XREF: ROM:0000A650o
Ani_Obj33:	dc.w byte_A662-Ani_Obj33 ; DATA	XREF: ROM:0000A5D0o
					; ROM:0000A604o ...
		dc.w byte_A666-Ani_Obj33
byte_A662:	dc.b   7,  0,  1,$FC	; 0 ; DATA XREF: ROM:Ani_Obj33o
byte_A666:	dc.b   1,  2,  3,$FF	; 0 ; DATA XREF: ROM:0000A660o
Map_Obj22:	dc.w word_A676-Map_Obj22 ; DATA	XREF: ROM:0000A420o
					; ROM:Map_Obj22o ...
		dc.w word_A6A8-Map_Obj22
		dc.w word_A6DA-Map_Obj22
		dc.w word_A714-Map_Obj22
		dc.w word_A74E-Map_Obj22
		dc.w word_A780-Map_Obj22
word_A676:	dc.w 6			; DATA XREF: ROM:Map_Obj22o
		dc.w $F409,    0,    0,$FFE8; 0
		dc.w $F409,   $F,    7,	   0; 4
		dc.w  $408,  $15,   $A,$FFE8; 8
		dc.w  $404,  $18,   $C,	   0; 12
		dc.w $F108,  $1A,   $D,$FFEC; 16
		dc.w $F104,  $1D,   $E,	   4; 20
word_A6A8:	dc.w 6			; DATA XREF: ROM:0000A66Co
		dc.w $F409,    0,    0,$FFE8; 0
		dc.w $F409,   $F,    7,	   0; 4
		dc.w  $408,  $15,   $A,$FFE8; 8
		dc.w  $404,  $18,   $C,	   0; 12
		dc.w $F408,  $1F,   $F,$FFEC; 16
		dc.w $F404,  $22,  $11,	   4; 20
word_A6DA:	dc.w 7			; DATA XREF: ROM:0000A66Eo
		dc.w  $400,  $30,  $18,	  $C; 0
		dc.w $F409,    0,    0,$FFE8; 4
		dc.w $F409,   $F,    7,	   0; 8
		dc.w  $408,  $15,   $A,$FFE8; 12
		dc.w  $404,  $18,   $C,	   0; 16
		dc.w $F108,  $1A,   $D,$FFEC; 20
		dc.w $F104,  $1D,   $E,	   4; 24
word_A714:	dc.w 7			; DATA XREF: ROM:0000A670o
		dc.w  $404,  $31,  $18,	  $C; 0
		dc.w $F409,    0,    0,$FFE8; 4
		dc.w $F409,   $F,    7,	   0; 8
		dc.w  $408,  $15,   $A,$FFE8; 12
		dc.w  $404,  $18,   $C,	   0; 16
		dc.w $F408,  $1F,   $F,$FFEC; 20
		dc.w $F404,  $22,  $11,	   4; 24
word_A74E:	dc.w 6			; DATA XREF: ROM:0000A672o
		dc.w $F40D,    0,    0,$FFEC; 0
		dc.w  $40C,    8,    4,$FFEC; 4
		dc.w  $400,   $C,    6,	  $C; 8
		dc.w  $C04,   $D,    6,$FFF4; 12
		dc.w $F108,  $1A,   $D,$FFEC; 16
		dc.w $F104,  $1D,   $E,	   4; 20
word_A780:	dc.w 4			; DATA XREF: ROM:0000A674o
		dc.w $F40D,    0,    0,$FFEC; 0
		dc.w  $40C,    8,    4,$FFEC; 4
		dc.w  $400,   $C,    6,	  $C; 8
		dc.w  $C04,   $D,    6,$FFF4; 12
		dc.w $F408,  $1F,   $F,$FFEC; 16
		dc.w $F404,  $22,  $11,	   4; 20
Map_Obj23:	dc.w word_A7BA-Map_Obj23 ; DATA	XREF: ROM:0000A580o
					; ROM:Map_Obj23o ...
		dc.w word_A7C4-Map_Obj23
		dc.w word_A7CE-Map_Obj23
		dc.w word_A7D8-Map_Obj23
word_A7BA:	dc.w 1			; DATA XREF: ROM:Map_Obj23o
		dc.w $F805,  $24,  $12,$FFF8; 0
word_A7C4:	dc.w 1			; DATA XREF: ROM:0000A7B4o
		dc.w $F805,  $28,  $14,$FFF8; 0
word_A7CE:	dc.w 1			; DATA XREF: ROM:0000A7B6o
		dc.w $F805,  $2C,  $16,$FFF8; 0
word_A7D8:	dc.w 1			; DATA XREF: ROM:0000A7B8o
		dc.w $F805,  $33,  $19,$FFF8; 0
; ---------------------------------------------------------------------------
		nop
;----------------------------------------------------
; Object 25 - Rings
;----------------------------------------------------

Obj25:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj25_Index(pc,d0.w),d1
		jmp	Obj25_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj25_Index:	dc.w loc_A81C-Obj25_Index ; DATA XREF: ROM:Obj25_Indexo
					; ROM:0000A7F4o ...
		dc.w loc_A88A-Obj25_Index
		dc.w loc_A8A6-Obj25_Index
		dc.w loc_A8CC-Obj25_Index
		dc.w loc_A8DA-Obj25_Index
		dc.b $10,  0,$18,  0	; 0
		dc.b $20,  0,  0,$10	; 4
		dc.b   0,$18,  0,$20	; 8
		dc.b $10,$10,$18,$18	; 12
		dc.b $20,$20,$F0,$10	; 16
		dc.b $E8,$18,$E0,$20	; 20
		dc.b $10,  8,$18,$10	; 24
		dc.b $F0,  8,$E8,$10	; 28
; ---------------------------------------------------------------------------

loc_A81C:				; DATA XREF: ROM:Obj25_Indexo
		movea.l	a0,a1
		moveq	#0,d1
		move.w	8(a0),d2
		move.w	$C(a0),d3
		bra.s	loc_A832
; ---------------------------------------------------------------------------

loc_A82A:				; CODE XREF: ROM:0000A886j
		swap	d1
		bsr.w	SingleObjectLoad
		bne.s	loc_A88A

loc_A832:				; CODE XREF: ROM:0000A828j
		move.b	#$25,0(a1) 
		addq.b	#2,$24(a1)
		move.w	d2,8(a1)
		move.w	8(a0),$32(a1)
		move.w	d3,$C(a1)
		move.l	#Map_Obj25,4(a1)
		move.w	#$26BC,2(a1)
		bsr.w	ModifyA1SpriteAttr_2P
		move.b	#4,1(a1)
		move.b	#2,$18(a1)
		move.b	#$47,$20(a1) 
		move.b	#8,$19(a1)
		move.b	$23(a0),$23(a1)
		move.b	d1,$34(a1)
		addq.w	#1,d1
		add.w	d5,d2
		add.w	d6,d3
		swap	d1
		dbf	d1,loc_A82A

loc_A88A:				; CODE XREF: ROM:0000A830j
					; DATA XREF: ROM:0000A7F4o
		move.b	($FFFFFEC3).w,$1A(a0)
		move.w	$32(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.s	loc_A8DA
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_A8A6:				; DATA XREF: ROM:0000A7F6o
		addq.b	#2,$24(a0)
		move.b	#0,$20(a0)
		move.b	#1,$18(a0)
		bsr.w	sub_A8DE
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		move.b	$34(a0),d1
		bset	d1,2(a2,d0.w)

loc_A8CC:				; DATA XREF: ROM:0000A7F8o
		lea	(Ani_Obj25).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_A8DA:				; CODE XREF: ROM:0000A8A0j
					; DATA XREF: ROM:0000A7FAo
		bra.w	DeleteObject

; =============== S U B	R O U T	I N E =======================================


sub_A8DE:				; CODE XREF: ROM:0000A8B6p
					; ROM:0000AA5Cp ...
		addq.w	#1,($FFFFFE20).w
		ori.b	#1,($FFFFFE1D).w
		move.w	#$B5,d0	; "?"
		cmpi.w	#$64,($FFFFFE20).w 
		bcs.s	loc_A918
		bset	#1,($FFFFFE1B).w
		beq.s	loc_A90C
		cmpi.w	#$C8,($FFFFFE20).w 
		bcs.s	loc_A918
		bset	#2,($FFFFFE1B).w
		bne.s	loc_A918

loc_A90C:				; CODE XREF: sub_A8DE+1Cj
		addq.b	#1,($FFFFFE12).w
		addq.b	#1,($FFFFFE1C).w
		move.w	#bgm_ExtraLife,d0	; "?"

loc_A918:				; CODE XREF: sub_A8DE+14j sub_A8DE+24j ...
		jmp	(PlaySound_Special).l
; End of function sub_A8DE

; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 37 - Rings flying out of you when you get hit
;----------------------------------------------------

Obj37:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj37_Index(pc,d0.w),d1
		jmp	Obj37_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj37_Index:	dc.w loc_A936-Obj37_Index ; DATA XREF: ROM:Obj37_Indexo
					; ROM:0000A92Eo ...
		dc.w loc_A9FA-Obj37_Index
		dc.w loc_AA4C-Obj37_Index
		dc.w loc_AA60-Obj37_Index
		dc.w loc_AA6E-Obj37_Index
; ---------------------------------------------------------------------------

loc_A936:				; DATA XREF: ROM:Obj37_Indexo
		movea.l	a0,a1
		moveq	#0,d5
		move.w	($FFFFFE20).w,d5
		moveq	#$20,d0	
		cmp.w	d0,d5
		bcs.s	loc_A946
		move.w	d0,d5

loc_A946:				; CODE XREF: ROM:0000A942j
		subq.w	#1,d5
		move.w	#$288,d4
		bra.s	loc_A956
; ---------------------------------------------------------------------------

loc_A94E:				; CODE XREF: ROM:0000A9DAj
		bsr.w	SingleObjectLoad
		bne.w	loc_A9DE

loc_A956:				; CODE XREF: ROM:0000A94Cj
		move.b	#$37,0(a1) 
		addq.b	#2,$24(a1)
		move.b	#8,$16(a1)
		move.b	#8,$17(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.l	#Map_Obj25,4(a1)
		move.w	#$26BC,2(a1)
		bsr.w	ModifyA1SpriteAttr_2P
		move.b	#4,1(a1)
		move.b	#3,$18(a1)
		move.b	#$47,$20(a1)
		move.b	#8,$19(a1)
		move.b	#$FF,($FFFFFEC6).w
		tst.w	d4
		bmi.s	loc_A9CE
		move.w	d4,d0
		bsr.w	CalcSine
		move.w	d4,d2
		lsr.w	#8,d2
		asl.w	d2,d0
		asl.w	d2,d1
		move.w	d0,d2
		move.w	d1,d3
		addi.b	#$10,d4
		bcc.s	loc_A9CE
		subi.w	#$80,d4	
		bcc.s	loc_A9CE
		move.w	#$288,d4

loc_A9CE:				; CODE XREF: ROM:0000A9AAj
					; ROM:0000A9C2j ...
		move.w	d2,$10(a1)
		move.w	d3,$12(a1)
		neg.w	d2
		neg.w	d4
		dbf	d5,loc_A94E

loc_A9DE:				; CODE XREF: ROM:0000A952j
		move.w	#0,($FFFFFE20).w
		move.b	#$80,($FFFFFE1D).w
		move.b	#0,($FFFFFE1B).w
		move.w	#sfx_RingLoss,d0	; "?"
		jsr	(PlaySound_Special).l

loc_A9FA:				; DATA XREF: ROM:0000A92Eo
		move.b	($FFFFFEC7).w,$1A(a0)
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		bmi.s	loc_AA34
		move.b	($FFFFFE0F).w,d0
		add.b	d7,d0
		andi.b	#3,d0
		bne.s	loc_AA34
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	loc_AA34
		add.w	d1,$C(a0)
		move.w	$12(a0),d0
		asr.w	#2,d0
		sub.w	d0,$12(a0)
		neg.w	$12(a0)

loc_AA34:				; CODE XREF: ROM:0000AA0Aj
					; ROM:0000AA16j ...
		tst.b	($FFFFFEC6).w
		beq.s	loc_AA6E
		move.w	($FFFFEECE).w,d0
		addi.w	#$E0,d0	
		cmp.w	$C(a0),d0
		bcs.s	loc_AA6E
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_AA4C:				; DATA XREF: ROM:0000A930o
		addq.b	#2,$24(a0)
		move.b	#0,$20(a0)
		move.b	#1,$18(a0)
		bsr.w	sub_A8DE

loc_AA60:				; DATA XREF: ROM:0000A932o
		lea	(Ani_Obj25).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_AA6E:				; CODE XREF: ROM:0000AA38j
					; ROM:0000AA46j
					; DATA XREF: ...
		bra.w	DeleteObject
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Sonic	1 Object 4B - leftover giant ring code
;----------------------------------------------------

S1Obj4B:
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	S1Obj4B_Index(pc,d0.w),d1
		jmp	S1Obj4B_Index(pc,d1.w)
; ---------------------------------------------------------------------------
S1Obj4B_Index:	dc.w loc_AA88-S1Obj4B_Index ; DATA XREF: ROM:S1Obj4B_Indexo
					; ROM:0000AA82o ...
		dc.w loc_AAD6-S1Obj4B_Index
		dc.w loc_AAF4-S1Obj4B_Index
		dc.w loc_AB38-S1Obj4B_Index
; ---------------------------------------------------------------------------

loc_AA88:				; DATA XREF: ROM:S1Obj4B_Indexo
		move.l	#Map_S1Obj4B,4(a0)
		move.w	#$2400,2(a0)
		bsr.w	ModifySpriteAttr_2P
		ori.b	#4,1(a0)
		move.b	#$40,$19(a0) 
		tst.b	1(a0)
		bpl.s	loc_AAD6
		cmpi.b	#6,($FFFFFE57).w
		beq.w	loc_AB38
		cmpi.w	#$32,($FFFFFE20).w 
		bcc.s	loc_AAC0
		rts
; ---------------------------------------------------------------------------

loc_AAC0:				; CODE XREF: ROM:0000AABCj
		addq.b	#2,$24(a0)
		move.b	#2,$18(a0)
		move.b	#$52,$20(a0) 
		move.w	#$C40,($FFFFF7BE).w

loc_AAD6:				; CODE XREF: ROM:0000AAAAj
					; ROM:0000AB36j
					; DATA XREF: ...
		move.b	($FFFFFEC3).w,$1A(a0)
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_AAF4:				; DATA XREF: ROM:0000AA84o
		subq.b	#2,$24(a0)
		move.b	#0,$20(a0)
		bsr.w	SingleObjectLoad
		bne.w	loc_AB2C
		move.b	#$7C,0(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.l	a0,$3C(a1)
		move.w	(v_objspace+8).w,d0
		cmp.w	8(a0),d0
		bcs.s	loc_AB2C
		bset	#0,1(a1)

loc_AB2C:				; CODE XREF: ROM:0000AB02j
					; ROM:0000AB24j
		move.w	#sfx_GiantRing,d0	; "?"
		jsr	(PlaySound_Special).l
		bra.s	loc_AAD6
; ---------------------------------------------------------------------------

loc_AB38:				; CODE XREF: ROM:0000AAB2j
					; DATA XREF: ROM:0000AA86o
		bra.w	DeleteObject
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Sonic	1 Object 7C - leftover giant flash when	you
;   collected the giant	ring
;----------------------------------------------------

Obj_S1Obj7C:
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj_S1Obj7C_Index(pc,d0.w),d1
		jmp	Obj_S1Obj7C_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj_S1Obj7C_Index:dc.w loc_AB50-Obj_S1Obj7C_Index ; DATA XREF: ROM:Obj_S1Obj7C_Indexo
					; ROM:0000AB4Co ...
		dc.w loc_AB7E-Obj_S1Obj7C_Index
		dc.w loc_ABE6-Obj_S1Obj7C_Index
; ---------------------------------------------------------------------------

loc_AB50:				; DATA XREF: ROM:Obj_S1Obj7C_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_S1Obj7C,4(a0)
		move.w	#$2462,2(a0)
		bsr.w	ModifySpriteAttr_2P
		ori.b	#4,1(a0)
		move.b	#0,$18(a0)
		move.b	#$20,$19(a0)
		move.b	#$FF,$1A(a0)

loc_AB7E:				; DATA XREF: ROM:0000AB4Co
		bsr.s	sub_AB98
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite

; =============== S U B	R O U T	I N E =======================================


sub_AB98:				; CODE XREF: ROM:loc_AB7Ep
		subq.b	#1,$1E(a0)
		bpl.s	locret_ABD6
		move.b	#1,$1E(a0)
		addq.b	#1,$1A(a0)
		cmpi.b	#8,$1A(a0)
		bcc.s	loc_ABD8
		cmpi.b	#3,$1A(a0)
		bne.s	locret_ABD6
		movea.l	$3C(a0),a1
		move.b	#6,$24(a1)
		move.b	#$1C,(v_objspace+$1C).w
		move.b	#1,($FFFFF7CD).w
		clr.b	($FFFFFE2D).w
		clr.b	($FFFFFE2C).w

locret_ABD6:				; CODE XREF: sub_AB98+4j sub_AB98+1Ej
		rts
; ---------------------------------------------------------------------------

loc_ABD8:				; CODE XREF: sub_AB98+16j
		addq.b	#2,$24(a0)
		move.w	#0,(v_objspace).w
		addq.l	#4,sp
		rts
; End of function sub_AB98

; ---------------------------------------------------------------------------

loc_ABE6:				; DATA XREF: ROM:0000AB4Eo
		bra.w	DeleteObject
; ---------------------------------------------------------------------------
Ani_Obj25:	dc.w byte_ABEC-Ani_Obj25 ; DATA	XREF: ROM:loc_A8CCo
					; ROM:loc_AA60o ...
byte_ABEC:	dc.b   5,  4,  5,  6,  7,$FC; 0	; DATA XREF: ROM:Ani_Obj25o
Map_Obj25:	dc.w word_AC04-Map_Obj25 ; DATA	XREF: ROM:0000A84Ao
					; ROM:0000A978o ...
		dc.w word_AC0E-Map_Obj25
		dc.w word_AC18-Map_Obj25
		dc.w word_AC22-Map_Obj25
		dc.w word_AC2C-Map_Obj25
		dc.w word_AC36-Map_Obj25
		dc.w word_AC40-Map_Obj25
		dc.w word_AC4A-Map_Obj25
		dc.w word_AC54-Map_Obj25
word_AC04:	dc.w 1			; DATA XREF: ROM:Map_Obj25o
		dc.w $F805,    0,    0,$FFF8; 0
word_AC0E:	dc.w 1			; DATA XREF: ROM:0000ABF4o
		dc.w $F805,    4,    2,$FFF8; 0
word_AC18:	dc.w 1			; DATA XREF: ROM:0000ABF6o
		dc.w $F801,    8,    4,$FFFC; 0
word_AC22:	dc.w 1			; DATA XREF: ROM:0000ABF8o
		dc.w $F805, $804, $802,$FFF8; 0
word_AC2C:	dc.w 1			; DATA XREF: ROM:0000ABFAo
		dc.w $F805,   $A,    5,$FFF8; 0
word_AC36:	dc.w 1			; DATA XREF: ROM:0000ABFCo
		dc.w $F805,$180A,$1805,$FFF8; 0
word_AC40:	dc.w 1			; DATA XREF: ROM:0000ABFEo
		dc.w $F805, $80A, $805,$FFF8; 0
word_AC4A:	dc.w 1			; DATA XREF: ROM:0000AC00o
		dc.w $F805,$100A,$1005,$FFF8; 0
word_AC54:	dc.w 0			; DATA XREF: ROM:0000AC02o
Map_S1Obj4B:	dc.w word_AC5E-Map_S1Obj4B ; DATA XREF:	ROM:loc_AA88o
					; ROM:Map_S1Obj4Bo ...
		dc.w word_ACB0-Map_S1Obj4B
		dc.w word_ACF2-Map_S1Obj4B
		dc.w word_AD14-Map_S1Obj4B
word_AC5E:	dc.w $A			; DATA XREF: ROM:Map_S1Obj4Bo
		dc.w $E008,    0,    0,$FFE8; 0
		dc.w $E008,    3,    1,	   0; 4
		dc.w $E80C,    6,    3,$FFE0; 8
		dc.w $E80C,   $A,    5,	   0; 12
		dc.w $F007,   $E,    7,$FFE0; 16
		dc.w $F007,  $16,   $B,	 $10; 20
		dc.w $100C,  $1E,   $F,$FFE0; 24
		dc.w $100C,  $22,  $11,	   0; 28
		dc.w $1808,  $26,  $13,$FFE8; 32
		dc.w $1808,  $29,  $14,	   0; 36
word_ACB0:	dc.w 8			; DATA XREF: ROM:0000AC58o
		dc.w $E00C,  $2C,  $16,$FFF0; 0
		dc.w $E808,  $30,  $18,$FFE8; 4
		dc.w $E809,  $33,  $19,	   0; 8
		dc.w $F007,  $39,  $1C,$FFE8; 12
		dc.w $F805,  $41,  $20,	   8; 16
		dc.w  $809,  $45,  $22,	   0; 20
		dc.w $1008,  $4B,  $25,$FFE8; 24
		dc.w $180C,  $4E,  $27,$FFF0; 28
word_ACF2:	dc.w 4			; DATA XREF: ROM:0000AC5Ao
		dc.w $E007,  $52,  $29,$FFF4; 0
		dc.w $E003, $852, $829,	   4; 4
		dc.w	 7,  $5A,  $2D,$FFF4; 8
		dc.w	 3, $85A, $82D,	   4; 12
word_AD14:	dc.w 8			; DATA XREF: ROM:0000AC5Co
		dc.w $E00C, $82C, $816,$FFF0; 0
		dc.w $E808, $830, $818,	   0; 4
		dc.w $E809, $833, $819,$FFE8; 8
		dc.w $F007, $839, $81C,	   8; 12
		dc.w $F805, $841, $820,$FFE8; 16
		dc.w  $809, $845, $822,$FFE8; 20
		dc.w $1008, $84B, $825,	   0; 24
		dc.w $180C, $84E, $827,$FFF0; 28
Map_S1Obj7C:	dc.w word_AD66-Map_S1Obj7C ; DATA XREF:	ROM:0000AB54o
					; ROM:Map_S1Obj7Co ...
		dc.w word_AD78-Map_S1Obj7C
		dc.w word_AD9A-Map_S1Obj7C
		dc.w word_ADBC-Map_S1Obj7C
		dc.w word_ADDE-Map_S1Obj7C
		dc.w word_AE00-Map_S1Obj7C
		dc.w word_AE22-Map_S1Obj7C
		dc.w word_AE34-Map_S1Obj7C
word_AD66:	dc.w 2			; DATA XREF: ROM:Map_S1Obj7Co
		dc.w $E00F,    0,    0,	   0; 0
		dc.w	$F,$1000,$1000,	   0; 4
word_AD78:	dc.w 4			; DATA XREF: ROM:0000AD58o
		dc.w $E00F,  $10,    8,$FFF0; 0
		dc.w $E007,  $20,  $10,	 $10; 4
		dc.w	$F,$1010,$1008,$FFF0; 8
		dc.w	 7,$1020,$1010,	 $10; 12
word_AD9A:	dc.w 4			; DATA XREF: ROM:0000AD5Ao
		dc.w $E00F,  $28,  $14,$FFE8; 0
		dc.w $E00B,  $38,  $1C,	   8; 4
		dc.w	$F,$1028,$1014,$FFE8; 8
		dc.w	$B,$1038,$101C,	   8; 12
word_ADBC:	dc.w 4			; DATA XREF: ROM:0000AD5Co
		dc.w $E00F, $834, $81A,$FFE0; 0
		dc.w $E00F,  $34,  $1A,	   0; 4
		dc.w	$F,$1834,$181A,$FFE0; 8
		dc.w	$F,$1034,$101A,	   0; 12
word_ADDE:	dc.w 4			; DATA XREF: ROM:0000AD5Eo
		dc.w $E00B, $838, $81C,$FFE0; 0
		dc.w $E00F, $828, $814,$FFF8; 4
		dc.w	$B,$1838,$181C,$FFE0; 8
		dc.w	$F,$1828,$1814,$FFF8; 12
word_AE00:	dc.w 4			; DATA XREF: ROM:0000AD60o
		dc.w $E007, $820, $810,$FFE0; 0
		dc.w $E00F, $810, $808,$FFF0; 4
		dc.w	 7,$1820,$1810,$FFE0; 8
		dc.w	$F,$1810,$1808,$FFF0; 12
word_AE22:	dc.w 2			; DATA XREF: ROM:0000AD62o
		dc.w $E00F, $800, $800,$FFE0; 0
		dc.w	$F,$1800,$1800,$FFE0; 4
word_AE34:	dc.w 4			; DATA XREF: ROM:0000AD64o
		dc.w $E00F,  $44,  $22,$FFE0; 0
		dc.w $E00F, $844, $822,	   0; 4
		dc.w	$F,$1044,$1022,$FFE0; 8
		dc.w	$F,$1844,$1822,	   0; 12
; ---------------------------------------------------------------------------
		nop
;----------------------------------------------------
; Object 26 - monitor
;----------------------------------------------------

Obj26:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj26_Index(pc,d0.w),d1
		jmp	Obj26_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj26_Index:	dc.w loc_AE70-Obj26_Index ; DATA XREF: ROM:Obj26_Indexo
					; ROM:0000AE68o ...
		dc.w loc_AED6-Obj26_Index
		dc.w loc_AFDC-Obj26_Index
		dc.w loc_AFBA-Obj26_Index
		dc.w loc_AFC4-Obj26_Index
; ---------------------------------------------------------------------------

loc_AE70:				; DATA XREF: ROM:Obj26_Indexo
		addq.b	#2,$24(a0)
		move.b	#$E,$16(a0)
		move.b	#$E,$17(a0)
		move.l	#Map_Obj26,4(a0)
		move.w	#$680,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#$F,$19(a0)
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		bclr	#7,2(a2,d0.w)
		btst	#0,2(a2,d0.w)
		beq.s	loc_AECA
		move.b	#8,$24(a0)
		move.b	#$B,$1A(a0)
		rts
; ---------------------------------------------------------------------------

loc_AECA:				; CODE XREF: ROM:0000AEBAj
		move.b	#$46,$20(a0)
		move.b	$28(a0),$1C(a0)

loc_AED6:				; DATA XREF: ROM:0000AE68o
		move.b	$25(a0),d0
		beq.s	loc_AF30
		subq.b	#2,d0
		bne.s	loc_AF10
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		bsr.w	sub_F9C8
		btst	#3,$22(a1)
		bne.w	loc_AF00
		clr.b	$25(a0)
		bra.w	loc_AFBA
; ---------------------------------------------------------------------------

loc_AF00:				; CODE XREF: ROM:0000AEF4j
		move.w	#$10,d3
		move.w	8(a0),d2
		bsr.w	sub_F70E
		bra.w	loc_AFBA
; ---------------------------------------------------------------------------

loc_AF10:				; CODE XREF: ROM:0000AEDEj
		bsr.w	ObjectFall
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.w	loc_AFBA
		add.w	d1,$C(a0)
		clr.w	$12(a0)
		clr.b	$25(a0)
		bra.w	loc_AFBA
; ---------------------------------------------------------------------------

loc_AF30:				; CODE XREF: ROM:0000AEDAj
		move.w	#$1A,d1
		move.w	#$F,d2
		bsr.w	Obj26_SolidSides
		beq.w	loc_AFA0
		tst.w	$12(a1)
		bmi.s	loc_AF4E
		cmpi.b	#2,$1C(a1)
		beq.s	loc_AFA0

loc_AF4E:				; CODE XREF: ROM:0000AF44j
		tst.w	d1
		bpl.s	loc_AF64
		sub.w	d3,$C(a1)
		bsr.w	sub_F8F8
		move.b	#2,$25(a0)
		bra.w	loc_AFBA
; ---------------------------------------------------------------------------

loc_AF64:				; CODE XREF: ROM:0000AF50j
		tst.w	d0
		beq.w	loc_AF8A
		bmi.s	loc_AF74
		tst.w	$10(a1)
		bmi.s	loc_AF8A
		bra.s	loc_AF7A
; ---------------------------------------------------------------------------

loc_AF74:				; CODE XREF: ROM:0000AF6Aj
		tst.w	$10(a1)
		bpl.s	loc_AF8A

loc_AF7A:				; CODE XREF: ROM:0000AF72j
		sub.w	d0,8(a1)
		move.w	#0,$14(a1)
		move.w	#0,$10(a1)

loc_AF8A:				; CODE XREF: ROM:0000AF66j
					; ROM:0000AF70j ...
		btst	#1,$22(a1)
		bne.s	loc_AFAE
		bset	#5,$22(a1)
		bset	#5,$22(a0)
		bra.s	loc_AFBA
; ---------------------------------------------------------------------------

loc_AFA0:				; CODE XREF: ROM:0000AF3Cj
					; ROM:0000AF4Cj
		btst	#5,$22(a0)
		beq.s	loc_AFBA
		move.w	#1,$1C(a1)

loc_AFAE:				; CODE XREF: ROM:0000AF90j
		bclr	#5,$22(a0)
		bclr	#5,$22(a1)

loc_AFBA:				; CODE XREF: ROM:0000AEFCj
					; ROM:0000AF0Cj ...
		lea	(Ani_Obj26).l,a1
		bsr.w	AnimateSprite

loc_AFC4:				; DATA XREF: ROM:0000AE6Eo
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_AFDC:				; DATA XREF: ROM:0000AE6Ao
		addq.b	#2,$24(a0)
		move.b	#0,$20(a0)
		bsr.w	SingleObjectLoad
		bne.s	loc_B004
		move.b	#$2E,0(a1) 
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	$1C(a0),$1C(a1)

loc_B004:				; CODE XREF: ROM:0000AFEAj
		bsr.w	SingleObjectLoad
		bne.s	loc_B020
		move.b	#$27,0(a1) 
		addq.b	#2,$24(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)

loc_B020:				; CODE XREF: ROM:0000B008j
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		bset	#0,2(a2,d0.w)
		move.b	#$A,$1C(a0)
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 2E - contents of monitors
;----------------------------------------------------

Obj2E:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj2E_Index(pc,d0.w),d1
		jmp	Obj2E_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj2E_Index:	dc.w loc_B04E-Obj2E_Index ; DATA XREF: ROM:Obj2E_Indexo
					; ROM:0000B04Ao ...
		dc.w loc_B092-Obj2E_Index
		dc.w loc_B1AA-Obj2E_Index
; ---------------------------------------------------------------------------

loc_B04E:				; DATA XREF: ROM:Obj2E_Indexo
		addq.b	#2,$24(a0)
		move.w	#$680,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#$24,1(a0) 
		move.b	#3,$18(a0)
		move.b	#8,$19(a0)
		move.w	#$FD00,$12(a0)
		moveq	#0,d0
		move.b	$1C(a0),d0
		addq.b	#1,d0
		move.b	d0,$1A(a0)
		movea.l	#Map_Obj26,a1
		add.b	d0,d0
		adda.w	(a1,d0.w),a1
		addq.w	#2,a1
		move.l	a1,4(a0)

loc_B092:				; DATA XREF: ROM:0000B04Ao
		bsr.s	sub_B098
		bra.w	DisplaySprite

; =============== S U B	R O U T	I N E =======================================


sub_B098:				; CODE XREF: ROM:loc_B092p
		tst.w	$12(a0)
		bpl.w	loc_B0AC
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		rts
; ---------------------------------------------------------------------------

loc_B0AC:				; CODE XREF: sub_B098+4j
		addq.b	#2,$24(a0)
		move.w	#$1D,$1E(a0)
		moveq	#0,d0
		move.b	$1C(a0),d0
		add.w	d0,d0
		move.w	Monitor_Subroutines(pc,d0.w),d0
		jmp	Monitor_Subroutines(pc,d0.w)
; End of function sub_B098

; ---------------------------------------------------------------------------
Monitor_Subroutines:dc.w Monitor_Null-Monitor_Subroutines
					; DATA XREF: ROM:Monitor_Subroutineso
					; ROM:0000B0C8o ...
		dc.w Monitor_SonicLife-Monitor_Subroutines
		dc.w Monitor_TailsLife-Monitor_Subroutines
		dc.w Monitor_Null-Monitor_Subroutines
		dc.w Monitor_Rigns-Monitor_Subroutines
		dc.w Monitor_Shoes-Monitor_Subroutines
		dc.w Monitor_Shield-Monitor_Subroutines
		dc.w Monitor_Invincibility-Monitor_Subroutines
		dc.w Monitor_Null-Monitor_Subroutines
		dc.w Monitor_Null-Monitor_Subroutines
; ---------------------------------------------------------------------------

Monitor_Null:				; DATA XREF: ROM:Monitor_Subroutineso
					; ROM:0000B0CCo ...
		rts
; ---------------------------------------------------------------------------

Monitor_SonicLife:			; CODE XREF: ROM:0000B11Aj
					; ROM:0000B12Cj
					; DATA XREF: ...
		addq.b	#1,($FFFFFE12).w
		addq.b	#1,($FFFFFE1C).w
		move.w	#bgm_ExtraLife,d0	; "?"
		jmp	(PlaySound).l
; ---------------------------------------------------------------------------

Monitor_TailsLife:			; DATA XREF: ROM:0000B0CAo
		addq.b	#1,($FFFFFE12).w
		addq.b	#1,($FFFFFE1C).w
		move.w	#bgm_ExtraLife,d0	; "?"
		jmp	(PlaySound).l
; ---------------------------------------------------------------------------

Monitor_Rigns:				; DATA XREF: ROM:0000B0CEo
		addi.w	#$A,($FFFFFE20).w
		ori.b	#1,($FFFFFE1D).w
		cmpi.w	#$64,($FFFFFE20).w 
		bcs.s	loc_B130
		bset	#1,($FFFFFE1B).w
		beq.w	Monitor_SonicLife
		cmpi.w	#$C8,($FFFFFE20).w
		bcs.s	loc_B130
		bset	#2,($FFFFFE1B).w
		beq.w	Monitor_SonicLife

loc_B130:				; CODE XREF: ROM:0000B112j
					; ROM:0000B124j
		move.w	#sfx_Ring,d0	; "?"
		jmp	(PlaySound).l
; ---------------------------------------------------------------------------

Monitor_Shoes:				; DATA XREF: ROM:0000B0D0o
		move.b	#1,($FFFFFE2E).w
		move.w	#$4B0,(v_objspace+$34).w
		move.w	#$C00,($FFFFF760).w
		move.w	#$18,($FFFFF762).w
		move.w	#$80,($FFFFF764).w
		move.w	#bgm_Speedup,d0	; "?"
		jmp	(PlaySound).l
; ---------------------------------------------------------------------------

Monitor_Shield:				; DATA XREF: ROM:0000B0D2o
		move.b	#1,($FFFFFE2C).w
		move.b	#$38,(v_objspace+$180).w 
		move.w	#sfx_Shield,d0	; "?"
		jmp	(PlaySound).l
; ---------------------------------------------------------------------------

Monitor_Invincibility:			; DATA XREF: ROM:0000B0D4o
		move.b	#1,($FFFFFE2D).w
		move.w	#$4B0,(v_objspace+$32).w
		move.b	#$38,(v_objspace+$200).w
		move.b	#1,(v_objspace+$21C).w
		tst.b	($FFFFF7AA).w
		bne.s	locret_B1A8
		cmpi.w	#$C,($FFFFFE14).w
		bls.s	locret_B1A8
		move.w	#bgm_Invincible,d0	; "?"
		jmp	(PlaySound).l
; ---------------------------------------------------------------------------

locret_B1A8:				; CODE XREF: ROM:0000B194j
					; ROM:0000B19Cj
		rts
; ---------------------------------------------------------------------------

loc_B1AA:				; DATA XREF: ROM:0000B04Co
		subq.w	#1,$1E(a0)
		bmi.w	DeleteObject
		bra.w	DisplaySprite

; =============== S U B	R O U T	I N E =======================================


Obj26_SolidSides:			; CODE XREF: ROM:0000AF38p
		lea	(v_objspace).w,a1
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_B20E
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.s	loc_B20E
		move.b	$16(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	$C(a1),d3
		sub.w	$C(a0),d3
		add.w	d2,d3
		bmi.s	loc_B20E
		add.w	d2,d2
		cmp.w	d2,d3
		bcc.s	loc_B20E
		tst.b	($FFFFF7C8).w
		bmi.s	loc_B20E
		cmpi.b	#6,(v_objspace+$24).w
		bcc.s	loc_B20E
		tst.w	($FFFFFE08).w
		bne.s	loc_B20E
		cmp.w	d0,d1
		bcc.s	loc_B204
		add.w	d1,d1
		sub.w	d1,d0

loc_B204:				; CODE XREF: Obj26_SolidSides+48j
		cmpi.w	#$10,d3
		bcs.s	loc_B212

loc_B20A:				; CODE XREF: Obj26_SolidSides+70j
					; Obj26_SolidSides+74j
		moveq	#1,d1
		rts
; ---------------------------------------------------------------------------

loc_B20E:				; CODE XREF: Obj26_SolidSides+Ej
					; Obj26_SolidSides+16j	...
		moveq	#0,d1
		rts
; ---------------------------------------------------------------------------

loc_B212:				; CODE XREF: Obj26_SolidSides+52j
		moveq	#0,d1
		move.b	$19(a0),d1
		addq.w	#4,d1
		move.w	d1,d2
		add.w	d2,d2
		add.w	8(a1),d1
		sub.w	8(a0),d1
		bmi.s	loc_B20A
		cmp.w	d2,d1
		bcc.s	loc_B20A
		moveq	#$FFFFFFFF,d1
		rts
; End of function Obj26_SolidSides

; ---------------------------------------------------------------------------
Ani_Obj26:	dc.w byte_B246-Ani_Obj26 ; DATA	XREF: ROM:loc_AFBAo
					; ROM:Ani_Obj26o ...
		dc.w byte_B24A-Ani_Obj26
		dc.w byte_B252-Ani_Obj26
		dc.w byte_B25A-Ani_Obj26
		dc.w byte_B262-Ani_Obj26
		dc.w byte_B26A-Ani_Obj26
		dc.w byte_B272-Ani_Obj26
		dc.w byte_B27A-Ani_Obj26
		dc.w byte_B282-Ani_Obj26
		dc.w byte_B28A-Ani_Obj26
		dc.w byte_B292-Ani_Obj26
byte_B246:	dc.b   1,  0,  1,$FF	; 0 ; DATA XREF: ROM:Ani_Obj26o
byte_B24A:	dc.b   1,  0,  2,  2,  1,  2,  2,$FF; 0	; DATA XREF: ROM:0000B232o
byte_B252:	dc.b   1,  0,  3,  3,  1,  3,  3,$FF; 0	; DATA XREF: ROM:0000B234o
byte_B25A:	dc.b   1,  0,  4,  4,  1,  4,  4,$FF; 0	; DATA XREF: ROM:0000B236o
byte_B262:	dc.b   1,  0,  5,  5,  1,  5,  5,$FF; 0	; DATA XREF: ROM:0000B238o
byte_B26A:	dc.b   1,  0,  6,  6,  1,  6,  6,$FF; 0	; DATA XREF: ROM:0000B23Ao
byte_B272:	dc.b   1,  0,  7,  7,  1,  7,  7,$FF; 0	; DATA XREF: ROM:0000B23Co
byte_B27A:	dc.b   1,  0,  8,  8,  1,  8,  8,$FF; 0	; DATA XREF: ROM:0000B23Eo
byte_B282:	dc.b   1,  0,  9,  9,  1,  9,  9,$FF; 0	; DATA XREF: ROM:0000B240o
byte_B28A:	dc.b   1,  0, $A, $A,  1, $A, $A,$FF; 0	; DATA XREF: ROM:0000B242o
byte_B292:	dc.b   2,  0,  1, $B,$FE,  1; 0	; DATA XREF: ROM:0000B244o
Map_Obj26:	dc.w word_B2B0-Map_Obj26 ; DATA	XREF: ROM:0000AE80o
					; ROM:Map_Obj26o ...
		dc.w word_B2BA-Map_Obj26
		dc.w word_B2CC-Map_Obj26
		dc.w word_B2DE-Map_Obj26
		dc.w word_B2F0-Map_Obj26
		dc.w word_B302-Map_Obj26
		dc.w word_B314-Map_Obj26
		dc.w word_B326-Map_Obj26
		dc.w word_B338-Map_Obj26
		dc.w word_B34A-Map_Obj26
		dc.w word_B35C-Map_Obj26
		dc.w word_B36E-Map_Obj26
word_B2B0:	dc.w 1			; DATA XREF: ROM:Map_Obj26o
		dc.w $EF0F,    0,    0,$FFF0; 0
word_B2BA:	dc.w 2			; DATA XREF: ROM:0000B29Ao
		dc.w $F505,  $18,   $C,$FFF8,$EF0F,    0,    0,$FFF0; 0
word_B2CC:	dc.w 2			; DATA XREF: ROM:0000B29Co
		dc.w $F505, $154,  $AA,$FFF8,$EF0F,    0,    0,$FFF0; 0
word_B2DE:	dc.w 2			; DATA XREF: ROM:0000B29Eo
		dc.w $F505,  $1C,   $E,$FFF8,$EF0F,    0,    0,$FFF0; 0
word_B2F0:	dc.w 2			; DATA XREF: ROM:0000B2A0o
		dc.w $F505,  $20,  $10,$FFF8,$EF0F,    0,    0,$FFF0; 0
word_B302:	dc.w 2			; DATA XREF: ROM:0000B2A2o
		dc.w $F505,$2024,$2012,$FFF8,$EF0F,    0,    0,$FFF0; 0
word_B314:	dc.w 2			; DATA XREF: ROM:0000B2A4o
		dc.w $F505,  $28,  $14,$FFF8,$EF0F,    0,    0,$FFF0; 0
word_B326:	dc.w 2			; DATA XREF: ROM:0000B2A6o
		dc.w $F505,  $2C,  $16,$FFF8,$EF0F,    0,    0,$FFF0; 0
word_B338:	dc.w 2			; DATA XREF: ROM:0000B2A8o
		dc.w $F505,  $30,  $18,$FFF8,$EF0F,    0,    0,$FFF0; 0
word_B34A:	dc.w 2			; DATA XREF: ROM:0000B2AAo
		dc.w $F505,  $34,  $1A,$FFF8,$EF0F,    0,    0,$FFF0; 0
word_B35C:	dc.w 2			; DATA XREF: ROM:0000B2ACo
		dc.w $F505,  $38,  $1C,$FFF8,$EF0F,    0,    0,$FFF0; 0
word_B36E:	dc.w 1			; DATA XREF: ROM:0000B2AEo
		dc.w $FF0D,  $10,    8,$FFF0; 0
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 0E - Sonic on title screen
;----------------------------------------------------

Obj0E:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj0E_Index(pc,d0.w),d1
		jmp	Obj0E_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj0E_Index:	dc.w loc_B38E-Obj0E_Index ; DATA XREF: ROM:Obj0E_Indexo
					; ROM:0000B388o ...
		dc.w loc_B3D0-Obj0E_Index
		dc.w loc_B3E4-Obj0E_Index
		dc.w loc_B3FA-Obj0E_Index
; ---------------------------------------------------------------------------

loc_B38E:				; DATA XREF: ROM:Obj0E_Indexo
		addq.b	#2,$24(a0)
		move.w	#$148,8(a0)
		move.w	#$C4,$A(a0) 
		move.l	#Map_Obj0E,4(a0)
		move.w	#$4200,2(a0)
		move.b	#1,$18(a0)
		move.b	#$1D,$1F(a0)
		tst.b	$1A(a0)
		beq.s	loc_B3D0
		move.w	#$FC,8(a0) ; "?"
		move.w	#$CC,$A(a0) ; "?"
		move.w	#$2200,2(a0)

loc_B3D0:				; CODE XREF: ROM:0000B3BCj
					; DATA XREF: ROM:0000B388o
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
		subq.b	#1,$1F(a0)
		bpl.s	locret_B3E2
		addq.b	#2,$24(a0)
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

locret_B3E2:				; CODE XREF: ROM:0000B3D8j
		rts
; ---------------------------------------------------------------------------

loc_B3E4:				; DATA XREF: ROM:0000B38Ao
		subi.w	#8,$A(a0)
		cmpi.w	#$96,$A(a0) ; "?"
		bne.s	loc_B3F6
		addq.b	#2,$24(a0)

loc_B3F6:				; CODE XREF: ROM:0000B3F0j
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_B3FA:				; DATA XREF: ROM:0000B38Co
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 0F - ???
;----------------------------------------------------

Obj0F:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj0F_Index(pc,d0.w),d1
		jsr	Obj0F_Index(pc,d1.w)
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Obj0F_Index:	dc.w loc_B416-Obj0F_Index ; DATA XREF: ROM:Obj0F_Indexo
					; ROM:0000B412o ...
		dc.w loc_B438-Obj0F_Index
		dc.w loc_B438-Obj0F_Index
; ---------------------------------------------------------------------------

loc_B416:				; DATA XREF: ROM:Obj0F_Indexo
		addq.b	#2,$24(a0)
		move.w	#$90,8(a0) ; "?"
		move.w	#$90,$A(a0) ; "?"
		move.l	#Map_Obj0F,4(a0)
		move.w	#$680,2(a0)
		bsr.w	ModifySpriteAttr_2P

loc_B438:				; DATA XREF: ROM:0000B412o
					; ROM:0000B414o
		move.b	(v_jpadpress1).w,d0
		btst	#5,d0
		beq.s	loc_B44C
		addq.b	#1,$1A(a0)
		andi.b	#$F,$1A(a0)

loc_B44C:				; CODE XREF: ROM:0000B440j
		btst	#4,d0
		beq.s	locret_B458
		bchg	#0,($FFFFFFE9).w

locret_B458:				; CODE XREF: ROM:0000B450j
		rts
; ---------------------------------------------------------------------------
Map_Obj0F:	dc.w word_B47A-Map_Obj0F ; DATA	XREF: ROM:0000B426o
					; ROM:Map_Obj0Fo ...
		dc.w word_B484-Map_Obj0F
		dc.w word_B48E-Map_Obj0F
		dc.w word_B498-Map_Obj0F
		dc.w word_B4A2-Map_Obj0F
		dc.w word_B4AC-Map_Obj0F
		dc.w word_B4B6-Map_Obj0F
		dc.w word_B4C0-Map_Obj0F
		dc.w word_B4CA-Map_Obj0F
		dc.w word_B4D4-Map_Obj0F
		dc.w word_B4DE-Map_Obj0F
		dc.w word_B4E8-Map_Obj0F
		dc.w word_B4F2-Map_Obj0F
		dc.w word_B4FC-Map_Obj0F
		dc.w word_B506-Map_Obj0F
		dc.w word_B510-Map_Obj0F
word_B47A:	dc.w 1			; DATA XREF: ROM:Map_Obj0Fo
		dc.w	 0,    0,    0,	   0; 0
word_B484:	dc.w 1			; DATA XREF: ROM:0000B45Co
		dc.w	 1,    0,    0,	   0; 0
word_B48E:	dc.w 1			; DATA XREF: ROM:0000B45Eo
		dc.w	 2,    0,    0,	   0; 0
word_B498:	dc.w 1			; DATA XREF: ROM:0000B460o
		dc.w	 3,    0,    0,	   0; 0
word_B4A2:	dc.w 1			; DATA XREF: ROM:0000B462o
		dc.w	 4,    0,    0,	   0; 0
word_B4AC:	dc.w 1			; DATA XREF: ROM:0000B464o
		dc.w	 5,    0,    0,	   0; 0
word_B4B6:	dc.w 1			; DATA XREF: ROM:0000B466o
		dc.w	 6,    0,    0,	   0; 0
word_B4C0:	dc.w 1			; DATA XREF: ROM:0000B468o
		dc.w	 7,    0,    0,	   0; 0
word_B4CA:	dc.w 1			; DATA XREF: ROM:0000B46Ao
		dc.w	 8,    0,    0,	   0; 0
word_B4D4:	dc.w 1			; DATA XREF: ROM:0000B46Co
		dc.w	 9,    0,    0,	   0; 0
word_B4DE:	dc.w 1			; DATA XREF: ROM:0000B46Eo
		dc.w	$A,    0,    0,	   0; 0
word_B4E8:	dc.w 1			; DATA XREF: ROM:0000B470o
		dc.w	$B,    0,    0,	   0; 0
word_B4F2:	dc.w 1			; DATA XREF: ROM:0000B472o
		dc.b   0, $C,  0,  0	; 0
		dc.b   0,  0,  0,  0	; 4
word_B4FC:	dc.w 1			; DATA XREF: ROM:0000B474o
		dc.b   0, $D,  0,  0	; 0
		dc.b   0,  0,  0,  0	; 4
word_B506:	dc.w 1			; DATA XREF: ROM:0000B476o
		dc.w	$E,    0,    0,	   0; 0
word_B510:	dc.w 1			; DATA XREF: ROM:0000B478o
		dc.w	$F,    0,    0,	   0; 0
off_B51A:	dc.w byte_B51C-off_B51A	; DATA XREF: ROM:off_B51Ao
byte_B51C:	dc.b   7,  0,  1,  2,  3,  4,  5,  6; 0	; DATA XREF: ROM:off_B51Ao
		dc.b   7,$FE,  2,  0	; 8
off_B528:	dc.w byte_B52A-off_B528	; DATA XREF: ROM:off_B528o
byte_B52A:	dc.b $1F,  0,  1,$FF	; 0 ; DATA XREF: ROM:off_B528o
Map_S1Obj0F:	dc.w word_B536-Map_S1Obj0F ; DATA XREF:	ROM:Map_S1Obj0Fo
					; ROM:0000B530o ...
					; leftover from	Sonic 1
		dc.w word_B538-Map_S1Obj0F ; leftover from Sonic 1
		dc.w word_B56A-Map_S1Obj0F ; leftover from Sonic 1
		dc.w word_B65C-Map_S1Obj0F ; leftover from Sonic 1
word_B536:	dc.w 0			; DATA XREF: ROM:Map_S1Obj0Fo
word_B538:	dc.w 6			; DATA XREF: ROM:0000B530o
		dc.w	$C,  $F0,  $78,	   0; 0
		dc.w	 0,  $F3,  $79,	 $20; 4
		dc.w	 0,  $F3,  $79,	 $30; 8
		dc.w	$C,  $F4,  $7A,	 $38; 12
		dc.w	 8,  $F8,  $7C,	 $60; 16
		dc.w	 8,  $FB,  $7D,	 $78; 20
word_B56A:	dc.w $1E		; DATA XREF: ROM:0000B532o
		dc.w $B80F,    0,    0,$FF80; 0
		dc.w $B80F,    0,    0,$FF80; 4
		dc.w $B80F,    0,    0,$FF80; 8
		dc.w $B80F,    0,    0,$FF80; 12
		dc.w $B80F,    0,    0,$FF80; 16
		dc.w $B80F,    0,    0,$FF80; 20
		dc.w $B80F,    0,    0,$FF80; 24
		dc.w $B80F,    0,    0,$FF80; 28
		dc.w $B80F,    0,    0,$FF80; 32
		dc.w $B80F,    0,    0,$FF80; 36
		dc.w $D80F,    0,    0,$FF80; 40
		dc.w $D80F,    0,    0,$FF80; 44
		dc.w $D80F,    0,    0,$FF80; 48
		dc.w $D80F,    0,    0,$FF80; 52
		dc.w $D80F,    0,    0,$FF80; 56
		dc.w $D80F,    0,    0,$FF80; 60
		dc.w $D80F,    0,    0,$FF80; 64
		dc.w $D80F,    0,    0,$FF80; 68
		dc.w $D80F,    0,    0,$FF80; 72
		dc.w $D80F,    0,    0,$FF80; 76
		dc.w $F80F,    0,    0,$FF80; 80
		dc.w $F80F,    0,    0,$FF80; 84
		dc.w $F80F,    0,    0,$FF80; 88
		dc.w $F80F,    0,    0,$FF80; 92
		dc.w $F80F,    0,    0,$FF80; 96
		dc.w $F80F,    0,    0,$FF80; 100
		dc.w $F80F,    0,    0,$FF80; 104
		dc.w $F80F,    0,    0,$FF80; 108
		dc.w $F80F,    0,    0,$FF80; 112
		dc.w $F80F,    0,    0,$FF80; 116
word_B65C:	dc.w 1			; DATA XREF: ROM:0000B534o
		dc.w $FC04,    0,    0,$FFF8; 0
Map_Obj0E:	dc.w word_B66A-Map_Obj0E ; DATA	XREF: ROM:0000B39Eo
					; ROM:Map_Obj0Eo ...
		dc.w word_B6C4-Map_Obj0E
word_B66A:	dc.w $B			; DATA XREF: ROM:Map_Obj0Eo
		dc.w $D40D,    0,    0,$FFD8; 0
		dc.w $CC0E,    8,    4,$FFF8; 4
		dc.w $CC07,  $14,   $A,	 $18; 8
		dc.w $E40F,  $1C,   $E,$FFE0; 12
		dc.w $E40B,  $2C,  $16,	   0; 16
		dc.w $EC07,  $38,  $1C,	 $18; 20
		dc.w  $40F,  $40,  $20,$FFD8; 24
		dc.w  $40F,  $50,  $28,$FFF8; 28
		dc.w  $C06,  $60,  $30,	 $18; 32
		dc.w $2404,  $66,  $33,$FFE8; 36
		dc.w $240D,  $68,  $34,$FFF8; 40
word_B6C4:	dc.w $A			; DATA XREF: ROM:0000B668o
		dc.w $DC06,  $70,  $38,$FFEC; 0
		dc.w $F40F,  $76,  $3B,$FFD4; 4
		dc.w $F40F,  $86,  $43,$FFF4; 8
		dc.w $E409,  $96,  $4B,$FFFC; 12
		dc.w $DC0B,  $9C,  $4E,	 $14; 16
		dc.w $FC08,  $A8,  $54,	 $14; 20
		dc.w  $405,  $AB,  $55,	 $14; 24
		dc.w $1404,  $AF,  $57,$FFD4; 28
		dc.w $140D,  $B1,  $58,$FFE4; 32
		dc.w $140D,  $B9,  $5C,	   4; 36
		dc.w $4E71		; 40
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 2B - GHZ Chopper Badnik
;----------------------------------------------------

Obj2B:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj2B_Index(pc,d0.w),d1
		jsr	Obj2B_Index(pc,d1.w)
		bra.w	MarkObjGone
; ---------------------------------------------------------------------------
Obj2B_Index:	dc.w loc_B72E-Obj2B_Index ; DATA XREF: ROM:Obj2B_Indexo
					; ROM:0000B72Co
		dc.w loc_B768-Obj2B_Index
; ---------------------------------------------------------------------------

loc_B72E:				; DATA XREF: ROM:Obj2B_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj2B,4(a0)
		move.w	#$470,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#9,$20(a0)
		move.b	#$10,$19(a0)
		move.w	#$F900,$12(a0)
		move.w	$C(a0),$30(a0)

loc_B768:				; DATA XREF: ROM:0000B72Co
		lea	(Ani_Obj2B).l,a1
		bsr.w	AnimateSprite
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		move.w	$30(a0),d0
		cmp.w	$C(a0),d0
		bcc.s	loc_B790
		move.w	d0,$C(a0)
		move.w	#$F900,$12(a0)

loc_B790:				; CODE XREF: ROM:0000B784j
		move.b	#1,$1C(a0)
		subi.w	#$C0,d0	
		cmp.w	$C(a0),d0
		bcc.s	locret_B7B2
		move.b	#0,$1C(a0)
		tst.w	$12(a0)
		bmi.s	locret_B7B2
		move.b	#2,$1C(a0)

locret_B7B2:				; CODE XREF: ROM:0000B79Ej
					; ROM:0000B7AAj
		rts
; ---------------------------------------------------------------------------
Ani_Obj2B:	dc.w byte_B7BA-Ani_Obj2B ; DATA	XREF: ROM:loc_B768o
					; ROM:Ani_Obj2Bo ...
		dc.w byte_B7BE-Ani_Obj2B
		dc.w byte_B7C2-Ani_Obj2B
byte_B7BA:	dc.b   7,  0,  1,$FF	; 0 ; DATA XREF: ROM:Ani_Obj2Bo
byte_B7BE:	dc.b   3,  0,  1,$FF	; 0 ; DATA XREF: ROM:0000B7B6o
byte_B7C2:	dc.b   7,  0,$FF,  0	; 0 ; DATA XREF: ROM:0000B7B8o
Map_Obj2B:	dc.w word_B7CA-Map_Obj2B ; DATA	XREF: ROM:0000B732o
					; ROM:Map_Obj2Bo ...
		dc.w word_B7D4-Map_Obj2B
word_B7CA:	dc.w 1			; DATA XREF: ROM:Map_Obj2Bo
		dc.w $F00F,    0,    0,$FFF0; 0
word_B7D4:	dc.w 1			; DATA XREF: ROM:0000B7C8o
		dc.w $F00F,  $10,    8,$FFF0; 0
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 2C - LZ Jaws Badnik
;----------------------------------------------------

Obj2C:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj2C_Index(pc,d0.w),d1
		jmp	Obj2C_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj2C_Index:	dc.w loc_B7F0-Obj2C_Index ; DATA XREF: ROM:Obj2C_Indexo
					; ROM:0000B7EEo
		dc.w loc_B842-Obj2C_Index
; ---------------------------------------------------------------------------

loc_B7F0:				; DATA XREF: ROM:Obj2C_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj2C,4(a0)
		move.w	#$2486,2(a0)
		bsr.w	ModifySpriteAttr_2P
		ori.b	#4,1(a0)
		move.b	#$A,$20(a0)
		move.b	#4,$18(a0)
		move.b	#$10,$19(a0)
		moveq	#0,d0
		move.b	$28(a0),d0
		lsl.w	#6,d0
		subq.w	#1,d0
		move.w	d0,$30(a0)
		move.w	d0,$32(a0)
		move.w	#$FFC0,$10(a0)
		btst	#0,$22(a0)
		beq.s	loc_B842
		neg.w	$10(a0)

loc_B842:				; CODE XREF: ROM:0000B83Cj
					; DATA XREF: ROM:0000B7EEo
		subq.w	#1,$30(a0)
		bpl.s	loc_B85E
		move.w	$32(a0),$30(a0)
		neg.w	$10(a0)
		bchg	#0,$22(a0)
		move.b	#1,$1D(a0)

loc_B85E:				; CODE XREF: ROM:0000B846j
		lea	(Ani_Obj2C).l,a1
		bsr.w	AnimateSprite
		bsr.w	SpeedToPos
		bra.w	MarkObjGone
; ---------------------------------------------------------------------------
Ani_Obj2C:	dc.b   0,  2,  7,  0,  1,  2,  3,$FF; 0	; DATA XREF: ROM:loc_B85Eo
Map_Obj2C:	dc.w word_B880-Map_Obj2C ; DATA	XREF: ROM:0000B7F4o
					; ROM:Map_Obj2Co ...
		dc.w word_B892-Map_Obj2C
		dc.w word_B8A4-Map_Obj2C
		dc.w word_B8B6-Map_Obj2C
word_B880:	dc.w 2			; DATA XREF: ROM:Map_Obj2Co
		dc.w $F40E,    0,    0,$FFF0; 0
		dc.w $F505,  $18,   $C,	 $10; 4
word_B892:	dc.w 2			; DATA XREF: ROM:0000B87Ao
		dc.w $F40E,   $C,    6,$FFF0; 0
		dc.w $F505,  $1C,   $E,	 $10; 4
word_B8A4:	dc.w 2			; DATA XREF: ROM:0000B87Co
		dc.w $F40E,    0,    0,$FFF0; 0
		dc.w $F505,$1018,$100C,	 $10; 4
word_B8B6:	dc.w 2			; DATA XREF: ROM:0000B87Eo
		dc.w $F40E,   $C,    6,$FFF0; 0
		dc.w $F505,$101C,$100E,	 $10; 4
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 34 - leftover Sonic 1 title cards
;----------------------------------------------------

Obj34:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj34_Index(pc,d0.w),d1
		jmp	Obj34_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj34_Index:	dc.w Obj34_CheckLZ4-Obj34_Index; 0 ; DATA XREF:	ROM:Obj34_Indexo
					; ROM:Obj34_Index+2o ...
		dc.w Obj34_CheckPos-Obj34_Index; 1
		dc.w Obj34_Wait-Obj34_Index; 2
		dc.w Obj34_Wait-Obj34_Index; 3
; ---------------------------------------------------------------------------

Obj34_CheckLZ4:				; DATA XREF: ROM:Obj34_Indexo
		movea.l	a0,a1
		moveq	#0,d0
		move.b	(v_zone).w,d0
		cmpi.w	#$103,(v_zone).w
		bne.s	Obj34_CheckFZ
		moveq	#5,d0

Obj34_CheckFZ:				; CODE XREF: ROM:0000B8ECj
		move.w	d0,d2
		cmpi.w	#$502,(v_zone).w
		bne.s	Obj34_CheckConfig
		moveq	#6,d0
		moveq	#$B,d2

Obj34_CheckConfig:			; CODE XREF: ROM:0000B8F8j
		lea	(Obj34_Config).l,a3
		lsl.w	#4,d0
		adda.w	d0,a3
		lea	(Obj34_ItemData).l,a2
		moveq	#3,d1

Obj34_Loop:				; CODE XREF: ROM:0000B976j
		move.b	#$34,0(a1)
		move.w	(a3),8(a1)
		move.w	(a3)+,$32(a1)
		move.w	(a3)+,$30(a1)
		move.w	(a2)+,$A(a1)
		move.b	(a2)+,$24(a1)
		move.b	(a2)+,d0
		bne.s	Obj34_ActNumber
		move.b	d2,d0

Obj34_ActNumber:			; CODE XREF: ROM:0000B92Cj
		cmpi.b	#7,d0
		bne.s	Obj34_MakeSprite
		add.b	($FFFFFE11).w,d0
		cmpi.b	#3,($FFFFFE11).w
		bne.s	Obj34_MakeSprite
		subq.b	#1,d0

Obj34_MakeSprite:			; CODE XREF: ROM:0000B934j
					; ROM:0000B940j
		move.b	d0,$1A(a1)
		move.l	#Map_Obj34,4(a1)
		move.w	#$8580,2(a1)
		bsr.w	ModifyA1SpriteAttr_2P
		move.b	#$78,$19(a1) 
		move.b	#0,1(a1)
		move.b	#0,$18(a1)
		move.w	#$3C,$1E(a1) 
		lea	$40(a1),a1
		dbf	d1,Obj34_Loop

Obj34_CheckPos:				; DATA XREF: ROM:Obj34_Indexo
		moveq	#$10,d1
		move.w	$30(a0),d0
		cmp.w	8(a0),d0
		beq.s	loc_B98E
		bge.s	Obj34_Move
		neg.w	d1

Obj34_Move:				; CODE XREF: ROM:0000B986j
		add.w	d1,8(a0)

loc_B98E:				; CODE XREF: ROM:0000B984j
		move.w	8(a0),d0
		bmi.s	Obj34_NoDisplay
		cmpi.w	#$200,d0
		bcc.s	Obj34_NoDisplay
		rts
; ---------------------------------------------------------------------------
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

Obj34_NoDisplay:			; CODE XREF: ROM:0000B992j
					; ROM:0000B998j
		rts
; ---------------------------------------------------------------------------

Obj34_Wait:				; DATA XREF: ROM:Obj34_Indexo
		tst.w	$1E(a0)
		beq.s	Obj34_CheckPos2
		subq.w	#1,$1E(a0)
		rts
; ---------------------------------------------------------------------------
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

Obj34_CheckPos2:			; CODE XREF: ROM:0000B9A6j
		tst.b	1(a0)
		bpl.s	Obj34_ChangeArt
		moveq	#$20,d1	
		move.w	$32(a0),d0
		cmp.w	8(a0),d0
		beq.s	Obj34_ChangeArt
		bge.s	Obj34_Move2
		neg.w	d1

Obj34_Move2:				; CODE XREF: ROM:0000B9C4j
		add.w	d1,8(a0)
		move.w	8(a0),d0
		bmi.s	Obj34_NoDisplay2
		cmpi.w	#$200,d0
		bcc.s	Obj34_NoDisplay2
		rts
; ---------------------------------------------------------------------------
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

Obj34_NoDisplay2:			; CODE XREF: ROM:0000B9D0j
					; ROM:0000B9D6j
		rts
; ---------------------------------------------------------------------------

Obj34_ChangeArt:			; CODE XREF: ROM:0000B9B6j
					; ROM:0000B9C2j
		cmpi.b	#4,$24(a0)
		bne.s	Obj34_Delete
		moveq	#plcid_Explode,d0
		jsr	(LoadPLC).l
		moveq	#0,d0
		move.b	(v_zone).w,d0
		addi.w	#plcid_GHZAnimals,d0
		jsr	(LoadPLC).l

Obj34_Delete:				; CODE XREF: ROM:0000B9E6j
		bra.w	DeleteObject
; ---------------------------------------------------------------------------
Obj34_ItemData:	dc.w $D0		; DATA XREF: ROM:0000B908o
		dc.b   2,  0		; 0
		dc.w $E4
		dc.b   2,  6		; 0
		dc.w $EA
		dc.b   2,  7		; 0
		dc.w $E0
		dc.b   2, $A		; 0
Obj34_Config:	dc.w	 0, $120,$FEFC,	$13C, $414, $154, $214,	$154; 0
					; DATA XREF: ROM:Obj34_CheckConfigo
		dc.w	 0, $120,$FEF4,	$134, $40C, $14C, $20C,	$14C; 8
		dc.w	 0, $120,$FEE0,	$120, $3F8, $138, $1F8,	$138; 16
		dc.w	 0, $120,$FEFC,	$13C, $414, $154, $214,	$154; 24
		dc.w	 0, $120,$FF04,	$144, $41C, $15C, $21C,	$15C; 32
		dc.w	 0, $120,$FF04,	$144, $41C, $15C, $21C,	$15C; 40
		dc.w	 0, $120,$FEE4,	$124, $3EC, $3EC, $1EC,	$12C; 48
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 39 - Game over	/ time over
;----------------------------------------------------

Obj39:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj39_Index(pc,d0.w),d1
		jmp	Obj39_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj39_Index:	dc.w loc_BA98-Obj39_Index ; DATA XREF: ROM:Obj39_Indexo
					; ROM:0000BA94o ...
		dc.w loc_BADC-Obj39_Index
		dc.w loc_BAFE-Obj39_Index
; ---------------------------------------------------------------------------

loc_BA98:				; DATA XREF: ROM:Obj39_Indexo
		tst.l	($FFFFF680).w
		beq.s	loc_BAA0
		rts
; ---------------------------------------------------------------------------

loc_BAA0:				; CODE XREF: ROM:0000BA9Cj
		addq.b	#2,$24(a0)
		move.w	#$50,8(a0) 
		btst	#0,$1A(a0)
		beq.s	loc_BAB8
		move.w	#$1F0,8(a0)

loc_BAB8:				; CODE XREF: ROM:0000BAB0j
		move.w	#$F0,$A(a0) ; "?"
		move.l	#Map_Obj39,4(a0)
		move.w	#$855E,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#0,1(a0)
		move.b	#0,$18(a0)

loc_BADC:				; DATA XREF: ROM:0000BA94o
		moveq	#$10,d1
		cmpi.w	#$120,8(a0)
		beq.s	loc_BAF2
		bcs.s	loc_BAEA
		neg.w	d1

loc_BAEA:				; CODE XREF: ROM:0000BAE6j
		add.w	d1,8(a0)
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_BAF2:				; CODE XREF: ROM:0000BAE4j
		move.w	#$2D0,$1E(a0)
		addq.b	#2,$24(a0)
		rts
; ---------------------------------------------------------------------------

loc_BAFE:				; DATA XREF: ROM:0000BA96o
		move.b	(v_jpadpress1).w,d0
		andi.b	#$70,d0	
		bne.s	loc_BB1E
		btst	#0,$1A(a0)
		bne.s	loc_BB42
		tst.w	$1E(a0)
		beq.s	loc_BB1E
		subq.w	#1,$1E(a0)
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_BB1E:				; CODE XREF: ROM:0000BB06j
					; ROM:0000BB14j
		tst.b	($FFFFFE1A).w
		bne.s	loc_BB38
		move.b	#$14,(v_gamemode).w
		tst.b	($FFFFFE18).w
		bne.s	loc_BB42
		move.b	#0,(v_gamemode).w
		bra.s	loc_BB42
; ---------------------------------------------------------------------------

loc_BB38:				; CODE XREF: ROM:0000BB22j
		clr.l	($FFFFFE38).w
		move.w	#1,($FFFFFE02).w

loc_BB42:				; CODE XREF: ROM:0000BB0Ej
					; ROM:0000BB2Ej ...
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 3A - leftover SONIC GOT THROUGH title card
;----------------------------------------------------

Obj3A:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj3A_Index(pc,d0.w),d1
		jmp	Obj3A_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj3A_Index:	dc.w loc_BB5C-Obj3A_Index ; DATA XREF: ROM:Obj3A_Indexo
					; ROM:0000BB56o ...
		dc.w loc_BBB8-Obj3A_Index
		dc.w loc_BC04-Obj3A_Index
		dc.w loc_BC80-Obj3A_Index
; ---------------------------------------------------------------------------

loc_BB5C:				; DATA XREF: ROM:Obj3A_Indexo
		tst.l	($FFFFF680).w
		beq.s	loc_BB64
		rts
; ---------------------------------------------------------------------------

loc_BB64:				; CODE XREF: ROM:0000BB60j
		movea.l	a0,a1
		lea	(Obj3A_Conf).l,a2
		moveq	#6,d1

loc_BB6E:				; CODE XREF: ROM:0000BBB4j
		move.b	#$3A,0(a1) 
		move.w	(a2),8(a1)
		move.w	(a2)+,$32(a1)
		move.w	(a2)+,$30(a1)
		move.w	(a2)+,$A(a1)
		move.b	(a2)+,$24(a1)
		move.b	(a2)+,d0
		cmpi.b	#6,d0
		bne.s	loc_BB94
		add.b	($FFFFFE11).w,d0

loc_BB94:				; CODE XREF: ROM:0000BB8Ej
		move.b	d0,$1A(a1)
		move.l	#Map_Obj3A,4(a1)
		move.w	#$8580,2(a1)
		bsr.w	ModifyA1SpriteAttr_2P
		move.b	#0,1(a1)
		lea	$40(a1),a1
		dbf	d1,loc_BB6E

loc_BBB8:				; DATA XREF: ROM:0000BB56o
		moveq	#$10,d1
		move.w	$30(a0),d0
		cmp.w	8(a0),d0
		beq.s	loc_BBEA
		bge.s	loc_BBC8
		neg.w	d1

loc_BBC8:				; CODE XREF: ROM:0000BBC4j
		add.w	d1,8(a0)

loc_BBCC:				; CODE XREF: ROM:0000BBF8j
		move.w	8(a0),d0
		bmi.s	locret_BBDE
		cmpi.w	#$200,d0
		bcc.s	locret_BBDE
		rts
; ---------------------------------------------------------------------------
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

locret_BBDE:				; CODE XREF: ROM:0000BBD0j
					; ROM:0000BBD6j
		rts
; ---------------------------------------------------------------------------

loc_BBE0:				; CODE XREF: ROM:0000BBF0j
		move.b	#$E,$24(a0)
		bra.w	loc_BCF8
; ---------------------------------------------------------------------------

loc_BBEA:				; CODE XREF: ROM:0000BBC2j
		cmpi.b	#$E,(v_objspace+$724).w
		beq.s	loc_BBE0
		cmpi.b	#4,$1A(a0)
		bne.s	loc_BBCC
		addq.b	#2,$24(a0)
		move.w	#$B4,$1E(a0) ; "?"

loc_BC04:				; DATA XREF: ROM:0000BB58o
		subq.w	#1,$1E(a0)
		bne.s	locret_BC0E
		addq.b	#2,$24(a0)

locret_BC0E:				; CODE XREF: ROM:0000BC08j
		rts
; ---------------------------------------------------------------------------
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
		bsr.w	DisplaySprite
		move.b	#1,($FFFFF7D6).w
		moveq	#0,d0
		tst.w	($FFFFF7D2).w
		beq.s	loc_BC30
		addi.w	#$A,d0
		subi.w	#$A,($FFFFF7D2).w

loc_BC30:				; CODE XREF: ROM:0000BC24j
		tst.w	($FFFFF7D4).w
		beq.s	loc_BC40
		addi.w	#$A,d0
		subi.w	#$A,($FFFFF7D4).w

loc_BC40:				; CODE XREF: ROM:0000BC34j
		tst.w	d0
		bne.s	loc_BC66
		move.w	#sfx_Cash,d0	; "?"
		jsr	(PlaySound_Special).l
		addq.b	#2,$24(a0)
		cmpi.w	#$501,(v_zone).w
		bne.s	loc_BC5E
		addq.b	#4,$24(a0)

loc_BC5E:				; CODE XREF: ROM:0000BC58j
		move.w	#$B4,$1E(a0) ; "?"

locret_BC64:				; CODE XREF: ROM:0000BC74j
		rts
; ---------------------------------------------------------------------------

loc_BC66:				; CODE XREF: ROM:0000BC42j
		jsr	(AddPoints).l
		move.b	($FFFFFE0F).w,d0
		andi.b	#3,d0
		bne.s	locret_BC64
		move.w	#sfx_Switch,d0	; "?"
		jmp	(PlaySound_Special).l
; ---------------------------------------------------------------------------

loc_BC80:				; DATA XREF: ROM:0000BB5Ao
		move.b	(v_zone).w,d0
		andi.w	#7,d0
		lsl.w	#3,d0
		move.b	($FFFFFE11).w,d1
		andi.w	#3,d1
		add.w	d1,d1
		add.w	d1,d0
		move.w	LevelOrder(pc,d0.w),d0
		move.w	d0,(v_zone).w
		tst.w	d0
		bne.s	loc_BCAA
		move.b	#0,(v_gamemode).w
		bra.s	locret_BCC2
; ---------------------------------------------------------------------------

loc_BCAA:				; CODE XREF: ROM:0000BCA0j
		clr.b	($FFFFFE30).w
		tst.b	($FFFFF7CD).w
		beq.s	loc_BCBC
		move.b	#$10,(v_gamemode).w
		bra.s	locret_BCC2
; ---------------------------------------------------------------------------

loc_BCBC:				; CODE XREF: ROM:0000BCB2j
		move.w	#1,($FFFFFE02).w

locret_BCC2:				; CODE XREF: ROM:0000BCA8j
					; ROM:0000BCBAj
		rts
; ---------------------------------------------------------------------------
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
LevelOrder:	dc.w	 1,    2, $200,	   0; 0
		dc.w  $101, $102, $300,	$502; 4
		dc.w  $201, $202, $400,	   0; 8
		dc.w  $301, $302, $500,	   0; 12
		dc.w  $401, $402, $100,	   0; 16
		dc.w  $501, $103,    0,	   0; 20
; ---------------------------------------------------------------------------

loc_BCF8:				; CODE XREF: ROM:0000BBE6j
		moveq	#$20,d1	
		move.w	$32(a0),d0
		cmp.w	8(a0),d0
		beq.s	loc_BD1E
		bge.s	loc_BD08
		neg.w	d1

loc_BD08:				; CODE XREF: ROM:0000BD04j
		add.w	d1,8(a0)
		move.w	8(a0),d0
		bmi.s	locret_BD1C
		cmpi.w	#$200,d0
		bcc.s	locret_BD1C
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

locret_BD1C:				; CODE XREF: ROM:0000BD10j
					; ROM:0000BD16j
		rts
; ---------------------------------------------------------------------------

loc_BD1E:				; CODE XREF: ROM:0000BD02j
		cmpi.b	#4,$1A(a0)
		bne.w	DeleteObject
		addq.b	#2,$24(a0)
		clr.b	($FFFFF7CC).w
		move.w	#bgm_FZ,d0	; "?"
		jmp	(PlaySound).l
; ---------------------------------------------------------------------------
		addq.w	#2,($FFFFEECA).w
		cmpi.w	#$2100,($FFFFEECA).w
		beq.w	DeleteObject
		rts
; ---------------------------------------------------------------------------
Obj3A_Conf:	dc.w	 4, $124,  $BC,	$200; 0	; DATA XREF: ROM:0000BB66o
		dc.w $FEE0, $120,  $D0,	$201; 4
		dc.w  $40C, $14C,  $D6,	$206; 8
		dc.w  $520, $120,  $EC,	$202; 12
		dc.w  $540, $120,  $FC,	$203; 16
		dc.w  $560, $120, $10C,	$204; 20
		dc.w  $20C, $14C,  $CC,	$205; 24
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Sonic	1 Object 7E - leftover S1 Special Stage	results
;----------------------------------------------------

S1Obj7E:
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	S1Obj7E_Index(pc,d0.w),d1
		jmp	S1Obj7E_Index(pc,d1.w)
; ---------------------------------------------------------------------------
S1Obj7E_Index:	dc.w loc_BDA6-S1Obj7E_Index ; DATA XREF: ROM:S1Obj7E_Indexo
					; ROM:0000BD92o ...
		dc.w loc_BE1E-S1Obj7E_Index
		dc.w loc_BE5C-S1Obj7E_Index
		dc.w loc_BE6A-S1Obj7E_Index
		dc.w loc_BE5C-S1Obj7E_Index
		dc.w loc_BEC4-S1Obj7E_Index
		dc.w loc_BE5C-S1Obj7E_Index
		dc.w loc_BECE-S1Obj7E_Index
		dc.w loc_BE5C-S1Obj7E_Index
		dc.w loc_BEC4-S1Obj7E_Index
		dc.w loc_BEF2-S1Obj7E_Index
; ---------------------------------------------------------------------------

loc_BDA6:				; DATA XREF: ROM:S1Obj7E_Indexo
		tst.l	($FFFFF680).w
		beq.s	loc_BDAE
		rts
; ---------------------------------------------------------------------------

loc_BDAE:				; CODE XREF: ROM:0000BDAAj
		movea.l	a0,a1
		lea	(S1Obj7E_Conf).l,a2
		moveq	#3,d1
		cmpi.w	#$32,($FFFFFE20).w 
		bcs.s	loc_BDC2
		addq.w	#1,d1

loc_BDC2:				; CODE XREF: ROM:0000BDBEj
					; ROM:0000BDF8j
		move.b	#$7E,0(a1) ; "~"
		move.w	(a2)+,8(a1)
		move.w	(a2)+,$30(a1)
		move.w	(a2)+,$A(a1)
		move.b	(a2)+,$24(a1)
		move.b	(a2)+,$1A(a1)
		move.l	#Map_S1Obj7E,4(a1)
		move.w	#$8580,2(a1)
		bsr.w	ModifyA1SpriteAttr_2P
		move.b	#0,1(a1)
		lea	$40(a1),a1
		dbf	d1,loc_BDC2
		moveq	#7,d0
		move.b	($FFFFFE57).w,d1
		beq.s	loc_BE1A
		moveq	#0,d0
		cmpi.b	#6,d1
		bne.s	loc_BE1A
		moveq	#8,d0
		move.w	#$18,8(a0)
		move.w	#$118,$30(a0)

loc_BE1A:				; CODE XREF: ROM:0000BE02j
					; ROM:0000BE0Aj
		move.b	d0,$1A(a0)

loc_BE1E:				; DATA XREF: ROM:0000BD92o
		moveq	#$10,d1
		move.w	$30(a0),d0
		cmp.w	8(a0),d0
		beq.s	loc_BE44
		bge.s	loc_BE2E
		neg.w	d1

loc_BE2E:				; CODE XREF: ROM:0000BE2Aj
		add.w	d1,8(a0)

loc_BE32:				; CODE XREF: ROM:0000BE4Aj
		move.w	8(a0),d0
		bmi.s	locret_BE42
		cmpi.w	#$200,d0
		bcc.s	locret_BE42
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

locret_BE42:				; CODE XREF: ROM:0000BE36j
					; ROM:0000BE3Cj
		rts
; ---------------------------------------------------------------------------

loc_BE44:				; CODE XREF: ROM:0000BE28j
		cmpi.b	#2,$1A(a0)
		bne.s	loc_BE32
		addq.b	#2,$24(a0)
		move.w	#$B4,$1E(a0) ; "?"
		move.b	#$7F,(v_objspace+$800).w 

loc_BE5C:				; DATA XREF: ROM:0000BD94o
					; ROM:0000BD98o ...
		subq.w	#1,$1E(a0)
		bne.s	loc_BE66
		addq.b	#2,$24(a0)

loc_BE66:				; CODE XREF: ROM:0000BE60j
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_BE6A:				; DATA XREF: ROM:0000BD96o
		bsr.w	DisplaySprite
		move.b	#1,($FFFFF7D6).w
		tst.w	($FFFFF7D4).w
		beq.s	loc_BE9C
		subi.w	#$A,($FFFFF7D4).w
		moveq	#$A,d0
		jsr	(AddPoints).l
		move.b	($FFFFFE0F).w,d0
		andi.b	#3,d0
		bne.s	locret_BEC2
		move.w	#sfx_Switch,d0	; "?"
		jmp	(PlaySound_Special).l
; ---------------------------------------------------------------------------

loc_BE9C:				; CODE XREF: ROM:0000BE78j
		move.w	#sfx_Cash,d0	; "?"
		jsr	(PlaySound_Special).l
		addq.b	#2,$24(a0)
		move.w	#$B4,$1E(a0) ; "?"
		cmpi.w	#$32,($FFFFFE20).w 
		bcs.s	locret_BEC2
		move.w	#$3C,$1E(a0) 
		addq.b	#4,$24(a0)

locret_BEC2:				; CODE XREF: ROM:0000BE90j
					; ROM:0000BEB6j
		rts
; ---------------------------------------------------------------------------

loc_BEC4:				; DATA XREF: ROM:0000BD9Ao
					; ROM:0000BDA2o
		move.w	#1,($FFFFFE02).w
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_BECE:				; DATA XREF: ROM:0000BD9Eo
		move.b	#4,(v_objspace+$6DA).w
		move.b	#$14,(v_objspace+$6E4).w
		move.w	#sfx_Continue,d0	; "?"
		jsr	(PlaySound_Special).l
		addq.b	#2,$24(a0)
		move.w	#$168,$1E(a0)
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_BEF2:				; DATA XREF: ROM:0000BDA4o
		move.b	($FFFFFE0F).w,d0
		andi.b	#$F,d0
		bne.s	loc_BF02
		bchg	#0,$1A(a0)

loc_BF02:				; CODE XREF: ROM:0000BEFAj
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
S1Obj7E_Conf:	dc.w   $20, $120,  $C4,	$200; 0	; DATA XREF: ROM:0000BDB0o
		dc.w  $320, $120, $118,	$201; 4
		dc.w  $360, $120, $128,	$202; 8
		dc.w  $1EC, $11C,  $C4,	$203; 12
		dc.w  $3A0, $120, $138,	$206; 16
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Sonic	1 Object 7F - leftover Sonic 1 SS emeralds
;----------------------------------------------------

S1Obj7F:
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	S1Obj7F_Index(pc,d0.w),d1
		jmp	S1Obj7F_Index(pc,d1.w)
; ---------------------------------------------------------------------------
S1Obj7F_Index:	dc.w loc_BF4C-S1Obj7F_Index ; DATA XREF: ROM:S1Obj7F_Indexo
					; ROM:0000BF3Eo
		dc.w loc_BFA6-S1Obj7F_Index
word_BF40:	dc.w $110		; DATA XREF: ROM:0000BF4Et
		dc.w $128
		dc.w $F8
		dc.w $140
		dc.w $E0
		dc.w $158
; ---------------------------------------------------------------------------

loc_BF4C:				; DATA XREF: ROM:S1Obj7F_Indexo
		movea.l	a0,a1
		lea	word_BF40(pc),a2
		moveq	#0,d2
		moveq	#0,d1
		move.b	($FFFFFE57).w,d1
		subq.b	#1,d1
		bcs.w	DeleteObject

loc_BF60:				; CODE XREF: ROM:0000BFA2j
		move.b	#$7F,0(a1) 
		move.w	(a2)+,8(a1)
		move.w	#$F0,$A(a1) ; "?"
		lea	($FFFFFE58).w,a3
		move.b	(a3,d2.w),d3
		move.b	d3,$1A(a1)
		move.b	d3,$1C(a1)
		addq.b	#1,d2
		addq.b	#2,$24(a1)
		move.l	#Map_S1Obj7F,4(a1)
		move.w	#$8541,2(a1)
		bsr.w	ModifyA1SpriteAttr_2P
		move.b	#0,1(a1)
		lea	$40(a1),a1
		dbf	d1,loc_BF60

loc_BFA6:				; DATA XREF: ROM:0000BF3Eo
		move.b	$1A(a0),d0
		move.b	#6,$1A(a0)
		cmpi.b	#6,d0
		bne.s	loc_BFBC
		move.b	$1C(a0),$1A(a0)

loc_BFBC:				; CODE XREF: ROM:0000BFB4j
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Map_Obj34:	dc.w word_BFD8-Map_Obj34 ; DATA	XREF: ROM:0000B948o
					; ROM:Map_Obj34o ...
		dc.w word_C022-Map_Obj34
		dc.w word_C06C-Map_Obj34
		dc.w word_C09E-Map_Obj34
		dc.w word_C0E8-Map_Obj34
		dc.w word_C13A-Map_Obj34
		dc.w word_C18C-Map_Obj34
		dc.w word_C1AE-Map_Obj34
		dc.w word_C1C0-Map_Obj34
		dc.w word_C1D2-Map_Obj34
		dc.w word_C1E4-Map_Obj34
		dc.w word_C24E-Map_Obj34
word_BFD8:	dc.w 9			; DATA XREF: ROM:Map_Obj34o
		dc.w $F805,  $18,   $C,$FFB4; 0
		dc.w $F805,  $3A,  $1D,$FFC4; 4
		dc.w $F805,  $10,    8,$FFD4; 8
		dc.w $F805,  $10,    8,$FFE4; 12
		dc.w $F805,  $2E,  $17,$FFF4; 16
		dc.w $F805,  $1C,   $E,	 $14; 20
		dc.w $F801,  $20,  $10,	 $24; 24
		dc.w $F805,  $26,  $13,	 $2C; 28
		dc.w $F805,  $26,  $13,	 $3C; 32
word_C022:	dc.w 9			; DATA XREF: ROM:0000BFC2o
		dc.w $F805,  $26,  $13,$FFBC; 0
		dc.w $F805,    0,    0,$FFCC; 4
		dc.w $F805,    4,    2,$FFDC; 8
		dc.w $F805,  $4A,  $25,$FFEC; 12
		dc.w $F805,  $3A,  $1D,$FFFC; 16
		dc.w $F801,  $20,  $10,	  $C; 20
		dc.w $F805,  $2E,  $17,	 $14; 24
		dc.w $F805,  $42,  $21,	 $24; 28
		dc.w $F805,  $1C,   $E,	 $34; 32
word_C06C:	dc.w 6			; DATA XREF: ROM:0000BFC4o
		dc.w $F805,  $2A,  $15,$FFCF; 0
		dc.w $F805,    0,    0,$FFE0; 4
		dc.w $F805,  $3A,  $1D,$FFF0; 8
		dc.w $F805,    4,    2,	   0; 12
		dc.w $F805,  $26,  $13,	 $10; 16
		dc.w $F805,  $10,    8,	 $20; 20
word_C09E:	dc.w 9			; DATA XREF: ROM:0000BFC6o
		dc.w $F805,  $3E,  $1F,$FFB4; 0
		dc.w $F805,  $42,  $21,$FFC4; 4
		dc.w $F805,    0,    0,$FFD4; 8
		dc.w $F805,  $3A,  $1D,$FFE4; 12
		dc.w $F805,  $26,  $13,	   4; 16
		dc.w $F801,  $20,  $10,	 $14; 20
		dc.w $F805,  $18,   $C,	 $1C; 24
		dc.w $F805,  $1C,   $E,	 $2C; 28
		dc.w $F805,  $42,  $21,	 $3C; 32
word_C0E8:	dc.w $A			; DATA XREF: ROM:0000BFC8o
		dc.w $F805,  $3E,  $1F,$FFAC; 0
		dc.w $F805,  $36,  $1B,$FFBC; 4
		dc.w $F805,  $3A,  $1D,$FFCC; 8
		dc.w $F801,  $20,  $10,$FFDC; 12
		dc.w $F805,  $2E,  $17,$FFE4; 16
		dc.w $F805,  $18,   $C,$FFF4; 20
		dc.w $F805,  $4A,  $25,	 $14; 24
		dc.w $F805,    0,    0,	 $24; 28
		dc.w $F805,  $3A,  $1D,	 $34; 32
		dc.w $F805,   $C,    6,	 $44; 36
word_C13A:	dc.w $A			; DATA XREF: ROM:0000BFCAo
		dc.w $F805,  $3E,  $1F,$FFAC; 0
		dc.w $F805,    8,    4,$FFBC; 4
		dc.w $F805,  $3A,  $1D,$FFCC; 8
		dc.w $F805,    0,    0,$FFDC; 12
		dc.w $F805,  $36,  $1B,$FFEC; 16
		dc.w $F805,    4,    2,	  $C; 20
		dc.w $F805,  $3A,  $1D,	 $1C; 24
		dc.w $F805,    0,    0,	 $2C; 28
		dc.w $F801,  $20,  $10,	 $3C; 32
		dc.w $F805,  $2E,  $17,	 $44; 36
word_C18C:	dc.w 4			; DATA XREF: ROM:0000BFCCo
		dc.w $F805,  $4E,  $27,$FFE0; 0
		dc.w $F805,  $32,  $19,$FFF0; 4
		dc.w $F805,  $2E,  $17,	   0; 8
		dc.w $F805,  $10,    8,	 $10; 12
word_C1AE:	dc.w 2			; DATA XREF: ROM:0000BFCEo
					; ROM:0000C2D4o
		dc.w  $40C,  $53,  $29,$FFEC; 0
		dc.w $F402,  $57,  $2B,	  $C; 4
word_C1C0:	dc.w 2			; DATA XREF: ROM:0000BFD0o
					; ROM:0000C2D6o
		dc.w  $40C,  $53,  $29,$FFEC; 0
		dc.w $F406,  $5A,  $2D,	   8; 4
word_C1D2:	dc.w 2			; DATA XREF: ROM:0000BFD2o
					; ROM:0000C2D8o
		dc.w  $40C,  $53,  $29,$FFEC; 0
		dc.w $F406,  $60,  $30,	   8; 4
word_C1E4:	dc.w $D			; DATA XREF: ROM:0000BFD4o
					; ROM:0000C2D2o
		dc.w $E40C,  $70,  $38,$FFF4; 0
		dc.w $E402,  $74,  $3A,	 $14; 4
		dc.w $EC04,  $77,  $3B,$FFEC; 8
		dc.w $F405,  $79,  $3C,$FFE4; 12
		dc.w $140C,$1870,$1838,$FFEC; 16
		dc.w  $402,$1874,$183A,$FFE4; 20
		dc.w  $C04,$1877,$183B,	   4; 24
		dc.w $FC05,$1879,$183C,	  $C; 28
		dc.w $EC08,  $7D,  $3E,$FFFC; 32
		dc.w $F40C,  $7C,  $3E,$FFF4; 36
		dc.w $FC08,  $7C,  $3E,$FFF4; 40
		dc.w  $40C,  $7C,  $3E,$FFEC; 44
		dc.w  $C08,  $7C,  $3E,$FFEC; 48
word_C24E:	dc.w 5			; DATA XREF: ROM:0000BFD6o
		dc.w $F805,  $14,   $A,$FFDC; 0
		dc.w $F801,  $20,  $10,$FFEC; 4
		dc.w $F805,  $2E,  $17,$FFF4; 8
		dc.w $F805,    0,    0,	   4; 12
		dc.w $F805,  $26,  $13,	 $14; 16
Map_Obj39:	dc.w word_C280-Map_Obj39 ; DATA	XREF: ROM:0000BABEo
					; ROM:Map_Obj39o ...
		dc.w word_C292-Map_Obj39
		dc.w word_C2A4-Map_Obj39
		dc.w word_C2B6-Map_Obj39
word_C280:	dc.w 2			; DATA XREF: ROM:Map_Obj39o
		dc.w $F80D,    0,    0,$FFB8; 0
		dc.w $F80D,    8,    4,$FFD8; 4
word_C292:	dc.w 2			; DATA XREF: ROM:0000C27Ao
		dc.w $F80D,  $14,   $A,	   8; 0
		dc.w $F80D,   $C,    6,	 $28; 4
word_C2A4:	dc.w 2			; DATA XREF: ROM:0000C27Co
		dc.w $F809,  $1C,   $E,$FFC4; 0
		dc.w $F80D,    8,    4,$FFDC; 4
word_C2B6:	dc.w 2			; DATA XREF: ROM:0000C27Eo
		dc.w $F80D,  $14,   $A,	  $C; 0
		dc.w $F80D,   $C,    6,	 $2C; 4
Map_Obj3A:	dc.w word_C2DA-Map_Obj3A ; DATA	XREF: ROM:0000BB98o
					; ROM:Map_Obj3Ao ...
		dc.w word_C31C-Map_Obj3A
		dc.w word_C34E-Map_Obj3A
		dc.w word_C380-Map_Obj3A
		dc.w word_C3BA-Map_Obj3A
		dc.w word_C1E4-Map_Obj3A
		dc.w word_C1AE-Map_Obj3A
		dc.w word_C1C0-Map_Obj3A
		dc.w word_C1D2-Map_Obj3A
word_C2DA:	dc.w 8			; DATA XREF: ROM:Map_Obj3Ao
		dc.w $F805,  $3E,  $1F,$FFB8; 0
		dc.w $F805,  $32,  $19,$FFC8; 4
		dc.w $F805,  $2E,  $17,$FFD8; 8
		dc.w $F801,  $20,  $10,$FFE8; 12
		dc.w $F805,    8,    4,$FFF0; 16
		dc.w $F805,  $1C,   $E,	 $10; 20
		dc.w $F805,    0,    0,	 $20; 24
		dc.w $F805,  $3E,  $1F,	 $30; 28
word_C31C:	dc.w 6			; DATA XREF: ROM:0000C2CAo
		dc.w $F805,  $36,  $1B,$FFD0; 0
		dc.w $F805,    0,    0,$FFE0; 4
		dc.w $F805,  $3E,  $1F,$FFF0; 8
		dc.w $F805,  $3E,  $1F,	   0; 12
		dc.w $F805,  $10,    8,	 $10; 16
		dc.w $F805,   $C,    6,	 $20; 20
word_C34E:	dc.w 6			; DATA XREF: ROM:0000C2CCo
		dc.w $F80D, $14A,  $A5,$FFB0; 0
		dc.w $F801, $162,  $B1,$FFD0; 4
		dc.w $F809, $164,  $B2,	 $18; 8
		dc.w $F80D, $16A,  $B5,	 $30; 12
		dc.w $F704,  $6E,  $37,$FFCD; 16
		dc.w $FF04,$186E,$1837,$FFCD; 20
word_C380:	dc.w 7			; DATA XREF: ROM:0000C2CEo
		dc.w $F80D, $15A,  $AD,$FFB0; 0
		dc.w $F80D,  $66,  $33,$FFD9; 4
		dc.w $F801, $14A,  $A5,$FFF9; 8
		dc.w $F704,  $6E,  $37,$FFF6; 12
		dc.w $FF04,$186E,$1837,$FFF6; 16
		dc.w $F80D,$FFF0,$FBF8,	 $28; 20
		dc.w $F801, $170,  $B8,	 $48; 24
word_C3BA:	dc.w 7			; DATA XREF: ROM:0000C2D0o
		dc.w $F80D, $152,  $A9,$FFB0; 0
		dc.w $F80D,  $66,  $33,$FFD9; 4
		dc.w $F801, $14A,  $A5,$FFF9; 8
		dc.w $F704,  $6E,  $37,$FFF6; 12
		dc.w $FF04,$186E,$1837,$FFF6; 16
		dc.w $F80D,$FFF8,$FBFC,	 $28; 20
		dc.w $F801, $170,  $B8,	 $48; 24
Map_S1Obj7E:	dc.w word_C406-Map_S1Obj7E ; DATA XREF:	ROM:0000BDDCo
					; ROM:Map_S1Obj7Eo ...
		dc.w word_C470-Map_S1Obj7E
		dc.w word_C4A2-Map_S1Obj7E
		dc.w word_C1E4+$10000-Map_S1Obj7E
		dc.w word_C4DC-Map_S1Obj7E
		dc.w word_C4FE-Map_S1Obj7E
		dc.w word_C520-Map_S1Obj7E
		dc.w word_C53A-Map_S1Obj7E
		dc.w word_C59C-Map_S1Obj7E
word_C406:	dc.w $D			; DATA XREF: ROM:Map_S1Obj7Eo
		dc.w $F805,    8,    4,$FF90; 0
		dc.w $F805,  $1C,   $E,$FFA0; 4
		dc.w $F805,    0,    0,$FFB0; 8
		dc.w $F805,  $32,  $19,$FFC0; 12
		dc.w $F805,  $3E,  $1F,$FFD0; 16
		dc.w $F805,  $10,    8,$FFF0; 20
		dc.w $F805,  $2A,  $15,	   0; 24
		dc.w $F805,  $10,    8,	 $10; 28
		dc.w $F805,  $3A,  $1D,	 $20; 32
		dc.w $F805,    0,    0,	 $30; 36
		dc.w $F805,  $26,  $13,	 $40; 40
		dc.w $F805,   $C,    6,	 $50; 44
		dc.w $F805,  $3E,  $1F,	 $60; 48
word_C470:	dc.w 6			; DATA XREF: ROM:0000C3F6o
		dc.w $F80D, $14A,  $A5,$FFB0; 0
		dc.w $F801, $162,  $B1,$FFD0; 4
		dc.w $F809, $164,  $B2,	 $18; 8
		dc.w $F80D, $16A,  $B5,	 $30; 12
		dc.w $F704,  $6E,  $37,$FFCD; 16
		dc.w $FF04,$186E,$1837,$FFCD; 20
word_C4A2:	dc.w 7			; DATA XREF: ROM:0000C3F8o
		dc.w $F80D, $152,  $A9,$FFB0; 0
		dc.w $F80D,  $66,  $33,$FFD9; 4
		dc.w $F801, $14A,  $A5,$FFF9; 8
		dc.w $F704,  $6E,  $37,$FFF6; 12
		dc.w $FF04,$186E,$1837,$FFF6; 16
		dc.w $F80D,$FFF8,$FBFC,	 $28; 20
		dc.w $F801, $170,  $B8,	 $48; 24
word_C4DC:	dc.w 4			; DATA XREF: ROM:0000C3FCo
		dc.w $F80D,$FFD1,$7FC8,$FFB0; 0
		dc.w $F80D,$FFD9,$7FD4,$FFD0; 4
		dc.w $F801,$FFE1,$7FE0,$FFF0; 8
		dc.w $F806,$1FE3,$2FE3,	 $40; 12
word_C4FE:	dc.w 4			; DATA XREF: ROM:0000C3FEo
		dc.w $F80D,$FFD1,$7FC8,$FFB0; 0
		dc.w $F80D,$FFD9,$7FD4,$FFD0; 4
		dc.w $F801,$FFE1,$7FE0,$FFF0; 8
		dc.w $F806,$1FE9,$2FEC,	 $40; 12
word_C520:	dc.w 3			; DATA XREF: ROM:0000C400o
		dc.w $F80D,$FFD1,$7FC8,$FFB0; 0
		dc.w $F80D,$FFD9,$7FD4,$FFD0; 4
		dc.w $F801,$FFE1,$7FE0,$FFF0; 8
word_C53A:	dc.w $C			; DATA XREF: ROM:0000C402o
		dc.w $F805,  $3E,  $1F,$FF9C; 0
		dc.w $F805,  $36,  $1B,$FFAC; 4
		dc.w $F805,  $10,    8,$FFBC; 8
		dc.w $F805,    8,    4,$FFCC; 12
		dc.w $F801,  $20,  $10,$FFDC; 16
		dc.w $F805,    0,    0,$FFE4; 20
		dc.w $F805,  $26,  $13,$FFF4; 24
		dc.w $F805,  $3E,  $1F,	 $14; 28
		dc.w $F805,  $42,  $21,	 $24; 32
		dc.w $F805,    0,    0,	 $34; 36
		dc.w $F805,  $18,   $C,	 $44; 40
		dc.w $F805,  $10,    8,	 $54; 44
word_C59C:	dc.w $F			; DATA XREF: ROM:0000C404o
		dc.w $F805,  $3E,  $1F,$FF88; 0
		dc.w $F805,  $32,  $19,$FF98; 4
		dc.w $F805,  $2E,  $17,$FFA8; 8
		dc.w $F801,  $20,  $10,$FFB8; 12
		dc.w $F805,    8,    4,$FFC0; 16
		dc.w $F805,  $18,   $C,$FFD8; 20
		dc.w $F805,  $32,  $19,$FFE8; 24
		dc.w $F805,  $42,  $21,$FFF8; 28
		dc.w $F805,  $42,  $21,	 $10; 32
		dc.w $F805,  $1C,   $E,	 $20; 36
		dc.w $F805,  $10,    8,	 $30; 40
		dc.w $F805,  $2A,  $15,	 $40; 44
		dc.w $F805,    0,    0,	 $58; 48
		dc.w $F805,  $26,  $13,	 $68; 52
		dc.w $F805,  $26,  $13,	 $78; 56
Map_S1Obj7F:	dc.w word_C624-Map_S1Obj7F ; DATA XREF:	ROM:0000BF86o
					; ROM:Map_S1Obj7Fo ...
		dc.w word_C62E-Map_S1Obj7F
		dc.w word_C638-Map_S1Obj7F
		dc.w word_C642-Map_S1Obj7F
		dc.w word_C64C-Map_S1Obj7F
		dc.w word_C656-Map_S1Obj7F
		dc.w word_C660-Map_S1Obj7F
word_C624:	dc.w 1			; DATA XREF: ROM:Map_S1Obj7Fo
		dc.w $F805,$2004,$2002,$FFF8; 0
word_C62E:	dc.w 1			; DATA XREF: ROM:0000C618o
		dc.w $F805,    0,    0,$FFF8; 0
word_C638:	dc.w 1			; DATA XREF: ROM:0000C61Ao
		dc.w $F805,$4004,$4002,$FFF8; 0
word_C642:	dc.w 1			; DATA XREF: ROM:0000C61Co
		dc.w $F805,$6004,$6002,$FFF8; 0
word_C64C:	dc.w 1			; DATA XREF: ROM:0000C61Eo
		dc.w $F805,$2008,$2004,$FFF8; 0
word_C656:	dc.w 1			; DATA XREF: ROM:0000C620o
		dc.w $F805,$200C,$2006,$FFF8; 0
word_C660:	dc.w 0			; DATA XREF: ROM:0000C622o
; ---------------------------------------------------------------------------
		nop
;----------------------------------------------------
; Object 36 - Spikes
;----------------------------------------------------

Obj36:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj36_Index(pc,d0.w),d1
		jmp	Obj36_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj36_Index:	dc.w loc_C682-Obj36_Index ; DATA XREF: ROM:Obj36_Indexo
					; ROM:0000C674o
		dc.w loc_C6CE-Obj36_Index
Obj36_Conf:	dc.b   0,$10		; 0 ; DATA XREF: ROM:0000C6B2t
		dc.b   0,$10		; 2
		dc.b   0,$10		; 4
		dc.b   0,$10		; 6
		dc.b   0,$10		; 8
		dc.b   0,$10		; 10
; ---------------------------------------------------------------------------

loc_C682:				; DATA XREF: ROM:Obj36_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj36,4(a0)
		move.w	#$2434,2(a0)
		bsr.w	ModifySpriteAttr_2P
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	$28(a0),d0
		andi.b	#$F,$28(a0)
		andi.w	#$F0,d0	; "?"
		lea	Obj36_Conf(pc),a1
		lsr.w	#3,d0
		adda.w	d0,a1
		move.b	(a1)+,$1A(a0)
		move.b	(a1)+,$19(a0)
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$32(a0)

loc_C6CE:				; DATA XREF: ROM:0000C674o
		bsr.w	sub_C788
		move.w	#4,d2
		cmpi.b	#5,$1A(a0)
		beq.s	loc_C6EA
		cmpi.b	#1,$1A(a0)
		bne.s	loc_C70C
		move.w	#$14,d2

loc_C6EA:				; CODE XREF: ROM:0000C6DCj
		move.w	#$1B,d1
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		btst	#3,$22(a0)
		bne.s	loc_C766
		swap	d6
		andi.w	#3,d6
		bne.s	loc_C736
		bra.s	loc_C766
; ---------------------------------------------------------------------------

loc_C70C:				; CODE XREF: ROM:0000C6E4j
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		btst	#3,$22(a0)
		bne.s	loc_C736
		swap	d6
		andi.w	#$C0,d6	
		beq.s	loc_C766

loc_C736:				; CODE XREF: ROM:0000C708j
					; ROM:0000C72Cj
		tst.b	($FFFFFE2D).w
		bne.s	loc_C766
		move.l	a0,-(sp)
		movea.l	a0,a2
		lea	(v_objspace).w,a0
		cmpi.b	#4,$24(a0)
		bcc.s	loc_C764
		move.l	$C(a0),d3
		move.w	$12(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d3,$C(a0)
		jsr	(HurtSonic).l

loc_C764:				; CODE XREF: ROM:0000C74Aj
		movea.l	(sp)+,a0

loc_C766:				; CODE XREF: ROM:0000C700j
					; ROM:0000C70Aj ...
		tst.w	(f_2player).w
		beq.s	loc_C770
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_C770:				; CODE XREF: ROM:0000C76Aj
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite

; =============== S U B	R O U T	I N E =======================================


sub_C788:				; CODE XREF: ROM:loc_C6CEp
		moveq	#0,d0
		move.b	$28(a0),d0
		add.w	d0,d0
		move.w	off_C798(pc,d0.w),d1
		jmp	off_C798(pc,d1.w)
; End of function sub_C788

; ---------------------------------------------------------------------------
off_C798:	dc.w locret_C79E-off_C798 ; DATA XREF: ROM:off_C798o
					; ROM:0000C79Ao ...
		dc.w loc_C7A0-off_C798
		dc.w loc_C7B4-off_C798
; ---------------------------------------------------------------------------

locret_C79E:				; DATA XREF: ROM:off_C798o
		rts
; ---------------------------------------------------------------------------

loc_C7A0:				; DATA XREF: ROM:0000C79Ao
		bsr.w	sub_C7C8
		moveq	#0,d0
		move.b	$34(a0),d0
		add.w	$32(a0),d0
		move.w	d0,$C(a0)
		rts
; ---------------------------------------------------------------------------

loc_C7B4:				; DATA XREF: ROM:0000C79Co
		bsr.w	sub_C7C8
		moveq	#0,d0
		move.b	$34(a0),d0
		add.w	$30(a0),d0
		move.w	d0,8(a0)
		rts

; =============== S U B	R O U T	I N E =======================================


sub_C7C8:				; CODE XREF: ROM:loc_C7A0p
					; ROM:loc_C7B4p
		tst.w	$38(a0)
		beq.s	loc_C7E6
		subq.w	#1,$38(a0)
		bne.s	locret_C828
		tst.b	1(a0)
		bpl.s	locret_C828
		move.w	#sfx_SpikesMove,d0	; "?"
		jsr	(PlaySound_Special).l
		bra.s	locret_C828
; ---------------------------------------------------------------------------

loc_C7E6:				; CODE XREF: sub_C7C8+4j
		tst.w	$36(a0)
		beq.s	loc_C808
		subi.w	#$800,$34(a0)
		bcc.s	locret_C828
		move.w	#0,$34(a0)
		move.w	#0,$36(a0)
		move.w	#$3C,$38(a0) 
		bra.s	locret_C828
; ---------------------------------------------------------------------------

loc_C808:				; CODE XREF: sub_C7C8+22j
		addi.w	#$800,$34(a0)
		cmpi.w	#$2000,$34(a0)
		bcs.s	locret_C828
		move.w	#$2000,$34(a0)
		move.w	#1,$36(a0)
		move.w	#$3C,$38(a0) 

locret_C828:				; CODE XREF: sub_C7C8+Aj sub_C7C8+10j	...
		rts
; End of function sub_C7C8

; ---------------------------------------------------------------------------
Map_Obj36:	dc.w word_C836-Map_Obj36 ; DATA	XREF: ROM:0000C686o
					; ROM:Map_Obj36o ...
		dc.w word_C836-Map_Obj36
		dc.w word_C836-Map_Obj36
		dc.w word_C836-Map_Obj36
		dc.w word_C836-Map_Obj36
		dc.w word_C836-Map_Obj36
word_C836:	dc.w 2			; DATA XREF: ROM:Map_Obj36o
					; ROM:0000C82Co ...
		dc.w $F007,    0,    0,$FFF0; 0
		dc.w $F007,    0,    0,	   0; 4
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 3B - GHZ Purple Rock
;----------------------------------------------------

Obj3B:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0

loc_C84A:
		move.b	$24(a0),d0
		move.w	Obj3B_Index(pc,d0.w),d1
		jmp	Obj3B_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj3B_Index:	dc.w loc_C85A-Obj3B_Index ; DATA XREF: ROM:Obj3B_Indexo
					; ROM:0000C858o
		dc.w loc_C882-Obj3B_Index
; ---------------------------------------------------------------------------

loc_C85A:				; DATA XREF: ROM:Obj3B_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj3B,4(a0)
		move.w	#$66C0,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#$13,$19(a0)
		move.b	#4,$18(a0)

loc_C882:				; DATA XREF: ROM:0000C858o
		move.w	#$1B,d1
		move.w	#$10,d2
		move.w	#$10,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Map_Obj3B:	dc.w word_C8B0-Map_Obj3B ; DATA	XREF: ROM:0000C85Eo
					; ROM:Map_Obj3Bo ...
word_C8B0:	dc.w 2			; DATA XREF: ROM:Map_Obj3Bo
		dc.w $F00B,    0,    0,$FFE8; 0
		dc.w $F00B,   $C,    6,	   0; 4
		dc.w 0
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 3C - GHZ smashable wall
;----------------------------------------------------

Obj3C:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj3C_Index(pc,d0.w),d1
		jsr	Obj3C_Index(pc,d1.w)
		bra.w	MarkObjGone
; ---------------------------------------------------------------------------
Obj3C_Index:	dc.w loc_C8DC-Obj3C_Index ; DATA XREF: ROM:Obj3C_Indexo
					; ROM:0000C8D8o ...
		dc.w loc_C90A-Obj3C_Index
		dc.w loc_C988-Obj3C_Index
; ---------------------------------------------------------------------------

loc_C8DC:				; DATA XREF: ROM:Obj3C_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj3C,4(a0)
		move.w	#$4590,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#4,$18(a0)
		move.b	$28(a0),$1A(a0)

loc_C90A:				; DATA XREF: ROM:0000C8D8o
		move.w	(v_objspace+$10).w,$30(a0)
		move.w	#$1B,d1
		move.w	#$20,d2	
		move.w	#$20,d3	
		move.w	8(a0),d4
		bsr.w	SolidObject
		btst	#5,$22(a0)
		bne.s	loc_C92E

locret_C92C:				; CODE XREF: ROM:0000C938j
					; ROM:0000C946j
		rts
; ---------------------------------------------------------------------------

loc_C92E:				; CODE XREF: ROM:0000C92Aj
		lea	(v_objspace).w,a1
		cmpi.b	#2,$1C(a1)
		bne.s	locret_C92C
		move.w	$30(a0),d0
		bpl.s	loc_C942
		neg.w	d0

loc_C942:				; CODE XREF: ROM:0000C93Ej
		cmpi.w	#$480,d0
		bcs.s	locret_C92C
		move.w	$30(a0),$10(a1)
		addq.w	#4,8(a1)
		lea	(Obj3C_FragSpdRight).l,a4
		move.w	8(a0),d0
		cmp.w	8(a1),d0
		bcs.s	loc_C96E
		subi.w	#8,8(a1)
		lea	(Obj3C_FragSpdLeft).l,a4

loc_C96E:				; CODE XREF: ROM:0000C960j
		move.w	$10(a1),$14(a1)
		bclr	#5,$22(a0)
		bclr	#5,$22(a1)
		moveq	#7,d1
		move.w	#$70,d2	
		bsr.s	sub_C99E

loc_C988:				; DATA XREF: ROM:0000C8DAo
		bsr.w	SpeedToPos
		addi.w	#$70,$12(a0) 
		tst.b	1(a0)
		bpl.w	DeleteObject
		bra.w	DisplaySprite

; =============== S U B	R O U T	I N E =======================================


sub_C99E:				; CODE XREF: ROM:0000C986p
		moveq	#0,d0
		move.b	$1A(a0),d0
		add.w	d0,d0
		movea.l	4(a0),a3
		adda.w	(a3,d0.w),a3
		addq.w	#2,a3
		bset	#5,1(a0)
		move.b	0(a0),d4
		move.b	1(a0),d5
		movea.l	a0,a1
		bra.s	loc_C9CA
; ---------------------------------------------------------------------------

loc_C9C2:				; CODE XREF: sub_C99E:loc_CA18j
		bsr.w	SingleObjectLoad
		bne.s	loc_CA1C
		addq.w	#8,a3

loc_C9CA:				; CODE XREF: sub_C99E+22j
		move.b	#4,$24(a1)
		move.b	d4,0(a1)
		move.l	a3,4(a1)
		move.b	d5,1(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	2(a0),2(a1)
		move.b	$18(a0),$18(a1)
		move.b	$19(a0),$19(a1)
		move.w	(a4)+,$10(a1)
		move.w	(a4)+,$12(a1)
		cmpa.l	a0,a1
		bcc.s	loc_CA18
		move.l	a0,-(sp)
		movea.l	a1,a0
		bsr.w	SpeedToPos
		add.w	d2,$12(a0)
		movea.l	(sp)+,a0
		bsr.w	DisplaySprite1

loc_CA18:				; CODE XREF: sub_C99E+66j
		dbf	d1,loc_C9C2

loc_CA1C:				; CODE XREF: sub_C99E+28j
		move.w	#sfx_WallSmash,d0	; "?"
		jmp	(PlaySound_Special).l
; End of function sub_C99E

; ---------------------------------------------------------------------------
Obj3C_FragSpdRight:dc.w	 $400,$FB00	   ; 0 ; DATA XREF: ROM:0000C952o
		dc.w  $600,$FF00	; 2
		dc.w  $600, $100	; 4
		dc.w  $400, $500	; 6
		dc.w  $600,$FA00	; 8
		dc.w  $800,$FE00	; 10
		dc.w  $800, $200	; 12
		dc.w  $600, $600	; 14
Obj3C_FragSpdLeft:dc.w $FA00,$FA00	  ; 0 ;	DATA XREF: ROM:0000C968o
		dc.w $F800,$FE00	; 2
		dc.w $F800, $200	; 4
		dc.w $FA00, $600	; 6
		dc.w $FC00,$FB00	; 8
		dc.w $FA00,$FF00	; 10
		dc.w $FA00, $100	; 12
		dc.w $FC00, $500	; 14
Map_Obj3C:	dc.w word_CA6C-Map_Obj3C ; DATA	XREF: ROM:0000C8E0o
					; ROM:Map_Obj3Co ...
		dc.w word_CAAE-Map_Obj3C
		dc.w word_CAF0-Map_Obj3C
word_CA6C:	dc.w 8			; DATA XREF: ROM:Map_Obj3Co
		dc.w $E005,    0,    0,$FFF0; 0
		dc.w $F005,    0,    0,$FFF0; 4
		dc.w	 5,    0,    0,$FFF0; 8
		dc.w $1005,    0,    0,$FFF0; 12
		dc.w $E005,    4,    2,	   0; 16
		dc.w $F005,    4,    2,	   0; 20
		dc.w	 5,    4,    2,	   0; 24
		dc.w $1005,    4,    2,	   0; 28
word_CAAE:	dc.w 8			; DATA XREF: ROM:0000CA68o
		dc.w $E005,    4,    2,$FFF0; 0
		dc.w $F005,    4,    2,$FFF0; 4
		dc.w	 5,    4,    2,$FFF0; 8
		dc.w $1005,    4,    2,$FFF0; 12
		dc.w $E005,    4,    2,	   0; 16
		dc.w $F005,    4,    2,	   0; 20
		dc.w	 5,    4,    2,	   0; 24
		dc.w $1005,    4,    2,	   0; 28
word_CAF0:	dc.w 8			; DATA XREF: ROM:0000CA6Ao
		dc.w $E005,    4,    2,$FFF0; 0
		dc.w $F005,    4,    2,$FFF0; 4
		dc.w	 5,    4,    2,$FFF0; 8
		dc.w $1005,    4,    2,$FFF0; 12
		dc.w $E005,    8,    4,	   0; 16
		dc.w $F005,    8,    4,	   0; 20
		dc.w	 5,    8,    4,	   0; 24
		dc.w $1005,    8,    4,	   0; 28
; ---------------------------------------------------------------------------
		nop

; =============== S U B	R O U T	I N E =======================================


ObjectsLoad:
		lea	(v_objspace).w,a0
		moveq	#$7F,d7	
		moveq	#0,d0
		cmpi.b	#6,(v_objspace+$24).w
		bcc.s	loc_CB5E

sub_CB44:
		move.b	(a0),d0
		beq.s	loc_CB54
		add.w	d0,d0
		add.w	d0,d0
		movea.l	Obj_Index-4(pc,d0.w),a1
		jsr	(a1)
		moveq	#0,d0

loc_CB54:
		lea	$40(a0),a0
		dbf	d7,sub_CB44
		rts
; End of function sub_CB44

; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR ObjectsLoad

loc_CB5E:				; CODE XREF: ObjectsLoad+Ej
		moveq	#$1F,d7
		bsr.s	sub_CB44
		moveq	#$5F,d7	

loc_CB64:				; CODE XREF: ObjectsLoad:loc_CB78j
		moveq	#0,d0
		move.b	(a0),d0
		beq.s	loc_CB74
		tst.b	1(a0)
		bpl.s	loc_CB74
		bsr.w	DisplaySprite

loc_CB74:				; CODE XREF: ObjectsLoad+34j
					; ObjectsLoad+3Aj
		lea	$40(a0),a0

loc_CB78:
		dbf	d7,loc_CB64
		rts
; END OF FUNCTION CHUNK	FOR ObjectsLoad
; ---------------------------------------------------------------------------
Obj_Index:	dc.l Obj01
                dc.l Obj02
                dc.l Obj03
                dc.l Obj04
		dc.l Obj05
                dc.l Obj06
                dc.l NullObject
                dc.l Obj08
		dc.l Obj09
                dc.l Obj0A
                dc.l Obj0B
                dc.l Obj0C
		dc.l Obj0D
                dc.l Obj0E
                dc.l Obj0F
                dc.l Obj10
		dc.l Obj11
                dc.l Obj12
                dc.l Obj13
                dc.l Obj14
		dc.l Obj15
                dc.l Obj16
                dc.l Obj17
                dc.l Obj18
		dc.l Obj19
                dc.l Obj1A
                dc.l NullObject
                dc.l Obj1C
		dc.l NullObject
                dc.l NullObject
                dc.l Obj1F
                dc.l NullObject
		dc.l Obj21
                dc.l Obj22
                dc.l Obj23
                dc.l Obj24
		dc.l Obj25
                dc.l Obj26
                dc.l Obj27
                dc.l Obj28
		dc.l Obj29
                dc.l Obj2A
                dc.l Obj2B
                dc.l Obj2C
		dc.l NullObject
                dc.l Obj2E
                dc.l NullObject
                dc.l NullObject
		dc.l NullObject
                dc.l NullObject
                dc.l NullObject
                dc.l Obj34
		dc.l NullObject
                dc.l Obj36
                dc.l Obj37
                dc.l Obj38
		dc.l Obj39
                dc.l Obj3A
                dc.l Obj3B
                dc.l Obj3C
		dc.l Obj3D
                dc.l Obj3E
                dc.l Obj3F
                dc.l Obj40
		dc.l Obj41
                dc.l Obj42
                dc.l NullObject
                dc.l Obj44
		dc.l NullObject
                dc.l NullObject
                dc.l NullObject
                dc.l Obj48
		dc.l Obj49
                dc.l Obj4A
                dc.l Obj4B
                dc.l Obj4C
		dc.l Obj4D
                dc.l Obj4E
                dc.l Obj4F
                dc.l Obj50
		dc.l Obj51
                dc.l Obj52
                dc.l Obj53
                dc.l Obj54
		dc.l Obj55
                dc.l Obj56
                dc.l Obj57
                dc.l Obj58
		dc.l NullObject
                dc.l NullObject
                dc.l NullObject
                dc.l NullObject
		dc.l NullObject
                dc.l NullObject
                dc.l NullObject
                dc.l NullObject
		dc.l NullObject
                dc.l NullObject
                dc.l NullObject
                dc.l NullObject
		dc.l NullObject
                dc.l NullObject
                dc.l NullObject
                dc.l NullObject
		dc.l NullObject
                dc.l NullObject
                dc.l NullObject
                dc.l NullObject
		dc.l NullObject
                dc.l NullObject
                dc.l NullObject
                dc.l NullObject
		dc.l NullObject
                dc.l NullObject
                dc.l NullObject
                dc.l NullObject
		dc.l NullObject
                dc.l NullObject
                dc.l NullObject
                dc.l NullObject
		dc.l Obj79
                dc.l NullObject
                dc.l NullObject
                dc.l NullObject
		dc.l Obj7D
                dc.l NullObject
                dc.l NullObject
                dc.l NullObject
		dc.l NullObject
                dc.l NullObject
                dc.l NullObject
                dc.l NullObject
		dc.l NullObject
                dc.l NullObject
                dc.l NullObject
                dc.l NullObject
		dc.l NullObject
                dc.l Obj8A
                dc.l NullObject
                dc.l NullObject
; ---------------------------------------------------------------------------

NullObject:			; DATA XREF: ROM:Obj_Indexo
		bra.w	DeleteObject

; =============== S U B	R O U T	I N E =======================================


ObjectFall:				; CODE XREF: ROM:loc_8D46p
					; ROM:loc_8E2Ep ...
		move.l	8(a0),d2
		move.l	$C(a0),d3
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.w	$12(a0),d0
		addi.w	#$38,$12(a0) 
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d2,8(a0)
		move.l	d3,$C(a0)
		rts
; End of function ObjectFall


; =============== S U B	R O U T	I N E =======================================


SpeedToPos:				; CODE XREF: ROM:loc_9D4Ep
					; ROM:00009E1Cp ...
		move.l	8(a0),d2
		move.l	$C(a0),d3
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.w	$12(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d2,8(a0)
		move.l	d3,$C(a0)
		rts
; End of function SpeedToPos


; =============== S U B	R O U T	I N E =======================================


DisplaySprite:				; CODE XREF: ROM:loc_7D5Aj
					; ROM:00008502j ...
		lea	(v_spritequeue).w,a1
		move.w	$18(a0),d0
		lsr.w	#1,d0
		andi.w	#$380,d0
		adda.w	d0,a1
		cmpi.w	#$7E,(a1) ; "~"
		bcc.s	locret_CE20
		addq.w	#2,(a1)
		adda.w	(a1),a1
		move.w	a0,(a1)

locret_CE20:				; CODE XREF: DisplaySprite+14j
		rts
; End of function DisplaySprite


; =============== S U B	R O U T	I N E =======================================


DisplaySprite1:			; CODE XREF: ROM:00008EDCp
					; sub_C99E+76p
		lea	(v_spritequeue).w,a2
		move.w	$18(a1),d0
		lsr.w	#1,d0
		andi.w	#$380,d0
		adda.w	d0,a2
		cmpi.w	#$7E,(a2) ; "~"
		bcc.s	locret_CE3E
		addq.w	#2,(a2)
		adda.w	(a2),a2
		move.w	a1,(a2)

locret_CE3E:				; CODE XREF: DisplaySprite1+14j
		rts
; End of function DisplaySprite1

; ---------------------------------------------------------------------------

DisplaySprite_Param:			; CODE XREF: ROM:00007BBAj
		lea	(v_spritequeue).w,a1
		lsr.w	#1,d0
		andi.w	#$380,d0
		adda.w	d0,a1
		cmpi.w	#$7E,(a1) ; "~"
		bcc.s	locret_CE58
		addq.w	#2,(a1)
		adda.w	(a1),a1
		move.w	a0,(a1)

locret_CE58:				; CODE XREF: ROM:0000CE50j
		rts
; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR sub_8CEC

MarkObjGone:				; CODE XREF: sub_8CEC+12j sub_8DD6+10j ...
		tst.w	(f_2player).w
		beq.s	loc_CE64
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_CE64:				; CODE XREF: sub_8CEC+4172j
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	loc_CE7C
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_CE7C:				; CODE XREF: sub_8CEC+4188j
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		beq.s	loc_CE8E
		bclr	#7,2(a2,d0.w)

loc_CE8E:				; CODE XREF: sub_8CEC+419Aj
		bra.w	DeleteObject
; END OF FUNCTION CHUNK	FOR sub_8CEC
; ---------------------------------------------------------------------------

loc_CE92:				; CODE XREF: ROM:00013E3Ej
		tst.w	(f_2player).w
		beq.s	loc_CE9A
		rts
; ---------------------------------------------------------------------------

loc_CE9A:				; CODE XREF: ROM:0000CE96j
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	loc_CEB0
		rts
; ---------------------------------------------------------------------------

loc_CEB0:				; CODE XREF: ROM:0000CEAAj
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		beq.s	loc_CEC2
		bclr	#7,2(a2,d0.w)

loc_CEC2:				; CODE XREF: ROM:0000CEBAj
		bra.w	DeleteObject
; ---------------------------------------------------------------------------

loc_CEC6:				; CODE XREF: ROM:loc_16A8Cj
					; ROM:loc_1786Cj
		tst.w	(f_2player).w
		bne.s	loc_CEFA
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	loc_CEE4
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_CEE4:				; CODE XREF: ROM:0000CEDCj
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		beq.s	loc_CEF6
		bclr	#7,2(a2,d0.w)

loc_CEF6:				; CODE XREF: ROM:0000CEEEj
		bra.w	DeleteObject
; ---------------------------------------------------------------------------

loc_CEFA:				; CODE XREF: ROM:0000CECAj
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	d0,d1
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	loc_CF14
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_CF14:				; CODE XREF: ROM:0000CF0Cj
		sub.w	($FFFFF7DC).w,d1
		cmpi.w	#$280,d1
		bhi.w	loc_CF24
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_CF24:				; CODE XREF: ROM:0000CF1Cj
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		beq.s	loc_CF36
		bclr	#7,2(a2,d0.w)

loc_CF36:				; CODE XREF: ROM:0000CF2Ej
		bra.w	*+4
; START	OF FUNCTION CHUNK FOR sub_8CEC

DeleteObject:
		movea.l	a0,a1

sub_CF3C:
		moveq	#0,d1
		moveq	#$F,d0

loc_CF40:
		move.l	d1,(a1)+
		dbf	d0,loc_CF40
		rts
; End of function sub_CF3C


; =============== S U B	R O U T	I N E =======================================


AnimateSprite:				; CODE XREF: ROM:0000946Ap
					; ROM:0000956Ap ...
		moveq	#0,d0
		move.b	$1C(a0),d0
		cmp.b	$1D(a0),d0
		beq.s	loc_CF64
		move.b	d0,$1D(a0)
		move.b	#0,$1B(a0)
		move.b	#0,$1E(a0)

loc_CF64:				; CODE XREF: AnimateSprite+Aj
		subq.b	#1,$1E(a0)
		bpl.s	locret_CFA4
		add.w	d0,d0
		adda.w	(a1,d0.w),a1
		move.b	(a1),$1E(a0)
		moveq	#0,d1
		move.b	$1B(a0),d1
		move.b	1(a1,d1.w),d0
		bmi.s	loc_CFA6

loc_CF80:				; CODE XREF: AnimateSprite+6Cj
					; AnimateSprite+80j
		move.b	d0,d1
		andi.b	#$1F,d0
		move.b	d0,$1A(a0)
		move.b	$22(a0),d0
		rol.b	#3,d1
		eor.b	d0,d1
		andi.b	#3,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		addq.b	#1,$1B(a0)

locret_CFA4:				; CODE XREF: AnimateSprite+20j
		rts
; ---------------------------------------------------------------------------

loc_CFA6:				; CODE XREF: AnimateSprite+36j
		addq.b	#1,d0
		bne.s	loc_CFB6
		move.b	#0,$1B(a0)
		move.b	1(a1),d0
		bra.s	loc_CF80
; ---------------------------------------------------------------------------

loc_CFB6:				; CODE XREF: AnimateSprite+60j
		addq.b	#1,d0
		bne.s	loc_CFCA
		move.b	2(a1,d1.w),d0
		sub.b	d0,$1B(a0)
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0
		bra.s	loc_CF80
; ---------------------------------------------------------------------------

loc_CFCA:				; CODE XREF: AnimateSprite+70j
		addq.b	#1,d0
		bne.s	loc_CFD6
		move.b	2(a1,d1.w),$1C(a0)
		rts
; ---------------------------------------------------------------------------

loc_CFD6:				; CODE XREF: AnimateSprite+84j
		addq.b	#1,d0
		bne.s	loc_CFE0
		addq.b	#2,$24(a0)
		rts
; ---------------------------------------------------------------------------

loc_CFE0:				; CODE XREF: AnimateSprite+90j
		addq.b	#1,d0
		bne.s	loc_CFF0
		move.b	#0,$1B(a0)
		clr.b	$25(a0)
		rts
; ---------------------------------------------------------------------------

loc_CFF0:				; CODE XREF: AnimateSprite+9Aj
		addq.b	#1,d0
		bne.s	locret_CFFA
		addq.b	#2,$25(a0)
		rts
; ---------------------------------------------------------------------------

locret_CFFA:				; CODE XREF: AnimateSprite+AAj
		rts
; End of function AnimateSprite

; ---------------------------------------------------------------------------
BldSpr_ScrPos:	dc.l 0
		dc.l v_screenposx
		dc.l v_bgscreenposx
		dc.l v_bg3screenposx

; =============== S U B	R O U T	I N E =======================================


BuildSprites:				; CODE XREF: ROM:000033B8p
					; ROM:00003408p ...

; FUNCTION CHUNK AT 0000D302 SIZE 00000130 BYTES
; FUNCTION CHUNK AT 0000D442 SIZE 00000228 BYTES

		tst.w	(f_2player).w
		bne.w	BuildSprites_2p
		lea	($FFFFF800).w,a2
		moveq	#0,d5
		moveq	#0,d4
		tst.b	($FFFFF711).w
		beq.s	loc_D026
		bsr.w	BuildSprites2

loc_D026:				; CODE XREF: BuildSprites+14j
		lea	(v_spritequeue).w,a4
		moveq	#7,d7

loc_D02C:				; CODE XREF: BuildSprites+FAj
		tst.w	(a4)
		beq.w	loc_D102
		moveq	#2,d6

loc_D034:				; CODE XREF: BuildSprites+F2j
		movea.w	(a4,d6.w),a0
		tst.b	(a0)
		beq.w	loc_D124
		tst.l	4(a0)
		beq.w	loc_D124
		andi.b	#$7F,1(a0)
		move.b	1(a0),d0
		move.b	d0,d4
		btst	#6,d0
		bne.w	loc_D126
		andi.w	#$C,d0
		beq.s	loc_D0B2
		movea.l	BldSpr_ScrPos(pc,d0.w),a1
		moveq	#0,d0
		move.b	$19(a0),d0
		move.w	8(a0),d3
		sub.w	(a1),d3
		move.w	d3,d1
		add.w	d0,d1
		bmi.w	loc_D0FA
		move.w	d3,d1
		sub.w	d0,d1
		cmpi.w	#$140,d1
		bge.w	loc_D0FA
		addi.w	#$80,d3
		btst	#4,d4
		beq.s	loc_D0BC
		moveq	#0,d0
		move.b	$16(a0),d0
		move.w	$C(a0),d2
		sub.w	4(a1),d2
		move.w	d2,d1
		add.w	d0,d1
		bmi.s	loc_D0FA
		move.w	d2,d1
		sub.w	d0,d1
		cmpi.w	#$E0,d1	
		bge.s	loc_D0FA
		addi.w	#$80,d2
		bra.s	loc_D0D4
; ---------------------------------------------------------------------------

loc_D0B2:				; CODE XREF: BuildSprites+52j
		move.w	$A(a0),d2
		move.w	8(a0),d3
		bra.s	loc_D0D4
; ---------------------------------------------------------------------------

loc_D0BC:				; CODE XREF: BuildSprites+80j
		move.w	$C(a0),d2
		sub.w	4(a1),d2
		addi.w	#$80,d2
		cmpi.w	#$60,d2
		bcs.s	loc_D0FA
		cmpi.w	#$180,d2
		bcc.s	loc_D0FA

loc_D0D4:				; CODE XREF: BuildSprites+A4j
					; BuildSprites+AEj
		movea.l	4(a0),a1
		moveq	#0,d1
		btst	#5,d4
		bne.s	loc_D0F0
		move.b	$1A(a0),d1
		add.w	d1,d1
		adda.w	(a1,d1.w),a1
		move.w	(a1)+,d1
		subq.w	#1,d1
		bmi.s	loc_D0F4

loc_D0F0:				; CODE XREF: BuildSprites+D2j
		bsr.w	sub_D1B6

loc_D0F4:				; CODE XREF: BuildSprites+E2j
		ori.b	#$80,1(a0)

loc_D0FA:				; CODE XREF: BuildSprites+68j
					; BuildSprites+74j ...
		addq.w	#2,d6
		subq.w	#2,(a4)
		bne.w	loc_D034

loc_D102:				; CODE XREF: BuildSprites+22j
		lea	$80(a4),a4
		dbf	d7,loc_D02C
		move.b	d5,($FFFFF62C).w
		cmpi.b	#$50,d5	
		beq.s	loc_D11C
		move.l	#0,(a2)
		rts
; ---------------------------------------------------------------------------

loc_D11C:				; CODE XREF: BuildSprites+106j
		move.b	#0,-5(a2)
		rts
; ---------------------------------------------------------------------------

loc_D124:				; CODE XREF: BuildSprites+2Ej
					; BuildSprites+36j
		bra.s	loc_D0FA
; ---------------------------------------------------------------------------

loc_D126:				; CODE XREF: BuildSprites+4Aj
		move.l	a4,-(sp)
		lea	(v_screenposx).w,a4
		movea.w	2(a0),a3
		movea.l	4(a0),a5
		moveq	#0,d0
		move.b	$E(a0),d0
		move.w	8(a0),d3
		sub.w	(a4),d3
		move.w	d3,d1
		add.w	d0,d1
		bmi.w	loc_D1B0
		move.w	d3,d1
		sub.w	d0,d1
		cmpi.w	#$140,d1
		bge.s	loc_D1B0
		move.w	$C(a0),d2
		sub.w	4(a4),d2
		addi.w	#$80,d2	
		cmpi.w	#$60,d2	
		bcs.s	loc_D1B0
		cmpi.w	#$180,d2
		bcc.s	loc_D1B0
		ori.b	#$80,1(a0)
		lea	$10(a0),a6
		moveq	#0,d0
		move.b	$F(a0),d0
		subq.w	#1,d0
		bcs.s	loc_D1B0

loc_D17E:				; CODE XREF: BuildSprites+1A0j
		swap	d0
		move.w	(a6)+,d3
		sub.w	(a4),d3
		addi.w	#$80,d3	
		move.w	(a6)+,d2
		sub.w	4(a4),d2
		addi.w	#$80,d2	
		addq.w	#1,a6
		moveq	#0,d1
		move.b	(a6)+,d1
		add.w	d1,d1
		movea.l	a5,a1
		adda.w	(a1,d1.w),a1
		move.w	(a1)+,d1
		subq.w	#1,d1
		bmi.s	loc_D1AA
		bsr.w	sub_D1BA

loc_D1AA:				; CODE XREF: BuildSprites+198j
		swap	d0
		dbf	d0,loc_D17E

loc_D1B0:				; CODE XREF: BuildSprites+138j
					; BuildSprites+144j ...
		movea.l	(sp)+,a4
		bra.w	loc_D0FA
; End of function BuildSprites


; =============== S U B	R O U T	I N E =======================================


sub_D1B6:				; CODE XREF: BuildSprites:loc_D0F0p
		movea.w	2(a0),a3
; End of function sub_D1B6


; =============== S U B	R O U T	I N E =======================================


sub_D1BA:				; CODE XREF: BuildSprites+19Ap
		cmpi.b	#$50,d5	
		bcc.s	locret_D1F6
		btst	#0,d4
		bne.s	loc_D1F8
		btst	#1,d4
		bne.w	loc_D258

loc_D1CE:				; CODE XREF: sub_D1BA+38j
					; S1SS_ShowLayout+114p
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.w	(a1)+,d0
		add.w	a3,d0
		move.w	d0,(a2)+
		addq.w	#2,a1
		move.w	(a1)+,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D1F0
		addq.w	#1,d0

loc_D1F0:				; CODE XREF: sub_D1BA+32j
		move.w	d0,(a2)+
		dbf	d1,loc_D1CE

locret_D1F6:				; CODE XREF: sub_D1BA+4j
		rts
; ---------------------------------------------------------------------------

loc_D1F8:				; CODE XREF: sub_D1BA+Aj
		btst	#1,d4
		bne.w	loc_D2A0

loc_D200:				; CODE XREF: sub_D1BA+78j
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4
		move.b	d4,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.w	(a1)+,d0
		add.w	a3,d0
		eori.w	#$800,d0
		move.w	d0,(a2)+
		addq.w	#2,a1
		move.w	(a1)+,d0
		neg.w	d0
		move.b	byte_D238(pc,d4.w),d4
		sub.w	d4,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D230
		addq.w	#1,d0

loc_D230:				; CODE XREF: sub_D1BA+72j
		move.w	d0,(a2)+
		dbf	d1,loc_D200
		rts
; ---------------------------------------------------------------------------
byte_D238:	dc.b   8,  8,  8,  8	; 0
		dc.b $10,$10,$10,$10	; 4
		dc.b $18,$18,$18,$18	; 8
		dc.b $20,$20,$20,$20	; 12
byte_D248:	dc.b   8,$10,$18,$20	; 0
		dc.b   8,$10,$18,$20	; 4
		dc.b   8,$10,$18,$20	; 8
		dc.b   8,$10,$18,$20	; 12
; ---------------------------------------------------------------------------

loc_D258:				; CODE XREF: sub_D1BA+10j sub_D1BA+D0j
		move.b	(a1)+,d0
		move.b	(a1),d4
		ext.w	d0
		neg.w	d0
		move.b	byte_D248(pc,d4.w),d4
		sub.w	d4,d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.w	(a1)+,d0
		add.w	a3,d0
		eori.w	#$1000,d0
		move.w	d0,(a2)+
		addq.w	#2,a1
		move.w	(a1)+,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D288
		addq.w	#1,d0

loc_D288:				; CODE XREF: sub_D1BA+CAj
		move.w	d0,(a2)+
		dbf	d1,loc_D258
		rts
; ---------------------------------------------------------------------------
byte_D290:	dc.b   8,$10,$18,$20	; 0
		dc.b   8,$10,$18,$20	; 4
		dc.b   8,$10,$18,$20	; 8
		dc.b   8,$10,$18,$20	; 12
; ---------------------------------------------------------------------------

loc_D2A0:				; CODE XREF: sub_D1BA+42j
					; sub_D1BA+122j
		move.b	(a1)+,d0
		move.b	(a1),d4
		ext.w	d0
		neg.w	d0
		move.b	byte_D290(pc,d4.w),d4
		sub.w	d4,d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4
		move.b	d4,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.w	(a1)+,d0
		add.w	a3,d0
		eori.w	#$1800,d0
		move.w	d0,(a2)+
		addq.w	#2,a1
		move.w	(a1)+,d0
		neg.w	d0
		move.b	byte_D2E2(pc,d4.w),d4
		sub.w	d4,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D2DA
		addq.w	#1,d0

loc_D2DA:				; CODE XREF: sub_D1BA+11Cj
		move.w	d0,(a2)+
		dbf	d1,loc_D2A0
		rts
; End of function sub_D1BA

; ---------------------------------------------------------------------------
byte_D2E2:	dc.b   8,  8,  8,  8	; 0
		dc.b $10,$10,$10,$10	; 4
		dc.b $18,$18,$18,$18	; 8
		dc.b $20,$20,$20,$20	; 12
BldSpr_ScrPos_2p:dc.l 0
		dc.l v_screenposx
		dc.l v_bgscreenposx
		dc.l v_bg3screenposx
; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR BuildSprites

BuildSprites_2p:			; CODE XREF: BuildSprites+4j
					; BuildSprites+2FAj
		tst.w	($FFFFF644).w
		bne.s	BuildSprites_2p
		lea	($FFFFF800).w,a2
		moveq	#2,d5
		moveq	#0,d4
		move.l	#$1D80F01,(a2)+
		move.l	#1,(a2)+
		move.l	#$1D80F02,(a2)+
		move.l	#0,(a2)+
		tst.b	($FFFFF711).w
		beq.s	loc_D332
		bsr.w	BuildSprites2_2p

loc_D332:				; CODE XREF: BuildSprites+320j
		lea	(v_spritequeue).w,a4
		moveq	#7,d7

loc_D338:				; CODE XREF: BuildSprites+408j
		move.w	(a4),d0
		beq.w	loc_D410
		move.w	d0,-(sp)
		moveq	#2,d6

loc_D342:				; CODE XREF: BuildSprites+3FEj
		movea.w	(a4,d6.w),a0
		tst.b	(a0)
		beq.w	loc_D406
		andi.b	#$7F,1(a0) 
		move.b	1(a0),d0
		move.b	d0,d4
		btst	#6,d0
		bne.w	loc_D54A
		andi.w	#$C,d0
		beq.s	loc_D3B6
		movea.l	BldSpr_ScrPos_2p(pc,d0.w),a1
		moveq	#0,d0
		move.b	$19(a0),d0
		move.w	8(a0),d3
		sub.w	(a1),d3
		move.w	d3,d1
		add.w	d0,d1
		bmi.w	loc_D406
		move.w	d3,d1
		sub.w	d0,d1
		cmpi.w	#$140,d1
		bge.s	loc_D406
		addi.w	#$80,d3	
		btst	#4,d4
		beq.s	loc_D3C4
		moveq	#0,d0
		move.b	$16(a0),d0
		move.w	$C(a0),d2
		sub.w	4(a1),d2
		move.w	d2,d1
		add.w	d0,d1
		bmi.s	loc_D406
		move.w	d2,d1
		sub.w	d0,d1
		cmpi.w	#$E0,d1	
		bge.s	loc_D406
		addi.w	#$100,d2
		bra.s	loc_D3E0
; ---------------------------------------------------------------------------

loc_D3B6:				; CODE XREF: BuildSprites+358j
		move.w	$A(a0),d2
		move.w	8(a0),d3
		addi.w	#$80,d2	
		bra.s	loc_D3E0
; ---------------------------------------------------------------------------

loc_D3C4:				; CODE XREF: BuildSprites+384j
		move.w	$C(a0),d2
		sub.w	4(a1),d2
		addi.w	#$80,d2	
		cmpi.w	#$60,d2	
		bcs.s	loc_D406
		cmpi.w	#$180,d2
		bcc.s	loc_D406
		addi.w	#$80,d2	

loc_D3E0:				; CODE XREF: BuildSprites+3A8j
					; BuildSprites+3B6j
		movea.l	4(a0),a1
		moveq	#0,d1
		btst	#5,d4
		bne.s	loc_D3FC
		move.b	$1A(a0),d1
		add.w	d1,d1
		adda.w	(a1,d1.w),a1
		move.w	(a1)+,d1
		subq.w	#1,d1
		bmi.s	loc_D400

loc_D3FC:				; CODE XREF: BuildSprites+3DEj
		bsr.w	sub_D6A2

loc_D400:				; CODE XREF: BuildSprites+3EEj
		ori.b	#$80,1(a0)

loc_D406:				; CODE XREF: BuildSprites+33Cj
					; BuildSprites+36Ej ...
		addq.w	#2,d6
		subq.w	#2,(sp)
		bne.w	loc_D342
		addq.w	#2,sp

loc_D410:				; CODE XREF: BuildSprites+32Ej
		lea	$80(a4),a4
		dbf	d7,loc_D338
		move.b	d5,($FFFFF62C).w
		cmpi.b	#$50,d5	
		bcc.s	loc_D42A
		move.l	#0,(a2)
		bra.s	loc_D442
; ---------------------------------------------------------------------------

loc_D42A:				; CODE XREF: BuildSprites+414j
		move.b	#0,-5(a2)
		bra.s	loc_D442
; END OF FUNCTION CHUNK	FOR BuildSprites
; ---------------------------------------------------------------------------
dword_D432:	dc.l 0
		dc.l v_screenposx_2p
		dc.l v_bgscreenposx_2p
		dc.l v_bg3screenposx_2p
; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR BuildSprites

loc_D442:				; CODE XREF: BuildSprites+41Cj
					; BuildSprites+424j
		lea	(v_spritetablebuffer).w,a2
		moveq	#0,d5
		moveq	#0,d4
		tst.b	($FFFFF711).w
		beq.s	loc_D454
		bsr.w	sub_DACA

loc_D454:				; CODE XREF: BuildSprites+442j
		lea	(v_spritequeue).w,a4
		moveq	#7,d7

loc_D45A:				; CODE XREF: BuildSprites+520j
		tst.w	(a4)
		beq.w	loc_D528
		moveq	#2,d6

loc_D462:				; CODE XREF: BuildSprites+518j
		movea.w	(a4,d6.w),a0
		tst.b	(a0)
		beq.w	loc_D520
		move.b	1(a0),d0
		move.b	d0,d4
		btst	#6,d0
		bne.w	loc_D5DA
		andi.w	#$C,d0
		beq.s	loc_D4D0
		movea.l	dword_D432(pc,d0.w),a1
		moveq	#0,d0
		move.b	$19(a0),d0
		move.w	8(a0),d3
		sub.w	(a1),d3
		move.w	d3,d1
		add.w	d0,d1
		bmi.w	loc_D520
		move.w	d3,d1
		sub.w	d0,d1
		cmpi.w	#$140,d1
		bge.s	loc_D520
		addi.w	#$80,d3
		btst	#4,d4
		beq.s	loc_D4DE
		moveq	#0,d0
		move.b	$16(a0),d0
		move.w	$C(a0),d2
		sub.w	4(a1),d2
		move.w	d2,d1
		add.w	d0,d1
		bmi.s	loc_D520
		move.w	d2,d1
		sub.w	d0,d1
		cmpi.w	#$E0,d1	
		bge.s	loc_D520
		addi.w	#$1E0,d2
		bra.s	loc_D4FA
; ---------------------------------------------------------------------------

loc_D4D0:				; CODE XREF: BuildSprites+472j
		move.w	$A(a0),d2
		move.w	8(a0),d3
		addi.w	#$160,d2
		bra.s	loc_D4FA
; ---------------------------------------------------------------------------

loc_D4DE:				; CODE XREF: BuildSprites+49Ej
		move.w	$C(a0),d2
		sub.w	4(a1),d2
		addi.w	#$80,d2
		cmpi.w	#$60,d2
		bcs.s	loc_D520
		cmpi.w	#$180,d2
		bcc.s	loc_D520
		addi.w	#$160,d2

loc_D4FA:				; CODE XREF: BuildSprites+4C2j
					; BuildSprites+4D0j
		movea.l	4(a0),a1
		moveq	#0,d1
		btst	#5,d4
		bne.s	loc_D516
		move.b	$1A(a0),d1
		add.w	d1,d1
		adda.w	(a1,d1.w),a1
		move.w	(a1)+,d1
		subq.w	#1,d1
		bmi.s	loc_D51A

loc_D516:				; CODE XREF: BuildSprites+4F8j
		bsr.w	sub_D6A2

loc_D51A:				; CODE XREF: BuildSprites+508j
		ori.b	#$80,1(a0)

loc_D520:				; CODE XREF: BuildSprites+45Cj
					; BuildSprites+488j ...
		addq.w	#2,d6
		subq.w	#2,(a4)
		bne.w	loc_D462

loc_D528:				; CODE XREF: BuildSprites+450j
		lea	$80(a4),a4
		dbf	d7,loc_D45A
		move.b	d5,($FFFFF62C).w
		cmpi.b	#$50,d5	
		beq.s	loc_D542
		move.l	#0,(a2)
		rts
; ---------------------------------------------------------------------------

loc_D542:				; CODE XREF: BuildSprites+52Cj
		move.b	#0,-5(a2)
		rts
; ---------------------------------------------------------------------------

loc_D54A:				; CODE XREF: BuildSprites+350j
		move.l	a4,-(sp)
		lea	(v_screenposx).w,a4
		movea.w	2(a0),a3
		movea.l	4(a0),a5
		moveq	#0,d0
		move.b	$E(a0),d0
		move.w	8(a0),d3
		sub.w	(a4),d3
		move.w	d3,d1
		add.w	d0,d1
		bmi.w	loc_D5D4
		move.w	d3,d1
		sub.w	d0,d1
		cmpi.w	#$140,d1
		bge.s	loc_D5D4
		move.w	$C(a0),d2
		sub.w	4(a4),d2
		addi.w	#$80,d2
		cmpi.w	#$60,d2
		bcs.s	loc_D5D4
		cmpi.w	#$180,d2
		bcc.s	loc_D5D4
		ori.b	#$80,1(a0)
		lea	$10(a0),a6
		moveq	#0,d0
		move.b	$F(a0),d0
		subq.w	#1,d0
		bcs.s	loc_D5D4

loc_D5A2:				; CODE XREF: BuildSprites+5C4j
		swap	d0
		move.w	(a6)+,d3
		sub.w	(a4),d3
		addi.w	#$80,d3
		move.w	(a6)+,d2
		sub.w	4(a4),d2
		addi.w	#$100,d2
		addq.w	#1,a6
		moveq	#0,d1
		move.b	(a6)+,d1
		add.w	d1,d1
		movea.l	a5,a1
		adda.w	(a1,d1.w),a1
		move.w	(a1)+,d1
		subq.w	#1,d1
		bmi.s	loc_D5CE
		bsr.w	sub_D6A6

loc_D5CE:				; CODE XREF: BuildSprites+5BCj
		swap	d0
		dbf	d0,loc_D5A2

loc_D5D4:				; CODE XREF: BuildSprites+55Cj
					; BuildSprites+568j ...
		movea.l	(sp)+,a4
		bra.w	loc_D406
; ---------------------------------------------------------------------------

loc_D5DA:				; CODE XREF: BuildSprites+46Aj
		move.l	a4,-(sp)
		lea	(v_screenposx_2p).w,a4
		movea.w	2(a0),a3
		movea.l	4(a0),a5
		moveq	#0,d0
		move.b	$E(a0),d0
		move.w	8(a0),d3
		sub.w	(a4),d3
		move.w	d3,d1
		add.w	d0,d1
		bmi.w	loc_D664
		move.w	d3,d1
		sub.w	d0,d1
		cmpi.w	#$140,d1
		bge.s	loc_D664
		move.w	$C(a0),d2
		sub.w	4(a4),d2
		addi.w	#$80,d2	
		cmpi.w	#$60,d2	
		bcs.s	loc_D664
		cmpi.w	#$180,d2
		bcc.s	loc_D664
		ori.b	#$80,1(a0)
		lea	$10(a0),a6
		moveq	#0,d0
		move.b	$F(a0),d0
		subq.w	#1,d0
		bcs.s	loc_D664

loc_D632:				; CODE XREF: BuildSprites+654j
		swap	d0
		move.w	(a6)+,d3
		sub.w	(a4),d3
		addi.w	#$80,d3	
		move.w	(a6)+,d2
		sub.w	4(a4),d2
		addi.w	#$1E0,d2
		addq.w	#1,a6
		moveq	#0,d1
		move.b	(a6)+,d1
		add.w	d1,d1
		movea.l	a5,a1
		adda.w	(a1,d1.w),a1
		move.w	(a1)+,d1
		subq.w	#1,d1
		bmi.s	loc_D65E
		bsr.w	sub_D6A6

loc_D65E:				; CODE XREF: BuildSprites+64Cj
		swap	d0
		dbf	d0,loc_D632

loc_D664:				; CODE XREF: BuildSprites+5ECj
					; BuildSprites+5F8j ...
		movea.l	(sp)+,a4
		bra.w	loc_D520
; END OF FUNCTION CHUNK	FOR BuildSprites

; =============== S U B	R O U T	I N E =======================================


ModifySpriteAttr_2P:			; CODE XREF: ROM:loc_7C14p
					; ROM:00008230p ...
		tst.w	(f_2player).w
		beq.s	locret_D684
		move.w	2(a0),d0
		andi.w	#$7FF,d0
		lsr.w	#1,d0
		andi.w	#$F800,2(a0)
		add.w	d0,2(a0)

locret_D684:				; CODE XREF: ModifySpriteAttr_2P+4j
		rts
; End of function ModifySpriteAttr_2P


; =============== S U B	R O U T	I N E =======================================


ModifyA1SpriteAttr_2P:			; CODE XREF: ROM:0000870Ap
					; ROM:0000A858p ...
		tst.w	(f_2player).w
		beq.s	ModifySpriteAttr_Not2pmode
		move.w	2(a1),d0
		andi.w	#$7FF,d0
		lsr.w	#1,d0
		andi.w	#$F800,2(a1)
		add.w	d0,2(a1)

ModifySpriteAttr_Not2pmode:		; CODE XREF: ModifyA1SpriteAttr_2P+4j
		rts
; End of function ModifyA1SpriteAttr_2P


; =============== S U B	R O U T	I N E =======================================


sub_D6A2:				; CODE XREF: BuildSprites:loc_D3FCp
					; BuildSprites:loc_D516p
		movea.w	2(a0),a3
; End of function sub_D6A2


; =============== S U B	R O U T	I N E =======================================


sub_D6A6:				; CODE XREF: BuildSprites+5BEp
					; BuildSprites+64Ep
		cmpi.b	#$50,d5	
		bcc.s	locret_D6E6
		btst	#0,d4
		bne.s	loc_D6F8
		btst	#1,d4
		bne.w	loc_D75A

loc_D6BA:				; CODE XREF: sub_D6A6+3Cj
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4
		move.b	byte_D6E8(pc,d4.w),(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		addq.w	#2,a1
		move.w	(a1)+,d0
		add.w	a3,d0
		move.w	d0,(a2)+
		move.w	(a1)+,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D6E0
		addq.w	#1,d0

loc_D6E0:				; CODE XREF: sub_D6A6+36j
		move.w	d0,(a2)+
		dbf	d1,loc_D6BA

locret_D6E6:				; CODE XREF: sub_D6A6+4j
		rts
; ---------------------------------------------------------------------------
byte_D6E8:	dc.b   0,  0		; 0
		dc.b   1,  1		; 2
		dc.b   4,  4		; 4
		dc.b   5,  5		; 6
		dc.b   8,  8		; 8
		dc.b   9,  9		; 10
		dc.b  $C, $C		; 12
		dc.b  $D, $D		; 14
; ---------------------------------------------------------------------------

loc_D6F8:				; CODE XREF: sub_D6A6+Aj
		btst	#1,d4
		bne.w	loc_D7B6

loc_D700:				; CODE XREF: sub_D6A6+8Ej
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4
		move.b	byte_D6E8(pc,d4.w),(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		addq.w	#2,a1
		move.w	(a1)+,d0
		add.w	a3,d0
		eori.w	#$800,d0
		move.w	d0,(a2)+
		move.w	(a1)+,d0
		neg.w	d0
		move.b	byte_D73A(pc,d4.w),d4
		sub.w	d4,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D732
		addq.w	#1,d0

loc_D732:				; CODE XREF: sub_D6A6+88j
		move.w	d0,(a2)+
		dbf	d1,loc_D700
		rts
; ---------------------------------------------------------------------------
byte_D73A:	dc.b   8,  8		; 0
		dc.b   8,  8		; 2
		dc.b $10,$10		; 4
		dc.b $10,$10		; 6
		dc.b $18,$18		; 8
		dc.b $18,$18		; 10
		dc.b $20,$20		; 12
		dc.b $20,$20		; 14
byte_D74A:	dc.b   8,$10,$18,$20	; 0
		dc.b   8,$10,$18,$20	; 4
		dc.b   8,$10,$18,$20	; 8
		dc.b   8,$10,$18,$20	; 12
; ---------------------------------------------------------------------------

loc_D75A:				; CODE XREF: sub_D6A6+10j sub_D6A6+EAj
		move.b	(a1)+,d0
		move.b	(a1),d4
		ext.w	d0
		neg.w	d0
		move.b	byte_D74A(pc,d4.w),d4
		sub.w	d4,d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4
		move.b	byte_D796(pc,d4.w),(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		addq.w	#2,a1
		move.w	(a1)+,d0
		add.w	a3,d0
		eori.w	#$1000,d0
		move.w	d0,(a2)+
		move.w	(a1)+,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D78E
		addq.w	#1,d0

loc_D78E:				; CODE XREF: sub_D6A6+E4j
		move.w	d0,(a2)+
		dbf	d1,loc_D75A
		rts
; ---------------------------------------------------------------------------
byte_D796:	dc.b   0,  0,  1,  1	; 0
		dc.b   4,  4,  5,  5	; 4
		dc.b   8,  8,  9,  9	; 8
		dc.b  $C, $C, $D, $D	; 12
byte_D7A6:	dc.b   8,$10,$18,$20	; 0
		dc.b   8,$10,$18,$20	; 4
		dc.b   8,$10,$18,$20	; 8
		dc.b   8,$10,$18,$20	; 12
; ---------------------------------------------------------------------------

loc_D7B6:				; CODE XREF: sub_D6A6+56j
					; sub_D6A6+14Ej
		move.b	(a1)+,d0
		move.b	(a1),d4
		ext.w	d0
		neg.w	d0
		move.b	byte_D7A6(pc,d4.w),d4
		sub.w	d4,d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4
		move.b	byte_D796(pc,d4.w),(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		addq.w	#2,a1
		move.w	(a1)+,d0
		add.w	a3,d0
		eori.w	#$1800,d0
		move.w	d0,(a2)+
		move.w	(a1)+,d0
		neg.w	d0
		move.b	byte_D7FA(pc,d4.w),d4
		sub.w	d4,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D7F2
		addq.w	#1,d0

loc_D7F2:				; CODE XREF: sub_D6A6+148j
		move.w	d0,(a2)+
		dbf	d1,loc_D7B6
		rts
; End of function sub_D6A6

; ---------------------------------------------------------------------------
byte_D7FA:	dc.b   8,  8,  8,  8	; 0
		dc.b $10,$10,$10,$10	; 4
		dc.b $18,$18,$18,$18	; 8
		dc.b $20,$20,$20,$20	; 12
		dc.b $30,$28,  0,  8	; 16
; ---------------------------------------------------------------------------
		sub.w	(v_screenposx).w,d0
		bmi.s	loc_D82E
		cmpi.w	#$140,d0
		bge.s	loc_D82E
		move.w	$C(a0),d1
		sub.w	(v_screenposy).w,d1
		bmi.s	loc_D82E
		cmpi.w	#$E0,d1	
		bge.s	loc_D82E
		moveq	#0,d0
		rts
; ---------------------------------------------------------------------------

loc_D82E:				; CODE XREF: ROM:0000D812j
					; ROM:0000D818j ...
		moveq	#1,d0
		rts
; ---------------------------------------------------------------------------
		moveq	#0,d1
		move.b	$19(a0),d1
		move.w	8(a0),d0
		sub.w	(v_screenposx).w,d0
		add.w	d1,d0
		bmi.s	loc_D862
		add.w	d1,d1
		sub.w	d1,d0
		cmpi.w	#$140,d0
		bge.s	loc_D862
		move.w	$C(a0),d1
		sub.w	(v_screenposy).w,d1
		bmi.s	loc_D862
		cmpi.w	#$E0,d1	
		bge.s	loc_D862
		moveq	#0,d0
		rts
; ---------------------------------------------------------------------------

loc_D862:				; CODE XREF: ROM:0000D842j
					; ROM:0000D84Cj ...
		moveq	#1,d0
		rts
; ---------------------------------------------------------------------------
		nop

; =============== S U B	R O U T	I N E =======================================


RingPosLoad:
		moveq	#0,d0
		move.b	($FFFFF710).w,d0
		move.w	RPL_Index(pc,d0.w),d0
		jmp	RPL_Index(pc,d0.w)
; End of function RingPosLoad

; ---------------------------------------------------------------------------
RPL_Index:	dc.w RPL_Main-RPL_Index	; DATA XREF: ROM:RPL_Indexo
					; ROM:0000D878o
		dc.w RPL_Next-RPL_Index
; ---------------------------------------------------------------------------

RPL_Main:				; DATA XREF: ROM:RPL_Indexo
		addq.b	#2,($FFFFF710).w
		bsr.w	RingPosLoad2
		lea	(v_rpl_data).w,a1
		move.w	(v_screenposx).w,d4
		subq.w	#8,d4
		bhi.s	loc_D896
		moveq	#1,d4
		bra.s	loc_D896
; ---------------------------------------------------------------------------

loc_D892:				; CODE XREF: ROM:0000D89Aj
		lea	6(a1),a1

loc_D896:				; CODE XREF: ROM:0000D88Cj
					; ROM:0000D890j
		cmp.w	2(a1),d4
		bhi.s	loc_D892
		move.w	a1,($FFFFF712).w
		move.w	a1,($FFFFF716).w
		addi.w	#$150,d4
		bra.s	loc_D8AE
; ---------------------------------------------------------------------------

loc_D8AA:				; CODE XREF: ROM:0000D8B2j
		lea	6(a1),a1

loc_D8AE:				; CODE XREF: ROM:0000D8A8j
		cmp.w	2(a1),d4
		bhi.s	loc_D8AA
		move.w	a1,($FFFFF714).w
		move.w	a1,($FFFFF718).w
		move.b	#1,($FFFFF711).w
		rts
; ---------------------------------------------------------------------------

RPL_Next:				; DATA XREF: ROM:0000D878o
		lea	(v_rpl_data).w,a1
		move.w	#$FF,d1

loc_D8CC:				; CODE XREF: ROM:0000D8EEj
		move.b	(a1),d0
		beq.s	loc_D8EA
		bmi.s	loc_D8EA
		subq.b	#1,(a1)
		bne.s	loc_D8EA
		move.b	#6,(a1)
		addq.b	#1,1(a1)
		cmpi.b	#8,1(a1)
		bne.s	loc_D8EA
		move.w	#-1,(a1)

loc_D8EA:				; CODE XREF: ROM:0000D8CEj
					; ROM:0000D8D0j ...
		lea	6(a1),a1
		dbf	d1,loc_D8CC
		movea.w	($FFFFF712).w,a1
		move.w	(v_screenposx).w,d4
		subq.w	#8,d4
		bhi.s	loc_D906
		moveq	#1,d4
		bra.s	loc_D906
; ---------------------------------------------------------------------------

loc_D902:				; CODE XREF: ROM:0000D90Aj
		lea	6(a1),a1

loc_D906:				; CODE XREF: ROM:0000D8FCj
					; ROM:0000D900j
		cmp.w	2(a1),d4
		bhi.s	loc_D902
		bra.s	loc_D910
; ---------------------------------------------------------------------------

loc_D90E:				; CODE XREF: ROM:0000D914j
		subq.w	#6,a1

loc_D910:				; CODE XREF: ROM:0000D90Cj
		cmp.w	-4(a1),d4
		bls.s	loc_D90E
		move.w	a1,($FFFFF712).w
		movea.w	($FFFFF714).w,a2
		addi.w	#$150,d4
		bra.s	loc_D928
; ---------------------------------------------------------------------------

loc_D924:				; CODE XREF: ROM:0000D92Cj
		lea	6(a2),a2

loc_D928:				; CODE XREF: ROM:0000D922j
		cmp.w	2(a2),d4
		bhi.s	loc_D924
		bra.s	loc_D932
; ---------------------------------------------------------------------------

loc_D930:				; CODE XREF: ROM:0000D936j
		subq.w	#6,a2

loc_D932:				; CODE XREF: ROM:0000D92Ej
		cmp.w	-4(a2),d4
		bls.s	loc_D930
		move.w	a2,($FFFFF714).w
		tst.w	(f_2player).w
		bne.s	loc_D94C
		move.w	a1,($FFFFF716).w
		move.w	a2,($FFFFF718).w
		rts
; ---------------------------------------------------------------------------

loc_D94C:				; CODE XREF: ROM:0000D940j
		movea.w	($FFFFF716).w,a1
		move.w	(v_screenposx_2p).w,d4
		subq.w	#8,d4
		bhi.s	loc_D960
		moveq	#1,d4
		bra.s	loc_D960
; ---------------------------------------------------------------------------

loc_D95C:				; CODE XREF: ROM:0000D964j
		lea	6(a1),a1

loc_D960:				; CODE XREF: ROM:0000D956j
					; ROM:0000D95Aj
		cmp.w	2(a1),d4
		bhi.s	loc_D95C
		bra.s	loc_D96A
; ---------------------------------------------------------------------------

loc_D968:				; CODE XREF: ROM:0000D96Ej
		subq.w	#6,a1

loc_D96A:				; CODE XREF: ROM:0000D966j
		cmp.w	-4(a1),d4
		bls.s	loc_D968
		move.w	a1,($FFFFF716).w
		movea.w	($FFFFF718).w,a2
		addi.w	#$150,d4
		bra.s	loc_D982
; ---------------------------------------------------------------------------

loc_D97E:				; CODE XREF: ROM:0000D986j
		lea	6(a2),a2

loc_D982:				; CODE XREF: ROM:0000D97Cj
		cmp.w	2(a2),d4
		bhi.s	loc_D97E
		bra.s	loc_D98C
; ---------------------------------------------------------------------------

loc_D98A:				; CODE XREF: ROM:0000D990j
		subq.w	#6,a2

loc_D98C:				; CODE XREF: ROM:0000D988j
		cmp.w	-4(a2),d4
		bls.s	loc_D98A
		move.w	a2,($FFFFF718).w
		rts

; =============== S U B	R O U T	I N E =======================================


sub_D998:				; CODE XREF: ROM:loc_19B7Aj
		movea.w	($FFFFF712).w,a1
		movea.w	($FFFFF714).w,a2
		cmpa.w	#$B000,a0
		beq.s	loc_D9AE
		movea.w	($FFFFF716).w,a1
		movea.w	($FFFFF718).w,a2

loc_D9AE:				; CODE XREF: sub_D998+Cj
		cmpa.l	a1,a2
		beq.w	locret_DA36
		cmpi.w	#$5A,$30(a0) 
		bcc.s	locret_DA36
		move.w	8(a0),d2
		move.w	$C(a0),d3
		subi.w	#8,d2
		moveq	#0,d5
		move.b	$16(a0),d5
		subq.b	#3,d5
		sub.w	d5,d3
		cmpi.b	#$39,$1A(a0) 
		bne.s	loc_D9E0
		addi.w	#$C,d3
		moveq	#$A,d5

loc_D9E0:				; CODE XREF: sub_D998+40j
		move.w	#6,d1
		move.w	#$C,d6
		move.w	#$10,d4
		add.w	d5,d5

loc_D9EE:				; CODE XREF: sub_D998+9Aj
		tst.w	(a1)
		bne.w	loc_DA2C
		move.w	2(a1),d0
		sub.w	d1,d0
		sub.w	d2,d0
		bcc.s	loc_DA06
		add.w	d6,d0
		bcs.s	loc_DA0C
		bra.w	loc_DA2C
; ---------------------------------------------------------------------------

loc_DA06:				; CODE XREF: sub_D998+64j
		cmp.w	d4,d0
		bhi.w	loc_DA2C

loc_DA0C:				; CODE XREF: sub_D998+68j
		move.w	4(a1),d0
		sub.w	d1,d0
		sub.w	d3,d0
		bcc.s	loc_DA1E
		add.w	d6,d0
		bcs.s	loc_DA24
		bra.w	loc_DA2C
; ---------------------------------------------------------------------------

loc_DA1E:				; CODE XREF: sub_D998+7Cj
		cmp.w	d5,d0
		bhi.w	loc_DA2C

loc_DA24:				; CODE XREF: sub_D998+80j
		move.w	#$604,(a1)
		bsr.w	sub_A8DE

loc_DA2C:				; CODE XREF: sub_D998+58j sub_D998+6Aj ...
		lea	6(a1),a1
		cmpa.l	a1,a2
		bne.w	loc_D9EE

locret_DA36:				; CODE XREF: sub_D998+18j sub_D998+22j
		rts
; End of function sub_D998


; =============== S U B	R O U T	I N E =======================================


BuildSprites2:				; CODE XREF: BuildSprites+16p
		movea.w	($FFFFF712).w,a0
		movea.w	($FFFFF714).w,a4
		cmpa.l	a0,a4
		bne.s	loc_DA46
		rts
; ---------------------------------------------------------------------------

loc_DA46:				; CODE XREF: BuildSprites2+Aj
		lea	(v_screenposx).w,a3

loc_DA4A:				; CODE XREF: BuildSprites2+76j
		tst.w	(a0)
		bmi.w	loc_DAA8
		move.w	2(a0),d3
		sub.w	(a3),d3
		addi.w	#$80,d3
		move.w	4(a0),d2
		sub.w	4(a3),d2
		addi.w	#8,d2
		bmi.s	loc_DAA8
		cmpi.w	#$F0,d2	; "?"
		bge.s	loc_DAA8
		addi.w	#$78,d2	
		lea	(off_DC04).l,a1
		moveq	#0,d1
		move.b	1(a0),d1
		bne.s	loc_DA84
		move.b	($FFFFFEC3).w,d1

loc_DA84:				; CODE XREF: BuildSprites2+46j
		add.w	d1,d1
		adda.w	(a1,d1.w),a1
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.w	(a1)+,d0
		addi.w	#$26BC,d0
		move.w	d0,(a2)+
		addq.w	#2,a1
		move.w	(a1)+,d0
		add.w	d3,d0
		move.w	d0,(a2)+

loc_DAA8:				; CODE XREF: BuildSprites2+14j
					; BuildSprites2+2Ej ...
		lea	6(a0),a0
		cmpa.l	a0,a4
		bne.w	loc_DA4A
		rts
; End of function BuildSprites2


; =============== S U B	R O U T	I N E =======================================


BuildSprites2_2p:			; CODE XREF: BuildSprites+322p
		lea	(v_screenposx).w,a3
		move.w	#$78,d6	
		movea.w	($FFFFF712).w,a0
		movea.w	($FFFFF714).w,a4
		cmpa.l	a0,a4
		bne.s	loc_DAE0
		rts
; End of function BuildSprites2_2p


; =============== S U B	R O U T	I N E =======================================


sub_DACA:				; CODE XREF: BuildSprites+444p
		lea	(v_screenposx_2p).w,a3
		move.w	#$158,d6
		movea.w	($FFFFF716).w,a0
		movea.w	($FFFFF718).w,a4
		cmpa.l	a0,a4
		bne.s	loc_DAE0
		rts
; ---------------------------------------------------------------------------

loc_DAE0:				; CODE XREF: BuildSprites2_2p+12j
					; sub_DACA+12j	...
		tst.w	(a0)
		bmi.w	loc_DB40
		move.w	2(a0),d3
		sub.w	(a3),d3
		addi.w	#$80,d3
		move.w	4(a0),d2
		sub.w	4(a3),d2
		addi.w	#$88,d2	; "?"
		bmi.s	loc_DB40
		cmpi.w	#$170,d2
		bge.s	loc_DB40
		add.w	d6,d2
		lea	(off_DC04).l,a1
		moveq	#0,d1
		move.b	1(a0),d1
		bne.s	loc_DB18
		move.b	($FFFFFEC3).w,d1

loc_DB18:				; CODE XREF: sub_DACA+48j
		add.w	d1,d1
		adda.w	(a1,d1.w),a1
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4
		move.b	byte_DB4C(pc,d4.w),(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		addq.w	#2,a1
		move.w	(a1)+,d0
		addi.w	#$235E,d0
		move.w	d0,(a2)+
		move.w	(a1)+,d0
		add.w	d3,d0
		move.w	d0,(a2)+

loc_DB40:				; CODE XREF: sub_DACA+18j sub_DACA+32j ...
		lea	6(a0),a0
		cmpa.l	a0,a4
		bne.w	loc_DAE0
		rts
; End of function sub_DACA

; ---------------------------------------------------------------------------
byte_DB4C:	dc.b   0,  0,  1,  1	; 0
		dc.b   4,  4,  5,  5	; 4
		dc.b   8,  8,  9,  9	; 8
		dc.b  $C, $C, $D, $D	; 12

; =============== S U B	R O U T	I N E =======================================


RingPosLoad2:				; CODE XREF: ROM:0000D87Ep
		lea	(v_rpl_data).w,a1
		moveq	#0,d0
		move.w	#$17F,d1

loc_DB66:				; CODE XREF: RingPosLoad2+Cj
		move.l	d0,(a1)+
		dbf	d1,loc_DB66
		moveq	#0,d0
		move.w	(v_zone).w,d0
		lsl.b	#6,d0
		lsr.w	#5,d0
		lea	(RingPos_Index).l,a1
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		lea	(v_rpl_data+6).w,a2

loc_DB88:				; CODE XREF: RingPosLoad2+50j
					; RingPosLoad2+6Ej
		move.w	(a1)+,d2
		bmi.s	loc_DBCC
		move.w	(a1)+,d3
		bmi.s	loc_DBAE
		move.w	d3,d0
		rol.w	#4,d0
		andi.w	#7,d0
		andi.w	#$FFF,d3

loc_DB9C:				; CODE XREF: RingPosLoad2+4Cj
		move.w	#0,(a2)+
		move.w	d2,(a2)+
		move.w	d3,(a2)+
		addi.w	#$18,d2
		dbf	d0,loc_DB9C
		bra.s	loc_DB88
; ---------------------------------------------------------------------------

loc_DBAE:				; CODE XREF: RingPosLoad2+32j
		move.w	d3,d0
		rol.w	#4,d0
		andi.w	#7,d0
		andi.w	#$FFF,d3

loc_DBBA:				; CODE XREF: RingPosLoad2+6Aj
		move.w	#0,(a2)+
		move.w	d2,(a2)+
		move.w	d3,(a2)+
		addi.w	#$18,d3
		dbf	d0,loc_DBBA
		bra.s	loc_DB88
; ---------------------------------------------------------------------------

loc_DBCC:				; CODE XREF: RingPosLoad2+2Ej
		moveq	#$FFFFFFFF,d0
		move.l	d0,(a2)+
		lea	(v_rpl_data+2).w,a1
		move.w	#$FE,d3	; "?"

loc_DBD8:				; CODE XREF: RingPosLoad2+A2j
		move.w	d3,d4
		lea	6(a1),a2
		move.w	(a1),d0

loc_DBE0:				; CODE XREF: RingPosLoad2+9Aj
		tst.w	(a2)
		beq.s	loc_DBF2
		cmp.w	(a2),d0
		bls.s	loc_DBF2
		move.l	(a1),d1
		move.l	(a2),d0
		move.l	d0,(a1)
		move.l	d1,(a2)
		swap	d0

loc_DBF2:				; CODE XREF: RingPosLoad2+86j
					; RingPosLoad2+8Aj
		lea	6(a2),a2
		dbf	d4,loc_DBE0
		lea	6(a1),a1
		dbf	d3,loc_DBD8
		rts
; End of function RingPosLoad2

; ---------------------------------------------------------------------------
off_DC04:	dc.w word_DC14-off_DC04	; DATA XREF: BuildSprites2+3Ao
					; sub_DACA+3Co	...
		dc.w word_DC1C-off_DC04
		dc.w word_DC24-off_DC04
		dc.w word_DC2C-off_DC04
		dc.w word_DC34-off_DC04
		dc.w word_DC3C-off_DC04
		dc.w word_DC44-off_DC04
		dc.w word_DC4C-off_DC04
word_DC14:	dc.w $F805,    0,    0,$FFF8; 0	; DATA XREF: ROM:off_DC04o
word_DC1C:	dc.w $F805,    4,    2,$FFF8; 0	; DATA XREF: ROM:0000DC06o
word_DC24:	dc.w $F801,    8,    4,$FFFC; 0	; DATA XREF: ROM:0000DC08o
word_DC2C:	dc.w $F805, $804, $802,$FFF8; 0	; DATA XREF: ROM:0000DC0Ao
word_DC34:	dc.w $F805,   $A,    5,$FFF8; 0	; DATA XREF: ROM:0000DC0Co
word_DC3C:	dc.w $F805,$180A,$1805,$FFF8; 0	; DATA XREF: ROM:0000DC0Eo
word_DC44:	dc.w $F805, $80A, $805,$FFF8; 0	; DATA XREF: ROM:0000DC10o
word_DC4C:	dc.w $F805,$100A,$1005,$FFF8; 0	; DATA XREF: ROM:0000DC12o

; =============== S U B	R O U T	I N E =======================================


ObjPosLoad:
		moveq	#0,d0
		move.b	($FFFFF76C).w,d0
		move.w	OPL_Index(pc,d0.w),d0
		jmp	OPL_Index(pc,d0.w)
; End of function ObjPosLoad

; ---------------------------------------------------------------------------
OPL_Index:	dc.w loc_DC68-OPL_Index
		dc.w loc_DD14-OPL_Index
		dc.w loc_DE5C-OPL_Index
; ---------------------------------------------------------------------------

loc_DC68:				; DATA XREF: ROM:OPL_Indexo
		addq.b	#2,($FFFFF76C).w
		move.w	(v_zone).w,d0
		lsl.b	#6,d0
		lsr.w	#4,d0
		lea	(ObjPos_Index).l,a0
		movea.l	a0,a1
		adda.w	(a0,d0.w),a0
		move.l	a0,($FFFFF770).w
		move.l	a0,($FFFFF774).w
		move.l	a0,($FFFFF778).w
		move.l	a0,($FFFFF77C).w
		lea	($FFFFFC00).w,a2
		move.w	#$101,(a2)+
		move.w	#$5E,d0

loc_DC9C:				; CODE XREF: ROM:0000DC9Ej
		clr.l	(a2)+
		dbf	d0,loc_DC9C
		lea	($FFFFFC00).w,a2
		moveq	#0,d2
		move.w	(v_screenposx).w,d6
		subi.w	#$80,d6	
		bcc.s	loc_DCB4
		moveq	#0,d6

loc_DCB4:				; CODE XREF: ROM:0000DCB0j
		andi.w	#$FF80,d6
		movea.l	($FFFFF770).w,a0

loc_DCBC:				; CODE XREF: ROM:0000DCCCj
		cmp.w	(a0),d6
		bls.s	loc_DCCE
		tst.b	4(a0)
		bpl.s	loc_DCCA
		move.b	(a2),d2
		addq.b	#1,(a2)

loc_DCCA:				; CODE XREF: ROM:0000DCC4j
		addq.w	#6,a0
		bra.s	loc_DCBC
; ---------------------------------------------------------------------------

loc_DCCE:				; CODE XREF: ROM:0000DCBEj
		move.l	a0,($FFFFF770).w
		move.l	a0,($FFFFF778).w
		movea.l	($FFFFF774).w,a0
		subi.w	#$80,d6	
		bcs.s	loc_DCF2

loc_DCE0:				; CODE XREF: ROM:0000DCF0j
		cmp.w	(a0),d6
		bls.s	loc_DCF2
		tst.b	4(a0)
		bpl.s	loc_DCEE
		addq.b	#1,1(a2)

loc_DCEE:				; CODE XREF: ROM:0000DCE8j
		addq.w	#6,a0
		bra.s	loc_DCE0
; ---------------------------------------------------------------------------

loc_DCF2:				; CODE XREF: ROM:0000DCDEj
					; ROM:0000DCE2j
		move.l	a0,($FFFFF774).w
		move.l	a0,($FFFFF77C).w
		move.w	#$FFFF,($FFFFF76E).w
		move.w	#$FFFF,($FFFFF78C).w
		tst.w	(f_2player).w
		beq.s	loc_DD14
		addq.b	#2,($FFFFF76C).w
		bra.w	loc_DDE0
; ---------------------------------------------------------------------------

loc_DD14:				; CODE XREF: ROM:0000DD0Aj
					; DATA XREF: ROM:0000DC64o
		move.w	(v_screenposx).w,d1
		subi.w	#$80,d1	
		andi.w	#$FF80,d1
		move.w	d1,($FFFFF7DA).w
		lea	($FFFFFC00).w,a2
		moveq	#0,d2
		move.w	(v_screenposx).w,d6
		andi.w	#$FF80,d6
		cmp.w	($FFFFF76E).w,d6
		beq.w	locret_DDDE
		bge.s	loc_DD9A
		move.w	d6,($FFFFF76E).w
		movea.l	($FFFFF774).w,a0
		subi.w	#$80,d6	
		bcs.s	loc_DD76

loc_DD4A:				; CODE XREF: ROM:0000DD68j
		cmp.w	-6(a0),d6
		bge.s	loc_DD76
		subq.w	#6,a0
		tst.b	4(a0)
		bpl.s	loc_DD60
		subq.b	#1,1(a2)
		move.b	1(a2),d2

loc_DD60:				; CODE XREF: ROM:0000DD56j
		bsr.w	sub_E0D2
		bne.s	loc_DD6A
		subq.w	#6,a0
		bra.s	loc_DD4A
; ---------------------------------------------------------------------------

loc_DD6A:				; CODE XREF: ROM:0000DD64j
		tst.b	4(a0)
		bpl.s	loc_DD74
		addq.b	#1,1(a2)

loc_DD74:				; CODE XREF: ROM:0000DD6Ej
		addq.w	#6,a0

loc_DD76:				; CODE XREF: ROM:0000DD48j
					; ROM:0000DD4Ej
		move.l	a0,($FFFFF774).w
		movea.l	($FFFFF770).w,a0
		addi.w	#$300,d6

loc_DD82:				; CODE XREF: ROM:0000DD92j
		cmp.w	-6(a0),d6
		bgt.s	loc_DD94
		tst.b	-2(a0)
		bpl.s	loc_DD90
		subq.b	#1,(a2)

loc_DD90:				; CODE XREF: ROM:0000DD8Cj
		subq.w	#6,a0
		bra.s	loc_DD82
; ---------------------------------------------------------------------------

loc_DD94:				; CODE XREF: ROM:0000DD86j
		move.l	a0,($FFFFF770).w
		rts
; ---------------------------------------------------------------------------

loc_DD9A:				; CODE XREF: ROM:0000DD3Aj
		move.w	d6,($FFFFF76E).w
		movea.l	($FFFFF770).w,a0
		addi.w	#$280,d6

loc_DDA6:				; CODE XREF: ROM:0000DDB8j
		cmp.w	(a0),d6
		bls.s	loc_DDBA
		tst.b	4(a0)
		bpl.s	loc_DDB4
		move.b	(a2),d2
		addq.b	#1,(a2)

loc_DDB4:				; CODE XREF: ROM:0000DDAEj
		bsr.w	sub_E0D2
		beq.s	loc_DDA6

loc_DDBA:				; CODE XREF: ROM:0000DDA8j
		move.l	a0,($FFFFF770).w
		movea.l	($FFFFF774).w,a0
		subi.w	#$300,d6
		bcs.s	loc_DDDA

loc_DDC8:				; CODE XREF: ROM:0000DDD8j
		cmp.w	(a0),d6
		bls.s	loc_DDDA
		tst.b	4(a0)
		bpl.s	loc_DDD6
		addq.b	#1,1(a2)

loc_DDD6:				; CODE XREF: ROM:0000DDD0j
		addq.w	#6,a0
		bra.s	loc_DDC8
; ---------------------------------------------------------------------------

loc_DDDA:				; CODE XREF: ROM:0000DDC6j
					; ROM:0000DDCAj
		move.l	a0,($FFFFF774).w
; START	OF FUNCTION CHUNK FOR sub_DED2

locret_DDDE:				; CODE XREF: ROM:0000DD36j sub_DED2+8j
		rts
; END OF FUNCTION CHUNK	FOR sub_DED2
; ---------------------------------------------------------------------------

loc_DDE0:				; CODE XREF: ROM:0000DD10j
		moveq	#$FFFFFFFF,d0
		move.l	d0,($FFFFF780).w
		move.l	d0,($FFFFF784).w
		move.l	d0,($FFFFF788).w
		move.l	d0,($FFFFF78C).w
		move.w	#0,($FFFFF76E).w
		move.w	#0,($FFFFF78C).w
		lea	($FFFFFC00).w,a2
		move.w	(a2),($FFFFF78E).w
		moveq	#0,d2
		lea	($FFFFFC00).w,a5
		lea	($FFFFF770).w,a4
		lea	($FFFFF786).w,a1
		lea	($FFFFF789).w,a6
		moveq	#$FFFFFFFE,d6
		bsr.w	sub_DF80
		lea	($FFFFF786).w,a1
		moveq	#$FFFFFFFF,d6
		bsr.w	sub_DF80
		lea	($FFFFF786).w,a1
		moveq	#0,d6
		bsr.w	sub_DF80
		lea	($FFFFF78E).w,a5
		lea	($FFFFF778).w,a4
		lea	($FFFFF789).w,a1
		lea	($FFFFF786).w,a6
		moveq	#$FFFFFFFE,d6
		bsr.w	sub_DF80
		lea	($FFFFF789).w,a1
		moveq	#$FFFFFFFF,d6
		bsr.w	sub_DF80
		lea	($FFFFF789).w,a1
		moveq	#0,d6
		bsr.w	sub_DF80

loc_DE5C:				; DATA XREF: ROM:0000DC66o
		move.w	(v_screenposx).w,d1
		andi.w	#$FF00,d1
		move.w	d1,($FFFFF7DA).w
		move.w	(v_screenposx_2p).w,d1
		andi.w	#$FF00,d1
		move.w	d1,($FFFFF7DC).w
		move.b	(v_screenposx).w,d6
		andi.w	#$FF,d6
		move.w	($FFFFF76E).w,d0
		cmp.w	($FFFFF76E).w,d6
		beq.s	loc_DE9C
		move.w	d6,($FFFFF76E).w
		lea	($FFFFFC00).w,a5
		lea	($FFFFF770).w,a4
		lea	($FFFFF786).w,a1
		lea	($FFFFF789).w,a6
		bsr.s	sub_DED2

loc_DE9C:				; CODE XREF: ROM:0000DE84j
		move.b	(v_screenposx_2p).w,d6
		andi.w	#$FF,d6
		move.w	($FFFFF78C).w,d0
		cmp.w	($FFFFF78C).w,d6
		beq.s	loc_DEC4
		move.w	d6,($FFFFF78C).w
		lea	($FFFFF78E).w,a5
		lea	($FFFFF778).w,a4
		lea	($FFFFF789).w,a1
		lea	($FFFFF786).w,a6
		bsr.s	sub_DED2

loc_DEC4:				; CODE XREF: ROM:0000DEACj
		move.w	($FFFFFC00).w,($FFFFFFEC).w
		move.w	($FFFFF78E).w,($FFFFFFEE).w
		rts

; =============== S U B	R O U T	I N E =======================================


sub_DED2:				; CODE XREF: ROM:0000DE9Ap
					; ROM:0000DEC2p

; FUNCTION CHUNK AT 0000DDDE SIZE 00000002 BYTES

		lea	($FFFFFC00).w,a2
		moveq	#0,d2
		cmp.w	d0,d6
		beq.w	locret_DDDE
		bge.w	sub_DF80
		move.b	2(a1),d2
		move.b	1(a1),2(a1)
		move.b	(a1),1(a1)
		move.b	d6,(a1)
		cmp.b	(a6),d2
		beq.s	loc_DF08
		cmp.b	1(a6),d2
		beq.s	loc_DF08
		cmp.b	2(a6),d2
		beq.s	loc_DF08
		bsr.w	sub_E062
		bra.s	loc_DF0C
; ---------------------------------------------------------------------------

loc_DF08:				; CODE XREF: sub_DED2+22j sub_DED2+28j ...
		bsr.w	sub_E026

loc_DF0C:				; CODE XREF: sub_DED2+34j
		bsr.w	sub_E002
		bne.s	loc_DF30
		movea.l	4(a4),a0

loc_DF16:				; CODE XREF: sub_DED2+56j
		cmp.b	-6(a0),d6
		bne.s	loc_DF2A
		tst.b	-2(a0)
		bpl.s	loc_DF26
		subq.b	#1,1(a5)

loc_DF26:				; CODE XREF: sub_DED2+4Ej
		subq.w	#6,a0
		bra.s	loc_DF16
; ---------------------------------------------------------------------------

loc_DF2A:				; CODE XREF: sub_DED2+48j
		move.l	a0,4(a4)
		bra.s	loc_DF66
; ---------------------------------------------------------------------------

loc_DF30:				; CODE XREF: sub_DED2+3Ej
		movea.l	4(a4),a0
		move.b	d6,(a1)

loc_DF36:				; CODE XREF: sub_DED2+82j
		cmp.b	-6(a0),d6
		bne.s	loc_DF62
		subq.w	#6,a0
		tst.b	4(a0)
		bpl.s	loc_DF4C
		subq.b	#1,1(a5)
		move.b	1(a5),d2

loc_DF4C:				; CODE XREF: sub_DED2+70j
		bsr.w	sub_E122
		bne.s	loc_DF56
		subq.w	#6,a0
		bra.s	loc_DF36
; ---------------------------------------------------------------------------

loc_DF56:				; CODE XREF: sub_DED2+7Ej
		tst.b	4(a0)
		bpl.s	loc_DF60
		addq.b	#1,1(a5)

loc_DF60:				; CODE XREF: sub_DED2+88j
		addq.w	#6,a0

loc_DF62:				; CODE XREF: sub_DED2+68j
		move.l	a0,4(a4)

loc_DF66:				; CODE XREF: sub_DED2+5Cj
		movea.l	(a4),a0
		addq.w	#3,d6

loc_DF6A:				; CODE XREF: sub_DED2+A8j
		cmp.b	-6(a0),d6
		bne.s	loc_DF7C
		tst.b	-2(a0)
		bpl.s	loc_DF78
		subq.b	#1,(a5)

loc_DF78:				; CODE XREF: sub_DED2+A2j
		subq.w	#6,a0
		bra.s	loc_DF6A
; ---------------------------------------------------------------------------

loc_DF7C:				; CODE XREF: sub_DED2+9Cj
		move.l	a0,(a4)
		rts
; End of function sub_DED2


; =============== S U B	R O U T	I N E =======================================


sub_DF80:				; CODE XREF: ROM:0000DE1Ap
					; ROM:0000DE24p ...
		addq.w	#2,d6
		move.b	(a1),d2
		move.b	1(a1),(a1)
		move.b	2(a1),1(a1)
		move.b	d6,2(a1)
		cmp.b	(a6),d2
		beq.s	loc_DFA8
		cmp.b	1(a6),d2
		beq.s	loc_DFA8
		cmp.b	2(a6),d2
		beq.s	loc_DFA8
		bsr.w	sub_E062
		bra.s	loc_DFAC
; ---------------------------------------------------------------------------

loc_DFA8:				; CODE XREF: sub_DF80+14j sub_DF80+1Aj ...
		bsr.w	sub_E026

loc_DFAC:				; CODE XREF: sub_DF80+26j
		bsr.w	sub_E002
		bne.s	loc_DFC8
		movea.l	(a4),a0

loc_DFB4:				; CODE XREF: sub_DF80+42j
		cmp.b	(a0),d6
		bne.s	loc_DFC4
		tst.b	4(a0)
		bpl.s	loc_DFC0
		addq.b	#1,(a5)

loc_DFC0:				; CODE XREF: sub_DF80+3Cj
		addq.w	#6,a0
		bra.s	loc_DFB4
; ---------------------------------------------------------------------------

loc_DFC4:				; CODE XREF: sub_DF80+36j
		move.l	a0,(a4)
		bra.s	loc_DFE2
; ---------------------------------------------------------------------------

loc_DFC8:				; CODE XREF: sub_DF80+30j
		movea.l	(a4),a0
		move.b	d6,(a1)

loc_DFCC:				; CODE XREF: sub_DF80+5Ej
		cmp.b	(a0),d6
		bne.s	loc_DFE0
		tst.b	4(a0)
		bpl.s	loc_DFDA
		move.b	(a5),d2
		addq.b	#1,(a5)

loc_DFDA:				; CODE XREF: sub_DF80+54j
		bsr.w	sub_E122
		beq.s	loc_DFCC

loc_DFE0:				; CODE XREF: sub_DF80+4Ej
		move.l	a0,(a4)

loc_DFE2:				; CODE XREF: sub_DF80+46j
		movea.l	4(a4),a0
		subq.w	#3,d6
		bcs.s	loc_DFFC

loc_DFEA:				; CODE XREF: sub_DF80+7Aj
		cmp.b	(a0),d6
		bne.s	loc_DFFC
		tst.b	4(a0)
		bpl.s	loc_DFF8
		addq.b	#1,1(a5)

loc_DFF8:				; CODE XREF: sub_DF80+72j
		addq.w	#6,a0
		bra.s	loc_DFEA
; ---------------------------------------------------------------------------

loc_DFFC:				; CODE XREF: sub_DF80+68j sub_DF80+6Cj
		move.l	a0,4(a4)
		rts
; End of function sub_DF80


; =============== S U B	R O U T	I N E =======================================


sub_E002:				; CODE XREF: sub_DED2:loc_DF0Cp
					; sub_DF80:loc_DFACp
		move.l	a1,-(sp)
		lea	($FFFFF780).w,a1
		cmp.b	(a1)+,d6
		beq.s	loc_E022
		cmp.b	(a1)+,d6
		beq.s	loc_E022
		cmp.b	(a1)+,d6
		beq.s	loc_E022
		cmp.b	(a1)+,d6
		beq.s	loc_E022
		cmp.b	(a1)+,d6
		beq.s	loc_E022
		cmp.b	(a1)+,d6
		beq.s	loc_E022
		moveq	#1,d0

loc_E022:				; CODE XREF: sub_E002+8j sub_E002+Cj ...
		movea.l	(sp)+,a1
		rts
; End of function sub_E002


; =============== S U B	R O U T	I N E =======================================


sub_E026:				; CODE XREF: sub_DED2:loc_DF08p
					; sub_DF80:loc_DFA8p
		lea	($FFFFF780).w,a1
		lea	(v_objspace+$E00).w,a3
		tst.b	(a1)+
		bmi.s	loc_E05E
		lea	($FFFFC100).w,a3
		tst.b	(a1)+
		bmi.s	loc_E05E
		lea	($FFFFC400).w,a3
		tst.b	(a1)+
		bmi.s	loc_E05E
		lea	($FFFFC700).w,a3
		tst.b	(a1)+
		bmi.s	loc_E05E
		lea	($FFFFCA00).w,a3
		tst.b	(a1)+
		bmi.s	loc_E05E
		lea	($FFFFCD00).w,a3
		tst.b	(a1)+
		bmi.s	loc_E05E
		nop
		nop

loc_E05E:				; CODE XREF: sub_E026+Aj sub_E026+12j	...
		subq.w	#1,a1
		rts
; End of function sub_E026


; =============== S U B	R O U T	I N E =======================================


sub_E062:				; CODE XREF: sub_DED2+30p sub_DF80+22p
		lea	($FFFFF780).w,a1
		lea	(v_objspace+$E00).w,a3
		cmp.b	(a1)+,d2
		beq.s	loc_E09A
		lea	($FFFFC100).w,a3
		cmp.b	(a1)+,d2
		beq.s	loc_E09A
		lea	($FFFFC400).w,a3
		cmp.b	(a1)+,d2
		beq.s	loc_E09A
		lea	($FFFFC700).w,a3
		cmp.b	(a1)+,d2
		beq.s	loc_E09A
		lea	($FFFFCA00).w,a3
		cmp.b	(a1)+,d2
		beq.s	loc_E09A
		lea	($FFFFCD00).w,a3
		cmp.b	(a1)+,d2
		beq.s	loc_E09A
		nop
		nop

loc_E09A:				; CODE XREF: sub_E062+Aj sub_E062+12j	...
		move.b	#$FF,-(a1)
		movem.l	a1/a3,-(sp)
		moveq	#0,d1
		moveq	#$B,d2

loc_E0A6:				; CODE XREF: sub_E062+64j
		tst.b	(a3)
		beq.s	loc_E0C2
		movea.l	a3,a1
		moveq	#0,d0
		move.b	$23(a1),d0
		beq.s	loc_E0BA
		bclr	#7,2(a2,d0.w)

loc_E0BA:				; CODE XREF: sub_E062+50j
		moveq	#$F,d0

loc_E0BC:				; CODE XREF: sub_E062+5Cj
		move.l	d1,(a1)+
		dbf	d0,loc_E0BC

loc_E0C2:				; CODE XREF: sub_E062+46j
		lea	$40(a3),a3
		dbf	d2,loc_E0A6
		moveq	#0,d2
		movem.l	(sp)+,a1/a3
		rts
; End of function sub_E062


; =============== S U B	R O U T	I N E =======================================


sub_E0D2:				; CODE XREF: ROM:loc_DD60p
					; ROM:loc_DDB4p
		tst.b	4(a0)
		bpl.s	loc_E0E6
		bset	#7,2(a2,d2.w)
		beq.s	loc_E0E6
		addq.w	#6,a0
		moveq	#0,d0
		rts
; ---------------------------------------------------------------------------

loc_E0E6:				; CODE XREF: sub_E0D2+4j sub_E0D2+Cj
		bsr.w	SingleObjectLoad
		bne.s	locret_E120
		move.w	(a0)+,8(a1)
		move.w	(a0)+,d0
		move.w	d0,d1
		andi.w	#$FFF,d0
		move.w	d0,$C(a1)
		rol.w	#2,d1
		andi.b	#3,d1
		move.b	d1,1(a1)
		move.b	d1,$22(a1)
		move.b	(a0)+,d0
		bpl.s	loc_E116
		andi.b	#$7F,d0	
		move.b	d2,$23(a1)

loc_E116:				; CODE XREF: sub_E0D2+3Aj
		move.b	d0,0(a1)
		move.b	(a0)+,$28(a1)
		moveq	#0,d0

locret_E120:				; CODE XREF: sub_E0D2+18j
		rts
; End of function sub_E0D2


; =============== S U B	R O U T	I N E =======================================


sub_E122:				; CODE XREF: sub_DED2:loc_DF4Cp
					; sub_DF80:loc_DFDAp
		tst.b	4(a0)
		bpl.s	loc_E136
		bset	#7,2(a2,d2.w)
		beq.s	loc_E136
		addq.w	#6,a0
		moveq	#0,d0
		rts
; ---------------------------------------------------------------------------

loc_E136:				; CODE XREF: sub_E122+4j sub_E122+Cj
		btst	#5,2(a0)
		beq.s	loc_E146
		bsr.w	SingleObjectLoad
		bne.s	locret_E180
		bra.s	loc_E14C
; ---------------------------------------------------------------------------

loc_E146:				; CODE XREF: sub_E122+1Aj
		bsr.w	sub_E1B4
		bne.s	locret_E180

loc_E14C:				; CODE XREF: sub_E122+22j
		move.w	(a0)+,8(a1)
		move.w	(a0)+,d0
		move.w	d0,d1
		andi.w	#$FFF,d0
		move.w	d0,$C(a1)
		rol.w	#2,d1
		andi.b	#3,d1
		move.b	d1,1(a1)
		move.b	d1,$22(a1)
		move.b	(a0)+,d0
		bpl.s	loc_E176
		andi.b	#$7F,d0	
		move.b	d2,$23(a1)

loc_E176:				; CODE XREF: sub_E122+4Aj
		move.b	d0,0(a1)
		move.b	(a0)+,$28(a1)
		moveq	#0,d0

locret_E180:				; CODE XREF: sub_E122+20j sub_E122+28j
		rts
; End of function sub_E122


; =============== S U B	R O U T	I N E =======================================


SingleObjectLoad:			; CODE XREF: ROM:0000767Ap
					; ROM:00007700p ...
		lea	(v_objspace+$800).w,a1
		move.w	#$5F,d0	

loc_E18A:				; CODE XREF: SingleObjectLoad+10j
		tst.b	(a1)
		beq.s	locret_E196
		lea	$40(a1),a1
		dbf	d0,loc_E18A

locret_E196:				; CODE XREF: SingleObjectLoad+Aj
		rts
; End of function SingleObjectLoad


; =============== S U B	R O U T	I N E =======================================


S1SingleObjectLoad2:			; CODE XREF: sub_7C76p	ROM:loc_82F0p ...
		movea.l	a0,a1
		move.w	#$D000,d0
		sub.w	a0,d0
		lsr.w	#6,d0
		subq.w	#1,d0
		bcs.s	locret_E1B2

loc_E1A6:				; CODE XREF: S1SingleObjectLoad2+16j
		tst.b	(a1)
		beq.s	locret_E1B2
		lea	$40(a1),a1
		dbf	d0,loc_E1A6

locret_E1B2:				; CODE XREF: S1SingleObjectLoad2+Cj
					; S1SingleObjectLoad2+10j
		rts
; End of function S1SingleObjectLoad2


; =============== S U B	R O U T	I N E =======================================


sub_E1B4:				; CODE XREF: sub_E122:loc_E146p
		movea.l	a3,a1
		move.w	#$B,d0

loc_E1BA:				; CODE XREF: sub_E1B4+Ej
		tst.b	(a1)
		beq.s	locret_E1C6
		lea	$40(a1),a1
		dbf	d0,loc_E1BA

locret_E1C6:				; CODE XREF: sub_E1B4+8j
		rts
; End of function sub_E1B4

; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 41 - springs
;----------------------------------------------------

Obj41:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj41_Index(pc,d0.w),d1
		jsr	Obj41_Index(pc,d1.w)
		tst.w	(f_2player).w
		beq.s	loc_E1E0
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_E1E0:				; CODE XREF: ROM:0000E1DAj
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Obj41_Index:	dc.w loc_E204-Obj41_Index ; DATA XREF: ROM:Obj41_Indexo
					; ROM:0000E1FAo ...
		dc.w loc_E302-Obj41_Index
		dc.w loc_E3F4-Obj41_Index
		dc.w loc_E606-Obj41_Index
		dc.w loc_E6F2-Obj41_Index
		dc.w loc_E828-Obj41_Index
; ---------------------------------------------------------------------------

loc_E204:				; DATA XREF: ROM:Obj41_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj41_GHZ,4(a0)
		move.w	#$4A8,2(a0)
		tst.b	(v_zone).w
		beq.s	loc_E22A
		move.l	#Map_Obj41,4(a0)
		move.w	#$45C,2(a0)

loc_E22A:				; CODE XREF: ROM:0000E21Aj
		ori.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#4,$18(a0)
		move.b	$28(a0),d0
		lsr.w	#3,d0
		andi.w	#$E,d0
		move.w	off_E24E(pc,d0.w),d0
		jmp	off_E24E(pc,d0.w)
; ---------------------------------------------------------------------------
off_E24E:	dc.w loc_E2D0-off_E24E	; DATA XREF: ROM:off_E24Eo
					; ROM:0000E250o ...
		dc.w loc_E258-off_E24E
		dc.w loc_E284-off_E24E
		dc.w loc_E298-off_E24E
		dc.w loc_E2B2-off_E24E
; ---------------------------------------------------------------------------

loc_E258:				; DATA XREF: ROM:0000E250o
		move.b	#4,$24(a0)
		move.b	#2,$1C(a0)
		move.b	#3,$1A(a0)
		move.w	#$4B8,2(a0)
		tst.b	(v_zone).w
		beq.s	loc_E27C
		move.w	#$470,2(a0)

loc_E27C:				; CODE XREF: ROM:0000E274j
		move.b	#8,$19(a0)
		bra.s	loc_E2D0
; ---------------------------------------------------------------------------

loc_E284:				; DATA XREF: ROM:0000E252o
		move.b	#6,$24(a0)
		move.b	#6,$1A(a0)
		bset	#1,$22(a0)
		bra.s	loc_E2D0
; ---------------------------------------------------------------------------

loc_E298:				; DATA XREF: ROM:0000E254o
		move.b	#8,$24(a0)
		move.b	#4,$1C(a0)
		move.b	#7,$1A(a0)
		move.w	#$43C,2(a0)
		bra.s	loc_E2D0
; ---------------------------------------------------------------------------

loc_E2B2:				; DATA XREF: ROM:0000E256o
		move.b	#$A,$24(a0)
		move.b	#4,$1C(a0)
		move.b	#$A,$1A(a0)
		move.w	#$43C,2(a0)
		bset	#1,$22(a0)

loc_E2D0:				; CODE XREF: ROM:0000E282j
					; ROM:0000E296j ...
		move.b	$28(a0),d0
		andi.w	#2,d0
		move.w	word_E2FE(pc,d0.w),$30(a0)
		btst	#1,d0
		beq.s	loc_E2F8
		bset	#5,2(a0)
		tst.b	(v_zone).w
		beq.s	loc_E2F8
		move.l	#Map_Obj41a,4(a0)

loc_E2F8:				; CODE XREF: ROM:0000E2E2j
					; ROM:0000E2EEj
		bsr.w	ModifySpriteAttr_2P
		rts
; ---------------------------------------------------------------------------
word_E2FE:	dc.w $F000
		dc.w $F600
; ---------------------------------------------------------------------------

loc_E302:				; DATA XREF: ROM:0000E1FAo
		move.w	#$1B,d1
		move.w	#8,d2
		move.w	#$10,d3
		move.w	8(a0),d4
		lea	(v_objspace).w,a1
		moveq	#3,d6
		movem.l	d1-d4,-(sp)
		bsr.w	loc_F4A8
		btst	#3,$22(a0)
		beq.s	loc_E32A
		bsr.s	sub_E34E

loc_E32A:				; CODE XREF: ROM:0000E326j
		movem.l	(sp)+,d1-d4
		lea	(v_objspace+$40).w,a1
		moveq	#4,d6
		bsr.w	loc_F4A8
		btst	#4,$22(a0)
		beq.s	loc_E342
		bsr.s	sub_E34E

loc_E342:				; CODE XREF: ROM:0000E33Ej
		lea	(Ani_Obj41).l,a1
		bra.w	AnimateSprite
; ---------------------------------------------------------------------------
		rts

; =============== S U B	R O U T	I N E =======================================


sub_E34E:				; CODE XREF: ROM:0000E328p
					; ROM:0000E340p
		move.w	#$100,$1C(a0)
		addq.w	#8,$C(a1)
		move.w	$30(a0),$12(a1)
		bset	#1,$22(a1)
		bclr	#3,$22(a1)
		move.b	#$10,$1C(a1)
		move.b	#2,$24(a1)
		move.b	$28(a0),d0
		bpl.s	loc_E382
		move.w	#0,$10(a1)

loc_E382:				; CODE XREF: sub_E34E+2Cj
		btst	#0,d0
		beq.s	loc_E3C2
		move.w	#1,$14(a1)
		move.b	#1,$27(a1)
		move.b	#0,$1C(a1)
		move.b	#0,$2C(a1)
		move.b	#4,$2D(a1)
		btst	#1,d0
		bne.s	loc_E3B2
		move.b	#1,$2C(a1)

loc_E3B2:				; CODE XREF: sub_E34E+5Cj
		btst	#0,$22(a1)
		beq.s	loc_E3C2
		neg.b	$27(a1)
		neg.w	$14(a1)

loc_E3C2:				; CODE XREF: sub_E34E+38j sub_E34E+6Aj
		andi.b	#$C,d0
		cmpi.b	#4,d0
		bne.s	loc_E3D8
		move.b	#$C,$3E(a1)
		move.b	#$D,$3F(a1)

loc_E3D8:				; CODE XREF: sub_E34E+7Cj
		cmpi.b	#8,d0
		bne.s	loc_E3EA
		move.b	#$E,$3E(a1)
		move.b	#$F,$3F(a1)

loc_E3EA:				; CODE XREF: sub_E34E+8Ej
		move.w	#sfx_Spring,d0	; "?"
		jmp	(PlaySound_Special).l
; End of function sub_E34E

; ---------------------------------------------------------------------------

loc_E3F4:				; DATA XREF: ROM:0000E1FCo
		move.w	#$13,d1
		move.w	#$E,d2
		move.w	#$F,d3
		move.w	8(a0),d4
		lea	(v_objspace).w,a1
		moveq	#3,d6
		movem.l	d1-d4,-(sp)
		bsr.w	loc_F4A8
		btst	#5,$22(a0)
		beq.s	loc_E434
		move.b	$22(a0),d1
		move.w	8(a0),d0
		sub.w	8(a1),d0
		bcs.s	loc_E42C
		eori.b	#1,d1

loc_E42C:				; CODE XREF: ROM:0000E426j
		andi.b	#1,d1
		bne.s	loc_E434
		bsr.s	sub_E474

loc_E434:				; CODE XREF: ROM:0000E418j
					; ROM:0000E430j
		movem.l	(sp)+,d1-d4
		lea	(v_objspace+$40).w,a1
		moveq	#4,d6
		bsr.w	loc_F4A8
		btst	#6,$22(a0)
		beq.s	loc_E464
		move.b	$22(a0),d1
		move.w	8(a0),d0
		sub.w	8(a1),d0
		bcs.s	loc_E45C
		eori.b	#1,d1

loc_E45C:				; CODE XREF: ROM:0000E456j
		andi.b	#1,d1
		bne.s	loc_E464
		bsr.s	sub_E474

loc_E464:				; CODE XREF: ROM:0000E448j
					; ROM:0000E460j
		bsr.w	sub_E54C
		lea	(Ani_Obj41).l,a1
		bra.w	AnimateSprite
; ---------------------------------------------------------------------------
		rts

; =============== S U B	R O U T	I N E =======================================


sub_E474:				; CODE XREF: ROM:0000E432p
					; ROM:0000E462p ...
		move.w	#$300,$1C(a0)
		move.w	$30(a0),$10(a1)
		addq.w	#8,8(a1)
		bset	#0,$22(a1)
		btst	#0,$22(a0)
		bne.s	loc_E4A2
		bclr	#0,$22(a1)
		subi.w	#$10,8(a1)
		neg.w	$10(a1)

loc_E4A2:				; CODE XREF: sub_E474+1Cj
		move.w	#$F,$2E(a1)
		move.w	$10(a1),$14(a1)
		btst	#2,$22(a1)
		bne.s	loc_E4BC
		move.b	#0,$1C(a1)

loc_E4BC:				; CODE XREF: sub_E474+40j
		move.b	$28(a0),d0
		bpl.s	loc_E4C8
		move.w	#0,$12(a1)

loc_E4C8:				; CODE XREF: sub_E474+4Cj
		btst	#0,d0
		beq.s	loc_E508
		move.w	#1,$14(a1)
		move.b	#1,$27(a1)
		move.b	#0,$1C(a1)
		move.b	#1,$2C(a1)
		move.b	#8,$2D(a1)
		btst	#1,d0
		bne.s	loc_E4F8
		move.b	#3,$2C(a1)

loc_E4F8:				; CODE XREF: sub_E474+7Cj
		btst	#0,$22(a1)
		beq.s	loc_E508
		neg.b	$27(a1)
		neg.w	$14(a1)

loc_E508:				; CODE XREF: sub_E474+58j sub_E474+8Aj
		andi.b	#$C,d0
		cmpi.b	#4,d0
		bne.s	loc_E51E
		move.b	#$C,$3E(a1)
		move.b	#$D,$3F(a1)

loc_E51E:				; CODE XREF: sub_E474+9Cj
		cmpi.b	#8,d0
		bne.s	loc_E530
		move.b	#$E,$3E(a1)
		move.b	#$F,$3F(a1)

loc_E530:				; CODE XREF: sub_E474+AEj
		bclr	#5,$22(a0)
		bclr	#6,$22(a0)
		bclr	#5,$22(a1)
		move.w	#sfx_Spring,d0	; "?"
		jmp	(PlaySound_Special).l
; End of function sub_E474


; =============== S U B	R O U T	I N E =======================================


sub_E54C:				; CODE XREF: ROM:loc_E464p
		cmpi.b	#3,$1C(a0)
		beq.w	locret_E604
		move.w	8(a0),d0
		move.w	d0,d1
		addi.w	#$28,d1	
		btst	#0,$22(a0)
		beq.s	loc_E56E
		move.w	d0,d1
		subi.w	#$28,d0	

loc_E56E:				; CODE XREF: sub_E54C+1Aj
		move.w	$C(a0),d2
		move.w	d2,d3
		subi.w	#$18,d2
		addi.w	#$18,d3
		lea	(v_objspace).w,a1
		btst	#1,$22(a1)
		bne.s	loc_E5C2
		move.w	$14(a1),d4
		btst	#0,$22(a0)
		beq.s	loc_E596
		neg.w	d4

loc_E596:				; CODE XREF: sub_E54C+46j
		tst.w	d4
		bmi.s	loc_E5C2
		move.w	8(a1),d4
		cmp.w	d0,d4
		bcs.w	loc_E5C2
		cmp.w	d1,d4
		bcc.w	loc_E5C2
		move.w	$C(a1),d4
		cmp.w	d2,d4
		bcs.w	loc_E5C2
		cmp.w	d3,d4
		bcc.w	loc_E5C2
		move.w	d0,-(sp)
		bsr.w	sub_E474
		move.w	(sp)+,d0

loc_E5C2:				; CODE XREF: sub_E54C+3Aj sub_E54C+4Cj ...
		lea	(v_objspace+$40).w,a1
		btst	#1,$22(a1)
		bne.s	locret_E604
		move.w	$14(a1),d4
		btst	#0,$22(a0)
		beq.s	loc_E5DC
		neg.w	d4

loc_E5DC:				; CODE XREF: sub_E54C+8Cj
		tst.w	d4
		bmi.s	locret_E604
		move.w	8(a1),d4
		cmp.w	d0,d4
		bcs.w	locret_E604
		cmp.w	d1,d4
		bcc.w	locret_E604
		move.w	$C(a1),d4
		cmp.w	d2,d4
		bcs.w	locret_E604
		cmp.w	d3,d4
		bcc.w	locret_E604
		bsr.w	sub_E474

locret_E604:				; CODE XREF: sub_E54C+6j sub_E54C+80j	...
		rts
; End of function sub_E54C

; ---------------------------------------------------------------------------

loc_E606:				; DATA XREF: ROM:0000E1FEo
		move.w	#$1B,d1
		move.w	#8,d2
		move.w	#$10,d3
		move.w	8(a0),d4
		lea	(v_objspace).w,a1
		moveq	#3,d6
		movem.l	d1-d4,-(sp)
		bsr.w	loc_F4A8
		cmpi.w	#$FFFE,d4
		bne.s	loc_E62C
		bsr.s	sub_E64E

loc_E62C:				; CODE XREF: ROM:0000E628j
		movem.l	(sp)+,d1-d4
		lea	(v_objspace+$40).w,a1
		moveq	#4,d6
		bsr.w	loc_F4A8
		cmpi.w	#$FFFE,d4
		bne.s	loc_E642
		bsr.s	sub_E64E

loc_E642:				; CODE XREF: ROM:0000E63Ej
		lea	(Ani_Obj41).l,a1
		bra.w	AnimateSprite
; ---------------------------------------------------------------------------
		rts

; =============== S U B	R O U T	I N E =======================================


sub_E64E:				; CODE XREF: ROM:0000E62Ap
					; ROM:0000E640p
		move.w	#$100,$1C(a0)
		subq.w	#8,$C(a1)
		move.w	$30(a0),$12(a1)
		neg.w	$12(a1)
		move.b	$28(a0),d0
		bpl.s	loc_E66E
		move.w	#0,$10(a1)

loc_E66E:				; CODE XREF: sub_E64E+18j
		btst	#0,d0
		beq.s	loc_E6AE
		move.w	#1,$14(a1)
		move.b	#1,$27(a1)
		move.b	#0,$1C(a1)
		move.b	#0,$2C(a1)
		move.b	#4,$2D(a1)
		btst	#1,d0
		bne.s	loc_E69E
		move.b	#1,$2C(a1)

loc_E69E:				; CODE XREF: sub_E64E+48j
		btst	#0,$22(a1)
		beq.s	loc_E6AE
		neg.b	$27(a1)
		neg.w	$14(a1)

loc_E6AE:				; CODE XREF: sub_E64E+24j sub_E64E+56j
		andi.b	#$C,d0
		cmpi.b	#4,d0
		bne.s	loc_E6C4
		move.b	#$C,$3E(a1)
		move.b	#$D,$3F(a1)

loc_E6C4:				; CODE XREF: sub_E64E+68j
		cmpi.b	#8,d0
		bne.s	loc_E6D6
		move.b	#$E,$3E(a1)
		move.b	#$F,$3F(a1)

loc_E6D6:				; CODE XREF: sub_E64E+7Aj
		bset	#1,$22(a1)
		bclr	#3,$22(a1)
		move.b	#2,$24(a1)
		move.w	#sfx_Spring,d0	; "?"
		jmp	(PlaySound_Special).l
; End of function sub_E64E

; ---------------------------------------------------------------------------

loc_E6F2:				; DATA XREF: ROM:0000E200o
		move.w	#$1B,d1
		move.w	#$10,d2
		move.w	8(a0),d4
		lea	byte_E934(pc),a2
		lea	(v_objspace).w,a1
		moveq	#3,d6
		movem.l	d1-d4,-(sp)
		bsr.w	loc_F4FA
		btst	#3,$22(a0)
		beq.s	loc_E71A
		bsr.s	sub_E73E

loc_E71A:				; CODE XREF: ROM:0000E716j
		movem.l	(sp)+,d1-d4
		lea	(v_objspace+$40).w,a1
		moveq	#4,d6
		bsr.w	loc_F4FA
		btst	#4,$22(a0)
		beq.s	loc_E732
		bsr.s	sub_E73E

loc_E732:				; CODE XREF: ROM:0000E72Ej
		lea	(Ani_Obj41).l,a1
		bra.w	AnimateSprite
; ---------------------------------------------------------------------------
		rts

; =============== S U B	R O U T	I N E =======================================


sub_E73E:				; CODE XREF: ROM:0000E718p
					; ROM:0000E730p
		btst	#0,$22(a0)
		bne.s	loc_E754
		move.w	8(a0),d0
		subq.w	#4,d0
		cmp.w	8(a1),d0
		bcs.s	loc_E762
		rts
; ---------------------------------------------------------------------------

loc_E754:				; CODE XREF: sub_E73E+6j
		move.w	8(a0),d0
		addq.w	#4,d0
		cmp.w	8(a1),d0
		bcc.s	loc_E762
		rts
; ---------------------------------------------------------------------------

loc_E762:				; CODE XREF: sub_E73E+12j sub_E73E+20j
		move.w	#$500,$1C(a0)
		move.w	$30(a0),$12(a1)
		move.w	$30(a0),$10(a1)
		addq.w	#6,$C(a1)
		addq.w	#6,8(a1)
		bset	#0,$22(a1)
		btst	#0,$22(a0)
		bne.s	loc_E79A
		bclr	#0,$22(a1)
		subi.w	#$C,8(a1)
		neg.w	$10(a1)

loc_E79A:				; CODE XREF: sub_E73E+4Aj
		bset	#1,$22(a1)
		bclr	#3,$22(a1)
		move.b	#$10,$1C(a1)
		move.b	#2,$24(a1)
		move.b	$28(a0),d0
		btst	#0,d0
		beq.s	loc_E7F6
		move.w	#1,$14(a1)
		move.b	#1,$27(a1)
		move.b	#0,$1C(a1)
		move.b	#1,$2C(a1)
		move.b	#8,$2D(a1)
		btst	#1,d0
		bne.s	loc_E7E6
		move.b	#3,$2C(a1)

loc_E7E6:				; CODE XREF: sub_E73E+A0j
		btst	#0,$22(a1)
		beq.s	loc_E7F6
		neg.b	$27(a1)
		neg.w	$14(a1)

loc_E7F6:				; CODE XREF: sub_E73E+7Cj sub_E73E+AEj
		andi.b	#$C,d0
		cmpi.b	#4,d0
		bne.s	loc_E80C
		move.b	#$C,$3E(a1)
		move.b	#$D,$3F(a1)

loc_E80C:				; CODE XREF: sub_E73E+C0j
		cmpi.b	#8,d0
		bne.s	loc_E81E
		move.b	#$E,$3E(a1)
		move.b	#$F,$3F(a1)

loc_E81E:				; CODE XREF: sub_E73E+D2j
		move.w	#sfx_Spring,d0	; "?"
		jmp	(PlaySound_Special).l
; End of function sub_E73E

; ---------------------------------------------------------------------------

loc_E828:				; DATA XREF: ROM:0000E202o
		move.w	#$1B,d1
		move.w	#$10,d2
		move.w	8(a0),d4
		lea	byte_E950(pc),a2
		lea	(v_objspace).w,a1
		moveq	#3,d6
		movem.l	d1-d4,-(sp)
		bsr.w	loc_F4FA
		cmpi.w	#$FFFE,d4
		bne.s	loc_E84E
		bsr.s	sub_E870

loc_E84E:				; CODE XREF: ROM:0000E84Aj
		movem.l	(sp)+,d1-d4
		lea	(v_objspace+$40).w,a1
		moveq	#4,d6
		bsr.w	loc_F4FA
		cmpi.w	#$FFFE,d4
		bne.s	loc_E864
		bsr.s	sub_E870

loc_E864:				; CODE XREF: ROM:0000E860j
		lea	(Ani_Obj41).l,a1
		bra.w	AnimateSprite
; ---------------------------------------------------------------------------
		rts

; =============== S U B	R O U T	I N E =======================================


sub_E870:				; CODE XREF: ROM:0000E84Cp
					; ROM:0000E862p
		move.w	#$500,$1C(a0)
		move.w	$30(a0),$12(a1)
		neg.w	$12(a1)
		move.w	$30(a0),$10(a1)
		subq.w	#6,$C(a1)
		addq.w	#6,8(a1)
		bset	#0,$22(a1)
		btst	#0,$22(a0)
		bne.s	loc_E8AC
		bclr	#0,$22(a1)
		subi.w	#$C,8(a1)
		neg.w	$10(a1)

loc_E8AC:				; CODE XREF: sub_E870+2Aj
		bset	#1,$22(a1)
		bclr	#3,$22(a1)
		move.b	#2,$24(a1)
		move.b	$28(a0),d0
		btst	#0,d0
		beq.s	loc_E902
		move.w	#1,$14(a1)
		move.b	#1,$27(a1)
		move.b	#0,$1C(a1)
		move.b	#1,$2C(a1)
		move.b	#8,$2D(a1)
		btst	#1,d0
		bne.s	loc_E8F2
		move.b	#3,$2C(a1)

loc_E8F2:				; CODE XREF: sub_E870+7Aj
		btst	#0,$22(a1)
		beq.s	loc_E902
		neg.b	$27(a1)
		neg.w	$14(a1)

loc_E902:				; CODE XREF: sub_E870+56j sub_E870+88j
		andi.b	#$C,d0
		cmpi.b	#4,d0
		bne.s	loc_E918
		move.b	#$C,$3E(a1)
		move.b	#$D,$3F(a1)

loc_E918:				; CODE XREF: sub_E870+9Aj
		cmpi.b	#8,d0
		bne.s	loc_E92A
		move.b	#$E,$3E(a1)
		move.b	#$F,$3F(a1)

loc_E92A:				; CODE XREF: sub_E870+ACj
		move.w	#sfx_Spring,d0	; "?"
		jmp	(PlaySound_Special).l
; End of function sub_E870

; ---------------------------------------------------------------------------
byte_E934:	dc.b $10,$10,$10,$10	; 0 ; DATA XREF: ROM:0000E6FEt
		dc.b $10,$10,$10,$10	; 4
		dc.b $10,$10,$10,$10	; 8
		dc.b  $E, $C, $A,  8	; 12
		dc.b   6,  4,  2,  0	; 16
		dc.b $FE,$FC,$FC,$FC	; 20
		dc.b $FC,$FC,$FC,$FC	; 24
byte_E950:	dc.b $F4,$F0,$F0,$F0	; 0 ; DATA XREF: ROM:0000E834t
		dc.b $F0,$F0,$F0,$F0	; 4
		dc.b $F0,$F0,$F0,$F0	; 8
		dc.b $F2,$F4,$F6,$F8	; 12
		dc.b $FA,$FC,$FE,  0	; 16
		dc.b   2,  4,  4,  4	; 20
		dc.b   4,  4,  4,  4	; 24
Ani_Obj41:	dc.w byte_E978-Ani_Obj41 ; DATA	XREF: ROM:loc_E342o
					; ROM:0000E468o ...
		dc.w byte_E97B-Ani_Obj41
		dc.w byte_E987-Ani_Obj41
		dc.w byte_E98A-Ani_Obj41
		dc.w byte_E996-Ani_Obj41
		dc.w byte_E999-Ani_Obj41
byte_E978:	dc.b  $F,  0,$FF	; 0 ; DATA XREF: ROM:Ani_Obj41o
byte_E97B:	dc.b   0,  1,  0,  0,  2,  2,  2,  2; 0	; DATA XREF: ROM:0000E96Eo
		dc.b   2,  2,$FD,  0	; 8
byte_E987:	dc.b  $F,  3,$FF	; 0 ; DATA XREF: ROM:0000E970o
byte_E98A:	dc.b   0,  4,  3,  3,  5,  5,  5,  5; 0	; DATA XREF: ROM:0000E972o
		dc.b   5,  5,$FD,  2	; 8
byte_E996:	dc.b  $F,  7,$FF	; 0 ; DATA XREF: ROM:0000E974o
byte_E999:	dc.b   0,  8,  7,  7,  9,  9,  9,  9; 0	; DATA XREF: ROM:0000E976o
		dc.b   9,  9,$FD,  4,  0; 8
Map_Obj41_GHZ:	dc.w word_E9B2-Map_Obj41_GHZ ; DATA XREF: ROM:0000E208o
					; ROM:Map_Obj41_GHZo ...
		dc.w word_E9C4-Map_Obj41_GHZ
		dc.w word_E9CE-Map_Obj41_GHZ
		dc.w word_E9E8-Map_Obj41_GHZ
		dc.w word_E9F2-Map_Obj41_GHZ
		dc.w word_E9FC-Map_Obj41_GHZ
word_E9B2:	dc.w 2			; DATA XREF: ROM:Map_Obj41_GHZo
		dc.w $F80C,    0,    0,$FFF0; 0
		dc.w	$C,    4,    2,$FFF0; 4
word_E9C4:	dc.w 1			; DATA XREF: ROM:0000E9A8o
		dc.w	$C,    0,    0,$FFF0; 0
word_E9CE:	dc.w 3			; DATA XREF: ROM:0000E9AAo
		dc.w $E80C,    0,    0,$FFF0; 0
		dc.w $F005,    8,    4,$FFF8; 4
		dc.w	$C,   $C,    6,$FFF0; 8
word_E9E8:	dc.w 1			; DATA XREF: ROM:0000E9ACo
		dc.b $F0,  7,  0,  0	; 0
		dc.b   0,  0,$FF,$F8	; 4
word_E9F2:	dc.w 1			; DATA XREF: ROM:0000E9AEo
		dc.w $F003,    4,    2,$FFF8; 0
word_E9FC:	dc.w 4			; DATA XREF: ROM:0000E9B0o
		dc.w $F003,    4,    2,	 $10; 0
		dc.w $F809,    8,    4,$FFF8; 4
		dc.w $F000,    0,    0,$FFF8; 8
		dc.w  $800,    3,    1,$FFF8; 12
Map_Obj41:	dc.w word_EA4A-Map_Obj41 ; DATA	XREF: ROM:0000E21Co
					; ROM:Map_Obj41o ...
		dc.w word_EA5C-Map_Obj41
		dc.w word_EA66-Map_Obj41
		dc.w word_EA78-Map_Obj41
		dc.w word_EA8A-Map_Obj41
		dc.w word_EA94-Map_Obj41
		dc.w word_EAA6-Map_Obj41
		dc.w word_EAB8-Map_Obj41
		dc.w word_EADA-Map_Obj41
		dc.w word_EAF4-Map_Obj41
		dc.w word_EB16-Map_Obj41
Map_Obj41a:	dc.w word_EA4A-Map_Obj41a ; DATA XREF: ROM:0000E2F0o
					; ROM:Map_Obj41ao ...
		dc.w word_EA5C-Map_Obj41a
		dc.w word_EA66-Map_Obj41a
		dc.w word_EA78-Map_Obj41a
		dc.w word_EA8A-Map_Obj41a
		dc.w word_EA94-Map_Obj41a
		dc.w word_EAA6-Map_Obj41a
		dc.w word_EB38-Map_Obj41a
		dc.w word_EB5A-Map_Obj41a
		dc.w word_EB74-Map_Obj41a
		dc.w word_EB96-Map_Obj41a
word_EA4A:	dc.w 2			; DATA XREF: ROM:Map_Obj41o
					; ROM:Map_Obj41ao
		dc.w $F00D,    0,    0,$FFF0; 0
		dc.w	 5,    8,    4,$FFF8; 4
word_EA5C:	dc.w 1			; DATA XREF: ROM:0000EA20o
					; ROM:0000EA36o
		dc.w $F80D,    0,    0,$FFF0; 0
word_EA66:	dc.w 2			; DATA XREF: ROM:0000EA22o
					; ROM:0000EA38o
		dc.w $E00D,    0,    0,$FFF0; 0
		dc.w $F007,   $C,    6,$FFF8; 4
word_EA78:	dc.w 2			; DATA XREF: ROM:0000EA24o
					; ROM:0000EA3Ao
		dc.w $F003,    0,    0,	   0; 0
		dc.w $F801,    4,    2,$FFF8; 4
word_EA8A:	dc.w 1			; DATA XREF: ROM:0000EA26o
					; ROM:0000EA3Co
		dc.w $F003,    0,    0,$FFF8; 0
word_EA94:	dc.w 2			; DATA XREF: ROM:0000EA28o
					; ROM:0000EA3Eo
		dc.w $F003,    0,    0,	 $10; 0
		dc.w $F809,    6,    3,$FFF8; 4
word_EAA6:	dc.w 2			; DATA XREF: ROM:0000EA2Ao
					; ROM:0000EA40o
		dc.w	$D,$1000,$1000,$FFF0; 0
		dc.w $F005,$1008,$1004,$FFF8; 4
word_EAB8:	dc.w 4			; DATA XREF: ROM:0000EA2Co
		dc.w $F00D,    0,    0,$FFF0; 0
		dc.w	 5,    8,    4,	   0; 4
		dc.w $FB05,   $C,    6,$FFF6; 8
		dc.w	 5,$201C,$200E,$FFF0; 12
word_EADA:	dc.w 3			; DATA XREF: ROM:0000EA2Eo
		dc.w $F60D,    0,    0,$FFEA; 0
		dc.w  $605,    8,    4,$FFFA; 4
		dc.w	 5,$201C,$200E,$FFF0; 8
word_EAF4:	dc.w 4			; DATA XREF: ROM:0000EA30o
		dc.w $E60D,    0,    0,$FFFB; 0
		dc.w $F605,    8,    4,	  $B; 4
		dc.w $F30B,  $10,    8,$FFF6; 8
		dc.w	 5,$201C,$200E,$FFF0; 12
word_EB16:	dc.w 4			; DATA XREF: ROM:0000EA32o
		dc.w	$D,$1000,$1000,$FFF0; 0
		dc.w $F005,$1008,$1004,	   0; 4
		dc.w $F505,$100C,$1006,$FFF6; 8
		dc.w $F005,$301C,$300E,$FFF0; 12
word_EB38:	dc.w 4			; DATA XREF: ROM:0000EA42o
		dc.w $F00D,    0,    0,$FFF0; 0
		dc.w	 5,    8,    4,	   0; 4
		dc.w $FB05,   $C,    6,$FFF6; 8
		dc.w	 5,  $1C,   $E,$FFF0; 12
word_EB5A:	dc.w 3			; DATA XREF: ROM:0000EA44o
		dc.w $F60D,    0,    0,$FFEA; 0
		dc.w  $605,    8,    4,$FFFA; 4
		dc.w	 5,  $1C,   $E,$FFF0; 8
word_EB74:	dc.w 4			; DATA XREF: ROM:0000EA46o
		dc.w $E60D,    0,    0,$FFFB; 0
		dc.w $F605,    8,    4,	  $B; 4
		dc.w $F30B,  $10,    8,$FFF6; 8
		dc.w	 5,  $1C,   $E,$FFF0; 12
word_EB96:	dc.w 4			; DATA XREF: ROM:0000EA48o
		dc.w	$D,$1000,$1000,$FFF0; 0
		dc.w $F005,$1008,$1004,	   0; 4
		dc.w $F505,$100C,$1006,$FFF6; 8
		dc.w $F005,$101C,$100E,$FFF0; 12
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 42 - GHZ Newtron badnik
;----------------------------------------------------

Obj42:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj42_Index(pc,d0.w),d1
		jmp	Obj42_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj42_Index:	dc.w loc_EBCC-Obj42_Index ; DATA XREF: ROM:Obj42_Indexo
					; ROM:0000EBC8o ...
		dc.w loc_EC00-Obj42_Index
		dc.w loc_ED6E-Obj42_Index
; ---------------------------------------------------------------------------

loc_EBCC:				; DATA XREF: ROM:Obj42_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj32,4(a0)
		move.w	#$49B,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$14,$19(a0)
		move.b	#$10,$16(a0)
		move.b	#8,$17(a0)

loc_EC00:				; DATA XREF: ROM:0000EBC8o
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	off_EC1C(pc,d0.w),d1
		jsr	off_EC1C(pc,d1.w)
		lea	(Ani_Obj32).l,a1
		bsr.w	AnimateSprite
		bra.w	MarkObjGone
; ---------------------------------------------------------------------------
off_EC1C:	dc.w loc_EC26-off_EC1C	; DATA XREF: ROM:off_EC1Co
					; ROM:0000EC1Eo ...
		dc.w loc_EC6C-off_EC1C
		dc.w loc_ECE0-off_EC1C
		dc.w loc_ED00-off_EC1C
		dc.w loc_ED06-off_EC1C
; ---------------------------------------------------------------------------

loc_EC26:				; DATA XREF: ROM:off_EC1Co
		bset	#0,$22(a0)
		move.w	(v_objspace+8).w,d0
		sub.w	8(a0),d0
		bcc.s	loc_EC3E
		neg.w	d0
		bclr	#0,$22(a0)

loc_EC3E:				; CODE XREF: ROM:0000EC34j
		cmpi.w	#$80,d0	
		bcc.s	locret_EC6A
		addq.b	#2,$25(a0)
		move.b	#1,$1C(a0)
		tst.b	$28(a0)
		beq.s	locret_EC6A
		move.w	#$249B,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#8,$25(a0)
		move.b	#4,$1C(a0)

locret_EC6A:				; CODE XREF: ROM:0000EC42j
					; ROM:0000EC52j
		rts
; ---------------------------------------------------------------------------

loc_EC6C:				; DATA XREF: ROM:0000EC1Eo
		cmpi.b	#4,$1A(a0)
		bcc.s	loc_EC8C
		bset	#0,$22(a0)
		move.w	(v_objspace+8).w,d0
		sub.w	8(a0),d0
		bcc.s	locret_EC8A
		bclr	#0,$22(a0)

locret_EC8A:				; CODE XREF: ROM:0000EC82j
		rts
; ---------------------------------------------------------------------------

loc_EC8C:				; CODE XREF: ROM:0000EC72j
		cmpi.b	#1,$1A(a0)
		bne.s	loc_EC9A
		move.b	#$C,$20(a0)

loc_EC9A:				; CODE XREF: ROM:0000EC92j
		bsr.w	ObjectFall
		bsr.w	ObjHitFloor
		tst.w	d1
		bpl.s	locret_ECDE
		add.w	d1,$C(a0)
		move.w	#0,$12(a0)
		addq.b	#2,$25(a0)
		move.b	#2,$1C(a0)
		btst	#5,2(a0)
		beq.s	loc_ECC6
		addq.b	#1,$1C(a0)

loc_ECC6:				; CODE XREF: ROM:0000ECC0j
		move.b	#$D,$20(a0)
		move.w	#$200,$10(a0)
		btst	#0,$22(a0)
		bne.s	locret_ECDE
		neg.w	$10(a0)

locret_ECDE:				; CODE XREF: ROM:0000ECA4j
					; ROM:0000ECD8j
		rts
; ---------------------------------------------------------------------------

loc_ECE0:				; DATA XREF: ROM:0000EC20o
		bsr.w	SpeedToPos
		bsr.w	ObjHitFloor
		cmpi.w	#$FFF8,d1
		blt.s	loc_ECFA
		cmpi.w	#$C,d1
		bge.s	loc_ECFA
		add.w	d1,$C(a0)
		rts
; ---------------------------------------------------------------------------

loc_ECFA:				; CODE XREF: ROM:0000ECECj
					; ROM:0000ECF2j
		addq.b	#2,$25(a0)
		rts
; ---------------------------------------------------------------------------

loc_ED00:				; DATA XREF: ROM:0000EC22o
		bsr.w	SpeedToPos
		rts
; ---------------------------------------------------------------------------

loc_ED06:				; DATA XREF: ROM:0000EC24o
		cmpi.b	#1,$1A(a0)
		bne.s	loc_ED14
		move.b	#$C,$20(a0)

loc_ED14:				; CODE XREF: ROM:0000ED0Cj
		cmpi.b	#2,$1A(a0)
		bne.s	locret_ED6C
		tst.b	$32(a0)
		bne.s	locret_ED6C
		move.b	#1,$32(a0)
		bsr.w	SingleObjectLoad
		bne.s	locret_ED6C
		move.b	#$23,0(a1) 
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		subq.w	#8,$C(a1)
		move.w	#$200,$10(a1)
		move.w	#$14,d0
		btst	#0,$22(a0)
		bne.s	loc_ED5C
		neg.w	d0
		neg.w	$10(a1)

loc_ED5C:				; CODE XREF: ROM:0000ED54j
		add.w	d0,8(a1)
		move.b	$22(a0),$22(a1)
		move.b	#1,$28(a1)

locret_ED6C:				; CODE XREF: ROM:0000ED1Aj
					; ROM:0000ED20j ...
		rts
; ---------------------------------------------------------------------------

loc_ED6E:				; DATA XREF: ROM:0000EBCAo
		bra.w	DeleteObject
; ---------------------------------------------------------------------------
Ani_Obj32:	dc.w byte_ED7C-Ani_Obj32 ; DATA	XREF: ROM:0000EC0Eo
					; ROM:Ani_Obj32o ...
		dc.w byte_ED7F-Ani_Obj32
		dc.w byte_ED87-Ani_Obj32
		dc.w byte_ED8B-Ani_Obj32
		dc.w byte_ED8F-Ani_Obj32
byte_ED7C:	dc.b  $F, $A,$FF	; 0 ; DATA XREF: ROM:Ani_Obj32o
byte_ED7F:	dc.b $13,  0,  1,  3,  4,  5,$FE,  1; 0	; DATA XREF: ROM:0000ED74o
byte_ED87:	dc.b   2,  6,  7,$FF	; 0 ; DATA XREF: ROM:0000ED76o
byte_ED8B:	dc.b   2,  8,  9,$FF	; 0 ; DATA XREF: ROM:0000ED78o
byte_ED8F:	dc.b $13,  0,  1,  1,  2,  1,  1,  0; 0	; DATA XREF: ROM:0000ED7Ao
		dc.b $FC		; 8
Map_Obj32:	dc.w word_EDAE-Map_Obj32 ; DATA	XREF: ROM:0000EBD0o
					; ROM:Map_Obj32o ...
		dc.w word_EDC8-Map_Obj32
		dc.w word_EDE2-Map_Obj32
		dc.w word_EDFC-Map_Obj32
		dc.w word_EE1E-Map_Obj32
		dc.w word_EE38-Map_Obj32
		dc.w word_EE4A-Map_Obj32
		dc.w word_EE64-Map_Obj32
		dc.w word_EE7E-Map_Obj32
		dc.w word_EE98-Map_Obj32
		dc.w word_EEB2-Map_Obj32
word_EDAE:	dc.w 3			; DATA XREF: ROM:Map_Obj32o
		dc.w $EC0D,    0,    0,$FFEC; 0
		dc.w $F400,    8,    4,	  $C; 4
		dc.w $FC0E,    9,    4,$FFF4; 8
word_EDC8:	dc.w 3			; DATA XREF: ROM:0000ED9Ao
		dc.w $EC06,  $15,   $A,$FFEC; 0
		dc.w $EC09,  $1B,   $D,$FFFC; 4
		dc.w $FC0A,  $21,  $10,$FFFC; 8
word_EDE2:	dc.w 3			; DATA XREF: ROM:0000ED9Co
		dc.w $EC06,  $2A,  $15,$FFEC; 0
		dc.w $EC09,  $1B,   $D,$FFFC; 4
		dc.w $FC0A,  $21,  $10,$FFFC; 8
word_EDFC:	dc.w 4			; DATA XREF: ROM:0000ED9Eo
		dc.w $EC06,  $30,  $18,$FFEC; 0
		dc.w $EC09,  $1B,   $D,$FFFC; 4
		dc.w $FC09,  $36,  $1B,$FFFC; 8
		dc.w  $C00,  $3C,  $1E,	  $C; 12
word_EE1E:	dc.w 3			; DATA XREF: ROM:0000EDA0o
		dc.w $F40D,  $3D,  $1E,$FFEC; 0
		dc.w $FC00,  $20,  $10,	  $C; 4
		dc.w  $408,  $45,  $22,$FFFC; 8
word_EE38:	dc.w 2			; DATA XREF: ROM:0000EDA2o
		dc.w $F80D,  $48,  $24,$FFEC; 0
		dc.w $F801,  $50,  $28,	  $C; 4
word_EE4A:	dc.w 3			; DATA XREF: ROM:0000EDA4o
		dc.w $F80D,  $48,  $24,$FFEC; 0
		dc.w $F801,  $50,  $28,	  $C; 4
		dc.w $FE00,  $52,  $29,	 $14; 8
word_EE64:	dc.w 3			; DATA XREF: ROM:0000EDA6o
		dc.w $F80D,  $48,  $24,$FFEC; 0
		dc.w $F801,  $50,  $28,	  $C; 4
		dc.w $FE04,  $53,  $29,	 $14; 8
word_EE7E:	dc.w 3			; DATA XREF: ROM:0000EDA8o
		dc.w $F80D,  $48,  $24,$FFEC; 0
		dc.w $F801,  $50,  $28,	  $C; 4
		dc.w $FE00,$E052,$E029,	 $14; 8
word_EE98:	dc.w 3			; DATA XREF: ROM:0000EDAAo
		dc.w $F80D,  $48,  $24,$FFEC; 0
		dc.w $F801,  $50,  $28,	  $C; 4
		dc.w $FE04,$E053,$E029,	 $14; 8
word_EEB2:	dc.w 0			; DATA XREF: ROM:0000EDACo
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 44 - GHZ wall
;----------------------------------------------------

Obj44:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj44_Index(pc,d0.w),d1
		jmp	Obj44_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj44_Index:	dc.w loc_EEC8-Obj44_Index ; DATA XREF: ROM:Obj44_Indexo
					; ROM:0000EEC4o ...
		dc.w loc_EF04-Obj44_Index
		dc.w loc_EF18-Obj44_Index
; ---------------------------------------------------------------------------

loc_EEC8:				; DATA XREF: ROM:Obj44_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj44,4(a0)
		move.w	#$434C,2(a0)
		bsr.w	ModifySpriteAttr_2P
		ori.b	#4,1(a0)
		move.b	#8,$19(a0)
		move.b	#6,$18(a0)
		move.b	$28(a0),$1A(a0)
		bclr	#4,$1A(a0)
		beq.s	loc_EF04
		addq.b	#2,$24(a0)
		bra.s	loc_EF18
; ---------------------------------------------------------------------------

loc_EF04:				; CODE XREF: ROM:0000EEFCj
					; DATA XREF: ROM:0000EEC4o
		move.w	#$13,d1
		move.w	#$28,d2	
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		bsr.w	SolidObject

loc_EF18:				; CODE XREF: ROM:0000EF02j
					; DATA XREF: ROM:0000EEC6o
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Map_Obj44:	dc.w word_EF36-Map_Obj44 ; DATA	XREF: ROM:0000EECCo
					; ROM:Map_Obj44o ...
		dc.w word_EF58-Map_Obj44
		dc.w word_EF7A-Map_Obj44
word_EF36:	dc.w 4			; DATA XREF: ROM:Map_Obj44o
		dc.w $E005,    4,    2,$FFF8; 0
		dc.w $F005,    8,    4,$FFF8; 4
		dc.w	 5,    8,    4,$FFF8; 8
		dc.w $1005,    8,    4,$FFF8; 12
word_EF58:	dc.w 4			; DATA XREF: ROM:0000EF32o
		dc.w $E005,    8,    4,$FFF8; 0
		dc.w $F005,    8,    4,$FFF8; 4
		dc.w	 5,    8,    4,$FFF8; 8
		dc.w $1005,    8,    4,$FFF8; 12
word_EF7A:	dc.w 4			; DATA XREF: ROM:0000EF34o
		dc.w $E005,    0,    0,$FFF8; 0
		dc.w $F005,    0,    0,$FFF8; 4
		dc.w	 5,    0,    0,$FFF8; 8
		dc.w $1005,    0,    0,$FFF8; 12
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 0D - end of level signpost
;----------------------------------------------------

Obj0D:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj0D_Index(pc,d0.w),d1
		jsr	Obj0D_Index(pc,d1.w)
		lea	(Ani_Obj0D).l,a1
		bsr.w	AnimateSprite
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Obj0D_Index:	dc.w loc_EFD6-Obj0D_Index ; DATA XREF: ROM:Obj0D_Indexo
					; ROM:0000EFCEo ...
		dc.w loc_EFFE-Obj0D_Index
		dc.w loc_F028-Obj0D_Index
		dc.w loc_F0C4-Obj0D_Index
		dc.w locret_F18A-Obj0D_Index
; ---------------------------------------------------------------------------

loc_EFD6:				; DATA XREF: ROM:Obj0D_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj0D,4(a0)
		move.w	#$680,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#$18,$19(a0)
		move.b	#4,$18(a0)

loc_EFFE:				; DATA XREF: ROM:0000EFCEo
		move.w	(v_objspace+8).w,d0
		sub.w	8(a0),d0
		bcs.s	locret_F026
		cmpi.w	#$20,d0	
		bcc.s	locret_F026
		move.w	#sfx_Signpost,d0	; "?"
		jsr	(PlaySound).l
		clr.b	($FFFFFE1E).w
		move.w	($FFFFEECA).w,($FFFFEEC8).w
		addq.b	#2,$24(a0)

locret_F026:				; CODE XREF: ROM:0000F006j
					; ROM:0000F00Cj
		rts
; ---------------------------------------------------------------------------

loc_F028:				; DATA XREF: ROM:0000EFD0o
		subq.w	#1,$30(a0)
		bpl.s	loc_F044
		move.w	#$3C,$30(a0) 
		addq.b	#1,$1C(a0)
		cmpi.b	#3,$1C(a0)
		bne.s	loc_F044
		addq.b	#2,$24(a0)

loc_F044:				; CODE XREF: ROM:0000F02Cj
					; ROM:0000F03Ej
		subq.w	#1,$32(a0)
		bpl.s	locret_F0B2
		move.w	#$B,$32(a0)
		moveq	#0,d0
		move.b	$34(a0),d0
		addq.b	#2,$34(a0)
		andi.b	#$E,$34(a0)
		lea	dword_F0B4(pc,d0.w),a2
		bsr.w	SingleObjectLoad
		bne.s	locret_F0B2
		move.b	#$25,0(a1) 
		move.b	#6,$24(a1)
		move.b	(a2)+,d0
		ext.w	d0
		add.w	8(a0),d0
		move.w	d0,8(a1)
		move.b	(a2)+,d0
		ext.w	d0
		add.w	$C(a0),d0
		move.w	d0,$C(a1)
		move.l	#Map_Obj25,4(a1)
		move.w	#$27B2,2(a1)
		bsr.w	ModifyA1SpriteAttr_2P
		move.b	#4,1(a1)
		move.b	#2,$18(a1)
		move.b	#8,$19(a1)

locret_F0B2:				; CODE XREF: ROM:0000F048j
					; ROM:0000F068j
		rts
; ---------------------------------------------------------------------------
dword_F0B4:	dc.l $E8F00808
		dc.l $F00018F8
		dc.l $F81000
		dc.l $E8081810
; ---------------------------------------------------------------------------

loc_F0C4:				; DATA XREF: ROM:0000EFD2o
		tst.w	($FFFFFE08).w
		bne.w	locret_F15E
		btst	#1,(v_objspace+$22).w
		bne.s	loc_F0E0
		move.b	#1,($FFFFF7CC).w
		move.w	#$800,(v_jpadhold2).w

loc_F0E0:				; CODE XREF: ROM:0000F0D2j
		tst.b	(v_objspace).w
		beq.s	loc_F0F6
		move.w	(v_objspace+8).w,d0
		move.w	($FFFFEECA).w,d1
		addi.w	#$128,d1
		cmp.w	d1,d0
		bcs.s	locret_F15E

loc_F0F6:				; CODE XREF: ROM:0000F0E4j
		addq.b	#2,$24(a0)

; =============== S U B	R O U T	I N E =======================================


GotThroughAct:				; CODE XREF: ROM:0001971Ep
		tst.b	(v_objspace+$5C0).w
		bne.s	locret_F15E
		move.w	($FFFFEECA).w,($FFFFEEC8).w
		clr.b	($FFFFFE2D).w
		clr.b	($FFFFFE1E).w
		move.b	#$3A,(v_objspace+$5C0).w 
		moveq	#plcid_TitleCard,d0
		jsr	(LoadPLC2).l
		move.b	#1,($FFFFF7D6).w
		moveq	#0,d0
		move.b	($FFFFFE23).w,d0
		mulu.w	#$3C,d0	
		moveq	#0,d1
		move.b	($FFFFFE24).w,d1
		add.w	d1,d0
		divu.w	#$F,d0
		moveq	#$14,d1
		cmp.w	d1,d0
		bcs.s	loc_F140
		move.w	d1,d0

loc_F140:				; CODE XREF: GotThroughAct+42j
		add.w	d0,d0
		move.w	TimeBonuses(pc,d0.w),($FFFFF7D2).w
		move.w	($FFFFFE20).w,d0
		mulu.w	#$A,d0
		move.w	d0,($FFFFF7D4).w
		move.w	#bgm_GotThrough,d0
		jsr	(PlaySound_Special).l

locret_F15E:				; CODE XREF: ROM:0000F0C8j
					; ROM:0000F0F4j ...
		rts
; End of function GotThroughAct

; ---------------------------------------------------------------------------
TimeBonuses:	dc.w  5000, 5000, 1000,	 500; 0
		dc.w   400,  400,  300,	 300; 4
		dc.w   200,  200,  200,	 200; 8
		dc.w   100,  100,  100,	 100; 12
		dc.w	50,   50,   50,	  50; 16
		dc.w	 0		; 20
; ---------------------------------------------------------------------------

locret_F18A:				; DATA XREF: ROM:0000EFD4o
		rts
; ---------------------------------------------------------------------------
Ani_Obj0D:	dc.w byte_F194-Ani_Obj0D ; DATA	XREF: ROM:0000EFAAo
					; ROM:Ani_Obj0Do ...
		dc.w byte_F197-Ani_Obj0D
		dc.w byte_F1A5-Ani_Obj0D
		dc.w byte_F1B3-Ani_Obj0D
byte_F194:	dc.b  $F,  2,$FF	; 0 ; DATA XREF: ROM:Ani_Obj0Do
byte_F197:	dc.b   1,  2,  3,  4,  5,  1,  3,  4; 0	; DATA XREF: ROM:0000F18Eo
		dc.b   5,  0,  3,  4,  5,$FF; 8
byte_F1A5:	dc.b   1,  2,  3,  4,  5,  1,  3,  4; 0	; DATA XREF: ROM:0000F190o
		dc.b   5,  0,  3,  4,  5,$FF; 8
byte_F1B3:	dc.b  $F,  0,$FF	; 0 ; DATA XREF: ROM:0000F192o
Map_Obj0D:	dc.w word_F1C2-Map_Obj0D ; DATA	XREF: ROM:0000EFDAo
					; ROM:Map_Obj0Do ...
		dc.w word_F1DC-Map_Obj0D
		dc.w word_F1F6-Map_Obj0D
		dc.w word_F210-Map_Obj0D
		dc.w word_F222-Map_Obj0D
		dc.w word_F234-Map_Obj0D
word_F1C2:	dc.w 3			; DATA XREF: ROM:Map_Obj0Do
		dc.w $F00B,    0,    0,$FFE8; 0
		dc.w $F00B, $800, $800,	   0; 4
		dc.w $1001,  $38,  $1C,$FFFC; 8
word_F1DC:	dc.w 3			; DATA XREF: ROM:0000F1B8o
		dc.w $F00B,   $C,    6,$FFE8; 0
		dc.w $F00B, $80C, $806,	   0; 4
		dc.w $1001,  $38,  $1C,$FFFC; 8
word_F1F6:	dc.w 3			; DATA XREF: ROM:0000F1BAo
		dc.w $F00B,  $18,   $C,$FFE8; 0
		dc.w $F00B, $818, $80C,	   0; 4
		dc.w $1001,  $38,  $1C,$FFFC; 8
word_F210:	dc.w 2			; DATA XREF: ROM:0000F1BCo
		dc.w $F00F,  $24,  $12,$FFF0; 0
		dc.w $1001,  $38,  $1C,$FFFC; 4
word_F222:	dc.w 2			; DATA XREF: ROM:0000F1BEo
		dc.w $F003,  $34,  $1A,$FFFC; 0
		dc.w $1001,  $38,  $1C,$FFFC; 4
word_F234:	dc.w 2			; DATA XREF: ROM:0000F1C0o
		dc.w $F00F, $824, $812,$FFF0; 0
		dc.w $1001,  $38,  $1C,$FFFC; 4
; ---------------------------------------------------------------------------
		nop
;----------------------------------------------------
; Object 40 - GHZ Motobug
;----------------------------------------------------

Obj40:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	off_F256(pc,d0.w),d1
		jmp	off_F256(pc,d1.w)
; ---------------------------------------------------------------------------
off_F256:	dc.w loc_F25E-off_F256	; DATA XREF: ROM:off_F256o
					; ROM:0000F258o ...
		dc.w loc_F2C6-off_F256
		dc.w loc_F36E-off_F256
		dc.w loc_F37C-off_F256
; ---------------------------------------------------------------------------

loc_F25E:				; DATA XREF: ROM:off_F256o
		move.l	#Map_Obj40,4(a0)
		move.w	#$4E0,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$14,$19(a0)
		tst.b	$1C(a0)
		bne.s	loc_F2BE
		move.b	#$E,$16(a0)
		move.b	#8,$17(a0)
		move.b	#$C,$20(a0)
		bsr.w	ObjectFall
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	locret_F2BC
		add.w	d1,$C(a0)
		move.w	#0,$12(a0)
		addq.b	#2,$24(a0)
		bchg	#0,$22(a0)

locret_F2BC:				; CODE XREF: ROM:0000F2A6j
		rts
; ---------------------------------------------------------------------------

loc_F2BE:				; CODE XREF: ROM:0000F286j
		addq.b	#4,$24(a0)
		bra.w	loc_F36E
; ---------------------------------------------------------------------------

loc_F2C6:				; DATA XREF: ROM:0000F258o
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	off_F2E2(pc,d0.w),d1
		jsr	off_F2E2(pc,d1.w)
		lea	(Ani_Obj40).l,a1
		bsr.w	AnimateSprite
		bra.w	MarkObjGone
; ---------------------------------------------------------------------------
off_F2E2:	dc.w loc_F2E6-off_F2E2	; DATA XREF: ROM:off_F2E2o
					; ROM:0000F2E4o
		dc.w loc_F30A-off_F2E2
; ---------------------------------------------------------------------------

loc_F2E6:				; DATA XREF: ROM:off_F2E2o
		subq.w	#1,$30(a0)
		bpl.s	locret_F308
		addq.b	#2,$25(a0)
		move.w	#$FF00,$10(a0)
		move.b	#1,$1C(a0)
		bchg	#0,$22(a0)
		bne.s	locret_F308
		neg.w	$10(a0)

locret_F308:				; CODE XREF: ROM:0000F2EAj
					; ROM:0000F302j
		rts
; ---------------------------------------------------------------------------

loc_F30A:				; DATA XREF: ROM:0000F2E4o
		bsr.w	SpeedToPos
		jsr	(ObjHitFloor).l
		cmpi.w	#$FFF8,d1
		blt.s	loc_F356
		cmpi.w	#$C,d1
		bge.s	loc_F356
		add.w	d1,$C(a0)
		subq.b	#1,$33(a0)
		bpl.s	locret_F354
		move.b	#$F,$33(a0)
		bsr.w	SingleObjectLoad
		bne.s	locret_F354
		move.b	#$40,0(a1) 
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	$22(a0),$22(a1)
		move.b	#2,$1C(a1)

locret_F354:				; CODE XREF: ROM:0000F328j
					; ROM:0000F334j
		rts
; ---------------------------------------------------------------------------

loc_F356:				; CODE XREF: ROM:0000F318j
					; ROM:0000F31Ej
		subq.b	#2,$25(a0)
		move.w	#$3B,$30(a0) 
		move.w	#0,$10(a0)
		move.b	#0,$1C(a0)
		rts
; ---------------------------------------------------------------------------

loc_F36E:				; CODE XREF: ROM:0000F2C2j
					; DATA XREF: ROM:0000F25Ao
		lea	(Ani_Obj40).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_F37C:				; DATA XREF: ROM:0000F25Co
		bra.w	DeleteObject
; ---------------------------------------------------------------------------
Ani_Obj40:	dc.w byte_F386-Ani_Obj40 ; DATA	XREF: ROM:0000F2D4o
					; ROM:loc_F36Eo ...
		dc.w byte_F389-Ani_Obj40
		dc.w byte_F38F-Ani_Obj40
byte_F386:	dc.b  $F,  2,$FF	; 0 ; DATA XREF: ROM:Ani_Obj40o
byte_F389:	dc.b   7,  0,  1,  0,  2,$FF; 0	; DATA XREF: ROM:0000F382o
byte_F38F:	dc.b   1,  3,  6,  3,  6,  4,  6,  4; 0	; DATA XREF: ROM:0000F384o
		dc.b   6,  4,  6,  5,$FC; 8
Map_Obj40:	dc.w word_F3AA-Map_Obj40 ; DATA	XREF: ROM:loc_F25Eo
					; ROM:Map_Obj40o ...
		dc.w word_F3CC-Map_Obj40
		dc.w word_F3EE-Map_Obj40
		dc.w word_F418-Map_Obj40
		dc.w word_F422-Map_Obj40
		dc.w word_F42C-Map_Obj40
		dc.w word_F436-Map_Obj40
word_F3AA:	dc.w 4			; DATA XREF: ROM:Map_Obj40o
		dc.w $F00D,    0,    0,$FFEC; 0
		dc.w	$C,    8,    4,$FFEC; 4
		dc.w $F801,   $C,    6,	  $C; 8
		dc.w  $808,   $E,    7,$FFF4; 12
word_F3CC:	dc.w 4			; DATA XREF: ROM:0000F39Eo
		dc.w $F10D,    0,    0,$FFEC; 0
		dc.w  $10C,    8,    4,$FFEC; 4
		dc.w $F901,   $C,    6,	  $C; 8
		dc.w  $908,  $11,    8,$FFF4; 12
word_F3EE:	dc.w 5			; DATA XREF: ROM:0000F3A0o
word_F3F0:	dc.w $F00D,    0,    0,$FFEC; 0
		dc.w	$C,  $14,   $A,$FFEC; 4
		dc.w $F801,   $C,    6,	  $C; 8
		dc.w  $804,  $18,   $C,$FFEC; 12
		dc.w  $804,  $12,    9,$FFFC; 16
word_F418:	dc.w 1			; DATA XREF: ROM:0000F3A2o
		dc.w $FA00,  $1A,   $D,	 $10; 0
word_F422:	dc.w 1			; DATA XREF: ROM:0000F3A4o
		dc.w $FA00,  $1B,   $D,	 $10; 0
word_F42C:	dc.w 1			; DATA XREF: ROM:0000F3A6o
		dc.w $FA00,  $1C,   $E,	 $10; 0
word_F436:	dc.w 0			; DATA XREF: ROM:0000F3A8o

; =============== S U B	R O U T	I N E =======================================


SolidObject:				; CODE XREF: ROM:00009584p
					; ROM:0000C6F6p ...
		lea	(v_objspace).w,a1
		moveq	#3,d6
		movem.l	d1-d4,-(sp)
		bsr.s	sub_F456
		movem.l	(sp)+,d1-d4
		lea	(v_objspace+$40).w,a1
		tst.b	1(a1)
		bpl.w	locret_F490
		addq.b	#1,d6
; End of function SolidObject


; =============== S U B	R O U T	I N E =======================================


sub_F456:				; CODE XREF: SolidObject+Ap

; FUNCTION CHUNK AT 0000F684 SIZE 0000008A BYTES

		btst	d6,$22(a0)
		beq.w	loc_F590
		move.w	d1,d2
		add.w	d2,d2
		btst	#1,$22(a1)
		bne.s	loc_F47A
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_F47A
		cmp.w	d2,d0
		bcs.s	loc_F488

loc_F47A:				; CODE XREF: sub_F456+12j sub_F456+1Ej
		bclr	#3,$22(a1)
		bclr	d6,$22(a0)
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------

loc_F488:				; CODE XREF: sub_F456+22j
		move.w	d4,d2
		bsr.w	sub_F70E
		moveq	#0,d4

locret_F490:				; CODE XREF: SolidObject+18j
		rts
; ---------------------------------------------------------------------------
		lea	(v_objspace).w,a1
		moveq	#3,d6
		movem.l	d1-d4,-(sp)
		bsr.s	loc_F4A8
		movem.l	(sp)+,d1-d4
		lea	(v_objspace+$40).w,a1
		addq.b	#1,d6

loc_F4A8:				; CODE XREF: ROM:0000E31Cp
					; ROM:0000E334p ...
		btst	d6,$22(a0)
		beq.w	loc_F598
		move.w	d1,d2
		add.w	d2,d2
		btst	#1,$22(a1)
		bne.s	loc_F4CC
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_F4CC
		cmp.w	d2,d0
		bcs.s	loc_F4DA

loc_F4CC:				; CODE XREF: sub_F456+64j sub_F456+70j
		bclr	#3,$22(a1)
		bclr	d6,$22(a0)
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------

loc_F4DA:				; CODE XREF: sub_F456+74j
		move.w	d4,d2
		bsr.w	sub_F70E
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------
		lea	(v_objspace).w,a1
		moveq	#3,d6
		movem.l	d1-d4,-(sp)
		bsr.s	loc_F4FA
		movem.l	(sp)+,d1-d4
		lea	(v_objspace+$40).w,a1
		addq.b	#1,d6

loc_F4FA:				; CODE XREF: ROM:0000E70Cp
					; ROM:0000E724p ...
		btst	d6,$22(a0)
		beq.w	loc_F536
		move.w	d1,d2
		add.w	d2,d2
		btst	#1,$22(a1)
		bne.s	loc_F51E
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_F51E
		cmp.w	d2,d0
		bcs.s	loc_F52C

loc_F51E:				; CODE XREF: sub_F456+B6j sub_F456+C2j
		bclr	#3,$22(a1)
		bclr	d6,$22(a0)
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------

loc_F52C:				; CODE XREF: sub_F456+C6j
		move.w	d4,d2
		bsr.w	sub_F748
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------

loc_F536:				; CODE XREF: sub_F456+A8j
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	loc_F668
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.w	loc_F668
		move.w	d0,d5
		btst	#0,1(a0)
		beq.s	loc_F55C
		not.w	d5
		add.w	d3,d5

loc_F55C:				; CODE XREF: sub_F456+100j
		lsr.w	#1,d5
		move.b	(a2,d5.w),d3
		sub.b	(a2),d3
		ext.w	d3
		move.w	$C(a0),d5
		sub.w	d3,d5
		move.b	$16(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	$C(a1),d3
		sub.w	d5,d3
		addq.w	#4,d3
		add.w	d2,d3
		bmi.w	loc_F668
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3
		bcc.w	loc_F668
		bra.w	loc_F5D2
; ---------------------------------------------------------------------------

loc_F590:				; CODE XREF: sub_F456+4j
		tst.b	1(a0)
		bpl.w	loc_F668

loc_F598:				; CODE XREF: sub_F456+56j
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	loc_F668
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.w	loc_F668
		move.b	$16(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	$C(a1),d3
		sub.w	$C(a0),d3
		addq.w	#4,d3
		add.w	d2,d3
		bmi.w	loc_F668
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3
		bcc.w	loc_F668

loc_F5D2:				; CODE XREF: sub_F456+136j
		tst.b	($FFFFF7C8).w
		bmi.w	loc_F668
		cmpi.b	#6,$24(a1)
		bcc.w	loc_F680
		tst.w	($FFFFFE08).w
		bne.w	loc_F680
		move.w	d0,d5
		cmp.w	d0,d1
		bcc.s	loc_F5FA
		add.w	d1,d1
		sub.w	d1,d0
		move.w	d0,d5
		neg.w	d5

loc_F5FA:				; CODE XREF: sub_F456+19Aj
		move.w	d3,d1
		cmp.w	d3,d2
		bcc.s	loc_F608
		subq.w	#4,d3
		sub.w	d4,d3
		move.w	d3,d1
		neg.w	d1

loc_F608:				; CODE XREF: sub_F456+1A8j
		cmp.w	d1,d5
		bhi.w	loc_F684
		cmpi.w	#4,d1
		bls.s	loc_F65A
		tst.w	d0
		beq.s	loc_F634
		bmi.s	loc_F622
		tst.w	$10(a1)
		bmi.s	loc_F634
		bra.s	loc_F628
; ---------------------------------------------------------------------------

loc_F622:				; CODE XREF: sub_F456+1C2j
		tst.w	$10(a1)
		bpl.s	loc_F634

loc_F628:				; CODE XREF: sub_F456+1CAj
		move.w	#0,$14(a1)
		move.w	#0,$10(a1)

loc_F634:				; CODE XREF: sub_F456+1C0j
					; sub_F456+1C8j ...
		sub.w	d0,8(a1)
		btst	#1,$22(a1)
		bne.s	loc_F65A
		move.l	d6,d4
		addq.b	#2,d4
		bset	d4,$22(a0)
		bset	#5,$22(a1)
		move.w	d6,d4
		addi.b	#$D,d4
		bset	d4,d6
		moveq	#1,d4
		rts
; ---------------------------------------------------------------------------

loc_F65A:				; CODE XREF: sub_F456+1BCj
					; sub_F456+1E8j
		bsr.s	sub_F678
		move.w	d6,d4
		addi.b	#$D,d4
		bset	d4,d6
		moveq	#1,d4
		rts
; ---------------------------------------------------------------------------

loc_F668:				; CODE XREF: sub_F456+EAj sub_F456+F4j ...
		move.l	d6,d4
		addq.b	#2,d4
		btst	d4,$22(a0)
		beq.s	loc_F680
		move.w	#1,$1C(a1)
; End of function sub_F456


; =============== S U B	R O U T	I N E =======================================


sub_F678:				; CODE XREF: sub_F456:loc_F65Ap
		move.l	d6,d4
		addq.b	#2,d4
		bclr	d4,$22(a0)

loc_F680:				; CODE XREF: sub_F456+18Aj
					; sub_F456+192j ...
		moveq	#0,d4
		rts
; End of function sub_F678

; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR sub_F456

loc_F684:				; CODE XREF: sub_F456+1B4j
		tst.w	d3
		bmi.s	loc_F690
		cmpi.w	#$10,d3
		bcs.s	loc_F6D2
		bra.s	loc_F668
; ---------------------------------------------------------------------------

loc_F690:				; CODE XREF: sub_F456+230j
		tst.w	$12(a1)
		beq.s	loc_F6B2
		bpl.s	loc_F6A6
		tst.w	d3
		bpl.s	loc_F6A6
		sub.w	d3,$C(a1)
		move.w	#0,$12(a1)

loc_F6A6:				; CODE XREF: sub_F456+240j
					; sub_F456+244j ...
		move.w	d6,d4
		addi.b	#$F,d4
		bset	d4,d6
		moveq	#$FFFFFFFE,d4
		rts
; ---------------------------------------------------------------------------

loc_F6B2:				; CODE XREF: sub_F456+23Ej
		btst	#1,$22(a1)
		bne.s	loc_F6A6
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	(KillSonic).l
		movea.l	(sp)+,a0
		move.w	d6,d4
		addi.b	#$F,d4
		bset	d4,d6
		moveq	#$FFFFFFFE,d4
		rts
; ---------------------------------------------------------------------------

loc_F6D2:				; CODE XREF: sub_F456+236j
		subq.w	#4,d3
		moveq	#0,d1
		move.b	$19(a0),d1
		move.w	d1,d2
		add.w	d2,d2
		add.w	8(a1),d1
		sub.w	8(a0),d1
		bmi.s	loc_F70A
		cmp.w	d2,d1
		bcc.s	loc_F70A
		tst.w	$12(a1)
		bmi.s	loc_F70A
		sub.w	d3,$C(a1)
		subq.w	#1,$C(a1)
		bsr.w	sub_F8F8
		move.w	d6,d4
		addi.b	#$11,d4
		bset	d4,d6
		moveq	#$FFFFFFFF,d4
		rts
; ---------------------------------------------------------------------------

loc_F70A:				; CODE XREF: sub_F456+290j
					; sub_F456+294j ...
		moveq	#0,d4
		rts
; END OF FUNCTION CHUNK	FOR sub_F456

; =============== S U B	R O U T	I N E =======================================


sub_F70E:				; CODE XREF: ROM:0000AF08p
					; sub_F456+34p	...
		move.w	$C(a0),d0
		sub.w	d3,d0
		bra.s	loc_F71E
; ---------------------------------------------------------------------------
		move.w	$C(a0),d0
		subi.w	#9,d0

loc_F71E:				; CODE XREF: sub_F70E+6j
		tst.b	($FFFFF7C8).w
		bmi.s	locret_F746
		cmpi.b	#6,$24(a1)
		bcc.s	locret_F746
		tst.w	($FFFFFE08).w
		bne.s	locret_F746
		moveq	#0,d1
		move.b	$16(a1),d1
		sub.w	d1,d0
		move.w	d0,$C(a1)
		sub.w	8(a0),d2
		sub.w	d2,8(a1)

locret_F746:				; CODE XREF: sub_F70E+14j sub_F70E+1Cj ...
		rts
; End of function sub_F70E


; =============== S U B	R O U T	I N E =======================================


sub_F748:				; CODE XREF: sub_F456+D8p sub_F7F2+34p
		btst	#3,$22(a1)
		beq.s	locret_F788
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		lsr.w	#1,d0
		btst	#0,1(a0)
		beq.s	loc_F768
		not.w	d0
		add.w	d1,d0

loc_F768:				; CODE XREF: sub_F748+1Aj
		move.b	(a2,d0.w),d1
		ext.w	d1
		move.w	$C(a0),d0
		sub.w	d1,d0
		moveq	#0,d1
		move.b	$16(a1),d1
		sub.w	d1,d0
		move.w	d0,$C(a1)
		sub.w	8(a0),d2
		sub.w	d2,8(a1)

locret_F788:				; CODE XREF: sub_F748+6j
		rts
; End of function sub_F748


; =============== S U B	R O U T	I N E =======================================


sub_F78A:				; CODE XREF: ROM:000088DAp sub_8DD6+Cp ...
		lea	(v_objspace).w,a1
		moveq	#3,d6
		movem.l	d1-d4,-(sp)
		bsr.s	sub_F7A0
		movem.l	(sp)+,d1-d4
		lea	(v_objspace+$40).w,a1
		addq.b	#1,d6
; End of function sub_F78A


; =============== S U B	R O U T	I N E =======================================


sub_F7A0:				; CODE XREF: sub_F78A+Ap
		btst	d6,$22(a0)
		beq.w	loc_F89E
		move.w	d1,d2
		add.w	d2,d2
		btst	#1,$22(a1)
		bne.s	loc_F7C4
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_F7C4
		cmp.w	d2,d0
		bcs.s	loc_F7D2

loc_F7C4:				; CODE XREF: sub_F7A0+12j sub_F7A0+1Ej
		bclr	#3,$22(a1)
		bclr	d6,$22(a0)
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------

loc_F7D2:				; CODE XREF: sub_F7A0+22j
		move.w	d4,d2
		bsr.w	sub_F70E
		moveq	#0,d4
		rts
; End of function sub_F7A0


; =============== S U B	R O U T	I N E =======================================


sub_F7DC:				; CODE XREF: sub_8CEC+Ep ROM:00014DEEj
		lea	(v_objspace).w,a1
		moveq	#3,d6
		movem.l	d1-d4,-(sp)
		bsr.s	sub_F7F2
		movem.l	(sp)+,d1-d4
		lea	(v_objspace+$40).w,a1
		addq.b	#1,d6
; End of function sub_F7DC


; =============== S U B	R O U T	I N E =======================================


sub_F7F2:				; CODE XREF: sub_F7DC+Ap

; FUNCTION CHUNK AT 0000F968 SIZE 00000038 BYTES

		btst	d6,$22(a0)
		beq.w	loc_F968
		move.w	d1,d2
		add.w	d2,d2
		btst	#1,$22(a1)
		bne.s	loc_F816
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_F816
		cmp.w	d2,d0
		bcs.s	loc_F824

loc_F816:				; CODE XREF: sub_F7F2+12j sub_F7F2+1Ej
		bclr	#3,$22(a1)
		bclr	d6,$22(a0)
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------

loc_F824:				; CODE XREF: sub_F7F2+22j
		move.w	d4,d2
		bsr.w	sub_F748
		moveq	#0,d4
		rts
; End of function sub_F7F2


; =============== S U B	R O U T	I N E =======================================


sub_F82E:				; CODE XREF: ROM:000083C2p
		lea	(v_objspace).w,a1
		moveq	#3,d6
		movem.l	d1-d4,-(sp)
		bsr.s	sub_F844
		movem.l	(sp)+,d1-d4
		lea	(v_objspace+$40).w,a1
		addq.b	#1,d6
; End of function sub_F82E


; =============== S U B	R O U T	I N E =======================================


sub_F844:				; CODE XREF: sub_F82E+Ap

; FUNCTION CHUNK AT 0000F9A0 SIZE 00000028 BYTES

		btst	d6,$22(a0)
		beq.w	loc_F9A0
		move.w	d1,d2
		add.w	d2,d2
		btst	#1,$22(a1)
		bne.s	loc_F868
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_F868
		cmp.w	d2,d0
		bcs.s	loc_F876

loc_F868:				; CODE XREF: sub_F844+12j sub_F844+1Ej
		bclr	#3,$22(a1)
		bclr	d6,$22(a0)
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------

loc_F876:				; CODE XREF: sub_F844+22j
		move.w	d4,d2
		bsr.w	sub_F70E
		moveq	#0,d4
		rts
; End of function sub_F844


; =============== S U B	R O U T	I N E =======================================


sub_F880:				; CODE XREF: sub_7DDA+66p
		tst.w	$12(a1)
		bmi.w	locret_F966
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	locret_F966
		cmp.w	d2,d0
		bcc.w	locret_F966
		bra.s	loc_F8BC
; ---------------------------------------------------------------------------

loc_F89E:				; CODE XREF: sub_F7A0+4j
		tst.w	$12(a1)
		bmi.w	locret_F966
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	locret_F966
		add.w	d1,d1
		cmp.w	d1,d0
		bcc.w	locret_F966

loc_F8BC:				; CODE XREF: sub_F880+1Cj
		move.w	$C(a0),d0
		sub.w	d3,d0

loc_F8C2:				; CODE XREF: sub_F7F2+1AAj
					; sub_F844+180j
		move.w	$C(a1),d2
		move.b	$16(a1),d1
		ext.w	d1
		add.w	d2,d1
		addq.w	#4,d1
		sub.w	d1,d0
		bhi.w	locret_F966
		cmpi.w	#$FFF0,d0
		bcs.w	locret_F966
		tst.b	($FFFFF7C8).w
		bmi.w	locret_F966
		cmpi.b	#6,$24(a1)
		bcc.w	locret_F966
		add.w	d0,d2
		addq.w	#3,d2
		move.w	d2,$C(a1)
; End of function sub_F880


; =============== S U B	R O U T	I N E =======================================


sub_F8F8:				; CODE XREF: ROM:0000AF56p
					; sub_F456+2A4p ...
		btst	#3,$22(a1)
		beq.s	loc_F916
		moveq	#0,d0
		move.b	$3D(a1),d0
		lsl.w	#6,d0
		addi.l	#v_objspace,d0
		movea.l	d0,a3
		bclr	#3,$22(a3)

loc_F916:				; CODE XREF: sub_F8F8+6j
		move.w	a0,d0
		subi.w	#$B000,d0
		lsr.w	#6,d0
		andi.w	#$7F,d0	
		move.b	d0,$3D(a1)
		move.b	#0,$26(a1)
		move.w	#0,$12(a1)
		move.w	$10(a1),$14(a1)
		btst	#1,$22(a1)
		beq.s	loc_F95C
		move.l	a0,-(sp)
		movea.l	a1,a0
		move.w	a0,d1
		subi.w	#$B000,d1
		bne.s	loc_F954
		jsr	(Sonic_ResetOnFloor).l
		bra.s	loc_F95A
; ---------------------------------------------------------------------------

loc_F954:				; CODE XREF: sub_F8F8+52j
		jsr	(Tails_ResetTailsOnFloor).l

loc_F95A:				; CODE XREF: sub_F8F8+5Aj
		movea.l	(sp)+,a0

loc_F95C:				; CODE XREF: sub_F8F8+46j
		bset	#3,$22(a1)
		bset	d6,$22(a0)

locret_F966:				; CODE XREF: sub_F880+4j sub_F880+12j	...
		rts
; End of function sub_F8F8

; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR sub_F7F2

loc_F968:				; CODE XREF: sub_F7F2+4j
		tst.w	$12(a1)
		bmi.w	locret_F966
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	locret_F966
		add.w	d1,d1
		cmp.w	d1,d0
		bcc.s	locret_F966
		btst	#0,1(a0)
		beq.s	loc_F98E
		not.w	d0
		add.w	d1,d0

loc_F98E:				; CODE XREF: sub_F7F2+196j
		lsr.w	#1,d0
		move.b	(a2,d0.w),d3
		ext.w	d3
		move.w	$C(a0),d0
		sub.w	d3,d0
		bra.w	loc_F8C2
; END OF FUNCTION CHUNK	FOR sub_F7F2
; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR sub_F844

loc_F9A0:				; CODE XREF: sub_F844+4j
		tst.w	$12(a1)
		bmi.w	locret_F966
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	locret_F966
		add.w	d1,d1
		cmp.w	d1,d0
		bcc.w	locret_F966
		move.w	$C(a0),d0
		sub.w	d3,d0
		bra.w	loc_F8C2
; END OF FUNCTION CHUNK	FOR sub_F844

; =============== S U B	R O U T	I N E =======================================


sub_F9C8:				; CODE XREF: ROM:0000AEEAp
		move.w	d1,d2
		add.w	d2,d2
		lea	(v_objspace).w,a1
		btst	#1,$22(a1)
		bne.s	loc_F9E8
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_F9E8
		cmp.w	d2,d0
		bcs.s	locret_F9FA

loc_F9E8:				; CODE XREF: sub_F9C8+Ej sub_F9C8+1Aj
		bclr	#3,$22(a1)
		move.b	#2,$24(a0)
		bclr	#3,$22(a0)

locret_F9FA:				; CODE XREF: sub_F9C8+1Ej
		rts
; End of function sub_F9C8

; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 01 - Sonic
;----------------------------------------------------

Obj01:					; DATA XREF: ROM:Obj_Indexo
		tst.w	($FFFFFE08).w
		beq.s	Obj01_Normal
		jmp	DebugMode
; ---------------------------------------------------------------------------

Obj01_Normal:				; CODE XREF: ROM:0000FA00j
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj01_Index(pc,d0.w),d1
		jmp	Obj01_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj01_Index:	dc.w Obj01_Main-Obj01_Index ; DATA XREF: ROM:Obj01_Indexo
					; ROM:0000FA18o ...
		dc.w Obj01_Control-Obj01_Index
		dc.w Obj01_Hurt-Obj01_Index
		dc.w Obj01_Death-Obj01_Index
		dc.w Obj01_ResetLevel-Obj01_Index
; ---------------------------------------------------------------------------

Obj01_Main:				; DATA XREF: ROM:Obj01_Indexo
		addq.b	#2,$24(a0)
		move.b	#$13,$16(a0)
		move.b	#9,$17(a0)
		move.l	#Map_Sonic,4(a0)
		move.w	#$780,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#2,$18(a0)
		move.b	#$18,$19(a0)
		move.b	#4,1(a0)
		move.w	#$600,($FFFFF760).w
		move.w	#$C,($FFFFF762).w
		move.w	#$80,($FFFFF764).w 
		move.b	#$C,$3E(a0)
		move.b	#$D,$3F(a0)
		move.b	#0,$2C(a0)
		move.b	#4,$2D(a0)
		move.w	#0,($FFFFEED2).w
		move.w	#$3F,d2	

loc_FA88:				; CODE XREF: ROM:0000FA92j
		bsr.w	CopySonicMovesForTails
		move.w	#0,(a1,d0.w)
		dbf	d2,loc_FA88

Obj01_Control:				; DATA XREF: ROM:0000FA18o
		tst.w	($FFFFFFFA).w
		beq.s	loc_FAB0
		btst	#4,(v_jpadpress1).w
		beq.s	loc_FAB0
		move.w	#1,($FFFFFE08).w
		clr.b	($FFFFF7CC).w
		rts
; ---------------------------------------------------------------------------

loc_FAB0:				; CODE XREF: ROM:0000FA9Aj
					; ROM:0000FAA2j
		tst.b	($FFFFF7CC).w
		bne.s	loc_FABC
		move.w	(v_jpadhold1).w,(v_jpadhold2).w

loc_FABC:				; CODE XREF: ROM:0000FAB4j
		btst	#0,($FFFFF7C8).w
		bne.s	Obj01_ControlsLock
		moveq	#0,d0
		move.b	$22(a0),d0
		andi.w	#6,d0
		move.w	Obj01_Modes(pc,d0.w),d1
		jsr	Obj01_Modes(pc,d1.w)

Obj01_ControlsLock:			; CODE XREF: ROM:0000FAC2j
		bsr.s	Sonic_Display
		bsr.w	CopySonicMovesForTails
		bsr.w	Sonic_Water
		move.b	($FFFFF768).w,$36(a0)
		move.b	($FFFFF76A).w,$37(a0)
		tst.b	($FFFFF7C7).w
		beq.s	loc_FAFE
		tst.b	$1C(a0)
		bne.s	loc_FAFE
		move.b	$1D(a0),$1C(a0)

loc_FAFE:				; CODE XREF: ROM:0000FAF0j
					; ROM:0000FAF6j
		bsr.w	Sonic_Animate
		tst.b	($FFFFF7C8).w
		bmi.s	loc_FB0E
		jsr	(TouchResponse).l

loc_FB0E:				; CODE XREF: ROM:0000FB06j
		bra.w	LoadSonicDynPLC
; ---------------------------------------------------------------------------
Obj01_Modes:	dc.w Obj01_MdNormal-Obj01_Modes	; DATA XREF: ROM:Obj01_Modeso
					; ROM:0000FB14o ...
		dc.w Obj01_MdJump-Obj01_Modes
		dc.w Obj01_MdRoll-Obj01_Modes
		dc.w Obj01_MdJump2-Obj01_Modes
MusicList_Sonic:dc.b $81,$82,$83,$84,$85,$86; 0	; DATA XREF: Sonic_Display:loc_FB66t

; =============== S U B	R O U T	I N E =======================================


Sonic_Display:				; CODE XREF: ROM:Obj01_ControlsLockp
		move.w	$30(a0),d0
		beq.s	loc_FB2E
		subq.w	#1,$30(a0)
		lsr.w	#3,d0
		bcc.s	loc_FB34

loc_FB2E:				; CODE XREF: Sonic_Display+4j
		jsr	(DisplaySprite).l

loc_FB34:				; CODE XREF: Sonic_Display+Cj
		tst.b	($FFFFFE2D).w
		beq.s	loc_FB7A
		tst.w	$32(a0)
		beq.s	loc_FB7A
		bra.s	loc_FB7A
; ---------------------------------------------------------------------------
		subq.w	#1,$32(a0)
		bne.s	loc_FB7A
		tst.b	($FFFFF7AA).w
		bne.s	loc_FB74
		cmpi.w	#$C,($FFFFFE14).w
		bcs.s	loc_FB74
		moveq	#0,d0
		move.b	(v_zone).w,d0
		cmpi.w	#$103,(v_zone).w
		bne.s	loc_FB66
		moveq	#5,d0

loc_FB66:				; CODE XREF: Sonic_Display+42j
		lea	MusicList_Sonic(pc),a1
		move.b	(a1,d0.w),d0
		jsr	(PlaySound).l

loc_FB74:				; CODE XREF: Sonic_Display+2Cj
					; Sonic_Display+34j
		move.b	#0,($FFFFFE2D).w

loc_FB7A:				; CODE XREF: Sonic_Display+18j
					; Sonic_Display+1Ej ...
		tst.b	($FFFFFE2E).w
		beq.s	locret_FBAE
		tst.w	$34(a0)
		beq.s	locret_FBAE
		subq.w	#1,$34(a0)
		bne.s	locret_FBAE
		move.w	#$600,($FFFFF760).w
		move.w	#$C,($FFFFF762).w
		move.w	#$80,($FFFFF764).w 
		move.b	#0,($FFFFFE2E).w
		move.w	#bgm_Slowdown,d0	; "?"
		jmp	(PlaySound).l
; ---------------------------------------------------------------------------

locret_FBAE:				; CODE XREF: Sonic_Display+5Ej
					; Sonic_Display+64j ...
		rts
; End of function Sonic_Display


; =============== S U B	R O U T	I N E =======================================


CopySonicMovesForTails:			; CODE XREF: ROM:loc_FA88p
					; ROM:0000FAD8p ...
		move.w	($FFFFEED2).w,d0
		lea	(v_tracktails).w,a1
		lea	(a1,d0.w),a1
		move.w	8(a0),(a1)+
		move.w	$C(a0),(a1)+
		addq.b	#4,($FFFFEED3).w
		lea	(v_tracksonic).w,a1
		move.w	(v_jpadhold1).w,(a1,d0.w)
		rts
; End of function CopySonicMovesForTails

; ---------------------------------------------------------------------------
;----------------------------------------------------
; unused subroutine for	recording Sonic's position
;----------------------------------------------------

Unused_PosRecord:
		move.w	($FFFFEEE0).w,d0
		subq.b	#4,d0
		lea	(v_recordsonic).w,a1
		lea	(a1,d0.w),a2
		move.w	8(a0),d1
		swap	d1
		move.w	$C(a0),d1
		cmp.l	(a2),d1
		beq.s	locret_FC02
		addq.b	#4,d0
		lea	(a1,d0.w),a2
		move.w	8(a0),(a2)+
		move.w	$C(a0),(a2)
		addq.b	#4,($FFFFEEE1).w

locret_FC02:				; CODE XREF: ROM:0000FBEEj
		rts

; =============== S U B	R O U T	I N E =======================================


Sonic_Water:				; CODE XREF: ROM:0000FADCp
		tst.b	($FFFFF730).w
		bne.s	Obj01_InLevelWithWater

locret_FC0A:				; CODE XREF: Sonic_Water+18j
					; Sonic_Water+48j ...
		rts
; ---------------------------------------------------------------------------

Obj01_InLevelWithWater:			; CODE XREF: Sonic_Water+4j
		move.w	($FFFFF646).w,d0
		cmp.w	$C(a0),d0
		bge.s	Obj01_NotInWater
		bset	#6,$22(a0)
		bne.s	locret_FC0A
		bsr.w	ResumeMusic
		move.b	#$A,(v_objspace+$340).w
		move.b	#$81,(v_objspace+$368).w
		move.w	#$300,($FFFFF760).w
		move.w	#6,($FFFFF762).w
		move.w	#$40,($FFFFF764).w 
		asr	$10(a0)
		asr	$12(a0)
		asr	$12(a0)
		beq.s	locret_FC0A
		move.b	#8,(v_objspace+$300).w
		move.w	#sfx_Splash,d0	; "?"
		jmp	(PlaySound_Special).l
; ---------------------------------------------------------------------------

Obj01_NotInWater:			; CODE XREF: Sonic_Water+10j
		bclr	#6,$22(a0)
		beq.s	locret_FC0A
		bsr.w	ResumeMusic
		move.w	#$600,($FFFFF760).w
		move.w	#$C,($FFFFF762).w
		move.w	#$80,($FFFFF764).w 
		asl	$12(a0)
		beq.w	locret_FC0A
		move.b	#8,(v_objspace+$300).w
		cmpi.w	#$F000,$12(a0)
		bgt.s	loc_FC98
		move.w	#$F000,$12(a0)

loc_FC98:				; CODE XREF: Sonic_Water+8Cj
		move.w	#sfx_Splash,d0	; "?"
		jmp	(PlaySound_Special).l
; End of function Sonic_Water

; ---------------------------------------------------------------------------

Obj01_MdNormal:				; DATA XREF: ROM:Obj01_Modeso
		bsr.w	Sonic_Spindash
		bsr.w	Sonic_Jump
		bsr.w	Sonic_SlopeResist
		bsr.w	Sonic_Move
		bsr.w	Sonic_Roll
		bsr.w	Sonic_LevelBoundaries
		jsr	SpeedToPos
		bsr.w	Sonic_AnglePos
		bsr.w	Sonic_SlopeRepel
		rts
; ---------------------------------------------------------------------------

Obj01_MdJump:				; DATA XREF: ROM:0000FB14o
		bsr.w	Sonic_JumpHeight
		bsr.w	Sonic_ChgJumpDir
		bsr.w	Sonic_LevelBoundaries
		jsr	ObjectFall
		btst	#6,$22(a0)
		beq.s	loc_FCEA
		subi.w	#$28,$12(a0) 

loc_FCEA:				; CODE XREF: ROM:0000FCE2j
		bsr.w	Sonic_JumpAngle
		bsr.w	Sonic_Floor
		rts
; ---------------------------------------------------------------------------

Obj01_MdRoll:				; DATA XREF: ROM:0000FB16o
		bsr.w	Sonic_Jump
		bsr.w	Sonic_RollRepel
		bsr.w	Sonic_RollSpeed
		bsr.w	Sonic_LevelBoundaries
		jsr	SpeedToPos
		bsr.w	Sonic_AnglePos
		bsr.w	Sonic_SlopeRepel
		rts
; ---------------------------------------------------------------------------

Obj01_MdJump2:				; DATA XREF: ROM:0000FB18o
		bsr.w	Sonic_JumpHeight
		bsr.w	Sonic_ChgJumpDir
		bsr.w	Sonic_LevelBoundaries
		jsr	ObjectFall
		btst	#6,$22(a0)
		beq.s	loc_FD34
		subi.w	#$28,$12(a0) 

loc_FD34:				; CODE XREF: ROM:0000FD2Cj
		bsr.w	Sonic_JumpAngle
		bsr.w	Sonic_Floor
		rts

; =============== S U B	R O U T	I N E =======================================


Sonic_Move:				; CODE XREF: ROM:0000FCAEp
		move.w	($FFFFF760).w,d6
		move.w	($FFFFF762).w,d5
		move.w	($FFFFF764).w,d4
		tst.b	($FFFFF7CA).w
		bne.w	loc_FE58
		tst.w	$2E(a0)
		bne.w	loc_FE2C
		btst	#2,(v_jpadhold2).w
		beq.s	loc_FD66
		bsr.w	Sonic_MoveLeft

loc_FD66:				; CODE XREF: Sonic_Move+22j
		btst	#3,(v_jpadhold2).w
		beq.s	loc_FD72
		bsr.w	Sonic_MoveRight

loc_FD72:				; CODE XREF: Sonic_Move+2Ej
		move.b	$26(a0),d0
		addi.b	#$20,d0	
		andi.b	#$C0,d0
		bne.w	loc_FE2C
		tst.w	$14(a0)
		bne.w	loc_FE2C
		bclr	#5,$22(a0)
		cmpi.b	#$B,$1C(a0)
		beq.s	loc_FD9E
		move.b	#5,$1C(a0)

loc_FD9E:				; CODE XREF: Sonic_Move+58j
		btst	#3,$22(a0)
		beq.s	Sonic_Balance
		moveq	#0,d0
		move.b	$3D(a0),d0
		lsl.w	#6,d0
		lea	(v_objspace).w,a1
		lea	(a1,d0.w),a1
		tst.b	$22(a1)
		bmi.s	Sonic_LookUp
		moveq	#0,d1
		move.b	$19(a1),d1
		move.w	d1,d2
		add.w	d2,d2
		subq.w	#4,d2
		add.w	8(a0),d1
		sub.w	8(a1),d1
		cmpi.w	#4,d1
		blt.s	loc_FE00
		cmp.w	d2,d1
		bge.s	loc_FDF0
		bra.s	Sonic_LookUp
; ---------------------------------------------------------------------------

Sonic_Balance:				; CODE XREF: Sonic_Move+66j
		jsr	Sonic_HitFloor
		cmpi.w	#$C,d1
		blt.s	Sonic_LookUp
		cmpi.b	#3,$36(a0)
		bne.s	loc_FDF8

loc_FDF0:				; CODE XREF: Sonic_Move+9Aj
		bclr	#0,$22(a0)
		bra.s	loc_FE06
; ---------------------------------------------------------------------------

loc_FDF8:				; CODE XREF: Sonic_Move+B0j
		cmpi.b	#3,$37(a0)
		bne.s	Sonic_LookUp

loc_FE00:				; CODE XREF: Sonic_Move+96j
		bset	#0,$22(a0)

loc_FE06:				; CODE XREF: Sonic_Move+B8j
		move.b	#6,$1C(a0)
		bra.s	loc_FE2C
; ---------------------------------------------------------------------------

Sonic_LookUp:				; CODE XREF: Sonic_Move+7Cj
					; Sonic_Move+9Cj ...
		btst	#0,(v_jpadhold2).w
		beq.s	Sonic_Duck
		move.b	#7,$1C(a0)
		bra.s	loc_FE2C
; ---------------------------------------------------------------------------

Sonic_Duck:				; CODE XREF: Sonic_Move+D6j
		btst	#1,(v_jpadhold2).w
		beq.s	loc_FE2C
		move.b	#8,$1C(a0)

loc_FE2C:				; CODE XREF: Sonic_Move+18j
					; Sonic_Move+40j ...
		move.b	(v_jpadhold2).w,d0
		andi.b	#$C,d0
		bne.s	loc_FE58
		move.w	$14(a0),d0
		beq.s	loc_FE58
		bmi.s	loc_FE4C
		sub.w	d5,d0
		bcc.s	loc_FE46
		move.w	#0,d0

loc_FE46:				; CODE XREF: Sonic_Move+102j
		move.w	d0,$14(a0)
		bra.s	loc_FE58
; ---------------------------------------------------------------------------

loc_FE4C:				; CODE XREF: Sonic_Move+FEj
		add.w	d5,d0
		bcc.s	loc_FE54
		move.w	#0,d0

loc_FE54:				; CODE XREF: Sonic_Move+110j
		move.w	d0,$14(a0)

loc_FE58:				; CODE XREF: Sonic_Move+10j
					; Sonic_Move+F6j ...
		move.b	$26(a0),d0
		jsr	(CalcSine).l
		muls.w	$14(a0),d1
		asr.l	#8,d1
		move.w	d1,$10(a0)
		muls.w	$14(a0),d0
		asr.l	#8,d0
		move.w	d0,$12(a0)

loc_FE76:				; CODE XREF: Sonic_RollSpeed+AEj
		move.b	$26(a0),d0
		addi.b	#$40,d0	
		bmi.s	locret_FEF6
		move.b	#$40,d1	
		tst.w	$14(a0)
		beq.s	locret_FEF6
		bmi.s	loc_FE8E
		neg.w	d1

loc_FE8E:				; CODE XREF: Sonic_Move+14Cj
		move.b	$26(a0),d0
		add.b	d1,d0
		move.w	d0,-(sp)
		bsr.w	Sonic_WalkSpeed
		move.w	(sp)+,d0
		tst.w	d1
		bpl.s	locret_FEF6
		asl.w	#8,d1
		addi.b	#$20,d0	
		andi.b	#$C0,d0
		beq.s	loc_FEF2
		cmpi.b	#$40,d0	
		beq.s	loc_FED8
		cmpi.b	#$80,d0
		beq.s	loc_FED2
		cmpi.w	#$600,$10(a0)
		bge.s	Sonic_WallRecoil
		add.w	d1,$10(a0)
		bset	#5,$22(a0)
		move.w	#0,$14(a0)
		rts
; ---------------------------------------------------------------------------

loc_FED2:				; CODE XREF: Sonic_Move+178j
		sub.w	d1,$12(a0)
		rts
; ---------------------------------------------------------------------------

loc_FED8:				; CODE XREF: Sonic_Move+172j
		cmpi.w	#$FA00,$10(a0)
		ble.s	Sonic_WallRecoil
		sub.w	d1,$10(a0)
		bset	#5,$22(a0)
		move.w	#0,$14(a0)
		rts
; ---------------------------------------------------------------------------

loc_FEF2:				; CODE XREF: Sonic_Move+16Cj
		add.w	d1,$12(a0)

locret_FEF6:				; CODE XREF: Sonic_Move+140j
					; Sonic_Move+14Aj ...
		rts
; ---------------------------------------------------------------------------

Sonic_WallRecoil:			; CODE XREF: Sonic_Move+180j
					; Sonic_Move+1A0j
		move.b	#4,$24(a0)
		bsr.w	Sonic_ResetOnFloor
		bset	#1,$22(a0)
		move.w	#$FE00,d0
		tst.w	$10(a0)
		bpl.s	Sonic_WallRecoil_Right
		neg.w	d0

Sonic_WallRecoil_Right:			; CODE XREF: Sonic_Move+1D2j
		move.w	d0,$10(a0)
		move.w	#$FC00,$12(a0)
		move.w	#0,$14(a0)
		move.b	#$A,$1C(a0)
		move.b	#1,$25(a0)
		move.w	#sfx_Death,d0	; "?"
		jsr	(PlaySound_Special).l
		rts
; End of function Sonic_Move


; =============== S U B	R O U T	I N E =======================================


Sonic_MoveLeft:				; CODE XREF: Sonic_Move+24p
		move.w	$14(a0),d0
		beq.s	loc_FF44
		bpl.s	loc_FF70

loc_FF44:				; CODE XREF: Sonic_MoveLeft+4j
		bset	#0,$22(a0)
		bne.s	loc_FF58
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)

loc_FF58:				; CODE XREF: Sonic_MoveLeft+Ej
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_FF64
		move.w	d1,d0

loc_FF64:				; CODE XREF: Sonic_MoveLeft+24j
		move.w	d0,$14(a0)
		move.b	#0,$1C(a0)
		rts
; ---------------------------------------------------------------------------

loc_FF70:				; CODE XREF: Sonic_MoveLeft+6j
		sub.w	d4,d0
		bcc.s	loc_FF78
		move.w	#$FF80,d0

loc_FF78:				; CODE XREF: Sonic_MoveLeft+36j
		move.w	d0,$14(a0)
		move.b	$26(a0),d0
		addi.b	#$20,d0	
		andi.b	#$C0,d0
		bne.s	locret_FFA6
		cmpi.w	#$400,d0
		blt.s	locret_FFA6
		move.b	#$D,$1C(a0)
		bclr	#0,$22(a0)
		move.w	#sfx_Skid,d0	; "?"
		jsr	(PlaySound_Special).l

locret_FFA6:				; CODE XREF: Sonic_MoveLeft+4Cj
					; Sonic_MoveLeft+52j
		rts
; End of function Sonic_MoveLeft


; =============== S U B	R O U T	I N E =======================================


Sonic_MoveRight:			; CODE XREF: Sonic_Move+30p
		move.w	$14(a0),d0
		bmi.s	loc_FFD6
		bclr	#0,$22(a0)
		beq.s	loc_FFC2
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)

loc_FFC2:				; CODE XREF: Sonic_MoveRight+Cj
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s	loc_FFCA
		move.w	d6,d0

loc_FFCA:				; CODE XREF: Sonic_MoveRight+1Ej
		move.w	d0,$14(a0)
		move.b	#0,$1C(a0)
		rts
; ---------------------------------------------------------------------------

loc_FFD6:				; CODE XREF: Sonic_MoveRight+4j
		add.w	d4,d0
		bcc.s	loc_FFDE
		move.w	#$80,d0	

loc_FFDE:				; CODE XREF: Sonic_MoveRight+30j
		move.w	d0,$14(a0)
		move.b	$26(a0),d0
		addi.b	#$20,d0	
		andi.b	#$C0,d0
		bne.s	locret_1000C
		cmpi.w	#$FC00,d0
		bgt.s	locret_1000C
		move.b	#$D,$1C(a0)

loc_FFFC:
		bset	#0,$22(a0)
		move.w	#sfx_Skid,d0	; "?"

loc_10006:
		jsr	(PlaySound_Special).l

locret_1000C:				; CODE XREF: Sonic_MoveRight+46j
					; Sonic_MoveRight+4Cj
		rts
; End of function Sonic_MoveRight


; =============== S U B	R O U T	I N E =======================================


Sonic_RollSpeed:			; CODE XREF: ROM:0000FCFCp
		move.w	($FFFFF760).w,d6
		asl.w	#1,d6
		move.w	($FFFFF762).w,d5
		asr.w	#1,d5
		move.w	($FFFFF764).w,d4
		asr.w	#2,d4
		tst.b	($FFFFF7CA).w
		bne.w	loc_1008A
		tst.w	$2E(a0)
		bne.s	loc_10046
		btst	#2,(v_jpadhold2).w
		beq.s	loc_1003A
		bsr.w	Sonic_RollLeft

loc_1003A:				; CODE XREF: Sonic_RollSpeed+26j
		btst	#3,(v_jpadhold2).w
		beq.s	loc_10046
		bsr.w	Sonic_RollRight

loc_10046:				; CODE XREF: Sonic_RollSpeed+1Ej
					; Sonic_RollSpeed+32j
		move.w	$14(a0),d0
		beq.s	loc_10068
		bmi.s	loc_1005C
		sub.w	d5,d0
		bcc.s	loc_10056
		move.w	#0,d0

loc_10056:				; CODE XREF: Sonic_RollSpeed+42j
		move.w	d0,$14(a0)
		bra.s	loc_10068
; ---------------------------------------------------------------------------

loc_1005C:				; CODE XREF: Sonic_RollSpeed+3Ej
		add.w	d5,d0
		bcc.s	loc_10064
		move.w	#0,d0

loc_10064:				; CODE XREF: Sonic_RollSpeed+50j
		move.w	d0,$14(a0)

loc_10068:				; CODE XREF: Sonic_RollSpeed+3Cj
					; Sonic_RollSpeed+4Cj
		tst.w	$14(a0)
		bne.s	loc_1008A
		bclr	#2,$22(a0)
		move.b	#$13,$16(a0)
		move.b	#9,$17(a0)
		move.b	#5,$1C(a0)
		subq.w	#5,$C(a0)

loc_1008A:				; CODE XREF: Sonic_RollSpeed+16j
					; Sonic_RollSpeed+5Ej
		move.b	$26(a0),d0
		jsr	(CalcSine).l
		muls.w	$14(a0),d0
		asr.l	#8,d0
		move.w	d0,$12(a0)
		muls.w	$14(a0),d1
		asr.l	#8,d1
		cmpi.w	#$1000,d1
		ble.s	loc_100AE
		move.w	#$1000,d1

loc_100AE:				; CODE XREF: Sonic_RollSpeed+9Aj
		cmpi.w	#$F000,d1
		bge.s	loc_100B8
		move.w	#$F000,d1

loc_100B8:				; CODE XREF: Sonic_RollSpeed+A4j
		move.w	d1,$10(a0)
		bra.w	loc_FE76
; End of function Sonic_RollSpeed


; =============== S U B	R O U T	I N E =======================================


Sonic_RollLeft:				; CODE XREF: Sonic_RollSpeed+28p
		move.w	$14(a0),d0
		beq.s	loc_100C8
		bpl.s	loc_100D6

loc_100C8:				; CODE XREF: Sonic_RollLeft+4j
		bset	#0,$22(a0)
		move.b	#2,$1C(a0)
		rts
; ---------------------------------------------------------------------------

loc_100D6:				; CODE XREF: Sonic_RollLeft+6j
		sub.w	d4,d0
		bcc.s	loc_100DE
		move.w	#$FF80,d0

loc_100DE:				; CODE XREF: Sonic_RollLeft+18j
		move.w	d0,$14(a0)
		rts
; End of function Sonic_RollLeft


; =============== S U B	R O U T	I N E =======================================


Sonic_RollRight:			; CODE XREF: Sonic_RollSpeed+34p
		move.w	$14(a0),d0
		bmi.s	loc_100F8
		bclr	#0,$22(a0)
		move.b	#2,$1C(a0)
		rts
; ---------------------------------------------------------------------------

loc_100F8:				; CODE XREF: Sonic_RollRight+4j
		add.w	d4,d0
		bcc.s	loc_10100
		move.w	#$80,d0	

loc_10100:				; CODE XREF: Sonic_RollRight+16j
		move.w	d0,$14(a0)
		rts
; End of function Sonic_RollRight


; =============== S U B	R O U T	I N E =======================================


Sonic_ChgJumpDir:			; CODE XREF: ROM:0000FCCEp
					; ROM:0000FD18p
		move.w	($FFFFF760).w,d6
		move.w	($FFFFF762).w,d5
		asl.w	#1,d5
		btst	#4,$22(a0)
		bne.s	loc_10150
		move.w	$10(a0),d0
		btst	#2,(v_jpadhold2).w
		beq.s	loc_10136
		bset	#0,$22(a0)
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_10136
		move.w	d1,d0

loc_10136:				; CODE XREF: Sonic_ChgJumpDir+1Cj
					; Sonic_ChgJumpDir+2Cj
		btst	#3,(v_jpadhold2).w
		beq.s	loc_1014C
		bclr	#0,$22(a0)
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s	loc_1014C
		move.w	d6,d0

loc_1014C:				; CODE XREF: Sonic_ChgJumpDir+36j
					; Sonic_ChgJumpDir+42j
		move.w	d0,$10(a0)

loc_10150:				; CODE XREF: Sonic_ChgJumpDir+10j
		cmpi.w	#$60,($FFFFEED8).w 
		beq.s	loc_10162
		bcc.s	loc_1015E
		addq.w	#4,($FFFFEED8).w

loc_1015E:				; CODE XREF: Sonic_ChgJumpDir+52j
		subq.w	#2,($FFFFEED8).w

loc_10162:				; CODE XREF: Sonic_ChgJumpDir+50j
		cmpi.w	#$FC00,$12(a0)
		bcs.s	locret_10190
		move.w	$10(a0),d0
		move.w	d0,d1
		asr.w	#5,d1
		beq.s	locret_10190
		bmi.s	loc_10184
		sub.w	d1,d0
		bcc.s	loc_1017E
		move.w	#0,d0

loc_1017E:				; CODE XREF: Sonic_ChgJumpDir+72j
		move.w	d0,$10(a0)
		rts
; ---------------------------------------------------------------------------

loc_10184:				; CODE XREF: Sonic_ChgJumpDir+6Ej
		sub.w	d1,d0
		bcs.s	loc_1018C
		move.w	#0,d0

loc_1018C:				; CODE XREF: Sonic_ChgJumpDir+80j
		move.w	d0,$10(a0)

locret_10190:				; CODE XREF: Sonic_ChgJumpDir+62j
					; Sonic_ChgJumpDir+6Cj
		rts
; End of function Sonic_ChgJumpDir


; =============== S U B	R O U T	I N E =======================================


Sonic_LevelBoundaries:			; CODE XREF: ROM:0000FCB6p
					; ROM:0000FCD2p ...

; FUNCTION CHUNK AT 00010C38 SIZE 00000006 BYTES

		move.l	8(a0),d1
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d1
		swap	d1
		move.w	($FFFFEEC8).w,d0
		addi.w	#$10,d0
		cmp.w	d1,d0
		bhi.s	loc_101FA
		move.w	($FFFFEECA).w,d0
		addi.w	#$128,d0
		tst.b	($FFFFF7AA).w
		bne.s	loc_101C0
		addi.w	#$40,d0	

loc_101C0:				; CODE XREF: Sonic_LevelBoundaries+28j
		cmp.w	d1,d0
		bls.s	loc_101FA

loc_101C4:				; CODE XREF: Sonic_LevelBoundaries+7Ej
		move.w	($FFFFEECE).w,d0
		addi.w	#$E0,d0	
		cmp.w	$C(a0),d0
		blt.s	loc_101D4
		rts
; ---------------------------------------------------------------------------

loc_101D4:				; CODE XREF: Sonic_LevelBoundaries+3Ej
		cmpi.w	#$501,(v_zone).w
		bne.w	j_KillSonic
		cmpi.w	#$2000,(v_objspace+8).w
                bcs.w	j_KillSonic
		clr.b	($FFFFFE30).w
		move.w	#1,($FFFFFE02).w
		move.w	#$103,(v_zone).w
		rts
; ---------------------------------------------------------------------------

loc_101FA:				; CODE XREF: Sonic_LevelBoundaries+1Aj
					; Sonic_LevelBoundaries+30j
		move.w	d0,8(a0)
		move.w	#0,$A(a0)
		move.w	#0,$10(a0)
		move.w	#0,$14(a0)
		bra.s	loc_101C4
; End of function Sonic_LevelBoundaries


; =============== S U B	R O U T	I N E =======================================


Sonic_Roll:				; CODE XREF: ROM:0000FCB2p
		tst.b	($FFFFF7CA).w
		bne.s	Obj01_NoRoll
		move.w	$14(a0),d0
		bpl.s	loc_10220
		neg.w	d0

loc_10220:				; CODE XREF: Sonic_Roll+Aj
		cmpi.w	#$80,d0	
		bcs.s	Obj01_NoRoll
		move.b	(v_jpadhold2).w,d0
		andi.b	#$C,d0
		bne.s	Obj01_NoRoll
		btst	#1,(v_jpadhold2).w
		bne.s	loc_1023A

Obj01_NoRoll:				; CODE XREF: Sonic_Roll+4j
					; Sonic_Roll+12j ...
		rts
; ---------------------------------------------------------------------------

loc_1023A:				; CODE XREF: Sonic_Roll+24j
		btst	#2,$22(a0)
		beq.s	Obj01_DoRoll
		rts
; ---------------------------------------------------------------------------

Obj01_DoRoll:				; CODE XREF: Sonic_Roll+2Ej
		bset	#2,$22(a0)
		move.b	#$E,$16(a0)
		move.b	#7,$17(a0)
		move.b	#2,$1C(a0)
		addq.w	#5,$C(a0)
		move.w	#sfx_Roll,d0	; "?"
		jsr	(PlaySound_Special).l
		tst.w	$14(a0)
		bne.s	locret_10276
		move.w	#$200,$14(a0)

locret_10276:				; CODE XREF: Sonic_Roll+5Cj
		rts
; End of function Sonic_Roll


; =============== S U B	R O U T	I N E =======================================


Sonic_Jump:				; CODE XREF: ROM:0000FCA6p
					; ROM:Obj01_MdRollp
		move.b	(v_jpadpress2).w,d0
		andi.b	#$70,d0	
		beq.w	locret_1031C
		moveq	#0,d0
		move.b	$26(a0),d0
		addi.b	#$80,d0
		bsr.w	sub_13102
		cmpi.w	#6,d1
		blt.w	locret_1031C
		move.w	#$680,d2
		btst	#6,$22(a0)
		beq.s	loc_102AA
		move.w	#$380,d2

loc_102AA:				; CODE XREF: Sonic_Jump+2Cj
		moveq	#0,d0
		move.b	$26(a0),d0
		subi.b	#$40,d0	
		jsr	(CalcSine).l
		muls.w	d2,d1
		asr.l	#8,d1
		add.w	d1,$10(a0)
		muls.w	d2,d0
		asr.l	#8,d0
		add.w	d0,$12(a0)
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		addq.l	#4,sp
		move.b	#1,$3C(a0)
		clr.b	$38(a0)
		move.w	#sfx_Jump,d0	
		jsr	(PlaySound_Special).l
		move.b	#$13,$16(a0)
		move.b	#9,$17(a0)
		btst	#2,$22(a0)
		bne.s	loc_1031E
		move.b	#$E,$16(a0)
		move.b	#7,$17(a0)
		move.b	#2,$1C(a0)
		bset	#2,$22(a0)
		addq.w	#5,$C(a0)

locret_1031C:				; CODE XREF: Sonic_Jump+8j
					; Sonic_Jump+1Ej
		rts
; ---------------------------------------------------------------------------

loc_1031E:				; CODE XREF: Sonic_Jump+86j
		bset	#4,$22(a0)
		rts
; End of function Sonic_Jump


; =============== S U B	R O U T	I N E =======================================


Sonic_JumpHeight:			; CODE XREF: ROM:Obj01_MdJumpp
					; ROM:Obj01_MdJump2p
		tst.b	$3C(a0)
		beq.s	loc_10352
		move.w	#$FC00,d1
		btst	#6,$22(a0)
		beq.s	loc_1033C
		move.w	#$FE00,d1

loc_1033C:				; CODE XREF: Sonic_JumpHeight+10j
		cmp.w	$12(a0),d1
		ble.s	locret_10350
		move.b	(v_jpadhold2).w,d0
		andi.b	#$70,d0	
		bne.s	locret_10350
		move.w	d1,$12(a0)

locret_10350:				; CODE XREF: Sonic_JumpHeight+1Aj
					; Sonic_JumpHeight+24j
		rts
; ---------------------------------------------------------------------------

loc_10352:				; CODE XREF: Sonic_JumpHeight+4j
		cmpi.w	#$F040,$12(a0)
		bge.s	locret_10360
		move.w	#$F040,$12(a0)

locret_10360:				; CODE XREF: Sonic_JumpHeight+32j
		rts
; End of function Sonic_JumpHeight


; =============== S U B	R O U T	I N E =======================================


Sonic_Spindash:				; CODE XREF: ROM:Obj01_MdNormalp
		tst.b	$39(a0)
		bne.s	loc_10396
		cmpi.b	#8,$1C(a0)
		bne.s	locret_10394
		move.b	(v_jpadpress2).w,d0
		andi.b	#$70,d0	
		beq.w	locret_10394
		move.b	#9,$1C(a0)
		move.w	#sfx_Roll,d0	; "?"
		jsr	(PlaySound_Special).l
		addq.l	#4,sp
		move.b	#1,$39(a0)

locret_10394:				; CODE XREF: Sonic_Spindash+Cj
					; Sonic_Spindash+16j
		rts
; ---------------------------------------------------------------------------

loc_10396:				; CODE XREF: Sonic_Spindash+4j
		move.b	(v_jpadhold2).w,d0
		btst	#1,d0
		bne.s	loc_103DC
		move.b	#$E,$16(a0)
		move.b	#7,$17(a0)
		move.b	#2,$1C(a0)
		addq.w	#5,$C(a0)
		move.b	#0,$39(a0)
		move.w	#$2000,($FFFFEED0).w
		move.w	#$800,$14(a0)
		btst	#0,$22(a0)
		beq.s	loc_103D4
		neg.w	$14(a0)

loc_103D4:				; CODE XREF: Sonic_Spindash+6Cj
		bset	#2,$22(a0)
		rts
; ---------------------------------------------------------------------------

loc_103DC:				; CODE XREF: Sonic_Spindash+3Cj
		move.b	(v_jpadpress2).w,d0
		andi.b	#$70,d0	
		beq.w	loc_103EA
		nop

loc_103EA:				; CODE XREF: Sonic_Spindash+82j
		addq.l	#4,sp
		rts
; End of function Sonic_Spindash


; =============== S U B	R O U T	I N E =======================================


Sonic_SlopeResist:			; CODE XREF: ROM:0000FCAAp
		move.b	$26(a0),d0
		addi.b	#$60,d0	
		cmpi.b	#$C0,d0
		bcc.s	locret_10422
		move.b	$26(a0),d0

loc_10400:
		jsr	(CalcSine).l
		muls.w	#$20,d0	
		asr.l	#8,d0
		tst.w	$14(a0)
		beq.s	locret_10422
		bmi.s	loc_1041E
		tst.w	d0
		beq.s	locret_1041C
		add.w	d0,$14(a0)

locret_1041C:				; CODE XREF: Sonic_SlopeResist+28j
		rts
; ---------------------------------------------------------------------------

loc_1041E:				; CODE XREF: Sonic_SlopeResist+24j
		add.w	d0,$14(a0)

locret_10422:				; CODE XREF: Sonic_SlopeResist+Cj
					; Sonic_SlopeResist+22j
		rts
; End of function Sonic_SlopeResist


; =============== S U B	R O U T	I N E =======================================


Sonic_RollRepel:			; CODE XREF: ROM:0000FCF8p
		move.b	$26(a0),d0
		addi.b	#$60,d0	
		cmpi.b	#$C0,d0
		bcc.s	locret_1045E
		move.b	$26(a0),d0
		jsr	(CalcSine).l
		muls.w	#$50,d0	
		asr.l	#8,d0
		tst.w	$14(a0)
		bmi.s	loc_10454
		tst.w	d0
		bpl.s	loc_1044E
		asr.l	#2,d0

loc_1044E:				; CODE XREF: Sonic_RollRepel+26j
		add.w	d0,$14(a0)
		rts
; ---------------------------------------------------------------------------

loc_10454:				; CODE XREF: Sonic_RollRepel+22j
		tst.w	d0
		bmi.s	loc_1045A
		asr.l	#2,d0

loc_1045A:				; CODE XREF: Sonic_RollRepel+32j
		add.w	d0,$14(a0)

locret_1045E:				; CODE XREF: Sonic_RollRepel+Cj
		rts
; End of function Sonic_RollRepel


; =============== S U B	R O U T	I N E =======================================


Sonic_SlopeRepel:			; CODE XREF: ROM:0000FCC4p
					; ROM:0000FD0Ep
		nop
		tst.b	$38(a0)
		bne.s	locret_1049A
		tst.w	$2E(a0)
		bne.s	loc_1049C
		move.b	$26(a0),d0
		addi.b	#$20,d0	
		andi.b	#$C0,d0
		beq.s	locret_1049A
		move.w	$14(a0),d0
		bpl.s	loc_10484
		neg.w	d0

loc_10484:				; CODE XREF: Sonic_SlopeRepel+20j
		cmpi.w	#$280,d0
		bcc.s	locret_1049A
		clr.w	$14(a0)
		bset	#1,$22(a0)
		move.w	#$1E,$2E(a0)

locret_1049A:				; CODE XREF: Sonic_SlopeRepel+6j
					; Sonic_SlopeRepel+1Aj	...
		rts
; ---------------------------------------------------------------------------

loc_1049C:				; CODE XREF: Sonic_SlopeRepel+Cj
		subq.w	#1,$2E(a0)
		rts
; End of function Sonic_SlopeRepel


; =============== S U B	R O U T	I N E =======================================


Sonic_JumpAngle:			; CODE XREF: ROM:loc_FCEAp
					; ROM:loc_FD34p
		move.b	$26(a0),d0
		beq.s	loc_104BC
		bpl.s	loc_104B2
		addq.b	#2,d0
		bcc.s	loc_104B0
		moveq	#0,d0

loc_104B0:				; CODE XREF: Sonic_JumpAngle+Aj
		bra.s	loc_104B8
; ---------------------------------------------------------------------------

loc_104B2:				; CODE XREF: Sonic_JumpAngle+6j
		subq.b	#2,d0
		bcc.s	loc_104B8
		moveq	#0,d0

loc_104B8:				; CODE XREF: Sonic_JumpAngle:loc_104B0j
					; Sonic_JumpAngle+12j
		move.b	d0,$26(a0)

loc_104BC:				; CODE XREF: Sonic_JumpAngle+4j
		move.b	$27(a0),d0
		beq.s	locret_104FA
		tst.w	$14(a0)
		bmi.s	loc_104E0
		move.b	$2D(a0),d1
		add.b	d1,d0
		bcc.s	loc_104DE
		subq.b	#1,$2C(a0)
		bcc.s	loc_104DE
		move.b	#0,$2C(a0)
		moveq	#0,d0

loc_104DE:				; CODE XREF: Sonic_JumpAngle+2Cj
					; Sonic_JumpAngle+32j
		bra.s	loc_104F6
; ---------------------------------------------------------------------------

loc_104E0:				; CODE XREF: Sonic_JumpAngle+24j
		move.b	$2D(a0),d1
		sub.b	d1,d0
		bcc.s	loc_104F6
		subq.b	#1,$2C(a0)
		bcc.s	loc_104F6
		move.b	#0,$2C(a0)
		moveq	#0,d0

loc_104F6:				; CODE XREF: Sonic_JumpAngle:loc_104DEj
					; Sonic_JumpAngle+44j ...
		move.b	d0,$27(a0)

locret_104FA:				; CODE XREF: Sonic_JumpAngle+1Ej
		rts
; End of function Sonic_JumpAngle


; =============== S U B	R O U T	I N E =======================================


Sonic_Floor:				; CODE XREF: ROM:0000FCEEp
					; ROM:0000FD38p ...
		move.l	#v_col1st,($FFFFF796).w
		cmpi.b	#$C,$3E(a0)
		beq.s	loc_10514
		move.l	#v_col2nd,($FFFFF796).w

loc_10514:				; CODE XREF: Sonic_Floor+Ej
		move.b	$3F(a0),d5
		move.w	$10(a0),d1
		move.w	$12(a0),d2
		jsr	(CalcAngle).l
		subi.b	#$20,d0	
		andi.b	#$C0,d0
		cmpi.b	#$40,d0	
		beq.w	loc_105E4
		cmpi.b	#$80,d0
		beq.w	loc_10646
		cmpi.b	#$C0,d0
		beq.w	loc_106A2
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_10558
		sub.w	d1,8(a0)
		move.w	#0,$10(a0)

loc_10558:				; CODE XREF: Sonic_Floor+50j
		bsr.w	sub_132EE
		tst.w	d1
		bpl.s	loc_1056A
		add.w	d1,8(a0)
		move.w	#0,$10(a0)

loc_1056A:				; CODE XREF: Sonic_Floor+62j
		bsr.w	loc_13146
		tst.w	d1
		bpl.s	locret_105E2
		move.b	$12(a0),d2
		addq.b	#8,d2
		neg.b	d2
		cmp.b	d2,d1
		bge.s	loc_10582
		cmp.b	d2,d0
		blt.s	locret_105E2

loc_10582:				; CODE XREF: Sonic_Floor+80j
		add.w	d1,$C(a0)
		move.b	d3,$26(a0)
		bsr.w	Sonic_ResetOnFloor
		move.b	#0,$1C(a0)
		move.b	d3,d0
		addi.b	#$20,d0	
		andi.b	#$40,d0	
		bne.s	loc_105C0
		move.b	d3,d0
		addi.b	#$10,d0
		andi.b	#$20,d0	
		beq.s	loc_105B2
		asr	$12(a0)
		bra.s	loc_105D4
; ---------------------------------------------------------------------------

loc_105B2:				; CODE XREF: Sonic_Floor+AEj
		move.w	#0,$12(a0)
		move.w	$10(a0),$14(a0)
		rts
; ---------------------------------------------------------------------------

loc_105C0:				; CODE XREF: Sonic_Floor+A2j
		move.w	#0,$10(a0)
		cmpi.w	#$FC0,$12(a0)
		ble.s	loc_105D4
		move.w	#$FC0,$12(a0)

loc_105D4:				; CODE XREF: Sonic_Floor+B4j
					; Sonic_Floor+D0j
		move.w	$12(a0),$14(a0)
		tst.b	d3
		bpl.s	locret_105E2
		neg.w	$14(a0)

locret_105E2:				; CODE XREF: Sonic_Floor+74j
					; Sonic_Floor+84j ...
		rts
; ---------------------------------------------------------------------------

loc_105E4:				; CODE XREF: Sonic_Floor+36j
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_105FE
		sub.w	d1,8(a0)
		move.w	#0,$10(a0)
		move.w	$12(a0),$14(a0)
		rts
; ---------------------------------------------------------------------------

loc_105FE:				; CODE XREF: Sonic_Floor+EEj
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	loc_10618
		sub.w	d1,$C(a0)
		tst.w	$12(a0)
		bpl.s	locret_10616
		move.w	#0,$12(a0)

locret_10616:				; CODE XREF: Sonic_Floor+112j
		rts
; ---------------------------------------------------------------------------

loc_10618:				; CODE XREF: Sonic_Floor+108j
		tst.w	$12(a0)
		bmi.s	locret_10644
		bsr.w	loc_13146
		tst.w	d1
		bpl.s	locret_10644
		add.w	d1,$C(a0)
		move.b	d3,$26(a0)
		bsr.w	Sonic_ResetOnFloor
		move.b	#0,$1C(a0)
		move.w	#0,$12(a0)
		move.w	$10(a0),$14(a0)

locret_10644:				; CODE XREF: Sonic_Floor+120j
					; Sonic_Floor+128j
		rts
; ---------------------------------------------------------------------------

loc_10646:				; CODE XREF: Sonic_Floor+3Ej
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_10658
		sub.w	d1,8(a0)
		move.w	#0,$10(a0)

loc_10658:				; CODE XREF: Sonic_Floor+150j
		bsr.w	sub_132EE
		tst.w	d1
		bpl.s	loc_1066A
		add.w	d1,8(a0)
		move.w	#0,$10(a0)

loc_1066A:				; CODE XREF: Sonic_Floor+162j
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	locret_106A0
		sub.w	d1,$C(a0)
		move.b	d3,d0
		addi.b	#$20,d0	
		andi.b	#$40,d0	
		bne.s	loc_1068A
		move.w	#0,$12(a0)
		rts
; ---------------------------------------------------------------------------

loc_1068A:				; CODE XREF: Sonic_Floor+184j
		move.b	d3,$26(a0)
		bsr.w	Sonic_ResetOnFloor
		move.w	$12(a0),$14(a0)
		tst.b	d3
		bpl.s	locret_106A0
		neg.w	$14(a0)

locret_106A0:				; CODE XREF: Sonic_Floor+174j
					; Sonic_Floor+19Ej
		rts
; ---------------------------------------------------------------------------

loc_106A2:				; CODE XREF: Sonic_Floor+46j
		bsr.w	sub_132EE
		tst.w	d1
		bpl.s	loc_106BC
		add.w	d1,8(a0)
		move.w	#0,$10(a0)
		move.w	$12(a0),$14(a0)
		rts
; ---------------------------------------------------------------------------

loc_106BC:				; CODE XREF: Sonic_Floor+1ACj
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	loc_106D6
		sub.w	d1,$C(a0)
		tst.w	$12(a0)
		bpl.s	locret_106D4
		move.w	#0,$12(a0)

locret_106D4:				; CODE XREF: Sonic_Floor+1D0j
		rts
; ---------------------------------------------------------------------------

loc_106D6:				; CODE XREF: Sonic_Floor+1C6j
		tst.w	$12(a0)
		bmi.s	locret_10702
		bsr.w	loc_13146
		tst.w	d1
		bpl.s	locret_10702
		add.w	d1,$C(a0)
		move.b	d3,$26(a0)
		bsr.w	Sonic_ResetOnFloor
		move.b	#0,$1C(a0)
		move.w	#0,$12(a0)
		move.w	$10(a0),$14(a0)

locret_10702:				; CODE XREF: Sonic_Floor+1DEj
					; Sonic_Floor+1E6j
		rts
; End of function Sonic_Floor


; =============== S U B	R O U T	I N E =======================================


Sonic_ResetOnFloor:			; CODE XREF: sub_F8F8+54p
					; Sonic_Move+1C0p ...
		btst	#4,$22(a0)
		beq.s	loc_10712
		nop
		nop
		nop

loc_10712:				; CODE XREF: Sonic_ResetOnFloor+6j
		bclr	#5,$22(a0)
		bclr	#1,$22(a0)
		bclr	#4,$22(a0)
		btst	#2,$22(a0)
		beq.s	loc_10748
		bclr	#2,$22(a0)
		move.b	#$13,$16(a0)
		move.b	#9,$17(a0)
		move.b	#0,$1C(a0)
		subq.w	#5,$C(a0)

loc_10748:				; CODE XREF: Sonic_ResetOnFloor+26j
		move.b	#0,$3C(a0)
		move.w	#0,($FFFFF7D0).w
		move.b	#0,$27(a0)
		rts
; End of function Sonic_ResetOnFloor

; ---------------------------------------------------------------------------

Obj01_Hurt:				; DATA XREF: ROM:0000FA1Ao
		tst.b	$25(a0)
		bmi.w	loc_107E8
		jsr	SpeedToPos
		addi.w	#$30,$12(a0) 
		btst	#6,$22(a0)
		beq.s	loc_1077E
		subi.w	#$20,$12(a0) 

loc_1077E:				; CODE XREF: ROM:00010776j
		bsr.w	Sonic_HurtStop
		bsr.w	Sonic_LevelBoundaries
		bsr.w	CopySonicMovesForTails
		bsr.w	Sonic_Animate
		bsr.w	LoadSonicDynPLC
		jmp	DisplaySprite

; =============== S U B	R O U T	I N E =======================================


Sonic_HurtStop:				; CODE XREF: ROM:loc_1077Ep
		move.w	($FFFFEECE).w,d0
		addi.w	#$E0,d0	
		cmp.w	$C(a0),d0
		bcs.w	j_KillSonic
		bsr.w	Sonic_Floor
		btst	#1,$22(a0)
		bne.s	locret_107E6
		moveq	#0,d0
		move.w	d0,$12(a0)
		move.w	d0,$10(a0)
		move.w	d0,$14(a0)
		tst.b	$25(a0)
		beq.s	loc_107D6
		move.b	#$FF,$25(a0)
		move.b	#$B,$1C(a0)
		rts
; ---------------------------------------------------------------------------

loc_107D6:				; CODE XREF: Sonic_HurtStop+2Ej
		move.b	#0,$1C(a0)
		subq.b	#2,$24(a0)
		move.w	#$78,$30(a0) 

locret_107E6:				; CODE XREF: Sonic_HurtStop+1Aj
		rts
; End of function Sonic_HurtStop

; ---------------------------------------------------------------------------

loc_107E8:				; CODE XREF: ROM:00010760j
		cmpi.b	#$B,$1C(a0)
		bne.s	loc_107FA
		move.b	(v_jpadpress1).w,d0
		andi.b	#$7F,d0	
		beq.s	loc_10804

loc_107FA:				; CODE XREF: ROM:000107EEj
		subq.b	#2,$24(a0)
		move.b	#0,$25(a0)

loc_10804:				; CODE XREF: ROM:000107F8j
		bsr.w	CopySonicMovesForTails
		bsr.w	Sonic_Animate
		bsr.w	LoadSonicDynPLC
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

Obj01_Death:				; DATA XREF: ROM:0000FA1Co
		bsr.w	Sonic_GameOver
		jsr	ObjectFall
		bsr.w	CopySonicMovesForTails
		bsr.w	Sonic_Animate
		bsr.w	LoadSonicDynPLC
		jmp	DisplaySprite

; =============== S U B	R O U T	I N E =======================================


Sonic_GameOver:				; CODE XREF: ROM:Obj01_Deathp
		move.w	($FFFFEECE).w,d0
		addi.w	#$100,d0
		cmp.w	$C(a0),d0
		bcc.w	locret_108B4
		move.w	#$FFC8,$12(a0)
		addq.b	#2,$24(a0)
		clr.b	($FFFFFE1E).w
		addq.b	#1,($FFFFFE1C).w
		subq.b	#1,($FFFFFE12).w
		bne.s	loc_10888
		move.w	#0,$3A(a0)
		move.b	#$39,(v_objspace+$80).w 
		move.b	#$39,(v_objspace+$C0).w 
		move.b	#1,(v_objspace+$DA).w
		clr.b	($FFFFFE1A).w

loc_10876:				; CODE XREF: Sonic_GameOver+80j
		move.w	#bgm_GameOver,d0	; "?"
		jsr	(PlaySound).l
		moveq	#plcid_GameOver,d0
		jmp	(LoadPLC).l
; ---------------------------------------------------------------------------

loc_10888:				; CODE XREF: Sonic_GameOver+26j
		move.w	#$3C,$3A(a0) 
		tst.b	($FFFFFE1A).w
		beq.s	locret_108B4
		move.w	#0,$3A(a0)
		move.b	#$39,(v_objspace+$80).w 
		move.b	#$39,(v_objspace+$C0).w 
		move.b	#2,(v_objspace+$9A).w
		move.b	#3,(v_objspace+$DA).w
		bra.s	loc_10876
; ---------------------------------------------------------------------------

locret_108B4:				; CODE XREF: Sonic_GameOver+Cj
					; Sonic_GameOver+60j
		rts
; End of function Sonic_GameOver

; ---------------------------------------------------------------------------

Obj01_ResetLevel:			; DATA XREF: ROM:0000FA1Eo
		tst.w	$3A(a0)
		beq.s	locret_108C8
		subq.w	#1,$3A(a0)
		bne.s	locret_108C8
		move.w	#1,($FFFFFE02).w

locret_108C8:				; CODE XREF: ROM:000108BAj
					; ROM:000108C0j
		rts

; =============== S U B	R O U T	I N E =======================================


Sonic_Animate:				; CODE XREF: ROM:loc_FAFEp
					; ROM:0001078Ap ...

; FUNCTION CHUNK AT 0001095C SIZE 0000015E BYTES

		lea	(SonicAniData).l,a1
		moveq	#0,d0
		move.b	$1C(a0),d0
		cmp.b	$1D(a0),d0
		beq.s	loc_108EC
		move.b	d0,$1D(a0)
		move.b	#0,$1B(a0)
		move.b	#0,$1E(a0)

loc_108EC:				; CODE XREF: Sonic_Animate+10j
		add.w	d0,d0
		adda.w	(a1,d0.w),a1
		move.b	(a1),d0
		bmi.s	loc_1095C
		move.b	$22(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		subq.b	#1,$1E(a0)
		bpl.s	locret_1092A
		move.b	d0,$1E(a0)
; End of function Sonic_Animate


; =============== S U B	R O U T	I N E =======================================


sub_10912:				; CODE XREF: Sonic_Animate+116p
					; Sonic_Animate+1BAj ...
		moveq	#0,d1
		move.b	$1B(a0),d1
		move.b	1(a1,d1.w),d0
		cmpi.b	#$F0,d0
		bcc.s	loc_1092C

loc_10922:				; CODE XREF: sub_10912+28j
					; sub_10912+3Cj
		move.b	d0,$1A(a0)
		addq.b	#1,$1B(a0)

locret_1092A:				; CODE XREF: Sonic_Animate+42j
					; Sonic_Animate+96j
		rts
; ---------------------------------------------------------------------------

loc_1092C:				; CODE XREF: sub_10912+Ej
		addq.b	#1,d0
		bne.s	loc_1093C
		move.b	#0,$1B(a0)
		move.b	1(a1),d0
		bra.s	loc_10922
; ---------------------------------------------------------------------------

loc_1093C:				; CODE XREF: sub_10912+1Cj
		addq.b	#1,d0
		bne.s	loc_10950
		move.b	2(a1,d1.w),d0
		sub.b	d0,$1B(a0)
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0
		bra.s	loc_10922
; ---------------------------------------------------------------------------

loc_10950:				; CODE XREF: sub_10912+2Cj
		addq.b	#1,d0
		bne.s	locret_1095A
		move.b	2(a1,d1.w),$1C(a0)

locret_1095A:				; CODE XREF: sub_10912+40j
		rts
; End of function sub_10912

; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR Sonic_Animate

loc_1095C:				; CODE XREF: Sonic_Animate+2Aj
		subq.b	#1,$1E(a0)
		bpl.s	locret_1092A
		addq.b	#1,d0
		bne.w	loc_10A44
		moveq	#0,d0
		move.b	$27(a0),d0
		bne.w	loc_109EA
		moveq	#0,d1
		move.b	$26(a0),d0
		move.b	$22(a0),d2
		andi.b	#1,d2
		bne.s	loc_10984
		not.b	d0

loc_10984:				; CODE XREF: Sonic_Animate+B6j
		addi.b	#$10,d0
		bpl.s	loc_1098C
		moveq	#3,d1

loc_1098C:				; CODE XREF: Sonic_Animate+BEj
		andi.b	#$FC,1(a0)
		eor.b	d1,d2
		or.b	d2,1(a0)
		btst	#5,$22(a0)
		bne.w	loc_10A88
		lsr.b	#4,d0
		andi.b	#6,d0
		move.w	$14(a0),d2
		bpl.s	loc_109B0
		neg.w	d2

loc_109B0:				; CODE XREF: Sonic_Animate+E2j
		lea	(SonicAni_Run).l,a1
		cmpi.w	#$600,d2
		bcc.s	loc_109C2
		lea	(SonicAni_Walk).l,a1

loc_109C2:				; CODE XREF: Sonic_Animate+F0j
		move.b	d0,d1
		lsr.b	#1,d1
		add.b	d1,d0
		add.b	d0,d0
		add.b	d0,d0
		move.b	d0,d3
		neg.w	d2
		addi.w	#$800,d2
		bpl.s	loc_109D8
		moveq	#0,d2

loc_109D8:				; CODE XREF: Sonic_Animate+10Aj
		lsr.w	#8,d2
		lsr.w	#1,d2
		move.b	d2,$1E(a0)
		bsr.w	sub_10912
		add.b	d3,$1A(a0)
		rts
; ---------------------------------------------------------------------------

loc_109EA:				; CODE XREF: Sonic_Animate+A4j
		move.b	$27(a0),d0
		moveq	#0,d1
		move.b	$22(a0),d2
		andi.b	#1,d2
		bne.s	loc_10A1E
		andi.b	#$FC,1(a0)
		moveq	#0,d2
		or.b	d2,1(a0)
		addi.b	#$B,d0
		divu.w	#$16,d0
		addi.b	#$9B,d0
		move.b	d0,$1A(a0)
		move.b	#0,$1E(a0)
		rts
; ---------------------------------------------------------------------------

loc_10A1E:				; CODE XREF: Sonic_Animate+12Ej
		moveq	#3,d2
		andi.b	#$FC,1(a0)
		or.b	d2,1(a0)
		neg.b	d0
		addi.b	#$8F,d0
		divu.w	#$16,d0
		addi.b	#$9B,d0
		move.b	d0,$1A(a0)
		move.b	#0,$1E(a0)
		rts
; ---------------------------------------------------------------------------

loc_10A44:				; CODE XREF: Sonic_Animate+9Aj
		addq.b	#1,d0
		bne.s	loc_10A88
		move.w	$14(a0),d2
		bpl.s	loc_10A50
		neg.w	d2

loc_10A50:				; CODE XREF: Sonic_Animate+182j
		lea	(SonicAni_Roll2).l,a1
		cmpi.w	#$600,d2
		bcc.s	loc_10A62
		lea	(SonicAni_Roll).l,a1

loc_10A62:				; CODE XREF: Sonic_Animate+190j
		neg.w	d2
		addi.w	#$400,d2
		bpl.s	loc_10A6C
		moveq	#0,d2

loc_10A6C:				; CODE XREF: Sonic_Animate+19Ej
		lsr.w	#8,d2
		move.b	d2,$1E(a0)
		move.b	$22(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		bra.w	sub_10912
; ---------------------------------------------------------------------------

loc_10A88:				; CODE XREF: Sonic_Animate+D4j
					; Sonic_Animate+17Cj
		move.w	$14(a0),d2
		bmi.s	loc_10A90
		neg.w	d2

loc_10A90:				; CODE XREF: Sonic_Animate+1C2j
		addi.w	#$800,d2
		bpl.s	loc_10A98
		moveq	#0,d2

loc_10A98:				; CODE XREF: Sonic_Animate+1CAj
		lsr.w	#6,d2
		move.b	d2,$1E(a0)
		lea	(SonicAni_Push).l,a1
		move.b	$22(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		bra.w	sub_10912
; END OF FUNCTION CHUNK	FOR Sonic_Animate
; ---------------------------------------------------------------------------
SonicAniData:	dc.w SonicAni_Walk-SonicAniData,SonicAni_Run-SonicAniData; 0
					; DATA XREF: Sonic_Animateo
					; ROM:SonicAniDatao ...
		dc.w SonicAni_Roll-SonicAniData,SonicAni_Roll2-SonicAniData; 2
		dc.w SonicAni_Push-SonicAniData,SonicAni_Wait-SonicAniData; 4
		dc.w SonicAni_Balance-SonicAniData,SonicAni_LookUp-SonicAniData; 6
		dc.w SonicAni_Duck-SonicAniData,SonicAni_Spindash-SonicAniData;	8
		dc.w SonicAni_WallRecoil1-SonicAniData,SonicAni_WallRecoil2-SonicAniData; 10
		dc.w SonicAni_0C-SonicAniData,SonicAni_Stop-SonicAniData; 12
		dc.w SonicAni_Float1-SonicAniData,SonicAni_Float2-SonicAniData;	14
		dc.w SonicAni_10-SonicAniData,SonicAni_S1LZHang-SonicAniData; 16
		dc.w SonicAni_Unused12-SonicAniData,SonicAni_Unused13-SonicAniData; 18
		dc.w SonicAni_Unused14-SonicAniData,SonicAni_Bubble-SonicAniData; 20
		dc.w SonicAni_Death1-SonicAniData,SonicAni_Drown-SonicAniData; 22
		dc.w SonicAni_Death2-SonicAniData,SonicAni_Unused19-SonicAniData; 24
		dc.w SonicAni_Hurt-SonicAniData,SonicAni_S1LZSlide-SonicAniData; 26
		dc.w SonicAni_1C-SonicAniData,SonicAni_Float3-SonicAniData; 28
		dc.w SonicAni_1E-SonicAniData; 30
SonicAni_Walk:	dc.b $FF,$10,$11,$12,$13,$14,$15,$16,$17, $C, $D, $E, $F,$FF; 0
					; DATA XREF: Sonic_Animate+F2o
					; ROM:SonicAniDatao
SonicAni_Run:	dc.b $FF,$3C,$3D,$3E,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF; 0
					; DATA XREF: Sonic_Animate:loc_109B0o
					; ROM:SonicAniDatao
SonicAni_Roll:	dc.b $FE,$6C,$70,$6D,$70,$6E,$70,$6F,$70,$FF; 0
					; DATA XREF: Sonic_Animate+192o
					; ROM:SonicAniDatao
SonicAni_Roll2:	dc.b $FE,$6C,$70,$6D,$70,$6E,$70,$6F,$70,$FF; 0
					; DATA XREF: Sonic_Animate:loc_10A50o
					; ROM:SonicAniDatao
SonicAni_Push:	dc.b $FD,$77,$78,$79,$7A,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF; 0
					; DATA XREF: Sonic_Animate+1D4o
					; ROM:SonicAniDatao
SonicAni_Wait:	dc.b   7,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1; 0
					; DATA XREF: ROM:SonicAniDatao
		dc.b   1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  2; 16
		dc.b   3,  3,  3,  4,  4,  5,  5,$FE,  4; 32
SonicAni_Balance:dc.b	7,$89,$8A,$FF	 ; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_LookUp:dc.b   5,  6,  7,$FE,  1; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_Duck:	dc.b   5,$7F,$80,$FE,  1; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_Spindash:dc.b	 0,$71,$72,$71,$73,$71,$74,$71,$75,$71,$76,$71,$FF; 0
					; DATA XREF: ROM:SonicAniDatao
SonicAni_WallRecoil1:dc.b $3F,$82,$FF	     ; 0 ; DATA	XREF: ROM:SonicAniDatao
SonicAni_WallRecoil2:dc.b   7,	8,  8,	9,$FD,	5; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_0C:	dc.b   7,  9,$FD,  5	; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_Stop:	dc.b   3,$81,$82,$83,$84,$85,$86,$87,$88,$FE,  2; 0
					; DATA XREF: ROM:SonicAniDatao
SonicAni_Float1:dc.b   7,$94,$96,$FF	; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_Float2:dc.b   7,$91,$92,$93,$94,$95,$FF; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_10:	dc.b $2F,$7E,$FD,  0	; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_S1LZHang:dc.b	 5,$8F,$90,$FF	  ; 0 ;	DATA XREF: ROM:SonicAniDatao
SonicAni_Unused12:dc.b	$F,$43,$43,$43,$FE,  1;	0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_Unused13:dc.b	$F,$43,$44,$FE,	 1; 0 ;	DATA XREF: ROM:SonicAniDatao
SonicAni_Unused14:dc.b $3F,$49,$FF	  ; 0 ;	DATA XREF: ROM:SonicAniDatao
SonicAni_Bubble:dc.b  $B,$97,$97,$12,$13,$FD,  0; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_Death1:dc.b $20,$9A,$FF	; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_Drown:	dc.b $20,$99,$FF	; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_Death2:dc.b $20,$98,$FF	; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_Unused19:dc.b	 3,$4E,$4F,$50,$51,$52,	 0,$FE,	 1; 0 ;	DATA XREF: ROM:SonicAniDatao
SonicAni_Hurt:	dc.b $40,$8D,$FF	; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_S1LZSlide:dc.b	  9,$8D,$8E,$FF	   ; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_1C:	dc.b $77,  0,$FD,  0	; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_Float3:dc.b   3,$91,$92,$93,$94,$95,$FF; 0 ; DATA XREF: ROM:SonicAniDatao
SonicAni_1E:	dc.b   3,$3C,$FD,  0	; 0 ; DATA XREF: ROM:SonicAniDatao

; =============== S U B	R O U T	I N E =======================================


LoadSonicDynPLC:			; CODE XREF: ROM:loc_FB0Ej
					; ROM:0001078Ep ...
		moveq	#0,d0
		move.b	$1A(a0),d0
		cmp.b	($FFFFF766).w,d0
		beq.s	locret_10C34
		move.b	d0,($FFFFF766).w
		lea	(SonicDynPLC).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d5
		subq.w	#1,d5
		bmi.s	locret_10C34

loc_10C04:
		move.w	#$F000,d4

loc_10C08:				; CODE XREF: LoadSonicDynPLC+4Ej
		moveq	#0,d1
		move.w	(a2)+,d1
		move.w	d1,d3
		lsr.w	#8,d3
		andi.w	#$F0,d3	; "?"
		addi.w	#$10,d3
		andi.w	#$FFF,d1
		lsl.l	#5,d1
		addi.l	#Art_Sonic,d1
		move.w	d4,d2
		add.w	d3,d4
		add.w	d3,d4
		jsr	(DMA_68KtoVRAM).l
		dbf	d5,loc_10C08

locret_10C34:				; CODE XREF: LoadSonicDynPLC+Aj
					; LoadSonicDynPLC+20j
		rts
; End of function LoadSonicDynPLC

; ---------------------------------------------------------------------------
		nop

j_KillSonic:
		jmp	KillSonic

        if removeJmpTos=0
		align 4
	endif
;----------------------------------------------------
; Object 02 - Tails
;----------------------------------------------------

Obj02:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj02_Index(pc,d0.w),d1
		jmp	Obj02_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj02_Index:	dc.w Obj02_Main-Obj02_Index; 0 ; DATA XREF: ROM:Obj02_Indexo
					; ROM:Obj02_Index+2o ...
		dc.w Obj02_Control-Obj02_Index;	1
		dc.w Obj02_Hurt-Obj02_Index; 2
		dc.w Obj02_Death-Obj02_Index; 3
		dc.w Obj02_ResetLevel-Obj02_Index; 4
; ---------------------------------------------------------------------------

Obj02_Main:				; DATA XREF: ROM:Obj02_Indexo
		addq.b	#2,$24(a0)
		move.b	#$F,$16(a0)
		move.b	#9,$17(a0)
		move.l	#Map_Tails,4(a0)
		move.w	#$7A0,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#2,$18(a0)
		move.b	#$18,$19(a0)
		move.b	#$84,1(a0)
		move.w	#$600,($FFFFF760).w
		move.w	#$C,($FFFFF762).w
		move.w	#$80,($FFFFF764).w 
		move.b	#$C,$3E(a0)
		move.b	#$D,$3F(a0)
		move.b	#0,$2C(a0)
		move.b	#4,$2D(a0)
		move.b	#5,(v_objspace+$1C0).w

Obj02_Control:				; DATA XREF: ROM:Obj02_Indexo
		bsr.w	Tails_Control
		btst	#0,($FFFFF7C8).w
		bne.s	Obj02_ControlsLock
		moveq	#0,d0
		move.b	$22(a0),d0
		andi.w	#6,d0
		move.w	Obj02_Modes(pc,d0.w),d1
		jsr	Obj02_Modes(pc,d1.w)

Obj02_ControlsLock:			; CODE XREF: ROM:00010CC6j
		bsr.s	Tails_Display
		bsr.w	RecordTailsMoves
		move.b	($FFFFF768).w,$36(a0)
		move.b	($FFFFF76A).w,$37(a0)
		bsr.w	Tails_Animate
		tst.b	($FFFFF7C8).w
		bmi.s	loc_10CFC
		jsr	TouchResponse

loc_10CFC:				; CODE XREF: ROM:00010CF4j
		bsr.w	LoadTailsDynPLC
		rts
; ---------------------------------------------------------------------------
Obj02_Modes:	dc.w Obj02_MdNormal-Obj02_Modes	; DATA XREF: ROM:Obj02_Modeso
					; ROM:00010D04o ...
		dc.w Obj02_MdJump-Obj02_Modes
		dc.w Obj02_MdRoll-Obj02_Modes
		dc.w Obj02_MdJump2-Obj02_Modes
MusicList_Tails:dc.b $81,$82,$83,$84,$85,$86; 0	; DATA XREF: Tails_Display:loc_10D54t

; =============== S U B	R O U T	I N E =======================================


Tails_Display:				; CODE XREF: ROM:Obj02_ControlsLockp
		move.w	$30(a0),d0
		beq.s	loc_10D1E
		subq.w	#1,$30(a0)
		lsr.w	#3,d0
		bcc.s	loc_10D24

loc_10D1E:				; CODE XREF: Tails_Display+4j
		jsr	(DisplaySprite).l

loc_10D24:				; CODE XREF: Tails_Display+Cj
		tst.b	($FFFFFE2D).w
		beq.s	loc_10D68
		tst.w	$32(a0)
		beq.s	loc_10D68
		subq.w	#1,$32(a0)
		bne.s	loc_10D68
		tst.b	($FFFFF7AA).w
		bne.s	loc_10D62
		cmpi.w	#$C,($FFFFFE14).w
		bcs.s	loc_10D62
		moveq	#0,d0
		move.b	(v_zone).w,d0
		cmpi.w	#$103,(v_zone).w
		bne.s	loc_10D54
		moveq	#5,d0

loc_10D54:				; CODE XREF: Tails_Display+40j
		lea	MusicList_Tails(pc),a1
		move.b	(a1,d0.w),d0
		jsr	(PlaySound).l

loc_10D62:				; CODE XREF: Tails_Display+2Aj
					; Tails_Display+32j
		move.b	#0,($FFFFFE2D).w

loc_10D68:				; CODE XREF: Tails_Display+18j
					; Tails_Display+1Ej ...
		tst.b	($FFFFFE2E).w
		beq.s	locret_10D9C
		tst.w	$34(a0)
		beq.s	locret_10D9C
		subq.w	#1,$34(a0)
		bne.s	locret_10D9C
		move.w	#$600,($FFFFF760).w
		move.w	#$C,($FFFFF762).w
		move.w	#$80,($FFFFF764).w 
		move.b	#0,($FFFFFE2E).w
		move.w	#$E3,d0	; "?"
		jmp	(PlaySound).l
; ---------------------------------------------------------------------------

locret_10D9C:				; CODE XREF: Tails_Display+5Cj
					; Tails_Display+62j ...
		rts
; End of function Tails_Display


; =============== S U B	R O U T	I N E =======================================


Tails_Control:				; CODE XREF: ROM:Obj02_Controlp
		move.b	($FFFFF606).w,d0
		andi.b	#$7F,d0	
		beq.s	TailsC_NoKeysPressed
		move.w	#0,($FFFFF700).w
		move.w	#$12C,($FFFFF702).w
		rts
; ---------------------------------------------------------------------------

TailsC_NoKeysPressed:			; CODE XREF: Tails_Control+8j
		tst.w	($FFFFF702).w
		beq.s	TailsC_DoControl
		subq.w	#1,($FFFFF702).w
		rts
; ---------------------------------------------------------------------------

TailsC_DoControl:			; CODE XREF: Tails_Control+1Cj
		move.w	($FFFFF708).w,d0
		move.w	TailsC_Index(pc,d0.w),d0
		jmp	TailsC_Index(pc,d0.w)
; End of function Tails_Control

; ---------------------------------------------------------------------------
TailsC_Index:	dc.w TailsC_00-TailsC_Index ; DATA XREF: ROM:TailsC_Indexo
					; ROM:00010DD0o ...
		dc.w TailsC_02-TailsC_Index
		dc.w TailsC_04-TailsC_Index
		dc.w TailsC_CopySonicMoves-TailsC_Index
; ---------------------------------------------------------------------------

TailsC_00:				; DATA XREF: ROM:TailsC_Indexo
		move.w	#6,($FFFFF708).w
		rts
; ---------------------------------------------------------------------------

TailsC_02:				; DATA XREF: ROM:00010DD0o
		move.w	#6,($FFFFF708).w
		rts
; ---------------------------------------------------------------------------
		move.w	#$40,($FFFFF706).w 
		move.w	#4,($FFFFF708).w

TailsC_04:				; DATA XREF: ROM:00010DD2o
		move.w	#6,($FFFFF708).w
		rts
; ---------------------------------------------------------------------------
		move.w	($FFFFF706).w,d1
		subq.w	#1,d1
		cmpi.w	#$10,d1
		bne.s	loc_10E0C
		move.w	#6,($FFFFF708).w

loc_10E0C:				; CODE XREF: ROM:00010E04j
		move.w	d1,($FFFFF706).w
		lea	(v_recordsonic).w,a1
		lsl.b	#2,d1
		addq.b	#4,d1
		move.w	($FFFFEEE0).w,d0
		sub.b	d1,d0
		move.w	(a1,d0.w),8(a0)
		move.w	2(a1,d0.w),$C(a0)
		rts
; ---------------------------------------------------------------------------

TailsC_CopySonicMoves:			; DATA XREF: ROM:00010DD4o
		move.w	(v_objspace+8).w,d0
		sub.w	8(a0),d0
		bpl.s	loc_10E38
		neg.w	d0

loc_10E38:				; CODE XREF: ROM:00010E34j
		cmpi.w	#$C0,d0	
		bcs.s	loc_10E40
		nop

loc_10E40:				; CODE XREF: ROM:00010E3Cj
		lea	(v_tracktails).w,a1
		move.w	#$10,d1
		lsl.b	#2,d1
		addq.b	#4,d1
		move.w	($FFFFEED2).w,d0
		sub.b	d1,d0
		lea	(v_tracksonic).w,a1
		move.w	(a1,d0.w),($FFFFF606).w
		rts

; =============== S U B	R O U T	I N E =======================================


RecordTailsMoves:			; CODE XREF: ROM:00010CDCp
		move.w	($FFFFEED6).w,d0
		lea	(v_recordtails).w,a1
		lea	(a1,d0.w),a1
		move.w	8(a0),(a1)+
		move.w	$C(a0),(a1)+
		addq.b	#4,($FFFFEED7).w
		rts
; End of function RecordTailsMoves

; ---------------------------------------------------------------------------

Obj02_MdNormal:				; DATA XREF: ROM:Obj02_Modeso
		bsr.w	Tails_Spindash
		bsr.w	Tails_Jump
		bsr.w	Tails_SlopeResist
		bsr.w	Tails_Move
		bsr.w	Tails_Roll
		bsr.w	Tails_LevelBoundaries
		jsr	(SpeedToPos).l
		bsr.w	Sonic_AnglePos
		bsr.w	Tails_SlopeRepel
		rts
; ---------------------------------------------------------------------------

Obj02_MdJump:				; DATA XREF: ROM:00010D04o
		bsr.w	Tails_JumpHeight
		bsr.w	Tails_ChgJumpDir
		bsr.w	Tails_LevelBoundaries
		jsr	(ObjectFall).l
		btst	#6,$22(a0)
		beq.s	loc_10EC0
		subi.w	#$28,$12(a0) 

loc_10EC0:				; CODE XREF: ROM:00010EB8j
		bsr.w	Tails_JumpAngle
		bsr.w	Tails_Floor
		rts
; ---------------------------------------------------------------------------

Obj02_MdRoll:				; DATA XREF: ROM:00010D06o
		bsr.w	Tails_Jump
		bsr.w	Tails_RollRepel
		bsr.w	Tails_RollSpeed
		bsr.w	Tails_LevelBoundaries
		jsr	(SpeedToPos).l
		bsr.w	Sonic_AnglePos
		bsr.w	Tails_SlopeRepel
		rts
; ---------------------------------------------------------------------------

Obj02_MdJump2:				; DATA XREF: ROM:00010D08o
		bsr.w	Tails_JumpHeight
		bsr.w	Tails_ChgJumpDir
		bsr.w	Tails_LevelBoundaries
		jsr	(ObjectFall).l
		btst	#6,$22(a0)
		beq.s	loc_10F0A
		subi.w	#$28,$12(a0) 

loc_10F0A:				; CODE XREF: ROM:00010F02j
		bsr.w	Tails_JumpAngle
		bsr.w	Tails_Floor
		rts

; =============== S U B	R O U T	I N E =======================================


Tails_Move:				; CODE XREF: ROM:00010E84p
		move.w	($FFFFF760).w,d6
		move.w	($FFFFF762).w,d5
		move.w	($FFFFF764).w,d4
		tst.b	($FFFFF7CA).w
		bne.w	loc_11026
		tst.w	$2E(a0)
		bne.w	loc_10FFA
		btst	#2,($FFFFF606).w
		beq.s	loc_10F3C
		bsr.w	Tails_MoveLeft

loc_10F3C:				; CODE XREF: Tails_Move+22j
		btst	#3,($FFFFF606).w
		beq.s	loc_10F48
		bsr.w	Tails_MoveRight

loc_10F48:				; CODE XREF: Tails_Move+2Ej
		move.b	$26(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		bne.w	loc_10FFA
		tst.w	$14(a0)
		bne.w	loc_10FFA
		bclr	#5,$22(a0)
		move.b	#5,$1C(a0)
		btst	#3,$22(a0)
		beq.s	Tails_Balance
		moveq	#0,d0
		move.b	$3D(a0),d0
		lsl.w	#6,d0
		lea	(v_objspace).w,a1
		lea	(a1,d0.w),a1
		tst.b	$22(a1)
		bmi.s	Tails_LookUp
		moveq	#0,d1
		move.b	$19(a1),d1
		move.w	d1,d2
		add.w	d2,d2
		subq.w	#4,d2
		add.w	8(a0),d1
		sub.w	8(a1),d1
		cmpi.w	#4,d1
		blt.s	loc_10FCE
		cmp.w	d2,d1
		bge.s	loc_10FBE
		bra.s	Tails_LookUp
; ---------------------------------------------------------------------------

Tails_Balance:				; CODE XREF: Tails_Move+5Ej
		jsr	(ObjHitFloor).l
		cmpi.w	#$C,d1
		blt.s	Tails_LookUp
		cmpi.b	#3,$36(a0)
		bne.s	loc_10FC6

loc_10FBE:				; CODE XREF: Tails_Move+92j
		bclr	#0,$22(a0)
		bra.s	loc_10FD4
; ---------------------------------------------------------------------------

loc_10FC6:				; CODE XREF: Tails_Move+A8j
		cmpi.b	#3,$37(a0)
		bne.s	Tails_LookUp

loc_10FCE:				; CODE XREF: Tails_Move+8Ej
		bset	#0,$22(a0)

loc_10FD4:				; CODE XREF: Tails_Move+B0j
		move.b	#6,$1C(a0)
		bra.s	loc_10FFA
; ---------------------------------------------------------------------------

Tails_LookUp:				; CODE XREF: Tails_Move+74j
					; Tails_Move+94j ...
		btst	#0,($FFFFF606).w
		beq.s	Tails_Duck
		move.b	#7,$1C(a0)
		bra.s	loc_10FFA
; ---------------------------------------------------------------------------

Tails_Duck:				; CODE XREF: Tails_Move+CEj
		btst	#1,($FFFFF606).w
		beq.s	loc_10FFA
		move.b	#8,$1C(a0)

loc_10FFA:				; CODE XREF: Tails_Move+18j
					; Tails_Move+40j ...
		move.b	($FFFFF606).w,d0

loc_10FFE:
		andi.b	#$C,d0
		bne.s	loc_11026
		move.w	$14(a0),d0
		beq.s	loc_11026
		bmi.s	loc_1101A
		sub.w	d5,d0
		bcc.s	loc_11014
		move.w	#0,d0

loc_11014:				; CODE XREF: Tails_Move+FAj
		move.w	d0,$14(a0)
		bra.s	loc_11026
; ---------------------------------------------------------------------------

loc_1101A:				; CODE XREF: Tails_Move+F6j
		add.w	d5,d0
		bcc.s	loc_11022
		move.w	#0,d0

loc_11022:				; CODE XREF: Tails_Move+108j
		move.w	d0,$14(a0)

loc_11026:				; CODE XREF: Tails_Move+10j
					; Tails_Move+EEj ...
		move.b	$26(a0),d0
		jsr	(CalcSine).l
		muls.w	$14(a0),d1
		asr.l	#8,d1
		move.w	d1,$10(a0)
		muls.w	$14(a0),d0
		asr.l	#8,d0
		move.w	d0,$12(a0)

loc_11044:				; CODE XREF: Tails_RollSpeed+AEj
		move.b	$26(a0),d0
		addi.b	#$40,d0	
		bmi.s	locret_110B4
		move.b	#$40,d1	
		tst.w	$14(a0)
		beq.s	locret_110B4
		bmi.s	loc_1105C
		neg.w	d1

loc_1105C:				; CODE XREF: Tails_Move+144j
		move.b	$26(a0),d0
		add.b	d1,d0
		move.w	d0,-(sp)
		bsr.w	Sonic_WalkSpeed
		move.w	(sp)+,d0
		tst.w	d1
		bpl.s	locret_110B4
		asl.w	#8,d1
		addi.b	#$20,d0	
		andi.b	#$C0,d0
		beq.s	loc_110B0
		cmpi.b	#$40,d0	
		beq.s	loc_1109E
		cmpi.b	#$80,d0
		beq.s	loc_11098
		add.w	d1,$10(a0)
		bset	#5,$22(a0)
		move.w	#0,$14(a0)
		rts
; ---------------------------------------------------------------------------

loc_11098:				; CODE XREF: Tails_Move+170j
		sub.w	d1,$12(a0)
		rts
; ---------------------------------------------------------------------------

loc_1109E:				; CODE XREF: Tails_Move+16Aj
		sub.w	d1,$10(a0)
		bset	#5,$22(a0)
		move.w	#0,$14(a0)
		rts
; ---------------------------------------------------------------------------

loc_110B0:				; CODE XREF: Tails_Move+164j
		add.w	d1,$12(a0)

locret_110B4:				; CODE XREF: Tails_Move+138j
					; Tails_Move+142j ...
		rts
; End of function Tails_Move


; =============== S U B	R O U T	I N E =======================================


Tails_MoveLeft:				; CODE XREF: Tails_Move+24p
		move.w	$14(a0),d0
		beq.s	loc_110BE
		bpl.s	loc_110EA

loc_110BE:				; CODE XREF: Tails_MoveLeft+4j
		bset	#0,$22(a0)
		bne.s	loc_110D2
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)

loc_110D2:				; CODE XREF: Tails_MoveLeft+Ej
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_110DE
		move.w	d1,d0

loc_110DE:				; CODE XREF: Tails_MoveLeft+24j
		move.w	d0,$14(a0)
		move.b	#0,$1C(a0)
		rts
; ---------------------------------------------------------------------------

loc_110EA:				; CODE XREF: Tails_MoveLeft+6j
		sub.w	d4,d0
		bcc.s	loc_110F2
		move.w	#$FF80,d0

loc_110F2:				; CODE XREF: Tails_MoveLeft+36j
		move.w	d0,$14(a0)
		move.b	$26(a0),d0
		addi.b	#$20,d0	
		andi.b	#$C0,d0
		bne.s	locret_11120
		cmpi.w	#$400,d0
		blt.s	locret_11120
		move.b	#$D,$1C(a0)
		bclr	#0,$22(a0)
		move.w	#$A4,d0	; "?"
		jsr	(PlaySound_Special).l

locret_11120:				; CODE XREF: Tails_MoveLeft+4Cj
					; Tails_MoveLeft+52j
		rts
; End of function Tails_MoveLeft


; =============== S U B	R O U T	I N E =======================================


Tails_MoveRight:			; CODE XREF: Tails_Move+30p
		move.w	$14(a0),d0
		bmi.s	loc_11150
		bclr	#0,$22(a0)
		beq.s	loc_1113C
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)

loc_1113C:				; CODE XREF: Tails_MoveRight+Cj
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s	loc_11144
		move.w	d6,d0

loc_11144:				; CODE XREF: Tails_MoveRight+1Ej
		move.w	d0,$14(a0)
		move.b	#0,$1C(a0)
		rts
; ---------------------------------------------------------------------------

loc_11150:				; CODE XREF: Tails_MoveRight+4j
		add.w	d4,d0
		bcc.s	loc_11158
		move.w	#$80,d0	

loc_11158:				; CODE XREF: Tails_MoveRight+30j
		move.w	d0,$14(a0)
		move.b	$26(a0),d0
		addi.b	#$20,d0	
		andi.b	#$C0,d0
		bne.s	locret_11186
		cmpi.w	#$FC00,d0
		bgt.s	locret_11186
		move.b	#$D,$1C(a0)
		bset	#0,$22(a0)
		move.w	#$A4,d0	; "?"
		jsr	(PlaySound_Special).l

locret_11186:				; CODE XREF: Tails_MoveRight+46j
					; Tails_MoveRight+4Cj
		rts
; End of function Tails_MoveRight


; =============== S U B	R O U T	I N E =======================================


Tails_RollSpeed:			; CODE XREF: ROM:00010ED2p
		move.w	($FFFFF760).w,d6
		asl.w	#1,d6
		move.w	($FFFFF762).w,d5
		asr.w	#1,d5
		move.w	($FFFFF764).w,d4
		asr.w	#2,d4
		tst.b	($FFFFF7CA).w
		bne.w	loc_11204
		tst.w	$2E(a0)
		bne.s	loc_111C0
		btst	#2,($FFFFF606).w
		beq.s	loc_111B4
		bsr.w	Tails_RollLeft

loc_111B4:				; CODE XREF: Tails_RollSpeed+26j
		btst	#3,($FFFFF606).w
		beq.s	loc_111C0
		bsr.w	Tails_RollRight

loc_111C0:				; CODE XREF: Tails_RollSpeed+1Ej
					; Tails_RollSpeed+32j
		move.w	$14(a0),d0
		beq.s	loc_111E2
		bmi.s	loc_111D6
		sub.w	d5,d0
		bcc.s	loc_111D0
		move.w	#0,d0

loc_111D0:				; CODE XREF: Tails_RollSpeed+42j
		move.w	d0,$14(a0)
		bra.s	loc_111E2
; ---------------------------------------------------------------------------

loc_111D6:				; CODE XREF: Tails_RollSpeed+3Ej
		add.w	d5,d0
		bcc.s	loc_111DE
		move.w	#0,d0

loc_111DE:				; CODE XREF: Tails_RollSpeed+50j
		move.w	d0,$14(a0)

loc_111E2:				; CODE XREF: Tails_RollSpeed+3Cj
					; Tails_RollSpeed+4Cj
		tst.w	$14(a0)
		bne.s	loc_11204
		bclr	#2,$22(a0)
		move.b	#$F,$16(a0)
		move.b	#9,$17(a0)
		move.b	#5,$1C(a0)
		subq.w	#5,$C(a0)

loc_11204:				; CODE XREF: Tails_RollSpeed+16j
					; Tails_RollSpeed+5Ej
		move.b	$26(a0),d0
		jsr	(CalcSine).l
		muls.w	$14(a0),d0
		asr.l	#8,d0
		move.w	d0,$12(a0)
		muls.w	$14(a0),d1
		asr.l	#8,d1
		cmpi.w	#$1000,d1
		ble.s	loc_11228
		move.w	#$1000,d1

loc_11228:				; CODE XREF: Tails_RollSpeed+9Aj
		cmpi.w	#$F000,d1
		bge.s	loc_11232
		move.w	#$F000,d1

loc_11232:				; CODE XREF: Tails_RollSpeed+A4j
		move.w	d1,$10(a0)
		bra.w	loc_11044
; End of function Tails_RollSpeed


; =============== S U B	R O U T	I N E =======================================


Tails_RollLeft:				; CODE XREF: Tails_RollSpeed+28p
		move.w	$14(a0),d0
		beq.s	loc_11242
		bpl.s	loc_11250

loc_11242:				; CODE XREF: Tails_RollLeft+4j
		bset	#0,$22(a0)
		move.b	#2,$1C(a0)
		rts
; ---------------------------------------------------------------------------

loc_11250:				; CODE XREF: Tails_RollLeft+6j
		sub.w	d4,d0
		bcc.s	loc_11258
		move.w	#$FF80,d0

loc_11258:				; CODE XREF: Tails_RollLeft+18j
		move.w	d0,$14(a0)
		rts
; End of function Tails_RollLeft


; =============== S U B	R O U T	I N E =======================================


Tails_RollRight:			; CODE XREF: Tails_RollSpeed+34p
		move.w	$14(a0),d0
		bmi.s	loc_11272
		bclr	#0,$22(a0)
		move.b	#2,$1C(a0)
		rts
; ---------------------------------------------------------------------------

loc_11272:				; CODE XREF: Tails_RollRight+4j
		add.w	d4,d0
		bcc.s	loc_1127A
		move.w	#$80,d0	

loc_1127A:				; CODE XREF: Tails_RollRight+16j
		move.w	d0,$14(a0)
		rts
; End of function Tails_RollRight


; =============== S U B	R O U T	I N E =======================================


Tails_ChgJumpDir:			; CODE XREF: ROM:00010EA4p
					; ROM:00010EEEp
		move.w	($FFFFF760).w,d6
		move.w	($FFFFF762).w,d5
		asl.w	#1,d5
		btst	#4,$22(a0)
		bne.s	loc_112CA
		move.w	$10(a0),d0
		btst	#2,($FFFFF606).w
		beq.s	loc_112B0
		bset	#0,$22(a0)
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_112B0
		move.w	d1,d0

loc_112B0:				; CODE XREF: Tails_ChgJumpDir+1Cj
					; Tails_ChgJumpDir+2Cj
		btst	#3,($FFFFF606).w
		beq.s	loc_112C6
		bclr	#0,$22(a0)
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s	loc_112C6
		move.w	d6,d0

loc_112C6:				; CODE XREF: Tails_ChgJumpDir+36j
					; Tails_ChgJumpDir+42j
		move.w	d0,$10(a0)

loc_112CA:				; CODE XREF: Tails_ChgJumpDir+10j
		cmpi.w	#$60,($FFFFEED8).w 
		beq.s	loc_112DC
		bcc.s	loc_112D8
		addq.w	#4,($FFFFEED8).w

loc_112D8:				; CODE XREF: Tails_ChgJumpDir+52j
		subq.w	#2,($FFFFEED8).w

loc_112DC:				; CODE XREF: Tails_ChgJumpDir+50j
		cmpi.w	#$FC00,$12(a0)
		bcs.s	locret_1130A
		move.w	$10(a0),d0
		move.w	d0,d1
		asr.w	#5,d1
		beq.s	locret_1130A
		bmi.s	loc_112FE
		sub.w	d1,d0
		bcc.s	loc_112F8
		move.w	#0,d0

loc_112F8:				; CODE XREF: Tails_ChgJumpDir+72j
		move.w	d0,$10(a0)
		rts
; ---------------------------------------------------------------------------

loc_112FE:				; CODE XREF: Tails_ChgJumpDir+6Ej
		sub.w	d1,d0
		bcs.s	loc_11306
		move.w	#0,d0

loc_11306:				; CODE XREF: Tails_ChgJumpDir+80j
		move.w	d0,$10(a0)

locret_1130A:				; CODE XREF: Tails_ChgJumpDir+62j
					; Tails_ChgJumpDir+6Cj
		rts
; End of function Tails_ChgJumpDir


; =============== S U B	R O U T	I N E =======================================


Tails_LevelBoundaries:			; CODE XREF: ROM:00010E8Cp
					; ROM:00010EA8p ...

; FUNCTION CHUNK AT 00011E5C SIZE 00000006 BYTES

		move.l	8(a0),d1
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d1
		swap	d1
		move.w	($FFFFEEC8).w,d0
		addi.w	#$10,d0
		cmp.w	d1,d0
		bhi.s	loc_11374
		move.w	($FFFFEECA).w,d0
		addi.w	#$128,d0
		tst.b	($FFFFF7AA).w
		bne.s	loc_1133A
		addi.w	#$40,d0	

loc_1133A:				; CODE XREF: Tails_LevelBoundaries+28j
		cmp.w	d1,d0
		bls.s	loc_11374

loc_1133E:				; CODE XREF: Tails_LevelBoundaries+7Ej
		move.w	($FFFFEECE).w,d0
		addi.w	#$E0,d0	
		cmp.w	$C(a0),d0
		blt.s	loc_1134E
		rts
; ---------------------------------------------------------------------------

loc_1134E:				; CODE XREF: Tails_LevelBoundaries+3Ej
		cmpi.w	#$501,(v_zone).w
		bne.w	KillTails
		cmpi.w	#$2000,8(a0)
		bcs.w	KillTails
		clr.b	($FFFFFE30).w
		move.w	#1,($FFFFFE02).w
		move.w	#$103,(v_zone).w
		rts
; ---------------------------------------------------------------------------

loc_11374:				; CODE XREF: Tails_LevelBoundaries+1Aj
					; Tails_LevelBoundaries+30j
		move.w	d0,8(a0)
		move.w	#0,$A(a0)
		move.w	#0,$10(a0)
		move.w	#0,$14(a0)
		bra.s	loc_1133E
; End of function Tails_LevelBoundaries


; =============== S U B	R O U T	I N E =======================================


Tails_Roll:				; CODE XREF: ROM:00010E88p
		tst.b	($FFFFF7CA).w
		bne.s	locret_113B2
		move.w	$14(a0),d0
		bpl.s	loc_1139A
		neg.w	d0

loc_1139A:				; CODE XREF: Tails_Roll+Aj
		cmpi.w	#$80,d0	
		bcs.s	locret_113B2
		move.b	($FFFFF606).w,d0
		andi.b	#$C,d0
		bne.s	locret_113B2
		btst	#1,($FFFFF606).w
		bne.s	loc_113B4

locret_113B2:				; CODE XREF: Tails_Roll+4j
					; Tails_Roll+12j ...
		rts
; ---------------------------------------------------------------------------

loc_113B4:				; CODE XREF: Tails_Roll+24j
		btst	#2,$22(a0)
		beq.s	loc_113BE
		rts
; ---------------------------------------------------------------------------

loc_113BE:				; CODE XREF: Tails_Roll+2Ej
		bset	#2,$22(a0)
		move.b	#$E,$16(a0)
		move.b	#7,$17(a0)
		move.b	#2,$1C(a0)
		addq.w	#5,$C(a0)
		move.w	#$BE,d0	; "?"
		jsr	(PlaySound_Special).l
		tst.w	$14(a0)
		bne.s	locret_113F0
		move.w	#$200,$14(a0)

locret_113F0:				; CODE XREF: Tails_Roll+5Cj
		rts
; End of function Tails_Roll


; =============== S U B	R O U T	I N E =======================================


Tails_Jump:				; CODE XREF: ROM:00010E7Cp
					; ROM:Obj02_MdRollp
		move.b	($FFFFF607).w,d0
		andi.b	#$70,d0	
		beq.w	locret_11496
		moveq	#0,d0
		move.b	$26(a0),d0

loc_11404:
		addi.b	#$80,d0

loc_11408:
		bsr.w	sub_13102
		cmpi.w	#6,d1
		blt.w	locret_11496
		move.w	#$680,d2
		btst	#6,$22(a0)
		beq.s	loc_11424
		move.w	#$380,d2

loc_11424:				; CODE XREF: Tails_Jump+2Cj
		moveq	#0,d0
		move.b	$26(a0),d0
		subi.b	#$40,d0	
		jsr	(CalcSine).l
		muls.w	d2,d1
		asr.l	#8,d1
		add.w	d1,$10(a0)
		muls.w	d2,d0
		asr.l	#8,d0
		add.w	d0,$12(a0)
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		addq.l	#4,sp
		move.b	#1,$3C(a0)
		clr.b	$38(a0)
		move.w	#$A0,d0	
		jsr	(PlaySound_Special).l
		move.b	#$F,$16(a0)
		move.b	#9,$17(a0)
		btst	#2,$22(a0)
		bne.s	loc_11498
		move.b	#$E,$16(a0)
		move.b	#7,$17(a0)
		move.b	#2,$1C(a0)
		bset	#2,$22(a0)
		addq.w	#5,$C(a0)

locret_11496:				; CODE XREF: Tails_Jump+8j
					; Tails_Jump+1Ej
		rts
; ---------------------------------------------------------------------------

loc_11498:				; CODE XREF: Tails_Jump+86j
		bset	#4,$22(a0)
		rts
; End of function Tails_Jump


; =============== S U B	R O U T	I N E =======================================


Tails_JumpHeight:			; CODE XREF: ROM:Obj02_MdJumpp
					; ROM:Obj02_MdJump2p
		tst.b	$3C(a0)
		beq.s	loc_114CC
		move.w	#$FC00,d1
		btst	#6,$22(a0)
		beq.s	loc_114B6
		move.w	#$FE00,d1

loc_114B6:				; CODE XREF: Tails_JumpHeight+10j
		cmp.w	$12(a0),d1
		ble.s	locret_114CA
		move.b	($FFFFF606).w,d0
		andi.b	#$70,d0	
		bne.s	locret_114CA
		move.w	d1,$12(a0)

locret_114CA:				; CODE XREF: Tails_JumpHeight+1Aj
					; Tails_JumpHeight+24j
		rts
; ---------------------------------------------------------------------------

loc_114CC:				; CODE XREF: Tails_JumpHeight+4j
		cmpi.w	#$F040,$12(a0)
		bge.s	locret_114DA
		move.w	#$F040,$12(a0)

locret_114DA:				; CODE XREF: Tails_JumpHeight+32j
		rts
; End of function Tails_JumpHeight


; =============== S U B	R O U T	I N E =======================================


Tails_Spindash:				; CODE XREF: ROM:Obj02_MdNormalp
		tst.b	$39(a0)
		bne.s	loc_11510
		cmpi.b	#8,$1C(a0)
		bne.s	locret_1150E
		move.b	($FFFFF607).w,d0
		andi.b	#$70,d0	
		beq.w	locret_1150E
		move.b	#9,$1C(a0)
		move.w	#$BE,d0	; "?"
		jsr	(PlaySound_Special).l
		addq.l	#4,sp
		move.b	#1,$39(a0)

locret_1150E:				; CODE XREF: Tails_Spindash+Cj
					; Tails_Spindash+16j
		rts
; ---------------------------------------------------------------------------

loc_11510:				; CODE XREF: Tails_Spindash+4j
		move.b	($FFFFF606).w,d0
		btst	#1,d0
		bne.s	loc_11556
		move.b	#$E,$16(a0)
		move.b	#7,$17(a0)
		move.b	#2,$1C(a0)
		addq.w	#5,$C(a0)
		move.b	#0,$39(a0)
		move.w	#$2000,($FFFFEED0).w
		move.w	#$800,$14(a0)
		btst	#0,$22(a0)
		beq.s	loc_1154E
		neg.w	$14(a0)

loc_1154E:				; CODE XREF: Tails_Spindash+6Cj
		bset	#2,$22(a0)
		rts
; ---------------------------------------------------------------------------

loc_11556:				; CODE XREF: Tails_Spindash+3Cj
		move.b	($FFFFF607).w,d0
		andi.b	#$70,d0	
		beq.w	loc_11564
		nop

loc_11564:				; CODE XREF: Tails_Spindash+82j
		addq.l	#4,sp
		rts
; End of function Tails_Spindash


; =============== S U B	R O U T	I N E =======================================


Tails_SlopeResist:			; CODE XREF: ROM:00010E80p
		move.b	$26(a0),d0
		addi.b	#$60,d0	
		cmpi.b	#$C0,d0
		bcc.s	locret_1159C
		move.b	$26(a0),d0
		jsr	(CalcSine).l
		muls.w	#$20,d0	
		asr.l	#8,d0
		tst.w	$14(a0)
		beq.s	locret_1159C
		bmi.s	loc_11598
		tst.w	d0
		beq.s	locret_11596
		add.w	d0,$14(a0)

locret_11596:				; CODE XREF: Tails_SlopeResist+28j
		rts
; ---------------------------------------------------------------------------

loc_11598:				; CODE XREF: Tails_SlopeResist+24j
		add.w	d0,$14(a0)

locret_1159C:				; CODE XREF: Tails_SlopeResist+Cj
					; Tails_SlopeResist+22j
		rts
; End of function Tails_SlopeResist


; =============== S U B	R O U T	I N E =======================================


Tails_RollRepel:			; CODE XREF: ROM:00010ECEp
		move.b	$26(a0),d0
		addi.b	#$60,d0	
		cmpi.b	#$C0,d0
		bcc.s	locret_115D8
		move.b	$26(a0),d0
		jsr	(CalcSine).l
		muls.w	#$50,d0	
		asr.l	#8,d0
		tst.w	$14(a0)
		bmi.s	loc_115CE
		tst.w	d0
		bpl.s	loc_115C8
		asr.l	#2,d0

loc_115C8:				; CODE XREF: Tails_RollRepel+26j
		add.w	d0,$14(a0)
		rts
; ---------------------------------------------------------------------------

loc_115CE:				; CODE XREF: Tails_RollRepel+22j
		tst.w	d0
		bmi.s	loc_115D4
		asr.l	#2,d0

loc_115D4:				; CODE XREF: Tails_RollRepel+32j
		add.w	d0,$14(a0)

locret_115D8:				; CODE XREF: Tails_RollRepel+Cj
		rts
; End of function Tails_RollRepel


; =============== S U B	R O U T	I N E =======================================


Tails_SlopeRepel:			; CODE XREF: ROM:00010E9Ap
					; ROM:00010EE4p
		nop
		tst.b	$38(a0)
		bne.s	locret_11614
		tst.w	$2E(a0)
		bne.s	loc_11616
		move.b	$26(a0),d0
		addi.b	#$20,d0	
		andi.b	#$C0,d0
		beq.s	locret_11614
		move.w	$14(a0),d0
		bpl.s	loc_115FE
		neg.w	d0

loc_115FE:				; CODE XREF: Tails_SlopeRepel+20j
		cmpi.w	#$280,d0
		bcc.s	locret_11614
		clr.w	$14(a0)
		bset	#1,$22(a0)
		move.w	#$1E,$2E(a0)

locret_11614:				; CODE XREF: Tails_SlopeRepel+6j
					; Tails_SlopeRepel+1Aj	...
		rts
; ---------------------------------------------------------------------------

loc_11616:				; CODE XREF: Tails_SlopeRepel+Cj
		subq.w	#1,$2E(a0)
		rts
; End of function Tails_SlopeRepel


; =============== S U B	R O U T	I N E =======================================


Tails_JumpAngle:			; CODE XREF: ROM:loc_10EC0p
					; ROM:loc_10F0Ap
		move.b	$26(a0),d0
		beq.s	loc_11636
		bpl.s	loc_1162C
		addq.b	#2,d0
		bcc.s	loc_1162A
		moveq	#0,d0

loc_1162A:				; CODE XREF: Tails_JumpAngle+Aj
		bra.s	loc_11632
; ---------------------------------------------------------------------------

loc_1162C:				; CODE XREF: Tails_JumpAngle+6j
		subq.b	#2,d0
		bcc.s	loc_11632
		moveq	#0,d0

loc_11632:				; CODE XREF: Tails_JumpAngle:loc_1162Aj
					; Tails_JumpAngle+12j
		move.b	d0,$26(a0)

loc_11636:				; CODE XREF: Tails_JumpAngle+4j
		move.b	$27(a0),d0
		beq.s	locret_11674
		tst.w	$14(a0)
		bmi.s	loc_1165A
		move.b	$2D(a0),d1
		add.b	d1,d0
		bcc.s	loc_11658
		subq.b	#1,$2C(a0)
		bcc.s	loc_11658
		move.b	#0,$2C(a0)
		moveq	#0,d0

loc_11658:				; CODE XREF: Tails_JumpAngle+2Cj
					; Tails_JumpAngle+32j
		bra.s	loc_11670
; ---------------------------------------------------------------------------

loc_1165A:				; CODE XREF: Tails_JumpAngle+24j
		move.b	$2D(a0),d1
		sub.b	d1,d0
		bcc.s	loc_11670
		subq.b	#1,$2C(a0)
		bcc.s	loc_11670
		move.b	#0,$2C(a0)
		moveq	#0,d0

loc_11670:				; CODE XREF: Tails_JumpAngle:loc_11658j
					; Tails_JumpAngle+44j ...
		move.b	d0,$27(a0)

locret_11674:				; CODE XREF: Tails_JumpAngle+1Ej
		rts
; End of function Tails_JumpAngle


; =============== S U B	R O U T	I N E =======================================


Tails_Floor:				; CODE XREF: ROM:00010EC4p
					; ROM:00010F0Ep ...
		move.b	$3F(a0),d5
		move.w	$10(a0),d1
		move.w	$12(a0),d2
		jsr	(CalcAngle).l
		subi.b	#$20,d0	
		andi.b	#$C0,d0
		cmpi.b	#$40,d0	
		beq.w	loc_11746
		cmpi.b	#$80,d0
		beq.w	loc_117A8
		cmpi.b	#$C0,d0
		beq.w	loc_11804
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_116BA
		sub.w	d1,8(a0)
		move.w	#0,$10(a0)

loc_116BA:				; CODE XREF: Tails_Floor+38j
		bsr.w	sub_132EE
		tst.w	d1
		bpl.s	loc_116CC
		add.w	d1,8(a0)
		move.w	#0,$10(a0)

loc_116CC:				; CODE XREF: Tails_Floor+4Aj
		bsr.w	loc_13146
		tst.w	d1
		bpl.s	locret_11744
		move.b	$12(a0),d2
		addq.b	#8,d2
		neg.b	d2
		cmp.b	d2,d1
		bge.s	loc_116E4
		cmp.b	d2,d0
		blt.s	locret_11744

loc_116E4:				; CODE XREF: Tails_Floor+68j
		add.w	d1,$C(a0)
		move.b	d3,$26(a0)
		bsr.w	Tails_ResetTailsOnFloor
		move.b	#0,$1C(a0)
		move.b	d3,d0
		addi.b	#$20,d0	
		andi.b	#$40,d0	
		bne.s	loc_11722
		move.b	d3,d0
		addi.b	#$10,d0
		andi.b	#$20,d0	
		beq.s	loc_11714
		asr	$12(a0)
		bra.s	loc_11736
; ---------------------------------------------------------------------------

loc_11714:				; CODE XREF: Tails_Floor+96j
		move.w	#0,$12(a0)
		move.w	$10(a0),$14(a0)
		rts
; ---------------------------------------------------------------------------

loc_11722:				; CODE XREF: Tails_Floor+8Aj
		move.w	#0,$10(a0)
		cmpi.w	#$FC0,$12(a0)
		ble.s	loc_11736
		move.w	#$FC0,$12(a0)

loc_11736:				; CODE XREF: Tails_Floor+9Cj
					; Tails_Floor+B8j
		move.w	$12(a0),$14(a0)
		tst.b	d3
		bpl.s	locret_11744
		neg.w	$14(a0)

locret_11744:				; CODE XREF: Tails_Floor+5Cj
					; Tails_Floor+6Cj ...
		rts
; ---------------------------------------------------------------------------

loc_11746:				; CODE XREF: Tails_Floor+1Ej
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_11760
		sub.w	d1,8(a0)
		move.w	#0,$10(a0)
		move.w	$12(a0),$14(a0)
		rts
; ---------------------------------------------------------------------------

loc_11760:				; CODE XREF: Tails_Floor+D6j
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	loc_1177A
		sub.w	d1,$C(a0)
		tst.w	$12(a0)
		bpl.s	locret_11778
		move.w	#0,$12(a0)

locret_11778:				; CODE XREF: Tails_Floor+FAj
		rts
; ---------------------------------------------------------------------------

loc_1177A:				; CODE XREF: Tails_Floor+F0j
		tst.w	$12(a0)
		bmi.s	locret_117A6
		bsr.w	loc_13146
		tst.w	d1
		bpl.s	locret_117A6
		add.w	d1,$C(a0)
		move.b	d3,$26(a0)
		bsr.w	Tails_ResetTailsOnFloor
		move.b	#0,$1C(a0)
		move.w	#0,$12(a0)
		move.w	$10(a0),$14(a0)

locret_117A6:				; CODE XREF: Tails_Floor+108j
					; Tails_Floor+110j
		rts
; ---------------------------------------------------------------------------

loc_117A8:				; CODE XREF: Tails_Floor+26j
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_117BA
		sub.w	d1,8(a0)
		move.w	#0,$10(a0)

loc_117BA:				; CODE XREF: Tails_Floor+138j
		bsr.w	sub_132EE
		tst.w	d1
		bpl.s	loc_117CC
		add.w	d1,8(a0)
		move.w	#0,$10(a0)

loc_117CC:				; CODE XREF: Tails_Floor+14Aj
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	locret_11802
		sub.w	d1,$C(a0)
		move.b	d3,d0
		addi.b	#$20,d0	
		andi.b	#$40,d0	
		bne.s	loc_117EC
		move.w	#0,$12(a0)
		rts
; ---------------------------------------------------------------------------

loc_117EC:				; CODE XREF: Tails_Floor+16Cj
		move.b	d3,$26(a0)
		bsr.w	Tails_ResetTailsOnFloor
		move.w	$12(a0),$14(a0)
		tst.b	d3
		bpl.s	locret_11802
		neg.w	$14(a0)

locret_11802:				; CODE XREF: Tails_Floor+15Cj
					; Tails_Floor+186j
		rts
; ---------------------------------------------------------------------------

loc_11804:				; CODE XREF: Tails_Floor+2Ej
		bsr.w	sub_132EE
		tst.w	d1
		bpl.s	loc_1181E
		add.w	d1,8(a0)
		move.w	#0,$10(a0)
		move.w	$12(a0),$14(a0)
		rts
; ---------------------------------------------------------------------------

loc_1181E:				; CODE XREF: Tails_Floor+194j
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	loc_11838
		sub.w	d1,$C(a0)
		tst.w	$12(a0)
		bpl.s	locret_11836
		move.w	#0,$12(a0)

locret_11836:				; CODE XREF: Tails_Floor+1B8j
		rts
; ---------------------------------------------------------------------------

loc_11838:				; CODE XREF: Tails_Floor+1AEj
		tst.w	$12(a0)
		bmi.s	locret_11864
		bsr.w	loc_13146
		tst.w	d1
		bpl.s	locret_11864
		add.w	d1,$C(a0)
		move.b	d3,$26(a0)
		bsr.w	Tails_ResetTailsOnFloor
		move.b	#0,$1C(a0)
		move.w	#0,$12(a0)
		move.w	$10(a0),$14(a0)

locret_11864:				; CODE XREF: Tails_Floor+1C6j
					; Tails_Floor+1CEj
		rts
; End of function Tails_Floor


; =============== S U B	R O U T	I N E =======================================


Tails_ResetTailsOnFloor:		; CODE XREF: sub_F8F8:loc_F954p
					; Tails_Floor+76p ...
		btst	#4,$22(a0)
		beq.s	loc_11874
		nop
		nop
		nop

loc_11874:				; CODE XREF: Tails_ResetTailsOnFloor+6j
		bclr	#5,$22(a0)
		bclr	#1,$22(a0)
		bclr	#4,$22(a0)
		btst	#2,$22(a0)
		beq.s	loc_118AA
		bclr	#2,$22(a0)
		move.b	#$F,$16(a0)
		move.b	#9,$17(a0)
		move.b	#0,$1C(a0)
		subq.w	#1,$C(a0)

loc_118AA:				; CODE XREF: Tails_ResetTailsOnFloor+26j
		move.b	#0,$3C(a0)
		move.w	#0,($FFFFF7D0).w
		move.b	#0,$27(a0)
		rts
; End of function Tails_ResetTailsOnFloor

; ---------------------------------------------------------------------------

Obj02_Hurt:				; DATA XREF: ROM:Obj02_Indexo
		jsr	SpeedToPos
		addi.w	#$30,$12(a0) 
		btst	#6,$22(a0)
		beq.s	loc_118D8
		subi.w	#$20,$12(a0) 

loc_118D8:				; CODE XREF: ROM:000118D0j
		bsr.w	Tails_HurtStop
		bsr.w	Tails_LevelBoundaries
		bsr.w	Tails_Animate
		bsr.w	LoadTailsDynPLC
		jmp	DisplaySprite

; =============== S U B	R O U T	I N E =======================================


Tails_HurtStop:				; CODE XREF: ROM:loc_118D8p
		move.w	($FFFFEECE).w,d0
		addi.w	#$E0,d0	
		cmp.w	$C(a0),d0
		bcs.w	KillTails
		bsr.w	Tails_Floor
		btst	#1,$22(a0)
		bne.s	locret_1192A
		moveq	#0,d0
		move.w	d0,$12(a0)
		move.w	d0,$10(a0)
		move.w	d0,$14(a0)
		move.b	#0,$1C(a0)
		move.b	#2,$24(a0)
		move.w	#$78,$30(a0) 

locret_1192A:				; CODE XREF: Tails_HurtStop+1Aj
		rts
; End of function Tails_HurtStop

; ---------------------------------------------------------------------------

Obj02_Death:				; DATA XREF: ROM:Obj02_Indexo
		bsr.w	Tails_GameOver
		jsr	ObjectFall
		bsr.w	Tails_Animate
		bsr.w	LoadTailsDynPLC
		jmp	DisplaySprite

; =============== S U B	R O U T	I N E =======================================


Tails_GameOver:				; CODE XREF: ROM:Obj02_Deathp
		move.w	($FFFFEECE).w,d0
		addi.w	#$100,d0
		cmp.w	$C(a0),d0
		bcc.w	locret_11986
		move.w	(v_objspace+8).w,d0
		subi.w	#$40,d0	
		move.w	d0,8(a0)
		move.w	(v_objspace+$C).w,d0
		subi.w	#$80,d0	
		move.w	d0,$C(a0)
		move.b	#2,$24(a0)
		andi.w	#$7FFF,2(a0)
		move.b	#$C,$3E(a0)
		move.b	#$D,$3F(a0)
		nop

locret_11986:				; CODE XREF: Tails_GameOver+Cj
		rts
; End of function Tails_GameOver

; ---------------------------------------------------------------------------

Obj02_ResetLevel:			; DATA XREF: ROM:Obj02_Indexo
		tst.w	$3A(a0)
		beq.s	locret_1199A
		subq.w	#1,$3A(a0)
		bne.s	locret_1199A
		move.w	#1,($FFFFFE02).w

locret_1199A:				; CODE XREF: ROM:0001198Cj
					; ROM:00011992j
		rts

; =============== S U B	R O U T	I N E =======================================


Tails_Animate:				; CODE XREF: ROM:00010CECp
					; ROM:000118E0p ...

; FUNCTION CHUNK AT 00011A2E SIZE 000001AE BYTES

		lea	(TailsAniData).l,a1

Tails_Animate2:				; CODE XREF: ROM:00011DECp
		moveq	#0,d0
		move.b	$1C(a0),d0
		cmp.b	$1D(a0),d0
		beq.s	loc_119BE
		move.b	d0,$1D(a0)
		move.b	#0,$1B(a0)
		move.b	#0,$1E(a0)

loc_119BE:				; CODE XREF: Tails_Animate+10j
		add.w	d0,d0
		adda.w	(a1,d0.w),a1
		move.b	(a1),d0
		bmi.s	loc_11A2E
		move.b	$22(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		subq.b	#1,$1E(a0)
		bpl.s	locret_119FC
		move.b	d0,$1E(a0)
; End of function Tails_Animate


; =============== S U B	R O U T	I N E =======================================


sub_119E4:				; CODE XREF: Tails_Animate+10Ep
					; Tails_Animate+1B2j ...
		moveq	#0,d1
		move.b	$1B(a0),d1
		move.b	1(a1,d1.w),d0
		cmpi.b	#$F0,d0
		bcc.s	loc_119FE

loc_119F4:				; CODE XREF: sub_119E4+28j
					; sub_119E4+3Cj
		move.b	d0,$1A(a0)
		addq.b	#1,$1B(a0)

locret_119FC:				; CODE XREF: Tails_Animate+42j
					; Tails_Animate+96j
		rts
; ---------------------------------------------------------------------------

loc_119FE:				; CODE XREF: sub_119E4+Ej
		addq.b	#1,d0
		bne.s	loc_11A0E
		move.b	#0,$1B(a0)
		move.b	1(a1),d0
		bra.s	loc_119F4
; ---------------------------------------------------------------------------

loc_11A0E:				; CODE XREF: sub_119E4+1Cj
		addq.b	#1,d0
		bne.s	loc_11A22
		move.b	2(a1,d1.w),d0
		sub.b	d0,$1B(a0)
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0
		bra.s	loc_119F4
; ---------------------------------------------------------------------------

loc_11A22:				; CODE XREF: sub_119E4+2Cj
		addq.b	#1,d0
		bne.s	locret_11A2C
		move.b	2(a1,d1.w),$1C(a0)

locret_11A2C:				; CODE XREF: sub_119E4+40j
		rts
; End of function sub_119E4

; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR Tails_Animate

loc_11A2E:				; CODE XREF: Tails_Animate+2Aj
		subq.b	#1,$1E(a0)
		bpl.s	locret_119FC
		addq.b	#1,d0
		bne.w	loc_11B0E
		moveq	#0,d0
		move.b	$27(a0),d0
		bne.w	loc_11AB4
		moveq	#0,d1
		move.b	$26(a0),d0
		move.b	$22(a0),d2
		andi.b	#1,d2
		bne.s	loc_11A56
		not.b	d0

loc_11A56:				; CODE XREF: Tails_Animate+B6j
		addi.b	#$10,d0
		bpl.s	loc_11A5E
		moveq	#3,d1

loc_11A5E:				; CODE XREF: Tails_Animate+BEj
		andi.b	#$FC,1(a0)
		eor.b	d1,d2
		or.b	d2,1(a0)
		lsr.b	#4,d0
		andi.b	#6,d0
		move.w	$14(a0),d2
		bpl.s	loc_11A78
		neg.w	d2

loc_11A78:				; CODE XREF: Tails_Animate+D8j
		move.b	d0,d3
		add.b	d3,d3
		add.b	d3,d3
		lea	(TailsAni_Walk).l,a1
		cmpi.w	#$600,d2
		bcs.s	loc_11A9A
		lea	(TailsAni_Run).l,a1
		move.b	d0,d1
		lsr.b	#1,d1
		add.b	d1,d0
		add.b	d0,d0
		move.b	d0,d3

loc_11A9A:				; CODE XREF: Tails_Animate+ECj
		neg.w	d2
		addi.w	#$800,d2
		bpl.s	loc_11AA4
		moveq	#0,d2

loc_11AA4:				; CODE XREF: Tails_Animate+104j
		lsr.w	#8,d2
		move.b	d2,$1E(a0)
		bsr.w	sub_119E4
		add.b	d3,$1A(a0)
		rts
; ---------------------------------------------------------------------------

loc_11AB4:				; CODE XREF: Tails_Animate+A4j
		move.b	$27(a0),d0
		moveq	#0,d1
		move.b	$22(a0),d2
		andi.b	#1,d2
		bne.s	loc_11AE8
		andi.b	#$FC,1(a0)
		moveq	#0,d2
		or.b	d2,1(a0)
		addi.b	#$B,d0
		divu.w	#$16,d0
		addi.b	#$75,d0	
		move.b	d0,$1A(a0)
		move.b	#0,$1E(a0)
		rts
; ---------------------------------------------------------------------------

loc_11AE8:				; CODE XREF: Tails_Animate+126j
		moveq	#3,d2
		andi.b	#$FC,1(a0)
		or.b	d2,1(a0)
		neg.b	d0
		addi.b	#$8F,d0
		divu.w	#$16,d0
		addi.b	#$75,d0	
		move.b	d0,$1A(a0)
		move.b	#0,$1E(a0)
		rts
; ---------------------------------------------------------------------------

loc_11B0E:				; CODE XREF: Tails_Animate+9Aj
		addq.b	#1,d0
		bne.s	loc_11B52
		move.w	$14(a0),d2
		bpl.s	loc_11B1A
		neg.w	d2

loc_11B1A:				; CODE XREF: Tails_Animate+17Aj
		lea	(TailsAni_Roll2).l,a1
		cmpi.w	#$600,d2
		bcc.s	loc_11B2C
		lea	(TailsAni_Roll).l,a1

loc_11B2C:				; CODE XREF: Tails_Animate+188j
		neg.w	d2
		addi.w	#$400,d2
		bpl.s	loc_11B36
		moveq	#0,d2

loc_11B36:				; CODE XREF: Tails_Animate+196j
		lsr.w	#8,d2
		move.b	d2,$1E(a0)
		move.b	$22(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		bra.w	sub_119E4
; ---------------------------------------------------------------------------

loc_11B52:				; CODE XREF: Tails_Animate+174j
		addq.b	#1,d0
		bne.s	loc_11B88
		move.w	$14(a0),d2
		bmi.s	loc_11B5E
		neg.w	d2

loc_11B5E:				; CODE XREF: Tails_Animate+1BEj
		addi.w	#$800,d2
		bpl.s	loc_11B66
		moveq	#0,d2

loc_11B66:				; CODE XREF: Tails_Animate+1C6j
		lsr.w	#6,d2
		move.b	d2,$1E(a0)
		lea	(TailsAni_Push_NoArt).l,a1
		move.b	$22(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		bra.w	sub_119E4
; ---------------------------------------------------------------------------

loc_11B88:				; CODE XREF: Tails_Animate+1B8j
		move.w	(v_objspace+$50).w,d1
		move.w	(v_objspace+$52).w,d2
		jsr	(CalcAngle).l
		moveq	#0,d1
		move.b	$22(a0),d2
		andi.b	#1,d2
		bne.s	loc_11BA6
		not.b	d0
		bra.s	loc_11BAA
; ---------------------------------------------------------------------------

loc_11BA6:				; CODE XREF: Tails_Animate+204j
		addi.b	#$80,d0

loc_11BAA:				; CODE XREF: Tails_Animate+208j
		addi.b	#$10,d0
		bpl.s	loc_11BB2
		moveq	#3,d1

loc_11BB2:				; CODE XREF: Tails_Animate+212j
		andi.b	#$FC,1(a0)
		eor.b	d1,d2
		or.b	d2,1(a0)
		lsr.b	#3,d0
		andi.b	#$C,d0
		move.b	d0,d3
		lea	(byte_11E3C).l,a1
		move.b	#3,$1E(a0)
		bsr.w	sub_119E4
		add.b	d3,$1A(a0)
		rts
; END OF FUNCTION CHUNK	FOR Tails_Animate
; ---------------------------------------------------------------------------
TailsAniData:	dc.w TailsAni_Walk-TailsAniData,TailsAni_Run-TailsAniData; 0
					; DATA XREF: Tails_Animateo
					; ROM:TailsAniDatao ...
		dc.w TailsAni_Roll-TailsAniData,TailsAni_Roll2-TailsAniData; 2
		dc.w TailsAni_Push_NoArt-TailsAniData,TailsAni_Wait-TailsAniData; 4
		dc.w TailsAni_Balance_NoArt-TailsAniData,TailsAni_LookUp-TailsAniData; 6
		dc.w TailsAni_Duck-TailsAniData,TailsAni_Spindash-TailsAniData;	8
		dc.w TailsAni_0A-TailsAniData,TailsAni_0B-TailsAniData;	10
		dc.w TailsAni_0C-TailsAniData,TailsAni_Stop-TailsAniData; 12
		dc.w TailsAni_Fly-TailsAniData,TailsAni_0F-TailsAniData; 14
		dc.w TailsAni_Jump-TailsAniData,TailsAni_11-TailsAniData; 16
		dc.w TailsAni_12-TailsAniData,TailsAni_13-TailsAniData;	18
		dc.w TailsAni_14-TailsAniData,TailsAni_15-TailsAniData;	20
		dc.w TailsAni_Death1-TailsAniData,TailsAni_UnusedDrown-TailsAniData; 22
		dc.w TailsAni_Death2-TailsAniData,TailsAni_19-TailsAniData; 24
		dc.w TailsAni_1A-TailsAniData,TailsAni_1B-TailsAniData;	26
		dc.w TailsAni_1C-TailsAniData,TailsAni_1D-TailsAniData;	28
		dc.w TailsAni_1E-TailsAniData; 30
TailsAni_Walk:	dc.b $FF,$10,$11,$12,$13,$14,$15, $E, $F,$FF; 0
					; DATA XREF: Tails_Animate+E2o
					; ROM:TailsAniDatao
TailsAni_Run:	dc.b $FF,$2E,$2F,$30,$31,$FF,$FF,$FF,$FF,$FF; 0
					; DATA XREF: Tails_Animate+EEo
					; ROM:TailsAniDatao
TailsAni_Roll:	dc.b   1,$48,$47,$46,$FF; 0 ; DATA XREF: Tails_Animate+18Ao
					; ROM:TailsAniDatao
TailsAni_Roll2:	dc.b   1,$48,$47,$46,$FF; 0 ; DATA XREF: Tails_Animate:loc_11B1Ao
					; ROM:TailsAniDatao
TailsAni_Push_NoArt:dc.b $FD,  9, $A, $B, $C, $D, $E,$FF; 0 ; DATA XREF: Tails_Animate+1D0o
					; ROM:TailsAniDatao
TailsAni_Wait:	dc.b   7,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  3,  2,  1,  1,  1; 0
					; DATA XREF: ROM:TailsAniDatao
		dc.b   1,  1,  1,  1,  1,  3,  2,  1,  1,  1,  1,  1,  1,  1,  1,  1; 16
		dc.b   5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5; 32
		dc.b   6,  7,  8,  7,  8,  7,  8,  7,  8,  7,  8,  6,$FE,$1C; 48
TailsAni_Balance_NoArt:dc.b $1F,  1,  2,  3,  4,  5,  6,  7,  8,$FF; 0
					; DATA XREF: ROM:TailsAniDatao
TailsAni_LookUp:dc.b $3F,  4,$FF	; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_Duck:	dc.b $3F,$5B,$FF	; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_Spindash:dc.b	 0,$60,$61,$62,$FF; 0 ;	DATA XREF: ROM:TailsAniDatao
TailsAni_0A:	dc.b $3F,$82,$FF	; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_0B:	dc.b   7,  8,  8,  9,$FD,  5; 0	; DATA XREF: ROM:TailsAniDatao
TailsAni_0C:	dc.b   7,  9,$FD,  5	; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_Stop:	dc.b   7,  1,  2,$FF	; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_Fly:	dc.b   7,$5E,$5F,$FF	; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_0F:	dc.b   7,  1,  2,  3,  4,  5,$FF; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_Jump:	dc.b   3,$59,$5A,$59,$5A,$59,$5A,$59,$5A,$59,$5A,$59,$5A,$FD,  0; 0
					; DATA XREF: ROM:TailsAniDatao
TailsAni_11:	dc.b   4,  1,  2,$FF	; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_12:	dc.b  $F,  1,  2,  3,$FE,  1; 0	; DATA XREF: ROM:TailsAniDatao
TailsAni_13:	dc.b  $F,  1,  2,$FE,  1; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_14:	dc.b $3F,  1,$FF	; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_15:	dc.b  $B,  1,  2,  3,  4,$FD,  0; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_Death1:dc.b $20,$5D,$FF	; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_UnusedDrown:dc.b $2F,$5D,$FF	     ; 0 ; DATA	XREF: ROM:TailsAniDatao
TailsAni_Death2:dc.b   3,$5D,$FF	; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_19:	dc.b   3,$5D,$FF	; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_1A:	dc.b   3,$5C,$FF	; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_1B:	dc.b   7,  1,  1,$FF	; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_1C:	dc.b $77,  0,$FD,  0	; 0 ; DATA XREF: ROM:TailsAniDatao
TailsAni_1D:	dc.b   3,  1,  2,  3,  4,  5,  6,  7,  8,$FF; 0
					; DATA XREF: ROM:TailsAniDatao
TailsAni_1E:	dc.b   3,  1,  2,  3,  4,  5,  6,  7,  8,$FF; 0
					; DATA XREF: ROM:TailsAniDatao

; =============== S U B	R O U T	I N E =======================================

; loads	the tails patterns in a	buffer at F600
; as opposed to	the usual F400

LoadTailsDynPLC_F600:			; CODE XREF: ROM:00011DF0p
		moveq	#0,d0
		move.b	$1A(a0),d0
		cmp.b	($FFFFF7DF).w,d0
		beq.s	locret_11D7C
		move.b	d0,($FFFFF7DF).w
		lea	(TailsDynPLC).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d5
		subq.w	#1,d5
		bmi.s	locret_11D7C
		move.w	#$F600,d4
		bra.s	loc_11D50
; End of function LoadTailsDynPLC_F600


; =============== S U B	R O U T	I N E =======================================


LoadTailsDynPLC:			; CODE XREF: ROM:loc_10CFCp
					; ROM:000118E4p ...
		moveq	#0,d0
		move.b	$1A(a0),d0
		cmp.b	($FFFFF7DE).w,d0
		beq.s	locret_11D7C
		move.b	d0,($FFFFF7DE).w
		lea	(TailsDynPLC).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d5
		subq.w	#1,d5
		bmi.s	locret_11D7C
		move.w	#$F400,d4

loc_11D50:				; CODE XREF: LoadTailsDynPLC_F600+26j
					; LoadTailsDynPLC+4Ej
		moveq	#0,d1
		move.w	(a2)+,d1
		move.w	d1,d3
		lsr.w	#8,d3
		andi.w	#$F0,d3	; "?"
		addi.w	#$10,d3
		andi.w	#$FFF,d1
		lsl.l	#5,d1
		addi.l	#Art_Tails,d1
		move.w	d4,d2
		add.w	d3,d4
		add.w	d3,d4
		jsr	(DMA_68KtoVRAM).l
		dbf	d5,loc_11D50

locret_11D7C:				; CODE XREF: LoadTailsDynPLC_F600+Aj
					; LoadTailsDynPLC_F600+20j ...
		rts
; End of function LoadTailsDynPLC

; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 05 - Tails" tails
;----------------------------------------------------

Obj05:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj05_Index(pc,d0.w),d1
		jmp	Obj05_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj05_Index:	dc.w Obj05_Init-Obj05_Index ; DATA XREF: ROM:Obj05_Indexo
					; ROM:00011D8Eo
		dc.w Obj05_Main-Obj05_Index
; ---------------------------------------------------------------------------

Obj05_Init:				; DATA XREF: ROM:Obj05_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Tails,4(a0)
		move.w	#$7B0,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#2,$18(a0)
		move.b	#$18,$19(a0)
		move.b	#4,1(a0)

Obj05_Main:				; DATA XREF: ROM:00011D8Eo
		move.b	(v_objspace+$66).w,$26(a0)
		move.b	(v_objspace+$62).w,$22(a0)
		move.w	(v_objspace+$48).w,8(a0)
		move.w	(v_objspace+$4C).w,$C(a0)
		moveq	#0,d0
		move.b	(v_objspace+$5C).w,d0
		cmp.b	$30(a0),d0
		beq.s	loc_11DE6
		move.b	d0,$30(a0)
		move.b	Obj05_Animations(pc,d0.w),$1C(a0)

loc_11DE6:				; CODE XREF: ROM:00011DDAj
		lea	(Obj05_AniData).l,a1
		bsr.w	Tails_Animate2
		bsr.w	LoadTailsDynPLC_F600 ; loads the tails patterns	in a buffer at F600
					; as opposed to	the usual F400
		jsr	(DisplaySprite).l
		rts
; ---------------------------------------------------------------------------
Obj05_Animations:dc.b	0,  0		 ; 0
		dc.b   3,  3		; 2
		dc.b   0,  1		; 4
		dc.b   0,  2		; 6
		dc.b   1,  7		; 8
		dc.b   0,  0		; 10
		dc.b   0,  0		; 12
		dc.b   0,  0		; 14
		dc.b   0,  0		; 16
		dc.b   0,  0		; 18
		dc.b   0,  0		; 20
		dc.b   0,  0		; 22
		dc.b   0,  0		; 24
		dc.b   0,  0		; 26
		dc.b   0,  0		; 28
Obj05_AniData:	dc.w byte_11E2A-Obj05_AniData ;	DATA XREF: ROM:loc_11DE6o
					; ROM:Obj05_AniDatao ...
		dc.w byte_11E2D-Obj05_AniData
		dc.w byte_11E34-Obj05_AniData
		dc.w byte_11E3C-Obj05_AniData
		dc.w byte_11E42-Obj05_AniData
		dc.w byte_11E48-Obj05_AniData
		dc.w byte_11E4E-Obj05_AniData
		dc.w byte_11E54-Obj05_AniData
byte_11E2A:	dc.b $20,  0,$FF	; 0 ; DATA XREF: ROM:Obj05_AniDatao
byte_11E2D:	dc.b   7,  9, $A, $B, $C, $D,$FF; 0 ; DATA XREF: ROM:00011E1Co
byte_11E34:	dc.b   3,  9, $A, $B, $C, $D,$FD,  1; 0	; DATA XREF: ROM:00011E1Eo
byte_11E3C:	dc.b $FC,$49,$4A,$4B,$4C,$FF; 0	; DATA XREF: Tails_Animate+22Ao
					; ROM:00011E20o
byte_11E42:	dc.b   3,$4D,$4E,$4F,$50,$FF; 0	; DATA XREF: ROM:00011E22o
byte_11E48:	dc.b   3,$51,$52,$53,$54,$FF; 0	; DATA XREF: ROM:00011E24o
byte_11E4E:	dc.b   3,$55,$56,$57,$58,$FF; 0	; DATA XREF: ROM:00011E26o
byte_11E54:	dc.b   2,$81,$82,$83,$84,$FF; 0	; DATA XREF: ROM:00011E28o
; ---------------------------------------------------------------------------
		nop
; START	OF FUNCTION CHUNK FOR Tails_LevelBoundaries

KillTails:				; CODE XREF: Tails_LevelBoundaries+48j
					; Tails_LevelBoundaries+52j ...
		jmp	KillSonic
; END OF FUNCTION CHUNK	FOR Tails_LevelBoundaries
; ---------------------------------------------------------------------------
        if removeJmpTos=0
		align 4
	endif	
;----------------------------------------------------
; Object 0A - drowning bubbles and countdown numbers
;----------------------------------------------------

Obj0A:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj0A_Index(pc,d0.w),d1
		jmp	Obj0A_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj0A_Index:	dc.w Obj0A_Init-Obj0A_Index ; DATA XREF: ROM:Obj0A_Indexo
					; ROM:00011E74o ...
		dc.w Obj0A_Animate-Obj0A_Index
		dc.w Obj0A_ChkWater-Obj0A_Index
		dc.w Obj0A_Display-Obj0A_Index
		dc.w Obj0A_Delete-Obj0A_Index
		dc.w Obj0A_Countdown-Obj0A_Index
		dc.w Obj0A_AirLeft-Obj0A_Index
		dc.w Obj0A_Display-Obj0A_Index
		dc.w Obj0A_Delete-Obj0A_Index
; ---------------------------------------------------------------------------

Obj0A_Init:				; DATA XREF: ROM:Obj0A_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj0A_Bubbles,4(a0)
		move.w	#$8348,2(a0)
		move.b	#$84,1(a0)
		move.b	#$10,$19(a0)
		move.b	#1,$18(a0)
		move.b	$28(a0),d0
		bpl.s	loc_11ECC
		addq.b	#8,$24(a0)
		move.l	#Map_Obj0A_Countdown,4(a0)
		move.w	#$440,2(a0)
		andi.w	#$7F,d0	
		move.b	d0,$33(a0)
		bra.w	Obj0A_Countdown
; ---------------------------------------------------------------------------

loc_11ECC:				; CODE XREF: ROM:00011EACj
		move.b	d0,$1C(a0)
		bsr.w	ModifySpriteAttr_2P
		move.w	8(a0),$30(a0)
		move.w	#$FF78,$12(a0)

Obj0A_Animate:				; DATA XREF: ROM:00011E74o
		lea	(Ani_Obj0A).l,a1
		jsr	AnimateSprite

Obj0A_ChkWater:				; DATA XREF: ROM:00011E76o
		move.w	($FFFFF646).w,d0
		cmp.w	$C(a0),d0
		bcs.s	loc_11F0A
		move.b	#6,$24(a0)
		addq.b	#7,$1C(a0)
		cmpi.b	#$D,$1C(a0)
		beq.s	Obj0A_Display
		bra.s	Obj0A_Display
; ---------------------------------------------------------------------------

loc_11F0A:				; CODE XREF: ROM:00011EF4j
		tst.b	($FFFFF7C7).w
		beq.s	loc_11F14
		addq.w	#4,$30(a0)

loc_11F14:				; CODE XREF: ROM:00011F0Ej
		move.b	$26(a0),d0
		addq.b	#1,$26(a0)
		andi.w	#$7F,d0	
		lea	(Obj0A_WobbleData).l,a1
		move.b	(a1,d0.w),d0
		ext.w	d0
		add.w	$30(a0),d0
		move.w	d0,8(a0)
		bsr.s	Obj0A_ShowNumber
		jsr	SpeedToPos
		tst.b	1(a0)
		bpl.s	loc_11F48
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_11F48:				; CODE XREF: ROM:00011F40j
		jmp	DeleteObject
; ---------------------------------------------------------------------------

Obj0A_Display:				; CODE XREF: ROM:00011F06j
					; ROM:00011F08j ...
		bsr.s	Obj0A_ShowNumber
		lea	(Ani_Obj0A).l,a1
		jsr	AnimateSprite
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

Obj0A_Delete:				; DATA XREF: ROM:00011E7Ao
					; ROM:00011E82o
		jmp	DeleteObject
; ---------------------------------------------------------------------------

Obj0A_AirLeft:				; DATA XREF: ROM:00011E7Eo
		cmpi.w	#$C,($FFFFFE14).w
		bhi.s	loc_11F9A
		subq.w	#1,$38(a0)
		bne.s	loc_11F82
		move.b	#$E,$24(a0)
		addq.b	#7,$1C(a0)
		bra.s	Obj0A_Display
; ---------------------------------------------------------------------------

loc_11F82:				; CODE XREF: ROM:00011F74j
		lea	(Ani_Obj0A).l,a1
		jsr	AnimateSprite
		tst.b	1(a0)
		bpl.s	loc_11F9A
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_11F9A:				; CODE XREF: ROM:00011F6Ej
					; ROM:00011F92j
		jmp	DeleteObject

; =============== S U B	R O U T	I N E =======================================


Obj0A_ShowNumber:			; CODE XREF: ROM:00011F34p
					; ROM:Obj0A_Displayp
		tst.w	$38(a0)
		beq.s	locret_11FEA
		subq.w	#1,$38(a0)
		bne.s	locret_11FEA
		cmpi.b	#7,$1C(a0)
		bcc.s	locret_11FEA
		move.w	#$F,$38(a0)
		clr.w	$12(a0)
		move.b	#$80,1(a0)
		move.w	8(a0),d0
		sub.w	(v_screenposx).w,d0
		addi.w	#$80,d0	
		move.w	d0,8(a0)
		move.w	$C(a0),d0
		sub.w	(v_screenposy).w,d0
		addi.w	#$80,d0	
		move.w	d0,$A(a0)
		move.b	#$C,$24(a0)

locret_11FEA:				; CODE XREF: Obj0A_ShowNumber+4j
					; Obj0A_ShowNumber+Aj ...
		rts
; End of function Obj0A_ShowNumber

; ---------------------------------------------------------------------------
Obj0A_WobbleData:dc.b	 0,   0,   0,	0,   0,	  0,   1,   1,	 1,   1,   1,	2,   2,	  2,   2,   2; 0
					; DATA XREF: ROM:00005E84o
					; ROM:00011F20o ...
		dc.b	2,   2,	  3,   3,   3,	 3,   3,   3,	3,   3,	  3,   3,   3,	 3,   3,   3; 16
		dc.b	3,   3,	  3,   3,   3,	 3,   3,   3,	3,   3,	  3,   3,   3,	 3,   3,   2; 32
		dc.b	2,   2,	  2,   2,   2,	 2,   1,   1,	1,   1,	  1,   0,   0,	 0,   0,   0; 48
		dc.b	0,  -1,	 -1,  -1,  -1,	-1,  -2,  -2,  -2,  -2,	 -2,  -3,  -3,	-3,  -3,  -3; 64
		dc.b   -3,  -3,	 -4,  -4,  -4,	-4,  -4,  -4,  -4,  -4,	 -4,  -4,  -4,	-4,  -4,  -4; 80
		dc.b   -4,  -4,	 -4,  -4,  -4,	-4,  -4,  -4,  -4,  -4,	 -4,  -4,  -4,	-4,  -4,  -3; 96
		dc.b   -3,  -3,	 -3,  -3,  -3,	-3,  -2,  -2,  -2,  -2,	 -2,  -1,  -1,	-1,  -1,  -1; 112
		dc.b	0,   0,	  0,   0,   0,	 0,   1,   1,	1,   1,	  1,   2,   2,	 2,   2,   2; 128
		dc.b	2,   2,	  3,   3,   3,	 3,   3,   3,	3,   3,	  3,   3,   3,	 3,   3,   3; 144
		dc.b	3,   3,	  3,   3,   3,	 3,   3,   3,	3,   3,	  3,   3,   3,	 3,   3,   2; 160
		dc.b	2,   2,	  2,   2,   2,	 2,   1,   1,	1,   1,	  1,   0,   0,	 0,   0,   0; 176
		dc.b	0,  -1,	 -1,  -1,  -1,	-1,  -2,  -2,  -2,  -2,	 -2,  -3,  -3,	-3,  -3,  -3; 192
		dc.b   -3,  -3,	 -4,  -4,  -4,	-4,  -4,  -4,  -4,  -4,	 -4,  -4,  -4,	-4,  -4,  -4; 208
		dc.b   -4,  -4,	 -4,  -4,  -4,	-4,  -4,  -4,  -4,  -4,	 -4,  -4,  -4,	-4,  -4,  -3; 224
		dc.b   -3,  -3,	 -3,  -3,  -3,	-3,  -2,  -2,  -2,  -2,	 -2,  -1,  -1,	-1,  -1,  -1; 240
; ---------------------------------------------------------------------------

Obj0A_Countdown:			; CODE XREF: ROM:00011EC8j
					; DATA XREF: ROM:00011E7Co
		tst.w	$2C(a0)
		bne.w	loc_121D6
		cmpi.b	#6,(v_objspace+$24).w
		bcc.w	locret_122DC
		btst	#6,(v_objspace+$22).w
		beq.w	locret_122DC
		subq.w	#1,$38(a0)
		bpl.w	loc_121FC
		move.w	#$3B,$38(a0) 
		move.w	#1,$36(a0)
		jsr	(PseudoRandomNumber).l
		andi.w	#1,d0
		move.b	d0,$34(a0)
		move.w	($FFFFFE14).w,d0
		cmpi.w	#$19,d0
		beq.s	loc_12166
		cmpi.w	#$14,d0
		beq.s	loc_12166
		cmpi.w	#$F,d0
		beq.s	loc_12166
		cmpi.w	#$C,d0
		bhi.s	loc_12170
		bne.s	loc_12152
		move.w	#$92,d0	; "?"
		jsr	(PlaySound).l

loc_12152:				; CODE XREF: ROM:00012146j
		subq.b	#1,$32(a0)
		bpl.s	loc_12170
		move.b	$33(a0),$32(a0)
		bset	#7,$36(a0)
		bra.s	loc_12170
; ---------------------------------------------------------------------------

loc_12166:				; CODE XREF: ROM:00012132j
					; ROM:00012138j ...
		move.w	#$C2,d0	; "?"
		jsr	(PlaySound_Special).l

loc_12170:				; CODE XREF: ROM:00012144j
					; ROM:00012156j ...
		subq.w	#1,($FFFFFE14).w
		bcc.w	loc_121FA
		bsr.w	ResumeMusic
		move.b	#$81,($FFFFF7C8).w
		move.w	#$B2,d0	; "?"
		jsr	(PlaySound_Special).l
		move.b	#$A,$34(a0)
		move.w	#1,$36(a0)
		move.w	#$78,$2C(a0) 
		move.l	a0,-(sp)
		lea	(v_objspace).w,a0
		bsr.w	Sonic_ResetOnFloor
		move.b	#$17,$1C(a0)
		bset	#1,$22(a0)
		bset	#7,2(a0)
		move.w	#0,$12(a0)
		move.w	#0,$10(a0)
		move.w	#0,$14(a0)
		move.b	#1,($FFFFEEDC).w
		movea.l	(sp)+,a0
		rts
; ---------------------------------------------------------------------------

loc_121D6:				; CODE XREF: ROM:000120F0j
		subq.w	#1,$2C(a0)
		bne.s	loc_121E4
		move.b	#6,(v_objspace+$24).w
		rts
; ---------------------------------------------------------------------------

loc_121E4:				; CODE XREF: ROM:000121DAj
		move.l	a0,-(sp)
		lea	(v_objspace).w,a0
		jsr	SpeedToPos
		addi.w	#$10,$12(a0)
		movea.l	(sp)+,a0
		bra.s	loc_121FC
; ---------------------------------------------------------------------------

loc_121FA:				; CODE XREF: ROM:00012174j
		bra.s	loc_1220C
; ---------------------------------------------------------------------------

loc_121FC:				; CODE XREF: ROM:0001210Cj
					; ROM:000121F8j
		tst.w	$36(a0)
		beq.w	locret_122DC
		subq.w	#1,$3A(a0)
		bpl.w	locret_122DC

loc_1220C:				; CODE XREF: ROM:loc_121FAj
		jsr	(PseudoRandomNumber).l
		andi.w	#$F,d0
		move.w	d0,$3A(a0)
		jsr	(SingleObjectLoad).l
		bne.w	locret_122DC
		move.b	#$A,0(a1)
		move.w	(v_objspace+8).w,8(a1)
		moveq	#6,d0
		btst	#0,(v_objspace+$22).w
		beq.s	loc_12242
		neg.w	d0
		move.b	#$40,$26(a1) 

loc_12242:				; CODE XREF: ROM:00012238j
		add.w	d0,8(a1)
		move.w	(v_objspace+$C).w,$C(a1)
		move.b	#6,$28(a1)
		tst.w	$2C(a0)
		beq.w	loc_1228E
		andi.w	#7,$3A(a0)
		addi.w	#0,$3A(a0)
		move.w	(v_objspace+$C).w,d0
		subi.w	#$C,d0
		move.w	d0,$C(a1)
		jsr	(PseudoRandomNumber).l
		move.b	d0,$26(a1)
		move.w	($FFFFFE04).w,d0
		andi.b	#3,d0
		bne.s	loc_122D2
		move.b	#$E,$28(a1)
		bra.s	loc_122D2
; ---------------------------------------------------------------------------

loc_1228E:				; CODE XREF: ROM:00012256j
		btst	#7,$36(a0)
		beq.s	loc_122D2
		move.w	($FFFFFE14).w,d2
		lsr.w	#1,d2
		jsr	(PseudoRandomNumber).l
		andi.w	#3,d0
		bne.s	loc_122BA
		bset	#6,$36(a0)
		bne.s	loc_122D2
		move.b	d2,$28(a1)
		move.w	#$1C,$38(a1)

loc_122BA:				; CODE XREF: ROM:000122A6j
		tst.b	$34(a0)
		bne.s	loc_122D2
		bset	#6,$36(a0)
		bne.s	loc_122D2
		move.b	d2,$28(a1)
		move.w	#$1C,$38(a1)

loc_122D2:				; CODE XREF: ROM:00012284j
					; ROM:0001228Cj ...
		subq.b	#1,$34(a0)
		bpl.s	locret_122DC
		clr.w	$36(a0)

locret_122DC:				; CODE XREF: ROM:000120FAj
					; ROM:00012104j ...
		rts

; =============== S U B	R O U T	I N E =======================================


ResumeMusic:				; CODE XREF: Sonic_Water+1Ap
					; Sonic_Water+62p ...
		cmpi.w	#$C,($FFFFFE14).w
		bhi.s	loc_12310
		move.w	#$82,d0	; "?"
		cmpi.w	#$103,(v_zone).w
		bne.s	loc_122F6
		move.w	#$86,d0	; "?"

loc_122F6:				; CODE XREF: ResumeMusic+12j
		tst.b	($FFFFFE2D).w
		beq.s	loc_12300
		move.w	#$87,d0	; "?"

loc_12300:				; CODE XREF: ResumeMusic+1Cj
		tst.b	($FFFFF7AA).w
		beq.s	loc_1230A
		move.w	#$8C,d0	; "?"

loc_1230A:				; CODE XREF: ResumeMusic+26j
		jsr	(PlaySound).l

loc_12310:				; CODE XREF: ResumeMusic+6j
		move.w	#$1E,($FFFFFE14).w
		clr.b	(v_objspace+$372).w
		rts
; End of function ResumeMusic

; ---------------------------------------------------------------------------
Ani_Obj0A:	dc.w byte_1233A-Ani_Obj0A,byte_12343-Ani_Obj0A;	0
					; DATA XREF: ROM:Obj0A_Animateo
					; ROM:00011F50o ...
		dc.w byte_1234C-Ani_Obj0A,byte_12355-Ani_Obj0A;	2
		dc.w byte_1235E-Ani_Obj0A,byte_12367-Ani_Obj0A;	4
		dc.w byte_12370-Ani_Obj0A,byte_12375-Ani_Obj0A;	6
		dc.w byte_1237D-Ani_Obj0A,byte_12385-Ani_Obj0A;	8
		dc.w byte_1238D-Ani_Obj0A,byte_12395-Ani_Obj0A;	10
		dc.w byte_1239D-Ani_Obj0A,byte_123A5-Ani_Obj0A;	12
		dc.w byte_123A7-Ani_Obj0A; 14
byte_1233A:	dc.b   5,  0,  1,  2,  3,  4,  9, $D,$FC; 0 ; DATA XREF: ROM:Ani_Obj0Ao
byte_12343:	dc.b   5,  0,  1,  2,  3,  4, $C,$12,$FC; 0 ; DATA XREF: ROM:Ani_Obj0Ao
byte_1234C:	dc.b   5,  0,  1,  2,  3,  4, $C,$11,$FC; 0 ; DATA XREF: ROM:Ani_Obj0Ao
byte_12355:	dc.b   5,  0,  1,  2,  3,  4, $B,$10,$FC; 0 ; DATA XREF: ROM:Ani_Obj0Ao
byte_1235E:	dc.b   5,  0,  1,  2,  3,  4,  9, $F,$FC; 0 ; DATA XREF: ROM:Ani_Obj0Ao
byte_12367:	dc.b   5,  0,  1,  2,  3,  4, $A, $E,$FC; 0 ; DATA XREF: ROM:Ani_Obj0Ao
byte_12370:	dc.b  $E,  0,  1,  2,$FC; 0 ; DATA XREF: ROM:Ani_Obj0Ao
byte_12375:	dc.b   7,$16, $D,$16, $D,$16, $D,$FC; 0	; DATA XREF: ROM:Ani_Obj0Ao
byte_1237D:	dc.b   7,$16,$12,$16,$12,$16,$12,$FC; 0	; DATA XREF: ROM:Ani_Obj0Ao
byte_12385:	dc.b   7,$16,$11,$16,$11,$16,$11,$FC; 0	; DATA XREF: ROM:Ani_Obj0Ao
byte_1238D:	dc.b   7,$16,$10,$16,$10,$16,$10,$FC; 0	; DATA XREF: ROM:Ani_Obj0Ao
byte_12395:	dc.b   7,$16, $F,$16, $F,$16, $F,$FC; 0	; DATA XREF: ROM:Ani_Obj0Ao
byte_1239D:	dc.b   7,$16, $E,$16, $E,$16, $E,$FC; 0	; DATA XREF: ROM:Ani_Obj0Ao
byte_123A5:	dc.b  $E,$FC		; 0 ; DATA XREF: ROM:Ani_Obj0Ao
byte_123A7:	dc.b  $E,  1,  2,  3,  4,$FC,  0; 0 ; DATA XREF: ROM:Ani_Obj0Ao
Map_Obj0A_Countdown:dc.w word_123B0-Map_Obj0A_Countdown	; DATA XREF: ROM:00011EB2o
					; ROM:Map_Obj0A_Countdowno
word_123B0:	dc.w 1			; DATA XREF: ROM:Map_Obj0A_Countdowno
		dc.w $E80E,    0,    0,$FFF2; 0
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 38 - shield invincibility stars
;----------------------------------------------------

Obj38:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj38_Index(pc,d0.w),d1
		jmp	Obj38_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj38_Index:	dc.w Obj38_Init-Obj38_Index ; DATA XREF: ROM:Obj38_Indexo
					; ROM:000123CAo ...
		dc.w Obj38_Shield-Obj38_Index
		dc.w Obj38_Stars-Obj38_Index
; ---------------------------------------------------------------------------

Obj38_Init:				; DATA XREF: ROM:Obj38_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj38,4(a0)
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#$18,$19(a0)
		tst.b	$1C(a0)
		bne.s	loc_1240C
		move.w	#$4BE,2(a0)
		cmpi.b	#3,(v_zone).w
		bne.s	loc_12406
		move.w	#$560,2(a0)

loc_12406:				; CODE XREF: ROM:000123FEj
		bsr.w	ModifySpriteAttr_2P
		rts
; ---------------------------------------------------------------------------

loc_1240C:				; CODE XREF: ROM:000123F0j
		addq.b	#2,$24(a0)
		move.l	#Map_Sonic,4(a0)
		move.w	#$4DE,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#2,$18(a0)
		rts
; ---------------------------------------------------------------------------

Obj38_Shield:				; DATA XREF: ROM:000123CAo
		tst.b	($FFFFFE2D).w
		bne.s	locret_1245A
		tst.b	($FFFFFE2C).w
		beq.s	loc_1245C
		move.w	(v_objspace+8).w,8(a0)
		move.w	(v_objspace+$C).w,$C(a0)
		move.b	(v_objspace+$22).w,$22(a0)
		lea	(Ani_Obj38_Shield).l,a1
		jsr	AnimateSprite
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

locret_1245A:				; CODE XREF: ROM:0001242Ej
		rts
; ---------------------------------------------------------------------------

loc_1245C:				; CODE XREF: ROM:00012434j
		jmp	DeleteObject
; ---------------------------------------------------------------------------

Obj38_Stars:				; DATA XREF: ROM:000123CCo
		tst.b	($FFFFFE2D).w
		beq.s	loc_124B2
		move.w	($FFFFEEE0).w,d0
		move.b	$1C(a0),d1
		subq.b	#1,d1
		move.b	#$3F,d1	
		lsl.b	#2,d1
		addi.b	#4,d1
		sub.b	d1,d0
		lea	(v_recordsonic).w,a1
		lea	(a1,d0.w),a1
		move.w	(a1)+,d0
		andi.w	#$3FFF,d0
		move.w	d0,8(a0)
		move.w	(a1)+,d0
		andi.w	#$7FF,d0
		move.w	d0,$C(a0)
		move.b	(v_objspace+$22).w,$22(a0)
		move.b	(v_objspace+$1A).w,$1A(a0)
		move.b	(v_objspace+1).w,1(a0)
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_124B2:				; CODE XREF: ROM:00012466j
		jmp	DeleteObject
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Sonic	1 Object 4A - special stage entry from
;		      Sonic 1 beta
;----------------------------------------------------

S1Obj4A:
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	S1Obj4A_Index(pc,d0.w),d1
		jmp	S1Obj4A_Index(pc,d1.w)
; ---------------------------------------------------------------------------
S1Obj4A_Index:	dc.w S1Obj4A_Init-S1Obj4A_Index	; DATA XREF: ROM:S1Obj4A_Indexo
					; ROM:000124C8o ...
		dc.w S1Obj4A_RmvSonic-S1Obj4A_Index
		dc.w S1Obj4A_LoadSonic-S1Obj4A_Index
; ---------------------------------------------------------------------------

S1Obj4A_Init:				; DATA XREF: ROM:S1Obj4A_Indexo
		tst.l	($FFFFF680).w
		beq.s	loc_124D4
		rts
; ---------------------------------------------------------------------------

loc_124D4:				; CODE XREF: ROM:000124D0j
		addq.b	#2,$24(a0)
		move.l	#Map_S1Obj4A,4(a0)
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#$38,$19(a0) 
		move.w	#$541,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.w	#$78,$30(a0) 

S1Obj4A_RmvSonic:			; DATA XREF: ROM:000124C8o
		move.w	(v_objspace+8).w,8(a0)
		move.w	(v_objspace+$C).w,$C(a0)
		move.b	(v_objspace+$22).w,$22(a0)
		lea	(Ani_S1Obj4A).l,a1
		jsr	AnimateSprite
		cmpi.b	#2,$1A(a0)
		bne.s	loc_1253E
		tst.b	(v_objspace).w
		beq.s	loc_1253E
		move.b	#0,(v_objspace).w
		move.w	#$A8,d0	; "?"
		jsr	(PlaySound_Special).l

loc_1253E:				; CODE XREF: ROM:00012526j
					; ROM:0001252Cj
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

S1Obj4A_LoadSonic:			; DATA XREF: ROM:000124CAo
		subq.w	#1,$30(a0)
		bne.s	locret_12556
		move.b	#1,(v_objspace).w
		jmp	DeleteObject
; ---------------------------------------------------------------------------

locret_12556:				; CODE XREF: ROM:00012548j
		rts
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 08 - water splash
;----------------------------------------------------

Obj08:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj08_Index(pc,d0.w),d1
		jmp	Obj08_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj08_Index:	dc.w Obj08_Init-Obj08_Index ; DATA XREF: ROM:Obj08_Indexo
					; ROM:00012568o ...
		dc.w Obj08_Display-Obj08_Index
		dc.w Obj08_Delete-Obj08_Index
; ---------------------------------------------------------------------------

Obj08_Init:				; DATA XREF: ROM:Obj08_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj08,4(a0)
		ori.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#$10,$19(a0)
		move.w	#$4259,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.w	(v_objspace+8).w,8(a0)

Obj08_Display:				; DATA XREF: ROM:00012568o
		move.w	($FFFFF646).w,$C(a0)
		lea	(Ani_Obj08).l,a1
		jsr	AnimateSprite
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

Obj08_Delete:				; DATA XREF: ROM:0001256Ao
		jmp	DeleteObject
; ---------------------------------------------------------------------------
Ani_Obj38_Shield:dc.w byte_125C2-Ani_Obj38_Shield ; DATA XREF: ROM:00012448o
					; ROM:Ani_Obj38_Shieldo ...
		dc.w byte_125CE-Ani_Obj38_Shield
		dc.w byte_125D4-Ani_Obj38_Shield
		dc.w byte_125EE-Ani_Obj38_Shield
		dc.w byte_12608-Ani_Obj38_Shield
byte_125C2:	dc.b   0,  5,  0,  5,  1,  5,  2,  5,  3,  5,  4,$FF; 0
					; DATA XREF: ROM:Ani_Obj38_Shieldo
byte_125CE:	dc.b   5,  4,  5,  6,  7,$FF; 0	; DATA XREF: ROM:000125BAo
byte_125D4:	dc.b   0,  4,  4,  0,  4,  4,  0,  5,  5,  0,  5,  5,  0,  6,  6,  0; 0
					; DATA XREF: ROM:000125BCo
		dc.b   6,  6,  0,  7,  7,  0,  7,  7,  0,$FF; 16
byte_125EE:	dc.b   0,  4,  4,  0,  4,  0,  0,  5,  5,  0,  5,  0,  0,  6,  6,  0; 0
					; DATA XREF: ROM:000125BEo
		dc.b   6,  0,  0,  7,  7,  0,  7,  0,  0,$FF; 16
byte_12608:	dc.b   0,  4,  0,  0,  4,  0,  0,  5,  0,  0,  5,  0,  0,  6,  0,  0; 0
					; DATA XREF: ROM:000125C0o
		dc.b   6,  0,  0,  7,  0,  0,  7,  0,  0,$FF; 16
Map_Obj38:	dc.w word_12636-Map_Obj38 ; DATA XREF: ROM:000123D2o
					; ROM:Map_Obj38o ...
		dc.w word_12658-Map_Obj38
		dc.w word_1267A-Map_Obj38
		dc.w word_1269C-Map_Obj38
		dc.w word_126BE-Map_Obj38
		dc.w word_126E0-Map_Obj38
		dc.w word_12702-Map_Obj38
		dc.w word_12724-Map_Obj38
		dc.w word_12746-Map_Obj38
		dc.w word_12768-Map_Obj38
word_12636:	dc.w 4			; DATA XREF: ROM:Map_Obj38o
		dc.w $F005,    0,    0,$FFF0; 0
		dc.w $F005, $800, $800,	   0; 4
		dc.w	 5,$1000,$1000,$FFF0; 8
		dc.w	 5,$1800,$1800,	   0; 12
word_12658:	dc.w 4			; DATA XREF: ROM:00012624o
		dc.w $F005,    4,    2,$FFF0; 0
		dc.w $F005, $804, $802,	   0; 4
		dc.w	 5,$1004,$1002,$FFF0; 8
		dc.w	 5,$1804,$1802,	   0; 12
word_1267A:	dc.w 4			; DATA XREF: ROM:00012626o
		dc.w $F005,    8,    4,$FFF0; 0
		dc.w $F005, $808, $804,	   0; 4
		dc.w	 5,$1008,$1004,$FFF0; 8
		dc.w	 5,$1808,$1804,	   0; 12
word_1269C:	dc.w 4			; DATA XREF: ROM:00012628o
		dc.w $F005,   $C,    6,$FFF0; 0
		dc.w $F005, $80C, $806,	   0; 4
		dc.w	 5,$100C,$1006,$FFF0; 8
		dc.w	 5,$180C,$1806,	   0; 12
word_126BE:	dc.w 4			; DATA XREF: ROM:0001262Ao
		dc.w $F005,  $10,    8,$FFF0; 0
		dc.w $F005, $810, $808,	   0; 4
		dc.w	 5,$1010,$1008,$FFF0; 8
		dc.w	 5,$1810,$1808,	   0; 12
word_126E0:	dc.w 4			; DATA XREF: ROM:0001262Co
		dc.w $E00B,  $14,   $A,$FFE8; 0
		dc.w $E00B, $814, $80A,	   0; 4
		dc.w	$B,$1014,$100A,$FFE8; 8
		dc.w	$B,$1814,$180A,	   0; 12
word_12702:	dc.w 4			; DATA XREF: ROM:0001262Eo
		dc.w $E80A,    0,    0,$FFE8; 0
		dc.w $E80A,    9,    4,	   0; 4
		dc.w	$A,$1809,$1804,$FFE8; 8
		dc.w	$A,$1800,$1800,	   0; 12
word_12724:	dc.w 4			; DATA XREF: ROM:00012630o
		dc.w $E80A, $809, $804,$FFE8; 0
		dc.w $E80A, $800, $800,	   0; 4
		dc.w	$A,$1000,$1000,$FFE8; 8
		dc.w	$A,$1009,$1004,	   0; 12
word_12746:	dc.w 4			; DATA XREF: ROM:00012632o
		dc.w $E80A,  $12,    9,$FFE8; 0
		dc.w $E80A,  $1B,   $D,	   0; 4
		dc.w	$A,$181B,$180D,$FFE8; 8
		dc.w	$A,$1812,$1809,	   0; 12
word_12768:	dc.w 4			; DATA XREF: ROM:00012634o
		dc.w $E80A, $81B, $80D,$FFE8; 0
		dc.w $E80A, $812, $809,	   0; 4
		dc.w	$A,$1012,$1009,$FFE8; 8
		dc.w	$A,$101B,$100D,	   0; 12
Ani_S1Obj4A:	dc.w byte_1278C-Ani_S1Obj4A ; DATA XREF: ROM:00012514o
					; ROM:Ani_S1Obj4Ao
byte_1278C:	dc.b   5,  0,  1,  0,  1,  0,  7,  1,  7,  2,  7,  3,  7,  4,  7,  5; 0
					; DATA XREF: ROM:Ani_S1Obj4Ao
		dc.b   7,  6,  7,$FC	; 16
Map_S1Obj4A:	dc.w word_127B0-Map_S1Obj4A ; DATA XREF: ROM:000124D8o
					; ROM:Map_S1Obj4Ao ...
		dc.w word_127CA-Map_S1Obj4A
		dc.w word_127E4-Map_S1Obj4A
		dc.w word_1280E-Map_S1Obj4A
		dc.w word_12858-Map_S1Obj4A
		dc.w word_128EA-Map_S1Obj4A
		dc.w word_12974-Map_S1Obj4A
		dc.w word_129BE-Map_S1Obj4A
word_127B0:	dc.w 3			; DATA XREF: ROM:Map_S1Obj4Ao
		dc.w $F800,    0,    0,	   8; 0
		dc.w	 4,    1,    0,	   0; 4
		dc.w  $800,$1000,$1000,	   8; 8
word_127CA:	dc.w 3			; DATA XREF: ROM:000127A2o
		dc.w $F00D,    3,    1,$FFF0; 0
		dc.w	$C,   $B,    5,$FFF0; 4
		dc.w  $80D,$1003,$1001,$FFF0; 8
word_127E4:	dc.w 5			; DATA XREF: ROM:000127A4o
		dc.w $E40E,   $F,    7,$FFF4; 0
		dc.w $EC02,  $1B,   $D,$FFEC; 4
		dc.w $FC0C,  $1E,   $F,$FFF4; 8
		dc.w  $40E,$100F,$1007,$FFF4; 12
		dc.w  $401,$101B,$100D,$FFEC; 16
word_1280E:	dc.w 9			; DATA XREF: ROM:000127A6o
		dc.w $F008,  $22,  $11,$FFF8; 0
		dc.w $F80E,  $25,  $12,$FFF0; 4
		dc.w $1008,  $31,  $18,$FFF0; 8
		dc.w	 5,  $34,  $1A,	 $10; 12
		dc.w $F800, $825, $812,	 $10; 16
		dc.w $F000,$1836,$181B,	 $18; 20
		dc.w $F800,$1825,$1812,	 $20; 24
		dc.w	 0, $825, $812,	 $28; 28
		dc.w $F800,  $25,  $12,	 $30; 32
word_12858:	dc.w $12		; DATA XREF: ROM:000127A8o
		dc.w	 0,$1825,$1812,$FFF0; 0
		dc.w $F804,  $38,  $1C,$FFF8; 4
		dc.w $F000,  $26,  $13,	   8; 8
		dc.w	 0,  $25,  $12,	   0; 12
		dc.w  $800,$1825,$1812,$FFF8; 16
		dc.w $1000,$1026,$1013,	   0; 20
		dc.w  $800,$1038,$101C,	   8; 24
		dc.w $F800,  $29,  $14,	 $10; 28
		dc.w	 0,  $26,  $13,	 $10; 32
		dc.w	 0,  $2D,  $16,	 $18; 36
		dc.w  $800, $826, $813,	 $18; 40
		dc.w  $800,  $29,  $14,	 $20; 44
		dc.w $F800,  $26,  $13,	 $20; 48
		dc.w $F800,  $2D,  $16,	 $28; 52
		dc.w	 0,  $3A,  $1D,	 $28; 56
		dc.w $F800,$1826,$1813,	 $30; 60
		dc.w	 0,$1025,$1012,	 $38; 64
		dc.w $F800,$1025,$1012,	 $40; 68
word_128EA:	dc.w $11		; DATA XREF: ROM:000127AAo
		dc.w $F800, $825, $812,	   0; 0
		dc.w $F000,  $38,  $1C,	 $10; 4
		dc.w $1000, $825, $812,	   0; 8
		dc.w	 0,$1825,$1812,	 $10; 12
		dc.w  $800,$1025,$1012,	 $18; 16
		dc.w $F800,$1825,$1812,	 $20; 20
		dc.w	 0,$1026,$1013,	 $28; 24
		dc.w $F800,$1025,$1012,	 $30; 28
		dc.w	 0,  $25,  $12,	 $30; 32
		dc.w  $800, $825, $812,	 $30; 36
		dc.w	 0, $826, $813,	 $38; 40
		dc.w  $800,  $29,  $14,	 $38; 44
		dc.w $F800, $826, $813,	 $40; 48
		dc.w	 0,  $2D,  $16,	 $40; 52
		dc.w $F800, $825, $812,	 $48; 56
		dc.w	 0,  $25,  $12,	 $48; 60
		dc.w	 0,$1025,$1012,	 $50; 64
word_12974:	dc.w 9			; DATA XREF: ROM:000127ACo
		dc.w $FC00, $826, $813,	 $30; 0
		dc.w  $400, $825, $812,	 $28; 4
		dc.w  $400,$1027,$1013,	 $38; 8
		dc.w  $400, $826, $813,	 $40; 12
		dc.w $FC00,$1025,$1012,	 $40; 16
		dc.w $FC00,$1026,$1013,	 $48; 20
		dc.w  $C00, $827, $813,	 $48; 24
		dc.w  $400,$1826,$1813,	 $50; 28
		dc.w  $400, $827, $813,	 $58; 32
word_129BE:	dc.w 0			; DATA XREF: ROM:000127AEo
Ani_Obj08:	dc.w byte_129C2-Ani_Obj08 ; DATA XREF: ROM:000125A0o
					; ROM:Ani_Obj08o
byte_129C2:	dc.b   4,  0,  1,  2,$FC,  0; 0	; DATA XREF: ROM:Ani_Obj08o
Map_Obj08:	dc.w word_129CE-Map_Obj08 ; DATA XREF: ROM:00012570o
					; ROM:Map_Obj08o ...
		dc.w word_129E0-Map_Obj08
		dc.w word_129F2-Map_Obj08
word_129CE:	dc.w 2			; DATA XREF: ROM:Map_Obj08o
		dc.w $F204,  $6D,  $36,$FFF8; 0
		dc.w $FA0C,  $6F,  $37,$FFF0; 4
word_129E0:	dc.w 2			; DATA XREF: ROM:000129CAo
		dc.w $E200,  $73,  $39,$FFF8; 0
		dc.w $EA0E,  $74,  $3A,$FFF0; 4
word_129F2:	dc.w 1			; DATA XREF: ROM:000129CCo
		dc.w $E20F,  $80,  $40,$FFF0; 0

; =============== S U B	R O U T	I N E =======================================


Sonic_AnglePos:				; CODE XREF: ROM:0000FCC0p
					; ROM:0000FD0Ap ...

; FUNCTION CHUNK AT 00012B30 SIZE 00000002 BYTES
; FUNCTION CHUNK AT 00012BA2 SIZE 000001D4 BYTES

		move.l	#v_col1st,($FFFFF796).w
		cmpi.b	#$C,$3E(a0)
		beq.s	loc_12A14
		move.l	#v_col2nd,($FFFFF796).w

loc_12A14:				; CODE XREF: Sonic_AnglePos+Ej
		move.b	$3E(a0),d5
		btst	#3,$22(a0)
		beq.s	loc_12A2C
		moveq	#0,d0
		move.b	d0,($FFFFF768).w
		move.b	d0,($FFFFF76A).w
		rts
; ---------------------------------------------------------------------------

loc_12A2C:				; CODE XREF: Sonic_AnglePos+22j
		moveq	#3,d0
		move.b	d0,($FFFFF768).w
		move.b	d0,($FFFFF76A).w
		move.b	$26(a0),d0
		addi.b	#$20,d0	
		bpl.s	loc_12A4E
		move.b	$26(a0),d0
		bpl.s	loc_12A48
		subq.b	#1,d0

loc_12A48:				; CODE XREF: Sonic_AnglePos+48j
		addi.b	#$20,d0	
		bra.s	loc_12A5A
; ---------------------------------------------------------------------------

loc_12A4E:				; CODE XREF: Sonic_AnglePos+42j
		move.b	$26(a0),d0
		bpl.s	loc_12A56
		addq.b	#1,d0

loc_12A56:				; CODE XREF: Sonic_AnglePos+56j
		addi.b	#$1F,d0

loc_12A5A:				; CODE XREF: Sonic_AnglePos+50j
		andi.b	#$C0,d0
		cmpi.b	#$40,d0	
		beq.w	Sonic_WalkVertL
		cmpi.b	#$80,d0
		beq.w	Sonic_WalkCeiling
		cmpi.b	#$C0,d0
		beq.w	Sonic_WalkVertR
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		neg.w	d0
		add.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		bsr.w	FindFloor
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_12AE4
		bpl.s	loc_12AE6
		cmpi.w	#$FFF2,d1
		blt.s	locret_12B0C
		add.w	d1,$C(a0)

locret_12AE4:				; CODE XREF: Sonic_AnglePos+DAj
		rts
; ---------------------------------------------------------------------------

loc_12AE6:				; CODE XREF: Sonic_AnglePos+DCj
		cmpi.w	#$E,d1
		bgt.s	loc_12AF2

loc_12AEC:				; CODE XREF: Sonic_AnglePos+FAj
		add.w	d1,$C(a0)
		rts
; ---------------------------------------------------------------------------

loc_12AF2:				; CODE XREF: Sonic_AnglePos+EEj
		tst.b	$38(a0)
		bne.s	loc_12AEC
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)
		rts
; ---------------------------------------------------------------------------

locret_12B0C:				; CODE XREF: Sonic_AnglePos+E2j
					; Sonic_AnglePos+2ACj
		rts
; End of function Sonic_AnglePos

; ---------------------------------------------------------------------------
		move.l	8(a0),d2
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d2
		move.l	d2,8(a0)
		move.w	#$38,d0	
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d3,$C(a0)
		rts
; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR Sonic_AnglePos

locret_12B30:				; CODE XREF: Sonic_AnglePos+20Ej
					; Sonic_AnglePos+34Aj
		rts
; END OF FUNCTION CHUNK	FOR Sonic_AnglePos
; ---------------------------------------------------------------------------
		move.l	$C(a0),d3
		move.w	$12(a0),d0
		subi.w	#$38,d0	
		move.w	d0,$12(a0)
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d3,$C(a0)
		rts
; ---------------------------------------------------------------------------
		rts
; ---------------------------------------------------------------------------
		move.l	8(a0),d2
		move.l	$C(a0),d3
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d2
		move.w	$12(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d2,8(a0)
		move.l	d3,$C(a0)
		rts

; =============== S U B	R O U T	I N E =======================================


Sonic_Angle:				; CODE XREF: Sonic_AnglePos+D4p
					; Sonic_AnglePos+200p ...
		move.b	($FFFFF76A).w,d2
		cmp.w	d0,d1
		ble.s	loc_12B84
		move.b	($FFFFF768).w,d2
		move.w	d0,d1

loc_12B84:				; CODE XREF: Sonic_Angle+6j
		btst	#0,d2
		bne.s	loc_12B90
		move.b	d2,$26(a0)
		rts
; ---------------------------------------------------------------------------

loc_12B90:				; CODE XREF: Sonic_Angle+12j
		move.b	$26(a0),d2
		addi.b	#$20,d2	
		andi.b	#$C0,d2
		move.b	d2,$26(a0)
		rts
; End of function Sonic_Angle

; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR Sonic_AnglePos

Sonic_WalkVertR:			; CODE XREF: Sonic_AnglePos+76j
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		neg.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		bsr.w	FindWall
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_12C12
		bpl.s	loc_12C14
		cmpi.w	#$FFF2,d1
		blt.w	locret_12B30
		add.w	d1,8(a0)

locret_12C12:				; CODE XREF: Sonic_AnglePos+206j
		rts
; ---------------------------------------------------------------------------

loc_12C14:				; CODE XREF: Sonic_AnglePos+208j
		cmpi.w	#$E,d1
		bgt.s	loc_12C20

loc_12C1A:				; CODE XREF: Sonic_AnglePos+228j
		add.w	d1,8(a0)
		rts
; ---------------------------------------------------------------------------

loc_12C20:				; CODE XREF: Sonic_AnglePos+21Cj
		tst.b	$38(a0)
		bne.s	loc_12C1A
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)
		rts
; ---------------------------------------------------------------------------

Sonic_WalkCeiling:			; CODE XREF: Sonic_AnglePos+6Ej
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#$FFF0,a3
		move.w	#$800,d6
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#$FFF0,a3
		move.w	#$800,d6
		bsr.w	FindFloor
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_12CB0
		bpl.s	loc_12CB2
		cmpi.w	#$FFF2,d1
		blt.w	locret_12B0C
		sub.w	d1,$C(a0)

locret_12CB0:				; CODE XREF: Sonic_AnglePos+2A4j
		rts
; ---------------------------------------------------------------------------

loc_12CB2:				; CODE XREF: Sonic_AnglePos+2A6j
		cmpi.w	#$E,d1
		bgt.s	loc_12CBE

loc_12CB8:				; CODE XREF: Sonic_AnglePos+2C6j
		sub.w	d1,$C(a0)
		rts
; ---------------------------------------------------------------------------

loc_12CBE:				; CODE XREF: Sonic_AnglePos+2BAj
		tst.b	$38(a0)
		bne.s	loc_12CB8
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)
		rts
; ---------------------------------------------------------------------------

Sonic_WalkVertL:			; CODE XREF: Sonic_AnglePos+66j
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	($FFFFF768).w,a4
		movea.w	#$FFF0,a3
		move.w	#$400,d6
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	($FFFFF76A).w,a4
		movea.w	#$FFF0,a3
		move.w	#$400,d6
		bsr.w	FindWall
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_12D4E
		bpl.s	loc_12D50
		cmpi.w	#$FFF2,d1
		blt.w	locret_12B30
		sub.w	d1,8(a0)

locret_12D4E:				; CODE XREF: Sonic_AnglePos+342j
		rts
; ---------------------------------------------------------------------------

loc_12D50:				; CODE XREF: Sonic_AnglePos+344j
		cmpi.w	#$E,d1
		bgt.s	loc_12D5C

loc_12D56:				; CODE XREF: Sonic_AnglePos+364j
		sub.w	d1,8(a0)
		rts
; ---------------------------------------------------------------------------

loc_12D5C:				; CODE XREF: Sonic_AnglePos+358j
		tst.b	$38(a0)
		bne.s	loc_12D56
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)
		rts
; END OF FUNCTION CHUNK	FOR Sonic_AnglePos

; =============== S U B	R O U T	I N E =======================================


Floor_ChkTile:				; CODE XREF: FindFloorp FindFloor2p ...
		move.w	d2,d0
		add.w	d0,d0
		andi.w	#$F00,d0
		move.w	d3,d1
		lsr.w	#7,d1
		andi.w	#$7F,d1
		add.w	d1,d0
		moveq	#$FFFFFFFF,d1
		lea	(v_lvllayout).w,a1
		move.b	(a1,d0.w),d1
		andi.w	#$FF,d1
		lsl.w	#7,d1
		move.w	d2,d0
		andi.w	#$70,d0	
		add.w	d0,d1
		move.w	d3,d0
		lsr.w	#3,d0
		andi.w	#$E,d0
		add.w	d0,d1
		movea.l	d1,a1
		rts
; End of function Floor_ChkTile


; =============== S U B	R O U T	I N E =======================================


FindFloor:				; CODE XREF: Sonic_AnglePos+A0p
					; Sonic_AnglePos+CEp ...
		bsr.s	Floor_ChkTile
		move.w	(a1),d0
		move.w	d0,d4
		andi.w	#$3FF,d0
		beq.s	loc_12DBE
		btst	d5,d4
		bne.s	loc_12DCC

loc_12DBE:				; CODE XREF: FindFloor+Aj
					; FindFloor+28j ...
		add.w	a3,d2
		bsr.w	FindFloor2
		sub.w	a3,d2
		addi.w	#$10,d1
		rts
; ---------------------------------------------------------------------------

loc_12DCC:				; CODE XREF: FindFloor+Ej
		movea.l	($FFFFF796).w,a2
		add.w	d0,d0
		move.w	(a2,d0.w),d0
		beq.s	loc_12DBE
		lea	(AngleMap).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d3,d1
		btst	#$A,d4
		beq.s	loc_12DF0
		not.w	d1
		neg.b	(a4)

loc_12DF0:				; CODE XREF: FindFloor+3Cj
		btst	#$B,d4
		beq.s	loc_12E00
		addi.b	#$40,(a4) 
		neg.b	(a4)
		subi.b	#$40,(a4) 

loc_12E00:				; CODE XREF: FindFloor+46j
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(ColArray1).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$B,d4
		beq.s	loc_12E1C
		neg.w	d0

loc_12E1C:				; CODE XREF: FindFloor+6Aj
		tst.w	d0
		beq.s	loc_12DBE
		bmi.s	loc_12E38
		cmpi.b	#$10,d0
		beq.s	loc_12E44
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts
; ---------------------------------------------------------------------------

loc_12E38:				; CODE XREF: FindFloor+72j
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_12DBE

loc_12E44:				; CODE XREF: FindFloor+78j
		sub.w	a3,d2
		bsr.w	FindFloor2
		add.w	a3,d2
		subi.w	#$10,d1
		rts
; End of function FindFloor


; =============== S U B	R O U T	I N E =======================================


FindFloor2:				; CODE XREF: FindFloor+12p
					; FindFloor+98p
		bsr.w	Floor_ChkTile
		move.w	(a1),d0
		move.w	d0,d4
		andi.w	#$3FF,d0
		beq.s	loc_12E64
		btst	d5,d4
		bne.s	loc_12E72

loc_12E64:				; CODE XREF: FindFloor2+Cj
					; FindFloor2+2Aj ...
		move.w	#$F,d1
		move.w	d2,d0
		andi.w	#$F,d0
		sub.w	d0,d1
		rts
; ---------------------------------------------------------------------------

loc_12E72:				; CODE XREF: FindFloor2+10j
		movea.l	($FFFFF796).w,a2
		add.w	d0,d0
		move.w	(a2,d0.w),d0
		beq.s	loc_12E64
		lea	(AngleMap).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d3,d1
		btst	#$A,d4
		beq.s	loc_12E96
		not.w	d1
		neg.b	(a4)

loc_12E96:				; CODE XREF: FindFloor2+3Ej
		btst	#$B,d4
		beq.s	loc_12EA6
		addi.b	#$40,(a4) 
		neg.b	(a4)
		subi.b	#$40,(a4) 

loc_12EA6:				; CODE XREF: FindFloor2+48j
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(ColArray1).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$B,d4
		beq.s	loc_12EC2
		neg.w	d0

loc_12EC2:				; CODE XREF: FindFloor2+6Cj
		tst.w	d0
		beq.s	loc_12E64
		bmi.s	loc_12ED8
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts
; ---------------------------------------------------------------------------

loc_12ED8:				; CODE XREF: FindFloor2+74j
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_12E64
		not.w	d1
		rts
; End of function FindFloor2


; =============== S U B	R O U T	I N E =======================================


FindWall:				; CODE XREF: Sonic_AnglePos+1CEp
					; Sonic_AnglePos+1FAp ...
		bsr.w	Floor_ChkTile
		move.w	(a1),d0
		move.w	d0,d4
		andi.w	#$3FF,d0
		beq.s	loc_12EFA
		btst	d5,d4
		bne.s	loc_12F08

loc_12EFA:				; CODE XREF: FindWall+Cj FindWall+2Aj	...
		add.w	a3,d3
		bsr.w	FindWall2
		sub.w	a3,d3
		addi.w	#$10,d1
		rts
; ---------------------------------------------------------------------------

loc_12F08:				; CODE XREF: FindWall+10j
		movea.l	($FFFFF796).w,a2
		add.w	d0,d0
		move.w	(a2,d0.w),d0
		beq.s	loc_12EFA
		lea	(AngleMap).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d2,d1
		btst	#$B,d4
		beq.s	loc_12F34
		not.w	d1
		addi.b	#$40,(a4)
		neg.b	(a4)
		subi.b	#$40,(a4)

loc_12F34:				; CODE XREF: FindWall+3Ej
		btst	#$A,d4
		beq.s	loc_12F3C
		neg.b	(a4)

loc_12F3C:				; CODE XREF: FindWall+50j
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(ColArray2).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$A,d4
		beq.s	loc_12F58
		neg.w	d0

loc_12F58:				; CODE XREF: FindWall+6Cj
		tst.w	d0
		beq.s	loc_12EFA
		bmi.s	loc_12F74
		cmpi.b	#$10,d0
		beq.s	loc_12F80
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts
; ---------------------------------------------------------------------------

loc_12F74:				; CODE XREF: FindWall+74j
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_12EFA

loc_12F80:				; CODE XREF: FindWall+7Aj
		sub.w	a3,d3
		bsr.w	FindWall2
		add.w	a3,d3
		subi.w	#$10,d1
		rts
; End of function FindWall


; =============== S U B	R O U T	I N E =======================================


FindWall2:				; CODE XREF: FindWall+14p FindWall+9Ap
		bsr.w	Floor_ChkTile
		move.w	(a1),d0
		move.w	d0,d4
		andi.w	#$3FF,d0
		beq.s	loc_12FA0
		btst	d5,d4
		bne.s	loc_12FAE

loc_12FA0:				; CODE XREF: FindWall2+Cj
					; FindWall2+2Aj ...
		move.w	#$F,d1
		move.w	d3,d0
		andi.w	#$F,d0
		sub.w	d0,d1
		rts
; ---------------------------------------------------------------------------

loc_12FAE:				; CODE XREF: FindWall2+10j
		movea.l	($FFFFF796).w,a2
		add.w	d0,d0
		move.w	(a2,d0.w),d0
		beq.s	loc_12FA0
		lea	(AngleMap).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d2,d1
		btst	#$B,d4
		beq.s	loc_12FDA
		not.w	d1
		addi.b	#$40,(a4)
		neg.b	(a4)
		subi.b	#$40,(a4)

loc_12FDA:				; CODE XREF: FindWall2+3Ej
		btst	#$A,d4
		beq.s	loc_12FE2
		neg.b	(a4)

loc_12FE2:				; CODE XREF: FindWall2+50j
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(ColArray2).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$A,d4
		beq.s	loc_12FFE
		neg.w	d0

loc_12FFE:				; CODE XREF: FindWall2+6Cj
		tst.w	d0
		beq.s	loc_12FA0
		bmi.s	loc_13014
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts
; ---------------------------------------------------------------------------

loc_13014:				; CODE XREF: FindWall2+74j
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_12FA0
		not.w	d1
		rts
; End of function FindWall2

;----------------------------------------------------
; leftover function from early Sonic 1/2 alpha
;----------------------------------------------------

; =============== S U B	R O U T	I N E =======================================


FloorLog_Unk:				; CODE XREF: ROM:00003D4Cp
		rts
; End of function FloorLog_Unk

; ---------------------------------------------------------------------------
		lea	(ColArray1_GHZ).l,a1
		tst.b	(v_zone).w
		beq.s	loc_13038
		lea	(ColArray1).l,a1

loc_13038:				; CODE XREF: ROM:00013030j
		lea	(ColArray1).l,a2
		move.w	#$7FF,d1

loc_13042:				; CODE XREF: ROM:00013044j
		move.w	(a1)+,(a2)+
		dbf	d1,loc_13042
		lea	(ColArray2).l,a2
		move.w	#$7FF,d1

loc_13052:				; CODE XREF: ROM:00013054j
		move.w	(a1)+,(a2)+
		dbf	d1,loc_13052
		lea	(AngleMap_GHZ).l,a1
		tst.b	(v_zone).w
		beq.s	loc_1306A
		lea	(AngleMap).l,a1

loc_1306A:				; CODE XREF: ROM:00013062j
		lea	(AngleMap).l,a2
		move.w	#$7F,d1	

loc_13074:				; CODE XREF: ROM:00013076j
		move.w	(a1)+,(a2)+
		dbf	d1,loc_13074
		rts

; =============== S U B	R O U T	I N E =======================================


Sonic_WalkSpeed:			; CODE XREF: Sonic_Move+158p
					; Tails_Move+150p

; FUNCTION CHUNK AT 000131DE SIZE 00000026 BYTES
; FUNCTION CHUNK AT 000132F6 SIZE 0000001C BYTES
; FUNCTION CHUNK AT 000133B0 SIZE 00000020 BYTES
; FUNCTION CHUNK AT 00013478 SIZE 00000020 BYTES

		move.l	#v_col1st,($FFFFF796).w
		cmpi.b	#$C,$3E(a0)
		beq.s	loc_13094
		move.l	#v_col2nd,($FFFFF796).w

loc_13094:				; CODE XREF: Sonic_WalkSpeed+Ej
		move.b	$3F(a0),d5
		move.l	8(a0),d3
		move.l	$C(a0),d2
		move.w	$10(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d3
		move.w	$12(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d2
		swap	d2
		swap	d3
		move.b	d0,($FFFFF768).w
		move.b	d0,($FFFFF76A).w
		move.b	d0,d1
		addi.b	#$20,d0	
		bpl.s	loc_130D4
		move.b	d1,d0
		bpl.s	loc_130CE
		subq.b	#1,d0

loc_130CE:				; CODE XREF: Sonic_WalkSpeed+4Ej
		addi.b	#$20,d0	
		bra.s	loc_130DE
; ---------------------------------------------------------------------------

loc_130D4:				; CODE XREF: Sonic_WalkSpeed+4Aj
		move.b	d1,d0
		bpl.s	loc_130DA
		addq.b	#1,d0

loc_130DA:				; CODE XREF: Sonic_WalkSpeed+5Aj
		addi.b	#$1F,d0

loc_130DE:				; CODE XREF: Sonic_WalkSpeed+56j
		andi.b	#$C0,d0
		beq.w	loc_131DE
		cmpi.b	#$80,d0
		beq.w	loc_133B0
		andi.b	#$38,d1	
		bne.s	loc_130F6
		addq.w	#8,d2

loc_130F6:				; CODE XREF: Sonic_WalkSpeed+76j
		cmpi.b	#$40,d0	
		beq.w	loc_13478
		bra.w	loc_132F6
; End of function Sonic_WalkSpeed


; =============== S U B	R O U T	I N E =======================================


sub_13102:				; CODE XREF: Sonic_Jump+16p
					; Tails_Jump:loc_11408p

; FUNCTION CHUNK AT 0001328E SIZE 00000060 BYTES
; FUNCTION CHUNK AT 00013408 SIZE 00000068 BYTES

		move.l	#v_col1st,($FFFFF796).w
		cmpi.b	#$C,$3E(a0)
		beq.s	loc_1311A
		move.l	#v_col2nd,($FFFFF796).w

loc_1311A:				; CODE XREF: sub_13102+Ej
		move.b	$3F(a0),d5
		move.b	d0,($FFFFF768).w
		move.b	d0,($FFFFF76A).w
		addi.b	#$20,d0	
		andi.b	#$C0,d0
		cmpi.b	#$40,d0	
		beq.w	loc_13408
		cmpi.b	#$80,d0
		beq.w	Sonic_DontRunOnWalls
		cmpi.b	#$C0,d0
		beq.w	loc_1328E

loc_13146:				; CODE XREF: Sonic_Floor:loc_1056Ap
					; Sonic_Floor+122p ...
		move.l	#v_col1st,($FFFFF796).w
		cmpi.b	#$C,$3E(a0)
		beq.s	loc_1315E
		move.l	#v_col2nd,($FFFFF796).w

loc_1315E:				; CODE XREF: sub_13102+52j
		move.b	$3E(a0),d5
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		bsr.w	FindFloor
		move.w	(sp)+,d0
		move.b	#0,d2

loc_131BE:				; CODE XREF: sub_13102+1E8j
					; Sonic_DontRunOnWalls+64j ...
		move.b	($FFFFF76A).w,d3
		cmp.w	d0,d1
		ble.s	loc_131CC
		move.b	($FFFFF768).w,d3
		exg	d0,d1

loc_131CC:				; CODE XREF: sub_13102+C2j
		btst	#0,d3
		beq.s	locret_131D4
		move.b	d2,d3

locret_131D4:				; CODE XREF: sub_13102+CEj
		rts
; End of function sub_13102

; ---------------------------------------------------------------------------
		move.w	$C(a0),d2
		move.w	8(a0),d3
; START	OF FUNCTION CHUNK FOR Sonic_WalkSpeed

loc_131DE:				; CODE XREF: Sonic_WalkSpeed+66j
		addi.w	#$A,d2
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		bsr.w	FindFloor
		move.b	#0,d2

loc_131F6:				; CODE XREF: Sonic_WalkSpeed+292j
					; Sonic_WalkSpeed+350j	...
		move.b	($FFFFF768).w,d3
		btst	#0,d3
		beq.s	locret_13202
		move.b	d2,d3

locret_13202:				; CODE XREF: Sonic_WalkSpeed+182j
		rts
; END OF FUNCTION CHUNK	FOR Sonic_WalkSpeed

; =============== S U B	R O U T	I N E =======================================


Sonic_HitFloor:				; CODE XREF: Sonic_Move:Sonic_Balancep
		move.w	8(a0),d3
		move.w	$C(a0),d2
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.l	#v_col1st,($FFFFF796).w
		cmpi.b	#$C,$3E(a0)
		beq.s	loc_1322E
		move.l	#v_col2nd,($FFFFF796).w

loc_1322E:				; CODE XREF: Sonic_HitFloor+20j
		lea	($FFFFF768).w,a4
		move.b	#0,(a4)
		movea.w	#$10,a3
		move.w	#0,d6
		move.b	$3E(a0),d5
		bsr.w	FindFloor
		move.b	($FFFFF768).w,d3
		btst	#0,d3
		beq.s	locret_13254
		move.b	#0,d3

locret_13254:				; CODE XREF: Sonic_HitFloor+4Aj
		rts
; End of function Sonic_HitFloor


; =============== S U B	R O U T	I N E =======================================


ObjHitFloor:				; CODE XREF: ROM:000096A8p
					; ROM:00009796p ...
		move.w	8(a0),d3

ObjHitFloor2:				; CODE XREF: ROM:loc_A224p
		move.w	$C(a0),d2
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		lea	($FFFFF768).w,a4
		move.b	#0,(a4)
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5
		bsr.w	FindFloor
		move.b	($FFFFF768).w,d3
		btst	#0,d3
		beq.s	locret_1328C
		move.b	#0,d3

locret_1328C:				; CODE XREF: ObjHitFloor+30j
		rts
; End of function ObjHitFloor

; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR sub_13102

loc_1328E:				; CODE XREF: sub_13102+40j
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		bsr.w	FindWall
		move.w	(sp)+,d0
		move.b	#$C0,d2
		bra.w	loc_131BE
; END OF FUNCTION CHUNK	FOR sub_13102

; =============== S U B	R O U T	I N E =======================================


sub_132EE:				; CODE XREF: Sonic_Floor:loc_10558p
					; Sonic_Floor:loc_10658p ...
		move.w	$C(a0),d2
		move.w	8(a0),d3
; End of function sub_132EE

; START	OF FUNCTION CHUNK FOR Sonic_WalkSpeed

loc_132F6:				; CODE XREF: Sonic_WalkSpeed+82j
		addi.w	#$A,d3
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		bsr.w	FindWall
		move.b	#$C0,d2
		bra.w	loc_131F6
; END OF FUNCTION CHUNK	FOR Sonic_WalkSpeed

; =============== S U B	R O U T	I N E =======================================


ObjHitWallRight:			; CODE XREF: ROM:000153B2p
					; ROM:000153D2p
		add.w	8(a0),d3
		move.w	$C(a0),d2
		lea	($FFFFF768).w,a4
		move.b	#0,(a4)
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindWall
		move.b	($FFFFF768).w,d3
		btst	#0,d3
		beq.s	locret_1333E
		move.b	#$C0,d3

locret_1333E:				; CODE XREF: ObjHitWallRight+26j
		rts
; End of function ObjHitWallRight


; =============== S U B	R O U T	I N E =======================================


Sonic_DontRunOnWalls:			; CODE XREF: Sonic_Floor:loc_105FEp
					; Sonic_Floor:loc_1066Ap ...
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#$FFF0,a3
		move.w	#$800,d6
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#$FFF0,a3
		move.w	#$800,d6
		bsr.w	FindFloor
		move.w	(sp)+,d0
		move.b	#$80,d2
		bra.w	loc_131BE
; End of function Sonic_DontRunOnWalls

; ---------------------------------------------------------------------------
		move.w	$C(a0),d2
		move.w	8(a0),d3
; START	OF FUNCTION CHUNK FOR Sonic_WalkSpeed

loc_133B0:				; CODE XREF: Sonic_WalkSpeed+6Ej
		subi.w	#$A,d2
		eori.w	#$F,d2
		lea	($FFFFF768).w,a4
		movea.w	#$FFF0,a3
		move.w	#$800,d6
		bsr.w	FindFloor
		move.b	#$80,d2
		bra.w	loc_131F6
; END OF FUNCTION CHUNK	FOR Sonic_WalkSpeed
; ---------------------------------------------------------------------------

ObjHitCeiling:
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		lea	($FFFFF768).w,a4
		movea.w	#$FFF0,a3
		move.w	#$800,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.b	($FFFFF768).w,d3
		btst	#0,d3
		beq.s	locret_13406
		move.b	#$80,d3

locret_13406:				; CODE XREF: ROM:00013400j
		rts
; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR sub_13102

loc_13408:				; CODE XREF: sub_13102+30j
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	($FFFFF768).w,a4
		movea.w	#$FFF0,a3
		move.w	#$400,d6
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	($FFFFF76A).w,a4
		movea.w	#$FFF0,a3
		move.w	#$400,d6
		bsr.w	FindWall
		move.w	(sp)+,d0
		move.b	#$40,d2	
		bra.w	loc_131BE
; END OF FUNCTION CHUNK	FOR sub_13102

; =============== S U B	R O U T	I N E =======================================


Sonic_HitWall:				; CODE XREF: Sonic_Floor+4Ap
					; Sonic_Floor:loc_105E4p ...
		move.w	$C(a0),d2
		move.w	8(a0),d3
; End of function Sonic_HitWall

; START	OF FUNCTION CHUNK FOR Sonic_WalkSpeed

loc_13478:				; CODE XREF: Sonic_WalkSpeed+7Ej
		subi.w	#$A,d3
		eori.w	#$F,d3
		lea	($FFFFF768).w,a4
		movea.w	#$FFF0,a3
		move.w	#$400,d6
		bsr.w	FindWall
		move.b	#$40,d2	
		bra.w	loc_131F6
; END OF FUNCTION CHUNK	FOR Sonic_WalkSpeed
; ---------------------------------------------------------------------------

ObjHitWallLeft:
		add.w	8(a0),d3
		move.w	$C(a0),d2
		lea	($FFFFF768).w,a4
		move.b	#0,(a4)
		movea.w	#$FFF0,a3
		move.w	#$400,d6
		moveq	#$D,d5
		bsr.w	FindWall
		move.b	($FFFFF768).w,d3
		btst	#0,d3
		beq.s	locret_134C4
		move.b	#$40,d3	

locret_134C4:				; CODE XREF: ROM:000134BEj
		rts
; ---------------------------------------------------------------------------
		nop
;----------------------------------------------------
; Object 79 - lamppost
;----------------------------------------------------

Obj79:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj79_Index(pc,d0.w),d1
		jsr	Obj79_Index(pc,d1.w)
		jmp	MarkObjGone
; ---------------------------------------------------------------------------
Obj79_Index:	dc.w Obj79_Init-Obj79_Index ; DATA XREF: ROM:Obj79_Indexo
					; ROM:000134DEo ...
		dc.w Obj79_Main-Obj79_Index
		dc.w Obj79_AfterHit-Obj79_Index
; ---------------------------------------------------------------------------

Obj79_Init:				; DATA XREF: ROM:Obj79_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj79,4(a0)
		move.w	#$47C,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#8,$19(a0)
		move.b	#5,$18(a0)
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		bclr	#7,2(a2,d0.w)
		btst	#0,2(a2,d0.w)
		bne.s	loc_13536
		move.b	($FFFFFE30).w,d1
		andi.b	#$7F,d1	
		move.b	$28(a0),d2
		andi.b	#$7F,d2	
		cmp.b	d2,d1
		bcs.s	Obj79_Main

loc_13536:				; CODE XREF: ROM:00013520j
		bset	#0,2(a2,d0.w)
		move.b	#4,$24(a0)
		rts
; ---------------------------------------------------------------------------

Obj79_Main:				; CODE XREF: ROM:00013534j
					; DATA XREF: ROM:000134DEo
		tst.w	($FFFFFE08).w
		bne.w	locret_135CA
		tst.b	($FFFFF7C8).w
		bmi.w	locret_135CA
		move.b	($FFFFFE30).w,d1
		andi.b	#$7F,d1	
		move.b	$28(a0),d2
		andi.b	#$7F,d2	
		cmp.b	d2,d1
		bcs.s	Obj79_HitLamp
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		bset	#0,2(a2,d0.w)
		move.b	#4,$24(a0)
		bra.w	locret_135CA
; ---------------------------------------------------------------------------

Obj79_HitLamp:				; CODE XREF: ROM:00013566j
		move.w	(v_objspace+8).w,d0
		sub.w	8(a0),d0
		addi.w	#8,d0
		cmpi.w	#$10,d0
		bcc.w	locret_135CA
		move.w	(v_objspace+$C).w,d0
		sub.w	$C(a0),d0
		addi.w	#$40,d0	
		cmpi.w	#$68,d0	
		bcc.s	locret_135CA
		move.w	#$A1,d0	; "?"
		jsr	(PlaySound_Special).l
		addq.b	#2,$24(a0)
		bsr.w	Lamppost_StoreInfo
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		bset	#0,2(a2,d0.w)

locret_135CA:				; CODE XREF: ROM:00013548j
					; ROM:00013550j ...
		rts
; ---------------------------------------------------------------------------

Obj79_AfterHit:				; DATA XREF: ROM:000134E0o
		move.b	($FFFFFE0F).w,d0
		andi.b	#2,d0
		lsr.b	#1,d0
		addq.b	#1,d0
		move.b	d0,$1A(a0)
		rts

; =============== S U B	R O U T	I N E =======================================


Lamppost_StoreInfo:			; CODE XREF: ROM:000135B6p
		move.b	$28(a0),($FFFFFE30).w
		move.b	($FFFFFE30).w,($FFFFFE31).w
		move.w	8(a0),($FFFFFE32).w
		move.w	$C(a0),($FFFFFE34).w
		move.w	($FFFFFE20).w,($FFFFFE36).w
		move.b	($FFFFFE1B).w,($FFFFFE54).w
		move.l	($FFFFFE22).w,($FFFFFE38).w
		move.b	($FFFFEEDF).w,($FFFFFE3C).w
		move.w	($FFFFEECE).w,($FFFFFE3E).w
		move.w	(v_screenposx).w,($FFFFFE40).w
		move.w	(v_screenposy).w,($FFFFFE42).w
		move.w	(v_bgscreenposx).w,($FFFFFE44).w
		move.w	(v_bgscreenposy).w,($FFFFFE46).w
		move.w	(v_bg2screenposx).w,($FFFFFE48).w
		move.w	(v_bg2screenposy).w,($FFFFFE4A).w
		move.w	(v_bg3screenposx).w,($FFFFFE4C).w
		move.w	(v_bg3screenposy).w,($FFFFFE4E).w
		move.w	($FFFFF648).w,($FFFFFE50).w
		move.b	($FFFFF64D).w,($FFFFFE52).w
		move.b	($FFFFF64E).w,($FFFFFE53).w
		rts
; End of function Lamppost_StoreInfo


; =============== S U B	R O U T	I N E =======================================


Lamppost_LoadInfo:			; CODE XREF: LevelSizeLoad+180p
		move.b	($FFFFFE31).w,($FFFFFE30).w
		move.w	($FFFFFE32).w,(v_objspace+8).w
		move.w	($FFFFFE34).w,(v_objspace+$C).w
		move.w	($FFFFFE36).w,($FFFFFE20).w
		move.b	($FFFFFE54).w,($FFFFFE1B).w
		clr.w	($FFFFFE20).w
		clr.b	($FFFFFE1B).w
		move.l	($FFFFFE38).w,($FFFFFE22).w
		move.b	#$3B,($FFFFFE25).w 
		subq.b	#1,($FFFFFE24).w
		move.b	($FFFFFE3C).w,($FFFFEEDF).w
		move.b	($FFFFFE52).w,($FFFFF64D).w
		move.w	($FFFFFE3E).w,($FFFFEECE).w
		move.w	($FFFFFE3E).w,($FFFFEEC6).w
		move.w	($FFFFFE40).w,(v_screenposx).w
		move.w	($FFFFFE42).w,(v_screenposy).w
		move.w	($FFFFFE44).w,(v_bgscreenposx).w
		move.w	($FFFFFE46).w,(v_bgscreenposy).w
		move.w	($FFFFFE48).w,(v_bg2screenposx).w
		move.w	($FFFFFE4A).w,(v_bg2screenposy).w
		move.w	($FFFFFE4C).w,(v_bg3screenposx).w
		move.w	($FFFFFE4E).w,(v_bg3screenposy).w
		cmpi.b	#1,(v_zone).w
		bne.s	loc_136F0
		move.w	($FFFFFE50).w,($FFFFF648).w
		move.b	($FFFFFE52).w,($FFFFF64D).w
		move.b	($FFFFFE53).w,($FFFFF64E).w

loc_136F0:				; CODE XREF: Lamppost_LoadInfo+84j
		tst.b	($FFFFFE30).w
		bpl.s	locret_13702
		move.w	($FFFFFE32).w,d0
		subi.w	#$A0,d0	
		move.w	d0,($FFFFEEC8).w

locret_13702:				; CODE XREF: Lamppost_LoadInfo+9Cj
		rts
; End of function Lamppost_LoadInfo

; ---------------------------------------------------------------------------
Map_Obj79:	dc.w word_1370A-Map_Obj79 ; DATA XREF: ROM:000134E6o
					; ROM:Map_Obj79o ...
		dc.w word_1372C-Map_Obj79
		dc.w word_1374E-Map_Obj79
word_1370A:	dc.w 4			; DATA XREF: ROM:Map_Obj79o
		dc.w $E801,$2000,$2000,$FFF8; 0
		dc.w $E801,$2800,$2800,	   0; 4
		dc.w $F803,    6,    3,$FFF8; 8
		dc.w $F803, $806, $803,	   0; 12
word_1372C:	dc.w 4			; DATA XREF: ROM:00013706o
		dc.w $E801,    2,    1,$FFF8; 0
		dc.w $E801, $802, $801,	   0; 4
		dc.w $F803,    6,    3,$FFF8; 8
		dc.w $F803, $806, $803,	   0; 12
word_1374E:	dc.w 4			; DATA XREF: ROM:00013708o
		dc.w $E801,$2004,$2002,$FFF8; 0
		dc.w $E801,$2804,$2802,	   0; 4
		dc.w $F803,    6,    3,$FFF8; 8
		dc.w $F803, $806, $803,	   0; 12
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 7D - hidden points at the end of a level
;----------------------------------------------------

Obj7D:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj7D_Index(pc,d0.w),d1
		jmp	Obj7D_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj7D_Index:	dc.w Obj7D_Main-Obj7D_Index ; DATA XREF: ROM:Obj7D_Indexo
					; ROM:00013780o
		dc.w Obj7D_DelayDelete-Obj7D_Index
; ---------------------------------------------------------------------------

Obj7D_Main:				; DATA XREF: ROM:Obj7D_Indexo
		moveq	#$10,d2
		move.w	d2,d3
		add.w	d3,d3
		lea	(v_objspace).w,a1
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.s	loc_13804
		move.w	$C(a1),d1
		sub.w	$C(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.s	loc_13804
		tst.w	($FFFFFE08).w
		bne.s	loc_13804
		tst.b	($FFFFF7CD).w
		bne.s	loc_13804
		addq.b	#2,$24(a0)
		move.l	#Map_Obj7D,4(a0)
		move.w	#$84B6,2(a0)
		bsr.w	ModifySpriteAttr_2P
		ori.b	#4,1(a0)
		move.b	#0,$18(a0)
		move.b	#$10,$19(a0)
		move.b	$28(a0),$1A(a0)
		move.w	#$77,$30(a0) 
		move.w	#$C9,d0	; "?"
		jsr	(PlaySound_Special).l
		moveq	#0,d0
		move.b	$28(a0),d0
		add.w	d0,d0
		move.w	Obj7D_Points(pc,d0.w),d0
		jsr	AddPoints

loc_13804:				; CODE XREF: ROM:00013798j
					; ROM:000137A6j ...
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.s	loc_13818
		rts
; ---------------------------------------------------------------------------

loc_13818:				; CODE XREF: ROM:00013814j
		jmp	DeleteObject
; ---------------------------------------------------------------------------
Obj7D_Points:	dc.w	 0, 1000,  100,	   1; 0
; ---------------------------------------------------------------------------

Obj7D_DelayDelete:			; DATA XREF: ROM:00013780o
		subq.w	#1,$30(a0)
		bmi.s	loc_13844
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.s	loc_13844
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_13844:				; CODE XREF: ROM:0001382Aj
					; ROM:0001383Cj
		jmp	DeleteObject
; ---------------------------------------------------------------------------
Map_Obj7D:	dc.w word_13852-Map_Obj7D ; DATA XREF: ROM:000137B8o
					; ROM:Map_Obj7Do ...
		dc.w word_13854-Map_Obj7D
		dc.w word_1385E-Map_Obj7D
		dc.w word_13868-Map_Obj7D
word_13852:	dc.w 0			; DATA XREF: ROM:Map_Obj7Do
word_13854:	dc.w 1			; DATA XREF: ROM:0001384Co
		dc.w $F40E,    0,    0,$FFF0; 0
word_1385E:	dc.w 1			; DATA XREF: ROM:0001384Eo
		dc.w $F40E,   $C,    6,$FFF0; 0
word_13868:	dc.w 1			; DATA XREF: ROM:00013850o
		dc.w $F40E,  $18,   $C,$FFF0; 0
; ---------------------------------------------------------------------------
		nop

S1Obj47:
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	S1Obj47_Index(pc,d0.w),d1
		jmp	S1Obj47_Index(pc,d1.w)
; ---------------------------------------------------------------------------
S1Obj47_Index:	dc.w S1Obj47_Init-S1Obj47_Index	; DATA XREF: ROM:S1Obj47_Indexo
					; ROM:00013884o
		dc.w S1Obj47_Main-S1Obj47_Index
; ---------------------------------------------------------------------------

S1Obj47_Init:				; DATA XREF: ROM:S1Obj47_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_S1Obj47,4(a0)
		move.w	#$380,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#1,$18(a0)
		move.b	#$D7,$20(a0)

S1Obj47_Main:				; DATA XREF: ROM:00013884o
		move.b	$21(a0),d0
		beq.w	loc_13976
		lea	(v_objspace).w,a1
		bclr	#0,$21(a0)
		beq.s	loc_138CA
		bsr.s	S1Obj47_Bump

loc_138CA:				; CODE XREF: ROM:000138C6j
		lea	(v_objspace+$40).w,a1
		bclr	#1,$21(a0)
		beq.s	loc_138D8
		bsr.s	S1Obj47_Bump

loc_138D8:				; CODE XREF: ROM:000138D4j
		clr.b	$21(a0)
		bra.w	loc_13976

; =============== S U B	R O U T	I N E =======================================


S1Obj47_Bump:				; CODE XREF: ROM:000138C8p
					; ROM:000138D6p
		move.w	8(a0),d1
		move.w	$C(a0),d2
		sub.w	8(a1),d1
		sub.w	$C(a1),d2
		jsr	(CalcAngle).l
		jsr	(CalcSine).l
		muls.w	#$F900,d1
		asr.l	#8,d1
		move.w	d1,$10(a1)
		muls.w	#$F900,d0
		asr.l	#8,d0
		move.w	d0,$12(a1)
		bset	#1,$22(a1)
		bclr	#4,$22(a1)
		bclr	#5,$22(a1)
		clr.b	$3C(a1)
		move.b	#1,$1C(a0)
		move.w	#$B4,d0	; "?"
		jsr	(PlaySound_Special).l
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		beq.s	loc_1394E
		cmpi.b	#$8A,2(a2,d0.w)
		bcc.s	locret_13974
		addq.b	#1,2(a2,d0.w)

loc_1394E:				; CODE XREF: S1Obj47_Bump+60j
		moveq	#1,d0
		jsr	AddPoints
		bsr.w	SingleObjectLoad
		bne.s	locret_13974
		move.b	#$29,0(a1) 
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	#4,$1A(a1)

locret_13974:				; CODE XREF: S1Obj47_Bump+68j
					; S1Obj47_Bump+7Aj
		rts
; End of function S1Obj47_Bump

; ---------------------------------------------------------------------------

loc_13976:				; CODE XREF: ROM:000138B8j
					; ROM:000138DCj
		lea	(Ani_S1Obj47).l,a1
		bsr.w	AnimateSprite
		bra.w	MarkObjGone
; ---------------------------------------------------------------------------
Ani_S1Obj47:	dc.w byte_13988-Ani_S1Obj47 ; DATA XREF: ROM:loc_13976o
					; ROM:Ani_S1Obj47o ...
		dc.w byte_1398B-Ani_S1Obj47
byte_13988:	dc.b  $F,  0,$FF	; 0 ; DATA XREF: ROM:Ani_S1Obj47o
byte_1398B:	dc.b   3,  1,  2,  1,  2,$FD,  0; 0 ; DATA XREF: ROM:00013986o
Map_S1Obj47:	dc.w word_13998-Map_S1Obj47 ; DATA XREF: ROM:0001388Ao
					; ROM:Map_S1Obj47o ...
		dc.w word_139AA-Map_S1Obj47
		dc.w word_139BC-Map_S1Obj47
word_13998:	dc.w 2			; DATA XREF: ROM:Map_S1Obj47o
		dc.w $F007,    0,    0,$FFF0; 0
		dc.w $F007, $800, $800,	   0; 4
word_139AA:	dc.w 2			; DATA XREF: ROM:00013994o
		dc.w $F406,    8,    4,$FFF4; 0
		dc.w $F402, $808, $804,	   4; 4
word_139BC:	dc.w 2			; DATA XREF: ROM:00013996o
		dc.w $F007,   $E,    7,$FFF0; 0
		dc.w $F007, $80E, $807,	   0; 4
; ---------------------------------------------------------------------------
		nop

S1Obj64:
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	S1Obj64_Index(pc,d0.w),d1
		jmp	S1Obj64_Index(pc,d1.w)
; ---------------------------------------------------------------------------
S1Obj64_Index:	dc.w S1Obj64_Init-S1Obj64_Index	; DATA XREF: ROM:S1Obj64_Indexo
					; ROM:000139E0o ...
		dc.w S1Obj64_Animate-S1Obj64_Index
		dc.w S1Obj64_ChkWater-S1Obj64_Index
		dc.w S1Obj64_Display-S1Obj64_Index
		dc.w S1Obj64_Delete-S1Obj64_Index
		dc.w S1Obj64_BblMaker-S1Obj64_Index
; ---------------------------------------------------------------------------

S1Obj64_Init:				; DATA XREF: ROM:S1Obj64_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj0A_Bubbles,4(a0)
		move.w	#$8348,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#$84,1(a0)
		move.b	#$10,$19(a0)
		move.b	#1,$18(a0)
		move.b	$28(a0),d0
		bpl.s	loc_13A32
		addq.b	#8,$24(a0)
		andi.w	#$7F,d0	
		move.b	d0,$32(a0)
		move.b	d0,$33(a0)
		move.b	#6,$1C(a0)
		bra.w	S1Obj64_BblMaker
; ---------------------------------------------------------------------------

loc_13A32:				; CODE XREF: ROM:00013A16j
		move.b	d0,$1C(a0)
		move.w	8(a0),$30(a0)
		move.w	#$FF78,$12(a0)
		jsr	(PseudoRandomNumber).l
		move.b	d0,$26(a0)

S1Obj64_Animate:			; DATA XREF: ROM:000139E0o
		lea	(Ani_S1Obj64).l,a1
		jsr	AnimateSprite
		cmpi.b	#6,$1A(a0)
		bne.s	S1Obj64_ChkWater
		move.b	#1,$2E(a0)

S1Obj64_ChkWater:			; CODE XREF: ROM:00013A5Ej
					; DATA XREF: ROM:000139E2o
		move.w	($FFFFF646).w,d0
		cmp.w	$C(a0),d0
		bcs.s	loc_13A7E

loc_13A70:				; CODE XREF: ROM:00013AECj
					; ROM:00013B06j
		move.b	#6,$24(a0)
		addq.b	#3,$1C(a0)
		bra.w	S1Obj64_Display
; ---------------------------------------------------------------------------

loc_13A7E:				; CODE XREF: ROM:00013A6Ej
		move.b	$26(a0),d0
		addq.b	#1,$26(a0)
		andi.w	#$7F,d0	
		lea	(Obj0A_WobbleData).l,a1
		move.b	(a1,d0.w),d0
		ext.w	d0
		add.w	$30(a0),d0
		move.w	d0,8(a0)
		tst.b	$2E(a0)
		beq.s	loc_13B0A
		bsr.w	S1Obj64_ChkSonic
		beq.s	loc_13B0A
		bsr.w	ResumeMusic
		move.w	#$AD,d0	; "?"
		jsr	(PlaySound_Special).l
		lea	(v_objspace).w,a1
		clr.w	$10(a1)
		clr.w	$12(a1)
		clr.w	$14(a1)
		move.b	#$15,$1C(a1)
		move.w	#$23,$2E(a1) 
		move.b	#0,$3C(a1)
		bclr	#5,$22(a1)
		bclr	#4,$22(a1)
		btst	#2,$22(a1)
		beq.w	loc_13A70
		bclr	#2,$22(a1)
		move.b	#$13,$16(a1)
		move.b	#9,$17(a1)
		subq.w	#5,$C(a1)
		bra.w	loc_13A70
; ---------------------------------------------------------------------------

loc_13B0A:				; CODE XREF: ROM:00013AA2j
					; ROM:00013AA8j
		bsr.w	SpeedToPos
		tst.b	1(a0)
		bpl.s	loc_13B1A
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_13B1A:				; CODE XREF: ROM:00013B12j
		jmp	DeleteObject
; ---------------------------------------------------------------------------

S1Obj64_Display:			; CODE XREF: ROM:00013A7Aj
					; DATA XREF: ROM:000139E4o
		lea	(Ani_S1Obj64).l,a1
		jsr	AnimateSprite
		tst.b	1(a0)
		bpl.s	loc_13B38
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_13B38:				; CODE XREF: ROM:00013B30j
		jmp	DeleteObject
; ---------------------------------------------------------------------------

S1Obj64_Delete:				; DATA XREF: ROM:000139E6o
		bra.w	DeleteObject
; ---------------------------------------------------------------------------

S1Obj64_BblMaker:			; CODE XREF: ROM:00013A2Ej
					; DATA XREF: ROM:000139E8o
		tst.w	$36(a0)
		bne.s	loc_13BA4
		move.w	($FFFFF646).w,d0
		cmp.w	$C(a0),d0
		bcc.w	loc_13C50
		tst.b	1(a0)
		bpl.w	loc_13C50
		subq.w	#1,$38(a0)
		bpl.w	loc_13C44
		move.w	#1,$36(a0)

loc_13B6A:				; CODE XREF: ROM:00013B7Aj
		jsr	(PseudoRandomNumber).l
		move.w	d0,d1
		andi.w	#7,d0
		cmpi.w	#6,d0
		bcc.s	loc_13B6A
		move.b	d0,$34(a0)
		andi.w	#$C,d1
		lea	(S1Obj64_BblTypes).l,a1
		adda.w	d1,a1
		move.l	a1,$3C(a0)
		subq.b	#1,$32(a0)
		bpl.s	loc_13BA2
		move.b	$33(a0),$32(a0)
		bset	#7,$36(a0)

loc_13BA2:				; CODE XREF: ROM:00013B94j
		bra.s	loc_13BAC
; ---------------------------------------------------------------------------

loc_13BA4:				; CODE XREF: ROM:00013B46j
		subq.w	#1,$38(a0)
		bpl.w	loc_13C44

loc_13BAC:				; CODE XREF: ROM:loc_13BA2j
		jsr	(PseudoRandomNumber).l
		andi.w	#$1F,d0
		move.w	d0,$38(a0)
		bsr.w	SingleObjectLoad
		bne.s	loc_13C28
		move.b	#$64,0(a1) 
		move.w	8(a0),8(a1)
		jsr	(PseudoRandomNumber).l
		andi.w	#$F,d0
		subq.w	#8,d0
		add.w	d0,8(a1)
		move.w	$C(a0),$C(a1)
		moveq	#0,d0
		move.b	$34(a0),d0
		movea.l	$3C(a0),a2
		move.b	(a2,d0.w),$28(a1)
		btst	#7,$36(a0)
		beq.s	loc_13C28
		jsr	(PseudoRandomNumber).l
		andi.w	#3,d0
		bne.s	loc_13C14
		bset	#6,$36(a0)
		bne.s	loc_13C28
		move.b	#2,$28(a1)

loc_13C14:				; CODE XREF: ROM:00013C04j
		tst.b	$34(a0)
		bne.s	loc_13C28
		bset	#6,$36(a0)
		bne.s	loc_13C28
		move.b	#2,$28(a1)

loc_13C28:				; CODE XREF: ROM:00013BBEj
					; ROM:00013BF8j ...
		subq.b	#1,$34(a0)
		bpl.s	loc_13C44
		jsr	(PseudoRandomNumber).l
		andi.w	#$7F,d0	
		addi.w	#$80,d0	
		add.w	d0,$38(a0)
		clr.w	$36(a0)

loc_13C44:				; CODE XREF: ROM:00013B60j
					; ROM:00013BA8j ...
		lea	(Ani_S1Obj64).l,a1
		jsr	AnimateSprite

loc_13C50:				; CODE XREF: ROM:00013B50j
					; ROM:00013B58j
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		move.w	($FFFFF646).w,d0
		cmp.w	$C(a0),d0
		bcs.w	DisplaySprite
		rts
; ---------------------------------------------------------------------------
S1Obj64_BblTypes:dc.b	0,  1,	0,  0,	0,  0,	1,  0,	0; 0 ; DATA XREF: ROM:00013B84o
		dc.b   0,  0,  1,  0,  1,  0,  0,  1,  0; 9

; =============== S U B	R O U T	I N E =======================================


S1Obj64_ChkSonic:			; CODE XREF: ROM:00013AA4p
		tst.b	($FFFFF7C8).w
		bmi.s	loc_13CBE
		lea	(v_objspace).w,a1
		move.w	8(a1),d0
		move.w	8(a0),d1
		subi.w	#$10,d1
		cmp.w	d0,d1
		bcc.s	loc_13CBE
		addi.w	#$20,d1	
		cmp.w	d0,d1
		bcs.s	loc_13CBE
		move.w	$C(a1),d0
		move.w	$C(a0),d1
		cmp.w	d0,d1
		bcc.s	loc_13CBE
		addi.w	#$10,d1
		cmp.w	d0,d1
		bcs.s	loc_13CBE
		moveq	#1,d0
		rts
; ---------------------------------------------------------------------------

loc_13CBE:				; CODE XREF: S1Obj64_ChkSonic+4j
					; S1Obj64_ChkSonic+18j	...
		moveq	#0,d0
		rts
; End of function S1Obj64_ChkSonic

; ---------------------------------------------------------------------------
Ani_S1Obj64:	dc.w byte_13CD0-Ani_S1Obj64 ; DATA XREF: ROM:S1Obj64_Animateo
					; ROM:S1Obj64_Displayo	...
		dc.w byte_13CD5-Ani_S1Obj64
		dc.w byte_13CDB-Ani_S1Obj64
		dc.w byte_13CE2-Ani_S1Obj64
		dc.w byte_13CE2-Ani_S1Obj64
		dc.w byte_13CE4-Ani_S1Obj64
		dc.w byte_13CE9-Ani_S1Obj64
byte_13CD0:	dc.b  $E,  0,  1,  2,$FC; 0 ; DATA XREF: ROM:Ani_S1Obj64o
byte_13CD5:	dc.b  $E,  1,  2,  3,  4,$FC; 0	; DATA XREF: ROM:00013CC4o
byte_13CDB:	dc.b  $E,  2,  3,  4,  5,  6,$FC; 0 ; DATA XREF: ROM:00013CC6o
byte_13CE2:	dc.b   4,$FC		; 0 ; DATA XREF: ROM:00013CC8o
					; ROM:00013CCAo
byte_13CE4:	dc.b   4,  6,  7,  8,$FC; 0 ; DATA XREF: ROM:00013CCCo
byte_13CE9:	dc.b  $F,$13,$14,$15,$FF; 0 ; DATA XREF: ROM:00013CCEo
Map_Obj0A_Bubbles:dc.w word_13D1C-Map_Obj0A_Bubbles ; DATA XREF: ROM:00011E88o
					; ROM:000139EEo ...
		dc.w word_13D26-Map_Obj0A_Bubbles
		dc.w word_13D30-Map_Obj0A_Bubbles
		dc.w word_13D3A-Map_Obj0A_Bubbles
		dc.w word_13D44-Map_Obj0A_Bubbles
		dc.w word_13D4E-Map_Obj0A_Bubbles
		dc.w word_13D58-Map_Obj0A_Bubbles
		dc.w word_13D62-Map_Obj0A_Bubbles
		dc.w word_13D84-Map_Obj0A_Bubbles
		dc.w word_13DA6-Map_Obj0A_Bubbles
		dc.w word_13DB0-Map_Obj0A_Bubbles
		dc.w word_13DBA-Map_Obj0A_Bubbles
		dc.w word_13DC4-Map_Obj0A_Bubbles
		dc.w word_13DCE-Map_Obj0A_Bubbles
		dc.w word_13DD8-Map_Obj0A_Bubbles
		dc.w word_13DE2-Map_Obj0A_Bubbles
		dc.w word_13DEC-Map_Obj0A_Bubbles
		dc.w word_13DF6-Map_Obj0A_Bubbles
		dc.w word_13E00-Map_Obj0A_Bubbles
		dc.w word_13E0A-Map_Obj0A_Bubbles
		dc.w word_13E14-Map_Obj0A_Bubbles
		dc.w word_13E1E-Map_Obj0A_Bubbles
		dc.w word_13E28-Map_Obj0A_Bubbles
word_13D1C:	dc.w 1			; DATA XREF: ROM:Map_Obj0A_Bubbleso
		dc.w $FC00,    0,    0,$FFFC; 0
word_13D26:	dc.w 1			; DATA XREF: ROM:00013CF0o
		dc.w $FC00,    1,    0,$FFFC; 0
word_13D30:	dc.w 1			; DATA XREF: ROM:00013CF2o
		dc.w $FC00,    2,    1,$FFFC; 0
word_13D3A:	dc.w 1			; DATA XREF: ROM:00013CF4o
		dc.w $F805,    3,    1,$FFF8; 0
word_13D44:	dc.w 1			; DATA XREF: ROM:00013CF6o
		dc.w $F805,    7,    3,$FFF8; 0
word_13D4E:	dc.w 1			; DATA XREF: ROM:00013CF8o
		dc.w $F40A,   $B,    5,$FFF4; 0
word_13D58:	dc.w 1			; DATA XREF: ROM:00013CFAo
		dc.w $F00F,  $14,   $A,$FFF0; 0
word_13D62:	dc.w 4			; DATA XREF: ROM:00013CFCo
		dc.w $F005,  $24,  $12,$FFF0; 0
		dc.w $F005, $824, $812,	   0; 4
		dc.w	 5,$1024,$1012,$FFF0; 8
		dc.w	 5,$1824,$1812,	   0; 12
word_13D84:	dc.w 4			; DATA XREF: ROM:00013CFEo
		dc.w $F005,  $28,  $14,$FFF0; 0
		dc.w $F005, $828, $814,	   0; 4
		dc.w	 5,$1028,$1014,$FFF0; 8
		dc.w	 5,$1828,$1814,	   0; 12
word_13DA6:	dc.w 1			; DATA XREF: ROM:00013D00o
		dc.w $F406,  $2C,  $16,$FFF8; 0
word_13DB0:	dc.w 1			; DATA XREF: ROM:00013D02o
		dc.w $F406,  $32,  $19,$FFF8; 0
word_13DBA:	dc.w 1			; DATA XREF: ROM:00013D04o
		dc.w $F406,  $38,  $1C,$FFF8; 0
word_13DC4:	dc.w 1			; DATA XREF: ROM:00013D06o
		dc.w $F406,  $3E,  $1F,$FFF8; 0
word_13DCE:	dc.w 1			; DATA XREF: ROM:00013D08o
		dc.w $F406,$2044,$2022,$FFF8; 0
word_13DD8:	dc.w 1			; DATA XREF: ROM:00013D0Ao
		dc.w $F406,$204A,$2025,$FFF8; 0
word_13DE2:	dc.w 1			; DATA XREF: ROM:00013D0Co
		dc.w $F406,$2050,$2028,$FFF8; 0
word_13DEC:	dc.w 1			; DATA XREF: ROM:00013D0Eo
		dc.w $F406,$2056,$202B,$FFF8; 0
word_13DF6:	dc.w 1			; DATA XREF: ROM:00013D10o
		dc.w $F406,$205C,$202E,$FFF8; 0
word_13E00:	dc.w 1			; DATA XREF: ROM:00013D12o
		dc.w $F406,$2062,$2031,$FFF8; 0
word_13E0A:	dc.w 1			; DATA XREF: ROM:00013D14o
		dc.w $F805,  $68,  $34,$FFF8; 0
word_13E14:	dc.w 1			; DATA XREF: ROM:00013D16o
		dc.w $F805,  $6C,  $36,$FFF8; 0
word_13E1E:	dc.w 1			; DATA XREF: ROM:00013D18o
		dc.w $F805,  $70,  $38,$FFF8; 0
word_13E28:	dc.w 0			; DATA XREF: ROM:00013D1Ao
; ---------------------------------------------------------------------------
		nop

                include "_incObj\03 Pathswappers.asm"

Map_Obj03:	dc.w word_140E8-Map_Obj03 ; DATA XREF: ROM:00013E52o
					; ROM:Map_Obj03o ...
		dc.w word_1410A-Map_Obj03
		dc.w word_1412C-Map_Obj03
		dc.w word_1412C-Map_Obj03
		dc.w word_1414E-Map_Obj03
		dc.w word_14170-Map_Obj03
		dc.w word_14192-Map_Obj03
		dc.w word_14192-Map_Obj03
word_140E8:	dc.w 4			; DATA XREF: ROM:Map_Obj03o
		dc.w $E005,    0,    0,$FFF8; 0
		dc.w $F005,    0,    0,$FFF8; 4
		dc.w	 5,    0,    0,$FFF8; 8
		dc.w $1005,    0,    0,$FFF8; 12
word_1410A:	dc.w 4			; DATA XREF: ROM:000140DAo
		dc.w $C005,    0,    0,$FFF8; 0
		dc.w $E005,    0,    0,$FFF8; 4
		dc.w	 5,    0,    0,$FFF8; 8
		dc.w $3005,    0,    0,$FFF8; 12
word_1412C:	dc.w 4			; DATA XREF: ROM:000140DCo
					; ROM:000140DEo
		dc.w $8005,    0,    0,$FFF8; 0
		dc.w $E005,    0,    0,$FFF8; 4
		dc.w	 5,    0,    0,$FFF8; 8
		dc.w $7005,    0,    0,$FFF8; 12
word_1414E:	dc.w 4			; DATA XREF: ROM:000140E0o
		dc.w $F805,    0,    0,$FFE0; 0
		dc.w $F805,    0,    0,$FFF0; 4
		dc.w $F805,    0,    0,	   0; 8
		dc.w $F805,    0,    0,	 $10; 12
word_14170:	dc.w 4			; DATA XREF: ROM:000140E2o
		dc.w $F805,    0,    0,$FFC0; 0
		dc.w $F805,    0,    0,$FFE0; 4
		dc.w $F805,    0,    0,	   0; 8
		dc.w $F805,    0,    0,	 $30; 12
word_14192:	dc.w 4			; DATA XREF: ROM:000140E4o
					; ROM:000140E6o
		dc.w $F805,    0,    0,$FF80; 0
		dc.w $F805,    0,    0,$FFE0; 4
		dc.w $F805,    0,    0,	   0; 8
		dc.w $F805,    0,    0,	 $70; 12
; ---------------------------------------------------------------------------

Obj0B:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj0B_Index(pc,d0.w),d1
		jmp	Obj0B_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj0B_Index:	dc.w loc_141C8-Obj0B_Index ; DATA XREF:	ROM:Obj0B_Indexo
					; ROM:000141C4o ...
		dc.w loc_1421C-Obj0B_Index
		dc.w loc_1422A-Obj0B_Index
; ---------------------------------------------------------------------------

loc_141C8:				; DATA XREF: ROM:Obj0B_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj0B,4(a0)
		move.w	#$E000,2(a0)
		bsr.w	ModifySpriteAttr_2P
		ori.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#4,$18(a0)
		moveq	#0,d0
		move.b	$28(a0),d0
		andi.w	#$F0,d0	; "?"
		addi.w	#$10,d0
		move.w	d0,d1
		subq.w	#1,d0
		move.w	d0,$30(a0)
		move.w	d0,$32(a0)
		moveq	#0,d0
		move.b	$28(a0),d0
		andi.w	#$F,d0
		addq.w	#1,d0
		lsl.w	#4,d0
		move.b	d0,$36(a0)

loc_1421C:				; DATA XREF: ROM:000141C4o
		move.b	($FFFFFE0F).w,d0
		add.b	$36(a0),d0
		bne.s	loc_14254
		addq.b	#2,$24(a0)

loc_1422A:				; DATA XREF: ROM:000141C6o
		subq.w	#1,$30(a0)
		bpl.s	loc_14248
		move.w	#$7F,$30(a0) 
		tst.b	$1C(a0)
		beq.s	loc_14242
		move.w	$32(a0),$30(a0)

loc_14242:				; CODE XREF: ROM:0001423Aj
		bchg	#0,$1C(a0)

loc_14248:				; CODE XREF: ROM:0001422Ej
		lea	(off_1428A).l,a1
		jsr	AnimateSprite

loc_14254:				; CODE XREF: ROM:00014224j
		tst.b	$1A(a0)
		bne.s	loc_1426E
		moveq	#0,d1
		move.b	$19(a0),d1
		moveq	#$11,d3
		move.w	8(a0),d4
		bsr.w	sub_F78A
		bra.w	MarkObjGone
; ---------------------------------------------------------------------------

loc_1426E:				; CODE XREF: ROM:00014258j
		btst	#3,$22(a0)
		beq.s	loc_14286
		lea	(v_objspace).w,a1
		bclr	#3,$22(a1)
		bclr	#3,$22(a0)

loc_14286:				; CODE XREF: ROM:00014274j
		bra.w	MarkObjGone
; ---------------------------------------------------------------------------
off_1428A:	dc.w byte_1428E-off_1428A ; DATA XREF: ROM:loc_14248o
					; ROM:off_1428Ao ...
		dc.w byte_14296-off_1428A
byte_1428E:	dc.b   7,  0,  1,  2,  3,  4,$FE,  1; 0	; DATA XREF: ROM:off_1428Ao
byte_14296:	dc.b   7,  4,  3,  2,  1,  0,$FE,  1; 0	; DATA XREF: ROM:0001428Co
Map_Obj0B:	dc.w word_142A8-Map_Obj0B ; DATA XREF: ROM:000141CCo
					; ROM:Map_Obj0Bo ...
		dc.w word_142B2-Map_Obj0B
		dc.w word_142BC-Map_Obj0B
		dc.w word_142C6-Map_Obj0B
		dc.w word_142D0-Map_Obj0B
word_142A8:	dc.w 1			; DATA XREF: ROM:Map_Obj0Bo
		dc.w $F00C,  $11,    8,$FFF0; 0
word_142B2:	dc.w 1			; DATA XREF: ROM:000142A0o
		dc.w $E80F,  $15,   $A,$FFF0; 0
word_142BC:	dc.w 1			; DATA XREF: ROM:000142A2o
		dc.w $F40F,  $25,  $12,$FFF0; 0
word_142C6:	dc.w 1			; DATA XREF: ROM:000142A4o
		dc.w	$F,$1015,$100A,$FFF0; 0
word_142D0:	dc.w 1			; DATA XREF: ROM:000142A6o
		dc.w $100C,$1011,$1008,$FFF0; 0
; ---------------------------------------------------------------------------
		nop

Obj0C:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj0C_Index(pc,d0.w),d1
		jmp	Obj0C_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj0C_Index:	dc.w Obj0C_Init-Obj0C_Index ; DATA XREF: ROM:Obj0C_Indexo
					; ROM:000142ECo
		dc.w Obj0C_Main-Obj0C_Index
; ---------------------------------------------------------------------------

Obj0C_Init:				; DATA XREF: ROM:Obj0C_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj0C,4(a0)
		move.w	#$E418,2(a0)
		bsr.w	ModifySpriteAttr_2P
		ori.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#4,$18(a0)
		move.w	$C(a0),d0
		subi.w	#$10,d0
		move.w	d0,$3A(a0)
		moveq	#0,d0
		move.b	$28(a0),d0
		andi.w	#$F0,d0	; "?"
		addi.w	#$10,d0
		move.w	d0,d1
		subq.w	#1,d0
		move.w	d0,$30(a0)
		move.w	d0,$32(a0)
		moveq	#0,d0
		move.b	$28(a0),d0
		andi.w	#$F,d0
		move.b	d0,$3E(a0)
		move.b	d0,$3F(a0)

Obj0C_Main:				; DATA XREF: ROM:000142ECo
		move.b	$3C(a0),d0
		beq.s	loc_1438C
		cmpi.b	#$80,d0
		bne.s	loc_1439C
		move.b	$3D(a0),d1
		bne.s	loc_1436E
		subq.b	#1,$3E(a0)
		bpl.s	loc_1436E
		move.b	$3F(a0),$3E(a0)
		bra.s	loc_1439C
; ---------------------------------------------------------------------------

loc_1436E:				; CODE XREF: ROM:0001435Ej
					; ROM:00014364j
		addq.b	#1,$3D(a0)
		move.b	d1,d0
	if removeJmpTos=1
		jsr	(CalcSine).l
	else
		bsr.w	j_CalcSine
	endif
		addi.w	#8,d0
		asr.w	#6,d0
		subi.w	#$10,d0
		add.w	$3A(a0),d0
		move.w	d0,$C(a0)
		bra.s	loc_143B2
; ---------------------------------------------------------------------------

loc_1438C:				; CODE XREF: ROM:00014352j
		move.w	($FFFFFE0E).w,d1
		andi.w	#$3FF,d1
		bne.s	loc_143A0
		move.b	#1,$3D(a0)

loc_1439C:				; CODE XREF: ROM:00014358j
					; ROM:0001436Cj
		addq.b	#1,$3C(a0)

loc_143A0:				; CODE XREF: ROM:00014394j
	if removeJmpTos=1
		jsr	(CalcSine).l
	else
		bsr.w	j_CalcSine
	endif
		addi.w	#8,d1
		asr.w	#4,d1
		add.w	$3A(a0),d1
		move.w	d1,$C(a0)

loc_143B2:				; CODE XREF: ROM:0001438Aj
		moveq	#0,d1
		move.b	$19(a0),d1
		moveq	#9,d3
		move.w	8(a0),d4
		bsr.w	sub_F78A
		bra.w	MarkObjGone
; ---------------------------------------------------------------------------
Map_Obj0C:	dc.w word_143C8-Map_Obj0C ; DATA XREF: ROM:000142F2o
					; ROM:Map_Obj0Co ...
word_143C8:	dc.w 1			; DATA XREF: ROM:Map_Obj0Co
		dc.w $F80D,    0,    0,$FFF0; 0
; ---------------------------------------------------------------------------
		nop

        if removeJmpTos=0
j_CalcSine:				; CODE XREF: ROM:00014374p
					; ROM:loc_143A0p
		jmp	(CalcSine).l

		align 4
	endif
;----------------------------------------------------
; Object 12 - Master Emerald from HPZ
;----------------------------------------------------

Obj12:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj12_Index(pc,d0.w),d1
		jmp	Obj12_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj12_Index:	dc.w Obj12_Init-Obj12_Index ; DATA XREF: ROM:Obj12_Indexo
					; ROM:000143ECo
		dc.w Obj12_Display-Obj12_Index
; ---------------------------------------------------------------------------

Obj12_Init:				; DATA XREF: ROM:Obj12_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj12,4(a0)
		move.w	#$6392,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#$20,$19(a0) 
		move.b	#4,$18(a0)

Obj12_Display:				; DATA XREF: ROM:000143ECo
		move.w	#$20,d1	
		move.w	#$10,d2
		move.w	#$10,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Map_Obj12:	dc.w word_14444-Map_Obj12 ; DATA XREF: ROM:000143F2o
					; ROM:Map_Obj12o
word_14444:	dc.w 2			; DATA XREF: ROM:Map_Obj12o
		dc.w $F00F,    0,    0,$FFE0; 0
		dc.w $F00F,  $10,    8,	   0; 4
; ---------------------------------------------------------------------------
		nop
;----------------------------------------------------
; Object 13 - HPZ waterfall
;----------------------------------------------------

Obj13:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj13_Index(pc,d0.w),d1
		jmp	Obj13_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj13_Index:	dc.w loc_1446C-Obj13_Index ; DATA XREF:	ROM:Obj13_Indexo
					; ROM:00014468o ...
		dc.w loc_14532-Obj13_Index
		dc.w loc_145BC-Obj13_Index
; ---------------------------------------------------------------------------

loc_1446C:				; DATA XREF: ROM:Obj13_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj13,4(a0)
		move.w	#$E315,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#1,$18(a0)
		move.b	#$12,$1A(a0)
		bsr.s	sub_144D4
		move.b	#$A0,$16(a1)
		bset	#4,1(a1)
		move.l	a1,$38(a0)
		move.w	$C(a0),$34(a0)
		move.w	$C(a0),$36(a0)
		cmpi.b	#$10,$28(a0)
		bcs.s	loc_14518
		bsr.s	sub_144D4
		move.l	a1,$3C(a0)
		move.w	$C(a0),$C(a1)
		addi.w	#$98,$C(a1) ; "?"
		bra.s	loc_14518

; =============== S U B	R O U T	I N E =======================================


sub_144D4:				; CODE XREF: ROM:0001449Ap
					; ROM:000144C0p
		jsr	S1SingleObjectLoad2
		bne.s	locret_14516
		move.b	#$13,0(a1)
		addq.b	#4,$24(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.l	#Map_Obj13,4(a1)
		move.w	#$E315,2(a1)
		bsr.w	ModifyA1SpriteAttr_2P
		move.b	#4,1(a1)
		move.b	#$10,$19(a1)
		move.b	#1,$18(a1)

locret_14516:				; CODE XREF: sub_144D4+6j
		rts
; End of function sub_144D4

; ---------------------------------------------------------------------------

loc_14518:				; CODE XREF: ROM:000144BEj
					; ROM:000144D2j
		moveq	#0,d1
		move.b	$28(a0),d1
		move.w	$34(a0),d0
		subi.w	#$78,d0	
		lsl.w	#4,d1
		add.w	d1,d0
		move.w	d0,$C(a0)
		move.w	d0,$34(a0)

loc_14532:				; DATA XREF: ROM:00014468o
		movea.l	$38(a0),a1
		move.b	#$12,$1A(a0)
		move.w	$34(a0),d0
		move.w	($FFFFF646).w,d1
		cmp.w	d0,d1
		bcc.s	loc_1454A
		move.w	d1,d0

loc_1454A:				; CODE XREF: ROM:00014546j
		move.w	d0,$C(a0)
		sub.w	$36(a0),d0
		addi.w	#$80,d0	
		bmi.s	loc_1459C
		lsr.w	#4,d0
		move.w	d0,d1
		cmpi.w	#$F,d0
		bcs.s	loc_14564
		moveq	#$F,d0

loc_14564:				; CODE XREF: ROM:00014560j
		move.b	d0,$1A(a1)
		cmpi.b	#$10,$28(a0)
		bcs.s	loc_14584
		movea.l	$3C(a0),a1
		subi.w	#$F,d1
		bcc.s	loc_1457C
		moveq	#0,d1

loc_1457C:				; CODE XREF: ROM:00014578j
		addi.w	#$13,d1
		move.b	d1,$1A(a1)

loc_14584:				; CODE XREF: ROM:0001456Ej
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------

loc_1459C:				; CODE XREF: ROM:00014556j
		moveq	#$13,d0
		move.b	d0,$1A(a0)
		move.b	d0,$1A(a1)
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		rts
; ---------------------------------------------------------------------------

loc_145BC:				; DATA XREF: ROM:0001446Ao
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Map_Obj13:	dc.w word_1460E-Map_Obj13 ; DATA XREF: ROM:00014470o
					; sub_144D4+1Eo ...
		dc.w word_14618-Map_Obj13
		dc.w word_1462A-Map_Obj13
		dc.w word_1463C-Map_Obj13
		dc.w word_14656-Map_Obj13
		dc.w word_14670-Map_Obj13
		dc.w word_14692-Map_Obj13
		dc.w word_146B4-Map_Obj13
		dc.w word_146DE-Map_Obj13
		dc.w word_14708-Map_Obj13
		dc.w word_1473A-Map_Obj13
		dc.w word_1476C-Map_Obj13
		dc.w word_147A6-Map_Obj13
		dc.w word_147E0-Map_Obj13
		dc.w word_14822-Map_Obj13
		dc.w word_14864-Map_Obj13
		dc.w word_148AE-Map_Obj13
		dc.w word_148AE-Map_Obj13
		dc.w word_148AE-Map_Obj13
		dc.w word_1460C-Map_Obj13
		dc.w word_148C0-Map_Obj13
		dc.w word_148CA-Map_Obj13
		dc.w word_148D4-Map_Obj13
		dc.w word_148E6-Map_Obj13
		dc.w word_148F8-Map_Obj13
		dc.w word_14912-Map_Obj13
		dc.w word_1492C-Map_Obj13
		dc.w word_1494E-Map_Obj13
word_1460C:	dc.w 0			; DATA XREF: ROM:000145FAo
word_1460E:	dc.w 1			; DATA XREF: ROM:Map_Obj13o
		dc.w $800C,  $10,    8,$FFF0; 0
word_14618:	dc.w 2			; DATA XREF: ROM:000145D6o
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880D,  $2D,  $16,$FFF0; 4
word_1462A:	dc.w 2			; DATA XREF: ROM:000145D8o
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880F,    0,    0,$FFF0; 4
word_1463C:	dc.w 3			; DATA XREF: ROM:000145DAo
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880F,    0,    0,$FFF0; 4
		dc.w $A80D,  $2D,  $16,$FFF0; 8
word_14656:	dc.w 3			; DATA XREF: ROM:000145DCo
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880F,    0,    0,$FFF0; 4
		dc.w $A80F,    0,    0,$FFF0; 8
word_14670:	dc.w 4			; DATA XREF: ROM:000145DEo
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880F,    0,    0,$FFF0; 4
		dc.w $A80F,    0,    0,$FFF0; 8
		dc.w $C80D,  $2D,  $16,$FFF0; 12
word_14692:	dc.w 4			; DATA XREF: ROM:000145E0o
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880F,    0,    0,$FFF0; 4
		dc.w $A80F,    0,    0,$FFF0; 8
		dc.w $C80F,    0,    0,$FFF0; 12
word_146B4:	dc.w 5			; DATA XREF: ROM:000145E2o
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880F,    0,    0,$FFF0; 4
		dc.w $A80F,    0,    0,$FFF0; 8
		dc.w $C80F,    0,    0,$FFF0; 12
		dc.w $E80D,  $2D,  $16,$FFF0; 16
word_146DE:	dc.w 5			; DATA XREF: ROM:000145E4o
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880F,    0,    0,$FFF0; 4
		dc.w $A80F,    0,    0,$FFF0; 8
		dc.w $C80F,    0,    0,$FFF0; 12
		dc.w $E80F,    0,    0,$FFF0; 16
word_14708:	dc.w 6			; DATA XREF: ROM:000145E6o
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880F,    0,    0,$FFF0; 4
		dc.w $A80F,    0,    0,$FFF0; 8
		dc.w $C80F,    0,    0,$FFF0; 12
		dc.w $E80F,    0,    0,$FFF0; 16
		dc.w  $80D,  $2D,  $16,$FFF0; 20
word_1473A:	dc.w 6			; DATA XREF: ROM:000145E8o
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880F,    0,    0,$FFF0; 4
		dc.w $A80F,    0,    0,$FFF0; 8
		dc.w $C80F,    0,    0,$FFF0; 12
		dc.w $E80F,    0,    0,$FFF0; 16
		dc.w  $80F,    0,    0,$FFF0; 20
word_1476C:	dc.w 7			; DATA XREF: ROM:000145EAo
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880F,    0,    0,$FFF0; 4
		dc.w $A80F,    0,    0,$FFF0; 8
		dc.w $C80F,    0,    0,$FFF0; 12
		dc.w $E80F,    0,    0,$FFF0; 16
		dc.w  $80F,    0,    0,$FFF0; 20
		dc.w $280D,  $2D,  $16,$FFF0; 24
word_147A6:	dc.w 7			; DATA XREF: ROM:000145ECo
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880F,    0,    0,$FFF0; 4
		dc.w $A80F,    0,    0,$FFF0; 8
		dc.w $C80F,    0,    0,$FFF0; 12
		dc.w $E80F,    0,    0,$FFF0; 16
		dc.w  $80F,    0,    0,$FFF0; 20
		dc.w $280F,    0,    0,$FFF0; 24
word_147E0:	dc.w 8			; DATA XREF: ROM:000145EEo
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880F,    0,    0,$FFF0; 4
		dc.w $A80F,    0,    0,$FFF0; 8
		dc.w $C80F,    0,    0,$FFF0; 12
		dc.w $E80F,    0,    0,$FFF0; 16
		dc.w  $80F,    0,    0,$FFF0; 20
		dc.w $280F,    0,    0,$FFF0; 24
		dc.w $480D,  $2D,  $16,$FFF0; 28
word_14822:	dc.w 8			; DATA XREF: ROM:000145F0o
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880F,    0,    0,$FFF0; 4
		dc.w $A80F,    0,    0,$FFF0; 8
		dc.w $C80F,    0,    0,$FFF0; 12
		dc.w $E80F,    0,    0,$FFF0; 16
		dc.w  $80F,    0,    0,$FFF0; 20
		dc.w $280F,    0,    0,$FFF0; 24
		dc.w $480F,    0,    0,$FFF0; 28
word_14864:	dc.w 9			; DATA XREF: ROM:000145F2o
		dc.w $800C,  $10,    8,$FFF0; 0
		dc.w $880F,    0,    0,$FFF0; 4
		dc.w $A80F,    0,    0,$FFF0; 8
		dc.w $C80F,    0,    0,$FFF0; 12
		dc.w $E80F,    0,    0,$FFF0; 16
		dc.w  $80F,    0,    0,$FFF0; 20
		dc.w $280F,    0,    0,$FFF0; 24
		dc.w $480F,    0,    0,$FFF0; 28
		dc.w $680D,  $2D,  $16,$FFF0; 32
word_148AE:	dc.w 2			; DATA XREF: ROM:000145F4o
					; ROM:000145F6o ...
		dc.w $F00A,  $18,   $C,$FFE8; 0
		dc.w $F00A, $818, $80C,	   0; 4
word_148C0:	dc.w 1			; DATA XREF: ROM:000145FCo
		dc.w $E00D,  $2D,  $16,$FFF0; 0
word_148CA:	dc.w 1			; DATA XREF: ROM:000145FEo
		dc.w $E00F,    0,    0,$FFF0; 0
word_148D4:	dc.w 2			; DATA XREF: ROM:00014600o
		dc.w $E00F,    0,    0,$FFF0; 0
		dc.w	$D,  $2D,  $16,$FFF0; 4
word_148E6:	dc.w 2			; DATA XREF: ROM:00014602o
		dc.w $E00F,    0,    0,$FFF0; 0
		dc.w	$F,    0,    0,$FFF0; 4
word_148F8:	dc.w 3			; DATA XREF: ROM:00014604o
		dc.w $E00F,    0,    0,$FFF0; 0
		dc.w	$F,    0,    0,$FFF0; 4
		dc.w $200D,  $2D,  $16,$FFF0; 8
word_14912:	dc.w 3			; DATA XREF: ROM:00014606o
		dc.w $E00F,    0,    0,$FFF0; 0
		dc.w	$F,    0,    0,$FFF0; 4
		dc.w $200F,    0,    0,$FFF0; 8
word_1492C:	dc.w 4			; DATA XREF: ROM:00014608o
		dc.w $E00F,    0,    0,$FFF0; 0
		dc.w	$F,    0,    0,$FFF0; 4
		dc.w $200F,    0,    0,$FFF0; 8
		dc.w $400D,  $2D,  $16,$FFF0; 12
word_1494E:	dc.w 4			; DATA XREF: ROM:0001460Ao
		dc.w $E00F,    0,    0,$FFF0; 0
		dc.w	$F,    0,    0,$FFF0; 4
		dc.w $200F,    0,    0,$FFF0; 8
		dc.w $400F,    0,    0,$FFF0; 12
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 06 - spiral loop in EHZ
;----------------------------------------------------

Obj06:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj06_Index(pc,d0.w),d1
		jsr	Obj06_Index(pc,d1.w)
		tst.w	(f_2player).w
		beq.s	loc_14986
		rts
; ---------------------------------------------------------------------------

loc_14986:				; CODE XREF: ROM:00014982j
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.s	loc_1499A
		rts
; ---------------------------------------------------------------------------

loc_1499A:				; CODE XREF: ROM:00014996j
		jmp	DeleteObject
; ---------------------------------------------------------------------------
Obj06_Index:	dc.w Obj06_Init-Obj06_Index ; DATA XREF: ROM:Obj06_Indexo
					; ROM:000149A2o
		dc.w Obj06_Main-Obj06_Index
; ---------------------------------------------------------------------------

Obj06_Init:				; DATA XREF: ROM:Obj06_Indexo
		addq.b	#2,$24(a0)
		move.b	#$D0,$19(a0)

Obj06_Main:				; DATA XREF: ROM:000149A2o
		lea	(v_objspace).w,a1
		moveq	#3,d6
		bsr.s	sub_149BC
		lea	(v_objspace+$40).w,a1
		addq.b	#1,d6

; =============== S U B	R O U T	I N E =======================================


sub_149BC:				; CODE XREF: ROM:000149B4p
		btst	d6,$22(a0)
		bne.w	loc_14A56
		btst	#1,$22(a1)
		bne.w	locret_14A54
		btst	#3,$22(a1)
		bne.s	loc_14A16
		move.w	8(a1),d0
		sub.w	8(a0),d0
		tst.w	$10(a1)
		bmi.s	loc_149F2
		cmpi.w	#$FF40,d0
		bgt.s	locret_14A54
		cmpi.w	#$FF30,d0
		blt.s	locret_14A54
		bra.s	loc_149FE
; ---------------------------------------------------------------------------

loc_149F2:				; CODE XREF: sub_149BC+26j
		cmpi.w	#$C0,d0	
		blt.s	locret_14A54
		cmpi.w	#$D0,d0	; "?"
		bgt.s	locret_14A54

loc_149FE:				; CODE XREF: sub_149BC+34j
		move.w	$C(a1),d1
		sub.w	$C(a0),d1
		subi.w	#$10,d1
		cmpi.w	#$30,d1	
		bcc.s	locret_14A54
		bsr.w	sub_F8F8
		rts
; ---------------------------------------------------------------------------

loc_14A16:				; CODE XREF: sub_149BC+18j
		move.w	8(a1),d0
		sub.w	8(a0),d0
		tst.w	$10(a1)
		bmi.s	loc_14A32
		cmpi.w	#$FF50,d0
		bgt.s	locret_14A54
		cmpi.w	#$FF40,d0
		blt.s	locret_14A54
		bra.s	loc_14A3E
; ---------------------------------------------------------------------------

loc_14A32:				; CODE XREF: sub_149BC+66j
		cmpi.w	#$B0,d0	; "?"
		blt.s	locret_14A54
		cmpi.w	#$C0,d0	
		bgt.s	locret_14A54

loc_14A3E:				; CODE XREF: sub_149BC+74j
		move.w	$C(a1),d1
		sub.w	$C(a0),d1
		subi.w	#$10,d1
		cmpi.w	#$30,d1	
		bcc.s	locret_14A54
		bsr.w	sub_F8F8

locret_14A54:				; CODE XREF: sub_149BC+Ej
					; sub_149BC+2Cj ...
		rts
; ---------------------------------------------------------------------------

loc_14A56:				; CODE XREF: sub_149BC+4j
		move.w	$14(a1),d0
		bpl.s	loc_14A5E
		neg.w	d0

loc_14A5E:				; CODE XREF: sub_149BC+9Ej
		cmpi.w	#$600,d0
		bcs.s	loc_14A80
		btst	#1,$22(a1)
		bne.s	loc_14A80
		move.w	8(a1),d0
		sub.w	8(a0),d0
		addi.w	#$D0,d0	; "?"
		bmi.s	loc_14A80
		cmpi.w	#$1A0,d0
		bcs.s	loc_14A98

loc_14A80:				; CODE XREF: sub_149BC+A6j
					; sub_149BC+AEj ...
		bclr	#3,$22(a1)
		bclr	d6,$22(a0)
		move.b	#0,$2C(a1)
		move.b	#4,$2D(a1)
		rts
; ---------------------------------------------------------------------------

loc_14A98:				; CODE XREF: sub_149BC+C2j
		btst	#3,$22(a1)
		beq.s	locret_14A54
		move.b	Obj06_PlayerDeltaYArray(pc,d0.w),d1
		ext.w	d1
		move.w	$C(a0),d2
		add.w	d1,d2
		moveq	#0,d1
		move.b	$16(a1),d1
		subi.w	#$13,d1
		sub.w	d1,d2
		move.w	d2,$C(a1)
		lsr.w	#3,d0
		andi.w	#$3F,d0	
		move.b	Obj06_PlayerAngleArray(pc,d0.w),$27(a1)
		rts
; End of function sub_149BC

; ---------------------------------------------------------------------------
Obj06_PlayerAngleArray:dc.b   0,  0,  1,  1    ; 0
		dc.b $16,$16,$16,$16	; 4
		dc.b $2C,$2C,$2C,$2C	; 8
		dc.b $42,$42,$42,$42	; 12
		dc.b $58,$58,$58,$58	; 16
		dc.b $6E,$6E,$6E,$6E	; 20
		dc.b $84,$84,$84,$84	; 24
		dc.b $9A,$9A,$9A,$9A	; 28
		dc.b $B0,$B0,$B0,$B0	; 32
		dc.b $C6,$C6,$C6,$C6	; 36
		dc.b $DC,$DC,$DC,$DC	; 40
		dc.b $F2,$F2,$F2,$F2	; 44
		dc.b   1,  1,  0,  0	; 48
Obj06_PlayerDeltaYArray:dc.b  $20, $20,	$20, $20, $20, $20, $20, $20, $20, $20,	$20, $20, $20, $20, $20, $20; 0
		dc.b  $20, $20,	$20, $20, $20, $20, $20, $20, $20, $20,	$20, $20, $20, $20, $1F, $1F; 16
		dc.b  $1F, $1F,	$1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F,	$1F, $1F, $1F, $1E, $1E, $1E; 32
		dc.b  $1E, $1E,	$1E, $1E, $1E, $1E, $1D, $1D, $1D, $1D,	$1D, $1C, $1C, $1C, $1C, $1B; 48
		dc.b  $1B, $1B,	$1B, $1A, $1A, $1A, $19, $19, $19, $18,	$18, $18, $17, $17, $16, $16; 64
		dc.b  $15, $15,	$14, $14, $13, $12, $12, $11, $10, $10,	 $F,  $E,  $E,	$D,  $C,  $C; 80
		dc.b   $B,  $A,	 $A,   9,   8,	 8,   7,   6,	6,   5,	  4,   4,   3,	 2,   2,   1; 96
		dc.b	0,  -1,	 -2,  -2,  -3,	-4,  -4,  -5,  -6,  -7,	 -7,  -8,  -9,	-9, -$A, -$A; 112
		dc.b  -$B, -$B,	-$C, -$C, -$D, -$E, -$E, -$F, -$F,-$10,-$10,-$11,-$11,-$12,-$12,-$13; 128
		dc.b -$13,-$13,-$14,-$15,-$15,-$16,-$16,-$17,-$17,-$18,-$18,-$19,-$19,-$1A,-$1A,-$1B; 144
		dc.b -$1B,-$1C,-$1C,-$1C,-$1D,-$1D,-$1E,-$1E,-$1E,-$1F,-$1F,-$1F,-$20,-$20,-$20,-$21; 160
		dc.b -$21,-$21,-$21,-$22,-$22,-$22,-$23,-$23,-$23,-$23,-$23,-$23,-$23,-$23,-$24,-$24; 176
		dc.b -$24,-$24,-$24,-$24,-$24,-$24,-$24,-$25,-$25,-$25,-$25,-$25,-$25,-$25,-$25,-$25; 192
		dc.b -$25,-$25,-$25,-$25,-$25,-$25,-$25,-$25,-$25,-$25,-$25,-$25,-$25,-$25,-$25,-$25; 208
		dc.b -$25,-$25,-$25,-$25,-$24,-$24,-$24,-$24,-$24,-$24,-$24,-$23,-$23,-$23,-$23,-$23; 224
		dc.b -$23,-$23,-$23,-$22,-$22,-$22,-$21,-$21,-$21,-$21,-$20,-$20,-$20,-$1F,-$1F,-$1F; 240
		dc.b -$1E,-$1E,-$1E,-$1D,-$1D,-$1C,-$1C,-$1C,-$1B,-$1B,-$1A,-$1A,-$19,-$19,-$18,-$18; 256
		dc.b -$17,-$17,-$16,-$16,-$15,-$15,-$14,-$13,-$13,-$12,-$12,-$11,-$10,-$10, -$F, -$E; 272
		dc.b  -$E, -$D,	-$C, -$B, -$B, -$A,  -9,  -8,  -7,  -7,	 -6,  -5,  -4,	-3,  -2,  -1; 288
		dc.b	0,   1,	  2,   3,   4,	 5,   6,   7,	8,   8,	  9,  $A,  $A,	$B,  $C,  $D; 304
		dc.b   $D,  $E,	 $E,  $F,  $F, $10, $10, $11, $11, $12,	$12, $13, $13, $14, $14, $15; 320
		dc.b  $15, $16,	$16, $17, $17, $18, $18, $18, $19, $19,	$19, $19, $1A, $1A, $1A, $1A; 336
		dc.b  $1B, $1B,	$1B, $1B, $1C, $1C, $1C, $1C, $1C, $1C,	$1D, $1D, $1D, $1D, $1D, $1D; 352
		dc.b  $1D, $1E,	$1E, $1E, $1E, $1E, $1E, $1E, $1F, $1F,	$1F, $1F, $1F, $1F, $1F, $1F; 368
		dc.b  $1F, $1F,	$20, $20, $20, $20, $20, $20, $20, $20,	$20, $20, $20, $20, $20, $20; 384
		dc.b  $20, $20,	$20, $20, $20, $20, $20, $20, $20, $20,	$20, $20, $20, $20, $20, $20; 400
; ---------------------------------------------------------------------------
		nop
;----------------------------------------------------
; Object 14 - HTZ see-saw
;----------------------------------------------------

Obj14:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj14_Index(pc,d0.w),d1
		jsr	Obj14_Index(pc,d1.w)
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite
; ---------------------------------------------------------------------------
Obj14_Index:	dc.w loc_14CD2-Obj14_Index ; DATA XREF:	ROM:Obj14_Indexo
					; ROM:00014CC8o ...
		dc.w loc_14D40-Obj14_Index
		dc.w locret_14DF2-Obj14_Index
		dc.w loc_14E3C-Obj14_Index
		dc.w loc_14E9C-Obj14_Index
		dc.w loc_14F30-Obj14_Index
; ---------------------------------------------------------------------------

loc_14CD2:				; DATA XREF: ROM:Obj14_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj14,4(a0)
		move.w	#$3CE,2(a0)
		bsr.w	ModifySpriteAttr_2P
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$30,$19(a0) 
		move.w	8(a0),$30(a0)
		tst.b	$28(a0)
		bne.s	loc_14D2C
		bsr.w	S1SingleObjectLoad2
		bne.s	loc_14D2C
		move.b	#$14,0(a1)
		addq.b	#6,$24(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	$22(a0),$22(a1)
		move.l	a0,$3C(a1)

loc_14D2C:				; CODE XREF: ROM:00014D04j
					; ROM:00014D0Aj
		btst	#0,$22(a0)
		beq.s	loc_14D3A
		move.b	#2,$1A(a0)

loc_14D3A:				; CODE XREF: ROM:00014D32j
		move.b	$1A(a0),$3A(a0)

loc_14D40:				; DATA XREF: ROM:00014CC8o
		move.b	$3A(a0),d1
		btst	#3,$22(a0)
		beq.s	loc_14D9A
		moveq	#2,d1
		lea	(v_objspace).w,a1
		move.w	8(a0),d0
		sub.w	8(a1),d0
		bcc.s	loc_14D60
		neg.w	d0
		moveq	#0,d1

loc_14D60:				; CODE XREF: ROM:00014D5Aj
		cmpi.w	#8,d0
		bcc.s	loc_14D68
		moveq	#1,d1

loc_14D68:				; CODE XREF: ROM:00014D64j
		btst	#4,$22(a0)
		beq.s	loc_14DBE
		moveq	#2,d2
		lea	(v_objspace+$40).w,a1
		move.w	8(a0),d0
		sub.w	8(a1),d0
		bcc.s	loc_14D84
		neg.w	d0
		moveq	#0,d2

loc_14D84:				; CODE XREF: ROM:00014D7Ej
		cmpi.w	#8,d0
		bcc.s	loc_14D8C
		moveq	#1,d2

loc_14D8C:				; CODE XREF: ROM:00014D88j
		add.w	d2,d1
		cmpi.w	#3,d1
		bne.s	loc_14D96
		addq.w	#1,d1

loc_14D96:				; CODE XREF: ROM:00014D92j
		lsr.w	#1,d1
		bra.s	loc_14DBE
; ---------------------------------------------------------------------------

loc_14D9A:				; CODE XREF: ROM:00014D4Aj
		btst	#4,$22(a0)
		beq.s	loc_14DBE
		moveq	#2,d1
		lea	(v_objspace+$40).w,a1
		move.w	8(a0),d0
		sub.w	8(a1),d0
		bcc.s	loc_14DB6
		neg.w	d0
		moveq	#0,d1

loc_14DB6:				; CODE XREF: ROM:00014DB0j
		cmpi.w	#8,d0
		bcc.s	loc_14DBE
		moveq	#1,d1

loc_14DBE:				; CODE XREF: ROM:00014D6Ej
					; ROM:00014D98j ...
		bsr.w	sub_14E10
		lea	(byte_14FFE).l,a2
		btst	#0,$1A(a0)
		beq.s	loc_14DD6
		lea	(byte_1502F).l,a2

loc_14DD6:				; CODE XREF: ROM:00014DCEj
		lea	(v_objspace).w,a1
		move.w	$12(a1),$38(a0)
		move.w	8(a0),-(sp)
		moveq	#0,d1
		move.b	$19(a0),d1
		moveq	#8,d3
		move.w	(sp)+,d4
		bra.w	sub_F7DC
; ---------------------------------------------------------------------------

locret_14DF2:				; DATA XREF: ROM:00014CCAo
		rts
; ---------------------------------------------------------------------------
		moveq	#2,d1
		lea	(v_objspace).w,a1
		move.w	8(a0),d0
		sub.w	8(a1),d0
		bcc.s	loc_14E08
		neg.w	d0
		moveq	#0,d1

loc_14E08:				; CODE XREF: ROM:00014E02j
		cmpi.w	#8,d0
		bcc.s	sub_14E10
		moveq	#1,d1

; =============== S U B	R O U T	I N E =======================================


sub_14E10:				; CODE XREF: ROM:loc_14DBEp
					; ROM:00014E0Cj
		move.b	$1A(a0),d0
		cmp.b	d1,d0
		beq.s	locret_14E3A
		bcc.s	loc_14E1C
		addq.b	#2,d0

loc_14E1C:				; CODE XREF: sub_14E10+8j
		subq.b	#1,d0
		move.b	d0,$1A(a0)
		move.b	d1,$3A(a0)
		bclr	#0,1(a0)
		btst	#1,$1A(a0)
		beq.s	locret_14E3A
		bset	#0,1(a0)

locret_14E3A:				; CODE XREF: sub_14E10+6j
					; sub_14E10+22j
		rts
; End of function sub_14E10

; ---------------------------------------------------------------------------

loc_14E3C:				; DATA XREF: ROM:00014CCCo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj14b,4(a0)
		move.w	#$3CE,2(a0)
		bsr.w	ModifySpriteAttr_2P
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$8B,$20(a0)
		move.b	#$C,$19(a0)
		move.w	8(a0),$30(a0)
		addi.w	#$28,8(a0) 
		addi.w	#$10,$C(a0)
		move.w	$C(a0),$34(a0)
		move.b	#1,$1A(a0)
		btst	#0,$22(a0)
		beq.s	loc_14E9C
		subi.w	#$50,8(a0) 
		move.b	#2,$3A(a0)

loc_14E9C:				; CODE XREF: ROM:00014E8Ej
					; DATA XREF: ROM:00014CCEo
		movea.l	$3C(a0),a1
		moveq	#0,d0
		move.b	$3A(a0),d0
		sub.b	$3A(a1),d0
		beq.s	loc_14EF2
		bcc.s	loc_14EB0
		neg.b	d0

loc_14EB0:				; CODE XREF: ROM:00014EACj
		move.w	#$F7E8,d1
		move.w	#$FEEC,d2
		cmpi.b	#1,d0
		beq.s	loc_14ED6
		move.w	#$F510,d1
		move.w	#$FF34,d2
		cmpi.w	#$A00,$38(a1)
		blt.s	loc_14ED6
		move.w	#$F200,d1
		move.w	#$FF60,d2

loc_14ED6:				; CODE XREF: ROM:00014EBCj
					; ROM:00014ECCj
		move.w	d1,$12(a0)
		move.w	d2,$10(a0)
		move.w	8(a0),d0
		sub.w	$30(a0),d0
		bcc.s	loc_14EEC
		neg.w	$10(a0)

loc_14EEC:				; CODE XREF: ROM:00014EE6j
		addq.b	#2,$24(a0)
		bra.s	loc_14F30
; ---------------------------------------------------------------------------

loc_14EF2:				; CODE XREF: ROM:00014EAAj
		lea	(word_14FF4).l,a2
		moveq	#0,d0
		move.b	$1A(a1),d0
		move.w	#$28,d2	
		move.w	8(a0),d1
		sub.w	$30(a0),d1
		bcc.s	loc_14F10
		neg.w	d2
		addq.w	#2,d0

loc_14F10:				; CODE XREF: ROM:00014F0Aj
		add.w	d0,d0
		move.w	$34(a0),d1
		add.w	(a2,d0.w),d1
		move.w	d1,$C(a0)
		add.w	$30(a0),d2
		move.w	d2,8(a0)
		clr.w	$E(a0)
		clr.w	$A(a0)
		rts
; ---------------------------------------------------------------------------

loc_14F30:				; CODE XREF: ROM:00014EF0j
					; DATA XREF: ROM:00014CD0o
		tst.w	$12(a0)
		bpl.s	loc_14F4E
	if removeJmpTos=1
                jsr	(ObjectFall).l
        else
                bsr.w	j_ObjectFall
        endif
		move.w	$34(a0),d0
		subi.w	#$2F,d0	; "/"
		cmp.w	$C(a0),d0
		bgt.s	locret_14F4C
	if removeJmpTos=1
                jsr	(ObjectFall).l
        else
                bsr.w	j_ObjectFall
        endif

locret_14F4C:				; CODE XREF: ROM:00014F46j
		rts
; ---------------------------------------------------------------------------

loc_14F4E:				; CODE XREF: ROM:00014F34j
	if removeJmpTos=1
                jsr	(ObjectFall).l
        else
                bsr.w	j_ObjectFall
        endif
		movea.l	$3C(a0),a1
		lea	(word_14FF4).l,a2
		moveq	#0,d0
		move.b	$1A(a1),d0
		move.w	8(a0),d1
		sub.w	$30(a0),d1
		bcc.s	loc_14F6E
		addq.w	#2,d0

loc_14F6E:				; CODE XREF: ROM:00014F6Aj
		add.w	d0,d0
		move.w	$34(a0),d1
		add.w	(a2,d0.w),d1
		cmp.w	$C(a0),d1
		bgt.s	locret_14FC2
		movea.l	$3C(a0),a1
		moveq	#2,d1
		tst.w	$10(a0)
		bmi.s	loc_14F8C
		moveq	#0,d1

loc_14F8C:				; CODE XREF: ROM:00014F88j
		move.b	d1,$3A(a1)
		move.b	d1,$3A(a0)
		cmp.b	$1A(a1),d1
		beq.s	loc_14FB6
		lea	(v_objspace).w,a2
		bclr	#3,$22(a1)
		beq.s	loc_14FA8
		bsr.s	sub_14FC4

loc_14FA8:				; CODE XREF: ROM:00014FA4j
		lea	(v_objspace+$40).w,a2
		bclr	#4,$22(a1)
		beq.s	loc_14FB6
		bsr.s	sub_14FC4

loc_14FB6:				; CODE XREF: ROM:00014F98j
					; ROM:00014FB2j
		clr.w	$10(a0)
		clr.w	$12(a0)
		subq.b	#2,$24(a0)

locret_14FC2:				; CODE XREF: ROM:00014F7Cj
		rts

; =============== S U B	R O U T	I N E =======================================


sub_14FC4:				; CODE XREF: ROM:00014FA6p
					; ROM:00014FB4p
		move.w	$12(a0),$12(a2)
		neg.w	$12(a2)
		bset	#1,$22(a2)
		bclr	#3,$22(a2)
		clr.b	$3C(a2)
		move.b	#$10,$1C(a2)
		move.b	#2,$24(a2)
		move.w	#$CC,d0	; "?"
		jmp	(PlaySound_Special).l
; End of function sub_14FC4

; ---------------------------------------------------------------------------
word_14FF4:	dc.w	 -8,  -$1C,  -$2F,  -$1C,    -8; 0 ; DATA XREF:	ROM:loc_14EF2o
					; ROM:00014F56o
byte_14FFE:	dc.b  $14, $14,	$16, $18, $1A, $1C, $1A; 0 ; DATA XREF:	ROM:00014DC2o
		dc.b  $18, $16,	$14, $13, $12, $11, $10; 7
		dc.b   $F,  $E,	 $D,  $C,  $B,	$A,   9; 14
		dc.b	8,   7,	  6,   5,   4,	 3,   2; 21
		dc.b	1,   0,	 -1,  -2,  -3,	-4,  -5; 28
		dc.b   -6,  -7,	 -8,  -9, -$A, -$B, -$C; 35
		dc.b  -$D, -$E,	-$E, -$E, -$E, -$E, -$E; 42
byte_1502F:	dc.b	5,   5,	  5,   5,   5,	 5,   5; 0 ; DATA XREF:	ROM:00014DD0o
		dc.b	5,   5,	  5,   5,   5,	 5,   5; 7
		dc.b	5,   5,	  5,   5,   5,	 5,   5; 14
		dc.b	5,   5,	  5,   5,   5,	 5,   5; 21
		dc.b	5,   5,	  5,   5,   5,	 5,   5; 28
		dc.b	5,   5,	  5,   5,   5,	 5,   5; 35
		dc.b	5,   5,	  5,   5,   5,	 5,   0; 42
Map_Obj14:	dc.w word_15068-Map_Obj14 ; DATA XREF: ROM:00014CD6o
					; ROM:Map_Obj14o ...
		dc.w word_150AA-Map_Obj14
		dc.w word_15068-Map_Obj14
		dc.w word_150AA-Map_Obj14
word_15068:	dc.w 8			; DATA XREF: ROM:Map_Obj14o
					; ROM:00015064o
		dc.w $FC05,$4014,$400A,$FFF8; 0
		dc.w  $C01,$2012,$2009,$FFFC; 4
		dc.w $E405,$4006,$4003,$FFD0; 8
		dc.w $EC05,$400A,$4005,$FFE0; 12
		dc.w $F405,$400A,$4005,$FFF0; 16
		dc.w $FC05,$400A,$4005,	   0; 20
		dc.w  $405,$400A,$4005,	 $10; 24
		dc.w  $C05,$400E,$4007,	 $20; 28
word_150AA:	dc.w 8			; DATA XREF: ROM:00015062o
					; ROM:00015066o
word_150AC:	dc.w $FC05,$4014,$400A,$FFF8; 0
		dc.w  $C01,$2012,$2009,$FFFC; 4
		dc.w $F405,$4000,$4000,$FFD0; 8
		dc.w $F405,$4002,$4001,$FFE0; 12
		dc.w $F405,$4002,$4001,$FFF0; 16
		dc.w $F405,$4002,$4001,	   0; 20
		dc.w $F405,$4002,$4001,	 $10; 24
		dc.w $F405,$4800,$4800,	 $20; 28
Map_Obj14b:	dc.w word_150F0-Map_Obj14b ; DATA XREF:	ROM:00014E40o
					; ROM:Map_Obj14bo ...
		dc.w word_150F0-Map_Obj14b
word_150F0:	dc.w 1			; DATA XREF: ROM:Map_Obj14bo
					; ROM:000150EEo
		dc.w $F805,$4014,$400A,$FFF8; 0
; ---------------------------------------------------------------------------
		nop

        if removeJmpTos=0
j_ObjectFall:				; CODE XREF: ROM:00014F36p
					; ROM:00014F48p ...
		jmp	(ObjectFall).l

		align 4
	endif
;----------------------------------------------------
; Object 16 - the HTZ platform that goes down diagonally
;	      and stops	after a	while (in final, it falls)
;----------------------------------------------------

Obj16:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0

loc_15106:
		move.b	$24(a0),d0
		move.w	Obj16_Index(pc,d0.w),d1
		jmp	Obj16_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj16_Index:	dc.w Obj16_Init-Obj16_Index ; DATA XREF: ROM:Obj16_Indexo
					; ROM:00015114o
		dc.w Obj16_Main-Obj16_Index
; ---------------------------------------------------------------------------

Obj16_Init:				; DATA XREF: ROM:Obj16_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj16,4(a0)
		move.w	#$43E6,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#$20,$19(a0) 
		move.b	#0,$1A(a0)
		move.b	#1,$18(a0)
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$32(a0)

Obj16_Main:				; DATA XREF: ROM:00015114o
		move.w	8(a0),-(sp)
		bsr.w	sub_15184
		moveq	#0,d1
		move.b	$19(a0),d1
		move.w	#$FFD8,d3
		move.w	(sp)+,d4
		bsr.w	sub_F78A
		move.w	$30(a0),d0
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	loc_152AA
		bra.w	loc_152A4

; =============== S U B	R O U T	I N E =======================================


sub_15184:				; CODE XREF: ROM:00015154p
		moveq	#0,d0
		move.b	$28(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	Obj16_SubIndex(pc,d0.w),d1
		jmp	Obj16_SubIndex(pc,d1.w)
; End of function sub_15184

; ---------------------------------------------------------------------------
Obj16_SubIndex:	dc.w Obj16_InitMove-Obj16_SubIndex ; DATA XREF:	ROM:Obj16_SubIndexo
					; ROM:0001519Ao ...
		dc.w Obj16_Move-Obj16_SubIndex
		dc.w Obj16_NoMove-Obj16_SubIndex
; ---------------------------------------------------------------------------

Obj16_InitMove:				; DATA XREF: ROM:Obj16_SubIndexo
		move.b	$22(a0),d0
		andi.b	#$18,d0
		beq.s	locret_151BE
		addq.b	#1,$28(a0)
		move.w	#$200,$10(a0)
		move.w	#$100,$12(a0)
		move.w	#$A0,$34(a0) 

locret_151BE:				; CODE XREF: ROM:000151A6j
		rts
; ---------------------------------------------------------------------------

Obj16_Move:				; DATA XREF: ROM:0001519Ao
	if removeJmpTos=1
                jsr	(SpeedToPos).l
        else
                bsr.w	j_SpeedToPos_0
        endif
		subq.w	#1,$34(a0)
		bne.s	locret_151CE
		addq.b	#1,$28(a0)

locret_151CE:				; CODE XREF: ROM:000151C8j
		rts
; ---------------------------------------------------------------------------

Obj16_NoMove:				; DATA XREF: ROM:0001519Co
		rts
; ---------------------------------------------------------------------------
Map_Obj16:	dc.w word_151DA-Map_Obj16 ; DATA XREF: ROM:000093E0o
					; ROM:000093EAo ...
		dc.w word_1522C-Map_Obj16
		dc.w word_15246-Map_Obj16
		dc.w word_15260-Map_Obj16
word_151DA:	dc.w $A			; DATA XREF: ROM:Map_Obj16o
		dc.w $C105,    0,    0,$FFE4; 0
		dc.w $D003,    4,    2,$FFE6; 4
		dc.w $F003,    4,    2,$FFE6; 8
		dc.w $1001,    8,    4,$FFE7; 12
		dc.w $D505,   $A,    5,	  $C; 16
		dc.w $E003,   $E,    7,	 $11; 20
		dc.w $1001,  $12,    9,	 $11; 24
		dc.w	 3,   $E,    7,	 $11; 28
		dc.w $200D,  $14,   $A,$FFE0; 32
		dc.w $200D, $814, $80A,	   0; 36
word_1522C:	dc.w 3			; DATA XREF: ROM:000151D4o
		dc.w $D805,  $1C,   $E,$FFF8; 0
		dc.w $E807,  $20,  $10,$FFF8; 4
		dc.w  $807,  $20,  $10,$FFF8; 8
word_15246:	dc.w 3			; DATA XREF: ROM:000151D6o
		dc.w $D805,  $28,  $14,$FFF8; 0
		dc.w $E807, $820, $810,$FFF8; 4
		dc.w  $807, $820, $810,$FFF8; 8
word_15260:	dc.w 8			; DATA XREF: ROM:000151D8o
		dc.w $C905,    0,    0,$FFE4; 0
		dc.w $D803,    4,    2,$FFE6; 4
		dc.w $F803,    4,    2,$FFE6; 8
		dc.w $1801,  $2C,  $16,$FFE6; 12
		dc.w $DD05,   $A,    5,	  $C; 16
		dc.w $E803,   $E,    7,	 $11; 20
		dc.w $2001,  $2E,  $17,	 $11; 24
		dc.w  $803,   $E,    7,	 $11; 28
; ---------------------------------------------------------------------------
		nop

loc_152A4:				; CODE XREF: ROM:00015180j
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_152AA:				; CODE XREF: ROM:0001517Cj
		jmp	DeleteObject
; ---------------------------------------------------------------------------

        if removeJmpTos=0
j_SpeedToPos_0:				; CODE XREF: ROM:Obj16_Movep
		jmp	SpeedToPos

		align 4
	endif
;----------------------------------------------------
; Object 19 - CPZ platforms moving side	to side
;----------------------------------------------------

Obj19:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj19_Index(pc,d0.w),d1
		jmp	Obj19_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj19_Index:	dc.w Obj19_Init-Obj19_Index ; DATA XREF: ROM:Obj19_Indexo
					; ROM:000152C8o
		dc.w Obj19_Main-Obj19_Index
Obj19_WidthArray:dc.w $2000		 ; 0
		dc.w $2001		; 1
		dc.w $2002		; 2
		dc.w $4003		; 3
		dc.w $3004		; 4
; ---------------------------------------------------------------------------

Obj19_Init:				; DATA XREF: ROM:Obj19_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj19,4(a0)
		move.w	#$6400,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		moveq	#0,d0
		move.b	$28(a0),d0
		lsr.w	#3,d0
		andi.w	#$1E,d0
		lea	Obj19_WidthArray(pc,d0.w),a2
		move.b	(a2)+,$19(a0)
		move.b	(a2)+,$1A(a0)
		move.b	#4,$18(a0)
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$32(a0)
		andi.b	#$F,$28(a0)

Obj19_Main:				; DATA XREF: ROM:000152C8o
		move.w	8(a0),-(sp)
		bsr.w	Obj19_Modes
		moveq	#0,d1
		move.b	$19(a0),d1
		move.w	#$10,d3
		move.w	(sp)+,d4
		bsr.w	sub_F78A
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	loc_154C6
		bra.w	loc_154C0

; =============== S U B	R O U T	I N E =======================================


Obj19_Modes:				; CODE XREF: ROM:00015324p
		moveq	#0,d0
		move.b	$28(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	Obj19_SubIndex(pc,d0.w),d1
		jmp	Obj19_SubIndex(pc,d1.w)
; End of function Obj19_Modes

; ---------------------------------------------------------------------------
Obj19_SubIndex:	dc.w locret_1537A-Obj19_SubIndex ; DATA	XREF: ROM:Obj19_SubIndexo
					; ROM:00015366o ...
		dc.w loc_1537C-Obj19_SubIndex
		dc.w loc_1539C-Obj19_SubIndex
		dc.w loc_153AC-Obj19_SubIndex
		dc.w loc_1539C-Obj19_SubIndex
		dc.w loc_153CC-Obj19_SubIndex
		dc.w loc_153EC-Obj19_SubIndex
		dc.w loc_1540E-Obj19_SubIndex
		dc.w loc_15430-Obj19_SubIndex
		dc.w loc_1539C-Obj19_SubIndex
		dc.w loc_15450-Obj19_SubIndex
; ---------------------------------------------------------------------------

locret_1537A:				; DATA XREF: ROM:Obj19_SubIndexo
		rts
; ---------------------------------------------------------------------------

loc_1537C:				; DATA XREF: ROM:00015366o
		move.b	($FFFFFE6C).w,d0
		move.w	#$60,d1	
		btst	#0,$22(a0)
		beq.s	loc_15390
		neg.w	d0
		add.w	d1,d0

loc_15390:				; CODE XREF: ROM:0001538Aj
		move.w	$30(a0),d1
		sub.w	d0,d1
		move.w	d1,8(a0)
		rts
; ---------------------------------------------------------------------------

loc_1539C:				; DATA XREF: ROM:00015368o
					; ROM:0001536Co ...
		move.b	$22(a0),d0
		andi.b	#$18,d0
		beq.s	locret_153AA
		addq.b	#1,$28(a0)

locret_153AA:				; CODE XREF: ROM:000153A4j
		rts
; ---------------------------------------------------------------------------

loc_153AC:				; DATA XREF: ROM:0001536Ao
		moveq	#0,d3
		move.b	$19(a0),d3
		bsr.w	ObjHitWallRight
		tst.w	d1
		bmi.s	loc_153C6
		addq.w	#1,8(a0)
		move.w	8(a0),$30(a0)
		rts
; ---------------------------------------------------------------------------

loc_153C6:				; CODE XREF: ROM:000153B8j
		clr.b	$28(a0)
		rts
; ---------------------------------------------------------------------------

loc_153CC:				; DATA XREF: ROM:0001536Eo
		moveq	#0,d3
		move.b	$19(a0),d3
		bsr.w	ObjHitWallRight
		tst.w	d1
		bmi.s	loc_153E6
		addq.w	#1,8(a0)
		move.w	8(a0),$30(a0)
		rts
; ---------------------------------------------------------------------------

loc_153E6:				; CODE XREF: ROM:000153D8j
		addq.b	#1,$28(a0)
		rts
; ---------------------------------------------------------------------------

loc_153EC:				; DATA XREF: ROM:00015370o
	if removeJmpTos=1
                jsr	(SpeedToPos).l
        else
                bsr.w	j_SpeedToPos_1
        endif
		addi.w	#$18,$12(a0)
		bsr.w	ObjHitFloor
		tst.w	d1
		bpl.w	locret_1540C
		add.w	d1,$C(a0)
		clr.w	$12(a0)
		clr.b	$28(a0)

locret_1540C:				; CODE XREF: ROM:000153FCj
		rts
; ---------------------------------------------------------------------------

loc_1540E:				; DATA XREF: ROM:00015372o
		tst.b	($FFFFF7E2).w
		beq.s	loc_15418
		subq.b	#3,$28(a0)

loc_15418:				; CODE XREF: ROM:00015412j
		addq.l	#6,sp
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	loc_154C6
		rts
; ---------------------------------------------------------------------------

loc_15430:				; DATA XREF: ROM:00015374o
		move.b	($FFFFFE7C).w,d0
		move.w	#$80,d1	
		btst	#0,$22(a0)
		beq.s	loc_15444
		neg.w	d0
		add.w	d1,d0

loc_15444:				; CODE XREF: ROM:0001543Ej
		move.w	$32(a0),d1
		sub.w	d0,d1
		move.w	d1,$C(a0)
		rts
; ---------------------------------------------------------------------------

loc_15450:				; DATA XREF: ROM:00015378o
		moveq	#0,d3
		move.b	$19(a0),d3
		add.w	d3,d3
		moveq	#8,d1
		btst	#0,$22(a0)
		beq.s	loc_15466
		neg.w	d1
		neg.w	d3

loc_15466:				; CODE XREF: ROM:00015460j
		tst.w	$36(a0)
		bne.s	loc_15492
		move.w	8(a0),d0
		sub.w	$30(a0),d0
		cmp.w	d3,d0
		beq.s	loc_15484
		add.w	d1,8(a0)
		move.w	#$12C,$34(a0)
		rts
; ---------------------------------------------------------------------------

loc_15484:				; CODE XREF: ROM:00015476j
		subq.w	#1,$34(a0)
		bne.s	locret_15490
		move.w	#1,$36(a0)

locret_15490:				; CODE XREF: ROM:00015488j
		rts
; ---------------------------------------------------------------------------

loc_15492:				; CODE XREF: ROM:0001546Aj
		move.w	8(a0),d0
		sub.w	$30(a0),d0
		beq.s	loc_154A2
		sub.w	d1,8(a0)
		rts
; ---------------------------------------------------------------------------

loc_154A2:				; CODE XREF: ROM:0001549Aj
		clr.w	$36(a0)
		subq.b	#1,$28(a0)
		rts
; ---------------------------------------------------------------------------
Map_Obj19:	dc.w word_154AE-Map_Obj19 ; DATA XREF: ROM:000152D8o
					; ROM:Map_Obj19o ...
word_154AE:	dc.w 2			; DATA XREF: ROM:Map_Obj19o
		dc.w $F00F,    0,    0,$FFE0; 0
		dc.w $F00F, $800, $800,	   0; 4
; ---------------------------------------------------------------------------

loc_154C0:				; CODE XREF: ROM:0001534Cj
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_154C6:				; CODE XREF: ROM:00015348j
					; ROM:0001542Aj
		jmp	DeleteObject
; ---------------------------------------------------------------------------

        if removeJmpTos=0
j_SpeedToPos_1:				; CODE XREF: ROM:loc_153ECp
		jmp	SpeedToPos

		align 4
	endif
;----------------------------------------------------
; Object 04 - water surface
;----------------------------------------------------

Obj04:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj04_Index(pc,d0.w),d1
		jmp	Obj04_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj04_Index:	dc.w Obj04_Init-Obj04_Index ; DATA XREF: ROM:Obj04_Indexo
					; ROM:000154E4o
		dc.w Obj04_Main-Obj04_Index
; ---------------------------------------------------------------------------

Obj04_Init:				; DATA XREF: ROM:Obj04_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj04,4(a0)
		move.w	#$8400,2(a0)
	if removeJmpTos=1
		jsr	(ModifySpriteAttr_2P).l
	else
		bsr.w	j_ModifySpriteAttr_2P_0
	endif
		move.b	#4,1(a0)
		move.b	#$80,$19(a0)
		move.w	8(a0),$30(a0)

Obj04_Main:				; DATA XREF: ROM:000154E4o
		move.w	($FFFFF646).w,d1
		move.w	d1,$C(a0)
		tst.b	$32(a0)
		bne.s	loc_15530
		btst	#7,(v_jpadpress1).w
		beq.s	loc_15540
		addq.b	#3,$1A(a0)
		move.b	#1,$32(a0)
		bra.s	loc_15540
; ---------------------------------------------------------------------------

loc_15530:				; CODE XREF: ROM:0001551Aj
		tst.w	($FFFFF63A).w
		bne.s	loc_15540
		move.b	#0,$32(a0)
		subq.b	#3,$1A(a0)

loc_15540:				; CODE XREF: ROM:00015522j
					; ROM:0001552Ej ...
		lea	(Obj04_FrameData).l,a1
		moveq	#0,d1
		move.b	$1B(a0),d1
		move.b	(a1,d1.w),$1A(a0)
		addq.b	#1,$1B(a0)
		andi.b	#$3F,$1B(a0)
		bra.w	loc_15868
; ---------------------------------------------------------------------------
Obj04_FrameData:dc.b   0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1; 0
					; DATA XREF: ROM:loc_15540o
		dc.b   1,  2,  1,  2,  1,  2,  1,  2,  1,  2,  1,  2,  1,  2,  1,  2; 16
		dc.b   2,  1,  2,  1,  2,  1,  2,  1,  2,  1,  2,  1,  2,  1,  2,  1; 32
		dc.b   1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0,  1,  0; 48
Map_Obj04:	dc.w word_155AC-Map_Obj04 ; DATA XREF: ROM:000154EAo
					; ROM:Map_Obj04o ...
		dc.w word_155C6-Map_Obj04
		dc.w word_155E0-Map_Obj04
		dc.w word_155FA-Map_Obj04
		dc.w word_1562C-Map_Obj04
		dc.w word_1565E-Map_Obj04
word_155AC:	dc.w 3			; DATA XREF: ROM:Map_Obj04o
		dc.w $F80D,    0,    0,$FFA0; 0
		dc.w $F80D,    0,    0,$FFE0; 4
		dc.w $F80D,    0,    0,	 $20; 8
word_155C6:	dc.w 3			; DATA XREF: ROM:000155A2o
		dc.w $F80D,    8,    4,$FFA0; 0
		dc.w $F80D,    8,    4,$FFE0; 4
		dc.w $F80D,    8,    4,	 $20; 8
word_155E0:	dc.w 3			; DATA XREF: ROM:000155A4o
		dc.w $F80D,  $10,    8,$FFA0; 0
		dc.w $F80D,  $10,    8,$FFE0; 4
		dc.w $F80D,  $10,    8,	 $20; 8
word_155FA:	dc.w 6			; DATA XREF: ROM:000155A6o
		dc.w $F80D,    0,    0,$FFA0; 0
		dc.w $F80D,    8,    4,$FFC0; 4
		dc.w $F80D,    0,    0,$FFE0; 8
		dc.w $F80D,    8,    4,	   0; 12
		dc.w $F80D,    0,    0,	 $20; 16
		dc.w $F80D,    8,    4,	 $40; 20
word_1562C:	dc.w 6			; DATA XREF: ROM:000155A8o
		dc.w $F80D,    8,    4,$FFA0; 0
		dc.w $F80D,  $10,    8,$FFC0; 4
		dc.w $F80D,    8,    4,$FFE0; 8
		dc.w $F80D,  $10,    8,	   0; 12
		dc.w $F80D,    8,    4,	 $20; 16
		dc.w $F80D,  $10,    8,	 $40; 20
word_1565E:	dc.w 6			; DATA XREF: ROM:000155AAo
		dc.w $F80D,  $10,    8,$FFA0; 0
		dc.w $F80D,    8,    4,$FFC0; 4
		dc.w $F80D,  $10,    8,$FFE0; 8
		dc.w $F80D,    8,    4,	   0; 12
		dc.w $F80D,  $10,    8,	 $20; 16
		dc.w $F80D,    8,    4,	 $40; 20
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 49 - EHZ waterfalls
;----------------------------------------------------

Obj49:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj49_Index(pc,d0.w),d1
		jmp	Obj49_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj49_Index:	dc.w Obj49_Init-Obj49_Index ; DATA XREF: ROM:Obj49_Indexo
					; ROM:000156A0o
		dc.w Obj49_Main-Obj49_Index
; ---------------------------------------------------------------------------

Obj49_Init:				; DATA XREF: ROM:Obj49_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj49,4(a0)
		move.w	#$23AE,2(a0)
	if removeJmpTos=1
		jsr	(ModifySpriteAttr_2P).l
	else
		bsr.w	j_ModifySpriteAttr_2P_0
	endif
		move.b	#4,1(a0)
		move.b	#$20,$19(a0)
		move.w	8(a0),$30(a0)
		move.b	#0,$18(a0)
		move.b	#$80,$16(a0)
		bset	#4,1(a0)

Obj49_Main:				; DATA XREF: ROM:000156A0o
		tst.w	(f_2player).w
		bne.s	loc_156F6
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	loc_1586E

loc_156F6:				; CODE XREF: ROM:000156E0j
		move.w	8(a0),d1
		move.w	d1,d2
		subi.w	#$40,d1
		addi.w	#$40,d2
		move.b	$28(a0),d3
		move.b	#0,$1A(a0)
		move.w	(v_objspace+8).w,d0
		cmp.w	d1,d0
		bcs.s	loc_15728
		cmp.w	d2,d0
		bcc.s	loc_15728
		move.b	#1,$1A(a0)
		add.b	d3,$1A(a0)
		bra.w	loc_15868
; ---------------------------------------------------------------------------

loc_15728:				; CODE XREF: ROM:00015714j
					; ROM:00015718j
		move.w	(v_objspace+$48).w,d0
		cmp.w	d1,d0
		bcs.s	loc_1573A
		cmp.w	d2,d0
		bcc.s	loc_1573A
		move.b	#1,$1A(a0)

loc_1573A:				; CODE XREF: ROM:0001572Ej
					; ROM:00015732j
		add.b	d3,$1A(a0)
		bra.w	loc_15868
; ---------------------------------------------------------------------------
Map_Obj49:	dc.w word_1574E-Map_Obj49 ; DATA XREF: ROM:000156A6o
					; ROM:Map_Obj49o ...
		dc.w word_15760-Map_Obj49
		dc.w word_157F2-Map_Obj49
		dc.w word_157F4-Map_Obj49
		dc.w word_157F2-Map_Obj49
		dc.w word_15816-Map_Obj49
word_1574E:	dc.w 2			; DATA XREF: ROM:Map_Obj49o
		dc.w $800D,    0,    0,$FFE0; 0
		dc.w $800D,    0,    0,	   0; 4
word_15760:	dc.w $12		; DATA XREF: ROM:00015744o
		dc.w $800D,    0,    0,$FFE0; 0
		dc.w $800D,    0,    0,	   0; 4
		dc.w $800F,    8,    4,$FFE0; 8
		dc.w $800F,    8,    4,	   0; 12
		dc.w $A00F,    8,    4,$FFE0; 16
		dc.w $A00F,    8,    4,	   0; 20
		dc.w $C00F,    8,    4,$FFE0; 24
		dc.w $C00F,    8,    4,	   0; 28
		dc.w $E00F,    8,    4,$FFE0; 32
		dc.w $E00F,    8,    4,	   0; 36
		dc.w	$F,    8,    4,$FFE0; 40
		dc.w	$F,    8,    4,	   0; 44
		dc.w $200F,    8,    4,$FFE0; 48
		dc.w $200F,    8,    4,	   0; 52
		dc.w $400F,    8,    4,$FFE0; 56
		dc.w $400F,    8,    4,	   0; 60
		dc.w $600F,    8,    4,$FFE0; 64
		dc.w $600F,    8,    4,	   0; 68
word_157F2:	dc.w 0			; DATA XREF: ROM:00015746o
					; ROM:0001574Ao
word_157F4:	dc.w 4			; DATA XREF: ROM:00015748o
		dc.w $E00F,    8,    4,$FFE0; 0
		dc.w $E00F,    8,    4,	   0; 4
		dc.w	$F,    8,    4,$FFE0; 8
		dc.w	$F,    8,    4,	   0; 12
word_15816:	dc.w $A			; DATA XREF: ROM:0001574Co
		dc.w $C00F,    8,    4,$FFE0; 0
		dc.w $C00F,    8,    4,	   0; 4
		dc.w $E00F,    8,    4,$FFE0; 8
		dc.w $E00F,    8,    4,	   0; 12
		dc.w	$F,    8,    4,$FFE0; 16
		dc.w	$F,    8,    4,	   0; 20
		dc.w $200F,    8,    4,$FFE0; 24
		dc.w $200F,    8,    4,	   0; 28
		dc.w $400F,    8,    4,$FFE0; 32
		dc.w $400F,    8,    4,	   0; 36
; ---------------------------------------------------------------------------

loc_15868:				; CODE XREF: ROM:0001555Cj
					; ROM:00015724j ...
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_1586E:				; CODE XREF: ROM:000156F2j
		jmp	DeleteObject
; ---------------------------------------------------------------------------

        if removeJmpTos=0
j_ModifySpriteAttr_2P_0:		; CODE XREF: ROM:000154F8p
					; ROM:000156B4p
		jmp	ModifySpriteAttr_2P

		align 4
	endif
;----------------------------------------------------
; Object 4D - Rhinobot badnik
;----------------------------------------------------

Obj4D:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj4D_Index(pc,d0.w),d1
		jmp	Obj4D_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj4D_Index:	dc.w Obj4D_Init-Obj4D_Index ; DATA XREF: ROM:Obj4D_Indexo
					; ROM:0001588Co
		dc.w Obj4D_Main-Obj4D_Index
; ---------------------------------------------------------------------------

Obj4D_Init:				; DATA XREF: ROM:Obj4D_Indexo
		move.l	#Map_Obj4D,4(a0)
		move.w	#$23C4,2(a0)
		ori.b	#4,1(a0)
		move.b	#$A,$20(a0)
		move.b	#4,$18(a0)
		move.b	#$18,$19(a0)
		move.b	#$10,$16(a0)
		move.b	#$18,$17(a0)
	if removeJmpTos=1
		jsr	(ObjectFall).l
	else
                bsr.w	j_ObjectFall_0
        endif
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	locret_158DC
		add.w	d1,$C(a0)
		move.w	#0,$12(a0)
		addq.b	#2,$24(a0)

locret_158DC:				; CODE XREF: ROM:000158CCj
		rts
; ---------------------------------------------------------------------------

Obj4D_Main:				; DATA XREF: ROM:0001588Co
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	Obj4D_SubIndex(pc,d0.w),d1
		jsr	Obj4D_SubIndex(pc,d1.w)
		lea	(Ani_Obj4D).l,a1
	if removeJmpTos=1
		jsr	(AnimateSprite).l
		jmp	(MarkObjGone).l
        else
                bsr.w	j_AnimateSprite_0
		bra.w	loc_15B38
	endif
; ---------------------------------------------------------------------------
Obj4D_SubIndex:	dc.w loc_158FE-Obj4D_SubIndex ;	DATA XREF: ROM:Obj4D_SubIndexo
					; ROM:000158FCo
		dc.w loc_15922-Obj4D_SubIndex
; ---------------------------------------------------------------------------

loc_158FE:				; DATA XREF: ROM:Obj4D_SubIndexo
		subq.w	#1,$30(a0)
		bpl.s	locret_15920
		addq.b	#2,$25(a0)
		move.w	#$FF80,$10(a0)
		move.b	#0,$1C(a0)
		bchg	#0,$22(a0)
		bne.s	locret_15920
		neg.w	$10(a0)

locret_15920:				; CODE XREF: ROM:00015902j
					; ROM:0001591Aj
		rts
; ---------------------------------------------------------------------------

loc_15922:				; DATA XREF: ROM:000158FCo
		bsr.w	sub_1596C
	if removeJmpTos=1
		jsr	(ObjectFall).l
	else
		bsr.w	j_ObjectFall_0
	endif
		jsr	(ObjHitFloor).l
		cmpi.w	#$FFF8,d1
		blt.s	loc_15948
		cmpi.w	#$C,d1
		bge.s	locret_15946
		move.w	#0,$12(a0)
		add.w	d1,$C(a0)

locret_15946:				; CODE XREF: ROM:0001593Aj
		rts
; ---------------------------------------------------------------------------

loc_15948:				; CODE XREF: ROM:00015934j
		subq.b	#2,$25(a0)
		move.w	#$3B,$30(a0) 
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,8(a0)
		move.w	#0,$10(a0)
		move.b	#1,$1C(a0)
		rts

; =============== S U B	R O U T	I N E =======================================


sub_1596C:				; CODE XREF: ROM:loc_15922p
		move.w	8(a0),d0
		sub.w	(v_objspace+8).w,d0
		bmi.s	loc_159A0
		cmpi.w	#$60,d0
		bgt.s	locret_15990
		btst	#0,$22(a0)
		bne.s	loc_15992
		move.b	#2,$1C(a0)
		move.w	#$FE00,$10(a0)

locret_15990:				; CODE XREF: sub_1596C+Ej
					; sub_1596C+38j
		rts
; ---------------------------------------------------------------------------

loc_15992:				; CODE XREF: sub_1596C+16j
		move.b	#0,$1C(a0)
		move.w	#$80,$10(a0)
		rts
; ---------------------------------------------------------------------------

loc_159A0:				; CODE XREF: sub_1596C+8j
		cmpi.w	#$FFA0,d0
		blt.s	locret_15990
		btst	#0,$22(a0)
		beq.s	loc_159BC
		move.b	#2,$1C(a0)
		move.w	#$200,$10(a0)
		rts
; ---------------------------------------------------------------------------

loc_159BC:				; CODE XREF: sub_1596C+40j
		move.b	#0,$1C(a0)
		move.w	#$FF80,$10(a0)
		rts
; End of function sub_1596C

; ---------------------------------------------------------------------------
Ani_Obj4D:	dc.w byte_159D0-Ani_Obj4D ; DATA XREF: ROM:000158ECo
					; ROM:Ani_Obj4Do ...
		dc.w byte_159DE-Ani_Obj4D
		dc.w byte_159E1-Ani_Obj4D
byte_159D0:	dc.b   2,  0,  0,  0,  3,  3,  4,  1,  1,  2,  5,  5,  5,$FF; 0
					; DATA XREF: ROM:Ani_Obj4Do
byte_159DE:	dc.b  $F,  0,$FF	; 0 ; DATA XREF: ROM:000159CCo
byte_159E1:	dc.b   2,  6,  7,$FF,  0; 0 ; DATA XREF: ROM:000159CEo
Map_Obj4D:	dc.w word_159F6-Map_Obj4D ; DATA XREF: ROM:Obj4D_Inito
					; ROM:Map_Obj4Do ...
		dc.w word_15A20-Map_Obj4D
		dc.w word_15A4A-Map_Obj4D
		dc.w word_15A74-Map_Obj4D
		dc.w word_15A9E-Map_Obj4D
		dc.w word_15AC8-Map_Obj4D
		dc.w word_15AF2-Map_Obj4D
		dc.w word_15B14-Map_Obj4D
word_159F6:	dc.w 5			; DATA XREF: ROM:Map_Obj4Do
		dc.w $F005,    0,    0,$FFF0; 0
		dc.w $F005,    4,    2,	   0; 4
		dc.w $F801,    8,    4,$FFE8; 8
		dc.w	 5,   $A,    5,$FFF0; 12
		dc.w	 9,  $22,  $11,	   0; 16
word_15A20:	dc.w 5			; DATA XREF: ROM:000159E8o
		dc.w $F005,    0,    0,$FFF0; 0
		dc.w $F005,    4,    2,	   0; 4
		dc.w $F801,    8,    4,$FFE8; 8
		dc.w	 5,   $E,    7,$FFF0; 12
		dc.w	 9,  $22,  $11,	   0; 16
word_15A4A:	dc.w 5			; DATA XREF: ROM:000159EAo
		dc.w $F005,    0,    0,$FFF0; 0
		dc.w $F005,    4,    2,	   0; 4
		dc.w $F801,    8,    4,$FFE8; 8
		dc.w	 5,  $12,    9,$FFF0; 12
		dc.w	 9,  $22,  $11,	   0; 16
word_15A74:	dc.w 5			; DATA XREF: ROM:000159ECo
		dc.w $F005,    0,    0,$FFF0; 0
		dc.w $F005,    4,    2,	   0; 4
		dc.w $F801,    8,    4,$FFE8; 8
		dc.w	 5,   $A,    5,$FFF0; 12
		dc.w	 9,  $28,  $14,	   0; 16
word_15A9E:	dc.w 5			; DATA XREF: ROM:000159EEo
		dc.w $F005,    0,    0,$FFF0; 0
		dc.w $F005,    4,    2,	   0; 4
		dc.w $F801,    8,    4,$FFE8; 8
		dc.w	 5,   $E,    7,$FFF0; 12
		dc.w	 9,  $28,  $14,	   0; 16
word_15AC8:	dc.w 5			; DATA XREF: ROM:000159F0o
		dc.w $F005,    0,    0,$FFF0; 0
		dc.w $F005,    4,    2,	   0; 4
		dc.w $F801,    8,    4,$FFE8; 8
		dc.w	 5,  $12,    9,$FFF0; 12
		dc.w	 9,  $28,  $14,	   0; 16
word_15AF2:	dc.w 4			; DATA XREF: ROM:000159F2o
		dc.w $F00B,  $16,   $B,$FFE8; 0
		dc.w $F005,    4,    2,	   0; 4
		dc.w	 9,  $22,  $11,	   0; 8
		dc.w $FB01,  $2E,  $17,	 $1A; 12
word_15B14:	dc.w 4			; DATA XREF: ROM:000159F4o
		dc.w $F00B,  $16,   $B,$FFE8; 0
		dc.w $F005,    4,    2,	   0; 4
		dc.w	 9,  $28,  $14,	   0; 8
		dc.w $FB01,  $30,  $18,	 $1A; 12

        if removeJmpTos=0
		align 4
loc_15B38:				; CODE XREF: ROM:000158F6j
		jmp	MarkObjGone
; ---------------------------------------------------------------------------

j_AnimateSprite_0:			; CODE XREF: ROM:000158F2p
		jmp	AnimateSprite
; ---------------------------------------------------------------------------

j_ObjectFall_0:				; CODE XREF: ROM:000158C0p
					; ROM:00015926p
		jmp	ObjectFall

		align 4
	endif
;----------------------------------------------------
; Object 52 - Piranha badnik
;----------------------------------------------------

Obj52:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj52_Index(pc,d0.w),d1
		jmp	Obj52_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj52_Index:	dc.w Obj52_Init-Obj52_Index ; DATA XREF: ROM:Obj52_Indexo
					; ROM:00015B5Co ...
		dc.w Obj52_Main-Obj52_Index
		dc.w loc_15C48-Obj52_Index
; ---------------------------------------------------------------------------

Obj52_Init:				; DATA XREF: ROM:Obj52_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj52,4(a0)
		move.w	#$2530,2(a0)
		ori.b	#4,1(a0)
		move.b	#$A,$20(a0)
		move.b	#4,$18(a0)
		move.b	#$10,$19(a0)
		moveq	#0,d0
		move.b	$28(a0),d0
		move.b	d0,d1
		andi.w	#$F0,d1	; "?"
		add.w	d1,d1
		add.w	d1,d1
		move.w	d1,$3A(a0)
		move.w	d1,$3C(a0)
		andi.w	#$F,d0
		lsl.w	#6,d0
		subq.w	#1,d0
		move.w	d0,$30(a0)
		move.w	d0,$32(a0)
		move.w	#$FF80,$10(a0)
		move.l	#$FFFB8000,$36(a0)
		move.w	$C(a0),$34(a0)
		bset	#6,$22(a0)
		btst	#0,$22(a0)
		beq.s	Obj52_Main
		neg.w	$10(a0)

Obj52_Main:				; CODE XREF: ROM:00015BD2j
					; DATA XREF: ROM:00015B5Co
		cmpi.w	#$FFFF,$3A(a0)
		beq.s	loc_15BE4
		subq.w	#1,$3A(a0)

loc_15BE4:				; CODE XREF: ROM:00015BDEj
		subq.w	#1,$30(a0)
		bpl.s	loc_15C06
		move.w	$32(a0),$30(a0)
		neg.w	$10(a0)
		bchg	#0,$22(a0)
		move.b	#1,$1D(a0)
		move.w	$3C(a0),$3A(a0)

loc_15C06:				; CODE XREF: ROM:00015BE8j
		lea	(Ani_Obj52).l,a1
	if removeJmpTos=1
		jsr	(AnimateSprite).l
		jsr	(SpeedToPos).l
	else
		bsr.w	j_AnimateSprite_1
		bsr.w	j_SpeedToPos_2
	endif
		tst.w	$3A(a0)
		bgt.w	loc_15D90
		cmpi.w	#$FFFF,$3A(a0)
		beq.w	loc_15D90
		move.l	#$FFFB8000,$36(a0)
		addq.b	#2,$24(a0)
		move.w	#$FFFF,$3A(a0)
		move.b	#2,$1C(a0)
		move.w	#1,$3E(a0)
		bra.w	loc_15D90
; ---------------------------------------------------------------------------

loc_15C48:				; DATA XREF: ROM:00015B5Eo
		move.w	#$390,($FFFFF646).w
		lea	(Ani_Obj52).l,a1
	if removeJmpTos=1
		jsr	(AnimateSprite).l
        else
                bsr.w	j_AnimateSprite_1
        endif
		move.w	$3E(a0),d0
		sub.w	d0,$30(a0)
		bsr.w	sub_15CF8
		tst.l	$36(a0)
		bpl.s	loc_15CA0
		move.w	$C(a0),d0
		cmp.w	($FFFFF646).w,d0
		bgt.w	loc_15D90
		move.b	#3,$1C(a0)
		bclr	#6,$22(a0)
		tst.b	$2A(a0)
		bne.w	loc_15D90
		move.w	$10(a0),d0
		asl.w	#1,d0
		move.w	d0,$10(a0)
		addq.w	#1,$3E(a0)
		st	$2A(a0)
		bra.w	loc_15D90
; ---------------------------------------------------------------------------

loc_15CA0:				; CODE XREF: ROM:00015C68j
		move.w	$C(a0),d0
		cmp.w	($FFFFF646).w,d0
		bgt.s	loc_15CB4
		move.b	#1,$1C(a0)
		bra.w	loc_15D90
; ---------------------------------------------------------------------------

loc_15CB4:				; CODE XREF: ROM:00015CA8j
		move.b	#0,$1C(a0)
		bset	#6,$22(a0)
		bne.s	loc_15CCE
		move.l	$36(a0),d0
		asr.l	#1,d0
		move.l	d0,$36(a0)
		nop

loc_15CCE:				; CODE XREF: ROM:00015CC0j
		move.w	$34(a0),d0
		cmp.w	$C(a0),d0
		bgt.w	loc_15D90
		subq.b	#2,$24(a0)
		tst.b	$2A(a0)
		beq.w	loc_15D90
		move.w	$10(a0),d0
		asr.w	#1,d0
		move.w	d0,$10(a0)
		sf	$2A(a0)
		bra.w	loc_15D90

; =============== S U B	R O U T	I N E =======================================


sub_15CF8:				; CODE XREF: ROM:00015C60p
		move.l	8(a0),d2
		move.l	$C(a0),d3
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		add.l	$36(a0),d3
		btst	#6,$22(a0)
		beq.s	loc_15D34
		tst.l	$36(a0)
		bpl.s	loc_15D2C
		addi.l	#$1000,$36(a0)
		addi.l	#$1000,$36(a0)

loc_15D2C:				; CODE XREF: sub_15CF8+22j
		subi.l	#$1000,$36(a0)

loc_15D34:				; CODE XREF: sub_15CF8+1Cj
		addi.l	#$1800,$36(a0)
		move.l	d2,8(a0)
		move.l	d3,$C(a0)
		rts
; End of function sub_15CF8

; ---------------------------------------------------------------------------
Ani_Obj52:	dc.w byte_15D4E-Ani_Obj52 ; DATA XREF: ROM:loc_15C06o
					; ROM:00015C4Eo ...
		dc.w byte_15D52-Ani_Obj52
		dc.w byte_15D56-Ani_Obj52
		dc.w byte_15D5A-Ani_Obj52
byte_15D4E:	dc.b  $E,  0,  1,$FF	; 0 ; DATA XREF: ROM:Ani_Obj52o
byte_15D52:	dc.b   3,  0,  1,$FF	; 0 ; DATA XREF: ROM:00015D48o
byte_15D56:	dc.b  $E,  2,  3,$FF	; 0 ; DATA XREF: ROM:00015D4Ao
byte_15D5A:	dc.b   3,  2,  3,$FF	; 0 ; DATA XREF: ROM:00015D4Co
Map_Obj52:	dc.w word_15D66-Map_Obj52 ; DATA XREF: ROM:00015B64o
					; ROM:Map_Obj52o ...
		dc.w word_15D70-Map_Obj52
		dc.w word_15D7A-Map_Obj52
		dc.w word_15D84-Map_Obj52
word_15D66:	dc.w 1			; DATA XREF: ROM:Map_Obj52o
		dc.w $F00F,    0,    0,$FFF0; 0
word_15D70:	dc.w 1			; DATA XREF: ROM:00015D60o
		dc.w $F00F,  $10,    8,$FFF0; 0
word_15D7A:	dc.w 1			; DATA XREF: ROM:00015D62o
		dc.w $F00F,  $20,  $10,$FFF0; 0
word_15D84:	dc.w 1			; DATA XREF: ROM:00015D64o
		dc.w $F00F,  $30,  $18,$FFF0; 0
	if removeJmpTos=0
		align 4
	endif	

loc_15D90:				; CODE XREF: ROM:00015C18j
					; ROM:00015C22j ...
		jmp	MarkObjGone
; ---------------------------------------------------------------------------

        if removeJmpTos=0
j_AnimateSprite_1:			; CODE XREF: ROM:00015C0Cp
					; ROM:00015C54p
		jmp	AnimateSprite
; ---------------------------------------------------------------------------

j_SpeedToPos_2:				; CODE XREF: ROM:00015C10p
		jmp	SpeedToPos

		align 4
	endif
;----------------------------------------------------
; Object 4F - Dinobot badnik
;----------------------------------------------------

Obj4F:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj4F_Index(pc,d0.w),d1
		jmp	Obj4F_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj4F_Index:	dc.w Obj4F_Init-Obj4F_Index ; DATA XREF: ROM:Obj4F_Indexo
					; ROM:00015DB4o ...
		dc.w Obj4F_Main-Obj4F_Index
		dc.w Obj4F_Delete-Obj4F_Index
; ---------------------------------------------------------------------------

Obj4F_Init:				; DATA XREF: ROM:Obj4F_Indexo
		move.l	#Map_Obj4F,4(a0)
		move.w	#$500,2(a0)
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$10,$19(a0)
		move.b	#$10,$16(a0)
		move.b	#6,$17(a0)
		move.b	#$C,$20(a0)
	if removeJmpTos=1
		jsr	(ObjectFall).l
	else
		bsr.w	j_ObjectFall_1
	endif
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	locret_15E0C
		add.w	d1,$C(a0)

loc_15DFC:
		move.w	#0,$12(a0)
		addq.b	#2,$24(a0)
		bchg	#0,$22(a0)

locret_15E0C:				; CODE XREF: ROM:00015DF6j
		rts
; ---------------------------------------------------------------------------

Obj4F_Main:				; DATA XREF: ROM:00015DB4o
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	Obj4F_SubIndex(pc,d0.w),d1
		jsr	Obj4F_SubIndex(pc,d1.w)
		lea	(Ani_Obj4F).l,a1
	if removeJmpTos=1
		jsr	(AnimateSprite).l
	else
		bsr.w	j_AnimateSprite_2
	endif
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.w	loc_15E3E
		bra.w	loc_15EE8
; ---------------------------------------------------------------------------

loc_15E3E:				; CODE XREF: ROM:00015E36j
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		beq.s	loc_15E50
		bclr	#7,2(a2,d0.w)

loc_15E50:				; CODE XREF: ROM:00015E48j
        if removeJmpTos=1
		jmp	(DeleteObject).l
	else
		bra.w	j_DeleteObject
	endif
; ---------------------------------------------------------------------------
Obj4F_SubIndex:	dc.w loc_15E58-Obj4F_SubIndex ;	DATA XREF: ROM:Obj4F_SubIndexo
					; ROM:00015E56o
		dc.w loc_15E7C-Obj4F_SubIndex
; ---------------------------------------------------------------------------

loc_15E58:				; DATA XREF: ROM:Obj4F_SubIndexo
		subq.w	#1,$30(a0)
		bpl.s	locret_15E7A
		addq.b	#2,$25(a0)
		move.w	#$FF80,$10(a0)
		move.b	#1,$1C(a0)
		bchg	#0,$22(a0)
		bne.s	locret_15E7A
		neg.w	$10(a0)

locret_15E7A:				; CODE XREF: ROM:00015E5Cj
					; ROM:00015E74j
		rts
; ---------------------------------------------------------------------------

loc_15E7C:				; DATA XREF: ROM:00015E56o
	if removeJmpTos=1
		jsr	(SpeedToPos).l
	else
		bsr.w	j_SpeedToPos_3
	endif
		jsr	(ObjHitFloor).l
		cmpi.w	#$FFF8,d1
		blt.s	loc_15E98
		cmpi.w	#$C,d1
		bge.s	loc_15E98
		add.w	d1,$C(a0)
		rts
; ---------------------------------------------------------------------------

loc_15E98:				; CODE XREF: ROM:00015E8Aj
					; ROM:00015E90j
		subq.b	#2,$25(a0)
		move.w	#$3B,$30(a0) 
		move.w	#0,$10(a0)
		move.b	#0,$1C(a0)
		rts
; ---------------------------------------------------------------------------

Obj4F_Delete:				; DATA XREF: ROM:00015DB6o
	if removeJmpTos=1
		jmp	(DeleteObject).l
	else
		bra.w	j_DeleteObject
	endif
; ---------------------------------------------------------------------------
Ani_Obj4F:	dc.w byte_15EB8-Ani_Obj4F ; DATA XREF: ROM:00015E1Co
					; ROM:Ani_Obj4Fo ...
		dc.w byte_15EBB-Ani_Obj4F
byte_15EB8:	dc.b   9,  1,$FF	; 0 ; DATA XREF: ROM:Ani_Obj4Fo
byte_15EBB:	dc.b   9,  0,  1,  2,  1,$FF,  0; 0 ; DATA XREF: ROM:00015EB6o
Map_Obj4F:	dc.w word_15EC8-Map_Obj4F ; DATA XREF: ROM:Obj4F_Inito
					; ROM:Map_Obj4Fo ...
		dc.w word_15ED2-Map_Obj4F
		dc.w word_15EDC-Map_Obj4F
word_15EC8:	dc.w 1			; DATA XREF: ROM:Map_Obj4Fo
		dc.w $F00F,    0,    0,$FFF0; 0
word_15ED2:	dc.w 1			; DATA XREF: ROM:00015EC4o
		dc.w $F00F,  $10,    8,$FFF0; 0
word_15EDC:	dc.w 1			; DATA XREF: ROM:00015EC6o
		dc.w $F00F,  $20,  $10,$FFF0; 0
	if removeJmpTos=0
		align 4
	endif	

loc_15EE8:				; CODE XREF: ROM:00015E3Aj
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

        if removeJmpTos=0
j_DeleteObject:				; CODE XREF: ROM:loc_15E50j
					; ROM:Obj4F_Deletej
		jmp	DeleteObject
; ---------------------------------------------------------------------------

j_AnimateSprite_2:			; CODE XREF: ROM:00015E22p
		jmp	AnimateSprite
; ---------------------------------------------------------------------------

j_ObjectFall_1:				; CODE XREF: ROM:00015DEAp
		jmp	ObjectFall
; ---------------------------------------------------------------------------

j_SpeedToPos_3:				; CODE XREF: ROM:loc_15E7Cp
		jmp	SpeedToPos

		align 4
	endif
;----------------------------------------------------
; Object 50 - unused Seahorse badnik from HPZ
;----------------------------------------------------

Obj50:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj50_Index(pc,d0.w),d1
		jmp	Obj50_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj50_Index:	dc.w Obj50_Init-Obj50_Index ; DATA XREF: ROM:Obj50_Indexo
					; ROM:00015F18o ...
		dc.w loc_15FDA-Obj50_Index
		dc.w loc_16006-Obj50_Index
		dc.w loc_16030-Obj50_Index
		dc.w Obj50_Routine08-Obj50_Index
		dc.w Obj50_Routine0A-Obj50_Index
; ---------------------------------------------------------------------------

Obj50_Init:				; DATA XREF: ROM:Obj50_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj50,4(a0)
		move.w	#$2570,2(a0)
		ori.b	#4,1(a0)
		move.b	#$A,$20(a0)
		move.b	#4,$18(a0)
		move.b	#$10,$19(a0)
		move.w	#$FF00,$10(a0)
		move.b	$28(a0),d0
		move.b	d0,d1
		andi.w	#$F0,d1	; "?"
		lsl.w	#4,d1
		move.w	d1,$2E(a0)
		move.w	d1,$30(a0)
		andi.w	#$F,d0
		lsl.w	#4,d0
		subq.w	#1,d0
		move.w	d0,$32(a0)
		move.w	d0,$34(a0)
		move.w	$C(a0),$2A(a0)
	if removeJmpTos=1
		jsr	(SingleObjectLoad).l
	else
		bsr.w	j_SingleObjectLoad
	endif
		bne.s	loc_15FDA
		move.b	#$50,0(a1) 
		move.b	#4,$24(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		addi.w	#$A,8(a1)
		addi.w	#$FFFA,$C(a1)
		move.l	#Map_Obj50,4(a1)
		move.w	#$24E0,2(a1)
		ori.b	#4,1(a1)
		move.b	#3,$18(a1)
		move.b	$22(a0),$22(a1)
		move.b	#3,$1C(a1)
		move.l	a1,$36(a0)
		move.l	a0,$36(a1)
		bset	#6,$22(a0)

loc_15FDA:				; CODE XREF: ROM:00015F80j
					; DATA XREF: ROM:00015F18o
		lea	(Ani_Obj50).l,a1
	if removeJmpTos=1
		jsr	(AnimateSprite).l
	else
		bsr.w	j_AnimateSprite_3
	endif
		move.w	#$39C,($FFFFF646).w
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	Obj50_SubIndex(pc,d0.w),d1
		jsr	Obj50_SubIndex(pc,d1.w)
		bsr.w	sub_161D8
	if removeJmpTos=1
                jmp     (MarkObjGone).l
        else
		bra.w	loc_1677A
	endif	
; ---------------------------------------------------------------------------
Obj50_SubIndex:	dc.w loc_16046-Obj50_SubIndex ;	DATA XREF: ROM:Obj50_SubIndexo
					; ROM:00016002o ...
		dc.w loc_16058-Obj50_SubIndex
		dc.w loc_16066-Obj50_SubIndex
; ---------------------------------------------------------------------------

loc_16006:				; DATA XREF: ROM:00015F1Ao
		movea.l	$36(a0),a1
		tst.b	(a1)
		beq.w	loc_1676E
		cmpi.b	#$50,(a1) 
		bne.w	loc_1676E
		btst	#7,$22(a1)
		bne.w	loc_1676E
		lea	(Ani_Obj50).l,a1
	if removeJmpTos=1
		jsr	(AnimateSprite).l
		jmp     (DisplaySprite).l
	else
		bsr.w	j_AnimateSprite_3
		bra.w	loc_16768
	endif
; ---------------------------------------------------------------------------

loc_16030:				; DATA XREF: ROM:00015F1Co
		bsr.w	loc_162FC
	if removeJmpTos=1
                jsr     (SpeedToPos).l 
        else
		bsr.w	j_SpeedToPos_4
	endif
		lea	(Ani_Obj50).l,a1
	if removeJmpTos=1
		jsr	(AnimateSprite).l
		jmp     (MarkObjGone).l
	else
		bsr.w	j_AnimateSprite_3
		bra.w	loc_1677A
	endif
; ---------------------------------------------------------------------------

loc_16046:				; DATA XREF: ROM:Obj50_SubIndexo
	if removeJmpTos=1
                jsr     (SpeedToPos).l
        else
                bsr.w	j_SpeedToPos_4
        endif
		bsr.w	sub_162DE
		bsr.w	sub_16184
		bsr.w	sub_1611C
		rts
; ---------------------------------------------------------------------------

loc_16058:				; DATA XREF: ROM:00016002o
	if removeJmpTos=1
                jsr     (SpeedToPos).l
        else
                bsr.w	j_SpeedToPos_4
        endif
		bsr.w	sub_162DE
		bsr.w	sub_161A6
		rts
; ---------------------------------------------------------------------------

loc_16066:				; DATA XREF: ROM:00016004o
	if removeJmpTos=1
                jsr     (ObjectFall).l
        else
                bsr.w	j_ObjectFall_2
        endif
		bsr.w	sub_162DE
		bsr.w	sub_16078
		bsr.w	sub_160F4
		rts

; =============== S U B	R O U T	I N E =======================================


sub_16078:				; CODE XREF: ROM:0001606Ep
		tst.b	$2D(a0)
		bne.s	locret_16084
		tst.w	$12(a0)
		bpl.s	loc_16086

locret_16084:				; CODE XREF: sub_16078+4j
		rts
; ---------------------------------------------------------------------------

loc_16086:				; CODE XREF: sub_16078+Aj
		st	$2D(a0)
	if removeJmpTos=1
		jsr	(SingleObjectLoad).l
	else
		bsr.w	j_SingleObjectLoad
	endif
		bne.s	locret_160F2
		move.b	#$50,0(a1) 
		move.b	#6,$24(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.l	#Map_Obj50,4(a1)
		move.w	#$24E0,2(a1)
		ori.b	#4,1(a1)
		move.b	#3,$18(a1)
		move.b	#$E5,$20(a1)
		move.b	#2,$1C(a1)
		move.w	#$C,d0
		move.w	#$10,d1
		move.w	#$FD00,d2
		btst	#0,$22(a0)
		beq.s	loc_160E6
		neg.w	d1
		neg.w	d2

loc_160E6:				; CODE XREF: sub_16078+68j
		sub.w	d0,$C(a1)
		sub.w	d1,8(a1)
		move.w	d2,$10(a1)

locret_160F2:				; CODE XREF: sub_16078+16j
		rts
; End of function sub_16078


; =============== S U B	R O U T	I N E =======================================


sub_160F4:				; CODE XREF: ROM:00016072p
		move.w	$C(a0),d0
		cmp.w	($FFFFF646).w,d0
		blt.s	locret_1611A
		move.b	#2,$25(a0)
		move.b	#0,$1C(a0)
		move.w	$30(a0),$2E(a0)
		move.w	#$40,$12(a0)
		sf	$2D(a0)

locret_1611A:				; CODE XREF: sub_160F4+8j
		rts
; End of function sub_160F4


; =============== S U B	R O U T	I N E =======================================


sub_1611C:				; CODE XREF: ROM:00016052p
		tst.b	$2C(a0)
		beq.s	locret_16182
		move.w	(v_objspace+8).w,d0
		move.w	(v_objspace+$C).w,d1
		sub.w	$C(a0),d1
		bpl.s	locret_16182
		cmpi.w	#$FFD0,d1
		blt.s	locret_16182
		sub.w	8(a0),d0
		cmpi.w	#$48,d0	
		bgt.s	locret_16182
		cmpi.w	#$FFB8,d0
		blt.s	locret_16182
		tst.w	d0
		bpl.s	loc_1615A
		cmpi.w	#$FFD8,d0
		bgt.s	locret_16182
		btst	#0,$22(a0)
		bne.s	locret_16182
		bra.s	loc_16168
; ---------------------------------------------------------------------------

loc_1615A:				; CODE XREF: sub_1611C+2Cj
		cmpi.w	#$28,d0	
		blt.s	locret_16182
		btst	#0,$22(a0)
		beq.s	locret_16182

loc_16168:				; CODE XREF: sub_1611C+3Cj
		moveq	#$20,d0
		cmp.w	$32(a0),d0
		bgt.s	locret_16182
		move.b	#4,$25(a0)
		move.b	#1,$1C(a0)
		move.w	#$FC00,$12(a0)

locret_16182:				; CODE XREF: sub_1611C+4j
					; sub_1611C+12j ...
		rts
; End of function sub_1611C


; =============== S U B	R O U T	I N E =======================================


sub_16184:				; CODE XREF: ROM:0001604Ep
		subq.w	#1,$2E(a0)
		bne.s	locret_161A4
		move.w	$30(a0),$2E(a0)
		addq.b	#2,$25(a0)
		move.w	#$FFC0,d0
		tst.b	$2C(a0)
		beq.s	loc_161A0
		neg.w	d0

loc_161A0:				; CODE XREF: sub_16184+18j
		move.w	d0,$12(a0)

locret_161A4:				; CODE XREF: sub_16184+4j
		rts
; End of function sub_16184


; =============== S U B	R O U T	I N E =======================================


sub_161A6:				; CODE XREF: ROM:00016060p
		move.w	$C(a0),d0
		tst.b	$2C(a0)
		bne.s	loc_161C4
		cmp.w	($FFFFF646).w,d0
		bgt.s	locret_161C2
		subq.b	#2,$25(a0)
		st	$2C(a0)
		clr.w	$12(a0)

locret_161C2:				; CODE XREF: sub_161A6+Ej
					; sub_161A6+22j
		rts
; ---------------------------------------------------------------------------

loc_161C4:				; CODE XREF: sub_161A6+8j
		cmp.w	$2A(a0),d0
		blt.s	locret_161C2
		subq.b	#2,$25(a0)
		sf	$2C(a0)
		clr.w	$12(a0)
		rts
; End of function sub_161A6


; =============== S U B	R O U T	I N E =======================================


sub_161D8:				; CODE XREF: ROM:00015FF8p
		moveq	#$A,d0
		moveq	#$FFFFFFFA,d1
		movea.l	$36(a0),a1
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	$22(a0),$22(a1)
		move.b	$23(a0),$23(a1)
		move.b	1(a0),1(a1)
		btst	#0,$22(a1)
		beq.s	loc_16208
		neg.w	d0

loc_16208:				; CODE XREF: sub_161D8+2Cj
		add.w	d0,8(a1)
		add.w	d1,$C(a1)
		rts
; End of function sub_161D8

; ---------------------------------------------------------------------------

Obj50_Routine08:			; DATA XREF: ROM:00015F1Eo
					; ROM:0001653At
	if removeJmpTos=1
                jsr     (ObjectFall).l
        else
                bsr.w	j_ObjectFall_2
        endif
		bsr.w	sub_16228
		lea	(Ani_Obj50).l,a1
	if removeJmpTos=1
		jsr	(AnimateSprite).l
		jmp     (MarkObjGone).l
	else
		bsr.w	j_AnimateSprite_3
		bra.w	loc_1677A
	endif

; =============== S U B	R O U T	I N E =======================================


sub_16228:				; CODE XREF: ROM:00016216p
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	loc_16242
		add.w	d1,$C(a0)
		move.w	$12(a0),d0
		asr.w	#1,d0
		neg.w	d0
		move.w	d0,$12(a0)

loc_16242:				; CODE XREF: sub_16228+8j
		subi.b	#1,$21(a0)
		beq.w	loc_1676E
		rts
; End of function sub_16228

; ---------------------------------------------------------------------------

Obj50_Routine0A:			; DATA XREF: ROM:00015F20o
					; ROM:0001653Ct
		bsr.w	sub_1629E
		tst.b	$25(a0)
		beq.s	locret_1628E
		subi.w	#1,$2C(a0)
		beq.w	loc_1676E
		move.w	(v_objspace+8).w,8(a0)
		move.w	(v_objspace+$C).w,$C(a0)
		addi.w	#$C,$C(a0)
		subi.b	#1,$2A(a0)
		bne.s	loc_16290
		move.b	#3,$2A(a0)
		bchg	#0,$22(a0)
		bchg	#0,1(a0)

locret_1628E:				; CODE XREF: ROM:00016256j
		rts
; ---------------------------------------------------------------------------

loc_16290:				; CODE XREF: ROM:0001627Aj
		lea	(Ani_Obj50).l,a1
	if removeJmpTos=1
		jsr	(AnimateSprite).l
		jmp     (DisplaySprite).l
	else
		bsr.w	j_AnimateSprite_3
		bra.w	loc_16768
	endif

; =============== S U B	R O U T	I N E =======================================


sub_1629E:				; CODE XREF: ROM:Obj50_Routine0Ap
		tst.b	$25(a0)
		bne.s	locret_162DC
		move.b	(v_objspace+$24).w,d0
		cmpi.b	#2,d0
		bne.s	locret_162DC
		move.w	(v_objspace+8).w,8(a0)
		move.w	(v_objspace+$C).w,$C(a0)
		ori.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#5,$1C(a0)
		st	$25(a0)
		move.w	#$12C,$2C(a0)
		move.b	#3,$2A(a0)

locret_162DC:				; CODE XREF: sub_1629E+4j sub_1629E+Ej
		rts
; End of function sub_1629E


; =============== S U B	R O U T	I N E =======================================


sub_162DE:				; CODE XREF: ROM:0001604Ap
					; ROM:0001605Cp ...
		subq.w	#1,$32(a0)
		bpl.s	locret_162FA
		move.w	$34(a0),$32(a0)
		neg.w	$10(a0)
		bchg	#0,$22(a0)
		move.b	#1,$1D(a0)

locret_162FA:				; CODE XREF: sub_162DE+4j
		rts
; End of function sub_162DE

; ---------------------------------------------------------------------------

loc_162FC:				; CODE XREF: ROM:loc_16030p
					; ROM:loc_165C0p
		tst.b	$21(a0)
		beq.w	locret_1639E
		moveq	#2,d3

loc_16306:				; CODE XREF: ROM:loc_16378j
	if removeJmpTos=1
		jsr	(SingleObjectLoad).l
	else
		bsr.w	j_SingleObjectLoad
	endif
		bne.s	loc_16378
		move.b	0(a0),0(a1)
		move.b	#8,$24(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.l	4(a0),4(a1)
		move.w	#$24E0,2(a1)
		ori.b	#4,1(a1)
		move.b	#3,$18(a1)
		move.w	#$FF00,$12(a1)
		move.b	#4,$1C(a1)
		move.b	#$78,$21(a1) 
		cmpi.w	#1,d3
		beq.s	loc_16372
		blt.s	loc_16364
		move.w	#$C0,$10(a1) 
		addi.w	#$FF40,$12(a1)
		bra.s	loc_16378
; ---------------------------------------------------------------------------

loc_16364:				; CODE XREF: ROM:00016354j
		move.w	#$FF00,$10(a1)
		addi.w	#$FFC0,$12(a1)
		bra.s	loc_16378
; ---------------------------------------------------------------------------

loc_16372:				; CODE XREF: ROM:00016352j
		move.w	#$40,$10(a1)

loc_16378:				; CODE XREF: ROM:0001630Aj
					; ROM:00016362j ...
		dbf	d3,loc_16306
	if removeJmpTos=1
		jsr	(SingleObjectLoad).l
	else
		bsr.w	j_SingleObjectLoad
	endif
		bne.s	loc_1639A
		move.b	0(a0),0(a1)
		move.b	#$A,$24(a1)
		move.l	4(a0),4(a1)
		move.w	#$24E0,2(a1)

loc_1639A:				; CODE XREF: ROM:00016380j
		bra.w	loc_1676E
; ---------------------------------------------------------------------------

locret_1639E:				; CODE XREF: ROM:00016300j
		rts
; ---------------------------------------------------------------------------
Ani_Obj50:	dc.w byte_163B0-Ani_Obj50 ; DATA XREF: ROM:loc_15FDAo
					; ROM:00016022o ...
		dc.w byte_163B3-Ani_Obj50
		dc.w byte_163BB-Ani_Obj50
		dc.w byte_163C1-Ani_Obj50
		dc.w byte_163C5-Ani_Obj50
		dc.w byte_163C8-Ani_Obj50
		dc.w byte_163CB-Ani_Obj50
		dc.w byte_163CF-Ani_Obj50
byte_163B0:	dc.b  $E,  0,$FF	; 0 ; DATA XREF: ROM:Ani_Obj50o
byte_163B3:	dc.b   5,  3,  4,  3,  4,  3,  4,$FF; 0	; DATA XREF: ROM:000163A2o
byte_163BB:	dc.b   3,  5,  6,  7,  6,$FF; 0	; DATA XREF: ROM:000163A4o
byte_163C1:	dc.b   3,  1,  2,$FF	; 0 ; DATA XREF: ROM:000163A6o
byte_163C5:	dc.b   1,  5,$FF	; 0 ; DATA XREF: ROM:000163A8o
byte_163C8:	dc.b  $E,  8,$FF	; 0 ; DATA XREF: ROM:000163AAo
byte_163CB:	dc.b   1,  9, $A,$FF	; 0 ; DATA XREF: ROM:000163ACo
byte_163CF:	dc.b   5, $B, $C, $B, $C, $B, $C,$FF,  0; 0 ; DATA XREF: ROM:000163AEo
Map_Obj50:	dc.w word_163F2-Map_Obj50 ; DATA XREF: ROM:00015F26o
					; ROM:00015FA6o ...
		dc.w word_1640C-Map_Obj50
		dc.w word_16416-Map_Obj50
		dc.w word_16420-Map_Obj50
		dc.w word_16442-Map_Obj50
		dc.w word_16464-Map_Obj50
		dc.w word_1646E-Map_Obj50
		dc.w word_16478-Map_Obj50
		dc.w word_16482-Map_Obj50
		dc.w word_1648C-Map_Obj50
		dc.w word_164AE-Map_Obj50
		dc.w word_164D0-Map_Obj50
		dc.w word_164FA-Map_Obj50
word_163F2:	dc.w 3			; DATA XREF: ROM:Map_Obj50o
		dc.w $E80D,    0,    0,$FFF0; 0
		dc.w $F809,  $16,   $B,$FFF8; 4
		dc.w  $805,  $24,  $12,$FFF8; 8
word_1640C:	dc.w 1			; DATA XREF: ROM:000163DAo
		dc.w $F805,  $28,  $14,$FFF8; 0
word_16416:	dc.w 1			; DATA XREF: ROM:000163DCo
		dc.w $F805,  $2C,  $16,$FFF8; 0
word_16420:	dc.w 4			; DATA XREF: ROM:000163DEo
		dc.w $E809,    8,    4,$FFF0; 0
		dc.w $E801,   $E,    7,	   8; 4
		dc.w $F809,  $16,   $B,$FFF8; 8
		dc.w  $805,  $24,  $12,$FFF8; 12
word_16442:	dc.w 4			; DATA XREF: ROM:000163E0o
		dc.w $E809,  $10,    8,$FFF0; 0
		dc.w $E801,   $E,    7,	   8; 4
		dc.w $F809,  $16,   $B,$FFF8; 8
		dc.w  $805,  $24,  $12,$FFF8; 12
word_16464:	dc.w 1			; DATA XREF: ROM:000163E2o
		dc.w $F801,  $30,  $18,$FFFC; 0
word_1646E:	dc.w 1			; DATA XREF: ROM:000163E4o
		dc.w $F801,  $32,  $19,$FFFC; 0
word_16478:	dc.w 1			; DATA XREF: ROM:000163E6o
		dc.w $F801,  $34,  $1A,$FFFC; 0
word_16482:	dc.w 1			; DATA XREF: ROM:000163E8o
		dc.w $F80D,  $36,  $1B,$FFF0; 0
word_1648C:	dc.w 4			; DATA XREF: ROM:000163EAo
		dc.w $E80D,    0,    0,$FFF0; 0
		dc.w $F805,  $1C,   $E,$FFF8; 4
		dc.w $F801,  $20,  $10,	   8; 8
		dc.w  $805,  $24,  $12,$FFF8; 12
word_164AE:	dc.w 4			; DATA XREF: ROM:000163ECo
		dc.w $E80D,    0,    0,$FFF0; 0
		dc.w $F805,  $1C,   $E,$FFF8; 4
		dc.w $F801,  $22,  $11,	   8; 8
		dc.w  $805,  $24,  $12,$FFF8; 12
word_164D0:	dc.w 5			; DATA XREF: ROM:000163EEo
		dc.w $E809,    8,    4,$FFF0; 0
		dc.w $E801,   $E,    7,	   8; 4
		dc.w $F805,  $1C,   $E,$FFF8; 8
		dc.w $F801,  $20,  $10,	   8; 12
		dc.w  $805,  $24,  $12,$FFF8; 16
word_164FA:	dc.w 5			; DATA XREF: ROM:000163F0o
		dc.w $E809,  $10,    8,$FFF0; 0
		dc.w $E801,   $E,    7,	   8; 4
		dc.w $F805,  $1C,   $E,$FFF8; 8
		dc.w $F801,  $22,  $11,	   8; 12
		dc.w  $805,  $24,  $12,$FFF8; 16
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 51 - unused Skyhorse badnik from HPZ
;----------------------------------------------------

Obj51:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	off_16532(pc,d0.w),d1
		jmp	off_16532(pc,d1.w)
; ---------------------------------------------------------------------------
off_16532:	dc.w loc_1653E-off_16532 ; DATA	XREF: ROM:off_16532o
					; ROM:00016534o ...
		dc.w loc_1659C-off_16532
		dc.w loc_165C0-off_16532
		dc.w 0
		dc.w Obj50_Routine08-off_16532
		dc.w Obj50_Routine0A-off_16532
; ---------------------------------------------------------------------------

loc_1653E:				; DATA XREF: ROM:off_16532o
		addq.b	#2,$24(a0)
		move.l	#Map_Obj50,4(a0)
		move.w	#$2570,2(a0)
		ori.b	#4,1(a0)
		move.b	#$A,$20(a0)
		move.b	#4,$18(a0)
		move.b	#$10,$19(a0)
		move.b	#6,$1C(a0)
		move.b	$28(a0),d0
		andi.w	#$F,d0
		move.w	d0,d1
		lsl.w	#5,d1
		subq.w	#1,d1
		move.w	d1,$32(a0)
		move.w	d1,$34(a0)
		move.w	$C(a0),$2A(a0)
		move.w	$C(a0),$2E(a0)
		addi.w	#$60,$2E(a0)
		move.w	#$FF00,$10(a0)

loc_1659C:				; DATA XREF: ROM:00016534o
		lea	Ani_Obj50(pc),a1
	if removeJmpTos=1
		jsr	(AnimateSprite).l
	else
		bsr.w	j_AnimateSprite_3
	endif
		move.w	#$39C,($FFFFF646).w
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	off_165BC(pc,d0.w),d1
		jsr	off_165BC(pc,d1.w)
	if removeJmpTos=1
                jmp     (MarkObjGone).l
        else
		bra.w	loc_1677A
	endif
; ---------------------------------------------------------------------------
off_165BC:	dc.w loc_165D4-off_165BC ; DATA	XREF: ROM:off_165BCo
					; ROM:000165BEo
		dc.w loc_165EA-off_165BC
; ---------------------------------------------------------------------------

loc_165C0:				; DATA XREF: ROM:00016536o
		bsr.w	loc_162FC
	if removeJmpTos=1
                jsr     (SpeedToPos).l 
        else
		bsr.w	j_SpeedToPos_4
	endif
		lea	Ani_Obj50(pc),a1
	if removeJmpTos=1
		jsr	(AnimateSprite).l
		jmp	(MarkObjGone).l
	else
                bsr.w	j_AnimateSprite_3
                bra.w	loc_1677A
	endif
; ---------------------------------------------------------------------------

loc_165D4:				; DATA XREF: ROM:off_165BCo
	if removeJmpTos=1
                jsr     (SpeedToPos).l 
        else
		bsr.w	j_SpeedToPos_4
	endif
		bsr.w	sub_162DE
		bsr.w	loc_16626
		bsr.w	loc_16708
		bsr.w	loc_16678
		rts
; ---------------------------------------------------------------------------

loc_165EA:				; DATA XREF: ROM:000165BEo
	if removeJmpTos=1
                jsr     (SpeedToPos).l 
        else
		bsr.w	j_SpeedToPos_4
	endif
		bsr.w	sub_162DE
		bsr.w	loc_16626
		bsr.w	loc_16708
		bsr.w	loc_16600
		rts
; ---------------------------------------------------------------------------

loc_16600:				; CODE XREF: ROM:000165FAp
		subq.w	#1,$30(a0)
		beq.s	loc_16614
		move.w	$30(a0),d0
		cmpi.w	#$12,d0
		beq.w	loc_1669E
		rts
; ---------------------------------------------------------------------------

loc_16614:				; CODE XREF: ROM:00016604j
		subq.b	#2,$25(a0)
		move.b	#6,$1C(a0)
		move.w	#$B4,$30(a0) ; "?"
		rts
; ---------------------------------------------------------------------------

loc_16626:				; CODE XREF: ROM:000165DCp
					; ROM:000165F2p
		sf	$2D(a0)
		sf	$2C(a0)
		sf	$36(a0)
		move.w	(v_objspace+8).w,d0
		sub.w	8(a0),d0
		bpl.s	loc_16646
		btst	#0,$22(a0)
		bne.s	loc_1664E
		bra.s	loc_16652
; ---------------------------------------------------------------------------

loc_16646:				; CODE XREF: ROM:0001663Aj
		btst	#0,$22(a0)
		bne.s	loc_16652

loc_1664E:				; CODE XREF: ROM:00016642j
		st	$2C(a0)

loc_16652:				; CODE XREF: ROM:00016644j
					; ROM:0001664Cj
		move.w	(v_objspace+$C).w,d0
		sub.w	$C(a0),d0
		cmpi.w	#$FFFC,d0
		blt.s	locret_16676
		cmpi.w	#4,d0
		bgt.s	loc_16672
		st	$2D(a0)
		move.w	#0,$12(a0)
		rts
; ---------------------------------------------------------------------------

loc_16672:				; CODE XREF: ROM:00016664j
		st	$36(a0)

locret_16676:				; CODE XREF: ROM:0001665Ej
		rts
; ---------------------------------------------------------------------------

loc_16678:				; CODE XREF: ROM:000165E4p
		tst.b	$2C(a0)
		bne.s	locret_1669C
		subq.w	#1,$30(a0)
		bgt.s	locret_1669C
		tst.b	$2D(a0)
		beq.s	locret_1669C
		move.b	#7,$1C(a0)
		move.w	#$24,$30(a0)
		addi.b	#2,$25(a0)

locret_1669C:				; CODE XREF: ROM:0001667Cj
					; ROM:00016682j ...
		rts
; ---------------------------------------------------------------------------

loc_1669E:				; CODE XREF: ROM:0001660Ej
	if removeJmpTos=1
		jsr	(SingleObjectLoad).l
	else
		bsr.w	j_SingleObjectLoad
	endif
		bne.s	locret_16706
		move.b	#$51,0(a1)
		move.b	#4,$24(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.l	#Map_Obj50,4(a1)
		move.w	#$24E0,2(a1)
		ori.b	#4,1(a1)
		move.b	#3,$18(a1)
		move.b	#2,$1C(a1)
		move.b	#$E5,$20(a1)
		move.w	#$C,d0
		move.w	#$10,d1
		move.w	#$FD00,d2
		btst	#0,$22(a0)
		beq.s	loc_166FA
		neg.w	d1
		neg.w	d2

loc_166FA:				; CODE XREF: ROM:000166F4j
		sub.w	d0,$C(a1)
		sub.w	d1,8(a1)
		move.w	d2,$10(a1)

locret_16706:				; CODE XREF: ROM:000166A2j
		rts
; ---------------------------------------------------------------------------

loc_16708:				; CODE XREF: ROM:000165E0p
					; ROM:000165F6p
		tst.b	$2D(a0)
		bne.s	locret_16766
		tst.b	$36(a0)
		beq.s	loc_16738
		move.w	$2E(a0),d0
		cmp.w	$C(a0),d0
		ble.s	loc_1675C
		tst.b	$2C(a0)
		beq.s	loc_16730
		move.w	$2A(a0),d0
		cmp.w	$C(a0),d0
		bge.s	loc_1675C
		rts
; ---------------------------------------------------------------------------

loc_16730:				; CODE XREF: ROM:00016722j
		move.w	#$180,$12(a0)
		rts
; ---------------------------------------------------------------------------

loc_16738:				; CODE XREF: ROM:00016712j
		move.w	$2A(a0),d0
		cmp.w	$C(a0),d0
		bge.s	loc_1675C
		tst.b	$2C(a0)
		beq.s	loc_16754
		move.w	$2E(a0),d0
		cmp.w	$C(a0),d0
		ble.s	loc_1675C
		rts
; ---------------------------------------------------------------------------

loc_16754:				; CODE XREF: ROM:00016746j
		move.w	#$FE80,$12(a0)
		rts
; ---------------------------------------------------------------------------

loc_1675C:				; CODE XREF: ROM:0001671Cj
					; ROM:0001672Cj ...
		move.w	d0,$C(a0)
		move.w	#0,$12(a0)

locret_16766:				; CODE XREF: ROM:0001670Cj
		rts
; ---------------------------------------------------------------------------
        if removeJmpTos=0
loc_16768:				; CODE XREF: ROM:0001602Cj
					; ROM:0001629Aj
		jmp	DisplaySprite
	endif
; ---------------------------------------------------------------------------

loc_1676E:				; CODE XREF: ROM:0001600Cj
					; ROM:00016014j ...
		jmp	DeleteObject
; ---------------------------------------------------------------------------
        if removeJmpTos=0
j_SingleObjectLoad:			; CODE XREF: ROM:00015F7Cp
					; sub_16078+12p ...
		jmp	SingleObjectLoad
; ---------------------------------------------------------------------------

loc_1677A:				; CODE XREF: ROM:00015FFCj
					; ROM:00016042j ...
		jmp	MarkObjGone
; ---------------------------------------------------------------------------

j_AnimateSprite_3:			; CODE XREF: ROM:00015FE0p
					; ROM:00016028p ...
		jmp	AnimateSprite
; ---------------------------------------------------------------------------

j_ObjectFall_2:				; CODE XREF: ROM:loc_16066p
					; ROM:Obj50_Routine08p
		jmp	ObjectFall
; ---------------------------------------------------------------------------

j_SpeedToPos_4:				; CODE XREF: ROM:00016034p
					; ROM:loc_16046p ...
		jmp	SpeedToPos

		align 4
	endif
;----------------------------------------------------
; Object 4B - Buzz Bomber badnik
;----------------------------------------------------

Obj4B:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj4B_Index(pc,d0.w),d1
		jmp	Obj4B_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj4B_Index:	dc.w Obj4B_Init-Obj4B_Index ; DATA XREF: ROM:Obj4B_Indexo
					; ROM:000167A4o ...
		dc.w Obj4B_Main-Obj4B_Index
		dc.w loc_167BC-Obj4B_Index
		dc.w loc_167AA-Obj4B_Index
; ---------------------------------------------------------------------------

loc_167AA:				; DATA XREF: ROM:000167A8o
                bsr.w	j_SpeedToPos_5
		lea	(Ani_Obj4B).l,a1
	if removeJmpTos=1
		jsr	(AnimateSprite).l
		jmp     (loc_CEC6).l
	else
		bsr.w	j_AnimateSprite_4
		bra.w	loc_16A8C
	endif
; ---------------------------------------------------------------------------

loc_167BC:				; DATA XREF: ROM:000167A6o
		movea.l	$2A(a0),a1
		tst.b	(a1)
		beq.w	loc_16A74
		tst.w	$30(a1)
		bmi.s	loc_167CE
		rts
; ---------------------------------------------------------------------------

loc_167CE:				; CODE XREF: ROM:000167CAj
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		move.b	$22(a1),$22(a0)
		move.b	1(a1),1(a0)
		lea	(Ani_Obj4B).l,a1
	if removeJmpTos=1
		jsr	(AnimateSprite).l
		jmp     (loc_CEC6).l
	else
		bsr.w	j_AnimateSprite_4
		bra.w	loc_16A8C
	endif
; ---------------------------------------------------------------------------

Obj4B_Init:				; DATA XREF: ROM:Obj4B_Indexo
		move.l	#Map_Obj4B,4(a0)
		move.w	#$3E6,2(a0)
	if removeJmpTos=1
		jsr	(ModifySpriteAttr_2P).l
	else
		bsr.w	j_ModifySpriteAttr_2P_2
	endif
		ori.b	#4,1(a0)
		move.b	#$A,$20(a0)
		move.b	#4,$18(a0)
		move.b	#$10,$19(a0)
		move.b	#$10,$16(a0)
		move.b	#$18,$17(a0)
		move.b	#3,$18(a0)
		addq.b	#2,$24(a0)
	if removeJmpTos=1
		jsr	(S1SingleObjectLoad2).l
	else
		bsr.w	j_S1SingleObjectLoad2_0
	endif
		bne.s	locret_1689E
		move.b	#$4B,0(a1) 
		move.b	#4,$24(a1)
		move.l	#Map_Obj4B,4(a1)
		move.w	#$3E6,2(a1)
	if removeJmpTos=1
		jsr	(ModifyA1SpriteAttr_2P).l
	else
		bsr.w	j_ModifyA1SpriteAttr_2P
	endif
		move.b	#4,$18(a1)
		move.b	#$10,$19(a1)
		move.b	$22(a0),$22(a1)
		move.b	1(a0),1(a1)
		move.b	#1,$1C(a1)
		move.l	a0,$2A(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	#$100,$2E(a0)
		move.w	#$FF00,$10(a0)
		btst	#0,1(a0)
		beq.s	locret_1689E
		neg.w	$10(a0)

locret_1689E:				; CODE XREF: ROM:00016838j
					; ROM:00016898j
		rts
; ---------------------------------------------------------------------------

Obj4B_Main:				; DATA XREF: ROM:000167A4o
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	Obj4B_SubIndex(pc,d0.w),d1
		jsr	Obj4B_SubIndex(pc,d1.w)
		lea	(Ani_Obj4B).l,a1
	if removeJmpTos=1
		jsr	(AnimateSprite).l
		jmp     (loc_CEC6).l
	else
		bsr.w	j_AnimateSprite_4
		bra.w	loc_16A8C
	endif
; ---------------------------------------------------------------------------
Obj4B_SubIndex:	dc.w loc_168C0-Obj4B_SubIndex ;	DATA XREF: ROM:Obj4B_SubIndexo
					; ROM:000168BEo
		dc.w loc_16950-Obj4B_SubIndex
; ---------------------------------------------------------------------------

loc_168C0:				; DATA XREF: ROM:Obj4B_SubIndexo
		bsr.w	sub_16902
		subq.w	#1,$30(a0)
		move.w	$30(a0),d0
		cmpi.w	#$F,d0
		beq.s	loc_168E6
		tst.w	d0
		bpl.s	locret_168E4
		subq.w	#1,$2E(a0)
		bgt.w	j_SpeedToPos_5
		move.w	#$1E,$30(a0)

locret_168E4:				; CODE XREF: ROM:000168D4j
		rts
; ---------------------------------------------------------------------------

loc_168E6:				; CODE XREF: ROM:000168D0j
		sf	$32(a0)
		neg.w	$10(a0)
		bchg	#0,1(a0)
		bchg	#0,$22(a0)
		move.w	#$100,$2E(a0)
		rts

; =============== S U B	R O U T	I N E =======================================


sub_16902:				; CODE XREF: ROM:loc_168C0p
		tst.b	$32(a0)
		bne.w	locret_1694E
		move.w	8(a0),d0
		sub.w	(v_objspace+8).w,d0
		move.w	d0,d1
		bpl.s	loc_16918
		neg.w	d0

loc_16918:				; CODE XREF: sub_16902+12j
		cmpi.w	#$28,d0	
		blt.s	locret_1694E
		cmpi.w	#$30,d0	
		bgt.s	locret_1694E
		tst.w	d1
		bpl.s	loc_16932
		btst	#0,1(a0)
		beq.s	locret_1694E
		bra.s	loc_1693A
; ---------------------------------------------------------------------------

loc_16932:				; CODE XREF: sub_16902+24j
		btst	#0,1(a0)
		bne.s	locret_1694E

loc_1693A:				; CODE XREF: sub_16902+2Ej
		st	$32(a0)
		addq.b	#2,$25(a0)
		move.b	#3,$1C(a0)
		move.w	#$32,$34(a0) 

locret_1694E:				; CODE XREF: sub_16902+4j
					; sub_16902+1Aj ...
		rts
; End of function sub_16902

; ---------------------------------------------------------------------------

loc_16950:				; DATA XREF: ROM:000168BEo
		move.w	$34(a0),d0
		subq.w	#1,d0
		blt.s	loc_16964
		move.w	d0,$34(a0)
		cmpi.w	#$14,d0
		beq.s	loc_1696A
		rts
; ---------------------------------------------------------------------------

loc_16964:				; CODE XREF: ROM:00016956j
		subq.b	#2,$25(a0)
		rts
; ---------------------------------------------------------------------------

loc_1696A:				; CODE XREF: ROM:00016960j
		jsr	(S1SingleObjectLoad2).l
		bne.s	locret_169D8
		move.b	#$4B,0(a1) 
		move.b	#6,$24(a1)
		move.l	#Map_Obj4B,4(a1)
		move.w	#$3E6,2(a1)
	if removeJmpTos=1
		jsr	(ModifyA1SpriteAttr_2P).l
	else
		bsr.w	j_ModifyA1SpriteAttr_2P
	endif
		move.b	#4,$18(a1)
		move.b	#$98,$20(a1)
		move.b	#$10,$19(a1)
		move.b	$22(a0),$22(a1)
		move.b	1(a0),1(a1)
		move.b	#2,$1C(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	#$180,$12(a1)
		move.w	#$FE80,$10(a1)
		btst	#0,1(a1)
		beq.s	locret_169D8
		neg.w	$10(a1)

locret_169D8:				; CODE XREF: ROM:00016970j
					; ROM:000169D2j
		rts
; ---------------------------------------------------------------------------
Ani_Obj4B:	dc.w byte_169E2-Ani_Obj4B ; DATA XREF: ROM:000167AEo
					; ROM:000167E6o ...
		dc.w byte_169E5-Ani_Obj4B
		dc.w byte_169E9-Ani_Obj4B
		dc.w byte_169ED-Ani_Obj4B
byte_169E2:	dc.b  $F,  0,$FF	; 0 ; DATA XREF: ROM:Ani_Obj4Bo
byte_169E5:	dc.b   2,  3,  4,$FF	; 0 ; DATA XREF: ROM:000169DCo
byte_169E9:	dc.b   3,  5,  6,$FF	; 0 ; DATA XREF: ROM:000169DEo
byte_169ED:	dc.b   9,  1,  1,  1,  1,  1,$FD,  0,  0; 0 ; DATA XREF: ROM:000169E0o
Map_Obj4B:	dc.w word_16A04-Map_Obj4B ; DATA XREF: ROM:Obj4B_Inito
					; ROM:00016846o ...
		dc.w word_16A16-Map_Obj4B
		dc.w word_16A30-Map_Obj4B
		dc.w word_16A4A-Map_Obj4B
		dc.w word_16A54-Map_Obj4B
		dc.w word_16A5E-Map_Obj4B
		dc.w word_16A68-Map_Obj4B
word_16A04:	dc.w 2			; DATA XREF: ROM:Map_Obj4Bo
		dc.w $F809,    0,    0,$FFE8; 0
		dc.w $F809,    6,    3,	   0; 4
word_16A16:	dc.w 3			; DATA XREF: ROM:000169F8o
		dc.w $F809,    0,    0,$FFE8; 0
		dc.w $F805,   $C,    6,	   0; 4
		dc.w  $805,  $10,    8,	   2; 8
word_16A30:	dc.w 3			; DATA XREF: ROM:000169FAo
		dc.w $F809,    0,    0,$FFE8; 0
		dc.w $F805,   $C,    6,	   0; 4
		dc.w  $805,  $14,   $A,	   2; 8
word_16A4A:	dc.w 1			; DATA XREF: ROM:000169FCo
		dc.w $F001,  $14,   $A,	   4; 0
word_16A54:	dc.w 1			; DATA XREF: ROM:000169FEo
		dc.w $F001,  $16,   $B,	   4; 0
word_16A5E:	dc.w 1			; DATA XREF: ROM:00016A00o
		dc.w $1001,  $18,   $C,	   9; 0
word_16A68:	dc.w 1			; DATA XREF: ROM:00016A02o
		dc.w $1001,  $1A,   $D,	   9; 0
	if removeJmpTos=0
		align 4
	endif	

loc_16A74:				; CODE XREF: ROM:000167C2j
		jmp	DeleteObject
; ---------------------------------------------------------------------------
        if removeJmpTos=0
j_S1SingleObjectLoad2_0:		; CODE XREF: ROM:00016834p
		jmp	S1SingleObjectLoad2
; ---------------------------------------------------------------------------

j_AnimateSprite_4:			; CODE XREF: ROM:000167B4p
					; ROM:000167ECp ...
		jmp	AnimateSprite
; ---------------------------------------------------------------------------

j_ModifyA1SpriteAttr_2P:		; CODE XREF: ROM:00016854p
					; ROM:0001698Cp
		jmp	ModifyA1SpriteAttr_2P
; ---------------------------------------------------------------------------

loc_16A8C:				; CODE XREF: ROM:000167B8j
					; ROM:000167F0j ...
		jmp	loc_CEC6
; ---------------------------------------------------------------------------

j_ModifySpriteAttr_2P_2:		; CODE XREF: ROM:00016802p
		jmp	ModifySpriteAttr_2P
	endif
; ---------------------------------------------------------------------------

j_SpeedToPos_5:				; CODE XREF: ROM:loc_167AAp
					; ROM:000168DAj
		jmp	SpeedToPos

	if removeJmpTos=0
                align 4
        endif
;----------------------------------------------------
; Object 4A - Octopus badnik
;----------------------------------------------------

Obj4A:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj4A_Index(pc,d0.w),d1
		jmp	Obj4A_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj4A_Index:	dc.w loc_16ADE-Obj4A_Index ; DATA XREF:	ROM:Obj4A_Indexo
					; ROM:00016AB0o ...
		dc.w loc_16B44-Obj4A_Index
		dc.w loc_16AD2-Obj4A_Index
		dc.w loc_16AB6-Obj4A_Index
; ---------------------------------------------------------------------------

loc_16AB6:				; DATA XREF: ROM:00016AB4o
		subi.w	#1,$2C(a0)
		bmi.s	loc_16AC0
		rts
; ---------------------------------------------------------------------------

loc_16AC0:				; CODE XREF: ROM:00016ABCj
	if removeJmpTos=1
	        jsr     (ObjectFall).l
	else
		bsr.w	j_ObjectFall_3
	endif
		lea	(Ani_Obj4A).l,a1
	if removeJmpTos=1
                jsr     (AnimateSprite).l
                jmp     (MarkObjGone).l
        else
		bsr.w	j_AnimateSprite_5
		bra.w	loc_16D3C
	endif
; ---------------------------------------------------------------------------

loc_16AD2:				; DATA XREF: ROM:00016AB2o
		subq.w	#1,$2C(a0)
		beq.w	loc_16D36
	if removeJmpTos=1
		jmp     (DisplaySprite).l
        else
                bra.w	loc_16D30
        endif
; ---------------------------------------------------------------------------

loc_16ADE:				; DATA XREF: ROM:Obj4A_Indexo
		move.l	#Map_Obj4A,4(a0)
		move.w	#$238A,2(a0)
		ori.b	#4,1(a0)
		move.b	#$A,$20(a0)
		move.b	#4,$18(a0)
		move.b	#$10,$19(a0)
		move.b	#$10,$16(a0)
		move.b	#8,$17(a0)
	if removeJmpTos=1
	        jsr     (ObjectFall).l
	else
		bsr.w	j_ObjectFall_3
	endif
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	loc_16B3C
		add.w	d1,$C(a0)
		move.w	#0,$12(a0)
		addq.b	#2,$24(a0)
		move.w	8(a0),d0
		sub.w	(v_objspace+8).w,d0
		bpl.s	loc_16B3C
		bchg	#0,$22(a0)

loc_16B3C:				; CODE XREF: ROM:00016B1Cj
					; ROM:00016B34j
		move.w	$C(a0),$2A(a0)
		rts
; ---------------------------------------------------------------------------

loc_16B44:				; DATA XREF: ROM:00016AB0o
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	Obj4A_SubIndex(pc,d0.w),d1
		jsr	Obj4A_SubIndex(pc,d1.w)
		lea	(Ani_Obj4A).l,a1
	if removeJmpTos=1
                jsr     (AnimateSprite).l
                jmp     (MarkObjGone).l
        else
		bsr.w	j_AnimateSprite_5
		bra.w	loc_16D3C
	endif
; ---------------------------------------------------------------------------
Obj4A_SubIndex:	dc.w Obj4A_Init-Obj4A_SubIndex ; DATA XREF: ROM:Obj4A_SubIndexo
					; ROM:00016B62o ...
		dc.w Obj4A_Main-Obj4A_SubIndex
		dc.w loc_16BAA-Obj4A_SubIndex
		dc.w loc_16C7C-Obj4A_SubIndex
; ---------------------------------------------------------------------------

Obj4A_Init:				; DATA XREF: ROM:Obj4A_SubIndexo
		move.w	8(a0),d0
		sub.w	(v_objspace+8).w,d0
		cmpi.w	#$80,d0
		bgt.s	locret_16B86
		cmpi.w	#$FF80,d0
		blt.s	locret_16B86
		addq.b	#2,$25(a0)
		move.b	#1,$1C(a0)

locret_16B86:				; CODE XREF: ROM:00016B74j
					; ROM:00016B7Aj
		rts
; ---------------------------------------------------------------------------

Obj4A_Main:				; DATA XREF: ROM:00016B62o
		subi.l	#$18000,$C(a0)
		move.w	$2A(a0),d0
		sub.w	$C(a0),d0
		cmpi.w	#$20,d0
		ble.s	locret_16BA8
		addq.b	#2,$25(a0)
		move.w	#0,$2C(a0)

locret_16BA8:				; CODE XREF: ROM:00016B9Cj
		rts
; ---------------------------------------------------------------------------

loc_16BAA:				; DATA XREF: ROM:00016B64o
		subi.w	#1,$2C(a0)
		beq.w	loc_16C76
		bpl.w	locret_16C74
		move.w	#$1E,$2C(a0)
		jsr	(SingleObjectLoad).l
		bne.s	loc_16C10
		move.b	#$4A,0(a1) 
		move.b	#4,$24(a1)
		move.l	#Map_Obj4A,4(a1)
		move.b	#4,$1A(a1)
		move.w	#$24C6,2(a1)
		move.b	#3,$18(a1)
		move.b	#$10,$19(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	#$1E,$2C(a1)
		move.b	1(a0),1(a1)
		move.b	$22(a0),$22(a1)

loc_16C10:				; CODE XREF: ROM:00016BC4j
		jsr	(SingleObjectLoad).l
		bne.s	locret_16C74
		move.b	#$4A,0(a1) 
		move.b	#6,$24(a1)
		move.l	#Map_Obj4A,4(a1)
		move.w	#$24C6,2(a1)
		move.b	#4,$18(a1)
		move.b	#$10,$19(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	#$F,$2C(a1)
		move.b	1(a0),1(a1)
		move.b	$22(a0),$22(a1)
		move.b	#2,$1C(a1)
		move.w	#$FA80,$10(a1)
		btst	#0,1(a1)
		beq.s	locret_16C74
		neg.w	$10(a1)

locret_16C74:				; CODE XREF: ROM:00016BB4j
					; ROM:00016C16j ...
		rts
; ---------------------------------------------------------------------------

loc_16C76:				; CODE XREF: ROM:00016BB0j
		addq.b	#2,$25(a0)
		rts
; ---------------------------------------------------------------------------

loc_16C7C:				; DATA XREF: ROM:00016B66o
		move.w	#$FFFA,d0
		btst	#0,1(a0)
		beq.s	loc_16C8A
		neg.w	d0

loc_16C8A:				; CODE XREF: ROM:00016C86j
		add.w	d0,8(a0)
	if removeJmpTos=1
                jmp     (MarkObjGone).l
        else
		bra.w	loc_16D3C
	endif
; ---------------------------------------------------------------------------
Ani_Obj4A:	dc.w byte_16C98-Ani_Obj4A ; DATA XREF: ROM:00016AC4o
					; ROM:00016B52o ...
		dc.w byte_16C9B-Ani_Obj4A
		dc.w byte_16CA0-Ani_Obj4A
byte_16C98:	dc.b  $F,  0,$FF	; 0 ; DATA XREF: ROM:Ani_Obj4Ao
byte_16C9B:	dc.b   3,  1,  2,  3,$FF; 0 ; DATA XREF: ROM:00016C94o
byte_16CA0:	dc.b   2,  5,  6,$FF	; 0 ; DATA XREF: ROM:00016C96o
Map_Obj4A:	dc.w word_16CB2-Map_Obj4A ; DATA XREF: ROM:loc_16ADEo
					; ROM:00016BD2o ...
		dc.w word_16CC4-Map_Obj4A
		dc.w word_16CDE-Map_Obj4A
		dc.w word_16CF8-Map_Obj4A
		dc.w word_16D12-Map_Obj4A
		dc.w word_16D1C-Map_Obj4A
		dc.w word_16D26-Map_Obj4A
word_16CB2:	dc.w 2			; DATA XREF: ROM:Map_Obj4Ao
		dc.w $F00D,    0,    0,$FFF0; 0
		dc.w	$D,    8,    4,$FFF0; 4
word_16CC4:	dc.w 3			; DATA XREF: ROM:00016CA6o
		dc.w $F00D,    0,    0,$FFF0; 0
		dc.w	 9,  $10,    8,$FFE8; 4
		dc.w	 9,  $16,   $B,	   0; 8
word_16CDE:	dc.w 3			; DATA XREF: ROM:00016CA8o
		dc.w $F00D,    0,    0,$FFF0; 0
		dc.w	 9,  $1C,   $E,$FFE8; 4
		dc.w	 9,  $22,  $11,	   0; 8
word_16CF8:	dc.w 3			; DATA XREF: ROM:00016CAAo
		dc.w $F00D,    0,    0,$FFF0; 0
		dc.w	 9,  $28,  $14,$FFE8; 4
		dc.w	 9,  $2E,  $17,	   0; 8
word_16D12:	dc.w 1			; DATA XREF: ROM:00016CACo
		dc.w $F001,  $34,  $1A,$FFF7; 0
word_16D1C:	dc.w 1			; DATA XREF: ROM:00016CAEo
		dc.w $F201,  $36,  $1B,$FFF0; 0
word_16D26:	dc.w 1			; DATA XREF: ROM:00016CB0o
		dc.w $F201,  $38,  $1C,$FFF0; 0
; ---------------------------------------------------------------------------

        if removeJmpTos=0
loc_16D30:				; CODE XREF: ROM:00016ADAj
		jmp	DisplaySprite
	endif
; ---------------------------------------------------------------------------

loc_16D36:				; CODE XREF: ROM:00016AD6j
		jmp	DeleteObject
; ---------------------------------------------------------------------------
        if removeJmpTos=0
loc_16D3C:				; CODE XREF: ROM:00016ACEj
					; ROM:00016B5Cj ...
		jmp	MarkObjGone
; ---------------------------------------------------------------------------

j_AnimateSprite_5:			; CODE XREF: ROM:00016ACAp
					; ROM:00016B58p
		jmp	AnimateSprite
; ---------------------------------------------------------------------------

j_ObjectFall_3:				; CODE XREF: ROM:loc_16AC0p
					; ROM:00016B10p
		jmp	ObjectFall

		align 4
	endif
;----------------------------------------------------
; Object 4C - Bat badnik from HPZ
;----------------------------------------------------

Obj4C:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj4C_Index(pc,d0.w),d1
		jmp	Obj4C_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj4C_Index:	dc.w Obj4C_Init-Obj4C_Index ; DATA XREF: ROM:Obj4C_Indexo
					; ROM:00016D60o ...
		dc.w loc_16DA2-Obj4C_Index
		dc.w loc_16E10-Obj4C_Index
; ---------------------------------------------------------------------------

Obj4C_Init:				; DATA XREF: ROM:Obj4C_Indexo
		move.l	#Map_Obj4C,4(a0)
		move.w	#$2530,2(a0)
		ori.b	#4,1(a0)
		move.b	#$A,$20(a0)
		move.b	#4,$18(a0)
		move.b	#$10,$19(a0)
		move.b	#$10,$16(a0)
		move.b	#8,$17(a0)
		addq.b	#2,$24(a0)
		move.w	$C(a0),$2E(a0)
		rts
; ---------------------------------------------------------------------------

loc_16DA2:				; DATA XREF: ROM:00016D60o
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	Obj4C_SubIndex(pc,d0.w),d1
		jsr	Obj4C_SubIndex(pc,d1.w)
		bsr.w	sub_16DC8
		lea	(Ani_Obj4C).l,a1
	if removeJmpTos=0
		bsr.w	j_AnimateSprite_6
		bra.w	loc_171C4
	else
		jsr	(AnimateSprite).l
		jmp     (MarkObjGone).l
	endif
; ---------------------------------------------------------------------------
Obj4C_SubIndex:	dc.w loc_16F2E-Obj4C_SubIndex ;	DATA XREF: ROM:Obj4C_SubIndexo
					; ROM:00016DC4o ...
		dc.w loc_16F66-Obj4C_SubIndex
		dc.w loc_16F72-Obj4C_SubIndex

; =============== S U B	R O U T	I N E =======================================


sub_16DC8:				; CODE XREF: ROM:00016DB0p
		move.b	$3F(a0),d0
		jsr	(CalcSine).l
		asr.w	#6,d0
		add.w	$2E(a0),d0
		move.w	d0,$C(a0)
		addq.b	#4,$3F(a0)
		rts
; End of function sub_16DC8


; =============== S U B	R O U T	I N E =======================================


sub_16DE2:				; CODE XREF: ROM:00016F36p
		move.w	8(a0),d0
		sub.w	(v_objspace+8).w,d0
		cmpi.w	#$80,d0
		bgt.s	locret_16E0E
		cmpi.w	#$FF80,d0
		blt.s	locret_16E0E
		move.b	#4,$25(a0)
		move.b	#2,$1C(a0)
		move.w	#8,$2A(a0)
		move.b	#0,$3E(a0)

locret_16E0E:				; CODE XREF: sub_16DE2+Cj
					; sub_16DE2+12j
		rts
; End of function sub_16DE2

; ---------------------------------------------------------------------------

loc_16E10:				; DATA XREF: ROM:00016D62o
		bsr.w	sub_16F0E
		bsr.w	sub_16EB0
		bsr.w	sub_16E30
	if removeJmpTos=0
		bsr.w	j_SpeedToPos_8
	else
                jsr	(SpeedToPos).l
        endif
		lea	(Ani_Obj4C).l,a1
	if removeJmpTos=0
		bsr.w	j_AnimateSprite_6
	else
                jsr	(AnimateSprite).l
        endif

        if removeJmpTos=0
		bra.w	loc_171C4
	else
                jmp	(MarkObjGone).l
        endif
; ---------------------------------------------------------------------------
		rts

; =============== S U B	R O U T	I N E =======================================


sub_16E30:				; CODE XREF: ROM:00016E18p
		tst.b	$3D(a0)
		beq.s	locret_16E42
		bset	#0,1(a0)
		bset	#0,$22(a0)

locret_16E42:				; CODE XREF: sub_16E30+4j
		rts
; End of function sub_16E30


; =============== S U B	R O U T	I N E =======================================


sub_16E44:				; CODE XREF: ROM:loc_16F72p
		subi.w	#1,$2C(a0)
		bpl.s	locret_16E8E
		move.w	8(a0),d0
		sub.w	(v_objspace+8).w,d0
		cmpi.w	#$60,d0
		bgt.s	loc_16E90
		cmpi.w	#$FFA0,d0
		blt.s	loc_16E90
		tst.w	d0
		bpl.s	loc_16E68
		st	$3D(a0)

loc_16E68:				; CODE XREF: sub_16E44+1Ej
		move.b	#$40,$3F(a0)
		move.w	#$400,$14(a0)
		move.b	#4,$24(a0)
		move.b	#3,$1C(a0)
		move.w	#$C,$2A(a0)
		move.b	#1,$3E(a0)
		moveq	#0,d0

locret_16E8E:				; CODE XREF: sub_16E44+6j
					; sub_16E44+56j
		rts
; ---------------------------------------------------------------------------

loc_16E90:				; CODE XREF: sub_16E44+14j
					; sub_16E44+1Aj
		cmpi.w	#$80,d0
		bgt.s	loc_16E9C
		cmpi.w	#$FF80,d0
		bgt.s	locret_16E8E

loc_16E9C:				; CODE XREF: sub_16E44+50j
		move.b	#1,$1C(a0)
		move.b	#0,$25(a0)
		move.w	#$18,$2A(a0)
		rts
; End of function sub_16E44


; =============== S U B	R O U T	I N E =======================================


sub_16EB0:				; CODE XREF: ROM:00016E14p
		tst.b	$3D(a0)
		bne.s	loc_16ECA
		moveq	#0,d0
		move.b	$3F(a0),d0
		cmpi.w	#$C0,d0	
		bge.s	loc_16EDE
		addq.b	#2,d0
		move.b	d0,$3F(a0)
		rts
; ---------------------------------------------------------------------------

loc_16ECA:				; CODE XREF: sub_16EB0+4j
		moveq	#0,d0
		move.b	$3F(a0),d0
		cmpi.w	#$C0,d0	
		beq.s	loc_16EDE
		subq.b	#2,d0
		move.b	d0,$3F(a0)
		rts
; ---------------------------------------------------------------------------

loc_16EDE:				; CODE XREF: sub_16EB0+10j
					; sub_16EB0+24j
		sf	$3D(a0)
		move.b	#0,$1C(a0)
		move.b	#2,$24(a0)
		move.b	#0,$25(a0)
		move.w	#$18,$2A(a0)
		move.b	#1,$1C(a0)
		bclr	#0,1(a0)
		bclr	#0,$22(a0)
		rts
; End of function sub_16EB0


; =============== S U B	R O U T	I N E =======================================


sub_16F0E:				; CODE XREF: ROM:loc_16E10p
		move.b	$3F(a0),d0
		jsr	(CalcSine).l
		muls.w	$14(a0),d1
		asr.l	#8,d1
		move.w	d1,$10(a0)
		muls.w	$14(a0),d0
		asr.l	#8,d0
		move.w	d0,$12(a0)
		rts
; End of function sub_16F0E

; ---------------------------------------------------------------------------

loc_16F2E:				; DATA XREF: ROM:Obj4C_SubIndexo
		subi.w	#1,$2A(a0)
		bpl.s	locret_16F64
		bsr.w	sub_16DE2
		beq.s	locret_16F64
		jsr	(PseudoRandomNumber).l
		andi.b	#$FF,d0
		bne.s	locret_16F64
		move.w	#$18,$2A(a0)
		move.w	#$1E,$2C(a0)
		addq.b	#2,$25(a0)
		move.b	#1,$1C(a0)
		move.b	#0,$3E(a0)

locret_16F64:				; CODE XREF: ROM:00016F34j
					; ROM:00016F3Aj ...
		rts
; ---------------------------------------------------------------------------

loc_16F66:				; DATA XREF: ROM:00016DC4o
		subq.b	#1,$2A(a0)
		bpl.s	locret_16F70
		subq.b	#2,$25(a0)

locret_16F70:				; CODE XREF: ROM:00016F6Aj
		rts
; ---------------------------------------------------------------------------

loc_16F72:				; DATA XREF: ROM:00016DC6o
		bsr.w	sub_16E44
		beq.s	locret_16FB8
		subi.w	#1,$2A(a0)
		bne.s	locret_16FB8
		move.b	$3E(a0),d0
		beq.s	loc_16FA0
		move.b	#0,$3E(a0)
		move.w	#8,$2A(a0)
		bset	#0,1(a0)
		bset	#0,$22(a0)
		rts
; ---------------------------------------------------------------------------

loc_16FA0:				; CODE XREF: ROM:00016F84j
		move.b	#1,$3E(a0)
		move.w	#$C,$2A(a0)
		bclr	#0,1(a0)
		bclr	#0,$22(a0)

locret_16FB8:				; CODE XREF: ROM:00016F76j
					; ROM:00016F7Ej
		rts
; ---------------------------------------------------------------------------
Ani_Obj4C:	dc.w byte_16FC2-Ani_Obj4C ; DATA XREF: ROM:00016DB4o
					; ROM:00016E20o ...
		dc.w byte_16FC6-Ani_Obj4C
		dc.w byte_16FD5-Ani_Obj4C
		dc.w byte_16FE6-Ani_Obj4C
byte_16FC2:	dc.b   1,  0,  5,$FF	; 0 ; DATA XREF: ROM:Ani_Obj4Co
byte_16FC6:	dc.b   1,  1,  6,  1,  6,  2,  7,  2,  7,  1,  6,  1,  6,$FD,  0; 0
					; DATA XREF: ROM:00016FBCo
byte_16FD5:	dc.b   1,  1,  6,  1,  6,  2,  7,  3,  8,  4,  9,  4,  9,  3,  8,$FE; 0
					; DATA XREF: ROM:00016FBEo
		dc.b  $A		; 16
byte_16FE6:	dc.b   3, $A, $B, $C, $D, $E,$FF,  0; 0	; DATA XREF: ROM:00016FC0o
Map_Obj4C:	dc.w word_1700C-Map_Obj4C ; DATA XREF: ROM:Obj4C_Inito
					; ROM:Map_Obj4Co ...
		dc.w word_1702E-Map_Obj4C
		dc.w word_17050-Map_Obj4C
		dc.w word_17072-Map_Obj4C
		dc.w word_17094-Map_Obj4C
		dc.w word_170AE-Map_Obj4C
		dc.w word_170D0-Map_Obj4C
		dc.w word_170F2-Map_Obj4C
		dc.w word_17114-Map_Obj4C
		dc.w word_17136-Map_Obj4C
		dc.w word_17150-Map_Obj4C
		dc.w word_1716A-Map_Obj4C
		dc.w word_17184-Map_Obj4C
		dc.w word_17196-Map_Obj4C
		dc.w word_171A8-Map_Obj4C
word_1700C:	dc.w 4			; DATA XREF: ROM:Map_Obj4Co
		dc.w $F005,    0,    0,$FFF8; 0
		dc.w	 5,    4,    2,$FFF8; 4
		dc.w $F00B,    8,    4,	   5; 8
		dc.w $F00B, $808, $804,$FFE3; 12
word_1702E:	dc.w 4			; DATA XREF: ROM:00016FF0o
		dc.w $F005,    0,    0,$FFF8; 0
		dc.w	 5,    4,    2,$FFF8; 4
		dc.w $F60D,  $14,   $A,	   5; 8
		dc.w $F60D, $814, $80A,$FFDB; 12
word_17050:	dc.w 4			; DATA XREF: ROM:00016FF2o
		dc.w $F005,    0,    0,$FFF8; 0
		dc.w	 5,    4,    2,$FFF8; 4
		dc.w $F80D,  $1C,   $E,	   4; 8
		dc.w $F80D, $81C, $80E,$FFDC; 12
word_17072:	dc.w 4			; DATA XREF: ROM:00016FF4o
		dc.w $F005,    0,    0,$FFF8; 0
		dc.w	 5,    4,    2,$FFF8; 4
		dc.w $F805,  $24,  $12,$FFEC; 8
		dc.w $F805,  $28,  $14,	   4; 12
word_17094:	dc.w 3			; DATA XREF: ROM:00016FF6o
		dc.w $F801,  $2C,  $16,	   0; 0
		dc.w $F005,    0,    0,$FFF8; 4
		dc.w	 5,    4,    2,$FFF8; 8
word_170AE:	dc.w 4			; DATA XREF: ROM:00016FF8o
		dc.w $F005,    0,    0,$FFF8; 0
		dc.w	 5,  $2E,  $17,$FFF8; 4
		dc.w $F00B,    8,    4,	   5; 8
		dc.w $F00B, $808, $804,$FFE3; 12
word_170D0:	dc.w 4			; DATA XREF: ROM:00016FFAo
		dc.w $F005,    0,    0,$FFF8; 0
		dc.w	 5,  $2E,  $17,$FFF8; 4
		dc.w $F60D,  $14,   $A,	   5; 8
		dc.w $F60D, $814, $80A,$FFDB; 12
word_170F2:	dc.w 4			; DATA XREF: ROM:00016FFCo
		dc.w $F005,    0,    0,$FFF8; 0
		dc.w	 5,  $2E,  $17,$FFF8; 4
		dc.w $F80D,  $1C,   $E,	   4; 8
		dc.w $F80D, $81C, $80E,$FFDC; 12
word_17114:	dc.w 4			; DATA XREF: ROM:00016FFEo
		dc.w $F005,    0,    0,$FFF8; 0
		dc.w	 5,  $2E,  $17,$FFF8; 4
		dc.w $F805,  $28,  $14,	   4; 8
		dc.w $F805,  $24,  $12,$FFEC; 12
word_17136:	dc.w 3			; DATA XREF: ROM:00017000o
		dc.w $F801,  $2C,  $16,	   0; 0
		dc.w $F005,    0,    0,$FFF8; 4
		dc.w	 5,  $2E,  $17,$FFF8; 8
word_17150:	dc.w 3			; DATA XREF: ROM:00017002o
		dc.w $F007,  $32,  $19,$FFF8; 0
		dc.w $F80D,  $1C,   $E,	   4; 4
		dc.w $F80D, $81C, $80E,$FFDC; 8
word_1716A:	dc.w 3			; DATA XREF: ROM:00017004o
		dc.w $F007,  $32,  $19,$FFF8; 0
		dc.w $F805,  $28,  $14,	   4; 4
		dc.w $F805,  $24,  $12,$FFEC; 8
word_17184:	dc.w 2			; DATA XREF: ROM:00017006o
		dc.w $F801,  $2C,  $16,	   0; 0
		dc.w $F007,  $32,  $19,$FFF8; 4
word_17196:	dc.w 2			; DATA XREF: ROM:00017008o
		dc.w $F801, $82C, $816,$FFF8; 0
		dc.w $F007,  $32,  $19,$FFF8; 4
word_171A8:	dc.w 3			; DATA XREF: ROM:0001700Ao
		dc.w $F007,  $32,  $19,$FFF8; 0
		dc.w $F805, $828, $814,$FFEC; 4
		dc.w $F805, $824, $812,	   4; 8
	if removeJmpTos=0
                align 4
loc_171C4:				; CODE XREF: ROM:00016DBEj
					; ROM:00016E2Aj
		jmp	MarkObjGone
; ---------------------------------------------------------------------------

j_AnimateSprite_6:			; CODE XREF: ROM:00016DBAp
					; ROM:00016E26p
		jmp	AnimateSprite
; ---------------------------------------------------------------------------

j_SpeedToPos_8:				; CODE XREF: ROM:00016E1Cp
		jmp	SpeedToPos
; ---------------------------------------------------------------------------
		align 4
	endif
;----------------------------------------------------
; Object 4E - Aligator badnik from HPZ
;----------------------------------------------------

Obj4E:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj4E_Index(pc,d0.w),d1
		jmp	Obj4E_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj4E_Index:	dc.w Obj4E_Init-Obj4E_Index ; DATA XREF: ROM:Obj4E_Indexo
					; ROM:000171E8o
		dc.w Obj4E_Main-Obj4E_Index
; ---------------------------------------------------------------------------

Obj4E_Init:				; DATA XREF: ROM:Obj4E_Indexo
		move.l	#Map_Obj4E,4(a0)
		move.w	#$2300,2(a0)
		ori.b	#4,1(a0)
		move.b	#$A,$20(a0)
		move.b	#4,$18(a0)
		move.b	#$10,$19(a0)
		move.b	#$10,$16(a0)
		move.b	#8,$17(a0)
		bsr.w	j_ObjectFall_4
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	locret_17238
		add.w	d1,$C(a0)
		move.w	#0,$12(a0)
		addq.b	#2,$24(a0)

locret_17238:				; CODE XREF: ROM:00017228j
		rts
; ---------------------------------------------------------------------------

Obj4E_Main:				; DATA XREF: ROM:000171E8o
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	Obj4E_SubIndex(pc,d0.w),d1
		jsr	Obj4E_SubIndex(pc,d1.w)
		lea	(Ani_Obj4E).l,a1
		bsr.w	j_AnimateSprite_7
		bra.w	loc_174B8
; ---------------------------------------------------------------------------
Obj4E_SubIndex:	dc.w loc_1725A-Obj4E_SubIndex ;	DATA XREF: ROM:Obj4E_SubIndexo
					; ROM:00017258o
		dc.w loc_1727E-Obj4E_SubIndex
; ---------------------------------------------------------------------------

loc_1725A:				; DATA XREF: ROM:Obj4E_SubIndexo
		subq.w	#1,$30(a0)
		bpl.s	locret_1727C
		addq.b	#2,$25(a0)
		move.w	#$FF40,$10(a0)
		move.b	#0,$1C(a0)
		bchg	#0,$22(a0)
		bne.s	locret_1727C
		neg.w	$10(a0)

locret_1727C:				; CODE XREF: ROM:0001725Ej
					; ROM:00017276j
		rts
; ---------------------------------------------------------------------------

loc_1727E:				; DATA XREF: ROM:00017258o
		bsr.w	sub_172B6
		bsr.w	j_SpeedToPos_6
		jsr	(ObjHitFloor).l
		cmpi.w	#$FFF8,d1
		blt.s	loc_1729E
		cmpi.w	#$C,d1
		bge.s	loc_1729E
		add.w	d1,$C(a0)
		rts
; ---------------------------------------------------------------------------

loc_1729E:				; CODE XREF: ROM:00017290j
					; ROM:00017296j
		subq.b	#2,$25(a0)
		move.w	#$3B,$30(a0) 
		move.w	#0,$10(a0)
		move.b	#1,$1C(a0)
		rts

; =============== S U B	R O U T	I N E =======================================


sub_172B6:				; CODE XREF: ROM:loc_1727Ep
		move.w	8(a0),d0
		sub.w	(v_objspace+8).w,d0
		bmi.s	loc_172D0
		cmpi.w	#$40,d0	
		bgt.s	loc_172E6
		btst	#0,$22(a0)
		beq.s	loc_172DE
		rts
; ---------------------------------------------------------------------------

loc_172D0:				; CODE XREF: sub_172B6+8j
		cmpi.w	#$FFC0,d0
		blt.s	loc_172E6
		btst	#0,$22(a0)
		beq.s	loc_172E6

loc_172DE:				; CODE XREF: sub_172B6+16j
		move.b	#2,$1C(a0)
		rts
; ---------------------------------------------------------------------------

loc_172E6:				; CODE XREF: sub_172B6+Ej
					; sub_172B6+1Ej ...
		move.b	#0,$1C(a0)
		rts
; End of function sub_172B6

; ---------------------------------------------------------------------------
Ani_Obj4E:	dc.w byte_172F4-Ani_Obj4E ; DATA XREF: ROM:00017248o
					; ROM:Ani_Obj4Eo ...
		dc.w byte_172FC-Ani_Obj4E
		dc.w byte_172FF-Ani_Obj4E
byte_172F4:	dc.b   3,  0,  4,  2,  3,  1,  5,$FF; 0	; DATA XREF: ROM:Ani_Obj4Eo
byte_172FC:	dc.b  $F,  0,$FF	; 0 ; DATA XREF: ROM:000172F0o
byte_172FF:	dc.b   3,  6, $A,  8,  9,  7, $B,$FF,  0; 0 ; DATA XREF: ROM:000172F2o
Map_Obj4E:	dc.w word_17320-Map_Obj4E ; DATA XREF: ROM:Obj4E_Inito
					; ROM:Map_Obj4Eo ...
		dc.w word_17342-Map_Obj4E
		dc.w word_17364-Map_Obj4E
		dc.w word_17386-Map_Obj4E
		dc.w word_173A8-Map_Obj4E
		dc.w word_173CA-Map_Obj4E
		dc.w word_173EC-Map_Obj4E
		dc.w word_1740E-Map_Obj4E
		dc.w word_17430-Map_Obj4E
		dc.w word_17452-Map_Obj4E
		dc.w word_17474-Map_Obj4E
		dc.w word_17496-Map_Obj4E
word_17320:	dc.w 4			; DATA XREF: ROM:Map_Obj4Eo
		dc.w $F80E,    0,    0,$FFE4; 0
		dc.w $F805,  $18,   $C,	   4; 4
		dc.w	 1,  $1C,   $E,	   4; 8
		dc.w	 5,  $20,  $10,	  $C; 12
word_17342:	dc.w 4			; DATA XREF: ROM:0001730Ao
		dc.w $F80E,    0,    0,$FFE4; 0
		dc.w $F805,  $18,   $C,	   4; 4
		dc.w	 1,  $1C,   $E,	   4; 8
		dc.w	 5,  $24,  $12,	  $C; 12
word_17364:	dc.w 4			; DATA XREF: ROM:0001730Co
		dc.w $F80E,    0,    0,$FFE4; 0
		dc.w $F805,  $18,   $C,	   4; 4
		dc.w	 1,  $1C,   $E,	   4; 8
		dc.w	 5,  $28,  $14,	  $C; 12
word_17386:	dc.w 4			; DATA XREF: ROM:0001730Eo
		dc.w $F80E,    0,    0,$FFE4; 0
		dc.w $F805,  $18,   $C,	   4; 4
		dc.w	 1,  $1E,   $F,	   4; 8
		dc.w	 5,  $20,  $10,	  $C; 12
word_173A8:	dc.w 4			; DATA XREF: ROM:00017310o
		dc.w $F80E,    0,    0,$FFE4; 0
		dc.w $F805,  $18,   $C,	   4; 4
		dc.w	 1,  $1E,   $F,	   4; 8
		dc.w	 5,  $24,  $12,	  $C; 12
word_173CA:	dc.w 4			; DATA XREF: ROM:00017312o
		dc.w $F80E,    0,    0,$FFE4; 0
		dc.w $F805,  $18,   $C,	   4; 4
		dc.w	 1,  $1E,   $F,	   4; 8
		dc.w	 5,  $28,  $14,	  $C; 12
word_173EC:	dc.w 4			; DATA XREF: ROM:00017314o
		dc.w $F00B,   $C,    6,$FFEC; 0
		dc.w $F805,  $18,   $C,	   4; 4
		dc.w	 1,  $1C,   $E,	   4; 8
		dc.w	 5,  $20,  $10,	  $C; 12
word_1740E:	dc.w 4			; DATA XREF: ROM:00017316o
		dc.w $F00B,   $C,    6,$FFEC; 0
		dc.w $F805,  $18,   $C,	   4; 4
		dc.w	 1,  $1C,   $E,	   4; 8
		dc.w	 5,  $24,  $12,	  $C; 12
word_17430:	dc.w 4			; DATA XREF: ROM:00017318o
		dc.w $F00B,   $C,    6,$FFEC; 0
		dc.w $F805,  $18,   $C,	   4; 4
		dc.w	 1,  $1C,   $E,	   4; 8
		dc.w	 5,  $28,  $14,	  $C; 12
word_17452:	dc.w 4			; DATA XREF: ROM:0001731Ao
		dc.w $F00B,   $C,    6,$FFEC; 0
		dc.w $F805,  $18,   $C,	   4; 4
		dc.w	 1,  $1E,   $F,	   4; 8
		dc.w	 5,  $20,  $10,	  $C; 12
word_17474:	dc.w 4			; DATA XREF: ROM:0001731Co
		dc.w $F00B,   $C,    6,$FFEC; 0
		dc.w $F805,  $18,   $C,	   4; 4
		dc.w	 1,  $1E,   $F,	   4; 8
		dc.w	 5,  $24,  $12,	  $C; 12
word_17496:	dc.w 4			; DATA XREF: ROM:0001731Eo
		dc.w $F00B,   $C,    6,$FFEC; 0
		dc.w $F805,  $18,   $C,	   4; 4
		dc.w	 1,  $1E,   $F,	   4; 8
		dc.w	 5,  $28,  $14,	  $C; 12
; ---------------------------------------------------------------------------

loc_174B8:				; CODE XREF: ROM:00017252j
		jmp	MarkObjGone
; ---------------------------------------------------------------------------

j_AnimateSprite_7:			; CODE XREF: ROM:0001724Ep
		jmp	AnimateSprite
; ---------------------------------------------------------------------------

j_ObjectFall_4:				; CODE XREF: ROM:0001721Cp
		jmp	ObjectFall
; ---------------------------------------------------------------------------

j_SpeedToPos_6:				; CODE XREF: ROM:00017282p
		jmp	SpeedToPos
; ---------------------------------------------------------------------------

Obj53:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0

loc_174D2:
		move.b	$24(a0),d0
		move.w	Obj53_Index(pc,d0.w),d1
		jsr	Obj53_Index(pc,d1.w)
		bra.w	loc_175B8
; ---------------------------------------------------------------------------
Obj53_Index:	dc.w Obj53_Init-Obj53_Index ; DATA XREF: ROM:Obj53_Indexo
					; ROM:000174E4o
		dc.w Obj53_Main-Obj53_Index
; ---------------------------------------------------------------------------

Obj53_Init:				; DATA XREF: ROM:Obj53_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj53,4(a0)
		move.w	#$41C,2(a0)
		bsr.w	j_ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#9,$20(a0)
		move.b	#$10,$19(a0)
		move.w	#$FC00,$12(a0)
		move.w	$C(a0),$30(a0)

Obj53_Main:				; DATA XREF: ROM:000174E4o
		lea	(Ani_Obj53).l,a1
		bsr.w	j_AnimateSprite
		bsr.w	j_SpeedToPos
		addi.w	#$18,$12(a0)
		move.w	$30(a0),d0
		cmp.w	$C(a0),d0
		bcc.s	loc_17548
		move.w	d0,$C(a0)
		move.w	#$FB00,$12(a0)

loc_17548:				; CODE XREF: ROM:0001753Cj
		move.b	#1,$1C(a0)
		subi.w	#$C0,d0
		cmp.w	$C(a0),d0
		bcc.s	locret_1756A
		move.b	#0,$1C(a0)
		tst.w	$12(a0)
		bmi.s	locret_1756A
		move.b	#2,$1C(a0)

locret_1756A:				; CODE XREF: ROM:00017556j
					; ROM:00017562j
		rts
; ---------------------------------------------------------------------------
Ani_Obj53:	dc.w byte_17572-Ani_Obj53 ; DATA XREF: ROM:Obj53_Maino
					; ROM:Ani_Obj53o ...
		dc.w byte_17576-Ani_Obj53
		dc.w byte_1757A-Ani_Obj53
byte_17572:	dc.b   7,  0,  1,$FF	; 0 ; DATA XREF: ROM:Ani_Obj53o
byte_17576:	dc.b   3,  0,  1,$FF	; 0 ; DATA XREF: ROM:0001756Eo
byte_1757A:	dc.b   7,  0,$FF,  0	; 0 ; DATA XREF: ROM:00017570o
Map_Obj53:	dc.w word_17582-Map_Obj53 ; DATA XREF: ROM:000174EAo
					; ROM:Map_Obj53o ...
		dc.w word_1759C-Map_Obj53
word_17582:	dc.w 3			; DATA XREF: ROM:Map_Obj53o
		dc.w $F005,    0,    0,$FFF4; 0
		dc.w $F001,    4,    2,	   4; 4
		dc.w	 9,   $A,    5,$FFF4; 8
word_1759C:	dc.w 3			; DATA XREF: ROM:00017580o
		dc.w $F005,    0,    0,$FFF4; 0
		dc.w $F005,    6,    3,	   2; 4
		dc.w	 9,  $10,    8,$FFF4; 8
		dc.w	 0		; 12
; ---------------------------------------------------------------------------

loc_175B8:				; CODE XREF: ROM:000174DEj
		jmp	MarkObjGone
; ---------------------------------------------------------------------------

j_AnimateSprite:			; CODE XREF: ROM:00017526p
		jmp	AnimateSprite
; ---------------------------------------------------------------------------

j_ModifySpriteAttr_2P:			; CODE XREF: ROM:000174F8p
		jmp	ModifySpriteAttr_2P
; ---------------------------------------------------------------------------

j_SpeedToPos:				; CODE XREF: ROM:0001752Ap
		jmp	SpeedToPos
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 54 - Snail badnik from	EHZ
;----------------------------------------------------

Obj54:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj54_Index(pc,d0.w),d1
		jmp	Obj54_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj54_Index:	dc.w Obj54_Init-Obj54_Index ; DATA XREF: ROM:Obj54_Indexo
					; ROM:000175E0o ...
		dc.w loc_17688-Obj54_Index
		dc.w loc_177B4-Obj54_Index
		dc.w loc_177EC-Obj54_Index
		dc.w loc_17772-Obj54_Index
; ---------------------------------------------------------------------------

Obj54_Init:				; DATA XREF: ROM:Obj54_Indexo
		move.l	#Map_Obj54,4(a0)
		move.w	#$402,2(a0)
		bsr.w	j_ModifySpriteAttr_2P_3
		ori.b	#4,1(a0)
		move.b	#$A,$20(a0)
		move.b	#4,$18(a0)
		move.b	#$10,$19(a0)
		move.b	#$10,$16(a0)
		move.b	#$E,$17(a0)
		bsr.w	j_S1SingleObjectLoad2_1
		bne.s	loc_17670
		move.b	#$54,0(a1) 
		move.b	#6,$24(a1)
		move.l	#Map_Obj54,4(a1)
		move.w	#$2402,2(a1)
		bsr.w	j_ModifyA1SpriteAttr_2P_0
		move.b	#3,$18(a1)
		move.b	#$10,$19(a1)
		move.b	$22(a0),$22(a1)
		move.b	1(a0),1(a1)
		move.l	a0,$2A(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	#2,$1A(a1)

loc_17670:				; CODE XREF: ROM:00017622j
		addq.b	#2,$24(a0)
		move.w	#$FF80,d0
		btst	#0,$22(a0)
		beq.s	loc_17682
		neg.w	d0

loc_17682:				; CODE XREF: ROM:0001767Ej
		move.w	d0,$10(a0)
		rts
; ---------------------------------------------------------------------------

loc_17688:				; DATA XREF: ROM:000175E0o
		bsr.w	sub_176D0
		bsr.w	j_SpeedToPos_7
		jsr	(ObjHitFloor).l
		cmpi.w	#$FFF8,d1
		blt.s	loc_176B4
		cmpi.w	#$C,d1
		bge.s	loc_176B4
		add.w	d1,$C(a0)
		lea	(Ani_Obj54).l,a1
		bsr.w	j_AnimateSprite_8
		bra.w	loc_1786C
; ---------------------------------------------------------------------------

loc_176B4:				; CODE XREF: ROM:0001769Aj
					; ROM:000176A0j
		addq.b	#2,$24(a0)
		move.w	#$14,$30(a0)
		st	$34(a0)
		lea	(Ani_Obj54).l,a1
		bsr.w	j_AnimateSprite_8
		bra.w	loc_1786C

; =============== S U B	R O U T	I N E =======================================


sub_176D0:				; CODE XREF: ROM:loc_17688p
		tst.b	$35(a0)
		bne.s	locret_17712
		move.w	(v_objspace+8).w,d0
		sub.w	8(a0),d0
		cmpi.w	#$64,d0	
		bgt.s	locret_17712
		cmpi.w	#$FF9C,d0
		blt.s	locret_17712
		tst.w	d0
		bmi.s	loc_176F8
		btst	#0,$22(a0)
		beq.s	locret_17712
		bra.s	loc_17700
; ---------------------------------------------------------------------------

loc_176F8:				; CODE XREF: sub_176D0+1Cj
		btst	#0,$22(a0)
		bne.s	locret_17712

loc_17700:				; CODE XREF: sub_176D0+26j
		move.w	$10(a0),d0
		asl.w	#2,d0
		move.w	d0,$10(a0)
		st	$35(a0)
		bsr.w	sub_17714

locret_17712:				; CODE XREF: sub_176D0+4j
					; sub_176D0+12j ...
		rts
; End of function sub_176D0


; =============== S U B	R O U T	I N E =======================================


sub_17714:				; CODE XREF: sub_176D0+3Ep
		bsr.w	j_S1SingleObjectLoad2_1
		bne.s	locret_17770
		move.b	#$54,0(a1) 
		move.b	#8,$24(a1)
		move.l	#Map_Obj4B,4(a1)
		move.w	#$3E6,2(a1)
		bsr.w	j_ModifyA1SpriteAttr_2P_0
		move.b	#4,$18(a1)
		move.b	#$10,$19(a1)
		move.b	$22(a0),$22(a1)
		move.b	1(a0),1(a1)
		move.l	a0,$2A(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		addq.w	#7,$C(a1)
		addi.w	#$D,8(a1)
		move.b	#1,$1C(a1)

locret_17770:				; CODE XREF: sub_17714+4j
		rts
; End of function sub_17714

; ---------------------------------------------------------------------------

loc_17772:				; DATA XREF: ROM:000175E6o
		movea.l	$2A(a0),a1
		cmpi.b	#$54,(a1) 
		bne.w	loc_17854
		tst.b	$34(a1)
		bne.w	loc_17854
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		addq.w	#7,$C(a0)
		moveq	#$D,d0
		btst	#0,$22(a0)
		beq.s	loc_177A2
		neg.w	d0

loc_177A2:				; CODE XREF: ROM:0001779Ej
		add.w	d0,8(a0)
		lea	(Ani_Obj4B).l,a1
		bsr.w	j_AnimateSprite_8
		bra.w	loc_1786C
; ---------------------------------------------------------------------------

loc_177B4:				; DATA XREF: ROM:000175E2o
		subi.w	#1,$30(a0)
		bpl.w	loc_1786C
		neg.w	$10(a0)
		bsr.w	j_ObjectFall_5
		move.w	$10(a0),d0
		asr.w	#2,d0
		move.w	d0,$10(a0)
		bchg	#0,$22(a0)
		bchg	#0,1(a0)
		subq.b	#2,$24(a0)
		sf	$34(a0)
		sf	$35(a0)
		bra.w	loc_1786C
; ---------------------------------------------------------------------------

loc_177EC:				; DATA XREF: ROM:000175E4o
		movea.l	$2A(a0),a1
		cmpi.b	#$54,(a1)
		bne.w	loc_17854
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		move.b	$22(a1),$22(a0)
		move.b	1(a1),1(a0)
		bra.w	loc_1786C
; ---------------------------------------------------------------------------
Ani_Obj54:	dc.w byte_17818-Ani_Obj54 ; DATA XREF: ROM:000176A6o
					; ROM:000176C2o ...
		dc.w byte_1781C-Ani_Obj54
byte_17818:	dc.b   5,  0,  1,$FF	; 0 ; DATA XREF: ROM:Ani_Obj54o
byte_1781C:	dc.b   1,  0,  1,$FF	; 0 ; DATA XREF: ROM:00017816o
Map_Obj54:	dc.w word_17826-Map_Obj54 ; DATA XREF: ROM:Obj54_Inito
					; ROM:00017630o ...
		dc.w word_17838-Map_Obj54
		dc.w word_1784A-Map_Obj54
word_17826:	dc.w 2			; DATA XREF: ROM:Map_Obj54o
		dc.w $F00F,    0,    0,$FFF0; 0
		dc.w  $109,  $14,   $A,$FFF4; 4
word_17838:	dc.w 2			; DATA XREF: ROM:00017822o
		dc.w $F00F,    0,    0,$FFF0; 0
		dc.w  $109,$1014,$100A,$FFF4; 4
word_1784A:	dc.w 1			; DATA XREF: ROM:00017824o
		dc.w $FA05,  $10,    8,$FFE9; 0
; ---------------------------------------------------------------------------

loc_17854:				; CODE XREF: ROM:0001777Aj
					; ROM:00017782j ...
		jmp	DeleteObject
; ---------------------------------------------------------------------------

j_S1SingleObjectLoad2_1:		; CODE XREF: ROM:0001761Ep sub_17714p
		jmp	S1SingleObjectLoad2
; ---------------------------------------------------------------------------

j_AnimateSprite_8:			; CODE XREF: ROM:000176ACp
					; ROM:000176C8p ...
		jmp	AnimateSprite
; ---------------------------------------------------------------------------

j_ModifyA1SpriteAttr_2P_0:		; CODE XREF: ROM:0001763Ep
					; sub_17714+20p
		jmp	ModifyA1SpriteAttr_2P
; ---------------------------------------------------------------------------

loc_1786C:				; CODE XREF: ROM:000176B0j
					; ROM:000176CCj ...
		jmp	loc_CEC6
; ---------------------------------------------------------------------------

j_ModifySpriteAttr_2P_3:		; CODE XREF: ROM:000175F6p
		jmp	ModifySpriteAttr_2P
; ---------------------------------------------------------------------------

j_ObjectFall_5:				; CODE XREF: ROM:000177C2p
		jmp	ObjectFall
; ---------------------------------------------------------------------------

j_SpeedToPos_7:				; CODE XREF: ROM:0001768Cp
		jmp	SpeedToPos
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 57 - sub object of the	EHZ boss
;----------------------------------------------------

Obj57:					; DATA XREF: ROM:Obj_Indexo
					; ROM:0001833Co
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	off_17892(pc,d0.w),d1
		jmp	off_17892(pc,d1.w)
; ---------------------------------------------------------------------------
off_17892:	dc.w loc_1789E-off_17892; 0 ; DATA XREF: ROM:off_17892o
					; ROM:off_17892+2o ...
		dc.w loc_178C4-off_17892; 1
		dc.w loc_17920-off_17892; 2
		dc.w loc_17952-off_17892; 3
		dc.w loc_1797C-off_17892; 4
		dc.w loc_17996-off_17892; 5
; ---------------------------------------------------------------------------

loc_1789E:				; DATA XREF: ROM:off_17892o
		move.b	#0,$20(a0)
		cmpi.w	#$29D0,8(a0)
		ble.s	loc_178B6
		subi.w	#1,8(a0)
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_178B6:				; CODE XREF: ROM:000178AAj
		move.w	#$29D0,8(a0)
		addq.b	#2,$25(a0)
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_178C4:				; DATA XREF: ROM:off_17892o
		moveq	#0,d0
		move.b	$2C(a0),d0
		move.w	off_178D2(pc,d0.w),d1
		jmp	off_178D2(pc,d1.w)
; ---------------------------------------------------------------------------
off_178D2:	dc.w loc_178D6-off_178D2 ; DATA	XREF: ROM:off_178D2o
					; ROM:000178D4o
		dc.w loc_178FC-off_178D2
; ---------------------------------------------------------------------------

loc_178D6:				; DATA XREF: ROM:off_178D2o
		cmpi.w	#$41E,$C(a0)
		bge.s	loc_178E8
		addi.w	#1,$C(a0)
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_178E8:				; CODE XREF: ROM:000178DCj
		addq.b	#2,$2C(a0)
		bset	#0,$2D(a0)
		move.w	#$3C,$2A(a0) 
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_178FC:				; DATA XREF: ROM:000178D4o
		subi.w	#1,$2A(a0)
		bpl.w	loc_181A8
		move.w	#$FE00,$10(a0)
		addq.b	#2,$25(a0)
		move.b	#$F,$20(a0)
		bset	#1,$2D(a0)
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_17920:				; DATA XREF: ROM:off_17892o
		bsr.w	sub_17A8C
		bsr.w	sub_17A6A
		move.w	$2E(a0),d0
		lsr.w	#1,d0
		subi.w	#$14,d0
		move.w	d0,$C(a0)
		move.w	#0,$2E(a0)
		move.l	8(a0),d2
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.l	d2,8(a0)
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_17952:				; DATA XREF: ROM:off_17892o
		subq.w	#1,$3C(a0)
		bpl.w	BossDefeated
		bset	#0,$22(a0)
		bclr	#7,$22(a0)
		clr.w	$10(a0)
		addq.b	#2,$25(a0)
		move.w	#$FFDA,$3C(a0)
		move.w	#$C,$2A(a0)
		rts
; ---------------------------------------------------------------------------

loc_1797C:				; DATA XREF: ROM:off_17892o
		addq.w	#1,$C(a0)
		subq.w	#1,$2A(a0)
		bpl.w	loc_181A8
		addq.b	#2,$25(a0)
		move.b	#0,$2C(a0)
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_17996:				; DATA XREF: ROM:off_17892o
		moveq	#0,d0
		move.b	$2C(a0),d0
		move.w	off_179A8(pc,d0.w),d1
		jsr	off_179A8(pc,d1.w)
		bra.w	loc_181A8
; ---------------------------------------------------------------------------
off_179A8:	dc.w loc_179AE-off_179A8 ; DATA	XREF: ROM:off_179A8o
					; ROM:000179AAo ...
		dc.w loc_17A22-off_179A8
		dc.w loc_17A3C-off_179A8
; ---------------------------------------------------------------------------

loc_179AE:				; DATA XREF: ROM:off_179A8o
		bclr	#0,$2D(a0)
		bsr.w	j_S1SingleObjectLoad2
		bne.w	loc_181A8
		move.b	#$58,0(a1) 
		move.l	a0,$34(a1)
		move.l	#Map_Obj58,4(a1)
		move.w	#$2540,2(a1)
		move.b	#4,1(a1)
		move.b	#$20,$19(a1) 
		move.b	#4,$18(a1)
		move.l	8(a0),8(a1)
		move.l	$C(a0),$C(a1)
		addi.w	#$C,$C(a1)
		move.b	$22(a0),$22(a1)
		move.b	1(a0),1(a1)
		move.b	#8,$24(a1)
		move.b	#2,$1C(a1)
		move.w	#$10,$2A(a1)
		move.w	#$32,$2A(a0) 
		addq.b	#2,$2C(a0)
		rts
; ---------------------------------------------------------------------------

loc_17A22:				; DATA XREF: ROM:000179AAo
		subi.w	#1,$2A(a0)
		bpl.s	locret_17A3A
		bset	#2,$2D(a0)
		move.w	#$60,$2A(a0) 
		addq.b	#2,$2C(a0)

locret_17A3A:				; CODE XREF: ROM:00017A28j
		rts
; ---------------------------------------------------------------------------

loc_17A3C:				; DATA XREF: ROM:000179ACo
		subq.w	#1,$C(a0)
		subi.w	#1,$2A(a0)
		bpl.s	locret_17A68
		addq.w	#1,$C(a0)
		addq.w	#2,8(a0)
		cmpi.w	#$2B08,8(a0)
		bcs.s	locret_17A68
		tst.b	($FFFFF7A7).w
		bne.s	locret_17A68
		move.b	#1,($FFFFF7A7).w
		bra.w	loc_181AE
; ---------------------------------------------------------------------------

locret_17A68:				; CODE XREF: ROM:00017A46j
					; ROM:00017A56j ...
		rts

; =============== S U B	R O U T	I N E =======================================


sub_17A6A:				; CODE XREF: ROM:00017924p
					; ROM:loc_17C58p
		move.w	8(a0),d0
		cmpi.w	#$2720,d0
		ble.s	loc_17A7A
		cmpi.w	#$2B08,d0
		blt.s	locret_17A8A

loc_17A7A:				; CODE XREF: sub_17A6A+8j
		bchg	#0,$22(a0)
		bchg	#0,1(a0)
		neg.w	$10(a0)

locret_17A8A:				; CODE XREF: sub_17A6A+Ej
		rts
; End of function sub_17A6A


; =============== S U B	R O U T	I N E =======================================


sub_17A8C:				; CODE XREF: ROM:loc_17920p
		cmpi.b	#6,$25(a0)
		bcc.s	locret_17AD2
		tst.b	$22(a0)
		bmi.s	loc_17AD4
		tst.b	$20(a0)
		bne.s	locret_17AD2
		tst.b	$3E(a0)
		bne.s	loc_17AB6
		move.b	#$20,$3E(a0) 
		move.w	#$AC,d0	; "?"
		jsr	(PlaySound_Special).l

loc_17AB6:				; CODE XREF: sub_17A8C+18j
		lea	($FFFFFB22).w,a1
		moveq	#0,d0
		tst.w	(a1)
		bne.s	loc_17AC4
		move.w	#$EEE,d0

loc_17AC4:				; CODE XREF: sub_17A8C+32j
		move.w	d0,(a1)
		subq.b	#1,$3E(a0)
		bne.s	locret_17AD2
		move.b	#$F,$20(a0)

locret_17AD2:				; CODE XREF: sub_17A8C+6j
					; sub_17A8C+12j ...
		rts
; ---------------------------------------------------------------------------

loc_17AD4:				; CODE XREF: sub_17A8C+Cj
		moveq	#$64,d0	
		bsr.w	AddPoints
		move.b	#6,$25(a0)
		move.w	#$B3,$3C(a0) ; "?"
		bset	#3,$2D(a0)
		rts
; End of function sub_17A8C

; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 58 - sub object of the	EHZ boss
;----------------------------------------------------

Obj58:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	off_17AFC(pc,d0.w),d1
		jmp	off_17AFC(pc,d1.w)
; ---------------------------------------------------------------------------
off_17AFC:	dc.w loc_17B2A-off_17AFC ; DATA	XREF: ROM:off_17AFCo
					; ROM:00017AFEo ...
		dc.w loc_17BB0-off_17AFC
		dc.w loc_17C02-off_17AFC
		dc.w loc_17CE4-off_17AFC
		dc.w loc_17B06-off_17AFC
; ---------------------------------------------------------------------------

loc_17B06:				; DATA XREF: ROM:00017B04o
		subi.w	#1,$C(a0)
		subi.w	#1,$2A(a0)
		bpl.w	loc_181A8
		move.b	#0,$24(a0)
		lea	(Ani_Obj58).l,a1
		bsr.w	j_AnimateSprite_9
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_17B2A:				; DATA XREF: ROM:off_17AFCo
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	off_17B38(pc,d0.w),d1
		jmp	off_17B38(pc,d1.w)
; ---------------------------------------------------------------------------
off_17B38:	dc.w loc_17B3C-off_17B38 ; DATA	XREF: ROM:off_17B38o
					; ROM:00017B3Ao
		dc.w loc_17B86-off_17B38
; ---------------------------------------------------------------------------

loc_17B3C:				; DATA XREF: ROM:off_17B38o
		movea.l	$34(a0),a1
		cmpi.b	#$55,(a1) 
		bne.w	loc_181AE
		btst	#0,$2D(a1)
		beq.s	loc_17B60
		move.b	#1,$1C(a0)
		move.w	#$18,$2A(a0)
		addq.b	#2,$25(a0)

loc_17B60:				; CODE XREF: ROM:00017B4Ej
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		move.b	$22(a1),$22(a0)
		move.b	1(a1),1(a0)
		lea	(Ani_Obj58).l,a1
		bsr.w	j_AnimateSprite_9
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_17B86:				; DATA XREF: ROM:00017B3Ao
		subi.w	#1,$2A(a0)
		bpl.s	loc_17BA2
		cmpi.w	#$FFF0,$2A(a0)
		ble.w	loc_181AE
		addi.w	#1,$C(a0)
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_17BA2:				; CODE XREF: ROM:00017B8Cj
		lea	(Ani_Obj58).l,a1
		bsr.w	j_AnimateSprite_9
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_17BB0:				; DATA XREF: ROM:00017AFEo
		movea.l	$34(a0),a1
		cmpi.b	#$55,(a1) 
		bne.w	loc_181AE
		btst	#1,$2D(a1)
		beq.w	loc_181A8
		btst	#2,$2D(a1)
		bne.w	loc_17BF2
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		addi.w	#8,$C(a0)
		move.b	$22(a1),$22(a0)
		move.b	1(a1),1(a0)
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_17BF2:				; CODE XREF: ROM:00017BCCj
		move.b	#8,$1A(a0)
		move.b	#0,$18(a0)
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_17C02:				; DATA XREF: ROM:00017B00o
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	off_17C10(pc,d0.w),d1
		jmp	off_17C10(pc,d1.w)
; ---------------------------------------------------------------------------
off_17C10:	dc.w loc_17C18-off_17C10 ; DATA	XREF: ROM:off_17C10o
					; ROM:00017C12o ...
		dc.w loc_17C36-off_17C10
		dc.w loc_17C96-off_17C10
		dc.w loc_17CC2-off_17C10
; ---------------------------------------------------------------------------

loc_17C18:				; DATA XREF: ROM:off_17C10o
		movea.l	$34(a0),a1
		cmpi.b	#$55,(a1) 
		bne.w	loc_181AE
		btst	#1,$2D(a1)
		beq.w	loc_181A8
		addq.b	#2,$25(a0)
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_17C36:				; DATA XREF: ROM:00017C12o
		movea.l	$34(a0),a1
		cmpi.b	#$55,(a1) 
		bne.w	loc_181AE
		move.b	$22(a1),$22(a0)
		move.b	1(a1),1(a0)
		tst.b	$22(a0)
		bpl.s	loc_17C58
		addq.b	#2,$25(a0)

loc_17C58:				; CODE XREF: ROM:00017C52j
		bsr.w	sub_17A6A
		bsr.w	j_ObjectFall_6
		jsr	(ObjHitFloor).l
		tst.w	d1
		bpl.s	loc_17C6E
		add.w	d1,$C(a0)

loc_17C6E:				; CODE XREF: ROM:00017C68j
		move.w	#$100,$12(a0)
		cmpi.b	#1,$18(a0)
		bne.s	loc_17C88
		move.w	$C(a0),d0
		movea.l	$34(a0),a1
		add.w	d0,$2E(a1)

loc_17C88:				; CODE XREF: ROM:00017C7Aj
		lea	(Ani_Obj58a).l,a1
		bsr.w	j_AnimateSprite_9
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_17C96:				; DATA XREF: ROM:00017C14o
		subi.w	#1,$2A(a0)
		bpl.w	loc_181A8
		addq.b	#2,$25(a0)
		move.w	#$A,$2A(a0)
		move.w	#$FD00,$12(a0)
		cmpi.b	#1,$18(a0)
		beq.w	loc_181A8
		neg.w	$10(a0)
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_17CC2:				; DATA XREF: ROM:00017C16o
		subq.w	#1,$2A(a0)
		bpl.w	loc_181A8
		bsr.w	j_ObjectFall_6
		bsr.w	ObjHitFloor
		tst.w	d1
		bpl.s	loc_17CE0
		move.w	#$FE00,$12(a0)
		add.w	d1,$C(a0)

loc_17CE0:				; CODE XREF: ROM:00017CD4j
		bra.w	loc_181B4
; ---------------------------------------------------------------------------

loc_17CE4:				; DATA XREF: ROM:00017B02o
		movea.l	$34(a0),a1
		cmpi.b	#$55,(a1) 
		bne.w	loc_181AE
		btst	#3,$2D(a1)
		bne.s	loc_17D4A
		bsr.w	sub_17D6A
		btst	#1,$2D(a1)
		beq.w	loc_181A8
		move.b	#$8B,$20(a0)
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		move.b	$22(a1),$22(a0)
		move.b	1(a1),1(a0)
		addi.w	#$10,$C(a0)
		move.w	#$FFCA,d0
		btst	#0,$22(a0)
		beq.s	loc_17D38
		neg.w	d0

loc_17D38:				; CODE XREF: ROM:00017D34j
		add.w	d0,8(a0)
		lea	(Ani_Obj58a).l,a1
		bsr.w	j_AnimateSprite_9
		bra.w	loc_181A8
; ---------------------------------------------------------------------------

loc_17D4A:				; CODE XREF: ROM:00017CF6j
		move.w	#$FFFD,d0
		btst	#0,$22(a0)
		beq.s	loc_17D58
		neg.w	d0

loc_17D58:				; CODE XREF: ROM:00017D54j
		add.w	d0,8(a0)
		lea	(Ani_Obj58a).l,a1
		bsr.w	j_AnimateSprite_9
		bra.w	loc_181A8

; =============== S U B	R O U T	I N E =======================================


sub_17D6A:				; CODE XREF: ROM:00017CF8p
		cmpi.b	#1,$21(a1)
		beq.s	loc_17D74
		rts
; ---------------------------------------------------------------------------

loc_17D74:				; CODE XREF: sub_17D6A+6j
		move.w	8(a0),d0
		sub.w	(v_objspace+8).w,d0
		bpl.s	loc_17D88
		btst	#0,$22(a1)
		bne.s	loc_17D92
		rts
; ---------------------------------------------------------------------------

loc_17D88:				; CODE XREF: sub_17D6A+12j
		btst	#0,$22(a1)
		beq.s	loc_17D92
		rts
; ---------------------------------------------------------------------------

loc_17D92:				; CODE XREF: sub_17D6A+1Aj
					; sub_17D6A+24j
		bset	#3,$2D(a1)
		rts
; End of function sub_17D6A


; =============== S U B	R O U T	I N E =======================================


sub_17D9A:				; CODE XREF: ROM:loc_17F98p
		jsr	S1SingleObjectLoad2
		bne.s	loc_17E0E
		move.b	#$58,0(a1) 
		move.l	a0,$34(a1)
		move.l	#Map_Obj58a,4(a1)
		move.w	#$24C0,2(a1)
		move.b	#4,1(a1)
		move.b	#$10,$19(a1)
		move.b	#1,$18(a1)
		move.b	#$10,$16(a1)
		move.b	#$10,$17(a1)
		move.l	8(a0),8(a1)
		move.l	$C(a0),$C(a1)
		addi.w	#$1C,8(a1)
		addi.w	#$C,$C(a1)
		move.w	#$FE00,$10(a1)
		move.b	#4,$24(a1)
		move.b	#4,$1A(a1)
		move.b	#1,$1C(a1)
		move.w	#$16,$2A(a1)

loc_17E0E:				; CODE XREF: sub_17D9A+6j
		jsr	S1SingleObjectLoad2
		bne.s	loc_17E82
		move.b	#$58,0(a1) 
		move.l	a0,$34(a1)
		move.l	#Map_Obj58a,4(a1)
		move.w	#$24C0,2(a1)
		move.b	#4,1(a1)
		move.b	#$10,$19(a1)
		move.b	#1,$18(a1)
		move.b	#$10,$16(a1)
		move.b	#$10,$17(a1)
		move.l	8(a0),8(a1)
		move.l	$C(a0),$C(a1)
		addi.w	#$FFF4,8(a1)
		addi.w	#$C,$C(a1)
		move.w	#$FE00,$10(a1)
		move.b	#4,$24(a1)
		move.b	#4,$1A(a1)
		move.b	#1,$1C(a1)
		move.w	#$4B,$2A(a1) 

loc_17E82:				; CODE XREF: sub_17D9A+7Aj
		jsr	S1SingleObjectLoad2
		bne.s	loc_17EF6
		move.b	#$58,0(a1) 
		move.l	a0,$34(a1)
		move.l	#Map_Obj58a,4(a1)
		move.w	#$24C0,2(a1)
		move.b	#4,1(a1)
		move.b	#$10,$19(a1)
		move.b	#2,$18(a1)
		move.b	#$10,$16(a1)
		move.b	#$10,$17(a1)
		move.l	8(a0),8(a1)
		move.l	$C(a0),$C(a1)
		addi.w	#$FFD4,8(a1)
		addi.w	#$C,$C(a1)
		move.w	#$FE00,$10(a1)
		move.b	#4,$24(a1)
		move.b	#6,$1A(a1)
		move.b	#2,$1C(a1)
		move.w	#$30,$2A(a1) 

loc_17EF6:				; CODE XREF: sub_17D9A+EEj
		jsr	S1SingleObjectLoad2
		bne.s	locret_17F52
		move.b	#$58,0(a1) 
		move.l	a0,$34(a1)
		move.l	#Map_Obj58a,4(a1)
		move.w	#$24C0,2(a1)
		move.b	#4,1(a1)
		move.b	#$10,$19(a1)
		move.b	#1,$18(a1)
		move.l	8(a0),8(a1)
		move.l	$C(a0),$C(a1)
		addi.w	#$FFCA,8(a1)
		addi.w	#8,$C(a1)
		move.b	#6,$24(a1)
		move.b	#1,$1A(a1)
		move.b	#0,$1C(a1)

locret_17F52:				; CODE XREF: sub_17D9A+162j
		rts
; End of function sub_17D9A

; ---------------------------------------------------------------------------

loc_17F54:				; DATA XREF: ROM:000182FEo
		jsr	S1SingleObjectLoad2
		bne.s	loc_17F98
		move.b	#$58,0(a1) 
		move.l	a0,$34(a1)
		move.l	#Map_Obj58a,4(a1)
		move.w	#$4C0,2(a1)
		move.b	#4,1(a1)
		move.b	#$20,$19(a1) 
		move.b	#2,$18(a1)
		move.l	8(a0),8(a1)
		move.l	$C(a0),$C(a1)
		move.b	#2,$24(a1)

loc_17F98:				; CODE XREF: ROM:00017F5Aj
		bsr.w	sub_17D9A
		subi.w	#8,$38(a0)
		move.w	#$2A00,8(a0)
		move.w	#$2C0,$C(a0)
		jsr	S1SingleObjectLoad2
		bne.s	locret_17FF8
		move.b	#$58,0(a1) 
		move.l	a0,$34(a1)
		move.l	#Map_Obj58,4(a1)
		move.w	#$2540,2(a1)
		move.b	#4,1(a1)
		move.b	#$20,$19(a1) 
		move.b	#4,$18(a1)
		move.l	8(a0),8(a1)
		move.l	$C(a0),$C(a1)
		move.w	#$1E,$2A(a1)
		move.b	#0,$24(a1)

locret_17FF8:				; CODE XREF: ROM:00017FB4j
		rts
; ---------------------------------------------------------------------------
Ani_Obj58:	dc.w byte_18000-Ani_Obj58 ; DATA XREF: ROM:00017B1Co
					; ROM:00017B78o ...
		dc.w byte_18004-Ani_Obj58
		dc.w byte_1801A-Ani_Obj58
byte_18000:	dc.b   1,  5,  6,$FF	; 0 ; DATA XREF: ROM:Ani_Obj58o
byte_18004:	dc.b   1,  1,  1,  1,  2,  2,  2,  3,  3,  3,  4,  4,  4,  0,  0,  0; 0
					; DATA XREF: ROM:00017FFCo
		dc.b   0,  0,  0,  0,  0,$FF; 16
byte_1801A:	dc.b   1,  0,  0,  0,  0,  0,  0,  0,  0,  4,  4,  4,  3,  3,  3,  2; 0
					; DATA XREF: ROM:00017FFEo
		dc.b   2,  2,  1,  1,  1,  5,  6,$FE,  2,  0; 16
Map_Obj58:	dc.w word_18042-Map_Obj58 ; DATA XREF: ROM:000179C6o
					; ROM:00017FC0o ...
		dc.w word_1804C-Map_Obj58
		dc.w word_18076-Map_Obj58
		dc.w word_180A0-Map_Obj58
		dc.w word_180BA-Map_Obj58
		dc.w word_180D4-Map_Obj58
		dc.w word_180EE-Map_Obj58
word_18042:	dc.w 1			; DATA XREF: ROM:Map_Obj58o
		dc.w $D805,    0,    0,	   2; 0
word_1804C:	dc.w 5			; DATA XREF: ROM:00018036o
		dc.w $D805,    4,    2,	   2; 0
		dc.w $D80D,   $C,    6,	 $12; 4
		dc.w $D80D,   $C,    6,	 $32; 8
		dc.w $D80D,   $C,    6,$FFE2; 12
		dc.w $D80D,   $C,    6,$FFC2; 16
word_18076:	dc.w 5			; DATA XREF: ROM:00018038o
		dc.w $D805,    4,    2,	   2; 0
		dc.w $D80D,   $C,    6,	 $12; 4
		dc.w $D805,    8,    4,	 $32; 8
		dc.w $D80D,   $C,    6,$FFE2; 12
		dc.w $D805,    8,    4,$FFD2; 16
word_180A0:	dc.w 3			; DATA XREF: ROM:0001803Ao
		dc.w $D805,    4,    2,	   2; 0
		dc.w $D80D,   $C,    6,	 $12; 4
		dc.w $D80D,   $C,    6,$FFE2; 8
word_180BA:	dc.w 3			; DATA XREF: ROM:0001803Co
		dc.w $D805,    4,    2,	   2; 0
		dc.w $D805,    8,    4,	 $12; 4
		dc.w $D805,    8,    4,$FFF2; 8
word_180D4:	dc.w 3			; DATA XREF: ROM:0001803Eo
		dc.w $D805,    0,    0,	   2; 0
		dc.w $D80D,   $C,    6,	 $12; 4
		dc.w $D80D,   $C,    6,	 $32; 8
word_180EE:	dc.w 3			; DATA XREF: ROM:00018040o
		dc.w $D805,    4,    2,	   2; 0
		dc.w $D80D,   $C,    6,$FFE2; 4
		dc.w $D80D,   $C,    6,$FFC2; 8
Ani_Obj58a:	dc.w byte_1810E-Ani_Obj58a ; DATA XREF:	ROM:loc_17C88o
					; ROM:00017D3Co ...
		dc.w byte_18113-Ani_Obj58a
		dc.w byte_18117-Ani_Obj58a
byte_1810E:	dc.b   5,  1,  2,  3,$FF; 0 ; DATA XREF: ROM:Ani_Obj58ao
byte_18113:	dc.b   1,  4,  5,$FF	; 0 ; DATA XREF: ROM:0001810Ao
byte_18117:	dc.b   1,  6,  7,$FF,  0; 0 ; DATA XREF: ROM:0001810Co
Map_Obj58a:	dc.w word_1812E-Map_Obj58a ; DATA XREF:	sub_17D9A+12o
					; sub_17D9A+86o ...
		dc.w word_18148-Map_Obj58a
		dc.w word_18152-Map_Obj58a
		dc.w word_1815C-Map_Obj58a
		dc.w word_18166-Map_Obj58a
		dc.w word_18170-Map_Obj58a
		dc.w word_1817A-Map_Obj58a
		dc.w word_18184-Map_Obj58a
		dc.w word_1818E-Map_Obj58a
word_1812E:	dc.w 3			; DATA XREF: ROM:Map_Obj58ao
		dc.w $F00F,    0,    0,$FFD0; 0
		dc.w $F00F,  $10,    8,$FFF0; 4
		dc.w $F00F,  $20,  $10,	 $10; 8
word_18148:	dc.w 1			; DATA XREF: ROM:0001811Eo
		dc.w $F00F,  $30,  $18,$FFF0; 0
word_18152:	dc.w 1			; DATA XREF: ROM:00018120o
		dc.w $F00F,  $40,  $20,$FFF0; 0
word_1815C:	dc.w 1			; DATA XREF: ROM:00018122o
		dc.w $F00F,  $50,  $28,$FFF0; 0
word_18166:	dc.w 1			; DATA XREF: ROM:00018124o
		dc.w $F00F,  $60,  $30,$FFF0; 0
word_18170:	dc.w 1			; DATA XREF: ROM:00018126o
		dc.w $F00F,$1060,$1030,$FFF0; 0
word_1817A:	dc.w 1			; DATA XREF: ROM:00018128o
		dc.w $F00F,  $70,  $38,$FFF0; 0
word_18184:	dc.w 1			; DATA XREF: ROM:0001812Ao
		dc.w $F00F,$1070,$1038,$FFF0; 0
word_1818E:	dc.w 3			; DATA XREF: ROM:0001812Co
		dc.w $F00F,$8000,$8000,$FFD0; 0
		dc.w $F00F,$8010,$8008,$FFF0; 4
		dc.w $F00F,$8020,$8010,	 $10; 8
; ---------------------------------------------------------------------------

loc_181A8:				; CODE XREF: ROM:000178B2j
					; ROM:000178C0j ...
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_181AE:				; CODE XREF: ROM:00017A64j
					; ROM:00017B44j ...
		jmp	DeleteObject
; ---------------------------------------------------------------------------

loc_181B4:				; CODE XREF: ROM:loc_17CE0j
		jmp	MarkObjGone
; ---------------------------------------------------------------------------

j_S1SingleObjectLoad2:			; CODE XREF: ROM:000179B4p
		jmp	S1SingleObjectLoad2
; ---------------------------------------------------------------------------

j_AnimateSprite_9:			; CODE XREF: ROM:00017B22p
					; ROM:00017B7Ep ...
		jmp	AnimateSprite
; ---------------------------------------------------------------------------

j_ObjectFall_6:				; CODE XREF: ROM:00017C5Cp
					; ROM:00017CCAp
		jmp	ObjectFall
; ---------------------------------------------------------------------------

Obj55:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj55_Index(pc,d0.w),d1
		jmp	Obj55_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj55_Index:	dc.w loc_181E4-Obj55_Index; 0 ;	DATA XREF: ROM:Obj55_Indexo
					; ROM:Obj55_Index+2o ...
		dc.w loc_18302-Obj55_Index; 1
		dc.w loc_18340-Obj55_Index; 2
		dc.w loc_18372-Obj55_Index; 3
		dc.w loc_18410-Obj55_Index; 4
; ---------------------------------------------------------------------------

loc_181E4:				; DATA XREF: ROM:Obj55_Indexo
		move.l	#Map_Obj55,4(a0)
		move.w	#$2400,2(a0)
		ori.b	#4,1(a0)
		move.b	#$20,$19(a0) 
		move.b	#3,$18(a0)
		move.b	#$F,$20(a0)
		move.b	#8,$21(a0)
		addq.b	#2,$24(a0)
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$38(a0)
		move.b	$28(a0),d0
		cmpi.b	#$81,d0
		bne.s	loc_18230
		addi.w	#$60,2(a0) 

loc_18230:				; CODE XREF: ROM:00018228j
		jsr	S1SingleObjectLoad2
		bne.w	loc_182E8
		move.b	#$55,0(a1) 
		move.l	a0,$34(a1)
		move.l	a1,$34(a0)
		move.l	#Map_Obj55,4(a1)
		move.w	#$400,2(a1)
		move.b	#4,1(a1)
		move.b	#$20,$19(a1) 
		move.b	#3,$18(a1)
		move.l	8(a0),8(a1)
		move.l	$C(a0),$C(a1)
		addq.b	#4,$24(a1)
		move.b	#1,$1C(a1)
		move.b	1(a0),1(a1)
		move.b	$28(a0),d0
		cmpi.b	#$81,d0
		bne.s	loc_18294
		addi.w	#$60,2(a1)

loc_18294:				; CODE XREF: ROM:0001828Cj
		tst.b	$28(a0)
		bmi.s	loc_182E8
		jsr	S1SingleObjectLoad2
		bne.s	loc_182E8
		move.b	#$55,0(a1)
		move.l	a0,$34(a1)

loc_182AC:
		move.l	#Map_Obj55a,4(a1)
		move.w	#$4D0,2(a1)
		move.b	#1,$1E(a0)

loc_182C0:
		move.b	#4,1(a1)
		move.b	#$20,$19(a1) 
		move.b	#3,$18(a1)
		move.l	8(a0),8(a1)
		move.l	$C(a0),$C(a1)
		addq.b	#6,$24(a1)
		move.b	1(a0),1(a1)

loc_182E8:				; CODE XREF: ROM:00018236j
					; ROM:00018298j ...
		move.b	$28(a0),d0
		andi.w	#$7F,d0	
		add.w	d0,d0
		add.w	d0,d0
		movea.l	dword_182FA(pc,d0.w),a1
		jmp	(a1)
; ---------------------------------------------------------------------------
dword_182FA:	dc.l 0
		dc.l loc_17F54
; ---------------------------------------------------------------------------

loc_18302:				; DATA XREF: ROM:Obj55_Indexo
		move.b	$28(a0),d0
		andi.w	#$7F,d0	
		add.w	d0,d0
		add.w	d0,d0
		movea.l	dword_18338(pc,d0.w),a1
		jsr	(a1)
		lea	(Ani_Obj55a).l,a1
		jsr	AnimateSprite
		move.b	$22(a0),d0
		andi.b	#3,d0
		andi.b	#$FC,1(a0)
		or.b	d0,1(a0)
		jmp	DisplaySprite
; ---------------------------------------------------------------------------
dword_18338:	dc.l 0
		dc.l Obj57
; ---------------------------------------------------------------------------

loc_18340:				; DATA XREF: ROM:Obj55_Indexo
		movea.l	$34(a0),a1
		move.l	8(a1),8(a0)
		move.l	$C(a1),$C(a0)
		move.b	$22(a1),$22(a0)
		move.b	1(a1),1(a0)
		movea.l	#Ani_Obj55a,a1
		jsr	AnimateSprite
		jmp	DisplaySprite
; ---------------------------------------------------------------------------
byte_1836E:	dc.b   0,$FF,  1,  0	; 0
; ---------------------------------------------------------------------------

loc_18372:				; DATA XREF: ROM:Obj55_Indexo
		btst	#7,$22(a0)
		bne.s	loc_183C6
		movea.l	$34(a0),a1
		move.l	8(a1),8(a0)
		move.l	$C(a1),$C(a0)
		move.b	$22(a1),$22(a0)
		move.b	1(a1),1(a0)
		subq.b	#1,$1E(a0)
		bpl.s	loc_183BA
		move.b	#1,$1E(a0)
		move.b	$2A(a0),d0
		addq.b	#1,d0
		cmpi.b	#2,d0
		ble.s	loc_183B0
		moveq	#0,d0

loc_183B0:				; CODE XREF: ROM:000183ACj
		move.b	byte_1836E(pc,d0.w),$1A(a0)
		move.b	d0,$2A(a0)

loc_183BA:				; CODE XREF: ROM:0001839Aj
		cmpi.b	#$FF,$1A(a0)
		bne.w	loc_185D4
		rts
; ---------------------------------------------------------------------------

loc_183C6:				; CODE XREF: ROM:00018378j
		movea.l	$34(a0),a1
		btst	#6,$2E(a1)
		bne.s	loc_183D4
		rts
; ---------------------------------------------------------------------------

loc_183D4:				; CODE XREF: ROM:000183D0j
		addq.b	#2,$24(a0)
		move.l	#Map_Obj55b,4(a0)
		move.w	#$4D8,2(a0)
		move.b	#0,$1A(a0)
		move.b	#5,$1E(a0)
		movea.l	$34(a0),a1
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		addi.w	#4,$C(a0)
		subi.w	#$28,8(a0) 
		rts
; ---------------------------------------------------------------------------

loc_18410:				; DATA XREF: ROM:Obj55_Indexo
		subq.b	#1,$1E(a0)
		bpl.s	loc_18452
		move.b	#5,$1E(a0)
		addq.b	#1,$1A(a0)
		cmpi.b	#4,$1A(a0)
		bne.w	loc_18452
		move.b	#0,$1A(a0)
		movea.l	$34(a0),a1
		move.b	(a1),d0
		beq.w	loc_185DA
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		addi.w	#4,$C(a0)
		subi.w	#$28,8(a0) 

loc_18452:				; CODE XREF: ROM:00018414j
					; ROM:00018426j
		bra.w	loc_185D4
; ---------------------------------------------------------------------------

Obj56:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj56_Index(pc,d0.w),d1
		jmp	Obj56_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj56_Index:	dc.w Obj56_Init-Obj56_Index ; DATA XREF: ROM:Obj56_Indexo
					; ROM:00018466o
		dc.w Obj56_Animate-Obj56_Index
; ---------------------------------------------------------------------------

Obj56_Init:				; DATA XREF: ROM:Obj56_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj56,4(a0)
		move.w	#$5A0,2(a0)
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#0,$20(a0)
		move.b	#$C,$19(a0)
		move.b	#7,$1E(a0)
		move.b	#0,$1A(a0)
		rts
; ---------------------------------------------------------------------------

Obj56_Animate:				; DATA XREF: ROM:00018466o
		subq.b	#1,$1E(a0)
		bpl.s	loc_184BA
		move.b	#7,$1E(a0)
		addq.b	#1,$1A(a0)
		cmpi.b	#7,$1A(a0)
		beq.w	loc_185DA

loc_184BA:				; CODE XREF: ROM:000184A4j
		bra.w	loc_185D4
; ---------------------------------------------------------------------------
Map_Obj55a:	dc.w word_184C2-Map_Obj55a ; DATA XREF:	ROM:loc_182ACo
					; ROM:Map_Obj55ao ...
		dc.w word_184CC-Map_Obj55a
word_184C2:	dc.w 1			; DATA XREF: ROM:Map_Obj55ao
		dc.w	 5,    0,    0,	 $1C; 0
word_184CC:	dc.w 1			; DATA XREF: ROM:000184C0o
		dc.w	 5,    4,    2,	 $1C; 0
Map_Obj55b:	dc.w word_184DE-Map_Obj55b ; DATA XREF:	ROM:000183D8o
					; ROM:Map_Obj55bo ...
		dc.w word_184E8-Map_Obj55b
		dc.w word_184F2-Map_Obj55b
		dc.w word_184FC-Map_Obj55b
word_184DE:	dc.w 1			; DATA XREF: ROM:Map_Obj55bo
		dc.w $F805,    0,    0,$FFF8; 0
word_184E8:	dc.w 1			; DATA XREF: ROM:000184D8o
		dc.w $F805,    4,    2,$FFF8; 0
word_184F2:	dc.w 1			; DATA XREF: ROM:000184DAo
		dc.w $F805,    8,    4,$FFF8; 0
word_184FC:	dc.w 1			; DATA XREF: ROM:000184DCo
		dc.w $F805,   $C,    6,$FFF8; 0
Map_Obj56:	dc.w word_18514-Map_Obj56 ; DATA XREF: ROM:0001846Co
					; ROM:Map_Obj56o ...
		dc.w word_1851E-Map_Obj56
		dc.w word_18528-Map_Obj56
		dc.w word_18532-Map_Obj56
		dc.w word_1853C-Map_Obj56
		dc.w word_18546-Map_Obj56
		dc.w word_18550-Map_Obj56
word_18514:	dc.w 1			; DATA XREF: ROM:Map_Obj56o
		dc.w $F805,    0,    0,$FFF8; 0
word_1851E:	dc.w 1			; DATA XREF: ROM:00018508o
		dc.w $F00F,    4,    2,$FFF0; 0
word_18528:	dc.w 1			; DATA XREF: ROM:0001850Ao
		dc.w $F00F,  $14,   $A,$FFF0; 0
word_18532:	dc.w 1			; DATA XREF: ROM:0001850Co
		dc.w $F00F,  $24,  $12,$FFF0; 0
word_1853C:	dc.w 1			; DATA XREF: ROM:0001850Eo
		dc.w $F00F,  $34,  $1A,$FFF0; 0
word_18546:	dc.w 1			; DATA XREF: ROM:00018510o
		dc.w $F00F,  $44,  $22,$FFF0; 0
word_18550:	dc.w 1			; DATA XREF: ROM:00018512o
		dc.w $F00F,  $54,  $2A,$FFF0; 0
Ani_Obj55a:	dc.w byte_1855E-Ani_Obj55a ; DATA XREF:	ROM:00018314o
					; ROM:0001835Co ...
		dc.w byte_18561-Ani_Obj55a
byte_1855E:	dc.b  $F,  0,$FF	; 0 ; DATA XREF: ROM:Ani_Obj55ao
byte_18561:	dc.b   7,  1,  2,$FF,  0; 0 ; DATA XREF: ROM:0001855Co
Map_Obj55:	dc.w word_1856C-Map_Obj55 ; DATA XREF: ROM:loc_181E4o
					; ROM:00018248o ...
		dc.w word_1858E-Map_Obj55
		dc.w word_185B0-Map_Obj55
word_1856C:	dc.w 4			; DATA XREF: ROM:Map_Obj55o
		dc.w $F805,    0,    0,$FFE0; 0
		dc.w  $805,    4,    2,$FFE0; 4
		dc.w $F80F,    8,    4,$FFF0; 8
		dc.w $F807,  $18,   $C,	 $10; 12
word_1858E:	dc.w 4			; DATA XREF: ROM:00018568o
		dc.w $E805,  $28,  $14,$FFE0; 0
		dc.w $E80D,  $30,  $18,$FFF0; 4
		dc.w $E805,  $24,  $12,	 $10; 8
		dc.w $D805,  $20,  $10,	   2; 12
word_185B0:	dc.w 4			; DATA XREF: ROM:0001856Ao
		dc.w $E805,  $28,  $14,$FFE0; 0
		dc.w $E80D,  $38,  $1C,$FFF0; 4
		dc.w $E805,  $24,  $12,	 $10; 8
		dc.w $D805,  $20,  $10,	   2; 12
; ---------------------------------------------------------------------------
		nop

loc_185D4:				; CODE XREF: ROM:000183C0j
					; ROM:loc_18452j ...
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_185DA:				; CODE XREF: ROM:00018436j
					; ROM:000184B6j
		jmp	DeleteObject
; ---------------------------------------------------------------------------

Obj8A:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0

loc_185E2:
		move.b	$24(a0),d0
		move.w	off_185EE(pc,d0.w),d1
		jmp	off_185EE(pc,d1.w)
; ---------------------------------------------------------------------------
off_185EE:	dc.w loc_185F2-off_185EE ; DATA	XREF: ROM:off_185EEo
					; ROM:000185F0o
		dc.w loc_18660-off_185EE
; ---------------------------------------------------------------------------

loc_185F2:				; DATA XREF: ROM:off_185EEo
		addq.b	#2,$24(a0)
		move.w	#$120,8(a0)
		move.w	#$F0,$A(a0) ; "?"
		move.l	#Map_Obj8A,4(a0)
		move.w	#$5A0,2(a0)
		bsr.w	j_ModifySpriteAttr_2P_4
		move.w	($FFFFFFF4).w,d0
		move.b	d0,$1A(a0)
		move.b	#0,1(a0)
		move.b	#0,$18(a0)
		cmpi.b	#4,(v_gamemode).w
		bne.s	loc_18660
		move.w	#$300,2(a0)
		bsr.w	j_ModifySpriteAttr_2P_4
		move.b	#$A,$1A(a0)
		tst.b	($FFFFFFE3).w
		beq.s	loc_18660
		cmpi.b	#$72,(v_jpadhold1).w
		bne.s	loc_18660

loc_1864E:
		move.w	#$EEE,($FFFFFBC0).w
		move.w	#$880,($FFFFFBC2).w
		jmp	DeleteObject
; ---------------------------------------------------------------------------

loc_18660:				; CODE XREF: ROM:0001862Ej
					; ROM:00018644j ...
		jmp	DisplaySprite
; ---------------------------------------------------------------------------
Map_Obj8A:	dc.w word_1867C-Map_Obj8A ; DATA XREF: ROM:00018602o
					; ROM:Map_Obj8Ao ...
		dc.w word_186EE-Map_Obj8A
		dc.w word_18770-Map_Obj8A
		dc.w word_187C2-Map_Obj8A
		dc.w word_18884-Map_Obj8A
		dc.w word_18926-Map_Obj8A
		dc.w word_189F8-Map_Obj8A
		dc.w word_18AB2-Map_Obj8A
		dc.w word_18BAC-Map_Obj8A
		dc.w word_18C26-Map_Obj8A
		dc.w word_18C68-Map_Obj8A
word_1867C:	dc.w $E			; DATA XREF: ROM:Map_Obj8Ao
		dc.w $F805,  $2E,  $17,$FF88; 0
		dc.w $F805,  $26,  $13,$FF98; 4
		dc.w $F805,  $1A,   $D,$FFA8; 8
		dc.w $F801,  $46,  $23,$FFB8; 12
		dc.w $F805,  $1E,   $F,$FFC0; 16
		dc.w $F805,  $3E,  $1F,$FFD8; 20
		dc.w $F805,   $E,    7,$FFE8; 24
		dc.w $F805,    4,    2,$FFF8; 28
		dc.w $F809,    8,    4,	   8; 32
		dc.w $F805,  $2E,  $17,	 $28; 36
		dc.w $F805,  $3E,  $1F,	 $38; 40
		dc.w $F805,    4,    2,	 $48; 44
		dc.w $F805,  $5C,  $2E,	 $58; 48
		dc.w $F805,  $5C,  $2E,	 $68; 52
word_186EE:	dc.w $10		; DATA XREF: ROM:00018668o
		dc.w $D805,    0,    0,$FF80; 0
		dc.w $D805,    4,    2,$FF90; 4
		dc.w $D809,    8,    4,$FFA0; 8
		dc.w $D805,   $E,    7,$FFB4; 12
		dc.w $D805,  $12,    9,$FFD0; 16
		dc.w $D805,  $16,   $B,$FFE0; 20
		dc.w $D805,    4,    2,$FFF0; 24
		dc.w $D805,  $1A,   $D,	   0; 28
		dc.w  $805,  $1E,   $F,$FFC8; 32
		dc.w  $805,    4,    2,$FFD8; 36
		dc.w  $805,  $22,  $11,$FFE8; 40
		dc.w  $805,  $26,  $13,$FFF8; 44
		dc.w  $805,  $16,   $B,	   8; 48
		dc.w  $805,  $2A,  $15,	 $20; 52
		dc.w  $805,    4,    2,	 $30; 56
		dc.w  $805,  $2E,  $17,	 $44; 60
word_18770:	dc.w $A			; DATA XREF: ROM:0001866Ao
		dc.w $D805,  $12,    9,$FF80; 0
		dc.w $D805,  $22,  $11,$FF90; 4
		dc.w $D805,  $26,  $13,$FFA0; 8
		dc.w $D805,    0,    0,$FFB0; 12
		dc.w $D805,  $22,  $11,$FFC0; 16
		dc.w $D805,    4,    2,$FFD0; 20
		dc.w $D809,    8,    4,$FFE0; 24
		dc.w  $805,  $2A,  $15,$FFE8; 28
		dc.w  $805,  $32,  $19,$FFF8; 32
		dc.w  $805,  $36,  $1B,	   8; 36
word_187C2:	dc.w $18		; DATA XREF: ROM:0001866Co
		dc.w $D805,  $1E,   $F,$FF88; 0
		dc.w $D805,  $3A,  $1D,$FF98; 4
		dc.w $D805,    4,    2,$FFA8; 8
		dc.w $D805,  $22,  $11,$FFB8; 12
		dc.w $D805,    4,    2,$FFC8; 16
		dc.w $D805,  $1E,   $F,$FFD8; 20
		dc.w $D805,  $3E,  $1F,$FFE8; 24
		dc.w $D805,   $E,    7,$FFF8; 28
		dc.w $D805,  $22,  $11,	   8; 32
		dc.w $D805,  $42,  $21,	 $20; 36
		dc.w $D805,   $E,    7,	 $30; 40
		dc.w $D805,  $2E,  $17,	 $40; 44
		dc.w $D801,  $46,  $23,	 $50; 48
		dc.w $D805,    0,    0,	 $58; 52
		dc.w $D805,  $1A,   $D,	 $68; 56
		dc.w  $805,  $48,  $24,$FFC0; 60
		dc.w  $801,  $46,  $23,$FFD0; 64
		dc.w  $805,    0,    0,$FFD8; 68
		dc.w  $801,  $46,  $23,$FFE8; 72
		dc.w  $805,  $2E,  $17,$FFF0; 76
		dc.w  $805,  $16,   $B,	   0; 80
		dc.w  $805,    4,    2,	 $10; 84
		dc.w  $805,  $1A,   $D,	 $20; 88
		dc.w  $805,  $42,  $21,	 $30; 92
word_18884:	dc.w $14		; DATA XREF: ROM:0001866Eo
		dc.w $D005,  $42,  $21,$FFA0; 0
		dc.w $D005,   $E,    7,$FFB0; 4
		dc.w $D005,  $2E,  $17,$FFC0; 8
		dc.w $D001,  $46,  $23,$FFD0; 12
		dc.w $D005,    0,    0,$FFD8; 16
		dc.w $D005,  $1A,   $D,$FFE8; 20
		dc.w	 5,  $4C,  $26,$FFE8; 24
		dc.w	 1,  $46,  $23,$FFF8; 28
		dc.w	 5,  $1A,   $D,	   4; 32
		dc.w	 5,  $2A,  $15,	 $14; 36
		dc.w	 5,    4,    2,	 $24; 40
		dc.w $2005,  $12,    9,$FFD0; 44
		dc.w $2005,  $3A,  $1D,$FFE0; 48
		dc.w $2005,   $E,    7,$FFF0; 52
		dc.w $2005,  $1A,   $D,	   0; 56
		dc.w $2001,  $46,  $23,	 $10; 60
		dc.w $2005,  $50,  $28,	 $18; 64
		dc.w $2005,  $22,  $11,	 $30; 68
		dc.w $2001,  $46,  $23,	 $40; 72
		dc.w $2005,   $E,    7,	 $48; 76
word_18926:	dc.w $1A		; DATA XREF: ROM:00018670o
		dc.w $D805,  $2E,  $17,$FF98; 0
		dc.w $D805,  $26,  $13,$FFA8; 4
		dc.w $D805,  $32,  $19,$FFB8; 8
		dc.w $D805,  $1A,   $D,$FFC8; 12
		dc.w $D805,  $54,  $2A,$FFD8; 16
		dc.w $D805,  $12,    9,$FFF8; 20
		dc.w $D805,  $22,  $11,	   8; 24
		dc.w $D805,  $26,  $13,	 $18; 28
		dc.w $D805,  $42,  $21,	 $28; 32
		dc.w $D805,  $32,  $19,	 $38; 36
		dc.w $D805,  $1E,   $F,	 $48; 40
		dc.w $D805,   $E,    7,	 $58; 44
		dc.w  $809,    8,    4,$FF88; 48
		dc.w  $805,    4,    2,$FF9C; 52
		dc.w  $805,  $2E,  $17,$FFAC; 56
		dc.w  $805,    4,    2,$FFBC; 60
		dc.w  $805,  $3E,  $1F,$FFCC; 64
		dc.w  $805,  $26,  $13,$FFDC; 68
		dc.w  $805,  $1A,   $D,$FFF8; 72
		dc.w  $805,    4,    2,	   8; 76
		dc.w  $805,  $58,  $2C,	 $18; 80
		dc.w  $805,    4,    2,	 $28; 84
		dc.w  $809,    8,    4,	 $38; 88
		dc.w  $805,  $32,  $19,	 $4C; 92
		dc.w  $805,  $22,  $11,	 $5C; 96
		dc.w  $805,    4,    2,	 $6C; 100
word_189F8:	dc.w $17		; DATA XREF: ROM:00018672o
		dc.w $D005,  $2E,  $17,$FF98; 0
		dc.w $D005,  $26,  $13,$FFA8; 4
		dc.w $D005,  $32,  $19,$FFB8; 8
		dc.w $D005,  $1A,   $D,$FFC8; 12
		dc.w $D005,  $54,  $2A,$FFD8; 16
		dc.w $D005,  $12,    9,$FFF8; 20
		dc.w $D005,  $22,  $11,	   8; 24
		dc.w $D005,  $26,  $13,	 $18; 28
		dc.w $D005,    0,    0,	 $28; 32
		dc.w $D005,  $22,  $11,	 $38; 36
		dc.w $D005,    4,    2,	 $48; 40
		dc.w $D009,    8,    4,	 $58; 44
		dc.w	 5,  $4C,  $26,$FFD0; 48
		dc.w	 1,  $46,  $23,$FFE0; 52
		dc.w	 9,    8,    4,$FFE8; 56
		dc.w	 1,  $46,  $23,$FFFC; 60
		dc.w	 5,  $3E,  $1F,	   4; 64
		dc.w	 5,    4,    2,	 $14; 68
		dc.w $2009,    8,    4,$FFD0; 72
		dc.w $2005,    4,    2,$FFE4; 76
		dc.w $2005,  $1E,   $F,$FFF4; 80
		dc.w $2005,  $58,  $2C,	   4; 84
		dc.w $2005,  $2A,  $15,	 $14; 88
word_18AB2:	dc.w $1F		; DATA XREF: ROM:00018674o
		dc.w $D805,  $2E,  $17,$FF80; 0
		dc.w $D805,  $12,    9,$FF90; 4
		dc.w $D805,   $E,    7,$FFA0; 8
		dc.w $D805,  $1E,   $F,$FFB0; 12
		dc.w $D801,  $46,  $23,$FFC0; 16
		dc.w $D805,    4,    2,$FFC8; 20
		dc.w $D805,  $16,   $B,$FFD8; 24
		dc.w $D805,  $3E,  $1F,$FFF8; 28
		dc.w $D805,  $3A,  $1D,	   8; 32
		dc.w $D805,    4,    2,	 $18; 36
		dc.w $D805,  $1A,   $D,	 $28; 40
		dc.w $D805,  $58,  $2C,	 $38; 44
		dc.w $D805,  $2E,  $17,	 $48; 48
		dc.w	 5,  $5C,  $2E,$FFB0; 52
		dc.w	 5,  $32,  $19,$FFC0; 56
		dc.w	 5,  $4C,  $26,$FFD0; 60
		dc.w	 1,  $46,  $23,$FFE0; 64
		dc.w	 5,  $26,  $13,$FFE8; 68
		dc.w	 9,    8,    4,	   0; 72
		dc.w	 1,  $46,  $23,	 $14; 76
		dc.w	 5,  $1A,   $D,	 $1C; 80
		dc.w	 5,   $E,    7,	 $2C; 84
		dc.w	 5,    0,    0,	 $3C; 88
		dc.w	 1,  $46,  $23,	 $4C; 92
		dc.w	 5,  $2E,  $17,	 $54; 96
		dc.w	 5,  $3A,  $1D,	 $64; 100
		dc.w	 1,  $46,  $23,	 $74; 104
		dc.w $2005,  $12,    9,$FFF8; 108
		dc.w $2005,    4,    2,	   8; 112
		dc.w $2005,  $12,    9,	 $18; 116
		dc.w $2005,    4,    2,	 $28; 120
word_18BAC:	dc.w $F			; DATA XREF: ROM:00018676o
		dc.w $F805,  $12,    9,$FF80; 0
		dc.w $F805,  $22,  $11,$FF90; 4
		dc.w $F805,   $E,    7,$FFA0; 8
		dc.w $F805,  $2E,  $17,$FFB0; 12
		dc.w $F805,   $E,    7,$FFC0; 16
		dc.w $F805,  $1A,   $D,$FFD0; 20
		dc.w $F805,  $3E,  $1F,$FFE0; 24
		dc.w $F805,   $E,    7,$FFF0; 28
		dc.w $F805,  $42,  $21,	   0; 32
		dc.w $F805,  $48,  $24,	 $18; 36
		dc.w $F805,  $2A,  $15,	 $28; 40
		dc.w $F805,  $2E,  $17,	 $40; 44
		dc.w $F805,   $E,    7,	 $50; 48
		dc.w $F805,    0,    0,	 $60; 52
		dc.w $F805,    4,    2,	 $70; 56
word_18C26:	dc.w 8			; DATA XREF: ROM:00018678o
		dc.w $3005,  $3E,  $1F,$FFC0; 0
		dc.w $3005,  $22,  $11,$FFD0; 4
		dc.w $3005,  $2A,  $15,$FFE0; 8
		dc.w $3005,    4,    2,$FFF8; 12
		dc.w $3005,    0,    0,	   8; 16
		dc.w $3005,    4,    2,	 $18; 20
		dc.w $3001,  $46,  $23,	 $28; 24
		dc.w $3005,  $1A,   $D,	 $30; 28
word_18C68:	dc.w $11		; DATA XREF: ROM:0001867Ao
		dc.w $E805,  $2E,  $17,$FFB4; 0
		dc.w $E805,  $26,  $13,$FFC4; 4
		dc.w $E805,  $1A,   $D,$FFD4; 8
		dc.w $E801,  $46,  $23,$FFE4; 12
		dc.w $E805,  $1E,   $F,$FFEC; 16
		dc.w $E805,  $3E,  $1F,	   4; 20
		dc.w $E805,   $E,    7,	 $14; 24
		dc.w $E805,    4,    2,	 $24; 28
		dc.w $E809,    8,    4,	 $34; 32
		dc.w	 5,  $12,    9,$FFC0; 36
		dc.w	 5,  $22,  $11,$FFD0; 40
		dc.w	 5,   $E,    7,$FFE0; 44
		dc.w	 5,  $2E,  $17,$FFF0; 48
		dc.w	 5,   $E,    7,	   0; 52
		dc.w	 5,  $1A,   $D,	 $10; 56
		dc.w	 5,  $3E,  $1F,	 $20; 60
		dc.w	 5,  $2E,  $17,	 $30; 64
; ---------------------------------------------------------------------------
		nop

j_ModifySpriteAttr_2P_4:		; CODE XREF: ROM:00018610p
					; ROM:00018636p
		jmp	ModifySpriteAttr_2P
; ---------------------------------------------------------------------------
		align 4
;----------------------------------------------------
; Object 3D - GHZ Boss
;----------------------------------------------------

Obj3D:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj3D_Index(pc,d0.w),d1
		jmp	Obj3D_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj3D_Index:	dc.w Obj3D_Main-Obj3D_Index ; DATA XREF: ROM:Obj3D_Indexo
					; ROM:00018D0Co ...
		dc.w Obj3D_ShipMain-Obj3D_Index
		dc.w Obj3D_FaceMain-Obj3D_Index
		dc.w Obj3D_FlameMain-Obj3D_Index
Obj3D_ObjData:	dc.b   2,  0		; 0 ; DATA XREF: ROM:Obj3D_Maint
		dc.b   4,  1		; 2
		dc.b   6,  7		; 4
; ---------------------------------------------------------------------------

Obj3D_Main:				; DATA XREF: ROM:Obj3D_Indexo
		lea	Obj3D_ObjData(pc),a2
		movea.l	a0,a1
		moveq	#2,d1
		bra.s	loc_18D2A
; ---------------------------------------------------------------------------

loc_18D22:				; CODE XREF: ROM:00018D6Cj
		jsr	S1SingleObjectLoad2
		bne.s	loc_18D70

loc_18D2A:				; CODE XREF: ROM:00018D20j
		move.b	(a2)+,$24(a1)
		move.b	#$3D,0(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.l	#Map_Eggman,4(a1)
		move.w	#$400,2(a1)
		bsr.w	j_ModifyA1SpriteAttr_2P_1
		move.b	#4,1(a1)
		move.b	#$20,$19(a1) 
		move.b	#3,$18(a1)
		move.b	(a2)+,$1C(a1)
		move.l	a0,$34(a1)
		dbf	d1,loc_18D22

loc_18D70:				; CODE XREF: ROM:00018D28j
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$38(a0)
		move.b	#$F,$20(a0)
		move.b	#8,$21(a0)

Obj3D_ShipMain:				; DATA XREF: ROM:00018D0Co
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	Obj3D_ShipIndex(pc,d0.w),d1
		jsr	Obj3D_ShipIndex(pc,d1.w)
		lea	(Ani_Eggman).l,a1
		jsr	AnimateSprite
		move.b	$22(a0),d0
		andi.b	#3,d0
		andi.b	#$FC,1(a0)
		or.b	d0,1(a0)
		jmp	DisplaySprite
; ---------------------------------------------------------------------------
Obj3D_ShipIndex:dc.w loc_18DC8-Obj3D_ShipIndex ; DATA XREF: ROM:Obj3D_ShipIndexo
					; ROM:00018DBCo ...
		dc.w loc_18EC8-Obj3D_ShipIndex
		dc.w loc_18F18-Obj3D_ShipIndex
		dc.w loc_18F52-Obj3D_ShipIndex
		dc.w loc_18F78-Obj3D_ShipIndex
		dc.w loc_18FAA-Obj3D_ShipIndex
		dc.w loc_18FF6-Obj3D_ShipIndex
; ---------------------------------------------------------------------------

loc_18DC8:				; DATA XREF: ROM:Obj3D_ShipIndexo
		move.w	#$100,$12(a0)
		bsr.w	BossMove
		cmpi.w	#$338,$38(a0)
		bne.s	loc_18DE4
		move.w	#0,$12(a0)
		addq.b	#2,$25(a0)

loc_18DE4:				; CODE XREF: ROM:00018DD8j
					; ROM:loc_18F14j ...
		move.b	$3F(a0),d0
		jsr	(CalcSine).l
		asr.w	#6,d0
		add.w	$38(a0),d0
		move.w	d0,$C(a0)
		move.w	$30(a0),8(a0)
		addq.b	#2,$3F(a0)
		cmpi.b	#8,$25(a0)
		bcc.s	locret_18E48
		tst.b	$22(a0)
		bmi.s	loc_18E4A
		tst.b	$20(a0)
		bne.s	locret_18E48
		tst.b	$3E(a0)
		bne.s	loc_18E2C
		move.b	#$20,$3E(a0) 
		move.w	#$AC,d0	; "?"
		jsr	(PlaySound_Special).l

loc_18E2C:				; CODE XREF: ROM:00018E1Aj
		lea	($FFFFFB22).w,a1
		moveq	#0,d0
		tst.w	(a1)
		bne.s	loc_18E3A
		move.w	#$EEE,d0

loc_18E3A:				; CODE XREF: ROM:00018E34j
		move.w	d0,(a1)
		subq.b	#1,$3E(a0)
		bne.s	locret_18E48
		move.b	#$F,$20(a0)

locret_18E48:				; CODE XREF: ROM:00018E08j
					; ROM:00018E14j ...
		rts
; ---------------------------------------------------------------------------

loc_18E4A:				; CODE XREF: ROM:00018E0Ej
		moveq	#$64,d0	
		bsr.w	AddPoints
		move.b	#8,$25(a0)
		move.w	#$B3,$3C(a0) ; "?"
		rts

; =============== S U B	R O U T	I N E =======================================


BossDefeated:				; CODE XREF: ROM:00017956j
					; ROM:00018F7Ej ...
		move.b	($FFFFFE0F).w,d0
		andi.b	#7,d0
		bne.s	locret_18EA0
		jsr	(SingleObjectLoad).l
		bne.s	locret_18EA0
		move.b	#$3F,0(a1) 
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		jsr	(PseudoRandomNumber).l
		move.w	d0,d1
		moveq	#0,d1
		move.b	d0,d1
		lsr.b	#2,d1
		subi.w	#$20,d1	
		add.w	d1,8(a1)
		lsr.w	#8,d0
		lsr.b	#3,d0
		add.w	d0,$C(a1)

locret_18EA0:				; CODE XREF: BossDefeated+8j
					; BossDefeated+10j
		rts
; End of function BossDefeated


; =============== S U B	R O U T	I N E =======================================


BossMove:				; CODE XREF: ROM:00018DCEp
					; ROM:00018ED4p ...
		move.l	$30(a0),d2
		move.l	$38(a0),d3
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.w	$12(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d2,$30(a0)
		move.l	d3,$38(a0)
		rts
; End of function BossMove

; ---------------------------------------------------------------------------

loc_18EC8:				; DATA XREF: ROM:00018DBCo
		move.w	#$FF00,$10(a0)
		move.w	#$FFC0,$12(a0)
		bsr.w	BossMove
		cmpi.w	#$2A00,$30(a0)
		bne.s	loc_18F14
		move.w	#0,$10(a0)
		move.w	#0,$12(a0)
		addq.b	#2,$25(a0)
		jsr	S1SingleObjectLoad2
		bne.s	loc_18F0E
		move.b	#$48,0(a1) 
		move.w	$30(a0),8(a1)
		move.w	$38(a0),$C(a1)
		move.l	a0,$34(a1)

loc_18F0E:				; CODE XREF: ROM:00018EF6j
		move.w	#$77,$3C(a0)

loc_18F14:				; CODE XREF: ROM:00018EDEj
		bra.w	loc_18DE4
; ---------------------------------------------------------------------------

loc_18F18:				; DATA XREF: ROM:00018DBEo
		subq.w	#1,$3C(a0)
		bpl.s	loc_18F42
		addq.b	#2,$25(a0)
		move.w	#$3F,$3C(a0) 
		move.w	#$100,$10(a0)
		cmpi.w	#$2A00,$30(a0)
		bne.s	loc_18F42
		move.w	#$7F,$3C(a0) 
		move.w	#$40,$10(a0) 

loc_18F42:				; CODE XREF: ROM:00018F1Cj
					; ROM:00018F34j
		btst	#0,$22(a0)
		bne.s	loc_18F4E
		neg.w	$10(a0)

loc_18F4E:				; CODE XREF: ROM:00018F48j
		bra.w	loc_18DE4
; ---------------------------------------------------------------------------

loc_18F52:				; DATA XREF: ROM:00018DC0o
		subq.w	#1,$3C(a0)
		bmi.s	loc_18F5E
		bsr.w	BossMove
		bra.s	loc_18F74
; ---------------------------------------------------------------------------

loc_18F5E:				; CODE XREF: ROM:00018F56j
		bchg	#0,$22(a0)
		move.w	#$3F,$3C(a0) 
		subq.b	#2,$25(a0)
		move.w	#0,$10(a0)

loc_18F74:				; CODE XREF: ROM:00018F5Cj
		bra.w	loc_18DE4
; ---------------------------------------------------------------------------

loc_18F78:				; DATA XREF: ROM:00018DC2o
		subq.w	#1,$3C(a0)
		bmi.s	loc_18F82
		bra.w	BossDefeated
; ---------------------------------------------------------------------------

loc_18F82:				; CODE XREF: ROM:00018F7Cj
		bset	#0,$22(a0)
		bclr	#7,$22(a0)
		clr.w	$10(a0)
		addq.b	#2,$25(a0)
		move.w	#$FFDA,$3C(a0)
		tst.b	($FFFFF7A7).w
		bne.s	locret_18FA8
		move.b	#1,($FFFFF7A7).w

locret_18FA8:				; CODE XREF: ROM:00018FA0j
		rts
; ---------------------------------------------------------------------------

loc_18FAA:				; DATA XREF: ROM:00018DC4o
		addq.w	#1,$3C(a0)
		beq.s	loc_18FBA
		bpl.s	loc_18FC0
		addi.w	#$18,$12(a0)
		bra.s	loc_18FEE
; ---------------------------------------------------------------------------

loc_18FBA:				; CODE XREF: ROM:00018FAEj
		clr.w	$12(a0)
		bra.s	loc_18FEE
; ---------------------------------------------------------------------------

loc_18FC0:				; CODE XREF: ROM:00018FB0j
		cmpi.w	#$30,$3C(a0) 
		bcs.s	loc_18FD8
		beq.s	loc_18FE0
		cmpi.w	#$38,$3C(a0)
		bcs.s	loc_18FEE
		addq.b	#2,$25(a0)
		bra.s	loc_18FEE
; ---------------------------------------------------------------------------

loc_18FD8:				; CODE XREF: ROM:00018FC6j
		subi.w	#8,$12(a0)
		bra.s	loc_18FEE
; ---------------------------------------------------------------------------

loc_18FE0:				; CODE XREF: ROM:00018FC8j
		clr.w	$12(a0)
		move.w	#$81,d0	; "?"
		jsr	(PlaySound).l

loc_18FEE:				; CODE XREF: ROM:00018FB8j
					; ROM:00018FBEj ...
		bsr.w	BossMove
		bra.w	loc_18DE4
; ---------------------------------------------------------------------------

loc_18FF6:				; DATA XREF: ROM:00018DC6o
		move.w	#$400,$10(a0)
		move.w	#$FFC0,$12(a0)
		cmpi.w	#$2AC0,($FFFFEECA).w
		beq.s	loc_19010
		addq.w	#2,($FFFFEECA).w
		bra.s	loc_19016
; ---------------------------------------------------------------------------

loc_19010:				; CODE XREF: ROM:00019008j
		tst.b	1(a0)
		bpl.s	loc_1901E

loc_19016:				; CODE XREF: ROM:0001900Ej
		bsr.w	BossMove
		bra.w	loc_18DE4
; ---------------------------------------------------------------------------

loc_1901E:				; CODE XREF: ROM:00019014j
		addq.l	#4,sp
		jmp	DeleteObject
; ---------------------------------------------------------------------------

Obj3D_FaceMain:				; DATA XREF: ROM:00018D0Eo
		moveq	#0,d0
		moveq	#1,d1
		movea.l	$34(a0),a1
		move.b	$25(a1),d0
		subq.b	#4,d0
		bne.s	loc_19040
		cmpi.w	#$2A00,$30(a1)
		bne.s	loc_19048
		moveq	#4,d1

loc_19040:				; CODE XREF: ROM:00019034j
		subq.b	#6,d0
		bmi.s	loc_19048
		moveq	#$A,d1
		bra.s	loc_1905C
; ---------------------------------------------------------------------------

loc_19048:				; CODE XREF: ROM:0001903Cj
					; ROM:00019042j
		tst.b	$20(a1)
		bne.s	loc_19052
		moveq	#5,d1
		bra.s	loc_1905C
; ---------------------------------------------------------------------------

loc_19052:				; CODE XREF: ROM:0001904Cj
		cmpi.b	#4,(v_objspace+$24).w
		bcs.s	loc_1905C
		moveq	#4,d1

loc_1905C:				; CODE XREF: ROM:00019046j
					; ROM:00019050j ...
		move.b	d1,$1C(a0)
		subq.b	#2,d0
		bne.s	loc_19070
		move.b	#6,$1C(a0)
		tst.b	1(a0)
		bpl.s	loc_19072

loc_19070:				; CODE XREF: ROM:00019062j
		bra.s	Obj3D_Display
; ---------------------------------------------------------------------------

loc_19072:				; CODE XREF: ROM:0001906Ej
		jmp	DeleteObject
; ---------------------------------------------------------------------------

Obj3D_FlameMain:			; DATA XREF: ROM:00018D10o
		move.b	#7,$1C(a0)
		movea.l	$34(a0),a1
		cmpi.b	#$C,$25(a1)
		bne.s	loc_19098
		move.b	#$B,$1C(a0)
		tst.b	1(a0)
		bpl.s	loc_190A6
		bra.s	loc_190A4
; ---------------------------------------------------------------------------

loc_19098:				; CODE XREF: ROM:00019088j
		move.w	$10(a1),d0
		beq.s	loc_190A4
		move.b	#8,$1C(a0)

loc_190A4:				; CODE XREF: ROM:00019096j
					; ROM:0001909Cj
		bra.s	Obj3D_Display
; ---------------------------------------------------------------------------

loc_190A6:				; CODE XREF: ROM:00019094j
		jmp	DeleteObject
; ---------------------------------------------------------------------------

Obj3D_Display:				; CODE XREF: ROM:loc_19070j
					; ROM:loc_190A4j
		movea.l	$34(a0),a1
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		move.b	$22(a1),$22(a0)
		lea	(Ani_Eggman).l,a1
		jsr	AnimateSprite
		move.b	$22(a0),d0
		andi.b	#3,d0
		andi.b	#$FC,1(a0)
		or.b	d0,1(a0)
		jmp	DisplaySprite
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 48 - the ball that swings on the GHZ boss
;----------------------------------------------------

Obj48:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj48_Index(pc,d0.w),d1
		jmp	Obj48_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj48_Index:	dc.w Obj48_Init-Obj48_Index ; DATA XREF: ROM:Obj48_Indexo
					; ROM:000190F6o ...
		dc.w Obj48_Main-Obj48_Index
		dc.w loc_19226-Obj48_Index
		dc.w loc_19274-Obj48_Index
		dc.w loc_19290-Obj48_Index
; ---------------------------------------------------------------------------

Obj48_Init:				; DATA XREF: ROM:Obj48_Indexo
		addq.b	#2,$24(a0)
		move.w	#$4080,$26(a0)
		move.w	#$FE00,$3E(a0)
		move.l	#Map_BossItems,4(a0)
		move.w	#$46C,2(a0)
		bsr.w	j_ModifySpriteAttr_2P_5
		lea	$28(a0),a2
		move.b	#0,(a2)+
		moveq	#5,d1
		movea.l	a0,a1
		bra.s	loc_1916A
; ---------------------------------------------------------------------------

loc_1912E:				; CODE XREF: ROM:00019190j
		jsr	S1SingleObjectLoad2
		bne.s	loc_19194
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	#$48,0(a1) 
		move.b	#6,$24(a1)
		move.l	#$852E,4(a1)
		move.w	#$380,2(a1)
		bsr.w	j_ModifyA1SpriteAttr_2P_1
		move.b	#1,$1A(a1)
		addq.b	#1,$28(a0)

loc_1916A:				; CODE XREF: ROM:0001912Cj
		move.w	a1,d5
		subi.w	#$B000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5	
		move.b	d5,(a2)+
		move.b	#4,1(a1)
		move.b	#8,$19(a1)
		move.b	#6,$18(a1)
		move.l	$34(a0),$34(a1)
		dbf	d1,loc_1912E

loc_19194:				; CODE XREF: ROM:00019134j
		move.b	#8,$24(a1)
		move.l	#$85CA,4(a1)
		move.w	#$43AA,2(a1)
		bsr.w	j_ModifyA1SpriteAttr_2P_1
		move.b	#1,$1A(a1)
		move.b	#5,$18(a1)
		move.b	#$81,$20(a1)
		rts
; ---------------------------------------------------------------------------
Obj48_PosData:	dc.b   0,$10,$20,$30,$40,$60; 0	; DATA XREF: ROM:Obj48_Maint
; ---------------------------------------------------------------------------

Obj48_Main:				; DATA XREF: ROM:000190F6o
		lea	Obj48_PosData(pc),a3
		lea	$28(a0),a2
		moveq	#0,d6
		move.b	(a2)+,d6

loc_191D2:				; CODE XREF: ROM:loc_191ECj
		moveq	#0,d4
		move.b	(a2)+,d4
		lsl.w	#6,d4
		addi.l	#v_objspace,d4
		movea.l	d4,a1
		move.b	(a3)+,d0
		cmp.b	$3C(a1),d0
		beq.s	loc_191EC
		addq.b	#1,$3C(a1)

loc_191EC:				; CODE XREF: ROM:000191E6j
		dbf	d6,loc_191D2
		cmp.b	$3C(a1),d0
		bne.s	loc_19206
		movea.l	$34(a0),a1
		cmpi.b	#6,$25(a1)
		bne.s	loc_19206
		addq.b	#2,$24(a0)

loc_19206:				; CODE XREF: ROM:000191F4j
					; ROM:00019200j
		cmpi.w	#$20,$32(a0) 
		beq.s	loc_19212
		addq.w	#1,$32(a0)

loc_19212:				; CODE XREF: ROM:0001920Cj
		bsr.w	sub_19236
		move.b	$26(a0),d0
		jsr	loc_842E
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_19226:				; DATA XREF: ROM:000190F8o
		bsr.w	sub_19236
		jsr	loc_83EA
		jmp	DisplaySprite

; =============== S U B	R O U T	I N E =======================================


sub_19236:				; CODE XREF: ROM:loc_19212p
					; ROM:loc_19226p
		movea.l	$34(a0),a1
		addi.b	#$20,$1B(a0) 
		bcc.s	loc_19248
		bchg	#0,$1A(a0)

loc_19248:				; CODE XREF: sub_19236+Aj
		move.w	8(a1),$3A(a0)
		move.w	$C(a1),d0
		add.w	$32(a0),d0
		move.w	d0,$38(a0)
		move.b	$22(a1),$22(a0)
		tst.b	$22(a1)
		bpl.s	locret_19272
		move.b	#$3F,0(a0) 
		move.b	#0,$24(a0)

locret_19272:				; CODE XREF: sub_19236+2Ej
		rts
; End of function sub_19236

; ---------------------------------------------------------------------------

loc_19274:				; DATA XREF: ROM:000190FAo
		movea.l	$34(a0),a1
		tst.b	$22(a1)
		bpl.s	loc_1928A
		move.b	#$3F,0(a0) 
		move.b	#0,$24(a0)

loc_1928A:				; CODE XREF: ROM:0001927Cj
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_19290:				; DATA XREF: ROM:000190FCo
		moveq	#0,d0
		tst.b	$1A(a0)
		bne.s	loc_1929A
		addq.b	#1,d0

loc_1929A:				; CODE XREF: ROM:00019296j
		move.b	d0,$1A(a0)
		movea.l	$34(a0),a1
		tst.b	$22(a1)
		bpl.s	loc_192C2
		move.b	#0,$20(a0)
		bsr.w	BossDefeated
		subq.b	#1,$3C(a0)
		bpl.s	loc_192C2
		move.b	#$3F,(a0) 
		move.b	#0,$24(a0)

loc_192C2:				; CODE XREF: ROM:000192A6j
					; ROM:000192B6j
		jmp	DisplaySprite
; ---------------------------------------------------------------------------
Ani_Eggman:	dc.w byte_192E0-Ani_Eggman ; DATA XREF:	ROM:00018D96o
					; ROM:000190C2o ...
		dc.w byte_192E3-Ani_Eggman
		dc.w byte_192E7-Ani_Eggman
		dc.w byte_192EB-Ani_Eggman
		dc.w byte_192EF-Ani_Eggman
		dc.w byte_192F3-Ani_Eggman
		dc.w byte_192F7-Ani_Eggman
		dc.w byte_192FB-Ani_Eggman
		dc.w byte_192FE-Ani_Eggman
		dc.w byte_19302-Ani_Eggman
		dc.w byte_19306-Ani_Eggman
		dc.w byte_19309-Ani_Eggman
byte_192E0:	dc.b  $F,  0,$FF	; 0 ; DATA XREF: ROM:Ani_Eggmano
byte_192E3:	dc.b   5,  1,  2,$FF	; 0 ; DATA XREF: ROM:000192CAo
byte_192E7:	dc.b   3,  1,  2,$FF	; 0 ; DATA XREF: ROM:000192CCo
byte_192EB:	dc.b   1,  1,  2,$FF	; 0 ; DATA XREF: ROM:000192CEo
byte_192EF:	dc.b   4,  3,  4,$FF	; 0 ; DATA XREF: ROM:000192D0o
byte_192F3:	dc.b $1F,  5,  1,$FF	; 0 ; DATA XREF: ROM:000192D2o
byte_192F7:	dc.b   3,  6,  1,$FF	; 0 ; DATA XREF: ROM:000192D4o
byte_192FB:	dc.b  $F, $A,$FF	; 0 ; DATA XREF: ROM:000192D6o
byte_192FE:	dc.b   3,  8,  9,$FF	; 0 ; DATA XREF: ROM:000192D8o
byte_19302:	dc.b   1,  8,  9,$FF	; 0 ; DATA XREF: ROM:000192DAo
byte_19306:	dc.b  $F,  7,$FF	; 0 ; DATA XREF: ROM:000192DCo
byte_19309:	dc.b   2,  9,  8, $B, $C, $B, $C,  9,  8,$FE,  2; 0
					; DATA XREF: ROM:000192DEo
Map_Eggman:	dc.w word_1932E-Map_Eggman ; DATA XREF:	ROM:00018D40o
					; ROM:Map_Eggmano ...
		dc.w word_19360-Map_Eggman
		dc.w word_19372-Map_Eggman
		dc.w word_19384-Map_Eggman
		dc.w word_1939E-Map_Eggman
		dc.w word_193B8-Map_Eggman
		dc.w word_193D2-Map_Eggman
		dc.w word_193EC-Map_Eggman
		dc.w word_1940E-Map_Eggman
		dc.w word_19418-Map_Eggman
		dc.w word_19422-Map_Eggman
		dc.w word_19424-Map_Eggman
		dc.w word_19436-Map_Eggman
word_1932E:	dc.w 6			; DATA XREF: ROM:Map_Eggmano
		dc.w $EC01,   $A,    5,$FFE4; 0
		dc.w $EC05,   $C,    6,	  $C; 4
		dc.w $FC0E,$2010,$2008,$FFE4; 8
		dc.w $FC0E,$201C,$200E,	   4; 12
		dc.w $140C,$2028,$2014,$FFEC; 16
		dc.w $1400,$202C,$2016,	  $C; 20
word_19360:	dc.w 2			; DATA XREF: ROM:00019316o
		dc.w $E404,    0,    0,$FFF4; 0
		dc.w $EC0D,    2,    1,$FFEC; 4
word_19372:	dc.w 2			; DATA XREF: ROM:00019318o
		dc.w $E404,    0,    0,$FFF4; 0
		dc.w $EC0D,  $35,  $1A,$FFEC; 4
word_19384:	dc.w 3			; DATA XREF: ROM:0001931Ao
		dc.w $E408,  $3D,  $1E,$FFF4; 0
		dc.w $EC09,  $40,  $20,$FFEC; 4
		dc.w $EC05,  $46,  $23,	   4; 8
word_1939E:	dc.w 3			; DATA XREF: ROM:0001931Co
		dc.w $E408,  $4A,  $25,$FFF4; 0
		dc.w $EC09,  $4D,  $26,$FFEC; 4
		dc.w $EC05,  $53,  $29,	   4; 8
word_193B8:	dc.w 3			; DATA XREF: ROM:0001931Eo
		dc.w $E408,  $57,  $2B,$FFF4; 0
		dc.w $EC09,  $5A,  $2D,$FFEC; 4
		dc.w $EC05,  $60,  $30,	   4; 8
word_193D2:	dc.w 3			; DATA XREF: ROM:00019320o
		dc.w $E404,  $64,  $32,	   4; 0
		dc.w $E404,    0,    0,$FFF4; 4
		dc.w $EC0D,  $35,  $1A,$FFEC; 8
word_193EC:	dc.w 4			; DATA XREF: ROM:00019322o
		dc.w $E409,  $66,  $33,$FFF4; 0
		dc.w $E408,  $57,  $2B,$FFF4; 4
		dc.w $EC09,  $5A,  $2D,$FFEC; 8
		dc.w $EC05,  $60,  $30,	   4; 12
word_1940E:	dc.w 1			; DATA XREF: ROM:00019324o
		dc.w  $405,  $2D,  $16,	 $22; 0
word_19418:	dc.w 1			; DATA XREF: ROM:00019326o
		dc.w  $405,  $31,  $18,	 $22; 0
word_19422:	dc.w 0			; DATA XREF: ROM:00019328o
word_19424:	dc.w 2			; DATA XREF: ROM:0001932Ao
		dc.w	 8, $12A, $195,	 $22; 0
		dc.w  $808,$112A,$1995,	 $22; 4
word_19436:	dc.w 2			; DATA XREF: ROM:0001932Co
		dc.w $F80B, $12D, $199,	 $22; 0
		dc.w	 1, $139, $1AB,	 $3A; 4
Map_BossItems:	dc.w word_19458-Map_BossItems ;	DATA XREF: ROM:0001910Eo
					; ROM:Map_BossItemso ...
		dc.w word_19462-Map_BossItems
		dc.w word_19474-Map_BossItems
		dc.w word_1947E-Map_BossItems
		dc.w word_19488-Map_BossItems
		dc.w word_19492-Map_BossItems
		dc.w word_194B4-Map_BossItems
		dc.w word_194C6-Map_BossItems
word_19458:	dc.w 1			; DATA XREF: ROM:Map_BossItemso
		dc.w $F805,    0,    0,$FFF8; 0
word_19462:	dc.w 2			; DATA XREF: ROM:0001944Ao
		dc.w $FC04,    4,    2,$FFF8; 0
		dc.w $F805,    0,    0,$FFF8; 4
word_19474:	dc.w 1			; DATA XREF: ROM:0001944Co
		dc.w $FC00,    6,    3,$FFFC; 0
word_1947E:	dc.w 1			; DATA XREF: ROM:0001944Eo
		dc.w $1409,    7,    3,$FFF4; 0
word_19488:	dc.w 1			; DATA XREF: ROM:00019450o
		dc.w $1405,   $D,    6,$FFF8; 0
word_19492:	dc.w 4			; DATA XREF: ROM:00019452o
		dc.w $F004,  $11,    8,$FFF8; 0
		dc.w $F801,  $13,    9,$FFF8; 4
		dc.w $F801, $813, $809,	   0; 8
		dc.w  $804,  $15,   $A,$FFF8; 12
word_194B4:	dc.w 2			; DATA XREF: ROM:00019454o
		dc.w	 5,  $17,   $B,	   0; 0
		dc.w	 0,  $1B,   $D,	 $10; 4
word_194C6:	dc.w 2			; DATA XREF: ROM:00019456o
		dc.w $1804,  $1C,   $E,	   0; 0
		dc.w	$B,  $1E,   $F,	 $10; 4
; ---------------------------------------------------------------------------

j_ModifyA1SpriteAttr_2P_1:		; CODE XREF: ROM:00018D4Ep
					; ROM:0001915Cp ...
		jmp	ModifyA1SpriteAttr_2P
; ---------------------------------------------------------------------------

j_ModifySpriteAttr_2P_5:		; CODE XREF: ROM:0001911Cp
		jmp	ModifySpriteAttr_2P
; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 3E - prison capsule
;----------------------------------------------------

Obj3E:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj3E_Index(pc,d0.w),d1
		jsr	Obj3E_Index(pc,d1.w)
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		sub.w	($FFFFF7DA).w,d0
		cmpi.w	#$280,d0
		bhi.s	loc_1950A
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_1950A:				; CODE XREF: ROM:00019502j
		jmp	DeleteObject
; ---------------------------------------------------------------------------
Obj3E_Index:	dc.w Obj3E_Init-Obj3E_Index ; DATA XREF: ROM:Obj3E_Indexo
					; ROM:00019512o ...
		dc.w Obj3E_BodyMain-Obj3E_Index
		dc.w Obj3E_Switched-Obj3E_Index
		dc.w Obj3E_Explosion-Obj3E_Index
		dc.w Obj3E_Explosion-Obj3E_Index
		dc.w Obj3E_Explosion-Obj3E_Index
		dc.w Obj3E_Animals-Obj3E_Index
		dc.w Obj3E_EndAct-Obj3E_Index
Obj3E_Var:	dc.b   2,$20,  4,  0	; 0
		dc.b   4, $C,  5,  1	; 4
		dc.b   6,$10,  4,  3	; 8
		dc.b   8,$10,  3,  5	; 12
; ---------------------------------------------------------------------------

Obj3E_Init:				; DATA XREF: ROM:Obj3E_Indexo
		move.l	#Map_Obj3E,4(a0)
		move.w	#$49D,2(a0)
		bsr.w	j_ModifySpriteAttr_2P_6
		move.b	#4,1(a0)
		move.w	$C(a0),$30(a0)
		moveq	#0,d0
		move.b	$28(a0),d0
		lsl.w	#2,d0
		lea	Obj3E_Var(pc,d0.w),a1
		move.b	(a1)+,$24(a0)
		move.b	(a1)+,$19(a0)
		move.b	(a1)+,$18(a0)
		move.b	(a1)+,$1A(a0)
		cmpi.w	#8,d0
		bne.s	locret_1957C
		move.b	#6,$20(a0)
		move.b	#8,$21(a0)

locret_1957C:				; CODE XREF: ROM:0001956Ej
		rts
; ---------------------------------------------------------------------------

Obj3E_BodyMain:				; DATA XREF: ROM:00019512o
		cmpi.b	#2,($FFFFF7A7).w
		beq.s	loc_1959C
		move.w	#$2B,d1	
		move.w	#$18,d2
		move.w	#$18,d3
		move.w	8(a0),d4
		jmp	SolidObject
; ---------------------------------------------------------------------------

loc_1959C:				; CODE XREF: ROM:00019584j
		tst.b	$25(a0)
		beq.s	loc_195B2
		clr.b	$25(a0)
		bclr	#3,(v_objspace+$22).w
		bset	#1,(v_objspace+$22).w

loc_195B2:				; CODE XREF: ROM:000195A0j
		move.b	#2,$1A(a0)
		rts
; ---------------------------------------------------------------------------

Obj3E_Switched:				; DATA XREF: ROM:00019514o
		move.w	#$17,d1
		move.w	#8,d2
		move.w	#8,d3
		move.w	8(a0),d4
		jsr	SolidObject
		lea	(Ani_Obj3E).l,a1
		jsr	AnimateSprite
		move.w	$30(a0),$C(a0)
		move.b	$22(a0),d0
		andi.b	#$18,d0
		beq.s	locret_19620
		addq.w	#8,$C(a0)
		move.b	#$A,$24(a0)
		move.w	#$3C,$1E(a0) 
		clr.b	($FFFFFE1E).w
		clr.b	($FFFFF7AA).w
		move.b	#1,($FFFFF7CC).w
		move.w	#$800,(v_jpadhold2).w
		clr.b	$25(a0)
		bclr	#3,(v_objspace+$22).w
		bset	#1,(v_objspace+$22).w

locret_19620:				; CODE XREF: ROM:000195EAj
		rts
; ---------------------------------------------------------------------------

Obj3E_Explosion:			; DATA XREF: ROM:00019516o
					; ROM:00019518o ...
		moveq	#7,d0
		and.b	($FFFFFE0F).w,d0
		bne.s	loc_19660
		jsr	(SingleObjectLoad).l
		bne.s	loc_19660
		move.b	#$3F,0(a1) 
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		jsr	(PseudoRandomNumber).l
		moveq	#0,d1
		move.b	d0,d1
		lsr.b	#2,d1
		subi.w	#$20,d1	
		add.w	d1,8(a1)
		lsr.w	#8,d0
		lsr.b	#3,d0
		add.w	d0,$C(a1)

loc_19660:				; CODE XREF: ROM:00019628j
					; ROM:00019630j
		subq.w	#1,$1E(a0)
		beq.s	loc_19668
		rts
; ---------------------------------------------------------------------------

loc_19668:				; CODE XREF: ROM:00019664j
		move.b	#2,($FFFFF7A7).w
		move.b	#$C,$24(a0)
		move.b	#6,$1A(a0)
		move.w	#$96,$1E(a0) ; "?"
		addi.w	#$20,$C(a0) 
		moveq	#7,d6
		move.w	#$9A,d5	; "?"
		moveq	#$FFFFFFE4,d4

loc_1968E:				; CODE XREF: ROM:000196B4j
		jsr	(SingleObjectLoad).l
		bne.s	locret_196B8
		move.b	#$28,0(a1) 
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		add.w	d4,8(a1)
		addq.w	#7,d4
		move.w	d5,$36(a1)
		subq.w	#8,d5
		dbf	d6,loc_1968E

locret_196B8:				; CODE XREF: ROM:00019694j
		rts
; ---------------------------------------------------------------------------

Obj3E_Animals:				; DATA XREF: ROM:0001951Co
		moveq	#7,d0
		and.b	($FFFFFE0F).w,d0
		bne.s	loc_196F8
		jsr	(SingleObjectLoad).l
		bne.s	loc_196F8
		move.b	#$28,0(a1) 
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		jsr	(PseudoRandomNumber).l
		andi.w	#$1F,d0
		subq.w	#6,d0
		tst.w	d1
		bpl.s	loc_196EE
		neg.w	d0

loc_196EE:				; CODE XREF: ROM:000196EAj
		add.w	d0,8(a1)
		move.w	#$C,$36(a1)

loc_196F8:				; CODE XREF: ROM:000196C0j
					; ROM:000196C8j
		subq.w	#1,$1E(a0)
		bne.s	locret_19708
		addq.b	#2,$24(a0)
		move.w	#$B4,$1E(a0) ; "?"

locret_19708:				; CODE XREF: ROM:000196FCj
		rts
; ---------------------------------------------------------------------------

Obj3E_EndAct:				; DATA XREF: ROM:0001951Eo
		moveq	#$3E,d0
		moveq	#$28,d1	
		moveq	#$40,d2	
		lea	(v_objspace+$40).w,a1

loc_19714:				; CODE XREF: ROM:0001971Aj
		cmp.b	(a1),d1
		beq.s	locret_1972A
		adda.w	d2,a1
		dbf	d0,loc_19714
		jsr	GotThroughAct
		jmp	DeleteObject
; ---------------------------------------------------------------------------

locret_1972A:				; CODE XREF: ROM:00019716j
		rts
; ---------------------------------------------------------------------------
Ani_Obj3E:	dc.w byte_19730-Ani_Obj3E ; DATA XREF: ROM:000195D0o
					; ROM:Ani_Obj3Eo ...
		dc.w byte_19730-Ani_Obj3E
byte_19730:	dc.b   2,  1,  3,$FF	; 0 ; DATA XREF: ROM:Ani_Obj3Eo
					; ROM:0001972Eo
Map_Obj3E:	dc.w word_19742-Map_Obj3E ; DATA XREF: ROM:Obj3E_Inito
					; ROM:Map_Obj3Eo ...
		dc.w word_1977C-Map_Obj3E
		dc.w word_19786-Map_Obj3E
		dc.w word_197B8-Map_Obj3E
		dc.w word_197C2-Map_Obj3E
		dc.w word_197D4-Map_Obj3E
		dc.w unk_197DE-Map_Obj3E
word_19742:	dc.w 7			; DATA XREF: ROM:Map_Obj3Eo
		dc.w $E00C,$2000,$2000,$FFF0; 0
		dc.w $E80D,$2004,$2002,$FFE0; 4
		dc.w $E80D,$200C,$2006,	   0; 8
		dc.w $F80E,$2014,$200A,$FFE0; 12
		dc.w $F80E,$2020,$2010,	   0; 16
		dc.w $100D,$202C,$2016,$FFE0; 20
		dc.w $100D,$2034,$201A,	   0; 24
word_1977C:	dc.w 1			; DATA XREF: ROM:00019736o
		dc.w $F809,  $3C,  $1E,$FFF4; 0
word_19786:	dc.w 6			; DATA XREF: ROM:00019738o
		dc.w	 8,$2042,$2021,$FFE0; 0
		dc.w  $80C,$2045,$2022,$FFE0; 4
		dc.w	 4,$2049,$2024,	 $10; 8
		dc.w  $80C,$204B,$2025,	   0; 12
		dc.w $100D,$202C,$2016,$FFE0; 16
		dc.w $100D,$2034,$201A,	   0; 20
word_197B8:	dc.w 1			; DATA XREF: ROM:0001973Ao
		dc.w $F809,  $4F,  $27,$FFF4; 0
word_197C2:	dc.w 2			; DATA XREF: ROM:0001973Co
		dc.w $E80E,$2055,$202A,$FFF0; 0
		dc.w	$E,$2061,$2030,$FFF0; 4
word_197D4:	dc.w 1			; DATA XREF: ROM:0001973Eo
		dc.w $F007,$206D,$2036,$FFF8; 0
unk_197DE:	dc.b   0		; DATA XREF: ROM:00019740o
		dc.b   0
; ---------------------------------------------------------------------------

j_ModifySpriteAttr_2P_6:		; CODE XREF: ROM:0001953Ep
		jmp	ModifySpriteAttr_2P
; ---------------------------------------------------------------------------
		align 4

; =============== S U B	R O U T	I N E =======================================


TouchResponse:				; CODE XREF: ROM:0000FB08p
					; ROM:00010CF6p

; FUNCTION CHUNK AT 00019B02 SIZE 00000070 BYTES

		nop
		bsr.w	loc_19B7A
		move.w	8(a0),d2
		move.w	$C(a0),d3
		subi.w	#8,d2
		moveq	#0,d5
		move.b	$16(a0),d5
		subq.b	#3,d5
		sub.w	d5,d3
		cmpi.b	#$39,$1A(a0)
		bne.s	loc_19812
		addi.w	#$C,d3
		moveq	#$A,d5

loc_19812:				; CODE XREF: TouchResponse+22j
		move.w	#$10,d4
		add.w	d5,d5
		lea	(v_objspace+$800).w,a1
		move.w	#$5F,d6

loc_19820:				; CODE XREF: TouchResponse+42j
		move.b	$20(a1),d0
		bne.s	Touch_Height

loc_19826:				; CODE XREF: TouchResponse+B0j
					; TouchResponse+B6j ...
		lea	$40(a1),a1
		dbf	d6,loc_19820
		moveq	#0,d0

locret_19830:
		rts
; ---------------------------------------------------------------------------
Touch_Sizes:	dc.b $14,$14		; 0 ; DATA XREF: TouchResponse+98t
		dc.b  $C,$14		; 2
		dc.b $14, $C		; 4
		dc.b   4,$10		; 6
		dc.b  $C,$12		; 8
		dc.b $10,$10		; 10
		dc.b   6,  6		; 12
		dc.b $18, $C		; 14
		dc.b  $C,$10		; 16
		dc.b $10, $C		; 18
		dc.b   8,  8		; 20
		dc.b $14,$10		; 22
		dc.b $14,  8		; 24
		dc.b  $E, $E		; 26
		dc.b $18,$18		; 28
		dc.b $28,$10		; 30
		dc.b $10,$18		; 32
		dc.b   8,$10		; 34
		dc.b $20,$70		; 36
		dc.b $40,$20		; 38
		dc.b $80,$20		; 40
		dc.b $20,$20		; 42
		dc.b   8,  8		; 44
		dc.b   4,  4		; 46
		dc.b $20,  8		; 48
		dc.b  $C, $C		; 50
		dc.b   8,  4		; 52
		dc.b $18,  4		; 54
		dc.b $28,  4		; 56
		dc.b   4,  8		; 58
		dc.b   4,$18		; 60
		dc.b   4,$28		; 62
		dc.b   4,$20		; 64
		dc.b $18,$18		; 66
		dc.b  $C,$18		; 68
		dc.b $48,  8		; 70
; ---------------------------------------------------------------------------

Touch_Height:				; CODE XREF: TouchResponse+3Cj
		andi.w	#$3F,d0	
		add.w	d0,d0
		lea	Touch_Sizes-2(pc,d0.w),a2
		moveq	#0,d1
		move.b	(a2)+,d1
		move.w	8(a1),d0
		sub.w	d1,d0
		sub.w	d2,d0
		bcc.s	loc_1989C
		add.w	d1,d1
		add.w	d1,d0
		bcs.s	loc_198A2
		bra.w	loc_19826
; ---------------------------------------------------------------------------

loc_1989C:				; CODE XREF: TouchResponse+A8j
		cmp.w	d4,d0
		bhi.w	loc_19826

loc_198A2:				; CODE XREF: TouchResponse+AEj
		moveq	#0,d1
		move.b	(a2)+,d1
		move.w	$C(a1),d0
		sub.w	d1,d0
		sub.w	d3,d0
		bcc.s	loc_198BA
		add.w	d1,d1
		add.w	d1,d0
		bcs.s	loc_198C0
		bra.w	loc_19826
; ---------------------------------------------------------------------------

loc_198BA:				; CODE XREF: TouchResponse+C6j
		cmp.w	d5,d0
		bhi.w	loc_19826

loc_198C0:				; CODE XREF: TouchResponse+CCj
		move.b	$20(a1),d1
		andi.b	#$C0,d1
		beq.w	loc_1993A
		cmpi.b	#$C0,d1
		beq.w	Touch_Special
		tst.b	d1
		bmi.w	loc_199F2
		move.b	$20(a1),d0
		andi.b	#$3F,d0	
		cmpi.b	#6,d0
		beq.s	loc_198FA
		cmpi.w	#$5A,$30(a0)
		bcc.w	locret_198F8
		move.b	#4,$24(a1)

locret_198F8:				; CODE XREF: TouchResponse+106j
		rts
; ---------------------------------------------------------------------------

loc_198FA:				; CODE XREF: TouchResponse+FEj
		tst.w	$12(a0)
		bpl.s	loc_19926
		move.w	$C(a0),d0
		subi.w	#$10,d0
		cmp.w	$C(a1),d0
		bcs.s	locret_19938

loc_1990E:
		neg.w	$12(a0)

loc_19912:
		move.w	#$FE80,$12(a1)
		tst.b	$25(a1)
		bne.s	locret_19938
		move.b	#4,$25(a1)
		rts
; ---------------------------------------------------------------------------

loc_19926:				; CODE XREF: TouchResponse+116j
		cmpi.b	#2,$1C(a0)
		bne.s	locret_19938
		neg.w	$12(a0)
		move.b	#4,$24(a1)

locret_19938:				; CODE XREF: TouchResponse+124j
					; TouchResponse+134j ...
		rts
; ---------------------------------------------------------------------------

loc_1993A:				; CODE XREF: TouchResponse+E0j
					; TouchResponse:loc_19B56j
		tst.b	($FFFFFE2D).w
		bne.s	loc_19952
		cmpi.b	#9,$1C(a0)
		beq.s	loc_19952
		cmpi.b	#2,$1C(a0)
		bne.w	loc_199F2

loc_19952:				; CODE XREF: TouchResponse+156j
					; TouchResponse+15Ej
		tst.b	$21(a1)
		beq.s	Touch_KillEnemy
		neg.w	$10(a0)
		neg.w	$12(a0)
		asr	$10(a0)
		asr	$12(a0)
		move.b	#0,$20(a1)
		subq.b	#1,$21(a1)
		bne.s	locret_1997A
		bset	#7,$22(a1)

locret_1997A:				; CODE XREF: TouchResponse+18Aj
		rts
; ---------------------------------------------------------------------------

Touch_KillEnemy:			; CODE XREF: TouchResponse+16Ej
		bset	#7,$22(a1)
		moveq	#0,d0
		move.w	($FFFFF7D0).w,d0
		addq.w	#2,($FFFFF7D0).w
		cmpi.w	#6,d0
		bcs.s	loc_19994
		moveq	#6,d0

loc_19994:				; CODE XREF: TouchResponse+1A8j
		move.w	d0,$3E(a1)
		move.w	Enemy_Points(pc,d0.w),d0
		cmpi.w	#$20,($FFFFF7D0).w 
		bcs.s	loc_199AE
		move.w	#$3E8,d0
		move.w	#$A,$3E(a1)

loc_199AE:				; CODE XREF: TouchResponse+1BAj
		bsr.w	AddPoints
		move.b	#$27,0(a1) 
		move.b	#0,$24(a1)
		tst.w	$12(a0)
		bmi.s	loc_199D4
		move.w	$C(a0),d0
		cmp.w	$C(a1),d0
		bcc.s	loc_199DC
		neg.w	$12(a0)
		rts
; ---------------------------------------------------------------------------

loc_199D4:				; CODE XREF: TouchResponse+1DAj
		addi.w	#$100,$12(a0)
		rts
; ---------------------------------------------------------------------------

loc_199DC:				; CODE XREF: TouchResponse+1E4j
		subi.w	#$100,$12(a0)
		rts
; ---------------------------------------------------------------------------
Enemy_Points:
		dc.w	10,   20,   50,	 100; 0
; ---------------------------------------------------------------------------

loc_199EC:				; CODE XREF: TouchResponse:Touch_Caterkillerj
		bset	#7,$22(a1)

loc_199F2:				; CODE XREF: TouchResponse+EEj
					; TouchResponse+166j ...
		tst.b	($FFFFFE2D).w
		beq.s	Touch_Hurt

loc_199F8:				; CODE XREF: TouchResponse+21Aj
		moveq	#$FFFFFFFF,d0
		rts
; ---------------------------------------------------------------------------

Touch_Hurt:				; CODE XREF: TouchResponse+20Ej
		nop
		tst.w	$30(a0)
		bne.s	loc_199F8
		movea.l	a1,a2
; End of function TouchResponse


; =============== S U B	R O U T	I N E =======================================


HurtSonic:				; CODE XREF: ROM:0000C75Ep
		tst.b	($FFFFFE2C).w
		bne.s	HurtShield
		tst.w	($FFFFFE20).w

loc_19A10:
		beq.w	Hurt_NoRings
		jsr	(SingleObjectLoad).l
		bne.s	HurtShield
		move.b	#$37,0(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)

HurtShield:				; CODE XREF: HurtSonic+4j
					; HurtSonic+14j ...
		move.b	#0,($FFFFFE2C).w
		move.b	#4,$24(a0)
		bsr.w	j_Sonic_ResetOnFloor
		bset	#1,$22(a0)
		move.w	#$FC00,$12(a0)
		move.w	#$FE00,$10(a0)
		btst	#6,$22(a0)
		beq.s	Hurt_Reverse
		move.w	#$FE00,$12(a0)
		move.w	#$FF00,$10(a0)

Hurt_Reverse:				; CODE XREF: HurtSonic+50j
		move.w	8(a0),d0
		cmp.w	8(a2),d0
		bcs.s	Hurt_ChkSpikes
		neg.w	$10(a0)

Hurt_ChkSpikes:				; CODE XREF: HurtSonic+66j
		move.w	#0,$14(a0)
		move.b	#$1A,$1C(a0)
		move.w	#$78,$30(a0)
		move.w	#$A3,d0	; "?"
		cmpi.b	#$36,(a2) 
		bne.s	loc_19A98
		cmpi.b	#$16,(a2)
		bne.s	loc_19A98
		move.w	#$A6,d0	; "?"

loc_19A98:				; CODE XREF: HurtSonic+86j
					; HurtSonic+8Cj
		jsr	(PlaySound_Special).l
		moveq	#$FFFFFFFF,d0
		rts
; ---------------------------------------------------------------------------

Hurt_NoRings:				; CODE XREF: HurtSonic:loc_19A10j
		tst.w	($FFFFFFFA).w
		bne.w	HurtShield
; End of function HurtSonic


; =============== S U B	R O U T	I N E =======================================


KillSonic:				; CODE XREF: sub_F456+268p
					; Sonic_LevelBoundaries:j_KillSonicj ...
		tst.w	($FFFFFE08).w
		bne.s	Kill_NoDeath
		move.b	#0,($FFFFFE2D).w
		move.b	#6,$24(a0)
		bsr.w	j_Sonic_ResetOnFloor
		bset	#1,$22(a0)
		move.w	#$F900,$12(a0)
		move.w	#0,$10(a0)
		move.w	#0,$14(a0)
		move.w	$C(a0),$38(a0)
		move.b	#$18,$1C(a0)
		bset	#7,2(a0)
		move.w	#$A3,d0	; "?"
		cmpi.b	#$36,(a2)
		bne.s	loc_19AF8
		move.w	#$A6,d0	; "?"

loc_19AF8:				; CODE XREF: KillSonic+48j
		jsr	(PlaySound_Special).l

Kill_NoDeath:				; CODE XREF: KillSonic+4j
		moveq	#$FFFFFFFF,d0
		rts
; End of function KillSonic

; ---------------------------------------------------------------------------
; START	OF FUNCTION CHUNK FOR TouchResponse

Touch_Special:				; CODE XREF: TouchResponse+E8j
		move.b	$20(a1),d1
		andi.b	#$3F,d1	
		cmpi.b	#$B,d1
		beq.s	Touch_Caterkiller
		cmpi.b	#$C,d1
		beq.s	Touch_Yadrin
		cmpi.b	#$17,d1
		beq.s	Touch_D7
		cmpi.b	#$21,d1
		beq.s	Touch_E1
		rts
; ---------------------------------------------------------------------------

Touch_Caterkiller:			; CODE XREF: TouchResponse+326j
		bra.w	loc_199EC
; ---------------------------------------------------------------------------

Touch_Yadrin:				; CODE XREF: TouchResponse+32Cj
		sub.w	d0,d5
		cmpi.w	#8,d5
		bcc.s	loc_19B56
		move.w	8(a1),d0
		subq.w	#4,d0
		btst	#0,$22(a1)
		beq.s	loc_19B42
		subi.w	#$10,d0

loc_19B42:				; CODE XREF: TouchResponse+354j
		sub.w	d2,d0
		bcc.s	loc_19B4E
		addi.w	#$18,d0
		bcs.s	loc_19B52
		bra.s	loc_19B56
; ---------------------------------------------------------------------------

loc_19B4E:				; CODE XREF: TouchResponse+35Cj
		cmp.w	d4,d0
		bhi.s	loc_19B56

loc_19B52:				; CODE XREF: TouchResponse+362j
		bra.w	loc_199F2
; ---------------------------------------------------------------------------

loc_19B56:				; CODE XREF: TouchResponse+346j
					; TouchResponse+364j ...
		bra.w	loc_1993A
; ---------------------------------------------------------------------------

Touch_D7:				; CODE XREF: TouchResponse+332j
		move.w	a0,d1
		subi.w	#$B000,d1
		beq.s	loc_19B66
		addq.b	#1,$21(a1)

loc_19B66:				; CODE XREF: TouchResponse+378j
		addq.b	#1,$21(a1)
		rts
; ---------------------------------------------------------------------------

Touch_E1:				; CODE XREF: TouchResponse+338j
		addq.b	#1,$21(a1)
		rts
; END OF FUNCTION CHUNK	FOR TouchResponse
; ---------------------------------------------------------------------------
		nop

j_Sonic_ResetOnFloor:			; CODE XREF: HurtSonic+34p
					; KillSonic+12p
		jmp	Sonic_ResetOnFloor
; ---------------------------------------------------------------------------

loc_19B7A:				; CODE XREF: TouchResponse+2p
		jmp	sub_D998

; =============== S U B	R O U T	I N E =======================================

; leftover from	Sonic 1

S1SS_ShowLayout:			; CODE XREF: ROM:0000518Ep
					; ROM:000051FAp
		bsr.w	sub_19CC2
		bsr.w	sub_19F02
		move.w	d5,-(sp)
		lea	($FFFF8000).w,a1
		move.b	($FFFFF780).w,d0
		andi.b	#$FC,d0
		jsr	(CalcSine).l
		move.w	d0,d4
		move.w	d1,d5
		muls.w	#$18,d4
		muls.w	#$18,d5
		moveq	#0,d2
		move.w	(v_screenposx).w,d2
		divu.w	#$18,d2
		swap	d2
		neg.w	d2
		addi.w	#$FF4C,d2
		moveq	#0,d3
		move.w	(v_screenposy).w,d3
		divu.w	#$18,d3
		swap	d3
		neg.w	d3
		addi.w	#$FF4C,d3
		move.w	#$F,d7

loc_19BD0:				; CODE XREF: S1SS_ShowLayout+8Ej
		movem.w	d0-d2,-(sp)
		movem.w	d0-d1,-(sp)
		neg.w	d0
		muls.w	d2,d1
		muls.w	d3,d0
		move.l	d0,d6
		add.l	d1,d6
		movem.w	(sp)+,d0-d1
		muls.w	d2,d0
		muls.w	d3,d1
		add.l	d0,d1
		move.l	d6,d2
		move.w	#$F,d6

loc_19BF2:				; CODE XREF: S1SS_ShowLayout+82j
		move.l	d2,d0
		asr.l	#8,d0
		move.w	d0,(a1)+
		move.l	d1,d0
		asr.l	#8,d0
		move.w	d0,(a1)+
		add.l	d5,d2
		add.l	d4,d1
		dbf	d6,loc_19BF2
		movem.w	(sp)+,d0-d2
		addi.w	#$18,d3
		dbf	d7,loc_19BD0
		move.w	(sp)+,d5
		lea	($FFFF0000).l,a0
		moveq	#0,d0
		move.w	(v_screenposy).w,d0
		divu.w	#$18,d0
		mulu.w	#$80,d0	
		adda.l	d0,a0
		moveq	#0,d0
		move.w	(v_screenposx).w,d0
		divu.w	#$18,d0
		adda.w	d0,a0
		lea	($FFFF8000).w,a4
		move.w	#$F,d7

loc_19C3E:				; CODE XREF: S1SS_ShowLayout+124j
		move.w	#$F,d6

loc_19C42:				; CODE XREF: S1SS_ShowLayout+11Cj
		moveq	#0,d0
		move.b	(a0)+,d0
		beq.s	loc_19C9A
		cmpi.b	#$4E,d0
		bhi.s	loc_19C9A
		move.w	(a4),d3
		addi.w	#$120,d3
		cmpi.w	#$70,d3	
		bcs.s	loc_19C9A
		cmpi.w	#$1D0,d3
		bcc.s	loc_19C9A
		move.w	2(a4),d2
		addi.w	#$F0,d2	; "?"
		cmpi.w	#$70,d2	
		bcs.s	loc_19C9A
		cmpi.w	#$170,d2
		bcc.s	loc_19C9A
		lea	($FFFF4000).l,a5
		lsl.w	#3,d0
		lea	(a5,d0.w),a5
		movea.l	(a5)+,a1
		move.w	(a5)+,d1
		add.w	d1,d1
		adda.w	(a1,d1.w),a1
		movea.w	(a5)+,a3
		moveq	#0,d1
		move.b	(a1)+,d1
		subq.b	#1,d1
		bmi.s	loc_19C9A
		jsr	loc_D1CE

loc_19C9A:				; CODE XREF: S1SS_ShowLayout+C6j
					; S1SS_ShowLayout+CCj ...
		addq.w	#4,a4
		dbf	d6,loc_19C42
		lea	$70(a0),a0
		dbf	d7,loc_19C3E
		move.b	d5,($FFFFF62C).w
		cmpi.b	#$50,d5	
		beq.s	loc_19CBA
		move.l	#0,(a2)
		rts
; ---------------------------------------------------------------------------

loc_19CBA:				; CODE XREF: S1SS_ShowLayout+130j
		move.b	#0,-5(a2)
		rts
; End of function S1SS_ShowLayout


; =============== S U B	R O U T	I N E =======================================


sub_19CC2:				; CODE XREF: S1SS_ShowLayoutp
		lea	($FFFF400C).l,a1
		moveq	#0,d0
		move.b	($FFFFF780).w,d0
		lsr.b	#2,d0
		andi.w	#$F,d0
		moveq	#$23,d1

loc_19CD6:				; CODE XREF: sub_19CC2+18j
		move.w	d0,(a1)
		addq.w	#8,a1
		dbf	d1,loc_19CD6
		lea	($FFFF4005).l,a1
		subq.b	#1,($FFFFFEC2).w
		bpl.s	loc_19CFA
		move.b	#7,($FFFFFEC2).w
		addq.b	#1,($FFFFFEC3).w
		andi.b	#3,($FFFFFEC3).w

loc_19CFA:				; CODE XREF: sub_19CC2+26j
		move.b	($FFFFFEC3).w,$1D0(a1)
		subq.b	#1,($FFFFFEC4).w
		bpl.s	loc_19D16
		move.b	#7,($FFFFFEC4).w
		addq.b	#1,($FFFFFEC5).w
		andi.b	#1,($FFFFFEC5).w

loc_19D16:				; CODE XREF: sub_19CC2+42j
		move.b	($FFFFFEC5).w,d0
		move.b	d0,$138(a1)

loc_19D1E:
		move.b	d0,$160(a1)
		move.b	d0,$148(a1)
		move.b	d0,$150(a1)
		move.b	d0,$1D8(a1)
		move.b	d0,$1E0(a1)
		move.b	d0,$1E8(a1)
		move.b	d0,$1F0(a1)
		move.b	d0,$1F8(a1)
		move.b	d0,$200(a1)
		subq.b	#1,($FFFFFEC6).w
		bpl.s	loc_19D58
		move.b	#4,($FFFFFEC6).w
		addq.b	#1,($FFFFFEC7).w
		andi.b	#3,($FFFFFEC7).w

loc_19D58:				; CODE XREF: sub_19CC2+84j
		move.b	($FFFFFEC7).w,d0
		move.b	d0,$168(a1)
		move.b	d0,$170(a1)
		move.b	d0,$178(a1)
		move.b	d0,$180(a1)
		subq.b	#1,($FFFFFEC0).w
		bpl.s	loc_19D82
		move.b	#7,($FFFFFEC0).w
		subq.b	#1,($FFFFFEC1).w
		andi.b	#7,($FFFFFEC1).w

loc_19D82:				; CODE XREF: sub_19CC2+AEj
		lea	($FFFF4016).l,a1
		lea	(S1SS_WaRiVramSet).l,a0
		moveq	#0,d0
		move.b	($FFFFFEC1).w,d0
		add.w	d0,d0
		lea	(a0,d0.w),a0
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),$20(a1)
		move.w	$A(a0),$28(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0	
		adda.w	#$48,a1	
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),$20(a1)
		move.w	$A(a0),$28(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0	
		adda.w	#$48,a1	
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),$20(a1)
		move.w	$A(a0),$28(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0	
		adda.w	#$48,a1	
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),$20(a1)
		move.w	$A(a0),$28(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0	
		adda.w	#$48,a1
		rts
; End of function sub_19CC2

; ---------------------------------------------------------------------------
S1SS_WaRiVramSet:dc.w  $142,$6142, $142, $142, $142, $142, $142,$6142; 0
					; DATA XREF: sub_19CC2+C6o
		dc.w  $142,$6142, $142,	$142, $142, $142, $142,$6142; 8
		dc.w $2142, $142,$2142,$2142,$2142,$2142,$2142,	$142; 16
		dc.w $2142, $142,$2142,$2142,$2142,$2142,$2142,	$142; 24
		dc.w $4142,$2142,$4142,$4142,$4142,$4142,$4142,$2142; 32
		dc.w $4142,$2142,$4142,$4142,$4142,$4142,$4142,$2142; 40
		dc.w $6142,$4142,$6142,$6142,$6142,$6142,$6142,$4142; 48
		dc.w $6142,$4142,$6142,$6142,$6142,$6142,$6142,$4142; 56

; =============== S U B	R O U T	I N E =======================================


sub_19EEC:				; CODE XREF: Obj09_ChkItems+40p
					; Obj09_ChkItems+7Cp ...
		lea	($FFFF4400).l,a2
		move.w	#$1F,d0

loc_19EF6:				; CODE XREF: sub_19EEC+10j
		tst.b	(a2)
		beq.s	locret_19F00
		addq.w	#8,a2
		dbf	d0,loc_19EF6

locret_19F00:				; CODE XREF: sub_19EEC+Cj
		rts
; End of function sub_19EEC


; =============== S U B	R O U T	I N E =======================================


sub_19F02:				; CODE XREF: S1SS_ShowLayout+4p
		lea	($FFFF4400).l,a0
		move.w	#$1F,d7

loc_19F0C:				; CODE XREF: sub_19F02:loc_19F1Cj
		moveq	#0,d0
		move.b	(a0),d0
		beq.s	loc_19F1A
		lsl.w	#2,d0
		movea.l	S1SS_AniIndex-4(pc,d0.w),a1
		jsr	(a1)

loc_19F1A:				; CODE XREF: sub_19F02+Ej
		addq.w	#8,a0

loc_19F1C:
		dbf	d7,loc_19F0C
		rts
; End of function sub_19F02

; ---------------------------------------------------------------------------
S1SS_AniIndex:	dc.l loc_19F3A		; DATA XREF: sub_19F02+12t
		dc.l loc_19F6A
		dc.l loc_19FA0
		dc.l loc_19FD0
		dc.l loc_1A006
		dc.l loc_1A046
; ---------------------------------------------------------------------------

loc_19F3A:				; DATA XREF: ROM:S1SS_AniIndexo
		subq.b	#1,2(a0)
		bpl.s	locret_19F62
		move.b	#5,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	byte_19F64(pc,d0.w),d0
		move.b	d0,(a1)
		bne.s	locret_19F62
		clr.l	(a0)
		clr.l	4(a0)

locret_19F62:				; CODE XREF: ROM:00019F3Ej
					; ROM:00019F5Aj
		rts
; ---------------------------------------------------------------------------
byte_19F64:	dc.b $42,$43,$44,$45,  0,  0; 0
; ---------------------------------------------------------------------------

loc_19F6A:				; DATA XREF: ROM:00019F26o
		subq.b	#1,2(a0)
		bpl.s	locret_19F98
		move.b	#7,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	byte_19F9A(pc,d0.w),d0
		bne.s	loc_19F96
		clr.l	(a0)
		clr.l	4(a0)
		move.b	#$25,(a1) 
		rts
; ---------------------------------------------------------------------------

loc_19F96:				; CODE XREF: ROM:00019F88j
		move.b	d0,(a1)

locret_19F98:				; CODE XREF: ROM:00019F6Ej
		rts
; ---------------------------------------------------------------------------
byte_19F9A:	dc.b $32,$33,$32,$33,  0,  0; 0
; ---------------------------------------------------------------------------

loc_19FA0:				; DATA XREF: ROM:00019F2Ao
		subq.b	#1,2(a0)
		bpl.s	locret_19FC8
		move.b	#5,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	byte_19FCA(pc,d0.w),d0
		move.b	d0,(a1)
		bne.s	locret_19FC8
		clr.l	(a0)
		clr.l	4(a0)

locret_19FC8:				; CODE XREF: ROM:00019FA4j
					; ROM:00019FC0j
		rts
; ---------------------------------------------------------------------------
byte_19FCA:	dc.b $46,$47,$48,$49,  0,  0; 0
; ---------------------------------------------------------------------------

loc_19FD0:				; DATA XREF: ROM:00019F2Eo
		subq.b	#1,2(a0)
		bpl.s	locret_19FFE
		move.b	#7,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	byte_1A000(pc,d0.w),d0
		bne.s	loc_19FFC
		clr.l	(a0)
		clr.l	4(a0)
		move.b	#$2B,(a1) 
		rts
; ---------------------------------------------------------------------------

loc_19FFC:				; CODE XREF: ROM:00019FEEj
		move.b	d0,(a1)

locret_19FFE:				; CODE XREF: ROM:00019FD4j
		rts
; ---------------------------------------------------------------------------
byte_1A000:	dc.b $2B,$31,$2B,$31,  0,  0; 0
; ---------------------------------------------------------------------------

loc_1A006:				; DATA XREF: ROM:00019F32o
		subq.b	#1,2(a0)
		bpl.s	locret_1A03E
		move.b	#5,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	byte_1A040(pc,d0.w),d0
		move.b	d0,(a1)
		bne.s	locret_1A03E
		clr.l	(a0)
		clr.l	4(a0)
		move.b	#4,(v_objspace+$24).w
		move.w	#$A8,d0	; "?"
		jsr	(PlaySound_Special).l

locret_1A03E:				; CODE XREF: ROM:0001A00Aj
					; ROM:0001A026j
		rts
; ---------------------------------------------------------------------------
byte_1A040:	dc.b $46,$47,$48,$49,  0,  0; 0
; ---------------------------------------------------------------------------

loc_1A046:				; DATA XREF: ROM:00019F36o
		subq.b	#1,2(a0)
		bpl.s	locret_1A072
		move.b	#1,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	byte_1A074(pc,d0.w),d0
		move.b	d0,(a1)
		bne.s	locret_1A072
		move.b	4(a0),(a1)
		clr.l	(a0)
		clr.l	4(a0)

locret_1A072:				; CODE XREF: ROM:0001A04Aj
					; ROM:0001A066j
		rts
; ---------------------------------------------------------------------------
byte_1A074:	dc.b $4B,$4C,$4D,$4E,$4B,$4C,$4D,$4E; 0
		dc.b   0,  0		; 8
S1SS_LayoutIndex:dc.l S1SS_1,S1SS_2	 ; 0
		dc.l S1SS_3,S1SS_4	; 2
		dc.l S1SS_5,S1SS_6	; 4
S1SS_StartLoc:	dc.w  $3D0, $2E0	; 0
		dc.w  $328, $574	; 2
		dc.w  $4E4, $2E0	; 4
		dc.w  $3AD, $2E0	; 6
		dc.w  $340, $6B8	; 8
		dc.w  $49B, $358	; 10

; =============== S U B	R O U T	I N E =======================================


S1SS_Load:				; CODE XREF: ROM:000050E0p
					; S1SS_Load+34j
		moveq	#0,d0
		move.b	($FFFFFE16).w,d0
		addq.b	#1,($FFFFFE16).w
		cmpi.b	#6,($FFFFFE16).w
		bcs.s	loc_1A0C6
		move.b	#0,($FFFFFE16).w

loc_1A0C6:				; CODE XREF: S1SS_Load+10j
		cmpi.b	#6,($FFFFFE57).w
		beq.s	loc_1A0E8
		moveq	#0,d1
		move.b	($FFFFFE57).w,d1
		subq.b	#1,d1
		bcs.s	loc_1A0E8
		lea	($FFFFFE58).w,a3

loc_1A0DC:				; CODE XREF: S1SS_Load:loc_1A0E4j
		cmp.b	(a3,d1.w),d0
		bne.s	loc_1A0E4
		bra.s	S1SS_Load
; ---------------------------------------------------------------------------

loc_1A0E4:				; CODE XREF: S1SS_Load+32j
		dbf	d1,loc_1A0DC

loc_1A0E8:				; CODE XREF: S1SS_Load+1Ej
					; S1SS_Load+28j
		lsl.w	#2,d0
		lea	S1SS_StartLoc(pc,d0.w),a1
		move.w	(a1)+,(v_objspace+8).w
		move.w	(a1)+,(v_objspace+$C).w
		movea.l	S1SS_LayoutIndex(pc,d0.w),a0
		lea	($FFFF4000).l,a1
		move.w	#0,d0
		jsr	(EniDec).l
		lea	($FFFF0000).l,a1
		move.w	#$FFF,d0

loc_1A114:				; CODE XREF: S1SS_Load+68j
		clr.l	(a1)+
		dbf	d0,loc_1A114
		lea	($FFFF1020).l,a1
		lea	($FFFF4000).l,a0
		moveq	#$3F,d1	

loc_1A128:				; CODE XREF: S1SS_Load+86j
		moveq	#$3F,d2	

loc_1A12A:				; CODE XREF: S1SS_Load+7Ej
		move.b	(a0)+,(a1)+
		dbf	d2,loc_1A12A
		lea	$40(a1),a1
		dbf	d1,loc_1A128
		lea	($FFFF4008).l,a1
		lea	(S1SS_MapIndex).l,a0
		moveq	#$4D,d1

loc_1A146:				; CODE XREF: S1SS_Load+A6j
		move.l	(a0)+,(a1)+
		move.w	#0,(a1)+
		move.b	-4(a0),-1(a1)
		move.w	(a0)+,(a1)+
		dbf	d1,loc_1A146
		lea	($FFFF4400).l,a1
		move.w	#$3F,d1	

loc_1A162:				; CODE XREF: S1SS_Load+B6j
		clr.l	(a1)+
		dbf	d1,loc_1A162
		rts
; End of function S1SS_Load

; ---------------------------------------------------------------------------
S1SS_MapIndex:	dc.l S1Map_SS_R		; DATA XREF: S1SS_Load+90o
		dc.w $142
		dc.l S1Map_SS_R
		dc.w $142
		dc.l S1Map_SS_R
		dc.w $142
		dc.l S1Map_SS_R
		dc.w $142
		dc.l S1Map_SS_R
		dc.w $142
		dc.l S1Map_SS_R
		dc.w $142
		dc.l S1Map_SS_R
		dc.w $142
		dc.l S1Map_SS_R
		dc.w $142
		dc.l S1Map_SS_R
		dc.w $142
		dc.l S1Map_SS_R
		dc.w $2142
		dc.l S1Map_SS_R
		dc.w $2142
		dc.l S1Map_SS_R
		dc.w $2142
		dc.l S1Map_SS_R
		dc.w $2142
		dc.l S1Map_SS_R
		dc.w $2142
		dc.l S1Map_SS_R
		dc.w $2142
		dc.l S1Map_SS_R
		dc.w $2142
		dc.l S1Map_SS_R
		dc.w $2142
		dc.l S1Map_SS_R
		dc.w $2142
		dc.l S1Map_SS_R
		dc.w $4142
		dc.l S1Map_SS_R
		dc.w $4142
		dc.l S1Map_SS_R
		dc.w $4142
		dc.l S1Map_SS_R
		dc.w $4142
		dc.l S1Map_SS_R
		dc.w $4142
		dc.l S1Map_SS_R
		dc.w $4142
		dc.l S1Map_SS_R
		dc.w $4142
		dc.l S1Map_SS_R
		dc.w $4142
		dc.l S1Map_SS_R
		dc.w $4142
		dc.l S1Map_SS_R
		dc.w $6142
		dc.l S1Map_SS_R
		dc.w $6142
		dc.l S1Map_SS_R
		dc.w $6142
		dc.l S1Map_SS_R
		dc.w $6142
		dc.l S1Map_SS_R
		dc.w $6142
		dc.l S1Map_SS_R
		dc.w $6142
		dc.l S1Map_SS_R
		dc.w $6142
		dc.l S1Map_SS_R
		dc.w $6142
		dc.l S1Map_SS_R
		dc.w $6142
		dc.l Map_S1Obj47
		dc.w $23B
		dc.l S1Map_SS_R
		dc.w $570
		dc.l S1Map_SS_R
		dc.w $251
		dc.l S1Map_SS_R
		dc.w $370
		dc.l S1Map_SS_Up
		dc.w $263
		dc.l S1Map_SS_Down
		dc.w $263
		dc.l S1Map_SS_R
		dc.w $22F0
		dc.l S1Map_SS_Glass
		dc.w $470
		dc.l S1Map_SS_Glass
		dc.w $5F0
		dc.l S1Map_SS_Glass
		dc.w $65F0
		dc.l S1Map_SS_Glass
		dc.w $25F0
		dc.l S1Map_SS_Glass
		dc.w $45F0
		dc.l S1Map_SS_R
		dc.w $2F0
		dc.l Map_S1Obj47+$1000000
		dc.w $23B
		dc.l Map_S1Obj47+$2000000
		dc.w $23B
		dc.l S1Map_SS_R
		dc.w $797
		dc.l S1Map_SS_R
		dc.w $7A0
		dc.l S1Map_SS_R
		dc.w $7A9
		dc.l S1Map_SS_R
		dc.w $797
		dc.l S1Map_SS_R
		dc.w $7A0
		dc.l S1Map_SS_R
		dc.w $7A9
		dc.l Map_Obj25
		dc.w $27B2
		dc.l S1Map_SS_Chaos3
		dc.w $770
		dc.l S1Map_SS_Chaos3
		dc.w $2770
		dc.l S1Map_SS_Chaos3
		dc.w $4770
		dc.l S1Map_SS_Chaos3
		dc.w $6770
		dc.l S1Map_SS_Chaos1
		dc.w $770
		dc.l S1Map_SS_Chaos2
		dc.w $770
		dc.l S1Map_SS_R
		dc.w $4F0
		dc.l Map_Obj25+$4000000
		dc.w $27B2
		dc.l Map_Obj25+$5000000
		dc.w $27B2
		dc.l Map_Obj25+$6000000
		dc.w $27B2
		dc.l Map_Obj25+$7000000
		dc.w $27B2
		dc.l S1Map_SS_Glass
		dc.w $23F0
		dc.l S1Map_SS_Glass+$1000000
		dc.w $23F0
		dc.l S1Map_SS_Glass+$2000000
		dc.w $23F0
		dc.l S1Map_SS_Glass+$3000000
		dc.w $23F0
		dc.l S1Map_SS_R+$2000000
		dc.w $4F0
		dc.l S1Map_SS_Glass
		dc.w $5F0
		dc.l S1Map_SS_Glass
		dc.w $65F0
		dc.l S1Map_SS_Glass
		dc.w $25F0
		dc.l S1Map_SS_Glass
		dc.w $45F0
;
; this is actually pretty funny, sonic 1 format	mappings
;
; ps. sonic 1 special stages code sucks	and i always hated it
;
S1Map_SS_R:	dc.w byte_1A344-S1Map_SS_R ; DATA XREF:	ROM:S1SS_MapIndexo
					; ROM:0001A170o ...
		dc.w byte_1A34A-S1Map_SS_R
		dc.w word_1A350-S1Map_SS_R
byte_1A344:	dc.b 1			; DATA XREF: ROM:S1Map_SS_Ro
		dc.b $F4, $A,  0,  0,$F4; 0
byte_1A34A:	dc.b 1			; DATA XREF: ROM:0001A340o
		dc.b $F4, $A,  0,  9,$F4; 0
word_1A350:	dc.w 0			; DATA XREF: ROM:0001A342o
S1Map_SS_Glass:	dc.w byte_1A35A-S1Map_SS_Glass ; DATA XREF: ROM:0001A26Co
					; ROM:0001A272o ...
		dc.w byte_1A360-S1Map_SS_Glass
		dc.w byte_1A366-S1Map_SS_Glass
		dc.w byte_1A36C-S1Map_SS_Glass
byte_1A35A:	dc.b 1			; DATA XREF: ROM:S1Map_SS_Glasso
		dc.b $F4, $A,  0,  0,$F4; 0
byte_1A360:	dc.b 1			; DATA XREF: ROM:0001A354o
		dc.b $F4, $A,  8,  0,$F4; 0
byte_1A366:	dc.b 1			; DATA XREF: ROM:0001A356o
		dc.b $F4, $A,$18,  0,$F4; 0
byte_1A36C:	dc.b 1			; DATA XREF: ROM:0001A358o
		dc.b $F4, $A,$10,  0,$F4; 0
S1Map_SS_Up:	dc.w byte_1A376-S1Map_SS_Up ; DATA XREF: ROM:0001A25Ao
					; ROM:S1Map_SS_Upo ...
		dc.w byte_1A37C-S1Map_SS_Up
byte_1A376:	dc.b 1			; DATA XREF: ROM:S1Map_SS_Upo
		dc.b $F4, $A,  0,  0,$F4; 0
byte_1A37C:	dc.b 1			; DATA XREF: ROM:0001A374o
		dc.b $F4, $A,  0,$12,$F4; 0
S1Map_SS_Down:	dc.w byte_1A386-S1Map_SS_Down ;	DATA XREF: ROM:0001A260o
					; ROM:S1Map_SS_Downo ...
		dc.w byte_1A38C-S1Map_SS_Down
byte_1A386:	dc.b 1			; DATA XREF: ROM:S1Map_SS_Downo
		dc.b $F4, $A,  0,  9,$F4; 0
byte_1A38C:	dc.b 1			; DATA XREF: ROM:0001A384o
		dc.b $F4, $A,  0,$12,$F4; 0
S1Map_SS_Chaos1:dc.w byte_1A39E-S1Map_SS_Chaos1	; DATA XREF: ROM:0001A2DEo
					; ROM:S1Map_SS_Chaos1o	...
		dc.w byte_1A3B0-S1Map_SS_Chaos1
S1Map_SS_Chaos2:dc.w byte_1A3A4-S1Map_SS_Chaos2	; DATA XREF: ROM:0001A2E4o
					; ROM:S1Map_SS_Chaos2o	...
		dc.w byte_1A3B0-S1Map_SS_Chaos2
S1Map_SS_Chaos3:dc.w byte_1A3AA-S1Map_SS_Chaos3	; DATA XREF: ROM:0001A2C6o
					; ROM:0001A2CCo ...
		dc.w byte_1A3B0-S1Map_SS_Chaos3
byte_1A39E:	dc.b 1			; DATA XREF: ROM:S1Map_SS_Chaos1o
		dc.b $F8,  5,  0,  0,$F8; 0
byte_1A3A4:	dc.b 1			; DATA XREF: ROM:S1Map_SS_Chaos2o
		dc.b $F8,  5,  0,  4,$F8; 0
byte_1A3AA:	dc.b 1			; DATA XREF: ROM:S1Map_SS_Chaos3o
		dc.b $F8,  5,  0,  8,$F8; 0
byte_1A3B0:	dc.b 1			; DATA XREF: ROM:0001A394o
					; ROM:0001A398o ...
		dc.b $F8,  5,  0, $C,$F8; 0
; ---------------------------------------------------------------------------
		nop
;----------------------------------------------------
; Object 09 - Sonic in Sonic 1 special stage
;----------------------------------------------------

Obj09:					; DATA XREF: ROM:Obj_Indexo
		tst.w	($FFFFFE08).w
		beq.s	Obj09_Normal
		bsr.w	S1SS_FixCamera
		bra.w	DebugMode
; ---------------------------------------------------------------------------

Obj09_Normal:				; CODE XREF: ROM:0001A3BCj
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj09_Index(pc,d0.w),d1
		jmp	Obj09_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj09_Index:	dc.w loc_1A3DC-Obj09_Index ; DATA XREF:	ROM:Obj09_Indexo
					; ROM:0001A3D6o ...
		dc.w loc_1A41C-Obj09_Index
		dc.w loc_1A618-Obj09_Index
		dc.w loc_1A66C-Obj09_Index
; ---------------------------------------------------------------------------

loc_1A3DC:				; DATA XREF: ROM:Obj09_Indexo
		addq.b	#2,$24(a0)
		move.b	#$E,$16(a0)
		move.b	#7,$17(a0)
		move.l	#Map_Sonic,4(a0)
		move.w	#$780,2(a0)
		bsr.w	j_ModifySpriteAttr_2P_7
		move.b	#4,1(a0)
		move.b	#0,$18(a0)
		move.b	#2,$1C(a0)
		bset	#2,$22(a0)
		bset	#1,$22(a0)

loc_1A41C:				; DATA XREF: ROM:0001A3D6o
		tst.w	($FFFFFFFA).w
		beq.s	loc_1A430
		btst	#4,(v_jpadpress1).w
		beq.s	loc_1A430
		move.w	#1,($FFFFFE08).w

loc_1A430:				; CODE XREF: ROM:0001A420j
					; ROM:0001A428j
		move.b	#0,$30(a0)
		moveq	#0,d0
		move.b	$22(a0),d0
		andi.w	#2,d0
		move.w	Obj09_Modes(pc,d0.w),d1
		jsr	Obj09_Modes(pc,d1.w)
		jsr	LoadSonicDynPLC
		jmp	DisplaySprite
; ---------------------------------------------------------------------------
Obj09_Modes:	dc.w Obj09_OnWall-Obj09_Modes ;	DATA XREF: ROM:Obj09_Modeso
					; ROM:0001A456o
		dc.w Obj09_InAir-Obj09_Modes
; ---------------------------------------------------------------------------

Obj09_OnWall:				; DATA XREF: ROM:Obj09_Modeso
		bsr.w	Obj09_Jump
		bsr.w	Obj09_Move
		bsr.w	Obj09_Fall
		bra.s	Obj09_Display
; ---------------------------------------------------------------------------

Obj09_InAir:				; DATA XREF: ROM:0001A456o
		bsr.w	nullsub_2
		bsr.w	Obj09_Move
		bsr.w	Obj09_Fall

Obj09_Display:				; CODE XREF: ROM:0001A464j
		bsr.w	Obj09_ChkItems
		bsr.w	OBj09_ChkItems2
		jsr	SpeedToPos
		bsr.w	S1SS_FixCamera
		move.w	($FFFFF780).w,d0
		add.w	($FFFFF782).w,d0
		move.w	d0,($FFFFF780).w
		jsr	Sonic_Animate
		rts

; =============== S U B	R O U T	I N E =======================================


Obj09_Move:				; CODE XREF: ROM:0001A45Cp
					; ROM:0001A46Ap
		btst	#2,(v_jpadhold2).w
		beq.s	loc_1A4A4
		bsr.w	Obj09_MoveLeft

loc_1A4A4:				; CODE XREF: Obj09_Move+6j
		btst	#3,(v_jpadhold2).w
		beq.s	loc_1A4B0
		bsr.w	Obj09_MoveRight

loc_1A4B0:				; CODE XREF: Obj09_Move+12j
		move.b	(v_jpadhold2).w,d0
		andi.b	#$C,d0
		bne.s	loc_1A4E0
		move.w	$14(a0),d0
		beq.s	loc_1A4E0
		bmi.s	loc_1A4D2
		subi.w	#$C,d0
		bcc.s	loc_1A4CC
		move.w	#0,d0

loc_1A4CC:				; CODE XREF: Obj09_Move+2Ej
		move.w	d0,$14(a0)
		bra.s	loc_1A4E0
; ---------------------------------------------------------------------------

loc_1A4D2:				; CODE XREF: Obj09_Move+28j
		addi.w	#$C,d0
		bcc.s	loc_1A4DC
		move.w	#0,d0

loc_1A4DC:				; CODE XREF: Obj09_Move+3Ej
		move.w	d0,$14(a0)

loc_1A4E0:				; CODE XREF: Obj09_Move+20j
					; Obj09_Move+26j ...
		move.b	($FFFFF780).w,d0
		addi.b	#$20,d0	
		andi.b	#$C0,d0
		neg.b	d0
		jsr	(CalcSine).l
		muls.w	$14(a0),d1
		add.l	d1,8(a0)
		muls.w	$14(a0),d0
		add.l	d0,$C(a0)
		movem.l	d0-d1,-(sp)
		move.l	$C(a0),d2
		move.l	8(a0),d3
		bsr.w	sub_1A720
		beq.s	loc_1A52A
		movem.l	(sp)+,d0-d1
		sub.l	d1,8(a0)
		sub.l	d0,$C(a0)
		move.w	#0,$14(a0)
		rts
; ---------------------------------------------------------------------------

loc_1A52A:				; CODE XREF: Obj09_Move+7Cj
		movem.l	(sp)+,d0-d1
		rts
; End of function Obj09_Move


; =============== S U B	R O U T	I N E =======================================


Obj09_MoveLeft:				; CODE XREF: Obj09_Move+8p
		bset	#0,$22(a0)
		move.w	$14(a0),d0
		beq.s	loc_1A53E
		bpl.s	loc_1A552

loc_1A53E:				; CODE XREF: Obj09_MoveLeft+Aj
		subi.w	#$C,d0
		cmpi.w	#$F800,d0
		bgt.s	loc_1A54C
		move.w	#$F800,d0

loc_1A54C:				; CODE XREF: Obj09_MoveLeft+16j
		move.w	d0,$14(a0)
		rts
; ---------------------------------------------------------------------------

loc_1A552:				; CODE XREF: Obj09_MoveLeft+Cj
		subi.w	#$40,d0	
		bcc.s	loc_1A55A
		nop

loc_1A55A:				; CODE XREF: Obj09_MoveLeft+26j
		move.w	d0,$14(a0)
		rts
; End of function Obj09_MoveLeft


; =============== S U B	R O U T	I N E =======================================


Obj09_MoveRight:			; CODE XREF: Obj09_Move+14p
		bclr	#0,$22(a0)
		move.w	$14(a0),d0
		bmi.s	loc_1A580
		addi.w	#$C,d0
		cmpi.w	#$800,d0
		blt.s	loc_1A57A
		move.w	#$800,d0

loc_1A57A:				; CODE XREF: Obj09_MoveRight+14j
		move.w	d0,$14(a0)
		bra.s	locret_1A58C
; ---------------------------------------------------------------------------

loc_1A580:				; CODE XREF: Obj09_MoveRight+Aj
		addi.w	#$40,d0	
		bcc.s	loc_1A588
		nop

loc_1A588:				; CODE XREF: Obj09_MoveRight+24j
		move.w	d0,$14(a0)

locret_1A58C:				; CODE XREF: Obj09_MoveRight+1Ej
		rts
; End of function Obj09_MoveRight


; =============== S U B	R O U T	I N E =======================================


Obj09_Jump:				; CODE XREF: ROM:Obj09_OnWallp
		move.b	(v_jpadpress2).w,d0
		andi.b	#$70,d0	
		beq.s	locret_1A5D0
		move.b	($FFFFF780).w,d0
		andi.b	#$FC,d0
		neg.b	d0
		subi.b	#$40,d0	
		jsr	(CalcSine).l
		muls.w	#$680,d1
		asr.l	#8,d1
		move.w	d1,$10(a0)
		muls.w	#$680,d0
		asr.l	#8,d0
		move.w	d0,$12(a0)
		bset	#1,$22(a0)
		move.w	#$A0,d0	
		jsr	(PlaySound_Special).l

locret_1A5D0:				; CODE XREF: Obj09_Jump+8j
		rts
; End of function Obj09_Jump


; =============== S U B	R O U T	I N E =======================================


nullsub_2:				; CODE XREF: ROM:Obj09_InAirp
		rts
; End of function nullsub_2

; ---------------------------------------------------------------------------
		move.w	#$FC00,d1
		cmp.w	$12(a0),d1
		ble.s	locret_1A5EC
		move.b	(v_jpadhold2).w,d0
		andi.b	#$70,d0	
		bne.s	locret_1A5EC
		move.w	d1,$12(a0)

locret_1A5EC:				; CODE XREF: ROM:0001A5DCj
					; ROM:0001A5E6j
		rts

; =============== S U B	R O U T	I N E =======================================


S1SS_FixCamera:				; CODE XREF: ROM:0001A3BEp
					; ROM:0001A480p ...
		move.w	$C(a0),d2
		move.w	8(a0),d3
		move.w	(v_screenposx).w,d0
		subi.w	#$A0,d3
		bcs.s	loc_1A606
		sub.w	d3,d0
		sub.w	d0,(v_screenposx).w

loc_1A606:				; CODE XREF: S1SS_FixCamera+10j
		move.w	(v_screenposy).w,d0
		subi.w	#$70,d2	
		bcs.s	locret_1A616
		sub.w	d2,d0
		sub.w	d0,(v_screenposy).w

locret_1A616:				; CODE XREF: S1SS_FixCamera+20j
		rts
; End of function S1SS_FixCamera

; ---------------------------------------------------------------------------

loc_1A618:				; DATA XREF: ROM:0001A3D8o
		addi.w	#$40,($FFFFF782).w 
		cmpi.w	#$1800,($FFFFF782).w
		bne.s	loc_1A62C
		move.b	#$C,(v_gamemode).w

loc_1A62C:				; CODE XREF: ROM:0001A624j
		cmpi.w	#$3000,($FFFFF782).w
		blt.s	loc_1A64A
		move.w	#0,($FFFFF782).w
		move.w	#$4000,($FFFFF780).w
		addq.b	#2,$24(a0)
		move.w	#$3C,$38(a0) 

loc_1A64A:				; CODE XREF: ROM:0001A632j
		move.w	($FFFFF780).w,d0
		add.w	($FFFFF782).w,d0
		move.w	d0,($FFFFF780).w
		jsr	Sonic_Animate
		jsr	LoadSonicDynPLC
		bsr.w	S1SS_FixCamera
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_1A66C:				; DATA XREF: ROM:0001A3DAo
		subq.w	#1,$38(a0)
		bne.s	loc_1A678
		move.b	#$C,(v_gamemode).w

loc_1A678:				; CODE XREF: ROM:0001A670j
		jsr	Sonic_Animate
		jsr	LoadSonicDynPLC
		bsr.w	S1SS_FixCamera
		jmp	DisplaySprite

; =============== S U B	R O U T	I N E =======================================


Obj09_Fall:				; CODE XREF: ROM:0001A460p
					; ROM:0001A46Ep
		move.l	$C(a0),d2
		move.l	8(a0),d3
		move.b	($FFFFF780).w,d0
		andi.b	#$FC,d0
		jsr	(CalcSine).l
		move.w	$10(a0),d4
		ext.l	d4
		asl.l	#8,d4
		muls.w	#$2A,d0	
		add.l	d4,d0
		move.w	$12(a0),d4
		ext.l	d4
		asl.l	#8,d4
		muls.w	#$2A,d1	
		add.l	d4,d1
		add.l	d0,d3
		bsr.w	sub_1A720
		beq.s	loc_1A6E8
		sub.l	d0,d3
		moveq	#0,d0
		move.w	d0,$10(a0)
		bclr	#1,$22(a0)
		add.l	d1,d2
		bsr.w	sub_1A720
		beq.s	loc_1A6FE
		sub.l	d1,d2
		moveq	#0,d1
		move.w	d1,$12(a0)
		rts
; ---------------------------------------------------------------------------

loc_1A6E8:				; CODE XREF: Obj09_Fall+38j
		add.l	d1,d2
		bsr.w	sub_1A720
		beq.s	loc_1A70C
		sub.l	d1,d2
		moveq	#0,d1
		move.w	d1,$12(a0)
		bclr	#1,$22(a0)

loc_1A6FE:				; CODE XREF: Obj09_Fall+4Ej
		asr.l	#8,d0
		asr.l	#8,d1
		move.w	d0,$10(a0)
		move.w	d1,$12(a0)
		rts
; ---------------------------------------------------------------------------

loc_1A70C:				; CODE XREF: Obj09_Fall+60j
		asr.l	#8,d0
		asr.l	#8,d1
		move.w	d0,$10(a0)
		move.w	d1,$12(a0)
		bset	#1,$22(a0)
		rts
; End of function Obj09_Fall


; =============== S U B	R O U T	I N E =======================================


sub_1A720:				; CODE XREF: Obj09_Move+78p
					; Obj09_Fall+34p ...
		lea	($FFFF0000).l,a1
		moveq	#0,d4
		swap	d2
		move.w	d2,d4
		swap	d2
		addi.w	#$44,d4	
		divu.w	#$18,d4
		mulu.w	#$80,d4	
		adda.l	d4,a1
		moveq	#0,d4
		swap	d3
		move.w	d3,d4
		swap	d3
		addi.w	#$14,d4
		divu.w	#$18,d4
		adda.w	d4,a1
		moveq	#0,d5
		move.b	(a1)+,d4
		bsr.s	sub_1A768
		move.b	(a1)+,d4
		bsr.s	sub_1A768
		adda.w	#$7E,a1	; "~"
		move.b	(a1)+,d4
		bsr.s	sub_1A768
		move.b	(a1)+,d4
		bsr.s	sub_1A768
		tst.b	d5
		rts
; End of function sub_1A720


; =============== S U B	R O U T	I N E =======================================


sub_1A768:				; CODE XREF: sub_1A720+32p
					; sub_1A720+36p ...
		beq.s	locret_1A77C
		cmpi.b	#$28,d4	
		beq.s	locret_1A77C
		cmpi.b	#$3A,d4	
		bcs.s	loc_1A77E
		cmpi.b	#$4B,d4
		bcc.s	loc_1A77E

locret_1A77C:				; CODE XREF: sub_1A768j sub_1A768+6j
		rts
; ---------------------------------------------------------------------------

loc_1A77E:				; CODE XREF: sub_1A768+Cj
					; sub_1A768+12j
		move.b	d4,$30(a0)
		move.l	a1,$32(a0)
		moveq	#$FFFFFFFF,d5
		rts
; End of function sub_1A768


; =============== S U B	R O U T	I N E =======================================


Obj09_ChkItems:				; CODE XREF: ROM:Obj09_Displayp
		lea	($FFFF0000).l,a1
		moveq	#0,d4
		move.w	$C(a0),d4
		addi.w	#$50,d4	
		divu.w	#$18,d4
		mulu.w	#$80,d4
		adda.l	d4,a1
		moveq	#0,d4
		move.w	8(a0),d4
		addi.w	#$20,d4
		divu.w	#$18,d4
		adda.w	d4,a1
		move.b	(a1),d4
		bne.s	loc_1A7C4
		tst.b	$3A(a0)
		bne.w	loc_1A894
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------

loc_1A7C4:				; CODE XREF: Obj09_ChkItems+2Cj
		cmpi.b	#$3A,d4
		bne.s	loc_1A800
		bsr.w	sub_19EEC
		bne.s	loc_1A7D8
		move.b	#1,(a2)
		move.l	a1,4(a2)

loc_1A7D8:				; CODE XREF: Obj09_ChkItems+44j
		jsr	sub_A8DE
		cmpi.w	#$32,($FFFFFE20).w
		bcs.s	loc_1A7FC
		bset	#0,($FFFFFE1B).w
		bne.s	loc_1A7FC
		addq.b	#1,($FFFFFE18).w
		move.w	#$BF,d0	; "?"
		jsr	(PlaySound).l

loc_1A7FC:				; CODE XREF: Obj09_ChkItems+5Aj
					; Obj09_ChkItems+62j
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------

loc_1A800:				; CODE XREF: Obj09_ChkItems+3Ej
		cmpi.b	#$28,d4
		bne.s	loc_1A82A
		bsr.w	sub_19EEC
		bne.s	loc_1A814
		move.b	#3,(a2)
		move.l	a1,4(a2)

loc_1A814:				; CODE XREF: Obj09_ChkItems+80j
		addq.b	#1,($FFFFFE12).w
		addq.b	#1,($FFFFFE1C).w
		move.w	#$88,d0	; "?"
		jsr	(PlaySound).l
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------

loc_1A82A:				; CODE XREF: Obj09_ChkItems+7Aj
		cmpi.b	#$3B,d4	
		bcs.s	loc_1A870
		cmpi.b	#$40,d4
		bhi.s	loc_1A870
		bsr.w	sub_19EEC
		bne.s	loc_1A844
		move.b	#5,(a2)
		move.l	a1,4(a2)

loc_1A844:				; CODE XREF: Obj09_ChkItems+B0j
		cmpi.b	#6,($FFFFFE57).w
		beq.s	loc_1A862
		subi.b	#$3B,d4
		moveq	#0,d0
		move.b	($FFFFFE57).w,d0
		lea	($FFFFFE58).w,a2
		move.b	d4,(a2,d0.w)
		addq.b	#1,($FFFFFE57).w

loc_1A862:				; CODE XREF: Obj09_ChkItems+C0j
		move.w	#$93,d0	; "?"
		jsr	(PlaySound_Special).l
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------

loc_1A870:				; CODE XREF: Obj09_ChkItems+A4j
					; Obj09_ChkItems+AAj
		cmpi.b	#$41,d4	
		bne.s	loc_1A87C
		move.b	#1,$3A(a0)

loc_1A87C:				; CODE XREF: Obj09_ChkItems+EAj
		cmpi.b	#$4A,d4
		bne.s	loc_1A890
		cmpi.b	#1,$3A(a0)
		bne.s	loc_1A890
		move.b	#2,$3A(a0)

loc_1A890:				; CODE XREF: Obj09_ChkItems+F6j
					; Obj09_ChkItems+FEj
		moveq	#$FFFFFFFF,d4
		rts
; ---------------------------------------------------------------------------

loc_1A894:				; CODE XREF: Obj09_ChkItems+32j
		cmpi.b	#2,$3A(a0)
		bne.s	loc_1A8BE
		lea	($FFFF1020).l,a1
		moveq	#$3F,d1	

loc_1A8A4:				; CODE XREF: Obj09_ChkItems+130j
		moveq	#$3F,d2

loc_1A8A6:				; CODE XREF: Obj09_ChkItems+128j
		cmpi.b	#$41,(a1)
		bne.s	loc_1A8B0
		move.b	#$2C,(a1)

loc_1A8B0:				; CODE XREF: Obj09_ChkItems+120j
		addq.w	#1,a1
		dbf	d2,loc_1A8A6
		lea	$40(a1),a1
		dbf	d1,loc_1A8A4

loc_1A8BE:				; CODE XREF: Obj09_ChkItems+110j
		clr.b	$3A(a0)
		moveq	#0,d4
		rts
; End of function Obj09_ChkItems


; =============== S U B	R O U T	I N E =======================================


OBj09_ChkItems2:			; CODE XREF: ROM:0001A476p
		move.b	$30(a0),d0
		bne.s	loc_1A8E6
		subq.b	#1,$36(a0)
		bpl.s	loc_1A8D8
		move.b	#0,$36(a0)

loc_1A8D8:				; CODE XREF: OBj09_ChkItems2+Aj
		subq.b	#1,$37(a0)
		bpl.s	locret_1A8E4
		move.b	#0,$37(a0)

locret_1A8E4:				; CODE XREF: OBj09_ChkItems2+16j
		rts
; ---------------------------------------------------------------------------

loc_1A8E6:				; CODE XREF: OBj09_ChkItems2+4j
		cmpi.b	#$25,d0
		bne.s	loc_1A95E
		move.l	$32(a0),d1
		subi.l	#$FFFF0001,d1
		move.w	d1,d2
		andi.w	#$7F,d1	
		mulu.w	#$18,d1
		subi.w	#$14,d1
		lsr.w	#7,d2
		andi.w	#$7F,d2	
		mulu.w	#$18,d2
		subi.w	#$44,d2
		sub.w	8(a0),d1
		sub.w	$C(a0),d2
		jsr	(CalcAngle).l
		jsr	(CalcSine).l
		muls.w	#$F900,d1
		asr.l	#8,d1
		move.w	d1,$10(a0)
		muls.w	#$F900,d0
		asr.l	#8,d0
		move.w	d0,$12(a0)
		bset	#1,$22(a0)
		bsr.w	sub_19EEC
		bne.s	loc_1A954
		move.b	#2,(a2)
		move.l	$32(a0),d0
		subq.l	#1,d0
		move.l	d0,4(a2)

loc_1A954:				; CODE XREF: OBj09_ChkItems2+7Ej
		move.w	#$B4,d0	; "?"
		jmp	(PlaySound_Special).l
; ---------------------------------------------------------------------------

loc_1A95E:				; CODE XREF: OBj09_ChkItems2+24j
		cmpi.b	#$27,d0
		bne.s	loc_1A974
		addq.b	#2,$24(a0)
		move.w	#$A8,d0	; "?"
		jsr	(PlaySound_Special).l
		rts
; ---------------------------------------------------------------------------

loc_1A974:				; CODE XREF: OBj09_ChkItems2+9Cj
		cmpi.b	#$29,d0	
		bne.s	loc_1A9A8
		tst.b	$36(a0)
		bne.w	locret_1AA58
		move.b	#$1E,$36(a0)
		btst	#6,($FFFFF783).w
		beq.s	loc_1A99E
		asl	($FFFFF782).w
		movea.l	$32(a0),a1
		subq.l	#1,a1
		move.b	#$2A,(a1) 

loc_1A99E:				; CODE XREF: OBj09_ChkItems2+C8j
		move.w	#$A9,d0	
		jmp	(PlaySound_Special).l
; ---------------------------------------------------------------------------

loc_1A9A8:				; CODE XREF: OBj09_ChkItems2+B2j
		cmpi.b	#$2A,d0
		bne.s	loc_1A9DC
		tst.b	$36(a0)
		bne.w	locret_1AA58
		move.b	#$1E,$36(a0)
		btst	#6,($FFFFF783).w
		bne.s	loc_1A9D2
		asr	($FFFFF782).w
		movea.l	$32(a0),a1
		subq.l	#1,a1
		move.b	#$29,(a1)

loc_1A9D2:				; CODE XREF: OBj09_ChkItems2+FCj
		move.w	#$A9,d0	
		jmp	(PlaySound_Special).l
; ---------------------------------------------------------------------------

loc_1A9DC:				; CODE XREF: OBj09_ChkItems2+E6j
		cmpi.b	#$2B,d0
		bne.s	loc_1AA12
		tst.b	$37(a0)
		bne.w	locret_1AA58
		move.b	#$1E,$37(a0)
		bsr.w	sub_19EEC
		bne.s	loc_1AA04
		move.b	#4,(a2)
		move.l	$32(a0),d0
		subq.l	#1,d0
		move.l	d0,4(a2)

loc_1AA04:				; CODE XREF: OBj09_ChkItems2+12Ej
		neg.w	($FFFFF782).w
		move.w	#$A9,d0
		jmp	(PlaySound_Special).l
; ---------------------------------------------------------------------------

loc_1AA12:				; CODE XREF: OBj09_ChkItems2+11Aj
		cmpi.b	#$2D,d0
		beq.s	loc_1AA2A
		cmpi.b	#$2E,d0
		beq.s	loc_1AA2A
		cmpi.b	#$2F,d0	; "/"
		beq.s	loc_1AA2A
		cmpi.b	#$30,d0	
		bne.s	locret_1AA58

loc_1AA2A:				; CODE XREF: OBj09_ChkItems2+150j
					; OBj09_ChkItems2+156j	...
		bsr.w	sub_19EEC
		bne.s	loc_1AA4E
		move.b	#6,(a2)
		movea.l	$32(a0),a1
		subq.l	#1,a1
		move.l	a1,4(a2)
		move.b	(a1),d0
		addq.b	#1,d0
		cmpi.b	#$30,d0
		bls.s	loc_1AA4A
		clr.b	d0

loc_1AA4A:				; CODE XREF: OBj09_ChkItems2+180j
		move.b	d0,4(a2)

loc_1AA4E:				; CODE XREF: OBj09_ChkItems2+168j
		move.w	#$BA,d0	; "?"
		jmp	(PlaySound_Special).l
; ---------------------------------------------------------------------------

locret_1AA58:				; CODE XREF: OBj09_ChkItems2+B8j
					; OBj09_ChkItems2+ECj ...
		rts
; End of function OBj09_ChkItems2

; ---------------------------------------------------------------------------
;----------------------------------------------------
; Object 10
;----------------------------------------------------

Obj10:					; DATA XREF: ROM:Obj_Indexo
		rts
; ---------------------------------------------------------------------------

j_ModifySpriteAttr_2P_7:		; CODE XREF: ROM:0001A3FAp
		jmp	ModifySpriteAttr_2P
; ---------------------------------------------------------------------------
		align 4

; =============== S U B	R O U T	I N E =======================================


DynamicArtCues:				; CODE XREF: ROM:j_DynamicArtCuesj
		moveq	#0,d0
		move.b	(v_zone).w,d0
		add.w	d0,d0
		add.w	d0,d0
		move.w	DynArtCue_Index+2(pc,d0.w),d1
		lea	DynArtCue_Index(pc,d1.w),a2
		move.w	DynArtCue_Index(pc,d0.w),d0
		jmp	DynArtCue_Index(pc,d0.w)
; End of function DynamicArtCues

; ---------------------------------------------------------------------------
		rts
; ---------------------------------------------------------------------------
DynArtCue_Index:dc.w Dynamic_NullGHZ-DynArtCue_Index,AnimCue_EHZ-DynArtCue_Index; 0
					; DATA XREF: ROM:DynArtCue_Indexo
					; ROM:DynArtCue_Index+2o ...
		dc.w Dynamic_Null-DynArtCue_Index,AnimCue_Unk-DynArtCue_Index; 2
		dc.w Dynamic_Null-DynArtCue_Index,AnimCue_Unk-DynArtCue_Index; 4
		dc.w Dynamic_Normal-DynArtCue_Index,AnimCue_EHZ-DynArtCue_Index; 6
		dc.w Dynamic_Normal-DynArtCue_Index,AnimCue_HPZ-DynArtCue_Index; 8
		dc.w Dynamic_Normal-DynArtCue_Index,AnimCue_EHZ-DynArtCue_Index; 10
		dc.w Dynamic_Null-DynArtCue_Index,AnimCue_Unk-DynArtCue_Index; 12
		dc.w Dynamic_Null-DynArtCue_Index,AnimCue_Unk-DynArtCue_Index; 14
		dc.w Dynamic_Normal-DynArtCue_Index,AnimCue_HPZ-DynArtCue_Index; 16
		dc.w Dynamic_Null-DynArtCue_Index,AnimCue_Unk-DynArtCue_Index; 18
		dc.w Dynamic_Null-DynArtCue_Index,AnimCue_Unk-DynArtCue_Index; 20
		dc.w Dynamic_Null-DynArtCue_Index,AnimCue_Unk-DynArtCue_Index; 22
		dc.w Dynamic_Null-DynArtCue_Index,AnimCue_Unk-DynArtCue_Index; 24
		dc.w Dynamic_Null-DynArtCue_Index,AnimCue_Unk-DynArtCue_Index; 26
		dc.w Dynamic_Null-DynArtCue_Index,AnimCue_Unk-DynArtCue_Index; 28
		dc.w Dynamic_Null-DynArtCue_Index,AnimCue_Unk-DynArtCue_Index; 30
; ---------------------------------------------------------------------------

Dynamic_Null:				; DATA XREF: ROM:DynArtCue_Indexo
		rts
; ---------------------------------------------------------------------------

Dynamic_NullGHZ:			; DATA XREF: ROM:DynArtCue_Indexo
		rts
; ---------------------------------------------------------------------------

Dynamic_Normal:				; DATA XREF: ROM:DynArtCue_Indexo
		lea	($FFFFF7F0).w,a3
		move.w	(a2)+,d6

loc_1AACA:				; CODE XREF: ROM:0001AB26j
		subq.b	#1,(a3)
		bpl.s	loc_1AB10
		moveq	#0,d0
		move.b	1(a3),d0
		cmp.b	6(a2),d0
		bcs.s	loc_1AAE0
		moveq	#0,d0
		move.b	d0,1(a3)

loc_1AAE0:				; CODE XREF: ROM:0001AAD8j
		addq.b	#1,1(a3)
		move.b	(a2),(a3)
		bpl.s	loc_1AAEE
		add.w	d0,d0
		move.b	9(a2,d0.w),(a3)

loc_1AAEE:				; CODE XREF: ROM:0001AAE6j
		move.b	8(a2,d0.w),d0
		lsl.w	#5,d0
		move.w	4(a2),d2
		move.l	(a2),d1
		andi.l	#$FFFFFF,d1
		add.l	d0,d1
		moveq	#0,d3
		move.b	7(a2),d3
		lsl.w	#4,d3
		jsr	(DMA_68KtoVRAM).l

loc_1AB10:				; CODE XREF: ROM:0001AACCj
		move.b	6(a2),d0
		tst.b	(a2)
		bpl.s	loc_1AB1A
		add.b	d0,d0

loc_1AB1A:				; CODE XREF: ROM:0001AB16j
		addq.b	#1,d0
		andi.w	#$FE,d0	; "?"
		lea	8(a2,d0.w),a2
		addq.w	#2,a3
		dbf	d6,loc_1AACA
		rts
; ---------------------------------------------------------------------------
AnimCue_EHZ:	dc.w 4			; DATA XREF: ROM:DynArtCue_Indexo
		dc.l Art_EHZFlower1+$FF000000
		dc.w $7280
		dc.b 6
		dc.b 2
		dc.b   0,$7F		; 0
		dc.b   2,$13		; 2
		dc.b   0,  7		; 4
		dc.b   2,  7		; 6
		dc.b   0,  7		; 8
		dc.b   2,  7		; 10
		dc.l Art_EHZFlower2+$FF000000
		dc.w $72C0
		dc.b 8
		dc.b 2
		dc.b   2,$7F		; 0
		dc.b   0, $B		; 2
		dc.b   2, $B		; 4
		dc.b   0, $B		; 6
		dc.b   2,  5		; 8
		dc.b   0,  5		; 10
		dc.b   2,  5		; 12
		dc.b   0,  5		; 14
		dc.l Art_EHZFlower3+$7000000
		dc.w $7300
		dc.b 2
		dc.b 2
		dc.b   0,  2		; 0
		dc.l Art_EHZFlower4+$FF000000
		dc.w $7340
		dc.b 8
		dc.b 2
		dc.b   0,$7F		; 0
		dc.b   2,  7		; 2
		dc.b   0,  7		; 4
		dc.b   2,  7		; 6
		dc.b   0,  7		; 8
		dc.b   2, $B		; 10
		dc.b   0, $B		; 12
		dc.b   2, $B		; 14
		dc.l Art_EHZPulsingBall+$1000000
		dc.w $7380
		dc.b 6
		dc.b 2
		dc.b   0,  2		; 0
		dc.b   4,  6		; 2
		dc.b   4,  2		; 4
AnimCue_HPZ:	dc.w 2			; DATA XREF: ROM:DynArtCue_Indexo
		dc.l Art_HPZGlowingBall+$8000000
		dc.w $5D00
		dc.b 6
		dc.b 8
		dc.b   0,  0		; 0
		dc.b   8,$10		; 2
		dc.b $10,  8		; 4
		dc.l Art_HPZGlowingBall+$8000000
		dc.w $5E00
		dc.b 6
		dc.b 8
		dc.b   8,$10		; 0
		dc.b $10,  8		; 2
		dc.b   0,  0		; 4
		dc.l Art_HPZGlowingBall+$8000000
		dc.w $5F00
		dc.b 6
		dc.b 8
		dc.b $10,  8		; 0
		dc.b   0,  0		; 2
		dc.b   8,$10		; 4
AnimCue_Unk:	dc.w 7			; DATA XREF: ROM:DynArtCue_Indexo
		dc.l Art_UnkZone_1+$7000000
		dc.w $9000
		dc.b 2
		dc.b 4
		dc.b   0,  4		; 0
		dc.l Art_UnkZone_2+$7000000
		dc.w $9080
		dc.b 3
		dc.b 8
		dc.b   0,  8		; 0
		dc.b $10,  0		; 2
		dc.l Art_UnkZone_3+$7000000
		dc.w $9180
		dc.b 4
		dc.b 2
		dc.b   0,  2		; 0
		dc.b   0,  4		; 2
		dc.l Art_UnkZone_4+$B000000
		dc.w $91C0
		dc.b 4
		dc.b 2
		dc.b   0,  2		; 0
		dc.b   4,  2		; 2
		dc.l Art_UnkZone_5+$F000000
		dc.w $9200
		dc.b $A
		dc.b 1
		dc.b   0		; 0
		dc.b   0		; 1
		dc.b   1		; 2
		dc.b   2		; 3
		dc.b   3		; 4
		dc.b   4		; 5
		dc.b   5		; 6
		dc.b   4		; 7
		dc.b   5		; 8
		dc.b   4		; 9
		dc.l Art_UnkZone_6+$3000000
		dc.w $9220
		dc.b 4
		dc.b 4
		dc.b   0,  4		; 0
		dc.b   8,  4		; 2
		dc.l Art_UnkZone_7+$7000000
		dc.w $92A0
		dc.b 6
		dc.b 3
		dc.b   0,  3		; 0
		dc.b   6,  9		; 2
		dc.b  $C, $F		; 4
		dc.l Art_UnkZone_8+$7000000
		dc.w $9300
		dc.b 4
		dc.b 1
		dc.b   0		; 0
		dc.b   1		; 1
		dc.b   2		; 2
		dc.b   3		; 3
; ---------------------------------------------------------------------------
		cmpi.b	#2,(v_zone).w
		beq.s	loc_1AC28

locret_1AC26:				; CODE XREF: ROM:0001AC30j
					; ROM:0001AC36j ...
		rts
; ---------------------------------------------------------------------------

loc_1AC28:				; CODE XREF: ROM:0001AC24j
		move.w	(v_screenposx).w,d0
		cmpi.w	#$1940,d0
		bcs.s	locret_1AC26
		cmpi.w	#$1F80,d0
		bcc.s	locret_1AC26
		subq.b	#1,($FFFFF721).w
		bpl.s	locret_1AC26
		move.b	#7,($FFFFF721).w
		move.b	#1,($FFFFF720).w
		lea	($FFFF7500).l,a1
		bsr.s	sub_1AC58
		lea	($FFFF7D00).l,a1

; =============== S U B	R O U T	I N E =======================================


sub_1AC58:				; CODE XREF: ROM:0001AC50p
		move.w	#7,d1

loc_1AC5C:				; CODE XREF: sub_1AC58+94j
		move.w	(a1),d0
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	$72(a1),(a1)+
		adda.w	#$70,a1	
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	$72(a1),(a1)+
		adda.w	#$70,a1	
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	$72(a1),(a1)+
		adda.w	#$70,a1
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	2(a1),(a1)+
		move.w	d0,(a1)+
		suba.w	#$180,a1
		dbf	d1,loc_1AC5C
		rts
; End of function sub_1AC58

;----------------------------------------------------
; This subroutines changes some	16x16 mappings
;----------------------------------------------------

; =============== S U B	R O U T	I N E =======================================


LoadMap16Delta:				; CODE XREF: ROM:00003D42p
		moveq	#0,d0
		move.b	(v_zone).w,d0
		add.w	d0,d0
		move.w	Map16Delta_Index(pc,d0.w),d0
		lea	Map16Delta_Index(pc,d0.w),a0
		tst.w	(a0)
		beq.s	locret_1AD1A
		lea	(v_16x16).w,a1
		adda.w	(a0)+,a1
		move.w	(a0)+,d1
		tst.w	(f_2player).w
		bne.s	loc_1AD1C

loc_1AD14:				; CODE XREF: LoadMap16Delta+24j
		move.w	(a0)+,(a1)+
		dbf	d1,loc_1AD14

locret_1AD1A:				; CODE XREF: LoadMap16Delta+12j
		rts
; ---------------------------------------------------------------------------

loc_1AD1C:				; CODE XREF: LoadMap16Delta+20j
					; LoadMap16Delta+3Cj
		move.w	(a0)+,d0
		move.w	d0,d1
		andi.w	#$F800,d0
		andi.w	#$7FF,d1
		lsr.w	#1,d1
		or.w	d1,d0
		move.w	d0,(a1)+
		dbf	d1,loc_1AD1C
		rts
; End of function LoadMap16Delta

; ---------------------------------------------------------------------------
Map16Delta_Index:dc.w Map16Delta_GHZ1-Map16Delta_Index;	0 ; DATA XREF: ROM:Map16Delta_Indexo
					; ROM:Map16Delta_Index+2o ...
		dc.w Map16Delta_GHZ2-Map16Delta_Index; 1
		dc.w Map16Delta_GHZ3-Map16Delta_Index; 2
		dc.w Map16Delta_GHZ1-Map16Delta_Index; 3
		dc.w Map16Delta_CPZ1-Map16Delta_Index; 4
		dc.w Map16Delta_GHZ1-Map16Delta_Index; 5
		dc.w Map16Delta_GHZ2-Map16Delta_Index; 6
		dc.w Map16Delta_GHZ2-Map16Delta_Index; 7
		dc.w Map16Delta_CPZ1-Map16Delta_Index; 8
		dc.w Map16Delta_GHZ2-Map16Delta_Index; 9
		dc.w Map16Delta_GHZ2-Map16Delta_Index; 10
		dc.w Map16Delta_GHZ2-Map16Delta_Index; 11
		dc.w Map16Delta_GHZ2-Map16Delta_Index; 12
		dc.w Map16Delta_GHZ3-Map16Delta_Index; 13
		dc.w Map16Delta_GHZ2-Map16Delta_Index; 14
		dc.w Map16Delta_GHZ2-Map16Delta_Index; 15
Map16Delta_GHZ1:dc.w $1788,  $3B,$4502,$4504,$4503,$4505,$4506,$4508,$4507,$4509,$450A,$450C,$450B,$450D,$450E,$4510; 0
					; DATA XREF: ROM:Map16Delta_Indexo
		dc.w $450F,$4511,$4512,$4514,$4513,$4515,$4516,$4518,$4517,$4519,$651A,$651C,$651B,$651D,$651E,$6520; 16
		dc.w $651F,$6521,$439C,$4B9C,$439D,$4B9D,$4158,$439C,$4159,$439D,$4B9C,$4958,$4B9D,$4959,$6394,$6B94; 32
		dc.w $6395,$6B95,$E396,$EB96,$E397,$EB97,$6398,$6B98,$6399,$6B99,$E39A,$EB9A,$E39B,$EB9B; 48
Map16Delta_GHZ2:dc.w	 0, $C80,  $9B,$43A1,$43A2,$43A3,$43A4,$43A5,$43A6,$43A7,$43A8,$43A9,$43AA,$43AB,$43AC,$43AD; 0
					; DATA XREF: ROM:Map16Delta_Indexo
		dc.w $43AE,$43AF,$43B0,$43B1,$43B2,$43B3,$43B4,$43B5,$43B6,$43B7,$43B8,$43B9,$43BA,$43BB,$43BC,$43BD; 16
		dc.w $43BE,$43BF,$43C0,$43C1,$43C2,$43C3,$43C4,$63A0,$63A0,$63A0,$63A0,$63A0,$63A0,$63A0,$63A0,	   0; 32
		dc.w	 0,$6340,$6344,	   0,	 0,$6348,$634C,$6341,$6345,$6342,$6346,$6349,$634D,$634A,$634E,$6343; 48
		dc.w $6347,$4358,$4359,$634B,$634F,$435A,$435B,$6380,$6384,$6381,$6385,$6388,$638C,$6389,$638D,$6382; 64
		dc.w $6386,$6383,$6387,$638A,$638E,$638B,$638F,$6390,$6394,$6391,$6395,$6398,$639C,$6399,$639D,$6392; 80
		dc.w $6396,$6393,$6397,$639A,$639E,$639B,$639F,$4378,$4379,$437A,$437B,$437C,$437D,$437E,$437F,$235C; 96
		dc.w $235D,$235E,$235F,$2360,$2361,$2362,$2363,$2364,$2365,$2366,$2367,$2368,$2369,$236A,$236B,	   0; 112
		dc.w	 0,$636C,$636D,	   0,	 0,$636E,    0,$636F,$6370,$6371,$6372,$6373,	 0,$6374,    0,$6375; 128
		dc.w $6376,$4358,$4359,$6377,	 0,$435A,$435B,$C378,$C379,$C37A,$C37B,$C37C,$C37D,$C37E,$C37F;	144
Map16Delta_GHZ3:dc.w $17E0,   $F,$43D1,$43D1,$43D1,$43D1,$43D2,$43D2,$43D3,$43D3,$43D4,$43D4,$43D5,$43D5,$43D6,$43D6; 0
					; DATA XREF: ROM:Map16Delta_Indexo
		dc.w $43D7,$43D7	; 16
Map16Delta_CPZ1:dc.w $1710,  $77,$62E8,$62E9,$62EA,$62EB,$62EC,$62ED,$62EE,$62EF,$62F0,$62F1,$62F2,$62F3,$62F4,$62F5; 0
					; DATA XREF: ROM:Map16Delta_Indexo
		dc.w $62F6,$62F7,$62F8,$62F9,$62FA,$62FB,$62FC,$62FD,$62FE,$62FF,$42E8,$42E9,$42EA,$42EB,$42EC,$42ED; 16
		dc.w $42EE,$42EF,$42F0,$42F1,$42F2,$42F3,$42F4,$42F5,$42F6,$42F7,$42F8,$42F9,$42FA,$42FB,$42FC,$42FD; 32
		dc.w $42FE,$42FF,    0,$62E8,	 0,$62EA,$62E9,$62EC,$62EB,$62EE,$62ED,	   0,$62EF,    0,    0,$62F0; 48
		dc.w	 0,$62F2,$62F1,$62F4,$62F3,$62F6,$62F5,	   0,$62F7,    0,    0,$62F8,	 0,$62FA,$62F9,$62FC; 64
		dc.w $62FB,$62FE,$62FD,	   0,$62FF,    0,    0,$42E8,	 0,$42EA,$42E9,$42EC,$42EB,$42EE,$42ED,	   0; 80
		dc.w $42EF,    0,    0,$42F0,	 0,$42F2,$42F1,$42F4,$42F3,$42F6,$42F5,	   0,$42F7,    0,    0,$42F8; 96
		dc.w	 0,$42FA,$42F9,$42FC,$42FB,$42FE,$42FD,	   0,$42FF,    0; 112
; ---------------------------------------------------------------------------
		nop
;----------------------------------------------------
; Object 21 - SCORE, TIME, RINGS
;----------------------------------------------------

Obj21:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj21_Index(pc,d0.w),d1
		jmp	Obj21_Index(pc,d1.w)
; ---------------------------------------------------------------------------
Obj21_Index:	dc.w Obj21_Init-Obj21_Index ; DATA XREF: ROM:Obj21_Indexo
					; ROM:0001B038o
		dc.w Obj21_Main-Obj21_Index
; ---------------------------------------------------------------------------

Obj21_Init:				; DATA XREF: ROM:Obj21_Indexo
		addq.b	#2,$24(a0)
		move.w	#$90,8(a0) ; "?"
		move.w	#$108,$A(a0)
		move.l	#Map_Obj21,4(a0)
		move.w	#$6CA,2(a0)
		bsr.w	j_ModifySpriteAttr_2P_8
		move.b	#0,1(a0)
		move.b	#0,$18(a0)

Obj21_Main:				; DATA XREF: ROM:0001B038o
		tst.w	($FFFFFE20).w
		beq.s	loc_1B08C
		moveq	#0,d0
		btst	#3,($FFFFFE05).w
		bne.s	loc_1B082
		cmpi.b	#9,($FFFFFE23).w
		bne.s	loc_1B082
		addq.w	#2,d0

loc_1B082:				; CODE XREF: ROM:0001B076j
					; ROM:0001B07Ej
		move.b	d0,$1A(a0)
		jmp	DisplaySprite
; ---------------------------------------------------------------------------

loc_1B08C:				; CODE XREF: ROM:0001B06Cj
		moveq	#0,d0
		btst	#3,($FFFFFE05).w
		bne.s	loc_1B0A2
		addq.w	#1,d0
		cmpi.b	#9,($FFFFFE23).w
		bne.s	loc_1B0A2
		addq.w	#2,d0

loc_1B0A2:				; CODE XREF: ROM:0001B094j
					; ROM:0001B09Ej
		move.b	d0,$1A(a0)
		jmp	DisplaySprite
; ---------------------------------------------------------------------------
Map_Obj21:	dc.w word_1B0B4-Map_Obj21 ; DATA XREF: ROM:0001B04Ao
					; ROM:Map_Obj21o ...
		dc.w word_1B106-Map_Obj21
		dc.w word_1B158-Map_Obj21
		dc.w word_1B1AA-Map_Obj21
word_1B0B4:	dc.w $A			; DATA XREF: ROM:Map_Obj21o
		dc.w $800D,$A000,$A000,	   0; 0
		dc.w $800D,$A018,$A00C,	 $20; 4
		dc.w $800D,$A020,$A010,	 $40; 8
		dc.w $900D,$A010,$A008,	   0; 12
		dc.w $900D,$A028,$A014,	 $28; 16
		dc.w $A00D,$A008,$A004,	   0; 20
		dc.w $A001,$A000,$A000,	 $20; 24
		dc.w $A009,$A030,$A018,	 $30; 28
		dc.w $4005,$810A,$8085,	   0; 32
		dc.w $400D,$A10E,$A087,	 $10; 36
word_1B106:	dc.w $A			; DATA XREF: ROM:0001B0AEo
		dc.w $800D,$A000,$A000,	   0; 0
		dc.w $800D,$A018,$A00C,	 $20; 4
		dc.w $800D,$A020,$A010,	 $40; 8
		dc.w $900D,$A010,$A008,	   0; 12
		dc.w $900D,$A028,$A014,	 $28; 16
		dc.w $A00D,$8008,$8004,	   0; 20
		dc.w $A001,$8000,$8000,	 $20; 24
		dc.w $A009,$A030,$A018,	 $30; 28
		dc.w $4005,$810A,$8085,	   0; 32
		dc.w $400D,$A10E,$A087,	 $10; 36
word_1B158:	dc.w $A			; DATA XREF: ROM:0001B0B0o
		dc.w $800D,$A000,$A000,	   0; 0
		dc.w $800D,$A018,$A00C,	 $20; 4
		dc.w $800D,$A020,$A010,	 $40; 8
		dc.w $900D,$8010,$8008,	   0; 12
		dc.w $900D,$A028,$A014,	 $28; 16
		dc.w $A00D,$A008,$A004,	   0; 20
		dc.w $A001,$A000,$A000,	 $20; 24
		dc.w $A009,$A030,$A018,	 $30; 28
		dc.w $4005,$810A,$8085,	   0; 32
		dc.w $400D,$A10E,$A087,	 $10; 36
word_1B1AA:	dc.w $A			; DATA XREF: ROM:0001B0B2o
		dc.w $800D,$A000,$A000,	   0; 0
		dc.w $800D,$A018,$A00C,	 $20; 4
		dc.w $800D,$A020,$A010,	 $40; 8
		dc.w $900D,$8010,$8008,	   0; 12
		dc.w $900D,$A028,$A014,	 $28; 16
		dc.w $A00D,$8008,$8004,	   0; 20
		dc.w $A001,$8000,$8000,	 $20; 24
		dc.w $A009,$A030,$A018,	 $30; 28
		dc.w $4005,$810A,$8085,	   0; 32
		dc.w $400D,$A10E,$A087,	 $10; 36

; =============== S U B	R O U T	I N E =======================================


AddPoints:				; CODE XREF: ROM:loc_BC66p
					; ROM:0000BE82p ...
		move.b	#1,($FFFFFE1F).w
		lea	($FFFFFE26).w,a3
		add.l	d0,(a3)
		move.l	#999999,d1
		cmp.l	(a3),d1
		bhi.s	loc_1B214
		move.l	d1,(a3)

loc_1B214:				; CODE XREF: AddPoints+14j
		move.l	(a3),d0
		cmp.l	($FFFFFFC0).w,d0
		bcs.s	locret_1B23C
		addi.l	#5000,($FFFFFFC0).w
		tst.b	($FFFFFFF8).w
		bmi.s	locret_1B23C
		addq.b	#1,($FFFFFE12).w
		addq.b	#1,($FFFFFE1C).w
		move.w	#$88,d0	; "?"
		jmp	(PlaySound).l
; ---------------------------------------------------------------------------

locret_1B23C:				; CODE XREF: AddPoints+1Ej
					; AddPoints+2Cj
		rts
; End of function AddPoints


; =============== S U B	R O U T	I N E =======================================


HudUpdate:				; CODE XREF: DemoTime:loc_DEAp
					; ROM:00000F7Cp
		nop
		lea	(vdp_data_port).l,a6
		tst.w	($FFFFFFFA).w
		bne.w	loc_1B330
		tst.b	($FFFFFE1F).w
		beq.s	loc_1B266
		clr.b	($FFFFFE1F).w
		move.l	#$5C800003,d0
		move.l	($FFFFFE26).w,d1
		bsr.w	HUD_Score

loc_1B266:				; CODE XREF: HudUpdate+14j
		tst.b	($FFFFFE1D).w
		beq.s	loc_1B286
		bpl.s	loc_1B272
		bsr.w	HUD_LoadZero

loc_1B272:				; CODE XREF: HudUpdate+2Ej
		clr.b	($FFFFFE1D).w
		move.l	#$5F400003,d0
		moveq	#0,d1
		move.w	($FFFFFE20).w,d1
		bsr.w	HUD_Rings

loc_1B286:				; CODE XREF: HudUpdate+2Cj
		tst.b	($FFFFFE1E).w
		beq.s	loc_1B2E2
		tst.w	($FFFFF63A).w
		bne.s	loc_1B2E2
		lea	($FFFFFE22).w,a1
		cmpi.l	#$93B3B,(a1)+
		nop
		addq.b	#1,-(a1)
		cmpi.b	#$3C,(a1) 
		bcs.s	loc_1B2E2
		move.b	#0,(a1)
		addq.b	#1,-(a1)
		cmpi.b	#$3C,(a1)
		bcs.s	loc_1B2C2
		move.b	#0,(a1)
		addq.b	#1,-(a1)
		cmpi.b	#9,(a1)
		bcs.s	loc_1B2C2
		move.b	#9,(a1)

loc_1B2C2:				; CODE XREF: HudUpdate+72j
					; HudUpdate+7Ej
		move.l	#$5E400003,d0
		moveq	#0,d1
		move.b	($FFFFFE23).w,d1
		bsr.w	HUD_Mins
		move.l	#$5EC00003,d0
		moveq	#0,d1
		move.b	($FFFFFE24).w,d1
		bsr.w	HUD_Secs

loc_1B2E2:				; CODE XREF: HudUpdate+4Cj
					; HudUpdate+52j ...
		tst.b	($FFFFFE1C).w
		beq.s	loc_1B2F0
		clr.b	($FFFFFE1C).w
		bsr.w	HUD_Lives

loc_1B2F0:				; CODE XREF: HudUpdate+A8j
		tst.b	($FFFFF7D6).w
		beq.s	locret_1B318
		clr.b	($FFFFF7D6).w
		move.l	#$6E000002,(vdp_control_port).l
		moveq	#0,d1
		move.w	($FFFFF7D2).w,d1
		bsr.w	HUD_TimeRingBonus
		moveq	#0,d1
		move.w	($FFFFF7D4).w,d1
		bsr.w	HUD_TimeRingBonus

locret_1B318:				; CODE XREF: HudUpdate+B6j
		rts
; ---------------------------------------------------------------------------

S1TimeOver:				; leftover from	Sonic 1
		clr.b	($FFFFFE1E).w
		lea	(v_objspace).w,a0
		movea.l	a0,a2
		bsr.w	KillSonic
		move.b	#1,($FFFFFE1A).w
		rts
; ---------------------------------------------------------------------------

loc_1B330:				; CODE XREF: HudUpdate+Cj
		bsr.w	HUDDebug_XY
		tst.b	($FFFFFE1D).w
		beq.s	loc_1B354
		bpl.s	loc_1B340
		bsr.w	HUD_LoadZero

loc_1B340:				; CODE XREF: HudUpdate+FCj
		clr.b	($FFFFFE1D).w
		move.l	#$5F400003,d0
		moveq	#0,d1
		move.w	($FFFFFE20).w,d1
		bsr.w	HUD_Rings

loc_1B354:				; CODE XREF: HudUpdate+FAj
		move.l	#$5EC00003,d0
		moveq	#0,d1
		move.b	($FFFFF62C).w,d1
		bsr.w	HUD_Secs
		tst.b	($FFFFFE1C).w
		beq.s	loc_1B372
		clr.b	($FFFFFE1C).w
		bsr.w	HUD_Lives

loc_1B372:				; CODE XREF: HudUpdate+12Aj
		tst.b	($FFFFF7D6).w
		beq.s	locret_1B39A
		clr.b	($FFFFF7D6).w
		move.l	#$6E000002,(vdp_control_port).l
		moveq	#0,d1
		move.w	($FFFFF7D2).w,d1
		bsr.w	HUD_TimeRingBonus
		moveq	#0,d1
		move.w	($FFFFF7D4).w,d1
		bsr.w	HUD_TimeRingBonus

locret_1B39A:				; CODE XREF: HudUpdate+138j
		rts
; End of function HudUpdate


; =============== S U B	R O U T	I N E =======================================


HUD_LoadZero:				; CODE XREF: HudUpdate+30p
					; HudUpdate+FEp
		move.l	#$5F400003,(vdp_control_port).l
		lea	HUD_TilesZero(pc),a2
		move.w	#2,d2
		bra.s	loc_1B3CC
; End of function HUD_LoadZero


; =============== S U B	R O U T	I N E =======================================


HUD_Base:				; CODE XREF: ROM:00003D24p
					; ROM:00005248p
		lea	(vdp_data_port).l,a6
		bsr.w	HUD_Lives
		move.l	#$5C400003,(vdp_control_port).l
		lea	HUD_TilesBase(pc),a2
		move.w	#$E,d2

loc_1B3CC:				; CODE XREF: HUD_LoadZero+12j
		lea	Art_HUD(pc),a1

loc_1B3D0:				; CODE XREF: HUD_Base:loc_1B3E6j
		move.w	#$F,d1
		move.b	(a2)+,d0
		bmi.s	loc_1B3EC
		ext.w	d0
		lsl.w	#5,d0
		lea	(a1,d0.w),a3

loc_1B3E0:				; CODE XREF: HUD_Base+32j
		move.l	(a3)+,(a6)
		dbf	d1,loc_1B3E0

loc_1B3E6:				; CODE XREF: HUD_Base+46j
		dbf	d2,loc_1B3D0
		rts
; ---------------------------------------------------------------------------

loc_1B3EC:				; CODE XREF: HUD_Base+26j HUD_Base+42j
		move.l	#0,(a6)
		dbf	d1,loc_1B3EC
		bra.s	loc_1B3E6
; End of function HUD_Base

; ---------------------------------------------------------------------------
HUD_TilesBase:	dc.b $16,$FF,$FF,$FF,$FF,$FF,$FF,  0,  0,$14,  0,  0; 0
					; DATA XREF: HUD_Base+14t
HUD_TilesZero:	dc.b $FF,$FF,  0,  0	; 0 ; DATA XREF: HUD_LoadZero+At

; =============== S U B	R O U T	I N E =======================================


HUDDebug_XY:				; CODE XREF: HudUpdate:loc_1B330p
		move.l	#$5C400003,(vdp_control_port).l
		move.w	(v_screenposx).w,d1
		swap	d1
		move.w	(v_objspace+8).w,d1
		bsr.s	HUDDebug_XY2
		move.w	(v_screenposy).w,d1
		swap	d1
		move.w	(v_objspace+$C).w,d1
; End of function HUDDebug_XY


; =============== S U B	R O U T	I N E =======================================


HUDDebug_XY2:				; CODE XREF: HUDDebug_XY+14p
		moveq	#7,d6
		lea	(Art_Text).l,a1

loc_1B430:				; CODE XREF: HUDDebug_XY2+32j
		rol.w	#4,d1
		move.w	d1,d2
		andi.w	#$F,d2
		cmpi.w	#$A,d2
		bcs.s	loc_1B442
		addi.w	#7,d2

loc_1B442:				; CODE XREF: HUDDebug_XY2+14j
		lsl.w	#5,d2
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		swap	d1
		dbf	d6,loc_1B430
		rts
; End of function HUDDebug_XY2


; =============== S U B	R O U T	I N E =======================================


HUD_Rings:				; CODE XREF: HudUpdate+44p
					; HudUpdate+112p
		lea	(HUD_100).l,a2
		moveq	#2,d6
		bra.s	loc_1B472
; End of function HUD_Rings


; =============== S U B	R O U T	I N E =======================================


HUD_Score:				; CODE XREF: HudUpdate+24p
		lea	(HUD_100000).l,a2
		moveq	#5,d6

loc_1B472:				; CODE XREF: HUD_Rings+8j
		moveq	#0,d4
		lea	Art_HUD(pc),a1

loc_1B478:				; CODE XREF: HUD_Score+58j
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1B47C:				; CODE XREF: HUD_Score+18j
		sub.l	d3,d1
		bcs.s	loc_1B484
		addq.w	#1,d2
		bra.s	loc_1B47C
; ---------------------------------------------------------------------------

loc_1B484:				; CODE XREF: HUD_Score+14j
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1B48E
		move.w	#1,d4

loc_1B48E:				; CODE XREF: HUD_Score+1Ej
		tst.w	d4
		beq.s	loc_1B4BC
		lsl.w	#6,d2
		move.l	d0,4(a6)
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)

loc_1B4BC:				; CODE XREF: HUD_Score+26j
		addi.l	#$400000,d0
		dbf	d6,loc_1B478
		rts
; End of function HUD_Score

; ---------------------------------------------------------------------------

HUD_Unk:
		move.l	#$5F800003,(vdp_control_port).l
		lea	(vdp_data_port).l,a6
		lea	(HUD_10).l,a2
		moveq	#1,d6
		moveq	#0,d4
		lea	Art_HUD(pc),a1

loc_1B4E6:				; CODE XREF: ROM:0001B51Aj
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1B4EA:				; CODE XREF: ROM:0001B4F0j
		sub.l	d3,d1
		bcs.s	loc_1B4F2
		addq.w	#1,d2
		bra.s	loc_1B4EA
; ---------------------------------------------------------------------------

loc_1B4F2:				; CODE XREF: ROM:0001B4ECj
		add.l	d3,d1
		lsl.w	#6,d2
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		dbf	d6,loc_1B4E6
		rts
; ---------------------------------------------------------------------------
HUD_100000:	dc.l 100000		; DATA XREF: HUD_Scoreo
HUD_10000:	dc.l 10000
HUD_1000:	dc.l 1000		; DATA XREF: HUD_TimeRingBonust
HUD_100:	dc.l 100		; DATA XREF: HUD_Ringso
HUD_10:		dc.l 10			; DATA XREF: ROM:0001B4D8o HUD_Secst ...
HUD_1:		dc.l 1			; DATA XREF: HUD_Minst

; =============== S U B	R O U T	I N E =======================================


HUD_Mins:				; CODE XREF: HudUpdate+90p
		lea	HUD_1(pc),a2
		moveq	#0,d6
		bra.s	loc_1B546
; End of function HUD_Mins


; =============== S U B	R O U T	I N E =======================================


HUD_Secs:				; CODE XREF: HudUpdate+A0p
					; HudUpdate+122p
		lea	HUD_10(pc),a2
		moveq	#1,d6

loc_1B546:				; CODE XREF: HUD_Mins+6j
		moveq	#0,d4

loc_1B548:
		lea	Art_HUD(pc),a1

loc_1B54C:				; CODE XREF: HUD_Secs+52j
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1B550:				; CODE XREF: HUD_Secs+16j
		sub.l	d3,d1
		bcs.s	loc_1B558
		addq.w	#1,d2
		bra.s	loc_1B550
; ---------------------------------------------------------------------------

loc_1B558:				; CODE XREF: HUD_Secs+12j
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1B562
		move.w	#1,d4

loc_1B562:				; CODE XREF: HUD_Secs+1Cj
		lsl.w	#6,d2
		move.l	d0,4(a6)
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		addi.l	#$400000,d0
		dbf	d6,loc_1B54C
		rts
; End of function HUD_Secs


; =============== S U B	R O U T	I N E =======================================


HUD_TimeRingBonus:			; CODE XREF: HudUpdate+CCp
					; HudUpdate+D6p ...
		lea	HUD_1000(pc),a2
		moveq	#3,d6
		moveq	#0,d4
		lea	Art_HUD(pc),a1

loc_1B5A4:				; CODE XREF: HUD_TimeRingBonus:loc_1B5E4j
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1B5A8:				; CODE XREF: HUD_TimeRingBonus+16j
		sub.l	d3,d1
		bcs.s	loc_1B5B0
		addq.w	#1,d2
		bra.s	loc_1B5A8
; ---------------------------------------------------------------------------

loc_1B5B0:				; CODE XREF: HUD_TimeRingBonus+12j
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1B5BA
		move.w	#1,d4

loc_1B5BA:				; CODE XREF: HUD_TimeRingBonus+1Cj
		tst.w	d4
		beq.s	loc_1B5EA
		lsl.w	#6,d2
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)

loc_1B5E4:				; CODE XREF: HUD_TimeRingBonus+5Ej
		dbf	d6,loc_1B5A4
		rts
; ---------------------------------------------------------------------------

loc_1B5EA:				; CODE XREF: HUD_TimeRingBonus+24j
		moveq	#$F,d5

loc_1B5EC:				; CODE XREF: HUD_TimeRingBonus+5Aj
		move.l	#0,(a6)
		dbf	d5,loc_1B5EC
		bra.s	loc_1B5E4
; End of function HUD_TimeRingBonus


; =============== S U B	R O U T	I N E =======================================


HUD_Lives:				; CODE XREF: HudUpdate+AEp
					; HudUpdate+130p ...
		move.l	#$7BA00003,d0
		moveq	#0,d1
		move.b	($FFFFFE12).w,d1
		lea	HUD_10(pc),a2
		moveq	#1,d6
		moveq	#0,d4
		lea	Art_LivesNums(pc),a1

loc_1B610:				; CODE XREF: HUD_Lives+52j
		move.l	d0,4(a6)
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1B618:				; CODE XREF: HUD_Lives+26j
		sub.l	d3,d1
		bcs.s	loc_1B620
		addq.w	#1,d2
		bra.s	loc_1B618
; ---------------------------------------------------------------------------

loc_1B620:				; CODE XREF: HUD_Lives+22j
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1B62A
		move.w	#1,d4

loc_1B62A:				; CODE XREF: HUD_Lives+2Cj
		tst.w	d4
		beq.s	loc_1B650

loc_1B62E:				; CODE XREF: HUD_Lives+5Aj
		lsl.w	#5,d2
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)

loc_1B644:				; CODE XREF: HUD_Lives+68j
		addi.l	#$400000,d0
		dbf	d6,loc_1B610
		rts
; ---------------------------------------------------------------------------

loc_1B650:				; CODE XREF: HUD_Lives+34j
		tst.w	d6
		beq.s	loc_1B62E
		moveq	#7,d5

loc_1B656:				; CODE XREF: HUD_Lives+64j
		move.l	#0,(a6)
		dbf	d5,loc_1B656
		bra.s	loc_1B644
; End of function HUD_Lives

; ---------------------------------------------------------------------------
Art_HUD:	incbin "artunc\HUD Numbers.bin"
                even
Art_LivesNums:	incbin "artunc\Lives Counter Numbers.bin"
                even
; ---------------------------------------------------------------------------
		nop

j_ModifySpriteAttr_2P_8:		; CODE XREF: ROM:0001B058p
		jmp	ModifySpriteAttr_2P
; ---------------------------------------------------------------------------
		align 4

DebugMode:				; CODE XREF: ROM:0000FA02j
					; ROM:0001A3C2j
		moveq	#0,d0
		move.b	($FFFFFE08).w,d0
		move.w	DebugIndex(pc,d0.w),d1
		jmp	DebugIndex(pc,d1.w)
; ---------------------------------------------------------------------------
DebugIndex:	dc.w Debug_Init-DebugIndex ; DATA XREF:	ROM:DebugIndexo
					; ROM:0001BABCo
		dc.w Debug_Move-DebugIndex
; ---------------------------------------------------------------------------

Debug_Init:				; DATA XREF: ROM:DebugIndexo
		addq.b	#2,($FFFFFE08).w
		move.w	($FFFFEECC).w,($FFFFFEF0).w
		move.w	($FFFFEEC6).w,($FFFFFEF2).w
		move.w	#0,($FFFFEECC).w
		move.w	#$720,($FFFFEEC6).w
		andi.w	#$7FF,(v_objspace+$C).w
		andi.w	#$7FF,(v_screenposy).w
		andi.w	#$3FF,(v_bgscreenposy).w
		move.b	#0,$1A(a0)
		move.b	#0,$1C(a0)
		cmpi.b	#$10,(v_gamemode).w
		bne.s	loc_1BB04
		moveq	#6,d0
		bra.s	loc_1BB0A
; ---------------------------------------------------------------------------

loc_1BB04:				; CODE XREF: ROM:0001BAFEj
		moveq	#0,d0
		move.b	(v_zone).w,d0

loc_1BB0A:				; CODE XREF: ROM:0001BB02j
		lea	(DebugList).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d6
		cmp.b	($FFFFFE06).w,d6
		bhi.s	loc_1BB24
		move.b	#0,($FFFFFE06).w

loc_1BB24:				; CODE XREF: ROM:0001BB1Cj
		bsr.w	Debug_ShowItem
		move.b	#$C,($FFFFFE0A).w
		move.b	#1,($FFFFFE0B).w

Debug_Move:				; DATA XREF: ROM:0001BABCo
		moveq	#6,d0
		cmpi.b	#$10,(v_gamemode).w
		beq.s	loc_1BB44
		moveq	#0,d0
		move.b	(v_zone).w,d0

loc_1BB44:				; CODE XREF: ROM:0001BB3Cj
		lea	(DebugList).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d6
		bsr.w	Debug_Control
		jmp	DisplaySprite

; =============== S U B	R O U T	I N E =======================================


Debug_Control:				; CODE XREF: ROM:0001BB52p
		moveq	#0,d4
		move.w	#1,d1
		move.b	(v_jpadpress1).w,d4
		andi.w	#$F,d4
		bne.s	loc_1BB9E
		move.b	(v_jpadhold1).w,d0
		andi.w	#$F,d0
		bne.s	loc_1BB86
		move.b	#$C,($FFFFFE0A).w
		move.b	#$F,($FFFFFE0B).w
		bra.w	loc_1BBF4
; ---------------------------------------------------------------------------

loc_1BB86:				; CODE XREF: Debug_Control+18j
		subq.b	#1,($FFFFFE0A).w
		bne.s	loc_1BBA2
		move.b	#1,($FFFFFE0A).w
		addq.b	#1,($FFFFFE0B).w
		bne.s	loc_1BB9E
		move.b	#$FF,($FFFFFE0B).w

loc_1BB9E:				; CODE XREF: Debug_Control+Ej
					; Debug_Control+3Aj
		move.b	(v_jpadhold1).w,d4

loc_1BBA2:				; CODE XREF: Debug_Control+2Ej
		moveq	#0,d1
		move.b	($FFFFFE0B).w,d1
		addq.w	#1,d1
		swap	d1
		asr.l	#4,d1
		move.l	$C(a0),d2
		move.l	8(a0),d3
		btst	#0,d4
		beq.s	loc_1BBC2
		sub.l	d1,d2
		bcc.s	loc_1BBC2
		moveq	#0,d2

loc_1BBC2:				; CODE XREF: Debug_Control+5Ej
					; Debug_Control+62j
		btst	#1,d4
		beq.s	loc_1BBD8
		add.l	d1,d2
		cmpi.l	#$7FF0000,d2
		bcs.s	loc_1BBD8
		move.l	#$7FF0000,d2

loc_1BBD8:				; CODE XREF: Debug_Control+6Aj
					; Debug_Control+74j
		btst	#2,d4
		beq.s	loc_1BBE4
		sub.l	d1,d3
		bcc.s	loc_1BBE4
		moveq	#0,d3

loc_1BBE4:				; CODE XREF: Debug_Control+80j
					; Debug_Control+84j
		btst	#3,d4
		beq.s	loc_1BBEC
		add.l	d1,d3

loc_1BBEC:				; CODE XREF: Debug_Control+8Cj
		move.l	d2,$C(a0)
		move.l	d3,8(a0)

loc_1BBF4:				; CODE XREF: Debug_Control+26j
		btst	#6,(v_jpadhold1).w
		beq.s	loc_1BC2C
		btst	#5,(v_jpadpress1).w
		beq.s	loc_1BC10
		subq.b	#1,($FFFFFE06).w
		bcc.s	loc_1BC28
		add.b	d6,($FFFFFE06).w
		bra.s	loc_1BC28
; ---------------------------------------------------------------------------

loc_1BC10:				; CODE XREF: Debug_Control+A6j
		btst	#6,(v_jpadpress1).w
		beq.s	loc_1BC2C
		addq.b	#1,($FFFFFE06).w
		cmp.b	($FFFFFE06).w,d6
		bhi.s	loc_1BC28
		move.b	#0,($FFFFFE06).w

loc_1BC28:				; CODE XREF: Debug_Control+ACj
					; Debug_Control+B2j ...
		bra.w	Debug_ShowItem
; ---------------------------------------------------------------------------

loc_1BC2C:				; CODE XREF: Debug_Control+9Ej
					; Debug_Control+BAj
		btst	#5,(v_jpadpress1).w
		beq.s	loc_1BC70
		jsr	(SingleObjectLoad).l
		bne.s	loc_1BC70
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	4(a0),0(a1)
		move.b	1(a0),1(a1)
		move.b	1(a0),$22(a1)
		andi.b	#$7F,$22(a1)
		moveq	#0,d0
		move.b	($FFFFFE06).w,d0
		lsl.w	#3,d0
		move.b	4(a2,d0.w),$28(a1)
		rts
; ---------------------------------------------------------------------------

loc_1BC70:				; CODE XREF: Debug_Control+D6j
					; Debug_Control+DEj
		btst	#4,(v_jpadpress1).w
		beq.s	locret_1BCCA
		moveq	#0,d0
		move.w	d0,($FFFFFE08).w
		move.l	#Map_Sonic,(v_objspace+4).w
		move.w	#$780,(v_objspace+2).w
		tst.w	(f_2player).w
		beq.s	loc_1BC98
		move.w	#$3C0,(v_objspace+2).w

loc_1BC98:				; CODE XREF: Debug_Control+134j
		move.b	d0,(v_objspace+$1C).w
		move.w	d0,$A(a0)
		move.w	d0,$E(a0)
		move.w	($FFFFFEF0).w,($FFFFEECC).w
		move.w	($FFFFFEF2).w,($FFFFEEC6).w
		cmpi.b	#$10,(v_gamemode).w
		bne.s	locret_1BCCA
		move.b	#2,(v_objspace+$1C).w
		bset	#2,(v_objspace+$22).w
		bset	#1,(v_objspace+$22).w

locret_1BCCA:				; CODE XREF: Debug_Control+11Aj
					; Debug_Control+15Aj
		rts
; End of function Debug_Control


; =============== S U B	R O U T	I N E =======================================


Debug_ShowItem:				; CODE XREF: ROM:loc_1BB24p
					; Debug_Control:loc_1BC28j
		moveq	#0,d0
		move.b	($FFFFFE06).w,d0
		lsl.w	#3,d0
		move.l	(a2,d0.w),4(a0)
		move.w	6(a2,d0.w),2(a0)
		move.b	5(a2,d0.w),$1A(a0)
		bsr.w	j_ModifySpriteAttr_2P_1
		rts
; End of function Debug_ShowItem

                include "_inc\DebugList.asm"

j_ModifySpriteAttr_2P_1:		; CODE XREF: Debug_ShowItem+1Ap
		jmp	ModifySpriteAttr_2P

		align 4

                include "_inc\LevelHeaders.asm"
                include "_inc\Pattern Load Cues.asm"

;----------------------------------------------------
; Unknown leftover art from an unknown prototype game
;  leftover due	to usage of a large FF padding
;----------------------------------------------------
LeftoverArt_Unknown:incbin "leftovers\0x1C318.bin"
                even
AngleMap_GHZ:	incbin "collide\S1 Angle Map.bin"
                even
AngleMap:	incbin "collide\Angle Map.bin"
                even
ColArray1_GHZ:	incbin "collide\S1 Collision Array (Normal).bin"
                even
ColArray2_GHZ:	incbin "collide\S1 Collision Array (Rotated).bin"
                even
ColArray1:	incbin "collide\Collision Array (Normal).bin"
                even
ColArray2:	incbin "collide\Collision Array (Rotated).bin"
                even
ColP_GHZ:	incbin "collide\GHZ (Primary).bin"
                even
ColS_GHZ:	incbin "collide\GHZ (Secondary).bin"
                even
ColP_EHZ:	incbin "collide\EHZ (Primary).bin"
                even
ColS_EHZ:	incbin "collide\EHZ (Secondary).bin"
                even
ColP_CPZ:	incbin "collide\CPZ (Primary).bin"
                even
ColS_CPZ:	incbin "collide\CPZ (Secondary).bin"
                even
ColP_HPZ:	incbin "collide\HPZ (Primary).bin"
                even
ColS_HPZ:	incbin "collide\HPZ (Secondary).bin"
                even
S1SS_1:		incbin "sslayout\1.bin"
                even
S1SS_2:		incbin "sslayout\2.bin"
                even
S1SS_3:		incbin "sslayout\3.bin"
                even
S1SS_4:		incbin "sslayout\4.bin"
                even
S1SS_5:		incbin "sslayout\5.bin"
                even
S1SS_6:		incbin "sslayout\6.bin"
                even
Art_EHZFlower1:	incbin "artunc\EHZ Flowers - 1.bin"
                even
Art_EHZFlower2:	incbin "artunc\EHZ Flowers - 2.bin"
                even
Art_EHZFlower3:	incbin "artunc\EHZ Flowers - 3.bin"
                even
Art_EHZFlower4:	incbin "artunc\EHZ Flowers - 4.bin"
                even
Art_EHZPulsingBall:incbin "artunc\EHZ Pulsing Ball.bin"
                even
Art_HPZUnusedBg:incbin "artunc\Unused - HPZ Background.bin"
                even
Art_HPZGlowingBall:incbin "artunc\HPZ - Orb.bin"
                even
Art_UnkZone_1:	dc.l $12332411,$12334199,$12331999,$12331999,$12331999,$12343199,$12313311,$12222222; 0
					; DATA XREF: ROM:0001ABB8t
		dc.l $11423333,$99143333,$99913333,$99913333,$99913333,$99133333,$11333333,$22222222; 8
		dc.l $33332411,$333341BB,$33331BBB,$33331BBB,$33331BBB,$333331BB,$33333311,$22222222; 16
		dc.l $11423321,$BB143321,$BBB13321,$BBB13321,$BBB13321,$BB134321,$11331321,$22222221; 24
		dc.l $12332411,$123341BB,$12331BBB,$12331BBB,$12331BBB,$123431BB,$12313311,$12222222; 32
		dc.l $11423333,$BB143333,$BBB13333,$BBB13333,$BBB13333,$BB133333,$11333333,$22222222; 40
		dc.l $33332411,$33334199,$33331999,$33331999,$33331999,$33333199,$33333311,$22222222; 48
		dc.l $11423321,$99143321,$99913321,$99913321,$99913321,$99134321,$11331321,$22222221; 56
Art_UnkZone_2:	dc.l $13333334,$11111111,$13333334,$13333334,$11111111,$13333334,$13333334,$14444444; 0
					; DATA XREF: ROM:0001ABC2t
		dc.l $13333334,$11111111,$13333334,$13333334,$11111111,$13333334,$13333334,$14444444; 8
		dc.l $11111111,$14444445,$14444445,$15555555,$15555555,$11111111,$15555555,$15555555; 16
		dc.l $11111111,$14444445,$14444445,$15555555,$15555555,$11111111,$15555555,$15555555; 24
		dc.l $15555555,$15555555,$11111111,$15555555,$15555555,$14444445,$14444445,$11111111; 32
		dc.l $15555555,$15555555,$11111111,$15555555,$15555555,$14444445,$14444445,$11111111; 40
		dc.l $14444444,$13333334,$13333334,$11111111,$13333334,$13333334,$11111111,$13333334; 48
		dc.l $14444444,$13333334,$13333334,$11111111,$13333334,$13333334,$11111111,$13333334; 56
		dc.l $13333334,$13333334,$11111111,$13333334,$13333334,$13333334,$11111111,$14444445; 64
		dc.l $11111111,$13333334,$11111111,$13333334,$13333334,$11111111,$13333334,$14444445; 72
		dc.l $14444445,$14444445,$15555555,$11111111,$15555555,$15555555,$15555555,$15555555; 80
		dc.l $14444445,$11111111,$14444445,$15555555,$15555555,$15555555,$11111111,$15555555; 88
		dc.l $15555555,$11111111,$15555555,$15555555,$15555555,$14444445,$11111111,$14444445; 96
		dc.l $15555555,$15555555,$15555555,$15555555,$11111111,$15555555,$14444445,$14444445; 104
		dc.l $14444445,$13333334,$11111111,$13333334,$13333334,$11111111,$13333334,$11111111; 112
		dc.l $14444445,$11111111,$13333334,$13333334,$13333334,$11111111,$13333334,$13333334; 120
		dc.l $11111111,$13333334,$11111111,$13333334,$13333334,$11111111,$13333334,$14444445; 128
		dc.l $13333334,$13333334,$11111111,$13333334,$13333334,$13333334,$11111111,$14444445; 136
		dc.l $14444445,$11111111,$14444445,$15555555,$15555555,$15555555,$11111111,$15555555; 144
		dc.l $14444445,$14444445,$15555555,$11111111,$15555555,$15555555,$15555555,$15555555; 152
		dc.l $15555555,$15555555,$15555555,$15555555,$11111111,$15555555,$14444445,$14444445; 160
		dc.l $15555555,$11111111,$15555555,$15555555,$15555555,$14444445,$11111111,$14444445; 168
		dc.l $14444445,$11111111,$13333334,$13333334,$13333334,$11111111,$13333334,$13333334; 176
		dc.l $14444445,$13333334,$11111111,$13333334,$13333334,$11111111,$13333334,$11111111; 184
Art_UnkZone_3:	dc.l $11111111,$13111131,$13111131,$14333341,$12222221,$12222221,$11111111,$11111111; 0
					; DATA XREF: ROM:0001ABCEt
		dc.l $11111111,$13111131,$13111131,$14333341,$12222221,$12222221,$11111111,$11111111; 8
		dc.l $13111131,$13111131,$14333341,$12222221,$12222221,$11111111,$11111111,$11111111; 16
		dc.l $11111111,$11111111,$13111131,$13111131,$14333341,$12222221,$12222221,$11111111; 24
		dc.l $11111111,$11111111,$13111131,$13111131,$14333341,$12222221,$12222221,$11111111; 32
		dc.l $13111131,$13111131,$14333341,$12222221,$12222221,$11111111,$11111111,$11111111; 40
Art_UnkZone_4:	dc.l $22222233,$15111111,$11111455,$11145555,$1115B555,$11455B55,$115555B5,$1155555B; 0
					; DATA XREF: ROM:0001ABDAt
		dc.l $33434445,$11111151,$55411111,$55554111,$55555111,$55555411,$55555511,$55555511; 8
		dc.l $22222233,$15111111,$11111455,$1114555B,$1115555B,$1145555B,$1155555B,$1155555B; 16
		dc.l $33434445,$11111151,$55411111,$55554111,$55555111,$55555411,$55555511,$55555511; 24
		dc.l $22222233,$15111111,$11111455,$11145555,$11155555,$11455555,$11555555,$1155555B; 32
		dc.l $33434445,$11111151,$55411111,$55554111,$55B55111,$5B555411,$B5555511,$55555511; 40
Art_UnkZone_5:	dc.l $11111111,$15511222,$15511222,$11155111,$11155111,$12211551,$12211551,$12211115; 0
					; DATA XREF: ROM:0001ABE6t
		dc.l $11111111,$12211222,$12211222,$11155111,$11155111,$12211551,$12211551,$12211115; 8
		dc.l $11111111,$12211222,$12211222,$11122111,$11122111,$12211551,$12211551,$12211115; 16
		dc.l $11111111,$12211222,$12211222,$11122111,$11122111,$12211221,$12211221,$12211115; 24
		dc.l $11111111,$12211222,$12211222,$11122111,$11122111,$12211221,$12211221,$12211112; 32
		dc.l $11111111,$12211555,$12211555,$11155111,$11155111,$15511221,$15511221,$15511112; 40
Art_UnkZone_6:	dc.l	     0,	       0,	 0,	   0,	     0,	$2222222,$22222222,$22222222; 0
					; DATA XREF: ROM:0001ABF8t
		dc.l	  $234,	    $234,     $234,	$234,	  $234,$22000234,$22222234,$22222211; 8
		dc.l $43200000,$43200000,$43200000,$43200000,$43200000,$43200044,$43234444,$11233333; 16
		dc.l	     0,	       0,	 0,	   0,	     0,$55555500,$44455555,$33444444; 24
		dc.l	     0,	       0,	 0,	   0,	     0,	     $44,    $4433,    $3332; 32
		dc.l	  $234,	    $234,     $234,	$234,	  $234,$33300234,$32222234,$22222211; 40
		dc.l $43200000,$43200000,$43200000,$43200000,$43200000,$43200054,$43225543,$11354432; 48
		dc.l	     0,	       0,	 0,	   0,	     0,$32000000,$32220000,$22220000; 56
		dc.l	     0,	       0,	 0,	   0,	     0,	       0,	 0,	   0; 64
		dc.l	  $234,	    $234,     $234,	$234,	  $234,	    $223,    $2334,    $2211; 72
		dc.l $43200000,$43200000,$43200000,$43200000,$43200000,$45200000,$44500000,$11250000; 80
		dc.l	     0,	       0,	 0,	   0,	     0,	       0,	 0,	   0; 88
Art_UnkZone_7:	dc.l	     0,	       0,	 0,	   0,	 $8700,	 $688786,$87876887,$68767768; 0
					; DATA XREF: ROM:0001AC04t
		dc.l	     0,	       0,	 0,	   0,$80000000,$67600000,$87876007,$68767768; 8
		dc.l	     0,	       0,	 0,	   0,	 $8700,	 $688786,$87876887,$68767768; 16
		dc.l	     0,	       0,	 0,	   0,	   $68,	   $8786,$87876887,$68767768; 24
		dc.l	     0,	       0,	 0,	   0,$88778000,$67688780,$87876887,$68767768; 32
		dc.l	     0,	       0,	 0,	   0,	     8,	   $8786,$87876887,$68767768; 40
		dc.l	     0,	       0,	 0,	   0,	 $8000,	     $86,$80076887,$68767768; 48
		dc.l	     0,	       0,	 0,	   0,$88778760,$67688786,$87876887,$68767768; 56
		dc.l	     0,	       0,	 0,	   0,	     0,$67680000,$87876887,$68767768; 64
		dc.l	     0,	       0,	 0,	   0,	     0,$67600000,$87876800,$68767768; 72
		dc.l	     0,	       0,	 0,	   0,	   $68,	   $8786,  $876887,$68767768; 80
		dc.l	     0,	       0,	 0,	   0,$88700000,$67688780,$87876887,$68767768; 88
		dc.l	     0,	       0,	 0,	   0,$80000000,$67688700,$87876887,$68767768; 96
		dc.l	     0,	       0,	 0,	   0,	     0,	       6,$87000887,$68767768; 104
		dc.l	     0,	       0,	 0,	   0,  $778760,$67688786,$87876887,$68767768; 112
		dc.l	     0,	       0,	 0,	   0,  $778700,$67688786,$87876887,$68767768; 120
		dc.l	     0,	       0,	 0,	   0,	     0,$60000000,$87800087,$68767768; 128
		dc.l	     0,	       0,	 0,	   0,	$78700,	$7688786,$87876887,$68767768; 136
Art_UnkZone_8:	dc.l  $6600666,	$7777777, $8888888,	   0, $6600666,	$7777777, $8888888,	   0; 0
					; DATA XREF: ROM:0001AC12t
		dc.l	     0,	$6600666, $7777777, $8888888,	     0,	$6600666, $7777777, $8888888; 8
		dc.l  $8888888,	       0, $6600666, $7777777, $8888888,	       0, $6600666, $7777777; 16
		dc.l  $7777777,	$8888888,	 0, $6600666, $7777777,	$8888888,	 0, $6600666; 24
LevelLayout_Index:
                ; GHZ
                dc.w Level_GHZ1-LevelLayout_Index,Level_GHZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 0
		dc.w Level_GHZ2-LevelLayout_Index,Level_GHZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 3
		dc.w Level_GHZ3-LevelLayout_Index,Level_GHZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 6
		dc.w Level_CPZ1-LevelLayout_Index,Level_CPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 9
                ; LZ
		dc.w Level_CPZ1-LevelLayout_Index,Level_CPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 12
		dc.w Level_CPZ1-LevelLayout_Index,Level_CPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 15
		dc.w Level_CPZ1-LevelLayout_Index,Level_CPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 18
		dc.w Level_CPZ1-LevelLayout_Index,Level_CPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 21
                ; CPZ
		dc.w Level_CPZ1-LevelLayout_Index,Level_CPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 24
		dc.w Level_CPZ1-LevelLayout_Index,Level_CPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 27
		dc.w Level_CPZ1-LevelLayout_Index,Level_CPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 30
		dc.w Level_CPZ1-LevelLayout_Index,Level_CPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 33
                ; EHZ
		dc.w Level_EHZ1-LevelLayout_Index,Level_EHZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 36
		dc.w Level_EHZ2-LevelLayout_Index,Level_EHZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 39
		dc.w Level_EHZ1-LevelLayout_Index,Level_EHZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 42
		dc.w Level_EHZ2-LevelLayout_Index,Level_EHZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 45
                ; HPZ
		dc.w Level_HPZ1-LevelLayout_Index,LeveL_HPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 48
		dc.w Level_HPZ1-LevelLayout_Index,LeveL_HPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 51
		dc.w Level_HPZ1-LevelLayout_Index,LeveL_HPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 54
		dc.w Level_HPZ1-LevelLayout_Index,LeveL_HPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 57
                ; HTZ
		dc.w Level_HTZ1-LevelLayout_Index,Level_HTZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 60
		dc.w Level_HTZ2-LevelLayout_Index,Level_HTZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 63
		dc.w Level_HTZ1-LevelLayout_Index,Level_HTZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 66
		dc.w Level_HTZ2-LevelLayout_Index,Level_HTZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 69
                ; Ending
		dc.w Level_CPZ1-LevelLayout_Index,Level_CPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 72
		dc.w Level_CPZ1-LevelLayout_Index,Level_CPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 75
		dc.w Level_CPZ1-LevelLayout_Index,Level_CPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 78
		dc.w Level_CPZ1-LevelLayout_Index,Level_CPZBg-LevelLayout_Index,Level_Null-LevelLayout_Index; 81
Level_GHZ1:	incbin "levels\ghz1.bin"
                even
Level_GHZ2:	incbin "levels\ghz2.bin"
                even
Level_GHZ3:	incbin "levels\ghz3.bin"
                even
Level_GHZBg:	incbin "levels\ghzbg.bin"
                even
Level_EHZ1:	incbin "levels\ehz1.bin"
                even
Level_EHZ2:	incbin "levels\ehz2.bin"
                even
Level_EHZBg:	incbin "levels\ehzbg.bin"
                even
Level_HTZ1:	incbin "levels\htz1.bin"
                even
Level_HTZ2:	incbin "levels\htz2.bin"
                even
Level_HTZBg:	incbin "levels\htzbg.bin"
                even
Level_CPZ1:	incbin "levels\cpz.bin"
                even
Level_HPZ1:	incbin "levels\hpz.bin"
                even
Level_CPZBg:	incbin "levels\cpzbg.bin"
                even
LeveL_HPZBg:	incbin "levels\hpzbg.bin"
                even
Level_Null:	dc.l 0
Art_BigRing:	incbin "artunc\Giant Ring.bin"
                even
;
; leftover level layouts from a	previous build
;
Leftover_LevelLayouts:incbin "leftovers\Layouts.bin"
                even
;----------------------------------------------------
; leftover from	a previous build
;----------------------------------------------------
Leftover_Art_BigRing:incbin "artunc\Giant Ring.bin"
                even
;
; these	are some level mappings	(16x16 or 256x256)
;
Leftover_LevelMappings:incbin "leftovers\map16.bin"
                even
;
; leftover art - full 128 char ASCII table 0x30000
;
Leftover_Art_Alphabet:incbin "leftovers\0x30000.bin"
                even
;
; various leftover stuff - mostly level	mappings and some palettes
;
; have fun exploring it	:P
;
Leftover_31000:	incbin "leftovers\0x31000.bin"
                even
ObjPos_Index:
                ; GHZ
                dc.w ObjPos_GHZ1-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ2-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ3-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ1-ObjPos_Index,ObjPos_Null-ObjPos_Index
                ; LZ
		dc.w ObjPos_LZ1-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_LZ2-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_LZ3-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_LZ3-ObjPos_Index,ObjPos_Null-ObjPos_Index
		; CPZ
		dc.w ObjPos_CPZ1-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_CPZ2-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_CPZ3-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_CPZ1-ObjPos_Index,ObjPos_Null-ObjPos_Index
		; EHZ
		dc.w ObjPos_EHZ1-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_EHZ2-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_EHZ3-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_EHZ1-ObjPos_Index,ObjPos_Null-ObjPos_Index
		; HPZ
		dc.w ObjPos_HPZ1-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_HPZ2-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_HPZ3-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_HPZ1-ObjPos_Index,ObjPos_Null-ObjPos_Index
		; HTZ
		dc.w ObjPos_HTZ1-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_HTZ2-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_HTZ3-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_HTZ1-ObjPos_Index,ObjPos_Null-ObjPos_Index
		; Ending
		dc.w ObjPos_S1Ending-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_S1Ending-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_S1Ending-ObjPos_Index,ObjPos_Null-ObjPos_Index
		dc.w ObjPos_S1Ending-ObjPos_Index,ObjPos_Null-ObjPos_Index
		; Extra Object Data (Leftover)
		dc.w ObjPos_S1LZ1pf1-ObjPos_Index,ObjPos_S1LZ1pf2-ObjPos_Index
		dc.w ObjPos_S1LZ2pf1-ObjPos_Index,ObjPos_S1LZ2pf2-ObjPos_Index
		dc.w ObjPos_S1LZ3pf1-ObjPos_Index,ObjPos_S1LZ3pf2-ObjPos_Index
		dc.w ObjPos_S1LZ1pf1-ObjPos_Index,ObjPos_S1LZ1pf2-ObjPos_Index
		dc.w ObjPos_S1SBZ1pf1-ObjPos_Index,ObjPos_S1SBZ1pf2-ObjPos_Index
		dc.w ObjPos_S1SBZ1pf3-ObjPos_Index,ObjPos_S1SBZ1pf4-ObjPos_Index
		dc.w ObjPos_S1SBZ1pf5-ObjPos_Index,ObjPos_S1SBZ1pf6-ObjPos_Index
		dc.w ObjPos_S1SBZ1pf1-ObjPos_Index,ObjPos_S1SBZ1pf2-ObjPos_Index
		dc.w $FFFF, 0, 0
ObjPos_GHZ1:	incbin "objpos\ghz1.bin"
                even
ObjPos_GHZ2:	incbin "objpos\ghz2.bin"
                even
ObjPos_GHZ3:	incbin "objpos\ghz3.bin"
                even
ObjPos_LZ1:	dc.w $FFFF,    0,    0	; 0 ; DATA XREF: ROM:ObjPos_Indexo
ObjPos_LZ2:	dc.w $FFFF,    0,    0	; 0 ; DATA XREF: ROM:ObjPos_Indexo
ObjPos_LZ3:	dc.w $FFFF,    0,    0	; 0 ; DATA XREF: ROM:ObjPos_Indexo
ObjPos_S1LZ1pf1:incbin "objpos\lz1pf1.bin"
                even
ObjPos_S1LZ1pf2:incbin "objpos\lz1pf2.bin"
                even
ObjPos_S1LZ2pf1:incbin "objpos\lz2pf1.bin"
                even
ObjPos_S1LZ2pf2:incbin "objpos\lz2pf2.bin"
                even
ObjPos_S1LZ3pf1:incbin "objpos\lz3pf1.bin"
                even
ObjPos_S1LZ3pf2:incbin "objpos\lz3pf2.bin"
                even
ObjPos_CPZ1:	incbin "objpos\cpz.bin"
                even
ObjPos_CPZ2:	dc.w $FFFF,    0,    0	; 0 ; DATA XREF: ROM:ObjPos_Indexo
ObjPos_CPZ3:	dc.w $FFFF,    0,    0	; 0 ; DATA XREF: ROM:ObjPos_Indexo
ObjPos_EHZ1:	incbin "objpos\ehz1.bin"
                even
ObjPos_EHZ2:	incbin "objpos\ehz2.bin"
                even
ObjPos_EHZ3:	dc.w $FFFF,    0,    0	; 0 ; DATA XREF: ROM:ObjPos_Indexo
ObjPos_HPZ1:	incbin "objpos\hpz.bin"
                even
ObjPos_HPZ2:	dc.w $FFFF,    0,    0	; 0 ; DATA XREF: ROM:ObjPos_Indexo
ObjPos_HPZ3:	dc.w $FFFF,    0,    0	; 0 ; DATA XREF: ROM:ObjPos_Indexo
ObjPos_HTZ1:	incbin "objpos\htz1.bin"
                even
ObjPos_HTZ2:	dc.w $FFFF,    0,    0	; 0 ; DATA XREF: ROM:ObjPos_Indexo
ObjPos_HTZ3:	incbin "objpos\htz3.bin"
                even
ObjPos_S1SBZ1pf1:incbin "objpos\sbz1pf1.bin"
                even
ObjPos_S1SBZ1pf2:incbin "objpos\sbz1pf2.bin"
                even
ObjPos_S1SBZ1pf3:incbin "objpos\sbz1pf3.bin"
                even
ObjPos_S1SBZ1pf4:incbin "objpos\sbz1pf4.bin"
                even
ObjPos_S1SBZ1pf5:incbin "objpos\sbz1pf5.bin"
                even
ObjPos_S1SBZ1pf6:incbin "objpos\sbz1pf6.bin"
                even
ObjPos_S1Ending:incbin "objpos\ending.bin"
                even
ObjPos_Null:	dc.w $FFFF,    0,    0	; 0 ; DATA XREF: ROM:ObjPos_Indexo
;
; a symbol table. "compiler trash"
;
Leftover_418A8:	incbin "leftovers\0x418A8.bin"
                even
RingPos_Index:
                ; GHZ
                dc.w RingPos_GHZ1-RingPos_Index
		dc.w RingPos_GHZ2-RingPos_Index
		dc.w RingPos_GHZ3-RingPos_Index
		dc.w RingPos_GHZ1-RingPos_Index
		; LZ
		dc.w RingPos_LZ1-RingPos_Index
		dc.w RingPos_LZ2-RingPos_Index
		dc.w RingPos_LZ3-RingPos_Index
		dc.w RingPos_LZ1-RingPos_Index
		; CPZ
		dc.w RingPos_CPZ1-RingPos_Index
		dc.w RingPos_GHZ2-RingPos_Index
		dc.w RingPos_GHZ3-RingPos_Index
		dc.w RingPos_GHZ1-RingPos_Index
		; EHZ
		dc.w RingPos_EHZ1-RingPos_Index
		dc.w RingPos_EHZ2-RingPos_Index
		dc.w RingPos_HTZ1-RingPos_Index
		dc.w RingPos_HTZ2-RingPos_Index
		; HPZ
		dc.w RingPos_HPZ1-RingPos_Index
		dc.w RingPos_GHZ2-RingPos_Index
		dc.w RingPos_GHZ3-RingPos_Index
		dc.w RingPos_GHZ1-RingPos_Index
		; HTZ
		dc.w RingPos_HTZ1-RingPos_Index
		dc.w RingPos_HTZ2-RingPos_Index
		dc.w RingPos_LZ3-RingPos_Index
		dc.w RingPos_LZ1-RingPos_Index

RingPos_GHZ1:	incbin "ringpos\ghz1.bin"
                even
RingPos_GHZ2:	incbin "ringpos\ghz2.bin"
                even
RingPos_GHZ3:	incbin "ringpos\ghz3.bin"
                even
RingPos_LZ1:	incbin "ringpos\lz1.bin"
                even
RingPos_LZ2:	incbin "ringpos\lz2.bin"
                even
RingPos_LZ3:	incbin "ringpos\lz3.bin"
                even
RingPos_HPZ1:	incbin "ringpos\hpz.bin"
                even
RingPos_EHZ1:	incbin "ringpos\ehz1.bin"
                even
RingPos_EHZ2:	incbin "ringpos\ehz2.bin"
                even
RingPos_HTZ1:	incbin "ringpos\htz.bin"
                even
RingPos_HTZ2:	dc.w $FFFF		; DATA XREF: ROM:RingPos_Indexo
RingPos_CPZ1:	incbin "ringpos\cpz.bin"
                even
;
; now this is a	bigass chunk of	leftovers
;
; in this one you can find practically anything...
;
; most interesting though, is the uncompiled debug mode
;  code	around 0x60000.	sweet stuff
;
Leftover_50A9C:	incbin "leftovers\0x50A9C.bin"
                even

                include "s1.sounddriver.asm"

Art_Sonic:	incbin "artunc\Sonic.bin"
                even
                include "_maps\Sonic.asm"

Art_Tails:	incbin "artunc\Tails.bin"
                even
                include "_maps\Sonic - Dynamic Gfx Script.asm"

Nem_Shield:	incbin "artnem\Shield.bin"
                even
Nem_Stars:	incbin "artnem\Invincibility Stars.bin"
                even
;
; some unused uncompressed art
;
Unused_Art_9E1FB:incbin "leftovers\0x9E1FB.bin"
                even

                include "_maps\Tails.asm"

                include "_maps\Tails - Dynamic Gfx Script.asm"

Nem_SegaLogo:	incbin "artnem\Sega Logo.bin"
                even
Eni_SegaLogo:	incbin "tilemaps\Sega Logo.bin"
                even
Eni_TitleMap:	incbin "tilemaps\Title Screen.bin"
                even
Eni_TitleBg1:	incbin "tilemaps\Title Screen Bg1.bin"
                even
Eni_TitleBg2:	incbin "tilemaps\Title Screen Bg2.bin"
                even
Nem_Title:	incbin "artnem\Title Screen Foreground.bin"
                even
Nem_TitleSonicTails:incbin "artnem\Title Screen Sonic And Tails.bin"
                even
S1Nem_GHZFlowerBits:incbin "artnem\GHZ Flower Stalk.bin"
                even
Nem_SwingPlatform:incbin "artnem\GHZ Swinging Platform.bin"
                even
Nem_GHZ_Bridge:	incbin "artnem\GHZ Bridge.bin"
                even
                incbin "artnem\Unused - GHZ Block.bin"
                even
S1Nem_GHZRollingBall:incbin "artnem\GHZ Giant Ball.bin"
                even
S1Nem_GHZRollingSpikesLog:incbin "artnem\Unused - GHZ Log.bin"
                even                 
S1Nem_GHZLogSpikes:incbin "artnem\GHZ Spiked Log.bin"
                even
Nem_GHZ_Rock:	incbin "artnem\GHZ Purple Rock.bin"
                even
S1Nem_GHZBreakableWall:incbin "artnem\GHZ Breakable Wall.bin"
                even
S1Nem_GHZWall:	incbin "artnem\GHZ Edge Wall.bin"
                even
Nem_EHZ_Fireball:incbin "artnem\EHZ Fireball.bin"
                even        
Nem_BurningLog:	incbin "artnem\Burning Log.bin"
                even
Nem_EHZ_Waterfall:incbin "artnem\EHZ Waterfall.bin"
                even         
Nem_HTZ_Fireball:incbin "artnem\HTZ Fireball.bin"
                even        
Nem_EHZ_Bridge:	incbin "artnem\EHZ Bridge.bin"
                even
Nem_HTZ_Lift:	incbin "artnem\HTZ Lift.bin"
                even
Nem_HTZ_AutomaticDoor:incbin "artnem\HTZ Auto Door.bin"
                even             
Nem_HTZ_Seesaw:	incbin "artnem\HTZ Seesaw.bin"
                even
Nem_HPZ_Bridge:	incbin "artnem\HPZ Bridge.bin"
                even
Nem_HPZ_Waterfall:incbin "artnem\HPZ Waterfall.bin"
                even         
Nem_HPZ_Emerald:incbin "artnem\HPZ Emerald.bin"
                even       
Nem_HPZ_Platform:incbin "artnem\HPZ Platform.bin"
                even        
Nem_HPZ_PulsingBall:incbin "artnem\HPZ Pulsing Ball.bin"
                even           
Nem_HPZ_Various:incbin "artnem\HPZ Various.bin"
                even       
Nem_UnusedDust:	incbin "artnem\Unused - Dust.bin"
                even
Nem_CPZ_Platform:incbin "artnem\CPZ Platform.bin"
                even
Nem_WaterSurface:incbin "artnem\Water Surface.bin"
                even
Nem_Button:	incbin "artnem\Button.bin"
                even
Nem_VSpring2:	incbin "artnem\Vertical Spring.bin"
                even
Nem_HSpring2:	incbin "artnem\Horizontal Spring.bin"
                even
Nem_DSpring:	incbin "artnem\Diagonal Spring.bin"
                even
Nem_HUD:	incbin "artnem\HUD.bin"
                even
Nem_Lives:	incbin "artnem\Lives.bin"
                even
Nem_Ring:	incbin "artnem\Rings.bin"
                even
Nem_Monitors:	incbin "artnem\Monitors.bin"
                even
Nem_VSpikes:	incbin "artnem\Vertical Spikes.bin"
                even
Nem_Points:	incbin "artnem\Points.bin"
                even
Nem_Lamppost:	incbin "artnem\Lamppost.bin"
                even
Nem_Signpost:	incbin "artnem\Signpost.bin"
                even
Nem_Gator:	incbin "artnem\Enemy Gator.bin"
                even
Nem_Buzzer:	incbin "artnem\Enemy Buzzer.bin"
                even
Nem_BBat:	incbin "artnem\Enemy BBat.bin"
                even
Nem_Octus:	incbin "artnem\Enemy Octus.bin"
                even
Nem_Triceratops:incbin "artnem\Enemy Triceratops.bin"
                even
Nem_Redz:	incbin "artnem\Enemy Redz.bin"
                even
Nem_BFish:      incbin "artnem\Enemy BFish.bin"
                even
Nem_Aquis:	incbin "artnem\Enemy Aquis.bin"
                even
Nem_UnusedRollingBall:incbin "artnem\Unused - Rolling Ball.bin"
                even
Nem_MotherBubbler:incbin "artnem\Enemy Bubbler's Mother.bin"
                even
Nem_Bubbler:    incbin "artnem\Enemy Bubbler.bin"
                even
Nem_Snail:	incbin "artnem\Enemy Snail.bin"
                even
Nem_Masher:     incbin "artnem\Enemy Masher.bin"
                even
Nem_BossShip:	incbin "artnem\Boss Ship.bin"
                even
Nem_CPZ_ProtoBoss:incbin "artnem\Boss - CPZ.bin"
                even
Nem_BigExplosion:incbin "artnem\Big Explosion.bin"
                even
Nem_BossShipBoost:incbin "artnem\Boss Ship Boost.bin"
                even
Nem_Smoke:	incbin "artnem\Smoke.bin"
                even
Nem_EHZ_Boss:	incbin "artnem\Boss - EHZ.bin"
                even
Nem_EHZ_Boss_Blades:incbin "artnem\Boss - EHZ Blades.bin"
                even
S1Nem_Ballhog:	incbin "artnem\Enemy Ball Hog.bin"
                even
Nem_Crabmeat:	incbin "artnem\Enemy Crabmeat.bin"
                even
Nem_GHZBuzzbomber:incbin "artnem\Enemy Buzz Bomber.bin"
                even
Nem_UnknownGroundExplosion:incbin "artnem\Unused - Explosion.bin"
                even
S1Nem_LZBurrobot:incbin "artnem\Enemy Burrobot.bin"
                even
Nem_GHZ_Piranha:incbin "artnem\Enemy Chopper.bin"
                even
Nem_S1LZJaws:	incbin "artnem\Enemy Jaws.bin"
                even
Nem_S1SYZRoller:incbin "artnem\Enemy Roller.bin"
                even
Nem_Motobug:	incbin "artnem\Enemy Motobug.bin"
                even
Nem_S1Newtron:	incbin "artnem\Enemy Newtron.bin"
                even
S1Nem_SYZSnail:	incbin "artnem\Enemy Yadrin.bin"
                even
S1Nem_MZBat:	incbin "artnem\Enemy Basaran.bin"
                even
S1Nem_Splats:	incbin "artnem\Enemy Splats.bin"
                even
S1Nem_Bomb:	incbin "artnem\Enemy Bomb.bin"
                even
S1Nem_Orbinaut:	incbin "artnem\Enemy Orbinaut.bin"
                even
S1Nem_Caterkiller:incbin "artnem\Enemy Caterkiller.bin"
                even
Nem_S1TitleCard:incbin "artnem\Title Cards.bin"
                even
Nem_Explosion:	incbin "artnem\Explosion.bin"
                even
Nem_GameOver:	incbin "artnem\Game Over.bin"
                even
Nem_HSpring:	incbin "artnem\S1 Spring Horizontal.bin"
                even
Nem_VSpring:	incbin "artnem\S1 Spring Vertical.bin"
                even
Nem_BigFlash:	incbin "artnem\Giant Ring Flash.bin"
                even
Nem_S1BonusPoints:incbin "artnem\Hidden Bonuses.bin"
                even
S1Nem_SonicContinue:incbin "artnem\Continue Screen Sonic.bin"
                even
S1Nem_MiniSonic:incbin "artnem\Continue Screen Stuff.bin"
                even
Nem_Bunny:	incbin "artnem\Animal Rabbit.bin"
                even
Nem_Chicken:	incbin "artnem\Animal Chicken.bin"
                even
Nem_Penguin:	incbin "artnem\Animal Blackbird.bin"
                even
Nem_Seal:	incbin "artnem\Animal Seal.bin"
                even
Nem_Pig:	incbin "artnem\Animal Pig.bin"
                even
Nem_Flicky:	incbin "artnem\Animal Flicky.bin"
                even
Nem_Squirrel:	incbin "artnem\Animal Squirrel.bin"
                even
Map16_EHZ:	incbin "map16\EHZ.bin"
                even
Nem_EHZ:	incbin "artnem\8x8 - EHZ.bin"
                even
Map16_HTZ:	incbin "map16\HTZ.bin"
                even
Nem_HTZ:	incbin "artnem\8x8 - HTZ.bin"
                even
Nem_HTZ_AniPlaceholders:incbin "artnem\HTZ zip-line platform.bin"
                even
Map128_EHZ:	incbin "map128\EHZ_HTZ.bin"
                even
Map16_HPZ:	incbin "map16\HPZ.bin"
                even
Nem_HPZ:	incbin "artnem\8x8 - HPZ.bin"
                even
Map128_HPZ:	incbin "map128\HPZ.bin"
                even
Map16_CPZ:	incbin "map16\CPZ.bin"
                even
Nem_CPZ:	incbin "artnem\8x8 - CPZ.bin"
                even
Nem_CPZ_Unknown:incbin "artnem\CPZ Buildings.bin"
                even
Map128_CPZ:	incbin "map128\CPZ.bin"
                even
Map16_GHZ:	incbin "map16\GHZ.bin"
                even
Nem_GHZ:	incbin "artnem\8x8 - GHZ1.bin"
                even
Nem_GHZ2:	incbin "artnem\8x8 - GHZ2.bin"
                even
Map128_GHZ:     incbin "map128\GHZ.bin"
                even
;
; yet another leftover chunk
;
Leftover_E0178:	incbin "leftovers\0xE0178.bin"
                even
S1Nem_EndingGraphics:incbin "artnem\Ending - Flowers.bin"
                even
S1Nem_CreditsFont:incbin "artnem\Ending - Credits.bin"
                even
S1Nem_EndingSONICText:incbin "artnem\Ending - StH Logo.bin"
                even
;
; lots of leftover stuff, mostly garbage
;
Leftover_E166F:	incbin "leftovers\0xE166F.bin"
                even
; end of "ROM"


		END
