(define-constant CONTRACT-OWNER tx-sender)

(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-CREDENTIAL (err u103))
(define-constant ERR-EXPIRED (err u104))
(define-constant ERR-REVOKED (err u105))
(define-constant ERR-INVALID-INSTITUTION (err u106))
(define-constant ERR-BATCH-TOO-LARGE (err u107))
(define-constant ERR-PARTIAL-FAILURE (err u108))

(define-non-fungible-token credential-nft uint)

(define-data-var next-credential-id uint u1)
(define-data-var contract-active bool true)
(define-data-var max-batch-size uint u20)

(define-map credentials
  { credential-id: uint }
  {
    recipient: principal,
    institution: principal,
    credential-type: (string-ascii 50),
    field-of-study: (string-ascii 100),
    issue-date: uint,
    expiry-date: (optional uint),
    bitcoin-block-height: uint,
    metadata-uri: (string-ascii 200),
    is-revoked: bool,
    grade: (optional (string-ascii 10))
  }
)

(define-map institutions
  { institution: principal }
  {
    name: (string-ascii 100),
    authorized: bool,
    registration-date: uint,
    country: (string-ascii 50),
    accreditation-level: (string-ascii 30)
  }
)

(define-map recipient-credentials
  { recipient: principal }
  { credential-ids: (list 100 uint) }
)

(define-map institution-stats
  { institution: principal }
  {
    total-issued: uint,
    total-revoked: uint,
    last-activity: uint
  }
)

(define-map batch-operations
  { batch-id: uint }
  {
    institution: principal,
    operation-type: (string-ascii 20),
    total-count: uint,
    success-count: uint,
    block-height: uint
  }
)

(define-data-var next-batch-id uint u1)

(define-read-only (get-contract-info)
  {
    owner: CONTRACT-OWNER,
    active: (var-get contract-active),
    next-id: (var-get next-credential-id),
    max-batch-size: (var-get max-batch-size),
    next-batch-id: (var-get next-batch-id)
  }
)

(define-read-only (get-credential (credential-id uint))
  (map-get? credentials { credential-id: credential-id })
)

(define-read-only (get-institution (institution principal))
  (map-get? institutions { institution: institution })
)

(define-read-only (get-recipient-credentials (recipient principal))
  (default-to 
    { credential-ids: (list) }
    (map-get? recipient-credentials { recipient: recipient })
  )
)

(define-read-only (get-institution-stats (institution principal))
  (default-to
    { total-issued: u0, total-revoked: u0, last-activity: u0 }
    (map-get? institution-stats { institution: institution })
  )
)

(define-read-only (verify-credential (credential-id uint))
  (match (get-credential credential-id)
    credential-data
    (let
      (
        (current-block burn-block-height)
      )
      (ok {
        valid: (and 
          (not (get is-revoked credential-data))
          (match (get expiry-date credential-data)
            expiry (< current-block expiry)
            true
          )
        ),
        credential: credential-data,
        verification-block: current-block
      })
    )
    ERR-NOT-FOUND
  )
)

(define-read-only (is-institution-authorized (institution principal))
  (match (get-institution institution)
    inst-data (get authorized inst-data)
    false
  )
)

(define-read-only (get-credential-owner (credential-id uint))
  (nft-get-owner? credential-nft credential-id)
)

(define-read-only (count-valid-credentials (recipient principal))
  (let
    (
      (recipient-data (get-recipient-credentials recipient))
      (credential-ids (get credential-ids recipient-data))
    )
    (fold check-and-count-valid credential-ids u0)
  )
)

(define-private (check-and-count-valid (credential-id uint) (count uint))
  (match (verify-credential credential-id)
    ok-value (if (get valid ok-value) (+ count u1) count)
    err-value count
  )
)

(define-read-only (get-batch-operation (batch-id uint))
  (map-get? batch-operations { batch-id: batch-id })
)

(define-read-only (batch-verify-credentials (credential-ids (list 20 uint)))
  (ok (map verify-single-credential credential-ids))
)

