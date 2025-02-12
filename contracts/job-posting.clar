;; Job Posting Contract

;; Define data structures
(define-map jobs
  { job-id: uint }
  {
    client: principal,
    title: (string-ascii 100),
    description: (string-ascii 1000),
    budget: uint,
    status: (string-ascii 20)
  }
)

(define-map job-applications
  { job-id: uint, applicant: principal }
  { proposal: (string-ascii 500) }
)

(define-data-var job-id-nonce uint u0)

;; Error codes
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u403))

;; Post a new job
(define-public (post-job (title (string-ascii 100)) (description (string-ascii 1000)) (budget uint))
  (let
    (
      (new-job-id (+ (var-get job-id-nonce) u1))
    )
    (map-set jobs
      { job-id: new-job-id }
      {
        client: tx-sender,
        title: title,
        description: description,
        budget: budget,
        status: "open"
      }
    )
    (var-set job-id-nonce new-job-id)
    (ok new-job-id)
  )
)

;; Apply for a job
(define-public (apply-for-job (job-id uint) (proposal (string-ascii 500)))
  (let
    (
      (job (unwrap! (map-get? jobs { job-id: job-id }) err-not-found))
    )
    (asserts! (is-eq (get status job) "open") err-unauthorized)
    (map-set job-applications
      { job-id: job-id, applicant: tx-sender }
      { proposal: proposal }
    )
    (ok true)
  )
)

;; Get job details
(define-read-only (get-job (job-id uint))
  (map-get? jobs { job-id: job-id })
)

;; Get job application
(define-read-only (get-job-application (job-id uint) (applicant principal))
  (map-get? job-applications { job-id: job-id, applicant: applicant })
)

