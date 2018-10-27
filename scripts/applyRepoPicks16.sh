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
#repo forall -vc 'bash -c "performCleanup $REPO_PATH"'
############################ Apply repopicks ####################

echo "Performing repopicks..."
# Initialize out file
echo "">$OUT_FILE

##### Global exclusion list
#excludeQueryGerrit "topic:android-9.0.0_r12"

#LineageOS/android_device_lenovo_YTX703-common
exclude "230059" # vintf: uprev power hal from 1.0 to 1.1

#LineageOS/android_device_qcom_sepolicy-legacy
exclude "230234" # common: allow wifi HIDL HAL to read tombstones, superseeded by 230831

# Example:
# queryGerrit <apply changes, which are submitted together> <query> <exclude changes>
# Note: changes, which are applied or excluded will never applied in other queryGerrit calls

queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_device_lenovo_YTX703-common AND branch:lineage-16.0" "228856"
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_kernel_lenovo_msm8976 AND branch:lineage-16.0"

queryGerrit "y"  "status:open AND is:mergeable AND branch:lineage-16.0-caf-8952"
queryGerrit2 -f "n"  -q "change:224631" # audio: Update compiler flags

queryGerrit2 -f "y" -q "status:open AND is:mergeable AND branch:lineage-16.0 AND topic:pie-hw-fde"
queryGerrit2 -f "y" -q "status:open AND is:mergeable AND branch:lineage-16.0 AND topic:fbe-wrapped-key"

# Lenovo
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_device_qcom_sepolicy branch:lineage-16.0" 
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_device_qcom_sepolicy-legacy branch:lineage-16.0"
queryGerrit "y"  "status:open AND is:mergeable AND project:LineageOS/android_system_sepolicy branch:lineage-16.0"

# system/core
queryGerrit2 -f "y" -q "change:230755" # libsuspend: Bring back earlysuspend

# O_TMPFILE patches
python ./vendor/lineage/build/tools/repopick.py -f -c 50 230246-230257

# Enable permissive mode
python ./vendor/lineage/build/tools/repopick.py -f -c 50 228843

# topic:android-9.0.0_r12 
# queryGerrit2 -f "y" -q  "status:open AND is:mergeable AND topic:android-9.0.0_r12"

echo "Changing qseecom-kernel-headers -> generated_kernel_headers..."
sed -i 's/qseecom-kernel-headers/generated_kernel_headers/' vendor/qcom/opensource/cryptfs/hw/Android.bp

echo "Revert commit 593513e216e7a6e9b60d6f477f2e48a71f97af9f sepolicy: allow init to read /proc/device-tree"
sed -i '/.*\/device-tree\/firmware\/android.*/d' device/lenovo/YTX703-common/sepolicy/genfs_contexts
