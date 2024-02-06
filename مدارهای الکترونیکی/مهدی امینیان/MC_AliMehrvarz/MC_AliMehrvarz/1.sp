
*************CMOS Inverter HSPICE netlist************ 
.include 'C:\MC\mosistsmc180.lib'
*netlist--------------------------------------- 
.param SUPPLY=1.8

*VDD Vdd 0 1.8 
VDD Vdd 0 'SUPPLY'
VA A gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 10ns 20ns)
VB B gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 20ns 40ns)
VCin Cin gnd PULSE ('SUPPLY' 0 0ps 100ps 100ps 40ns 80ns)


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

*X3 Cin InvertCin Vdd CMOS_INV
*X4 A B InvertA InvertB XorOut vdd CMOS_XOR
*X5 InvertA InvertB AndOut vdd CMOS_AND
*X6 InvertA InvertB OrOut vdd CMOS_Or
CL S gnd 10fF
CL2 Cout gnd 10fF





*extra control information--------------------- 
.options post=2 nomod 
.op 
*analysis-------------------------------------- 
.TRAN 10ps 80ns * transient analysis: Step end_time 


.END 