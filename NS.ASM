lorom

!BRAND = $7EF500

;Note: Comments are lined up nicely on NP++, but all over the place on GitHub!
;OVERWRITE BLOCK ---------------------------------------------------------------------------

org $0DB81C								;EXCEPTION FOR SPRITE #$03 IN INITIALIZATION CODE

	JML SL_INIT							;overwriting PHY : PHDB : PHPB: PLDB

RT_INIT:

	PHB : PHK : PLB						;overwriting LDY $0E20, X; 

org $068661 							;LOCATION TO JUMP FOR SPRITE ROUTINES 1

dw $8873								;this alters the sprite's jump during sprite routines 1
										;causing it to jump to an RTS, giving us a clean start	

org $069289								;LOCATION TO JUMP FOR SPRITE ROUTINES 2

dw $946E								;sprite #$03 goes to 'new sprites' hook for sprite routines 2

org $06946E								;HOOKING TO OUR NEW CODE FROM SPRITE ROUTINES 2

	JSL SL_HOOK							;NEW SPRITES HOOK INSTEAD OF 'RAVEN' CODE
										;(this is accounted for later. If the sprite really
										;is a raven, we'll just JML back to the raven's code)

org $1D804F								;FREEING UP SOME SPACE IN BANK 1D	

										;overwritten code
										;---------------------
										;LDA $0C04, X		3
										;STA $0D10, Y		3
										;LDA $0C18, X		3
										;STA $0D30, Y		3
										;LDA $0BFA, X		3
										;STA $0D00, Y		3
										;LDA $0C0E, X		3
										;STA $0D20, Y		3
										;LDA #$06			2
										;STA $0DD0, Y		3
										;LDA #$1F			2
										;STA $0DF0, Y		3
										;LDA $0C2C, X		3
										;STA $0D50, Y		3
										;LDA $0C22, X		3
										;STA $0D40, Y		3
										;LDA $EE			2
										;STA $0F20, Y		3
										;PHX				1
										;TYX				1
										;----------------------
										;			53 bytes freed

	JML SL_FREEBANK_1D 					;4 (overwritten code is now in padding)	
	
										;PART OF 'RECOIL HANDLER' (NS3)

SL_NS3_HOOK:
{
	PHB									;1 byte
	PHK									;1
	PLB									;1

	JSR SR_NS3_HOOK2					;3			

	PLB									;1 (return to here = cancel rest of routines)

	RTL									;1								
}

SR_NS3_HOOK2:
{
	JSR $E8C5 ;RECOIL HANDLER		;3	
	
	PLA								;1 (return to here = continue routines)				
	PLA								;1
	PLB								;1
	PLA								;1				
	PLA								;1				
	PLA								;1	

	JML RT_NS3_CONTINUE				;4
}

;(FREE SPACE LEFT OVER)

	NOP #$1C						;28 bytes remaining			

RT_FREEBANK_1D:						;NOW WE'RE BACK ON TRACK IN BANK 1D

org $06EDA0							;EXCEPTION FOR SPRITE #$03 IN CODE FOR DEALING DAMAGE TO SPRITE

	JML SL_DAMAGES					;REP #$20 : ASL A : ASL A

RT_DAMAGES:

org $06EDC5							;(ABOVE, CONTINUED)

RT_DAMAGES_NEWSPRITE:

org $01B62C							;SPRITE PALETTES BY ROOMS

	JSL SL_SPBR						;DEFINING CUSTOM PALETTES!

	NOP #$11

;PADDING BLOCK A (BANK $21) ---------------------------------------------------------------------------

org $218000							;BEGINNING OF PADDING BLOCK A

									;EXCEPTION FOR SPRITE #$03 IN INITIALIZATION CODE

SL_INIT:
{
	PHY
	LDY $0E20, X
	CPY #$03

	BEQ BR_INIT_NEWSPRITE
		
	JML RT_INIT

BR_INIT_NEWSPRITE:

	JSR SR_FINDBRAND
	
	STA !BRAND, X

	XBA
	LDA #$00
	XBA	
	REP #$30
	ASL
	ASL
	ASL
	ASL
	TXY
	TAX
	SEP #$20
	LDA TB_INITVAR+0, X	
	STA $0E40, Y	
	LDA TB_INITVAR+1, X 
	STA $0E50, Y
	LDA TB_INITVAR+2, X
	STA $0F60, Y 			
	LDA TB_INITVAR+3, X
	STA $0BE0, Y
	LDA TB_INITVAR+4, X
	STA $0CAA, Y
	LDA TB_INITVAR+5, X
	STA $0CD2, Y
	LDA TB_INITVAR+6, X
	STA $0B6B, Y
	LDA TB_INITVAR+7, X
	STA $0E60, Y
	AND #$0F
	STA $0F50, Y
	TYX
	SEP #$10
	LDA $040A
	LDY $1B; Are we indoors?

	BEQ BR_INIT_OUTDOORS2

	LDA $048E							;If indoors, instead load the room number. (in this case, the lower byte)

BR_INIT_OUTDOORS2: 

	STA $0C9A, X						;And store that index here.
	PLY	
	
	RTL
}

										;RETURNS THE "BRAND" (I.E. NEW SPRITE TYPE) OF THE SPRITE

SR_FINDBRAND:
{
	LDY $1B								;Are we indoors?

	BEQ BR_FINDBRAND_OUTDOORS
	
	LDA $048F							; A = ???????? 0000000R 	
	XBA									; A = 0000000R ????????	
	LDA $048E							; A = 0000000R rrrrrrrr	
	REP #$30							; A = 0000000R rrrrrrrr   
	ASL									; A = 000000Rr rrrrrrr0   
	ASL									; A = 00000Rrr rrrrrr00   
	ASL									; A = 0000Rrrr rrrrr000   						
	ASL									; A = 000Rrrrr rrrr0000   	r = low byte of room #		
	STX $00
	STZ $01
	CLC
	ADC $00
	PHX
	TAX									; A = 000Rrrrr rrrrSSSS	R = high bit of room #
	SEP #$20
	LDA TB_BRANDS_DUNGEONS, X			; X = 000Rrrrr rrrrSSSS	S = sprite slot
	PLX
	SEP #$10
	
	RTS

BR_FINDBRAND_OUTDOORS: 

	LDA $040A							; A = ???????? AAAAAAAA 	
	XBA									; A = AAAAAAAA ????????	
	TXA									; A = AAAAAAAA 0000SSSS
	ASL									; A = AAAAAAAA 000SSSS0
	ASL									; A = AAAAAAAA 00SSSS00					
	ASL									; A = AAAAAAAA 0SSSS000
	ASL									; A = AAAAAAAA SSSS0000
	REP #$30							; A = AAAAAAAA SSSS0000
	LSR									; A = 0AAAAAAA ASSSS000
	LSR									; A = 00AAAAAA AASSSS00
	LSR									; A = 000AAAAA AAASSSS0	A = Overworld Area									
	LSR									; A = 0000AAAA AAAASSSS
	PHX
	TAX									; X = 0000AAAA AAAASSSS	S = sprite #3 subtype
	LDA $7EF3C5	
	AND #$00FF
	CMP #$02

	BCS BR_FINDBRAND_NOTRAIN

	SEP #$20
	LDA TB_BRANDS_RAIN, X
	PLX
	SEP #$10	

	RTS

BR_FINDBRAND_NOTRAIN:

	BNE BR_FINDBRAND_POSTAGAHNIM

	SEP #$20
	LDA TB_BRANDS_PREAGAHNIM, X
	PLX
	SEP #$10

	RTS
	
BR_FINDBRAND_POSTAGAHNIM:	

	SEP #$20
	LDA TB_BRANDS_POSTAGAHNIM, X
	PLX
	SEP #$10

	RTS
}

										;REPLACEMENT FOR CODE OVERWRITTEN IN BANK 1D

SL_FREEBANK_1D:
{
	LDA $0C04, X
	STA $0D10, Y
	LDA $0C18, X
	STA $0D30, Y
	LDA $0BFA, X
	STA $0D00, Y
	LDA $0C0E, X
	STA $0D20, Y
	LDA #$06
	STA $0DD0, Y
	LDA #$1F
	STA $0DF0, Y
	LDA $0C2C, X
	STA $0D50, Y
	LDA $0C22, X
	STA $0D40, Y
	LDA $EE
	STA $0F20, Y
	PHX		
	TYX

	JML RT_FREEBANK_1D
}

										;CUSTOM SPRITE DAMAGES FOR EACH DAMAGE CLASS, BY SPRITE "BRAND" CODE

SL_DAMAGES:
{
	CMP #$03
	
	BEQ BR_DAMAGES_NEWSPRITE

	REP #$20
	ASL
	ASL

	JML RT_DAMAGES

BR_DAMAGES_NEWSPRITE:

	SEP #$10

	JSR SR_FINDBRAND

	ASL
	ASL
	ASL
	ASL
	ORA $0CF2
	PHX
	TAX
	SEP #$20
	LDA TB_DAMAGES, X
	PLX
	SEP #$10

	JML RT_DAMAGES_NEWSPRITE
}

;SPRITE PALETTES BY ROOMS CODE

SL_SPBR:
{
	REP #$20
	LDA $A0  
	ASL 
	CLC  
	ADC $A0	
	TAX
	SEP #$20
	LDA TB_SPBR+0, X 
	STA $0AAC
	LDA TB_SPBR+1, X
	STA $0AAD	
	LDA TB_SPBR+2, X 
	STA $0AAE	

	RTL
}

										;HOOKING INTO 'NEW SPRITES' WITH "RAVEN" ENEMY TYPE

SL_HOOK:
{
	LDA $0E20, X						;IF THIS IS ANYTHING BUT ZERO IT'S A CUSTOM SPRITE
	
	BNE BR_HOOK_NOTRAVEN

	JML $1DDD7B							;OTHERWISE IT'S A LEGIT RAVEN, GO DO OG RAVEN STUFF
	
BR_HOOK_NOTRAVEN:
	
	PHB	
	PHK
	PLB
	
	JSR SR_BLUEBOT		

	PLB

	RTL
}

;'GRAPHICS HANDLER' (NS1)

