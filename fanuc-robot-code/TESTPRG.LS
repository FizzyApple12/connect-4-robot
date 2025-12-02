/PROG  TESTPRG
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "";
PROG_SIZE	= 1897;
CREATE		= DATE 25-11-29  TIME 18:45:27;
MODIFIED	= DATE 25-12-01  TIME 17:35:00;
FILE_NAME	= ;
VERSION		= 0;
LINE_COUNT	= 72;
MEMORY_SIZE	= 2337;
PROTECT		= READ_WRITE;
TCD:  STACK_SIZE	= 0,
      TASK_PRIORITY	= 50,
      TIME_SLICE	= 0,
      BUSY_LAMP_OFF	= 0,
      ABORT_REQUEST	= 0,
      PAUSE_REQUEST	= 0;
DEFAULT_GROUP	= 1,*,*,*,*;
CONTROL_CODE	= 00000000 00000000;
/MN
   1:J PR[1:HOME] 25% FINE    ;
   2:  RO[2:MOVING]=OFF ;
   3:  R[3]=0    ;
   4:  LBL[1:START] ;
   5:  R[1]=0    ;
   6:  LBL[2:POS_IDX_READ] ;
   7:  WAIT RI[2:POS_CLOCK]=ON    ;
   8:  IF RI[1:POS_DATA   ]=OFF,JMP LBL[3] ;
   9:  R[1]=R[1]+1    ;
  10:  LBL[3:END_READ_1] ;
  11:  WAIT RI[2:POS_CLOCK]=OFF    ;
  12:  IF RI[1:POS_DATA   ]=OFF,JMP LBL[4] ;
  13:  R[1]=R[1]+2    ;
  14:  LBL[4:END_READ_2] ;
  15:  WAIT RI[2:POS_CLOCK]=ON    ;
  16:  IF RI[1:POS_DATA   ]=OFF,JMP LBL[5] ;
  17:  R[1]=R[1]+4    ;
  18:  LBL[5:END_READ_3] ;
  19:  WAIT RI[2:POS_CLOCK]=OFF    ;
  20:  IF RI[1:POS_DATA   ]=OFF,JMP LBL[6] ;
  21:  R[1]=R[1]+8    ;
  22:  LBL[6:END_READ_4] ;
  23:  WAIT RI[2:POS_CLOCK]=ON    ;
  24:  IF RI[1:POS_DATA   ]=OFF,JMP LBL[7] ;
  25:  R[1]=R[1]+16    ;
  26:  LBL[7:END_READ_5] ;
  27:  WAIT RI[2:POS_CLOCK]=OFF    ;
  28:  RO[2:MOVING]=ON ;
  29:  IF R[2]=0,JMP LBL[8] ;
  30:  IF R[2]=1,JMP LBL[8] ;
  31:  IF R[2]=19,JMP LBL[8] ;
  32:  IF R[2]=20,JMP LBL[8] ;
  33:  R[3]=R[2]*2    ;
  34:  R[3]=R[3]-1    ;
  35:L PR[R[3]] 100mm/sec FINE    ;
  36:  LBL[8:PRIMARY_POS] ;
  37:  SELECT R[1]=0,JMP LBL[9] ;
  38:         =1,JMP LBL[10] ;
  39:         =19,JMP LBL[13] ;
  40:         =20,JMP LBL[14] ;
  41:         ELSE,JMP LBL[11] ;
  42:  LBL[9:HOME] ;
  43:L PR[1:HOME] 300mm/sec FINE    ;
  44:  JMP LBL[12] ;
  45:  LBL[10:CAPTURE] ;
  46:L PR[2:CAPTURE] 300mm/sec FINE    ;
  47:  JMP LBL[12] ;
  48:  LBL[11:OTHER] ;
  49:  R[3]=R[1]*2    ;
  50:  R[3]=R[3]-1    ;
  51:L PR[R[3]] 300mm/sec FINE    ;
  52:  R[3]=R[3]+1    ;
  53:L PR[R[3]] 100mm/sec FINE    ;
  54:  LBL[12:END_MOVE] ;
  55:  RO[2:MOVING]=OFF ;
  56:  R[2]=R[1]    ;
  57:  JMP LBL[1] ;
  58:  LBL[13:WIN] ;
  59:J P[1] 50% FINE    ;
  60:L P[2] 600mm/sec FINE    ;
  61:L P[3] 600mm/sec FINE    ;
  62:L P[2] 600mm/sec FINE    ;
  63:L P[3] 600mm/sec FINE    ;
  64:L P[2] 600mm/sec FINE    ;
  65:L P[3] 600mm/sec FINE    ;
  66:J PR[1:HOME] 25% FINE    ;
  67:  JMP LBL[12] ;
  68:  LBL[14:LOSE] ;
  69:J P[4] 50% FINE    ;
  70:L P[5] 50mm/sec FINE    ;
  71:  WAIT   1.50(sec) ;
  72:  JMP LBL[12] ;
/POS
P[1]{
   GP1:
	UF : 0, UT : 1,		CONFIG : 'N U T, 0, 0, 0',
	X =   376.27  mm,	Y =    11.54  mm,	Z =   819.35  mm,
	W =   145.74 deg,	P =   -84.60 deg,	R =    34.16 deg
};
P[2]{
   GP1:
	UF : 0, UT : 1,		CONFIG : 'N U T, 0, 0, 0',
	X =   376.27  mm,	Y =    93.14  mm,	Z =   819.35  mm,
	W =   110.92 deg,	P =   -65.57 deg,	R =    92.78 deg
};
P[3]{
   GP1:
	UF : 0, UT : 1,		CONFIG : 'N U T, 0, 0, 0',
	X =   376.27  mm,	Y =  -147.82  mm,	Z =   819.35  mm,
	W =  -126.33 deg,	P =   -70.65 deg,	R =   -91.11 deg
};
P[4]{
   GP1:
	UF : 0, UT : 1,		CONFIG : 'N U T, 0, 0, 0',
	X =   201.55  mm,	Y =   100.82  mm,	Z =   416.35  mm,
	W =  -179.13 deg,	P =    19.79 deg,	R =     3.22 deg
};
P[5]{
   GP1:
	UF : 0, UT : 1,		CONFIG : 'N U T, 0, 0, 0',
	X =   172.75  mm,	Y =   -60.46  mm,	Z =   320.35  mm,
	W =  -165.09 deg,	P =    23.98 deg,	R =     -.96 deg
};
/END
