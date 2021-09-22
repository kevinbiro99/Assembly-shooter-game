#####################################################################
#
# CSCB58 Summer2021Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Kevin Biro, 1006930396, birokevi
# 
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 256
# - Display width in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
# 
# Which milestones have been reached in this submission?
# Milestone 1,2,3
#
# Which approved features have been implementedfor milestone 3?
# 1. Scoring system based on number of obstacles that get removed
# 2. Increase difficulty as game progresses. Obstacles move faster, spawn faster, different types of obstacles spawn.
# 3. Pick-ups that the ship can pick up: repair the ship, make enemies slower
# 
# Link to video demonstration for final submission
# - https://drive.google.com/file/d/1ISUuDxqyIWQJ21p_3mekg-_DtvFlVQ_X/view?usp=sharing
# 
# Are you OK with us sharing the video with people outside course staff?
# no
#
# Additional information:
# Keyboard input: w(up), a(left), s(down), d(down), p(restart game), k(kill player), esc(terminate program)
#
#####################################################################
STARTGAME:
.data
str: 	.asciiz 	" \n"
displayAddress: .word 	0x10008000
shipx:		.word	32
shipy: 		.word	32
xmult:		.word	4
ymult:		.word	256
delImage:	.word	0
rockXY:		.space	312		#space for 26 rocks
currX:		.word	0		#rock x used when drawing image
currY:		.word 	0		#rock y used when drawing image
currT:		.word	0		#rock type
currRockOffset:	.word	0		#keep track of current rock when updating position of rocks
numRocks:	.word	25		#max number of rocks
clock:		.word	0
spawnTimer:	.word	0
score:		.word	0
score1:		.word	0		#changes the speed that the rocks spawn and move
score2:		.word	0
score3:		.word	0
hit:		.word	0
health: 	.word	10
poisoned:	.word	0
spawnTime:	.word	1000

shipHitCounter:	.word	0
.text

lw $t0, displayAddress # $t0 stores the base address for display
#li $t1, 0xff0000 # $t1 stores the red colour code
#li $t2, 0x00ff00 # $t2 stores the green colour code
li $t3, 0x0000ff # $t3 stores the blue colour code
#li $t9, 0xffff00 # $t9 stores the yellow colour code

#clear array of rocks

addi $t0, $zero, 32
sw $t0, shipx
sw $t0, shipy
addi $t0, $zero, 1000
sw $t0, spawnTime
addi $t0, $zero, 25
sw $t0, health
add $t0, $zero, $zero
sw $t0, shipHitCounter
sw $t0, hit
sw $t0, score
sw $t0, score1
sw $t0, score2
sw $t0, score3
sw $t0, poisoned

clearArray:
	bge $t0, 300, setupScreen
	la $t8, rockXY
	add $t8, $t8, $t0
	sw $zero, 0($t8)
	addi $t0, $t0, 4
j clearArray
#clear screen
setupScreen:
	li $t3, 0x000000
	add $t0, $zero, $zero
	jal clearLoop		#clears the screen
jal DRAWHEALTH
jal UPDATESCORE
#generate random asteroids
SPAWNROCK:
	add $t1, $zero, $zero
spawnLoop:	
	bge $t1, 300, UPDATEROCK #if array is full
	la $t8, rockXY
	add $t8, $t8, $t1
	lw $t3, 4($t8)		#check if x <=0
	bgt $t3, $zero increment	#skip current rock if occupied
	
	li $v0, 42
	li $a0, 0
	li $a1, 54
	syscall			#get random number
	add $a0, $a0, 5		#radius of meteor is 5 pixels
	
	sw $a0, 0($t8)		#store 1 random rock for now
	addi $a0, $zero, 60
	sw $a0, 4($t8)
	#generate rock type
	lw $t2, score
	li $a0, 0
	li $a1, 75
	syscall
	bgt $a0, 67, HP
	bne $a0, 12, SROCK
	addi $a0, $zero, 5
	sw $a0, 8($t8)
	j UPDATEROCK
