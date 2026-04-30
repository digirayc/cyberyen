(use-modules (guix packages)
             (guix download)
             (guix build-system gnu)
             (guix licenses)
             (gnu packages)
             (gnu packages autotools)
             (gnu packages base)
             (gnu packages boost)
             (gnu packages commencement)     ; for gcc-toolchain
             (gnu packages compression)
             (gnu packages databases)
             (gnu packages gcc)
             (gnu packages gettext)
             (gnu packages glib)
             (gnu packages libevent)
             (gnu packages pkg-config)
             (gnu packages qt)
             (gnu packages version-control)
             (gnu packages xorg))

(packages->manifest
 (list
  ;; Core build tools
  gcc-toolchain                    ; using default version (works reliably in CI)
  make
  autoconf
  automake
  libtool
  pkg-config

  ;; Required dependencies for Cyberyen
  boost@1.81
  qtbase@5
  qttools@5
  libevent
  miniupnpc
  qrencode
  sqlite
  zeromq

  ;; Optional but useful
  berkeley-db-4
  zlib
  bzip2
  xz

  ;; Build tools
  git
  which
  coreutils
  bash
  ))
