#!/bin/bash - 

# Generate and install docset for a framework

set -o nounset                              # Treat unset variables as an error

# Get the directory this script lives in, accounting for symlinks to the script
if [ -L "$0" ]; then
  pushd "$(dirname $0)/$(dirname $(readlink "$0"))" >/dev/null
else
  pushd $(dirname "$0") >/dev/null
fi
readonly ScriptDir=$(pwd)
popd >/dev/null



if [[ -d "${HOME}/Library/Caches" ]]; then
    BaseTempDir="${HOME}/Library/Caches"
else
    BaseTempDir=/tmp
fi
TempDir=`mktemp -d ${BaseTempDir}/GenerateDocs.XXXXXX` || exit 1

DOXYGEN=/usr/local/bin/doxygen
APPLEDOC=/usr/local/bin/appledoc

function usage ()
{
	cat <<- EOT

  Usage :  $(basename $0) -s <dir> -x <path> -f <name> -c <name> -d <name>

  Options: 
  -s <dir>      The directory containing the source header files
  -o <dir>      Output directory -- if supplied, generated files will be preserved, otherwise
                the generated files are deleted after the docset is installed
  -x <path>     The path to the index page
  -f <name>     The name of the framework (appears on doc pages) (default = basename of source)
  -c <name>     The company/organisation name
  -d <name>     The company id in the format 'com.dervishsoftware'
  -b <path>     Path to 'dot' for doxygen (default = dot binary found in path), or 'none' for no graphs
  -a            Turn on TomDoc conversion of the source
  -t appledoc|doxygen  The output type (default = appledoc)
  -h            Display this message
EOT
}    # ----------  end of function usage  ----------

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------
InputSourceDir=
INDEX_PATH=
FRAMEWORK=
COMPANY=
COMPANY_ID=
OUTPUT_TYPE=appledoc
DOT_PATH=
CONVERT_TOMDOC=
OUTPUT_DIR=

while getopts ":hvs:x:f:c:d:t:b:ao:" opt
do
    case $opt in

        a ) CONVERT_TOMDOC=1 ;;
        s ) 
            InputSourceDir=$OPTARG 
            ;;
        x ) 
            INDEX_PATH=$OPTARG 
            ;;
        f ) 
            FRAMEWORK=$OPTARG 
            ;;
        c ) 
            COMPANY=$OPTARG 
            ;;
        b )
            DOT_PATH=$OPTARG ;;
        d ) 
            COMPANY_ID=$OPTARG
            ;;
        t ) 
            OUTPUT_TYPE=$OPTARG
            ;;
        o ) OUTPUT_DIR=$OPTARG ;;
        h ) 
            usage
            exit 0   
            ;;
        \? ) 
            echo -e "\n  Option does not exist : $OPTARG\n"
            usage
            exit 1
            ;;

esac    # --- end of case ---
done
shift $(($OPTIND-1))

if [[ -z "${InputSourceDir}" || -z "${COMPANY}" || -z "${COMPANY_ID}" ]]; then
    echo "Missing parameters. Must supply -s, -c, and -d"
    usage
    exit 1
fi
if [[ -z "$FRAMEWORK" ]]; then
    FRAMEWORK=$(basename "$InputSourceDir")
fi
if [[ ! -z "$OUTPUT_DIR" ]]; then
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        if ! mkdir -p "$OUTPUT_DIR"; then
            echo "Could not create output directory '$OUTPUT_DIR'" >&2
            exit 1
        fi
    fi
else
    OUTPUT_DIR=${TempDir}/doc
    mkdir $OUTPUT_DIR
fi

GeneratedHeadersDir="${TempDir}/headers"
mkdir -p "${GeneratedHeadersDir}"

InputSourceDir=$(path_resolving_symlinks "$InputSourceDir")
if [[ $? -ne 0 ]]; then
    echo "Could not find source directory ${InputSourceDir}" >&2
    exit 1
fi

if [[ "${OUTPUT_TYPE}" != "appledoc" && "${OUTPUT_TYPE}" != "doxygen" ]]; then
    echo "Output type must be 'appledoc' or 'doxygen'"
    usage
    exit 1
fi

VERBOSITY=0 # 0 (silent) to 6 (most verbose) -- verbosity of appledoc

#PUBLISH_OPTION=--publish-docset
PUBLISH_OPTION=

DOCSET_NAME=${COMPANY_ID}.${FRAMEWORK}.docset
DOCSET_FEED_URL=http://www.dervishsoftware/docsets
INDEX_FILE=


#===============================================================================
# Convert TomDoc, if required
#===============================================================================

