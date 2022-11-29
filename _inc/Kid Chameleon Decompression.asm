; =============== S U B	R O U T	I N E =======================================

;sub_13684
Decompress_Chunk:
	moveq	#0,d0
	move.w	#$7FF,d4
	moveq	#0,d5
	moveq	#0,d6
	move.w	a3,d7
	subq.w	#1,d2
	beq.w	loc_dec_A24
	subq.w	#1,d2
	beq.w	loc_dec_9A6
	subq.w	#1,d2
	beq.w	loc_dec_928
	subq.w	#1,d2
	beq.w	loc_dec_8AA
	subq.w	#1,d2
	beq.w	loc_dec_82E
	subq.w	#1,d2
	beq.w	loc_dec_7B0
	subq.w	#1,d2
	beq.w	loc_dec_736

Decompress_BitPos0:
	move.b	(a0)+,d1
	add.b	d1,d1
	bcs.s	Decompress_BP0_DrcCpy
	move.l	a2,a6
	add.b	d1,d1
	bcs.s	Decompress_BP0_LongRef
	move.b	(a1)+,d5
	suba.l	d5,a6
	add.b	d1,d1
	bcc.s	loc_dec_6D0
	move.b	(a6)+,(a2)+

loc_dec_6D0:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_724
	bra.w	loc_dec_82E
; ---------------------------------------------------------------------------

Decompress_BP0_LongRef:
	lsl.w	#3,d1
	move.w	d1,d6
	and.w	d4,d6		; d4 = $7FF
	move.b	(a1)+,d6
	suba.l	d6,a6
	add.b	d1,d1
	bcs.s	Decompress_BP0_LongRef_2or3
	add.b	d1,d1
	bcs.s	loc_dec_706
	bra.s	loc_dec_708
; ---------------------------------------------------------------------------

Decompress_BP0_LongRef_2or3:
	add.b	d1,d1
	bcc.s	Decompress_BP0_LongRef_2
	moveq	#0,d0
	move.b	(a1)+,d0	; read amount of bytes
	beq.s	loc_dec_716
	subq.w	#6,d0
	bmi.s	loc_dec_71C

loc_dec_6FE:
	move.b	(a6)+,(a2)+
	dbf	d0,loc_dec_6FE

Decompress_BP0_LongRef_2:
	move.b	(a6)+,(a2)+

loc_dec_706:
	move.b	(a6)+,(a2)+

loc_dec_708:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_72C
	bra.w	loc_dec_A24
; ---------------------------------------------------------------------------

loc_dec_716:
	move.w	#0,d0
	rts
; ---------------------------------------------------------------------------

loc_dec_71C:
	move.w	#$FFFF,d0
	moveq	#1,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_724:
	move.w	#1,d0
	moveq	#5,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_72C:
	move.w	#1,d0
	moveq	#1,d2
	rts
; ---------------------------------------------------------------------------

Decompress_BP0_DrcCpy:
	move.b	(a1)+,(a2)+

loc_dec_736:
	add.b	d1,d1
	bcs.s	loc_dec_7AE	; top bit = 1 --> direct copy
	move.l	a2,a6
	add.b	d1,d1
	bcs.s	loc_dec_756	; top bits 01 --> long ref
	; top bits 00 --> short ref 00:A
	move.b	(a1)+,d5
	suba.l	d5,a6
	add.b	d1,d1
	bcc.s	loc_dec_74A	; A = 0 --> copy 2 tiles
	; A = 1 --> copy 3 tiles
	move.b	(a6)+,(a2)+

loc_dec_74A:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_79E
	bra.w	loc_dec_8AA
; ---------------------------------------------------------------------------

loc_dec_756:	; long ref 01:BBB:AA
	lsl.w	#3,d1	; skip 3 bits, put the into upper byte of word
	move.w	d1,d6
	and.w	d4,d6	; d4 = $7FF? is that always true?
	move.b	(a1)+,d6	; d6 = BBB*256 + BYTE1
	suba.l	d6,a6	; address to copy from
	add.b	d1,d1
	bcs.s	loc_dec_76A	; first bit of AA is 1
	add.b	d1,d1
	bcs.s	loc_dec_780	; AA = 01 --> copy 4 tiles
	bra.s	loc_dec_782	; AA = 00 --> copy 3 tiles
; ---------------------------------------------------------------------------

