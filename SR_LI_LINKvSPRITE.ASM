!BLUEBOT 	= #$00
!FAERIE		= #$00
!BRAND		= $7F8500
TB_INITVAR:
TB_DAMAGES:

								print "SR_LI_LINKvSPRITE.ASM BEGINS AT ",pc
								print "----------------------------------------------"

								print "SR_LI_LINKv_SPRITE:        ",pc
								;======================================================================
								;SR_LI_LINKvSPRITE: HANDLE LINK VS. SPRITE COLLISION
								;======================================================================
								;If sprite and Link collide, set carry, if not, clear it.
								;If Link is untouchable, there is no collision.
								;If sprite still flashing(?) there is no collision.
								;If sprite and Link on different floors, no collision.
								;If the sprite is harmless, there is no collision.
								;If the sprite and Link aren't touching, there is no collision.
								;If there is collision:
								;If the sprite cannot touch the shield, there is bump damage.
								;If the sprite can touch the shield:
								;If Link is the bunny, there is bump damage.
								;If Link has no shield, there is bump damage.
								;If Link's shield is facing the wrong way, there is bump damage.
								;If sprite hits shield, make it vanish, DING S.E., and spark animation.
								;---SIMILAR FUNCTIONALITY TO----
								;$37145-$371F5 
								;---OUTPUT----
								;CARRY		= 	Set if Link "collided" with sprite, Clear if not
								;======================================================================
