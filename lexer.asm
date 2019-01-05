#Esse codigo interno eh para identificar que nao ha mais nada
#Note que seu codigo eh maior que todos os codigos ASCII
.eqv iEOFInternal 0x100

#Macro(usa o $at), ve se o valor de arg eh um digito e escreve o resultado em result
.macro isASCIINum($result, $arg)
  slti $result $arg iASCII_0
  slti $at rReturn iASCII_9P 
  xori $result $result 0x1
  and  $result $result $at
.end_macro
#Macro(n usa o $at), converte o digito arg(eu assumo que ele eh) em um numero binario
.macro ASCII2Num($result, $arg)
 addi $result $arg -iASCII_0
.end_macro

.data
  input_file: .space iFileNameSize
  file_descriptor: .word 0
  buffer_pos: .word 0
  buffer: .space iBufferSize
  temp: .space 4
  read_from_terminal: .word 0
.text

nextChar:
  checkBuffer:
  lw $t1 buffer_pos
  lbu $t0 buffer($t1)
  beq $t0 $zero read2buffer
  nop
  read2reg:
    la $t2 buffer
    add $t2 $t2 $t1
    lbu rReturn 0($t2)
    addi $t1 $t1 1
    sw $t1 buffer_pos
  jr $ra
  nop
  read2buffer:
    lw $t2 read_from_terminal
    beq $t2 1 nextCharReturnEOF
    nop
      li rSyscall iReadFileCode
      la rString buffer
      li rNumChar iBufferSizeM1
      lw rDescriptorP file_descriptor
      syscall
      sw $zero buffer_pos
      slti $t0 rReturn 0
      bne $t0 $zero erroLer
      nop
      bne rReturn $zero checkBuffer
        nop
        nextCharReturnEOF:
        #Final de arquivo
        li rReturn 0x100
      jr $ra
      nop
jr $ra
nop
#Pode ocorrer(na hora que eu leio um numero) que eu li um caractere a mais("1232+" eu acabo lendo o '+')
#Eu tenho que devolver '+', felizmente isso eh soh reduzir o buffer_pos
ungetChar:
  lw $t1 buffer_pos
  beq $t1 $zero ungetCharOut
  nop
  addi $t1 $t1 -1
  sw $t1 buffer_pos
ungetCharOut:
jr $ra
nop

ignoreComment:
  jal nextChar
  nop
  beq rReturn iASCII_NEWLINE ignoreWhiteSpace 
  nop
  beq rReturn iEOFInternal foundEOF
  nop
j ignoreComment
nop
nextToken:
  PUSH($ra)
  ignoreWhiteSpace:
  jal nextChar  
  
  #Ignorar '\t', '\n', ' ', CR(carriage return)
  nop
  beq rReturn iASCII_TAB     ignoreWhiteSpace
  nop
  beq rReturn iASCII_NEWLINE ignoreWhiteSpace
  nop
  beq rReturn iASCII_SPACE   ignoreWhiteSpace
  nop
  beq rReturn iASCII_CR      ignoreWhiteSpace
  nop
  #Reconhecer cometarios
  beq rReturn iASCII_COMMENT ignoreComment
  nop
  
  bne rReturn iEOFInternal nextTokenNotEOF
  nop
   foundEOF:
   li rReturnCode iEOF
   j nextTokenOut
  nop
  nextTokenNotEOF: 
  #Eh um '+'?
  bne rReturn iASCII_SUM  nextTokenNotSum
  nop
    li rReturnCode iSum
  j nextTokenOut
  nop
  nextTokenNotSum:
  
  #Eh um '-'?
  bne rReturn iASCII_SUB  nextTokenNotSub
  nop
    li rReturnCode iSub
  j nextTokenOut
  nop
  nextTokenNotSub:
  
  #Eh um '*'?
  bne rReturn iASCII_MULT nextTokenNotMult
  nop
    li rReturnCode iMult
  j nextTokenOut
  nop
  nextTokenNotMult:
  
  #Eh um '/'?
  bne rReturn iASCII_DIV  nextTokenNotDiv
  nop
    li rReturnCode iDiv
  j nextTokenOut
  nop
  nextTokenNotDiv:
  
  #Eh um '('?
  bne rReturn iASCII_OPAR nextTokenNotOPAR
  nop
    li rReturnCode iOPAR
  j nextTokenOut
  nop
  nextTokenNotOPAR:
  
  #Eh um ')'?
  bne rReturn iASCII_CPAR nextTokenNotCPAR
  nop
    li rReturnCode iCPAR
  j nextTokenOut
  nop
  nextTokenNotCPAR:
  
  #Soh pode ser um numero
  isASCIINum($t0, rReturn)
  beq $t0 $zero nextTokenNotNum
  nop
    li $s0 0
    li $s1 10
    loopParseInt:
      ASCII2Num($s2, rReturn)
      mult $s0 $s1
      mflo $s0
      add $s0 $s0 $s2
    jal nextChar
    nop
    isASCIINum($t0, rReturn)
    beq $t0 1 loopParseInt
    nop
    jal ungetChar
    nop
    li rReturnCode  iNum
    move rReturnVal $s0
  j nextTokenOut
  nop
  nextTokenNotNum:
  #Eu nao sei o que eh isso
  j badCharError
  nop
nextTokenOut:
POP($ra)
jr $ra
nop
closeInputFile:
  li rSyscall     iCloseCode
  lw rDescriptorP file_descriptor
  sw $zero        file_descriptor
  syscall
jr $ra
nop
openInputFile:
  li rSyscall iOpenFileCode
  la rFilename input_file
  li rFlag iReadFlag
  syscall
  sw rDescriptorR	file_descriptor
jr $ra
nop
pushToken:
  sw rCode 0($sp)
  sw rVal  4($sp)
  addi $sp $sp 8
jr $ra
nop	
popToken:
  addi $sp $sp -8
jr $ra
nop
peekToken:
  lw rReturnCode -8($sp)
  lw rReturnVal  -4($sp)
jr $ra
nop

badCharError:
  POP($ra)
  error(erroBadCharDesc)
erroLer:
  POP($ra)
  error(erroRead)
errorFile:
  error(erroOpenFile)
