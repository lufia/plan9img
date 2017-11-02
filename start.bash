#!/usr/bin/env bash

usage()
{
	echo usage: $(basename $0) [-c size] [-dnv] >&2
	exit 1
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
device=
cdrom=
ether=e1000

while getopts :c:dnv OPT
do
	case $OPT in
	c)	size=$OPTARG
		;;
	d)	cdrom="-cdrom $iso -boot d"
		;;
	n)	run() { echo $*; }
		;;
	v)	ether=virtio
		drive="$drive,if=none"
		device='virtio-scsi-pci,id=scsi -device scsi-hd,drive=hd'
		;;
	V)	ether=virtio
		;;
	*)	usage
		;;
	esac
done
shift $((OPTIND - 1))

if [[ $size != 0 ]]
then
	run qemu-img create $disk $size || exit
fi

options="-smp $ncpu"
options="$options -drive $drive"
if [[ -n $device ]]
then
	options="$options -device $device"
fi
options="$options -net nic,model=$ether -net user"

# qemu-system-i386 -machine accel=kvm -m $mem
QEMU="qemu-system-i386 -m $mem $options $cdrom"

run $QEMU "$@"
