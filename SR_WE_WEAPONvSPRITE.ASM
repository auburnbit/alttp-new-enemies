!BLUEBOT 	= #$00
!FAERIE	= #$00
!BRAND		= $7F8500
TB_INITVAR:
TB_DAMAGES:

print "SR_WE_WEAPONvSPRITE.ASM BEGINS AT ",pc
print "----------------------------------------------"

print "SR_WE_WEAPONvSPRITE:       ",pc
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
{
	LDA $0EF0, X			 
	AND #$80			;Is sprite temporarily invincible after getting hit?

	BNE BR_WE_CANCEL		;If so, branch, no weapon contact.

	LDA $EE			;In dungeons, 0 Means you’re on the upper level, 1 Means you’re on a lower level.
	CMP $0F20, X			;Is sprite on the same floor as Link?

	BEQ BR_WE_SAMEFLOOR		;If so, branch, we're not cancelling.

BR_WE_CANCEL:

	CLC				;Clear carry, signaling no collision detected.

	LDA #$00

	RTS

BR_WE_SAMEFLOOR:

	LDA $44			;Y offset for sword collision from Link's coordinates.
	CMP #$80			;Was sword collision cancelled?

	BEQ BR_WE_CANCEL		;If so, branch, no weapon contact.

	JSR SR_WEa_WEAPONCOORDS
	;======================================================================
	;SR_WEa_WEAPONCOORDS: RETRIEVE COORDINATE RANGE FOR WEAPON COLLISION
	;======================================================================
	;Retrieves the range of coordinates for weapon collision.
	;Signals collision impossible with #$80 in WR-8. 
	;---OUTPUT----
	;WR-0		=	Low X coordinate for weapon collision
	;WR-1		=	Low Y coordinate for weapon collision
	;WR-2		=	Width (x) of range to be checked for weapon
	;WR-3		=	Height (y) of range to be checked for weapon
	;WR-8		=	High X coordinate for weapon collision
	;			OR #$80 if collision impossible
	;WR-9		=	High Y coordinate for weapon collision
	;======================================================================

	JSR SR_WEb_SPRITECOORDS
	;======================================================================
	;SR_WEb_SPRITECOORDS: RETRIEVE COORDINATE RANGE FOR SPRITE COLLISION
	;======================================================================
	;Retrieves the range of coordinates for sprite collision.
	;Signals collision impossible with #$80 in WR-A.
	;---OUTPUT----
	;WR-4		=	Low X coordinate for sprite collision
	;WR-5		=	Low Y coordinate for sprite collision
	;WR-6		=	Width (x) of range to be checked for sprite
	;WR-7		=	Height (y) of range to be checked for sprite
	;WR-A		=	High X coordinate for sprite collision
	;			OR #$80 if collision impossible
	;WR-B		=	High Y coordinate for sprite collision
	;======================================================================

	JSR SR_WEc_CHECKRANGES
	;======================================================================
	;SR_WEc_CHECKRANGES: DETERMINE IF THE TWO PARTIES ARE COLLLIDING
	;======================================================================
	;Returns with the carry bit set if the two parties are colliding.
	;---INPUT-----
	;WR-0		=	Low X coordinate for (weapon) collision
	;WR-1		=	Low Y coordinate for (weapon) collision
	;WR-2		=	Width (x) of range to be checked for (weapon)
	;WR-3		=	Height (y) of range to be checked for (weapon)
	;WR-4		=	Low X coordinate for (sprite) collision
	;WR-5		=	Low Y coordinate for (sprite) collision
	;WR-6		=	Width (x) of range to be checked for (sprite)
	;WR-7		=	Height (y) of range to be checked for (sprite)
	;WR-8		=	High X coordinate for (weapon) collision
	;			OR #$80 if collision impossible
	;WR-9		=	High Y coordinate for (weapon) collision
	;WR-A		=	High X coordinate for (sprite) collision
	;			OR #$80 if collision impossible
	;WR-B		=	High Y coordinate for (sprite) collision
	;---OUTPUT----
	;CARRY		= 	Set if collision detected, Clear if not
	;======================================================================

	BCC BR_WE_CANCEL		;If no collision detected, branch, we're cancelling.
	
	STZ $0047			;Stop Link if he's recoiling.

	LDA $037A			
	AND #$10			;Is Link using the bug catching net?

	BEQ BR_WE_NOTNET		;If not, continue, we're not cancelling. 

	RTS				;(carry is still set, signaling collision, however)

BR_WE_NOTNET:

	LDA $0CAA, X
	AND #$04			;Does sprite deflect sword and hammer?

	BNE BR_WE_DEFLECT		;If so, branch, we need to deflect them.

	JSR SR_WEj_WEAPONHIT
	;======================================================================
	;SR_WEj_WEAPONHIT: WEAPON MADE CONTACT WITH SPRITE, SO DEAL WITH IT
	;======================================================================
	;Sets up correct recoil velocities for sprite by attack used.
	;If sprite immune to damage, this routine does nothing more.
	;If sprite hit by sword, find damage/effect class from 1-5 and deal it.
	;If sprite hit by hammer, use damage/effect class 3 and deal it.
	;If sprite hit by powder, transform to faerie or bot or do nothing.
	;If damage is dealt, play correct sound effect, allow sprite recoil.
	;If damage dealt with Ether or Quake medallions, no sprite recoil.
	;======================================================================

	SEC				;Signal that collision was detected.

	LDA #$00
	
	RTS

BR_WE_DEFLECT: 

	LDA $47			;Is Link already recoiling?

	BNE BR_WE_SKIP		;If so, branch, we don't need to do it again.

	LDA #$04			;We're going for a weak recoil.

	JSR SR_WEl_LINKRECOIL
	;======================================================================
	;SR_WEl_LINKRECOIL: SEND LINK RECOILING AWAY FROM SPRITE
	;======================================================================
	;Uses the single value in (A) to send Link recoiling away from sprite.
	;---INPUT-----
	;A		=	Link's recoil velocity (single value)
	;======================================================================

	LDA #$10
	STA $46			;No charging for the spin attack for a while.

	LDA #$10
	STA $47			;And you can't control Link for a little bit.

BR_WE_SKIP:

	JSR SR_WEg_SWORDSPARK
	;======================================================================
	;SR_WEg_SWORDSPARK: CREATE A 'SPARK' AT SWORD COORDINATES (WITH SOUND) 
	;======================================================================
	;Makes a 'spark' animation at the sword collision coordinates.
	;Also forces a 'sword clink' Sound Effect in SE reg 12E.
	;Both are cancelled if another spark present on screen already.
	;======================================================================

	SEC

	LDA #$00

	RTS
}

