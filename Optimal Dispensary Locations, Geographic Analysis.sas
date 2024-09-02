*Reading dev file into SAS;
options validvarname= v7;
proc import out= dev replace
datafile= '/home/u63586186/BAN210/ban210dev1.csv' dbms= csv;
guessingrows= 500;
getnames= yes;
run;

*Reading val file into SAS;
options validvarname= v7;
proc import out= val replace
datafile= '/home/u63586186/BAN210/ban210val1.csv' dbms= csv;
guessingrows= 500;
getnames= yes;
run;

*Drop variables not needed for exercise;
data dev1;
set dev;
drop PRIZM5DA SG LS DensityClusterCode15 DensityClusterCode15_2 SG_U2
     DensityClusterCode5_lbl DEPVAR7;
run;     

*Basic statistics of target and independent variables;
title 'Basic Stat of Target Variable & 5 Independent Variables'; 
proc means data= dev1 N mean median min max std;
var TOT__SPENT7 CNBBAS1934 SV00058 HSCL001 HSGC001 ECYHTA6064;
run; 

*Random Sample of analytical file;
proc surveyselect data= dev1 
out= randev /* saving to randev1 */
method= srs /* simple random sampling */
n= 10 /*number of records to select */
seed= 12345;
run;
title 'Ten Random Records from Analytical file with Target & Predictors';
proc print data= randev (keep= TOT__SPENT7 CNBBAS1934 SV00058 HSCL001 HSGC001 
                               ECYHTA6064 DensityClusterCode5);
run;

*Running Correlation;
proc corr data= dev1 rank out= corep;
with tot__spent7;
run;
proc transpose data= corep out= out1;
data out (keep= _name_ snp tot__spent7);
set out1;
snp= abs(tot__spent7);
proc sort data= out;
by descending snp;
proc print data= out;
run;

*EDA's on correlation from key variables Sign;
data edarep;
set out;
_N= left(_N_);
call symput('a'!!_N,_NAME_) ;
run;
%macro contin(dataset=,GR=,VAR=);
data tfile;
set &dataset;
count= 1;
keep &var TOT__SPENT7;
proc rank data= tfile group= &GR OUT= tfile1;
var &var;
ranks __rank;
run;
proc summary data= tfile1 noprint;
class __rank;
var &var  TOT__SPENT7;
output out= tfile2
min= minvar DU1
max= maxvar DU4
mean= DU7 defect2
n= Count du2;
run;
data tfile;
informat mminvar $8. mmaxvar $8.;
length _var $20. range $20.;
set tfile2;
_var = "&VAR" ;
*_LAB = "&LAB" ;
mminvar= put(MINVAR,8.2);
mmaxvar= put(MAXVAR,8.2);
range= MMINVAR||' to '||MMAXVAR;
if __rank= 0 then Range=' <= '|| MMAXVAR;
if __rank= &GR-1 then range= MMINVAR ||'+';
if minvar = maxvar	then range= MMINVAR ;
if _N_ = 1 then Range = 'Average';
pcdef = defect2;
label Range='Range'
Count= 'Count'
pcdef= 'Average Spent';
proc print split= ' ';
var _var Range  pcdef  COUNT;
run;
%mend;
options missing= ' ';
%macro eda;
%do i=150 %to 153;
%contin(dataset= dev1,GR=5,VAR=&&a&i)	;
run;
%END;
%mend eda;
%eda;

