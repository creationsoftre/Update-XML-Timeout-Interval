<###############################
Title: Update ClaimsXten Timeout Interval
Author: TW
Original: 2022_02_27
Last Updated: 2022_02_27
	

Overview:
- Update ClaimsXten Timeout Interval to 120 to prevent NCCI Market errors.
- Script no longer needed after R59 (2/1) as this change is now hard coded into the custom release.
###############################>

# Show an Open File Dialog and return the file selected by the user.
function Read-OpenFileDialog([string]$WindowTitle, [string]$InitialDirectory, [string]$Filter = "All files (*.*)|*.*", [switch]$AllowMultiSelect)
{  
    Add-Type -AssemblyName System.Windows.Forms

    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog

    $openFileDialog.Title = $WindowTitle

    if ($InitialDirectory) 
    { 
        $openFileDialog.InitialDirectory = $InitialDirectory 
    }

    $openFileDialog.Filter = $Filter
    if ($AllowMultiSelect) 
    { 
        $openFileDialog.MultiSelect = $true 
    }

    $openFileDialog.ShowHelp = $true 
    $null = $openFileDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))

    if ($AllowMultiSelect) 
    { 
        return $openFileDialog.Filenames 
    } 
    else 
    { 
        return $openFileDialog.Filename 
    }
}

#Selecting a server list file for contents to be read
$serverList = Read-OpenFileDialog -WindowTitle "Select your Server List" -InitialDirectory 'c:\temp' -Filter "Text files (*.txt)|*.txt"
if (![string]::IsNullOrEmpty($serverList)) 
{ 
    Write-Host "You selected the file: $serverList" 
}
else
{ 
    "You did not select a file.";break 
}


#reading servers in server lis
$servers = @(Get-content $serverList)

#User Credntials
$cred = "$env:USERDOMAIN\$env:USERNAME"

#Get User credentials
$userCredentials = Get-Credential -UserName $cred  -message 'Enter credentials for Elevated Account' 

#Create new PowerShell Session on each Server in server list
$sessions = New-PSSession -ComputerName $servers -Credential $userCredentials

#Perform the folllowing steps on each server
Invoke-Command -Session $sessions {
#User Variables 
$origPath = 'PATH\McKesson.TPP.DTO.Configurations.RuleEngineSettings.xml'
$ootbPath = 'PATH\\McKesson.TPP.DTO.Configurations.RuleEngineSettings_OOTB.xml'
$dir = 'D:\CXT\totalpayment\Data\'

if(Test-Path $dir){
    #TEST
    Write-Host 'Making Copy of OOTB McKesson.TPP.DTO.Configurations.RuleEngineSettings.xml' -ForegroundColor Cyan

    #Check if xml file OOTB file exist
    if(!(Test-Path $ootbPath)){
        Copy-Item -Path $origPath -Destination $ootbPath

        if(Test-Path -path $ootbPath)
        {
            Write-Host 'McKesson.TPP.DTO.Configurations.RuleEngineSettings.xml has been Successfully Copied and Renamed' -ForegroundColor Green
        }else{
            Write-Host 'Copy of McKesson.TPP.DTO.Configurations.RuleEngineSettings.xml failed' -ForegroundColor Red
            }

    } else {
       Write-Host $dir ' was not found' -ForegroundColor Yellow
    }
}else{
       Write-Host 'McKesson.TPP.DTO.Configurations.RuleEngineSettings_OOTB already exist. Please remove file and try again.' -ForegroundColor Yellow
       break
}

#Modify McKesson.TPP.DTO.Configurations.RuleEngineSettings.xml <d2p1:Value>20</d2p1:Value> to <d2p1:Value>120</d2p1:Value>
$xmlFile = "D:\CXT\totalpayment\Data\McKesson.TPP.DTO.Configurations.RuleEngineSettings.xml"
$xmlData =  [xml](Get-Content $xmlFile)

# create namespace prefixes
$nametable = new-object System.Xml.NameTable;
$nsmgr = new-object System.Xml.XmlNamespaceManager($nametable);
$nsmgr.AddNamespace("x", "http://schemas.datacontract.org/2004/07/McKesson.TPP.DTO.Configurations");
$nsmgr.AddNamespace("a", "http://schemas.microsoft.com/2003/10/Serialization/Arrays");


$nodeToSelect = "x:RuleEngineSettings/x:Settings/a:KeyValueOfstringstring"

# note the $nsmgr parameter which maps "a:" in the xpath query to the actual namespace
# "http://schemas.microsoft.com/2003/10/Serialization/Arrays" in the xml document
$Xmlnodes = $xmlData.SelectNodes($nodeToSelect, $nsmgr)
$Xmlnode = $Xmlnodes | Where-Object {$_.Key -eq "timeout_interval"}

try{
    $Xmlnode.Value = "120"

    $xmlData.Save($xmlFile)

    Write-Host "Timeout Interval Successfully Updated." -ForegroundColor Green
}
catch{

    $ErrorMessage = $Error[0].Exception.Message
    Write-Host "Updating Timeout Interval Failed - $Error"

}



}
#Close session#>
$s = Get-PSSession
Remove-PSSession -Session $s


