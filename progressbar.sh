#! /usr/bin/env bash

function setstyle() {
    progstyle=$1; shift
    blankstyle=$1; shift

    local edgestyle=$1; shift
    if [ $edgestyle == "[" ]; then
        leftedge="["
        rightedge="]"
    elif [ $edgestyle == "(" ]; then
        leftedge="("
        rightedge=")"
    elif [ $edgestyle == "{" ]; then
        leftedge="{"
        rightedge="}"
    else
        leftedge=$edgestyle
        rightedge=$edgestyle
    fi

    disappear=$1
}

function main() {
    tput civis

    local -i percent=$1; shift
    local -i width=$(( $1 - 4 )); shift

    local -i prog=$(( percent * width / 100 ))
    local -i blanks=$(( width - prog ))

    printf "${leftedge}"
    local i;
    for (( i=0; i<prog; i++ )); do
        printf "$progstyle"
    done
    for (( i=0; i<blanks; i++ )); do
        printf "$blankstyle"
    done
    printf "${rightedge}"
    printf "%4d%s" $percent "%"

    if [ $percent -ne 100 ]; then
        printf "\r"
    elif [ $percent -eq 100 ]; then
        tput cvvis
        if [ $disappear == true ]; then
            printf "\r"
        else
            printf "\n"
        fi
    fi
}

setstyle "#" "." "/" true

for i in $(seq 0 100); do
    main $i 80
    sleep 0.01
done