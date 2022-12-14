!BLUEBOT 	= #$00
!FAERIE	= #$00
!BRAND		= $7F8500
TB_INITVAR:
TB_DAMAGES:

print "SR_WO_WORLDvSPRITE.ASM BEGINS AT ",pc
print "----------------------------------------------"

print "SR_WOi_PLAYSE12E:          ",pc
;======================================================================
;SR_WOi_PLAYSE12E: PLAY SOUND EFFECT IN REGISTER $12E 
;======================================================================
;Plays the Sound Effect specified in (A) in SE reg 12E.
;Cancelled if a Sound Effect is already playing in that register.
;---SOURCE----
;$6BB7C-$6BB89 
;---MIRRORS--- 
;SR_WEd_PLAYSE12E
;SR_LIe_PLAYSE12E
;---INPUT-----
;A		=	Sound Effect index (in Mono)
;======================================================================
SR_WOi_PLAYSE12E:
{
	PHY				;Push Y to stack.
	LDY $012E			;Load Y with SE reg 12E.
	
	BEQ BR_WOi_CANCEL		;Is there a sound effect playing in SE reg 12E?

	JSR SR_WOj_STEREOBYSPRITE
	;======================================================================
	;SR_WOj_STEREOBYSPRITE: RETURN SOUND EFFECT TYPE IN STEREO
	;======================================================================
	;Returns the Sound Effect type in stereo. (Both, Right, or Left).
	;---INPUT----
	;A		=	Sound Effect index (in Mono)
	;---OUTPUT----
	;A		=	Sound Effect type in Stereo (Both, Right, or Left)
	;======================================================================

	STA $012E			;Play sound effect in SE reg 12E.

BR_WOi_CANCEL:

	PLY				;Get Y back off of stack.

	RTS	
}

