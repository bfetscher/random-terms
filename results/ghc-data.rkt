#lang racket

(require racket/runtime-path
         pict
         plot)

(define-runtime-path data "ghc/data")

(provide make-table
         table-prop1-data
         table-prop2-data
         hists-pict)

(define test-aggr (build-path data
                              "test32_2ex_hand_50_2014-10-11.aggr"))

(define table-prop1-data
  '(("Hand-written (size: 50)"    "test27_hand_50_2014-10-11.aggr")
    ("Hand-written (size: 70)"    "test17_hand_70_2014-10-11.aggr")
    ("Hand-written (size: 90)"    "test34_hand_90_2014-10-11.aggr")
    ("Redex poly (depth: 6)"      "test18_redex_6_2014-10-11.aggr")
    ("Redex poly (depth: 7)"      "test15_redex_7_2014-10-11.aggr")
    ("Redex poly (depth: 8)*"     "test22_redex_8_2014-10-11.aggr")
    ("Redex non-poly (depth: 6)*" "test40_redex_6_nopoly_2014-10-14.aggr")
    ("Redex non-poly (depth: 7)"  "test39_redex_7_nopoly_2014-10-14.aggr")
    ("Redex non-poly (depth: 8)"  "test37_redex_8_nopoly_2014-10-14.aggr")))

(define table-prop2-data
  '(("Hand-written (size: 50)"     "test32_2ex_hand_50_2014-10-11.aggr")
    ("Hand-written (size: 70)"     "test21_2ex_hand_70_2014-10-11.aggr")
    ("Hand-written (size: 90)"     "test33_2ex_hand_90_2014-10-11.aggr")
    ("Redex poly (depth: 6)"       "test28_2ex_redex_6_2014-10-11.aggr")
    ("Redex poly (depth: 7)"       "test19_2ex_redex_7_2014-10-11.aggr")
    ("Redex poly (depth: 8)"       "test29_2ex_redex_8_2014-10-11.aggr")
    ("Redex non-poly (depth: 6)"   "test42_2ex_redex_6_nopoly_2014-10-14.aggr")
    ("Redex non-poly (depth: 7)"   "test41_2ex_redex_7_nopoly_2014-10-14.aggr")
    ("Redex non-poly (depth: 8)"   "test38_2ex_redex_8_nopoly_2014-10-14.aggr")
    ("Redex non-poly (depth: 10)*" "test43_2ex_redex_10_nopoly_2014-10-14.aggr")))

