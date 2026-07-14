/* ================================================================= */
/* Treasury risk-free-rate interpolation                             */
/* ----------------------------------------------------------------- */
/* Extracted from delta.sas (the riskfree_rate data step).           */
/* The FRB series gives 1,2,3,5,7 and 10-year rates; the program     */
/* interpolates the missing 4,6,8 and 9-year maturities used in the  */
/* Black-Scholes valuation.  In the full program the annual means    */
/* come from frb.rates_daily on WRDS; here rates_annual is stood up  */
/* with a small in-line sample of representative Treasury yields so   */
/* the interpolation runs standalone.  The rounding and interpolation */
/* arithmetic are unchanged.                                         */
/* ================================================================= */

data rates_annual;
  input year oneyr twoyr threeyr fiveyr sevenyr tenyr;
datalines;
2005 3.62 3.85 3.93 4.05 4.16 4.29
2006 4.94 4.82 4.77 4.75 4.76 4.79
2007 4.53 4.36 4.35 4.43 4.52 4.63
2008 1.82 2.00 2.24 2.80 3.18 3.66
2009 0.47 0.96 1.43 2.20 2.91 3.26
2010 0.32 0.70 1.11 1.93 2.62 3.22
;
run;

data riskfree_rate (drop=_TYPE_ _FREQ_);
  set rates_annual;
  oneyr=round(oneyr, 0.01);
  twoyr=round(twoyr, 0.01);
  threeyr=round(threeyr, 0.01);
  fiveyr=round(fiveyr, 0.01);
  sevenyr=round(sevenyr, 0.01);
  tenyr=round(tenyr, 0.01);
  fouryr=round(threeyr+(fiveyr-threeyr)/2, 0.01);
  sixyr=round(fiveyr+(sevenyr-fiveyr)/2, 0.01);
  eightyr=round(sevenyr+(tenyr-sevenyr)/3, 0.01);
  nineyr=round(sevenyr+(tenyr-sevenyr)/3*2, 0.01);
run;

proc print data=riskfree_rate;
 var year oneyr twoyr threeyr fouryr fiveyr sixyr sevenyr eightyr nineyr tenyr;
 title "Annual Treasury rates with interpolated 4/6/8/9-year maturities";
run;
