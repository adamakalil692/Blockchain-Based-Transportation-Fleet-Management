;; Maintenance Tracking Contract
;; Manages vehicle service and maintenance records

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Data structures
(define-map maintenance-records uint {
  vehicle: (string-ascii 20),
  service-type: (string-ascii 50),
  description: (string-ascii 200),
  cost: uint,
  mileage: uint,
  service-date: uint,
  next-service-due: uint,
  technician: (string-ascii 50),
  completed: bool
})

(define-map vehicle-maintenance-schedule (string-ascii 20) {
  last-service: uint,
  next-service: uint,
  service-interval: uint,
  total-maintenance-cost: uint
})

(define-data-var maintenance-counter uint u0)

;; Public functions
(define-public (record-maintenance
  (vehicle (string-ascii 20))
  (service-type (string-ascii 50))
  (description (string-ascii 200))
  (cost uint)
  (mileage uint)
  (next-service-due uint)
  (technician (string-ascii 50))
)
  (let ((record-id (+ (var-get maintenance-counter) u1)))
    (map-set maintenance-records record-id {
      vehicle: vehicle,
      service-type: service-type,
      description: description,
      cost: cost,
      mileage: mileage,
      service-date: block-height,
      next-service-due: next-service-due,
      technician: technician,
      completed: true
    })
    (update-vehicle-schedule vehicle cost next-service-due)
    (var-set maintenance-counter record-id)
    (ok record-id)
  )
)

(define-public (schedule-maintenance
  (vehicle (string-ascii 20))
  (service-type (string-ascii 50))
  (description (string-ascii 200))
  (estimated-cost uint)
  (scheduled-date uint)
)
  (let ((record-id (+ (var-get maintenance-counter) u1)))
    (map-set maintenance-records record-id {
      vehicle: vehicle,
      service-type: service-type,
      description: description,
      cost: estimated-cost,
      mileage: u0,
      service-date: scheduled-date,
      next-service-due: u0,
      technician: "",
      completed: false
    })
    (var-set maintenance-counter record-id)
    (ok record-id)
  )
)

(define-public (complete-maintenance (record-id uint) (actual-cost uint) (technician (string-ascii 50)))
  (begin
    (match (map-get? maintenance-records record-id)
      record-data
      (ok (map-set maintenance-records record-id (merge record-data {
        cost: actual-cost,
        technician: technician,
        completed: true
      })))
      err-not-found
    )
  )
)

;; Private functions
(define-private (update-vehicle-schedule (vehicle (string-ascii 20)) (cost uint) (next-service uint))
  (match (map-get? vehicle-maintenance-schedule vehicle)
    schedule-data
    (map-set vehicle-maintenance-schedule vehicle (merge schedule-data {
      last-service: block-height,
      next-service: next-service,
      total-maintenance-cost: (+ (get total-maintenance-cost schedule-data) cost)
    }))
    (map-set vehicle-maintenance-schedule vehicle {
      last-service: block-height,
      next-service: next-service,
      service-interval: u5000,
      total-maintenance-cost: cost
    })
  )
)

;; Read-only functions
(define-read-only (get-maintenance-record (record-id uint))
  (map-get? maintenance-records record-id)
)

(define-read-only (get-vehicle-schedule (vehicle (string-ascii 20)))
  (map-get? vehicle-maintenance-schedule vehicle)
)

(define-read-only (get-maintenance-count)
  (var-get maintenance-counter)
)

(define-read-only (is-maintenance-due (vehicle (string-ascii 20)))
  (match (map-get? vehicle-maintenance-schedule vehicle)
    schedule-data (>= block-height (get next-service schedule-data))
    false
  )
)

(define-read-only (get-total-maintenance-cost (vehicle (string-ascii 20)))
  (match (map-get? vehicle-maintenance-schedule vehicle)
    schedule-data (get total-maintenance-cost schedule-data)
    u0
  )
)
