#! /usr/bin/env bash

# Here are a few sample progress and blank styles to choose from:
# +--------------------+---------------------+
# |     progstyle      |     blankstyle      |
# +--------------------+---------------------+
# |    '█' (U+2588)    |    ' ' (U+0020)     |
# |    '|' (U+007C)    |    ' ' (U+0020)     |
# |    '■' (U+25A0)    |    '□' (U+25A1)     |
# |    '●' (U+25CF)    |    '○' (U+25CB)     |
# |    '►' (U+25BA)    |    '·' (U+00B7)     |
# |    '>' (U+003E)    |    '·' (U+00B7)     |
# +--------------------+---------------------+
# You can use any combination of UTF-8 characters for progstyle and blankstyle.

set -e

function colormap() {
    case $1 in
        black)      echo "\e[30m" ;;
        red)        echo "\e[31m" ;;
        green)      echo "\e[32m" ;;
        yellow)     echo "\e[33m" ;;
        blue)       echo "\e[34m" ;;
        magenta)    echo "\e[35m" ;;
        cyan)       echo "\e[36m" ;;
        white)      echo "\e[37m" ;;
        reset)      echo "\e[0m" ;;
        *)          echo $1; echo "usage: colormap <color>" 1>&2
                    echo "colors: black red green yellow blue magenta cyan white reset" 1>&2
                    exit -1 ;;
    esac
}

function setup() {
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

    progcolor=$(colormap $1); shift
    blankcolor=$(colormap $1); shift
    edgecolor=$(colormap $1); shift
    percentcolor=$(colormap $1); shift
    reset=$(colormap reset)

    disappear=$1; shift
    bell=$1
}

function main() {
    tput civis

    local -i percent=$1; shift
    local -i width=$(( $1 - 4 )); shift

    local -i prog=$(( percent * width / 100 ))
    local -i blanks=$(( width - prog ))

    printf "${edgecolor}${leftedge}${reset}"
    local i;
    for (( i=0; i<prog; i++ )); do
        printf "${progcolor}${progstyle}${reset}"
    done
    for (( i=0; i<blanks; i++ )); do
        printf "${blankcolor}${blankstyle}${reset}"
    done
    printf "${edgecolor}${rightedge}${reset}"
    printf "${percentcolor}%4d%s${reset}" $percent "%"

    if [ $percent -ne 100 ]; then
        printf "\r"
    elif [ $percent -eq 100 ]; then
        tput cvvis
        if [ $bell == true ]; then
            echo -ne "\a"
        fi
        if [ $disappear == true ]; then
            printf "\r"
        else
            printf "\n"
        fi
    fi
}

setup "■" "□" "[" red green blue cyan false false

for i in $(seq 0 100); do
    main $i 80
done