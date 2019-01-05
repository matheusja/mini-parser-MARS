.include "header.asm"

.eqv iShowParCode  0
.eqv iShowTreeCode 1
.eqv iShowRPN      2
.eqv iShowValue    3

.macro UnstackingPriority(%iPriorityMask)
  move $s0 rReturnCode
  UnstackingPriorityLoop:
    jal peekToken
    nop
    andi $t0 rReturn %iPriorityMask
    beq $t0 $zero UnstackingPriorityOut
    nop
    beq $s7 $sp   UnstackingPriorityOut
    nop
    move rCode rReturnCode
    jal pushOP
    nop
    jal popToken
    nop
  j UnstackingPriorityLoop
  nop
  UnstackingPriorityOut:
    move rCode $s0
    jal pushToken
    nop
.end_macro

.data
  ptr:	.word 0
  space: .space 0x200000
  prompt_file: .asciiz "Digite o nome do arquivo a ser lido(ou nao coloque nada para indicar que deve ser lida a entrada padrao):"
  prompt_filename_too_big: .asciiz "Nome do arquivo muito grande(maximo 255 caracteres)"
  prompt_expr: .asciiz "Digite a expressao a ser lida:"
  prompt_what_do: .asciiz "O que fazer?\n0-Colocar a paretensis na expressao.\n1-Mostrar(em notacao) a arvore sintatica\n2-Escrever em notacao polonesa reversa\n3-Calcular o valor"
  prompt_what_now: .asciiz "Desja fazer outro 'parseamento'?"
  prompt_value: .asciiz "O valor obtido eh: "
.text
start:
move $s7 $sp

li rSyscall iInputDialogString
la rDialogString prompt_file
la rDialogInputBuffer input_file
li rDialogBufferSize   iFileNameSizeM1
syscall

beq rDialogStatusReturn iDialogStatusCancel out
nop
beq rDialogStatusReturn iDialogStatusNoInput LerTerminal
nop
beq rDialogStatusReturn iDialogStatusOK OpenFile
nop
li rSyscall iMessageDialog
la rDialogString prompt_filename_too_big
syscall
# Indicar que iremos ler 
LerTerminal:
li $t0 1
sw $t0 read_from_terminal

li rSyscall iInputDialogString
la rDialogString prompt_expr
la rDialogInputBuffer buffer
li rDialogBufferSize iBufferSize
syscall

j configOut 
nop
OpenFile:
#Retirar o '\n' do nome do arquivo
la $t0 input_file
lbu $t1 0($t0)
#Se for so um '\n' o nome do arquivo entao vamos ler do terminal
beq $t1 iASCII_NEWLINE LerTerminal
nop
OverwriteNewLineLoop:
  addi $t0 $t0 1
  lbu $t1 0($t0)
  beq $t1 0 OverwriteNewLineOut
  nop
  beq $t1 iASCII_NEWLINE OverwriteNewLine
  nop
j OverwriteNewLineLoop
nop
OverwriteNewLine:
li $t1 0
sb $t1 0($t0)
OverwriteNewLineOut:
jal openInputFile
nop
beq rReturn iSyscallErrorOpenFile errorFile
nop
configOut:

#Usarei o algoritmo Shunting Yard com algumas modificacoes
#https://en.wikipedia.org/wiki/Shunting-yard_algorithm
#E->E op E | (E) | N
# first(E)     =  N, (
# follow(E)    = op, ), EOF
# follow(N)    = op, ), EOF
# follow(')')  = op, ), EOF
# follow('(')  = N, (
# follow(op)   = N, (
#Isso descreve a mesma linguagem que o parser entende, soh que eh
#Eu espero um numero ou um abre parentesis
ShuntingLoopNum:
  jal nextToken
  nop
  beq rReturn iEOF erroEOF
  nop
  #Se for um numero, colocar na saida(no caso, montar arvore)   
  bne rReturn iNum ShuntingNotNum
  nop
    move rVal rReturnVal
    jal pushNUM
    nop
    j ShuntingLoopOp
  ShuntingNotNum:
  bne rReturn iOPAR ShuntingNotOPAR
  nop
    move rCode rReturnCode
    jal pushToken
    nop
    j ShuntingLoopNum
    nop
  ShuntingNotOPAR:
	j errorNumExpected
	nop
