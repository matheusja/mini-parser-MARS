.eqv rSyscall    $v0
.eqv rReturn     $v0
.eqv rReturn2    $v1

.eqv rReturnCode $v0
.eqv rReturnVal  $v1


# Syscall Codes
.eqv iPrintInteger 1
.eqv iPrintString  4
.eqv iReadInteger  5
.eqv iReadString   8
.eqv iExitCode     10
.eqv iPrintChar    11
.eqv iOpenFileCode 13
.eqv iReadFileCode 14
.eqv iWriteCode    15
.eqv iCloseCode    16
.eqv iExitValCode  17
.eqv iConfirmDialog     50
.eqv iInputDialogInt    51
.eqv iInputDialogString 54
.eqv iMessageDialog     55
.eqv iMessageDialogInt  56


.eqv rDescriptorR  $v0 #Retorno de open file
.eqv rFilename 		 $a0 #Parametro da string
.eqv rDescriptorP  $a0 #Parametro do descritor read/write/close file
.eqv rFlag				 $a1 #Parametro das flags
.eqv rString 			 $a1 #Endereco em que sera colocada a string lida, ou da string que sera escrita
.eqv rNumChar 		 $a2 #Quatidade  de carcateres a serem lidos/escritos
.eqv rExitVal      $a0 #Registrador parametro do codigo de saida
.eqv rASTReturn    $v0 #O ponteiro para AST gerada
.eqv rASTArg       $a0 #Colocar aqui a AST para rodar o codeGen
.eqv rStringPrint  $a0 #Endereco da string que sera imprimida
.eqv rIntegerPrint $a0 #Inteiro a ser imprimido
.eqv rDialogString      $a0 #String que sera mostrada no popup
.eqv rDialogInputBuffer $a1 #Onde sera colocada a string lida no popup
.eqv rDialogBufferSize  $a2 #O tamanho maximo do buffer
.eqv rDialogStatusReturn $a1 #Onde os status ira retornar
.eqv rDialogMessageType  $a1 #Qual eh o status da mensagem(erro, informacao, warning)
.eqv rDialogReturn        $a0 #Onde colocamos o que o usuario coloca na caixa de popup
.eqv rDialogConfirmReturn $a0 #Onde colocamos o que a caixa de confirmacao retorna
.eqv rDialogIntString     $a0 #Onde colocamos a String a ser escrita antes do numero
.eqv rDialogInt           $a1 #Onde colocamos o Int a ser escrito
.eqv rOutChar             $a0 #Charactere a ser imprimido

#Valores possiveis do rFlag
.eqv iReadFlag 	0
.eqv iWriteFlag	1
#Codigo de error na hora em que foi aberto um arquivo
.eqv iSyscallErrorOpenFile -1

.eqv iDialogStatusOK           0 #OK
.eqv iDialogStatusCancel      -2 #Usuario clicou "cancelar"
.eqv iDialogStatusNoInput     -3 #Usuario clicou "OK" sem colocar nada
.eqv iDialogStatusInputTooBig -4 #Usuario colocou um texto maior que o permitido

# Tipo de popup
.eqv iDialogTypeError 0
.eqv iDialogTypeInf   1
.eqv iDialogTypeWarn  2
.eqv iDialogTypeQues  3

# Retorno da caixa de confirmacao
.eqv iDialogConfirmYes    0
.eqv iDialogConfirmNo     1
.eqv iDialogConfirmCancel 2

#Codigos adotados nos tokens e na Arvore Sintatica Abstrata(Abstract Sintax Tree, AST)
.eqv iNum  0x0000
.eqv iSum  0x0001
.eqv iSub  0x0002
.eqv iMult 0x0010
.eqv iDiv  0x0020
#Codigos adotados nos tokens
.eqv iOPAR 0x1000
.eqv iCPAR 0x2000
.eqv iEOF  0x8000
#Mascaras que podem ser uteis
.eqv iPriorityMask1 0x000F
.eqv iPriorityMask2 0x00F0
.eqv iPriorityMaskOver1 0x0FFF
.eqv iPriorityMaskOver2 0x0FF0
#Parametros de entrada para as subrotinas pushNUM e pushOP
.eqv rNum  $a0
.eqv rCode $a0
.eqv rVal  $a1
#Alguns codigos ASCII uteis
.eqv iASCII_TAB     0x09
.eqv iASCII_NEWLINE 0x0A
.eqv iASCII_CR      0x0D
.eqv iASCII_SPACE   0x20
.eqv iASCII_COMMENT 0x23
.eqv iASCII_SUM     0x2B
.eqv iASCII_SUB     0x2D
.eqv iASCII_MULT    0x2A
.eqv iASCII_DIV     0x2F
.eqv iASCII_0       0x30
.eqv iASCII_9       0x39
.eqv iASCII_9P      0x3A
.eqv iASCII_OPAR    0x28
.eqv iASCII_CPAR    0x29
.eqv iASCII_OBRACK  0x5B
.eqv iASCII_CBRACK  0x5D

# Maximo 65535 caracteres no buffer;
.eqv iBufferSize   0x10000
# O ultimo caracter eh um '\0'
.eqv iBufferSizeM1 0x0FFFF

#  Maximo 65535 caracteres no nome do arquivo a ser lido
.eqv iFileNameSize   0x10000
.eqv iFileNameSizeM1 0xFFFF


.macro printString(%str)
  li rSyscall iPrintString
  la rStringPrint %str
  syscall
.end_macro
.macro error(%string)
  li rSyscall iMessageDialog
  la rDialogString %string
  li rDialogMessageType iDialogTypeError
  syscall
  j askWhatElse
  nop
.end_macro
.macro printChar(%str)
	li rSyscall iPrintChar
	li rOutChar %str
  syscall
.end_macro
.macro PUSH($r)
  sw $r 0($sp)
  addi $sp $sp -4
.end_macro
.macro POP($r)
  addi $sp $sp 4
  lw $r 0($sp)
.end_macro
.macro PEEK($r)
  lw $r 4($sp)
.end_macro
.data
	erroBadCharDesc:      .asciiz "Erro: characterere desconhecido\n"
	erroUnexpectedEOF:    .asciiz "Erro: final de arquivo inesperado\n"
	erroLackParentesis:   .asciiz "Erro: falta fechar parentesis\n"
	erroNumOPARExpected:  .asciiz "Erro: esperava um '(' ou um numero\n"
	erroOPCPARExpected:   .asciiz "Erro: esperava um ')' ou um operador\n"
	erroOpenFile:         .asciiz "Erro: nao foi possivel abrir o arquivo\n"
	erroRead:             .asciiz "Erro: nao foi possivel ler arquiro\n"
.text


