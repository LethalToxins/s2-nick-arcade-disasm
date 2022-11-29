;----------------------------------------------------
; Object 03 - collision	index switcher (in loops)
;----------------------------------------------------

Obj03:					; DATA XREF: ROM:Obj_Indexo
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj03_Index(pc,d0.w),d1
		jsr	Obj03_Index(pc,d1.w)
		tst.w	($FFFFFFFA).w
		beq.w	loc_CE92
		jmp	MarkObjGone
; ---------------------------------------------------------------------------
Obj03_Index:	dc.w Obj03_Init-Obj03_Index ; DATA XREF: ROM:Obj03_Indexo
					; ROM:00013E4Ao ...
		dc.w loc_13EB4-Obj03_Index
		dc.w loc_13FB6-Obj03_Index
; ---------------------------------------------------------------------------

Obj03_Init:				; DATA XREF: ROM:Obj03_Indexo
		addq.b	#2,$24(a0)
		move.l	#Map_Obj03,4(a0)
		move.w	#$26BC,2(a0)
		bsr.w	ModifySpriteAttr_2P
		move.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#5,$18(a0)
		move.b	$28(a0),d0
		btst	#2,d0
		beq.s	loc_13EA4
		addq.b	#2,$24(a0)
		andi.w	#7,d0
		move.b	d0,$1A(a0)
		andi.w	#3,d0
		add.w	d0,d0
		move.w	Obj03_Data(pc,d0.w),$32(a0)
		bra.w	loc_13FB6
; ---------------------------------------------------------------------------
Obj03_Data:	dc.w   $20,  $40,  $80,	$100; 0
; ---------------------------------------------------------------------------

loc_13EA4:				; CODE XREF: ROM:00013E7Ej
		andi.w	#3,d0
		move.b	d0,$1A(a0)
		add.w	d0,d0
		move.w	Obj03_Data(pc,d0.w),$32(a0)

loc_13EB4:				; DATA XREF: ROM:00013E4Ao
		tst.w	($FFFFFE08).w
		bne.w	locret_13FB4
		move.w	$30(a0),d5
		move.w	8(a0),d0
		move.w	d0,d1
		subq.w	#8,d0
		addq.w	#8,d1
		move.w	$C(a0),d2
		move.w	d2,d3
		move.w	$32(a0),d4
		sub.w	d4,d2
		add.w	d4,d3
		lea	(dword_140B8).l,a2
		moveq	#7,d6

loc_13EE0:				; CODE XREF: ROM:00013FAAj
		move.l	(a2)+,d4
		beq.w	loc_13FA8
		movea.l	d4,a1
		move.w	8(a1),d4
		cmp.w	d0,d4
		bcs.w	loc_13F10
		cmp.w	d1,d4
		bcc.w	loc_13F10
		move.w	$C(a1),d4
		cmp.w	d2,d4
		bcs.w	loc_13F10
		cmp.w	d3,d4
		bcc.w	loc_13F10
		ori.w	#$8000,d5
		bra.w	loc_13FA8
; ---------------------------------------------------------------------------

loc_13F10:				; CODE XREF: ROM:00013EEEj
					; ROM:00013EF4j ...
		tst.w	d5
		bpl.w	loc_13FA8
		swap	d0
		move.b	$28(a0),d0
		bpl.s	loc_13F26
		btst	#1,$22(a1)
		bne.s	loc_13FA2

loc_13F26:				; CODE XREF: ROM:00013F1Cj
		move.w	8(a1),d4
		cmp.w	8(a0),d4
		bcs.s	loc_13F62
		move.b	#$C,$3E(a1)
		move.b	#$D,$3F(a1)
		btst	#3,d0
		beq.s	loc_13F4E
		move.b	#$E,$3E(a1)
		move.b	#$F,$3F(a1)

loc_13F4E:				; CODE XREF: ROM:00013F40j
		bclr	#7,2(a1)
		btst	#5,d0
		beq.s	loc_13F92
		bset	#7,2(a1)
		bra.s	loc_13F92
; ---------------------------------------------------------------------------

loc_13F62:				; CODE XREF: ROM:00013F2Ej
		move.b	#$C,$3E(a1)
		move.b	#$D,$3F(a1)
		btst	#4,d0
		beq.s	loc_13F80
		move.b	#$E,$3E(a1)
		move.b	#$F,$3F(a1)