HP:	addi $a0, $zero, 4
	sw $a0, 8($t8)
	j UPDATEROCK
SROCK:	bgt $t2, 25, LEVEL1
	li $a1, 1
	j temp1
LEVEL1: 
	bgt $t2, 75, LEVEL2
	li $a1, 2
	j temp1
LEVEL2:	li $a1, 3		#only allow type3 rocks to spawn after player reaches score of 50
temp1:	syscall			#get random number
	addi $a0, $a0, 1
	sw $a0, 8($t8)
	#lw $t2, numRocks
	#addi $t2, $t2, 1
	#sw $t2 numRocks
	j UPDATEROCK	#only spawn one rock per cycle
increment:
	addi $t1, $t1, 12
	j spawnLoop
	#j UPDATEROCK

UPDATEROCK:
	addi $t0, $zero, 2
	lw $t6, score
	mult $t6, $t0
	mflo $t6
	lw $t0, clock
	lw $t3, spawnTimer
	#lw $t6, score		#determines rock speed
	lw $t7, spawnTime
	#addi $t7, $zero, 1500	#start speed
	sub $t7, $t7, $t6	#updated speed
	
	addi $t0, $t0, 1
	sw $t0, clock
	lw $t6, score3
	addi $t8, $zero, 8
	sub $t6, $t8, $t6
	#sub $t3, $t3, $t6	#subtract 1 from spawn timer every 100 points
	bgt $t3, $t6, SPAWN
	j RIMAGE
SPAWN:
	add $t3, $zero, $zero
	sw $t3, spawnTimer
	lw $t8, shipHitCounter		#timer for ship hits (to change colour)
	addi $t8, $t8, 1
	sw $t8, shipHitCounter
	bgt $t8, 3, resetHit
	j noResetHit
resetHit:
	add $t8, $zero, $zero
	sw $t8, shipHitCounter
	sw $t8, hit		#reset the ship hit
	sw $t8, poisoned
noResetHit:
	j SPAWNROCK
RIMAGE:		
	blt $t0, $t7, LOOP
	addi $t3, $t3, 1
	sw $t3, spawnTimer	#increase spawnTimer
	add $t0, $zero, $zero
	sw $t0, clock			#reset clock
	add $t1, $zero, $zero
	sw $t1, currRockOffset
	

LOOPROCK:
	lw $t1, currRockOffset
	
	lw $t2, numRocks
	addi $t6, $zero, 12
	mult $t2, $t6
	mflo $t2		#$t1 counts in increments of 8, so match $t2's scale (8 per rock)
	
	la $t8, rockXY
	add $t8, $t8, $t1
	bgt $t1, $t2, ENDROCK
	lw $t3, 0($t8)		#load y val
	lw $t4, 4($t8)		#load x val
	lw $t9, 8($t8)		#load type
	beqz $t3, temp
	ble $t4, 3, removeRock	#rock reached left side of screen (remove)
	
	sw $t3, currY
	sw $t4, currX
	sw $t9, currT
	
	#check collision to player
	jal distance
	
	lw $t5, delImage
	addi $t5, $zero, 1	#reset rock image
	sw $t5, delImage
	jal DRAWROCK
	
	lw $t5, delImage
	add $t5, $zero, $zero	#set colour back to display updated image
	sw $t5, delImage
	
	lw $t3, currY	#load y val again since DRAW uses $t3
	lw $t4, currX
	
	lw $t9, currT
	bgt $t9, 3, slow
	j normal
slow:	addi $t9, $zero, 1
normal:	sub $t4, $t4, $t9	#move rock left
	
	la $t8, rockXY
	lw $t1, currRockOffset
	add $t8, $t8, $t1
	sw $t3, 0($t8)			#technocally, y val wont change (for now)
	sw $t4, 4($t8)			#save current position in array (loop gets val from array)
	
	sw $t3, currY		#save updated coordinates for draw
	sw $t4, currX
	jal DRAWROCK
temp:	
	lw $t1, currRockOffset
	addi $t1, $t1, 12
	sw $t1, currRockOffset
	j LOOPROCK
