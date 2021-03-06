# Function to get time difference in human readable format
# Input is start time and end time
# If "frm" is set to "hms" then output will be h:m:s
# otherwise only hours will be returned
tmDiff <- function(start, end, frm="hms") {
  
  dsec <- as.numeric(difftime(end, start, units = c("secs")))
  hours <- floor(dsec / 3600)
  
  if (frm == "hms" ){
    minutes <- floor((dsec - 3600 * hours) / 60)
    seconds <- dsec - 3600*hours - 60*minutes
    
    out=paste0(
      sapply(c(hours, minutes, seconds), function(x) {
        formatC(x, width = 2, format = "d", flag = "0")
      }), collapse = ":")
    
    return(out)
  }else{
    return(hours)
  }
}


# Function to download file from ftp server
#
# @param file_path is a path to a remoute file
# @param dest_file is a path where downloaded file will be stored
# @param username ftp username to WorldPop ftp server
# @param password ftp password to WorldPop ftp server
# @param quiet If TRUE, suppress status messages (if any), and the progress bar.
# @param method Method to be used for downloading files.
#  Current download methods are "internal", "wininet" (Windows only) "libcurl",
# "wget" and "curl", and there is a value "auto"
# @rdname grid3DownloadFileFromFTP
#' @importFrom utils read.csv
grid3DownloadFileFromFTP <- function(file_path, dest_file, username, password, quiet, method="auto") {
  
  grid3FTP <- "ftp.worldpop.org.uk"
  credentials <- paste(username, password, sep = ":")
  file_remote <-paste0('ftp://',credentials,'@',grid3FTP ,file_path)
  
  tmStartDw  <- Sys.time()
  
  checkStatus <- tryCatch(
    {
      utils::download.file(file_remote, destfile=dest_file,mode="wb",quiet=quiet, method=method)
    },
    error=function(cond){
      message(paste("URL does not seem to exist:", file_remote))
      message("Here's the original error message:")
      message(cond)
    },
    warning=function(cond){
      message(paste("URL caused a warning:", file_remote))
      message("Here's the original warning message:")
      message(cond)
    },
    finally={
      if (!quiet){
        tmEndDw  <- Sys.time()
        #message(paste("Processed URL:", file_remote))
        message(paste("It took ", tmDiff(tmStartDw ,tmEndDw,frm="hms"), "to download" ))
      }
    }
  )
  
  if(inherits(checkStatus, "error") | inherits(checkStatus, "warning")){
    return(NULL)
  } else{
    return(1)
  }
}

# grid3GetCSVFileAllCovariates function to download csv
# file from WorldPop ftp server
# containing a list of avalible Covariates. The csv file
# will be stored in a temporary R folder with a temporary
# file name and pattern grid3AllCovariates. This file will be used
# internally during querying and downloading datasets.
#
# @param username ftp username to WorldPop ftp server
# @param password ftp password to WorldPop ftp server
# @param quiet If TRUE, suppress status messages (if any), and the progress bar.
# @param frCSVDownload If TRUE, a new wpgAllCovariates.csv file will
# be downloaded and the old one removed.
# @rdname grid3GetCSVFileAllCovariates
# @return Data frame of all covariates.
#' @importFrom utils read.csv
grid3GetCSVFileAllCovariates <- function(username, password, frCSVDownload=FALSE) {
  
  grid3AllCSVFilesPath <- paste0(tempdir(),"/grid3covariates.csv")
  
  if(!file.exists(grid3AllCSVFilesPath) | frCSVDownload){
    
    credentials <- paste(username,password,sep = ":")
    file_remote <-paste0('/Covariates/grid3covariates.csv')
    
    grid3DownloadFileFromFTP(file_remote, grid3AllCSVFilesPath, username, password, quiet=TRUE)
  }
  
  df.all.Covariates = utils::read.csv(grid3AllCSVFilesPath, stringsAsFactors=FALSE)
  return(df.all.Covariates)
}



#' grid3ListCountries function will return a list of the country
#' avalible to download
#'
#' @param username ftp username to WorldPop ftp server
#' @param password ftp password to WorldPop ftp server
#' @param verbose quiet If TRUE, suppress status messages (if any)
#' @param frCSVDownload If TRUE, a new wpgAllCovariates.csv file will downloaded
#' @rdname grid3ListCountries
#' @return Dataframe
#' @export
grid3ListCountries <- function(username, password, verbose=FALSE, frCSVDownload=FALSE) {
  
  df <- grid3GetCSVFileAllCovariates(username, password, frCSVDownload)
  
  return(df[!duplicated(df$ISO3), c("ISO3")])
}