loc_dec_76A:
	add.b	d1,d1
	bcc.s	loc_dec_77E	; AA = 10 --> copy 5 tiles
	; AA = 11 --> copy 6 or more tiles
	moveq	#0,d0
	move.b	(a1)+,d0
	beq.s	loc_dec_790	; BYTE2 = 0 means: quit decompression
	subq.w	#6,d0
	bmi.s	loc_dec_796	; 0 < BYTE2 < 6 means: flush buffer

loc_dec_778:	; copy BYTE2 tiles
	move.b	(a6)+,(a2)+
	dbf	d0,loc_dec_778

loc_dec_77E:
	move.b	(a6)+,(a2)+

loc_dec_780:
	move.b	(a6)+,(a2)+

loc_dec_782:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_7A6
	bra.w	Decompress_BitPos0
; ---------------------------------------------------------------------------

loc_dec_790:	; quit decompression
	move.w	#0,d0
	rts
; ---------------------------------------------------------------------------

loc_dec_796:	; flush decompression buffer
	move.w	#$FFFF,d0
	moveq	#0,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_79E:
	move.w	#1,d0
	moveq	#4,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_7A6:
	move.w	#1,d0
	moveq	#0,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_7AE:
	move.b	(a1)+,(a2)+

loc_dec_7B0:
	add.b	d1,d1
	bcs.s	loc_dec_82C
	move.l	a2,a6
	add.b	d1,d1
	bcs.s	loc_dec_7D0
	move.b	(a1)+,d5
	suba.l	d5,a6
	add.b	d1,d1
	bcc.s	loc_dec_7C4
	move.b	(a6)+,(a2)+

loc_dec_7C4:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_81C
	bra.w	loc_dec_928
; ---------------------------------------------------------------------------

loc_dec_7D0:
	lsl.w	#3,d1
	move.w	d1,d6
	and.w	d4,d6
	move.b	(a1)+,d6
	suba.l	d6,a6
	add.b	d1,d1
	bcs.s	loc_dec_7E6
	move.b	(a0)+,d1
	add.b	d1,d1
	bcs.s	loc_dec_7FE
	bra.s	loc_dec_800
; ---------------------------------------------------------------------------

loc_dec_7E6:
	move.b	(a0)+,d1
	add.b	d1,d1
	bcc.s	loc_dec_7FC
	moveq	#0,d0
	move.b	(a1)+,d0
	beq.s	loc_dec_80E
	subq.w	#6,d0
	bmi.s	loc_dec_814

loc_dec_7F6:
	move.b	(a6)+,(a2)+
	dbf	d0,loc_dec_7F6

loc_dec_7FC:
	move.b	(a6)+,(a2)+

loc_dec_7FE:
	move.b	(a6)+,(a2)+

loc_dec_800:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_824
	bra.w	loc_dec_736
; ---------------------------------------------------------------------------

loc_dec_80E:
	move.w	#0,d0
	rts
; ---------------------------------------------------------------------------

loc_dec_814:
	move.w	#$FFFF,d0
	moveq	#7,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_81C:
	move.w	#1,d0
	moveq	#3,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_824:
	move.w	#1,d0
	moveq	#7,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_82C:
	move.b	(a1)+,(a2)+

loc_dec_82E:
	add.b	d1,d1
	bcs.s	loc_dec_8A8
	move.l	a2,a6
	add.b	d1,d1
	bcs.s	loc_dec_84E
	move.b	(a1)+,d5
	suba.l	d5,a6
	add.b	d1,d1
	bcc.s	loc_dec_842
	move.b	(a6)+,(a2)+

loc_dec_842:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_898
	bra.w	loc_dec_9A6
; ---------------------------------------------------------------------------

loc_dec_84E:
	lsl.w	#3,d1
	move.b	(a0)+,d1
	move.w	d1,d6
	and.w	d4,d6
	move.b	(a1)+,d6
	suba.l	d6,a6
	add.b	d1,d1
	bcs.s	loc_dec_864
	add.b	d1,d1
	bcs.s	loc_dec_87A
	bra.s	loc_dec_87C
; ---------------------------------------------------------------------------

loc_dec_864:
	add.b	d1,d1
	bcc.s	loc_dec_878
	moveq	#0,d0
	move.b	(a1)+,d0
	beq.s	loc_dec_88A
	subq.w	#6,d0
	bmi.s	loc_dec_890

