#!/bin/bash
grep -i CONFIG_PACKAGE_luci-app .config | grep  -v \# >Plug-in
sed -i "s/=y//g" Plug-in
sed -i "s/CONFIG_PACKAGE_//g" Plug-in
sed -i '/INCLUDE/d' Plug-in > /dev/null 2>&1
cat -n Plug-in > Plugin
sed -i 's/	luci/、luci/g' Plugin
awk '{print "  " $0}' Plugin > Plug-in
if [[ ${UPLOAD_FIRMWARE} == "true" ]]; then
	echo " 上传固件在github actions: 开启"
else
	echo " 上传固件在github actions: 关闭"
fi
if [[ ${UPLOAD_CONFIG} == "true" ]]; then
	echo " 上传[.config]配置文件: 开启"
else
	echo " 上传[.config]配置文件: 关闭"
fi
if [[ ${UPLOAD_BIN_DIR} == "true" ]]; then
	echo " 上传BIN文件夹(固件+IPK): 开启"
else
	echo " 上传BIN文件夹(固件+IPK): 关闭"
fi
if [[ ${UPLOAD_RELEASE} == "true" ]]; then
	echo " 发布固件: 开启"
else
	echo " 发布固件: 关闭"
fi

if [[ ${SSH_ACTIONS} == "true" ]]; then
	echo " SSH远程连接: 开启"
else
	echo " SSH远程连接: 关闭"
fi

if [[ ${COMP1} == immortalwrt ]]; then
    echo " luci版本：${REPO_Version}"
else
    echo " luci版本：${REPO_BRANCH}"
fi
if [[ ${UPLOAD_RELEASE} == "true" ]]; then
	
    echo
    echo " 编译源码: ${COMP2}"
    echo " 源码链接: ${REPO_URL}"
    echo " 源码分支: ${REPO_BRANCH}"
    echo " 编译机型: ${TARGET_PROFILE}"
    echo " 固件作者: ${Author}"
    echo " 仓库地址: ${GITURL}"
    echo " 启动编号: #${Run_number}（${CanKu}仓库第${Run_number}次启动[${Run_workflow}]工作流程）"
    echo " 编译时间: $(TZ=UTC-8 date "+%Y年%m月%d号.%H时%M分")"
    echo " 您当前使用【${Modelfile}】文件夹编译【${TARGET_PROFILE}】固件"
    echo " 插件版本: ${AutoUpdate_Version}"
	echo " 固件名称: ${Firmware_mz}"
	echo " 固件后缀: ${Firmware_hz}"
	echo " 固件版本: ${Openwrt_Version}"
	echo " 云端路径: ${Github_UP_RELEASE}"
	echo
fi
if [ -n "$(ls -A "${Home}/EXT4" 2>/dev/null)" ]; then
	[ -s EXT4 ] && cat EXT4
fi
echo " 系统空间      类型   总数  已用  可用 使用率"
cd ../ && df -hT $PWD && cd openwrt
echo
if [ -n "$(ls -A "${Home}/Chajianlibiao" 2>/dev/null)" ]; then
	echo
	[ -s CHONGTU ] && cat CHONGTU
fi
if [ -n "$(ls -A "${Home}/Plug-in" 2>/dev/null)" ]; then
	echo
	echo "		已选插件列表"
	[ -s Plug-in ] && cat Plug-in
	echo
fi
rm -rf {CHONGTU,Plug-in,Plugin,Chajianlibiao}
}
