;; performance-tracking.clar
;; Records ticket sales and attendance

(define-data-var contract-owner principal tx-sender)

;; Performance data structure
(define-map performances
  { production-id: uint, performance-id: uint }
  {
    date: uint,
    tickets-sold: uint,
    attendance: uint,
    revenue: uint
  }
)

;; Performance counter per production
(define-map performance-counters
  { production-id: uint }
  { next-performance-id: uint }
)

;; Total revenue per production
(define-map production-revenues
  { production-id: uint }
  { total-revenue: uint }
)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Add a new performance
(define-public (add-performance (production-id uint) (date uint))
  (let (
    (next-id (default-to u1 (get next-performance-id (map-get? performance-counters { production-id: production-id }))))
  )
    ;; Add performance
    (map-set performances
      { production-id: production-id, performance-id: next-id }
      {
        date: date,
        tickets-sold: u0,
        attendance: u0,
        revenue: u0
      }
    )

    ;; Update counter
    (map-set performance-counters
      { production-id: production-id }
      { next-performance-id: (+ next-id u1) }
    )

    (ok next-id)
  )
)

;; Update performance data
(define-public (update-performance-data
    (production-id uint)
    (performance-id uint)
    (tickets-sold uint)
    (attendance uint)
    (revenue uint)
  )
  (let (
    (performance (map-get? performances { production-id: production-id, performance-id: performance-id }))
    (current-total-revenue (default-to u0 (get total-revenue (map-get? production-revenues { production-id: production-id }))))
    (old-revenue (if (is-some performance) (get revenue (unwrap-panic performance)) u0))
  )
    (if (is-some performance)
      (begin
        ;; Update performance data
        (map-set performances
          { production-id: production-id, performance-id: performance-id }
          {
            date: (get date (unwrap-panic performance)),
            tickets-sold: tickets-sold,
            attendance: attendance,
            revenue: revenue
          }
        )

        ;; Update total revenue
        (map-set production-revenues
          { production-id: production-id }
          { total-revenue: (+ (- current-total-revenue old-revenue) revenue) }
        )

        (ok true)
      )
      (err u404)
    )
  )
)

;; Get performance details
(define-read-only (get-performance (production-id uint) (performance-id uint))
  (map-get? performances { production-id: production-id, performance-id: performance-id })
)

;; Get total revenue for a production
(define-read-only (get-total-revenue (production-id uint))
  (default-to u0 (get total-revenue (map-get? production-revenues { production-id: production-id })))
)

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) (err u403))
    (var-set contract-owner new-owner)
    (ok true)
  )
)
