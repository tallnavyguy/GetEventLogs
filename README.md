# Introduction
A simple PowerShell script that manages getting event logs from the Windows Event Log system and then exports them as CSV.  The columns written to the CSV are ```UserName``` and ```TimeGenerated```.
# Syntax
To execute this script, call:
```
.\GetEventLogs.ps1
    [-LogName] <string>
    [-Id] <int>
    [-FromDate] <datetime>
    [-ToDate] <datetime>
    -CsvPath <string>
    [-RemoteServers] <string[]>
    [-DesiredCount] <int>
    [-SortAscendingByTime]
    [<CommonParameters>]
```
# Example
An example of calling this script successfully is as follows:
```
PS C:\Users\Navy\source\repos\GetEventLogs> .\GetEventLogs.ps1 -CsvPath .\a.csv -DesiredCount 100
Getting all events logged on or before 4/2/2019 at 3:56 PM...
```
This call produces the file ```a.csv``` in the current directory:
```
PS C:\Users\Navy\source\repos\GetEventLogs> dir


    Directory: C:\Users\Navy\source\repos\GetEventLogs


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----         4/2/2019   3:56 PM           2477 a.csv
-a----         4/2/2019   3:40 PM          15851 GetEventLogs.ps1
```
# Further notes
The ```GetEventLogs.ps1``` script fetches event logs from either the local machine or the specified remote servers and then exports the output as a CSV file containing only the ```UserName``` and ```TimeGenerated``` properties in its columns.

Please see the comments at the top of the file for information on the parameters and their valid values.