SR_NS1_GFXHANDLER:						;(M:8bit ; X:16bit)
{
	LDA $0E40, X 						; A = ???????? ???TTTTT
	AND #$1F 							; A = ???????? 000TTTTT 
	PHA									; stack a: 000TTTTT			
	PHY									; stack b: AAAAAAAA AAAAAAAA
	SEP #$10							; (x:8bit)
	TAY									; Y = 000TTTTT
	REP #$20							; (m:16bit)
	LDA #$0008							; A = 00000000 00001000

LP_NS1_ANOTHERTILE:

	DEY									;number of tiles, - 1
	
	BEQ BR_NS1_ENOUGHTILES				;if Y = 0, we're done 

	CLC			
	ADC #$0008							;number of bytes per animation frame is 8 more		
	
	BRA LP_NS1_ANOTHERTILE

BR_NS1_ENOUGHTILES:

	STA $08	
	LDA #$0000	
	LDY $0DC0, X;

LP_NS1_NEXTANIMATION:

	BEQ BR_NS1_GOTANIMATION
	
	CLC
	ADC $08
	DEY
	
	BRA LP_NS1_NEXTANIMATION

BR_NS1_GOTANIMATION:
	
	PHA	
	LDA $0E20, X
	AND #$00FF
	ASL
	REP #$10
	TAY
	PLA	
	STA $08
	PLA
	CLC
	ADC $08
	STA $08
	SEP #$30
	PLA
	STA $06
	STZ $07
	
	JSR SR_NS1a_ONSCREENCHECKS:
										;======================================================================
										; SR_NS1a_ONSCREENCHECKS: IS SPRITE ONSCREEN? / RETURN OAM INFO IF SO
										;======================================================================
										;
										;----INPUT-----
										;M 	:  8 bit
										;X 	:  8 bit
										;--------------
										;X 		= 	Sprite Slot
										;
										;----OUTPUT----
										;M 	:  8 bit
										;X 	:  8 bit
										;--------------
										;CARRY		=	Set if sprite offscreen; Clear if onscreen
										;A 			= 	O/W  
										;X 			= 	Sprite Slot
										;Y			=	#$00
										;WR-0&1		=	Sprite X-coord - Horizontal scroll register
										;WR-2&3		=	Sprite Y-coord - Sprite Altitude - Vert. Scroll reg.
										;WR-4		=	#$00
										;WR-5		=	Mirroring, Priority, Palette, and Tileset.
										;======================================================================
	
	BCC BR_NS1_NOCANCEL

	JSR SR_NS1b_DRAWSHADOW
										;======================================================================
										; SR_NS1b_DRAWSHADOW: IF SHADOW ONSCREEN, DRAW SHADOW TO OAM 
										;======================================================================
										;
										;----INPUT-----
										;M 	:  8 bit
										;X 	:  8 bit
										;--------------
										;X 			= 	Sprite Slot
										;Y			=	If sprite is offscreen vertically = 1
										;				If sprite is onscreen vertically  = 3
										;WR-0&1		=	Sprite X-coord - Horizontal scroll register
										;WR-2&3		=	Sprite Y-coord - Sprite Altitude - Vert. Scroll reg.
										;WR-4		=	#$00
										;WR-5		=	Mirroring, Priority, Palette, and Tileset.
										;
										;----OUTPUT----
										;M 	:  8 bit
										;X 	:  8 bit
										;--------------
										;N/A
										;
										;======================================================================

	RTS

BR_NS1_NOCANCEL:
	
	STZ $0CFE
	STZ $0CFF	
	LDA $0DD0, X
	CMP #$0A	

	BNE BR_NS1_NOTPICKEDUP
	
	LDA $7FFA2C, X

BR_NS1_NOTPICKEDUP:

	CMP #$0B	
	
	BNE BR_NS1_NOTFROZEN
	
	LDA $7FFA3C
	STA $0CFE
	
BR_NS1_NOTFROZEN:

	PHX
	REP #$30
	LDY #$0000
	LDX $0090

LP_NS1_NEXTTILE:

	LDA ($08), Y 						;Y:00 {FC FF} ie. A:FFFC = 4 <
	CLC
	ADC $00
	STA $0000, X						;x coord on screen
	AND #$0100
	STA $0C
	INY
	INY
	LDA ($08), Y 						;Y:02 {08 00} ie. A:0008 = 8 v
	CLC
	ADC $02
	STA $0001, X						;y coord on screen
	CLC
	ADC #$0010
	CMP #$0100

	BCC BR_NS1_UNKNOWN

	LDA #$00F0
	STA $0001, X

BR_NS1_UNKNOWN:

	INY
	INY
	LDA $0CFE		
	CMP #$0001
	LDA ($08), Y						;Y:04 {5E 04} ie. A:045E
	EOR $04

	BCC BR_NS1_NOTFROZEN2

	AND #$F1FF
	ORA #$0400

BR_NS1_NOTFROZEN2:

	STA $0002, X						;character number to use and palette
	PHX
	TXA
	SEC
	SBC #$0800
	LSR A
	LSR A
	TAX
	SEP #$20
	INY
	INY
	INY
	LDA ($08), Y						;Y:07 {00} 
	ORA $0D
	STA $0A20, X						;bit 8 of x coord
	PLX
	REP #$20
	INY
	INX
	INX
	INX
	INX
	DEC $06

	BNE LP_NS1_NEXTTILE

	SEP #$30
	PLX

	JSR SR_NS1b_DRAWSHADOW
										;======================================================================
										; SR_NS1b_DRAWSHADOW: IF SHADOW ONSCREEN, DRAW SHADOW TO OAM 
										;======================================================================
										;
										;----INPUT-----
										;M 	:  8 bit
										;X 	:  8 bit
										;--------------
										;X 			= 	Sprite Slot
										;Y			=	If sprite is offscreen vertically = 1
										;				If sprite is onscreen vertically  = 3
										;WR-0&1		=	Sprite X-coord - Horizontal scroll register
										;WR-2&3		=	Sprite Y-coord - Sprite Altitude - Vert. Scroll reg.
										;WR-4		=	#$00
										;WR-5		=	Mirroring, Priority, Palette, and Tileset.
										;
										;----OUTPUT----
										;M 	:  8 bit
										;X 	:  8 bit
										;--------------
										;N/A
										;
										;======================================================================

	RTS
}

										;======================================================================
										; SR_NS1a_ONSCREENCHECKS: IS SPRITE ONSCREEN? / RETURN OAM INFO IF SO
										;======================================================================
										;
										;----INPUT-----
										;M 	:  8 bit
										;X 	:  8 bit
										;--------------
										;X 		= 	Sprite Slot
										;
										;----OUTPUT----
										;M 	:  8 bit
										;X 	:  8 bit
										;--------------
										;CARRY		=	Set if sprite offscreen; Clear if onscreen
										;A 			= 	O/W  
										;X 			= 	Sprite Slot
										;Y			=	#$00
										;WR-0&1		=	Sprite X-coord - Horizontal scroll register
										;WR-2&3		=	Sprite Y-coord - Sprite Altitude - Vert. Scroll reg.
										;WR-4		=	#$00
										;WR-5		=	Mirroring, Priority, Palette, and Tileset.
										;======================================================================
