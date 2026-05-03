;; Cyberyen Core — modern Guix manifest (parallel path only).
;;
;; Package graph matches contrib/guix/manifest.scm (dongcarl-era toolchain: GCC 9,
;; glibc 2.27) so that the shared autotools contrib/guix/libexec/build.sh keeps
;; working unchanged. The driver pins upstream Guix via contrib/guix/libexec/prelude.bash
;; (Codeberg guix.git @ c5eee3336cc1d10a3cc1c97fde2809c3451624d3).
;;
;; Bitcoin Core's CMake-based Guix manifest targets a different libexec/build.sh;
;; Cyberyen intentionally retains this Scheme baseline until the tree migrates.

(use-modules (gnu)
             (gnu packages)
             (gnu packages autotools)
             (gnu packages base)
             (gnu packages bash)
             (gnu packages check)
             (gnu packages commencement)
             (gnu packages compression)
             (gnu packages cross-base)
             (gnu packages file)
             (gnu packages gawk)
             (gnu packages gcc)
             (gnu packages installers)
             (gnu packages linux)
             (gnu packages mingw)
             (gnu packages perl)
             (gnu packages pkg-config)
             (gnu packages python)
             (gnu packages shells)
             (gnu packages version-control)
             (guix build-system gnu)
             (guix build-system trivial)
             (guix gexp)
             (guix packages)
             (guix profiles)
             (guix utils))

(define (make-ssp-fixed-gcc xgcc)
  "Given a XGCC package, return a modified package that uses the SSP function
from glibc instead of from libssp.so. Our `symbol-check' script will complain if
we link against libssp.so, and thus will ensure that this works properly.

Taken from:
http://www.linuxfromscratch.org/hlfs/view/development/chapter05/gcc-pass1.html"
  (package
   (inherit xgcc)
   (arguments
    (substitute-keyword-arguments (package-arguments xgcc)
      ((#:make-flags flags)
       `(cons "gcc_cv_libc_provides_ssp=yes" ,flags))))))

(define (make-gcc-rpath-link xgcc)
  "Given a XGCC package, return a modified package that replace each instance of
-rpath in the default system spec that's inserted by Guix with -rpath-link"
  (package
   (inherit xgcc)
   (arguments
    (substitute-keyword-arguments (package-arguments xgcc)
      ((#:phases phases)
       `(modify-phases ,phases
          (add-after 'pre-configure 'replace-rpath-with-rpath-link
            (lambda _
              (substitute* (cons "gcc/config/rs6000/sysv4.h"
                                 (find-files "gcc/config"
                                             "^gnu-user.*\\.h$"))
                (("-rpath=") "-rpath-link="))
              #t))))))))

(define (make-cross-toolchain target
                              base-gcc-for-libc
                              base-kernel-headers
                              base-libc
                              base-gcc)
  "Create a cross-compilation toolchain package for TARGET"
  (let* ((xbinutils (cross-binutils target))
         (xgcc-sans-libc (cross-gcc target
                                    #:xgcc base-gcc-for-libc
                                    #:xbinutils xbinutils))
         (xkernel (cross-kernel-headers target
                                        base-kernel-headers
                                        xgcc-sans-libc
                                        xbinutils))
         (xlibc (cross-libc target
                            base-libc
                            xgcc-sans-libc
                            xbinutils
                            xkernel))
         (xgcc (cross-gcc target
                          #:xgcc base-gcc
                          #:xbinutils xbinutils
                          #:libc xlibc)))
    (package
      (name (string-append target "-toolchain"))
      (version (package-version xgcc))
      (source #f)
      (build-system trivial-build-system)
      (arguments '(#:builder (begin (mkdir %output) #t)))
      (propagated-inputs
       `(("binutils" ,xbinutils)
         ("libc" ,xlibc)
         ("libc:static" ,xlibc "static")
         ("gcc" ,xgcc)))
      (synopsis (string-append "Complete GCC tool chain for " target))
      (description (string-append "This package provides a complete GCC tool
chain for " target " development."))
      (home-page (package-home-page xgcc))
      (license (package-license xgcc)))))

(define* (make-cyberyen-cross-toolchain target
                                  #:key
                                  (base-gcc-for-libc gcc-5)
                                  (base-kernel-headers linux-libre-headers-4.19)
                                  (base-libc glibc-2.27)
                                  (base-gcc (make-gcc-rpath-link gcc-9)))
  "Convenience wrapper around MAKE-CROSS-TOOLCHAIN with default values
desirable for building Cyberyen Core release binaries."
  (make-cross-toolchain target
                   base-gcc-for-libc
                   base-kernel-headers
                   base-libc
                   base-gcc))

(define (make-gcc-with-pthreads gcc)
  (package-with-extra-configure-variable gcc "--enable-threads" "posix"))

(define (make-mingw-pthreads-cross-toolchain target)
  "Create a cross-compilation toolchain package for TARGET"
  (let* ((xbinutils (cross-binutils target))
         (pthreads-xlibc mingw-w64-x86_64-winpthreads)
         (pthreads-xgcc (make-gcc-with-pthreads
                         (cross-gcc target
                                    #:xgcc (make-ssp-fixed-gcc gcc-9)
                                    #:xbinutils xbinutils
                                    #:libc pthreads-xlibc))))
    (package
      (name (string-append target "-posix-toolchain"))
      (version (package-version pthreads-xgcc))
      (source #f)
      (build-system trivial-build-system)
      (arguments '(#:builder (begin (mkdir %output) #t)))
      (propagated-inputs
       `(("binutils" ,xbinutils)
         ("libc" ,pthreads-xlibc)
         ("gcc" ,pthreads-xgcc)))
      (synopsis (string-append "Complete GCC tool chain for " target))
      (description (string-append "This package provides a complete GCC tool
chain for " target " development."))
      (home-page (package-home-page pthreads-xgcc))
      (license (package-license pthreads-xgcc)))))


(packages->manifest
 (append
  (list ;; The Basics
        bash-minimal
        which
        coreutils
        util-linux
        ;; File(system) inspection
        file
        grep
        diffutils
        findutils
        ;; File transformation
        patch
        gawk
        sed
        ;; Compression and archiving
        tar
        bzip2
        gzip
        xz
        zlib
        ;; Build tools
        gnu-make
        libtool
        autoconf
        automake
        pkg-config
        ;; Scripting (legacy manifest used python-3.7; upstream Guix no longer exports
        ;; that symbol—python-minimal provides Python 3 for scripts without changing GCC/glibc)
        perl
        python-minimal
        ;; Git
        git
        ;; Native gcc 9 toolchain targeting glibc 2.27
        (make-gcc-toolchain gcc-9 glibc-2.27))
  (let ((target (getenv "HOST")))
    (cond ((string-suffix? "-mingw32" target)
           ;; Windows
           (list zip (make-mingw-pthreads-cross-toolchain "x86_64-w64-mingw32") nsis-x86_64))
          ((string-contains target "riscv64-linux-")
           (list (make-cyberyen-cross-toolchain "riscv64-linux-gnu"
                                               #:base-gcc-for-libc gcc-7)))
          ((string-contains target "-linux-")
           (list (make-cyberyen-cross-toolchain target)))
          (else '())))))
