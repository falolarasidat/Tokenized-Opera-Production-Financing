;; revenue-distribution.clar
;; Allocates income from successful productions

(define-data-var contract-owner principal tx-sender)

;; Distribution data structure
(define-map distributions
  { production-id: uint, investor: principal }
  { amount-distributed: uint }
)

;; Production distribution totals
(define-map production-distributions
  { production-id: uint }
  { total-distributed: uint }
)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Distribute revenue for a production
(define-public (distribute-revenue (production-id uint) (total-revenue uint))
  (let (
    (total-distributed (default-to u0 (get total-distributed (map-get? production-distributions { production-id: production-id }))))
    (available-to-distribute (- total-revenue total-distributed))
  )
    (asserts! (> available-to-distribute u0) (err u1))

    ;; Update total distributed
    (map-set production-distributions
      { production-id: production-id }
      { total-distributed: total-revenue }
    )

    (ok available-to-distribute)
  )
)

;; Claim distribution for an investor
(define-public (claim-distribution (production-id uint) (total-revenue uint) (ownership-basis-points uint))
  (let (
    (investor tx-sender)
    (already-claimed (default-to u0 (get amount-distributed (map-get? distributions { production-id: production-id, investor: investor }))))
    (entitled-amount (/ (* total-revenue ownership-basis-points) u10000))
    (claimable-amount (- entitled-amount already-claimed))
  )
    (asserts! (> claimable-amount u0) (err u1))

    ;; Update claimed amount
    (map-set distributions
      { production-id: production-id, investor: investor }
      { amount-distributed: entitled-amount }
    )

    (ok claimable-amount)
  )
)

;; Get distribution amount for an investor
(define-read-only (get-distribution (production-id uint) (investor principal))
  (default-to u0 (get amount-distributed (map-get? distributions { production-id: production-id, investor: investor })))
)

;; Get claimable amount for an investor (simplified)
(define-read-only (get-claimable-amount (production-id uint) (investor principal) (total-revenue uint) (ownership-basis-points uint))
  (let (
    (already-claimed (get-distribution production-id investor))
    (entitled-amount (/ (* total-revenue ownership-basis-points) u10000))
  )
    (- entitled-amount already-claimed)
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
