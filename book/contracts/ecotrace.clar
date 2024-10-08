;; Product Registry Contract
;; Manages the registration and tracking of sustainable products

(define-constant contract-owner tx-sender)

;; Data variables
(define-map products
    {product-id: (string-ascii 36)}
    {
        manufacturer: principal,
        name: (string-ascii 64),
        description: (string-ascii 256),
        creation-date: uint,
        origin: (string-ascii 64),
        certifications: (list 10 (string-ascii 32))
    }
)

;; Error constants
(define-constant err-not-owner (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-not-found (err u102))

;; Public functions
(define-public (register-product 
    (product-id (string-ascii 36))
    (name (string-ascii 64))
    (description (string-ascii 256))
    (origin (string-ascii 64))
    (certifications (list 10 (string-ascii 32))))
    (let
        ((product-data {
            manufacturer: tx-sender,
            name: name,
            description: description,
            creation-date: block-height,
            origin: origin,
            certifications: certifications
        }))
        (asserts! (is-eq tx-sender contract-owner) err-not-owner)
        (asserts! (is-none (map-get? products {product-id: product-id})) err-already-exists)
        (ok (map-set products {product-id: product-id} product-data))
    )
)

;; Read-only functions
(define-read-only (get-product (product-id (string-ascii 36)))
    (match (map-get? products {product-id: product-id})
        product (ok product)
        err-not-found
    )
)

;; Administrative functions
(define-public (update-product-certifications 
    (product-id (string-ascii 36))
    (new-certifications (list 10 (string-ascii 32))))
    (let ((existing-product (unwrap! (map-get? products {product-id: product-id}) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-not-owner)
        (ok (map-set products 
            {product-id: product-id}
            (merge existing-product {certifications: new-certifications})
        ))
    )
)