ENDROCK:
	j LOOP
removeRock:	#erases from screen and updates array to 0,0
	#t3=y,t4=x
	#draw over rock
	lw $t3, 0($t8)		#load y val
	lw $t4, 4($t8)		#load x val
	lw $t9, 8($t8)		#load type
	sw $t3, currY
	sw $t4, currX
	sw $t9, currT
	lw $t5, delImage
	addi $t5, $zero, 1	#reset rock image
	sw $t5, delImage
	jal DRAWROCK
	lw $t5, delImage
	add $t5, $zero, $zero	#set colour back to display updated image
	sw $t5, delImage
	
	la $t8, rockXY
	lw $t1, currRockOffset
	add $t8, $t8, $t1
	
	add $t3, $zero, $zero
	add $t4, $zero, $zero
	sw $t3, 0($t8)		#remove y val
	sw $t4, 4($t8)		#remove x val
	#increase score
	lw $t3, score
	addi $t3, $t3, 1
	sw $t3, score
	lw $t3, score1
	beq $t3, 9, RS1
	addi $t3, $t3, 1
	sw $t3, score1
	jal UPDATESCORE
	j temp
RS1:	add $t3, $zero, $zero
	sw $t3, score1
	lw $t3, score2
	beq $t3, 9, RS2
	addi $t3, $t3, 1
	sw $t3, score2
	jal UPDATESCORE
	j temp
RS2:	add $t3, $zero, $zero
	sw $t3, score2
	lw $t3, score3
	addi $t3, $t3, 1
	sw $t3, score3
	jal UPDATESCORE
	j temp #go to next rock
#********************************************************
#MAIN LOOP
LOOP:				
	li $t9, 0xffff0000	#keyboard
	lw $t8 0($t9)		# whether key is pressed
	beq $t8, 1, KEYPRESSED
NKEY:
	lw $t5, delImage
	add $t5, $zero, $zero	#set colour back to display updated image
	sw $t5, delImage
	jal DRAW
donedraw:
	j UPDATEROCK
	#j LOOP

KEYPRESSED: 
	lw $t4, 4($t9)	#get the key pressed
	beq $t4, 0x61, respond_to_a	#a is pressed
	beq $t4, 0x77, respond_to_w	#w is pressed
	beq $t4, 0x73, respond_to_s	#s is pressed
	beq $t4, 0x64, respond_to_d	#d is pressed
	beq $t4, 0x6B, respond_to_k	#in case you want to kill yourself
	beq $t4, 0x70 respond_to_p	#restart game
	beq $t4, 0x1B, EXIT	#esc is pressed
donekey:
	j NKEY

respond_to_a:
	#decrease x value by 1 if not at left edge (shipx > 0)
	lw $t4, shipx
	ble $t4, 3, donekey	#check if ship is out of bounds (ship radius = 1)	
	lw $t5, delImage	#set to black to delete ship
	addi $t5, $zero, 1	
	sw $t5, delImage
	jal DRAW
	addi $t4, $t4, -1
	sw $t4, shipx
	j donekey
respond_to_w:
	lw $t4, shipy
	ble $t4, 7, donekey	#check if ship is out of bounds (ship radius = 1)
	lw $t5, delImage	#set to black to delete ship
	addi $t5, $zero, 1	
	sw $t5, delImage
	jal DRAW
	addi $t4, $t4, -1
	sw $t4, shipy
	j donekey
respond_to_s:
	lw $t4, shipy
	bgt $t4, 58, donekey	#check if ship is out of bounds (ship radius = 1)
	lw $t5, delImage	#set to black to delete ship
	addi $t5, $zero, 1	
	sw $t5, delImage
	jal DRAW
	addi $t4, $t4, 1
	sw $t4, shipy
	j donekey
respond_to_d:
	lw $t4, shipx
	bgt $t4, 59, donekey	#check if ship is out of bounds (ship radius = 1)
	lw $t5, delImage	#set to black to delete ship
	addi $t5, $zero, 1	
	sw $t5, delImage
	jal DRAW
	addi $t4, $t4, 1
	sw $t4, shipx
	j donekey