SR_LI_LINKvSPRITE:
{
LDA $037B						;Is Link untouchable?

BNE BR_LI_NOHIT					;So branch, we're not colliding with the sprite.

TXA				
EOR $1A							;Frame Counter
AND #$03			
ORA $0EF0, X					;Controls dealing sprite damage, rotating their palettes when hit, and death animation

BNE BR_LI_NOHIT					;if sprite still flashing from being hit before, no collision

LDA $00EE						;What floor Link is on.
CMP $0F20, X					;Is the sprite on the same floor as Link?

BNE BR_LI_NOHIT					;If not, branch, we're not colliding.

LDA $0F60, X					;BITS 4 – 0 = determines the sprite's "size class" for weapon/sprite collision purposes.

BEQ BR_LI_SAMESIZE				;branch if sprite is same size as Link.

JSR SR_LIa_FORCERANGE
								;======================================================================
								;SR_LIa_FORCERANGE: GET RANGE FOR LINK COLLISION, EVEN IF UNHITTABLE 
								;======================================================================
								;Retrieves the range of Link's coordinates, even if he can't be hit.
								;---OUTPUT----
								;WR-0		=	Low X coordinate for Link collision
								;WR-1		=	Low Y coordinate for Link collision
								;WR-2		=	Width (x) of range to be checked for Link
								;WR-3		=	Height (y) of range to be checked for Link
								;WR-8		=	High X coordinate for Link collision
								;WR-9		=	High Y coordinate for Link collision
								;======================================================================

JSR SR_LIb_SPRITECOORDS
								;======================================================================
								;SR_LIb_SPRITECOORDS: RETRIEVE COORDINATE RANGE FOR SPRITE COLLISION
								;======================================================================
								;Retrieves the range of coordinates for sprite collision.
								;Signals collision impossible with #$80 in WR-A.
								;---OUTPUT----
								;WR-4		=	Low X coordinate for sprite collision
								;WR-5		=	Low Y coordinate for sprite collision
								;WR-6		=	Width (x) of range to be checked for sprite
								;WR-7		=	Height (y) of range to be checked for sprite
								;WR-A		=	High X coordinate for sprite collision
								;				OR #$80 if collision impossible
								;WR-B		=	High Y coordinate for sprite collision
								;======================================================================

JSR SR_LIc_CHECKRANGES
								;======================================================================
								;SR_LIc_CHECKRANGES: DETERMINE IF THE TWO PARTIES ARE COLLIDING
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
								;				OR #$80 if collision impossible
								;WR-9		=	High Y coordinate for (weapon) collision
								;WR-A		=	High X coordinate for (sprite) collision
								;				OR #$80 if collision impossible
								;WR-B		=	High Y coordinate for (sprite) collision
								;---OUTPUT----
								;CARRY		= 	Set if collision detected, Clear if not
								;======================================================================

BRA BR_LI_SKIP

BR_LI_SAMESIZE:

JSR SR_LId_SAMESIZE
								;======================================================================
								;SR_LId_SAMESIZE: CHECK IF LINK IS TOUCHING THE SPRITE IF SAME SIZE 
								;======================================================================
								;Carry returns clear if Link is touching sprite.
								;Sprite must be the same size as Link. (Size class 0)
								;---OUTPUT----
								;CARRY		= 	Set if collision detected, Clear if not
								;======================================================================

BR_LI_SKIP:

LDA $0E40, X					;Bit 7: If set, enemy is harmless. Otherwise you take damage from contact

BPL BR_LI_CONTINUE				;If bit 7 is clear, continue, don't cancel damage yet.

RTS

BR_LI_CONTINUE:

BCC BR_LI_NOHIT					;Branch if collision wasn't detected, we're not dealing damage.

LDA $4D							;Is Link in the normal ground state?

BNE BR_LI_NOHIT					;Branch if not, we're not dealing damage.

LDA $02E0						;Is Link currently the bunny?

BNE BR_LI_GOTHIT				;Branch if he is, we don't have our shield up, we get bump damage.

LDA $0308						;Is Link carrying something?

BMI BR_LI_GOTHIT				;Branch if he is, we don't have our shield up, we get bump damage.

LDA $0BE0, X			
AND #$20						;Does the sprite collide with Link's shield? (normally only used w/ projectiles)

BEQ BR_LI_GOTHIT				;Branch if not, we get bump damage.

LDA $7EF35A						;Does Link have a shield?

BEQ BR_LI_GOTHIT				;Branch if not, we get bump damage.

STZ $0DD0, X					;Make the sprite (normally projectile by this point) vanish.

LDA $2F							;The direction Link is facing. 0 - up, 2 - down, 4 - left, 6 - right.
LDY $3C							;Is Link swinging the sword? (ie. Is Link's shield to his side?)

BEQ BR_LI_FRONT					;If not swinging sword, branch, shield is in front.

LSR								;Direction Link is facing is now 0 - up, 1 - down, 2 - left, 3 - right.
TAY								;This is our offset.

LDA TB_LI_SHIELDSIDE, Y			;DATA TABLE: Load the direction Link's SHIELD is facing instead.		

BR_LI_FRONT:

LDY $0DE0, X					;which side sprite (projectiles only) is coming from
CMP TB_LI_SPRITESIDE, Y			;DATA TABLE: determines which side of the sprite you're colliding with.

BNE BR_LI_GOTHIT

LDA #$06						;Load Sound Effect index for bouncing of of shield ding.

JSR SR_LIe_PLAYSE12E
								;======================================================================
								;SR_LIe_PLAYSE12E: PLAY SOUND EFFECT IN REGISTER $12E 
								;======================================================================
								;Plays the Sound Effect specified in (A) in SE reg 12E.
								;Cancelled if a Sound Effect is already playing in that register.
								;---INPUT-----
								;A		=	Sound Effect index (in Mono)
								;======================================================================

JSR SR_LIh_QUIETSPARK
								;======================================================================
								;SR_LIh_QUIETSPARK: CREATE A SPARK ANIMATION AT SPRITE WITH NO SOUND 
								;======================================================================
								;Forces a silent 'spark' animation at the sprite coordinates.
								;No sound effect.
								;======================================================================

RTS

BR_LI_NOHIT:

CLC								;Signal Link did not collide with sprite.

RTS			

BR_LI_GOTHIT:

	JSR SR_LIl_BUMPLINK
								;======================================================================
								;SR_LIl_BUMPLINK: SPRITE BUMPS LINK AND DEALS HIM DAMAGE
								;======================================================================
								;Sprite deals bump damage to Link with recoil, unless Link invincible.
								;======================================================================

SEC								;Signal Link DID collide with sprite.

RTS
}

								print "> TB_LI_SHIELDSIDE:        ",pc

TB_LI_SHIELDSIDE:

db $06, $04, $00, $00

								print "> TB_LI_SPRITESIDE:        ",pc

TB_LI_SPRITESIDE:

db $04, $06, $00, $02

								print "SR_LIa_FORCERANGE:         ",pc
								;======================================================================
								;SR_LIa_FORCERANGE: GET RANGE FOR LINK COLLISION, EVEN IF UNHITTABLE 
								;======================================================================
								;Retrieves the range of Link's coordinates, even if he can't be hit.
								;---SIMILAR FUNCTIONALITY TO----
								;$3770A-$37729
								;---OUTPUT----
								;WR-0		=	Low X coordinate for Link collision
								;WR-1		=	Low Y coordinate for Link collision
								;WR-2		=	Width (x) of range to be checked for Link
								;WR-3		=	Height (y) of range to be checked for Link
								;WR-8		=	High X coordinate for Link collision
								;WR-9		=	High Y coordinate for Link collision
								;======================================================================
SR_LIa_FORCERANGE:
{
	LDA #$08
	STA $02						;Width (x) of range to be checked for Link.
	STA $03						;Height (y) of range to be checked for Link.

	LDA $22
	CLC
	ADC #$04
	STA $00						;Low X coordinate for Link collision.

	LDA $23
	ADC #$00
	STA $08						;High X coordinate for Link collision.

	LDA $20
	ADC #$08
	STA $01						;Low Y coordinate for Link collision.

	LDA $21
	ADC #$00
	STA $09						;High Y coordinate for Link collision.

	RTS
}

								print "SR_LIb_SPRITECOORDS:       ",pc
								;======================================================================
								;SR_LIb_SPRITECOORDS: RETRIEVE COORDINATE RANGE FOR SPRITE COLLISION
								;======================================================================
								;Retrieves the range of coordinates for sprite collision.
								;Signals collision impossible with #$80 in WR-A.
								;---SIMILAR FUNCTIONALITY TO----
								;$377EF-$37835 
								;---MIRRORS---
								;SR_WEb_SPRITECOORDS
								;---OUTPUT----
								;WR-4		=	Low X coordinate for sprite collision
								;WR-5		=	Low Y coordinate for sprite collision
								;WR-6		=	Width (x) of range to be checked for sprite
								;WR-7		=	Height (y) of range to be checked for sprite
								;WR-A		=	High X coordinate for sprite collision
								;			OR #$80 if collision impossible
								;WR-B		=	High Y coordinate for sprite collision
								;======================================================================
SR_LIb_SPRITECOORDS:
{
	LDA $0F70, X				;Check the height value of the sprite.

	BMI BR_LIb_CANCEL			;If negative, branch, don't even check.

	PHY							;Push Y to stack.

	LDA $0F60, X
	AND #$1F					;Size class of sprite.
	TAY							;Transfer size class to Y, as our offset.

	LDA $0D10, X 				;The lower byte of a sprite's X - coordinate.
	CLC				
	ADC TB_LIb_LOWX, Y			;Add that with low X offset of sprite.

	STA $04						;Low x coord for sprite collision.

	LDA $0D30, X				;The high byte of a sprite's X - coordinate.
	ADC TB_LIb_HIGHX, Y			;Add that with high X offset of sprite.
	
	STA $0A						;High x coord for sprite collision.
	
	LDA $0D00, X				;The lower byte of a sprite's Y - coordinate.
	CLC
	ADC TB_LIb_LOWY, Y			;Add that with low Y offset of sprite
	
	PHP
	
	SEC
	SBC $0F70, X				;Subtract height value.
	STA $05						;Low y coord for sprite collision
	
	LDA $0D20, X				;The high byte of a sprite's Y - coordinate.
	SBC #$00					;Add that with high Y offset of sprite.
	
	PLP
	
	ADC TB_LIb_HIGHY, Y
	STA $0B						;High y coord for sprite collision

	LDA TB_LIb_XRANGE, Y
	STA $06						;Store as x range.

	LDA TB_LIb_YRANGE, Y
	STA $07						;Store as y range.

	PLY

	RTS

BR_LIb_CANCEL:

	LDA #$80			
	STA $0A						;There will not be collision.

	RTS
}

								print "> TB_LIb_LOWX:             ",pc

TB_LIb_LOWX:

db $02, $03, $00, $FD, $FA, $00, $02, $F8, $00, $FC, $F8, $00, $F8, $F0, $02, $02 	;LOW X OFFSETS
db $02, $02, $02, $F8, $02, $02, $F0, $F8, $F4, $04, $FC, $F4, $05, $E0, $FE, $04

								print "> TB_LIb_HIGHX:            ",pc

TB_LIb_HIGHX:

db $00, $00, $00, $FF, $FF, $00, $00, $FF, $00, $FF, $FF, $00, $FF, $FF, $00, $00	;HIGH X OFFSETS
db $00, $00, $00, $FF, $00, $00, $FF, $FF, $FF, $00, $FF, $FF, $00, $FF, $FF, $00

								print "> TB_LIb_XRANGE:           ",pc

TB_LIb_XRANGE:

db $0C, $01, $10, $14, $14, $08, $04, $20, $30, $18, $20, $20, $20, $30, $0C, $0C	;X RANGES
db $3C, $7C, $0C, $20, $04, $0C, $30, $20, $28, $08, $18, $18, $05, $50, $04, $08

								print "> TB_LIb_LOWY:             ",pc

TB_LIb_LOWY:

db $00, $03, $04, $FC, $F8, $02, $00, $F0, $0C, $FC, $F8, $00, $F6, $F0, $02, $02	;LOW Y OFFSETS
db $02, $02, $FD, $F4, $02, $0A, $00, $F4, $10, $04, $FC, $F4, $03, $F0, $F8, $0A

								print "> TB_LIb_HIGHY:            ",pc

TB_LIb_HIGHY:

db $00, $00, $00, $FF, $FF, $00, $00, $FF, $00, $FF, $FF, $00, $FF, $FF, $00, $00	;HIGH Y OFFSETS
db $00, $00, $FF, $FF, $00, $00, $00, $FF, $00, $00, $FF, $FF, $00, $FF, $FF, $00

								print "> TB_LIb_YRANGE:           ",pc

TB_LIb_YRANGE:

db $0E, $01, $10, $15, $18, $04, $08, $28, $14, $18, $28, $1D, $24, $30, $3C, $7C	;Y RANGES
db $0C, $0C, $11, $1C, $04, $02, $1C, $14, $0A, $04, $18, $10, $05, $30, $08, $0C

								print "SR_LIc_CHECKRANGES:        ",pc
								;======================================================================
								;SR_LIc_CHECKRANGES: DETERMINE IF THE TWO PARTIES ARE COLLIDING
								;======================================================================
								;Returns with the carry bit set if the two parties are colliding.
								;---SIMILAR FUNCTIONALITY TO----
								;$37836-$37863 
								;---MIRRORS---
								;SR_WEc_CHECKRANGES
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
SR_LIc_CHECKRANGES:
{
	PHX							;Push sprite slot to stack.

	LDX #$01					;When X is 1, doing Y part. When 0, doing X part.

LP_LIc_CHECK:

	LDA $04, X					;Low X or Y coordinate for (sprite) collision.			
	SEC
	SBC $00, X					;Low X or Y coordinate for (weapon) collision
	PHA							;Push low byte of distance between them to stack.

	PHP							;Push that processor status to stack.

	CLC
	ADC $06, X					;Width (x) or Height (y) of range to be checked for (sprite).
	STA $0F						;Store low byte of distance between them + range to be checked to WR-F.			

	PLP							;Pull processor status from stack.

	LDA $0A, X					;High X or Y coordinate for (sprite) collision.		
	SBC $08, X					;High X or Y coordinate for (weapon) collision.
	STA $0C						;Store high byte of distance between them to WR-C.

	PLA							;Pull low byte of distance between them from stack.		
	CLC
	ADC #$80					;Add #$80 to that.

	LDA $0C						;Load high byte of distance between them.
	ADC #$00					;Add carry.

	BNE BR_LIc_EXIT

	LDA $02, X					;Width (x) or Height (y) of range to be checked for (weapon).
	CLC
	ADC $06, X					;Width (x) or Height (y) of range to be checked for (sprite)
	CMP $0F

	BCC BR_LIc_EXIT				;Collision must be detected along both axies.

	DEX

	BPL LP_LIc_CHECK

BR_LIc_EXIT:

	PLX							;Pull sprite slot to stack.

	RTS
}

								print "SR_LId_SAMESIZE:           ",pc
								;======================================================================
								;SR_LId_SAMESIZE: CHECK IF LINK IS TOUCHING THE SPRITE IF SAME SIZE 
								;======================================================================
								;Carry returns clear if Link is touching sprite.
								;Sprite must be the same size as Link. (Size class 0)
								;---SIMILAR FUNCTIONALITY TO----
								;$371F6-$37227 
								;---OUTPUT----
								;CARRY		= 	Set if collision detected, Clear if not
								;======================================================================
SR_LId_SAMESIZE:
{
LDA $0F70, X					;Height value (how far the enemy is from its shadow)

STA $0C
STZ $0D							;Height value of sprite stored to WR-C&D

REP #$20						;(M:16bit)

LDA $22							;$22-$23 Link’s X-Coordinate (mirrored at $0FC2)

SEC
SBC $0FD8						;The lower byte of the current sprite's X – coordinate ($0FD9 - The upper byte of the current sprite's X – coordinate)
CLC
ADC #$000B
CMP #$0017

BCS BR_LId_NOTOUCH				;if we're not in a vertical line with the sprite, CLC and end

LDA $20							;$20-$21 Link’s Y-Coordinate (mirrored at $0FC4)
SEC
SBC $0FDA						;The lower byte of the current sprite's Y – coordinate ($0FDB - The upper byte of the current sprite's Y – coordinate)
CLC
ADC $0C
CLC
ADC #$0010
CMP #$0018

