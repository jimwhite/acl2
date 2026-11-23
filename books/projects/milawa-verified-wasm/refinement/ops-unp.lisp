; The (un-p v 32) facts needed by the final frame-append step for each
; dispatcher value.
;
; License: (An MIT/X11-style license)

(in-package "MILAWA-WASM")
(include-book "ops-tail-2")

(defthm un-p-32-when-unsigned-byte-p
  (implies (unsigned-byte-p 32 x) (w3t::un-p x 32))
  :hints (("Goal" :in-theory (enable w3t::un-p unsigned-byte-p))))

(defthm ubp-loghead-32
  (unsigned-byte-p 32 (loghead 32 x)))

(defthm un-p-loghead-32
  (w3t::un-p (loghead 32 x) 32)
  :hints (("Goal" :use ubp-loghead-32
                  :in-theory (disable loghead))))

(defthm un-p-zero-32
  (w3t::un-p 0 32)
  :hints (("Goal" :in-theory (enable w3t::un-p))))

(defthm un-p-one-32
  (w3t::un-p 1 32)
  :hints (("Goal" :in-theory (enable w3t::un-p))))

(defthm un-p-if-01
  (w3t::un-p (if c 1 0) 32)
  :hints (("Goal" :cases (c)
                  :in-theory (enable w3t::un-p))))

(defthm un-p-if-equal-zero-sel
  (w3t::un-p (if (equal x 0) (sel b) 0) 32)
  :hints (("Goal" :cases ((equal x 0))
                  :in-theory (enable w3t::un-p))))
