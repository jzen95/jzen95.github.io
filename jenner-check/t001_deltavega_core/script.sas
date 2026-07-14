/* ================================================================= */
/* Core-Guay / Coles-Daniel-Naveen option delta & vega core          */
/* ----------------------------------------------------------------- */
/* Extracted verbatim from delta.sas (steps excomp11 and excomp14):  */
/*   the Black-Scholes valuation of current-year option grants and    */
/*   the aggregation into delta, optiondelta, sharedelta and vega.    */
/* In the full program the input dataset excomp10 is assembled from   */
/* ExecuComp, CRSP and Compustat on WRDS.  Here it is stood up with a */
/* small in-line sample so the calculation runs standalone; the       */
/* formulas (probnorm, PDF('normal',...), the Zc/Sc/Vc/Rc functions   */
/* and the sum()-based delta/vega) are unchanged.                     */
/* ================================================================= */

data excomp10;
  input coperol year prccf Xc expric numsecur maturity_yearend
        maturity_grantdate rfc bs_yield sigma mktpric shrown
        opts_vested_num opts_unvested_num;
  sigmasq = sigma*sigma;
datalines;
16285 2005 82.20 71.05 71.05 250.0 6.90 6.95 0.045 0.012 0.30 71.05 120.5 900 1500
16285 2006 91.90 80.10 80.10 300.0 6.80 6.85 0.048 0.011 0.28 80.10 130.0 1100 1700
6     2005 47.50 40.00 40.00 180.0 5.50 5.55 0.041 0.020 0.35 40.00 60.2 500 800
6     2006 52.30 45.20 45.20 210.0 5.40 5.45 0.043 0.019 0.33 45.20 65.0 620 950
2611  2005 33.10 28.75 28.75 90.0  7.10 7.15 0.046 0.015 0.40 28.75 40.0 300 450
2611  2006 36.80 31.10 31.10 110.0 7.00 7.05 0.049 0.014 0.38 31.10 44.0 360 520
984   2004 61.40 55.00 55.00 400.0 6.20 6.25 0.038 0.022 0.26 55.00 210.0 1400 2100
984   2005 66.90 59.30 59.30 430.0 6.10 6.15 0.040 0.021 0.25 59.30 225.0 1550 2300
668   2009 41.20 35.60 35.60 150.0 5.90 5.95 0.024 0.023 0.28 35.60 55.0 470 700
668   2010 44.70 38.90 38.90 170.0 5.80 5.85 0.026 0.022 0.27 38.90 60.0 540 820
;
run;

/* ---- excomp11: Black-Scholes value of current-year option grants ---- */
data excomp11;
 set excomp10;

 if numsecur=. and (exdate=. and expric=. and mktpric=.
   and option_awards_num=0) then numsecur=0;

 * REALIZABLE VALUE AS EXCESS OF S OVER X;
  realizable_value = (prccf-Xc)*numsecur;
  if realizable_value<0 then realizable_value=0;
  if mktpric=. or Xc=. or numsecur=. then realizable_value=.;

 Zc_yearend = (log(prccf/Xc)+maturity_yearend*(rfc-bs_yield+sigmasq/2))/(sigma*sqrt(maturity_yearend));
 if maturity_yearend=. then Zc_yearend=.;

 Zc_grantdate= (log(mktpric/Xc)+maturity_grantdate*(rfc-bs_yield+sigmasq/2))/(sigma*sqrt(maturity_grantdate));
 if maturity_grantdate=. then Zc_grantdate=.;

 * appendix of core guay paper;
 Sc_yearend = exp(-bs_yield*maturity_yearend)*probnorm(Zc_yearend)*numsecur*prccf/100;
  if Zc_yearend=. then Sc_yearend=.;
 if  numsecur=0 then Sc_yearend=0;

 * Black Scholes value of options;
  Vc_grantdate = numsecur*(mktpric*exp(-bs_yield* maturity_grantdate)*probnorm(Zc_grantdate)
               -Xc*exp(-rfc* maturity_grantdate)*probnorm(Zc_grantdate-sigma*sqrt( maturity_grantdate)));
  if Zc_grantdate=. then Vc_grantdate=.;
 if numsecur=0 then Vc_grantdate=0;

  if Zc_yearend^=. then do;
  Vc_yearend = numsecur*(prccf*exp(-bs_yield*maturity_yearend)*probnorm(Zc_yearend)
               -Xc*exp(-rfc*maturity_yearend)*probnorm(Zc_yearend-sigma*sqrt(maturity_yearend)));
  end;
 if numsecur=0 then Vc_yearend=0;

 * sensitivity with respect to a 0.01 change in stock return volatility;
 * see core and guay appendix A;
  if Zc_yearend^=. then do;
   Rc_yearend = exp(-bs_yield* maturity_yearend)*PDF('normal',Zc_yearend,0,1)*prccf*sqrt( maturity_yearend)*0.01*numsecur;
  end;
  if Zc_yearend=. or maturity_yearend=. then Rc_yearend=.;
 if numsecur=0 then Rc_yearend=0;
 run;

/* ---- aggregate tranche-level to one obs per executive-year ---- */
proc sql;
 create table excomp12
  as select *, sum(Vc_grantdate) as Vopts_grantdate,
     sum(Vc_yearend) as Vopts_yearend,
   sum(numsecur) as sumnumsecur,
    sum(Sc_yearend) as Sopts_grants_yearend,
     sum(Rc_yearend) as Ropts_grants_yearend,
          sum(realizable_value) as sumrealizable_value
  from excomp11
  group by coperol,year;
quit;

/* ---- excomp14 delta / vega assembly (share + option components) ---- */
data delta_vega;
 set excomp12;

 * sensitivity of shareholdings;
 Sshr = shrown*prccf/100;
 Vshr = shrown*prccf;

 * overall sensitivity;
  delta = sum(Svest, Sunvest, Sopts_grants_yearend, Sshr);
  optiondelta = sum(Svest, Sunvest, Sopts_grants_yearend);
  sharedelta = Sshr;

  Ropt = sum(Rvest, Runvest, Ropts_grants_yearend);
  vega = Ropt;

 * firm-related wealth;
 firm_related_wealth = sum(Vvest, Vunvest, Vopts_yearend, Vshr);

 keep coperol year delta optiondelta sharedelta vega firm_related_wealth;
run;

proc sort data=delta_vega nodupkey; by coperol year; run;

proc print data=delta_vega;
 var coperol year delta optiondelta sharedelta vega firm_related_wealth;
 format delta optiondelta sharedelta vega firm_related_wealth 12.2;
 title "Executive-year delta, vega and firm-related wealth";
run;

proc means data=delta_vega n mean min max;
 var delta vega firm_related_wealth;
 title "Summary of computed incentive measures";
run;
