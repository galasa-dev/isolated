#! /usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

#-----------------------------------------------------------------------------------------
#
# Objectives: Build this repository code locally.
#
#-----------------------------------------------------------------------------------------

# Where is this script executing from ?
BASEDIR=$(dirname "$0");pushd $BASEDIR 2>&1 >> /dev/null ;BASEDIR=$(pwd);popd 2>&1 >> /dev/null
export ORIGINAL_DIR=$(pwd)

cd "${BASEDIR}/.."
WORKSPACE_DIR=$(pwd)

export ISOLATED_DIR=${BASEDIR}/full
export MVP_DIR=${BASEDIR}/mvp

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
underline() { printf "${underline}${bold}%s${reset}\n" "$@" ; }
h1() { printf "\n${underline}${bold}${blue}%s${reset}\n" "$@" ; }
h2() { printf "\n${underline}${bold}${white}%s${reset}\n" "$@" ; }
debug() { printf "${white}[.] %s${reset}\n" "$@" ; }
info()  { printf "${white}[➜] %s${reset}\n" "$@" ; }
success() { printf "${white}[${green}✔${white}] ${green}%s${reset}\n" "$@" ; }
error() { printf "${white}[${red}✖${white}] ${red}%s${reset}\n" "$@" ; }
warn() { printf "${white}[${tan}➜${white}] ${tan}%s${reset}\n" "$@" ; }
bold() { printf "${bold}%s${reset}\n" "$@" ; }
note() { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@" ; }

#-----------------------------------------------------------------------------------------
# Functions
#-----------------------------------------------------------------------------------------
function usage {
    info "Syntax: build-locally.sh [OPTIONS]"
    cat << EOF
Options are:
-h | --help : Display this help text

Environment Variables:
SOURCE_MAVEN_OBR :
    Optional. Defaults to https://development.galasa.dev/main/maven-repo/obr
    Used to indicate where the Galasa OBR artifacts can be found.
    Can be set to the location of the local maven repository.

SOURCE_MAVEN_SIMPLATFORM :
    Optional. Defaults to https://development.galasa.dev/main/maven-repo/simplatform
    Used to indicate where the Galasa Simplatform artifacts can be found.
    Can be set to the location of the local maven repository.

SOURCE_MAVEN_JAVADOC :
    Optional. Defaults to https://development.galasa.dev/main/maven-repo/javadoc
    Used to indicate where the Galasa Uber Javadoc can be found.
    Can be set to the location of the local maven repository.

LOGS_DIR :
    Optional. Defaults to creating a new temporary folder.
    Controls where logs are placed.

EOF
}

function check_exit_code () {
    # This function takes 3 parameters in the form:
    # $1 an integer value of the returned exit code
    # $2 an error message to display if $1 is not equal to 0
    if [[ "$1" != "0" ]]; then 
        error "$2" 
        exit 1  
    fi
}

#-----------------------------------------------------------------------------------------
# Process parameters
#-----------------------------------------------------------------------------------------
while [ "$1" != "" ]; do
    case $1 in
        -h | --help )           usage
                                exit
                                ;;
        * )                     error "Unexpected argument $1"
                                usage
                                exit 1
    esac
    shift
done

#-----------------------------------------------------------------------------------------
# Main logic.
#-----------------------------------------------------------------------------------------
MVP_DISTRIBUTION="MVP"
ISOLATED_DISTRIBUTION="Isolated"
source_dir="."

project=$(basename ${BASEDIR})
h1 "Building ${project}"


# Override these variables if you want to build from different maven repos, like your local .m2...
if [[ -z ${SOURCE_MAVEN_OBR} ]]; then
    export SOURCE_MAVEN_OBR=https://development.galasa.dev/main/maven-repo/obr
    info "SOURCE_MAVEN_OBR repo defaulting to ${SOURCE_MAVEN_OBR}."
    info "Set this environment variable if you want to override this value."
else
    info "SOURCE_MAVEN_OBR set to ${SOURCE_MAVEN_OBR} by caller."
fi

if [[ -z ${SOURCE_MAVEN_SIMPLATFORM} ]]; then
    export SOURCE_MAVEN_SIMPLATFORM=https://development.galasa.dev/main/maven-repo/simplatform
    info "SOURCE_MAVEN_SIMPLATFORM repo defaulting to ${SOURCE_MAVEN_SIMPLATFORM}."
    info "Set this environment variable if you want to override this value."
else
    info "SOURCE_MAVEN_SIMPLATFORM set to ${SOURCE_MAVEN_SIMPLATFORM} by caller."
fi

if [[ -z ${SOURCE_MAVEN_JAVADOC} ]]; then
    export SOURCE_MAVEN_JAVADOC=https://development.galasa.dev/main/maven-repo/javadoc
    info "SOURCE_MAVEN_JAVADOC repo defaulting to ${SOURCE_MAVEN_JAVADOC}."
    info "Set this environment variable if you want to override this value."