(define-private (verify-single-credential (credential-id uint))
  {
    credential-id: credential-id,
    verification: (verify-credential credential-id)
  }
)

(define-public (register-institution 
  (name (string-ascii 100))
  (country (string-ascii 50))
  (accreditation-level (string-ascii 30))
  )
  (begin
    (asserts! (var-get contract-active) ERR-UNAUTHORIZED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (is-none (get-institution tx-sender)) ERR-ALREADY-EXISTS)
    
    (map-set institutions
      { institution: tx-sender }
      {
        name: name,
        authorized: true,
        registration-date: burn-block-height,
        country: country,
        accreditation-level: accreditation-level
      }
    )
    
    (map-set institution-stats
      { institution: tx-sender }
      {
        total-issued: u0,
        total-revoked: u0,
        last-activity: burn-block-height
      }
    )
    
    (ok tx-sender)
  )
)

(define-public (issue-credential
  (recipient principal)
  (credential-type (string-ascii 50))
  (field-of-study (string-ascii 100))
  (expiry-blocks (optional uint))
  (metadata-uri (string-ascii 200))
  (grade (optional (string-ascii 10)))
  )
  (let
    (
      (credential-id (var-get next-credential-id))
      (current-block burn-block-height)
    )
    (begin
      (asserts! (var-get contract-active) ERR-UNAUTHORIZED)
      (asserts! (is-institution-authorized tx-sender) ERR-UNAUTHORIZED)
      
      (try! (nft-mint? credential-nft credential-id recipient))
      
      (map-set credentials
        { credential-id: credential-id }
        {
          recipient: recipient,
          institution: tx-sender,
          credential-type: credential-type,
          field-of-study: field-of-study,
          issue-date: current-block,
          expiry-date: expiry-blocks,
          bitcoin-block-height: current-block,
          metadata-uri: metadata-uri,
          is-revoked: false,
          grade: grade
        }
      )
      
      (update-recipient-credentials recipient credential-id)
      (update-institution-stats tx-sender true)
      
      (var-set next-credential-id (+ credential-id u1))
      
      (ok credential-id)
    )
  )
)

(define-private (update-recipient-credentials (recipient principal) (credential-id uint))
  (let
    (
      (current-credentials (get credential-ids (get-recipient-credentials recipient)))
    )
    (map-set recipient-credentials
      { recipient: recipient }
      { credential-ids: (unwrap-panic (as-max-len? (append current-credentials credential-id) u100)) }
    )
  )
)

(define-private (update-institution-stats (institution principal) (is-issue bool))
  (let
    (
      (current-stats (get-institution-stats institution))
    )
    (map-set institution-stats
      { institution: institution }
      {
        total-issued: (if is-issue 
          (+ (get total-issued current-stats) u1)
          (get total-issued current-stats)
        ),
        total-revoked: (if is-issue 
          (get total-revoked current-stats)
          (+ (get total-revoked current-stats) u1)
        ),
        last-activity: burn-block-height
      }
    )
  )
)

(define-public (revoke-credential (credential-id uint))
  (let
    (
      (credential-data (unwrap! (get-credential credential-id) ERR-NOT-FOUND))
    )
    (begin
      (asserts! (var-get contract-active) ERR-UNAUTHORIZED)
      (asserts! (is-eq tx-sender (get institution credential-data)) ERR-UNAUTHORIZED)
      (asserts! (not (get is-revoked credential-data)) ERR-REVOKED)
      
      (map-set credentials
        { credential-id: credential-id }
        (merge credential-data { is-revoked: true })
      )
      
      (update-institution-stats tx-sender false)
      
      (ok credential-id)
    )
  )
)

(define-public (transfer-credential (credential-id uint) (new-recipient principal))
  (let
    (
      (credential-data (unwrap! (get-credential credential-id) ERR-NOT-FOUND))
    )
    (begin
      (asserts! (var-get contract-active) ERR-UNAUTHORIZED)
      (asserts! (is-eq tx-sender (get recipient credential-data)) ERR-UNAUTHORIZED)
      (asserts! (not (get is-revoked credential-data)) ERR-REVOKED)
      
      (try! (nft-transfer? credential-nft credential-id tx-sender new-recipient))
      
      (map-set credentials
        { credential-id: credential-id }
        (merge credential-data { recipient: new-recipient })
      )
      
      (update-recipient-credentials new-recipient credential-id)
      
      (ok credential-id)
    )
  )
)

