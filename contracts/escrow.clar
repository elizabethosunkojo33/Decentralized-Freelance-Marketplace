;; Escrow Contract

;; Define data structures
(define-map escrows
  { escrow-id: uint }
  {
    client: principal,
    freelancer: principal,
    amount: uint,
    status: (string-ascii 20)
  }
)

(define-data-var escrow-id-nonce uint u0)

;; Error codes
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u403))
(define-constant err-insufficient-funds (err u400))

;; Create escrow
(define-public (create-escrow (freelancer principal) (amount uint))
  (let
    (
      (new-escrow-id (+ (var-get escrow-id-nonce) u1))
    )
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set escrows
      { escrow-id: new-escrow-id }
      {
        client: tx-sender,
        freelancer: freelancer,
        amount: amount,
        status: "funded"
      }
    )
    (var-set escrow-id-nonce new-escrow-id)
    (ok new-escrow-id)
  )
)

;; Release funds
(define-public (release-funds (escrow-id uint))
  (let
    (
      (escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get client escrow)) err-unauthorized)
    (asserts! (is-eq (get status escrow) "funded") err-unauthorized)
    (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get freelancer escrow))))
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow { status: "released" })
    )
    (ok true)
  )
)

;; Get escrow details
(define-read-only (get-escrow (escrow-id uint))
  (map-get? escrows { escrow-id: escrow-id })
)