respond_to_k:
	j GAMEOVER
respond_to_p:
	j STARTGAME

#draw basic outline of ship
DRAW:
	lw $t2, delImage	# 1 = delete image
	beq $t2, 1, NOCOLOUR
	j COLOUR
NOCOLOUR: 
	li $t3, 0x000000
	li $t5, 0x000000
	j STARTDRAW
COLOUR: 
	lw $t1, hit
	beq $t1, 1, COLOURHIT
	li $t5, 0xffff00 # $t9 stores the yellow colour code
	li $t3, 0x0000ff # blue
	j STARTDRAW
COLOURHIT:
	li $t5, 0xffA500 # $t9 stores the yellow colour code
	li $t3, 0xff0000 # blue
STARTDRAW:
	lw $t6, ymult		# next memory location down
	lw $t7, xmult		# next memory location across
	lw $t8, shipx
	lw $t9, shipy
	mult $t8, $t7
	mflo $t8
	mult $t9, $t6
	mflo $t9
	add $t8, $t8, $t9	#holds memory location of x,y coordinate
	
	lw $t0, displayAddress
	add $t0, $t8, $t0	#load player location
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, 8($t0)
	sw $t5, 12($t0)		#yellow
	
	sw $t3, -4($t0)
	sw $t3, -8($t0)
	sw $t5, -12($t0)	#yellow
	
	sw $t3, 256($t0)
	sw $t3, -256($t0)
	
	sw $t3, 260($t0)
	sw $t3, -252($t0)
	sw $t3, 264($t0)
	sw $t3, -248($t0)
	
	sw $t3, 252($t0)
	sw $t3, -260($t0)
	sw $t3, 248($t0)
	sw $t3, -264($t0)
	sw $t5, 244($t0)	#yellow
	sw $t5, -268($t0)	#yellow
	
	sw $t3, 504($t0)
	sw $t3, 760($t0)
	sw $t3, 1016($t0)
	sw $t5, 1020($t0)	#yellow
	sw $t5, 1024($t0)	#yellow

	sw $t3, -520($t0)
	sw $t3, -776($t0)
	sw $t3, -1032($t0)
	sw $t5, -1028($t0)	#yellow
	sw $t5, -1024($t0)	#yellow

	jr $ra			#jump back to call

DRAWROCK:
	lw $t4, currT
	lw $t2, delImage	# 1 = delete image

	lw $t4, currT
	beq $t2, 1, NOCOLOUR2
	lw $t2, poisoned
	beq $t2, 1, GREENCOLOUR
	j COLOUR2
NOCOLOUR2:
	li $t3, 0x000000
	j STARTDRAW2
GREENCOLOUR:
	li $t3, 0x81B622
	lw $t2, delImage
	j STARTDRAW2
COLOUR2:
	li $t3, 0xA8A8A8
STARTDRAW2:
	lw $t6, ymult		# next memory location down
	lw $t7, xmult		# next memory location across
	lw $t8, currX
	lw $t9, currY
	mult $t8, $t7
	mflo $t8
	mult $t9, $t6
	mflo $t9
	add $t8, $t8, $t9	#holds memory location of x,y coordinate
	
	lw $t0, displayAddress
	add $t0, $t8, $t0	#load rock location
	
	beq $t4, 1, rock1
	beq $t4, 2, rock3
	beq $t4, 3, rock2
	beq $t4, 4, healthPickup
	beq $t4, 5, slowEnemies
rock1:
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, 8($t0)
	sw $t3, -4($t0)
	sw $t3, -8($t0)
	
	sw $t3, -252($t0)
	sw $t3, 260($t0)
	sw $t3, 256($t0)
	sw $t3, -256($t0)
	sw $t3, -260($t0)
	sw $t3, 252($t0)
	sw $t3, -512($t0)
	sw $t3, 512($t0)
	jr $ra
rock2:
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, -4($t0)
	sw $t3, 256($t0)
	sw $t3, -256($t0)
	jr $ra