else
    info "SOURCE_MAVEN_JAVADOC set to ${SOURCE_MAVEN_JAVADOC} by caller."
fi

# Create a temporary dir.
# Note: This bash 'spell' works in OSX and Linux.
if [[ -z ${LOGS_DIR} ]]; then
    export LOGS_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t "galasa-logs")
    info "Logs are stored in the ${LOGS_DIR} folder."
    info "Override this setting using the LOGS_DIR environment variable."
else
    mkdir -p ${LOGS_DIR} 2>&1 > /dev/null # Don't show output. We don't care if it already existed.
    info "Logs are stored in the ${LOGS_DIR} folder."
    info "Overridden by caller using the LOGS_DIR variable."
fi

info "Using source code at ${source_dir}"
cd ${BASEDIR}/${source_dir}
if [[ "${DEBUG}" == "1" ]]; then
    OPTIONAL_DEBUG_FLAG="-debug"
else
    OPTIONAL_DEBUG_FLAG="-info"
fi


log_file=${LOGS_DIR}/${project}.txt
info "Log will be placed at ${log_file}"
date > ${log_file}

#------------------------------------------------------------------------------------
function get_galasabld_binary_location {
    # What's the architecture-variable name of the build tool we want for this local build ?
    export ARCHITECTURE=$(uname -m) # arm64 or amd64
    if [ $ARCHITECTURE == "x86_64" ]; then
        export ARCHITECTURE="amd64"
    fi

    raw_os=$(uname -s) # eg: "Darwin"
    os=""
    case $raw_os in
        Darwin*)
            os="darwin"
            ;;
        Windows*)
            os="windows"
            ;;
        Linux*)
            os="linux"
            ;;
        *)
            error "Failed to recognise which operating system is in use. $raw_os"
            exit 1
    esac
    export GALASA_BUILD_TOOL_NAME=galasabld-${os}-${ARCHITECTURE}

    # Favour the locally built galasabld tool, else use the galasabld tool on the path, or fail if not available.
    export GALASA_BUILD_TOOL_PATH=${WORKSPACE_DIR}/galasa/modules/buildutils/bin/${GALASA_BUILD_TOOL_NAME}
    if [[ -e ${GALASA_BUILD_TOOL_PATH} ]]; then
        info "Using the $GALASA_BUILD_TOOL_NAME tool at ${GALASA_BUILD_TOOL_PATH}"
    else
        GALASABLD_ON_PATH=$(which galasabld)
        rc=$?
        if [[ "${rc}" == "0" ]]; then
            info "Using the 'galasabld' tool which is on the PATH"
            GALASA_BUILD_TOOL_PATH=${GALASABLD_ON_PATH}
        else
            GALASABLD_ON_PATH=$(which $GALASA_BUILD_TOOL_NAME)
            rc=$?
            if [[ "${rc}" == "0" ]]; then
                info "Using the '$GALASA_BUILD_TOOL_NAME' tool which is on the PATH"
                GALASA_BUILD_TOOL_PATH=${GALASABLD_ON_PATH}
            else
                error "Cannot find the $GALASA_BUILD_TOOL_NAME tools on locally built workspace or the path."
                info "Try re-building the buildutils module of the 'galasa' repository"
                exit 1
            fi
        fi
    fi

}

#------------------------------------------------------------------------------------
function generate_pom_xml {

    export DIRECTORY=$1
    export DISTRIBUTION=$2

    cd ${DIRECTORY}

    h2 "Generating the pom.xml from the pom.template for ${DISTRIBUTION}"

    dist_flag=""
    if [[ "${DISTRIBUTION}" == "${ISOLATED_DISTRIBUTION}" ]]; then
        dist_flag="--isolated"
    elif [[ "${DISTRIBUTION}" == "${MVP_DISTRIBUTION}" ]]; then
        dist_flag="--mvp"
    else
        error "Programming logic error. Invalid distribution provided. Log file is ${log_file}"
        exit 1
    fi

    info "Using galasabld tool ${GALASA_BUILD_TOOL_PATH}"

    cmd="${GALASA_BUILD_TOOL_PATH} template \
    --releaseMetadata ${WORKSPACE_DIR}/galasa/modules/framework/release.yaml \
    --releaseMetadata ${WORKSPACE_DIR}/galasa/modules/extensions/release.yaml \
    --releaseMetadata ${WORKSPACE_DIR}/galasa/modules/managers/release.yaml \
    --releaseMetadata ${WORKSPACE_DIR}/galasa/modules/obr/release.yaml \
    --template pom.template \
    --output pom.xml \
    ${dist_flag}"

    echo "Command is $cmd" >> ${log_file}
    $cmd 2>&1 >> ${log_file}

    rc=$?
    if [[ "${rc}" != "0" ]]; then
        error "Failed to generate a pom.xml from the pom.template. Log file is ${log_file}"
        exit 1
    fi
    success "pom.xml generated ok - log is at ${log_file}"
}

