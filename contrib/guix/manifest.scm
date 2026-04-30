(use-modules (guix packages)
             (guix download)
             (guix build-system gnu)
             (guix licenses)
             (gnu packages)
             (gnu packages autotools)
             (gnu packages base)
             (gnu packages boost)
             (gnu packages compression)
             (gnu packages databases)
             (gnu packages gcc)
             (gnu packages gettext)
             (gnu packages glib)
             (gnu packages graphviz)
             (gnu packages libevent)
             (gnu packages pkg-config)
             (gnu packages qt)
             (gnu packages version-control)
             (gnu packages xorg))

(packages->manifest
 (list
  ;; Core build tools
  gcc-toolchain-10                ; We use GCC 10 for maximum compatibility with 0.21.x
  make
  autoconf
  automake
  libtool
  pkg-config

  ;; Required dependencies for Cyberyen
  boost@1.81
  qtbase-5
  qttools-5
  libevent
  miniupnpc
  qrencode
  sqlite
  zeromq

  ;; Optional but recommended
  berkeley-db-4                   ; For wallet (can be disabled with --without-bdb)
  zlib
  bzip2
  xz

  ;; Tools needed during build
  git
  which
  coreutils
  bash
  ))
