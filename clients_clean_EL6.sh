#!/bin/bash
set -ex
trap "exit 1" TERM

echo "voms-clients3 clean deployment test"

WGET_OPTIONS="--no-check-certificate"
VOMS_REPO=${VOMS_REPO:-http://radiohead.cnaf.infn.it:9999/view/REPOS/job/repo_voms_develop_SL6/lastSuccessfulBuild/artifact/voms-develop_sl6.repo}

EMI_RELEASE_PACKAGE=${EMI_RELEASE_PACKAGE:-emi-release-3.0.0-2.el6.noarch.rpm}
EMI_RELEASE_PACKAGE_URL="http://emisoft.web.cern.ch/emisoft/dist/EMI/3/sl6/x86_64/base/${EMI_RELEASE_PACKAGE}"
EMI_GPG_KEY=${EMI_GPG_KEY:-http://emisoft.web.cern.ch/emisoft/dist/EMI/3/RPM-GPG-KEY-emi}

# install emi gpg key
rpm --import ${EMI_GPG_KEY}

# install emi-release package
wget $WGET_OPTIONS ${EMI_RELEASE_PACKAGE_URL}
yum localinstall -y ${EMI_RELEASE_PACKAGE}

# install voms repo
wget $WGET_OPTIONS $VOMS_REPO -O /etc/yum.repos.d/voms.repo

# Clean yum database
yum clean all

# install voms-clients
yum install -y voms-clients3 voms-clients

# Configure vomsdir
mkdir -p /etc/grid-security/vomsdir
cp /etc/grid-security/hostcert.pem /etc/grid-security/vomsdir

echo "VOMS clients successfully deployed"
