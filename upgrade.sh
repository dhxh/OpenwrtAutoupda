#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild Functions

GET_TARGET_INFO() {
	[ -f ${GITHUB_WORKSPACE}/Openwrt.info ] && . ${GITHUB_WORKSPACE}/Openwrt.info
	TARGET_BOARD="$(awk -F '[="]+' '/TARGET_BOARD/{print $2}' .config)"
	TARGET_SUBTARGET="$(awk -F '[="]+' '/TARGET_SUBTARGET/{print $2}' .config)"
	if [[ "${TARGET_BOARD}" == "x86" ]];then
		TARGET_PROFILE="x86-64"
	else
		TARGET_PROFILE="$(egrep -o "CONFIG_TARGET.*DEVICE.*=y" .config | sed -r 's/.*DEVICE_(.*)=y/\1/')"
	fi
	[[ -z "${TARGET_PROFILE}" ]] && TARGET_PROFILE="Unknown"
	case "${TARGET_PROFILE}" in
	x86-64)
		if [ `grep -c "CONFIG_TARGET_IMAGES_GZIP=y" ${Home}/.config` -eq '1' ]; then
			Firmware_sfxo="img.gz"
		else
			Firmware_sfxo="img"
		fi
	;;
	esac
	case "${REPO_URL}" in
	"${LEDE}")
		COMP1="coolsnowwolf"
		COMP2="lede"
		if [[ "${TARGET_PROFILE}" == "x86-64" ]]; then
			Default_Firmware="openwrt-x86-64-generic-squashfs-combined.${Firmware_sfxo}"
			EFI_Default_Firmware="openwrt-x86-64-generic-squashfs-combined-efi.${Firmware_sfxo}"
			Firmware_sfx="${Firmware_sfxo}"
		elif [[ "${TARGET_BOARD}" == "bcm53xx" ]]; then
			Default_Firmware="openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-${TARGET_PROFILE}-squashfs.trx"
			Firmware_sfx="trx"
		elif [[ "${TARGET_BOARD}-${TARGET_SUBTARGET}" = "ramips-mt7621" ]]; then
			Default_Firmware="openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-${TARGET_PROFILE}-squashfs-sysupgrade.bin"
			Firmware_sfx="bin"
		fi
	;;
	"${LIENOL}") 
		COMP1="openwrt"
		COMP2="lienol"
		if [[ "${TARGET_PROFILE}" == "x86-64" ]]; then
			Default_Firmware="openwrt-x86-64-generic-squashfs-combined.${Firmware_sfxo}"
			EFI_Default_Firmware="openwrt-x86-64-generic-squashfs-combined-efi.${Firmware_sfxo}"
			Firmware_sfx="${Firmware_sfxo}"
		elif [[ "${TARGET_BOARD}" == "bcm53xx" ]]; then
			Default_Firmware="openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-${TARGET_PROFILE}-squashfs.trx"
			Firmware_sfx="trx"
		elif [[ "${TARGET_BOARD}-${TARGET_SUBTARGET}" = "ramips-mt7621" ]]; then
			Default_Firmware="openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-${TARGET_PROFILE}-squashfs-sysupgrade.bin"
			Firmware_sfx="bin"
		fi
	;;
	"${PROJECT}")
		COMP1="immortalwrt"
		COMP2="CTCGFW"
		if [[ "${TARGET_PROFILE}" == "x86-64" ]]; then
			Default_Firmware="immortalwrt-x86-64-combined-squashfs.${Firmware_sfxo}"
			EFI_Default_Firmware="immortalwrt-x86-64-uefi-gpt-squashfs.${Firmware_sfxo}"
			Firmware_sfx="${Firmware_sfxo}"
		elif [[ "${TARGET_BOARD}" == "bcm53xx" ]]; then
			Default_Firmware="immortalwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-${TARGET_PROFILE}-squashfs.trx"
			Firmware_sfx="trx"
		elif [[ "${TARGET_BOARD}-${TARGET_SUBTARGET}" = "ramips-mt7621" ]]; then
			Default_Firmware="immortalwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-${TARGET_PROFILE}-squashfs-sysupgrade.bin"
			Firmware_sfx="bin"
	;;		
	esac
	if [[ ${REGULAR_UPDATE} == "true" ]]; then
		AutoUpdate_Version=$(awk 'NR==6' package/base-files/files/bin/AutoUpdate.sh | awk -F '[="]+' '/Version/{print $2}')
	fi
	Github_Repo="$(grep "https://github.com/[a-zA-Z0-9]" ${GITHUB_WORKSPACE}/.git/config | cut -c8-100)"
	Github_UP_RELEASE="${GITURL}/releases/"
	AutoBuild_Info=${GITHUB_WORKSPACE}/openwrt/package/base-files/files/etc/openwrt_info
	Openwrt_Version="${Compile_Date_Day}-${Compile_Date_Minute}"
}

