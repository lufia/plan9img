#!/usr/bin/env bash
#qemu-img create $disk 10G

set -e

usage()
{
	echo usage: $(basename $0) [[-a disk] ...] [[-A disk] ...] [-d iso] [-i 10.0.2.15] [-l port] [-m size] [-u root] [-nsv] -- [qemu options] >&2
	exit 2
}

disks=(disk0.raw)
ncpu=2
mem=1G
execcmd=exec
u9fs=
tftp=

cdrom=
ether=e1000
ipnet=10.0.2.0/24
ports=()
options=()
mac=52:54:00:12:34:56

while getopts :a:A:d:i:l:m:u:nsv OPT
do
	case $OPT in
	a)	disks+=("$OPTARG")
		;;
	A)	disks=("$OPTARG")
		;;
	i)	ipnet="$OPTARG"
		;;
	l)	ports+=("hostfwd=tcp::$OPTARG-:$OPTARG")
		;;
	m)	mem="$OPTARG"
		;;
	n)	execcmd=echo
		;;
	d)	iso="$OPTARG"
		cdrom="-drive file=$iso,index=2,media=cdrom -boot order=d"
		;;
	s)	ports+=("hostfwd=tcp::567-:567")
		ports+=("hostfwd=tcp::17010-:17010")
		;;
	u)	u9fs="guestfwd=tcp:10.0.2.1:564-cmd:u9fs -a none -u $USER $OPTARG"
		tftp="tftp=$OPTARG"
		;;
	v)	ether=virtio-net-pci
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
	i=$((i+1))
done
options+=(-device "$ether,netdev=ether0,mac=$mac")
net="$ipnet"
if [[ -n $u9fs ]]
then
	net="$ipnet,$u9fs,$tftp"
fi
if (( ${#ports[@]} > 0 ))
then
	hostfwd="$(IFS=,; echo "${ports[*]}")"
	options+=(-netdev "user,id=ether0,net=$net,$hostfwd")
else
	options+=(-netdev "user,id=ether0,net=$net")
fi

case $(uname) in
Darwin)
	options+=(-machine type=pc,accel=hvf) ;;
Linux)
	options+=(-machine type=pc,accel=kvm) ;;
esac
$execcmd qemu-system-x86_64 -m $mem "${options[@]}" $cdrom "$@"
