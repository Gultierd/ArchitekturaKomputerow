.data
	RAM:		.space 4096
	RAM_size:	.word 4096 
	rows_txt:	.asciiz "Podaj liczbe wierszy ( > 0): "
	cols_txt:	.asciiz "Podaj liczbe kolumn ( > 0): "
	operations_txt:	.asciiz "Wybierz operacje: 1 - zapis / 2 - odczyt / 0 - koniec\n"
	sel_row_txt:	.asciiz "Podaj indeks wiersza (indeksy od 0): "
	sel_col_txt:	.asciiz "Podaj indeks kolumny (indeksy od 0): "
	sav_val_txt:	.asciiz "Podaj wartosc do zapisu: "
	read_val_txt:	.asciiz "Odczytana wartosc: "
	err_init_txt:	.asciiz "Blad: Wykryto niepoprawne liczby!\nWartosci musza byc wieksze od 0 i miescic sie w RAM!\n"
	err_idx_txt:	.asciiz "Blad: Indeks poza zakresem!\n"
	err_inv_txt:	.asciiz "Blad: Niepoprawna operacja!\n"
	newline_txt:	.asciiz "\n"

.text
	la 	$s3, RAM	# inicjalizacja wskaźnika na ram
	lw	$s4, RAM_size	# maksymalny dostępny dla użytkownika rozmiar, używany do sprawdzania poprawności danych
	
dimensions_init:
	li 	$v0, 4
	la	$a0, rows_txt	# wyświetlamy zapytanie dla użytkownika
	syscall
	
	li	$v0, 5
	syscall			# użytkownik wpisuje dane (wiersze)
	move	$s0, $v0	# dane zapisujemy w rejestrze $s0
	blez	$s0, invalid_data # jeśli dane niepoprawne - skok do błędu
	
	li 	$v0, 4
	la	$a0, cols_txt	# wyświetlamy zapytanie dla użytkownika
	syscall
	
	li	$v0, 5
	syscall			# użytkownik wpisuje dane (kolumny)
	move	$s1, $v0	# dane zapisujemy w rejestrze $s1
	blez	$s1, invalid_data # jeśli dane niepoprawne - skok do błędu
	
	#sprawdzamy czy rozmiar mieści się w naszym RAM (4096)
	addiu 	$t0, $s1, 1	# całkowity rozmiar liczymy wzorem: W * (K+1) * 4 , gdzie W - wiersze, K - kolumny
	mul 	$t1, $t0, $s0	# wykonujemy działanie opisane powyżej
	sll	$t2, $t1, 2
	bgt	$t2, $s4, invalid_data # jeśli jest większy to wyświetlamy błąd, użytkownik wpisuje dane ponownie
	j	allocation
	
invalid_data:			# wpisane dane nie są poprawne, wyświetlamy błąd dla użytkownika
	li 	$v0, 4
	la	$a0, err_init_txt
	syscall
	j	dimensions_init # wracamy do wprowadzania danych przez użytkownika
	
allocation:			# dane na ten moment: $s0 - wiersze, $s1 - kolumny, $s3 - adres RAM, wskaźnik wolnej pamięci $s4 - rozmiar ram (4096)
	sll	$t0, $s0, 2	# Obliczamy rozmiar (w bajtach) tablicy wierszy - pierwszego poziomu opisanego w zadaniu
	move	$s2, $s3	# Zapisujemy adres bazowy tablicy tych wierszy
	addu	$s3, $s3, $t0	# Przesuwamy wskaźnik wolnej pamięci o długość pierwszej tablicy
	
	li 	$t0, 0		# Indeks bieżącego wiersza, rozpoczynamy pętlę
	
allocate_rows_outer_loop:
	bge	$t0, $s0, end_loop_operations_selection	# Jeśli indeks jest większy niż liczba wierszy to kończymy pętlę
	
	move	$t5, $s3	# zapisuejmy adres bazowy dla bieżącego wiersza
	sll	$t1, $t0, 2	# offset w tablicy
	addu 	$t2, $s2, $t1	# adres i-tej komórki w pierwszej tablicy (tablicy wierszy)
	sw	$t5, 0($t2)	# zapisujemy do tablicy
	
	li 	$t6, 0		# indeks kolumny, wchodzimy w pętle wewnętrzną

