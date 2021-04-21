[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$NewArray =@()
$OldArray =@()
$OldNotInNew =@()
$NewNotInOld =@()

#Function to open FileExpolrer
#This will allow selection of New.sha1.txt and Old.sha1.txt
Function Get-Backup($Dir)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.winodws.forms") | Out-Null

    $OpenFileExplorer = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileExplorer.InitialDirectory = $Dir
    $OpenFileExplorer.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
    $OpenFileExplorer.ShowDialog() | Out-Null
    $OpenFileExplorer.FileName
}


#Allow user to select Old.sha1.txt and New.sha1.txt
Write-Host "`nSelect Old.sha1.txt"
Start-Sleep -Seconds 1
$oldSha1Path = Get-Backup -initialDirectory “C:”
Write-Host "Old.sha1.txt Path = $($oldSha1Path)"

Write-Host "`nSelect New.sha1.txt"
Start-Sleep -Seconds 1
$newSha1Path = Get-Backup -initialDirectory “C:”
Write-Host "New.sha1.txt Path = $($newSha1Path)"

#Allow user to select folder where they'd like to save the output
Write-Host "`nSelect where to save your output"
Start-Sleep -Seconds 1

#Generate FolderDialogBox 
Add-Type -AssemblyName System.Windows.Forms
$Folder = New-Object System.Windows.Forms.FolderBrowserDialog
$null = $Folder.ShowDialog()
$OutputPath =  "$($Folder.SelectedPath)"
$OutputPathOld = "$($Folder.SelectedPath)\OldNotInNew.txt"
$OutputPathNew = "$($Folder.SelectedPath)\NewNotInOld.txt"


#Get Content of New.sha1.txt.txt and Old.sha1.txt.txt
$newSha1Content = Get-Content -Path $newSha1Path
$oldSha1Content = Get-Content -Path $oldSha1Path

#Loop through Old.sha1.txt and set SHA1 + Filename values as an object
ForEach($line in $oldSha1Content)
{
    $SHA = $line.split(' ')[0]
    $filename = $line.substring($SHA.length + 1, $line.length-$SHA.length-1)
    $object = New-Object System.Object
    $object | Add-Member -type NoteProperty -name SHA -Value $SHA
    $object | Add-Member -type NoteProperty -name Filename -Value $filename
    $OldArray += $object
}

#Loop through New.sha1.txt and set SHA1 + Filename values as an object
ForEach($line in $newSha1Content)
{
    $SHA = $line.split(' ')[0]
    $filename = $line.Substring($SHA.length+1,$line.length-$SHA.length-1)
    $object = New-Object System.Object
    $object | Add-Member -type NoteProperty -name SHA -Value $SHA
    $object | Add-Member -type NoteProperty -name Filename -Value $filename
    $NewArray += $object
}

#Compare the backup objects
$CompareBackUps = Compare-Object -ReferenceObject $NewArray -DifferenceObject $OldArray -Property SHA -PassThru

#Loop through the comparision output and assign to cooresponding results to their own array.
ForEach($i in $CompareBackUps)
{
    if($i.sideindicator -eq "=>")
    {
        $OldNotInNew += $i
    }
    if($i.sideindicator -eq "<=")
    {
        $NewNotInOld += $i
    }
}


#Output the final results into .txt
Set-Content -Path $OutputPathOld -Value "OldNotInNew.txt contains:`n$($OldNotInNew.FileName -join "`n")"
Set-Content -Path $OutputPathNew -Value "NewNotInOld.txt contains:`n$($NewNotInOld.FileName -join "`n")"

#Popup with output and file locations for the user to see
$Shell = New-Object -ComObject "WScript.Shell"
$Shell.Popup("The Output Files Are Located: $($OutputPath) `n`nClick OK to end.", 0, "OldNotInNew and NewNotInOld", 0)        
