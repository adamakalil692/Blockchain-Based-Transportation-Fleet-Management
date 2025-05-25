;; Fleet Verification Contract
;; Validates vehicle operators and fleet managers

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Data structures
(define-map operators principal {
  name: (string-ascii 50),
  license-number: (string-ascii 20),
  verified: bool,
  registration-date: uint
})

(define-map fleet-managers principal {
  company-name: (string-ascii 100),
  verified: bool,
  registration-date: uint
})

;; Public functions
(define-public (register-operator (operator principal) (name (string-ascii 50)) (license-number (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? operators operator)) err-already-exists)
    (ok (map-set operators operator {
      name: name,
      license-number: license-number,
      verified: false,
      registration-date: block-height
    }))
  )
)

(define-public (verify-operator (operator principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? operators operator)
      operator-data (ok (map-set operators operator (merge operator-data { verified: true })))
      err-not-found
    )
  )
)

(define-public (register-fleet-manager (manager principal) (company-name (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? fleet-managers manager)) err-already-exists)
    (ok (map-set fleet-managers manager {
      company-name: company-name,
      verified: false,
      registration-date: block-height
    }))
  )
)

(define-public (verify-fleet-manager (manager principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? fleet-managers manager)
      manager-data (ok (map-set fleet-managers manager (merge manager-data { verified: true })))
      err-not-found
    )
  )
)

;; Read-only functions
(define-read-only (get-operator (operator principal))
  (map-get? operators operator)
)

(define-read-only (get-fleet-manager (manager principal))
  (map-get? fleet-managers manager)
)

(define-read-only (is-verified-operator (operator principal))
  (match (map-get? operators operator)
    operator-data (get verified operator-data)
    false
  )
)

(define-read-only (is-verified-fleet-manager (manager principal))
  (match (map-get? fleet-managers manager)
    manager-data (get verified manager-data)
    false
  )
)