allocate_fill_inner_loop:		# pętla wewnętrzna do zapisywania wartości w kolejnych wierszach
	bge	$t6, $s1, end_allocate_fill_inner_loop # jeśli j >= ilość kolumn to kończymy pętle wewnętrzną
	
	li	$t7, 100
	mul	$t7, $t0, $t7	# Obliczamy wartość dla komórki zgodnie z treścią zadania
	addiu	$t8, $t6, 1
	addu	$t7, $t7,$t8	# całkowita wartość do zapisania (i * 100 + j+1)
	
	sll	$t8, $t6, 2	# offset dla bieżącego wiersza
	addu	$t8, $t5, $t8	# adres komórki w macierzy
	sw 	$t7, 0($t8)	# wpisujemy wartość do tablicy
	
	addiu 	$t6, $t6, 1	# inkrementacja j do pętli wewnętrznej
	j allocate_fill_inner_loop

end_allocate_fill_inner_loop:	# koniec pętli wewnętrznej do zapisywania wartości w wierszach
	sll	$t4, $s1, 2	# rozmiar jednego wiersza danych ( liczba kolumn *4)
	addu	$s3, $s3, $t4	# wyznaczamy kolejne wolne miejsce do wpisywania danych do tablic
	
	addiu	$t0, $t0, 1	# inkrementacja i do pętli zewnętrznej
	j allocate_rows_outer_loop

end_loop_operations_selection:	# Koniec pętli, tablice zostały zinicjalizowane a ich wartości wpisane
	
	li	$v0, 4
	la	$a0, operations_txt
	syscall			# wyświetlamy tekst dla użytkownika
	
	li	$v0, 5
	syscall			# 0 - koniec / 1 - zapis / 2 - odczyt
	move	$t0, $v0	# użytkownik wybiera operację spośród dostępnych
	
	beq	$t0, $zero, end_program	# 0 - kończymy program
	
	li	$t1, 1
	beq	$t0, $t1, get_rows_cols # 1 - zapisujemy dane, przystępujemy do pozyskania konkretnej komórki
	
	li	$t1, 2
	beq	$t0, $t1, get_rows_cols # 2 - odczytujemy dane, przystępujemy do pozyskania konkretnej komórki
	
	li	$v0, 4
	la	$a0, err_inv_txt # jeśli nie jest to żadna z operacji to wyświetlamy błąd
	syscall
	
	j 	end_loop_operations_selection # jeśli użytkownik nie wybrał poprawnej to przeskakujemy na początek wyboru operacji
	
get_rows_cols:
	li 	$v0, 4
	la 	$a0, sel_row_txt     # Pytamy użytkowika o indeks wiersza
	syscall
    	
    	li 	$v0, 5
    	syscall
    	move 	$t1, $v0	# $t1 = wczytany indeks wiersza 'i'
    	
	li 	$v0, 4
	la 	$a0, sel_col_txt	# Pytamy użytkowika o indeks kolumny
	syscall
    	
	li 	$v0, 5
	syscall
	move 	$t2, $v0	# $t2 = wczytany indeks kolumny 'j'
	
	# Weryfikacja poprawności wpisanych indeksów - wiersz 'i'
	bltz	$t1, index_out_of_bounds
	bge	$t1, $s0, index_out_of_bounds
	# Weryfikacja poprawności wpisanych indeksów - kolumna 'j'
	bltz	$t2, index_out_of_bounds
	bge	$t2, $s1, index_out_of_bounds
	
	move	$a1, $t1	# indeks wiersza
	move	$a2, $t2	# indeks kolumny
	# wpisujemy dane do rejestrów argumentowych pod podprogramy
	
	li	$t7, 1
	beq	$t0, $t7, operation_write	#jeśli użytkownik wpisał 1 - zapisujemy dane
	# jeśli użytkownik wpisał 2 - odczytujemy dane, nie musimy przeskakiwać, bo inne przypdaki obsłużone zostały wcześniej
	