rock3:
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, -4($t0)
	sw $t3, 256($t0)
	sw $t3, -256($t0)
	sw $t3, -260($t0)
	sw $t3, 260($t0)
	jr $ra
healthPickup:
	beq $t2, 1, removeHealthPickup
	li $t3, 0xffffff
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, -4($t0)
	sw $t3, 256($t0)
	sw $t3, -256($t0)
	li $t3, 0xff0000
	sw $t3, 252($t0)
	sw $t3, 260($t0)
	sw $t3, -252($t0)
	sw $t3, -260($t0)
	jr $ra
removeHealthPickup:
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, -4($t0)
	sw $t3, 256($t0)
	sw $t3, -256($t0)
	sw $t3, 252($t0)
	sw $t3, 260($t0)
	sw $t3, -252($t0)
	sw $t3, -260($t0)
	jr $ra
slowEnemies:
	beq $t2, 1, removeSlowPickup
	li $t3, 0x00ff00
	sw $t3, 0($t0)
	sw $t3, 256($t0)
	sw $t3, 260($t0)
	sw $t3, 252($t0)
	li $t3, 0x007500
	sw $t3, 4($t0)
	sw $t3, -4($t0)
	sw $t3, -256($t0)
	sw $t3, -252($t0)
	sw $t3, -260($t0)
	jr $ra
removeSlowPickup:
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, -4($t0)
	sw $t3, 256($t0)
	sw $t3, -256($t0)
	sw $t3, 252($t0)
	sw $t3, 260($t0)
	sw $t3, -252($t0)
	sw $t3, -260($t0)
	jr $ra
	
GAMEOVER:
	#clear screen
	li $t3, 0x000000
	add $t0, $zero, $zero
	jal clearLoop
	j drawGameOver
clearLoop:
	bge $t0, 16384, jumpBack
	lw $t1, displayAddress
	add $t1, $t1, $t0
	sw $t3, 0($t1)
	addi $t0, $t0, 4
	j clearLoop
jumpBack:	jr $ra
drawGameOver:

	#li $v0, 1		#debug (display score)
	#lw $a0, score
	#move $a0, $t2
	#syscall
	#li $v0, 4
	#la $a0, str
	#syscall
	jal UPDATESCORE
	#now draw the game over screen
	li $t3, 0xFFFFFF
	lw $t0, displayAddress
	#G
	#sw $t3, 8064($t0)	#middle of screen
	sw $t3, 6752($t0)
	sw $t3, 6756($t0)
	sw $t3, 6760($t0)
	sw $t3, 7004($t0)
	sw $t3, 7260($t0)
	sw $t3, 7516($t0)
	sw $t3, 7776($t0)
	sw $t3, 7780($t0)
	sw $t3, 7784($t0)
	sw $t3, 7528($t0)
	sw $t3, 7272($t0)
	sw $t3, 7268($t0)
	#A
	sw $t3, 7792($t0)
	sw $t3, 7536($t0)
	sw $t3, 7280($t0)
	sw $t3, 7024($t0)
	sw $t3, 7284($t0)
	sw $t3, 7288($t0)
	sw $t3, 7292($t0)
	sw $t3, 7036($t0)
	sw $t3, 7548($t0)
	sw $t3, 7804($t0)
	sw $t3, 6772($t0)
	sw $t3, 6776($t0)
	#M
	sw $t3, 7812($t0)
	sw $t3, 7556($t0)
	sw $t3, 7300($t0)
	sw $t3, 7044($t0)
	sw $t3, 6788($t0)
	sw $t3, 7048($t0)
	sw $t3, 7056($t0)
	sw $t3, 7060($t0)
	sw $t3, 7308($t0)
	sw $t3, 6804($t0)
	sw $t3, 7316($t0)
	sw $t3, 7572($t0)
	sw $t3, 7828($t0)
	#E
	sw $t3, 6812($t0)
	sw $t3, 7068($t0)
	sw $t3, 7324($t0)
	sw $t3, 7580($t0)
	sw $t3, 7836($t0)
	sw $t3, 6816($t0)
	sw $t3, 6820($t0)
	sw $t3, 6824($t0)
	sw $t3, 7328($t0)
	sw $t3, 7332($t0)
	sw $t3, 7840($t0)
	sw $t3, 7844($t0)
	sw $t3, 7848($t0)
	#O
	sw $t3, 8540($t0)
	sw $t3, 8796($t0)
	sw $t3, 9052($t0)
	sw $t3, 9312($t0)
	sw $t3, 9316($t0)
	sw $t3, 8552($t0)
	sw $t3, 8808($t0)
	sw $t3, 9064($t0)
	sw $t3, 8288($t0)
	sw $t3, 8292($t0)
	#V
	sw $t3, 8304($t0)
	sw $t3, 8560($t0)
	sw $t3, 8816($t0)
	sw $t3, 9076($t0)
	sw $t3, 9336($t0)
	sw $t3, 9084($t0)
	sw $t3, 8320($t0)
	sw $t3, 8576($t0)
	sw $t3, 8832($t0)
	#E
	sw $t3, 8328($t0)
	sw $t3, 8584($t0)
	sw $t3, 8840($t0)
	sw $t3, 9096($t0)
	sw $t3, 9352($t0)
	sw $t3, 8332($t0)
	sw $t3, 8336($t0)
	sw $t3, 8340($t0)
	sw $t3, 8844($t0)
	sw $t3, 8848($t0)
	sw $t3, 9356($t0)
	sw $t3, 9360($t0)
	sw $t3, 9364($t0)
	#R
	sw $t3, 8348($t0)
	sw $t3, 8604($t0)
	sw $t3, 8860($t0)
	sw $t3, 9116($t0)
	sw $t3, 9372($t0)
	sw $t3, 8864($t0)
	sw $t3, 8868($t0)
	sw $t3, 8872($t0)
	sw $t3, 8616($t0)
	sw $t3, 9124($t0)
	sw $t3, 9384($t0)
	sw $t3, 8352($t0)
	sw $t3, 8356($t0)