BCS BR_LId_NOTOUCH				;if we're not touching the sprite, CLC and leave

SEP #$20

SEC								;set carry if we're touching the sprite

RTS

BR_LId_NOTOUCH:

SEP #$20
CLC

RTS
}

								print "SR_LIe_PLAYSE12E:          ",pc
								;======================================================================
								;SR_LIe_PLAYSE12E: PLAY SOUND EFFECT IN REGISTER $12E 
								;======================================================================
								;Plays the Sound Effect specified in (A) in SE reg 12E.
								;Cancelled if a Sound Effect is already playing in that register.
								;---SIMILAR FUNCTIONALITY TO----
								;$6BB7C-$6BB89 
								;---MIRRORS--- 
								;SR_WEd_PLAYSE12E
								;SR_WOi_PLAYSE12E
								;---INPUT-----
								;A		=	Sound Effect index (in Mono)
								;======================================================================
SR_LIe_PLAYSE12E:
{
	PHY							;Push Y to stack.
	LDY $012E					;Load Y with SE reg 12E.
	
	BEQ BR_LIe_CANCEL			;Is there a sound effect playing in SE reg 12E?

	JSR SR_LIf_STEREOBYSPRITE
								;======================================================================
								;SR_LIf_STEREOBYSPRITE: RETURN SOUND EFFECT TYPE IN STEREO
								;======================================================================
								;Returns the Sound Effect type in stereo. (Both, Right, or Left).
								;---INPUT----
								;A		=	Sound Effect index (in Mono)
								;---OUTPUT----
								;A		=	Sound Effect type in Stereo (Both, Right, or Left)
								;======================================================================

	STA $012E					;Play sound effect in SE reg 12E.

BR_LIe_CANCEL:

	PLY							;Get Y back off of stack.

	RTS	
}

								print "SR_LIf_STEREOBYSPRITE:     ",pc
								;======================================================================
								;SR_LIf_STEREOBYSPRITE: RETURN SOUND EFFECT TYPE IN STEREO
								;======================================================================
								;Returns the Sound Effect type in stereo (Both, Right, or Left).
								;---SIMILAR FUNCTIONALITY TO----
								;6BB98-$6BBA0 
								;---MIRRORS--- 
								;SR_WEe_STEREOBYSPRITE
								;SR_WOj_STEREOBYSPRITE
								;---INPUT-----
								;A		=	Sound Effect index (in Mono)
								;---OUTPUT----
								;A		=	Sound Effect type in Stereo (Both, Right, or Left)
								;======================================================================
