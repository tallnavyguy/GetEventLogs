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
# -RemoteServers            : (Required). Set to localhost to specify the local machine, otherwise, this
#                             param must be a comma-separated list of either NetBIOS machine names or 
#                             IP addresses on a LAN, from which you want to pull the logs.

# Parse command-line args (if any) and ensure values will parse; stop the script execution
# otherwise.  if the args' values are all valid, then store them into variables for later use.

param (
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)][string]$LogName = "Security",
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)][int]$Id = 4657,
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)][DateTime]$FromDate = [DateTime]::MinValue,
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)][DateTime]$ToDate = [DateTime]::MaxValue,
    [Parameter(Mandatory = $false,  ValueFromPipeline = $true)][int]$DesiredCount = [int]::MinValue,
    [Parameter(Mandatory = $true,  ValueFromPipeline = $true)][string]$CsvPath = "",
    [Parameter(Mandatory = $false,  ValueFromPipeline = $true)][string]$RemoteServers = "localhost",
    [Parameter(Mandatory = $false,  ValueFromPipeline = $true)][switch]$SortAscendingByTime = $true,
    [Parameter(Mandatory = $false,  ValueFromPipeline = $true)][switch]$SortDescendingByTime = $false
 )

# Main execution

function Main {
    "Reading events from the {0} log..." -f $LogName | Write-Host

    $global:CmdToInvoke = "Get-EventLog -LogName {0} " -f $LogName

    ParseDesiredCount -DesiredCount $DesiredCount

    ParseDateRange -FromDate $FromDate -ToDate $ToDate

    $global:CmdToInvoke = $global:CmdToInvoke + "| Sort-Object TimeGenerated -Descending | Select UserName, TimeGenerated | Format-Table"

    $list = (Invoke-Expression -Command $global:CmdToInvoke)

    if ($list.Count -eq 0) {
        Write-Host "No results returned."
    } else {
        "{0} results found." -f ($list.Count - 4)| Write-Host
    }
}

function ParseDesiredCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,  ValueFromPipeline = $true)][int]$DesiredCount
    )

    switch($true) {
        {$DesiredCount -le 0} {
            Return
        }
        {$DesiredCount -gt 0} {
            $DesiredCountParam = "-Newest {0}" -f $DesiredCount

            $global:CmdToInvoke = $global:CmdToInvoke + ' ' + $DesiredCountParam
        }
    }

    if ($DesiredCount -eq [int]::MinValue) {
        Return
    }
}

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

function bar {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [pscustomobject]$Thing
    )

    $Thing
}

. Main

#       Search and filter the desired log
#       Gather all matching log entries that match the search
#           If no log entries found that match the search, report this to the user and then quit
#       Write 

# Clean up, if needed.
