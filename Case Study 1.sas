/******************** FIRST STEP ********************/

/* Create library and filename */

libname tsa '/folders/myfolders/case study/';
filename study '/folders/myfolders/case study/TSAClaims2002_2017.csv';

/* Import the data */
proc import datafile=study dbms=csv out=tsa.clean replace;
	guessingrows=max;
	getnames=Yes;
run;

/* Preview the data*/
proc print data=tsa.Clean (obs=20);
run;
proc contents data=tsa.Clean varnum;
run;


/* Sort and remove duplicates */
proc sort data=tsa.clean noduprecs;
	by _all_;
/* format the dates I did this here to help with the date calculations in the Data step*/
	format Date_Received Incident_Date Date9.;
run;

/* Change missing and "-" values to Unknown */
data cleaning;
	set tsa.clean;
	if Claim_Type in ("-" , " ", "") then Claim_Type = 'Unknown';
		if Claim_Site in ("-" , " ", "") then Claim_Site = 'Unknown';
			if Disposition in ("-" , " ", "") then Disposition = 'Unknown';
/* Use only the first word */
	Claim_Type=scan(Claim_Type,1,"/");
/* Correct Type/Spelling errors */
	if Disposition = "Closed: Canceled" then Disposition = "Closed:Canceled";
		if Disposition = "losed: Contractor Claim" then Disposition = "Closed:Canceled";
/* Change the Case of the text */
	StateName=Propcase(StateName);
	State=Propcase(State);
	
/* Create new coloumn to identify date issues */
	IYear = Year(Incident_Date);
	DYear = Year(Date_Received);
	if Incident_Date =.  then Date_Issues="Needs Review";
		if Date_Received =.  then Date_Issues="Needs Review";
	if IYear <2002 or IYear >2017 then Date_Issues="Needs Review2";
	if DYear <2002 or DYear >2017 then Date_Issues="Needs Review2";
	IF Incident_Date > Date_Received then Date_Issues="Needs Review2";

/* Drop Unnecessary columns */
	Drop IYear DYear County City;

/* Format currency to be dollar with 2 decimal	 */
	format Close_Amount Dollar12.2;

/* Adding Labels */
	Label 	Claim_Number = "Claim Number"
			Date_Received = "Date Received"
			Incident_Date = "Incident Date"
			Airport_Code = "Airport Code"
			Airport_Name = "Airport Name"
			Claim_Type = "Claim Type"
			Claim_Site = "Claim Site"
			Item_Category = "Item Category"
			Close_Amount = "Close Amount"
			Disposition = "Disposition"
			StateName = "State Name"
			State = "State"
			Date_Issues = "Date Issues";
	
run;

proc sort data=cleaning;
	by Incident_Date;
run;

/* Good Practise to clear libname and filename */
/* libname tsa clear; */
/* filename study clear; */



/* Error checking */

/* Displays data set descriptor information variables and permanent labels */
proc contents data=cleaning;  
run;

Data Test1;
	Set cleaning;
	where IYear > DYear;
run;

proc sort data=cleaning out=test;
	by Date_Issues;
run;
proc freq data=cleaning ;
	table Date_Issues IYear;
run;



/******************** SECOND STEP ********************/



proc sort data=cleaning out=test;
	by Date_Issues;
	where Date_Issues is missing;
run;


%let outpath=/folders/myfolders/case study/;
ods pdf file="&outpath\ClaimsReport.pdf" style=Meadow bookmarkgen=Yes;
/* ods proclabel "" */

Title "Total Number of Date Issues";
ods proclabel "Total Number of Date Issues";
options nodate; /*removes the date*/
ODS NOPROCTITLE;

proc freq data=cleaning;
	table Date_Issues /nocum nopercent ;
run;

Title "Number of Claims per year";
ods proclabel "Number of Claims per year";
proc freq data=test;
	table Incident_Date /nocum nopercent plots=freqplot; /*this can also be done using the Proc SGPLOTS step*/
	format Incident_Date year.;
	where '01Jan2002'd <= Incident_Date <= '31Dec2017'd;
run;

%Let State="California"; /*this is the macro to use to substitue the State value in the code below*/

Title "Frequency of Claim Type per state";
ods proclabel "Frequency of Claim Type per state";
proc freq data=test order=freq;
	table Claim_Type /nocum nopercent;
	where StateName=&State and '01Jan2002'd <= Incident_Date <= '31Dec2017'd;
run;

Title "Frequency of Claim Site per state";
ods proclabel "Frequency of Claim Site per state";
proc freq data=test order=freq;
	table Claim_Site /nocum nopercent;
	where StateName=&State and '01Jan2002'd <= Incident_Date <= '31Dec2017'd;
run;

Title "Frequency of Disposition per state";
ods proclabel "Frequency of Disposition per state";
proc freq data=test order=freq;
	table Disposition /nocum nopercent;
	where StateName=&State and '01Jan2002'd <= Incident_Date <= '31Dec2017'd;
run;

proc means data=test maxdec=0 mean min max sum;
	var Close_Amount;
	where StateName=&State and '01Jan2002'd <= Incident_Date <= '31Dec2017'd;
run;

ods pdf close;