loc_dec_872:
	move.b	(a6)+,(a2)+
	dbf	d0,loc_dec_872

loc_dec_878:
	move.b	(a6)+,(a2)+

loc_dec_87A:
	move.b	(a6)+,(a2)+

loc_dec_87C:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_8A0
	bra.w	loc_dec_7B0
; ---------------------------------------------------------------------------

loc_dec_88A:
	move.w	#0,d0
	rts
; ---------------------------------------------------------------------------

loc_dec_890:
	move.w	#$FFFF,d0
	moveq	#6,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_898:
	move.w	#1,d0
	moveq	#2,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_8A0:
	move.w	#1,d0
	moveq	#6,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_8A8:
	move.b	(a1)+,(a2)+

loc_dec_8AA:
	add.b	d1,d1
	bcs.s	loc_dec_926
	move.l	a2,a6
	add.b	d1,d1
	bcs.s	loc_dec_8CA
	move.b	(a1)+,d5
	suba.l	d5,a6
	add.b	d1,d1
	bcc.s	loc_dec_8BE
	move.b	(a6)+,(a2)+

loc_dec_8BE:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_916
	bra.w	loc_dec_A24
; ---------------------------------------------------------------------------

loc_dec_8CA:
	lsl.w	#2,d1
	move.b	(a0)+,d1
	add.w	d1,d1
	move.w	d1,d6
	and.w	d4,d6
	move.b	(a1)+,d6
	suba.l	d6,a6
	add.b	d1,d1
	bcs.s	loc_dec_8E2
	add.b	d1,d1
	bcs.s	loc_dec_8F8
	bra.s	loc_dec_8FA
; ---------------------------------------------------------------------------

loc_dec_8E2:
	add.b	d1,d1
	bcc.s	loc_dec_8F6
	moveq	#0,d0
	move.b	(a1)+,d0
	beq.s	loc_dec_908
	subq.w	#6,d0
	bmi.s	loc_dec_90E

loc_dec_8F0:
	move.b	(a6)+,(a2)+
	dbf	d0,loc_dec_8F0

loc_dec_8F6:
	move.b	(a6)+,(a2)+

loc_dec_8F8:
	move.b	(a6)+,(a2)+

loc_dec_8FA:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_91E
	bra.w	loc_dec_82E
; ---------------------------------------------------------------------------

loc_dec_908:
	move.w	#0,d0
	rts
; ---------------------------------------------------------------------------

loc_dec_90E:
	move.w	#$FFFF,d0
	moveq	#5,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_916:
	move.w	#1,d0
	moveq	#1,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_91E:
	move.w	#1,d0
	moveq	#5,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_926:
	move.b	(a1)+,(a2)+

loc_dec_928:
	add.b	d1,d1
	bcs.s	loc_dec_9A4
	move.l	a2,a6
	add.b	d1,d1
	bcs.s	loc_dec_948
	move.b	(a1)+,d5
	suba.l	d5,a6
	add.b	d1,d1
	bcc.s	loc_dec_93C
	move.b	(a6)+,(a2)+

loc_dec_93C:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_994
	bra.w	Decompress_BitPos0
; ---------------------------------------------------------------------------

loc_dec_948:
	add.w	d1,d1
	move.b	(a0)+,d1
	lsl.w	#2,d1
	move.w	d1,d6
	and.w	d4,d6
	move.b	(a1)+,d6
	suba.l	d6,a6
	add.b	d1,d1
	bcs.s	loc_dec_960
	add.b	d1,d1
	bcs.s	loc_dec_976
	bra.s	loc_dec_978
; ---------------------------------------------------------------------------

loc_dec_960:
	add.b	d1,d1
	bcc.s	loc_dec_974
	moveq	#0,d0
	move.b	(a1)+,d0
	beq.s	loc_dec_986
	subq.w	#6,d0
	bmi.s	loc_dec_98C

loc_dec_96E:
	move.b	(a6)+,(a2)+
	dbf	d0,loc_dec_96E

loc_dec_974:
	move.b	(a6)+,(a2)+

loc_dec_976:
	move.b	(a6)+,(a2)+

loc_dec_978:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_99C
	bra.w	loc_dec_8AA
; ---------------------------------------------------------------------------

loc_dec_986:
	move.w	#0,d0
	rts
; ---------------------------------------------------------------------------

