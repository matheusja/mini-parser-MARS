.eqv PROX_POS   0
.eqv CODE_POS   4
.eqv VAL_POS    8
.eqv LEFT_POS   8
.eqv RIGHT_POS 12
.eqv AST_SIZE  16

.macro printSimpleBinaryOp($ast, %str)
	PEEK($ast)
  lw $ast LEFT_POS($ast)
  jal codeGenUgly
  nop
  printChar(%str)
  PEEK($ast)
  lw $ast RIGHT_POS($ast)
  jal codeGenUgly
  nop
.end_macro
.macro printUglyBinaryOp($ast, %str)
	printChar(iASCII_OPAR)
	printSimpleBinaryOp($ast, %str)
	printChar(iASCII_CPAR)
.end_macro
.macro printTreeOp($ast, %str)
  printChar(%str)
  PEEK($ast)
  lw $ast LEFT_POS($ast)
  jal codeGenTree
  nop
  PEEK($ast)
  lw $ast RIGHT_POS($ast)
  jal codeGenTree
  nop
.end_macro
.macro printRPNOp($ast, %str)
  PEEK($ast)
  lw $ast LEFT_POS($ast)
  jal codeGenRPN
  nop
  PEEK($ast)
  lw $ast RIGHT_POS($ast)
  jal codeGenRPN
  nop
  printChar(%str)
.end_macro
.macro evalArgs
  lw rASTArg LEFT_POS(rASTArg)
  jal eval
  nop
  PEEK(rASTArg)
  PUSH(rReturn)
  lw rASTArg RIGHT_POS(rASTArg)
  jal eval
  nop
  POP($t0)
.end_macro
.text
#	Num = {
#		.word Prox	
#		.word Code  0
#		.word val		
#		.space 			4(nao usado)
# }
# 16 Bytes

pushNUM:
	la $t0 space
	lw $t1 ptr
	add $t0 $t0 $t1
	bne $t1 $zero continuarPush
	nop
	sw $zero PROX_POS($t0)
	j pularPushProx
	nop
	continuarPush:
  addi $t2 $t0 -AST_SIZE
  sw $t2 PROX_POS($t0)
  pularPushProx:
  sw $zero CODE_POS($t0)
  sw rVal  VAL_POS($t0)
  addi $t1 $t1 AST_SIZE
  sw $t1 ptr
jr $ra
nop
#	OP = {
#		Prox
#		Code 			!= 0
#		LeftArg		!= 0
# 	RightArg	!= 0
# }
# 16 Bytes
pushOP:
	lw $t1 ptr
	la $t0 space
	add $t0 $t0 $t1
	#Vai ser algo do tipo: ...|arvore 0|arvore 1|arvore 2|operador
	#Operador.right = arvore 2 = ultimo elemento inserido = $t2
	addi $t2 $t0 -AST_SIZE
	#Operador.left = arvore 1 = $t2.prox = $t3
	lw $t3    PROX_POS($t2)
	#Operador.prox = arvore 0 = $t3.prox = $t4
	lw $t4    PROX_POS($t3)
	sw $t4    PROX_POS($t0)
	sw rCode  CODE_POS ($t0)
	sw $t3    LEFT_POS ($t0)
	sw $t2    RIGHT_POS($t0)
	addi $t1 $t1 AST_SIZE
	sw $t1 ptr
jr $ra
nop
getAST:
	lw rReturn2 ptr
	la rReturn  space
	add rReturn rReturn rReturn2
	addi rReturn rReturn -AST_SIZE
jr $ra
nop

codeGenUgly:
  PUSH($ra)
  PUSH(rASTArg)
  lw $t0 CODE_POS(rASTArg)
  bne $t0 iNum codeGenUglyNotNum
  nop
    li rSyscall iPrintInteger
    lw rIntegerPrint VAL_POS(rASTArg)
    syscall
  j codeGenUglyOut
  nop
  codeGenUglyNotNum:
  #Se nao eh um numero, entao temos uma recursao
  bne $t0 iSum codeGenUglyNotSum
  nop
    printUglyBinaryOp(rASTArg, iASCII_SUM)
  j codeGenUglyOut
  nop
  codeGenUglyNotSum:
  
  bne $t0 iSub codeGenUglyNotSub
  nop
    printUglyBinaryOp(rASTArg, iASCII_SUB)
  j codeGenUglyOut
  nop
  codeGenUglyNotSub:
  
  bne $t0 iMult codeGenUglyNotMult
  nop
    printUglyBinaryOp(rASTArg, iASCII_MULT)
  j codeGenUglyOut
  nop
  codeGenUglyNotMult:
  
  bne $t0 iDiv codeGenUglyNotDiv
  nop
    printUglyBinaryOp(rASTArg, iASCII_DIV)
  j codeGenUglyOut
  nop
  codeGenUglyNotDiv:
  codeGenUglyOut:
  POP(rASTArg)
  POP($ra)
