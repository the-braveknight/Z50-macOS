#!/bin/bash

hda_resources=Resources_CX20751

EFI=$(macos-tools/mount_efi.sh)

function downloadTools() {
    echo "Downloading macos-tools..."
    rm -Rf macos-tools && git clone https://github.com/the-braveknight/macos-tools --quiet
}

function downloadRequirements() {
    macos-tools/download.sh settings.plist
}

function installPS2Kext() {
    if [[ "$(macos-tools/trackpad_model.sh)" == *"SYN"* ]]; then
        macos-tools/install_kext.sh $(macos-tools/find_kext.sh VoodooPS2Controller.kext)
    else
        macos-tools/install_kext.sh Kexts/ApplePS2SmartTouchPad.kext
    fi
}

function installHDAInjector() {
    # Create XML/Layout files injector; PinConfigs are injected with CodecCommander.kext & SSDT-HDEF
    macos-tools/create_xmlinjector.sh $hda_resources
    macos-tools/install_kext.sh AppleHDAInjector.kext
}

function installBacklightInjector() {
    macos-tools/install_kext.sh Kexts/AppleBacklightInjector.kext
}

function installKexts() {
    installHDAInjector
    installPS2Kext
    installBacklightInjector

    macos-tools/install_downloads.sh settings.plist
}

function installConfig() {
    macos-tools/install_config.sh config.plist
}

function updateConfig() {
    macos-tools/update_config.sh config.plist
}

function compileACPI() {
    rm -f Build/*.aml
    macos-tools/compile_acpi.sh Downloads/Hotpatch/*.dsl
    if [[ "$1" == "-g50" ]]; then
        macos-tools/compile_acpi.sh Hotpatch/SSDT-G50.dsl
    else
        macos-tools/compile_acpi.sh Hotpatch/SSDT-Z50.dsl
    fi
}

function installACPI() {
    rm -f $EFI/EFI/Clover/ACPI/patched/*.aml
    macos-tools/install_acpi.sh Build/*.aml
}

if [[ ! -d macos-tools ]]; then
    downloadTools
fi

case "$1" in
    --download-tools)
        downloadTools
        ;;
    --download-requirements)
        downloadRequirements
        ;;
    --install-kexts)
        installKexts
        ;;
    --install-config)
        installConfig
        ;;
    --update-config)
        updateConfig
        ;;
    --compile-acpi)
        compileACPI "$2"
        ;;
    --install-acpi)
        installACPI
        ;;
esac
