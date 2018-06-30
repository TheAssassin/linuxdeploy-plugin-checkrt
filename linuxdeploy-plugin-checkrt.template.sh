#! /bin/bash

OFFSET=-1

if [ $OFFSET -le 0 ]; then
    echo "Please run ./generate-plugin-script.sh to build the linuxdeploy plugin script"
    exit 1
fi

script=$(readlink -f "$0")

show_usage() {
    echo "Usage: $script --appdir <path to AppDir>"
    echo
    echo "Creates or replaces AppRun in AppRun that decides whether to load a bundled libstdc++ or not"
}

APPDIR=

case "$1" in
    --plugin-api-version)
        echo "0"
        exit 0
        ;;
    --appdir)
        APPDIR="$2"
        shift
        shift
        ;;
    *)
        echo "Invalid argument: $1"
        echo
        show_usage
        exit 1
esac

if [ ! -d "$APPDIR" ]; then
    echo "No such directory: $APPDIR"
    exit 1
fi

pushd "$APPDIR"

# extract files from appended tarball
dd if="$script" skip="$OFFSET" iflag=skip_bytes,count_bytes | tar xvz

# copy system libraries
mkdir -p usr/optional/{libstdc++,libgcc_s}

for path in /usr/lib/x86_64-linux-gnu/libstdc++.so.6; do
    if [ -f "$path" ]; then
        cp "$path" usr/optional/libstdc++/
        break
    fi
done

for path in /lib/x86_64-linux-gnu/libgcc_s.so.1; do
    if [ -f "$path" ]; then
        cp "$path" usr/optional/libgcc_s/
        break
    fi
done

if [ -f AppRun ]; then
    rm AppRun
fi

# use patched AppRun
mv AppRun_patched AppRun

# remove unused shell script
[ -f AppRun.sh ] && rm AppRun.sh

# leave AppDir
popd

# important: exit before the appended tarball
exit