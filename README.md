# Data Management & Creating of the Analytical File

## Table of Content

- [Project Overview](#project-overview)
- [Data Source](#data-source)
- [Tools](#tools)
- [Data Cleaning and Preparation](#data-cleaning-and-preparation)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Creation of the Analytical File](#creation-of-the-analytical-file)
- [Data Analysis](#data-analysis)
- [Key Findings](#key-findings)
- [Limitations](#limitations)
- [Code](#code)
- [References](#references)

## Project Overview
In conducting this exercise, I seek to understand the information requirements needed for this analysis. Central to this theme are four key areas I would like to highlight as critical to this exercise.

#### Quality of data 
Creating an analytical file involves preparing the data in a form that is conducive for analysis. This will involve the transformation of raw data into usable features. Poor data quality leads to biased or inaccurate predictions.

#### Data integration 
Most often data used in analytics comes from multiple sources, I will be merging data from two sources (Customer & Transaction file) to create an analytical file. This is to ensure all relevant information is considered during the analysis.

#### Feature selection 
This exercise will also involve the creation of variables that will be relevant to my analysis. By carefully selecting features I hope to improve the accuracy and robustness of my prediction.

#### Model training and evaluation
The creation of an analytical file serves as an input to predictive models. Ensuring a well-structured analytical file will simplify the process of evaluating my model and help in assessing the performance of my predictive models.        


## Data Source

Customer Data: The primary datasets used for this analysis is the "custfile.csv" file, which contains customer demographics and
Transaction Data: "transfile.csv" file which contains each customer transactions over a period of time.


## Tools

- SAS Studio - for data cleaning, analysis and visualisation.
- Tableau - for visualization and presentation.


## Data Cleaning and Preparation

In preparing my data for analysis I performed the following tasks:
1. Importing of data into SAS Studio.
2. Performing random sample on data.
3. Performing frequency distributions.
4. Cleaning, formatting & standardizing data.


## Exploratory Data Analysis

Performed EDAs to explore the customer data to get insights such as:
- Customer purchasing power
- Customer preferred payment type
- Customer household size and
- Relationships between key variables.


## Creation of the Analytical File

In creating the analytical file I created new variables in the transaction file and aggregated amount to total amount at the customer level.
I conducted joins between customer file and transaction file and created an analytical file at the customer level.


## Data Analysis
As part of my analysis I created new variables from the analytical file and performed some basic statistics to gain insights from the 
analytical file. I plottd some graphs against the key variables as well as used a proc summary to determine relationships and gain
more insights from the analytical file.

## Key Findings
Compared to females, males tend to have:
- High-income levels 
- Low credit score
- High education level
- Much younger and
- Low tenure

Compared to other regions, customers living in ‘N’(Southwest of Ontario) have:
- High-income levels
- Moderately high credit score
- Relatively high level of education
- A sizable household
- And fairly old demographics.

Compared to other payment types, payment type B is mostly preferred by customers who:
- Are older 
- Have been with the company for a while
- Have high levels of education
- Have good credit score 
- Have a slightly high-income level 


## Limitations
I had to retain only information present in the customer file and omitted information that were missing in transaction file to
arrive at my analytical file. These were about 10 records that could possibly impact my findings, but without it there are still
strong indications the derived sights give a better indication of the datasets.


## Code
~~~sas
*reading cust and trans file into sas;
options validvarname= v7;
proc import out= cust replace
datafile= '/home/u63586186/BAN210/custfile.csv' dbms= csv;
guessingrows= 20;
getnames= yes;
run;
options validvarname= v7;
proc import out= trans replace
datafile= '/home/u63586186/BAN210/transfile.csv' dbms= csv;
guessingrows= 20;
getnames= yes;
run;

*creating 10 random records;
title 'Ten Random Records from Customer File';
proc print data= cust (obs= 10) /* number of records to select */; 
where ranuni(0) le 0.25; 
run;
*creating 10 random records;
proc surveyselect data= trans out= random_sample
method= srs /* simple random sampling */
n= 10; /* number of records to select */
run;
title 'Ten Random Records from Transaction File';
proc print data= random_sample;
run;

*content procedure;
proc contents data= cust;
run;
proc contents data= trans;
run;

*frequency distribution;
proc freq data= cust;
tables number_in_house credit_score	customer_id	education gender income	preferred_payment_type	
       region_of_country source_code tenure_date type_of_card year_of_birth/ missing;
run;
proc freq data= trans;
tables amount customer_id transaction_date transaction_type/ missing;
run;

*cleaning up data & standardizing output character values;
data cust_clean;
set cust;
gender1= upcase(compress(gender));
preferred_payment_type1= upcase(compress(preferred_payment_type));
region_of_country1= upcase(compress(region_of_country));
source_code1= upcase(compress(source_code));
drop gender preferred_payment_type region_of_country source_code;  
run;

title 'Clean & Standardized Customer Data';
proc print data= cust_clean;
run;

*frequency distribution of clean data;
proc freq data= cust_clean;
tables gender1 preferred_payment_type1 region_of_country1 source_code1/ missing;
run;

*frequency distribution of gender by number in house;
proc freq data= cust_clean;
tables gender1* number_in_house/ missing;
run;

*plotting graphs; 
title 'Distribution # of Customers by Household size';
proc sgplot data= cust_clean;
format number_in_house;
vbar number_in_house/ missing datalabel colorstat= freq dataskin= crisp;
run;      

title 'Distribution # of Customers by Gender';
proc sgplot data= cust_clean;
format gender1;
vbar gender1/ missing datalabel colorstat= freq dataskin= crisp;
run;  

title 'Distribution # of Customers by Preferred Payment Type';
proc sgplot data= cust_clean;
format preferred_payment_type1;
vbar preferred_payment_type1/ missing datalabel colorstat= freq dataskin= crisp;
run;

title 'Distribution # of Customers by Region of Country';
proc sgplot data= cust_clean;
format region_of_country1;
vbar region_of_country1/ missing datalabel colorstat= freq dataskin= crisp;
run; 

title 'Credit Score by Income by Gender and sized by Income';
proc sgplot data= cust_clean;
bubble x= credit_score y= income size= income/ group= gender1;
run;

*plotting the relationship above on a scatter plot;
title 'Correlation between Credit Score and Income'; 
proc sgplot data= cust_clean;
    scatter x= credit_score y= income / markerattrs= (symbol= circlefilled);
    xaxis label="Credit Score";
    yaxis label="Income";
run;

*plotting box plot of Income by region of country;
title 'Income by Region of Country';
proc sgplot data= cust_clean;
hbox income/ category= region_of_country1;
run;

*correlation between income and credit score;
proc corr data= cust_clean;
var credit_score income;
run;

*basic statistics of clean data;
proc means data= cust_clean N mean min max median std;
*var year_of_birth tenure_date income education Number_in_house credit_score;
run;

*creating new variables for year of birth and tenure date;
data cust_clean1;
set cust_clean;
age= intck('year', year_of_birth, today());
tenure= intck('year', tenure_date, today());
drop year_of_birth tenure_date;
run;

*handling missing values in age and tenure;
proc means data= cust_clean1 noprint;
var age tenure; /*taking the mean values of age and tenure*/
output out= neo1 median= medage medtenure mean= meanage meantenure;
run;

*replacing missing values with the median values of age and tenure;
data cust_clean1;
set cust_clean1;
if age= . then age= 57;
if tenure= . then tenure= 7;
run;

*rerun freq;
proc freq data= cust_clean1;
tables gender1 region_of_country1 source_code1/ nocum;
run;

*creating analytical file at customer level;

proc sort data= trans;
by customer_id;
run;

*creating new variables to clean trans file;
data trans1;
set trans;
by customer_id;

*initialize variables for RFM calculation;
if first.customer_id then do;
TRANS_A= 0;
TRANS_B= 0;
TRANS_C= 0;
totamount= 0;
nummonths1= 9999;
totfreq= 0;
        
*set the current date;
curr_date = mdy(8, 16, 2019);
end;

*update transaction type counts and total amount;
select(upcase(compress(transaction_type)));
when ('A') TRANS_A + amount;
when ('B') TRANS_B + amount;
when ('C') TRANS_C + amount;
end;

*compute nummonths and update recency, frequency, and total amount;
if not missing(transaction_date) then do;
nummonths= intck('month', transaction_date, curr_date);
if nummonths < nummonths1 then nummonths1 = nummonths;
end;
totfreq + 1;
totamount + amount;

*if it's the last record for a customer, calculate RFM components;
if last.customer_id then do;
PCTRANS_A= TRANS_A / TOTAMOUNT;
PCTRANS_B= TRANS_B / TOTAMOUNT;
PCTRANS_C= TRANS_C / TOTAMOUNT;
totamountperevent = totamount / totfreq;
output;
end;

*retain nummonths1 for the next iteration;
drop nummonths1 nummonths curr_date totamountperevent;
format transaction_date monyy7.;
format pctrans_a pctrans_b pctrans_c percent8.2;
run;

*combing custfile and transfile by customer id to create analytical file;
proc sort data= cust_clean1;
by customer_id;
proc sort data= trans1;
by customer_id;
data anal_file;
merge cust_clean1 (in=AA1)
      trans1 (in=BB1);
by customer_id;
if BB1=1; /*retaining only information present in customer file and omitting information that are missing in transfile*/
run;      

*creating 5 random records from analytical file;
data anal_1;
set anal_file;
drop type_of_card totfreq pctrans_a pctrans_b pctrans_c;
run;
proc surveyselect data= anal_1 out= random_sample1
method= srs /*simple random sampling*/
seed= 13 n= 5; /*number of records to select*/
run;
title 'Five Random Records from Analytical File';
proc print data= random_sample1;
run;

*deriving variables from analytical file;
data anal_file1;
set anal_file;
if upcase(compress(gender1)) in ('M') then Male= 1; else Male= 0;
if upcase(compress(gender1)) in ('F') then Female= 1; else Female= 0;
if upcase(compress(source_code1)) in ('G') then Source_G= 1; else Source_G= 0;
if upcase(compress(source_code1)) in ('H') then Source_H= 1; else Source_H= 0;
if upcase(compress(source_code1)) in ('R') then Source_R= 1; else Source_R= 0;
if upcase(compress(region_of_country1)) in ('K') then EASTONT= 1; else EASTONT= 0;
if upcase(compress(region_of_country1)) in ('L') then CENTONT= 1; else CENTONT= 0;
if upcase(compress(region_of_country1)) in ('M') then GT_AREA= 1; else GT_AREA= 0;
if upcase(compress(region_of_country1)) in ('N') then SOWEONT= 1; else SOWEONT= 0;
if upcase(compress(region_of_country1)) in ('P') then NORTONT= 1; else NORTONT= 0;
run;

*basic statistics for derived variables;
title 'Basic statistics for derived variables';
proc means data= anal_file1 N mean min max median std;
var Male Female Source_G Source_H Source_R EASTONT CENTONT GT_AREA SOWEONT NORTONT;
run;

*some graphs to explain derived variables;

*relationship between Males and GT Area;
title 'Relationship between Males and GT Area';
proc sgplot data= anal_file1;
vbarbasic male/ 
response= GT_AREA 
stat= mean;
scatter x= male y= GT_AREA;
run;

*relationship between Males and Income;
title 'Relationship between Males and Income';
proc sgplot data= anal_file1;
vbarbasic male/ 
response= income 
stat= mean;
scatter x= male y= income;
run;

/* proc means data= Cust_Trans1 noprint; */
/* var Male; /*taking the mean values of Male */
/* output out= Male median= medmale mean= meanmale max= maxmale min= minmale std= stdmale; */
/* run; */

*proc summary on key variables (Gender);
title 'Insight from Gender variable';
proc summary data= anal_file1;
class gender1; /*Gender*/
var income credit_score education number_in_house age tenure;
output out= neo mean= ;
proc print data= neo;
id gender1;
run;  

*proc summary on key variables (Region of Country);
title 'Insight from Region of Country variable';
proc summary data= anal_file1;
class region_of_country1; /*Region of Country*/
var income credit_score education number_in_house age tenure;
output out= neo mean= ;
proc print data= neo;
id region_of_country1;
run;  

*proc summary on key variables (Payment Type);
title 'Insight from Preferred Payment Type variable';
proc summary data= anal_file1;
class preferred_payment_type1; /*Preferred Payment Type*/
var income credit_score education number_in_house age tenure;
output out= neo mean= ;
proc print data= neo;
id preferred_payment_type1;
run;


/*further insight can be made into the trans file and customer file to determine best customer value*/

*proc summary on key variables (Payment Type);
title 'Insight from Preferred Payment Type variable';
proc summary data= anal_file1;
class customer_id; /*Customer ID*/
var income credit_score education age tenure totamount;
output out= neo mean= ;
proc print data= neo;
id customer_id;
run;

/* proc sort data= neo; */
/* by totamount; */
/* run; */
~~~


## References
1. Data Mining for Managers by Richard Boire.
2. Learning SAS by Example 2nd Edition by Ron Cody.






