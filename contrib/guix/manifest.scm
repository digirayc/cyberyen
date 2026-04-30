(use-modules (guix packages)
             (guix profiles)
             (gnu packages))

(packages->manifest
 (map specification->package
      (list
       ;; Core build toolchain
       "gcc-toolchain@10"
       "make"
       "autoconf"
       "automake"
       "libtool"
       "pkg-config"

       ;; Cyberyen dependencies (Litecoin 0.21 base)
       "boost@1.81"
       "qtbase@5"
       "qttools@5"
       "libevent"
       "miniupnpc"
       "qrencode"
       "sqlite"
       "zeromq"

       ;; Optional but recommended
       "berkeley-db@4"
       "zlib"
       "bzip2"
       "xz"

       ;; Build utilities
       "git"
       "which"
       "coreutils"
       "bash-minimal"
       )))
