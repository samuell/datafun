#lang racket

(require (except-in syntax/parse expr) (for-syntax syntax/parse))

(require "util.rkt")
(provide (all-defined-out))

(enum type
  (t-bool) (t-nat) (t-str)
  (t-tuple types)
  ;; branches is a hash from branch names to types
  (t-sum branches)
  (t-fun arg result)
  (t-mono arg result)
  (t-fs type))

(define type=? equal?)

;; convenience macros for types
(define-syntax-parser Bool [_:id #'(t-bool)])
(define-syntax-parser Nat [_:id #'(t-nat)])
(define-syntax-parser Str [_:id #'(t-str)])
(define-match-expander FS
  (syntax-parser [(_ a) #'(t-fs a)])
  (syntax-parser [(_ a) #'(t-fs a)]))
(define-for-syntax expand->
  (syntax-parser
    [(_ a) #'a]
    [(_ a b ...) #'(t-fun a (-> b ...))]))
(define-match-expander -> expand-> expand->)
(define-for-syntax expand~>
  (syntax-parser
    [(_ a) #'a]
    [(_ a b ...) #'(t-mono a (~> b ...))]))
(define-match-expander ~> expand~> expand~>)
(define-match-expander ×
  (syntax-parser [(× a ...) #'(t-tuple (list a ...))])
  (syntax-parser [(× a ...) #'(t-tuple (list a ...))]))
(define-syntax-parser Σ
  [(Σ (tag:id type) ...)
    #'(t-sum (make-immutable-hash `((tag . ,type) ...)))])

(define (type-wf? x)
  (match x
    [(t-mono a b) (andmap (andf type-wf? lattice-type?) (list a b))]
    [(t-fun a b) (andmap type-wf? (list a b))]
    [(t-fs a) (type-wf? a)]
    [(t-tuple ts) (andmap type-wf? ts)]
    [(t-sum bs) ((hash/c symbol? type-wf? #:immutable #t) bs)]
    [_ #t]))

(define (lattice-type? x)
  (match x
    [(or (t-bool) (t-nat) (t-mono _ _) (t-fs _)) #t]
    [(or (t-str) (t-sum _)) #f]
    [(t-tuple ts) (andmap lattice-type? ts)]
    [(t-fun _ r) (lattice-type? r)]))

(define (eqtype? x)
  (match x
    [(or (t-bool) (t-nat) (t-str)) #t]
    [(or (t-tuple as) (t-sum (app hash-values as)))
      (andmap eqtype? as)]
    [(or (t-fun _ _) (t-mono _ _)) #f]
    [(t-fs a) (eqtype? a)]))

(enum expr
  (e-ann expr type)
  ;; DeBruijn indexing w/ name for readability
  (e-var name index)
  ;; used for literals & primitive functions.
  (e-lit value)
  (e-prim prim)
  (e-fun var type body)
  (e-mono var type body)
  (e-app func arg)
  (e-tuple exprs) (e-proj index expr)
  (e-tag tag expr)
  ;; branches is a list of (pat . expr) pairs. TODO: use a struct!
  (e-case subject branches)
  (e-empty) (e-join left right)
  (e-singleton expr) (e-letin var arg body)
  (e-fix var body))

(enum pat
  (p-wild)
  (p-var name)
  (p-tuple pats)
  (p-tag tag pat)
  (p-lit lit))

(define (lit? x) (if (lit-type x) #t #f))
(define (lit-type l)
  (cond
    [(boolean? l) (t-bool)]
    [(number? l) (t-nat)]
    [(string? l) (t-str)]
    [#t #f]))

(define (prim? x) (member x '(= <= + - * subset? print puts ++)))

(define (prim-type-synth p)
  (match p
    ['<= (-> Nat (~> Nat Bool))]
    [(or '+ '*) (~> Nat Nat Nat)]
    ['- (~> Nat (-> Nat Nat))]
    ['++ (-> Str Str Str)]
    ['puts (~> Str (×))]
    [_ #f]))

(define (prim-type-check p t)
  (define pt (prim-type-synth t))
  (if pt (type=? t pt)
    (match* (p t)
      [('= (-> a b (t-bool)))
        (and (type=? a b) (eqtype? a))]
      [('subset? (-> (FS a) (~> (FS b) (t-bool))))
        (and (type=? a b) (eqtype? a))]
      [('print (~> _ (×))) #t]
      [(_ _) #f])))