#!/bin/bash

set -e -o pipefail

query_submitted_together() {
	change=$1
	curl -s -H 'Accept-Type: application/json' "https://review.lineageos.org/changes/${change}/submitted_together" | tail -n +2 | jq -r '.[]._number'
}

repopick_chain() {
	local chain_top=$1

	submitted_together=($(query_submitted_together ${chain_top}))
	for ((i=${#submitted_together[@]} - 1; i >= 0; i--)); do
		change=${submitted_together[i]}
		# Check for a number of commits equal to double the chain's length
		repopick -c $((2 * ${#submitted_together[@]})) ${change}
	done
}

clean() {
	export BUILD_PWD="${PWD}"

	repo forall -vc "${BUILD_PWD}/${0} perform_cleanup \${REPO_PATH}"
	repo sync --force-sync -j 8
}

perform_cleanup() {
	excludearray="vendor/lenovo device/xiaomi/msm8956-common kernel/xiaomi/msm8956 vendor/xiaomi device/lenovo/YTX703-common"
	cd ${BUILD_PWD}
	repo="$1"
	echo -n "${repo} "

	if echo "${excludearray}" | grep -q "${1}"; then
		echo "Skipping"
	else
		echo "Clean up now"
		git -C ${repo} clean -fd
		git -C ${repo} reset --hard
		repo sync -d ${repo}
	fi
}

pick() {
	source build/envsetup.sh

	repopick_chain 238169 # device/lenovo/YTX703-common
	repopick 238097
	repopick_chain 230257 # kernel/lenovo/msm8976

	repopick_chain 231249 # roomservice.py for lineage-16.0
	repopick -c 100 232292 # repopick: be able to kang yourself

	repopick_chain 238128 # extract_utils

	repopick -c 100 230224 # init: run timekeep service as system user
	repopick -c 100 230610 # APP may display abnormally in landscape LCM

	# sepolicy
	#repopick -c 100 230613 # Allow webview_zygote to read /dev/ion
	repopick -c 100 234861 # Reading the serialno property is forbidden
	repopick -c 100 234884 # Allow init to write to /proc/cpu/alignment
	repopick -c 100 234886 # Allow init to chmod/chown /proc/slabinfo
	repopick -c 100 235196 # Allow dnsmasq to getattr netd unix_stream_socket
	repopick -c 100 235258 # Allow fsck_untrusted to getattr block_device
	repopick -c 100 230237 # common: allow vendor_init to create /data/dpm
	repopick -c 100 230229 # mm-qcamera-daemon: fix denial
	repopick -c 100 230834 # legacy: allow init to read /proc/device-tree
	repopick -c 100 230230 # common: fix sensors denial
	repopick -c 100 230231 # common: grant cnss-daemon access to sysfs_net
	repopick -c 100 230232 # common: grant netmgrd access to sysfs_net nodes
	repopick -c 100 230233 # common: allow sensors HIDL HAL to access /dev/sensors
	repopick -c 100 230235 # common: grant DRM HIDL HAL ownership access to /data/{misc,vendor}/media/
	repopick -c 100 230236 # common: label /sys/devices/virtual/graphics as sysfs_graphics
	repopick -c 100 230239 # common: allow uevent to control sysfs_mmc_host via vold

	#repopick -t "pie-qcom-wfd"

	git -C device/lenovo/YTX703-common am ${ANDROID_BUILD_TOP}/env/dt2w-patches/device/*.patch
	git -C kernel/lenovo/msm8976 am ${ANDROID_BUILD_TOP}/env/dt2w-patches/kernel/*.patch
}

usage() {
	echo "$0 clean"
	echo "$0 pick"
}

case ${1:-x} in
clean)
	clean
	;;
pick)
	pick
	;;
perform_cleanup)
	shift
	perform_cleanup $@
	;;
*)
	usage
esac