#------------------------------------------------------------------------------------
function build_pom_xml {

    export DIRECTORY=$1
    export DISTRIBUTION=$2
    export POM_FILE=$3
    export TARGET_DIR=$4

    cd ${DIRECTORY}

    h2 "Building the ${POM_FILE} for ${DISTRIBUTION}"

    cmd="mvn -f ${POM_FILE} process-sources -X \
    -Dgpg.skip=true \
    -Dgalasa.target.repo=file:${TARGET_DIR} \
    -Dgalasa.runtime.repo=${SOURCE_MAVEN_OBR} \
    -Dgalasa.simplatform.repo=${SOURCE_MAVEN_SIMPLATFORM} \
    -Dgalasa.javadoc.repo=${SOURCE_MAVEN_JAVADOC} \
    -Dgalasa.central.repo=https://repo.maven.apache.org/maven2/ \
    --batch-mode --errors --fail-at-end \
    --settings ${BASEDIR}/settings.xml"

    echo "Command is $cmd" >> ${log_file}
    $cmd 2>&1 >> ${log_file}

    rc=$?
    if [[ "${rc}" != "0" ]]; then
        error "Failed to build ${POM_FILE}. Log file is ${log_file}"
        exit 1
    fi
    success "${POM_FILE} built ok - log is at ${log_file}"
    
}

#------------------------------------------------------------------------------------
function build_pom_galasactl_xml {

    export DIRECTORY=$1
    export DISTRIBUTION=$2

    cd ${DIRECTORY}

    h2 "Getting the galasactl binaries"

    mkdir bin
    cp ${WORKSPACE_DIR}/cli/bin/galasactl* bin

    h2 "Building the pomGalasactl.xml for ${DISTRIBUTION}"

    cmd="mvn -f pomGalasactl.xml validate -X \
    -Dgpg.skip=true \
    -Dgalasa.target.repo=file:target/isolated \
    -Dgalasa.runtime.repo=${SOURCE_MAVEN_OBR} \
    -Dgalasa.simplatform.repo=${SOURCE_MAVEN_SIMPLATFORM} \
    -Dgalasa.javadoc.repo=${SOURCE_MAVEN_JAVADOC} \
    -Dgalasa.central.repo=https://repo.maven.apache.org/maven2/ \
    --batch-mode --errors --fail-at-end \
    --settings ${BASEDIR}/settings.xml"

    echo "Command is $cmd" >> ${log_file}
    $cmd 2>&1 >> ${log_file}

    rc=$?
    if [[ "${rc}" != "0" ]]; then
        error "Failed to build pomGalasactl.xml. Log file is ${log_file}"
        exit 1
    fi
    success "pomGalasactl.xml built ok - log is at ${log_file}"

}

