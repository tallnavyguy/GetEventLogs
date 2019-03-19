# SCRIPT NAME               : GetEventLogs.ps1
# VERSION                   : 1.0
# CREATED DATE              : 03/19/2019
# LAST UPDATE               : 03/19/2019
# AUTHOR                    : Brian Hart
# DESCRIPTION               : A simple PowerShell script that manages getting event logs from the 
#                             Windows Event Log system and then exports them as CSV.  The columns
#                             written to the CSV are: 
#

# COMMAND-LINE ARGS         
# -LogName <Log>            : (Optional).  If specified, may be Application, Setup, System, or 
#                             Security.  Security log is the default.  These correspond to the
#                             categories listed under 'Windows Logs' in the eventvwr.exe applet on
#                             Windows.
#
# -Id <int>                 : (Optional). Specifies the ID number of the log(s) you want to extract.
#                             Must be an integer in between 0 and 65535 (inclusive).  If nothing is 
#                             specified, then all logs are extracted (which may or may not be what
#                             you want, since some logs contain thousands of entries).
#
# -FromDate <date>          : (Optional). Specifies that extracted log entries should be limited to
#                             those written on or after the specified date/time.  Must be specified
#                             as a string in any valid, system-parsable date-time format.
#
# -ToDate <date>            : (Optional). Specifies that extracted log entries should be limited to
#                             those written on or before the specified date/time.  Must be specified
#                             as a string in any valid, system-parsable date-time format.
#
# -CsvPath                  : (Required). Specifies the path, on disk, where the output should be 
#                             written to CSV.  Can be a network path.  The file does not have to 
#                             exist beforehand.

# Parse command-line args (if any) and ensure values will parse; stop the script execution
# otherwise.  if the args' values are all valid, then store them into variables for later use.

# Main execution

#       Search and filter the desired log
#       Gather all matching log entries that match the search
#           If no log entries found that match the search, report this to the user and then quit
#       Write 

# Clean up, if needed.