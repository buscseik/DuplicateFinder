# Duplicate Finder
This function will scan all files in current folder and sub folders and build a list about duplication in default mode.
   You can use switches to choose one of the following options to manage files:
   
   DisplayOnly /  Manual / Auto / DefendedDirectory / Save / ReturnObject

### Important note.

I did not spend too much time on testing of this script. So use it carefully and make backup before run.



   
### Installation
```
Install-Module DuplicateFinder
```

### Examples
 * DisplayOnly
 
This is the default behaviour. Script will only scan and display result
```
Find-FileDuplicates -AfterBehaviour DisplayOnly
```
 * Manual
 
After scan, script will offer option to keep a selected file after every single duplication group.
```
   Find-FileDuplicates -AfterBehaviour Manual
```

 * Auto
 
After scan, script will delete all duplication except first instance.
```
   Find-FileDuplicates -AfterBehaviour Auto
```
   
 * DefendedDirectory
 
   After scan, script will delete all duplication except copies that located in protected folder instance.
   In case of duplication where no instance found in protected folder, the first instance will be kept.

   Script will ask for protected folders after start of the script.
```
   Find-FileDuplicates -AfterBehaviour DefendedDirectory
```
 
 * Save
 
   After scan, script will save result in an XML file.
```
   Find-FileDuplicates -AfterBehaviour Save
```


 * ReturnObject
 
   After scan, script will return the Object list that can be used for further manipulation.
```
   Find-FileDuplicates -AfterBehaviour ReturnObject
```

 * MoveDuplication
   After scan, script will keep the first instance of duplication and move the rest of dupliacation
   to a target folder. 
   Script will reserve relateive path.
   Target folder will be asked by script after start.
```
   Find-FileDuplicates -AfterBehaviour MoveDuplication
```
   
