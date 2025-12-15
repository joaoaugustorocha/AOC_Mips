	.data

instrucaoPrincipal: .asciiz "Insira (Temperatura Fumaça) separadas por espaço ou insira o código 'b' para ativação manual do alarme, ou o código 'l' para listar as ultimas leituras. Digite 'e' para encerar.\n"
ResultadoAlarme1: .asciiz "RISCO: "
ResultadoAlarme2: .asciiz "/100\n"
Estado: .asciiz "ESTADO: "
Normal: .asciiz "normal\n"
Alerta: .asciiz "alerta\n"
Atencao: .asciiz "atençao\n"
Evacuacao: .asciiz "evacuação\n"
ErroLeitura: .asciiz "ERRO: O sistema detectou um erro na leitura de dados, verificar sensores.\n"
Label: .asciiz "(Temperatura | fumaça)\n"
LF: .asciiz "\n"
Manual: .asciiz "Alarme ativado manualmente\n"
ErroListarLeitura: .asciiz "ERRO: Nenhuma leitura feita.\n"
.align 2
PilhaGeral: .space 32
.align 2
buffer: .space 32
.align 2
UltimasLeiturasT: .space 44
.align 2
UltimasLeiturasF: .space 44
.align 2
	.text
.globl main

main:
	la $s1, UltimasLeiturasT 
	la $s2, UltimasLeiturasF
	li $t5, 0 #Total de leituras
	main2:
	li $t1, 0
	li $t2, 0
	
	la $s0, PilhaGeral #Topo da pilha

	
	
	add $s0, $s0, -4
	
	
	li $v0, 4
	la $a0, instrucaoPrincipal

	syscall
	
	li $v0, 8
	la $a0, buffer
	li $a1, 32
	syscall
	
	la $a0, buffer
	
	jal lendoEntrada
		
	move $a0, $v0
	move $a1, $v1
	
	jal CalcularRisco
	move $a0, $v0

	jal OutputAlarme
	
	j main2
	
lendoEntrada:
	#a0 endereço da string, v0 e v1 numeros lidos.
	li $v0, 0
	li $t0, 0 #contador de leituras
	lb $t1, 0($a0)
	beq $t1, 101, Encerrar
	beq $t1, 98, acionarAlarmeManualmente
	beq $t1, 108, ListarUltimasLeituras
	blt $t1, 48, ErroDeLeitura
	bgt $t1, 57, ErroDeLeitura
	loop:
		lb $t1, 0($a0)
		beq $t1, 10, loopBottom2
		beq $t1, 32, loopBottom2
		add $t1, $t1, -48
		mul $v0, $v0, 10
		add $v0, $v0, $t1
		add $a0, $a0, 1
		j loop
	loopBottom2:
	add $a0, $a0, 1
	
	add $s0, $s0, 4
	sw $v0, 0($s0)
	add $t0, $t0, 1
	beq $t1, 10, endFunc
	
	li $v0, 0
	j loop
	
	endFunc:
	bne $t0, 2, ErroDeLeitura 
	add $t5, $t5, 1
	lw $v1, 0($s0)
	add $s0, $s0, -4
	lw $v0, 0($s0)
	move $t0, $ra
	move $a0, $v0
	move $a1, $t5
	la $a2, UltimasLeiturasT
	jal GravarLeitura
	move $a0, $v1
	la $a2, UltimasLeiturasF
	move $a1, $t5
	jal GravarLeitura
	move $ra, $t0
	jr $ra

GravarLeitura:
#a0 valor a ser gravado, a1 total de leituras feitas, a2 lista onde a leitura será gravada
	
	add $a1, $a1, -1
	rem $a1, $a1, 10
	mul $a1, $a1, 4
	add $a2, $a2, $a1
	sw $a0, 0($a2)
	jr $ra
	
ListarUltimasLeituras:
	move $a2, $t5
	beq $a2, 0, Erro2
	
	bgt $a2, 10, limite2
	continua:
	li $t0, 0
	loop1:
		move $a0, $t0
		move $a0, $s1
		move $a1, $s2
		mul $t7, $t0, 4
		add $a1, $a1, $t7
		add $a0, $a0, $t7
		move $t7, $a0
		la $a0, Label
		li $v0, 4
		syscall
		lw $a0, 0($t7)
		li $v0, 1
		syscall
		li $a0, 32
		li $v0, 11
		syscall
		lw $a0, 0($a1)
		li $v0, 1
		syscall
		li $a0, 10
		li $v0, 11
		syscall		
		move $a0, $t7
		li $t7, 0
	loopBottom1:
		add $t0, $t0, 1
		blt $t0, $a2, loop1
		j main2
	limite2:
		li $a2, 10
		j continua

CalcularRisco:
#a0 temperatura, a1 fumaça, v0 risco]
	li $t1, 0
	mul $a0, $a0, 18
	mul $a1, $a1, 32
	add $t1, $a1, $a0
	div $t1, $t1, 120
	bgt $t1, 100, limite
	
	endFunc2:
		move $v0, $t1
		jr $ra
	limite:
		li $t1, 100
		j endFunc2
		
OutputAlarme:
#a0 Risco
	move $t1, $a0
	la $a0, ResultadoAlarme1
	li $v0, 4
	syscall
	move $a0, $t1
	li $v0, 1
	syscall
	li $v0, 4
	la $a0, ResultadoAlarme2
	syscall
	la $a0, Estado
	syscall
	bgt $t1, 10, atencao
	la $a0, Normal
	syscall
	jr $ra
	atencao:
	bgt $t1, 30, alerta
	la $a0, Atencao
	syscall
	jr $ra
	alerta:
	bgt $t1, 50, evacuacao
	la $a0, Alerta
	syscall
	jr $ra
	evacuacao:
	la $a0, Evacuacao
	syscall
	jr $ra
	
ErroDeLeitura:
	la $a0, ErroLeitura
	li $v0, 4
	syscall
	j main2
Erro2:
	la $a0, ErroListarLeitura
	li $v0, 4
	syscall
	j main2


acionarAlarmeManualmente:
	li $t4, 100
	li $v0, 4
	la $a0, ResultadoAlarme1
	syscall
	li $v0, 1
	move $a0, $t4
	syscall
	li $v0, 4
	la $a0, ResultadoAlarme2
	syscall
	la $a0, Estado
	syscall
	la $a0, Evacuacao
	syscall 
	la $a0, Manual
	syscall
	j main2

Encerrar:
	li $v0, 10
	syscall