loc_13F80:				; CODE XREF: ROM:00013F72j
		bclr	#7,2(a1)
		btst	#6,d0
		beq.s	loc_13F92
		bset	#7,2(a1)

loc_13F92:				; CODE XREF: ROM:00013F58j
					; ROM:00013F60j ...
		tst.w	($FFFFFFFA).w
		beq.s	loc_13FA2
		move.w	#$A1,d0	; "¡"
		jsr	(PlaySound_Special).l

loc_13FA2:				; CODE XREF: ROM:00013F24j
					; ROM:00013F96j
		swap	d0
		andi.w	#$7FFF,d5

loc_13FA8:				; CODE XREF: ROM:00013EE2j
					; ROM:00013F0Cj ...
		add.l	d5,d5
		dbf	d6,loc_13EE0
		swap	d5
		move.b	d5,$30(a0)

locret_13FB4:				; CODE XREF: ROM:00013EB8j
		rts
; ---------------------------------------------------------------------------

loc_13FB6:				; CODE XREF: ROM:00013E98j
					; DATA XREF: ROM:00013E4Co
		tst.w	($FFFFFE08).w
		bne.w	locret_140B6
		move.w	$30(a0),d5
		move.w	8(a0),d0
		move.w	d0,d1
		move.w	$32(a0),d4
		sub.w	d4,d0
		add.w	d4,d1
		move.w	$C(a0),d2
		move.w	d2,d3
		subq.w	#8,d2
		addq.w	#8,d3
		lea	(dword_140B8).l,a2
		moveq	#7,d6

loc_13FE2:				; CODE XREF: ROM:000140ACj
		move.l	(a2)+,d4
		beq.w	loc_140AA
		movea.l	d4,a1
		move.w	8(a1),d4
		cmp.w	d0,d4
		bcs.w	loc_14012
		cmp.w	d1,d4
		bcc.w	loc_14012
		move.w	$C(a1),d4
		cmp.w	d2,d4
		bcs.w	loc_14012
		cmp.w	d3,d4
		bcc.w	loc_14012
		ori.w	#$8000,d5
		bra.w	loc_140AA
; ---------------------------------------------------------------------------

loc_14012:				; CODE XREF: ROM:00013FF0j
					; ROM:00013FF6j ...
		tst.w	d5
		bpl.w	loc_140AA
		swap	d0
		move.b	$28(a0),d0
		bpl.s	loc_14028
		btst	#1,$22(a1)
		bne.s	loc_140A4

loc_14028:				; CODE XREF: ROM:0001401Ej
		move.w	$C(a1),d4
		cmp.w	$C(a0),d4
		bcs.s	loc_14064
		move.b	#$C,$3E(a1)
		move.b	#$D,$3F(a1)
		btst	#3,d0
		beq.s	loc_14050
		move.b	#$E,$3E(a1)
		move.b	#$F,$3F(a1)

loc_14050:				; CODE XREF: ROM:00014042j
		bclr	#7,2(a1)
		btst	#5,d0
		beq.s	loc_14094
		bset	#7,2(a1)
		bra.s	loc_14094
; ---------------------------------------------------------------------------

loc_14064:				; CODE XREF: ROM:00014030j
		move.b	#$C,$3E(a1)
		move.b	#$D,$3F(a1)
		btst	#4,d0
		beq.s	loc_14082
		move.b	#$E,$3E(a1)
		move.b	#$F,$3F(a1)

loc_14082:				; CODE XREF: ROM:00014074j
		bclr	#7,2(a1)
		btst	#6,d0
		beq.s	loc_14094
		bset	#7,2(a1)

loc_14094:				; CODE XREF: ROM:0001405Aj
					; ROM:00014062j ...
		tst.w	($FFFFFFFA).w
		beq.s	loc_140A4
		move.w	#$A1,d0	; "¡"
		jsr	(PlaySound_Special).l

loc_140A4:				; CODE XREF: ROM:00014026j
					; ROM:00014098j
		swap	d0
		andi.w	#$7FFF,d5

loc_140AA:				; CODE XREF: ROM:00013FE4j
					; ROM:0001400Ej ...
		add.l	d5,d5
		dbf	d6,loc_13FE2
		swap	d5
		move.b	d5,$30(a0)

locret_140B6:				; CODE XREF: ROM:00013FBAj
		rts
; ---------------------------------------------------------------------------
dword_140B8:	dc.l v_objspace		; DATA XREF: ROM:00013ED8o
					; ROM:00013FDAo
		dc.l v_objspace+$40
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0