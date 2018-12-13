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
	excludearray="vendor/lenovo device/xiaomi/msm8956-common"
	cd ${BUILD_PWD}
	repo="$1"
	echo -n "${repo} "

	if echo ${1} | grep -q "${excludearray}"; then
		echo "Skipping"
	else
		echo "Clean up now"
		git -C ${repo} clean -fd
		git -C ${repo} reset --hard
		repo sync -d ${repo}
	fi
}

pick() {
	. build/envsetup.sh

	repopick_chain 236425 # device/lenovo/YTX703-common
	repopick_chain 230257 # kernel/lenovo/msm8976

	# ######################
	# # Needed for things to compile

	repopick -t "pie-mode-bits"

	#######################
	# Nice to have

	repopick_chain 231249 # roomservice.py for lineage-16.0
	repopick 232292 # repopick: be able to kang yourself
	#repopick_chain 233223 # Snap: Always allow 100% JPEG quality to be set
	repopick -c 100 -t "pie-gallery2"
	repopick -c 100 -t "pie-tiles"
	repopick -c 100 -t "pie-powermenu"
	#repopick -t "pie-battery-styles"
	#repopick -t "pie-hide-night-display"

	repopick -c 100 -t "wifi-dual-interface"
	repopick -c 100 -t "pie-su"

	#######################
	# Needed for things to work
	#
	repopick -c 100 -t "pie-hw-fde"
	repopick -c 100 -t "fbe-wrapped-key"

	repopick 224631 # audio: Update compiler flags
	repopick 230224 # init: run timekeep service as system user
	repopick 230610 # APP may display abnormally in landscape LCM
	repopick 230613 # Allow webview_zygote to read /dev/ion

	repopick_chain 227211 # hardware/qcom/audio-caf/msm8952
	#repopick 224642 # hardware/qcom/audio-caf/msm8952

	#repopick -c 100 -t "pie-qcom-sepolicy"
	repopick -c 100 -t "pie-qcom-legacy-sepolicy"
	repopick 234861 # Reading the serialno property is forbidden
	repopick 234884 # Allow init to write to /proc/cpu/alignment
	repopick 234886 # Allow init to chmod/chown /proc/slabinfo
	repopick 235196 # Allow dnsmasq to getattr netd unix_stream_socket
	repopick 235258 # Allow fsck_untrusted to getattr block_device
	repopick 236217 # private: allow vendor_init to create dpmd_data_file
	repopick -c 100 230834 # legacy: allow init to read /proc/device-tree
	repopick -c 100 230230 # common: fix sensors denial
	repopick -c 100 230231 # common: grant cnss-daemon access to sysfs_net
	repopick -c 100 230232 # common: grant netmgrd access to sysfs_net nodes
	repopick -c 100 230233 # common: allow sensors HIDL HAL to access /dev/sensors
	#repopick -c 100 230234 # common: allow wifi HIDL HAL to read tombstones <- superseded by 230831
	repopick -c 100 230235 # common: grant DRM HIDL HAL ownership access to /data/{misc,vendor}/media/
	repopick -c 100 230236 # common: label /sys/devices/virtual/graphics as sysfs_graphics
	#repopick -c 100 230238 # common: create proc_kernel_sched domain to restrict perf hal access <- doesn't apply
	repopick -c 100 230239 # common: allow uevent to control sysfs_mmc_host via vold

	# system/core
	#repopick 230755 # libsuspend: Bring back earlysuspend <- abandoned

	# Enable permissive mode
	#repopick -f -c 50 228843
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

