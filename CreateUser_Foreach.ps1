Write-Output 'Starting operations. Timer begins now.'
	$elapsed = [System.Diagnostics.Stopwatch]::StartNew()

$AllCities = get-content "C:\System\runspaces\us-500.csv" | select -Skip 1 | ConvertFrom-Csv -Header "first_name","last_name","company_name","address","city","county","state","zip","phone1","phone2","email","web"
        
Import-module ActiveDirectory
$Path = "OU=Bulk,OU=Users,OU=HQ,DC=District,DC=Local"
foreach ($Line in $AllCities){

    New-ADUser -Name ($line.First_Name + " " + $Line.Last_Name) -GivenName $Line.First_Name -Surname $Line.Last_Name  -City $Line.City -Path $Path -Description "Created with simple foreach" 

}

$seconds = $elapsed.Elapsed.TotalSeconds
write-output "Time elapsed: $($seconds)"