#------------------------------------------------------------------------------------
function copy_text_files {

    export DIRECTORY=$1
    export DISTRIBUTION=$2

    cd ${DIRECTORY}

    h2 "Copy required text files into the target directory for ${DISTRIBUTION}"

    cp -vr resources/* target/isolated

    success "Text files copied into the target directory ok - log is at ${log_file}"

}

#------------------------------------------------------------------------------------
function build_zip {

    export DIRECTORY=$1
    export DISTRIBUTION=$2

    cd ${DIRECTORY}

    h2 "Building the pomZip.xml for ${DISTRIBUTION}"

    cmd="mvn -f pomZip.xml deploy -X \
    -Dgpg.skip=true \
    -Dgalasa.target.repo=file:target/isolated \
    -Dgalasa.release.repo=file:target/isolated \
    -Dgalasa.runtime.repo=${SOURCE_MAVEN_OBR} \
    -Dgalasa.simplatform.repo=${SOURCE_MAVEN_SIMPLATFORM} \
    -Dgalasa.javadoc.repo=${SOURCE_MAVEN_JAVADOC} \
    -Dgalasa.central.repo=https://repo.maven.apache.org/maven2/ \
    --batch-mode --errors --fail-at-end \
    --settings ${BASEDIR}/settings.xml"

    echo "Command is $cmd" >> ${log_file}
    $cmd 2>&1 >> ${log_file}

    rc=$?
    if [[ "${rc}" != "0" ]]; then
        error "Failed to build pomZip.xml. Log file is ${log_file}"
        exit 1
    fi
    success "pomZip.xml built ok - log is at ${log_file}"

}

#------------------------------------------------------------------------------------
function check_secrets {

    h2 "Updating secrets baseline"
    cd ${BASEDIR}
    detect-secrets scan --update .secrets.baseline
    rc=$? 
    check_exit_code $rc "Failed to run detect-secrets. Please check it is installed properly" 
    success "Updated secrets file"

    h2 "Running audit for secrets"
    detect-secrets audit .secrets.baseline
    rc=$? 
    check_exit_code $rc "Failed to audit detect-secrets."
    
    # Check all secrets have been audited
    secrets=$(grep -c hashed_secret .secrets.baseline)
    audits=$(grep -c is_secret .secrets.baseline)
    if [[ "$secrets" != "$audits" ]]; then 
        error "Not all secrets found have been audited"
        exit 1  
    fi
    success "Secrets audit complete"

    h2 "Removing the timestamp from the secrets baseline file so it doesn't always cause a git change."
    mkdir -p temp
    rc=$? 
    check_exit_code $rc "Failed to create a temporary folder"
    cat .secrets.baseline | grep -v "generated_at" > temp/.secrets.baseline.temp
    rc=$? 
    check_exit_code $rc "Failed to create a temporary file with no timestamp inside"
    mv temp/.secrets.baseline.temp .secrets.baseline
    rc=$? 
    check_exit_code $rc "Failed to overwrite the secrets baseline with one containing no timestamp inside."
    success "Secrets baseline timestamp content has been removed ok"
}

rm -f ${ISOLATED_DIR}/pom.xml
rm -rf ${ISOLATED_DIR}/target
rm -rf ${ISOLATED_DIR}/bin

rm -f ${MVP_DIR}/pom.xml
rm -rf ${MVP_DIR}/target
rm -rf ${MVP_DIR}/bin

# galasabld is used to create a pom.xml from a pom.template
# with information from several release.yaml files.
get_galasabld_binary_location

generate_pom_xml ${ISOLATED_DIR} ${ISOLATED_DISTRIBUTION}
build_pom_xml ${ISOLATED_DIR} ${ISOLATED_DISTRIBUTION} "pom.xml" "target/isolated/maven"
build_pom_xml ${ISOLATED_DIR} ${ISOLATED_DISTRIBUTION} "pom2.xml" "target/isolated/maven"
build_pom_xml ${ISOLATED_DIR} ${ISOLATED_DISTRIBUTION} "pom3.xml" "target/isolated/maven"
build_pom_xml ${ISOLATED_DIR} ${ISOLATED_DISTRIBUTION} "pom4.xml" "target/isolated/maven"
build_pom_xml ${ISOLATED_DIR} ${ISOLATED_DISTRIBUTION} "pom5.xml" "target/isolated/maven"
build_pom_xml ${ISOLATED_DIR} ${ISOLATED_DISTRIBUTION} "pom6.xml" "target/isolated/maven"
build_pom_xml ${ISOLATED_DIR} ${ISOLATED_DISTRIBUTION} "pomJavaDoc.xml" "target/isolated"
build_pom_galasactl_xml ${ISOLATED_DIR} ${ISOLATED_DISTRIBUTION}
copy_text_files ${ISOLATED_DIR} ${ISOLATED_DISTRIBUTION}
build_zip ${ISOLATED_DIR} ${ISOLATED_DISTRIBUTION}

success "Galasa Isolated distribution built successfully - the result can be found at ${ISOLATED_DIR}/target/isolated."

generate_pom_xml ${MVP_DIR} ${MVP_DISTRIBUTION}
build_pom_xml ${MVP_DIR} ${MVP_DISTRIBUTION} "pom.xml" "target/isolated/maven"
build_pom_xml ${MVP_DIR} ${MVP_DISTRIBUTION} "pom2.xml" "target/isolated/maven"
build_pom_xml ${MVP_DIR} ${MVP_DISTRIBUTION} "pom3.xml" "target/isolated/maven"
build_pom_xml ${MVP_DIR} ${MVP_DISTRIBUTION} "pom4.xml" "target/isolated/maven"
build_pom_xml ${MVP_DIR} ${MVP_DISTRIBUTION} "pom5.xml" "target/isolated/maven"
build_pom_xml ${MVP_DIR} ${MVP_DISTRIBUTION} "pom6.xml" "target/isolated/maven"
build_pom_xml ${MVP_DIR} ${MVP_DISTRIBUTION} "pomJavaDoc.xml" "target/isolated"
build_pom_galasactl_xml ${MVP_DIR} ${MVP_DISTRIBUTION}
copy_text_files ${MVP_DIR} ${MVP_DISTRIBUTION}
build_zip ${MVP_DIR} ${MVP_DISTRIBUTION}

success "Galasa MVP distribution built successfully - the result can be found at ${MVP_DIR}/target/isolated."

check_secrets

success "Project ${project} built - OK - log is at ${log_file}"