print "SR_WEa_WEAPONCOORDS:       ",pc
;======================================================================
;SR_WEa_WEAPONCOORDS: RETRIEVE COORDINATE RANGE FOR WEAPON COLLISION
;======================================================================
;Retrieves the range of coordinates for weapon collision.
;Signals collision impossible with #$80 in WR-8. 
;---SOURCE----
;$375E0-$37644 
;---OUTPUT----
;WR-0		=	Low X coordinate for weapon collision
;WR-1		=	Low Y coordinate for weapon collision
;WR-2		=	Width (x) of range to be checked for weapon
;WR-3		=	Height (y) of range to be checked for weapon
;WR-8		=	High X coordinate for weapon collision
;			OR #$80 if collision impossible
;WR-9		=	High Y coordinate for weapon collision
;======================================================================
SR_WEa_WEAPONCOORDS:
{
	LDA $0372			;Is Link dashing?

	BEQ BR_WEa_NOTDASHING 

	LDA $2F			;Which direction is Link facing? (0 up 2 down 4 left 6 right).
	LSR				;0 UP, 1 DOWN, 2 LEFT, 3 RIGHT.

	TAY				;Link's direction transfered to Y.

	LDA $22			;Link's low X coordinate.
	CLC				
	ADC TB_WEa_DASHLOWX, Y	;Value from datatable adjusts based on direction link is facing.
	STA $00			;Store that as low X coordinate for weapon collision.

	LDA $23			;Load Link's high X coordinate.
	ADC TB_WEa_DASHHIGHX, Y	;Value from datatable adjusts (with carry).
	STA $08			;Store that as high X coordinate for weapon collision.

	LDA $20			;Load Link's low Y coordinate.		
	CLC				
	ADC TB_WEa_DASHLOWY, Y	;Value from datatable adjusts based on direction link is facing
	STA $01			;That gets stored as low Y coordinate for weapon collision.

	LDA $21			;Load Link's high Y coodinate.		
	ADC TB_WEa_DASHHIGHY, Y	;Value from datatable adjusts (with carry).
	STA $09			;That gets stored as high Y coordinate for weapon collision.

	LDA #$10			
	STA $02			;Store as width (x) of range to be checked for weapon.
	STA $03			;Store as height (y) of range to be checked for weapon.

	RTS

BR_WEa_NOTDASHING:

	PHX				;Push sprite slot to stack.

	LDX #$00			;Set X to zero, if it stays this way it's not sword collision.

	LDA $0301			
	AND #$0A			;Is Link using a weapon besides the sword or bug catching net?

	BNE BR_WEa_NOTSWORD		;If he is, branch.

	LDA $037A			
	AND #$10			;Is link using the bug catching net?

	BNE BR_WEa_NOTSWORD		;If he is, branch.

	LDY $3C			;Is Link using the spin attack?

	BPL BR_WEa_NOTSPIN		;If he isn't, branch.

	LDA $22			;Load Link's low X coordinate.
	SEC				
	SBC #$0E			;Adjust coordinate for spin attack.
	STA $00			;Store low X coordinate for weapon collision.

	LDA $23			;Load Link's high X coordinate.
	SBC #$00			;Adjust coordinate for spin attack.
	STA $08			;Store high X coordinate for weapon collision.

	LDA $20			;Load Link's low Y coordinate.
	SEC				
	SBC #$0A			;Adjust coordinate for spin attack.
	STA $01			;Store low Y coordinate for weapon collision.

	LDA $21			;Load Link's high Y coordinate.
	SBC #$00			;Adjust coordinate for spin attack.
	STA $09			;Store high Y coordinate for weapon collision.

	LDA #$2C			
	STA $02			;Store width of weapon collision.
	INC				
	STA $03			;Store height of weapon collision.

	PLX				;Pull sprite slot back from stack.

	RTS				

BR_WEa_NOTSPIN:

	LDA $F571, Y			;Otherwise, load a value based on where we are on swing.
				
	BNE BR_WEa_CANCEL		;If that value is nonzero, branch, no collision.
				
	LDA $2F			;Load what direction link is facing. 
					;A:0000 0DD0 -- D:direction 
	ASL 				;A:0000 DD00
	ASL 				;A:000D D000
	ASL 				;A:00DD 0000							
	ADC $3C			;A:00DD SSSS -- S:stage of swing we're on   
	TAX				
	INX				;That, plus 1, is our offset.

BR_WEa_NOTSWORD:

	LDY #$00
	LDA $45			;Load sword collision X offset from Link's coordinates.
	CLC
	ADC TB_WEa_SWINGX, X		;X is 0 if not using sword. X is nonzero if he is.

	BPL BR_WEa_XCARRY 

	DEY				;This is like the carry.

BR_WEa_XCARRY:

	CLC
	ADC $22			;Add Link's low X coordinate.
	STA $00			;Store it to WR-0, as low X coordinate for weapon collision.

	TYA				;Transfer "carry" from Y to A.
	ADC $23			;Add Link's high X coordinate.
	STA $08			;Store it to WR-8, as high X coordinate for weapon collision.

	LDY #$00
	LDA $44			;Load sword collision Y offset from Link's coordinates.
	CLC
	ADC TB_WEa_SWINGY, X		;X is 0 if not using sword.  X is nonzero if he is.

	BPL BR_WEa_YCARRY
	
	DEY				;This is like the carry.

BR_WEa_YCARRY:

	ADC $20			;Add Link's low Y coordinate.
	STA $01			;Store it to WR-0, as low Y coordinate for weapon collision.
	
	TYA				;Transfer "carry" from Y to A.
	ADC $21			;Add Link's high Y coordinate.
	STA $09			;Store it to WR-9, as high Y coordinate for weapon collision.

	LDA TB_WEa_SWINGWIDTH, X	;X is 0 if not using sword.  X is nonzero if he is.
	STA $02			;Store as width (x) of range to be checked for weapon.

	LDA TB_WEa_SWINGHEIGHT, X	;X is 0 if not using sword.  X is nonzero if he is.
	STA $03			;Store as height (y) of range to be checked for weapon.

	PLX				;Pull sprite slot from stack.

	RTS

BR_WEa_CANCEL:

	LDA #$80			
	STA $08			;Signal that collision isn't possible.
	
	PLX				;Pull sprite slot from stack.

	RTS
}

print "> TB_WEa_DASHLOWX:         ",pc

TB_WEa_DASHLOWX:

db $00, $00, $F8, $08

print "> TB_WEa_DASHHIGHX:        ",pc

TB_WEa_DASHHIGHX:

db $00, $00, $FF, $00

print "> TB_WEa_DASHLOWY:         ",pc

TB_WEa_DASHLOWY:

db $F8, $10, $08, $08

print "> TB_WEa_DASHHIGHY:        ",pc

TB_WEa_DASHHIGHY:

db $FF, $00, $00, $00

print "> TB_WEa_SWINGX:           ",pc

TB_WEa_SWINGX:

db $00

db $02, $00, $00, $F8, $00, $02, $00, $02, $02, $01, $01, $00, $00, $00, $00, $00 
db $02, $04, $04, $00, $00, $FC, $FC, $FA, $02, $01, $01, $00, $00, $00, $00, $00 
db $00, $00, $00, $02, $02, $04, $04, $02, $02, $02, $02, $00, $00, $00, $00, $00 
db $00, $00, $00, $FC, $FC, $F6, $00, $02, $02, $00, $00, $00, $00, $00, $00, $00 

print "> TB_WEa_SWINGY:           ",pc

TB_WEa_SWINGY:

db $00 

db $02, $00, $02, $04, $04, $04, $07, $02, $02, $01, $01, $00, $00, $00, $00, $00 
db $02, $00, $02, $FC, $FD, $F8, $00, $00, $02, $01, $01, $00, $00, $00, $00, $00 
db $00, $00, $00, $FE, $00, $FC, $01, $02, $02, $01, $01, $00, $00, $00, $00, $00 
db $00, $00, $00, $FE, $00, $FC, $01, $02, $02, $01, $01, $00, $00, $00, $00, $00

print "> TB_WEa_SWINGWIDTH:       ",pc

TB_WEa_SWINGWIDTH:

db $0F

db $04, $08, $08, $08, $08, $0C, $08, $04, $04, $06, $06, $00, $00, $00, $00, $00
db $04, $10, $0C, $08, $08, $0C, $0B, $0C, $04, $06, $06, $00, $00, $00, $00, $00
db $08, $08, $08, $0A, $0E, $0F, $04, $04, $04, $06, $06, $00, $00, $00, $00, $00
db $08, $08, $08, $0A, $0E, $0F, $04, $04, $04, $06, $06, $00, $00, $00, $00, $00

print "> TB_WEa_SWINGHEIGHT:      ",pc

TB_WEa_SWINGHEIGHT:

db $0F

db $04, $08, $02, $0C, $08, $0C, $08, $04, $04, $06, $06, $00, $00, $00, $00, $00
db $04, $08, $04, $0C, $0C, $0C, $04, $08, $04, $06, $04, $00, $00, $00, $00, $00
db $08, $08, $08, $08, $08, $0C, $04, $04, $04, $06, $06, $00, $00, $00, $00, $00
db $08, $08, $08, $08, $08, $0C, $04, $04, $04, $06, $06, $00, $00, $00, $00, $00

print "SR_WEb_SPRITECOORDS:       ",pc
;======================================================================
;SR_WEb_SPRITECOORDS: RETRIEVE COORDINATE RANGE FOR SPRITE COLLISION
;======================================================================
;Retrieves the range of coordinates for sprite collision.
;Signals collision impossible with #$80 in WR-A.
;---SOURCE----
;$377EF-$37835 
;---MIRRORS---
;SR_LIb_SPRITECOORDS
;---OUTPUT----
;WR-4		=	Low X coordinate for sprite collision
;WR-5		=	Low Y coordinate for sprite collision
;WR-6		=	Width (x) of range to be checked for sprite
;WR-7		=	Height (y) of range to be checked for sprite
;WR-A		=	High X coordinate for sprite collision
;			OR #$80 if collision impossible
;WR-B		=	High Y coordinate for sprite collision
;======================================================================
SR_WEb_SPRITECOORDS:
{
	LDA $0F70, X			;Check the height value of the sprite.

	BMI BR_WEb_CANCEL		;If negative, branch, don't even check.

	PHY				;Push Y to stack.

	LDA $0F60, X
	AND #$1F			;Size class of sprite.
	TAY				;Transfer size class to Y, as our offset.

	LDA $0D10, X 			;The lower byte of a sprite's X - coordinate.
	CLC				
	ADC TB_WEb_LOWX, Y		;Add that with low X offset of sprite.

	STA $04			;Low x coord for sprite collision.

	LDA $0D30, X			;The high byte of a sprite's X - coordinate.
	ADC TB_WEb_HIGHX, Y		;Add that with high X offset of sprite.
	
	STA $0A			;High x coord for sprite collision.
	
	LDA $0D00, X			;The lower byte of a sprite's Y - coordinate.
	CLC
	ADC TB_WEb_LOWY, Y	;Add that with low Y offset of sprite
	
	PHP
	
	SEC
	SBC $0F70, X			;Subtract height value.
	STA $05			;Low y coord for sprite collision
	
	LDA $0D20, X			;The high byte of a sprite's Y - coordinate.
	SBC #$00			;Add that with high Y offset of sprite.
	
	PLP
	
	ADC TB_WEb_HIGHY, Y
	STA $0B			;High y coord for sprite collision

	LDA TB_WEb_XRANGE, Y
	STA $06			;Store as x range.

	LDA TB_WEb_YRANGE, Y
	STA $07			;Store as y range.

	PLY

	RTS

BR_WEb_CANCEL:

	LDA #$80			
	STA $0A			;There will not be collision.

	RTS
}

