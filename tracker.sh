#!/bin/bash
width=1920 #$(xdpyinfo | awk '/dimensions/{print $2}'|cut -f1 -dx);
height=1080 #$(xdpyinfo | awk '/dimensions/{print $2}'|cut -f2 -dx);
taskFile='./tasks'
shortBreak=300
longBreak=900
workCycle=1500
output=./times
trigerFile=/tmp/stop
stepTriger=/tmp/next
refreshTime=10

check_command(){
    [ -f $trigerFile ] && return 1 || return 0
}

check_skip(){
    [ -f $stepTriger ] && { rm $stepTriger; return 1; } || return 0
}
active_sleep(){
    duration=$1
    now=`date +%s`
    endTime=`echo "$now + $duration"|bc`
    while [ $now -le $endTime ]
    do
        check_skip || return 1
        check_command || return 1
        sleep 1
        now=`date +%s`
    done
}


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
    [ -z "$projects" ] && return 1
    selectedProject=`zenity --list --column="project" $projects`
    [ ! -z $selectedProject ] && { echo $selectedProject; return 0;}|| return 1;
}

select_task_for_project(){
    projectName=$1
    tasks=`grep $projectName $taskFile|cut -d '|' -f2`
    [ -z "$tasks" ] && return 1
    selectedTask=`zenity --list --column="task" $tasks`
    [ ! -z  $selectedTask ] && { echo $selectedTask; return 0;} || return 1;
}

long_break(){
    endTime=$( expr `date +%s` + $longBreak)
    now=`date +%s`
    while [ $now -le $endTime ]
    do
        now=`date +%s`
        active_sleep $refreshTime || return 1
        remaingTime=$( expr $endTime - $now )
        remaingtime=$( expr $remaingTime / 60 )
        seconds=`echo "$endTime -$now - (60 * $remaingtime)" |bc`
        zenity --warning --text="take a long break for $remaingtime minutes and $seconds seconds" --width=$width --height=$height --timeout=$refreshTime &
    done

}

short_break(){
    endTime=$( expr `date +%s` + $shortBreak)
    now=`date +%s`
    while [ $now -le $endTime ]
    do
        now=`date +%s`
        active_sleep $refreshTime || return 1
        remaingTime=$( expr $endTime - $now )
        remaingtime=$( expr $remaingTime / 60 )
        seconds=`echo "$endTime -$now - (60 * $remaingtime)" |bc`
        zenity --warning --text="take a short break for $remaingtime minutes and $seconds seconds" --width=$width --height=$height --timeout=$refreshTime &
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
    active_sleep $workCycle
    returnCode=$?
    endTime=`date +%s`
    echo "$1|$startTime|$endTime" >> $output
    return $returnCode
}

loop(){
    i=1
    rm $trigerFile
    while true
    do
        [ -z ${taskProject+"0"} ] && taskProject=$(select_task_project)
        echo $taskProject
        work_cycle $taskProject
        if [  $? -eq 0 ]
        then
            echo "did not skiped"
            [ 0 -eq  `expr $i % 4` ]  && long_break || short_break
        fi
        active_sleep 1 && { continue_same_task || taskProject=$(select_task_project); } || return 1
    done
}
loop
