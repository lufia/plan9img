#!/usr/bin/env bash
#qemu-img create $disk 10G

set -e

usage()
{
	echo usage: $(basename $0) [[-a disk] ...] [-d iso] [-i 10.0.2.15] [-l port] [-m size] [-sv] -- [qemu options] >&2
	exit 2
}

disks=(disk0.raw)
ncpu=2
mem=1G

cdrom=
ether=e1000
ipnet=10.0.2.0/24
ports=()
options=()

while getopts :a:d:i:l:m:sv OPT
do
	case $OPT in
	a)	disks+=("$OPTARG")
		;;
	i)	ipnet="$OPTARG"
		;;
	l)	ports+=("hostfwd=tcp::$OPTARG-:$OPTARG")
		;;
	m)	mem="$OPTARG"
		;;
	d)	iso="$OPTARG"
		cdrom="-drive file=$iso,index=2,media=cdrom -boot order=d"
		;;
	s)	ports+=("hostfwd=tcp::567-:567")
		ports+=("hostfwd=tcp::17010-:17010")
		;;
	v)	ether=virtio-net-pci
		options+=(-nographic)
		options+=(-device virtio-scsi-pci,id=scsi)
		virtio=enable
		;;
	*)	usage
		;;
	esac
done
shift $((OPTIND - 1))

options+=(-smp $ncpu)
i=0
disk_opt='format=raw,cache=writethrough'
for d in "${disks[@]}"
do
	id="hd$i"

	if [[ $virtio = enable ]]
	then
		options+=(-device scsi-hd,drive=$id)
		options+=(-drive file=$d,$disk_opt,id=$id,if=none,index=$i)
	else
		options+=(-drive file=$d,$disk_opt,id=$id,index=$i)
	fi
	((i++))
done
options+=(-device $ether,netdev=ether0)
if (( ${#ports[@]} > 0 ))
then
	hostfwd="$(IFS=,; echo "${ports[*]}")"
	options+=(-netdev user,id=ether0,net=$ipnet,$hostfwd)
else
	options+=(-netdev user,id=ether0,net=$ipnet)
fi

case $(uname) in
Darwin)
	options+=(-machine type=pc,accel=hvf) ;;
Linux)
	options+=(-machine type=pc,accel=kvm) ;;
esac
echo qemu-system-x86_64 -m $mem ${options[@]} $cdrom "$@"
exec qemu-system-x86_64 -m $mem ${options[@]} $cdrom "$@"
