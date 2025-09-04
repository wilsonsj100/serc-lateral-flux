#####################Functions for Lateral Flux Data Processing################

# This script contains functions required to run the script 
# 'SLP_LF_22_complete_processing.R' This script was written by S. Kuhl (USGS).
# Last updated: May 2024
# Minor edits by Qipei Shangguan, WHOI, to prevent site-specific descriptions,
# such as 'SLP', on April 2025
# Add alkalinity on July 2025

# this function converts a numeric month value (1-12) to a numeric season value.
# season 1 = Jan-May, season 2 = Jun-Aug, season 3 = Sept-Dec
month2season <- function(month){
  
  season <- rep(NA,length(month))
  
  season[which(month %in% c(1:5))] <- 1
  season[which(month %in% c(6:8))] <- 2
  season[which(month %in% c(9:12))] <- 3
  
  return(season)
  
}

bin2group <- function(month){
  
  season <- rep(3,length(month))
  
  season[which(month <= 0.5)] <- 2
  # season[which(month <= 0.3)] <- 2
  season[which(month <= 0.1)] <- 1
  
  
  return(season)
  
}

# this function takes the "gap check" vector (0 in places where there is flux data,
# and 1 in places where flux = NA) and creates a corresponding vector that contains 
# lengths associated with each run of real values or gap (run of NAs)
gapcheck2length <- function(gap_check){
  
  # creates an object containing the value of each run (0 or 1) and the length of the run
  fluxgaps <- rle(gap_check)
  lengths <- fluxgaps$lengths
  values <- fluxgaps$values
  
  # creates a counter that shows the start position of each gap or series of real values
  lengths_sum <- cumsum(lengths)
  lengths_sum <- c(0,lengths_sum)
  gap_length <- rep(0,length(gap_check))
  
  # assign the length of the sequence to each entry that is part of that run
  for (i in 1:length(lengths)) {
    gap_length[(lengths_sum[i]+1):lengths_sum[i+1]] <- lengths[i]
  }
  
  return(gap_length)
}


# this function assigns a bin to each entry input. input the data to be sorted 
# and a vector of bin values (max bin value should be greater than the greatest 
# data value, and min bin value should be less than the lowest data value).
# We use this function to assign bin values to tides based on high tide water level,
# and to instantaneous water flow values
setBins <- function(data,bins){
  
  #upper bounds for values in each bin
  bin_h <- bins[-1]
  
  #lower bounds for values in each bin
  bin_l <- bins[-length(bins)]
  
  # vector to store bin number 
  bin_num <- rep(NA,length(data))
  
  # sequentially find and label values that fall with in the span of values for 
  # each bin
  for (i in 1:length(bin_h)){
    
    counter <- which(data<=bin_h[i]
                     & data>bin_l[i])
    
    bin_num[counter] <- bin_h[i]
    
  }
  
  return(bin_num)
  
}

# this function determines the boundary values for a set number of  bins based 
# on instantaneous water flow values. The bins are symmetrical around zero and 
# each bin is sized to hold approximately the same percentage of all flow data
# based on the input variable "bin_per". We used this function to create 20 flow
# bins each containing ~5% of data

