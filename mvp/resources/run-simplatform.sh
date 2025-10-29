#! /usr/bin/env bash 

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#
#-----------------------------------------------------------------------------------------                   
#
# Objectives: Start the Simbank application
# 
#-----------------------------------------------------------------------------------------                   

# Where is this script executing from ?
BASEDIR=$(dirname "$0");pushd $BASEDIR 2>&1 >> /dev/null ;BASEDIR=$(pwd);popd 2>&1 >> /dev/null
# echo "Running from directory ${BASEDIR}"
export ORIGINAL_DIR=$(pwd)
# cd "${BASEDIR}"

cd "${BASEDIR}/.."
WORKSPACE_DIR=$(pwd)


#-----------------------------------------------------------------------------------------                   
#
# Set Colors
#
#-----------------------------------------------------------------------------------------                   
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 76)
white=$(tput setaf 7)
tan=$(tput setaf 202)
blue=$(tput setaf 25)

#-----------------------------------------------------------------------------------------                   
#
# Headers and Logging
#
#-----------------------------------------------------------------------------------------                   
underline() { printf "${underline}${bold}%s${reset}\n" "$@" ;}
h1()        { printf "\n${underline}${bold}${blue}%s${reset}\n" "$@" ;}
h2()        { printf "\n${underline}${bold}${white}%s${reset}\n" "$@" ;}
debug()     { printf "${white}[.] %s${reset}\n" "$@" ;}
info()      { printf "${white}[➜] %s${reset}\n" "$@" ;}
success()   { printf "${white}[${green}✔${white}] ${green}%s${reset}\n" "$@" ;}
error()     { printf "${white}[${red}✖${white}] ${red}%s${reset}\n" "$@" ;}
warn()      { printf "${white}[${tan}➜${white}] ${tan}%s${reset}\n" "$@" ;}
bold()      { printf "${bold}%s${reset}\n" "$@" ;}
note()      { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@" ;}

#-----------------------------------------------------------------------------------------                   
# Functions
#-----------------------------------------------------------------------------------------                   
function usage {
    info "Syntax: run-simplatform.sh [OPTIONS]"
    cat << EOF
Options are:
-h | --help : Display this help text
--location  : (Required with --server) The path to the location of galasa-simplatform within the isolated package.
              Can be an absolute path (/Users/user/Downloads/isolated/maven/dev/galasa/) 
              or a relative path (~/Downloads/isolated/maven/dev/galasa/).
--server    : Launch the back-end server 3270 application. Ctrl-C to end it.
--ui        : Launch the web user interface application which talks to the back-end server. Ctrl-C to end it.
Environment Variables:
None


EOF
}

#-----------------------------------------------------------------------------------------                   
# Process parameters
#-----------------------------------------------------------------------------------------                   
export package_location=""
export is_server=false
export is_ui=false
export is_tests=false

while [ "$1" != "" ]; do
    case $1 in
        -h | --help )           usage
                                exit
                                ;;
        --location)             shift
                                package_location=$1
                                ;;
        --server )              is_server=true
                                ;;
        --ui )                  is_ui=true
                                ;;
        --tests )               is_tests=true
                                ;;
        * )                     error "Unexpected argument $1"
                                usage
                                exit 1
    esac
    shift
done

if [[ "$package_location" == "" ]] && [[ "$is_server" == true ]] ; then
    error "--location is not set."
    usage 
    exit 1
fi

if [[ "$is_ui" == false ]] && [[ "$is_server" == false ]] && [[ "$is_tests" == false ]] ; then
    error "Not enough parameters."
    usage 
    exit 1
fi

if [[ "$is_ui" == true ]]  && [[ "$is_server" == true  ]] && [[ "$is_tests" == true  ]]; then
    error "Too many parameters. Either the --server, --ui or --tests parameter is needed, not both."
    usage
    exit 1
fi

#-----------------------------------------------------------------------------------------                   
# Main logic.
#-----------------------------------------------------------------------------------------  

SIMBANK_VERSION="0.45.0"

function run_server {
    h1 "Running Simbank back-end server application (version ${SIMBANK_VERSION}) ..."
    info "Use Ctrl-C to stop it.\n"

    java -jar ${package_location}/galasa-simplatform/${SIMBANK_VERSION}/galasa-simplatform-${SIMBANK_VERSION}.jar
    rc=$?
    if [[ "${rc}" != "130" ]]; then
        error "Failed. Exit code was ${rc}"
        exit 1
    fi
    info "Passed. Exit code was $rc. (130 means user killed the process)"
    success "Ran Simbank application OK"
}

function run_ui {
    h1 "Running Simbank web user interface application (version ${SIMBANK_VERSION}) ..."
    info "Use Ctrl-C to stop it.\n"
    container_id=$(docker run --rm -p 7080:8080 -d galasa-simplatform-webapp)
    info "Launch the Simbank web UI here: http://localhost:7080/galasa-simplatform-webapp/index.html"
    docker attach ${container_id}
}

function run_tests {
    h1 "Running Simbank tests ..."
    
    cmd="galasactl runs submit local \
    --obr mvn:dev.galasa/dev.galasa.simbank.obr/${TEST_OBR_VERSION}/obr \
    --class dev.galasa.simbank.tests/dev.galasa.simbank.tests.SimBankIVT \
    --log ${BASEDIR}/temp/log.txt"

    info "Running this command: $cmd"
    $cmd
    rc=$?
    if [[ "${rc}" != "0" ]]; then
        error "Failed to run the tests. Exit code was ${rc}"
        exit 1
    fi
    success "Tests ran OK"
}


if [[ "$is_server" == true ]]; then 
    run_server 
fi

if [[ "$is_ui" == true ]]; then 
    run_ui 
fi

if [[ "$is_tests" == true ]]; then 
    run_tests 
fi
