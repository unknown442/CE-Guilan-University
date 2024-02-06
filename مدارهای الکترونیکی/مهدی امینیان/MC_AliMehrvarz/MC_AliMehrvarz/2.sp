
*************CMOS Inverter HSPICE netlist************ 
.include 'C:\MC\mosistsmc180.lib'
*netlist--------------------------------------- 
.param SUPPLY=1.8

*VDD Vdd 0 1.8 
VDD Vdd 0 'SUPPLY'

VCin Cin gnd 0
VA1 A1 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 10ns 20ns)
VA2 A2 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 20ns 40ns)
VA3 A3 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 40ns 60ns)
VA4 A4 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 60ns 80ns)
VA5 A5 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 80ns 100ns)
VA6 A6 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 100ns 120ns)
VA7 A7 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 120ns 140ns)
VA8 A8 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 140ns 160ns)

VB1 B1 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 10ns 20ns)
VB2 B2 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 20ns 40ns)
VB3 B3 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 40ns 60ns)
VB4 B4 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 60ns 80ns)
VB5 B5 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 80ns 100ns)
VB6 B6 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 100ns 120ns)
VB7 B7 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 120ns 140ns)
VB8 B8 gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 140ns 160ns)





.subckt FULLADDER A B Cin S Cout Vdd

.subckt CMOS_INV in out vdd
MP1 out in vdd vdd PMOS L=0.18u W=0.72u AS='0.72u*0.36u' PS='2*0.72u+2*0.36u' AD='0.72u*0.36u' PD='2*0.72u+2*0.36u'
MN1 out in 0 0 NMOS L=0.18u W=0.36u AS='0.36u*0.36u' PS='2*0.36u+2*0.36u' AD='0.36u*0.36u' PD='2*0.36u+2*0.36u'
.ends

.subckt CMOS_XOR in1 in2 invin1 invin2 out vdd
MP3 vdd invin1 Node1 vdd PMOS L=.18u W=1.44u AS='1.44u*0.36u' PS='2*1.44u+2*0.36u' AD='1.44u*0.36u' PD='2*1.44u+2*0.36u'
MP4 vdd in1 Node2 vdd PMOS L=.18u W=1.44u AS='1.44u*0.36u' PS='2*1.44u+2*0.36u' AD='1.44u*0.36u' PD='2*1.44u+2*0.36u'
MP5 Node1 in2 out vdd PMOS L=.18u W=1.44u AS='1.44u*0.36u' PS='2*1.44u+2*0.36u' AD='1.44u*0.36u' PD='2*1.44u+2*0.36u'
MP6 Node2 invin2 out vdd PMOS L=.18u W=1.44u AS='1.44u*0.36u' PS='2*1.44u+2*0.36u' AD='1.44u*0.36u' PD='2*1.44u+2*0.36u'
MN3 out invin1 Node4 0 NMOS L=0.18u W=0.72u AS='0.72u*0.36u' PS='2*0.72u+2*0.36u' AD='0.72u*0.36u' PD='2*0.72u+2*0.36u'
MN4 out in1 Node5 0 NMOS L=0.18u W=0.72u AS='0.72u*0.36u' PS='2*0.72u+2*0.36u' AD='0.72u*0.36u' PD='2*0.72u+2*0.36u'
MN5 Node4 invin2 0 0 NMOS L=0.18u W=0.72u AS='0.72u*0.36u' PS='2*0.72u+2*0.36u' AD='0.72u*0.36u' PD='2*0.72u+2*0.36u'
MN6 Node5 in2 0 0 NMOS L=0.18u W=0.72u AS='0.72u*0.36u' PS='2*0.72u+2*0.36u' AD='0.72u*0.36u' PD='2*0.72u+2*0.36u'
.ends

.subckt CMOS_AND invin1 invin2 out vdd
MP1 vdd invin1 Node1 vdd PMOS L=.18u W=1.44u AS='1.44u*0.36u' PS='2*1.44u+2*0.36u' AD='1.44u*0.36u' PD='2*1.44u+2*0.36u'
MP2 Node1 invin2 out vdd PMOS L=.18u W=1.44u AS='1.44u*0.36u' PS='2*1.44u+2*0.36u' AD='1.44u*0.36u' PD='2*1.44u+2*0.36u'
MN1 out invin1 0 0 NMOS L=0.18u W=0.36u AS='0.36u*0.36u' PS='2*0.36u+2*0.36u' AD='0.36u*0.36u' PD='2*0.36u+2*0.36u'
MN2 out invin2 0 0 NMOS L=0.18u W=0.36u AS='0.36u*0.36u' PS='2*0.36u+2*0.36u' AD='0.36u*0.36u' PD='2*0.36u+2*0.36u'
.ends

.subckt CMOS_OR invin1 invin2 out vdd
MP1 vdd invin1 out vdd PMOS L=.18u W=.72u AS='0.72u*0.36u' PS='2*0.72u+2*0.36u' AD='0.72u*0.36u' PD='2*0.72u+2*0.36u'
MP2 vdd invin2 out vdd PMOS L=.18u W=.72u AS='0.72u*0.36u' PS='2*0.72u+2*0.36u' AD='0.72u*0.36u' PD='2*0.72u+2*0.36u'
MN1 out invin1 node2 0 NMOS L=0.18u W=0.72u AS='0.72u*0.36u' PS='2*0.72u+2*0.36u' AD='0.72u*0.36u' PD='2*0.72u+2*0.36u'
MN2 node2 invin2 0 0 NMOS L=0.18u W=0.72u AS='0.72u*0.36u' PS='2*0.72u+2*0.36u' AD='0.72u*0.36u' PD='2*0.72u+2*0.36u'
.ends 

 

X1 A InvertA Vdd CMOS_INV
X2 B InvertB Vdd CMOS_INV
X3 Cin InvertCin Vdd CMOS_INV
* Level 1
X4 A B InvertA InvertB X1Out vdd CMOS_XOR
X5 InvertA InvertB A1Out vdd CMOS_AND

X6 X1Out InvertXOut1 Vdd CMOS_INV

*Level 2
X7 X1Out Cin InvertXOut1 InvertCin S Vdd CMOS_XOR 
X8 InvertXOut1 InvertCin A2Out vdd CMOS_AND


X9 A2Out InvertA2Out Vdd CMOS_INV
X10 A1Out InvertA1Out Vdd CMOS_INV
*Level 3

X11 InvertA2Out InvertA1Out Cout Vdd CMOS_OR

.ends

*.subckt FULLADDER A B Cin S Cout Vdd
X1 A1 B1 Cin S1 Cout1 Vdd FULLADDER
X2 A2 B2 Cout1 S2 Cout2 Vdd FULLADDER
X3 A3 B3 Cout2 S3 Cout3 Vdd FULLADDER
X4 A4 B4 Cout3 S4 Cout4 Vdd FULLADDER
X5 A5 B5 Cout4 S5 Cout5 Vdd FULLADDER
X6 A6 B6 Cout5 S6 Cout6 Vdd FULLADDER
X7 A7 B7 Cout6 S7 Cout7 Vdd FULLADDER
X8 A8 B8 Cout7 S8 Cout8 Vdd FULLADDER



*extra control information--------------------- 
.options post=2 nomod 
.op 
*analysis-------------------------------------- 
.TRAN 10ps 160ns * transient analysis: Step end_time 


.END 