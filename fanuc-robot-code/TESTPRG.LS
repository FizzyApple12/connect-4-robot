/PROG  TESTPRG
/ATTR
OWNER        = MNEDITOR;
COMMENT        = "";
PROG_SIZE    = 1076;
CREATE        = DATE 25-11-29  TIME 18:45:27;
MODIFIED    = DATE 25-11-30  TIME 03:24:20;
FILE_NAME    = ;
VERSION        = 0;
LINE_COUNT    = 51;
MEMORY_SIZE    = 1472;
PROTECT        = READ_WRITE;
TCD:  STACK_SIZE    = 0,
      TASK_PRIORITY    = 50,
      TIME_SLICE    = 0,
      BUSY_LAMP_OFF    = 0,
      ABORT_REQUEST    = 0,
      PAUSE_REQUEST    = 0;
DEFAULT_GROUP    = 1,*,*,*,*;
CONTROL_CODE    = 00000000 00000000;
/MN
   1:J PR[1:HOME] 25% FINE    ;
   2:  LBL[1:START] ;
   3:  R[1]=0    ;
   4:  LBL[2:POS_IDX_READ] ;
   5:  WAIT RI[2:POS_CLOCK]=ON    ;
   6:  IF RI[1:POS_DATA   ]=OFF,JMP LBL[3] ;
   7:  R[1]=R[1]+1    ;
   8:  LBL[3:END_READ_1] ;
   9:  WAIT RI[2:POS_CLOCK]=OFF    ;
  10:  IF RI[1:POS_DATA   ]=OFF,JMP LBL[4] ;
  11:  R[1]=R[1]+2    ;
  12:  LBL[4:END_READ_2] ;
  13:  WAIT RI[2:POS_CLOCK]=ON    ;
  14:  IF RI[1:POS_DATA   ]=OFF,JMP LBL[5] ;
  15:  R[1]=R[1]+4    ;
  16:  LBL[5:END_READ_3] ;
  17:  WAIT RI[2:POS_CLOCK]=OFF    ;
  18:  IF RI[1:POS_DATA   ]=OFF,JMP LBL[6] ;
  19:  R[1]=R[1]+8    ;
  20:  LBL[6:END_READ_4] ;
  21:  WAIT RI[2:POS_CLOCK]=ON    ;
  22:  IF RI[1:POS_DATA   ]=OFF,JMP LBL[7] ;
  23:  R[1]=R[1]+16    ;
  24:  LBL[7:END_READ_5] ;
  25:  WAIT RI[2:POS_CLOCK]=OFF    ;
  26:  RO[2:MOVING]=ON ;
  27:  IF R[2]=0,JMP LBL[8] ;
  28:  IF R[2]=1,JMP LBL[8] ;
  29:  R[3]=R[2]*2    ;
  30:  R[3]=R[3]+3    ;
  31:L PR[R[3]] 100mm/sec FINE    ;
  32:  LBL[8:PRIMARY_POS] ;
  33:  SELECT R[1]=0,JMP LBL[9] ;
  34:         =1,JMP LBL[10] ;
  35:         ELSE,JMP LBL[11] ;
  36:  LBL[9:HOME] ;
  37:L PR[1:HOME] 300mm/sec FINE    ;
  38:  JMP LBL[12] ;
  39:  LBL[10:CAPTURE] ;
  40:L PR[2:CAPTURE] 300mm/sec FINE    ;
  41:  JMP LBL[12] ;
  42:  LBL[11:OTHER] ;
  43:  R[3]=R[1]*2    ;
  44:  R[3]=R[3]+3    ;
  45:L PR[R[3]] 300mm/sec FINE    ;
  46:  R[3]=R[3]+1    ;
  47:L PR[R[3]] 100mm/sec FINE    ;
  48:  LBL[12:END_MOVE] ;
  49:  RO[2:MOVING]=OFF ;
  50:  R[2]=R[1]    ;
  51:  JMP LBL[1] ;
/POS
/END
