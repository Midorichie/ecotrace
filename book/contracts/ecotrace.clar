;; Supply Chain Verification Contract
;; Handles the verification of supply chain steps and participant management

(use-trait product-trait .product-registry.product-trait)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-invalid-step (err u102))
(define-constant err-step-already-verified (err u103))

;; Data maps
(define-map authorized-verifiers principal bool)

(define-map supply-chain-steps
    {product-id: (string-ascii 36), step-id: uint}
    {
        verifier: principal,
        timestamp: uint,
        location: (string-ascii 64),
        details: (string-ascii 256),
        carbon-impact: uint,
        proof-hash: (buff 32)
    }
)

;; Private functions
(define-private (is-authorized-verifier (account principal))
    (default-to false (map-get? authorized-verifiers account))
)

;; Public functions
(define-public (add-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-not-owner)
        (ok (map-set authorized-verifiers verifier true))
    )
)

(define-public (remove-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-not-owner)
        (ok (map-delete authorized-verifiers verifier))
    )
)

(define-public (verify-supply-chain-step
    (product-id (string-ascii 36))
    (step-id uint)
    (location (string-ascii 64))
    (details (string-ascii 256))
    (carbon-impact uint)
    (proof-hash (buff 32)))
    (let
        ((step-data {
            verifier: tx-sender,
            timestamp: block-height,
            location: location,
            details: details,
            carbon-impact: carbon-impact,
            proof-hash: proof-hash
        }))
        (asserts! (is-authorized-verifier tx-sender) err-not-authorized)
        (asserts! (is-none (map-get? supply-chain-steps {product-id: product-id, step-id: step-id})) err-step-already-verified)
        (ok (map-set supply-chain-steps {product-id: product-id, step-id: step-id} step-data))
    )
)

;; Read-only functions
(define-read-only (get-step-verification
    (product-id (string-ascii 36))
    (step-id uint))
    (map-get? supply-chain-steps {product-id: product-id, step-id: step-id})
)

(define-read-only (is-step-verified
    (product-id (string-ascii 36))
    (step-id uint))
    (is-some (map-get? supply-chain-steps {product-id: product-id, step-id: step-id}))
)

;; Verification checks
(define-public (verify-complete-chain
    (product-id (string-ascii 36))
    (required-steps uint))
    (let
        ((verified-steps (fold check-step-verified 
            (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10)
            u0)))
        (ok (>= verified-steps required-steps))
    )
)

(define-private (check-step-verified (step uint) (acc uint))
    (if (is-step-verified product-id step)
        (+ acc u1)
        acc
    )
)