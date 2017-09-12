class UniqueSize
{
    UniqueSize()
    {
        $this.Count=0
        $this.ListOfFiles=@()
        $this.hashOfFiles=@()
    }
    [int32]$FileSize
    [int32]$Count
    [System.Collections.Generic.List[System.Object]]$ListOfFiles
    [System.Collections.Generic.List[System.Object]]$hashOfFiles
}

#Generate a file list that grouped by size and removed where size is unique
#Generate a reference object for each size, and add file list and hashes
#Group by hash
#Remove those hashes and file that are unique
#Generate a new list based on unique hash instead of size.
#Ready to manage delete...

function FindDuplicates()
{
	
    #Generate a file list that gruped by size and removed where size is unique
    Write-Host "$(Get-Date -Format "dd.MM.yyyy-HH:mm:ss [1/3]>") Building file list"
    $FullListOfDuplicationGroups=Get-ChildItem -File -Recurse | Sort-Object {$_.Length} | Group-Object -Property Length | where-Object {$_.Count -gt 1}


    Write-Host "$(Get-Date -Format "dd.MM.yyyy-HH:mm:ss [2/3]>") Generate hash for potential duplication candidatas"
    $ListOfUniqueHashObjects=@()
    
    $GroupCounter=0
    foreach($nextFileGroup in $FullListOfDuplicationGroups)
    {
        
        Write-Progress -Id 1 -Activity "Generate Hash for each duplication candidates" -status "Group completed $GroupCounter" -percentComplete ($GroupCounter / $FullListOfDuplicationGroups.Count*100)
        $GroupCounter++
        #Generate an reference object for each file size, that contain all the 
        [UniqueSize]$NewSize=[UniqueSize]::new()
        $NewSize.FileSize=$nextFileGroup.Name
        $NewSize.Count=$nextFileGroup.Count
        $NewSize.ListOfFiles+=$nextFileGroup.Group
        
        #Generate hash for files
        foreach($NextFileToHash in $NewSize.ListOfFiles)
        {
            $NewSize.hashOfFiles+=($NextFileToHash | Get-FileHash).hash
        }

        #Group by hash and generate new reference object for each invidual hash 
        $NewUniqueHashes=$NewSize.hashOfFiles | Group-Object | Where-Object {$_.Count -gt 1}
        
        #If only one hash group exists just copy over the original $NewSize object, 
        #If more than one hash exists, generate separate object for each.
        if($NewUniqueHashes.Count -eq 1)
        {
            $ListOfUniqueHashObjects+=$NewSize
        }
        else
        {
            foreach($nextHashGroup in $NewUniqueHashes)
            {
                [UniqueSize]$NewHashSize=[UniqueSize]::new()
                $NewHashSize.FileSize=$nextFileGroup.Name
            
            
                for([int]$i=0; $i -lt $NewSize.ListOfFiles.Count;$i++)
                {
                    if($NewSize.hashOfFiles[$i] -eq $nextHashGroup.Name)
                    {
                        $NewHashSize.ListOfFiles+=$NewSize.ListOfFiles[$i]
                        $NewHashSize.hashOfFiles+=$NewSize.hashOfFiles[$i]
                        $NewHashSize.Count++
                    }
                }
                $ListOfUniqueHashObjects+=$NewHashSize
            }
        }
        
    }
    Write-Progress -Id 1 -Activity "Generate Hash for each duplication candidates" -status "Completed" -percentComplete 100
    return $ListOfUniqueHashObjects
}
function CleanUpManual()
{
    param($ListOfDuplicatesGroups)
    $GroupCounter=0
    foreach($nextDuplicateGroup in $ListOfDuplicatesGroups)
    {
        
        $firstFile=$nextDuplicateGroup.ListOfFiles[0]
        $RestOfFiles=$nextDuplicateGroup.ListOfFiles | select -Skip 1

        Write-host "============================================================================================================="

        $FirstLineString="`n[0]   {0,-20} {1} {2}" -f $firstFile.Name, $($nextDuplicateGroup.hashOfFiles[0].Substring(0,20)+"..."), $firstFile.DirectoryName 
        Write-Host $FirstLineString -ForegroundColor Cyan

        $FileCounter=1
        foreach($nextFile in $RestOfFiles)
        {
            "  [{3}] {0,-20} {1} {2}" -f $nextFile.Name, $($nextDuplicateGroup.hashOfFiles[0].Substring(0,20)+"..."), $nextFile.DirectoryName, $FileCounter
            $FileCounter++
        }

        Write-Host "`nWhich one would you like to keep? Please specify by Nr of the file. `nIf you do not define whichone and hit enter, de default will be kept"
        $ItIsNotANumber=$true
        Do
        {
            try
            {
                [int]$FileNr=Read-Host 
                if($FileCounter -gt  $FileNr)
                {
                    $ItIsNotANumber=$false
                }
                else
                {
                    "Please enter your choise again!"
                }
            }
            catch
            {
                "Please enter your choise again!"
            }
        }while($ItIsNotANumber)
        
        if($FileNr -eq 0)
        {
            foreach($nextFileToDelete in $RestOfFiles)
            {
                "This has been deleted {0,-20} {1} {2}" -f $nextFileToDelete.Name,$($nextDuplicateGroup.hashOfFiles[0].Substring(0,20)+"..."), $nextFileToDelete.DirectoryName | Tee-Object -Append DeletedFilesLog.txt
                $nextFileToDelete | Remove-Item
            }
        }
        else
        {
                #Remove first Item
                "This has been deleted {0,-20} {1} {2}" -f $firstFile.Name,$($nextDuplicateGroup.hashOfFiles[0].Substring(0,20)+"..."), $firstFile.DirectoryName | Tee-Object -Append DeletedFilesLog.txt
                $firstFile | Remove-Item

                #Build a list without the file that will be kept
                $FileToNotDelete=$RestOfFiles[$($FileNr - 1)]
                $listToDelete=$RestOfFiles | where {$_ -ne $FileToNotDelete}

                #Remove rest of the files
                foreach($nextFileToDelete in $listToDelete)
                {
                    "This has been deleted {0,-20} {1} {2}" -f $nextFileToDelete.Name,$($nextDuplicateGroup.hashOfFiles[0].Substring(0,20)+"..."), $nextFileToDelete.DirectoryName | Tee-Object -Append DeletedFilesLog.txt
                    $nextFileToDelete | Remove-Item
                }
                
                
        }

        Write-Progress -Id 2 -Activity "Duplication groups been progressed" -status "Group completed $GroupCounter" -percentComplete ($GroupCounter / $ListOfDuplicatesGroups.Count*100)
        $GroupCounter++

    }
    Write-Progress -Id 2 -Activity "Duplication groups been progressed" -status "Completed" -percentComplete 100

    Write-host "============================================================================================================="
    Write-host "               You can find summary of file that has been deleted in DeletedFilesLog.txt"
    Write-host "============================================================================================================="
    
}
function CleanUpAuto()
{
    param($ListOfDuplicatesGroups)
    $GroupCounter=0
    foreach($nextDuplicateGroup in $ListOfDuplicatesGroups)
    {
        
        $firstFile=$nextDuplicateGroup.ListOfFiles[0]
        $RestOfFiles=$nextDuplicateGroup.ListOfFiles | select -Skip 1

        $FirstLine="This has been kept {0,-20} {1} {2}" -f $firstFile.Name,$($nextDuplicateGroup.hashOfFiles[0].Substring(0,20)+"..."), $firstFile.DirectoryName 
        Write-host $FirstLine -ForegroundColor Cyan

        foreach($nextFileToDelete in $RestOfFiles)
        {
            "This has been deleted {0,-20} {1} {2}" -f $nextFileToDelete.Name,$($nextDuplicateGroup.hashOfFiles[0].Substring(0,20)+"..."), $nextFileToDelete.DirectoryName | Tee-Object -Append DeletedFilesLog.txt
            $nextFileToDelete | Remove-Item
        }
        Write-Progress -Id 3 -Activity "Duplication groups been progressed" -status "Group completed $GroupCounter" -percentComplete ($GroupCounter / $ListOfDuplicatesGroups.Count*100)
        $GroupCounter++
    }
    Write-Progress -Id 2 -Activity "Duplication groups been progressed" -status "Completed" -percentComplete 100

    Write-host "============================================================================================================="
    Write-host "               You can find summary of file that has been deleted in DeletedFilesLog.txt"
    Write-host "============================================================================================================="
    
}