*Running first stepwise;
proc stepwise data= dev1;
model tot__spent7= SV00058 CNBBAS1934 ECYBASHPOP CNBBAS19P ECYCHAKIDS CNBBAS35P HSCL001
                   HSGC001 HSHC001 ECYHOMPANJ HSRE001 HSRE011 HSRE040 HSRO001
                   HSSH014 ECYHTA6064 HSCM001D HSCM001F HSRE001S WSD2AR ECYHTA3034
                   ECYHTA5559 ECYMTN2534 ECYHTA6569 SV00044 ECYTIMSA SV00066 HSED006
                   ECYHTA2529 HSTR050 SV00041 HSCS013 ECYMTN3544 SV00021 ECYHTA7074
                   ECYSTYSING ECYSTYAPT HSCS007 ECYTENOWN HSRE061 HSRO002 SV00093 SV00086
                   HSSH037B ECYMARSING HSTA002A ECYCDOIC HSTA005 SV00043 WSIN100_P ECYHSZ2PER
                   WSWORTHV ECYPIMNI ECYRELCHR SV00079 SV00030 SV00028 ECYTRAWALK HSCS008
                   SV00011 HSRE021 HSRV001B SV00038 SV00061 ECYRELCATH HSRM014 ECYOCCSCND
                   ECYMARM HSHC007 SV00012 ECYACTINLF ECYMARWID ECYHSZ1PER HSTA002B HSRE006
                   HSTR034 HSSH037A HSTA006 HSHC004B ECYACTUR HSHC003 HSMG008 ECYCFSLP HSRE063
                   SV00025 ECYINDADMN ECYTRAPUBL ECYPOC17P HSHE012 ECYPOWHOME SV00002 ECYTIMSAM 
                   HSRE052 ECYINDARTS SV00023 ECYHOMUKRA HSRE042 ECYOCCMGMT 
                   ECYINDMANU HSHC001S ECYINDEDUC ECYSTYAPU5 DensityClusterCode5 WSCARDSB ECYHOMCHIN 
                   ECYMARCL HSED005 SV00064 SV00077 SV00074 ECYHOMFREN/
sls=.05 sle=.05;
run;

*Running second stepwise;
proc stepwise data= dev1;
model tot__spent7=
SV00058
ECYHOMPANJ
CNBBAS1934
HSRE040
HSCM001F/
sls=.05 sle=.05;
run;

*Run multiple regression;
proc reg data= dev1 outest= regout1;
oxyhat: model tot__spent7= SV00058
ECYHOMPANJ
CNBBAS1934
HSRE040
HSCM001F;
run;
*Running algorithm against validation dataset;
proc score data= val
score= regout1 out= rscorep
type= parms;
VAR SV00058
ECYHOMPANJ
CNBBAS1934
HSRE040
HSCM001F;
run;

data file2;
set rscorep;
array raw _numeric_;
do over raw;
if raw= . then raw= 0;
end; 
run;
*sortting validation file by model score in descending order and putting it into 10 deciles;
proc sort data= file2;
by descending oxyhat;
data file3;
set file2 nobs= no;
account= 1;
if _N_= 1 then  percent= 0;
if ceil((_N_/NO)*10) gt percent then  percent + 1;
retain percent;
run;
proc summary data= file3;
class percent;
var  oxyhat tot__spent7 account;
output out= test3 SUM= DU1 totspend ACCOUNT 
mean=DU2 SPENDRATE du3
min=SCORE du4 DU5;
DATA GAINS1;
SET TEST3;
DROP DU1-DU5 _TYPE_ _FREQ_;
IF _N_=1 THEN DO;
TOTALSPEND= totspend;
TOTSP= SPENDRATE;
cummail= 0;
END;
ELSE DO;
PCTOTSP=ROUND((TOTSPEND/TOTALSPEND)*100,.01);
INRSRATE=ROUND((spendrate/TOTSP)*100,.01);
END;
RETAIN TOTALSPEND TOTSP;
DATA GAINS2;
SET GAINS1;
IF _N_=1 THEN DELETE;
LABEL SCORE='MINIMUM* SCORE IN RANGE'
PCTOTSP='% OF TOTAL* SPEND IN INTERVAL'
SPENDRATE='AVG. SPEND. RATE* WITHIN INTERVAL'
INRSRATE='INTERVAL LIFT IN SPEND.RATE'
percent='% OF PROSPECTS *IN INTERVAL';
PROC FORMAT;
value  ABC 1='0-5%'
                  2='5%-10%'
                  3='10%-15%'
                  4='15%-20%'
                  5='20%-25%'
                  6='25%-30%'
                  7='30%-35%'
                  8='35%-40%'
                  9='40%-45%'
                  10='45%-50%'
                  11='50%-55%'
                  12='55%-60%'
                  13='60%-65%'
                  14='65%-70%'
                  15='70%-75%'
                  16='75%-80%'
                  17='80%-85%'
                  18='85%-90%'
                  19='90%-95%'
                  20='95%-100%';
				 
PROC PRINT DATA=GAINS2 SPLIT='*';
ID PERCENT;
VAR score pctotsp spendrate ACCOUNT;
*FORMAT PERCENT ABC.;
title "Development - Multiple Regression";
quit;