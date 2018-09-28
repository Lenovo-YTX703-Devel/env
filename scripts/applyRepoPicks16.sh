#!/bin/bash
##################################################################
#                       CONSTANTS
# PATH to android folder
export ANDROID_DIR=android16
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
repo forall -vc 'bash -c "performCleanup $REPO_PATH"'
############################ Apply repopicks ####################

echo "Performing repopicks..."
# Initialize out file
echo "">$OUT_FILE

##### Global exclusion list
# exclude "225684"

##### # system/core
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_system_core AND branch:lineage-16.0"

#queryGerrit "n"  "status:open AND is:mergeable AND branch:lineage-16.0 AND topic:pie-buttons"

queryGerrit "n"  "status:open AND is:mergeable AND branch:lineage-16.0 AND topic:pie-swap-volume-buttons"

#queryGerrit "n"  "status:open AND is:mergeable AND branch:lineage-16.0 AND topic:pie-lock-pattern"

queryGerrit "y"  "status:open AND is:mergeable AND branch:lineage-16.0 AND topic:pie-navbar-runtime-toggle AND NOT (project:LineageOS/android_packages_apps_SetupWizard)"

queryGerrit "y"  "status:open AND is:mergeable AND branch:lineage-16.0 AND topic:per-process-sdk-override"

queryGerrit "y"  "status:open AND is:mergeable AND branch:lineage-16.0 AND topic:pie-camera2"

queryGerrit "y"  "status:open AND is:mergeable AND branch:lineage-16.0 AND topic:pie-deskclock"

queryGerrit "y"  "status:open AND is:mergeable AND branch:lineage-16.0 AND topic:pie-volume-id"

queryGerrit "y"  "status:open AND is:mergeable AND branch:lineage-16.0 AND topic:pie-hw-fde"

queryGerrit "y"  "status:open AND is:mergeable AND branch:lineage-16.0 AND topic:fbe-wrapped-key"

# Remaining framework patches
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_frameworks_base AND branch:lineage-16.0"

queryGerrit "y"  "status:open AND is:mergeable AND branch:lineage-16.0 AND topic:revert-textrels"

queryGerrit "y"  "status:open AND is:mergeable AND branch:lineage-16.0 AND topic:pie-kernel-headers"

##### # system/vold
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_system_vold AND branch:lineage-16.0 AND topic:pie-vold"

##### # build/make
queryGerrit "y"  "status:open AND is:mergeable AND branch:lineage-16.0 AND (change:222733 OR change:222760)"

##### # dalvik
queryGerrit "y"  "status:open AND is:mergeable AND branch:lineage-16.0 AND (change:225475 OR change:225476)"

##### # external/perfetto
queryGerrit "y"  "status:open AND is:mergeable AND branch:lineage-16.0 AND (change:223413)"

##### # external/tinycompress
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_external_tinycompress AND branch:lineage-16.0"

##### # frameworks/av
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_frameworks_av AND branch:lineage-16.0"

##### # hardware/qcom/bt-caf
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_hardware_qcom_bt branch:lineage-16.0-caf topic:pie-bt-caf"


##### # bionic
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_bionic AND branch:lineage-16.0" "223943"

queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_device_lenovo_YTX703-common AND branch:lineage-16.0" "228856"
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_kernel_lenovo_msm8976 AND branch:lineage-16.0"

queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_hardware_qcom_audio branch:lineage-16.0-caf-8952"
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_hardware_qcom_media branch:lineage-16.0-caf-8952"

queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_device_qcom_sepolicy branch:lineage-16.0" "224768 224767"
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_device_qcom_sepolicy-legacy branch:lineage-16.0"
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_system_sepolicy branch:lineage-16.0"

#echo "Applying repopicks..."
#wget -O /storage/development/lenovo/repopick-lineage-sony8960-16.0.md https://raw.githubusercontent.com/AdrianDC/lineage_development_sony8960/local_manifests/repopick-lineage-sony8960-16.0.md
#sed -i 's/repopick *\([0-9]\)/repopick -c 50 \1/' /storage/development/lenovo/repopick-lineage-sony8960-16.0.md
#. /storage/development/lenovo/repopick-lineage-sony8960-16.0.md

echo "Changing qseecom-kernel-headers -> generated_kernel_headers..."
sed -i 's/qseecom-kernel-headers/generated_kernel_headers/' vendor/qcom/opensource/cryptfs/hw/Android.bp
