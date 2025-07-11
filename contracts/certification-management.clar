;; Certification Management Contract
;; Manages sustainability certifications for materials and suppliers

(define-map certifications
  { cert-id: uint }
  {
    name: (string-ascii 100),
    issuer: (string-ascii 100),
    standard: (string-ascii 50),
    validity-period: uint,
    active: bool
  }
)

(define-map supplier-certifications
  { supplier-id: uint, cert-id: uint }
  {
    issue-date: uint,
    expiry-date: uint,
    status: (string-ascii 20)
  }
)

(define-map material-certifications
  { material-id: uint, cert-id: uint }
  {
    certified-date: uint,
    valid: bool
  }
)

(define-data-var next-cert-id uint u1)

;; Create new certification standard
(define-public (create-certification
  (name (string-ascii 100))
  (issuer (string-ascii 100))
  (standard (string-ascii 50))
  (validity-period uint)
)
  (let ((cert-id (var-get next-cert-id)))
    (map-set certifications
      { cert-id: cert-id }
      {
        name: name,
        issuer: issuer,
        standard: standard,
        validity-period: validity-period,
        active: true
      }
    )
    (var-set next-cert-id (+ cert-id u1))
    (ok cert-id)
  )
)

;; Certify a supplier
(define-public (certify-supplier (supplier-id uint) (cert-id uint))
  (match (map-get? certifications { cert-id: cert-id })
    cert-data
    (if (get active cert-data)
      (begin
        (map-set supplier-certifications
          { supplier-id: supplier-id, cert-id: cert-id }
          {
            issue-date: block-height,
            expiry-date: (+ block-height (get validity-period cert-data)),
            status: "active"
          }
        )
        (ok true)
      )
      (err u400)
    )
    (err u404)
  )
)

;; Certify a material
(define-public (certify-material (material-id uint) (cert-id uint))
  (match (map-get? certifications { cert-id: cert-id })
    cert-data
    (if (get active cert-data)
      (begin
        (map-set material-certifications
          { material-id: material-id, cert-id: cert-id }
          {
            certified-date: block-height,
            valid: true
          }
        )
        (ok true)
      )
      (err u400)
    )
    (err u404)
  )
)

;; Get certification details
(define-read-only (get-certification (cert-id uint))
  (map-get? certifications { cert-id: cert-id })
)

;; Check if supplier has valid certification
(define-read-only (is-supplier-certified (supplier-id uint) (cert-id uint))
  (match (map-get? supplier-certifications { supplier-id: supplier-id, cert-id: cert-id })
    cert-data
    (and
      (is-eq (get status cert-data) "active")
      (> (get expiry-date cert-data) block-height)
    )
    false
  )
)
