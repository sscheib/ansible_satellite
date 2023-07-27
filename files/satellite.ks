%pre    
#Dynamic

if [ -e /dev/sda ]; then
  dev_device="sda" 
elif [ -e /dev/vda ]; then
  dev_device="vda" 
fi

cat <<EOF > /tmp/diskpart.cfg
  zerombr
  # Partition clearing information
  bootloader --location=mbr --append="splash=quiet"
  clearpart --all --initlabel --drives="${dev_device}" --disklabel=gpt
  # as we have gpt, we need a separate biosboot partition
  part biosboot --fstype=biosboot --size=1
EOF

cat <<EOF >> /tmp/diskpart.cfg
  # Disk partitioning information with xfs
  part /boot --fstype=xfs --size=4096
  part pv.0 --grow --ondisk="${dev_device}"
  volgroup vg_system pv.0
  logvol /               --fstype xfs    --name=lv_root           --vgname=vg_system --size=10240
  logvol /var            --fstype xfs    --name=lv_var            --vgname=vg_system --size=8192   --fsoptions="nodev,nosuid"
  logvol /var/lib/qpidd  --fstype xfs    --name=lv_var_lib_qpidd  --vgname=vg_system --size=3072
  logvol /var/lib/pgsql  --fstype xfs    --name=lv_var_lib_pgsql  --vgname=vg_system --size=24576
  logvol /var/lib/pulp   --fstype xfs    --name=lv_var_lib_pulp   --vgname=vg_system --size=614400
  logvol /var/log        --fstype xfs    --name=lv_var_log        --vgname=vg_system --size=5120   --fsoptions="nodev,nosuid,noexec"
  logvol /var/log/audit  --fstype xfs    --name=lv_var_log_audit  --vgname=vg_system --size=2048   --fsoptions="nodev,nosuid,noexec"
  logvol /var/tmp        --fstype xfs    --name=lv_var_tmp        --vgname=vg_system --size=2048   --fsoptions="nodev,nosuid"
  logvol /usr            --fstype xfs    --name=lv_usr            --vgname=vg_system --size=8192   --fsoptions="nodev"
  logvol /usr/local      --fstype xfs    --name=lv_usr_local      --vgname=vg_system --size=1024   --fsoptions="nodev"
  logvol /openscap       --fstype xfs    --name=lv_openscap       --vgname=vg_system --size=512    --fsoptions="nodev,noexec"
  logvol /home           --fstype xfs    --name=lv_home           --vgname=vg_system --size=1024   --fsoptions="nodev,nosuid"
  logvol /tmp            --fstype xfs    --name=lv_tmp            --vgname=vg_system --size=5120   --fsoptions="nodev,nosuid,noexec"
  logvol /opt            --fstype xfs    --name=lv_opt            --vgname=vg_system --size=4096   --fsoptions="nodev"
  logvol /opt/puppetlabs --fstype xfs    --name=lv_opt_puppetlabs --vgname=vg_system --size=512
  logvol swap            --fstype swap   --name=lv_swap           --vgname=vg_system --size=4096
EOF
%end

cdrom
lang en_US.UTF-8
selinux --enforcing
keyboard de
skipx
services --disabled gpm,sendmail,cups,pcmcia,isdn,rawdevices,hpoj,bluetooth,openibd,avahi-daemon,avahi-dnsconfd,hidd,hplip,pcscd  
network --bootproto dhcp
firewall --service ssh
authselect --useshadow --passalgo=sha512 --kickstart
timezone Europe/Berlin --utc
bootloader --location=mbr --append="splash=quiet" 
%include /tmp/diskpart.cfg
text
shutdown

%packages
  dhclient
  chrony
  rsync
  @Core
  lsof
  net-tools
  sos
%end
