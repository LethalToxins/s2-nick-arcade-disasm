; Variables (v) and Flags (f)

v_128x128:	equ $FFFF0000   ; 128x128 tile mappings ($8000 bytes)
v_lvllayout:    equ $FFFF8000   ; level layout ($1000 bytes)
v_16x16:        equ $FFFF9000   ; 16x16 tile mappings ($1800 bytes)
v_bgscroll_buffer:	equ $FFFFA800	; background scroll buffer ($200 bytes)
v_ngfx_buffer:	equ $FFFFAA00    ; Nemesis graphics decompression buffer ($200 bytes)
v_spritequeue:	equ $FFFFAC00    ; sprite display queue, in order of priority ($400 bytes)
v_objspace:	equ $FFFFB000    ; object variable space ($40 bytes per object) ($2000 bytes)
v_col1st:       equ $FFFFD000
v_col2nd:       equ $FFFFD600
v_vdp_cmdbuf:   equ $FFFFDC00
v_vdp_cmdbufend:equ $FFFFDCFC
v_spritetablebuffer:    equ $FFFFDD00   ; sprite table ($280 bytes)
v_hscrolltablebuffer:   equ $FFFFE000
v_tracksonic:   equ $FFFFE400
v_tracktails:   equ $FFFFE500
v_recordsonic:  equ $FFFFE600
v_recordtails:  equ $FFFFE700
v_rpl_data:     equ $FFFFE800
v_screenposx:   equ $FFFFEE00
v_screenposy:   equ $FFFFEE04
v_bgscreenposx: equ $FFFFEE08
v_bgscreenposy: equ $FFFFEE0C
v_bg2screenposx:equ $FFFFEE10
v_bg2screenposy:equ $FFFFEE14
v_bg3screenposx:equ $FFFFEE18
v_bg3screenposy:equ $FFFFEE1C
v_screenposx_2p:equ $FFFFEE20
v_screenposy_2p:equ $FFFFEE24
v_bgscreenposx_2p:      equ $FFFFEE28
v_bgscreenposy_2p:      equ $FFFFEE2C
v_bg2screenposx_2p:     equ $FFFFEE30
v_bg2screenposy_2p:     equ $FFFFEE34
v_bg3screenposx_2p:     equ $FFFFEE38
v_bg3screenposy_2p:     equ $FFFFEE3C
v_fg_horiz_rd_flags:    equ $FFFFEE40
v_fg_verti_rd_flags:    equ $FFFFEE41
v_bg1_xblock:   equ $FFFFEE42
v_bg2_xblock:   equ $FFFFEE43
v_bg3_xblock:   equ $FFFFEE44
v_bg4_xblock:   equ $FFFFEE46

v_snddriver_ram:	equ $FFFFF000   ; start of RAM for the sound driver data ($5C0 bytes)
v_gamemode:	equ $FFFFF600	; game mode (00=Sega; 04=Title; 08=Demo; 0C=Level; 10=SS; 14=Cont; 18=End; 1C=Credit; +8C=PreLevel)
v_jpadhold2:	equ $FFFFF602	; joypad input - held, duplicate
v_jpadpress2:	equ $FFFFF603	; joypad input - pressed, duplicate
v_jpadhold1:	equ $FFFFF604	; joypad input - held
v_jpadpress1:	equ $FFFFF605	; joypad input - pressed

v_vdp_buffer1:	equ $FFFFF60C	; VDP instruction buffer (2 bytes)
v_demolength:	equ $FFFFF614	; the length of a demo in frames (2 bytes)
v_scrposy_dup:	equ $FFFFF616	; screen position y (duplicate) (2 bytes)
v_bgscrposy_dup:	equ $FFFFF618	; background screen position y (duplicate) (2 bytes)
v_scrposx_dup:	equ $FFFFF61A	; screen position x (duplicate) (2 bytes)
v_bgscreenposx_dup_unused:	equ $FFFFF61C	; background screen position x (duplicate) (2 bytes)
v_bg3screenposy_dup_unused:	equ $FFFFF61E	; (2 bytes)
v_bg3screenposx_dup_unused:	equ $FFFFF620	; (2 bytes)

v_hbla_hreg:	equ $FFFFF624	; VDP H.interrupt register buffer (8Axx) (2 bytes)
v_hbla_line:	equ $FFFFF625	; screen line where water starts and palette is changed by HBlank
v_pfade_start:	equ $FFFFF626	; palette fading - start position in bytes
v_pfade_size:	equ $FFFFF627	; palette fading - number of colours
v_vbla_routine:	equ $FFFFF62A	; VBlank - routine counter
v_spritecount:	equ $FFFFF62C	; number of sprites on-screen
v_pcyc_num:	equ $FFFFF632	; palette cycling - current reference number (2 bytes)
v_pcyc_time:	equ $FFFFF634	; palette cycling - time until the next change (2 bytes)
v_random:	equ $FFFFF636	; pseudo random number buffer (4 bytes)
f_pause:		equ $FFFFF63A	; flag set to pause the game (2 bytes)
v_vdp_buffer2:	equ $FFFFF640	; VDP instruction buffer (2 bytes)
f_hbla_pal:	equ $FFFFF644	; flag set to change palette during HBlank (0000 = no; 0001 = change) (2 bytes)
v_waterpos1:	equ $FFFFF646	; water height, actual (2 bytes)
v_waterpos2:	equ $FFFFF648	; water height, ignoring sway (2 bytes)
v_waterpos3:	equ $FFFFF64A	; water height, next target (2 bytes)
f_water:		equ $FFFFF64C	; flag set for water
v_wtr_routine:	equ $FFFFF64D	; water event - routine counter
f_wtr_state:	equ $FFFFF64E	; water palette state when water is above/below the screen (00 = partly/all dry; 01 = all underwater)