function CleanUpDefaultDir()
{
    param($ListOfDuplicatesGroups)

    #Collect readonly directory list
    $ReadOnlyDirectoryList=@()
    $InValidPath=$true
    do
    {
        Write-Host "`nPlease define read-only directories"
        try
        {
            $ReadOnlyDirectory=Read-Host
            if(Test-Path -PathType Container $ReadOnlyDirectory )
            {
                $lastChar=$ReadOnlyDirectory.Substring($($ReadOnlyDirectory.Length-1))
                if($lastChar -eq "\")
                {
                    $ReadOnlyDirectoryList+=$ReadOnlyDirectory+"*"
                }
                else
                {
                    $ReadOnlyDirectoryList+=$ReadOnlyDirectory+"\*"
                }

                $YesNoNotValid=$true
                do{
                    Write-host "Do you want to add another Directory?(y/n)"
                    $Answer=read-host
                    if($Answer -match "[yYnN]")
                    {
                        if($Answer -match "[nN]")
                        {
                            $InValidPath=$false   
                        }
                        $YesNoNotValid=$false
                    }
                    else
                    {
                        write-host "Pelase answer with y or n"
                    }
                }While($YesNoNotValid)
                
            }         
            else
            {
                Write-Host "Invalid Path"
            }
        }
        catch
        {
            Write-Host "Invalid path."
        }

        
    }While($InValidPath)


    $ReadOnlyDirectoryList | Format-Table


    $GroupCounter=0
    foreach($nextDuplicateGroup in $ListOfDuplicatesGroups)
    {
        
        $protectedFileList=@()
        $FilesToDelete=@()
        foreach($nextFile in $nextDuplicateGroup.ListOfFiles) 
        {
            $IsThisFileProtected=$false
            foreach($nextPath in $ReadOnlyDirectoryList)
            {
                if($($nextFile.DirectoryName.ToLower()+"\") -like $nextPath)
                {
                    $IsThisFileProtected=$true
                    
                }
            }
            if($IsThisFileProtected)
            {
                $protectedFileList+=$nextFile
            }
            else
            {
                $FilesToDelete+=$nextFile
            }
        }

        if($protectedFileList.count -gt 0)
        {
            foreach($nextFileToProtect in $protectedFileList)
            {
                $FirstLine="This has been kept {0,-20} {1} {2}" -f $nextFileToProtect.Name,$($nextDuplicateGroup.hashOfFiles[0].Substring(0,20)+"..."), $nextFileToProtect.DirectoryName 
                Write-host $FirstLine -ForegroundColor Cyan
            }
            foreach($nextFileToDelete in $FilesToDelete)
            {
                "This has been deleted {0,-20} {1} {2}" -f $nextFileToDelete.Name,$($nextDuplicateGroup.hashOfFiles[0].Substring(0,20)+"..."), $nextFileToDelete.DirectoryName | Tee-Object -Append DeletedFilesLog.txt
                $nextFileToDelete | Remove-Item
            }
        }
        else
        {
            #Keep the first file in this case
        
        
            $firstFile=$nextDuplicateGroup.ListOfFiles[0]
            $RestOfFiles=$nextDuplicateGroup.ListOfFiles | select -Skip 1
            
            $FirstLine="This has been kept {0,-20} {1} {2}" -f $firstFile.Name,$($nextDuplicateGroup.hashOfFiles[0].Substring(0,20)+"..."), $firstFile.DirectoryName 
            Write-host $FirstLine -ForegroundColor Cyan
            
            foreach($nextFileToDelete in $RestOfFiles)
            {
                "This has been deleted {0,-20} {1} {2}" -f $nextFileToDelete.Name,$($nextDuplicateGroup.hashOfFiles[0].Substring(0,20)+"..."), $nextFileToDelete.DirectoryName | Tee-Object -Append DeletedFilesLog.txt
                $nextFileToDelete | Remove-Item
            }
        }
        Write-Progress -Id 4 -Activity "Duplication groups been progressed" -status "Group completed $GroupCounter" -percentComplete ($GroupCounter / $ListOfDuplicatesGroups.Count*100)
        $GroupCounter++
    }
    Write-Progress -Id 2 -Activity "Duplication groups been progressed" -status "Completed" -percentComplete 100

    Write-host "============================================================================================================="
    Write-host "               You can find summary of file that has been deleted in DeletedFilesLog.txt"
    Write-host "============================================================================================================="
    
}

function CleanUpMove()
{
    param($ListOfDuplicatesGroups)
    
    #get output folder from user and validate
    $IsItCorrectPath=$false
    do
    {
        $OutPutPath=Read-Host("Please define directory path where duplicated files can be moved")
    
        if($OutPutPath[$OutPutPath.Length-1] -ne "\")
        {
            $OutPutPath+="\"
        }    
        $CurrentFolder=(Get-Location).Path
        $CurrentFolder+="\"
        
        #the output folder must be a different folder than source folder.
        if($CurrentFolder -eq $OutPutPath)
        {
            write-host "Output folder must be different!"

        }
        else
        {
            $IsItCorrectPath=$true
        }
    }while(!$IsItCorrectPath)

####
    

    #Proceed file moves group by group
    $GroupCounter=0
    foreach($nextDuplicateGroup in $ListOfDuplicatesGroups)
    {
        #Separate the group for first item and rest of the list
        $firstFile=$nextDuplicateGroup.ListOfFiles[0]
        $RestOfFiles=$nextDuplicateGroup.ListOfFiles | select -Skip 1


        $FirstLine="This has been kept {0,-20} {1} {2}" -f $firstFile.Name,$($nextDuplicateGroup.hashOfFiles[0].Substring(0,20)+"..."), $firstFile.DirectoryName 
        Write-host $FirstLine -ForegroundColor Cyan

        #Move rest of the list
        foreach($nextFileToDelete in $RestOfFiles)
        {
            "This has been moved {0,-20} {1} {2}" -f $nextFileToDelete.Name,$($nextDuplicateGroup.hashOfFiles[0].Substring(0,20)+"..."), $nextFileToDelete.DirectoryName | Tee-Object -Append MovedFilesLog.txt
            
            #Script will keep original folder structure on new location, so need to build up relative path based on 
            #start location and current file location
            $nextFilePath=$OutPutPath+$($nextFileToDelete.FullName.SubString($CurrentFolder.Length))
            $NextFileDirectory=$nextFilePath.Substring(0,$nextFilePath.IndexOf($nextFilePath.Split("\")[$nextFilePath.Split("\").Length-1]))
            
            #Check if do directory exists and move
            if (!(Test-Path -path $NextFileDirectory)) {$temp=New-Item $NextFileDirectory -Type Directory }
            Move-Item $nextFileToDelete.fullname $nextFilePath

            
        }

        Write-Progress -Id 5 -Activity "Duplication groups been progressed" -status "Group completed $GroupCounter" -percentComplete ($GroupCounter / $ListOfDuplicatesGroups.Count*100)
        $GroupCounter++
    }
    Write-Progress -Id 2 -Activity "Duplication groups been progressed" -status "Completed" -percentComplete 100

    Write-host "============================================================================================================="
    Write-host "               You can find summary of file that has been moved in MovedFilesLog.txt"
    Write-host "============================================================================================================="
####

    
}



function Find-FileDuplicates()
{
<#
   
.DESCRIPTION
   +---------------------------------------------------------------------------------------------------------------------+
   |                Please make a backup before proceed or use DisplayOnly or ReturnObject features                      |
   +---------------------------------------------------------------------------------------------------------------------+
   This function will scan all files in current folder and sub folders and build a list about duplication in default mode.
   You can use switches to choose one of the following options to manage files:
   
   DisplayOnly /  Manual / Auto / DefendedDirectory / Save / ReturnObject / MoveDuplication

.EXAMPLE
   Find-FileDuplicates -AfterBehaviour DisplayOnly
   This is the default behaviour. Script will only scan and display result

.EXAMPLE
   Find-FileDuplicates -AfterBehaviour Manual
   After scan, script will offer option to keep a selected file after every single duplication group.

.EXAMPLE
   Find-FileDuplicates -AfterBehaviour Auto
   After scan, script will delete all duplication except first instance.

.EXAMPLE
   Find-FileDuplicates -AfterBehaviour DefendedDirectory
   After scan, script will delete all duplication except copies that located in protected folder instance.
   In case of duplication where no instance found in protected folder, the first instance will be kept.

   Script will ask for protected folders after start of the script.

.EXAMPLE
   Find-FileDuplicates -AfterBehaviour Save
   After scan, script will save result in an XML file.

.EXAMPLE
   Find-FileDuplicates -AfterBehaviour ReturnObject
   After scan, script will return the Object list that can be used for further manipulation.

.EXAMPLE
   Find-FileDuplicates -AfterBehaviour MoveDuplication
   After scan, script will clean up automiticlly and keep one instance of it. 
   Rest of the duplications will be moved to the target folder with relative path.
   Target folder will need to be provided on interactive way after script start.

#>
    
    param(
        [ValidateSet('DisplayOnly','Manual','Auto','DefendedDirectory', 'Save', 'ReturnObject',"MoveDuplication")]
        [Parameter(Mandatory=$false, HelpMessage="Option to choose what script will do after file scan.")]
        [string]$AfterBehaviour="DisplayOnly")
    

    $ListOfDuplicates=FindDuplicates

    Write-Host "$(Get-Date -Format "dd.MM.yyyy-HH:mm:ss [3/3]>") Clean Up"
    
    if($AfterBehaviour -in "Manual", "Auto", "DefendedDirectory")
    {
        $completed=$false
        do
        {
            Write-Host "=============================================================================================================" -ForegroundColor DarkYellow
            Write-Host "  Backup before procceding is highly recommended, or if you are not sure try DisplayOnly or MoveDuplication " -ForegroundColor DarkYellow
            Write-Host "=============================================================================================================" -ForegroundColor DarkYellow

            $Confirmation=Read-Host("Do you want to continue?[y/n] ")
            if($Confirmation.ToLower() -eq "y")
            {
                $completed=$true
            }
            elseif($Confirmation.ToLower() -eq "n")
            {
                
                return
            }
        }while(!$completed)
    }


    if($AfterBehaviour -eq "DisplayOnly")
    {
        $ListOfDuplicates
    }
    if($AfterBehaviour -eq "ReturnObject")
    {
        return $ListOfDuplicates
    }
    if($AfterBehaviour -eq "Save")
    {
        Write-host "All object has been exported to FileDuplication.xml"
        return $ListOfDuplicates | Export-CliXML FileDuplication.xml
    }
    if($AfterBehaviour -eq "Manual")
    {
        CleanUpManual $ListOfDuplicates
    }
    if($AfterBehaviour -eq "Auto")
    {
        CleanUpAuto $ListOfDuplicates
    }
    if($AfterBehaviour -eq "DefendedDirectory")
    {
        CleanUpDefaultDir $ListOfDuplicates 
    }
    if($AfterBehaviour -eq "MoveDuplication")
    {
        CleanUpMove $ListOfDuplicates 
    }
}