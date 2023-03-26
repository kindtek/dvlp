#!/bin/bash
config_file=${1:-$config_file_default}
user_name=${2:-dvl}
cpu_vendor=$(grep -Pom 1 '^vendor_id\s*:\s*\K.*' /proc/cpuinfo)
cpu_arch=$(uname -m)
cpu_arch="${cpu_arch%%_*}"
config_suffix=_wsl-zfs0

linux_version_name=6.3-rc3
# replace first . with _ and then remove the rest of the .'s
linux_version_mask=${linux_version_name/./_}
linux_version_mask=${linux_version_mask//[.-]/}
linux_mask=linux-$linux_version_mask

zfs_version_name=2.1.9
# replace first . with _ and then remove the rest of the .'s
zfs_version_mask=${zfs_version_name/./_}
zfs_version_mask=${zfs_version_mask//[.-]/}
zfs_mask=zfs-$zfs_version_mask


if ! [ -d /home/$user_name ]; then $user_name=/home/dvl; fi
if [ $cpu_vendor = AuthenticAMD ]; then cpu_vendor=amd; fi
if [ $cpu_vendor = GenuineIntel ]; then cpu_vendor=intel; fi

save_name=$linux_mask\_wz0
save_location1=/home/dvl/dvl-works/dvlp/kernels/ubuntu/$cpu_arch/$cpu_vendor/$linux_version_mask/$save_name
save_location2=/home/$user_name/$save_name

# wsl_username=$(wslvar USERNAME) > /dev/null 2> /dev/null
if [ -d /mnt/c/users/$wsl_username ]; then save_location4=/mnt/c/users/$wsl_username/$save_name; fi

cd /home/$user_name/dls 

# try to pick the best .config file and default to the one provided by microsoft
config_file_default=/home/dvl/dvl-works/dvlp/kernels/ubuntu/$cpu_arch/$cpu_vendor/$linux_version_mask/.config$config_suffix
if ! [ -f $config_file_default ]; then config_file_default=/home/dvl/dvl-works/dvlp/kernels/ubuntu/$cpu_arch/generic/$linux_version_mask/.config$config_suffix; fi
if ! [ -f $config_file_default ]; then config_file_default=linux/Microsoft/config-wsl; fi
if ! [ -f ${config_file} ]; then cp -fv $config_file_default $linux_mask/.config; config_file=$config_file_default; else cp -fv ${config_file} linux/.config; fi


printf '\n======= Kernel Build Info =========================================================================\n\n\tCPU Architecture:\t%s\n\n\tCPU Vendor:\t\t%s\n\n\tConfiguration File:\n\t\t%s\n\n\tSave Locations:\n\t\t%s\n\t\t%s\n\t\t%s\n\n===================================================================================================\n' $cpu_arch $cpu_vendor $config_file $save_location1 $save_location2 $save_location4


wget https://github.com/openzfs/zfs/releases/download/zfs-$zfs_version_name/zfs-$zfs_version_name.tar.gz
tar -xvf zfs-$zfs_version_name.tar.gz
mv zfs-$zfs_version_name $zfs_mask

wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$linux_version_name.tar.xz
tar -xvf linux-$linux_version_name.tar.xz
mv linux-$linux_version_name $linux_mask

yes "" | make prepare scripts
cd ../$zfs_mask && sh autogen.sh
sh configure --prefix=/ --libdir=/lib --includedir=/usr/include --datarootdir=/usr/share --enable-linux-builtin=yes --with-linux=/home/$user_name/dls/$linux_mask --with-linux-obj=/home/$user_name/dls/$linux_mask
sh copy-builtin ../$linux_mask
yes "" | make install 

cd ../$linux_mask
sed -i 's/\# CONFIG_ZFS is not set/CONFIG_ZFS=y/g' .config
yes "" | make -j $(expr $(nproc) - 1)
make modules_install

mkdir -pv /home/$user_name/kernels
mkdir -pv /home/dvl/dvl-works/dvlp/kernels/ubuntu/$cpu_arch/$cpu_vendor/$save_name
cp -fv --backup=numbered arch/$cpu_arch/boot/bzImage $save_location1 
cp -fv --backup=numbered arch/$cpu_arch/boot/bzImage $save_location2
cp -fv --backup=numbered .config /home/dvl/dvl-works/dvlp/kernels/ubuntu/$cpu_arch/$cpu_vendor/$linux_version_mask/.config$config_suffix
if ! [ -z $save_location4 ]; then cp -fv --backup=numbered  arch/$cpu_arch/boot/bzImage /mnt/c/users/$wsl_username/$save_name; fi

rm -rf /home/$user_name/dls/zfs-$zfs_version_name
rm /home/$user_name/dls/zfs-$zfs_version_name.tar.gz
rm -rf /home/$user_name/dls/$linux_mask