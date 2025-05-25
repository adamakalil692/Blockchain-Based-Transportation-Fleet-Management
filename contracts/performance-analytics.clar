;; Performance Analytics Contract
;; Monitors and analyzes fleet efficiency metrics

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Data structures
(define-map vehicle-performance (string-ascii 20) {
  total-distance: uint,
  total-fuel-consumed: uint,
  total-trips: uint,
  average-speed: uint,
  fuel-efficiency: uint,
  uptime-percentage: uint,
  last-updated: uint
})

(define-map operator-performance principal {
  total-trips: uint,
  total-distance: uint,
  safety-score: uint,
  on-time-percentage: uint,
  fuel-efficiency-rating: uint,
  last-updated: uint
})

(define-map fleet-metrics uint {
  period-start: uint,
  period-end: uint,
  total-vehicles: uint,
  active-vehicles: uint,
  total-distance: uint,
  total-fuel-cost: uint,
  average-efficiency: uint,
  maintenance-cost: uint
})

(define-data-var metrics-counter uint u0)

;; Public functions
(define-public (update-vehicle-performance
  (vehicle (string-ascii 20))
  (distance uint)
  (fuel-consumed uint)
  (average-speed uint)
)
  (match (map-get? vehicle-performance vehicle)
    perf-data
    (let ((new-trips (+ (get total-trips perf-data) u1))
          (new-distance (+ (get total-distance perf-data) distance))
          (new-fuel (+ (get total-fuel-consumed perf-data) fuel-consumed))
          (fuel-eff (if (> new-fuel u0) (/ (* new-distance u100) new-fuel) u0)))
      (ok (map-set vehicle-performance vehicle {
        total-distance: new-distance,
        total-fuel-consumed: new-fuel,
        total-trips: new-trips,
        average-speed: average-speed,
        fuel-efficiency: fuel-eff,
        uptime-percentage: (get uptime-percentage perf-data),
        last-updated: block-height
      }))
    )
    (let ((fuel-eff (if (> fuel-consumed u0) (/ (* distance u100) fuel-consumed) u0)))
      (ok (map-set vehicle-performance vehicle {
        total-distance: distance,
        total-fuel-consumed: fuel-consumed,
        total-trips: u1,
        average-speed: average-speed,
        fuel-efficiency: fuel-eff,
        uptime-percentage: u100,
        last-updated: block-height
      }))
    )
  )
)

(define-public (update-operator-performance
  (operator principal)
  (distance uint)
  (safety-score uint)
  (on-time bool)
  (fuel-efficiency-rating uint)
)
  (match (map-get? operator-performance operator)
    perf-data
    (let ((new-trips (+ (get total-trips perf-data) u1))
          (new-distance (+ (get total-distance perf-data) distance))
          (current-on-time (get on-time-percentage perf-data))
          (new-on-time (if on-time
                         (/ (+ (* current-on-time (- new-trips u1)) u100) new-trips)
                         (/ (* current-on-time (- new-trips u1)) new-trips))))
      (ok (map-set operator-performance operator {
        total-trips: new-trips,
        total-distance: new-distance,
        safety-score: safety-score,
        on-time-percentage: new-on-time,
        fuel-efficiency-rating: fuel-efficiency-rating,
        last-updated: block-height
      }))
    )
    (ok (map-set operator-performance operator {
      total-trips: u1,
      total-distance: distance,
      safety-score: safety-score,
      on-time-percentage: (if on-time u100 u0),
      fuel-efficiency-rating: fuel-efficiency-rating,
      last-updated: block-height
    }))
  )
)

(define-public (record-fleet-metrics
  (total-vehicles uint)
  (active-vehicles uint)
  (total-distance uint)
  (total-fuel-cost uint)
  (maintenance-cost uint)
)
  (let ((metrics-id (+ (var-get metrics-counter) u1))
        (avg-eff (if (> total-fuel-cost u0) (/ (* total-distance u100) total-fuel-cost) u0)))
    (map-set fleet-metrics metrics-id {
      period-start: (- block-height u144), ;; ~24 hours ago
      period-end: block-height,
      total-vehicles: total-vehicles,
      active-vehicles: active-vehicles,
      total-distance: total-distance,
      total-fuel-cost: total-fuel-cost,
      average-efficiency: avg-eff,
      maintenance-cost: maintenance-cost
    })
    (var-set metrics-counter metrics-id)
    (ok metrics-id)
  )
)

;; Read-only functions
(define-read-only (get-vehicle-performance (vehicle (string-ascii 20)))
  (map-get? vehicle-performance vehicle)
)

(define-read-only (get-operator-performance (operator principal))
  (map-get? operator-performance operator)
)

(define-read-only (get-fleet-metrics (metrics-id uint))
  (map-get? fleet-metrics metrics-id)
)

(define-read-only (get-metrics-count)
  (var-get metrics-counter)
)

(define-read-only (calculate-fleet-efficiency)
  (let ((latest-id (var-get metrics-counter)))
    (match (map-get? fleet-metrics latest-id)
      metrics-data (get average-efficiency metrics-data)
      u0
    )
  )
)

(define-read-only (get-top-performing-vehicle)
  ;; This is a simplified version - in practice, you'd iterate through all vehicles
  ;; For now, returns a placeholder indicating the need for off-chain computation
  u0
)
