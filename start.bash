#!/usr/bin/env bash

set -e

usage()
{
	echo usage: $(basename $0) [-c size] [-i 10.0.2.15] [-l port] [-m size] [-dnsv] >&2
	exit 2
}

run()
{
	"$@"
}

iso=plan9.iso
disk=disk.raw
ncpu=2
mem=1G

size=0
drive="file=$disk,format=raw,id=hd,cache=writethrough"
disk=
cdrom=
ether=e1000
ipnet=10.0.2.0/24
ports=()

while getopts :c:i:l:m:dnsv OPT
do
	case $OPT in
	c)	size="$OPTARG"
		;;
	i)	ipnet="$OPTARG"
		;;
	l)	ports+=("hostfwd=tcp::$OPTARG-:$OPTARG")
		;;
	m)	mem="$OPTARG"
		;;
	d)	cdrom="-cdrom $iso -boot d"
		;;
	n)	run() { echo $*; }
		;;
	s)	ports+=("hostfwd=tcp::567-:567")
		ports+=("hostfwd=tcp::17010-:17010")
		;;
	v)	ether=virtio-net-pci
		drive="$drive,if=none"
		disk='virtio-scsi-pci,id=scsi -device scsi-hd,drive=hd'
		;;
	*)	usage
		;;
	esac
done
shift $((OPTIND - 1))

if [[ $size != 0 ]]
then
	run qemu-img create $disk $size
fi

options=()
options+=(-smp $ncpu)
options+=(-drive $drive)
if [[ -n $disk ]]
then
	options+=(-device $disk)
fi
if (( ${#ports[@]} > 0 ))
then
	hostfwd="$(IFS=,; echo "${ports[*]}")"
	options+=(-netdev user,id=ether0,net=$ipnet,$hostfwd)
else
	options+=(-netdev user,id=ether0,net=$ipnet)
fi
options+=(-device $ether,netdev=ether0)

# qemu-system-x86_64 -machine accel=kvm -m $mem
QEMU="qemu-system-x86_64 -m $mem ${options[@]} $cdrom"

run $QEMU "$@"
