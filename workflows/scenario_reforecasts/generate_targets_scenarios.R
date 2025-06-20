# # In-situ lake level, water temp, salinity (EC)
# water level data is height above sea level
# height of bottom of ALEX (per glm.nml) = -5.3 m
# In situ WQ data
message('Get target obs')
options(timeout=500)
setwd('data_raw')
download.file(url = paste0("https://water.data.sa.gov.au/Export/BulkExport?DateRange=Custom&StartTime=2014-01-01%2000%3A00&EndTime=", Sys.Date(), "%2000%3A00&TimeZone=0&Calendar=CALENDARYEAR&Interval=PointsAsRecorded&Step=1&ExportFormat=csv&TimeAligned=True&RoundData=True&IncludeGradeCodes=False&IncludeApprovalLevels=False&IncludeQualifiers=False&IncludeInterpolationTypes=False&Datasets[0].DatasetName=Lake%20Level.Best%20Available--Continuous%40A4261133&Datasets[0].Calculation=Instantaneous&Datasets[0].UnitId=82&Datasets[1].DatasetName=EC%20Corr.Best%20Available%40A4261133&Datasets[1].Calculation=Instantaneous&Datasets[1].UnitId=305&Datasets[2].DatasetName=Water%20Temp.Best%20Available--Continuous%40A4261133&Datasets[2].Calculation=Instantaneous&Datasets[2].UnitId=169&_=1711554907800"),
              destfile = file.path(lake_directory, "data_raw", "current_insitu.csv"))

cleaned_insitu_file <- file.path(config$file_path$qaqc_data_directory, paste0(config$location$site_id, "-targets-insitu.csv"))

readr::read_csv(file.path(lake_directory, "data_raw", "current_insitu.csv"),
                skip = 5, show_col_types = FALSE,
                col_names = c('time','Value_level', 'Value_EC', 'Value_temperature')) |>
  # simple conversion to salt
  mutate(Value_salt = oce::swSCTp(conductivity = Value_EC/1000,
                                  temperature = Value_temperature,
                                  conductivityUnit = 'mS/cm'),
         Value_depth = 5.3 + Value_level) |> # 5.3 is the height
  select(-Value_EC, -Value_level) |>
  pivot_longer(names_to = 'variable', names_prefix = 'Value_',
               cols = starts_with('Value'),
               values_to = 'observed') |>
  mutate(time = lubridate::force_tz(time, tzone = "Etc/GMT+9"),
         time = time - lubridate::minutes(30),
         time = lubridate::with_tz(time, tzone = "UTC"),
         date = lubridate::as_date(time),
         hour = lubridate::hour(time)) |>
  group_by(date, hour, variable) |>
  summarize(observation = mean(observed, na.rm = TRUE), .groups = "drop") |>
  mutate(depth = ifelse(variable %in% c('salt', 'temperature'), 0.5, NA),
         site_id = config$location$site_id,
         datetime = lubridate::as_datetime(date) + lubridate::hours(hour)) |>
  filter(hour == 0) |>
  select(site_id, datetime, depth, variable, observation) |>
  write_csv(cleaned_insitu_file)
#======================================#

# inflow driver observations ####
# Currently getting discharge, temp, and conductivity - data is in UTC
options(timeout=3000)
#Murray (Q@A4261001, WQ@A4261159) Not using Q@A4260903 - Lock 1
# download.file(paste0('https://water.data.sa.gov.au/Export/BulkExport?DateRange=Custom&StartTime=2015-01-01%2000%3A00&EndTime=', Sys.Date(), '%2000%3A00&TimeZone=0&Calendar=CALENDARYEAR&Interval=Hourly&Step=1&ExportFormat=csv&TimeAligned=True&RoundData=True&IncludeGradeCodes=False&IncludeApprovalLevels=False&IncludeQualifiers=False&IncludeInterpolationTypes=False&Datasets[0].DatasetName=Discharge.Master--Daily%20Read--ML%2Fday%40A4261001&Datasets[0].Calculation=Aggregate&Datasets[0].UnitId=239&Datasets[1].DatasetName=EC%20Corr.Best%20Available--Sensor%20near%20surface%40A4261159&Datasets[1].Calculation=Aggregate&Datasets[1].UnitId=305&Datasets[2].DatasetName=Water%20Temp.Best%20Available--Sensor%20near%20surface%40A4261159&Datasets[2].Calculation=Aggregate&Datasets[2].UnitId=169&_=1730580709437'),
#               destfile = 'current_inflow_murray.csv')

