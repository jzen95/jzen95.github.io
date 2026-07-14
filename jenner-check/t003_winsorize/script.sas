/* ================================================================= */
/* ExecuComp-style winsorization of yield and volatility             */
/* ----------------------------------------------------------------- */
/* Extracted from delta.sas (the excomp5 -> out1 -> excomp6a/6b       */
/* block).  Following the ExecuComp methodology the program           */
/* winsorizes estimated dividend yield and estimated volatility at    */
/* the 5th and 95th percentiles, by year, before the Black-Scholes    */
/* valuation.  In the full program excomp5 is the merged              */
/* ExecuComp/CRSP panel; here it is stood up with a small in-line     */
/* sample by year so the proc univariate percentile capture and the   */
/* clamp logic run standalone and unchanged.                          */
/* ================================================================= */

data excomp5;
  input gvkey $ year estimated_yield estimated_volatility;
datalines;
001078 2005 0.012 0.28
001078 2005 0.014 0.30
001078 2005 0.016 0.31
001078 2005 0.018 0.33
001078 2005 0.020 0.34
001078 2005 0.022 0.36
001078 2005 0.024 0.38
001078 2005 0.026 0.40
001078 2005 0.028 0.42
001078 2005 0.030 0.44
002403 2005 0.011 0.27
002403 2005 0.013 0.29
002403 2005 0.015 0.32
002403 2005 0.017 0.35
002403 2005 0.019 0.37
002403 2005 0.180 0.39
002403 2005 0.021 0.41
002403 2005 0.023 0.43
002403 2005 0.001 0.92
002403 2005 0.025 0.45
006066 2006 0.010 0.26
006066 2006 0.012 0.28
006066 2006 0.014 0.30
006066 2006 0.016 0.32
006066 2006 0.018 0.34
006066 2006 0.020 0.36
006066 2006 0.022 0.38
006066 2006 0.024 0.40
006066 2006 0.150 0.41
006066 2006 0.002 0.88
;
run;

proc sort data=excomp5; by year; run;

proc univariate data=excomp5 noprint;
  by year;
  var estimated_yield estimated_volatility;
 output out=out1 pctlpts=5 95 pctlpre=estimated_yield estimated_volatility;
run;

data out1;
 set out1;
keep year estimated_yield5 estimated_yield95 estimated_volatility5 estimated_volatility95;
run;

proc sort data=excomp5; by year; run;
proc sort data=out1; by year; run;

data excomp6a;
 merge excomp5 (in=A) out1 (in=B);
  by year;
   if A;
run;

 data excomp6b;
  set excomp6a;
   if estimated_yield>estimated_yield95 and estimated_yield^=. then estimated_yield=estimated_yield95;
   if estimated_volatility>estimated_volatility95 and estimated_volatility^=. then estimated_volatility=estimated_volatility95;
   if estimated_yield<estimated_yield5 and estimated_yield^=. then estimated_yield=estimated_yield5;
   if estimated_volatility<estimated_volatility5 and estimated_volatility^=. then estimated_volatility=estimated_volatility5;
    drop estimated_volatility5 estimated_volatility95 estimated_yield5 estimated_yield95;
run;

proc print data=excomp6b;
 var gvkey year estimated_yield estimated_volatility;
 title "Winsorized yield and volatility (5th/95th percentile, by year)";
run;

proc means data=excomp6b n min max mean;
 class year;
 var estimated_yield estimated_volatility;
 title "Post-winsorization ranges by year";
run;
