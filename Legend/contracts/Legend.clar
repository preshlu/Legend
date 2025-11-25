;; LegendaryWeapons - Mythical Arms Bazaar Contract
;; Import standard libraries

;; Error declarations
(define-constant err-permission-denied (err u100))
(define-constant err-not-wielder (err u101))
(define-constant err-sale-inactive (err u102))
(define-constant err-bid-inadequate (err u103))
(define-constant err-weapon-missing (err u104))
(define-constant err-forge-data-invalid (err u105))
(define-constant err-tribute-limit-exceeded (err u106))
(define-constant err-empty-principal (err u107))

;; NFT definition
(define-non-fungible-token legendary-weapon uint)

;; State management
(define-data-var armory-master principal tx-sender)
(define-data-var weapon-count uint u1)

;; Storage structures
(define-map weapons-vault
  { weapon-id: uint }
  { wielder: principal, blacksmith: principal, enchantment: (string-ascii 256), forge-tribute: uint })

(define-map arms-market
  { weapon-id: uint }
  { sale-price: uint, merchant: principal })

;; Authorization helper
(define-private (confirm-master)
  (is-eq tx-sender (var-get armory-master)))

;; Principal validation
(define-private (validate-principal (principal-addr principal))
  (not (is-eq principal-addr 'SP000000000000000000002Q6VF78)))

;; Change master
(define-public (enthrone-master (successor principal))
  (begin
    (asserts! (confirm-master) err-permission-denied)
    (asserts! (validate-principal successor) err-empty-principal)
    (ok (var-set armory-master successor))
  ))

;; Retrieve master
(define-read-only (get-current-master)
  (ok (var-get armory-master)))

;; Forge weapon
(define-public (forge-weapon (enchantment (string-ascii 256)) (forge-tribute uint))
  (let ((weapon-id (var-get weapon-count)))
    (asserts! (> (len enchantment) u0) err-forge-data-invalid)
    (asserts! (<= forge-tribute u1000) err-tribute-limit-exceeded)
    (try! (nft-mint? legendary-weapon weapon-id tx-sender))
    (map-set weapons-vault
      { weapon-id: weapon-id }
      { wielder: tx-sender, blacksmith: tx-sender, enchantment: enchantment, forge-tribute: forge-tribute }
    )
    (var-set weapon-count (+ weapon-id u1))
    (ok weapon-id)
  ))

;; Initiate sale
(define-public (initiate-sale (weapon-id uint) (sale-price uint))
  (let ((current-wielder (unwrap! (nft-get-owner? legendary-weapon weapon-id) err-weapon-missing)))
    (asserts! (> sale-price u0) err-bid-inadequate)
    (asserts! (is-eq tx-sender current-wielder) err-not-wielder)
    (map-set arms-market
      { weapon-id: weapon-id }
      { sale-price: sale-price, merchant: tx-sender }
    )
    (ok true)
  ))

;; Terminate sale
(define-public (terminate-sale (weapon-id uint))
  (let ((market-entry (unwrap! (map-get? arms-market { weapon-id: weapon-id }) err-sale-inactive)))
    (asserts! (< weapon-id (var-get weapon-count)) err-weapon-missing)
    (asserts! (is-eq tx-sender (get merchant market-entry)) err-not-wielder)
    (map-delete arms-market { weapon-id: weapon-id })
    (ok true)
  ))

;; Complete purchase
(define-public (claim-weapon (weapon-id uint))
  (let
    (
      (market-entry (unwrap! (map-get? arms-market { weapon-id: weapon-id }) err-sale-inactive))
      (final-price (get sale-price market-entry))
      (selling-merchant (get merchant market-entry))
      (weapon-record (unwrap! (map-get? weapons-vault { weapon-id: weapon-id }) err-weapon-missing))
      (original-blacksmith (get blacksmith weapon-record))
      (tribute-percentage (get forge-tribute weapon-record))
      (blacksmith-payment (/ (* final-price tribute-percentage) u10000))
      (merchant-payment (- final-price blacksmith-payment))
    )
    (asserts! (< weapon-id (var-get weapon-count)) err-weapon-missing)
    (try! (stx-transfer? blacksmith-payment tx-sender original-blacksmith))
    (try! (stx-transfer? merchant-payment tx-sender selling-merchant))
    (try! (nft-transfer? legendary-weapon weapon-id selling-merchant tx-sender))
    (map-set weapons-vault
      { weapon-id: weapon-id }
      (merge weapon-record { wielder: tx-sender })
    )
    (map-delete arms-market { weapon-id: weapon-id })
    (ok true)
  ))

;; Query weapon
(define-read-only (inspect-weapon (weapon-id uint))
  (ok (unwrap! (map-get? weapons-vault { weapon-id: weapon-id }) err-weapon-missing)))

;; Query sale
(define-read-only (inspect-sale (weapon-id uint))
  (ok (unwrap! (map-get? arms-market { weapon-id: weapon-id }) err-sale-inactive)))