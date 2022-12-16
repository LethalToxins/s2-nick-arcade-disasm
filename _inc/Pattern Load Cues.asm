; ---------------------------------------------------------------------------
; Pattern load cues
; ---------------------------------------------------------------------------
ArtLoadCues:

ptr_PLC_Main:		dc.w PLC_Main-ArtLoadCues
ptr_PLC_Main2:		dc.w PLC_Main2-ArtLoadCues
ptr_PLC_Explode:	dc.w PLC_Explode-ArtLoadCues
ptr_PLC_GameOver:	dc.w PLC_GameOver-ArtLoadCues
PLC_Levels:
ptr_PLC_GHZ:		dc.w PLC_GHZ-ArtLoadCues
ptr_PLC_GHZ2:		dc.w PLC_GHZ2-ArtLoadCues
ptr_PLC_LZ:		dc.w PLC_CPZ-ArtLoadCues
ptr_PLC_LZ2:            dc.w PLC_CPZ2-ArtLoadCues
ptr_PLC_CPZ:		dc.w PLC_CPZ-ArtLoadCues
ptr_PLC_CPZ2:           dc.w PLC_CPZ2-ArtLoadCues
ptr_PLC_EHZ:		dc.w PLC_EHZ-ArtLoadCues
ptr_PLC_EHZ2:           dc.w PLC_EHZ2-ArtLoadCues
ptr_PLC_HPZ:		dc.w PLC_HPZ-ArtLoadCues
ptr_PLC_HPZ2:           dc.w PLC_HPZ2-ArtLoadCues
ptr_PLC_HTZ:		dc.w PLC_HTZ-ArtLoadCues
ptr_PLC_HTZ2:           dc.w PLC_HTZ2-ArtLoadCues

ptr_PLC_TitleCard:	dc.w PLC_S1TitleCard-ArtLoadCues
ptr_PLC_Boss:		dc.w PLC_Boss-ArtLoadCues
ptr_PLC_Signpost:	dc.w PLC_Signpost-ArtLoadCues
ptr_PLC_SpecialStage:	dc.w PLC_Invalid-ArtLoadCues
ptr_PLC_Warp:		dc.w PLC_Invalid-ArtLoadCues
PLC_Animals:
ptr_PLC_GHZAnimals:	dc.w PLC_GHZAnimals-ArtLoadCues
ptr_PLC_LZAnimals:	dc.w PLC_LZAnimals-ArtLoadCues
ptr_PLC_CPZAnimals:	dc.w PLC_CPZAnimals-ArtLoadCues
ptr_PLC_EHZAnimals:	dc.w PLC_EHZAnimals-ArtLoadCues
ptr_PLC_HPZAnimals:	dc.w PLC_HPZAnimals-ArtLoadCues
ptr_PLC_HTZAnimals:	dc.w PLC_HTZAnimals-ArtLoadCues

ptr_PLC_SSResult:	dc.w PLC_SSResult-ArtLoadCues
ptr_PLC_Ending:		dc.w PLC_Ending-ArtLoadCues
ptr_PLC_TryAgain:	dc.w PLC_TryAgain-ArtLoadCues
ptr_PLC_EggmanSBZ2:	dc.w PLC_EggmanSBZ2-ArtLoadCues
ptr_PLC_FZBoss:		dc.w PLC_FZBoss-ArtLoadCues

PLC_SSResult:    equ $1C318
PLC_Ending:      equ $1C31A
PLC_TryAgain:    equ $1C31C
PLC_EggmanSBZ2:  equ $1C31E
PLC_FZBoss:      equ $1C320

plcm:	macro gfx,vram
	dc.l gfx
	dc.w vram
	endm

PLC_Main:	dc.w ((PLC_Mainend-PLC_Main-2)/6)-1
		plcm    Nem_Lamppost, $8F80
		plcm    Nem_HUD, $D940
		plcm    Nem_Lives, $FA80
		plcm    Nem_Ring, $D780
		plcm    Nem_Points, $9580
	PLC_Mainend:

PLC_Main2:	dc.w ((PLC_Main2end-PLC_Main2-2)/6)-1
		plcm    Nem_Monitors, $D000
		plcm    Nem_Shield, $97C0
		plcm    Nem_Stars, $9BC0
        PLC_Main2end:

PLC_Explode:	dc.w ((PLC_Explodeend-PLC_Explode-2)/6)-1
		plcm    Nem_Explosion, $B400
        PLC_Explodeend:

PLC_GameOver:	dc.w ((PLC_GameOverend-PLC_GameOver-2)/6)-1
		plcm    Nem_GameOver, $ABC0
        PLC_GameOverend:

PLC_GHZ:	dc.w ((PLC_GHZend-PLC_GHZ-2)/6)-1
                plcm    Nem_GHZ, 0
                plcm    Nem_GHZ_Piranha, $8E00
                plcm    Nem_VSpikes, $9400
                plcm    Nem_HSpring, $9500
                plcm    Nem_VSpring, $9700
                plcm    Nem_GHZ_Bridge, $98C0
                plcm    Nem_SwingPlatform, $9A00
                plcm    Nem_Motobug, $9C00
                plcm    Nem_GHZ_Rock, $D800
	PLC_GHZend:

PLC_GHZ2:	dc.w ((PLC_GHZ2end-PLC_GHZ2-2)/6)-1
                plcm    Nem_GHZ_Piranha, $8E00
	PLC_GHZ2end:

PLC_CPZ:	dc.w 2			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_CPZ
		dc.w 0
		dc.l Nem_CPZ_Unknown
		dc.w $7A00
		dc.l Nem_CPZ_Platform
		dc.w $8000
PLC_CPZ2:	dc.w 3			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_VSpikes
		dc.w $8680
		dc.l Nem_DSpring
		dc.w $8780
		dc.l Nem_VSpring2
		dc.w $8B80
		dc.l Nem_HSpring2
		dc.w $8E00
PLC_EHZ:	dc.w 8			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_EHZ
		dc.w 0
		dc.l Nem_EHZ_Fireball
		dc.w $73C0
		dc.l Nem_EHZ_Waterfall
		dc.w $75C0
		dc.l Nem_EHZ_Bridge
		dc.w $78C0
		dc.l Nem_HTZ_Seesaw
		dc.w $79C0
		dc.l Nem_VSpikes
		dc.w $8680
		dc.l Nem_DSpring
		dc.w $8780
		dc.l Nem_VSpring2
		dc.w $8B80
		dc.l Nem_HSpring2
		dc.w $8E00
PLC_EHZ2:	dc.w 4			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_Shield
		dc.w $AC00
		dc.l Nem_Points
		dc.w $9580
		dc.l Nem_Buzzer
		dc.w $7CC0
		dc.l Nem_Snail
		dc.w $8040
		dc.l Nem_Masher
		dc.w $8380
PLC_HPZ:	dc.w 7			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_HPZ
		dc.w 0
		dc.l Nem_HPZ_Bridge
		dc.w $6000
		dc.l Nem_HPZ_Waterfall
		dc.w $62A0
		dc.l Nem_HPZ_Platform
		dc.w $6940
		dc.l Nem_HPZ_PulsingBall
		dc.w $6B40
		dc.l Nem_HPZ_Various
		dc.w $6F80
		dc.l Nem_HPZ_Emerald
		dc.w $7240
		dc.l Nem_WaterSurface
		dc.w $8000
PLC_HPZ2:	dc.w 1			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_Redz
		dc.w $A000
		dc.l Nem_BBat
        	dc.w $A600
		dc.l Nem_Gator
		dc.w $6000
		dc.l Nem_Buzzer
		dc.w $6580
		dc.l Nem_BBat
		dc.w $6A00
		dc.l Nem_Triceratops
		dc.w $7880
		dc.l Nem_Redz
		dc.w $A000
		dc.l Nem_BFish
		dc.w $A600
PLC_HTZ:	dc.w 9			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_EHZ
		dc.w 0
		dc.l Nem_HTZ
		dc.w $3F80
		dc.l Nem_HTZ_AniPlaceholders
		dc.w $A000
		dc.l Nem_EHZ_Fireball
		dc.w $73C0
		dc.l Nem_HTZ_Fireball
		dc.w $75C0
		dc.l Nem_HTZ_AutomaticDoor
		dc.w $77C0
		dc.l Nem_EHZ_Bridge
		dc.w $78C0
		dc.l Nem_HTZ_Seesaw
		dc.w $79C0
		dc.l Nem_VSpikes
		dc.w $8680
		dc.l Nem_DSpring
		dc.w $8780
		dc.l Nem_VSpring2
		dc.w $8B80
		dc.l Nem_HSpring2
		dc.w $8E00
PLC_HTZ2:	dc.w 0			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_HTZ_Lift
		dc.w $7CC0
		dc.l Nem_Buzzer
		dc.w $7CC0
		dc.l Nem_Snail
		dc.w $8040
		dc.l Nem_Masher
		dc.w $8380
PLC_S1TitleCard:dc.w 0			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_S1TitleCard
		dc.w $B000
PLC_Boss:	dc.w 2			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_BossShip
		dc.w $8C00
		dc.l Nem_EHZ_Boss
		dc.w $9800
		dc.l Nem_EHZ_Boss_Blades
		dc.w $A800
		dc.l Nem_BossShip
		dc.w $8000
		dc.l Nem_CPZ_ProtoBoss
		dc.w $8C00
		dc.l Nem_BossShipBoost
		dc.w $9A00
		dc.l Nem_Smoke
		dc.w $9B00
		dc.l Nem_EHZ_Boss
		dc.w $9D00
		dc.l Nem_EHZ_Boss_Blades
		dc.w $AD00
