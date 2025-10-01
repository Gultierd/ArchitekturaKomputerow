.data
	coefs:		.float 2.3, 3.45, 7.67, 5.32	# współczynniki wielomianu od najwyższej potęgi do wyrazu wolnego
	degree:		.word	3		# stopień wielomianu (4 współczynniki - 3 z potęgami i wyraz wolny)
	
	prompt_txt:	.asciiz "\nPodaj wartosc x - liczba zmiennoprzecinkowa: "
	result_txt:	.asciiz "\nWartosc wielomianu P(x) = "
	continue_txt:	.asciiz "\nWykonac dzialanie dla innego x? (0 - nie, inne - tak): "
	
.text
	la	$s0, coefs		# ładujemy adres bazowy tablicy współczynników
	lw	$s1, degree		# ładujemy wartość stopnia wielomianu
	
interactive_loop:
	li	$v0, 4
	la	$a0, prompt_txt
	syscall				# wyświetlamy zapytanie dla użytkownika
	
	li	$v0, 7
	syscall				# odczytujemy double x od uzytkownika
	
	mov.d	$f12, $f0 		# przenosimy wczytana wartosc do $f12 jako argument dla eval_poly (rejestr dla double)
	
	move	$a0, $s0
	move	$a1, $s1		# wczytujemy argumenty - adres tablicy i wartość stopnia wielomianu (a0 - adres tablicy, a1 - wartosc wielomianu)
	
	jal	eval_poly		# przechodzimy do podprogramu z wyliczaniem wielomianu
	
	li	$v0, 4
	la	$a0, result_txt
	syscall				# wyświetlamy użytkownikowi napis
	
	mov.d	$f12, $f0		# przenosimy adres do $f12 do wydrukowania
	li	$v0, 3			# syscall 3 - printuje double z argumentem w $f12
	syscall
	
	li	$v0, 4
	la	$a0, continue_txt	# wyświetlamy zapytanie odnosnie kontynuacji
	syscall
	
	li	$v0, 5
	syscall				# użytkownik wpisuje swoja odpowiedz
	
	bne	$v0, $zero, interactive_loop	# jeśli odpowiedź nie jest zerem to wracamy do początku pętli
	
	li	$v0, 10			# w przeciwnym wypadku kończymy program
	syscall
	
eval_poly:				# $a0 - adres początku tablicy współczynników, $a1 - stopień wielomianu, $f12 wartość x, double
	l.s	$f2, 0($a0)		# wczytujemy pierwszy współczynnik (pierwsze słowo z tablicy współczynników wielomianu) w pojedynczej precyzji
	cvt.d.s $f0, $f2		# konwertujemy float na double (pojedyncza na podwojna precyzja)

	li	$t0, 1			# licznik dla stopnia wielomianu
	
horner_loop:				# stosując schemat hornera ilość wykonanych mnożeń (oraz później dodawań) dla liczb zmiennoprzecinkowych jest równa stopniowi wielomianu
	bgt	$t0, $a1, horner_end	# jeśli nasz licznik będzie większy niż deklarowany stopień to kończymy pętlę i podprogram
	
	mul.d	$f0, $f0, $f12		# mnożymy współczynnik i nasz podany x
	sll	$t1, $t0, 2		# przechodzimy do adresu następnego współczynnika, liczymy offset
	addu	$t2, $a0, $t1		# zupełny adres wyznaczonego współczynnika przy x
	
	l.s	$f2, 0($t2) 		# ładujemy bieżący współczynnik do $f2 (l.s wczytuje liczbę pojedynczej precyzji, wymagana jest konwersja na podwójnej)
	cvt.d.s	$f4, $f2		# konwertujemy float na double
	
	add.d	$f0, $f0, $f4		# dodajemy do wyniku wartość (i-tego wyrazu * x)
	addiu	$t0, $t0, 1		# zwiększamy nasz licznik
	j 	horner_loop		# powrót do pętli
	 

horner_end:
	jr	$ra			# koniec podprogramu, wracamy do programu głównego
