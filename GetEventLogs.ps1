# SCRIPT NAME               : GetEventLogs.ps1
# VERSION                   : 1.0
# CREATED DATE              : 03/19/2019
# LAST UPDATE               : 04/02/2019
# AUTHOR                    : Brian Hart
# DESCRIPTION               : A simple PowerShell script that manages getting event logs from the 
#                             Windows Event Log system and then exports them as CSV.  The columns
#                             written to the CSV are UserName and TimeGenerated.
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
# -RemoteServers            : (Required). Set to localhost to specify the local machine, otherwise, this
#                             param must be a comma-separated list of either NetBIOS machine names or 
#                             IP addresses on a LAN, from which you want to pull the logs.  The Loop-
#                             back address (127.0.0.1) is not supported
# -DesiredCount             : (Optional.)  Count of the number of records desired as output.  If this
#                             parameter is equal to 1.
#
# -SortAscendingByTime      : (Optional.) If specified, this parameter returns the results in order by
#                             time generated, with the most-recently-generated event at the bottom of
#                             the list.   Results are sorted in the reverse order if this parameter
#                             is not included.  Sorting results by descending order is the default.

###############################################################################
# Parse command-line args (if any) and ensure values will parse; stop the script execution
# otherwise.  if the args' values are all valid, then store them into variables for later use.
###############################################################################

param (
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)][string]$LogName = "Security",
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)][int]$Id = 4657,
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)][DateTime]$FromDate = [DateTime]::MinValue,
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)][DateTime]$ToDate = (Get-Date),
    [Parameter(Mandatory = $false,  ValueFromPipeline = $true)][int]$DesiredCount = 1,
    [Parameter(Mandatory = $true,  ValueFromPipeline = $true)][string]$CsvPath = "",
    [Parameter(Mandatory = $false,  ValueFromPipeline = $true)][string]$RemoteServers = "localhost",
    [Parameter(Mandatory = $false,  ValueFromPipeline = $true)][switch]$SortAscendingByTime = $false
 )

###############################################################################
# Main execution function - the program's entry point.
###############################################################################

function Main {
    # OKAY, so this program is basically asked to do the following:
    #   1. Validate and parse input parameters that drive our execution
    #       a. Apply QC rules to the input parameters  
    #           i. Count of desired records, if specified, must be a positive
    #              integer since I don't know what is meant by -5 records
    #           ii. From Date must be either today's date or in the past
    #           iii. To Date must be either today's date or in the past
    #           iv. From date must be on or before the To Date
    #       b. If input parameters satisfy QC rules
    #           i. Translate our input parameters' values into the corresponding
    #              values accepted by Get-EventLog
    #       c. If a particular input parameter's value violates QC rules
    #           i. Throw an error with a descriptive message about the validation
    #              if applicable, or just let the case through, depending on the 
    #              situation. 
    #           ii. If an error is thrown, then die so the user can fix their 
    #               input first.
    #   2. Invoke the Get-EventLog cmdlet and filter the results by ID, date
    #      range, desired count, etc.
    #   3. Export the results as CSV
    # Along the way, we also tell the user what we're doing.  Input parameters
    # have rules applied to them by various 'black-box' parser functions to apply
    # QC rules to the input parameters' values, such as count being negative or
    # from and to dates being in the wrong order etc.
    #
    
    $global:CmdToInvoke = "Get-EventLog -LogName {0} " -f $LogName

    if ((IsValidCount -DesiredCount $DesiredCount) -eq $false) {
        $LASTEXITCODE = -1;
        Return
    }
    
    ParseDesiredCount -DesiredCount $DesiredCount

    if ((IsValidDateRange -FromDate $FromDate -ToDate $ToDate) -eq $false) {
        $LASTEXITCODE = -1;
        Return   
    }
    
    ParseDateRange -FromDate $FromDate -ToDate $ToDate

    $global:CmdToInvoke = $global:CmdToInvoke + "| Sort-Object TimeGenerated -Descending | Select UserName, TimeGenerated | Export-Csv " + $CsvPath

    Invoke-Expression -Command $global:CmdToInvoke
}

###############################################################################
# IsValidCount function
#
# FUNCTION NAME             : IsValidCount
# CREATED DATE              : 03/25/2019
# LAST UPDATE               : 03/25/2019
# AUTHOR                    : Brian Hart
# IN                        : -DesiredCount: Variable that supposedly holds a count;
#                             i.e. a value that is an integer greater than zero.
# MODIFIES                  : Nothing
# RETURNS                   : $true if the value specified is an integer that
#                             is greater than zero. $false otherwise.
# DESCRIPTION               : Runs validation rules that determine whether a
#                             specific variable actually holds a count, e.g.,
#                             of desired records.
###############################################################################
function IsValidCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)][int]$DesiredCount = [int]::MinValue
    )
    
    Return $DesiredCount -gt 0
}

###############################################################################
# ParseDesiredCount function
#
# FUNCTION NAME             : ParseDesiredCount
# CREATED DATE              : 03/19/2019
# LAST UPDATE               : 03/25/2019
# AUTHOR                    : Brian Hart
# IN                        : -DesiredCount: Count of records you want returned.
#                             If this parameter is not specified then nothing is 
#                             done and this function returns immediately.
# MODIFIES                  : $global:CmdToInvoke - Altered to specify the appr-
#                             opriate amount of records that must be returned, if
#                             applicable
# DESCRIPTION               : Serves as a "black box" of sorts that modifies the
#                             global $global:CmdToInvoke variable after applying
#                             quality-check rules to the -DesiredCount parameter
#                             such as checking to ensure the parameter is an 
#                             integer greater than zero.  If the parameter is 
#                             less than or equal to zero, then we assume the user
#                             is requesting all available records, and therefore
#                             we do not do anything to the global command invocation
#                             string.
###############################################################################

function ParseDesiredCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)][int]$DesiredCount = [int]::MinValue
    )

    if ($DesiredCount -le 0) {
        Return
    }

    $DesiredCountParam = "-Newest {0} " -f $DesiredCount

    $global:CmdToInvoke = $global:CmdToInvoke + $DesiredCountParam
}

###############################################################################
# IsValidDateRange function
#
# FUNCTION NAME             : IsValidDateRange
# CREATED DATE              : 03/25/2019
# LAST UPDATE               : 03/25/2019
# AUTHOR                    : Brian Hart
# IN                        : -FromDate: DateTime value indicating the lower end
#                             of the TimeGenerated value on which to filter records.
#                             Required.
#                           : -ToDate: DateTime value indicating the upper end of
#                             the TimeGenerated value on which to filter records.
#                             Required.
# MODIFIES                  : Nothing
# RETURNS                   : $true if the date range is valid; $false
#                             otherwise.
# DESCRIPTION               : A date range is supposed to consist of a 'From
#                             Date' and a 'To Date', the 'From Date' coming first
#                             and not being equal to the 'To Date'.  This
#                             function runs validation rules to screen against
#                             absurd things such as the From Date being after
#                             the To Date or the To Date being before the From
#                             Date, or one or the other date being in the future.
#                             DateTime.MinValue and DateTime.MaxValue are allowed
#                             inputs for the 
###############################################################################
function IsValidDateRange {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)][DateTime]$FromDate = [DateTime]::MinValue,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)][DateTime]$ToDate = [DateTime]::MaxValue
    )
    
    # Get the time that it is now
    $Now = Get-Date
    
    # The FromDate can't be in the future.  The FromDate can be
    # equal to today's date.
    if ($FromDate -gt $Now) {
        Return $false
    }
    
    # The ToDate can't be in the future.  The ToDate can be 
    # equal to today's date.
    if ($ToDate -gt $Now) {
        Return $false
    }

    # The FromDate can't be greater than the ToDate; although the 
    # dates can be the same
    if ($FromDate -gt $ToDate) {
        Return $false
    }
    
    # If we are still here, then the dates are valid
    Return $true
}

###############################################################################
# ParseDateRange function
#
# FUNCTION NAME             : ParseDateRange
# CREATED DATE              : 03/19/2019
# LAST UPDATE               : 03/25/2019
# AUTHOR                    : Brian Hart
# IN                        : -FromDate: DateTime value indicating the lower end
#                             of the TimeGenerated value on which to filter records.
#                             Optional.
#                           : -ToDate: DateTime value indicating the upper end of
#                             the TimeGenerated value on which to filter records.
#                             Optional.
# MODIFIES                  : $global:CmdToInvoke - Altered to specify the appr-
#                             opriate amount of records that must be returned, if
#                             applicable
# DESCRIPTION               : Serves as a "black box" of sorts that modifies the
#                             global $global:CmdToInvoke variable after applying
#                             quality-check rules to the -FromDate and -ToDate 
#                             parameters' values with the future, to-be-written
#                             ValidateDateRange function.
#
###############################################################################

function ParseDateRange {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)][DateTime]$FromDate = [DateTime]::MinValue,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)][DateTime]$ToDate = [DateTime]::MaxValue
    )

    $FromDateParam = ""
    $ToDateParam = ""

    # Parse the values of the $FromDate and $ToDate parameter values and formulate the command string
    # for actually calling Get-EventLog

    switch ( $true) {
        {$FromDate -eq [DateTime]::MinValue -and $ToDate -eq [DateTime]::MaxValue } {
            Write-Host "Getting events for all dates..."

            $FromDateParam = ""
            $ToDateParam = ""

            Return
        }

        {$FromDate -gt [DateTime]::MinValue -and $ToDate -eq [DateTime]::MaxValue } {
            "Getting all events logged on or after {0} at {1}..." -f $FromDate.ToShortDateString(), 
            $FromDate.ToShortTimeString() | Write-Host

            $FromDateParam = "-After '{0}'" -f $FromDate
            $ToDateParam = ""

            $global:CmdToInvoke = $global:CmdToInvoke + $FromDateParam
            Return
        }

        {$FromDate -eq [DateTime]::MinValue -and $ToDate -lt [DateTime]::MaxValue } {
            "Getting all events logged on or before {0} at {1}..." -f $ToDate.ToShortDateString(), 
            $ToDate.ToShortTimeString() | Write-Host

            $FromDateParam =  ""
            $ToDateParam = "-Before '{0}'" -f $ToDate

            $global:CmdToInvoke = $global:CmdToInvoke + $ToDateParam
            Return
        }

        {$FromDate -gt [DateTime]::MinValue -and $ToDate -lt [DateTime]::MaxValue } {
            "Getting all events logged on or after {0} at {1} and on or before {2} at {3}..." -f 
            $FromDate.ToShortDateString(), $FromDate.ToShortTimeString(),
            $ToDate.ToShortDateString(), $ToDate.ToShortTimeString() | Write-Host

            $FromDateParam = "-After '{0}'" -f $FromDate
            $ToDateParam = "-Before '{0}'" -f $ToDate

            $global:CmdToInvoke = $global:CmdToInvoke + $FromDateParam + ' ' + $ToDateParam
            Return
        }
    }
}

. Main