gameoverLoop:		#wait for key input to escape (end program) or reset (p)
	li $t9, 0xffff0000	#keyboard
	lw $t8 0($t9)		# whether key is pressed
	beq $t8, 1, KEYPRESSED2
	j gameoverLoop
KEYPRESSED2:
	lw $t4, 4($t9)	#get the key pressed
	beq $t4, 0x70, STARTGAME	#p is pressed
	beq $t4, 0x1B, EXIT	#esc is pressed, terminate program
	j gameoverLoop

distance:
	lw $t1, currX
	lw $t2, currY
	lw $t3, currT
	lw $t4, shipx
	lw $t5, shipy
	sub $t1, $t1, $t4
	sub $t2, $t2, $t5
	mult $t1, $t1
	mflo $t1
	mult $t2, $t2
	mflo $t2
	add $t1, $t1, $t2
	blt $t1, 49, HIT
	jr $ra
HIT:
	addi $t1, $zero, 1
	sw $t1, shipHitCounter		#ship stays red if hit again
	lw $t2, health
	beq $t3, 4, increaseHealth	#health pickup
	beq $t3, 5, poisonEnemies
	beq $t3, 1, heavyHit
	subi $t2, $t2, 2
	j normalHit
heavyHit:
	subi $t2, $t2, 5		#larger/slower obstacles take away more health
normalHit:	
	sw $t2, health
	blez $t2, GAMEOVER
	sw $t1, hit		#if ship is hit, set to 1 (will reset when next obstacle spawns)
	j noIncreaseHealth
increaseHealth:
	addi $t2, $t2, 3
	bgt $t2, 25, setMAXHEALTH	#cannot exceed maximum health
	j noIncreaseHealth
setMAXHEALTH:	
	addi $t2, $zero, 25
	sw $t2, health
noIncreaseHealth:
	sw $t2, health
	jal DRAWHEALTH
	j removeRock
poisonEnemies:
	addi $t2, $zero, 1
	sw $t2, poisoned
	lw $t3, spawnTime
	addi $t2, $zero 200
	add $t3, $t2, $t3
	sw $t3, spawnTime
	j removeRock