print "> TB_WEb_LOWX:             ",pc

TB_WEb_LOWX:

db $02, $03, $00, $FD, $FA, $00, $02, $F8, $00, $FC, $F8, $00, $F8, $F0, $02, $02 	;LOW X OFFSETS
db $02, $02, $02, $F8, $02, $02, $F0, $F8, $F4, $04, $FC, $F4, $05, $E0, $FE, $04

print "> TB_WEb_HIGHX:            ",pc

TB_WEb_HIGHX:

db $00, $00, $00, $FF, $FF, $00, $00, $FF, $00, $FF, $FF, $00, $FF, $FF, $00, $00	;HIGH X OFFSETS
db $00, $00, $00, $FF, $00, $00, $FF, $FF, $FF, $00, $FF, $FF, $00, $FF, $FF, $00

print "> TB_WEb_XRANGE:           ",pc

TB_WEb_XRANGE:

db $0C, $01, $10, $14, $14, $08, $04, $20, $30, $18, $20, $20, $20, $30, $0C, $0C	;X RANGES
db $3C, $7C, $0C, $20, $04, $0C, $30, $20, $28, $08, $18, $18, $05, $50, $04, $08

print "> TB_WEb_LOWY:             ",pc

TB_WEb_LOWY:

db $00, $03, $04, $FC, $F8, $02, $00, $F0, $0C, $FC, $F8, $00, $F6, $F0, $02, $02	;LOW Y OFFSETS
db $02, $02, $FD, $F4, $02, $0A, $00, $F4, $10, $04, $FC, $F4, $03, $F0, $F8, $0A

print "> TB_WEb_HIGHY:            ",pc

TB_WEb_HIGHY:

db $00, $00, $00, $FF, $FF, $00, $00, $FF, $00, $FF, $FF, $00, $FF, $FF, $00, $00	;HIGH Y OFFSETS
db $00, $00, $FF, $FF, $00, $00, $00, $FF, $00, $00, $FF, $FF, $00, $FF, $FF, $00

print "> TB_WEb_YRANGE:           ",pc

TB_WEb_YRANGE:

db $0E, $01, $10, $15, $18, $04, $08, $28, $14, $18, $28, $1D, $24, $30, $3C, $7C	;Y RANGES
db $0C, $0C, $11, $1C, $04, $02, $1C, $14, $0A, $04, $18, $10, $05, $30, $08, $0C

print "SR_WEc_CHECKRANGES:        ",pc
;======================================================================
;SR_WEc_CHECKRANGES: DETERMINE IF THE TWO PARTIES ARE COLLIDING
;======================================================================
;Returns with the carry bit set if the two parties are colliding.
;---SOURCE----
;$37836-$37863 
;---MIRRORS---
;SR_LIc_CHECKRANGES
;---INPUT-----
;WR-0		=	Low X coordinate for (weapon) collision
;WR-1		=	Low Y coordinate for (weapon) collision
;WR-2		=	Width (x) of range to be checked for (weapon)
;WR-3		=	Height (y) of range to be checked for (weapon)
;WR-4		=	Low X coordinate for (sprite) collision
;WR-5		=	Low Y coordinate for (sprite) collision
;WR-6		=	Width (x) of range to be checked for (sprite)
;WR-7		=	Height (y) of range to be checked for (sprite)
;WR-8		=	High X coordinate for (weapon) collision
;			OR #$80 if collision impossible
;WR-9		=	High Y coordinate for (weapon) collision
;WR-A		=	High X coordinate for (sprite) collision
;			OR #$80 if collision impossible
;WR-B		=	High Y coordinate for (sprite) collision
;---OUTPUT----
;CARRY		= 	Set if collision detected, Clear if not
;======================================================================
SR_WEc_CHECKRANGES:
{
	PHX				;Push sprite slot to stack.

	LDX #$01			;When X is 1, doing Y part. When 0, doing X part.

LP_WEc_CHECK:

	LDA $04, X			;Low X or Y coordinate for (sprite) collision.			
	SEC
	SBC $00, X			;Low X or Y coordinate for (weapon) collision
	PHA				;Push low byte of distance between them to stack.

	PHP				;Push that processor status to stack.

	CLC
	ADC $06, X			;Width (x) or Height (y) of range to be checked for (sprite).
	STA $0F			;Store low byte of distance between them + range to be checked to WR-F.			

	PLP				;Pull processor status from stack.

	LDA $0A, X			;High X or Y coordinate for (sprite) collision.		
	SBC $08, X			;High X or Y coordinate for (weapon) collision.
	STA $0C			;Store high byte of distance between them to WR-C.

	PLA				;Pull low byte of distance between them from stack.		
	CLC
	ADC #$80			;Add #$80 to that.

	LDA $0C			;Load high byte of distance between them.
	ADC #$00			;Add carry.

	BNE BR_WEc_EXIT

	LDA $02, X			;Width (x) or Height (y) of range to be checked for (weapon).
	CLC
	ADC $06, X			;Width (x) or Height (y) of range to be checked for (sprite)
	CMP $0F

	BCC BR_WEc_EXIT		;Collision must be detected along both axies.

	DEX

	BPL LP_WEc_CHECK

BR_WEc_EXIT:

	PLX				;Pull sprite slot to stack.

	RTS
}

print "SR_WEd_PLAYSE12E:          ",pc
;======================================================================
;SR_WEd_PLAYSE12E: PLAY SOUND EFFECT IN REGISTER $12E 
;======================================================================
;Plays the Sound Effect specified in (A) in SE reg 12E.
;Cancelled if a Sound Effect is already playing in that register.
;---SOURCE----
;$6BB7C-$6BB89 
;---MIRRORS--- 
;SR_LIe_PLAYSE12E
;SR_WOi_PLAYSE12E
;---INPUT-----
;A		=	Sound Effect index (in Mono)
;======================================================================
SR_WEd_PLAYSE12E:
{
	PHY				;Push Y to stack.
	LDY $012E			;Load Y with SE reg 12E.
	
	BEQ BR_WEd_CANCEL		;Is there a sound effect playing in SE reg 12E?

	JSR SR_WEe_STEREOBYSPRITE
	;======================================================================
	;SR_WEe_STEREOBYSPRITE: RETURN SOUND EFFECT TYPE IN STEREO
	;======================================================================
	;Returns the Sound Effect type in stereo. (Both, Right, or Left).
	;---INPUT----
	;A		=	Sound Effect index (in Mono)
	;---OUTPUT----
	;A		=	Sound Effect type in Stereo (Both, Right, or Left)
	;======================================================================

	STA $012E			;Play sound effect in SE reg 12E.

BR_WEd_CANCEL:

	PLY				;Get Y back off of stack.

	RTS	
}

