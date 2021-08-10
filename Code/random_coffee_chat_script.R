# RANDOM COFFEE SCRIPT ------------------------------------------------

# created by George Yang
# 2/2021, the second year of corona.

# LIBRARIES ---------------------------------------------------

library(data.table)
library(dplyr)
library(lubridate) # mess with dates
library(googlesheets4) # google sheets
library(RDCOMClient) # outlook email
library(random) # random numbers from Random.org
library(googledrive)

# the googlesheets4 and RDCOMClient package take a bit of
# difficulty to install. but google it, and it's pretty straightforward.

# install.packages("RDCOMClient")
# install.packages("RDCOMClient", repos = "http://www.omegahat.net/R")

# FUNCTIONS --------------------------------------------

# Get the end date of the period: (i.e. next next Friday)
next_friday <- function(given_date) {
  n_days_to_fri <- 6 - wday(given_date)
  z <- given_date + duration(n_days_to_fri, "days")
  return(z)
}

waitifnot <- function(cond) {
  if (!cond) {
    msg <- paste(deparse(substitute(cond)), "is not TRUE")
    if (interactive()) {
      message(msg)
      while (TRUE) {}
    } else {
      stop(msg)
    }
  }
}


# GET NEXT FRIDAY --------------------------------------------

end_day <- next_friday(next_friday(Sys.Date()) + 2)
end_day <- format(end_day, format="%b %d")
end_day <- month.abb[month(Sys.Date())]


# READ SHEET (PAUSE HERE!) -----------------------------------------------------
options(
  gargle_oauth_cache = ".secrets",
  gargle_oauth_email = TRUE
)

# get the CGD coffee sheet:
ss <-
  # REPLACE THIS WITH YOUR INSTITUTION'S GOOGLE SHEET
  # it should have a column for the date that people registered, their email, 
  # and the group size (2-4)
  "https://docs.google.com/spreadsheets/d/TEST"
dat <- read_sheet(ss)

# GET MOST RECENT PERIOD ---------------------------------------------
dat <- dat[, 1:3]
names(dat) <- c("time", "email", "size")
dat <- as.data.table(dat)
dat[, ltime := shift(time, n = 1L, type = "lag")]
dat[, difftime := time - ltime]
dat[, newperiod := difftime > 6 * 10 ^ 5]
dat[, newperiod := as.numeric(newperiod)]
dat <- na.omit(dat)
dat[, newperiod2 := cumsum(newperiod)]
whichperiod <- max(dat$newperiod2)
dat <-
  dat[newperiod2 == whichperiod, .(time, email, size)] %>% as.data.table()

print("If code stopped, there is only 1 person who signed up for coffee chat.")
waitifnot(nrow(dat) > 1)


# STORE CHECKING DATASET --------------------------------------------------

check_dat <- dat %>% as.data.table()

# GET RANDOM NUMBERS AND SORT ------------------------
rand <-
  randomNumbers(
    n = nrow(dat),
    min = 1,
    max = 1000,
    col = 1,
    base = 10,
    check = TRUE
  )
closeAllConnections()

dat[, rand := rand]
dat[, size := size %>% gsub("Indifferent", "777", .) %>% as.numeric]
dat[, drup:= duplicated(email)]
dat <- dat[drup==FALSE,]
dat[,drup:=NULL]


# GROUP PEOPLE ----------------------------------------------
size_counts <- dat$size %>% table %>% as.data.table()
names(size_counts)[1] <- "size"
size_counts[, size := as.numeric(size)]
size_counts[, need := ((N+size-1)%/%(size))*size-N]
needed <- as.data.frame(size_counts[need > 0 &
                                      size < 5, .(size, need)])

# for each group size, find the number of people we still need to
# obtain the proper group size, and let the indifferent people be
# that size.
sortdat <-
  function(zzz) {
    needed <- needed[needed$need!=0,] %>% as.data.table()
    for (s_ in unique(needed$size)) {
      nnum <- needed[size == s_, .(need)] %>% unlist %>% as.vector
      dat <- dat[order(-size, -rand)] %>% as.data.table()
      num_indiff <- dat[size == 777,] %>% nrow
      if (num_indiff >= nnum) {
        dat[1:nnum, size := s_]
      } else{
        cat("Oh no! There aren't enough indifferent people.")
        {
          if (TRUE) {
            stop("The script must end here")
          }
          print("Script did NOT end!")
        }
        break
      }
      dat <- dat[order(-size, -rand)] %>% as.data.table()
    }
    dat
  }

dat <- sortdat(1) %>% as.data.table()


# Now, distribute the people who are indifferent
# to groups of size 3 first; then, groups of size 2.

dat <- dat[order(size,-rand)] %>% as.data.table()
num_indiff <- dat[size == 777, ] %>% nrow

groups_of_3 <- as.numeric(num_indiff%%2==1)
groups_of_2 <- (num_indiff - 3*groups_of_3)%/%2

needed <- data.table(
  size = c(2,3),
  need = c(2*groups_of_2, 3*groups_of_3)
)
dat <- sortdat(1) %>% as.data.table()
dat <- dat[order(size,-rand)] %>% as.data.table()

# checks:

tabs <- dat$size %>% table %>% as.data.frame()
names(tabs)[1] <- "size"
tabs$size <- as.numeric(as.character(tabs$size))
tabs$zeros <- tabs$Freq %% tabs$size

paste("do we have proper group sizes?")
waitifnot(all(tabs$zeros==0))

paste("are all emails CGD emails?")
waitifnot(all(grepl("@cgdev.org",dat$email)))

paste("are all people of the same group size as they originally wanted?")
check <-
  merge(dat,
        check_dat,
        by = "email",
        all.x = TRUE) %>% 
  as.data.table()
waitifnot(all(check[size.y!="Indifferent",size.x==size.y]))

# SEND EMAILS ------------------------------------------

for (s_ in unique(dat$size)) {
  while (any(dat$size==s_)){
  email.vec <- dat[size == s_][1:s_, .(email)] %>% 
    unlist %>% as.vector
  emails_h <- email.vec %>% paste(collapse = ";")
  emails_v <- email.vec %>% paste(collapse = "\n   ")
  dat <- dat[!(email%in%email.vec)]
  ## init com api
  OutApp <- COMCreate("Outlook.Application")
  ## create an email
  outMail = OutApp$CreateItem(0)
  ## configure  email parameter
  outMail[["To"]] = emails_h
  outMail[["subject"]] = paste0("Coffee Chat: ", end_day)
  outMail[["body"]] = 
    paste0(
      "Hello! \n
This is to let you know that the people with the following email addresses will have a coffee chat in the month of ",
      end_day,
      ":\n   ",
      emails_v,
      "\n\nPlease schedule among yourselves. \n
Best, \n
George \n
Note: This is a semi-automated message. Please do not reply all."
    )
  
  ## send it
  outMail$Send()
  closeAllConnections()
  }
}
