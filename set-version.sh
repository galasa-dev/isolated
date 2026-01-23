#! /usr/bin/env bash 

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

#-----------------------------------------------------------------------------------------                   
#
# Objectives: Sets the version number of this component.
#
# Environment variable over-rides:
# None
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
h1() { printf "\n${underline}${bold}${blue}%s${reset}\n" "$@" ;}
h2() { printf "\n${underline}${bold}${white}%s${reset}\n" "$@" ;}
debug() { printf "${white}%s${reset}\n" "$@" ;}
info() { printf "${white}➜ %s${reset}\n" "$@" ;}
success() { printf "${green}✔ %s${reset}\n" "$@" ;}
error() { printf "${red}✖ %s${reset}\n" "$@" ;}
warn() { printf "${tan}➜ %s${reset}\n" "$@" ;}
bold() { printf "${bold}%s${reset}\n" "$@" ;}
note() { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@" ;}

#-----------------------------------------------------------------------------------------                   
# Functions
#-----------------------------------------------------------------------------------------                   
function usage {
    h1 "Syntax"
    cat << EOF
set-version.sh [OPTIONS]
Options are:
-v | --version xxx : Mandatory. Set the version number to something explicitly. 
    Re-builds the release.yaml based on the contents of sub-projects.
    For example '--version 0.29.0'
EOF
}

#-----------------------------------------------------------------------------------------                   
# Process parameters
#-----------------------------------------------------------------------------------------                   
component_version=""

while [ "$1" != "" ]; do
    case $1 in
        -v | --version )        shift
                                export component_version=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     error "Unexpected argument $1"
                                usage
                                exit 1
    esac
    shift
done

if [[ -z $component_version ]]; then 
    error "Missing mandatory '--version' argument."
    usage
    exit 1
fi



function update_all_pom_version_tags {
    source_file=$1
    h1 "Updating the version in $source_file "

    temp_dir=$2

    set -o pipefail

    temp_file="$temp_dir/temp-pom.xml"
    rm -f $temp_file
    touch $temp_file

    info "Using temporary file $temp_file"
    info "Updating file $source_file"

    while IFS="" read -r line ; do
        
        if [[ $line =~ "<version>" ]]; then
            info "version line found. $line"
            transformed_line=$(echo -n "$line" | sed "s/<version>.*<\/version>$/<version>$component_version<\/version>/")
            rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to substitute $source_file file."; exit 1; fi
            info "changing that to $transformed_line"
            line=$transformed_line
        fi
        echo "$line" >> $temp_file
    done < $source_file

    cp $temp_file ${source_file}
    rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to overwrite new version of $source_file file."; exit 1; fi

    success "$source_file updated OK."
}

function update_pom_platform_version_tag {
    source_file=$1
    h1 "Updating the version in $source_file "

    temp_dir=$2

    set -o pipefail

    temp_file="$temp_dir/temp-pom.xml"
    rm -f $temp_file
    touch $temp_file

    info "Using temporary file $temp_file"
    info "Updating file $source_file"

    done="false"
    platform_line_found="false"

    while IFS="" read -r line; do
        if [[ "$done" == "false" ]]; then
            if [[ $line =~ "<artifactId>dev.galasa.platform</artifactId>" ]]; then
                info "platform line found. $line"
                platform_line_found="true"
            elif [[ $line =~ "<version>" ]] && [[ $platform_line_found == true ]]; then
                info "platform version line found. $line"
                transformed_line=$(echo -n "$line" | sed "s/<version>.*<\/version>/<version>$component_version<\/version>/")
                rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to substitute $source_file file."; exit 1; fi
                info "changing that to $transformed_line"
                line=$transformed_line

                info "No more version substitutions needed."
                done="true"
            fi
        fi

        # Write the line to the temporary file
        echo "$line" >> "$temp_file"
    done < "$source_file"

    cp $temp_file ${source_file}
    rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to overwrite new version of $source_file file."; exit 1; fi

    success "$source_file updated OK."
}

function update_pom_first_version_tag {
    source_file=$1
    h1 "Updating the version in $source_file "

    temp_dir=$2

    set -o pipefail

    temp_file="$temp_dir/temp-pom.xml"
    rm -f $temp_file
    touch $temp_file

    info "Using temporary file $temp_file"
    info "Updating file $source_file"

    done="false"

    while IFS="" read -r line ; do
        
        if [[ "$done" == "false" ]]; then
            if [[ $line =~ "<version>" ]]; then
                info "version line found. $line"
                transformed_line=$(echo -n "$line" | sed "s/<version>.*<\/version>$/<version>$component_version<\/version>/")
                rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to substitute $source_file file."; exit 1; fi
                info "changing that to $transformed_line"
                line=$transformed_line

                info "No more version substitutions done. Only the first occurrance changed."
                done="true"
            fi
        fi
        echo "$line" >> $temp_file
    done < $source_file

    cp $temp_file ${source_file}
    rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to overwrite new version of $source_file file."; exit 1; fi

    success "$source_file updated OK."
}

