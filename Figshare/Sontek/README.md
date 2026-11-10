**GCReW - Flume Sontek ADCP Dataset** 

Data Type: Acoustic Doppler Current Profiler (ADCP) Tidal Creek Monitoring

Sampling Type: Continuous sensor

Sampling Locations: GCReW Flume (38.87486, -76.5465) 

<br>

Wilson S ; Miller W ; Noyce G ; Peresta D ; Read Z ; Reynolds A ; Rich R ; Megonigal J P (2026): Dataset: L2 2023-2025 Global Change Research Wetland (GCReW) Flume Sontek Acoustic Doppler Current Profiler (ADCP). FigShare repository. Dataset. doi: accessed via url.

<br>

**Data Description:** 
These data are measurements of water temperature, depth, velocity, and discharge made at the Smithsonian Environmental Research Center's Global Change Research Wetland (GCReW) in the Kirkpatrick Marsh along the Rhode River in Edgewater, MD, USA. Measurements were made  with a Sontek IQ series acoustic doupler current profiler (ADCP) at the GCReW Flume (38.87486, -76.5465) through which a tidal creek flows. The Sontek ADCP is affixed to a PVC pipe bolted to the center of the flume that extended to just above the sediment surface. Measurements were collected every six minutes and recorded by a Campbell Scientific CR1000x logger as described by Wilson et al. (in review).

Data collected every six minutes 2022-present. Previous data being prepared for repository publication by Whitman Miller and Amanda Reynolds. 

For questions about these data: contact Stephanie J. Wilson (wilsonsj@si.edu) or Patrick Megonigal (megonigalp@si.edu). 

![Figure 1: SonTek IQ Series ADCP (Xylem)](Pictures/SonTekIQ.jpg)

<br>

**Data Processing:**
L0 Level Data: Raw data is received by the logger from the instrument. 

L1 level Data: L0 data is processed with programmatic quality checks and flags depth and velocity data when those data are out of the instrument bounds (OOR), out of service when the instrument is down for cleaning or servicing (OOS), and flagged for internal system status codes (SSF).In addition, data are flagged with NOAA IOOS QARTOD flags (1,2,3,4,9) according to instrument bounds, internal system status codes, or if data is missing. 

L2 level Data: L1 water depth and index velocity measurements are manually QAQC'd and data are flagged as out of reasonable range (ORR) for this site or as suspected sensor noise (SSN) when applicable. Those data, along with any dependent data (cross sectional area, mean velocity, flowrate) are made to be NA when flagged as ORR or if they were flagged by L1 programmatic checks.  The only exception are SSF flags 2 and 3, which indicate a change in tilt values that were input into the ADCP and flag the user so that the IQ mount should be checked. In addition, data are flagged with NOAA IOOS QARTOD flags (1,2,3,4,9) according to instrument bounds, internal system status codes, if data is missing, or manually added QAQC lettered codes. Time points made to be NA are retained in the dataset along with their flags. Discharge, Q (m3/s), was calculated as the cross sectional area * velocity using both index velocity and mean velocity measured by the Sontek IQ and is reported here. The QAQC procedures are outlined and the code to produce these data from L` are available on GitHub (link). 


<br>

**QAQC Codes:**
Lettered Codes: 
 OOB = Out of instrument's sensor bounds 
 OOS = Out of service, when the instrument is out of water or being serviced 
 SSF = Sontek system flag, this flag indicates that there is a system code in the system_status column 
 ORR = Out of reasonable range - when data are outside the reasonable range for this location 
 SSN = Suspected sensor noise - when data appear to be noise rather than signal 


QARTOD Codes (NOAA, IOOS, 2019):
 1 = Pass - Data have passed critical real-time QA tests and are deemed adequate for use as preliminary data 
 2 = Not Evaluated - Data have not been QC-tested, or the information on quality is not available 
 3 = Suspect or Of High Interest - Data are considered to be either suspect or of high interest to operators and users. They are flagged suspect to draw further attention to them by operators.
 4 = Fail - Data are considered to have failed one (or more) critical real-time QA Checks. If they are disseminated at all, it should be readily apparent that they are not of acceptable quality 
 9 = Data are missing; used as a placeholder

**Data Files Available:** 

"L0_data" - All available L0 data combined into one parquet file 

"L1_data" - Annual files post L1 processing (2023-2025)

"L2_data" - Annual files post L2 processing (2023-2025)

"clean-sontek-files_L1.Rmd" - L1 processing file containing programmatic data flagging (takes L0 data to L1)

"clean-sontek-files_L2.Rmd" - L2 processing file containing Shiny out of reasonable range flagging application (takes L1 data to L2)

"clean-sontek-data-protocol.pdf" - PDF instructions for QAQCing sontek data 

![Figure 2: GCReW Flume looking out to Rhode River](Pictures/GCW_HighTide.png)

  

