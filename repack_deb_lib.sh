#!/bin/sh

CUDA_MAJOR_VERSION="10"
CUDA_MINOR_VERSION="2"
CUDA_MICRO_VERSION="460"
CUDA_BUILD_NUMBER="450.115"
LIBCUDNN_VERSION="8.2.1.32"
LIBCUDNN_MAJOR_VERSION="8"
HOST_OS="ubuntu1804"
CUDA_VERSION="${CUDA_MAJOR_VERSION}.${CUDA_MINOR_VERSION}"
HOST_DEB_FILES="cuda-repo-cross-aarch64-${HOST_OS}-${CUDA_MAJOR_VERSION}-${CUDA_MINOR_VERSION}-local_${CUDA_MAJOR_VERSION}.${CUDA_MINOR_VERSION}.${CUDA_MICRO_VERSION}-1_all.deb cuda-repo-${HOST_OS}-${CUDA_MAJOR_VERSION}-${CUDA_MINOR_VERSION}-local_${CUDA_MAJOR_VERSION}.${CUDA_MINOR_VERSION}.${CUDA_MICRO_VERSION}-${CUDA_BUILD_NUMBER}-1_amd64.deb"
TARGET_DEB_FILES="cuda-repo-l4t-${CUDA_MAJOR_VERSION}-${CUDA_MINOR_VERSION}-local_${CUDA_MAJOR_VERSION}.${CUDA_MINOR_VERSION}.${CUDA_MICRO_VERSION}-1_arm64.deb"
TARGET_DNN_RT_DEB_FILES="libcudnn${LIBCUDNN_MAJOR_VERSION}_${LIBCUDNN_VERSION}-1+cuda${CUDA_MAJOR_VERSION}.${CUDA_MINOR_VERSION}_arm64.deb"
TARGET_DNN_DEV_DEB_FILES="libcudnn${LIBCUDNN_MAJOR_VERSION}-dev_${LIBCUDNN_VERSION}-1+cuda${CUDA_MAJOR_VERSION}.${CUDA_MINOR_VERSION}_arm64.deb"

set -e

unpack_deb()
{
	DEBFILE=$1
	SKIP_SUBDIR=$2
	echo "Unpacking $DEBFILE"
	if [ -z "$SKIP_SUBDIR" ]; then
		dirname=$(basename "$DEBFILE" .deb)
		mkdir $dirname
		cd $dirname
		ar x ../$1
		tar xf data.tar.xz
		cd ..
	else
		ar x $1
		tar xf data.tar.xz
	fi
}

# libcudnn rt
mkdir -p output/libcudnn-${LIBCUDNN_VERSION}/rt
cd output/libcudnn-${LIBCUDNN_VERSION}/rt
for f in ${TARGET_DNN_RT_DEB_FILES}
do
	unpack_deb "../../../dl/$f" 1
done
rm -f control.tar.xz control.tar.gz data.tar.xz debian-binary _gpgbuilder
cd ../../..

# libcudnn dev
mkdir -p output/libcudnn-${LIBCUDNN_VERSION}/dev
cd output/libcudnn-${LIBCUDNN_VERSION}/dev
for f in ${TARGET_DNN_DEV_DEB_FILES}
do
	unpack_deb "../../../dl/$f" 1
done
rm -f control.tar.xz control.tar.gz data.tar.xz debian-binary _gpgbuilder
cd ../../..

# CUDA aarch64
mkdir -p output/tmp_target
cd output/tmp_target
for f in ${TARGET_DEB_FILES}
do
	unpack_deb "../../dl/$f"
done
cd ../..
mkdir output/cuda-${CUDA_VERSION}-tegra210
cd output/cuda-${CUDA_VERSION}-tegra210
find ../tmp_target -type f -name "*.deb" | xargs -I % sh -c 'echo "Extracting %" ; ar x "%" ; tar xf data.tar.xz '
rm -f control.tar.xz control.tar.gz data.tar.xz debian-binary _gpgbuilder
rm -rf usr/share/doc usr/local/cuda-${CUDA_VERSION}/tools usr/local/cuda-${CUDA_VERSION}/doc usr/local/cuda-${CUDA_VERSION}/samples
rm -rf usr/local/cuda-${CUDA_VERSION}/nvvm/libnvvm-samples usr/local/cuda-${CUDA_VERSION}/nvml/example usr/local/cuda-${CUDA_VERSION}/extras/CUPTI/sample
cd ../..

# CUDA ubuntu1804
mkdir -p output/tmp_host
cd output/tmp_host
for f in ${HOST_DEB_FILES}
do
	unpack_deb "../../dl/$f"
done
cd ../..
mkdir output/cuda-${CUDA_VERSION}-${HOST_OS}
cd output/cuda-${CUDA_VERSION}-${HOST_OS}
find ../tmp_host -type f -name "*.deb" | xargs -I % sh -c 'echo "Extracting %" ; ar x "%" ; tar xf data.tar.xz '
rm -f control.tar.xz control.tar.gz data.tar.xz debian-binary _gpgbuilder
cd ../..

# Compress
cd output
echo "Compressing tegra210 CUDA files to output/cuda-${CUDA_VERSION}-tegra210.tar.xz"
XZ_OPT=-9 tar cfJ cuda-${CUDA_VERSION}-tegra210.tar.xz cuda-${CUDA_VERSION}-tegra210
echo "Compressing tegra210 CUDA DNN files to output/libcudnn-${LIBCUDNN_VERSION}-tegra210.tar.xz"
XZ_OPT=-9 tar cfJ libcudnn-${LIBCUDNN_VERSION}-tegra210.tar.xz libcudnn-${LIBCUDNN_VERSION}
echo "Compressing ${HOST_OS} CUDA files to output/cuda-${CUDA_VERSION}-${HOST_OS}.tar.xz"
XZ_OPT=-9 tar cfJ cuda-${CUDA_VERSION}-${HOST_OS}.tar.xz cuda-${CUDA_VERSION}-${HOST_OS}

echo Done
