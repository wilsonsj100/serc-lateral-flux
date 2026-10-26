#Calculate Z* for GCReW Marsh 

#use data from Holmquist et al. (2021) DOI: https://doi.org/10.3354/meps13683


# Z*  = (Median Elevation - MSL) / (MHHW - MSL) 

Median_elevation = 0.221 #Table 2, Median Total elevation (m) NAVD88

Mean_sea_level = 0.092  #Table 1, Mean sea level, Elevation (m) NAVD88

Mean_higher_high_water = 0.278 #Table 1, Mean higher high water, Elevation (m) NAVD88

Tial_amplitude = 18 #cm 


Z_star = (Median_elevation - Mean_sea_level ) / (Mean_higher_high_water - Mean_sea_level)

# Z* = 0.6935