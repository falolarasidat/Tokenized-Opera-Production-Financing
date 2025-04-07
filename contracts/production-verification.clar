;; production-verification.clar
;; Validates legitimate operatic projects

(define-data-var contract-owner principal tx-sender)

;; Production data structure
(define-map productions
  { production-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    start-date: uint,
    end-date: uint,
    venue: (string-utf8 100),
    verified: bool,
    producer: principal
  }
)

;; Counter for production IDs
(define-data-var next-production-id uint u1)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Register a new production
(define-public (register-production
    (name (string-utf8 100))
    (description (string-utf8 500))
    (start-date uint)
    (end-date uint)
    (venue (string-utf8 100))
  )
  (let ((production-id (var-get next-production-id)))
    (asserts! (>= end-date start-date) (err u1))
    (map-insert productions
      { production-id: production-id }
      {
        name: name,
        description: description,
        start-date: start-date,
        end-date: end-date,
        venue: venue,
        verified: false,
        producer: tx-sender
      }
    )
    (var-set next-production-id (+ production-id u1))
    (ok production-id)
  )
)

;; Verify a production (only contract owner)
(define-public (verify-production (production-id uint))
  (begin
    (asserts! (is-contract-owner) (err u403))
    (let ((production (map-get? productions { production-id: production-id })))
      (if (is-some production)
        (begin
          (map-set productions
            { production-id: production-id }
            (merge (unwrap-panic production) { verified: true })
          )
          (ok true)
        )
        (err u404)
      )
    )
  )
)

;; Get production details
(define-read-only (get-production (production-id uint))
  (map-get? productions { production-id: production-id })
)

;; Check if production is verified
(define-read-only (is-production-verified (production-id uint))
  (let ((production (map-get? productions { production-id: production-id })))
    (if (is-some production)
      (ok (get verified (unwrap-panic production)))
      (err u404)
    )
  )
)

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) (err u403))
    (var-set contract-owner new-owner)
    (ok true)
  )
)