makeBinsPer <- function(flows,bins_per){
  
  # create a vector of all instantaneous flow values and sort in ascending order
  flow_vals <- sort(flows)
  
  # separate incoming (positive) and outgoing (negative) flows
  flow_vals_in <- flow_vals[which(flow_vals > 0)]
  flow_vals_out <- flow_vals[which(flow_vals < 0)]
  
  # determine the number of flows in each group
  l_in <- length(flow_vals_in)
  l_out <- length(flow_vals_out)
  
  # determine the number of entries that should go in each bin (separately for 
  # incoming and outgoing) 
  n_per_bin_in <- bins_per*2/100*l_in
  n_per_bin_out <- bins_per*2/100*l_out
  
  # find the minimum and maximum bin values that will be less than lowest/
  # greater than greatest flow values
  min <- floor(min(flow_vals_out,na.rm=TRUE))
  max <- ceiling(max(flow_vals_in,na.rm=TRUE))
  
  # determine the number of bins based on the input % per bin
  n_bins <- 100/bins_per/2-1
  
  # create a vector to store bin values for bins holding incoming flows
  bins_in <- rep(NA,n_bins)
  
  # determine the numeric flow value associated with each bin based on the 
  # average of the incoming and outgoing values for that bin
  for (i in 1:n_bins) {
    
    val_in <- flow_vals_in[n_per_bin_in*i]
    
    val_out <- flow_vals_out[length(flow_vals_out)-n_per_bin_out*i]
    
    bins_in[i] <- (val_in+abs(val_out))/2
    
  }
  
  # create values for outgoing bins as the negatives of the incoming bin values
  bins_out <- bins_in*-1
  
  # create one vector to hold all bin values, including 0
  bins <- sort(c(min,max,bins_in,bins_out,0))
  
  # create a list to store function output
  out <- list()
  out$bins <- bins
  
  # calculate width of each bin and add to output list
  bin_width <- bins[-c(1,length(bins))]
  bin_width <- c(min(flow_vals_out),bin_width,max(flow_vals_in))
  bin_width_prev <- c(NA,bin_width)
  bin_width_prev <- bin_width_prev[-length(bin_width_prev)]
  bin_width <- bin_width-bin_width_prev
  out$bin_width <- bin_width[which(!is.na(bin_width))]
  
  return(out)
  
}


# this function is used to calculate the average carbon flux rate in each 
# flow bin in order to calculate a weighted average of carbon fluxes and correct
# the bias introduced by simply averaging carbon flux data (since there is bias
# in flow data coverage, e.g., ebbing != flooding)
binSumFlowMo <- function(data){
  
  # separately group bin values in each season and year and calculate 
  # flux averages
  bin <- group_by_at(data, c("year","month","flow_bin"))%>%
    summarize(N=n(),
              N_DOC = length(which(!is.na(DOC_flux))),
              N_DIC = length(which(!is.na(DIC_flux))),
              N_TA = length(which(!is.na(TA_flux))),
              DOC_flux = mean(DOC_flux,na.rm=TRUE),
              DIC_flux = mean(DIC_flux,na.rm=TRUE),
              TA_flux = mean(TA_flux,na.rm=TRUE),
              DIC = mean(DIC,na.rm=TRUE),
              TA = mean(TA,na.rm=TRUE),
              DOC = mean(DOC,na.rm=TRUE))%>%
    filter(!is.na(flow_bin))
  
  bin <- merge(bin, bins_tb, by= c("year","month","flow_bin"), all = TRUE)
  
  # calculate total number of entries in all flow bins for each season/year
  N_sum <- group_by_at(bin,c("year","month"))%>%summarize(N=sum(N,na.rm=TRUE))
  
  # create column for total number of entries in summary data frame
  sums <- rep(N_sum$N,rep(20,nrow(N_sum)))
  bin$Nsum <- sums
  
  # calculate the percent of time (/flows) of the total that is contained in
  # each bin, add to data frame
  per_time <- bin$N/sums
  bin$per_time <- per_time
  
  # to calculate the percent of time in each bin for incoming and outgoing bins 
  # separately, create a marker for incoming/outgoing bins
  bin$in_out_per <- NA
  bin$in_out <- if_else(round(bin$flow_bin,8)<=0,1,0)
  
  # create start and end values for each set of incoming/outgoing bins
  in_out_vals <- rle(bin$in_out)
  S <- cumsum(in_out_vals$lengths)-(in_out_vals$lengths-1)
  E <- cumsum(in_out_vals$lengths)
  
  # calculate the percentage in each bin for each group of incoming/outgoing bins
  for (i in 1:length(in_out_vals$lengths)){
    bin$in_out_per[S[i]:E[i]] <- bin$per_time[S[i]:E[i]]/
      sum(bin$per_time[S[i]:E[i]],na.rm=TRUE)
  }
  
  # calculate products of average flux/conc per bin and time per bin
  bin <- mutate(bin,DOC_flux_time = DOC_flux*per_time,
                DIC_flux_time = DIC_flux*per_time,
                TA_flux_time = TA_flux*per_time,
                DOC_time = DOC*per_time,
                DIC_time = DIC*per_time,
                TA_time = TA*per_time,
                DOC_in_out_time = DOC*in_out_per,
                DIC_in_out_time = DIC*in_out_per,
                TA_in_out_time = TA*in_out_per)
  return(bin)
}