jr $ra
nop

codeGenTree:
  PUSH($ra)
  PUSH(rASTArg)
	printChar(iASCII_OBRACK)
	PEEK(rASTArg)
  lw $t0 CODE_POS(rASTArg)
  bne $t0 iNum codeGenTreeNotNum
  nop
    li rSyscall iPrintInteger
    lw rIntegerPrint VAL_POS (rASTArg)
    syscall
  j codeGenTreeOut
  nop
  codeGenTreeNotNum:
  #Se nao eh um numero, entao temos uma recursao
  bne $t0 iSum codeGenTreeNotSum
  nop
    printTreeOp(rASTArg, iASCII_SUM)
  j codeGenTreeOut
  nop
  codeGenTreeNotSum:
  
  bne $t0 iSub codeGenTreeNotSub
  nop
    printTreeOp(rASTArg, iASCII_SUB)
  j codeGenTreeOut
  nop
  codeGenTreeNotSub:
  
  bne $t0 iMult codeGenTreeNotMult
  nop
    printTreeOp(rASTArg, iASCII_MULT)
  j codeGenTreeOut
  nop
  codeGenTreeNotMult:
  
  bne $t0 iDiv codeGenTreeNotDiv
  nop
    printTreeOp(rASTArg, iASCII_DIV)
  j codeGenTreeOut
  nop
  codeGenTreeNotDiv:
  codeGenTreeOut:
  
	printChar(iASCII_CBRACK)
  POP(rASTArg)
  POP($ra)
jr $ra
nop
codeGenRPN:
  PUSH($ra)
  PUSH(rASTArg)
  lw $t0 CODE_POS(rASTArg)
  bne $t0 iNum codeGenRPNNotNum
  nop
    li rSyscall iPrintInteger
    lw rIntegerPrint VAL_POS(rASTArg)
    syscall
  j codeGenRPNOut
  nop
  codeGenRPNNotNum:
  #Se nao eh um numero, entao temos uma recursao
  bne $t0 iSum codeGenRPNNotSum
  nop
    printRPNOp(rASTArg, iASCII_SUM)
  j codeGenRPNOut
  nop
  codeGenRPNNotSum:
  
  bne $t0 iSub codeGenRPNNotSub
  nop
    printRPNOp(rASTArg, iASCII_SUB)
  j codeGenRPNOut
  nop
  codeGenRPNNotSub:
  
  bne $t0 iMult codeGenRPNNotMult
  nop
    printRPNOp(rASTArg, iASCII_MULT)
  j codeGenRPNOut
  nop
  codeGenRPNNotMult:
  
  bne $t0 iDiv codeGenRPNNotDiv
  nop
    printRPNOp(rASTArg, iASCII_DIV)
  j codeGenRPNOut
  nop
  codeGenRPNNotDiv:
  codeGenRPNOut:
  printChar(iASCII_SPACE)
  POP(rASTArg)
  POP($ra)
jr $ra
nop
eval:
  PUSH($ra)
  PUSH(rASTArg)
  lw $t0 CODE_POS(rASTArg)
  bne $t0 iNum evalNotNum
  nop
    lw rReturn VAL_POS(rASTArg)
  j evalOut
  nop
  evalNotNum:
  #Se nao eh um numero, entao temos uma recursao
  bne $t0 iSum evalNotSum
  nop
    evalArgs()
    add rReturn rReturn $t0
  j evalOut
  nop
  evalNotSum:
  
  bne $t0 iSub evalNotSub
  nop
    evalArgs()
    sub rReturn $t0 rReturn
  j evalOut
  nop
  evalNotSub:
  
  bne $t0 iMult evalNotMult
  nop
    evalArgs()
    mult rReturn $t0
    mflo rReturn
  j evalOut
  nop
  evalNotMult:
  
  bne $t0 iDiv evalNotDiv
  nop
    evalArgs()
    div $t0 rReturn
    mflo rReturn
  j evalOut
  nop
  evalNotDiv:
  evalOut:
  POP(rASTArg)
  POP($ra)
jr $ra
nop





