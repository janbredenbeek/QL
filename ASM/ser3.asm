* 6850 ACIA DEVICE DRIVER
* USAGE: "SER3", "SER3E" OR "SER3O"
* FOR 8 BIT NOPARITY, 7 BIT EVEN OR 7 BIT ODD PARITY
* IN ALL CASES 1 STOP BIT

* QDOS CONSTANTS

MT_BAUD   EQU       $12
MT_ALCHP  EQU       $18
MT_LXINT  EQU       $1A
MT_LIOD   EQU       $20
MM_ALCHP  EQU       $C0
MM_RECHP  EQU       $C2
IO_QSET   EQU       $DC
IO_QTEST  EQU       $DE
IO_QIN    EQU       $E0
IO_QOUT   EQU       $E2
IO_SERIO  EQU       $EA
IO_NAME   EQU       $122

IO_PORT   EQU       $10000    ACIA I/O PORT, $10000 = CONTROL/STATUS,
*                             $10001 = TXDATA/RXDATA
RX_QUEUE  EQU       $18       RX QUEUE OFFSET IN CHANNEL
TX_QUEUE  EQU       $428      TX QUEUE OFFSET IN CHANNEL
QLEN      EQU       $410      QUEUE LENGTH (INCL. HEADER)
QADDR     EQU       $3A       OFFSET OF QUEUE POINTER IN LINKAGE BLOCK
SER_CTRL  EQU       $3E       COPY OF ACIA CONTROL REGISTER
LINKLEN   EQU       $40       LENGTH OF LINKAGE BLOCK

* Next line only necessary when assembling using GST or Quanta assembler

          SECTION   CODE


* INITIALISATION ROUTINE

          MOVE.B    #$4B,IO_PORT    RESET ACIA, RTS OFF
          MOVEQ     #LINKLEN,D1
          MOVEQ     #0,D2
          MOVEQ     #MT_ALCHP,D0
          TRAP      #1
          TST.L     D0
          BNE.S     INITEND
          MOVE.L    A0,A3           ; Linkage block
          LEA       DEV_INT,A1      ; External interrupt
          MOVE.L    A1,4(A3)
          LEA       $20(A3),A0
          LEA       DEV_OPEN,A1     ; Open routine
          MOVE.L    A1,(A0)+
          LEA       DEV_CLOSE,A1    ; Close routine
          MOVE.L    A1,(A0)+
          MOVE.L    A0,$1C(A3)      ; I/O routine
          MOVE.W    #$4EB8,(A0)+    ; Opcode for JSR xxxx.w
          MOVE.W    IO_SERIO,(A0)+  ; JSR IO.SERIO
          LEA       DEV_PEND,A1     ; Pending I/O
          MOVE.L    A1,(A0)+
          LEA       DEV_FETCH,A1    ; Fetch byte
          MOVE.L    A1,(A0)+
          LEA       DEV_SEND,A1     ; Send byte
          MOVE.L    A1,(A0)+
          MOVE.W    #$4E75,(A0)+    ; RTS instruction
          CLR.L     (A0)+
          LEA       $18(A3),A0
          MOVEQ     #MT_LIOD,D0     ; Link in driver
          TRAP      #1
          MOVE.L    A3,A0
          MOVEQ     #MT_LXINT,D0    ; Link in external interrupt
          TRAP      #1
          MOVE.W    #4800,D1        ; We get BAUD clock from BAUDx4 signal
          MOVEQ     #MT_BAUD,D0     ; so set 4800 for 1200 baud!
          TRAP      #1
          MOVEQ     #0,D0
INITEND   RTS

DEV_OPEN  MOVE.L    A3,A5
          SUBQ.W    #6,A7
          MOVE.L    A7,A3
          MOVE.W    IO_NAME,A2
          JSR       (A2)      DECODE NAME
          BRA.S     OP_QUIT   IF "NOT FOUND"
          BRA.S     OP_QUIT   IF "BAD NAME"
          BRA.S     OP_OK     IF "OK"
          DC.W      4         LENGTH OF "SER3"
          DC.B      'SER3'    DEVICE NAME
          DC.W      3         3 PARAMETERS
          DC.W      2         2 POSSIBLE CHARACTERS
          DC.B      'EO'      "E"VEN OR "O"DD
          DC.W      2
          DC.B      'IH'      *NOTE*: THE "HANDSHAKE" AND "PROTOCOL"
          DC.W      3         PARAMETERS ARE ACCEPTED FOR SER1/2 
          DC.B      'RZC'     COMPATIBILITY BUT ARE CURRENTLY IGNORED.
