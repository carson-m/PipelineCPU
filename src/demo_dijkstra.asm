.text
main:
# Parameters
addi $a0, $zero, 6  # set $a0 to n , n = 6
sw   $a0, 0($zero)  # store n to 0x00000000
addi $a1, $zero, 4  # set $a1 to &graph = 0x00000004
addi $a2, $zero, 800 # $a2 = &dist[]
addi $a3, $zero, 840 # $a3 = &visited[]

# StoreGraph
addi $t1, $a1, 0
#Row 1
li $t0, 0	#Weight of edges
sw $t0, 0($t1)
addi $t1, $t1, 4
li $t0, 9
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 3
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 6
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, -1
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, -1
sw $t0, 0($t1)

#Row 2
addi $t1, $t1, 108 #128-20
li $t0, 9
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 0
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, -1
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 3
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 4
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 1
sw $t0, 0($t1)	

#Row 3
addi $t1, $t1, 108 #256-128-20
li $t0, 3
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, -1
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 0
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 2
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, -1
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 5
sw $t0, 0($t1)	

#Row 4
addi $t1, $t1, 108
li $t0, 6
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 3
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 2
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 0
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 6
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, -1
sw $t0, 0($t1)	

#Row 5
addi $t1, $t1, 108
li $t0, -1
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 4
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, -1
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 6
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 0
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 2
sw $t0, 0($t1)	

#Row 6
addi $t1, $t1, 108
li $t0, -1
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 1
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 5
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, -1
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 2
sw $t0, 0($t1)	
addi $t1, $t1, 4
li $t0, 0
sw $t0, 0($t1)	

# Call Dijkstra
jal  dijkstra

# Sum up results
addi $t0, $zero, 0 #Counter
addi $t1, $a2, 0 #Address
addi $v0, $zero, 0 #Result
sumuploop:
beq $t0, $a0, printrslt
lw $t2, 0($t1)
addi $t0, $t0, 1
addi $t1, $t1, 4
add $v0, $v0, $t2 #result is stored in $v0
j sumuploop

# Print results
printrslt:
li $t3, 0x40000010 #BCDAddress 0x40000010
addi $t1, $zero, 2048 #AN init = b 1000 0000 0000
li $t2, 10000 #delay timer
addi $t4, $zero, 256
addi $t5, $zero, 512
addi $t6, $zero, 2048

refreshdelay:
addi $t2, $t2, -1
bgtz $t2, refreshdelay
addi $t2, $zero, 10000

getAN:
beq $t1, $t6, getdigit0
beq $t1, $t4, getdigit1
beq $t1, $t5, getdigit2
#getdigit3
andi $t0, $v0, 0xf000 #get [15:12]
srl $t0, $t0, 12
sll $t1, $t1, 1
j determinedisp
getdigit2:
andi $t0, $v0, 0x0f00 #get [11:8]
srl $t0, $t0, 8
sll $t1, $t1, 1
j determinedisp
getdigit1:
andi $t0, $v0, 0x00f0 #get [7:4]
srl $t0, $t0, 4
sll $t1, $t1, 1
j determinedisp
getdigit0:
andi $t0, $v0, 0x000f #get [3:0]
addi $t1, $zero, 256

determinedisp: #Binary Search
addi $t7, $t0, -7
bgtz $t7, gt7
beq $t0, 0x0 disp0
beq $t0, 0x1 disp1
beq $t0, 0x2 disp2
beq $t0, 0x3 disp3
beq $t0, 0x4 disp4
beq $t0, 0x5 disp5
beq $t0, 0x6 disp6
beq $t0, 0x7 disp7
gt7:
beq $t0, 0x8 disp8
beq $t0, 0x9 disp9
beq $t0, 0xa dispA
beq $t0, 0xb dispB
beq $t0, 0xc dispC
beq $t0, 0xd dispD
beq $t0, 0xe dispE
beq $t0, 0xf dispF

disp0:
	li $t7, 0x3f
	add $t7, $t7, $t1	
	sw $t7, 0($t3)
	j refreshdelay
disp1:
	li $t7, 0x6
	add $t7, $t7, $t1	
	sw $t7, 0($t3)
	j refreshdelay
disp2:
	li $t7, 0x5b
	add $t7, $t7, $t1	
	sw $t7, 0($t3)
	j refreshdelay
disp3:
	li $t7, 0x4f
	add $t7, $t7, $t1	
	sw $t7, 0($t3)
	j refreshdelay
disp4:
	li $t7, 0x66
	add $t7, $t7, $t1	
	sw $t7, 0($t3)
	j refreshdelay
disp5:
	li $t7, 0x6d
	add $t7, $t7, $t1	
	sw $t7, 0x666($t3)
	j refreshdelay
disp6:
	li $t7, 0x7d
	add $t7, $t7, $t1	
	sw $t7, 0($t3)
	j refreshdelay
disp7:
	li $t7, 0x7
	add $t7, $t7, $t1
	sw $t7, 0($t3)
	j refreshdelay
disp8:
	li $t7, 0x7f
	add $t7, $t7, $t1	
	sw $t7, 0($t3)
	j refreshdelay