Diy_Part1() {
	sed -i '/luci-app-autoupdate/d' .config > /dev/null 2>&1
	echo -e "\nCONFIG_PACKAGE_luci-app-autoupdate=y" >> .config
	sed -i '/luci-app-ttyd/d' .config > /dev/null 2>&1
	echo -e "\nCONFIG_PACKAGE_luci-app-ttyd=y" >> .config
}

Diy_Part2() {
	GET_TARGET_INFO
	[[ -z "${AutoUpdate_Version}" ]] && AutoUpdate_Version="Unknown"
	[[ -z "${Author}" ]] && Author="Unknown"
	echo "Author: ${Author}"
	echo "Openwrt Version: ${Openwrt_Version}"
	echo "Router: ${TARGET_PROFILE}"
	echo "Github: ${Github_Repo}"
	echo "${Compile_Date_Day}}" > ${AutoBuild_Info}
	echo "${Compile_Date_Minute}" >> ${AutoBuild_Info}
	echo "${Openwrt_Version}" >> ${AutoBuild_Info}
	echo "${Github_Repo}" >> ${AutoBuild_Info}
	echo "${TARGET_PROFILE}" >> ${AutoBuild_Info}
	echo "Firmware Type: ${Firmware_sfx}"
	echo "Writting Type: ${Firmware_sfx} to ${AutoBuild_Info} ..."
	echo "${Firmware_sfx}" >> ${AutoBuild_Info}
	echo "${COMP1}" >> ${AutoBuild_Info}
	echo "${COMP2}" >> ${AutoBuild_Info}
	
}

Diy_Part3() {
	GET_TARGET_INFO
	Firmware_Path="bin/targets/${TARGET_BOARD}/${TARGET_SUBTARGET}"
	Mkdir bin/Firmware
	case "${TARGET_PROFILE}" in
	x86-64)
		cd ${Firmware_Path}
		Legacy_Firmware="${Default_Firmware}"
		EFI_Firmware="${EFI_Default_Firmware}"
		AutoBuild_Firmware="${COMP1}-${COMP2}-${TARGET_PROFILE}-${Openwrt_Version}"
		if [ -f "${Legacy_Firmware}" ];then
            Firmware_MD5=$(md5sum ${Firmware_Path}/${AutoBuild_Firmware}-Legacy.${Firmware_sfx} | cut -d ' ' -f1)
            Firmware_SHA256=$(sha256sum ${Firmware_Path}/${AutoBuild_Firmware}-Legacy.${Firmware_sfx} | cut -d ' ' -f1)
            echo -e "\nMD5:${Firmware_MD5}\nSHA256:${Firmware_SHA256}" > ${Home}/bin/Firmware/${AutoBuild_Firmware}-Legacy.detail
			cp ${Legacy_Firmware} ${Home}/bin/Firmware/${AutoBuild_Firmware}-Legacy.${Firmware_sfx}
			echo "Legacy Firmware is detected !"
		fi
		if [ -f "${EFI_Firmware}" ];then
            Firmware_MD5=$(md5sum ${Firmware_Path}/${AutoBuild_Firmware}-UEFI.${Firmware_sfx} | cut -d ' ' -f1)
            Firmware_SHA256=$(sha256sum ${Firmware_Path}/${AutoBuild_Firmware}-UEFI.${Firmware_sfx} | cut -d ' ' -f1)
            echo -e "\nMD5:${Firmware_MD5}\nSHA256:${Firmware_SHA256}" > ${Home}/bin/Firmware/${AutoBuild_Firmware}-UEFI.detail
			cp ${Legacy_Firmware} ${Home}/bin/Firmware/${AutoBuild_Firmware}-Legacy.${Firmware_sfx}
			echo "UEFI Firmware is detected !"
		fi
	;;
	*)
		cd ${Home}
		Default_Firmware=""${Default_Firmware}""
		AutoBuild_Firmware="${COMP1}-${COMP2}-${Openwrt_Version}.${Firmware_sfx}"
		AutoBuild_Detail="${COMP1}-${COMP2}-${Openwrt_Version}.detail"
		echo "Firmware: ${AutoBuild_Firmware}"
		cp ${Firmware_Path}/${Default_Firmware} ${Home}/bin/Firmware/${AutoBuild_Firmware}
		Firmware_MD5=$(md5sum ${Firmware_Path}/${AutoBuild_Firmware} | cut -d ' ' -f1)
		Firmware_SHA256=$(sha256sum ${Firmware_Path}/${AutoBuild_Firmware} | cut -d ' ' -f1)
		echo -e "\nMD5:${_MD5}\nSHA256:${_SHA256}" > ${Home}/bin/Firmware/${AutoBuild_Detail}
	;;
	esac
	cd ${Home}
	echo "Actions Avaliable: $(df -h | grep "/dev/root" | awk '{printf $4}')"
}

Mkdir() {
	_DIR=${1}
	if [ ! -d "${_DIR}" ];then
		echo "[$(date "+%H:%M:%S")] Creating new folder [${_DIR}] ..."
		mkdir -p ${_DIR}
	fi
	unset _DIR
}

Diy_xinxi() {
	Diy_xinxi_Base
}