SR_NS1a_ONSCREENCHECKS:
{
	STZ $0F00, X						;//Make sure sprites are moving.
	REP #$20							;(M:16bit)
	LDA $0FD8;
	SEC;
	SBC $E2;
	STA $00;
	CLC;
	ADC #$0040							;//The X coordinate for the "camera"
	CMP #$0170							;is sprite offscreen horizontally?
	SEP #$20							;(M:8bit)

	BCS BR_NS1a_OFFHORIZ				;if so, branch to deal with it
										;Else continue, it might be onscreen.

	LDA $0F70, X						;//Altitude
	STA $04								;//Temp store at $04
	STZ $05;
	REP #$20;
	LDA $0FDA							;//Some sort of generalize Y coordinate
	SEC;
	SBC $E8								;//Subtract the Y coordinate of the camera
	PHA;
	SEC;
	SBC $04								;//Offset by altitude
	STA $02								;//Temp store at $02
	PLA									;//Grab the non height adjusted value.
	CLC;
	ADC #$0040;
	CMP #$0170							;is sprite offscreen vertically?
	SEP #$20							;(M:8bit)

	BCS BR_NS1a_OFFVERT					;if not, branch, it's offscreen
										;Else continue, it's onscreen

	CLC									;signal that the sprite is onscreen 

BR_NS1a_FINISH:

	LDA $0F50, X						;Mirroring, Palette, and Tileset.  (MMV? PPPT)
	EOR $0B89, X						;Swap any bits present in B89, X? 
	STA $05; 
	STZ $04;
	LDA $00								;Load sprite (X-coord - horizontal scroll reg.)
	STA $0FA8;
	LDA $02								;Load sprite Y-coord -(Altitude?) - vscroll reg
	STA $0FA9;
	LDY #$00							;Prep Y as an OAM table offset...
	
	RTS;

BR_NS1a_OFFHORIZ:

	REP #$20;
	LDA $0FDA;
	SEC;
	SBC $E8;
	SEC;
	SBC $04;
	STA $02;
	SEP #$20;

BR_NS1a_OFFVERT:

	INC $0F00, X						;pause the sprite
	LDA $0CAA, X						;bit 7 set: can move even when paused with [$0FF0, X] 

	BMI BR_NS1a_JUSTLEAVE				;if it doesn't pause, just leave it alone
										;Else: deal with it, marking if it should respawn

	LDA $0CAA, X						;Load bit six of CAA, X
	AND #$40							;That tells whether to kill the sprite if it
										;goes offscreen in a dungeon (projectiles)
	
	BNE BR_NS1a_GOAWAY					;If bit 6 is set and we're in a dungeon,
										;this routine just kills the sprite if it goes 				
										;offscreen.

	;ELSE								;If bit six is clear, continue on...

	LDA $1B								;Are we in a dungeon? zero = no, nonzero = yes
	
	BNE BR_NS1a_JUSTLEAVE				;In dungeons, sprites don't reset to their 				
										;original spawning positions when they go 				
										;offscreen.  Just RTL and leave.
	
	;ELSE								;If we're not in a dungeon, continue on...

BR_NS1a_GOAWAY:

	STZ $0DD0, X						;Make the sprite go away.
	
	TXA									;Double Sprite slot and transfer to Y as an 
	ASL A								;offset to be used in $0BC0, Y. Each sprite has
	TAY									;a word long value in this table.
	
	REP #$20							;(M:16bit)
	
	LDA $0BC0, Y						;Check the sprite's spawning table offset.
	STA $00								;Get lowest three bytes in WR-0
	CMP #$FFFF							;If sprite was dead and not just offscreen, SEC

	PHP									;Transfer carry status to stack.

	LSR A								;Drop those lowest three bits.
	LSR A			
	LSR A								;Bits 10 - 3 make a byte-size value. 
		
	CLC									;The spawning table is at 7FEF80, so we need to 
	ADC #$EF80							;add in that offset.
	
	STA $01								;Store that part of the address to WR-1&2

	PLP									;Pull that old carry status back. (If sprite 				
										;was dead and not just offscreen, SEC)

	SEP #$20							;(M:8bit)
	
	BCS BR_NS1a_SPRITEDEAD				;If sprite was dead and not just offscreen, we 				
										;don't reset its bit in the spawning table. 				
										;(i.e. if it's dead, don't allow it to respawn)

	;ELSE								;If sprite was just offscreen, and not dead, we
										;reset its bit in the spawning table.
										;(i.e. if it's not dead, allow it to respawn)
										;REMEMBER, SPAWNING TABLE ONLY APPLIES OUTDOORS

	LDA #$7F							;we're gonna use the spawning table, so
	STA $03								;complete the address in WR-1&2 by writing
										;7F to WR-3.  (Now it's 7FEF80 + Spawning table 				
										;offset from BC0, Y)

	PHX									;Store sprite slot to stack.
	
	LDA $00								;Back to those three bits in WR-0. They have a
	AND #$07							;value from 0 - 7, indicating a bit to clear in
	TAX									;the spawning table to let the sprite respawn.
	
	LDA [$01]							;$09F24B, X determines what bit to clear.  If X
	AND $09F24B, X						;is zero, bit 7 is cleared. 1 clears bit 6, and 
	STA [$01]							;so on. [$01] is the byte in the spawning table
										;we're dealing with.
	
	PLX									;Pull sprite slot back off stack.

BR_NS1a_SPRITEDEAD:

	LDA $1B								;Are we in a dungeon? zero = no, nonzero = yes
	
	BNE BR_NS1a_INDUNGEON				;If we're in a dungeon, just write FF to the
										;table at BC0, signifying that the sprite is 				
										;dead.

	;ELSE								;If we're outdoors, overwrite the spawning 				
										;table offset in the BC0 table, signifying that
										;the sprite is dead or offscreen.

	TXA									;Double the sprite slot again.
	ASL A			
	TAY									;Transfer it to Y to be an offset below.
	
	LDA #$FF									;Overwrite the spawning table offset for	
	STA $0BC0, Y								;the sprite, signifying that the sprite
	STA $0BC1, Y								;is dead.
	
	BRA BR_NS1a_JUSTLEAVE

BR_NS1a_INDUNGEON:

	LDA #$FF									;Write FF to the table at BC0, signifying that
	STA $0BC0, X								;the sprite is dead.
	
BR_NS1a_JUSTLEAVE:

	SEC											;signal that the sprite is offscreen 
	
	LDA $0F50, X								;Mirroring, Palette, and Tileset.  (MMV? PPPT)
	EOR $0B89, X								;Swap any bits present in B89, X? 
	STA $05; 
	STZ $04;
	LDA $00										;Load sprite (X-coord - horizontal scroll reg.)
	STA $0FA8;
	LDA $02										;Load sprite Y-coord -(Altitude?) - vscroll reg
	STA $0FA9;
	LDY #$00									;Prep Y as an OAM table offset...
	
	RTS;
} 

												;======================================================================
												; SR_NS1b_DRAWSHADOW: IF SHADOW ONSCREEN, DRAW SHADOW TO OAM 
												;======================================================================
												;
												;----INPUT-----
												;M 	:  8 bit
												;X 	:  8 bit
												;--------------
												;X 		= 	Sprite Slot
												;Y		=	If sprite is offscreen vertically = 1
												;			If sprite is onscreen vertically  = 3
												;WR-0&1	=	Sprite X-coord - Horizontal scroll register
												;WR-2&3	=	Sprite Y-coord - Sprite Altitude - Vert. Scroll reg.
												;WR-4		=	#$00
												;WR-5		=	Mirroring, Priority, Palette, and Tileset.
												;
												;----OUTPUT----
												;M 	:  8 bit
												;X 	:  8 bit
												;--------------
												;	N/A
												;
												;======================================================================

SR_NS1b_DRAWSHADOW:
{
	LDA #$0A; 
	CLC;
	ADC $0D00, X								;Low byte of sprite's Y-coord
	STA $02										;Store low byte of sprite's Y-coord + #$02
	LDA $0D20, X								;High byte of sprite's y-coord
	ADC #$00;									;add carry
	STA $03										;Store high byte + carry
	
	LDA $0F00, X								;is SPRITE PAUSED?
	
	BNE BR_NS1b_ALPHA							;BRANCH IF SPRITES ARE PAUSED

	LDA $0DD0, X								;CHECK SPRITE STATE
	CMP #$0A									;HAS LINK PICKED IT UP?
	
	BNE BR_NS1b_BETA							;IF NOT, BRANCH BETA

	LDA $7FFA1C, X								;Look up special effect when sprite thrown?
	CMP #$03									;Splash when thrown??
	
	BEQ BR_NS1b_ALPHA							;If it WILL splash when thrown?? just RTS

BR_NS1b_BETA:

	REP #$20;									;M:16bit

	LDA $02;									;Load the lower byte of the sprite's Y-coord-
												;altitude-v-scrollregister
	SEC;
	SBC $E8;									;Subtract vertical scroll register, AGAIN?
	STA $02;									;Replace that in $02
	CLC;
	ADC #$0010;									;Add #$0010 to it
	CMP #$0100;									;basically, is it onscreen vertically?

	SEP #$20;									;M:8bit

	BCS BR_NS1b_GAMMA;							;If it was offscreen vertically branch 

	LDA $0E40, X;								;Load... something	
	AND #$1F;									;And with 0001 1111
	ASL A			
	ASL A										;Times 4
	TAY											;Store that to Y as an offset
	
	LDA $00;									;What's in $00 right now...?
	STA ($90), Y;
	
	LDA $0E60, X;			
	AND #$20;									;Shadow size
	
	BEQ BR_NS1b_DELTA;							;BR_NS1b_DELTA if Bit 5 of $0E60, x is clear 				
												;(Big shadow)

	INY											;increment Y
	
	LDA $02										;Load the lower byte of the sprite's Y-coord - 				
												;Vertical scroll register
	
	INC;										;add 1

	STA ($90), Y								;Store Sprite GFX Y-position to OAM data table
	

	INY;
	LDA #$38									;Store #$38 to Sprite GFX THIS IS THE SHADOW!
	STA ($90), Y;
	
	LDA $05;									;keep priority bits, but make it all shadow colored, 				
	AND #$30;									;And 0011 0000
	ORA #$08;									;OR  0000 1000
												;-------------
												;    00XX 1000?
				
	INY;
	STA ($90), Y								;Store that to the next byte in memory
	
	TYA											;Tranfer Y to a
	LSR A;			
	LSR A										;Divide by 4
	TAY											;Transfer A back to y to be an offset
	
	LDA $01;									;What's in $01 right now?
	AND #$01;									;Only care about bit 0
	STA ($92), Y								;Store the state of bit zero to
	
BR_NS1b_ALPHA:

	RTS;

BR_NS1b_DELTA: 									;We're calling for the big shadow

	LDA $02;
	INY;
	STA ($90), Y;
	
	LDA #$6C;
	INY;
	STA ($90), Y;								;It's the shadow
	
	LDA $05;
	AND #$30;
	ORA #$08;
	INY;
	STA ($90), Y;
	
	TYA;
	LSR A;
	LSR A;
	TAY;
	
	LDA $01;
	AND #$01;
	ORA #$02;
	STA ($92), Y								;determines 8x8 or 16x16 size

BR_NS1b_GAMMA:
	
	RTS;
}

												;'ROUTINE TO CHECK IF THE SPRITE SHOULD MOVE' (NS2)

SR_NS2_MOVECHECK:
{
	LDA $0DD0, X 		
	CMP #$09									;is the sprite alive?

	BNE BR_NS2_CANCEL							;No, its dead/something else.

	LDA $0FC1;

	BNE BR_NS2_CANCEL

	LDA $11										;Are we in a mode other than normal? (Such as the item screen)

	BNE BR_NS2_CANCEL							;If so, then branch.

	LDA $0CAA, X

	BMI BR_NS2_CONTINUE

	LDA $0F00, X

	BEQ BR_NS2_CONTINUE

BR_NS2_CANCEL:

	PLA			
	PLA											;cancel rest of sprite routines on this pass

BR_NS2_CONTINUE:

	RTS
}

;'RECOIL HANDLER' (NS3)

SR_NS3_RECOILHANDLER:
{
	JSL SL_NS3_HOOK

	PLA											;only pass through this code if recoil handler
	PLA											;would've normally cancelled rest of routines		

RT_NS3_CONTINUE:								;otherwise, return here, continuing routines

	RTS	
}

												;======================================================================
												; SR_NS4_XYZMOVEMENTHANDLER: MOVE SPRITE ACCORDING TO X Y AND Z VELOCITIES
												;======================================================================
												;
												;----INPUT-----
												;M 	:  8 bit
												;X 	:  8 bit
												;--------------
												;X 		= 	Sprite Slot 
												;
												;----OUTPUT----
												;M 	:  8 bit
												;X 	:  8 bit
												;--------------
												;X		=	Sprite Slot 
												;
												;=======================================================================

SR_NS4_XYZMOVEMENTHANDLER:
{
	LDA $0F80, X;
	ASL A;
	ASL A;
	ASL A;
	ASL A;
	CLC;
	ADC $0F90, X;
	STA $0F90, X;

	LDA $0F80, X;

	PHP;

	LSR A;
	LSR A;
	LSR A;
	LSR A;

	PLP;

	BPL BR_NS4_ZNOFLIP;

	ORA #$F0;

BR_NS4_ZNOFLIP:

	ADC $0F70, X;
	STA $0F70, X;

												;======================================================================
												; SR_NS4_XYMOVEMENTHANDLER: MOVE SPRITE ACCORDING TO X AND Y VELOCITIES
												;======================================================================
												;
												;----INPUT-----
												;M 	:  8 bit
												;X 	:  8 bit
												;--------------
												;X 		= 	Sprite Slot 
												;
												;----OUTPUT----
												;M 	:  8 bit
												;X 	:  8 bit
												;--------------
												;X		=	Sprite Slot 
												;
												;=======================================================================

SR_NS4_XYMOVEMENTHANDLER:

	LDA $0D50, X								;$0D50 is the x component.
	
	BEQ BR_NS4_XNOMOVE							;Does it move?

	ASL A;
	ASL A;
	ASL A;
	ASL A;
	CLC											;If A was positive, A is now zero. If negative, A is now 7.
	ADC $0D70, X;
	STA $0D70, X;
	
	LDA $0D50, X;
	PHP;
	LSR A;
	LSR A;
	LSR A;
	LSR A;
	
	LDY #$00;
	PLP;  
	
	BPL BR_NS4_XNOFLIP							;Is the effect moving right? I.e. positive directions.
	
	ORA #$F0;
	DEY;
	
BR_NS4_XNOFLIP:

	ADC $0D10, X;
	STA $0D10, X;
	
	TYA;
	ADC $0D30, X;
	STA $0D30, X;
	
BR_NS4_XNOMOVE: 

	LDA $0D40, X								;$0D40 is the y component
	
	BEQ BR_NS4_YNOMOVE							;Does it move?

	ASL A;
	ASL A;
	ASL A;
	ASL A;
	CLC											;If A was positive, A is now zero. If negative, A is now 7.
	ADC $0D60, X;
	STA $0D60, X;
	
	LDA $0D40, X;
	PHP;
	LSR A;
	LSR A;
	LSR A;
	LSR A;
	
	LDY #$00;
	PLP; 
	
	BPL BR_NS4_YNOFLIP							;Is the effect moving down? I.e. positive directions.
	
	ORA #$F0;
	DEY;
	
BR_NS4_YNOFLIP:

	ADC $0D00, X;
	STA $0D00, X;
	
	TYA;
	ADC $0D20, X;
	STA $0D20, X;
	
BR_NS4_YNOMOVE: 

	RTS;
}

SR_NS5_MOVEATLINK:
{
JSR SR_NS6_TARGETLINK

LDA $00;
STA $0D40, X									; Y velocity for a sprite.
LDA $01;
STA $0D50, X									; X velocity for a sprite.

RTS;
}

SR_NS6_TARGETLINK:
{
	STA $01
	CMP #$00

	BNE BR_NS6_DUMB

	STZ $00

	RTS

BR_NS6_DUMB:

	PHX
	PHY

	JSR SR_NS8_UPORDOWN

	STY $02										;The difference in the high bytes between the hunter and Link.
	LDA $0E

	BPL BR_NS6_ALPHA;

	EOR #$FF
	INC											;Essentially, multiply by negative one, or in this context, absolute value.

BR_NS6_ALPHA:

	STA $0C										;$0C = |$0E| = |dY|

	JSR SR_NS7_LEFTORRIGHT

	STY $03										;If Link is to the left of the hunter, Y = 1, otherwise, Y = 0.
	LDA $0F										;The difference in the low X coordinate bytes.

	BPL BR_NS6_BETA;

	EOR #$FF;
	INC;

BR_NS6_BETA:

	STA $0D										;$0D = |$0F| = |dX|
	LDY #$00;
	LDA $0D;
	CMP $0C;

	BCS BR_NS6_GAMMA							; If |dX| > |dY|

	INY											;Flag indicating |dY| >= |dX|
	PHA											; |dX| -> Stack.
	LDA $0C		
	STA $0D										; |dY| -> $0D 
	PLA											; |dX| -> A
	STA $0C										; |dX| -> $0C. Either way, the larger value will end up at $0D

BR_NS6_GAMMA:

	STZ $0B;
	STZ $00;

	LDX $01;

BR_NS6_EPSILON:

	LDA $0B;
	CLC;
	ADC $0C;
	CMP $0D;

	BCC BR_NS6_DELTA							;If ($0B + $0C) <= ($0D)

	SBC $0D										;Otherwise, just subtract the smaller value and increment $00.
	INC $00;

BR_NS6_DELTA:

	STA $0B;
	DEX;

	BNE BR_NS6_EPSILON;

	TYA;

	BEQ BR_NS6_ZETA								; If |dX| > |dY|

	LDA $00;
	PHA;
	LDA $01;
	STA $00;
	PLA;
	STA $01;

BR_NS6_ZETA:

	LDA $00;
	LDY $02;

BEQ BR_NS6_THETA;

	EOR #$FF;
	INC;
	STA $00;

BR_NS6_THETA:

	LDA $01;
	LDY $03;

BEQ BR_NS6_IOTA;

	EOR #$FF;
	INC;
	STA $01;

BR_NS6_IOTA:

	PLY;
	PLX;

	RTS;
}

SR_NS7_LEFTORRIGHT:
{
	LDY #$00;
	LDA $22										; // Load the lower byte of Link's X coordinate.
	SEC;
	SBC $0D10, X								; // Subtract the sprite's coordinate.
	STA $0F										; // Store the difference at $0F.
	LDA $23										; // Load the high byte of Link's X coordinate.
	SBC $0D30, X								; // Subtract the sprites's high byte.
	
	BPL BR_NS7_RIGHT							; If Link is to the right of the sprite

	INY											; // If Link is to the left, then increment Y.

BR_NS7_RIGHT:

	RTS
}

SR_NS8_UPORDOWN:
{
	LDY #$00;
	LDA $20										; // The lower byte of Link's Y coordinate.
	CLC;
	ADC #$08									; A = Link's low byte Y coord + 0x08
	PHP;
	CLC;
	ADC $0F70, X								; // The second derivative terms gets added.
	PHP;
	SEC;
	SBC $0D00, X								; // The sprite's Y coordinate.
	STA $0E										; // The difference between the two coordinates.
	LDA $21										; // The higher byte of Link's Y coordinate
	SBC $0D20, X								; // The difference in their higher bytes. 
	PLP;
	ADC #$00									; Offset if Link is crossing a #$100 pixel boundary.
	PLP;
	ADC #$00;
	
	BPL BR_NS8_BELOW							; Link is below the sprite
		
	INY											; Link is above the sprite.

BR_NS8_BELOW:

	RTS;
}

SR_WE_WEAPONvSPRITE:

incsrc SR_WE_WEAPONvSPRITE.ASM
												;======================================================================
												;SR_WE_WEAPONvSPRITE: HANDLE WEAPON VS. SPRITE COLLISION
												;======================================================================
												;If sprite is temporarily invincible, signal no collision.
												;If you're not on the same floor as sprite, signal no collision.
												;If weapon vs. sprite collision is detected, signal it and do this:
												;If Link is using the bug catching net, no damage.
												;If not, set up correct recoil velocities for sprite by attack used.
												;If sprite immune to damage, this routine does nothing more.
												;If sprite hit by sword, find damage/effect class from 1-5 and deal it.
												;If Link is using the hammer and the sprite is frozen, give magic drop.
												;If unfrozen sprite hit by hammer, use damage/effect class 3.
												;If sprite hit by powder, transform to faerie or bot or do nothing.
												;If damage is dealt, play correct sound effect, allow sprite recoil.
												;If damage dealt with Ether or Quake medallions, no sprite recoil.
												;If sprite deflects sword/hammer, no damage, spark, only Link recoils.
												;---SOURCE----
												;$372B4-$373C9 
												;---OUTPUT----
												;CARRY		= Set if collision detected, Clear if not
												;======================================================================

												;ACTUAL CODE FOR NEW SPRITES 

												;BRAND #$00 = "BLUEBOT"

SR_BLUEBOT:
{
	LDA $0DC0, X
	PHA
	LDA $0E00, X
	CMP #$0C

	BCC BR_BLUEBOT_NOTFRAME2

	LDA $0D80, X
	CMP #$01
		
	BNE BR_BLUEBOT_NOTFRAME2
	
	LDA #$02
	STA $0DC0, X

BR_BLUEBOT_NOTFRAME2:

	REP #$10
	LDY #TB_NS1_ANIMATION_BLUEBOT

	JSR SR_NS1_GFXHANDLER						;GRAPHICS HANDLER

	PLA
	STA $0DC0, X	
	
	JSR SR_NS2_MOVECHECK						;CHECK IF SPRITE SHOULD MOVE
	
	JSR SR_NS3_RECOILHANDLER					;RECOIL HANDLER
	
	JSR SR_WE_WEAPONvSPRITE						;WEAPON VS SPRITE HANDLER
	
	JSL $06F121									;LINK VS SPRITE HANDLER
	
	LDA $0D80, X
	
	JSL $008781									;SEE JUMP TABLE BELOW
}

TB_BLUEBOT_AI:

dw #SR_BLUEBOT_AI0								;sit there and wiggle
dw #SR_BLUEBOT_AI1								;move about randomly
dw #SR_BLUEBOT_AI2								;jump and wiggle
dw #SR_BLUEBOT_AI3								;jump and stop animation


SR_BLUEBOT_AI0:									;sit there and wiggle
{
	LDA $0E10, X								;load timer e10
	CMP #$81									;is this a "follower" jump?

	BEQ BR_JUMP									;if so, make the bot jump

	CMP #$00									;okay, is it time to see if we should jump?

	BEQ BR_YESJUMP								;if it's time, DO IT!

	JMP JP_NOJUMP 								;if not time, don't do it

BR_YESJUMP:

	LDA $2137									;   ?
	LDA $213C									;GENERATE
	ADC $1A										; RANDOM
	ADC $0FA1									; NUMBER
	STA $0FA1									;   ?

	AND #$07									;random number from 0 - 8
	
	BNE BR_RESETJUMP							;nonzero, continue normally

	LDY #$00									;otherwise we're making it jump

LP_ALLJUMP:
	
	LDA $0E20, Y								;is this a new sprite?
	CMP #$03
	
	BNE BR_NOTBLUEBOT   						;no, so check the next one

												;WILL NEED TO ADD CHECK FOR SPRITE "BRAND" LATER
												;BUT FOR NOW, THIS'LL WORK FOR TESTING PURPOSES
												;          ------DON'T FORGET!------

	LDA $2137									;   ?
	LDA $213C									;GENERATE
	ADC $1A										; RANDOM
	ADC $0FA1									; NUMBER
	STA $0FA1									;   ?
	
	AND #$1F									;it's a blue bot, so give a number from 0 - $1F
	ADC #$A0									;add $A0,
	STA $0E10, Y								;MAKE OTHER BLUEBOT JUMP AFTER THE FIRST

BR_NOTBLUEBOT:
	
	INY											;next sprite
	CPY #$10									;but are we done?
	BCC LP_ALLJUMP								;if not, continue loop

BR_JUMP:										;yay, make it jump!

	LDA $2137									;   ?
	LDA $213C									;GENERATE
	ADC $1A										; RANDOM
	ADC $0FA1									; NUMBER
	STA $0FA1									;   ?
	
	AND #$07									;random number from 0 - 7
	ADC #$10									;VELOCITIES WILL BE FROM #$10 - $17

	JSR SR_NS5_MOVEATLINK
	
	LDA $2137									;   ?
	LDA $213C									;GENERATE
	ADC $1A										; RANDOM
	ADC $0FA1									; NUMBER
	STA $0FA1									;   ?

	AND #$0F;									;random number from 0 - $F
	ADC #$18;									;add that to $18
	STA $0F80, X								;that's our Z velocity
	LDA #$02									;wiggling while jumping AI is #$02
	STA $0D80, X								;Switch to WIGGLING WHILE JUMPING AI
	
	LDA $2137									;   ?
	LDA $213C									;GENERATE
	ADC $1A										; RANDOM
	ADC $0FA1									; NUMBER
	STA $0FA1									;   ?
	
	AND #$1F									;random number from 0 - $1F
	ADC #$60									;add $60
	STA $0E10, X								;begin delay until next chance to jump
	LDA $0E00, X								;is it time to scrunch in or out?
	
	BNE BR_BLUEBOT_AI0_NOANIMATION1 			;if not, skip this

	LDA $0DC0, X								;otherwise, we'll need to change the animation frame
	EOR #$01
	STA $0DC0, X
	LDA #$04
	STA $0E00, X

BR_BLUEBOT_AI0_NOANIMATION1:

	RTS

BR_RESETJUMP:

	LDA $2137									;   ?
	LDA $213C									;GENERATE
	ADC $1A										; RANDOM
	ADC $0FA1									; NUMBER
	STA $0FA1									;   ?
	
	AND #$1F									;random number from 0 - $1F
	ADC #$60									;add $60
	STA $0E10, X								;begin delay until next chance to jump

JP_NOJUMP:	

	LDA $0E00, X								;is it time to scrunch in or out?	
	
	BNE BR_BLUEBOT_AI0_NOANIMATION2 			;if not, skip this

	LDA $0DC0, X 								;otherwise, we'll need to change the animation frame
	EOR #$01
	STA $0DC0, X
	LDA #$04
	STA $0E00, X

BR_BLUEBOT_AI0_NOANIMATION2:

	LDA $0DF0, X 								;time to stop wiggling and move about the room, if zero
	
	BNE BR_BLUEBOT_AI0_CONTINUE					;nonzero, then skip this

	INC $0D80, X 								;otherwise start making the bot move bout the room
	STZ $0E00, X 								;clear "scrunch" timer, we won't be needing it anymore
	STZ $0DC0, X 								;we'll need to start at animation frame 0
	
	LDA $2137									;   ?
	LDA $213C									;GENERATE
	ADC $1A										; RANDOM
	ADC $0FA1									; NUMBER
	STA $0FA1									;   ?

	AND #$07									;gives us one of 8 directions
	TAY
	LDA TB_RANDOMMOVE1, Y 						;set speed and direction
	STA $0D50, X
	LDA TB_RANDOMMOVE2, Y 						;set speed and direction
	STA $0D40, X
	LDA #$FF									;how long the sprite should move
	STA $0DF0, X

BR_BLUEBOT_AI0_CONTINUE:			
	
	RTS											;we're done, this pass
}

SR_BLUEBOT_AI1: 								;move about randomly
{
	LDA $0E10, X								;load timer e10
	CMP #$81									;is this a "follower" jump?

	BEQ BR_AI1_JUMP								;if so, make the bot jump

	CMP #$00									;okay, is it time for bot to jump?

	BEQ BR_AI1_YESJUMP							;if it's time, bot jumps now

	JMP JP_AI1_NOJUMP 							;if not time, wait

BR_AI1_YESJUMP:

	LDA $2137									;   ?
	LDA $213C									;GENERATE
	ADC $1A										; RANDOM
	ADC $0FA1									; NUMBER
	STA $0FA1									;   ?

	AND #$07									;random number from 0 - 7
	
	BNE BR_AI1_RESETJUMP						;nonzero, continue normally

	LDY #$00									;otherwise we're making it jump

LP_AI1_ALLJUMP:
	
	LDA $0E20, Y								;is this a new sprite?
	CMP #$03
	
	BNE BR_AI1_NOTBLUEBOT   					;no, so check the next one

												;WILL NEED TO ADD CHECK FOR SPRITE "BRAND" LATER
												;BUT FOR NOW, THIS'LL WORK FOR TESTING PURPOSES
												;          ------DON'T FORGET!------

	LDA $2137									;   ?
	LDA $213C									;GENERATE
	ADC $1A										; RANDOM
	ADC $0FA1									; NUMBER
	STA $0FA1									;   ?
	
	AND #$1F									;it's a blue bot, so give a number from 0 - $1F
	ADC #$A0									;add $A0,
	STA $0E10, Y								;MAKE OTHER BLUEBOT JUMP AFTER THE FIRST

BR_AI1_NOTBLUEBOT:
	
	INY											;next sprite
	CPY #$10									;but are we done?
	BCC LP_AI1_ALLJUMP							;if not, continue loop

BR_AI1_JUMP:									;make it jump!

	LDA $2137									;   ?
	LDA $213C									;GENERATE
	ADC $1A										; RANDOM
	ADC $0FA1									; NUMBER
	STA $0FA1									;   ? 
	
	AND #$07									;random number from 0 - 7
	ADC #$10									;VELOCITIES WILL BE FROM #$10 - $17

	JSR SR_NS5_MOVEATLINK
	
	LDA $2137									;   ?
	LDA $213C									;GENERATE
	ADC $1A										; RANDOM
	ADC $0FA1									; NUMBER
	STA $0FA1									;   ? 

	AND #$0F;									;random number from 0 - $F
	ADC #$18;									;add that to $18
	STA $0F80, X								;that's our Z velocity
	LDA #$03									;STIFF WHILE JUMPING AI #
	STA $0D80, X								;Switch to STIFF WHILE JUMPING AI ?
	
	LDA $2137									;   ?
	LDA $213C									;GENERATE
	ADC $1A										; RANDOM
	ADC $0FA1									; NUMBER
	STA $0FA1									;   ?
	
	AND #$1F									;random number from 0 - $1F
	ADC #$60									;add $60
	STA $0E10, X								;begin delay until next chance to jump
	
	RTS

BR_AI1_RESETJUMP:

	LDA $2137									;   ?
	LDA $213C									;GENERATE
	ADC $1A										; RANDOM
	ADC $0FA1									; NUMBER
	STA $0FA1									;   ?
	
	AND #$1F									;random number from 0 - $1F
	ADC #$60									;add $60
	STA $0E10, X								;begin delay until next chance to jump

JP_AI1_NOJUMP:	

	LDA $0E00, X  								;if this is nonzero, it doesn't move

	BNE BR_BLUEBOT_AI1_NOMOVE

		JSR SR_NS4_XYMOVEMENTHANDLER
												;======================================================================
												; SR_NS4_XYMOVEMENTHANDLER: MOVE SPRITE ACCORDING TO X AND Y VELOCITIES
												;======================================================================
												;
												;----INPUT-----
												;M 	:  8 bit
												;X 	:  8 bit
												;--------------
												;X 		= 	Sprite Slot 
												;
												;----OUTPUT----
												;M 	:  8 bit
												;X 	:  8 bit
												;--------------
												;X		=	Sprite Slot 
												;
												;=======================================================================

	LDA #$10 									;how long to pause between movements
	STA $0E00, X 

BR_BLUEBOT_AI1_NOMOVE:

	JSL $06E496									;ENVIRONMENT VS SPRITE HANDLER

	LDA $0E70, X								;was there collision?
	
	BEQ BR_BLUEBOT_AI1_NOREVERSE 				;if not, branch

LDA $0D50, X									; sprite x vel
EOR #$FF
INC												; reverse it
STA $0D50, X									; store it back
LDA $0D40, X									; sprite x vel
EOR #$FF
INC												; reverse it
STA $0D40, X									; store it back

BR_BLUEBOT_AI1_NOREVERSE:

	LDA $0DF0, X 								;is it time to stop moving

	BNE BR_BLUEBOT_AI1_CONTINUE					;if not, branch

	DEC $0D80, X 								;otherwise, start wiggling
	STZ $0E00, X 								;the "movement" timer becomes the wiggle timer
	LDA #$FF									;how long to wiggle
	STA $0DF0, X 

BR_BLUEBOT_AI1_CONTINUE:		

	RTS	;we're done, this pass
}

SR_BLUEBOT_AI2:
{	
	LDA $0E00, X								;is it time to scrunch in or out?
	
	BNE BR_BLUEBOT_AI2_NOANIMATION1 			;if not, skip this

	LDA $0DC0, X								;otherwise, we'll need to change the animation frame
	EOR #$01
	STA $0DC0, X
	LDA #$04
	STA $0E00, X

BR_BLUEBOT_AI2_NOANIMATION1:

SR_BLUEBOT_AI3:

		JSR SR_NS4_XYMOVEMENTHANDLER
												;======================================================================
												; SR_NS4_XYMOVEMENTHANDLER: MOVE SPRITE ACCORDING TO X AND Y VELOCITIES
												;======================================================================
												;
												;----INPUT-----
												;M 	:  8 bit
												;X 	:  8 bit
												;--------------
												;X 		= 	Sprite Slot 
												;
												;----OUTPUT----
												;M 	:  8 bit
												;X 	:  8 bit
												;--------------
												;X		=	Sprite Slot 
												;
												;=======================================================================

	JSL $06E496									;ENVIRONMENT VS SPRITE HANDLER

	LDA $0E70, X								; was there collision?

	BEQ BR_BLUEBOT_AI3_NOCOLLISION				; if not, branch

	STZ $0D50, X
	STZ $0D40, X

BR_BLUEBOT_AI3_NOCOLLISION:

	LDA $0F80, X;
	ASL;
	ASL;
	ASL;
	ASL;
	CLC;
	ADC $0F90, X;
	STA $0F90, X;
	LDA $0F80, X;
	PHP;
	LSR;
	LSR;
	LSR;
	LSR;
	PLP;

	BPL BR_BLUEBOT_AI3_ZVEL;

	ORA #$F0;

BR_BLUEBOT_AI3_ZVEL:

	ADC $0F70, X;
	STA $0F70, X;
	DEC $0F80, X								; decrement Z velocity
	DEC $0F80, X								; decrement Z velocity

	LDA $0F70, X								; what's the sprite's altitude

	BPL BR_BLUEBOT_AI3_INAIR					; is it above the ground?

	STZ $0F70, X								; zero out altitude

	DEC $0D80, X								; we're done jumping
	DEC $0D80, X								; we're done jumping

BR_BLUEBOT_AI3_INAIR: 							;still off the ground, still jumping

	RTS;
}

TB_RANDOMMOVE1:

db $30, $20, $E0, $D0, $20, $E0, $00, $00 

TB_RANDOMMOVE2:

db $00, $20, $20, $00, $E0, $E0, $D0, $30

												;DATA FOR EACH FRAME OF ANIMATION

TB_NS1_ANIMATION_BLUEBOT:

;Animation #$00 ; NORMAL
;--------------

;Tile A
;---------
dw $FFF8 	;x offset
dw $0000 	;y offset
db $00		;tile #
db $00		;vhoopppc
db $00		;(unused, keep it as $00)
db $02		;size toggle

;Tile B
;---------
dw $0008 	;x offset
dw $0000 	;y offset
db $00		;tile #
db $40		;vhoopppc
db $00		;(unused, keep it as $00)
db $02		;size toggle

;Animation #$01 ; SQUEEZED IN
;--------------

;Tile A
;---------
dw $FFF9 	;x offset
dw $0000 	;y offset
db $00		;tile #
db $00		;vhoopppc
db $00		;(unused, keep it as $00)
db $02		;size toggle

;Tile B
;---------
dw $0007 	;x offset
dw $0000 	;y offset
db $00		;tile #
db $40		;vhoopppc
db $00		;(unused, keep it as $00)
db $02		;size toggle

;Animation #$02 ; PUFFED UP
;--------------

;Tile A
;---------
dw $FFF8 	;x offset
dw $0000 	;y offset
db $02		;tile #
db $00		;vhoopppc
db $00		;(unused, keep it as $00)
db $02		;size toggle

;Tile B
;---------
dw $0008 	;x offset
dw $0000 	;y offset
db $02		;tile #
db $40		;vhoopppc
db $00		;(unused, keep it as $00)
db $02		;size toggle

;SPRITE'S INITIAL VARIABLES	 

TB_INITVAR:

;BRAND $00 - "BLUEBOT"
;---------------------------

;INITIAL VALUE FOR [$0E40, X]

db $02	; 0 / 0 / 0 / 00010
	;-----------------------------------
	; 0 - BIT7   = set: deals no damage				
	; 0 - BIT6   = set: dies if it leaves loaded screen
	; 0 - BIT5   = set: doesn't autocorrect when it hits wall
	;02 - BIT4-0 = how many separate gfx tiles make up sprite

;INITIAL VALUE FOR [$0E50, X]

db $10	; 00010000

	;10 - BIT7-0 = initial HP

;INITIAL VALUE FOR [$0F60, X]

db $00	; 0 / 0 / 0 / 00000
	;-----------------------------------
	; 0 - BIT7   = set: unaffected by moving floor / moving water
	; 0 - BIT6   = set: ignored during checks for remaining enemies
	; 0 - BIT5   = LEAVE CLEAR (unknown: horizontal roller only?)
	; 0 - BIT4-0 = size class for sprite vs link/weapon collision

;INITIAL VALUE FOR [$0BE0, X]

db $10	; 0 / 0 / 0 / 1 / 0000
	;-----------------------------------
	; 0 - BIT7   = set: unaffected by holes, moving floors, and conveyor belts
	; 0 - BIT6   = set: walks on / floats over water
	; 0 - BIT5   = set: if projectile, can hit Link's shield
	; 1 - BIT4   = set: if hit, give "special" sword strike sound effect
	; 0 - BIT3-0 = prize pack class

;INITIAL VALUE FOR [$0CAA, X]

db $00	; 0 / 0 / 0 / 0 / 0 / 0 / 0 / 0
	;-----------------------------------
	; 0 - BIT7   = set: can move even when paused with [$0FF0, X] 
	; 0 - BIT6   = set: dies if it goes offscreen in a dungeon
	; 0 - BIT5   = LEAVE CLEAR (unknown: statue objects, no animation?)
	; 0 - BIT4   = LEAVE CLEAR (none were set)
	; 0 - BIT3   = set: can climb stairs (projectiles, walking zoras)
	; 0 - BIT2   = set: deflects sword and hammer, pushes link back
	; 0 - BIT1   = set: deflects hookshot and boomerang, stuck arrows vanish
	; 0 - BIT0   = LEAVE CLEAR (only bosses and giant zora)

;INITIAL VALUE FOR [$0CD2, X]

db $00	; 0 / 0 / 0 / 0 / 0000
	;-----------------------------------
	; 0 - BIT7   = set: "flying" (no collision with environment on recoil)
	; 0 - BIT6   = LEAVE CLEAR (unknown: events/animation?)
	; 0 - BIT5   = LEAVE CLEAR (none were set)
	; 0 - BIT4   = LEAVE CLEAR (bosses, fireball spitter, fairies?)
	; 0 - BIT3-0 = sprite bump damage class

;INITIAL VALUE FOR [$0B6B, X]

db $01	; 0000 / 0 / 0 / 0 / 1
	;-----------------------------------
	; 0 - BIT7-4 = size class for sprite vs environment collision
	; 0 - BIT3   = set: deflects arrows for no harm
	; 0 - BIT2   = LEAVE CLEAR (unknown: ganon, arrow, tutorial soldier, moldorm boss)
	; 0 - BIT1   = set: dies like a boss / boss hurt sound effect
	; 0 - BIT0   = set: can fall in holes

;INITIAL VALUE FOR [$0BE0, X] and [$0BE0, X] (lower nibble)

db $11	; 0 / 0 / 0 / 1 / 000 / 1
	;-----------------------------------
	; 0 - BIT7   = LEAVE CLEAR (unknown: projectile related??)
	; 0 - BIT6   = set: impervious to attack
	; 0 - BIT5   = set: has small shadow
	; 1 - BIT4   = set: has a shadow
	; 0 - BIT3-1 = palette
	; 1 - BIT0   = tileset

;CUSTOM SPRITE DAMAGES FOR EACH DAMAGE CLASS, BY SPRITE "BRAND" (DATA TABLE)

TB_DAMAGES:

;$00-F8	: ACTUAL DAMAGE AMOUNT TO SPRITE HP

;SPECIAL EFFECTS

;$F9		: Make faerie
;$FA		: Make 0-HP blob
;$FB		: Very short stun
;$FC		: Shorter stun
;$FD		: Incinerate
;$FE		: Freeze
;$FF		: Stun

!FAERIE 	= $F9
!BLOB 		= $FA
!STUN3 	= $FB
!STUN2 	= $FC
!BURN 		= $FD
!FREEZE 	= $FE
!STUN1 	= $FF

;BRAND $00 - "BLUEBOT"
;---------------------------

;DAMAGE CLASS $0
;Boomerang (Blue or Red)
;-----------------------

db !BURN

;DAMAGE CLASS $1
;Drawn Level 1 sword,
;Level 1 sword swing/Pegasus charge,
;Drawn Level 2 sword,
;Level 2+ sword light beam,
;Cane of Somaria block,
;Cane of Somaria missile,
;Cane of Byrna force field,
;Bee attack,
;Throw:
;  Purple bush,
;  Normal green bush
;-----------------------

db $02

;DAMAGE CLASS $2
;Level 1 sword spin attack,
;Level 2 sword swing/Pegasus charge,
;Drawn level 3 sword
;-----------------------

db $04

;DAMAGE CLASS $3
;Level 2 sword spin attack,
;Level 3 sword swing/Pegasus charge,
;Drawn Level 4 sword,
;Hammer,
;Throw:
;  Light gray "8" stone, Dark "8" stone,
;  Big gray-edged rock (LW), Big black-edged rock (LW),
;  Gray skull rock, Black skull rock,
;  Big gray-edged rock (DW), Big black-edged rock (DW),
;  Brown pot, Skull pot,
;  Brown sign, Yellow sign,
;  Brownish green bush,
;  Frozen enemy
;-----------------------

db $08

;DAMAGE CLASS $4
;Level 3 sword spin attack,
;Level 4 sword swing/Pegasus charge
;-----------------------

db $10

;DAMAGE CLASS $5
;Level 4 sword spin attack
;-----------------------

db $10

;DAMAGE CLASS $6
;Normal bow + arrow
;-----------------------

db $04

;DAMAGE CLASS $7
;Hookshot
;-----------------------

db $40

;DAMAGE CLASS $8
;Bomb
;-----------------------

db $40

;DAMAGE CLASS $9
;Bow + silver arrow
;-----------------------

db $64

;DAMAGE CLASS $A
;Magic powder
;-----------------------

db $00 

;DAMAGE CLASS $B
;Fire rod
;-----------------------

db !BURN

;DAMAGE CLASS $C
;Ice rod
;-----------------------

db !FREEZE

;DAMAGE CLASS $D
;Bombos medallion
;-----------------------

db !BURN

;DAMAGE CLASS $E
;Ether medallion
;-----------------------

db !FREEZE

;DAMAGE CLASS $F
;Quake medallion
;-----------------------

db $40

;'SPRITE PALETTES BY ROOMS' (DATA TABLE

TB_SPBR:

; - Column "0" can contain values #$00 through #$0F. (16 selectable palettes)
; - Columns "5" and "6" can contain values #$00 through #$17. (24 selectable palettes)
; - Column "0" corresponds to the "Enemies 2" palettes in HM.
; - Columns "5" and "6" both correspond to the "Enemies 1" palettes in HM.
; - The numbers already in the table are correct for the rooms in a fresh Zelda 3 ROM.
;
;	  |-0-||-5-||-6-| <-- Sprite Palette Slot (SP)
;-------------------------------.-----------------------  
	db $08, $13, $0D	;ROOM :	0
	db $00, $03, $01	;ROOM :	1
	db $00, $03, $0A	;ROOM :	2
	db $00, $03, $0A	;ROOM :	3
	db $05, $07, $0B	;ROOM :	4
	db $00, $0F, $14	;ROOM :	5
	db $00, $0F, $14	;ROOM :	6
	db $05, $08, $14	;ROOM :	7
	db $00, $03, $0A	;ROOM :	8
	db $05, $0A, $07	;ROOM :	9
	db $05, $0A, $07	;ROOM :	10
	db $05, $0A, $07	;ROOM :	11
	db $05, $05, $0B	;ROOM :	12
	db $02, $00, $07	;ROOM :	13
	db $00, $04, $0C	;ROOM :	14
	db $00, $04, $0C	;ROOM :	15
	db $00, $04, $0C	;ROOM :	16
	db $00, $03, $01	;ROOM :	17
	db $00, $03, $0A	;ROOM :	18
	db $05, $07, $0B	;ROOM :	19
	db $05, $07, $0B	;ROOM :	20
	db $05, $07, $0B	;ROOM :	21
	db $00, $0F, $14	;ROOM :	22
	db $05, $08, $14	;ROOM :	23
	db $00, $03, $0A	;ROOM :	24
	db $05, $0A, $07	;ROOM :	25
	db $05, $0A, $07	;ROOM :	26
	db $05, $0A, $07	;ROOM :	27
	db $02, $00, $07	;ROOM :	28
	db $02, $00, $07	;ROOM :	29
	db $00, $04, $0C	;ROOM :	30
	db $00, $04, $0C	;ROOM :	31
	db $00, $00, $00	;ROOM :	32
	db $00, $03, $01	;ROOM :	33
	db $00, $03, $01	;ROOM :	34
	db $05, $07, $0B	;ROOM :	35
	db $05, $07, $0B	;ROOM :	36
	db $00, $0F, $0C	;ROOM :	37
	db $00, $0F, $0C	;ROOM :	38
	db $05, $08, $14	;ROOM :	39
	db $00, $0F, $0C	;ROOM :	40
	db $00, $02, $0C	;ROOM :	41
	db $05, $0A, $07	;ROOM :	42
	db $05, $0A, $07	;ROOM :	43
	db $00, $03, $0A	;ROOM :	44
	db $00, $04, $0C	;ROOM :	45
	db $00, $04, $0C	;ROOM :	46
	db $00, $03, $0A	;ROOM :	47
	db $00, $00, $00	;ROOM :	48
	db $05, $08, $14	;ROOM :	49
	db $00, $03, $01	;ROOM :	50
	db $02, $02, $07	;ROOM :	51
	db $00, $0F, $0C	;ROOM :	52
	db $00, $0F, $0C	;ROOM :	53
	db $00, $0F, $0C	;ROOM :	54
	db $00, $0F, $0C	;ROOM :	55
	db $00, $0F, $0C	;ROOM :	56
	db $05, $05, $0B	;ROOM :	57
	db $05, $0A, $07	;ROOM :	58
	db $05, $0A, $07	;ROOM :	59
	db $00, $03, $0A	;ROOM :	60
	db $05, $08, $14	;ROOM :	61
	db $00, $04, $0C	;ROOM :	62
	db $00, $04, $0C	;ROOM :	63
	db $00, $03, $01	;ROOM :	64
	db $00, $03, $01	;ROOM :	65
	db $00, $03, $01	;ROOM :	66
	db $02, $02, $07	;ROOM :	67
	db $00, $14, $0C	;ROOM :	68
	db $00, $14, $0C	;ROOM :	69
	db $00, $0F, $0C	;ROOM :	70
	db $05, $05, $0B	;ROOM :	71
	db $05, $05, $0B	;ROOM :	72
	db $05, $05, $0B	;ROOM :	73
	db $05, $0A, $07	;ROOM :	74
	db $05, $0A, $07	;ROOM :	75
	db $05, $08, $14	;ROOM :	76
	db $05, $08, $14	;ROOM :	77
	db $00, $04, $0C	;ROOM :	78
	db $00, $04, $0C	;ROOM :	79
	db $00, $03, $01	;ROOM :	80
	db $00, $03, $01	;ROOM :	81
	db $00, $03, $01	;ROOM :	82
	db $02, $02, $07	;ROOM :	83
	db $00, $0F, $0C	;ROOM :	84
	db $00, $03, $01	;ROOM :	85
	db $05, $05, $0B	;ROOM :	86
	db $05, $05, $0B	;ROOM :	87
	db $05, $05, $0B	;ROOM :	88
	db $05, $05, $0B	;ROOM :	89
	db $00, $10, $0C	;ROOM :	90
	db $02, $00, $07	;ROOM :	91
	db $02, $00, $07	;ROOM :	92
	db $02, $02, $07	;ROOM :	93
	db $00, $04, $0C	;ROOM :	94
	db $00, $04, $0C	;ROOM :	95
	db $00, $03, $01	;ROOM :	96
	db $00, $03, $01	;ROOM :	97
	db $00, $03, $01	;ROOM :	98
	db $0D, $00, $07	;ROOM :	99
	db $00, $04, $04	;ROOM :	100
	db $00, $04, $04	;ROOM :	101
	db $00, $0F, $0C	;ROOM :	102
	db $05, $05, $0B	;ROOM :	103
	db $05, $05, $0B	;ROOM :	104
	db $05, $0A, $07	;ROOM :	105
	db $05, $0A, $07	;ROOM :	106
	db $02, $00, $07	;ROOM :	107
	db $02, $02, $07	;ROOM :	108
	db $02, $02, $07	;ROOM :	109
	db $00, $04, $0C	;ROOM :	110
	db $00, $03, $01	;ROOM :	111
	db $00, $03, $01	;ROOM :	112
	db $00, $03, $01	;ROOM :	113
	db $00, $03, $01	;ROOM :	114
	db $02, $00, $07	;ROOM :	115
	db $02, $00, $07	;ROOM :	116
	db $02, $00, $07	;ROOM :	117
	db $00, $0F, $0C	;ROOM :	118
	db $05, $08, $14	;ROOM :	119
	db $05, $05, $0B	;ROOM :	120
	db $05, $05, $0B	;ROOM :	121
	db $05, $05, $0B	;ROOM :	122
	db $05, $05, $0B	;ROOM :	123
	db $05, $05, $0B	;ROOM :	124
	db $05, $05, $0B	;ROOM :	125
	db $00, $04, $0C	;ROOM :	126
	db $00, $04, $0C	;ROOM :	127
	db $00, $03, $01	;ROOM :	128
	db $00, $03, $01	;ROOM :	129
	db $00, $03, $01	;ROOM :	130
	db $02, $00, $07	;ROOM :	131
	db $02, $00, $07	;ROOM :	132
	db $02, $00, $07	;ROOM :	133
	db $05, $08, $14	;ROOM :	134
	db $05, $08, $14	;ROOM :	135
	db $00, $06, $07	;ROOM :	136
	db $00, $06, $07	;ROOM :	137
	db $05, $05, $0B	;ROOM :	138
	db $05, $05, $0B	;ROOM :	139
	db $05, $05, $0B	;ROOM :	140
	db $05, $05, $0B	;ROOM :	141
	db $00, $04, $0C	;ROOM :	142
	db $00, $07, $0F	;ROOM :	143
	db $00, $07, $0F	;ROOM :	144
	db $07, $02, $07	;ROOM :	145
	db $07, $02, $07	;ROOM :	146
	db $07, $02, $07	;ROOM :	147
	db $0A, $00, $00	;ROOM :	148
	db $0A, $00, $00	;ROOM :	149
	db $0A, $00, $00	;ROOM :	150
	db $07, $02, $07	;ROOM :	151
	db $07, $02, $07	;ROOM :	152
	db $00, $06, $07	;ROOM :	153
	db $05, $05, $0B	;ROOM :	154
	db $05, $05, $0B	;ROOM :	155
	db $05, $05, $0B	;ROOM :	156
	db $05, $05, $0B	;ROOM :	157
	db $00, $04, $0C	;ROOM :	158
	db $00, $04, $0C	;ROOM :	159
	db $00, $07, $0F	;ROOM :	160
	db $07, $02, $07	;ROOM :	161
	db $07, $02, $07	;ROOM :	162
	db $07, $02, $07	;ROOM :	163
	db $06, $10, $0C	;ROOM :	164
	db $0A, $00, $00	;ROOM :	165
	db $0A, $00, $00	;ROOM :	166
	db $05, $08, $14	;ROOM :	167
	db $00, $06, $07	;ROOM :	168
	db $00, $06, $07	;ROOM :	169
	db $00, $06, $07	;ROOM :	170
	db $00, $14, $0C	;ROOM :	171
	db $00, $14, $0C	;ROOM :	172
	db $00, $04, $0C	;ROOM :	173
	db $00, $04, $0C	;ROOM :	174
	db $00, $04, $0C	;ROOM :	175
	db $00, $03, $02	;ROOM :	176
	db $07, $02, $07	;ROOM :	177
	db $07, $02, $07	;ROOM :	178
	db $07, $02, $07	;ROOM :	179
	db $06, $10, $0C	;ROOM :	180
	db $05, $07, $0B	;ROOM :	181
	db $05, $07, $0B	;ROOM :	182
	db $05, $07, $0B	;ROOM :	183
	db $00, $06, $07	;ROOM :	184
	db $00, $06, $07	;ROOM :	185
	db $00, $06, $07	;ROOM :	186
	db $00, $14, $0C	;ROOM :	187
	db $00, $14, $0C	;ROOM :	188
	db $00, $04, $0C	;ROOM :	189
	db $00, $04, $0C	;ROOM :	190
	db $00, $04, $0C	;ROOM :	191
	db $00, $03, $01	;ROOM :	192
	db $07, $02, $07	;ROOM :	193
	db $07, $02, $07	;ROOM :	194
	db $07, $02, $07	;ROOM :	195
	db $05, $07, $0B	;ROOM :	196
	db $05, $07, $0B	;ROOM :	197
	db $05, $07, $0B	;ROOM :	198
	db $05, $07, $0B	;ROOM :	199
	db $00, $06, $07	;ROOM :	200
	db $0D, $06, $07	;ROOM :	201
	db $00, $14, $0C	;ROOM :	202
	db $00, $14, $0C	;ROOM :	203
	db $00, $14, $0C	;ROOM :	204
	db $00, $04, $0C	;ROOM :	205
	db $00, $04, $0C	;ROOM :	206
	db $00, $03, $01	;ROOM :	207
	db $00, $03, $01	;ROOM :	208
	db $07, $02, $07	;ROOM :	209
	db $07, $02, $07	;ROOM :	210
	db $00, $06, $07	;ROOM :	211
	db $00, $06, $07	;ROOM :	212
	db $05, $07, $0B	;ROOM :	213
	db $05, $07, $0B	;ROOM :	214
	db $00, $06, $07	;ROOM :	215
	db $00, $06, $07	;ROOM :	216
	db $00, $06, $07	;ROOM :	217
	db $00, $06, $07	;ROOM :	218
	db $00, $14, $0C	;ROOM :	219
	db $00, $14, $0C	;ROOM :	220
	db $00, $04, $09	;ROOM :	221
	db $00, $04, $09	;ROOM :	222
	db $00, $00, $02	;ROOM :	223
	db $00, $03, $02	;ROOM :	224
	db $00, $03, $0A	;ROOM :	225
	db $00, $00, $02	;ROOM :	226
	db $00, $00, $02	;ROOM :	227
	db $00, $03, $0A	;ROOM :	228
	db $00, $03, $0A	;ROOM :	229
	db $00, $03, $0A	;ROOM :	230
	db $00, $03, $0A	;ROOM :	231
	db $00, $03, $0A	;ROOM :	232
	db $00, $00, $02	;ROOM :	233
	db $00, $00, $02	;ROOM :	234
	db $00, $03, $0A	;ROOM :	235
	db $00, $00, $02	;ROOM :	236
	db $00, $00, $02	;ROOM :	237
	db $00, $00, $02	;ROOM :	238
	db $00, $00, $02	;ROOM :	239
	db $00, $03, $0A	;ROOM :	240
	db $00, $03, $0A	;ROOM :	241
	db $00, $0A, $01	;ROOM :	242
	db $00, $0A, $01	;ROOM :	243
	db $00, $0A, $01	;ROOM :	244
	db $00, $0A, $01	;ROOM :	245
	db $00, $03, $0A	;ROOM :	246
	db $00, $03, $0A	;ROOM :	247
	db $00, $03, $0A	;ROOM :	248
	db $00, $00, $02	;ROOM :	249
	db $00, $00, $02	;ROOM :	250
	db $00, $03, $0A	;ROOM :	251
	db $00, $00, $02	;ROOM :	252
	db $00, $00, $02	;ROOM :	253
	db $00, $00, $02	;ROOM :	254
	db $00, $03, $0A	;ROOM :	255
	db $04, $03, $0A	;ROOM :	256
	db $00, $0A, $01	;ROOM :	257
	db $00, $03, $01	;ROOM :	258
	db $04, $03, $0A	;ROOM :	259
	db $00, $03, $01	;ROOM :	260
	db $00, $03, $0A	;ROOM :	261
	db $00, $0B, $11	;ROOM :	262
	db $00, $0A, $01	;ROOM :	263
	db $00, $0A, $01	;ROOM :	264
	db $04, $03, $0A	;ROOM :	265
	db $00, $03, $0A	;ROOM :	266
	db $00, $0F, $0C	;ROOM :	267
	db $00, $03, $07	;ROOM :	268
	db $00, $0F, $0C	;ROOM :	269
	db $00, $03, $0A	;ROOM :	270
	db $00, $0B, $11	;ROOM :	271
	db $00, $0B, $11	;ROOM :	272
	db $00, $0B, $11	;ROOM :	273
	db $00, $03, $0A	;ROOM :	274
	db $00, $01, $07	;ROOM :	275
	db $00, $03, $0A	;ROOM :	276
	db $00, $03, $0A	;ROOM :	277
	db $00, $03, $0A	;ROOM :	278
	db $00, $00, $02	;ROOM :	279
	db $04, $03, $0A	;ROOM :	280
	db $00, $04, $04	;ROOM :	281
	db $00, $03, $0A	;ROOM :	282
	db $00, $03, $0A	;ROOM :	283
	db $00, $0B, $11	;ROOM :	284
	db $00, $04, $04	;ROOM :	285
	db $00, $00, $02	;ROOM :	286
	db $04, $03, $0A	;ROOM :	287
	db $00, $04, $0C	;ROOM :	288
	db $00, $0B, $11	;ROOM :	289
	db $00, $0B, $11	;ROOM :	290
	db $00, $03, $0A	;ROOM :	291
	db $00, $03, $0A	;ROOM :	292
	db $00, $03, $0A	;ROOM :	293
	db $00, $03, $0A	;ROOM :	294
	db $00, $00, $02	;ROOM :	295
	db $00, $00, $00	;ROOM :	296
	db $00, $00, $00	;ROOM :	297
	db $00, $00, $00	;ROOM :	298
	db $00, $00, $00	;ROOM :	299
	db $00, $00, $00	;ROOM :	300
	db $00, $00, $00	;ROOM :	301
	db $00, $00, $00	;ROOM :	302
	db $00, $00, $00	;ROOM :	303
	db $00, $00, $00	;ROOM :	304
	db $00, $00, $00	;ROOM :	305
	db $00, $00, $00	;ROOM :	306
	db $00, $00, $00	;ROOM :	307
	db $00, $00, $00	;ROOM :	308
	db $00, $00, $00	;ROOM :	309
	db $00, $00, $00	;ROOM :	310
	db $00, $00, $00	;ROOM :	311
	db $00, $00, $00	;ROOM :	312
	db $00, $00, $00	;ROOM :	313
	db $00, $00, $00	;ROOM :	314
	db $00, $00, $00	;ROOM :	315
	db $00, $00, $00	;ROOM :	316
	db $00, $00, $00	;ROOM :	317
	db $00, $00, $00	;ROOM :	318
	db $00, $00, $00	;ROOM :	319
	db $00, $00, $00	;ROOM :	320
	db $00, $00, $00	;ROOM :	321
	db $00, $00, $00	;ROOM :	322
	db $00, $00, $00	;ROOM :	323
	db $00, $00, $00	;ROOM :	324	
	db $00, $00, $00	;ROOM :	325
	db $00, $00, $00	;ROOM :	326
	db $00, $00, $00	;ROOM :	327
	db $00, $00, $00	;ROOM :	328
	db $00, $00, $00	;ROOM :	329
	db $00, $00, $00	;ROOM :	330

;SPRITE #$03 SPRITE BRANDS BY ROOM / OVERWORLD AREA * STAGE OF GAME

;DUNGEON ROOMS

TB_BRANDS_DUNGEONS:

dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	10
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	11
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	12
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	13
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	14
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	15
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	16
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	17
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	18
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	19
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	20
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	21
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	22
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	23
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	24
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	25
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	26
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	27
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	28
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	29
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	30
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	31
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	32
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	33
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	34
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	35
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	36
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	37
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	38
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	39
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	40
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	41
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	42
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	43
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	44
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	45
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	46
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	47
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	48
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	49
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	50
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	51
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	52
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	53
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	54
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	55
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	56
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	57
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	58
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	59
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	60
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	61
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	62
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	63
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	64
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	65
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	66
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	67
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	68
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	69
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	70
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	71
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	72
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	73
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	74
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	75
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	76
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	77
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	78
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	79
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	80
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	81
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	82
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	83
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	84
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	85
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	86
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	87
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	88
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	89
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	90
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	91
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	92
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	93
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	94
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	95
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	96
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	97
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	98
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	99
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	100
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	101
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	102
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	103
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	104
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	105
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	106
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	107
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	108
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	109
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	110
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	111
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	112
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	113
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	114
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	115
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	116
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	117
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	118
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	119
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	120
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	121
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	122
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	123
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	124
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	125
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	126
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	127
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	128
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	129
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	130
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	131
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	132
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	133
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	134
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	135
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	136
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	137
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	138
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	139
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	140
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	141
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	142
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	143
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	144
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	145
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	146
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	147
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	148
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	149
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	150
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	151
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	152
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	153
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	154
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	155
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	156
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	157
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	158
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	159
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	160
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	161
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	162
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	163
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	164
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	165
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	166
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	167
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	168
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	169
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	170
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	171
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	172
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	173
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	174
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	175
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	176
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	177
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	178
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	179
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	180
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	181
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	182
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	183
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	184
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	185
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	186
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	187
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	188
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	189
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	190
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	191
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	192
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	193
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	194
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	195
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	196
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	197
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	198
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	199
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	200
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	201
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	202
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	203
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	204
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	205
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	206
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	207
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	208
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	209
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	210
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	211
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	212
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	213
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	214
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	215
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	216
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	217
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	218
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	219
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	220
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	221
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	222
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	223
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	224
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	225
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	226
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	227
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	228
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	229
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	230
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	231
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	232
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	233
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	234
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	235
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	236
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	237
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	238
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	239
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	240
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	241
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	242
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	243
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	244
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	245
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	246
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	247
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	248
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	249
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	250
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	251
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	252
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	253
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	254
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	255
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	256
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	257
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	258
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	259
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	260
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	261
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	262
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	263
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	264
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	265
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	266
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	267
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	268
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	269
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	270
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	271
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	272
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	273
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	274
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	275
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	276
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	277
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	278
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	279
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	280
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	281
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	282
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	283
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	284
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	285
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	286
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	287
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	288
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	289
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	290
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	291
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	292
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	293
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	294
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	295
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	296
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	297
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	298
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	299
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	300
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	301
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	302
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	303
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	304
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	305
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	306
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	307
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	308
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	309
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	310
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	311
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	312
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	313
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	314
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	315
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	316
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	317
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	318
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	319
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	320
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	321
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	322
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	323
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	324
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	325
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	326
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	327
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	328
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	329
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;ROOM	330

warnpc $228000

;PADDING BLOCK B (BANK $22) ---------------------------------------------------------------------------

org $228000	;BEGINNING OF PADDING BLOCK B

;OVERWORLD AREAS (RAIN PHASE)

TB_BRANDS_RAIN:

dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 00
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 01
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 02
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 03
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 04
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 05
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 06
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 07
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 08
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 09
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 10
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 11
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 12
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 13
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 14
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 15
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 16
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 17
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 18
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 19
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 20
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 21
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 22
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 23
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 24
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 25
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 26
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 27
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 28
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 29
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 30
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 31
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 32
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 33
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 34
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 35
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 36
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 37
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 38
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 39
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 40
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 41
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 42
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 43
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 44
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 45
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 46
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 47
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 48
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 49
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 50
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 51
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 52
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 53
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 54
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 55
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 56
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 57
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 58
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 59
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 60
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 61
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 62
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 63
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 64
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 65
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 66
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 67
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 68
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 69
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 70
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 71
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 72
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 73
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 74
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 75
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 76
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 77
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 78
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 79
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 80
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 81
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 82
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 83
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 84
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 85
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 86
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 87
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 88
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 89
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 90
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 91
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 92
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 93
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 94
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 95
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 96
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 97
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 98
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 99
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA ED
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FF

;OVERWORLD AREAS (PRE-AGAHNIM PHASE)

TB_BRANDS_PREAGAHNIM:

dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 00
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 01
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 02
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 03
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 04
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 05
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 06
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 07
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 08
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 09
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 10
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 11
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 12
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 13
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 14
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 15
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 16
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 17
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 18
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 19
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 20
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 21
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 22
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 23
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 24
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 25
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 26
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 27
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 28
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 29
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 30
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 31
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 32
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 33
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 34
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 35
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 36
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 37
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 38
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 39
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 40
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 41
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 42
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 43
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 44
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 45
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 46
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 47
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 48
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 49
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 50
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 51
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 52
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 53
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 54
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 55
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 56
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 57
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 58
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 59
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 60
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 61
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 62
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 63
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 64
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 65
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 66
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 67
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 68
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 69
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 70
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 71
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 72
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 73
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 74
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 75
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 76
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 77
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 78
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 79
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 80
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 81
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 82
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 83
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 84
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 85
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 86
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 87
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 88
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 89
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 90
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 91
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 92
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 93
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 94
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 95
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 96
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 97
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 98
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 99
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA ED
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FF

;OVERWORLD AREAS (POST-AGAHNIM PHASE)

TB_BRANDS_POSTAGAHNIM:

dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 00
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 01
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 02
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 03
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 04
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 05
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 06
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 07
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 08
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 09
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 0F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 10
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 11
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 12
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 13
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 14
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 15
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 16
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 17
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 18
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 19
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 1F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 20
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 21
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 22
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 23
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 24
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 25
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 26
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 27
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 28
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 29
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 2F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 30
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 31
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 32
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 33
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 34
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 35
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 36
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 37
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 38
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 39
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 3F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 40
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 41
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 42
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 43
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 44
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 45
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 46
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 47
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 48
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 49
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 4F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 50
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 51
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 52
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 53
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 54
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 55
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 56
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 57
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 58
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 59
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 5F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 60
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 61
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 62
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 63
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 64
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 65
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 66
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 67
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 68
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 69
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 6F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 70
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 71
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 72
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 73
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 74
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 75
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 76
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 77
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 78
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 79
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 7F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 80
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 81
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 82
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 83
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 84
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 85
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 86
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 87
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 88
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 89
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 8F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 90
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 91
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 92
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 93
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 94
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 95
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 96
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 97
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 98
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 99
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9A
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9B
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9C
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9D
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9E
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA 9F
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA A9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA AF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA B9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA BF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA C9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA CF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA D9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA DF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA E9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA ED
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA EF
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F0
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F1
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F2
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F3
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F4
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F5
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F6
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F7
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F8
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA F9
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FA
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FB
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FC
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FD
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FE
dw $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; AREA FF

padbyte #$00 : pad $2FFFFF	;TO EXPANDETH THY ROM