(struct runtime (name a b) #:transparent)
(struct aggr (gentime childtime tries-hist ctxs-hist) #:transparent)
(struct raw-data (num-tries
                  num-ctxs
                  gen-time
                  check-time) #:transparent)
(struct row-data (ctx-per
                  term-gen-time
                  term-chk-time
                  time-ctx) #:transparent)

(define-syntax-rule (inf-check n exp)
  (if (= +inf.0 n)
      "∞"
      exp))

(define (show-num n)
  (if (n . > . 1000)
      (string-append (~r (round (/ n 1000))) "K")
      (~r n #:precision 2)))


(define (make-table tdata)
  (for/list ([row (in-list tdata)])
    (match row
      [(list gen-name path)
       (match (raw->row-data (aggr->data (parse-aggr (build-path data path))))
         [(row-data ctx-per time-gen time-check time/ctx)
          (list gen-name 
                (inf-check ctx-per (show-num (round ctx-per)))
                (~r time-gen #:precision 3)
                (~r time-check #:precision 3)
                (inf-check time/ctx
                           (show-num time/ctx)))])])))


(define (aggr->data ag)
  (match ag
    [(aggr (runtime _ tg1 tg2)
           (runtime _ tc1 tc2)
           tries-hist ctxs-hist)
     (raw-data (apply + (map second tries-hist))
               (apply + (map second ctxs-hist))
               (+ tg1 tg2)
               (+ tc1 tc2))]))

(define (->secs t)
  (/ t 1000000))

(define (raw->row-data rd)
  (match rd
    [(raw-data nt nc tg tc)
     (row-data (if (= 0 nc) +inf.0 (/ nt nc))
               (/ (->secs tg) nt)
               (/ (->secs tc) nt)
               (if (= 0 nc)
                   +inf.0
                   (/ (->secs (+ tc tg)) nc)))]))

(define (read-aggr path)
  (read
   (open-input-string
    (string-replace
     (call-with-input-file path
       (λ (in)
         (read-line in)))
     "," " "))))

(define (parse-aggr path)
  (define data (read-aggr path))
  (define-values (t1 t2 hist-data)
    (match data
      [`(TimingInfo
         (,t1n = RunTime ,t1a ,t1b
               ,t2n = RunTime ,t2a ,t2b)
         ,hist-data)
       (values (runtime t1n t1a t1b)
               (runtime t2n t2a t2b)
               hist-data)]))
  (define-values (tlist clist)
    (match hist-data
      [`(Histogram
         (fromList ,trieslist)
         Histogram
         (fromList ,ctxslist))
       (values trieslist ctxslist)]))
  (aggr t1 t2 tlist clist))

(define (scale-hist hist-list scale)
  (map (match-lambda [(list size num)
                      (list size (* scale num))])
       hist-list))

(define (add-zeros hist-list max)
  (for/list ([n (in-range 1 max)])
    (define hist-el (findf (match-lambda [(list size num)
                                          (= size n)])
                           hist-list))
    (or hist-el
        `(,n 0))))

(define (sort/erase hist-list)
  (map (match-lambda [(list size num)
                      (list size num)])
       (sort hist-list <
             #:key (match-lambda [(list size num) size]))))

(define (get-max hist-list)
  (define szs (map (match-lambda [(list size num) size]) hist-list))
  (if (empty? szs)
      0
      (apply max szs)))


(define (tries/20 aggr)
  (round (/ (raw-data-num-tries (aggr->data aggr)) 20)))

(define (aggr-hist aggr [show-cexps? #t] [y-max 60000] [max? #f] [x-label? #t])
  (define thist (aggr-tries-hist aggr))
  (define chist (aggr-ctxs-hist aggr))
  (define the-max (or max? (max (get-max thist) (get-max chist))))
  (parameterize ([plot-x-label (and x-label? "size")]
                 [plot-y-label #f])
    (plot-pict
     (append
      (list
       (points '(5 5) #:size 0.1)
       (discrete-histogram
        #:add-ticks? #f
        #:y-max y-max
        (sort/erase (add-zeros thist the-max))))
      (if show-cexps?
          (list
           (discrete-histogram
            #:color 'red
            #:add-ticks? #f
            #:y-max y-max
            (sort/erase
             (scale-hist (add-zeros chist the-max) 10000))))
          '())))))

(define hists-cmp '(("Hand-written (size: 90)" "test33_2ex_hand_90_2014-10-11.aggr")
                    ("Redex poly (depth: 8)" "test29_2ex_redex_8_2014-10-11.aggr")
                    ("Redex non-poly (depth: 8)" "test38_2ex_redex_8_nopoly_2014-10-14.aggr")))


(define (hists-pict height width)
  (define name/aggrs
    (for/list ([np (in-list hists-cmp)])
      (list (first np) (parse-aggr (build-path data (second np))))))
  (define x-max (apply max (map (match-lambda [(list n a)
                                               (get-max (aggr-tries-hist a))])
                                name/aggrs)))
  (apply hc-append
         (map (match-lambda [(list n a)
                             (parameterize ([plot-y-ticks no-ticks]
                                            [plot-x-far-ticks no-ticks]
                                            [plot-font-size 12]
                                            [plot-title n]
                                            [plot-height height]
                                            [plot-width (round (/ width 3))]
                                            [rectangle-style 'transparent])
                               (aggr-hist a #f (tries/20 a) x-max #f))])
              name/aggrs)))