v_pal_buffer:	equ $FFFFF650	; palette data buffer (used for palette cycling) ($30 bytes)
v_plc_buffer:	equ $FFFFF680	; pattern load cues buffer (maximum $10 PLCs) ($60 bytes)
v_ptrnemcode:	equ $FFFFF6E0	; pointer for nemesis decompression code ($1502 or $150C) (4 bytes)

f_plc_execute:	equ $FFFFF6F8	; flag set for pattern load cue execution (2 bytes)
v_systemstack:	equ $FFFFFE00
v_zone:		equ $FFFFFE10	 ; current zone number
v_act:		equ $FFFFFE11	 ; current act number
f_2player:      equ $FFFFFFE8    ; flag for 2 player mode.

v_startofvariables:	equ $000
v_sndprio:		equ $000	; sound priority (priority of new music/SFX must be higher or equal to this value or it won't play; bit 7 of priority being set prevents this value from changing)
v_main_tempo_timeout:	equ $001	; Counts down to zero; when zero, resets to next value and delays song by 1 frame
v_main_tempo:		equ $002	; Used for music only
f_pausemusic:		equ $003	; flag set to stop music when paused
v_fadeout_counter:	equ $004

v_fadeout_delay:	equ $006
v_communication_byte:	equ $007	; used in Ristar to sync with a boss' attacks; unused here
f_updating_dac:		equ $008	; $80 if updating DAC, $00 otherwise
v_sound_id:		equ $009	; sound or music copied from below
v_soundqueue0:		equ $00A	; sound or music to play
v_soundqueue1:		equ $00B	; special sound to play
v_soundqueue2:		equ $00C	; unused sound to play

f_voice_selector:	equ $00E	; $00 = use music voice pointer; $40 = use special voice pointer; $80 = use track voice pointer

v_voice_ptr:		equ $018	; voice data pointer (4 bytes)

v_special_voice_ptr:	equ $020	; voice data pointer for special SFX ($D0-$DF) (4 bytes)

f_fadein_flag:		equ $024	; Flag for fade in
v_fadein_delay:		equ $025
v_fadein_counter:	equ $026	; Timer for fade in/out
f_1up_playing:		equ $027	; flag indicating 1-up song is playing
v_tempo_mod:		equ $028	; music - tempo modifier
v_speeduptempo:		equ $029	; music - tempo modifier with speed shoes
f_speedup:		equ $02A	; flag indicating whether speed shoes tempo is on ($80) or off ($00)
v_ring_speaker:		equ $02B	; which speaker the "ring" sound is played in (00 = right; 01 = left)
f_push_playing:		equ $02C	; if set, prevents further push sounds from playing

v_music_track_ram:	equ $040	; Start of music RAM

v_music_fmdac_tracks:	equ v_music_track_ram+TrackSz*0
v_music_dac_track:	equ v_music_fmdac_tracks+TrackSz*0
v_music_fm_tracks:	equ v_music_fmdac_tracks+TrackSz*1
v_music_fm1_track:	equ v_music_fm_tracks+TrackSz*0
v_music_fm2_track:	equ v_music_fm_tracks+TrackSz*1
v_music_fm3_track:	equ v_music_fm_tracks+TrackSz*2
v_music_fm4_track:	equ v_music_fm_tracks+TrackSz*3
v_music_fm5_track:	equ v_music_fm_tracks+TrackSz*4
v_music_fm6_track:	equ v_music_fm_tracks+TrackSz*5
v_music_fm_tracks_end:	equ v_music_fm_tracks+TrackSz*6
v_music_fmdac_tracks_end:	equ v_music_fm_tracks_end
v_music_psg_tracks:	equ v_music_fmdac_tracks_end
v_music_psg1_track:	equ v_music_psg_tracks+TrackSz*0
v_music_psg2_track:	equ v_music_psg_tracks+TrackSz*1
v_music_psg3_track:	equ v_music_psg_tracks+TrackSz*2
v_music_psg_tracks_end:	equ v_music_psg_tracks+TrackSz*3
v_music_track_ram_end:	equ v_music_psg_tracks_end

v_sfx_track_ram:	equ v_music_track_ram_end	; Start of SFX RAM, straight after the end of music RAM

v_sfx_fm_tracks:	equ v_sfx_track_ram+TrackSz*0
v_sfx_fm3_track:	equ v_sfx_fm_tracks+TrackSz*0
v_sfx_fm4_track:	equ v_sfx_fm_tracks+TrackSz*1
v_sfx_fm5_track:	equ v_sfx_fm_tracks+TrackSz*2
v_sfx_fm_tracks_end:	equ v_sfx_fm_tracks+TrackSz*3
v_sfx_psg_tracks:	equ v_sfx_fm_tracks_end
v_sfx_psg1_track:	equ v_sfx_psg_tracks+TrackSz*0
v_sfx_psg2_track:	equ v_sfx_psg_tracks+TrackSz*1
v_sfx_psg3_track:	equ v_sfx_psg_tracks+TrackSz*2
v_sfx_psg_tracks_end:	equ v_sfx_psg_tracks+TrackSz*3
v_sfx_track_ram_end:	equ v_sfx_psg_tracks_end

v_spcsfx_track_ram:	equ v_sfx_track_ram_end	; Start of special SFX RAM, straight after the end of SFX RAM

v_spcsfx_fm4_track:	equ v_spcsfx_track_ram+TrackSz*0
v_spcsfx_psg3_track:	equ v_spcsfx_track_ram+TrackSz*1
v_spcsfx_track_ram_end:	equ v_spcsfx_track_ram+TrackSz*2

v_1up_ram_copy:		equ v_spcsfx_track_ram_end