# reads in discharge from SA border in ML/day - this is used in the inflow models (including historical) and WQ from wellington
download.file(paste0("https://water.data.sa.gov.au/Export/BulkExport?DateRange=Custom&StartTime=2015-01-01%2000%3A00&EndTime=", Sys.Date(), "%2000%3A00&TimeZone=0&Calendar=CALENDARYEAR&Interval=Daily&Step=1&ExportFormat=csv&TimeAligned=True&RoundData=True&IncludeGradeCodes=False&IncludeApprovalLevels=False&IncludeQualifiers=False&IncludeInterpolationTypes=False&Datasets[0].DatasetName=Discharge.Master--Daily%20Calculation--ML%2Fday%40A4261001&Datasets[0].Calculation=Aggregate&Datasets[0].UnitId=241&Datasets[1].DatasetName=EC%20Corr.Best%20Available--Sensor%20near%20surface%40A4261159&Datasets[1].Calculation=Aggregate&Datasets[1].UnitId=305&Datasets[2].DatasetName=Water%20Temp.Best%20Available--Sensor%20near%20surface%40A4261159&Datasets[2].Calculation=Aggregate&Datasets[2].UnitId=169&_=1730580709437"),
              destfile = "current_inflow_murray.csv")


#Finnis (A4261208)
# download.file(paste0("https://water.data.sa.gov.au/Export/BulkExport?DateRange=Custom&StartTime=2015-01-01%2000%3A00&EndTime=", Sys.Date(), "%2000%3A00&TimeZone=0&Calendar=CALENDARYEAR&Interval=Hourly&Step=1&ExportFormat=csv&TimeAligned=True&RoundData=True&IncludeGradeCodes=False&IncludeApprovalLevels=False&IncludeQualifiers=False&IncludeInterpolationTypes=False&Datasets[0].DatasetName=Discharge.Best%20Available%40A4261208&Datasets[0].Calculation=Instantaneous&Datasets[0].UnitId=239&Datasets[1].DatasetName=EC%20Corr.Best%20Available%40A4261208&Datasets[1].Calculation=Instantaneous&Datasets[1].UnitId=305&Datasets[2].DatasetName=Water%20Temp.Best%20Available--Continuous%40A4261208&Datasets[2].Calculation=Instantaneous&Datasets[2].UnitId=169&_=1724767129649"),
#               destfile = file.path(lake_directory, "data_raw", "current_inflow_finnis.csv"))

# #Bremer (A4261219)
# download.file(paste0("https://water.data.sa.gov.au/Export/BulkExport?DateRange=Custom&StartTime=2020-01-01%2000%3A00&EndTime=", Sys.Date(), "%2000%3A00&TimeZone=0&Calendar=CALENDARYEAR&Interval=PointsAsRecorded&Step=1&ExportFormat=csv&TimeAligned=True&RoundData=True&IncludeGradeCodes=False&IncludeApprovalLevels=False&IncludeQualifiers=False&IncludeInterpolationTypes=False&Datasets[0].DatasetName=Discharge.Best%20Available%40A4261219&Datasets[0].Calculation=Instantaneous&Datasets[0].UnitId=239&Datasets[1].DatasetName=EC%20Corr.Best%20Available%40A4261219&Datasets[1].Calculation=Instantaneous&Datasets[1].UnitId=305&Datasets[2].DatasetName=Water%20Temp.Best%20Available--Continuous%40A4261219&Datasets[2].Calculation=Instantaneous&Datasets[2].UnitId=169&_=1724767713824"), 
#               destfile = file.path(lake_directory, "data_raw", "current_inflow_bremer.csv"))
# 
# #Angas (A4261220)
# download.file(paste0("https://water.data.sa.gov.au/Export/BulkExport?DateRange=Custom&StartTime=2020-01-01%2000%3A00&EndTime=", Sys.Date(), "%2000%3A00&TimeZone=0&Calendar=CALENDARYEAR&Interval=PointsAsRecorded&Step=1&ExportFormat=csv&TimeAligned=True&RoundData=True&IncludeGradeCodes=False&IncludeApprovalLevels=False&IncludeQualifiers=False&IncludeInterpolationTypes=False&Datasets[0].DatasetName=Discharge.Best%20Available%40A4261220&Datasets[0].Calculation=Instantaneous&Datasets[0].UnitId=239&Datasets[1].DatasetName=EC%20Corr.Best%20Available%40A4261220&Datasets[1].Calculation=Instantaneous&Datasets[1].UnitId=305&Datasets[2].DatasetName=Water%20Temp.Best%20Available--Continuous%40A4261220&Datasets[2].Calculation=Instantaneous&Datasets[2].UnitId=169&_=1724767831011"), 
#               destfile = file.path(lake_directory, "data_raw", "current_inflow_angas.csv"))

cleaned_inflow_file <- file.path(config$file_path$qaqc_data_directory, paste0(config$location$site_id, "-targets-inflow.csv"))