ShuntingLoopOp:
  jal nextToken
  nop
  beq rReturn iEOF ShuntingOut
  nop
  andi $t0 rReturn iPriorityMask1
  beq $t0 $zero  ShuntingNotOP1
  nop
    #Fazer um macro eh mais estrategico
    UnstackingPriority(iPriorityMaskOver1)
  j ShuntingLoopNum
  nop
  ShuntingNotOP1:
  andi $t0 rReturn iPriorityMask2
  beq $t0 $zero ShuntingNotOP2
  nop
    UnstackingPriority(iPriorityMaskOver2)
  j ShuntingLoopNum
  nop
  ShuntingNotOP2:
  bne rReturn iCPAR ShuntingNotCPAR
  nop
  #Tudo menos parentesis
  UnstackParLoop:
    beq $s7 $sp erroParentesis
    nop
    jal peekToken
    nop
    beq rReturnCode iOPAR UnstackParOut
    nop 
    move rCode rReturnCode
    jal pushOP
    nop
    jal popToken
    nop
  j UnstackParLoop
  nop
  UnstackParOut:
  jal popToken
  nop
  j ShuntingLoopOp
  nop
  ShuntingNotCPAR:
  
ShuntingOut:
lw $t0 read_from_terminal
bne $t0 $zero skipCloseFile
nop
jal closeInputFile
nop
skipCloseFile:
#Desempilhar tudo
UnstackLoop:
beq $s7 $sp UnstackOut
nop
  jal peekToken
  nop
  beq rReturnCode iOPAR erroParentesis
  nop
  move rCode rReturnCode
  jal pushOP
  nop
  jal popToken
  nop
j UnstackLoop
nop
UnstackOut:
loopDoThings:
li rSyscall iInputDialogInt
la rDialogString prompt_what_do
syscall
bne rDialogStatusReturn iDialogStatusOK askWhatElse
bne rDialogReturn iShowParCode notCodeGen
nop
  jal getAST
  nop
  move rASTArg rASTReturn
  jal codeGenUgly
  nop
  li rSyscall iPrintChar
  li rOutChar iASCII_NEWLINE
  syscall
j loopDoThings
nop
notCodeGen:
bne rDialogReturn iShowTreeCode notTreeGen
nop
  jal getAST
  nop
  move rASTArg rASTReturn
  jal codeGenTree
  nop
	printChar(iASCII_NEWLINE)
j loopDoThings
nop
notTreeGen:
bne rDialogReturn iShowRPN notRPNGen
nop
  jal getAST
  nop
  move rASTArg rASTReturn
  jal codeGenRPN
  nop
  printChar(iASCII_NEWLINE)
j loopDoThings
nop
notRPNGen:
bne rDialogReturn iShowValue notShowValue
nop
  jal getAST
  nop
  move rASTArg rASTReturn
  jal eval
  nop
  move rDialogInt rReturn
  li rSyscall iMessageDialogInt
  la rDialogIntString prompt_value
  syscall
j loopDoThings
nop
notShowValue:
askWhatElse:

li rSyscall iConfirmDialog
la rDialogString prompt_what_now
syscall

bne rDialogConfirmReturn iDialogConfirmYes out
nop
reconfig:
#Reconfiguar o programa para outra execucao
li $t0 0
sw $t0 ptr
sw $t0 buffer_pos
sw $t0 read_from_terminal
la $t1 buffer
cleanBufferLoop:
lw $t2 0($t1)
beq $t2 $zero cleanBufferOut
nop
  sw $t0 0($t1)
  addi $t1 $t1 4
j cleanBufferLoop
nop
cleanBufferOut:
j start
nop
out:
li rSyscall iExitCode
syscall
.include "lexer.asm"
.include "ast.asm"
erroParentesis:
  error(erroLackParentesis)
erroEOF:
  error(erroUnexpectedEOF)
errorNumExpected:
  error(erroNumOPARExpected)
errorOpExpexted:
  error(erroOPCPARExpected)
	