loc_dec_98C:
	move.w	#$FFFF,d0
	moveq	#4,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_994:
	move.w	#1,d0
	moveq	#8,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_99C:
	move.w	#1,d0
	moveq	#4,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_9A4:
	move.b	(a1)+,(a2)+

loc_dec_9A6:
	add.b	d1,d1
	bcs.s	loc_dec_A22
	move.l	a2,a6
	add.b	d1,d1
	bcs.s	loc_dec_9C8
	move.b	(a0)+,d1
	move.b	(a1)+,d5
	suba.l	d5,a6
	add.b	d1,d1
	bcc.s	loc_dec_9BC
	move.b	(a6)+,(a2)+

loc_dec_9BC:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_A12
	bra.w	loc_dec_736
; ---------------------------------------------------------------------------

loc_dec_9C8:
	move.b	(a0)+,d1
	lsl.w	#3,d1
	move.w	d1,d6
	and.w	d4,d6
	move.b	(a1)+,d6
	suba.l	d6,a6
	add.b	d1,d1
	bcs.s	loc_dec_9DE
	add.b	d1,d1
	bcs.s	loc_dec_9F4
	bra.s	loc_dec_9F6
; ---------------------------------------------------------------------------

loc_dec_9DE:
	add.b	d1,d1
	bcc.s	loc_dec_9F2
	moveq	#0,d0
	move.b	(a1)+,d0
	beq.s	loc_dec_A04
	subq.w	#6,d0
	bmi.s	loc_dec_A0A

loc_dec_9EC:
	move.b	(a6)+,(a2)+
	dbf	d0,loc_dec_9EC

loc_dec_9F2:
	move.b	(a6)+,(a2)+

loc_dec_9F4:
	move.b	(a6)+,(a2)+

loc_dec_9F6:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_A1A
	bra.w	loc_dec_928
; ---------------------------------------------------------------------------

loc_dec_A04:
	move.w	#0,d0
	rts
; ---------------------------------------------------------------------------

loc_dec_A0A:
	move.w	#$FFFF,d0
	moveq	#3,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_A12:
	move.w	#1,d0
	moveq	#7,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_A1A:
	move.w	#1,d0
	moveq	#3,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_A22:
	move.b	(a1)+,(a2)+

loc_dec_A24:
	add.b	d1,d1
	bcs.s	loc_dec_A9E
	move.b	(a0)+,d1
	move.l	a2,a6
	add.b	d1,d1
	bcs.s	loc_dec_A46
	move.b	(a1)+,d5
	suba.l	d5,a6
	add.b	d1,d1
	bcc.s	loc_dec_A3A
	move.b	(a6)+,(a2)+

loc_dec_A3A:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_A8E
	bra.w	loc_dec_7B0
; ---------------------------------------------------------------------------

loc_dec_A46:
	lsl.w	#3,d1
	move.w	d1,d6
	and.w	d4,d6
	move.b	(a1)+,d6
	suba.l	d6,a6
	add.b	d1,d1
	bcs.s	loc_dec_A5A
	add.b	d1,d1
	bcs.s	loc_dec_A70
	bra.s	loc_dec_A72
; ---------------------------------------------------------------------------

loc_dec_A5A:
	add.b	d1,d1
	bcc.s	loc_dec_A6E
	moveq	#0,d0
	move.b	(a1)+,d0
	beq.s	loc_dec_A80
	subq.w	#6,d0
	bmi.s	loc_dec_A86

loc_dec_A68:
	move.b	(a6)+,(a2)+
	dbf	d0,loc_dec_A68

loc_dec_A6E:
	move.b	(a6)+,(a2)+

loc_dec_A70:
	move.b	(a6)+,(a2)+

loc_dec_A72:
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	move.b	(a6)+,(a2)+
	cmp.w	a2,d7
	bls.s	loc_dec_A96
	bra.w	loc_dec_9A6
; ---------------------------------------------------------------------------

loc_dec_A80:
	move.w	#0,d0
	rts
; ---------------------------------------------------------------------------

loc_dec_A86:
	move.w	#$FFFF,d0
	moveq	#2,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_A8E:
	move.w	#1,d0
	moveq	#6,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_A96:
	move.w	#1,d0
	moveq	#2,d2
	rts
; ---------------------------------------------------------------------------

loc_dec_A9E:
	move.b	(a1)+,(a2)+
	bra.w	Decompress_BitPos0
; End of function Decompress_Chunk