PLC_Signpost:	dc.w 2			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_Signpost
		dc.w $D000
		dc.l Nem_S1BonusPoints
		dc.w $96C0
		dc.l Nem_BigFlash
		dc.w $8C40
PLC_Invalid:	dc.w $10		; DATA XREF: ROM:ArtLoadCueso
PLC_GHZAnimals:	dc.w 1			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_Bunny
		dc.w $B000
		dc.l Nem_Flicky
		dc.w $B240
PLC_LZAnimals:	dc.w 1			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_Penguin
		dc.w $B000
		dc.l Nem_Seal
		dc.w $B240
PLC_CPZAnimals:	dc.w 1			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_Squirrel
		dc.w $B000
		dc.l Nem_Seal
		dc.w $B240
PLC_EHZAnimals:	dc.w 1			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_Pig
		dc.w $B000
		dc.l Nem_Flicky
		dc.w $B240
PLC_HPZAnimals:	dc.w 1			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_Pig
		dc.w $B000
		dc.l Nem_Chicken
		dc.w $B240
PLC_HTZAnimals:	dc.w 1			; DATA XREF: ROM:ArtLoadCueso
		dc.l Nem_Bunny
		dc.w $B000
		dc.l Nem_Chicken
		dc.w $B240
		
; ---------------------------------------------------------------------------
; Pattern load cue IDs
; ---------------------------------------------------------------------------
plcid_Main:		equ (ptr_PLC_Main-ArtLoadCues)/2	; 0
plcid_Main2:		equ (ptr_PLC_Main2-ArtLoadCues)/2	; 1
plcid_Explode:		equ (ptr_PLC_Explode-ArtLoadCues)/2	; 2
plcid_GameOver:		equ (ptr_PLC_GameOver-ArtLoadCues)/2	; 3
plcid_GHZ:		equ (ptr_PLC_GHZ-ArtLoadCues)/2		; 4
plcid_GHZ2:		equ (ptr_PLC_GHZ2-ArtLoadCues)/2	; 5
plcid_LZ:		equ (ptr_PLC_LZ-ArtLoadCues)/2		; 6
plcid_LZ2:		equ (ptr_PLC_LZ2-ArtLoadCues)/2		; 7
plcid_CPZ:		equ (ptr_PLC_CPZ-ArtLoadCues)/2		; 8
plcid_CPZ2:		equ (ptr_PLC_CPZ2-ArtLoadCues)/2	; 9
plcid_EHZ:		equ (ptr_PLC_EHZ-ArtLoadCues)/2		; $A
plcid_EHZ2:		equ (ptr_PLC_EHZ2-ArtLoadCues)/2	; $B
plcid_HPZ:		equ (ptr_PLC_HPZ-ArtLoadCues)/2		; $C
plcid_HPZ2:		equ (ptr_PLC_HPZ2-ArtLoadCues)/2	; $D
plcid_HTZ:		equ (ptr_PLC_HTZ-ArtLoadCues)/2		; $E
plcid_HTZ2:		equ (ptr_PLC_HTZ2-ArtLoadCues)/2	; $F
plcid_TitleCard:	equ (ptr_PLC_TitleCard-ArtLoadCues)/2	; $10
plcid_Boss:		equ (ptr_PLC_Boss-ArtLoadCues)/2	; $11
plcid_Signpost:		equ (ptr_PLC_Signpost-ArtLoadCues)/2	; $12
plcid_Warp:		equ (ptr_PLC_Warp-ArtLoadCues)/2	; $13
plcid_SpecialStage:	equ (ptr_PLC_SpecialStage-ArtLoadCues)/2 ; $14
plcid_GHZAnimals:	equ (ptr_PLC_GHZAnimals-ArtLoadCues)/2	; $15
plcid_LZAnimals:	equ (ptr_PLC_LZAnimals-ArtLoadCues)/2	; $16
plcid_CPZAnimals:	equ (ptr_PLC_CPZAnimals-ArtLoadCues)/2	; $17
plcid_EHZAnimals:	equ (ptr_PLC_EHZAnimals-ArtLoadCues)/2	; $18
plcid_HPZAnimals:	equ (ptr_PLC_HPZAnimals-ArtLoadCues)/2	; $19
plcid_HTZAnimals:	equ (ptr_PLC_HTZAnimals-ArtLoadCues)/2	; $1A
plcid_SSResult:		equ (ptr_PLC_SSResult-ArtLoadCues)/2	; $1B
plcid_Ending:		equ (ptr_PLC_Ending-ArtLoadCues)/2	; $1C
plcid_TryAgain:		equ (ptr_PLC_TryAgain-ArtLoadCues)/2	; $1D
plcid_EggmanSBZ2:	equ (ptr_PLC_EggmanSBZ2-ArtLoadCues)/2	; $1E
plcid_FZBoss:		equ (ptr_PLC_FZBoss-ArtLoadCues)/2	; $1F