
library(RMySQL)
openmrs = dbConnect(MySQL(), user='esaude', password='esaude', dbname='openmrs', host='192.168.40.247')

  rs <- dbSendQuery(openmrs, "show databases;")
  databases <- fetch(rs)  
  
  databases <- subset(databases,! databases$Database %in% c("performance_schema","openmrs_reports","temp","mysql","openmrs","	information_schema"))
  
  RMySQL::dbClearResult(rs)
  rm(data,rs)
  