print "SR_WEe_STEREOBYSPRITE:     ",pc
;======================================================================
;SR_WEe_STEREOBYSPRITE: RETURN SOUND EFFECT TYPE IN STEREO
;======================================================================
;Returns the Sound Effect type in stereo (Both, Right, or Left).
;---SOURCE----
;$6BB98-$6BBA0 
;---MIRRORS--- 
;SR_LIf_STEREOBYSPRITE
;SR_WOj_STEREOBYSPRITE
;---INPUT-----
;A		=	Sound Effect index (in Mono)
;---OUTPUT----
;A		=	Sound Effect type in Stereo (Both, Right, or Left)
;======================================================================
SR_WEe_STEREOBYSPRITE:
{
	STA $0D			;Store the sound effect index here temporarily.
	
	JSR SR_WEf_POLBYSPRITE
	;======================================================================
	;SR_WEf_POLBYSPRITE: RETURN SOUND EFFECT POLARITY BY SPRITE POSITION
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

print "SR_WEf_POLBYSPRITE:        ",pc
;======================================================================
;SR_WEf_POLBYSPRITE: RETURN SOUND EFFECT POLARITY BY SPRITE POSITION
;======================================================================
;Returns #$00 if Sound Effect should occur on both speakers.
;Returns #$40 if Sound Effect should occur on only right speaker.
;Returns #$80 if Sound Effect should occur on only left speaker.
;This is determined by sprite's horizontal position on screen.
;---SOURCE----
;$6BBA1-$6BBC7 
;---MIRRORS--- 
;SR_LIg_POLBYSPRITE
;SR_WOk_POLBYSPRITE
;---OUTPUT----
;A		=	Sound Effect Polarity (#$00-BOTH #$40-R #$80-L)
;======================================================================
SR_WEf_POLBYSPRITE:
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

	BCC BR_WEf_POLARITY		;If yes, branch, SE plays on BOTH sides at once.

	INX				;SE only plays on one side.
	CMP #$0000
	
	BMI BR_WEf_POLARITY		;If A is negative, then branch. SE will play on left.

	INX				;SE will play on right.
	
BR_WEf_POLARITY:

	SEP #$20			;(M:8bit)

	LDA TB_WEf_POLARITY, X	;Load Sound Effect Polarity (offset).	
	
	PLX				;Pull sprite slot back.
	
	RTS
}

print "> TB_WEf_POLARITY:         ",pc

TB_WEf_POLARITY:

db $00, $80, $40			; (#$00-BOTH #$40-R #$80-L)

print "SR_WEg_SWORDSPARK:         ",pc
;======================================================================
;SR_WEg_SWORDSPARK: CREATE A 'SPARK' AT SWORD COORDINATES (WITH SOUND) 
;======================================================================
;Makes a 'spark' animation at the sword collision coordinates.
;Also forces a 'sword clink' Sound Effect in SE reg 12E.
;Both are cancelled if another spark present on screen already.
;---SOURCE----
;$3769F-$376C9 
;======================================================================
SR_WEg_SWORDSPARK:
{
	LDA $0FAC			;Check spark animation timer.

	BNE BR_WEg_CANCEL		;If it's in use, branch out.

	LDA #$05							
	STA $0FAC			;Store $#05 to the timer, creating a spark.

	LDA $0022			;$22-$23 Link’s x-Coordinate (mirrored at $0FC2). 
	ADC $0045			;Sword collision x offset from Link's coordinates.
	STA $0FAD			;Spark animation x-coordinate.

	LDA $0020			;$20-$21 Link’s y-Coordinate (mirrored at $0FC4).
	ADC $0044			;Sword collision y offset from Link's coordinates.
	STA $0FAE			;Spark animation y-coordinate.

	LDA $EE			;BG Layer Link is on. 
	STA $0B68			;BG Layer to draw spark animation on.

	JSR SR_WEh_POLBYLINK
	;======================================================================
	;SR_WEh_POLBYLINK: RETURN SOUND EFFECT POLARITY BY LINK'S POSITION
	;======================================================================
	;Returns #$00 if Sound Effect should occur on both speakers.
	;Returns #$40 if Sound Effect should occur on only right speaker.
	;Returns #$80 if Sound Effect should occur on only left speaker.
	;This is determined by Link's horizontal position on screen.
	;---OUTPUT----
	;A		=	Sound Effect Polarity (#$00-BOTH #$40-R #$80-L)
	;======================================================================

	ORA #$05 			;Combine polarity with index for 'sword clink' sound effect.
					;This gives you the sound effect type in stereo.
	
	STA $012E			;Force 'sword clink' sound effect to play in SE reg 12E.

BR_WEg_CANCEL:

	RTS
}

print "SR_WEh_POLBYLINK:          ",pc
;======================================================================
;SR_WEh_POLBYLINK: RETURN SOUND EFFECT POLARITY BY LINK'S POSITION
;======================================================================
;Returns #$00 if Sound Effect should occur on both speakers.
;Returns #$40 if Sound Effect should occur on only right speaker.
;Returns #$80 if Sound Effect should occur on only left speaker.
;This is determined by Link's horizontal position on screen.
;---SOURCE----
;$6BB67-$6BB7B & $6BBA7-$6BBC7 (merged)
;---OUTPUT----
;A		=	Sound Effect Polarity (#$00-BOTH #$40-R #$80-L)
;======================================================================
SR_WEh_POLBYLINK:
{
	LDA $23			;The high byte of Link's x-coordinate.
	XBA

	LDA $22			;The low byte of Link's x-coordinate.

	REP #$20			;(M:16bit)

	PHX				;Push sprite slot to stack.
	
	LDX #$00			;Starting x off with zero.
	
	SEC
	SBC $E2			;Subtract the X coordinate of the scroll register for Layer 2. 
						
	SEC
	SBC #$0050
	
	CMP #$0050			;Are coordinates in the middle of the screen?

	BCC BR_WEh_POLARITY		;If yes, branch, SE plays on BOTH sides at once.

	INX				;SE only plays on one side.
	CMP #$0000
	
	BMI BR_WEh_POLARITY		;If A is negative, then branch. SE will play on left.

	INX				;SE will play on right.
	
BR_WEh_POLARITY:

	SEP #$20			;(M:8bit)

	LDA TB_WEh_POLARITY, X	;Load Sound Effect Polarity (offset).	
	
	PLX				;Pull sprite slot back.
	
	RTS
}

print "> TB_WEh_POLARITY:         ",pc

TB_WEh_POLARITY:

db $00, $80, $40			;(#$00-BOTH #$40-R #$80-L)

print "SR_WEj_WEAPONHIT:          ",pc
;======================================================================
;SR_WEj_WEAPONHIT: WEAPON MADE CONTACT WITH SPRITE, SO DEAL WITH IT
;======================================================================
;Sets up correct recoil velocities for sprite by attack used.
;If sprite immune to damage, this routine does nothing more.
;If sprite hit by sword, find damage/effect class from 1-5 and deal it.
;If sprite hit by hammer, use damage/effect class 3 and deal it.
;If sprite hit by powder, transform to faerie or bot or do nothing.
;If damage is dealt, play correct sound effect, allow sprite recoil.
;If damage dealt with Ether or Quake medallions, no sprite recoil.
;---SOURCE----
;$36C02-$36C5B 
;======================================================================
SR_WEj_WEAPONHIT:
{
	BRA BR_WEj_NOSHOCK		;I'm keeping the following code in case we want to shock people later.

	LDA $0DD0, X			 
	CMP #$09			;Is the sprite state "alive"?

	BNE BR_WEj_NOSHOCK		;If not, branch, we're dealing the damage, not shocking.

	LDA $031F			;Is Link temporarily invincible?

	BNE BR_WEj_CANCEL		;If so, branch, we're not doing anything here.

	LDA #$40
	STA $0E00, X			;Auxiliary Delay Timer 1.
	STA $0360			;We want Link to get shocked.

	JSR SR_WEk_BUMPLINK 
	;======================================================================
	;SR_WEk_BUMPLINK: SPRITE BUMPS LINK AND DEALS HIM DAMAGE
	;======================================================================
	;Sprite deals bump damage to Link with recoil, unless Link invincible.
	;======================================================================

BR_WEj_CANCEL:

	RTS

BR_WEj_NOSHOCK: 

	LDA #$50			;Velocity for recoil from swing or spin.
	LDY $3C			
	CPY #$09			;Is Link swinging/spinning or stabbing?

	BMI BR_WEj_SWING		;If he's swinging/spinning, branch, we want more velocity.

	LDA #$40			;He's stabbing, lower that velocity.

BR_WEj_SWING:

	JSR SR_WEm_TARGETLINK
	;======================================================================
	;SR_WEm_TARGETLINK: TARGET LINK WITH DESIRED TARGETING VELOCITY 
	;======================================================================
	;Uses the single value in (A) to output converted X and Y velocities.
	;---INPUT-----
	;A		=	Desired targeting velocity (single value)
	;---OUTPUT----
	;WR-0		=	Converted Y velocity to target Link
	;WR-1		=	Converted X velocity to target Link
	;======================================================================
	
	LDA $00			;Converted Y velocity to target Link.
	EOR #$FF
	INC 				;Reverse it.
	STA $0F30, X			;Store as Y recoil velocity for sprite.

	LDA $01			;Converted X velocity to target Link.
	EOR #$FF
	INC				;Reverse it.
	STA $0F40, X			;Store as X recoil velocity for sprite.

	JSR SR_WEp_SPRITEHIT
	;======================================================================
	;SR_WEp_SPRITEHIT: SPRITE HAS BEEN HIT BY SOMETHING, SO DEAL WITH IT
	;======================================================================
	;(Recoil velocities for sprite (F30,X) (F40,X) need to be set first).
	;If sprite immune to damage, this routine does nothing.
	;If sprite hit by sword, find damage/effect class from 1-5 and deal it.
	;If sprite hit by hammer, use damage/effect class 3 and deal it.
	;If sprite hit by powder, transform to faerie or bot or do nothing.
	;If damage is dealt, play correct sound effect, allow sprite recoil.
	;If damage dealt with Ether or Quake medallions, no sprite recoil.
	;======================================================================
	
	RTS
} 

print "SR_WEk_BUMPLINK:           ",pc
;======================================================================
;SR_WEk_BUMPLINK: SPRITE BUMPS LINK AND DEALS HIM DAMAGE
;======================================================================
;Sprite deals bump damage to Link with recoil, unless Link invincible.
;---SOURCE----
;$373DB-$3741E
;---MIRROR----
;SR_LIl_BUMPLINK
;======================================================================
SR_WEk_BUMPLINK:
{
	LDA $031F			;Is Link temporarily invincible?
	ORA $037B			;Is Link unhittable?

	BNE BR_WEk_CANCEL		;If Link isn't hittable, branch, we're not doing this.

	LDA #$13			
	STA $46			;Timer preventing Link's movement until it runs down.

	LDA #$18			;We're going to send Link recoiling away at this velocity.

	JSR SR_WEl_LINKRECOIL
	;======================================================================
	;SR_WEl_LINKRECOIL: SEND LINK RECOILING AWAY FROM SPRITE
	;======================================================================
	;Uses the single value in (A) to send Link recoiling away from sprite.
	;---INPUT-----
	;A		=	Link's recoil velocity (single value)
	;======================================================================

	LDA #$01
	STA $4D			;Set Link's state to recoil. 

	LDA $0CD2, X			;Sprite's bump damage class. (0-9 are valid)
	AND #$0F			;A: 0000 BBBB -- B = bump damage class.

	STA $00			
	ASL				
	ADC $00			;Basically multiplied bump damage class by 3.

	CLC
	ADC $7EF35B			;Add in Link's armor value, to form our offset.
	
	TAY				;Now it's in Y as our offset.	

	LDA TB_WEk_BUMPDAM, Y	;Damage Link takes by tunic and bump damage.
	STA $0373			;Damage dealt to Link.

BR_WEk_CANCEL:

	RTS
}

print "> TB_WEk_BUMPDAM:          ",pc

TB_WEk_BUMPDAM:

;--ARMOR LEVEL----/-----------------
;  |1|  |2|  |3| / BUMP DAMAGE CLASS
;---------------/-------------------
db $02, $01, $01 			;0
db $04, $04, $04 			;1
db $00, $00, $00 			;2
db $08, $04, $02 			;3
db $08, $08, $08 			;4
db $10, $08, $04 			;5
db $20, $10, $08 			;6
db $20, $18, $10 			;7
db $18, $10, $08 			;8
db $40, $30, $18			;9

print "SR_WEl_LINKRECOIL:         ",pc
;======================================================================
;SR_WEl_LINKRECOIL: SEND LINK RECOILING AWAY FROM SPRITE
;======================================================================
;Uses the single value in (A) to send Link recoiling away from sprite.
;---SOURCE----
;$37688-$3769E
;---MIRROR----
;SR_LIm_LINKRECOIL
;---INPUT-----
;A		=	Link's recoil velocity (single value)
;======================================================================
SR_WEl_LINKRECOIL:
{
	PHA 				;Push Link's recoil velocity to the stack.

	JSR SR_WEm_TARGETLINK
	;======================================================================
	;SR_WEm_TARGETLINK: TARGET LINK WITH DESIRED TARGETING VELOCITY 
	;======================================================================
	;Uses the single value in (A) to output converted X and Y velocities.
	;---INPUT-----
	;A		=	Desired targeting velocity
	;---OUTPUT----
	;WR-0		=	Converted Y velocity to target Link
	;WR-1		=	Converted X velocity to target Link
	;======================================================================

	LDA $00			;Converted Y velocity to target Link.	
	STA $27			;Link's Recoil for horizontal collisions.

	LDA $01			;Converted X velocity to target link.
	STA $28			;Link's Recoil for vertical collisions.
	
	PLA				;Pull Link's recoil velocity from the stack.
	LSR
	STA $29			;Possibly Z velocity for Link when recoiling jumping?
	STA $C7			;Unknown?  Whatever.

	STZ $24			
	STZ $25			;$24-$25 Typically #$FFFF, but use is still unknown.
	
	RTS
}

print "SR_WEm_TARGETLINK:         ",pc
;======================================================================
;SR_WEm_TARGETLINK: TARGET LINK WITH DESIRED TARGETING VELOCITY 
;======================================================================
;Uses the single value in (A) to output converted X and Y velocities.
;---SOURCE----
;$36991-$36A03 
;---MIRROR----
;SR_LIn_TARGETLINK
;---INPUT-----
;A		=	Desired targeting velocity (single value)
;---OUTPUT----
;WR-0		=	Converted Y velocity to target Link
;WR-1		=	Converted X velocity to target Link
;======================================================================
SR_WEm_TARGETLINK:
{
	STA $01			;Store desired targeting velocity to WR-1
	CMP #$00			;Is it zero?

	BNE BR_WEm_CONTINUE		;If nonzero, branch, we're doing this.

	STZ $00			;If zero, zero out Y velocity as well.

	RTS

BR_WEm_CONTINUE:

	PHX				;Push sprite slot to stack.
	PHY				;Push value in Y to stack, whatever.

	JSR SR_WEn_TOLINKVERT
	;======================================================================
	;SR_WEn_TOLINKVERT: FIND DIRECTION/DISTANCE TO LINK VERTICALLY
	;======================================================================
	;Finds the direction and distance to Link vertically.
	;---OUTPUT----
	;Y		=	0 if Link below; 1 if Link above.
	;A		=	High byte of distance to Link vertically.
	;WR-E		=	Low byte of distance to Link vertically.
	;======================================================================

	STY $02			;Store 0 if Link below; 1 if Link above WR-2.

	LDA $0E			;Load low byte of distance to Link vertically.

	BPL BR_WEm_ABSVALUE

	EOR #$FF
	INC				;Absolute value of A.

BR_WEm_ABSVALUE:

	STA $0C			;Store positive low byte of distance to Link vertically to WR-C.

	JSR SR_WEo_TOLINKHORIZ
	;======================================================================
	;SR_WEo_TOLINKHORIZ: FIND DIRECTION/DISTANCE TO LINK HORIZONTALLY
	;======================================================================
	;Finds the direction and distance to Link horizontally.
	;---OUTPUT----
	;Y		=	0 if Link to right; 1 if Link to left.
	;A		=	High byte of distance to Link horizontally.
	;WR-F		=	Low byte of distance to Link horizontally.
	;======================================================================

	STY $03			;Store 0 if Link to right; 1 if Link to left in WR-3

	LDA $0F			;Load low byte of distance to Link horizontally.

	BPL BR_WEm_ABSVALUE2

	EOR #$FF
	INC				;Absolute value of A.

BR_WEm_ABSVALUE2:

	STA $0D			;Store positive low byte of distance to Link horizontally to WR-D.
	
	LDY #$00			;Zero out Y.
	LDA $0D			;Load positive low byte of distance to Link horizontally.		
	CMP $0C			;Is Link closer vertically than horizontally?

	BCS BR_WEm_CLOSERVERT	;If yes, branch.

	INY				;Increment Y, to show he's closer horizontally.
	PHA				;Push the positive low byte of the distance to Link horizontally to stack.

	LDA $0C			
	STA $0D			;Store positive low byte of distance to Link vertically in WR-D instead.

	PLA				;Pull the positive low byte of the distance to Link horizontally from stack. 
	STA $0C			;Store the positive low byte of the distance to Link horizontally to WR-C.

BR_WEm_CLOSERVERT:

	STZ $0B			;Zero out WR-B to keep up with cumulative WR-C distance.
	STZ $00			;Zero out WR-0 to count how many times we subtract WR-D from WR-C.

	LDX $01			;Load X with desired targeting velocity.

LP_WEm_FORMRATIO:

	LDA $0B			;Cumulative WR-C distance from last time.
	CLC
	ADC $0C			;Add WR-C distance, forming cumulative WR-C distance.

	CMP $0D			;Is it smaller than (or equal to) WR-D distance?

	BCC BR_WEm_NOINC		;If it is smaller than or equal to, branch without subtracting or incrementing WR-0. 

	SBC $0D			;If WR-C distance greater, subtract the WR-D distance.
	INC $00			;And increment WR-0, the smaller part of our ratio.
	
BR_WEm_NOINC:

	STA $0B			;Store cumulative WR-C distance.
	DEX				;Subtract desired targeting velocity (large part of ratio).

	BNE LP_WEm_FORMRATIO		;If we're not done, continue the loop.

	TYA				;0 = closer vertically, 1 = closer horizontally.

	BEQ BR_WEm_NOSWAP		;If closer horizontally, branch, we don't need to swap the velocities.

	LDA $00			;How many times we had to subtract vertical distance from horizontal distance.
	PHA				;Push that to stack.

	LDA $01			;Load desired targeting velocity (large part of ratio).
	STA $00			;Store as the (positive) converted Y velocity to target Link.				

	PLA				;Load small part of ratio.
	STA $01			;Store as the (positive) converted X velocity to target Link.

BR_WEm_NOSWAP:
	
	LDA $00			;Load the (positive) converted Y velocity to target Link.
	LDY $02			;Is Link below the sprite?

	BEQ BR_WEm_BELOW		;If Link below, branch, we keep the positive value.

	EOR #$FF
	INC				;Make the value negative.

	STA $00			;Store (negative) converted Y velocity to target Link.

BR_WEm_BELOW:

	LDA $01			;Load the (positive) converted X velocity to target Link
	LDY $03			;Is Link to the right of the sprite?

	BEQ BR_WEm_ABOVE		;If Link to right, branch, we keep the positive value.

	EOR #$FF
	INC				;Make the value negative.

	STA $01			;Store (negative) converted X velocity to target Link.

BR_WEm_ABOVE:

	PLY				;Pull value in Y from stack, whatever.
	PLX				;Pull sprite slot from stack.

	RTS
}

print "SR_WEn_TOLINKVERT:         ",pc
;======================================================================
;SR_WEn_TOLINKVERT: FIND DIRECTION/DISTANCE TO LINK VERTICALLY
;======================================================================
;Finds the direction and distance to Link vertically.
;---SOURCE----
;36AE8-$36B09 
;---MIRRORS--- 
;SR_LIo_TOLINKVERT
;---OUTPUT----
;Y		=	0 if Link below; 1 if Link above.
;A		=	High byte of distance to Link vertically.
;WR-E		=	Low byte of distance to Link vertically.
;======================================================================
SR_WEn_TOLINKVERT:
{
	LDY #$00
	LDA $20			;Load the lower byte of Link's Y coordinate.
	CLC				
	ADC #$08			;Add #$08 to that.

	PHP				;Push processor status to stack.

	CLC				
	ADC $0F70, X			;Add the sprite's altitude.

	PHP				;Push processor status to stack.

	SEC				
	SBC $0D00, X			;Subtract the lower byte of the sprite's Y coordinate.
	STA $0E			;Store the difference between the two coordinates to WR-E.
	
	LDA $21			;Load the high byte of Link's Y coordinate.
	SBC $0D20, X			;Subtract the high byte of the sprite's Y coordinate. 

	PLP				;Pull processor status from stack.

	ADC #$00			;Add carry from adding sprite's altitude.

	PLP				;Pull processor status from stack.

	ADC #$00			;Add carry from adding #$08 earlier.
	
	BPL BR_WEn_LINKBELOW		;If Link is below the sprite, branch.

	INY				;If Link is above the sprite, increment Y.

BR_WEn_LINKBELOW:

	RTS
}

print "SR_WEo_TOLINKHORIZ:        ",pc
;======================================================================
;SR_WEo_TOLINKHORIZ: FIND DIRECTION/DISTANCE TO LINK HORIZONTALLY
;======================================================================
;Finds the direction and distance to Link horizontally.
;---SOURCE----
;$36AD1-$36AE3
;---MIRRORS--- 
;SR_LIp_TOLINKHORIZ
;---OUTPUT----
;Y		=	0 if Link to right; 1 if Link to left.
;A		=	High byte of distance to Link horizontally.
;WR-F		=	Low byte of distance to Link horizontally.
;======================================================================
SR_WEo_TOLINKHORIZ:
{
	LDY #$00
	
	LDA $22 			;Load the lower byte of Link's X coordinate.
	SEC
	SBC $0D10, X			;Subtract low byte of the sprite's coordinate.
	STA $0F			;Store the difference at WR-F.
	
	LDA $23			;Load the high byte of Link's X coordinate.
	SBC $0D30, X			;Subtract high byte of the sprite's coordinate.
	
	BPL BR_WEo_LINKTORIGHT	;If Link is to the right of the sprite, branch.

	INY				;If Link is to the left, then increment Y.

BR_WEo_LINKTORIGHT:

	RTS
}

print "SR_WEp_SPRITEHIT:          ",pc
;======================================================================
;SR_WEp_SPRITEHIT: SPRITE HAS BEEN HIT BY SOMETHING, SO DEAL WITH IT
;======================================================================
;(Recoil velocities for sprite (F30,X) (F40,X) need to be set first).
;If sprite immune to damage, this routine does nothing.
;If sprite hit by sword, find damage/effect class from 1-5 and deal it.
;If sprite hit by hammer, use damage/effect class 3 and deal it.
;If sprite hit by powder, transform to faerie or bot or do nothing.
;If damage is dealt, play correct sound effect, allow sprite recoil.
;If damage dealt with Ether or Quake medallions, no sprite recoil.
;---SOURCE----
;$36D3F-$36EC0 
;======================================================================
SR_WEp_SPRITEHIT:
{
	LDA $0E60, X
	AND #$40			;Is the sprite currently immune to attack?

	BEQ BR_WEp_NOTIMMUNE		;If no, branch, we're not cancelling.

	RTS				

BR_WEp_NOTIMMUNE:

	LDA $0372			;Load whether Link is dashing or not.
	STA $7FFA4C, X		;Store that here.  From original code; unsure of purpose.
	
	PHX				;Push the sprite slot to stack.				

	LDA $7EF359			;Load Link's sword level.
	DEC 				;Decrement it to be used in the table.

	LDX $0372			;Is Link dashing?

	BNE BR_WEp_GOTPOWER		;If yes, branch, this is our sword power.

	BRA BR_WEp_FINDPOWER		;Otherwise branch, we need to find it.

BR_WEp_SPINNING:

	ORA #$04			;Add in the offset for the spin attack.

	BRA BR_WEp_GOTPOWER		;Branch, this is our sword power.

BR_WEp_FINDPOWER:

	LDX $3C			;How long has Link’s sword been stuck out?

	BMI BR_WEp_SPINNING		;If negative, branch, he’s doing a spin attack.

	CPX #$09			;He's not spinning, but is he swinging?

	BMI BR_WEp_GOTPOWER		;If he is, branch, this is our sword power.

	ORA #$08			;He's stabbing, add in the offset for stabbing.

BR_WEp_GOTPOWER:

	TAX				;Sword power (type of attack x sword level) becomes the offset.

	LDA TB_WEp_SWORD, X		;Load damage/effect class based on sword power. 	
	STA $0CF2			;Store the damage/effect class, to be dealt to sprite.

	LDA $0301			
	AND #$0A			;But is Link using the hammer?

	BEQ BR_WEp_NOTHAMMER		;If not, branch, we're keeping that damage.

	LDA #$03			;Load #$03 as the hammer's damage/effect class.
	STA $0CF2			;Store that value, to be dealt to the sprite.

BR_WEp_NOTHAMMER:

	LDA #$04	
	STA $02E3			;Delay timer for Link, keeps him from being able to attack.

	PLX				;Pull the sprite slot back from the stack.

	LDA #$10
	STA $47			;Delay timer for Link, keeps him from charging for spin attack.

	STZ $0CF3			;Address involved with making enemies stunned, unhittable, and turning them to blobs.

	LDA #$00			;A: ???? ???? | 0000 0000
	XBA				;A: 0000 0000 | ???? ????

	LDA !BRAND, X			;A: 0000 0000 | BBBB BBBB -- B = brand of sprite

	ASL				;A: 0000 000B | BBBB BBB0 
	ASL				;A: 0000 00BB | BBBB BB00	
	ASL				;A: 0000 0BBB | BBBB B000
	ASL				;A: 0000 BBBB | BBBB 0000
	
	ORA $0CF2			;A: 0000 BBBB | BBBB DDDD -- D = damage class				
	
	PHX				;Push the sprite slot to the stack.
	
	TAX				;X: 0000 BBBB | BBBB DDDD -- X is our offset
	
	SEP #$20			;(M:8bit)			
	
	LDA TB_DAMAGES, X		;Load the damage/effect for this damage class for this brand.
	
	PLX				;Pull the sprite slot back from the stack.

	SEP #$10			;(X:8bit)

	CMP #$F9			;Is the damage/effect "make faerie"? 

	BNE BR_WEp_NOFAERIE		;If not, branch, don't make a faerie.
	
	LDA !FAERIE			;Load brand value of the faerie.
	STA !BRAND, X			;Make the sprite brand a faerie.	

	JSR SR_WEq_INITSPRITE 	;Initialize the faerie sprite.
	;======================================================================
	;SR_WEq_INITSPRITE: LOAD INITIAL VARIABLES FOR THE SPRITE
	;======================================================================
	;Loads the initial variables and attributes for the specified sprite.
	;======================================================================

	JSR SR_WEs_SMALLPOOF		;Draw a 'small poof' as the faerie appears.
	;======================================================================
	;SR_WEs_SMALLPOOF: "SMALL POOF" ANIMATION AT SPRITE LOCATION
	;======================================================================
	;Triggers a "small poof" animation at the sprite location.
	;======================================================================

	STZ $012F			;Clear out SE reg 12F.

	LDA #$32			;Load index for "boing!" SE. 

	JSR SR_WEt_PLAYSE12F		;Play "boing!" Sound Effect.
	;======================================================================
	;SR_WEt_PLAYSE12F: PLAY SOUND EFFECT IN REGISTER $12F
	;======================================================================
	;Plays the Sound Effect specified in (A) in SE reg 12F.
	;Cancelled if a Sound Effect is already playing in that register.
	;---INPUT-----
	;A		=	Sound Effect index (in Mono)
	;======================================================================

	JMP SR_WEu_CANCELDAMAGE	;Don't deal this new sprite the damage.
	;======================================================================
	;SR_WEu_CANCELDAMAGE: CANCEL DAMAGE BEING DEALT TO SPRITE
	;======================================================================
	;Clears values causing damage to sprite, so they don't take effect.
	;======================================================================

BR_WEp_NOFAERIE:

	CMP #$FA			;Is the damage/effect "Make Blue Bot"?

	BNE BR_WEp_NOBLOB
		
	LDA !BLUEBOT			;Load brand value of the blue bot.
	STA !BRAND, X			;Make the sprite brand a blue bot.	

	JSR SR_WEq_INITSPRITE 	;Initialize the bot sprite.
	;======================================================================
	;SR_WEq_INITSPRITE: LOAD INITIAL VARIABLES FOR THE SPRITE
	;======================================================================
	;Loads the initial variables and attributes for the specified sprite.
	;======================================================================

	JSR SR_WEs_SMALLPOOF		;Draw a 'small poof' as the bot appears.
	;======================================================================
	;SR_WEs_SMALLPOOF: "SMALL POOF" ANIMATION AT SPRITE LOCATION
	;======================================================================
	;Triggers a "small poof" animation at the sprite location.
	;======================================================================

	STZ $012F			;Clear out SE reg 12F.

	LDA #$32			;Load index for "boing!" SE.

	JSR SR_WEt_PLAYSE12F		;Play "boing!" Sound Effect.
	;======================================================================
	;SR_WEt_PLAYSE12F: PLAY SOUND EFFECT IN REGISTER $12F
	;======================================================================
	;Plays the Sound Effect specified in (A) in SE reg 12F.
	;Cancelled if a Sound Effect is already playing in that register.
	;---INPUT-----
	;A		=	Sound Effect index (in Mono)
	;======================================================================

	JMP SR_WEu_CANCELDAMAGE	;Don't deal this new sprite the damage.
	;======================================================================
	;SR_WEu_CANCELDAMAGE: CANCEL DAMAGE BEING DEALT TO SPRITE
	;======================================================================
	;Clears values causing damage to sprite, so they don't take effect.
	;======================================================================

BR_WEp_NOBLOB: 			

	CMP $0CE2, X			;Was the sprite already recieving a higher priority damage?

	BCC BR_WEp_OLDDAMAGE		;Yes, so branch, this damage value doesn't get used.

	STA $0CE2, X			;Copy our new damage value over.

BR_WEp_OLDDAMAGE:

	CMP #$00			;Was our new damage value nonzero, whether we used it or not?

	BNE BR_WEp_EFFECTIVE		;Yes, so branch, we're actually doing something.

	LDA $0CF2			
	CMP #$0A			;Was the attack from Link magic powder?

	BEQ BR_WEp_NODAMAGE		;If yes, branch, we're not dealing damage.

	LDA $0B6B, X
	AND #$04			;Is Bit 2 of B6B, X, set? From original code; unsure of purpose.

	BNE BR_WEp_UNKNOWN		;If so, branch. From original code; unsure of purpose. 

	STZ $02E3			;You can immediately use your weapons again!

BR_WEp_NODAMAGE:

	JMP SR_WEu_CANCELDAMAGE
	;======================================================================
	;SR_WEu_CANCELDAMAGE: CANCEL DAMAGE BEING DEALT TO SPRITE
	;======================================================================
	;Clears values causing damage to sprite, so they don't take effect.
	;======================================================================

BR_WEp_EFFECTIVE: 			

	CMP #$FE			;Is it real damage, or an effect?

	BCC BR_WEp_REALDAMAGE	;If it's real damage, branch, we don't care that it's frozen.

	LDA $0DD0, X			
	CMP #$0B			;Is the sprite frozen?

	BEQ BR_WEp_NODAMAGE		;If yes, branch, we're not hurting the sprite.

BR_WEp_REALDAMAGE:

	LDA #$9D
	STA $0EF0, X			;involved in dealing sprite damage, rotating their palettes, perhaps death.

	LDY #$21			;Sound Effect index for the "boss hurt" sound 

	LDA $0B6B, X	
	AND #$02			;Is this sprite a boss?

	BNE BR_WEp_GOTSOUND		;If yes, branch, give the "boss hurt" sound.

	LDY #$08			;Sound Effect index for "special" sword strike sound.

	LDA $0BE0, X			
	AND #$10			;Bit 4 of BE0, does the sprite get a "special" sword strike sound?

	BEQ BR_WEp_GOTSOUND		;Yes, so branch, give "special" sword strike sound.

	LDY #$1C			;Otherwise it get's #1C, for the normal sword strike sound.

BR_WEp_GOTSOUND:

	STY $01			;Y = #$21. the "boss hurt" sound.
			 		;Y = #$08. the special sword strike sound.
			 		;Y = #$1C. the normal sword strike sound.

	JSR SR_WEf_POLBYSPRITE
	;======================================================================
	;SR_WEf_POLBYSPRITE: RETURN SOUND EFFECT POLARITY BY SPRITE POSITION
	;======================================================================
	;Returns #$00 if Sound Effect should occur on both speakers.
	;Returns #$40 if Sound Effect should occur on only right speaker.
	;Returns #$80 if Sound Effect should occur on only left speaker.
	;This is determined by sprite's horizontal position on screen.
	;---OUTPUT----
	;A		=	Sound Effect Polarity (#$00-BOTH #$40-R #$80-L)
	;======================================================================

	ORA $01			;Add Sound Effect Polarity to the SE index for stereo sound.
	STA $012F			;Force one of the damage sounds in SE reg 12F.

BR_WEp_UNKNOWN: 				

	LDA #$00			;This value will give no recoil/recovery if used in the end.

	LDY $0CF2			
	CPY #$0D			;Did the Ether or Quake medallion do this damage?

	BCS BR_WEp_MEDALLION		;If yes, branch, for no recoil/recovery time. 

	LDA #$0F			;Normal recoil/recovery value.

BR_WEp_MEDALLION:

	STA $0EA0, X			;Store the recoil/recovery value.

	RTS
}

print "> TB_WEp_SWORD:            ",pc

TB_WEp_SWORD:

;-------SWORD LEVEL--------
;  |1|  |2|  |3|  |4|	
;--------------------------
db $01, $02, $03, $04 	;normal strike damage indices
				
db $02, $03, $04, $05 	;spin attack damage indices	
			
db $01, $01, $02, $03 	;stabbing damage indices

print "SR_WEq_INITSPRITE:         ",pc
;======================================================================
;SR_WEq_INITSPRITE: LOAD INITIAL VARIABLES FOR THE SPRITE
;======================================================================
;Loads the initial variables and attributes for the specified sprite.
;---SOURCE----
;$6B818-$6B870 
;---MIRRORS--- 
;SR_WOm_INITSPRITE
;======================================================================
SR_WEq_INITSPRITE:
{
	JSR SR_WEr_RESETSLOT
	;======================================================================
	;SR_WEr_RESETSLOT: RESET THE VARIABLES FOR THIS SPRITE SLOT
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

	BEQ BR_WEq_OUTDOORS

	LDA $048E			;If indoors, instead load the room number. (in this case, the lower byte)

BR_WEq_OUTDOORS: 

	STA $0C9A, X			;And store that index here.
		
	RTS
}

print "SR_WEr_RESETSLOT:          ",pc
;======================================================================
;SR_WEr_RESETSLOT: RESET THE VARIABLES FOR THIS SPRITE SLOT
;======================================================================
;Clears out all the important variables for this sprite slot.
;---SOURCE----
;$6B871-$6B8F0
;---MIRRORS--- 
;SR_WOn_RESETSLOT
;======================================================================
SR_WEr_RESETSLOT:
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

print "SR_WEs_SMALLPOOF:          ",pc
;======================================================================
;SR_WEs_SMALLPOOF: "SMALL POOF" ANIMATION AT SPRITE LOCATION
;======================================================================
;Triggers a "small poof" animation at the sprite location.
;---SOURCE----
;$2AB9C-$2ABE3 
;---MIRRORS--- 
;SR_WOo_SMALLPOOF
;---OUTPUT----
;Y		=	Animation slot used for "small poof" animation
;======================================================================
SR_WEs_SMALLPOOF:
{
	PHX				;Push sprite slot to stack.

	TXY				;Transfer sprite slot to Y.

	LDX #$1D 			;We're checking #$1D total animation slots.

LP_WEs_FINDASLOT:

	LDA $7FF800, X		;Check $7FF801D... 1C... 1B... to 00 until one is empty.

	BEQ BR_WEs_EMPTYSLOT		;If that slot is empty, branch out of the loop.

	DEX				;Otherwise, decrement X, to check the next one.

	BPL LP_WEs_FINDASLOT		;As long as we're 0 - 1D, try again.

	INX				;If we go below 00 for x, force animation on slot 00.

BR_WEs_EMPTYSLOT:

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

print "SR_WEt_PLAYSE12F:          ",pc
;======================================================================
;SR_WEt_PLAYSE12F: PLAY SOUND EFFECT IN REGISTER $12F
;======================================================================
;Plays the Sound Effect specified in (A) in SE reg 12F.
;Cancelled if a Sound Effect is already playing in that register.
;---SOURCE----
;$6BB8A-$6BB97 
;---MIRRORS--- 
;SR_LIi_PLAYSE12F
;SR_WOp_PLAYSE12F
;---INPUT-----
;A		=	Sound Effect index (in Mono)
;======================================================================
SR_WEt_PLAYSE12F:
{
	PHY				;Push Y to stack.
	LDY $012F			;Load Y with SE reg 12F.
	
	BEQ BR_WEt_CANCEL		;Is there a sound effect playing in SE reg 12F?

	JSR SR_WEe_STEREOBYSPRITE
	;======================================================================
	;SR_WEe_STEREOBYSPRITE: RETURN SOUND EFFECT TYPE IN STEREO
	;======================================================================
	;Returns the Sound Effect type in stereo. (Both, Right, or Left).
	;---INPUT----
	;A		=	Sound Effect index (in Mono)
	;---OUTPUT----
	;A		=	Sound Effect type in Stereo (Both, Right, or Left)
	;======================================================================

	STA $012F			;Play sound effect in SE reg 12F.

BR_WEt_CANCEL:

	PLY				;Get Y back off of stack.

	RTS	
}

print "SR_WEu_CANCELDAMAGE:       ",pc
;======================================================================
;SR_WEu_CANCELDAMAGE: CANCEL DAMAGE BEING DEALT TO SPRITE
;======================================================================
;Clears values causing damage to sprite, so they don't take effect.
;---SOURCE----
;$36EC1-$36EC7
;---MIRROR--- 
;SR_WOq_CANCELDAMAGE
;======================================================================
SR_WEu_CANCELDAMAGE:
{
	STZ $0EF0, X			;Deals with rotating palettes when sprite is hit, and perhaps death mode.
	STZ $0CE2, X			;This is written to with the amount of damage to do to a sprite.

	RTS
}

print "SR_WEw_BREAKSPRITE:        ",pc
;======================================================================
;SR_WEw_BREAKSPRITE: GIVE BREAKABLE SPRITE (EX. BUSH) ANIMATED DEATH
;======================================================================
;Gives the bush/rock/sign etc. an animated normal death.
;---SOURCE----
;$3625A-$3626D 
;---MIRROR--- 
;SR_LIs_BREAKSPRITE
;SR_WOs_BREAKSPRITE
;======================================================================
SR_WEw_BREAKSPRITE:
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

print "SR_WEx_SPRITESPARK:        ",pc
;======================================================================
;SR_WEx_SPRITESPARK: CREATE A SPARK AT SPRITE COODINATES (WITH SOUND)
;======================================================================
;Makes a 'spark' animation at the sprite coordinates.
;Also tries a 'sword clink' Sound Effect in SE reg 12E.
;Both are cancelled if another spark present on screen already.
;---SOURCE----
;$376CA-$37704 
;---MIRROR--- 
;SR_WOt_SPRITESPARK
;======================================================================
SR_WEx_SPRITESPARK:
{
	LDA $0FAC			;Check spark animation timer.

	BNE BR_WEx_CANCEL		;If it's in use, branch out.

	LDA #$05			;Load the index for the 'sword clink' SE.

	JSR SR_WEd_PLAYSE12E
	;======================================================================
	;SR_WEd_PLAYSE12E: PLAY SOUND EFFECT IN REGISTER $12E 
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

	BNE BR_WEx_CANCEL

	LDA $0D00, X			;The lower byte of a sprite's Y - coordinate
	CMP $E8			;$E8-$E9 BG1 vertical scroll register ($210E)

	LDA $0D20, X			;The high byte of a sprite's Y - coordinate.
	SBC $E9			;$E8-$E9 BG1 vertical scroll register ($210E)

	BNE BR_WEx_CANCEL

	LDA $0D10, X			;The lower byte of a sprite's X - coordinate
	STA $0FAD			;"Collision spark" x coordinate
	
	LDA $0D00, X			;The lower byte of a sprite's Y - coordinate
	STA $0FAE			;"Collision spark" y coordinate

	LDA #$05
	STA $0FAC			;Create a "Collision spark"

	LDA $0F20, X
	STA $0B68			;Which BG layer to draw the spark on

BR_WEx_CANCEL:

	RTS
}

print "SR_WEab_DEFLECT:           ",pc
;======================================================================
;SR_WEab_DEFLECT: LINK RECOILS A LITTLE; NO DAMAGE TO SPRITE WITH SPARK
;======================================================================
;Sends Link weakly recoiling away from sprite, after weapon strike.
;Makes spark animation at sword coordinates.
;---SOURCE----
;$373B2-$373C9 
;---OUTPUT----
;A		=	#$00
;CARRY		=	SET
;======================================================================
SR_WEab_DEFLECT:

	LDA $47			;Is Link already recoiling?

	BNE BR_WEab_SKIP		;If so, branch, we don't need to do it again.

	LDA #$04			;We're going for a weak recoil.

	JSR SR_WEl_LINKRECOIL
	;======================================================================
	;SR_WEl_LINKRECOIL: SEND LINK RECOILING AWAY FROM SPRITE
	;======================================================================
	;Uses the single value in (A) to send Link recoiling away from sprite.
	;---INPUT-----
	;A		=	Link's recoil velocity (single value)
	;======================================================================

	LDA #$10
	STA $46			;No charging for the spin attack for a while.

	LDA #$10
	STA $47			;And you can't control Link for a little bit.

BR_WEab_SKIP:

	JSR SR_WEg_SWORDSPARK
	;======================================================================
	;SR_WEg_SWORDSPARK: CREATE A 'SPARK' AT SWORD COORDINATES (WITH SOUND) 
	;======================================================================
	;Makes a 'spark' animation at the sword collision coordinates.
	;Also forces a 'sword clink' Sound Effect in SE reg 12E.
	;Both are cancelled if another spark present on screen already.
	;======================================================================

	SEC

	LDA #$00

	RTS
}

print "SR_WEac_WEAPONRECOIL:      ",pc
;======================================================================
;SR_WEac_WEAPONRECOIL: WEAPON HITS SPRITE, HANDLE IT, LINK RECOILS
;======================================================================
;Sends Link recoiling away from sprite after hitting it with weapon.
;If sprite deflects sword/hammer for no damage: 
;Makes spark animation at sword coordinates.
;If sprite does NOT deflect sword/hammer for no damage:
;Sets up correct recoil velocities for sprite by attack used.
;If sprite immune to damage, this routine does nothing more.
;If sprite hit by sword, find damage/effect class from 1-5 and deal it.
;If sprite hit by hammer, use damage/effect class 3 and deal it.
;If sprite hit by powder, transform to faerie or bot or do nothing.
;If damage is dealt, play correct sound effect, allow sprite recoil.
;If damage dealt with Ether or Quake medallions, no sprite recoil.
;---SOURCE----
;$37395-$373C9 
;---OUTPUT----
;A		=	#$00
;CARRY		=	SET
;======================================================================
SR_WEac_WEAPONRECOIL:

	LDA #$20			;Load as Link's recoil velocity.

	JSR SR_WEl_LINKRECOIL
	;======================================================================
	;SR_WEl_LINKRECOIL: SEND LINK RECOILING AWAY FROM SPRITE
	;======================================================================
	;Uses the single value in (A) to send Link recoiling away from sprite.
	;---INPUT-----
	;A		=	Link's recoil velocity (single value)
	;======================================================================

	LDA #$90
	STA $47			;No charging for the spin attack for a while.
	
	LDA #$10
	STA $46			;And you can't control Link for a little bit.
	
	LDA $0CAA, X
	AND #$04			;Now, does sprite deflect sword/hammer?

	BNE BR_WEac_DEFLECT		;If so, branch, we need to deflect sword/hammer.

	JSR SR_WEj_WEAPONHIT
	;======================================================================
	;SR_WEj_WEAPONHIT: WEAPON MADE CONTACT WITH SPRITE, SO DEAL WITH IT
	;======================================================================
	;Sets up correct recoil velocities for sprite by attack used.
	;If sprite immune to damage, this routine does nothing more.
	;If sprite hit by sword, find damage/effect class from 1-5 and deal it.
	;If sprite hit by hammer, use damage/effect class 3 and deal it.
	;If sprite hit by powder, transform to faerie or bot or do nothing.
	;If damage is dealt, play correct sound effect, allow sprite recoil.
	;If damage dealt with Ether or Quake medallions, no sprite recoil.
	;======================================================================

	BRA BR_WEac_DONE 

BR_WEac_DEFLECT:

	JSR SR_WEg_SWORDSPARK
	;======================================================================
	;SR_WEg_SWORDSPARK: CREATE A 'SPARK' AT SWORD COORDINATES (WITH SOUND) 
	;======================================================================
	;Makes a 'spark' animation at the sword collision coordinates.
	;Also forces a 'sword clink' Sound Effect in SE reg 12E.
	;Both are cancelled if another spark present on screen already.
	;======================================================================

BR_WEac_DONE:
	
	SEC

	LDA #$00

	RTS
}

print "----------------------------------------------"
print "SR_WE_WEAPONvSPRITE.ASM ENDS AT ",pc," (MINUS 1)"
