$CurrentSchedule = import-csv "\\conrad\{Private}$\BusinessTechnology\Westwood College\save for chris.csv"


function create-musCourseCodeGroups{
[cmdletbinding()]
 param(
        $CurrentSchedule,
        $OrganizationalUnit = "OU=CourseCodes,OU=MarsUniversityScheduling,DC=planetexpress,DC=local"
      )

 foreach($CourseCode in $CurrentSchedule.CourseCode){
    Write-Verbose "create-musCourseCodeGroups - Checking if group Exists."
    $Group = $(Get-ADGroup -Filter {SamAccountName -eq $CourseCode})
    try{
        #if group doesn't exist, create
        if(!$Group){
         write-verbose "create-musCourseCodeGroups - Security Group $Coursecode does not exist."
         New-ADGroup $Coursecode -Path $OrganizationalUnit -GroupCategory Security -GroupScope Global
         if($?){write-verbose "create-musRoomGroups - Security Group $Coursecode created."}
        }#End If
        else{        
         write-verbose "create-musCourseCodeGroups - Security Group $Coursecode exists."
        }#End else
    }#End Try
    catch{}#EndCatch
    finally{}
 }#End ForeachCourseCode in $CurrentSchedule
}#End Create-muscoursecodegroup

function create-musRoomGroups{
[cmdletbinding()]
 param(
        $CurrentSchedule,
        $OrganizationalUnit = "OU=Campuses,OU=MarsUniversityScheduling,DC=planetexpress,DC=local"
      )

$RoomGroups = $CurrentSchedule |? RoomNumber -ne "" | %{$_.Building+"-"+$_.RoomNumber}

 foreach($RoomGroup in $RoomGroups){
    Write-Verbose "create-musRoomGroups - Checking if $RoomGroup group exists."
    $Group = $(Get-ADGroup -Filter {SamAccountName -eq $RoomGroup})
    try{
        #if group doesn't exist, create
        if(!$Group){
         write-verbose "create-musRoomGroups - Security Group $RoomGroup does not exist."
         New-ADGroup $RoomGroup -Path $OrganizationalUnit -GroupCategory Security -GroupScope Global
         if($?){write-verbose "create-musRoomGroups - Security Group $RoomGroup created."}
        }#End If
        else{        
         write-verbose "create-musRoomGroups - Security Group $RoomGroup exists."
        }#End else
    }#End Try
    catch{}#EndCatch
    finally{}
 }#End ForeachCourseCode in $CurrentSchedule
}#End Create-muscoursecodegroup

function sync-musCourseSchedule{
[cmdletbinding()]
 param($CurrentSchedule)


}

#What I need

#Location Building?

#Connect Course Code (where software is applied) with Unique code (Building-Room where course code exists)

#Add Unique Code to Course Code for software.

create-musCourseCodeGroups -CurrentSchedule $CurrentSchedule -Verbose

create-musRoomGroups -CurrentSchedule $CurrentSchedule -Verbose


