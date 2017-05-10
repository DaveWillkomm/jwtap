#!/usr/bin/env bash
set -evx

rpmbuild_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../rpmbuild" && pwd)"
rpmbuild -bb --define="_topdir ${rpmbuild_dir}" --define="uid 456" "${rpmbuild_dir}/SPECS/jwtap.spec"
