#!/bin/sh

conffile=${0%.sh}".conf"
if [ -f $conffile ]; then
. $conffile
fi

resources=${resources:-all}

action=$1
vhid=${2%@*}
ifname=${2#*@}

syslog_facility="user.notice"
syslog_tag="carp-hast"
maxwait=60
delay=3

logger="/usr/bin/logger -p $syslog_facility -t $syslog_tag"


if [ "$resources" = "all" ]; then
  hastdevs=$(/sbin/hastctl dump | /usr/bin/awk '/^[[:space:]]*resource:[[:space:]]/ {print $2}')
else
  hastdevs="$resources"
fi


#
case "$action" in
  MASTER|BACKUP|INIT)
    $logger "State Changed. I/F: $ifname VHID: $vhid state: $action"
  ;;

  AUTO)
    action=$(/sbin/ifconfig $ifname | /usr/bin/awk '/[[:space:]]*carp:[[:space:]]+([A-Z]+)[[:space:]]vhid[[:space:]]'"$vhid"'[[:space:]]?/ {print $2; exit}' )
    if [ "$action" ]; then
      $logger "State Changed. I/F: $ifname VHID: $vhid state: $action"
    else
      die "carp state not found"
    fi
  ;;

  *)
    die "$action is not yet implemented"
  ;;

esac


reverse_list()
{
  _revlist=
  for _revfile in $*; do
    _revlist="$_revfile $_revlist"
  done
  echo $_revlist
}

die()
{
  $logger "FATAL: "$*
  exit 1
}


# check hastd enabled
if ! /bin/pgrep -q hastd; then
  $logger "hastd not running"
  exit
fi


stop_services()
{
  for service in $( reverse_list $* ); do
    if /usr/sbin/service ${service} onestatus | /usr/bin/grep -q "running as" || /usr/sbin/service ${service} onestatus | /usr/bin/grep -q "server is running" ; then
      /usr/sbin/service ${service} onestop \
        || $logger "Unable to stop service: ${service}."
    fi
  done
}

change_role()
{
  roletype=$1
  shift 1

  for hdev in $*; do
    /sbin/hastctl role $roletype $hdev \
        || $logger "Unable to change role to $roletype for resource: $hdev"
  done
}

# main
case "$action" in
  BACKUP|INIT)
    # stop services
    stop_services $services

    # unmount zfs
    for pool in $zpools; do
      if /sbin/zpool status | /usr/bin/grep -q "pool: $pool" ; then
        /sbin/zpool export -f $pool \
            || $logger "Unable to export zpool: ${pool}."
      fi
    done

    # unmount ufs
    for mdev in $(/sbin/mount -p | /usr/bin/awk '/^\/dev\/hast\// {print $1}'); do
      for hdev in $hastdevs; do
        if [ "$mdev" = "/dev/hast/$hdev" ]; then
          /sbin/umount -f $mdev \
            || $logger "Unable to unmount: ${mdev}."
        fi
      done
    done

    # change role
    if [ "$action" = "BACKUP" ]; then
      roletype="secondary"
    else
      roletype="init"
    fi
    change_role $roletype $resources
    $logger "Change role $roletype completed."
  ;;

  MASTER)
    # stop services
    stop_services $services

    # wait for not running secondary
    for hdev in $hastdevs; do
      for i in $(/usr/bin/jot $maxwait); do
        /bin/pgrep -fq "hastd: ${hdev} \(secondary\)" || break
        sleep 1
      done

      if /bin/pgrep -fq "hastd: ${hdev} \(secondary\)" ; then
        die "Secondary process for resource ${hdev} is still running after $maxwait seconds."
      fi
    done

    # change role primary
    change_role primary $resources
    sleep $delay

    # wait for the /dev/hast/* devices to appear
    for hdev in $hastdevs; do
      for i in $(/usr/bin/jot $maxwait); do
        [ -c /dev/hast/$hdev ] && break
        sleep 1
      done

      if [ ! -c /dev/hast/$hdev ]; then
        die "GEOM provider /dev/hast/$hdev did not appear."
      fi
    done

    # mount zfs
    if [ "$zpools" ]; then
      for pool in $zpools; do
        /sbin/zpool status | /usr/bin/grep -q -E "[[:space:]]*$pool[[:space:]]+ONLINE[[:space:]]" && break;

        /sbin/zpool import -d /dev/hast/ -f -N $pool \
          || die "Unable to import zpool: ${pool}."
      done

      /sbin/zpool scrub $zpools

      for pool in $zpools; do
        for mdev in $(/usr/bin/awk '/^'"$pool"'\// {print $1}' /etc/fstab); do
          $logger "mount $mdev"
          /sbin/mount -p | /usr/bin/grep -q -e "^${mdev}[[:space:]]" && break;

          /sbin/mount ${mdev} \
            || die "Unable to mount: ${mdev}."
        done
      done
    fi

    # mount ufs
    #for mdev in $(/usr/bin/awk '/^\/dev\/hast\// {print $1}' /etc/fstab); do
    for hdev in $hastdevs; do
        #if [ "$mdev" = "/dev/hast/$hdev" ]; then
                  mdev="/dev/hast/$hdev"
          $logger "mount $mdev"
          /sbin/mount -p | /usr/bin/grep -q -e "^${mdev}[[:space:]]" && break;

          /sbin/fsck -y -t ufs ${mdev} \
            || die "Failed to fsck: ${mdev}."

          /sbin/mount ${mdev} /hast/shared/ \
            || die "Unable to mount: ${mdev}."
        #fi
      #done
    done

    # start services
    for service in ${services}; do
      /usr/sbin/service ${service} onestart \
        || $logger "Failed to start service: ${service}."
    done

    $logger "Change role primary completed."
  ;;

esac
