#!/bin/bash
width=1920 #$(xdpyinfo | awk '/dimensions/{print $2}'|cut -f1 -dx);
height=1080 #$(xdpyinfo | awk '/dimensions/{print $2}'|cut -f2 -dx);
taskFile='./tasks'
shortBreak=300
longBreak=900
workCycle=1500
output=./times
get_task( ){
    currentTask=`zenity --entry --title="add a task" --text ""|tr ' ' '_'`
    [ -z `grep $currentTask $taskFile` ] && echo "$currentTask" >> $taskFile || get_task
}

continue_same_task(){
    zenity --question --text="continue with the same task?"
    return $?
}


select_project(){
    projects=`cat $taskFile|cut -d '|' -f1|sort -u`
    [ -z $projects ] && return 1
    selectedProject=`zenity --list --column="project" $projects`
    [ ! -z $selectedProject ] && { echo $selectedProject; return 0;}|| return 1;
}

select_task_for_project(){
    projectName=$1
    tasks=`grep $projectName $taskFile|cut -d '|' -f2`
    [ -z $tasks ] && return 1
    selectedTask=`zenity --list --column="task" $tasks`
    [ ! -z  $selectedTask ] && { echo $selectedTask; return 0;} || return 1;
}

long_break(){
    endTime=$( expr `date +%s` + $longBreak)
    now=`date +%s`
    while [ $now -le $endTime ]
    do
        now=`date +%s`
        remaingTime=$( expr $endTime - $now )
        remaingtime=$( expr $remaingTime / 60 )
        seconds=`echo "$endTime -$now - (60 * $remaingtime)" |bc`
        zenity --warning --text="take a long break for $remaingtime minutes and $seconds seconds" --width=$width --height=$height --timeout=5
    done

}

short_break(){
    endTime=$( expr `date +%s` + $shortBreak)
    now=`date +%s`
    while [ $now -le $endTime ]
    do
        now=`date +%s`
        remaingTime=$( expr $endTime - $now )
        remaingtime=$( expr $remaingTime / 60 )
        seconds=`echo "$endTime -$now - (60 * $remaingtime)" |bc`
        zenity --warning --text="take a short break for $remaingtime minutes and $seconds seconds" --width=$width --height=$height --timeout=5
    done
}

project_task_exist(){
    [ ! -z `grep $1 $taskFile` ] && return 0 || return 1 
}
select_task_project(){
    project=$(select_project) || project=$(zenity --entry --title="project name" --text "add a name for project"|tr ' ' '_')
    #[ -z $project ] && get_task
    #echo "selected project name : $project"
    task=$(select_task_for_project $project) || task=$(zenity --entry --title="add a task" --text "add a task name for $project"|tr ' ' '_')
    #echo "selected task is : $task"
    $(project_task_exist "$project|$task") || echo "$project|$task" >> $taskFile
    echo "$project|$task"
}

work_cycle(){
    projectTask=$1
    startTime=`date +%s`
    sleep 5s;
    endTime=`date +%s`
    echo "$1|$startTime|$endTime" >> $output
}
[ -z ${taskProject+"0"} ] && taskProject=$(select_task_project)
echo $taskProject
work_cycle $taskProject
short_break
continue_same_task || taskProject=$(select_task_project)
work_cycle $taskProject
short_break
continue_same_task || taskProject=$(select_task_project)
work_cycle $taskProject
short_break
continue_same_task || taskProject=$(select_task_project)
work_cycle $taskProject
long_break
continue_same_task || taskProject=$(select_task_project)

