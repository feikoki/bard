(load "word.scm")
(load "constraints.scm")
(load "grader.scm")
(load "matching.scm")
(load "pp.scm")
(load "util.scm")

(define (make-interpreter vocabulary grader)
  (define (interpreter poem)
    (let loop ((result '())
               (lines (contents poem))
               (lines-alist '())
               (words-alist '()))
      (if (null? lines)
        result
        (let ((next-line (car lines))
              (remaining-lines (cdr lines)))
          (parse-line next-line
                      (lambda (line-value new-lines-alist new-words-alist)
                        (loop (append result (list line-value))
                              remaining-lines
                              new-lines-alist
                              new-words-alist))
                      (lambda ()
                        (pp "Failed to parse a line!")
                        (error "Unsolveable constraints" next-line))
                      lines-alist
                      words-alist)))))
  (define (parse-line line-constraint succeed fail lines-alist words-alist)
    (let* ((name (name-of line-constraint))
           (syllables (syllables-of line-constraint))
           (words (constraints-of line-constraint))
           (existing-match (and name (assq name lines-alist)))
           (existing-value (and existing-match (cdr existing-match))))
      (define (line-success line-value
                            new-fail-fn
                            new-lines-alist
                            new-words-alist)
        (if (or (not syllables)
                (= syllables (line-value-syllables line-value vocabulary)))
            (succeed line-value
                     (if name
                       ; Update the line association list if this is a named
                       ; line.
                       (cons (cons name line-value) new-lines-alist)
                       new-lines-alist)
                     new-words-alist)
            (new-fail-fn)))
      (if existing-value
        (succeed existing-value lines-alist words-alist)
        (parse-words-in-line words line-success fail lines-alist words-alist))))

  (define (parse-words-in-line words succeed fail lines-alist words-alist)
    (define (impl result words succeed fail lines-alist words-alist)
      (if (null? words)
        (succeed result fail lines-alist words-alist)
        (let ((next-word (car words))
              (rest-of-words (cdr words)))
          (define (new-success-fn next-word-value
                                  new-fail-fn
                                  new-lines-alist
                                  new-words-alist)
            (let ((new-result (append result (list next-word-value))))
              (impl new-result
                    rest-of-words
                    succeed
                    ; This is the tricky part -- if the next call
                    ; to impl fails, it will call the fail
                    ; function gotten from this call!
                    new-fail-fn
                    new-lines-alist
                    new-words-alist)))
          (if (match-word? next-word)
            (parse-word next-word new-success-fn fail lines-alist words-alist)
            (let ((new-result
                    (append result
                            (list (cond
                                    ((string? next-word) (symbol next-word))
                                    ((symbol? next-word) next-word)
                                    (else (cons 'unrecognized next-word)))))))
              (impl new-result
                    rest-of-words
                    succeed
                    fail
                    lines-alist
                    words-alist))))))
    (impl '() words succeed fail lines-alist words-alist))
  (define (parse-word word-constraint succeed fail lines-alist words-alist)
    (let* ((name (name-of word-constraint))
           (constraints (contents word-constraint))
           (existing-match (and name (assq name words-alist)))
           (existing-value (and existing-match (cdr existing-match))))
      (define (new-succeed value new-fail-fn)
        (succeed value
                 new-fail-fn
                 lines-alist
                 (if name
                     (cons (cons name value) words-alist)
                     words-alist)))
      (if existing-value
        (succeed existing-value fail lines-alist words-alist)
        (parse-word-constraints constraints
                                new-succeed
                                (lambda () (fail))))))
  (define (parse-word-constraints constraints succeed fail)
    (let loop ((possibilities (grader (fetch-words vocabulary constraints))))
      (if (null? possibilities)
        (fail)
        (let ((next-value (car possibilities))
              (remaining-values (cdr possibilities)))
          (succeed next-value
                   (lambda () (loop remaining-values)))))))

  interpreter)

; TODO(peter): grader format
; TODO(peter): improvements:
;   * wordnet (meanings)
;   * not-rhyming (pattern 'a can't rhyme with 'b)
