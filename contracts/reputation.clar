;; Reputation Contract

;; Define data structures
(define-map user-ratings
  { user: principal }
  { total-score: uint, review-count: uint }
)

(define-map user-reviews
  { reviewer: principal, reviewee: principal }
  { rating: uint, review: (string-ascii 500) }
)

;; Error codes
(define-constant err-invalid-rating (err u400))
(define-constant err-self-review (err u401))

;; Submit rating and review
(define-public (submit-review (reviewee principal) (rating uint) (review (string-ascii 500)))
  (let
    (
      (current-rating (default-to { total-score: u0, review-count: u0 } (map-get? user-ratings { user: reviewee })))
    )
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
    (asserts! (not (is-eq tx-sender reviewee)) err-self-review)
    (map-set user-ratings
      { user: reviewee }
      {
        total-score: (+ (get total-score current-rating) rating),
        review-count: (+ (get review-count current-rating) u1)
      }
    )
    (map-set user-reviews
      { reviewer: tx-sender, reviewee: reviewee }
      { rating: rating, review: review }
    )
    (ok true)
  )
)

;; Get user rating
(define-read-only (get-user-rating (user principal))
  (let
    (
      (rating (default-to { total-score: u0, review-count: u0 } (map-get? user-ratings { user: user })))
    )
    (if (is-eq (get review-count rating) u0)
      u0
      (/ (get total-score rating) (get review-count rating))
    )
  )
)

;; Get user review
(define-read-only (get-user-review (reviewer principal) (reviewee principal))
  (map-get? user-reviews { reviewer: reviewer, reviewee: reviewee })
)

