#!/bin/bash --login

# Copyright 2013-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# This script can help you download and run a script from S3 using aws-cli.
# It can also download a zip file from S3 and run a script from inside.
# See below for usage instructions.

PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
BASENAME="${0##*/}"
S3_BUCKET="s3://ssparse"
BATCH_FILE_TYPE="script"
BATCH_FILE_S3_URL="s3://ssparse/job.sh"
S3_HYPERMAPPER_URL="s3://ssparse/hypermapper_dev"
S3_TACO_URL="s3://ssparse/taco"

usage () {
  if [ "${#@}" -ne 0 ]; then
    echo "* ${*}"
    echo
  fi
  cat <<ENDUSAGE
Usage:
export BATCH_FILE_TYPE="script"
export BATCH_FILE_S3_URL="s3://my-bucket/my-script"
export S3_HYPERMAPPER_URL="s3://hypermapper_dev"
export S3_TACO_URL="s3://taco"
${BASENAME} script-from-s3 [ <script arguments> ]
  - or -
export BATCH_FILE_TYPE="zip"
export BATCH_FILE_S3_URL="s3://my-bucket/my-zip"
${BASENAME} script-from-zip [ <script arguments> ]
ENDUSAGE

  exit 2
}

# Standard function to print an error and exit with a failing return code
error_exit () {
  echo "${BASENAME} - ${1}" >&2
  exit 1
}

# Check what environment variables are set
if [ -z "${BATCH_FILE_TYPE}" ]; then
  usage "BATCH_FILE_TYPE not set, unable to determine type (zip/script) of URL ${BATCH_FILE_S3_URL}"
fi

if [ -z "${BATCH_FILE_S3_URL}" ]; then
  usage "BATCH_FILE_S3_URL not set. No object to download."
fi

if [ -z "${S3_HYPERMAPPER_URL}" ]; then
  usage "S3_HYPERMAPPER_URL not set. No object to download."
fi

if [ -z "${S3_TACO_URL}" ]; then
  usage "S3_TACO_URL not set. No object to download."
fi

scheme="$(echo "${BATCH_FILE_S3_URL}" | cut -d: -f1)"
if [ "${scheme}" != "s3" ]; then
  usage "BATCH_FILE_S3_URL must be for an S3 object; expecting URL starting with s3://"
fi

# Check that necessary programs are available
which aws >/dev/null 2>&1 || error_exit "Unable to find AWS CLI executable."
which unzip >/dev/null 2>&1 || error_exit "Unable to find unzip executable."

# Create a temporary directory to hold the downloaded contents, and make sure
# it's removed later, unless the user set KEEP_BATCH_FILE_CONTENTS.
cleanup () {
  KEEP_BATCH_FILE_CONTENTS=0
   if [ -z "${KEEP_BATCH_FILE_CONTENTS}" ] \
     && [ -n "${TMPDIR}" ] \
     && [ "${TMPDIR}" != "/" ]; then
      rm -r "${TMPDIR}"
   fi
}
trap 'cleanup' EXIT HUP INT QUIT TERM
# mktemp arguments are not very portable.  We make a temporary directory with
# portable arguments, then use a consistent filename within.
# TMPDIR="$(mktemp -d -t tmp.XXXXXXXXX)" || error_exit "Failed to create temp directory."
#mkdir -p local
TMPDIR=/app
TMPFILE="${TMPDIR}/batch-file-temp"
install -m 0600 /dev/null "${TMPFILE}" || error_exit "Failed to create temp file."

# Fetch and run a script
fetch_and_run_script () {
  # Create a temporary file and download the script
  # mkdir -p "${TMPDIR}"/hypermapper_dev
  # mkdir -p "${TMPDIR}"/taco
  
  # aws s3 cp "${S3_HYPERMAPPER_URL}" "${TMPDIR}"/hypermapper_dev --recursive 
  # aws s3 cp "${S3_TACO_URL}" "${TMPDIR}"/taco --recursive 

  # ls "${TMPDIR}"/hypermapper_dev

  # cd "${TMPDIR}"/hypermapper_dev

  # set +euo pipefail
  # conda activate hypermapper
  # source activate hypermapper
  # set -euo pipefail

  # mv /app/taco "${TMPDIR}"
  # mv /app/hypermapper_dev "${TMPDIR}"
  cd "${TMPDIR}"/taco/build
  # aws s3 cp "${S3_BUCKET}"/cpp_taco_SDDMM.json .
  #sudo ln -s /usr/bin/cmake3 /usr/bin/cmake
  # cmake -DCMAKE_BUILD_TYPE=Release -DOPENMP=ON ..
  # make -j32

  mkdir -p experiments

  mkdir -p data
  LINE=$((AWS_BATCH_JOB_ARRAY_INDEX + 1))
  matrix=$(sed -n ${LINE}p /app/mtx_list.txt)
  n=2
  aws s3 cp "${S3_BUCKET}"/"${matrix}" data/

  export SUITESPARSE_PATH="${TMPDIR}"/taco/build/data
  export HYPERMAPPER_HOME="${TMPDIR}"/hypermapper_dev

  ls
  echo "Running ls on suitesparse directory"
  ls "${SUITESPARSE_PATH}"

  # Make the temporary file executable and run it with any given arguments
  aws s3 cp --recursive "${S3_BUCKET}"/experiments/ "${TMPDIR}"/taco/build/experiments
  aws s3 cp "${BATCH_FILE_S3_URL}" runner.sh
  local script="./${1}"; shift
  chmod u+x runner.sh || error_exit "Failed to chmod script."
  sh runner.sh "${matrix}" || error_exit "Failed to execute script."

  basename="$(echo "${matrix}" | cut -d'.' -f1)"

  aws s3 cp --recursive "${TMPDIR}"/taco/build/experiments/outdata_SpMM_"${basename}" "${S3_BUCKET}"/experiments/outdata_SpMM_"${basename}"/
}

# Download a zip and run a specified script from inside
fetch_and_run_zip () {
  # Create a temporary file and download the zip file
  aws s3 cp "${BATCH_FILE_S3_URL}" - > "${TMPFILE}" || error_exit "Failed to download S3 zip file from ${BATCH_FILE_S3_URL}"

  # Create a temporary directory and unpack the zip file
  cd "${TMPDIR}" || error_exit "Unable to cd to temporary directory."
  unzip -q "${TMPFILE}" || error_exit "Failed to unpack zip file."

  # Use first argument as script name and pass the rest to the script
  local script="./${1}"; shift
  [ -r "${script}" ] || error_exit "Did not find specified script '${script}' in zip from ${BATCH_FILE_S3_URL}"
  chmod u+x "${script}" || error_exit "Failed to chmod script."
  exec "${script}" "${@}" || error_exit " Failed to execute script."
}

# Main - dispatch user request to appropriate function
case ${BATCH_FILE_TYPE} in
  zip)
    if [ ${#@} -eq 0 ]; then
      usage "zip format requires at least one argument - the script to run from inside"
    fi
    fetch_and_run_zip "${@}"
    ;;

  script)
    fetch_and_run_script "${@}"
    ;;

  *)
    usage "Unsupported value for BATCH_FILE_TYPE. Expected (zip/script)."
    ;;
esac
