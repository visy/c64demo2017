
	.word	entry
	* = $200
entry
	; Call music init.

	lda	#0
	jsr	$1000

	; Set up raster interrupt.

	lda	#$3b
	sta	$d011
	lda	#$ff
	sta	$d012
	lda	#$01
	sta	$d01a
	lsr	$d019

	; Install simple IRQ wrapper to call playroutine.
	; Alternatively, we could use the $fffe vector normally.

	ldx	#<$1003
	ldy	#>$1003
	jsr	$c10
	cli		; cli is needed starting with Spindle 2.3

	; Switch banks so we can watch the loading process.

	lda	#$3d
	sta	$dd02
	lda	#$08
	sta	$d018
	lda	#$18
	sta	$d016
	lda	#$0
	sta	$d020

	; Load the first picture.

	jsr	$c90

	; Since spindle 2.2 we may trash the upper bits of dd02 in between
	; loadercalls (but not during loadercalls, e.g. from interrupts).

	lda	$dd02
trash_example
	clc
	adc	#4
	sta	$dd02
	cmp	#$3d
	bne	trash_example

	; Wait for space, then load the next picture, etc.

	jsr	wait4space
	jsr	$c90
	jsr	wait4space
	jsr	$c90

	; All done.
	; The drive will be reset when ATN is released (e.g. at system reset).

	jmp	*

wait4space
	lda	#$ff
	sta	$dc02
	lsr
	sta	$dc00
	lda	#$10
	bit	$dc01
	beq	*-3
	bit	$dc01
	bne	*-3
	rts