(define-public (deauthorize-institution (institution principal))
  (let
    (
      (institution-data (unwrap! (get-institution institution) ERR-NOT-FOUND))
    )
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
      
      (map-set institutions
        { institution: institution }
        (merge institution-data { authorized: false })
      )
      
      (ok institution)
    )
  )
)

(define-public (emergency-pause)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set contract-active false)
    (ok true)
  )
)

(define-public (resume-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set contract-active true)
    (ok true)
  )
)

(define-public (batch-issue-credentials
  (recipients (list 20 principal))
  (credential-type (string-ascii 50))
  (field-of-study (string-ascii 100))
  (expiry-blocks (optional uint))
  (metadata-uri (string-ascii 200))
  (grades (list 20 (optional (string-ascii 10))))
  )
  (let
    (
      (batch-id (var-get next-batch-id))
      (batch-size (len recipients))
      (batch-data {
        cred-type: credential-type,
        field: field-of-study,
        expiry: expiry-blocks,
        uri: metadata-uri
      })
    )
    (begin
      (asserts! (var-get contract-active) ERR-UNAUTHORIZED)
      (asserts! (is-institution-authorized tx-sender) ERR-UNAUTHORIZED)
      (asserts! (<= batch-size (var-get max-batch-size)) ERR-BATCH-TOO-LARGE)
      (asserts! (is-eq (len recipients) (len grades)) ERR-INVALID-CREDENTIAL)
      
      (let
        (
          (paired-data (map create-recipient-grade-pair recipients grades))
          (results (map process-batch-credential paired-data))
          (success-count (fold count-successes results u0))
        )
        (begin
          (map-set batch-operations
            { batch-id: batch-id }
            {
              institution: tx-sender,
              operation-type: "issue",
              total-count: batch-size,
              success-count: success-count,
              block-height: burn-block-height
            }
          )
          
          (var-set next-batch-id (+ batch-id u1))
          
          (if (is-eq success-count batch-size)
            (ok { batch-id: batch-id, results: results })
            ERR-PARTIAL-FAILURE
          )
        )
      )
    )
  )
)

(define-private (create-recipient-grade-pair 
  (recipient principal) 
  (grade (optional (string-ascii 10)))
  )
  {
    recipient: recipient,
    grade: grade
  }
)

(define-private (process-batch-credential 
  (pair { recipient: principal, grade: (optional (string-ascii 10)) })
  )
  (let
    (
      (credential-id (var-get next-credential-id))
      (current-block burn-block-height)
      (recipient (get recipient pair))
      (grade (get grade pair))
    )
    (match (nft-mint? credential-nft credential-id recipient)
      success
      (begin
        (map-set credentials
          { credential-id: credential-id }
          {
            recipient: recipient,
            institution: tx-sender,
            credential-type: "batch-issued",
            field-of-study: "batch-issued",
            issue-date: current-block,
            expiry-date: none,
            bitcoin-block-height: current-block,
            metadata-uri: "batch-operation",
            is-revoked: false,
            grade: grade
          }
        )
        
        (update-recipient-credentials recipient credential-id)
        (update-institution-stats tx-sender true)
        (var-set next-credential-id (+ credential-id u1))
        
        { success: true, credential-id: (some credential-id) }
      )
      error { success: false, credential-id: none }
    )
  )
)

(define-private (count-successes 
  (result { success: bool, credential-id: (optional uint) }) 
  (count uint)
  )
  (if (get success result) (+ count u1) count)
)

(define-public (update-batch-size (new-size uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (and (> new-size u0) (<= new-size u50)) ERR-INVALID-CREDENTIAL)
    (var-set max-batch-size new-size)
    (ok new-size)
  )
)