OP_OK     MOVEQ     #-9,D0
          TST.L     QADDR(A5)
          BNE.S     OP_QUIT   "IN USE"
          MOVE.L    #RX_QUEUE+2*QLEN,D1
          MOVE.W    MM_ALCHP,A2
          JSR       (A2)      MAKE ROOM FOR CHANNEL
          BNE.S     OP_QUIT
          LEA       RX_QUEUE(A0),A2
          MOVE.L    A2,QADDR(A5)
          MOVE.L    #$400,D1
          MOVE.W    IO_QSET,A1
          JSR       (A1)      SET UP QUEUES
          LEA       TX_QUEUE(A0),A2
          MOVE.W    IO_QSET,A1
          JSR       (A1)
          MOVEQ     #$95,D1   8 BIT, NOPARITY, 1 STOP, RX INT ON
          MOVE.W    (A7),D0
          BEQ.S     SET_PAR   IF NO PARAMETER
          MOVEQ     #$89,D1   7 BIT EVEN PARITY, 1 STOP, RX INT ON
          SUBQ.B    #1,D0
          LSL.B     #2,D0     D0 = 0 FOR EVEN, 4 FOR ODD
          OR.B      D0,D1
SET_PAR   MOVE.B    D1,SER_CTRL(A5)
          MOVE.B    D1,IO_PORT
          MOVEQ     #0,D0
OP_QUIT   ADDQ.W    #6,A7
          RTS

DEV_CLOSE MOVEQ     #$43,D0
          OR.B      SER_CTRL(A3),D0
          MOVE.B    D0,IO_PORT          RESET ACIA, RTS OFF
          CLR.L     QADDR(A3)
          MOVE.W    MM_RECHP,A2
          JMP       (A2)                RECLAIM CHANNEL

DEV_PEND  MOVE.W    IO_QTEST,A4
          BRA.S     GETQ
DEV_FETCH MOVE.W    IO_QOUT,A4
GETQ      LEA       RX_QUEUE(A0),A2
          JMP       (A4)
DEV_SEND  MOVE.L    A3,A5
          LEA       TX_QUEUE(A0),A2
          MOVE.W    IO_QIN,A1
          JSR       (A1)
          BNE.S     SEND_RTS
          MOVEQ     #$20,D2
          OR.B      SER_CTRL(A5),D2
          MOVE.B    D2,IO_PORT          ENABLE TX INTERRUPTS
SEND_RTS  RTS

* External interrupt handler

DEV_INT   MOVE.L    A3,A5
          LEA       IO_PORT,A4
          MOVE.B    (A4),D7
          BPL.S     INT_END   IF NO ACIA INTERRUPT
          MOVE.L    QADDR(A5),D6
          MOVE.B    1(A4),D1  GET BYTE FROM RXDATA REGISTER
          BTST      #0,D7
          BEQ.S     INT_TX    IF NO RX INTERRUPT
          BTST      #4,D7
          BNE.S     INT_TX    IGNORE CHR IF FRAMING ERROR
          BTST      #6,D7
          BEQ.S     INT_STO
          MOVEQ     #$7F,D1   SET TO $7F IF PARITY ERROR
INT_STO   TST.L     D6
          BEQ.S     INT_TX
          MOVE.L    D6,A2
          MOVE.W    IO_QIN,A1
          JSR       (A1)
INT_TX    BTST      #1,D7     TEST FOR TX INTERRUPT
          BEQ.S     INT_END
          TST.L     D6
          BEQ.S     MASK_TX
          MOVE.L    D6,A2
          ADDA.W    #QLEN,A2
          MOVE.W    IO_QOUT,A1
          JSR       (A1)
          BNE.S     MASK_TX   IF NO BYTES TO SEND
          MOVE.B    D1,1(A4)
          BRA.S     INT_END
MASK_TX   MOVEQ     #$DF,D2   DISABLE TX INTERRUPT
          AND.B     SER_CTRL(A5),D2
          MOVE.B    D2,(A4)
INT_END   RTS

          END
