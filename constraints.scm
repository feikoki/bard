(load "word.scm")
(load "util.scm")

; Constraint functions return functions of the following type:
; (lambda (vocabulary word-thing)
;   ...
;   #t or #f),
; which return #t if the given word is considered to match the constraint or #f
; if it does not. The word-thing must be converted to a word-record by being
; looked up in a vocabulary, because poem constraints allow literals and
; symbols as well as generic words constraints

(define (number-syllables n)
  (lambda (vocabulary thing)
    (let ((word (get-word vocabulary thing)))
      (= n (word-num-syllables word)))))

(define (any-word)
  (lambda (vocabulary test-thing)
    (let ((test (get-word vocabulary test-thing)))
      (not (eq? test word-dne)))))

(define (has-synonym base-thing)
  (lambda (vocabulary test-thing)
    (let ((requirement (get-word vocabulary base-thing))
          (test (get-word vocabulary test-thing)))
      (memq (word-sym requirement) (word-synonyms test)))))

(define (has-antonym base)
  (lambda (vocabulary test)
    (let ((word (get-word vocabulary base))
          (antonym (get-word vocabulary test)))
      (memq (word-sym antonym) (word-antonyms word)))))

(define (rhymes-with base)
  (lambda (vocabulary test)
    (let ((word (get-word vocabulary base))
          (possibility (get-word vocabulary test)))
      (memq (word-sym possibility) (word-rhymes word)))))
