#!/bin/sh

# Bold / Non-bold
BOLD="\033[1m"
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[1;34m"
#echo -e "\033[0;32mCOLOR_GREEN\t\033[1;32mCOLOR_LIGHT_GREEN"
OFF="\033[m"

# Repository location
REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
GIT_DIR="${REPO}"

git_update()
{
    cd ${REPO}
    echo "${GREEN}[GIT]${OFF}: Updating local data to latest version"

    echo "${BLUE}[GIT]${OFF}: Updating to latest PRECISION-M3800-OSX git master"
    git pull

    echo "${BLUE}[GIT]${OFF}: Initializing Laptop-DSDT-Patch & ssdtPRgen"
    git submodule update --init --recursive

    echo "${BLUE}[GIT]${OFF}: Updating Laptop-DSDT-Patch & ssdtPRgen"
    git submodule foreach git pull origin master
}

decompile_dsdt()
{
    echo "${GREEN}[DSDT]${OFF}: Decompiling DSDT / SSDT in ./DSDT/raw"
    cd "${REPO}"

    ./tools/iasl -w1 -da -dl ./DSDT/raw/DSDT.aml ./DSDT/raw/SSDT-*.aml &> ./logs/dsdt_decompile.log
    echo "${BLUE}[DSDT]${OFF}: Log created in ./logs/dsdt_decompile.log"
    rm ./DSDT/decompiled/* 2&>/dev/null
    cp ./DSDT/raw/DSDT.dsl ./DSDT/decompiled/
    cp ./DSDT/raw/SSDT-1[0235].dsl ./DSDT/decompiled/
}

patch_dsdt()
{
    echo "${GREEN}[DSDT]${OFF}: Patching DSDT / SSDT"

    echo "${BLUE}[DSDT]${OFF}: Patching DSDT in ./DSDT/decompiled"

    echo "${BOLD}[syn] Fix PARSEOP_ZERO Error${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/syntax/fix_PARSEOP_ZERO.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}[syn] Fix ADBG Error${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/syntax/fix_ADBG.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}[usb] 7-series/8-series USB${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/usb/usb_7-series.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}[bat] Acer Aspire E1-571${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/battery/battery_Acer-Aspire-E1-571.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}[sys] IRQ Fix${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_IRQ.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}[sys] SMBus Fix${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_SMBUS.txt ./DSDT/decompiled/DSDT.dsl

    #echo "${BOLD}[sys] HPET Fix${OFF}" # (No HPETs available..), Check if boot / wakeup works
    #./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_HPET.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}[sys] OS Check Fix${OFF}"
    #./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_OSYS.txt ./DSDT/decompiled/DSDT.dsl
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/system_OSYS.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}[sys] AC Adapter Fix${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_ADP1.txt ./DSDT/decompiled/DSDT.dsl
    #./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/system_AC.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}[sys] Add MCHC${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_MCHC.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}[sys] Fix _WAK Arg0 v2${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_WAK2.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}[sys] Add IMEI${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_IMEI.txt ./DSDT/decompiled/DSDT.dsl

    #echo "${BOLD}[sys] Fix PNOT/PPNT${OFF}"
    #./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_PNOT.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}[sys] Fix Non-zero Mutex${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_Mutex.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}[sys] Add Haswell LPC${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/misc/misc_Haswell-LPC.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}Audio Layout${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/audio_HDEF-layout1.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}Rename B0D3 to HDAU${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/audio_B0D3_HDAU.txt ./DSDT/decompiled/DSDT.dsl

    echo "${BOLD}Remove GLAN device${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/remove_glan.txt ./DSDT/decompiled/DSDT.dsl

    ########################
    # SSDT-10 Patches
    ########################

    echo "${BLUE}[SSDT-10]${OFF}: Patching SSDT-10 in ./DSDT/decompiled"

    echo "${BOLD}_BST package size${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/SSDT-10.dsl ./DSDT/patches/_BST-package-size.txt ./DSDT/decompiled/SSDT-10.dsl

    echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/SSDT-10.dsl ./externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt ./DSDT/decompiled/SSDT-10.dsl

    ########################
    # SSDT-12 Patches
    ########################

    echo "${BLUE}[SSDT-12]${OFF}: Patching SSDT-12 in ./DSDT/decompiled"

    echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/SSDT-12.dsl ./externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt ./DSDT/decompiled/SSDT-12.dsl

    echo "${BOLD}Haswell HD4400/HD4600/HD5000 (Yosemite - Modified)${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/SSDT-12.dsl ./DSDT/patches/graphics_Intel_HD4600.txt ./DSDT/decompiled/SSDT-12.dsl

    echo "${BOLD}[gfx] Brightness fix (Haswell)${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/SSDT-12.dsl ./externals/Laptop-DSDT-Patch/graphics/graphics_PNLF_haswell.txt ./DSDT/decompiled/SSDT-12.dsl

    echo "${BOLD}Rename B0D3 to HDAU${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/SSDT-12.dsl ./DSDT/patches/audio_B0D3_HDAU.txt ./DSDT/decompiled/SSDT-12.dsl

    echo "${BOLD}Insert HDAU device${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/SSDT-12.dsl ./DSDT/patches/audio_Intel_HD4600.txt ./DSDT/decompiled/SSDT-12.dsl

    ########################
    # SSDT-13 Patches
    ########################

    echo "${BLUE}[SSDT-13]${OFF}: Patching SSDT-13 in ./DSDT/decompiled"

    echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/SSDT-13.dsl ./externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt ./DSDT/decompiled/SSDT-13.dsl

    ########################
    # SSDT-15 Patches
    ########################

    echo "${BLUE}[SSDT-15]${OFF}: Patching SSDT-15 in ./DSDT/decompiled"

    echo "${BOLD}Remove invalid operands${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/SSDT-15.dsl ./DSDT/patches/WMMX-invalid-operands.txt ./DSDT/decompiled/SSDT-15.dsl

    echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/SSDT-15.dsl ./externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt ./DSDT/decompiled/SSDT-15.dsl

    echo "${BOLD}Disable Nvidia card (Non-operational in OS X)${OFF}"
    ./tools/patchmatic ./DSDT/decompiled/SSDT-15.dsl ./DSDT/patches/graphics_Disable_Nvidia.txt ./DSDT/decompiled/SSDT-15.dsl
    }

compile_dsdt()
{
    echo "${GREEN}[DSDT]${OFF}: Compiling DSDT / SSDT in ./DSDT/compiled"
    cd "${REPO}"

    rm ./DSDT/compiled/*

    echo "${BLUE}[SSDT]${OFF}: Copying untouched original SSDTs to ./DSDT/compiled"
    cp ./DSDT/raw/SSDT-0.aml ./DSDT/compiled
    cp ./DSDT/raw/SSDT-1.aml ./DSDT/compiled
    cp ./DSDT/raw/SSDT-2.aml ./DSDT/compiled
    cp ./DSDT/raw/SSDT-3.aml ./DSDT/compiled
    cp ./DSDT/raw/SSDT-7.aml ./DSDT/compiled
    cp ./DSDT/raw/SSDT-8.aml ./DSDT/compiled
    cp ./DSDT/raw/SSDT-9.aml ./DSDT/compiled
    cp ./DSDT/raw/SSDT-11.aml ./DSDT/compiled
    cp ./DSDT/raw/SSDT-14.aml ./DSDT/compiled

    echo "${BLUE}[DSDT]${OFF}: Compiling DSDT to ./DSDT/compiled"
    ./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/DSDT.aml -I ./DSDT/decompiled/ ./DSDT/decompiled/DSDT.dsl

    echo "${BLUE}[SSDT-10]${OFF}: Compiling SSDT-10 to ./DSDT/compiled"
    ./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/SSDT-10.aml -I ./DSDT/decompiled/ ./DSDT/decompiled/SSDT-10.dsl

    echo "${BLUE}[SSDT-12]${OFF}: Compiling SSDT-12 to ./DSDT/compiled"
    ./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/SSDT-12.aml -I ./DSDT/decompiled/ ./DSDT/decompiled/SSDT-12.dsl

    echo "${BLUE}[SSDT-13]${OFF}: Compiling SSDT-13 to ./DSDT/compiled"
    ./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/SSDT-13.aml -I ./DSDT/decompiled/ ./DSDT/decompiled/SSDT-13.dsl

    echo "${BLUE}[SSDT-15]${OFF}: Compiling SSDT-15 to ./DSDT/compiled"
    ./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/SSDT-15.aml -I ./DSDT/decompiled/ ./DSDT/decompiled/SSDT-15.dsl

    # Additional custom SSDT
    # ssdtPRgen (P-states / C-states)
    echo "${BLUE}[PRgen]${OFF}: Compiling ssdtPRgen to ./DSDT/compiled"

    if [[ `sysctl machdep.cpu.brand_string` == *"i7-4702HQ"* ]]
    then
    echo "${BLUE}[PRgen]${OFF}: Intel ${BOLD}i7-4702HQ${OFF} processor found"
    ./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/SSDT-pr.aml ./DSDT/custom/SSDT-pr-i7-4702HQ.dsl
    fi

    if [[ `sysctl machdep.cpu.brand_string` == *"i7-4712HQ"* ]]
    then
    echo "${BLUE}[PRgen]${OFF}: Intel ${BOLD}i7-4712HQ${OFF} processor found"
    ./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/SSDT-pr.aml ./DSDT/custom/SSDT-pr-i7-4712HQ.dsl
    fi

    # Rehabman NullEthernet.kext
    echo "${BLUE}[RMNE]${OFF}: Compiling SSDT-rmne to ./DSDT/compiled"
    ./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/SSDT-rmne.aml ./DSDT/custom/SSDT-rmne.dsl
}

patch_iokit()
{
    iokit_md5=$(md5 -q "/System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit")

    echo "${GREEN}[IOKit]${OFF}: Patching IOKit for maximum pixel clock"
    echo "${BLUE}[IOKit]${OFF}: Current IOKit md5 is ${BOLD}${iokit_md5}${OFF}"

    case $iokit_md5 in
    "2a8cbc2f6616d3f7a5e499bd2d5593ab")
    echo "         --> Yosemite 10.10.1 IOKit (${GREEN}unpatched${OFF})"
    sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
    sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
    echo "         Patched"
    ;;
    "a94dc8e1b6bb6491e5f610f0a3caf960")
    echo "         --> Yosemite 10.10.2 IOKit (${GREEN}unpatched${OFF})"
    sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
    sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
    echo "         Patched"
    ;;
    "29d7632362b2fa4993156717671a5642")
    echo "         --> Yosemite 10.10.3 / 10.10.4 IOKit (${GREEN}unpatched${OFF})"
    sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
    sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
    echo "         Patched"
    ;;
    "15f9046ff25c807b7c76db8cdaf6ae4c")
    echo "         --> El Capitan 10.11 Beta 1 IOKit (${GREEN}unpatched${OFF})"
    sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
    sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
    echo "         Patched"
    ;;
    "16e1320076417596176c919009f4b088")
    echo "         --> El Capitan 10.11 Beta 2 IOKit (${GREEN}unpatched${OFF})"
    sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
    sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
    echo "         Patched"
    ;;
    "8756e20f979c9e74c80f07b452ebfadd")
    echo "         --> Yosemite 10.10.1 IOKit (${RED}patched, not signed${OFF})"
    ;;
    "20849598dcfa1e8c59038d28e0ab5fd5")
    echo "         --> Yosemite 10.10.2 IOKit (${RED}patched, not signed${OFF})"
    ;;
    "4bd81492fd13e905ef10719ef391e8a0")
    echo "         --> Yosemite 10.10.3 / 10.10.4 IOKit (${RED}patched, not signed${OFF})"
    ;;
    "1ab7c0ec047d11f6b40798b6f0107c0c")
    echo "         --> El Capitan 10.11 Beta 1 IOKit (${RED}patched, not signed${OFF})"
    ;;
    "080b614971777a0b7022f0c19ba58f9b")
    echo "         --> El Capitan 10.11 Beta 2 IOKit (${RED}patched, not signed${OFF})"
    ;;
    "f834136d72126cc9479604879270d24f")
    echo "         --> Yosemite 10.10.1 IOKit (${RED}patched${OFF})"
    echo "         IOKit is already patched, no action taken."
    ;;
    "9f99c861294afc3d643987782ce45e4f")
    echo "         --> Yosemite 10.10.2 IOKit (${RED}patched${OFF})"
    echo "         IOKit is already patched, no action taken."
    ;;
    "a045c1ac523fece1f1b083b2c5ee842c"|"4c99100b36f37df4bdcc5dc4cd2b8237")
    echo "         --> Yosemite 10.10.3 / 10.10.4 IOKit (${RED}patched${OFF})"
    echo "         IOKit is already patched, no action taken."
    ;;
    "e96a04420555b71bb0933e26773575bc")
    echo "         --> El Capitan 10.11 Beta 1 IOKit (${RED}patched${OFF})"
    echo "         IOKit is already patched, no action taken."
    ;;
    "f0b2d73ac13c9211857af8707db9676d")
    echo "         --> El Capitan 10.11 Beta 1 IOKit (${RED}patched${OFF})"
    echo "         IOKit is already patched, no action taken."
    ;;
    *)
    echo "         --> Unknown IOKit version (${RED}no action taken${OFF})"
    ;;
    esac
}

patch_hda()
{
    echo "${GREEN}[HDA]${OFF}: Creating AppleHDA injection kernel extension for ${BOLD}ALC668${OFF}"
    cd "${REPO}"

    plist=./audio/AppleHDA_ALC668.kext/Contents/Info.plist

    echo "       --> ${BOLD}Creating AppleHDA_ALC668 file layout${OFF}"
    rm -R ./audio/AppleHDA_ALC668.kext 2&>/dev/null

    cp -R /System/Library/Extensions/AppleHDA.kext ./audio/AppleHDA_ALC668.kext
    rm -R ./audio/AppleHDA_ALC668.kext/Contents/Resources/*
    rm -R ./audio/AppleHDA_ALC668.kext/Contents/PlugIns
    rm -R ./audio/AppleHDA_ALC668.kext/Contents/_CodeSignature
    rm -R ./audio/AppleHDA_ALC668.kext/Contents/MacOS/AppleHDA
    rm ./audio/AppleHDA_ALC668.kext/Contents/version.plist
    ln -s /System/Library/Extensions/AppleHDA.kext/Contents/MacOS/AppleHDA ./audio/AppleHDA_ALC668.kext/Contents/MacOS/AppleHDA

    echo "       --> ${BOLD}Copying AppleHDA_ALC668 audio platform & layouts${OFF}"
    cp ./audio/*.zlib ./audio/AppleHDA_ALC668.kext/Contents/Resources/

    echo "       --> ${BOLD}Configuring AppleHDA_ALC668 Info.plist${OFF}"
    replace=`/usr/libexec/plistbuddy -c "Print :NSHumanReadableCopyright" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
    /usr/libexec/plistbuddy -c "Set :NSHumanReadableCopyright '$replace'" $plist
    replace=`/usr/libexec/plistbuddy -c "Print :CFBundleGetInfoString" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
    /usr/libexec/plistbuddy -c "Set :CFBundleGetInfoString '$replace'" $plist
    replace=`/usr/libexec/plistbuddy -c "Print :CFBundleVersion" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
    /usr/libexec/plistbuddy -c "Set :CFBundleVersion '$replace'" $plist
    replace=`/usr/libexec/plistbuddy -c "Print :CFBundleShortVersionString" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
    /usr/libexec/plistbuddy -c "Set :CFBundleShortVersionString '$replace'" $plist
    /usr/libexec/plistbuddy -c "Add ':HardwareConfigDriver_Temp' dict" $plist
    /usr/libexec/plistbuddy -c "Merge /System/Library/Extensions/AppleHDA.kext/Contents/PlugIns/AppleHDAHardwareConfigDriver.kext/Contents/Info.plist ':HardwareConfigDriver_Temp'" $plist
    /usr/libexec/plistbuddy -c "Copy ':HardwareConfigDriver_Temp:IOKitPersonalities:HDA Hardware Config Resource' ':IOKitPersonalities:HDA Hardware Config Resource'" $plist
    /usr/libexec/plistbuddy -c "Delete ':HardwareConfigDriver_Temp'" $plist
    /usr/libexec/plistbuddy -c "Delete ':IOKitPersonalities:HDA Hardware Config Resource:HDAConfigDefault'" $plist
    /usr/libexec/plistbuddy -c "Delete ':IOKitPersonalities:HDA Hardware Config Resource:PostConstructionInitialization'" $plist
    /usr/libexec/plistbuddy -c "Add ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' integer" $plist
    /usr/libexec/plistbuddy -c "Set ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' 2000" $plist
    /usr/libexec/plistbuddy -c "Merge ./audio/ahhcd.plist ':IOKitPersonalities:HDA Hardware Config Resource'" $plist

    echo "       --> ${BOLD}Created AppleHDA_ALC668.kext${OFF}"
    sudo cp -r ./audio/AppleHDA_ALC668.kext /Library/Extensions
    echo "       --> ${BOLD}Installed AppleHDA_ALC668.kext to /Library/Extensions${OFF}"
    sudo cp -r ./audio/CodecCommander.kext /Library/Extensions
    echo "       --> ${BOLD}Installed CodecCommander.kext to /Library/Extensions${OFF}"
}

RETVAL=0

case "$1" in
	--update)
		git_update
		RETVAL=1
		;;
	--decompile-dsdt)
		decompile_dsdt
		RETVAL=1
		;;
	--compile-dsdt)
		compile_dsdt
		RETVAL=1
		;;
	--patch-dsdt)
		patch_dsdt
		RETVAL=1
		;;
	--patch-iokit)
		patch_iokit
		RETVAL=1
		;;
	--patch-hda)
		patch_hda
		RETVAL=1
		;;
	*)
		echo "${BOLD}Dell Precision M3800${OFF} - Yosemite 10.10.2 (14C109)"
		echo "https://github.com/AustinSMU/PRECISION-M3800-OSX"
		echo
		echo "\t${BOLD}--update${OFF}: Update to latest git version (including externals)"
		echo "\t${BOLD}--decompile-dsdt${OFF}: Decompile DSDT files in ./DSDT/raw"
		echo "\t${BOLD}--patch-dsdt${OFF}: Patch DSDT files in ./DSDT/decompiled"
		echo "\t${BOLD}--compile-dsdt${OFF}: Compile DSDT files to ./DSDT/compiled"
		echo "\t${BOLD}--patch-iokit${OFF}: Patch maximum pixel clock in IOKit"
		echo "\t${BOLD}--patch-hda${OFF}: Create AppleHDA injector kernel extension"
		echo
		echo "Credits:"
		echo "${BLUE}Laptop-DSDT${OFF}: https://github.com/RehabMan/Laptop-DSDT-Patch"
		echo "${BLUE}ssdtPRgen${OFF}: https://github.com/Piker-Alpha/ssdtPRGen.sh"
		echo "${BLUE}AppleHDA ALC668${OFF}: https://github.com/vbourachot/Dell-XPS13-9333-DSDT-Patch/"
		echo
		RETVAL=1
	    ;;
esac

exit $RETVAL
