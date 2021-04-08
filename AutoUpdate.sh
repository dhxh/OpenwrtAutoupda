#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoUpdate for Openwrt

Version=V5.5

List_Info() {
	echo "固件作者:	${Author}"
	echo "作者仓库:	${Cangku}"
	echo -e "\n/overlay 可用:	${Overlay_Available}"
	echo "/tmp 可用:	${TMP_Available}M"
	echo "固件下载位置:	/tmp/Downloads"
	echo "当前设备:	${CURRENT_Device}"
	echo "默认设备:	${DEFAULT_Device}"
	echo "当前固件版本:	${CURRENT_Ver}"
	echo "固件名称:	${Firmware_COMP1}-${CURRENT_Version}${Firmware_SFX}"
	echo "Github 地址:	${Github}"
	echo "解析 API 地址:	${Github_Tags}"
	echo "固件下载地址:	${Github_Download}"
	if [[ ${DEFAULT_Device} == "x86-64" ]];then
		echo "EFI 引导: 	${EFI_Boot}"
		echo "固件压缩:	${Compressed_x86}"
	fi
	echo "固件格式:	${Firmware_GESHI}"
	exit
}

Shell_Helper() {
	echo -e "\n使用方法: bash /bin/AutoUpdate.sh [参数1] [参数2]"
	echo -e "\n支持下列参数:\n"
	echo "	-q	更新固件,不打印备份信息日志 [保留配置]"
	echo "	-n	更新固件 [不保留配置]"
	echo "	-f	强制更新固件,即跳过版本号验证,自动下载以及安装必要软件包 [保留配置]"
	echo "	-u	适用于定时更新 LUCI 的参数 [保留配置]"
	echo "	-c	[更换检测地址,命令 bash /bin/AutoUpdate.sh -c 地址"
	echo "	-b	[转换固件引导格式,命令 bash /bin/AutoUpdate.sh -b Legacy 或 bash /bin/AutoUpdate.sh -b UEFI [危险]"
	echo "	-l	列出所有信息"
	echo "	-d	清除固件下载缓存"
	echo -e "	-h	打印帮助信息\n"
	exit
}

Install_Pkg() {
	PKG_NAME=${1}
	grep "${PKG_NAME}" /tmp/Package_list > /dev/null 2>&1
	if [[ $? -ne 0 ]];then
		TIME && echo "未安装[ ${PKG_NAME} ],执行安装[ ${PKG_NAME} ],请耐心等待..."
		opkg update > /dev/null 2>&1
		opkg install ${PKG_NAME}
		if [[ $? -ne 0 ]];then
			TIME && echo "[ ${PKG_NAME} ] 安装失败,正在再次尝试安装...!"
			wget -c -P /tmp https://downloads.openwrt.org/snapshots/packages/x86_64/packages/gzip_1.10-3_x86_64.ipk
			opkg install /tmp/gzip_1.10-3_x86_64.ipk
			if [[ $? -ne 0 ]];then
				TIME && echo "再次尝试安装[ ${PKG_NAME} ]失败,请尝试手动安装!"
				exit
			else
				TIME && echo "再次尝试安装[ ${PKG_NAME} ]安装成功!"
				TIME && echo "开始解压固件,请耐心等待..."
			fi
		else
			TIME && echo "[ ${PKG_NAME} ] 安装成功!"
			TIME && echo "开始解压固件,请耐心等待...!"
		fi
	fi
}

TIME() {
	echo -ne "\n[$(date "+%H:%M:%S")] "
}