list.files(pattern = "current_inflow*") |> 
  map_dfr(read_csv, id = "inflow_name", 
          show_col_types = FALSE, skip=5, 
          col_names = c('time1', 'time2', 'Value_FLOW', 'Value_EC', 'Value_TEMP')) |> 
  mutate(inflow_name = stringr::str_remove_all(inflow_name, str_c(c('.csv', 'current_inflow_'), collapse="|")),
         # simple conversion to salt
         Value_SALT = oce::swSCTp(conductivity = Value_EC/1000,
                                  temperature = Value_TEMP,
                                  conductivityUnit = 'mS/cm')) |> 
  # convert from m3/s --> m3/day
  # Value_FLOW = 86400 * Value_FLOW) |>
  select(-Value_EC) |>
  pivot_longer(names_to = 'variable',
               names_prefix = 'Value_',
               cols = Value_FLOW:Value_SALT,
               values_to = 'observed') |>
  mutate(time = lubridate::with_tz(time2, tzone = "UTC"),
         date = lubridate::as_date(time2),
         hour = lubridate::hour(time2)) |>
  group_by(date, variable, inflow_name) |> # calculate the daily mean - assign this to midnight
  summarize(observation = mean(observed, na.rm = TRUE), .groups = "drop") |>
  mutate(site_id = config$location$site_id,
         datetime = lubridate::as_datetime(paste(date, '00:00:00'))) |> # assigned to midnight
  select(site_id, inflow_name, datetime, variable, observation) |>
  write_csv(cleaned_inflow_file)
#=========================================#

# outflow observations ####

# combined 5 barrages (A4261002) - calculated flow
download.file(paste0('https://water.data.sa.gov.au/Export/BulkExport?DateRange=Custom&StartTime=2020-04-01%2000%3A00&EndTime=', Sys.Date(), '%2000%3A00&TimeZone=9.5&Calendar=CALENDARYEAR&Interval=PointsAsRecorded&Step=1&ExportFormat=csv&TimeAligned=True&RoundData=True&IncludeGradeCodes=False&IncludeApprovalLevels=False&IncludeQualifiers=False&IncludeInterpolationTypes=False&Datasets[0].DatasetName=Discharge.Total%20barrage%20flow%40A4261002&Datasets[0].Calculation=Instantaneous&Datasets[0].UnitId=241&_=1745424489848'),
              destfile = file.path(lake_directory, "data_raw", "current_outflow.csv"))

# Tuawitchere salinity and temperature to calculate salt export
# download.file(paste0('https://water.data.sa.gov.au/Export/BulkExport?DateRange=Custom&StartTime=2020-04-01%2000%3A00&EndTime=', Sys.Date(), '%2000%3A00&TimeZone=0&Calendar=CALENDARYEAR&Interval=PointsAsRecorded&Step=1&ExportFormat=csv&TimeAligned=True&RoundData=True&IncludeGradeCodes=False&IncludeApprovalLevels=False&IncludeQualifiers=False&IncludeInterpolationTypes=False&Datasets[0].DatasetName=Discharge.Total%20barrage%20flow%40A4261002&Datasets[0].Calculation=Instantaneous&Datasets[0].UnitId=239&Datasets[1].DatasetName=EC%20Corr.Best%20Available%40A4261207&Datasets[1].Calculation=Instantaneous&Datasets[1].UnitId=305&Datasets[2].DatasetName=Water%20Temp.Best%20Available--Continuous%40A4261207&Datasets[2].Calculation=Instantaneous&Datasets[2].UnitId=169&_=1744746294858'),
#               destfile = file.path(lake_directory, "data_raw", "current_outflow.csv"))


cleaned_outflow_file <- file.path(config$file_path$qaqc_data_directory, paste0(config$location$site_id, "-targets-outflow.csv"))

readr::read_csv(file.path(lake_directory, "data_raw", "current_outflow.csv"),
                skip = 5, show_col_types = FALSE,
                col_names = c('time', 'Value_FLOW')) |> 
                #col_names = c('time','Value_FLOW', 'Value_EC', 'Value_temperature')) |>
  # mutate(Value_salt = oce::swSCTp(conductivity = Value_EC/1000,
  #                                 temperature = Value_temperature,
  #                                 conductivityUnit = 'mS/cm')) |> 
  select(-any_of('Value_EC')) |> 
  # mutate(# convert from m3/s --> m3/day
  #        Value_FLOW = 86400 * Value_FLOW) |> 
  pivot_longer(names_to = 'variable',
               names_prefix = 'Value_',
               cols = -time,
               values_to = 'observed') |>
  mutate(time = lubridate::with_tz(time, tzone = "UTC"),
         date = lubridate::as_date(time),
         hour = lubridate::hour(time)) |>
  group_by(date, variable) |> # calculate the daily mean - assign this to midnight
  summarize(observation = mean(observed, na.rm = TRUE), .groups = "drop") |>
  mutate(site_id = 'ALEX',
         datetime = lubridate::as_datetime(paste(date, '00:00:00'))) |> # assigned to midnight
  select(site_id, datetime, variable, observation) |>
  write_csv(cleaned_outflow_file)

##=========================================##

setwd(lake_directory)