#' grid3ListCountryCovariates function will return a data frame of
#' avalible covariates for a country
#' @param ISO3 a 3-character country code or vector of country codes
#' @param username ftp username to WorldPop ftp server
#' @param password ftp password to WorldPop ftp server
#' @param detailed If TRUE, then more information will be given
#' @param frCSVDownload If TRUE, a new wpgAllCovariates.csv file will downloaded
#' @rdname grid3ListCountryCovariates
#' @return Dataframe
#' @export
#' @examples
#' grid3ListCountryCovariates( ISO3="USA", username="ftpUsername", password="ftpPassword" )
#' 
#' grid3ListCountryCovariates(ISO3=c("USA","AFG"), username="ftpUsername", password="ftpPassword" )
grid3ListCountryCovariates <- function(ISO3=NULL,
                                      username=NULL,
                                      password=NULL,
                                      detailed=FALSE,
                                      frCSVDownload=FALSE) {
  
  if (is.null(ISO3))  stop("Enter country ISO3" )
  if (is.null(username)) stop("Enter ftp username" )
  if (is.null(password)) stop("Enter ftp password" )
  
  uISO3 <- toupper(ISO3)
  
  if (any(nchar(uISO3)!=3)){
    stop( paste0("Country codes should be three letters. You entered: ", paste(uISO3, collapse=", ")) )
  }
  
  df <- grid3GetCSVFileAllCovariates(username, password, frCSVDownload)
  
  if(any(!uISO3 %in% df$ISO3)){
    warning( paste0("ISO3 code not found: ", paste(uISO3[which(!uISO3 %in% df$ISO3)])) )
  }
  
  df.filtered <- df[df$ISO3 %in% uISO3,] 
  
  if(nrow(df.filtered)<1){
    stop( paste0("No ISO3 code found: ", paste(uISO3, collapse=", ")))
  }
  
  if (detailed){
    return(df.filtered)
  }else{
    keeps <- c("ISO3", "CvtName", "Description", "Year")
    return(df.filtered[keeps])
  }
}



#' grid3GetCountryCovariate function will download files and return a list 
#' with the file paths to the requested covariates for one or more countries
#' @param df.user data frame of files to download. Must contain ISO3, Folder, and RstName.
#' If not supplied, must give ISO3, year, and covariate
#' @param ISO3 a 3-character country code or vector of country codes. Optional if df.user supplied
#' @param covariate Covariate name(s). Optional if df.user supplied
#' @param destDir Path to the folder where you want to save raster file
#' @param username ftp username to WorldPop ftp server
#' @param password ftp password to WorldPop ftp server
#' @param quiet Download Without any messages if TRUE
#' @param frCSVDownload If TRUE, a new wpgAllCovariates.csv file will downloaded
#' @param method Method to be used for downloading files. Current download methods
#' are "internal", "wininet" (Windows only) "libcurl", "wget" and
#' "curl", and there is a value "auto"
#' @rdname grid3GetCountryCovariate
#' @return List of files downloaded, including file paths
#' @export
#' @examples
#' grid3GetCountryCovariate(df.user = NULL,'NPL','px_area','G:/WorldPop/','ftpUsername','ftpPassword')
grid3GetCountryCovariate <- function(df.user=NULL,
                                    ISO3=NULL,
                                    covariate=NULL,
                                    destDir=tempdir(),
                                    username=NULL,
                                    password=NULL,
                                    quiet=TRUE,
                                    frCSVDownload=FALSE,
                                    method="auto") {
  
  if (!dir.exists(destDir)) stop( paste0("Please check destDir exists: ", destDir))
  if (is.null(username)) stop("Error: Enter ftp username" )
  if (is.null(password)) stop("Error: Enter ftp password" )
  
  if(!is.null(df.user)){ # provide a full data frame
    if(!is.data.frame(df.user)){
      stop("Error: Expecting a data.frame argument")
    }
    if(!all(c("ISO3","Folder","CvtName") %in% names(df.user))){
      stop("Error: must supply ISO3, CvtName, and Folder data.")
    } else { 
      df.filtered <- unique(df.user) 
      df.filtered$CvtName <- gsub(pattern=paste(tolower(df.filtered$ISO3), sep="", collapse="|"), 
                                  replacement="", 
                                  x=df.filtered$RstName)
    }
    
  } else{ # if not providing a data.frame
    if (is.null(ISO3))  stop("Error: Enter country ISO3" )
    if (is.null(covariate)) stop("Error: Enter covariate" )
    
    df <- grid3GetCSVFileAllCovariates(username, password, frCSVDownload)
    
    ISO3 <- toupper(ISO3)
    covariate <- tolower(covariate)
    # allow filtering by vectors
    df.filtered <- df[df$ISO3 %in% ISO3 & df$CvtName %in% covariate, ]
  }
  
  if (nrow(df.filtered)<1){
    stop( paste0("Entered Covariates: ", paste(covariate, collapse=", ")," not present in WP. Please check name of the dataset"))
  }
  
  credentials <- paste(username,password,sep = ":")
  
  # preallocate return storage
  outFiles <- vector(mode="character", length=nrow(df.filtered))
  # loop over all inputs
  for(i in 1:nrow(df.filtered)){
    file_remote <- paste0(df.filtered[i,"Folder"],'/', df.filtered[i,"CvtName"],'.tif')
    file_local <- paste0(destDir,'/', df.filtered[i,"CvtName"],'.tif')
    
    ftpReturn <- grid3DownloadFileFromFTP(file_remote, file_local, username, password, quiet=quiet, method=method)
    
    if(!is.null(ftpReturn)){
      outFiles[i] <- file_local
    } else{
      outFiles[i] <- NULL
    }
  }
  
  returnList <- as.list(df.filtered[c("ISO3","CvtName")])
  returnList$filepath <- outFiles
  return(returnList)
}