if [[ ! -z "$CONVERT_TOMDOC" ]]; then
    if [[ -z "$TempDir" ]]; then
        TempDir=`mktemp -d ${BaseTempDir}/GenerateDocs.XXXXXX` || exit 1
    fi

    if [[ ! -z "${INDEX_PATH}" ]]; then
        if ! cp ${INDEX_PATH} ${TempDir}; then
            echo "Could not find index file '${INDEX_PATH}'" >&2
            exit 2
        fi
        INDEX_FILE="../$(basename "${INDEX_PATH}")"
    fi

    echo "Converting TomDoc headers in ${InputSourceDir}..."
    "${ScriptDir}/tomdoc_converter_objc.py" "--${OUTPUT_TYPE}" -o "${GeneratedHeadersDir}" "${InputSourceDir}"
    InputSourceDir="$GeneratedHeadersDir"
fi


#===============================================================================
# Generate documentation
#===============================================================================


if [[ "${OUTPUT_TYPE}" = "appledoc" ]]; then
    # As of 31 August, 2013, these extra flags to appledoc are only supported in the version of
    # appledoc available here: https://github.com/antmd/appledoc:
    # --ignore-symbol <glob>
    # --require-leader-for-local-crossrefs
    # A pull request to the parent repository has been made

    APPLEDOC_EXTRA_FLAGS=
    if appledoc --help | grep 'ignore-symbol' >/dev/null; then
        APPLEDOC_EXTRA_FLAGS="${APPLEDOC_EXTRA_FLAGS} --ignore-symbol """*Deprecated*""
    fi
    if appledoc --help | grep 'require-leader-for-local-crossrefs' >/dev/null; then
        APPLEDOC_EXTRA_FLAGS=${APPLEDOC_EXTRA_FLAGS}" --require-leader-for-local-crossrefs"
    fi

    echo "Generating DocSet using appledoc..."
    # Call appledoc to generate and install the docset
    "${APPLEDOC}" \
        --project-name "${FRAMEWORK}" \
        --project-company "${COMPANY}" \
        --company-id "${COMPANY_ID}" \
        --docset-atom-filename "${FRAMEWORK}.atom" \
        --docset-feed-url "${DOCSET_FEED_URL}/%DOCSETATOMFILENAME" \
        --docset-package-url "${DOCSET_FEED_URL}/%DOCSETPACKAGEFILENAME" \
        --docset-fallback-url "${DOCSET_FEED_URL}" \
        --docset-bundle-filename "${DOCSET_NAME}" \
        --output "${OUTPUT_DIR}" \
        ${PUBLISH_OPTION} \
        --logformat xcode \
        --keep-undocumented-objects \
        --keep-undocumented-members \
        --keep-intermediate-files \
        --no-repeat-first-par \
        --no-warn-invalid-crossref \
        --ignore "*.m" \
        --ignore "*Deprecated*" \
        ${APPLEDOC_EXTRA_FLAGS} \
        --index-desc "${INDEX_FILE}" \
        --verbose $VERBOSITY \
        "${InputSourceDir}"
else # Doxygen
    DOXYGEN_TEMPLATES_DIR="${ScriptDir}/doxygen-templates"
    HAVE_DOT=YES
    if [[ "$DOT_PATH" = "none" ]]; then
        HAVE_DOT=NO
    elif [[ -z "$DOT_PATH" ]]; then
        DOT_PATH=$(type -P dot)
        if [[ $? -ne 0 ]]; then
            echo "Cannot find 'dot' in PATH." >&2
            echo "Use -b none as an argument to turn off dot." >&2
            exit 1
        fi
    elif [[ ! -e "$DOT_PATH" ]]; then
        echo "Cannot find 'dot' at $DOT_PATH." >&2
        exit 1
    fi
    export DOT_PATH
    export HAVE_DOT
    export INPUT_DIR="\"${InputSourceDir}\" \"${GeneratedHeadersDir}\""
    export HTML_HEADER=
    export DOCSET_PUBLISHER_ID="${COMPANY_ID}"
    export DOCSET_PUBLISHER="${COMPANY}"
    export DOCSET_BUNDLE_ID="${COMPANY_ID}.${FRAMEWORK}"
    export FRAMEWORK
    export OUTPUT_DIRECTORY="$OUTPUT_DIR"

    # Generate the index page
    pushd "${GeneratedHeadersDir}" >/dev/null 2>&1
    cat > mainpage.h <<-EOF
    /*! \\mainpage ${FRAMEWORK} Main Page
     *
EOF
    if [[ ! -z "$INDEX_FILE" ]]; then
        cat < "../${INDEX_FILE}" >> mainpage.h
    fi
    cat >> mainpage.h <<-EOF
    */
EOF

    popd >/dev/null 2>&1
    ${DOXYGEN} "${DOXYGEN_TEMPLATES_DIR}/DocSet.Doxyfile"
    if [[ $? -eq 0 ]]; then
        cd "${OUTPUT_DIRECTORY}" && make install
    fi
fi

echo "Cleaning up..."
cd ${ScriptDir}
if [[ ! -z "$TempDir" ]]; then
    rm -rf ${TempDir}
fi

echo "Installed docset for ${FRAMEWORK} to ~/Library/Developer/Shared/Documentation/DocSets/${DOCSET_NAME}"
