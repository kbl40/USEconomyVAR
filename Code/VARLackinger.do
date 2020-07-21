********************************************************************************
*VAR code
*Author: Kyle Lackinger
*Date Created: 19 July 2020
*Date Last Updated: 20 July 2020
*Dependencies: VARData.csv file
*Description: This code takes in US economic data relating to economic activity
* and inflation and constructs a simple VAR model with visualizations using 
* impulse response functions.  Statistical checks are performed to assess if 
* econometric issues due to non-stationarity are to be expected.  
********************************************************************************

clear

* Import dataset with fed funds rate, core CPI, and IP
import delimited VARData.csv

* Format date string to MDY
quietly generate double newdate = date(datestr,"MDY")
format %td newdate

* Convert into monthly time series format
generate datem = mofd(newdate)
tsset datem, monthly

* Rename vars for brevity
rename indpro_pch IP
rename cpilfesl CPI
rename fedfunds FFR
rename dpccram1m225nbea inflation

* Plot original data over time
tsline inflation, name(cpi)
tsline IP, name(ip)
tsline FFR, name(ffr)
graph combine cpi ip ffr, name(ts)

* Assess number of lags for model
varsoc IP inflation FFR, maxlag(10)

* Run VAR
quietly var FFR IP inflation if datem <= tm(2019m5), lags(1/9)

* Check stationarity
varstable, graph
varlmar, mlag(4)
varnorm

* Cross correlation
xcorr IP inflation, name(left)
xcorr inflation IP, name(right)
graph combine left right, name(lr)

* Cross correlation
xcorr FFR inflation, name(left2)
xcorr inflation FFR, name(right2)
graph combine left2 right2, name(lr2)

* Cross correlation
xcorr FFR IP, name(left3)
xcorr IP FFR, name(right3)
graph combine left3 right3, name(lr3)

* Check Granger causality
vargranger

* Orthogonalized IRFs with varying order.
irf create fpi, set(macrovar) step(20) replace
irf table oirf, noci
irf graph oirf, name(fpi)

irf create ipf, order(inflation IP FFR) step(20)
irf create ifp, order(inflation FFR IP)	step(20)
irf create pfi, order(IP FFR inflation) step(20)

irf table oirf, noci irf(ipf)
irf table oirf, noci irf(ifp)
irf table oirf, noci irf(pfi)

* Plots of IRFs to compare ordering effects
irf graph oirf, impulse(FFR) response(IP) name(chart1)
irf graph oirf, impulse(FFR) response(inflation) name(chart2)

* Final plots
irf graph oirf, irf(fpi) impulse(FFR) response(IP) name(test3)
irf graph oirf, irf(fpi) impulse(FFR) response(inflation) name(test4)
graph combine test3 test4, name(result)