opkg list | awk '{print $1}' > /tmp/Package_list
Input_Option="$1"
Input_Other="$2"
CURRENT_Version="$(awk 'NR==1' /etc/openwrt_info)"
Github="$(awk 'NR==2' /etc/openwrt_info)"
DEFAULT_Device="$(awk 'NR==3' /etc/openwrt_info)"
Firmware_Type="$(awk 'NR==4' /etc/openwrt_info)"
Firmware_COMP1="$(awk 'NR==5' /etc/openwrt_info)"
Firmware_COMP2="$(awk 'NR==6' /etc/openwrt_info)"
Github_Download="${Github}/releases/download/update_Firmware"
Apidz="${Github##*com/}"
Author="${Apidz%/*}"
Cangku="${Github##*${Author}/}"
Github_Tags="https://api.github.com/repos/${Apidz}/releases/tags/update_Firmware"
TMP_Available="$(df -m | grep "/tmp" | awk '{print $4}' | awk 'NR==1' | awk -F. '{print $1}')"
Overlay_Available="$(df -h | grep ":/overlay" | awk '{print $4}' | awk 'NR==1')"
case ${DEFAULT_Device} in
x86-64)
	[[ -z ${Firmware_Type} ]] && Firmware_Type="img"
	if [[ "${Firmware_Type}" == "img.gz" ]];then
		Compressed_x86="1"
	else
		Compressed_x86="0"
	fi
	if [ -f /etc/openwrt_boot ];then
		BOOT_Type="-$(cat /etc/openwrt_boot)"
	else
		if [ -d /sys/firmware/efi ];then
			BOOT_Type="-UEFI"
			GESHI_Type="UEFI"
		else
			BOOT_Type="-Legacy"
			GESHI_Type="Legacy"
		fi
	fi
	case "${BOOT_Type}" in
	-Legacy)
		EFI_Boot=0
	;;
	-UEFI)
		EFI_Boot=1
	;;
	esac
	Firmware_SFX="${BOOT_Type}.${Firmware_Type}"
	Firmware_GESHI="${GESHI_Type}.${Firmware_Type}"
	Detail_SFX="${BOOT_Type}.detail"
	CURRENT_Device="x86-64"
	Space_Req=480
;;
*)
	CURRENT_Device="$(jsonfilter -e '@.model.id' < /etc/board.json | tr ',' '_')"
	Firmware_SFX=".${Firmware_Type}"
	Firmware_GESHI=".${Firmware_Type}"
	[[ -z ${Firmware_SFX} ]] && Firmware_SFX=".${Firmware_Type}"
	Detail_SFX=".detail"
	Space_Req=0
esac
CURRENT_Ver="${CURRENT_Version}${BOOT_Type}"
cd /etc
clear && echo "Openwrt-AutoUpdate Script ${Version}"
if [[ -z "${Input_Option}" ]];then
	Upgrade_Options="-q" && TIME && echo "执行: 保留配置更新固件[静默模式]"