function update_simbank_version_in_script {
    source_file=$1
    h1 "Updating the version in $source_file "

    temp_dir=$2

    set -o pipefail

    temp_file="$temp_dir/temp-script.sh"
    rm -f $temp_file
    touch $temp_file

    info "Using temporary file $temp_file"
    info "Updating file $source_file"

    done="false"

    while IFS="" read -r line ; do
        
        if [[ "$done" == "false" ]]; then
            if [[ $line =~ "SIMBANK_VERSION" ]]; then
                info "simbank version line found. $line"
                transformed_line=$(echo -n "$line" | sed "s/SIMBANK_VERSION=\".*\"/SIMBANK_VERSION=\"$component_version\"/")
                rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to substitute $source_file file."; exit 1; fi
                info "changing that to $transformed_line"
                line=$transformed_line

                info "No more version substitutions needed."
                done="true"
            fi
        fi
        echo "$line" >> $temp_file
    done < $source_file

    cp $temp_file ${source_file}
    rc=$?; if [[ "${rc}" != "0" ]]; then error "Failed to overwrite new version of $source_file file."; exit 1; fi

    success "$source_file updated OK."
}

temp_dir=$BASEDIR/temp/versions
rm -fr $temp_dir
mkdir -p $temp_dir

#   These files need to be bumped...
#     a. full/pom2.xml - the first version tag and the version of the platform needs replacing.
#     b. full/pom3.xml - only the first version tag needs replacing.
#     c. full/pom4.xml - only the first version tag needs replacing.
#     d. full/pom5.xml - the first version tag and the version of the platform needs replacing.
#     e. full/pom6.xml - only the first version tag needs replacing.
#     f. full/pomZip.xml - only the first version tag needs replacing.
#     g. full/pomGalasactl.xml
#     h. full/resources/run-simplatform.sh - the SIMBANK_VERSION needs replacing.
#     i. mvp/pom2.xml - the first version tag and the version of the platform needs replacing.
#     j. mvp/pom3.xml - only the first version tag needs replacing.
#     k. mvp/pom4.xml - only the first version tag needs replacing.
#     l. mvp/pom5.xml - the first version tag and the version of the platform needs replacing.
#     m. mvp/pom6.xml - only the first version tag needs replacing.
#     n. mvp/pomZip.xml
#     o. mvp/pomGalasactl.xml
#     p. mvp/resources/run-simplatform.sh - the SIMBANK_VERSION needs replacing.

update_pom_first_version_tag $BASEDIR/full/pom2.xml $temp_dir
update_pom_platform_version_tag $BASEDIR/full/pom2.xml $temp_dir
update_pom_first_version_tag $BASEDIR/full/pom3.xml $temp_dir
update_pom_first_version_tag $BASEDIR/full/pom4.xml $temp_dir
update_pom_first_version_tag $BASEDIR/full/pom5.xml $temp_dir
update_pom_platform_version_tag $BASEDIR/full/pom5.xml $temp_dir
update_pom_first_version_tag $BASEDIR/full/pom6.xml $temp_dir
update_pom_first_version_tag $BASEDIR/full/pomZip.xml $temp_dir
update_pom_first_version_tag $BASEDIR/full/pomGalasactl.xml $temp_dir
update_simbank_version_in_script $BASEDIR/full/resources/run-simplatform.sh $temp_dir

update_pom_first_version_tag $BASEDIR/mvp/pom2.xml $temp_dir
update_pom_platform_version_tag $BASEDIR/mvp/pom2.xml $temp_dir
update_pom_first_version_tag $BASEDIR/mvp/pom3.xml $temp_dir
update_pom_first_version_tag $BASEDIR/mvp/pom4.xml $temp_dir
update_pom_first_version_tag $BASEDIR/mvp/pom5.xml $temp_dir
update_pom_platform_version_tag $BASEDIR/mvp/pom5.xml $temp_dir
update_pom_first_version_tag $BASEDIR/mvp/pom6.xml $temp_dir
update_pom_first_version_tag $BASEDIR/mvp/pomZip.xml $temp_dir
update_pom_first_version_tag $BASEDIR/mvp/pomGalasactl.xml $temp_dir
update_simbank_version_in_script $BASEDIR/mvp/resources/run-simplatform.sh $temp_dir




