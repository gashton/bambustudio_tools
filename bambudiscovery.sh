#!/bin/bash
#
# Send the IP address of your BambuLab printer to port 2021/udp, which BambuStudio is listens on.
#
# Ensure your PC has firewall pot 2021/udp open. This is required as the proper response would usually go to the ephemeral source port that the M-SEARCH ssdp:discover message.
# But we are are blindly sending a response directly to the BambuStudio listening service port (2021/udp).
#
# Temporary solution to BambuStudio not allowing you to manually specify the Printer IP.
#
# Author(s): gashton <https://github.com/gashton>
#
TARGET_IP="127.0.0.1" # IP address of your PC running BambuStudio.
PRINTER_IP=$1 # IP address of your BambuLab Printer
PRINTER_USN="000000000000000" # Printer Serial Number
PRINTER_DEV_MODEL="3DPrinter-X1-Carbon" # Set this to your model.
PRINTER_DEV_NAME="3DP-000-000" # Set this to the device name
PRINTER_DEV_SIGNAL="-44" # Good Signal (Artificial), WiFi icon in BambuStudio will appear green with full-bars.
PRINTER_DEV_CONNECT="lan" # LAN Mode
PRINTER_DEV_BIND="free" # Not bound to a Cloud user-account.
CONFIG_FILE="$(dirname "$0")/config.env"

[[ -r "${CONFIG_FILE}" ]] && source "${CONFIG_FILE}"
[[ -z ${PRINTER_IP} ]] && echo -e "Please specify your printers IP.\nusage: \e[1m$0\e[0m <PRINTER_IP>" && exit 2
[[ -z $(pgrep bambu-studio) ]] && echo "Please start BambuStudio" && exit 1

# Tested with openbsd-netcat
[[ -z $(type -p nc) ]] && echo "ERROR: Please install netcat" && exit 2

echo -e -n "HTTP/1.1 200 OK\r\nServer: Buildroot/2018.02-rc3 UPnP/1.0 ssdpd/1.8\r\nDate: $(date)\r\nLocation: ${PRINTER_IP}\r\nST: urn:bambulab-com:device:3dprinter:1\r\nEXT:\r\nUSN: ${PRINTER_USN}\r\nCache-Control: max-age=1800\r\nDevModel.bambu.com: ${PRINTER_DEV_MODEL}\r\nDevName.bambu.com: ${PRINTER_DEV_NAME}\r\nDevSignal.bambu.com: ${PRINTER_DEV_SIGNAL}\r\nDevConnect.bambu.com: ${PRINTER_DEV_CONNECT}\r\nDevBind.bambu.com: ${PRINTER_DEV_BIND}\r\n\r\n" | nc -u -w0 ${TARGET_IP} 2021