else
	case ${Input_Option} in
	-n | -f | -u)
		case ${Input_Option} in
		-n)
			TIME && echo "执行: 更新固件(不保留配置)"
			Upgrade_Options="-n"
		;;
		-f)
			Force_Update=1
			Upgrade_Options="-q"
			TIME && echo "执行: 强制更新固件(保留配置)"
		;;
		-u)
			AutoUpdate_Mode=1
			Upgrade_Options="-q"
		;;
		esac
	;;
	-c)
		if [[ ! -z "${Input_Other}" ]];then
			sed -i "s?${Github}?${Input_Other}?g" /etc/openwrt_info > /dev/null 2>&1
			echo -e "\nGithub 地址已更换为: ${Input_Other}"
			unset Input_Other
		else
			Shell_Helper
		fi
		exit
	;;
	-l | -L)
		List_Info
	;;
	-d)
		rm -f /tmp/Downloads/* /tmp/Github_Tags
		TIME && echo "固件下载缓存清理完成!"
		sleep 1
		exit
	;;
	-h | -H | --help)
		Shell_Helper
	;;
	-b)
		[[ -z "${Input_Other}" ]] && Shell_Helper
		case "${Input_Other}" in
		UEFI | Legacy)
			echo "${Input_Other}" > openwrt_boot
			sed -i '/openwrt_boot/d' /etc/sysupgrade.conf
			echo -e "\n/etc/openwrt_boot" >> /etc/sysupgrade.conf
			TIME && echo "固件引导方式已指定为: ${Input_Other}!"
		;;
		*)
			echo -e "\n错误的参数: [${Input_Other}],当前支持的选项: [UEFI/Legacy] !"
		;;
		esac
		exit
	;;
	*)
		echo -e "\nERROR INPUT: [$*]"
		Shell_Helper
	;;
	esac
fi
if [[ ! "${Force_Update}" == "1" ]];then
	grep "curl" /tmp/Package_list > /dev/null 2>&1
	if [[ ! $? -ne 0 ]];then
		Google_Check=$(curl -I -s --connect-timeout 8 google.com -w %{http_code} | tail -n1)
		if [ ! "$Google_Check" == 301 ];then
			TIME && echo "梯子翻墙失败,转换成[ FastGit镜像加速 ]下载!"
			PROXY_URL="https://download.fastgit.org"
		else
			TIME && echo "梯子翻墙成功,您可以愉快的玩耍了!"
		fi
	fi
	if [[ "${TMP_Available}" -lt "${Space_Req}" ]];then
		TIME && echo "/tmp 空间不足: [${Space_Req}M],无法执行更新!"
		exit
	fi
fi
Install_Pkg wget
if [[ -z "${CURRENT_Version}" ]];then
	TIME && echo "警告: 当前固件版本获取失败!"
	CURRENT_Version="未知"
fi
if [[ -z "${CURRENT_Device}" ]];then
	[[ "${Force_Update}" == "1" ]] && exit
	TIME && echo "警告: 当前设备名称获取失败,使用预设名称[$DEFAULT_Device]"
	CURRENT_Device="${DEFAULT_Device}"
fi
TIME && echo "正在检查版本更新..."
wget -q ${Github_Tags} -O - > /tmp/Github_Tags
if [[ ! "$?" == 0 ]];then
	TIME && echo "检查更新失败,请稍后重试!"
	exit
fi
TIME && echo "正在获取云端固件版本..."
GET_Firmware="$(cat /tmp/Github_Tags | egrep -o "${Firmware_COMP1}-${Firmware_COMP2}-${DEFAULT_Device}-[a-zA-Z0-9_-]+.*?[0-9]+${Firmware_SFX}" | awk 'END {print}')"
GET_Version="$(echo ${GET_Firmware} | egrep -o "${Firmware_COMP2}-${DEFAULT_Device}-[a-zA-Z0-9_-]+.*?[0-9]+${BOOT_Type}")"
if [[ -z "${GET_Firmware}" ]] || [[ -z "${GET_Version}" ]];then
	TIME && echo "云端固件版本获取失败!"
	exit
fi
Firmware_Info="$(echo ${GET_Firmware} | egrep -o "${Firmware_COMP1}-${Firmware_COMP2}-${DEFAULT_Device}-[a-zA-Z0-9_-]+.*?[0-9]+")"
Firmware="${GET_Firmware}"
Firmware_Detail="${Firmware_Info}${Detail_SFX}"
echo -e "\n固件作者: ${Author}"
echo "设备名称: ${CURRENT_Device}"
echo "固件格式: ${Firmware_GESHI}"
echo -e "\n当前固件版本: ${CURRENT_Ver}"
echo "云端固件版本: ${GET_Version}"
if [[ ! ${Force_Update} == 1 ]];then
	if [[ ${CURRENT_Version} -eq ${GET_Version} ]];then
		[[ "${AutoUpdate_Mode}" == "1" ]] && exit
		TIME && read -p "当前版本和云端最新版本一致，是否还要重新安装固件?[Y/n]:" Choose
		if [[ "${Choose}" == Y ]] || [[ "${Choose}" == y ]];then
			TIME && echo "开始重新安装固件..."
		else
			TIME && echo "已取消重新安装固件,即将退出程序..."
			sleep 2
			exit
		fi
	fi
	if [[ ${CURRENT_Version} -lt ${GET_Version} ]];then
		[[ "${AutoUpdate_Mode}" == "1" ]] && exit
		TIME && read -p "当前版本高于云端最新版,是否使用云端版本覆盖现有固件?[Y/n]:" Choose
		if [[ "${Choose}" == Y ]] || [[ "${Choose}" == y ]];then
			TIME && echo "开始使用云端版本覆盖现有固件..."
		else
			TIME && echo "已取消覆盖固件,退出程序..."
			sleep 2
			exit
		fi
	fi
fi
if [ ! -z "${PROXY_URL}" ];then
	Github_Download="https://download.fastgit.org/${Apidz}/releases/download/update_Firmware"
fi
echo -e "\n云端固件名称: ${Firmware}"
echo "固件下载地址: ${Github_Download}"
echo "固件保存位置: /tmp/Downloads"
[ ! -d "/tmp/Downloads" ] && mkdir -p /tmp/Downloads
rm -f /tmp/Downloads/*
TIME && echo "正在下载固件,请耐心等待..."
cd /tmp/Downloads
wget -c "${Github_Download}/${Firmware}" -O ${Firmware}
if [[ ! "$?" == 0 ]];then
	TIME && echo "固件下载失败,请检查网络后重试!"
	exit
fi
TIME && echo "固件下载成功!"
TIME && echo "正在下载云端的MD5和SHA256,请耐心等待..."
wget -c ${Github_Download}/${Firmware_Detail} -O ${Firmware_Detail}
if [[ ! "$?" == 0 ]];then
	TIME && echo "MD5和SHA256下载失败,请检查网络后重试!"
	exit
fi
GET_MD5=$(awk -F '[ :]' '/MD5/ {print $2;exit}' ${Firmware_Detail})
CURRENT_MD5=$(md5sum ${Firmware} | cut -d ' ' -f1)
echo -e "\n本地MD5：${CURRENT_MD5}"
echo "云端MD5：${GET_MD5}"
if [[ -z "${GET_MD5}" ]] || [[ -z "${CURRENT_MD5}" ]];then
	TIME && echo "MD5 获取失败!"
	exit
fi
if [[ ! "${GET_MD5}" == "${CURRENT_MD5}" ]];then
	TIME && echo "MD5 对比失败,请检查网络后重试!"
	exit
else
	TIME && echo "MD5 对比成功!"
fi
GET_SHA256=$(awk -F '[ :]' '/SHA256/ {print $2;exit}' ${Firmware_Detail})
CURRENT_SHA256=$(sha256sum ${Firmware} | cut -d ' ' -f1)
echo -e "\n本地SHA256：${CURRENT_SHA256}"
echo "云端SHA256：${GET_SHA256}"
if [[ "${GET_SHA256}" == "${CURRENT_SHA256}" ]];then
	TIME && echo "SHA256 对比成功!"
else
	TIME && echo "SHA256 对比失败!"
	exit
fi
if [[ ${Compressed_x86} == 1 ]];then
	TIME && echo "检测到固件为[ .gz ]压缩格式,开始解压固件..."
	Install_Pkg gzip
	gzip -dk ${Firmware} > /dev/null 2>&1
	Firmware="${Firmware_Info}${BOOT_Type}.img"
	if [ -f "${Firmware}" ];then
		TIME && echo "解压成功,固件名称: ${Firmware}"
	else
		TIME && echo "固件解压失败!"
		exit
	fi
fi
TIME && echo -e "一切准备就绪,3秒后开始更新固件..."
sleep 3
TIME && echo "正在更新固件,期间请耐心等待..."
sysupgrade ${Upgrade_Options} ${Firmware}
if [[ $? -ne 0 ]];then
	TIME && echo "固件刷写失败,请尝试手动下载更新固件!"
	exit
fi