SR_LIf_STEREOBYSPRITE:
{
	STA $0D						;Store the sound effect index here temporarily.
	
	JSR SR_LIg_POLBYSPRITE
								;======================================================================
								;SR_LIg_POLBYSPRITE: RETURN SOUND EFFECT POLARITY BY SPRITE POSITION
								;======================================================================
								;Returns #$00 if Sound Effect should occur on both speakers.
								;Returns #$40 if Sound Effect should occur on only right speaker.
								;Returns #$80 if Sound Effect should occur on only left speaker.
								;This is determined by sprite's horizontal position on screen.
								;---OUTPUT----
								;A		=	Sound Effect Polarity (#$00-BOTH #$40-R #$80-L)
								;======================================================================
	
	ORA $0D						;Polarity + SE index = SE type in stereo.
	
	RTS
}

								print "SR_LIg_POLBYSPRITE:        ",pc
								;======================================================================
								;SR_LIg_POLBYSPRITE: RETURN SOUND EFFECT POLARITY BY SPRITE POSITION
								;======================================================================
								;Returns #$00 if Sound Effect should occur on both speakers.
								;Returns #$40 if Sound Effect should occur on only right speaker.
								;Returns #$80 if Sound Effect should occur on only left speaker.
								;This is determined by sprite's horizontal position on screen.
								;---SIMILAR FUNCTIONALITY TO----
								;$6BBA1-$6BBC7 
								;---MIRRORS--- 
								;SR_WEf_POLBYSPRITE
								;SR_WOk_POLBYSPRITE
								;---OUTPUT----
								;A		=	Sound Effect Polarity (#$00-BOTH #$40-R #$80-L)
								;======================================================================
SR_LIg_POLBYSPRITE:
{
	LDA $0D30, X				;The high byte of a sprite's X - coordinate.		
	XBA	

	LDA $0D10, X				;The lower byte of a sprite's X - coordinate.

	REP #$20					;(M:16bit)

	PHX							;Push sprite slot to stack.
	
	LDX #$00					;Starting x off with zero.
	
	SEC
	SBC $E2						;Subtract the X coordinate of the scroll register for Layer 2. 
						
	SEC
	SBC #$0050
	
	CMP #$0050					;Are coordinates in the middle of the screen?

	BCC BR_LIg_POLARITY			;If yes, branch, SE plays on BOTH sides at once.

	INX							;SE only plays on one side.
	CMP #$0000
	
	BMI BR_LIg_POLARITY			;If A is negative, then branch. SE will play on left.

	INX							;SE will play on right.
	
BR_LIg_POLARITY:

	SEP #$20					;(M:8bit)

	LDA TB_LIg_POLARITY, X		;Load Sound Effect Polarity (offset).	
	
	PLX							;Pull sprite slot back.
	
	RTS
}

								print "> TB_LIg_POLARITY:         ",pc

TB_LIg_POLARITY:

db $00, $80, $40				; (#$00-BOTH #$40-R #$80-L)

								print "SR_LIh_QUIETSPARK:         ",pc
								;======================================================================
								;SR_LIh_QUIETSPARK: CREATE A SPARK ANIMATION AT SPRITE WITH NO SOUND 
								;======================================================================
								;Forces a silent 'spark' animation at the sprite coordinates.
								;No sound effect.
								;---SIMILAR FUNCTIONALITY TO----
								;$376D5-$37704  
								;======================================================================
SR_LIh_QUIETSPARK:
{
	LDA $0D10, X	 			;The lower byte of a sprite's X - coordinate
	CMP $E2						;LOW BYTE OF BG1 horizontal scroll register ($210D)

	LDA $0D30, X				;The high byte of a sprite's X - coordinate.
	SBC $E3						;HIGH BYTE OF BG1 horizontal scroll register ($210D)

	BNE BR_LIh_CANCEL

	LDA $0D00, X			;The lower byte of a sprite's Y - coordinate
	CMP $E8					;$E8-$E9 BG1 vertical scroll register ($210E)

	LDA $0D20, X			;The high byte of a sprite's Y - coordinate.
	SBC $E9					;$E8-$E9 BG1 vertical scroll register ($210E)

	BNE BR_LIh_CANCEL

	LDA $0D10, X			;The lower byte of a sprite's X - coordinate
	STA $0FAD				;"Collision spark" x coordinate
	
	LDA $0D00, X			;The lower byte of a sprite's Y - coordinate
	STA $0FAE				;"Collision spark" y coordinate

	LDA #$05
	STA $0FAC				;Create a "Collision spark"

	LDA $0F20, X
	STA $0B68				;Which BG layer to draw the spark on

BR_LIh_CANCEL:

	RTS
}

							print "SR_LIi_PLAYSE12F:          ",pc
							;======================================================================
							;SR_LIi_PLAYSE12F: PLAY SOUND EFFECT IN REGISTER $12F
							;======================================================================
							;Plays the Sound Effect specified in (A) in SE reg 12F.
							;Cancelled if a Sound Effect is already playing in that register.
							;---SIMILAR FUNCTIONALITY TO----
							;$6BB8A-$6BB97 
							;---MIRRORS--- 
							;SR_WEt_PLAYSE12F
							;SR_WOp_PLAYSE12F
							;---INPUT-----
							;A		=	Sound Effect index (in Mono)
							;======================================================================
SR_LIi_PLAYSE12F:
{
	PHY						;Push Y to stack.
	LDY $012F				;Load Y with SE reg 12F.
	
	BEQ BR_LIi_CANCEL		;Is there a sound effect playing in SE reg 12F?

	JSR SR_LIf_STEREOBYSPRITE
							;======================================================================
							;SR_LIf_STEREOBYSPRITE: RETURN SOUND EFFECT TYPE IN STEREO
							;======================================================================
							;Returns the Sound Effect type in stereo. (Both, Right, or Left).
							;---INPUT----
							;A		=	Sound Effect index (in Mono)
							;---OUTPUT----
							;A		=	Sound Effect type in Stereo (Both, Right, or Left)
							;======================================================================

	STA $012F				;Play sound effect in SE reg 12F.

BR_LIi_CANCEL:

	PLY						;Get Y back off of stack.

	RTS	
}

							print "SR_LIl_BUMPLINK:           ",pc
							;======================================================================
							;SR_LIl_BUMPLINK: SPRITE BUMPS LINK AND DEALS HIM DAMAGE
							;======================================================================
							;Sprite deals bump damage to Link with recoil, unless Link invincible.
							;---SIMILAR FUNCTIONALITY TO----
							;$373DB-$3741E 
							;---MIRROR----
							;SR_WEk_BUMPLINK
							;======================================================================
SR_LIl_BUMPLINK:
{
	LDA $031F				;Is Link temporarily invincible?
	ORA $037B				;Is Link unhittable?

	BNE BR_LIl_CANCEL		;If Link isn't hittable, branch, we're not doing this.

	LDA #$13			
	STA $46					;Timer preventing Link's movement until it runs down.

	LDA #$18				;We're going to send Link recoiling away at this velocity.

	JSR SR_LIm_LINKRECOIL
							;======================================================================
							;SR_LIm_LINKRECOIL: SEND LINK RECOILING AWAY FROM SPRITE
							;======================================================================
							;Uses the single value in (A) to send Link recoiling away from sprite.
							;---INPUT-----
							;A		=	Link's recoil velocity (single value)
							;======================================================================

	LDA #$01
	STA $4D					;Set Link's state to recoil. 

	LDA $0CD2, X			;Sprite's bump damage class. (0-9 are valid)
	AND #$0F				;A: 0000 BBBB -- B = bump damage class.

	STA $00			
	ASL				
	ADC $00					;Basically multiplied bump damage class by 3.

	CLC
	ADC $7EF35B				;Add in Link's armor value, to form our offset.
	
	TAY						;Now it's in Y as our offset.	

	LDA TB_LIl_BUMPDAM, Y	;Damage Link takes by tunic and bump damage.
	STA $0373				;Damage dealt to Link.

BR_LIl_CANCEL:

	RTS
}

							print "> TB_LIl_BUMPDAM:          ",pc

TB_LIl_BUMPDAM:

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

							print "SR_LIm_LINKRECOIL:         ",pc
							;======================================================================
							;SR_LIm_LINKRECOIL: SEND LINK RECOILING AWAY FROM SPRITE
							;======================================================================
							;Uses the single value in (A) to send Link recoiling away from sprite.
							;---SIMILAR FUNCTIONALITY TO----
							;$37688-$3769E
							;---MIRROR----
							;SR_WEl_LINKRECOIL
							;---INPUT-----
							;A		=	Link's recoil velocity (single value)
							;======================================================================
SR_LIm_LINKRECOIL:
{
	PHA 					;Push Link's recoil velocity to the stack.

	JSR SR_LIn_TARGETLINK
							;======================================================================
							;SR_LIn_TARGETLINK: TARGET LINK WITH DESIRED TARGETING VELOCITY 
							;======================================================================
							;Uses the single value in (A) to output converted X and Y velocities.
							;---INPUT-----
							;A		=	Desired targeting velocity
							;---OUTPUT----
							;WR-0		=	Converted Y velocity to target Link
							;WR-1		=	Converted X velocity to target Link
							;======================================================================

	LDA $00					;Converted Y velocity to target Link.	
	STA $27					;Link's Recoil for horizontal collisions.

	LDA $01					;Converted X velocity to target link.
	STA $28					;Link's Recoil for vertical collisions.
	
	PLA						;Pull Link's recoil velocity from the stack.
	LSR
	STA $29					;Possibly Z velocity for Link when recoiling jumping?
	STA $C7					

	STZ $24			
	STZ $25					
	
	RTS
}

							print "SR_LIn_TARGETLINK:         ",pc
							;======================================================================
							;SR_LIn_TARGETLINK: TARGET LINK WITH DESIRED TARGETING VELOCITY 
							;======================================================================
							;Uses the single value in (A) to output converted X and Y velocities.
							;---SIMILAR FUNCTIONALITY TO----
							;$36991-$36A03 
							;---MIRROR----
							;SR_WEm_TARGETLINK
							;---INPUT-----
							;A		=	Desired targeting velocity (single value)
							;---OUTPUT----
							;WR-0		=	Converted Y velocity to target Link
							;WR-1		=	Converted X velocity to target Link
							;======================================================================
SR_LIn_TARGETLINK:
{
	STA $01					;Store desired targeting velocity to WR-1
	CMP #$00				;Is it zero?

	BNE BR_LIn_CONTINUE		;If nonzero, branch, we're doing this.

	STZ $00					;If zero, zero out Y velocity as well.

	RTS

BR_LIn_CONTINUE:

	PHX						;Push sprite slot to stack.
	PHY						;Push value in Y to stack, whatever.

	JSR SR_LIo_TOLINKVERT
							;======================================================================
							;SR_LIo_TOLINKVERT: FIND DIRECTION/DISTANCE TO LINK VERTICALLY
							;======================================================================
							;Finds the direction and distance to Link vertically.
							;---OUTPUT----
							;Y		=	0 if Link below; 1 if Link above.
							;A		=	High byte of distance to Link vertically.
							;WR-E		=	Low byte of distance to Link vertically.
							;======================================================================

	STY $02					;Store 0 if Link below; 1 if Link above WR-2.

	LDA $0E					;Load low byte of distance to Link vertically.

	BPL BR_LIn_ABSVALUE

	EOR #$FF
	INC						;Absolute value of A.

BR_LIn_ABSVALUE:

	STA $0C					;Store positive low byte of distance to Link vertically to WR-C.

	JSR SR_LIp_TOLINKHORIZ
							;======================================================================
							;SR_LIp_TOLINKHORIZ: FIND DIRECTION/DISTANCE TO LINK HORIZONTALLY
							;======================================================================
							;Finds the direction and distance to Link horizontally.
							;---OUTPUT----
							;Y		=	0 if Link to right; 1 if Link to left.
							;A		=	High byte of distance to Link horizontally.
							;WR-F		=	Low byte of distance to Link horizontally.
							;======================================================================

	STY $03					;Store 0 if Link to right; 1 if Link to left in WR-3

	LDA $0F					;Load low byte of distance to Link horizontally.

	BPL BR_LIn_ABSVALUE2

	EOR #$FF
	INC						;Absolute value of A.

BR_LIn_ABSVALUE2:

	STA $0D					;Store positive low byte of distance to Link horizontally to WR-D.
	
	LDY #$00				;Zero out Y.
	LDA $0D					;Load positive low byte of distance to Link horizontally.		
	CMP $0C					;Is Link closer vertically than horizontally?

	BCS BR_LIn_CLOSERVERT	;If yes, branch.

	INY						;Increment Y, to show he's closer horizontally.
	PHA						;Push the positive low byte of the distance to Link horizontally to stack.

	LDA $0C			
	STA $0D					;Store positive low byte of distance to Link vertically in WR-D instead.

	PLA						;Pull the positive low byte of the distance to Link horizontally from stack. 
	STA $0C					;Store the positive low byte of the distance to Link horizontally to WR-C.

BR_LIn_CLOSERVERT:

	STZ $0B					;Zero out WR-B to keep up with cumulative WR-C distance.
	STZ $00					;Zero out WR-0 to count how many times we subtract WR-D from WR-C.

	LDX $01					;Load X with desired targeting velocity.

LP_LIn_FORMRATIO:

	LDA $0B					;Cumulative WR-C distance from last time.
	CLC
	ADC $0C					;Add WR-C distance, forming cumulative WR-C distance.

	CMP $0D					;Is it smaller than (or equal to) WR-D distance?

	BCC BR_LIn_NOINC		;If it is smaller than or equal to, branch without subtracting or incrementing WR-0. 

	SBC $0D					;If WR-C distance greater, subtract the WR-D distance.
	INC $00					;And increment WR-0, the smaller part of our ratio.
	
BR_LIn_NOINC:

	STA $0B					;Store cumulative WR-C distance.
	DEX						;Subtract desired targeting velocity (large part of ratio).

	BNE LP_LIn_FORMRATIO	;If we're not done, continue the loop.

	TYA						;0 = closer vertically, 1 = closer horizontally.

	BEQ BR_LIn_NOSWAP		;If closer horizontally, branch, we don't need to swap the velocities.

	LDA $00					;How many times we had to subtract vertical distance from horizontal distance.
	PHA						;Push that to stack.

	LDA $01					;Load desired targeting velocity (large part of ratio).
	STA $00					;Store as the (positive) converted Y velocity to target Link.				

	PLA						;Load small part of ratio.
	STA $01					;Store as the (positive) converted X velocity to target Link.

BR_LIn_NOSWAP:
	
	LDA $00					;Load the (positive) converted Y velocity to target Link.
	LDY $02					;Is Link below the sprite?

	BEQ BR_LIn_BELOW		;If Link below, branch, we keep the positive value.

	EOR #$FF
	INC						;Make the value negative.

	STA $00					;Store (negative) converted Y velocity to target Link.

BR_LIn_BELOW:

	LDA $01					;Load the (positive) converted X velocity to target Link
	LDY $03					;Is Link to the right of the sprite?

	BEQ BR_LIn_ABOVE		;If Link to right, branch, we keep the positive value.

	EOR #$FF
	INC						;Make the value negative.

	STA $01					;Store (negative) converted X velocity to target Link.

BR_LIn_ABOVE:

	PLY						;Pull value in Y from stack, whatever.
	PLX						;Pull sprite slot from stack.

	RTS
}

							print "SR_LIo_TOLINKVERT:         ",pc
							;======================================================================
							;SR_LIo_TOLINKVERT: FIND DIRECTION/DISTANCE TO LINK VERTICALLY
							;======================================================================
							;Finds the direction and distance to Link vertically.
							;---SIMILAR FUNCTIONALITY TO----
							;36AE8-$36B09 
							;---MIRRORS--- 
							;SR_WEn_TOLINKVERT
							;---OUTPUT----
							;Y		=	0 if Link below; 1 if Link above.
							;A		=	High byte of distance to Link vertically.
							;WR-E		=	Low byte of distance to Link vertically.
							;======================================================================
SR_LIo_TOLINKVERT:
{
	LDY #$00
	LDA $20					;Load the lower byte of Link's Y coordinate.
	CLC				
	ADC #$08				;Add #$08 to that.

	PHP						;Push processor status to stack.

	CLC				
	ADC $0F70, X			;Add the sprite's altitude.

	PHP						;Push processor status to stack.

	SEC				
	SBC $0D00, X			;Subtract the lower byte of the sprite's Y coordinate.
	STA $0E					;Store the difference between the two coordinates to WR-E.
	
	LDA $21					;Load the high byte of Link's Y coordinate.
	SBC $0D20, X			;Subtract the high byte of the sprite's Y coordinate. 

	PLP						;Pull processor status from stack.

	ADC #$00				;Add carry from adding sprite's altitude.

	PLP						;Pull processor status from stack.

	ADC #$00				;Add carry from adding #$08 earlier.
	
	BPL BR_LIo_LINKBELOW	;If Link is below the sprite, branch.

	INY						;If Link is above the sprite, increment Y.

BR_LIo_LINKBELOW:

	RTS
}

							print "SR_LIp_TOLINKHORIZ:        ",pc
							;======================================================================
							;SR_LIp_TOLINKHORIZ: FIND DIRECTION/DISTANCE TO LINK HORIZONTALLY
							;======================================================================
							;Finds the direction and distance to Link horizontally.
							;---SIMILAR FUNCTIONALITY TO----
							;$36AD1-$36AE3
							;---MIRRORS--- 
							;SR_WEo_TOLINKHORIZ
							;---OUTPUT----
							;Y		=	0 if Link to right; 1 if Link to left.
							;A		=	High byte of distance to Link horizontally.
							;WR-F		=	Low byte of distance to Link horizontally.
							;======================================================================
SR_LIp_TOLINKHORIZ:
{
	LDY #$00
	
	LDA $22 				;Load the lower byte of Link's X coordinate.
	SEC
	SBC $0D10, X			;Subtract low byte of the sprite's coordinate.
	STA $0F					;Store the difference at WR-F.
	
	LDA $23					;Load the high byte of Link's X coordinate.
	SBC $0D30, X			;Subtract high byte of the sprite's coordinate.
	
	BPL BR_LIp_LINKTORIGHT	;If Link is to the right of the sprite, branch.

	INY						;If Link is to the left, then increment Y.

BR_LIp_LINKTORIGHT:

	RTS
}

							print "SR_LIs_BREAKSPRITE:        ",pc
							;======================================================================
							;SR_LIs_BREAKSPRITE: GIVE BREAKABLE SPRITE (EX. BUSH) ANIMATED DEATH
							;======================================================================
							;Gives the bush/rock/sign etc. an animated normal death.
							;---SIMILAR FUNCTIONALITY TO----
							;$3625A-$3626D 
							;---MIRROR--- 
							;SR_WEw_BREAKSPRITE
							;SR_WOs_BREAKSPRITE
							;======================================================================
SR_LIs_BREAKSPRITE:
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

							print "----------------------------------------------"
							print "SR_LI_LINKvSPRITE.ASM ENDS AT ",pc," (MINUS 1)"
