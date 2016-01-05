
Function Group-PerCity {
    Param(
        $CityName,
        $FirstName,
        $LastName,
        $Path
    )

    $FullPath = join-Path -Path $Path -childPath ($CityName+'.txt') 

    if (!(test-Path $FullPath)){
        New-Item -path $FullPath -ItemType File
        $Header = 'First_Name,Laste_Name'
        $header > $FullPath
    }

     "$FirstName,$LastName" >> $FullPath
    
}

$ScriptBlock = {
   Param(

        $FirstName,
        $LastName,
        $CityName,
        $Path,
        $Description

    )

    New-ADUser -Name ($FirstName + " " + $LastName) -GivenName $FirstName -Surname $LastName  -City $CityName -Path $Path -Description $Description
}

	Write-Output 'Starting operations. Timer begins now.'
	$elapsed = [System.Diagnostics.Stopwatch]::StartNew()


        #work around to avoir error 'Member already exists'
        $AllCities = get-content "C:\System\runspaces\us-500.csv" | select -Skip 1 | ConvertFrom-Csv -Header "first_name","last_name","company_name","address","city","county","state","zip","phone1","phone2","email","web"
        $Count = 0
        $Max = $Allcities.Count-1
        $RunSpaceParameters = @{
            'Path'= "OU=Bulk,OU=Users,OU=HQ,DC=District,DC=Local"
            'FirstName'=''
            'LastName'=''
            'City'=''
            'Description'='Created with Runspaces'
        }
        
        # Setup runspace pool and the scriptblock that runs inside each runspace
            $MinRunspaces = 1
            $Throttle = 500
	        #$pool = [RunspaceFactory]::CreateRunspacePool($MinRunspaces,$MaxRunspaces)

        #Creating Sessions state that is needed in order to load the module
            $SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $SessionState.ImportPSModule('ActiveDirectory')
            $Pool = [runspacefactory]::CreateRunspacePool(1,$Throttle,$SessionState,$Host)
	        $pool.ApartmentState = 'MTA'
	        $pool.Open()
	        $jobs = @()
       

        0..$Max | % {
            
           $job = [PowerShell]::Create()
           $job.RunspacePool = $pool
           $RunSpaceParameters.LastName = $Allcities[$_].Last_Name
           $RunSpaceParameters.City = $Allcities[$_].City
           $RunSpaceParameters.FirstName = $Allcities[$_].First_Name

      
		   $null = $job.AddScript($ScriptBlock)
		   $null = $job.AddParameters($RunSpaceParameters)
		   
		   
		   $jobs += [PSCustomObject]@{ Pipe = $job; Status = $job.BeginInvoke() }
           #write-output "Working on $($_)"
           
        }
while ($jobs.Status.IsCompleted -notcontains $true) {}
$seconds = $elapsed.Elapsed.TotalSeconds
write-output "Time elapsed: $($seconds)"

#Results:
#Results without output 