DRAWHEALTH:
	li $t3, 0x00ff00	#green
	lw $t0, displayAddress
	add $t1, $zero, $zero
	lw $t2, health
healthLoop:
	beq $t1, $t2, redHealth
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	#sw $t3, 8($t0)
	sw $t3, 256($t0)
	sw $t3, 260($t0)
	#sw $t3, 264($t0)
	sw $t3, 512($t0)
	sw $t3, 516($t0)
	#sw $t3, 520($t0)
	addi $t0, $t0, 8
	addi $t1, $t1, 1
	j healthLoop
redHealth:
	li $t3, 0xff0000
redLoop:
	bge $t1, 25, doneHealth
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	#sw $t3, 8($t0)
	sw $t3, 256($t0)
	sw $t3, 260($t0)
	#sw $t3, 264($t0)
	sw $t3, 512($t0)
	sw $t3, 516($t0)
	#sw $t3, 520($t0)
	addi $t0, $t0, 8
	addi $t1, $t1, 1
	j redLoop
	
doneHealth:
	jr $ra

#numbers for score
UPDATESCORE:
	add $t4, $zero, $ra
	li $t3, 0xffffff	
	lw $t0, displayAddress
	addi $t0, $t0, 208
	lw $t1, score3
	addi $t2, $zero, 2
	beq $t1, 0, draw0
	beq $t1, 1, draw1
	beq $t1, 2, draw2
	beq $t1, 3, draw3
	beq $t1, 4, draw4
	beq $t1, 5, draw5
	beq $t1, 6, draw6
	beq $t1, 7, draw7
	beq $t1, 8, draw8
	beq $t1, 9, draw9
NUM2:	
	addi $t2, $zero, 3
	lw $t1, score2
	addi $t0, $t0, 16
	beq $t1, 0, draw0
	beq $t1, 1, draw1
	beq $t1, 2, draw2
	beq $t1, 3, draw3
	beq $t1, 4, draw4
	beq $t1, 5, draw5
	beq $t1, 6, draw6
	beq $t1, 7, draw7
	beq $t1, 8, draw8
	beq $t1, 9, draw9
NUM3:
	addi $t2, $zero, 4
	lw $t1, score1
	addi $t0, $t0, 16
	beq $t1, 0, draw0
	beq $t1, 1, draw1
	beq $t1, 2, draw2
	beq $t1, 3, draw3
	beq $t1, 4, draw4
	beq $t1, 5, draw5
	beq $t1, 6, draw6
	beq $t1, 7, draw7
	beq $t1, 8, draw8
	beq $t1, 9, draw9
doneScore:
	add $ra, $zero, $t4
	jr $ra

eraseNum:
	li $t3, 0x000000
	sw $t3, 8($t0)
	sw $t3, 264($t0)
	sw $t3, 520($t0)
	sw $t3, 776($t0)
	sw $t3, 1032($t0)
	sw $t3, 4($t0)
	sw $t3, 260($t0)
	sw $t3, 516($t0)
	sw $t3, 772($t0)
	sw $t3, 1028($t0)
	sw $t3, 0($t0)
	sw $t3, 256($t0)
	sw $t3, 512($t0)
	sw $t3, 768($t0)
	sw $t3, 1024($t0)
	li $t3, 0xffffff
	jr $ra
draw0: 
	jal eraseNum
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, 8($t0)
	sw $t3, 264($t0)
	sw $t3, 520($t0)
	sw $t3, 776($t0)
	sw $t3, 256($t0)
	sw $t3, 512($t0)
	sw $t3, 768($t0)
	sw $t3, 1024($t0)
	sw $t3, 1028($t0)
	sw $t3, 1032($t0)
	beq $t2, 2, NUM2
	beq $t2, 3, NUM3
	beq $t2, 4, doneScore
draw1:
	jal eraseNum
	sw $t3, 8($t0)
	sw $t3, 264($t0)
	sw $t3, 520($t0)
	sw $t3, 776($t0)
	sw $t3, 1032($t0)
	beq $t2, 2, NUM2
	beq $t2, 3, NUM3
	beq $t2, 4, doneScore
