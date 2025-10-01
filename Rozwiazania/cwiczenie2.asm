.data
	N_count:	.word 100000 	# górna granica
	numall:		.space 400004 	# tablica ze wszystkimi liczbami, 4  * (N_count+1) ze względu na długość słowa (4 bajty)
	primes:		.space 400004	# tablica z liczbami pierwszymi
	nprimes:	.word 0		# ilość liczb pierwszych

	nprimes_text: 	.ascii  "\nLaczna ilosc liczb pierwszych w wyznaczonym zakresie - "

.text
	li 	$v0, 30         	# rozpoczynamy pomiar czasu
	syscall
	move	$s7, $a0		# zapisujemy czas startu do obliczenia

	lw	$s0, N_count 		# górna granica tablicy
	la 	$s1, numall		# bazowy adres tablicy
	la	$s2, primes		# bazowy adres tablicy
	li	$t0, 2			# licznik pętli, zaczynamy od 2, bo jedynka nie jest liczbą pierwszą

arrayInitLoop:
	bgt 	$t0, $s0, arrayInitEnd	# sprawdzamy czy licznik pętli nie przekroczył granicy
	# jeśli licznik jest większy - kończymy inicjalizację tablicy
	sll	$t2, $t0, 2		# przesuwamy o 2 w binarnym, czyli mnożymy o 4 - do obliczania adresu
	addu	$t3, $s1, $t2		# obliczamy adres elementu, licznik pętli i adres bazowy

	sw 	$t0, 0($t3)		# zapisujemy wartość licznika (i) do i-tego elementu tablicy, z dodanym offsetem 0, bo adres jest już  wyliczony
	addiu	$t0, $t0, 1		# inkrementacja licznika
	j 	arrayInitLoop		# kontynnujemy pętle

arrayInitEnd:
	li 	$t0, 0 			# w razie czego zapisujemy pierwszy element (1) od razu jako 0, bo nie jest to l. pierw.
	sw 	$t0, 4($s1)		# przypisujemy wartość 0 do 1. elementu tabliy

	li	$t7, 2			# dzielnik, 2
	div	$s2, $t7		# dzielimy n_count/2
	mflo	$s5			# pobieramy wynik do s5
	li 	$s4, 2			# bierzemy n=2 dla rozpoczęcia sita erastotenesa
	
outerErastosthenesLoop:
	bgt 	$s4, $s5, endOuterErastosthenes # kończymy pętle jeśli i > n_count/2

	sll 	$t1, $s4, 2		# przesunięcie w lewo jako mnożenie * 4 dla odczytania wartości z tablicy
	addu	$t1, $s1, $t1		# wyliczamy adres n-tego elementu z tablicy dodając bazowy adres tablicy
	lw	$t2, 0($t1)		# wczytujemy wartość n-tego elementu

	beq	$t2, $zero, incrementN	# jeśli wartość to 0 (wykreślona wcześniej) to przechodzimy do kolejnej liczby
	
	mult	$s4, $s4		# dla optymalizacji liczymy n*n dla początku k wewnętrznej pętli, wszystkie wcześniejsze zostały już wykreślone
	mflo	$t3			# otrzymujemy wynik w rejestrze t3
	bltz 	$t3 endOuterErastosthenes # jeśli wynik jest ujemny (wychodzi poza 32 bity) to wychodzimy od razu z pętli, nie znajdziemy kolejnych liczb

innerErastosthenesLoop:
	bgt 	$t3, $s0, incrementN  	# kończymy pętle wewnętrzną gdy k > N_count i przechodzimy do kolejnej liczby

	sll 	$t0, $t3, 2		# będziemy wykreślali k-ty elementy i jego wielokrotności, podobna sytuacja z przesunięciem
	addu 	$t1, $s1, $t0		# wyznaczamy adres k-tego elementu
	sw	$zero, 0($t1)		# zerujemy wartość elementu

	addu 	$t3, $t3, $s4		# przechodzimy do kolejnej wielokrotności
	j 	innerErastosthenesLoop	# powtarzamy pętlę

incrementN:
	addiu 	$s4, $s4, 1		# inkrementacja N
	j 	outerErastosthenesLoop	# wracamy do pętli zewnętrznej

endOuterErastosthenes:
	la 	$s5, primes		# bazowy adres tablicy
	li 	$s6, 0			# nprimes - na razie 0
	li 	$t0, 2			# będziemy rozpatrywali liczby w numall od 2

collectPrimes:
	bgt 	$t0, $s0, endCollectPrimes # iterujemy przez całą tablicę
	sll 	$t1, $t0, 2		# ponownie przesuwamy w lewo, czyli mnożymy o 4
	addu 	$t2, $s1, $t1		# otrzymujemy adres i-tego elementu tablicy
	lw	$t3, 0($t2)		# otrzymujemy wartość i-tego elementu

	beq 	$t3, $zero, incrementCollect # jeśli wartość to 0 to liczba nie jest pierwsza, idziemy dalej

	sll	$t4, $s6, 2		# liczymy offset dla nowej wartości w tablicy primes
	addu 	$t5, $s5, $t4		# wyliczony adres primes dla n-tej wartości

	sw 	$t3, 0($t5)		# zapisujemy liczbę pierwszą w tablicy
	addiu 	$s6, $s6, 1		# zwiększamy nprimes, ilość liczb pierwszych

incrementCollect:
	addiu 	$t0, $t0, 1		# zwiększamy indeks i
	j 	collectPrimes		# wracamy do głównej pętli

endCollectPrimes:
	sw 	$s6, nprimes 		# zapisujemy ilość przechwyconych liczb pierwszych

	li 	$v0, 30       		# kończymy pomiar czasu
	syscall 
	subu 	$t0, $a0, $s7		# obliczamy różnicę czasu

	move 	$a0, $t0       		# wypisujemy różnicę czasu w milisekundach - jest to czas od rozpoczęcia do wypełnienia tablicy nprimes
	li 	$v0, 1
	syscall
	
	li 	$a0, '\n'             	# przerwa pomiędzy liczbami
	li 	$v0, 11              	# printujemy pojednyczy char
	syscall
	
	
	li 	$t0, 0 			# indeks do wypisywania, zaczynamy od 0


printPrimes:
	bge 	$t0, $s6 endPrintPrimes # warunek pętli, sprawdzamy czy indeks do wypisywania jest wiekszy od nprimes

	sll	$t1, $t0, 2 		# prezesuwamy w lewo do znalezienia adresu elementu
	addu	$t2, $s5, $t1		# adres elementu
	lw	$a0, 0($t2) 		# wartość wyznaczonego elementu
	li 	$v0, 1 			# printujemy liczbę
	syscall

	li 	$a0, ' '             	# przerwa pomiędzy liczbami
	li 	$v0, 11              	# printujemy pojednyczy char
	syscall
	
	addiu 	$t0, $t0, 1		# inkrementacja indeksu
	j 	printPrimes

endPrintPrimes:
	la 	$a0, nprimes_text
	li 	$v0, 4
	syscall

	lw 	$a0, nprimes		# wypisujemy iloćś liczb pierwszych
	li 	$v0, 1
	syscall
