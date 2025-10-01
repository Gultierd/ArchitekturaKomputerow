.data
	.eqv 		STACK_SIZE 	2048		# rozmiar naszego stosu
	sys_stack_addr:	.word		0
	stack:		.space		STACK_SIZE	# deklaracja stosu
	global_array:	.word		1,2,3,4,5,6,7,8,9,10
	array_size:	.word		10		# dwa argumenty - tablica i jej rozmiar
	
	results_txt:	.asciiz		"\nSuma elementów tablicy: "
.text
main:
	sw	$sp, sys_stack_addr		# Zapisujemy wartość
	la	$sp, stack			# Ładujemy adres początku naszego stosu
	addiu	$sp, $sp, STACK_SIZE		# przesuwamy wskaźnik do przodu o cały rozmiar stosu
	addiu	$sp, $sp -4			# robimy miejsce dla zmiennej
	
	la	$t0, global_array		# wczytujemy adres naszej tablicy
	addiu	$sp, $sp, -4			# robimy miejsce dla adresu tablicy (stąd tylko 4 bajty)
	sw	$t0, 0($sp)			# umieszczamy na stosie adres tablicy
	
	lw	$t0, array_size			# ładujemy wartość długości tablicy
	addiu	$sp, $sp, -4			# robimy miejsce na stosie na wartość
	sw	$t0, 0($sp)			# kładziemy wartość na stos
	
	jal	calculate_sum			# wykonujemy wyznaczony podprogram
	
	lw	$t0, 0($sp)			# ładujemy wartość zwróconą z podprogramu
	sw	$t0, 12($sp)			# zapisujemy zwróconą sumę do s_main
	
	li	$v0, 4
	la	$a0, results_txt		# wiadomość dla użytkownika
	syscall
	
	lw	$a0, 12($sp)			# ładujemy dla użytkownika wartość wyniku ze stosu
	li	$v0, 1
	syscall
	
	addiu	$sp, $sp, 16			# czyścimy stos - usuwamy miejsca wszystkich wcześniejszych wartości
	
	lw 	$sp, sys_stack_addr		# odtwarzamy wskaźnik dla naszego stosu
	
	li $v0, 10				# kończymy program
	syscall
		
	
calculate_sum:
	addiu	$sp, $sp, -4			# tworzymy na stosie miejsce na wartość zwracaną, zgodnie z poleceniem zadania
	addiu	$sp, $sp -4			# tworzymy na stosie kolejne miejsce na słowo - teraz dla adresu powrotu ($ra) - zgodnie z poleceniem nie idziemy na skróty od razu dając -8
	sw	$ra, 0($sp)			# zapisujemy $ra (adres powrotu z podprogramu) na stosie
	
	addiu	$sp, $sp, -8			# rezerwujemy kolejne miejsca na dwie zmienne lokalne - zgodnie z poleceniem int i oraz int s
	
	lw	$t0, 20($sp)			# wyciągamy ze stosu adres początku tablicy
	lw	$t1, 16($sp)			# wyciągamy ze stosu słowo z długością tablicy
	
	sw	$zero, 0($sp)			# aktualna suma = 0
	
	addiu	$t2, $t1, -1			# to będzie nasz licznik (i) po tablicy, zaczynamy od rozmiar tablicy - 1
	sw	$t2, 4($sp)			# zapisujemy i na stosie

sum_loop:					# pętla do sumowania wartości
	lw	$t2, 4($sp)			# odczytujemy wartość i
	bltz 	$t2, sum_loop_end		# jeśli i < 0 to pętla się kończy
	
	sll	$t3, $t2, 2			# offset dla tablicy to i*4 (bierzemy i-ty wyraz)
	addu	$t3, $t0, $t3			# wyliczamy konkretny adres i-tego elementu w tablicy
	lw	$t4, 0($t3)			# odczytujemy wartość z adresu dla tablicy
	
	lw	$t5, 0($sp)			# odczytujemy aktualną wartość sumy ze stosu
	addu	$t5, $t5, $t4			# dodajemy odczytaną wartość z tablicy do sumy
	sw	$t5, 0($sp)			# zapisujemy nową sumę na stos
	
	addiu	$t2, $t2, -1			# dekrementacja licznika i
	sw	$t2, 4($sp)			# zapisujemy nowe i na stosie
	j sum_loop
	
sum_loop_end:
	lw	$t0, 0($sp)			# ostateczna wyliczona wartość sumy
	sw	$t0, 12($sp)			# zapisujemy sumę na zarezerwowane miejsce dla wartości zwracanej
		
	addiu	$sp, $sp, 8			# przesuwamy wskaźnik na zapisany adres powrotu $ra
	lw	$ra, 0($sp)			# odczytujemy oryginalny adres powrotu
	
	addiu	$sp, $sp, 4			# przesuwamy wskaźnik na miejsce dla zwracanej wartości

	jr 	$ra				# wracamy do głównego programu