draw2: 
	jal eraseNum
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, 8($t0)
	sw $t3, 264($t0)
	sw $t3, 520($t0)
	sw $t3, 516($t0)
	sw $t3, 512($t0)
	sw $t3, 768($t0)
	sw $t3, 1024($t0)
	sw $t3, 1028($t0)
	sw $t3, 1032($t0)
	beq $t2, 2, NUM2
	beq $t2, 3, NUM3
	beq $t2, 4, doneScore
draw3: 
	jal eraseNum
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, 8($t0)
	sw $t3, 264($t0)
	sw $t3, 520($t0)
	sw $t3, 516($t0)
	sw $t3, 512($t0)
	sw $t3, 776($t0)
	sw $t3, 1024($t0)
	sw $t3, 1028($t0)
	sw $t3, 1032($t0)
	beq $t2, 2, NUM2
	beq $t2, 3, NUM3
	beq $t2, 4, doneScore
draw4: 
	jal eraseNum
	sw $t3, 0($t0)
	sw $t3, 8($t0)
	sw $t3, 256($t0)
	sw $t3, 264($t0)
	sw $t3, 512($t0)
	sw $t3, 516($t0)
	sw $t3, 520($t0)
	sw $t3, 776($t0)
	sw $t3, 1032($t0)
	beq $t2, 2, NUM2
	beq $t2, 3, NUM3
	beq $t2, 4, doneScore
draw5: 
	jal eraseNum
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, 8($t0)
	sw $t3, 256($t0)
	sw $t3, 520($t0)
	sw $t3, 516($t0)
	sw $t3, 512($t0)
	sw $t3, 776($t0)
	sw $t3, 1024($t0)
	sw $t3, 1028($t0)
	sw $t3, 1032($t0)
	beq $t2, 2, NUM2
	beq $t2, 3, NUM3
	beq $t2, 4, doneScore
draw6: 
	jal eraseNum
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, 8($t0)
	sw $t3, 516($t0)
	sw $t3, 520($t0)
	sw $t3, 776($t0)
	sw $t3, 256($t0)
	sw $t3, 512($t0)
	sw $t3, 768($t0)
	sw $t3, 1024($t0)
	sw $t3, 1028($t0)
	sw $t3, 1032($t0)
	beq $t2, 2, NUM2
	beq $t2, 3, NUM3
	beq $t2, 4, doneScore
draw7: 
	jal eraseNum
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, 8($t0)
	sw $t3, 264($t0)
	sw $t3, 520($t0)
	sw $t3, 776($t0)
	sw $t3, 1032($t0)
	beq $t2, 2, NUM2
	beq $t2, 3, NUM3
	beq $t2, 4, doneScore
draw8: 
	jal eraseNum
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, 8($t0)
	sw $t3, 264($t0)
	sw $t3, 516($t0)
	sw $t3, 520($t0)
	sw $t3, 776($t0)
	sw $t3, 256($t0)
	sw $t3, 512($t0)
	sw $t3, 768($t0)
	sw $t3, 1024($t0)
	sw $t3, 1028($t0)
	sw $t3, 1032($t0)
	beq $t2, 2, NUM2
	beq $t2, 3, NUM3
	beq $t2, 4, doneScore
draw9: 
	jal eraseNum
	sw $t3, 0($t0)
	sw $t3, 4($t0)
	sw $t3, 8($t0)
	sw $t3, 264($t0)
	sw $t3, 516($t0)
	sw $t3, 520($t0)
	sw $t3, 776($t0)
	sw $t3, 256($t0)
	sw $t3, 512($t0)
	sw $t3, 1024($t0)
	sw $t3, 1028($t0)
	sw $t3, 1032($t0)
	beq $t2, 2, NUM2
	beq $t2, 3, NUM3
	beq $t2, 4, doneScore
EXIT:
	li $v0, 10 # terminate the program gracefully
	syscall	
	

