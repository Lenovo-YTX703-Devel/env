#!/bin/bash
##################################################################
#                       CONSTANTS
# PATH to android folder
export ANDROID_DIR=android
# Debug messages for script execution
export DEBUG=1
# File where applied repopicks are stored in a picklist
export OUT_FILE=/tmp/repopicks.sh
# Overwrite PATH (e.g. python 2)
export PATH=/home/mueller/bin_python2:$PATH

# If cleanup is performed, exclude the following repositories
function _get_excluded_projects_from_cleanup() {
 EXCLUDED_PROJECTS_FROM_CLEANUP=("device/lenovo/YTX703-common" "device/lenovo/YTX703F" "device/lenovo/YTX703L" "vendor/lenovo")
}
export -f _get_excluded_projects_from_cleanup
##################################################################

# Break on error
set -e
# Be verbose
set -v

# Include common functions
_PATH_OF_SCRIPT=$(dirname $(readlink -f "$0"))
. "$_PATH_OF_SCRIPT/_functions.sh"

# Array where already applied or excluded changes are stored
export ARRAY=()

# Switch to android folder
cd $ANDROID_DIR
export BUILD_PWD=`pwd`
. build/envsetup.sh

############################   Clean up repo ####################
# Clean build
echo "Performing cleanup..."
#repo forall -vc 'bash -c "performCleanup $REPO_PATH"'
############################ Apply repopicks ####################

echo "Performing repopicks..."
# Initialize out file
echo "">$OUT_FILE

##### Global exclusion list
# exclude "225684"

# Example:
# queryGerrit <apply changes, which are submitted together> <query> <exclude changes>
# Note: changes, which are applied or excluded will never applied in other queryGerrit calls

queryGerrit "y" "status:open AND is:mergeable AND project:LineageOS/android_device_lenovo_YTX703-common AND branch:lineage-15.1 AND NOT (change:225735)"
queryGerrit "y" "status:open AND is:mergeable AND project:LineageOS/android_kernel_lenovo_msm8976 AND branch:lineage-15.1 AND NOT topic:containerdroid-15.1"

queryGerrit "y" "status:open AND is:mergeable AND project:LineageOS/android_device_bq_bardockpro AND branch:lineage-15.1"
queryGerrit "y" "status:open AND is:mergeable AND project:LineageOS/android_device_bq_msm8953-common AND branch:lineage-15.1"
queryGerrit "y" "status:open AND is:mergeable AND project:LineageOS/android_kernel_bq_msm8953 AND branch:lineage-15.1"


# mm-pp-daemon: Enable mm-pp-daemon color improvements.
# repopick \
# 225735

# VNDK
# hal: compilation error fixes with the vndk
#repopick \
#220562

# mm-audio: compilation error fixes with the vndk
#repopick \
#220563

# post_proc: compilation error fixes with the vndk
#repopick \
#220564

# visualizer: compilation error fixes with the vndk
#repopick \
#220565

# voice_processing: compilation error fixes with the vndk
#repopick \
#220566

# libc2dcolorconvert: compilation error fixes with the vndk
#repopick \
#220567

# libstagefrighthw: compilation error fixes with the vndk
#repopick \
#220568

# mm-video-v4l2: compilation error fixes with the vndk
#repopick \
#220569

# Make volume steps and defaults adjustable for all audio streams
#repopick 226009

# dts: backlight: make lp8557 full-scale LED current configurable
#repopick 226082