print "SR_WOj_STEREOBYSPRITE:     ",pc
;======================================================================
;SR_WOj_STEREOBYSPRITE: RETURN SOUND EFFECT TYPE IN STEREO
;======================================================================
;Returns the Sound Effect type in stereo (Both, Right, or Left).
;---SOURCE----
;$6BB98-$6BBA0 
;---MIRRORS--- 
;SR_WEe_STEREOBYSPRITE
;SR_LIf_STEREOBYSPRITE
;---INPUT-----
;A		=	Sound Effect index (in Mono)
;---OUTPUT----
;A		=	Sound Effect type in Stereo (Both, Right, or Left)
;======================================================================
SR_WOj_STEREOBYSPRITE:
{
	STA $0D			;Store the sound effect index here temporarily.
	
	JSR SR_WOk_POLBYSPRITE
	;======================================================================
	;SR_WOk_POLBYSPRITE: RETURN SOUND EFFECT POLARITY BY SPRITE POSITION
	;======================================================================
	;Returns #$00 if Sound Effect should occur on both speakers.
	;Returns #$40 if Sound Effect should occur on only right speaker.
	;Returns #$80 if Sound Effect should occur on only left speaker.
	;This is determined by sprite's horizontal position on screen.
	;---OUTPUT----
	;A		=	Sound Effect Polarity (#$00-BOTH #$40-R #$80-L)
	;======================================================================
	
	ORA $0D			;Polarity + SE index = SE type in stereo.
	
	RTS
}

print "SR_WOk_POLBYSPRITE:        ",pc
;======================================================================
;SR_WOk_POLBYSPRITE: RETURN SOUND EFFECT POLARITY BY SPRITE POSITION
;======================================================================
;Returns #$00 if Sound Effect should occur on both speakers.
;Returns #$40 if Sound Effect should occur on only right speaker.
;Returns #$80 if Sound Effect should occur on only left speaker.
;This is determined by sprite's horizontal position on screen.
;---SOURCE----
;$6BBA1-$6BBC7 
;---MIRRORS--- 
;SR_WEf_POLBYSPRITE
;SR_LIg_POLBYSPRITE
;---OUTPUT----
;A		=	Sound Effect Polarity (#$00-BOTH #$40-R #$80-L)
;======================================================================
SR_WOk_POLBYSPRITE:
{
	LDA $0D30, X			;The high byte of a sprite's X - coordinate.		
	XBA	

	LDA $0D10, X			;The lower byte of a sprite's X - coordinate.

	REP #$20			;(M:16bit)

	PHX				;Push sprite slot to stack.
	
	LDX #$00			;Starting x off with zero.
	
	SEC
	SBC $E2			;Subtract the X coordinate of the scroll register for Layer 2. 
						
	SEC
	SBC #$0050
	
	CMP #$0050			;Are coordinates in the middle of the screen?

	BCC BR_WOk_POLARITY		;If yes, branch, SE plays on BOTH sides at once.

	INX				;SE only plays on one side.
	CMP #$0000
	
	BMI BR_WOk_POLARITY		;If A is negative, then branch. SE will play on left.

	INX				;SE will play on right.
	
BR_WOk_POLARITY:

	SEP #$20			;(M:8bit)

	LDA TB_WOk_POLARITY, X	;Load Sound Effect Polarity (offset).	
	
	PLX				;Pull sprite slot back.
	
	RTS
}

print "> TB_WOk_POLARITY:         ",pc

TB_WOk_POLARITY:

db $00, $80, $40			; (#$00-BOTH #$40-R #$80-L)

print "SR_WOm_INITSPRITE:         ",pc
;======================================================================
;SR_WOm_INITSPRITE: LOAD INITIAL VARIABLES FOR THE SPRITE
;======================================================================
;Loads the initial variables and attributes for the specified sprite.
;---SOURCE----
;$6B818-$6B870 
;---MIRRORS--- 
;SR_WEq_INITSPRITE
;======================================================================
SR_WOm_INITSPRITE:
{
	JSR SR_WOn_RESETSLOT
	;======================================================================
	;SR_WOn_RESETSLOT: RESET THE VARIABLES FOR THIS SPRITE SLOT
	;======================================================================
	;Clears out all the important variables for this sprite slot.
	;======================================================================

	LDA !BRAND, X			;Load the "brand" of sprite.
	ASL
	ASL
	ASL
	ASL
	TXY
	TAX
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
	LDY $1B			;Are we indoors?

	BEQ BR_WOm_OUTDOORS

	LDA $048E			;If indoors, instead load the room number. (in this case, the lower byte)

BR_WOm_OUTDOORS: 

	STA $0C9A, X			;And store that index here.
		
	RTS
}

print "SR_WOn_RESETSLOT:          ",pc
;======================================================================
;SR_WOn_RESETSLOT: RESET THE VARIABLES FOR THIS SPRITE SLOT
;======================================================================
;Clears out all the important variables for this sprite slot.
;---SOURCE----
;$6B871-$6B8F0
;---MIRRORS--- 
;SR_WEr_RESETSLOT
;======================================================================
SR_WOn_RESETSLOT:
{
	STZ $0F00, X
	STZ $0E90, X
	STZ $0D50, X
	STZ $0D40, X
	STZ $0F80, X
	STZ $0D70, X
	STZ $0D60, X
	STZ $0F90, X
	STZ $0D80, X
	STZ $0DC0, X
	STZ $0DE0, X
	STZ $0DF0, X
	STZ $0E00, X
	STZ $0E10, X
	STZ $0F10, X
	STZ $0EB0, X
	STZ $0EC0, X
	STZ $0ED0, X
	STZ $0EF0, X
	STZ $0E70, X
	STZ $0F70, X
	STZ $0E50, X
	STZ $0EA0, X
	STZ $0F40, X
	STZ $0F30, X
	STZ $0D90, X
	STZ $0DA0, X
	STZ $0DB0, X
	STZ $0BB0, X
	STZ $0E80, X
	STZ $0BA0, X
	STZ $0B89, X
	STZ $0F50, X
	STZ $0B58, X
	STZ $0CE2, X

	LDA #$00
	STA $7FFA1C, X
	STA $7FFA2C, X
	STA $7FFA3C, X
	STA $7FFA4C, X
	STA $7FF9C2, X
	
	RTS
}

print "SR_WOo_SMALLPOOF:          ",pc
;======================================================================
;SR_WOo_SMALLPOOF: "SMALL POOF" ANIMATION AT SPRITE LOCATION
;======================================================================
;Triggers a "small poof" animation at the sprite location.
;---SOURCE----
;$2AB9C-$2ABE3 
;---MIRRORS--- 
;SR_WEs_SMALLPOOF
;---OUTPUT----
;Y		=	Animation slot used for "small poof" animation
;======================================================================
SR_WOo_SMALLPOOF:
{
	PHX				;Push sprite slot to stack.

	TXY				;Transfer sprite slot to Y.

	LDX #$1D 			;We're checking #$1D total animation slots.

LP_WOo_FINDASLOT:

	LDA $7FF800, X		;Check $7FF801D... 1C... 1B... to 00 until one is empty.

	BEQ BR_WOo_EMPTYSLOT		;If that slot is empty, branch out of the loop.

	DEX				;Otherwise, decrement X, to check the next one.

	BPL LP_WOo_FINDASLOT		;As long as we're 0 - 1D, try again.

	INX				;If we go below 00 for x, force animation on slot 00.

BR_WOo_EMPTYSLOT:

	LDA #$0A			;#$0A = "small poof" animation type.
	STA $7FF800, X		;We want a "small poof" animation.

	STA $0FB4			;This gets copied here too.  I think all	that matters is that 
					;this makes it nonzero, thus allowing the animation to occur.

	LDA $0D10, Y			;The lower byte of the sprite's x-coordinate.
	STA $7FF83C, X		;The low byte of the x-coordinate for the animation.
	
	LDA $0D30, Y			;The high byte of the sprite's x-coordinate.
	STA $7FF878, X		;The high byte of the x-coordinate for the animation.
	
	LDA $0D00, Y			;The lower byte of the sprite's y-coordinate.
	CLC
	ADC #$10
	STA $7FF81E, X		;The low byte of the y-coordinate for the animation.
	
	LDA $0D20, Y			;The high byte of the sprite's y-coordinate.
	ADC #$00
	STA $7FF85A, X		;The high byte of the y-coordinate for the animation.
	
	LDA $0F20, Y			;Floor selector. Tells us which floor each sprite is on (in multilevel rooms).
	STA $7FF92C, X		;Which layer to draw the animation on.
	
	LDA #$0F
	STA $7FF90E, X		;Timer that determines what part of the animation we're on.
	
	TXY				;Transfer animation slot to Y.
	
	PLX				;Pull sprite slot back from stack.
	
	RTS
}

print "SR_WOp_PLAYSE12F:          ",pc
;======================================================================
;SR_WOp_PLAYSE12F: PLAY SOUND EFFECT IN REGISTER $12F
;======================================================================
;Plays the Sound Effect specified in (A) in SE reg 12F.
;Cancelled if a Sound Effect is already playing in that register.
;---SOURCE----
;$6BB8A-$6BB97 
;---MIRRORS--- 
;SR_WEt_PLAYSE12F
;SR_LIi_PLAYSE12F
;---INPUT-----
;A		=	Sound Effect index (in Mono)
;======================================================================
SR_WOp_PLAYSE12F:
{
	PHY				;Push Y to stack.
	LDY $012F			;Load Y with SE reg 12F.
	
	BEQ BR_WOp_CANCEL		;Is there a sound effect playing in SE reg 12F?

	JSR SR_WOj_STEREOBYSPRITE
	;======================================================================
	;SR_WOj_STEREOBYSPRITE: RETURN SOUND EFFECT TYPE IN STEREO
	;======================================================================
	;Returns the Sound Effect type in stereo. (Both, Right, or Left).
	;---INPUT----
	;A		=	Sound Effect index (in Mono)
	;---OUTPUT----
	;A		=	Sound Effect type in Stereo (Both, Right, or Left)
	;======================================================================

	STA $012F			;Play sound effect in SE reg 12F.

BR_WOp_CANCEL:

	PLY				;Get Y back off of stack.

	RTS	
}

print "SR_WOq_CANCELDAMAGE:       ",pc
;======================================================================
;SR_WOq_CANCELDAMAGE: CANCEL DAMAGE BEING DEALT TO SPRITE
;======================================================================
;Clears values causing damage to sprite, so they don't take effect.
;---SOURCE----
;$36EC1-$36EC7
;---MIRROR--- 
;SR_WEu_CANCELDAMAGE
;======================================================================
SR_WOq_CANCELDAMAGE:
{
	STZ $0EF0, X			;Deals with rotating palettes when sprite is hit, and perhaps death mode.
	STZ $0CE2, X			;This is written to with the amount of damage to do to a sprite.

	RTS
}

print "SR_WOs_BREAKSPRITE:        ",pc
;======================================================================
;SR_WOs_BREAKSPRITE: GIVE BREAKABLE SPRITE (EX. BUSH) ANIMATED DEATH
;======================================================================
;Gives the bush/rock/sign etc. an animated normal death.
;---SOURCE----
;$3625A-$3626D 
;---MIRROR--- 
;SR_WEw_BREAKSPRITE
;SR_LIs_BREAKSPRITE
;======================================================================
SR_WOs_BREAKSPRITE:
{
	LDA #$1F
	STA $0DF0, Y			;Put #$1F into the timer for the "breaking" animation.

	LDA #$06	
	STA $0DD0, X			;Give the breaking sprite the state: animated normal death

	LDA $0E40, X		
	CLC
	ADC #$04
	STA $0E40, X			;Giving us more tiles to draw the sprite with?
					;Not sure why it does this, everything acts the same if you don't.

	RTS
}

print "SR_WOt_SPRITESPARK:        ",pc
;======================================================================
;SR_WOt_SPRITESPARK: CREATE A SPARK AT SPRITE COODINATES (WITH SOUND)
;======================================================================
;Makes a 'spark' animation at the sprite coordinates.
;Also tries a 'sword clink' Sound Effect in SE reg 12E.
;Both are cancelled if another spark present on screen already.
;---SOURCE----
;$376CA-$37704 
;---MIRROR--- 
;SR_WEx_SPRITESPARK
;======================================================================
SR_WOt_SPRITESPARK:
{
	LDA $0FAC			;Check spark animation timer.

	BNE BR_WOt_CANCEL		;If it's in use, branch out.

	LDA #$05			;Load the index for the 'sword clink' SE.

	JSR SR_WOi_PLAYSE12E
	;======================================================================
	;SR_WOi_PLAYSE12E: PLAY SOUND EFFECT IN REGISTER $12E 
	;======================================================================
	;Plays the Sound Effect specified in (A) in SE reg 12E.
	;Cancelled if a Sound Effect is already playing in that register.
	;---INPUT-----
	;A		=	Sound Effect index (in Mono)
	;======================================================================

	LDA $0D10, X	 		;The lower byte of a sprite's X - coordinate
	CMP $E2			;LOW BYTE OF BG1 horizontal scroll register ($210D)

	LDA $0D30, X			;The high byte of a sprite's X - coordinate.
	SBC $E3			;HIGH BYTE OF BG1 horizontal scroll register ($210D)

	BNE BR_WOt_CANCEL

	LDA $0D00, X			;The lower byte of a sprite's Y - coordinate
	CMP $E8			;$E8-$E9 BG1 vertical scroll register ($210E)

	LDA $0D20, X			;The high byte of a sprite's Y - coordinate.
	SBC $E9			;$E8-$E9 BG1 vertical scroll register ($210E)

	BNE BR_WOt_CANCEL

	LDA $0D10, X			;The lower byte of a sprite's X - coordinate
	STA $0FAD			;"Collision spark" x coordinate
	
	LDA $0D00, X			;The lower byte of a sprite's Y - coordinate
	STA $0FAE			;"Collision spark" y coordinate

	LDA #$05
	STA $0FAC			;Create a "Collision spark"

	LDA $0F20, X
	STA $0B68			;Which BG layer to draw the spark on

BR_WOt_CANCEL:

	RTS
}

print "----------------------------------------------"
print "SR_WO_WORLDvSPRITE.ASM ENDS AT ",pc," (MINUS 1)"
