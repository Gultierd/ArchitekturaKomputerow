.data
	licz1: 		.word  			# liczby w naturalnym kodzie binarnym, mnożna
	licz2: 		.word  			# mnożnik - póki co tylko zinicjalizowane, później wartości zostaną wprowadzone przez użytkownika
	wyn: 		.word 0
	status: 	.word 0
	txt_licz1: 	.asciiz "\nPodaj pierwsza liczbe (mnozna, >0) - "
	txt_licz2: 	.asciiz "\nPodaj druga liczbe (mnoznik, >0) - "
	txt_wyn: 	.asciiz "\nWynik (zinterpretowany niepoprawnie jesli mamy nadmiar) - "
	txt_status: 	.asciiz "\nStatus (nadmiar/brak nadmiaru - 1/0) - "
	
.text
	li 	$v0, 4        			# informacja dla użytkownika o wpisaniu liczby       
    	la 	$a0, txt_licz1 
    	syscall
    	
    	li 	$v0, 5        			# użytkownik wpisuje liczbę pierwszą, mnożną
    	syscall
    	sw 	$v0, licz1 
    	lw 	$s0, licz1 			# wczytujemy liczby na rejestry s - saved temporary 
    						# możemy również usunąć całkowicie pamięć licz1 i po prostu wczytywać dane z $v0 do rejestru $s0 żeby prowadzić dalsze działania
    	
    	li 	$v0, 4        			#informacja dla użytkownika o wpisaniu liczby       
    	la 	$a0, txt_licz2
    	syscall
    	
    	li 	$v0, 5        			#użytkownik wpisuje liczbę drguą, mnożnik
    	syscall
    	sw 	$v0, licz2 
    	lw 	$s1, licz2
						# analogicznie do poprzedniego możemy ominąć zastosowanie pamięci licz2
	
	li 	$s2, 0 				# wynik, początkowo 0
	li 	$s3, 0 				# status, początkowo 0
	
	
multiplicationLoop: 				# główna pętla dzielenia	
	beqz 	$s1, endloop 			# jeśli s1 (mnożnik) jest równy zero to przechodzimy od razu do końca pętli
	
	and 	$t1, $s1, 1 			# badamy najmniej znaczący bit mnożnika - sprawdzamy czy jest jedynką. 
						# De facto bitowa reprezentacja liczby to 0000...001. /And/ zwraca 1 jeśli wszystkie bity '1' rejestru się zgadzają
	beqz 	$t1, shift 			# jeśli jest on zerem - przechodzimy do badania kolejnej cyfry i omijamy dodawanie
	
	move 	$t2, $s2 			# zapisujemy aktualny wynik w rejestrze do badania nadmiaru
	
	xor	$t0, $s2, $s0			# bierzemy xora dla liczb, które dodajemy - xor > 0 liczby tych samych znaków, xor < 0 liczby różnych znaków
	
	addu 	$s2, $s2, $s0  			# do wartości wyniku dodajemy wartość mnożoną - samo add doprowadza do wyjatku
	
	blt 	$t0, $zero, overflow		# jeśli poprzedni xor był fałszem (xor<0) - liczby różnych znaków - odnotowujemy nadmiar, ponieważ jedna z liczb dodawanych jest już poza zakresem
	xor	$t0, $s2, $s0			# badamy xora dla wyniku po dodawaniu, podobnie tak jak wcześniej
	bge	$t0, $zero, shift		# jeśli wynik jest tego samego znaku (xor>0) to nie doszło do nadmiaru - badamy kolejne cyfry
	j overflow				# przypadki nie wychwycone wcześniej - wynik różnych znaków świadczy o nadmiarze
	
shift:	
   	srl 	$s1, $s1, 1         		# przesuwamy mnożnik o jeden w prawo do badania kolejnych cyfr
    	sll 	$s0, $s0, 1         		# przesuwamy mnożną o jeden w lewo
    						# wszystkie operacje wykonywane są w systemie dwójkowym, więc wszystko się zgadza
    	j	multiplicationLoop 		# kontynuujemy pętlę
    	
    	    		
overflow:					# label przy wykrywaniu nadmiaru - zmienia status na 1 i kończy pętle
	li 	$s3, 1	
	j 	endloop

endloop:
	sw 	$s2, wyn 			# zapisujemy wyniki do naszej pamięci
	sw 	$s3, status

	li 	$v0, 4 				# wypisujemy w konsoli dodatkowy tekst 
	la 	$a0, txt_wyn 
	syscall
    
	lw 	$a0, wyn 			# wartość wyniku przekazujemy do rejestru $a0, argumentu kolejnej instrukcji (alternatywnie li $a0, $s2)
	li 	$v0, 1
	syscall 				# wypisujemy integer - wartość wyniku
	
	li 	$v0, 4 				# wypisujemy w konsoli dodatkowy teskt
	la 	$a0, txt_status
	syscall
	
	lw 	$a0, status 			# wartość statusu (nasz nadmiar) przypisujemy do rejestru $a0
	li 	$v0, 1
	syscall 				# wypisujemy integer - wartość wyniku
	
