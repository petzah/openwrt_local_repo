#!/bin/sh

# Examples:
# /root/add_package.sh packages base libopenssl1.1
# /root/add_package.sh targets packages libip4tc2

source /etc/openwrt_release
REPODIR=/root/opkg_local_repo
PRIVKEY=/root/.local_repo
PUBKEY=/root/.local_repo.pub

REPOURL="https://downloads.openwrt.org/releases/22.03.0-rc6"

# "targets" or "packages"
REPO=${1}
if [ -z ${REPO} ]; then
    exit 1
fi

# "base" "packages" "routing"
REPOCAT=${2}
if [ -z ${REPOCAT} ]; then
    exit 1
fi

PACKAGE=${3}
if [ -z ${PACKAGE} ]; then
    exit 1
fi

if [ "${REPO}}" == "targets" ]; then
    REPOURL="${REPOURL}/${REPO}/${DISTRIB_TARGET}/${REPOCAT}"
else
    REPOURL="${REPOURL}/${REPO}/${DISTRIB_ARCH}/${REPOCAT}"
fi


if [ ! -f ${PRIVKEY} ]; then  
    usign -G -c "local repo in ${REPODIR}" -s ${PRIVKEY} -p ${PUBKEY}
fi

KEYSIG=$(usign -F -p ${PUBKEY})
if [ ! -f /etc/opkg/keys/${KEYSIG} ]; then
    cat ${PUBKEY} > /etc/opkg/keys/${KEYSIG}
fi

mkdir -p "${REPODIR}"

sed -i "/^Package: ${PACKAGE}$/,/^$/d" ${REPODIR}/Packages
METADATA="$(wget -qO - ${REPOURL}/Packages.gz | gzip -d -c | sed "/^Package: ${PACKAGE}$/,/^$/!d")"
echo "${METADATA}" >> ${REPODIR}/Packages
echo "" >> ${REPODIR}/Packages

PKGFNAME="$(echo "${METADATA}" | awk '/^Filename:/ {print $2}')"
PKGURL="${REPOURL}/${PKGFNAME}"

wget --continue -qP ${REPODIR} ${PKGURL}

usign -S -m "${REPODIR}/Packages" -s ${PRIVKEY}
cd ${REPODIR} && gzip -c Packages > ${REPODIR}/Packages.gz