operation_read: 		# wybrana operacja to odczyt danych
	li	$v0, 4
	la	$a0, read_val_txt
	syscall			# wypisujemy tekst użytkownikowi, odczytana wartosc
	
	move	$a0, $s2	# bazowy adres pierwszej tablicy, nastawiamy tuż przed podprogramem ze względu na wcześniejsze jego użycie
	jal 	read_element	# wywołujemy podprogram do odczytu wartości, odczytana wartość zapisana w $v0
	move	$a0, $v0	# przenosimy wynik z podprogramu wczytywyania do rejestru $a0 do wydruku
	
	li	$v0, 1
	syscall
	
	li 	$v0, 4
	la 	$a0, newline_txt
	syscall			# wypisujemy pustą linijkę dla przejrzystosci
	
	j end_loop_operations_selection # po zakończeniu wracamy do wyboru operacji

operation_write:		# wybrana operacja to zapis danych
	li	$v0, 4
	la	$a0, sav_val_txt
	syscall			# wypisujemy tekst użytkownikowi, prośba o podanie wartości
	
	li	$v0, 5
	syscall
	move	$a3, $v0	# zapisujemy wartość do zapisania
	
	move	$a0, $s2	# bazowy adres pierwszej tablicy, nastawiamy tuż przed podprogramem ze względu na wcześniejsze jego użycie
	jal 	save_element	# wywołujemy podprogram do zapisu wartości

	j end_loop_operations_selection # po zakończeniu wracamy do wyboru operacji

index_out_of_bounds:
	li	$v0, 4
	la	$a0, err_idx_txt
	syscall
	j	end_loop_operations_selection	# jeśli indeksy były niepoprawne to wracamy do wyboru operacji

end_program:
	li	$v0, 10
	syscall			# koniec programu, operacja przy wyborze zakończenia
	
read_element:			# podprogram do odczytu elementu - wynik zapisujemy w $v0
	addiu 	$sp, $sp, -4  	# użyjemy stosu, ze względu na konieczność zapisania $ra, zmienianego w zagneżdżonym podprogramie
	# Ta operacja tworzy miejsce na stosie na jeden wyraz
	sw 	$ra, 0($sp)	# na stosie zapisujemy aktualną wartość $ra
	jal	find_cell_address # zagnieżdżony podprogram do odnalezienia adresu komórki, wynik otrzymujemy w $v0
	
	lw	$v0, 0($v0)	# nadpisujemy wartość rejestru $v0 (aktualnie adres komórki) wartością z tej komórki
	
	lw	$ra, 0($sp)	# wczytujemy oryginalną waratość $ra ze stosu
	addiu	$sp, $sp, 4	# zwalniamy miejsce na stosie, przywracamy wskaźnik na początek
	jr	$ra		# wracamy do miejsca wywołania podprogramu, zwracana wartość w rejestrze $v0
	
save_element:			# podprogram do zapisu na miejsce elementu
	addiu 	$sp, $sp, -4  	# użyjemy stosu, ze względu na konieczność zapisania $ra, zmienianego w zagneżdżonym podprogramie
	# Ta operacja tworzy miejsce na stosie na jeden wyraz
	sw 	$ra, 0($sp)	# na stosie zapisujemy aktualną wartość $ra
	jal	find_cell_address # zagnieżdżony podprogram do odnalezienia adresu komóki, wynik otrzymujemy w $v0
	
	sw	$a3, 0($v0)	# zapisujemy przyjęty argument do adresu komórki
	
	lw	$ra, 0($sp)	# wczytujemy oryginalną waratość $ra ze stosu
	addiu	$sp, $sp, 4	# zwalniamy miejsce na stosie, przywracamy wskaźnik na początek
	jr	$ra		# koniec podprogramu, wracamy do miejsca wywołania


find_cell_address:		# podprogram dla podprogramu do odnalezienia konkretnej komórki - przydatne dla obydwu podprogramów
	sll	$t0, $a1, 2	# offset dla i-tego wiersza
	addu	$t1, $a0, $t0	# wyliczamy adres wiersza w pierwszej tablicy
	
	lw	$t2, 0($t1)	# odczytujemy adres bazowy poszukiwanego wiersza
	sll	$t0, $a2, 2	# wyliczcamy offset dla j-tej kolumny wewnątrz wiersza
	
	addu	$v0, $t2, $t0	# wyliczamy adres poszukiwanego elementu w macierzy, zapisujemy w $v0 jako zwrotny rejestr funkcji
	jr 	$ra		# wracamy do miejsca wywołania