disp9:
	li $t7, 0x67
	add $t7, $t7, $t1	
	sw $t7, 0($t3)
	j refreshdelay
dispA:
	li $t7, 0x77
	add $t7, $t7, $t1	
	sw $t7, 0($t3)
	j refreshdelay
dispB:
	li $t7, 0x7c
	add $t7, $t7, $t1	
	sw $t7, 0($t3)
	j refreshdelay
dispC:
	li $t7, 0x39
	add $t7, $t7, $t1	
	sw $t7, 0($t3)
	j refreshdelay
dispD:
	li $t7, 0x5e
	add $t7, $t7, $t1
	sw $t7, 0($t3)
	j refreshdelay
dispE:
	li $t7, 0x79
	add $t7, $t7, $t1
	sw $t7, 0($t3)
	j refreshdelay
dispF:
	li $t7, 0x71
	add $t7, $t7, $t1	
	sw $t7, 0($t3)
	j refreshdelay

dijkstra:
##### YOUR CODE HERE #####
#a0=n
#a1=&graph
#a2=&dist
#a3=&visited
addi $t0, $a2, 0 #t0=&dist
addi $t1, $a3, 0 #t1=&visited
sw $zero, 0($t0) #dist[0]=0
li $t2, 1 #暂存1，之后当作i使用(i=1),不推荐这么写
sw $t2, 0($t1) #visited[0]=1
addi $t3, $t0, 4 #&dist[1]
addi $t4, $t1, 4 #&visited[1]
addi $t5, $a1, 4 #&graph[1]
for0:
bge $t2, $a0, endfor0 #不满足i<n则退出循环
lw $t6, 0($t5) #graph[i]
sw $t6, 0($t3) #dist[i]=graph[i]
sw $zero, 0($t4) #visited[i]=0
addi $t3, $t3, 4 #&dist[i+1]
addi $t4, $t4, 4 #&visited[i+1]
addi $t5, $t5, 4 #&graph[i+1]
addi $t2, $t2, 1 #i++
j for0 #循环
endfor0:
li $t2, 1 #i=1
for1:
bge $t2, $a0, endfor1 #不满足i<n则退出循环
#####外层for内容
 li $t3, -1 #u=-1
 li $t4, -1 #min_dist=-1
 li $t5, 1 #v=1
 for2:
 bge $t5, $a0, endfor2 #不满足i<n则退出循环
 #####内层第一个for内容
  sll $t6, $t5, 2 #4v
  add $t6, $t6, $t1 #&visited[v]
  lw $t6, 0($t6) #visited[v]
  sll $t7, $t5, 2 #4v
  add $t7, $t7, $t0 #&dist[v]
  lw $t7, 0($t7) #dist[v]
  bne $t6, 0, continue2 #if (visited[v] != 0) continue
  beq $t7, -1, continue2 #if (dist[v] == -1) continue
  beq $t4, -1, if2 #if (min_dist == -1 || dist[v] < min_dist)
  blt $t7, $t4, if2
  j continue2 #若两条件均不满足，跳过if内容
  if2:
  ###if2内容开始
   move $t4, $t7 #min_dist=dist[v]
   move $t3, $t5 #u=v
  ###if2内容结束
 #####内层第一个for内容结束
 continue2:
 addi $t5, $t5, 1 #v++
 j for2 #循环
 endfor2:
 bne $t4, -1, endif3 #if (min_dist == -1)
 jr $ra #return
 endif3:
 #Update
 sll $t6, $t3, 2 #4u
 add $t6, $t6, $t1 #&visited[u]
 li $t7, 1
 sw $t7, 0($t6) #visited[u] = 1
 li $t5, 1 #v=1
 for3:
 bge $t5, $a0, endfor3 #不满足v<n则退出循环
 #####内层第二个for内容
  sll $t6, $t5, 2 #4v
  add $t6, $t6, $t1 #&visited[v]
  lw $t6, 0($t6) #visited[v]
  bnez $t6, continue3 #if (visited[v] != 0) continue
  sll $t6, $t3, 5 #addr = (u << 5)
  add $t6, $t6, $t5 #addr = (u << 5) + v
  sll $t6, $t6, 2 #4addr
  add $t6, $t6, $a1 #&graph[addr]
  lw $t6, 0($t6) #graph[addr]
  beq $t6, -1, continue3 #if (graph[addr] == -1) continue
  sll $t7, $t5, 2 #4v
  add $t7, $t7, $t0 #&dist[v]
  lw $t8, 0($t7) #dist[v]
  add $t6, $t6, $t4 #min_dist + graph[addr]
  beq $t8, -1, if3 #if (dist[v] == -1 || dist[v] > min_dist + graph[addr])
  bgt $t8, $t6, if3
  j continue3 #若两条件均不满足，跳过if3内容
  if3:
  ###最后一个if内容
  sw $t6, 0($t7) #dist[v] = min_dist + graph[addr]
  ###最后一个if内容结束
 #####内层第二个for内容结束
 continue3:
 addi $t5, $t5, 1 #v++
 j for3 #循环
 endfor3:
 #Update Ends
#####外层for内容结束
addi $t2, $t2, 1 #i++
j for1 #
endfor1:
jr $ra #return
