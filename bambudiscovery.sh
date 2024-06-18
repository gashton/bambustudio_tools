#!/bin/bash
# vim:ts=4:sw=4:sts=4:et:ai:fdm=marker
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
# Additions for portability and flexibility with moving settings out of the script and to the named config file
#  - Roy Sigurd Karlsbakk <https://github.com/rkarlsba>
#

CONFIG_FILE="$(dirname "$0")/config.env"
DEBUG=0

# Very verbose and clear and all, can be shorted down, but I like it when it's clear (RSK)
case $( uname -s ) in
    Linux)
        USE_ANSI_COLOURS=1
        BAMBU_STUDIO_PID=$( pgrep bambu-studio )
        ;;
    Darwin)
        BAMBU_STUDIO_PID=$( pgrep BambuStudio )
        ;;
    *)
        USE_ANSI_COLOURS=0
        BAMBU_STUDIO_PID=$( pgrep bambu-studio )
        ORCA_SLICER_PID=$( pgrep OrcaSlicer )
        ;;
esac

if [[ $USE_ANSI_COLOURS -gt 0 ]]
then
    please_specify_printer_ip="Please specify your printers IP.\nusage: \e[1m$0\e[0m <PRINTER_IP>"
else
    please_specify_printer_ip="Please specify your printers IP.\nusage: $0 <PRINTER_IP>"
fi

[[ -r "${CONFIG_FILE}" ]] && source "${CONFIG_FILE}"
if [[ -z ${PRINTER_IP} ]]
then
    if [[ ! -z ${1} ]]
    then
        PRINTER_IP=$1
    else
        printf "$please_specify_printer_ip"
        exit 2
    fi
fi
[[ -z "${BAMBU_STUDIO_PID}" -a -z "${ORCA_SLICER_PID}" ]] && echo "Please start BambuStudio" && exit 1

# Tested with openbsd-netcat
[[ -z $(type -p nc) ]] && echo "ERROR: Please install netcat" && exit 2

http_chatter="HTTP/1.1 200 OK\r\n"
http_chatter+="Server: Buildroot/2018.02-rc3 UPnP/1.0 ssdpd/1.8\r\n"
http_chatter+="Server: Buildroot/2018.02-rc3 UPnP/1.0 ssdpd/1.8\r\n"
http_chatter+="Date: $(date)\r\n"
http_chatter+="Location: ${PRINTER_IP}\r\n"
http_chatter+="ST: urn:bambulab-com:device:3dprinter:1\r\n"
http_chatter+="EXT:\r\nUSN: ${PRINTER_USN}\r\n"
http_chatter+="Cache-Control: max-age=1800\r\n"
http_chatter+="DevModel.bambu.com: ${PRINTER_DEV_MODEL}\r\n"
http_chatter+="DevName.bambu.com: ${PRINTER_DEV_NAME}\r\n"
http_chatter+="DevSignal.bambu.com: ${PRINTER_DEV_SIGNAL}\r\n"
http_chatter+="DevConnect.bambu.com: ${PRINTER_DEV_CONNECT}\r\n"
http_chatter+="DevBind.bambu.com: ${PRINTER_DEV_BIND}\r\n"
http_chatter+="\r\n"
http_chatter+="" | nc -u -w0 ${TARGET_IP} 2021

if [[ $DEBUG -gt 0 ]]
then
    printf "$http_chatter"
    exit 0
fi

printf "$http_chatter" | nc -u -w0 ${TARGET_IP} 2021
