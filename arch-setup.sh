#!/usr/bin/env bash

timedatectl set-ntp true

DISK=/dev/sda
HOSTNAME=test.change-me.com
LUKS="$(openssl rand -base64 20)"

echo "Save the following information:"
echo ""
echo "################################"
echo "DISK PASSWORD: $LUKS"
echo "################################"
echo ""

sleep 10

echo "Setting up disk(s)..."
wipefs -af $DISK
sgdisk -Zo $DISK
sgdisk -og $DISK
sgdisk -n 1:2048:4095 -c 1:"BIOS Boot Partition" -t 1:ef02 $DISK
sgdisk -n 2:0:+1G -c 2:"Linux boot" -t 2:8300 $DISK
ENDSECTOR=$(sgdisk -E $DISK)
sgdisk -n 3:0:"$ENDSECTOR" -c 3:"System" -t 3:8300 $DISK
sgdisk -p $DISK
mkfs.ext4 -F /dev/sda2

# Setup LUKS encryption for the data partition
echo -n "$LUKS" | cryptsetup --batch-mode --verbose --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat /dev/sda3 -
echo -n "$LUKS" | cryptsetup luksOpen /dev/sda3 luks -

# Create and format system disks
pvcreate /dev/mapper/luks &&
vgcreate vg0 /dev/mapper/luks &&
lvcreate --size 2G vg0 --name swap &&
lvcreate -l +100%FREE vg0 --name root &&
mkfs.ext4 -F /dev/mapper/vg0-root &&
mkswap /dev/mapper/vg0-swap &&
mount /dev/mapper/vg0-root /mnt &&
swapon /dev/mapper/vg0-swap &&
mkdir /mnt/boot &&
mount /dev/sda2 /mnt/boot

# Inform kernel about disk changes
partprobe /dev/sda

echo "Setting up Arch Linux..."
# Pacstrap basic stuff, refreshing keys may be needed on Hetzner so run in just in case
pacman-key --refresh-keys &&
pacstrap /mnt base base-devel linux-firmware mkinitcpio linux lvm2 grub openssh libfido2 networkmanager

# Generate fstab
genfstab -pU /mnt >> /mnt/etc/fstab

# Put TMP into RAM and protect procfs
echo "tmpfs	/tmp    tmpfs   defaults,noatime,mode=1777    0   0" >> /mnt/etc/fstab
echo "proc    /proc   proc    defaults,hidepid=2    0   0" >> /mnt/etc/fstab

echo "$HOSTNAME" > /mnt/etc/hostname
echo LANG=en_US.UTF-8 >> /mnt/etc/locale.conf
echo LANGUAGE=en_US >> /mnt/etc/locale.conf
echo LC_ALL=C >> /mnt/etc/locale.conf

# Make sure encryption is properly initialized
sed -i 's,modconf block filesystems keyboard,keyboard modconf block lvm2 encrypt filesystems,g' /mnt/etc/mkinitcpio.conf
sed -i 's/^GRUB_CMDLINE_LINUX="/&cryptdevice=\/dev\/sda3:luks:allow-discards/' /mnt/etc/default/grub

# Remove nullok
sed -i 's/nullok//g' /mnt/etc/pam.d/system-auth

# Disable coredump
echo "* hard core 0" >> /mnt/etc/security/limits.conf

# Disable su for non-wheel users
bash -c 'cat > /mnt/etc/pam.d/su' <<-'EOF'
#%PAM-1.0
auth		sufficient	pam_rootok.so
# Uncomment the following line to implicitly trust users in the "wheel" group.
#auth		sufficient	pam_wheel.so trust use_uid
# Uncomment the following line to require a user to be in the "wheel" group.
auth		required	pam_wheel.so use_uid
auth		required	pam_unix.so
account		required	pam_unix.so
session		required	pam_unix.so
EOF

# Disable Connectivity Check.
bash -c 'cat > /mnt/etc/NetworkManager/conf.d/20-connectivity.conf' <<-'EOF'
[connectivity]
uri=http://www.archlinux.org/check_network_status.txt
interval=0
EOF

chmod 600 /mnt/etc/NetworkManager/conf.d/20-connectivity.conf

# Setup the system from within the installation
arch-chroot /mnt /bin/bash -e <<EOF
  # Setting up timezone
  ln -s /usr/share/zoneinfo/Europe/Stockholm /etc/localtime

  # Setting up clock.
  hwclock --systohc

  # Generate locales
  locale-gen

  # Generating initramfs
  mkinitcpio -p linux

  # Setup grub
  grub-install --target=i386-pc --recheck /dev/sda
  grub-mkconfig -o /boot/grub/grub.cfg

  # Enable services
  systemctl enable sshd.service
  systemctl enable NetworkManager.service
  systemctl enable fstrim.timer

  # Create default user
  echo "Create user..."
  useradd -m myuser
  usermod -aG wheel myuser

  echo "Setup user SSH keys..."
  mkdir /home/myuser/.ssh
  echo "SSH_KEY" > /home/myuser/.ssh/authorized_keys
  chown -R myuser:myuser /home/myuser/.ssh
  chmod 700 /home/myuser/.ssh
  chmod 644 /home/myuser/.ssh/authorized_keys

  # Allow members of wheel group to sudo
  sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers
EOF

# Change default user password
echo "Change user password..."
openssl rand -base64 15 > /mnt/home/myuser/user.txt
echo "myuser:$(cat /mnt/home/myuser/user.txt)" | arch-chroot /mnt /usr/bin/chpasswd

echo "Done with everything, time to reboot - don\'t forget to remove ISO image through the UI!"
