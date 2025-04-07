;; investment-management.clar
;; Tracks capital contributions and ownership

(define-data-var contract-owner principal tx-sender)

;; Investment data structure
(define-map investments
  { production-id: uint, investor: principal }
  { amount: uint }
)

;; Total investment per production
(define-map production-totals
  { production-id: uint }
  { total-investment: uint }
)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Invest in a production
(define-public (invest (production-id uint) (amount uint))
  (let (
    (current-investment (default-to u0 (get amount (map-get? investments { production-id: production-id, investor: tx-sender }))))
    (current-total (default-to u0 (get total-investment (map-get? production-totals { production-id: production-id }))))
  )
    ;; For simplicity, we're not checking if the production is verified

    ;; Update investor's investment
    (map-set investments
      { production-id: production-id, investor: tx-sender }
      { amount: (+ current-investment amount) }
    )

    ;; Update total investment for production
    (map-set production-totals
      { production-id: production-id }
      { total-investment: (+ current-total amount) }
    )

    (ok true)
  )
)

;; Get investment amount for an investor in a production
(define-read-only (get-investment (production-id uint) (investor principal))
  (default-to u0 (get amount (map-get? investments { production-id: production-id, investor: investor })))
)

;; Get total investment for a production
(define-read-only (get-total-investment (production-id uint))
  (default-to u0 (get total-investment (map-get? production-totals { production-id: production-id })))
)

;; Calculate ownership percentage (returns basis points, i.e., 1/100 of a percent)
(define-read-only (get-ownership-percentage (production-id uint) (investor principal))
  (let (
    (investment (get-investment production-id investor))
    (total (get-total-investment production-id))
  )
    (if (is-eq total u0)
      u0
      (/ (* investment u10000) total)
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
