#! /bin/sh

ACTION=$1
DEVICE_NAME=$2
MTP_MOUNT_DIR="/mnt"
USB_STORAGE_SYNC=""
USB_MOUNT_OPTIONS=""
MOUNT=/bin/aft-mtp-mount

CURRENT_DEVICE_MOUNT_PATH=$MTP_MOUNT_DIR/$DEVICE_NAME

_logger() {
    logger "$2" -p $1 -t "mtp"
}

_mounted() {
    if [ -n "$(grep -oe "$1" /proc/mounts)" ]; then
        return 0
    else
        return 1
    fi
}

_mount() {
    _logger info "mount $DEVICE_NAME"
    if [ -d $CURRENT_DEVICE_MOUNT_PATH ] && _mounted $CURRENT_DEVICE_MOUNT_PATH; then
        _logger warning "$DEVICE_NAME already mounted"
        exit 1
    fi
    if [ ! -d $CURRENT_DEVICE_MOUNT_PATH ]; then
        mkdir $CURRENT_DEVICE_MOUNT_PATH
        if is_enabled "$USB_STORAGE_SYNC" && [ ! -n "$(echo $USB_MOUNT_OPTIONS | grep -e sync)" ]; then
            USB_MOUNT_OPTIONS=$USB_MOUNT_OPTIONS,sync
        fi
        $MOUNT -o $USB_MOUNT_OPTIONS $CURRENT_DEVICE_MOUNT_PATH
        if _mounted $CURRENT_DEVICE_MOUNT_PATH && [ "$(ls -A $CURRENT_DEVICE_MOUNT_PATH)" ]; then
            _logger info "mounted $DEVICE_NAME in $CURRENT_DEVICE_MOUNT_PATH"
        else
            _logger warning "$DEVICE_NAME failed to mount"
            _umount
            exit 2
        fi
    else
        _logger warning "$CURRENT_DEVICE_MOUNT_PATH already exists"
        exit 3
    fi
}

_umount() {
    _logger info "unmount $DEVICE_NAME"
    if [[ -d $CURRENT_DEVICE_MOUNT_PATH ]]; then
        while _mounted $CURRENT_DEVICE_MOUNT_PATH; do
            umount $CURRENT_DEVICE_MOUNT_PATH
        done
        _logger info "unmounted $DEVICE_NAME in $CURRENT_DEVICE_MOUNT_PATH"
        rm -r $CURRENT_DEVICE_MOUNT_PATH
    else
        _logger warning "$DEVICE_NAME was not mounted"
    fi
}

if [ $ACTION == "add" ]; then
    _mount
elif [ $ACTION == "remove" ]; then
    _umount
fi

exit 0