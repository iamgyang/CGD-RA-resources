# Before you run this code, you have to change line 12 to be your directory. 
# You also have to include a notepad txt file html_source_for_bank_urls.txt 
# in your directory that has text copy and pasted 
# from view-source:https://www.tdbgroup.org/annual-reports/. 
# (what happens when you go on the annual reports page, right click, 
# and click "view source").

# This installs the packages I used:
list.of.packages <- c("dplyr", "data.table", "glue", "pdftools", "stringr", "tidyverse")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages)) install.packages(new.packages, dependencies = TRUE)
for (package in list.of.packages) {library(eval((package)), character.only = TRUE)}

# set the working directory; you will have to change this.
setwd("C:/Users/user/Downloads/")

# this is the source HTML code for the website that has the URLs:
# from https://www.tdbgroup.org/annual-reports/
# see 
# view-source:https://www.tdbgroup.org/annual-reports/
fileName <- "html_source_for_bank_urls.txt"
text <- readChar(fileName, file.info(fileName)$size)

# this gets the locations that have the pattern "https://"
start_index <- text %>%
  gregexpr(pattern ="https://",.) %>% unlist %>% as.numeric

# this gets the locations in that text file  that have the pattern ".pdf"
end_index <- text %>%
  gregexpr(pattern =".pdf",.) %>% unlist %>% as.numeric

# this gets me a list of strings that are urls
url_list <- mapply((function(x, y)
  substr(text, x, y + 3)), 
  start_index, end_index)

# cleaning that list of strings: I don't want it to be in french, or just a blank "":
url_list <- url_list[url_list!=""] %>% unlist
url_list <- url_list[-grep("French",url_list)]
url_list <- url_list %>% sort

# I only want urls that have the word "annual" in them: (for annual report)
url_list <- 
  grep("Annual",url_list, value = T, ignore.case = T)

# here, I get the annual report YEAR:
pat <- "(\\d)+"
pdf_names <- url_list %>% (function(x) substr(x, nchar(x)-20, nchar(x))) %>% str_extract(., pat) %>% gsub("26","2016",.)

# then, in order to save everything, I'm going to save it as pta_`year'.pdf:
pdf_names <- paste0("pta_",pdf_names,".pdf")

# this downloads the pdfs. BUT, if I've already downloaded them before, I
# don't want to download them again. So, I attach a condition:  if 2010 and
# 2018 PDFs are not in the input directory, then actually download the pdfs
# from the urls:
if(!any(dir()%in%c("pta_2015.pdf", "pta_2017.pdf"))){
  walk2(url_list, pdf_names, download.file, mode = "wb")}

# get the pdf text from the downloaded pdfs:
raww <- map(pdf_names, pdf_text)

# this outputs a list; name the list the years of the pdf reports:
names(raww) <- pdf_names %>% 
  gsub("pta_", "",.,fixed=T) %>% 
  gsub(".pdf","",.,fixed=T) %>% 
  as.character()

# if all of the values within the pdf are empty strings, then delete that part
# from the list
to_remove <- raww %>% lapply(., function(x)
  all(x == "")
) %>% unlist()

raww <- raww[!to_remove]
raww <- raww[lapply(raww,length)>0]

# Now we will loop through the entire contents of each PDF (each element of the list):
# !!!!!!!the beginning of our giant loop!!!!!!!
bob <- list()
for (i_ in names(raww)) {
  table <- raww[[i_]]
  
  # display what year PDF I'm at in the console:
  cat(i_, sep = "\n")
  
  # if the number of characters within the pdf is less than 500, then delete
  # that pdf from our list: indicates that we won't find anything in the pdf
  # itself.
  if (sum(nchar(table)) <= 500) {
    raww[[i_]] <- NULL
    next
  }
  
  # Find the PAGES of the pdf where there is use of these words in ("short
  # term borrowings" OR "long term borrowings") AND ("bank") AND ("term"). 
  search <- Reduce(intersect,
                   map(c("short term borrowings|long term borrowings",
                         "bank",
                         "term"),
                       function(x)
                         grep(x, table, ignore.case = T)))
  
  # narrow down to the groups of pages where there are consecutive pages that
  # were found (because normally this "short term borrowings" comes in groups
  # of 3, with the last page being the "long term borrowings")
  diffs1 <- c(diff(search),0)
  diffs2 <- c(diffs1[1], diff(search))
  which_searches <- mapply(pmin, diffs1, diffs2)<=2
  table_index <- search[which_searches]
  
  # this is the name of the pdf we want to read in:
  nam <- paste0("pta_", i_, ".pdf")
  
  # start a loop over each PAGE of the pdf that used the words "short term
  # borrowings" or "long term borrowings"
  for (p_ in 1:length(table_index)) {
    
    # first, get the data as a pdf table: As a side note, it probably helps to
    # first read the documentation on R pdf_data function. This returns every
    # word of the pdf with a coordinate axis (x,y coordinate): this 
    # %>% as.data.table() is very important, because it defines a new data.table
    # for each page of the pdf you're looping over. see
    # https://stackoverflow.com/questions/65164323/r-data-table-gets-modified-after-ive-changed-it
    df <- pdf_data(nam)[[table_index[[p_]]]] %>% as.data.table()

    # remove  margin text: (header / footer):
    df <- df[y != max(y) & x != max(x), ]

    # round the values of the locations; feel free to change this 11 based on
    # how precise / imprecise you want it to be, with bigger denominators
    # being more imprecise y coordinates for your words.
    df[, `:=`(x = round(x),
              y = round(y / 11))]

    # the idea of the next few lines is to define a group indicator, so that
    # we can merge the words / numbers that are close to each other on the x-y
    # axis grid we came up with:
    df <- df[order(y, x),]
    df[, group := shift(space, n = 1, type = "lag")]
    df[space == FALSE & group == TRUE, group := TRUE]
    
    df[is.na(group), group := 0]
    df[, group := cumsum(!group)]
    df <- df[, .(
      y = last(y),
      x = last(x),
      text = paste(text, collapse = " ")
    ), by = group]
    
    # next, we finally convert to the desired table by pivoting from long to
    # wide: I'm using tidyverse syntax because it's got this "row_number"
    # function that doesn't work with data.tables. I also got this code
    # snippet from some online source: 
    # see https://stackoverflow.com/questions/60127375/using-the-pdf-data-function-from-the-pdftools-package-efficiently
    df <- df %>% group_by(y) %>%
      mutate(colno = row_number()) %>%
      ungroup() %>%
      dplyr::select(text, colno, y) %>%
      pivot_wider(names_from = colno, values_from = text) %>%
      dplyr::select(-y)
    
    # this is the name of the pdf: i_ is the YEAR (defined earlier), and
    # table_index[[p_]] is the PAGE.
    name_of_written_pdf <- 
      paste0(
        i_,
        "_page_",
        table_index[[p_]],
        ".csv"
      )
    
    # output as a CSV
    write.csv(df, name_of_written_pdf, na = "")
    
    # input the table into a list for further cleaning
    bob[[i_]][[paste("page",table_index[[p_]])]] <- df %>% as.data.table() 

# this marks the end of the giant for loop
}}



