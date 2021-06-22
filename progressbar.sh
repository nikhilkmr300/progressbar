#! /usr/local/bin/bash

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

colorreset="\e[0m"

#######################################
# Converts name to ANSI escape code.
# Globals:
#   colorreset
# Arguments:
#   Name of color or ANSI escape code in the format "\e[32m"
# Outputs:
#   ANSI escape code to stdout
# Examples:
#   *) colormap "blue"
#   *) colormap "\e[32m"
#######################################
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
        "")         echo $colorreset ;;
        reset)      echo $colorreset ;;
        \\e*m)      echo $1 ;;
        *)          echo $1; echo "usage: colormap <color>" 1>&2
                    exit -1 ;;
    esac
}

#######################################
# Configures style from an input string.
# Globals:
#   styles
# Arguments:
#   String containing styles for completed progress, blanks, left edge and right
#   edge, in that order, separated by colons ";". 
#   For example, if you want a progress bar that looks like
#       [>>>>>>>...] 70%
#   pass the string as ">;.;[;]". If you do not want to set a parameter, leave 
#   it blank, and it will use the default.
# Outputs:
#   None
# Example:
#   parsestyles ">;;[;]"
#######################################
function parsestyles() {
    local delim=";"
    local keys=(
        "prog"
        "blank"
        "edgeleft"
        "edgeright"
    )
    vals=($(echo $1 | sed "s/$delim/$delim /g"))

    declare -Ag styles;
    local style;
    for key in ${keys[@]}; do
        style=$(echo ${vals[0]} | sed "s/$delim//g")
        echo "style: $style"
        if [[ $style != "" ]]; then
            styles[$key]=$style
        else
            styles[$key]=" "
        fi
        vals=(${vals[@]:1})
    done
}

#######################################
# Configures colors from an input string.
# Globals:
#   colors
# Arguments:
#   String containing styles for completed progress, blanks, left edge and right
#   edge, in that order, separated by colons ";". 
#   For example, if you want a progress bar with green completed progress,
#   blanks with color code "\e[32m", colorless edges, and blue percentage pass 
#   the string as "green;\e[32m;reset;reset;blue" or "green;\e[32m;;;blue". If 
#   you do not want to set a parameter, leave it blank, and it will use the 
#   default.
# Outputs:
#   None
#######################################
function parsecolors() {
    local delim=";"
    local keys=(
        "prog"
        "blank"
        "edge"
        "percent"
    )
    vals=($(echo $1 | sed "s/$delim/$delim /g"))

    declare -Ag colors;
    local color;
    for key in ${keys[@]}; do
        color=$(echo ${vals[0]} | sed "s/$delim//g")
        colors[$key]=$(colormap $color)
        vals=(${vals[@]:1})
    done
}

#######################################
# Setup configuration.
# Globals:
#   styles      :   Style-related config, setup in `parsestyles`
#   colors      :   Color-related config, setup in `parsecolors`
#   disappear   :   If true, progress bar disappears after 100%
#   alert       :   If true, rings bell ('\a') after 100%
# Arguments:
#   stylestring :   As described in `parsestyles`
#   colorstring :   As described in `parsecolors`
#   disappear   :   boolean
#   alert       :   boolean
# Outputs:
#   None
#######################################
function setup() {
    parsestyles "$1"; shift
    parsecolors "$1"; shift
    disappear=$1; shift
    alert=$1
}

#######################################
# Prints config to stdout in JSON format (for debugging).
#######################################
function printsetup() {
    local key; local i;

    echo "{"

    echo -e "\t\"styles\": {"
    i=1
    for key in ${!styles[@]}; do
        echo -ne "\t\t\"$key\": \"${styles[$key]}\""
        if [ $i -ne ${#styles[@]} ]; then
            echo ","
        else
            echo ""
        fi
        i=$(( i + 1 ))
    done
    echo -e "\t},"

    echo -e "\t\"colors\": {"
    i=1
    for key in ${!colors[@]}; do
        echo -ne "\t\t\"$key\": \"\\\\e${colors[$key]:2}\""
        if [ $i -ne ${#colors[@]} ]; then
            echo ","
        else
            echo ""
        fi
        i=$(( i + 1 ))
    done
    echo -e "\t}"

    echo -e "\t\"disappear\": $disappear,"

    echo -e "\t\"alert\": $alert"

    echo "}"
}

#######################################
# Main function to generate progress bar.
# Arguments:
#   percent     :   Current percentage completed
#   width       :   Total width (columns) of progress bar on screen
#######################################
function main() {
    tput civis                                              # Hiding cursor

    local -i percent=$1; shift                              # Percent completed
    local -i width=$(( $1 - 4 )); shift                     # Number of columns in progress bar

    local -i prog=$(( percent * width / 100 ))              # Number of columns for completed
    local -i blanks=$(( width - prog ))                     # Number of columns for remaining

    # Printing progress.
    printf "${colors[edge]}${styles[edgeleft]}${colorreset}"
    local i;
    for (( i=0; i<prog; i++ )); do
        printf "${colors[prog]}${styles[prog]}${colorreset}"
    done
    # Printing remaining (blanks).
    for (( i=0; i<blanks; i++ )); do
        printf "${colors[blank]}${styles[blank]}${colorreset}"
    done
    printf "${colors[edge]}${styles[edgeright]}${colorreset}"
    printf "${colors[percent]}%4d%s${colorreset}" $percent "%"

    if [ $percent -ne 100 ]; then
        printf "\r"                                         # Flush
    elif [ $percent -eq 100 ]; then
        tput cvvis                                          # Unhiding cursor
        if [ $alert == true ]; then
            echo -ne "\a"
        fi
        if [ $disappear == true ]; then
            printf "\r"
        else
            printf "\n"
        fi
    fi
}

setup "█; ;|;|" "\e[32m;green;;blue" false true
printsetup

for i in $(seq 1 100); do
    main i 80
done