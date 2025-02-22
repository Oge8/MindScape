;; MindScape: Decentralized Reflection Journal
;; A secure platform for storing and sharing personal reflections

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-reflection (err u101))
(define-constant err-invalid-release-date (err u102))
(define-constant err-reflection-not-found (err u103))
(define-constant err-theme-limit (err u104))
(define-constant err-invalid-theme (err u105))
(define-constant err-invalid-participant (err u106))
(define-constant err-not-in-shared-space (err u107))
(define-constant err-already-revealed (err u108))

;; Data Types
(define-map reflections
    { reflection-id: uint, creator: principal }
    {
        insight: (string-utf8 2048),
        creation-date: uint,
        release-date: uint,
        is-restricted: bool,
        is-hidden: bool,
        themes: (list 10 (string-utf8 32))
    }
)

;; New map for shared reflection space
(define-map shared-space
    uint  ;; reflection-id
    {
        creator: principal,
        is-revealed: bool,
        reveal-block: uint
    }
)

(define-map reflection-totals principal uint)
(define-map theme-directory { theme: (string-utf8 32) } (list 50 { reflection-id: uint, creator: principal }))
(define-data-var shared-space-counter uint u0)

;; Private Functions
(define-private (is-creator (reflection-id uint))
    (match (map-get? reflections {reflection-id: reflection-id, creator: tx-sender})
        entry true
        false)
)

(define-private (get-reflection-count-internal (user principal))
    (default-to u0 (map-get? reflection-totals user))
)

(define-private (validate-theme (theme (string-utf8 32)))
    (and (> (len theme) u0) (<= (len theme) u32))
)

(define-private (validate-theme-list (theme (string-utf8 32)) (valid bool))
    (and valid (validate-theme theme))
)

(define-private (validate-themes (themes (list 10 (string-utf8 32))))
    (and 
        (<= (len themes) u10)
        (fold validate-theme-list themes true)
    )
)

(define-private (validate-participant (user principal))
    (is-some (map-get? reflection-totals user))
)

(define-private (validate-bool (value bool))
    true
)

;; Generate reveal time for shared reflections
(define-private (generate-reveal-time)
    (let (
        (current-block block-height)
        (random-blocks (mod (var-get shared-space-counter) u144))
    )
        (+ current-block (+ u72 random-blocks))
    )
)

;; Public Functions
(define-public (create-reflection (insight (string-utf8 2048)) 
                               (release-date uint) 
                               (is-restricted bool)
                               (is-hidden bool)
                               (themes (list 10 (string-utf8 32))))
    (let (
        (reflection-id (get-reflection-count-internal tx-sender))
        (validated-restricted (validate-bool is-restricted))
        (validated-hidden (validate-bool is-hidden))
    )
        (begin
            (asserts! (> (len insight) u0) err-invalid-reflection)
            (asserts! (>= release-date block-height) err-invalid-release-date)
            (asserts! (validate-themes themes) err-invalid-theme)
            (asserts! validated-restricted err-unauthorized)
            (asserts! validated-hidden err-unauthorized)
            
            (map-set reflections
                { reflection-id: reflection-id, creator: tx-sender }
                {
                    insight: insight,
                    creation-date: block-height,
                    release-date: release-date,
                    is-restricted: is-restricted,
                    is-hidden: is-hidden,
                    themes: themes
                }
            )
            
            (map-set reflection-totals 
                tx-sender 
                (+ reflection-id u1))
            
            (if is-hidden
                (begin
                    (map-set shared-space
                        reflection-id
                        {
                            creator: tx-sender,
                            is-revealed: false,
                            reveal-block: (generate-reveal-time)
                        }
                    )
                    (var-set shared-space-counter (+ (var-get shared-space-counter) u1))
                    (ok reflection-id)
                )
                (ok reflection-id)
            )
        )
    )
)

(define-public (view-reflection (reflection-id uint) (creator principal))
    (let (
        (entry (unwrap! (map-get? reflections {reflection-id: reflection-id, creator: creator}) 
                         err-reflection-not-found))
        (shared-entry (map-get? shared-space reflection-id))
    )
        (begin
            (asserts! (or
                (is-eq tx-sender creator)
                (and
                    (not (get is-restricted entry))
                    (or
                        (>= block-height (get release-date entry))
                        (and
                            (is-some shared-entry)
                            (get is-revealed (unwrap! shared-entry err-not-in-shared-space))
                        )
                    )
                )
            ) err-unauthorized)
            
            (ok {
                insight: (get insight entry),
                creation-date: (get creation-date entry),
                themes: (get themes entry),
                hidden: (get is-hidden entry)
            })
        )
    )
)

(define-public (update-visibility (reflection-id uint) 
                               (is-restricted bool)
                               (is-hidden bool))
    (let ((entry (unwrap! (map-get? reflections 
                                   {reflection-id: reflection-id, creator: tx-sender})
                         err-reflection-not-found)))
        (begin
            (asserts! (is-creator reflection-id) err-unauthorized)
            (asserts! (validate-bool is-restricted) err-unauthorized)
            (asserts! (validate-bool is-hidden) err-unauthorized)
            
            (map-set reflections
                { reflection-id: reflection-id, creator: tx-sender }
                (merge entry {
                    is-restricted: is-restricted,
                    is-hidden: is-hidden
                })
            )
            (ok true)
        )
    )
)

(define-public (check-shared-reflection-status (reflection-id uint))
    (let ((entry (unwrap! (map-get? shared-space reflection-id) err-not-in-shared-space)))
        (begin
            (if (and
                    (not (get is-revealed entry))
                    (>= block-height (get reveal-block entry))
                )
                (begin
                    (map-set shared-space
                        reflection-id
                        (merge entry { is-revealed: true })
                    )
                    (ok true)
                )
                (ok false)
            )
        )
    )
)

(define-public (get-reflection-count (user principal))
    (begin
        (asserts! (validate-participant user) err-invalid-participant)
        (ok (get-reflection-count-internal user))
    )
)

(define-public (get-public-reflections-by-theme (theme (string-utf8 32)))
    (begin
        (asserts! (validate-theme theme) err-invalid-theme)
        (ok (default-to (list) (map-get? theme-directory {theme: theme})))
    )
)

(define-public (add-theme-to-directory (reflection-id uint) (theme (string-utf8 32)))
    (begin
        (asserts! (validate-theme theme) err-invalid-theme)
        (let (
            (current-entries (default-to (list) (map-get? theme-directory {theme: theme})))
            (new-entry {reflection-id: reflection-id, creator: tx-sender})
        )
            (if (< (len current-entries) u50)
                (begin
                    (map-set theme-directory 
                        {theme: theme}
                        (unwrap! (as-max-len? (concat current-entries (list new-entry)) u50)
                                err-theme-limit))
                    (ok true))
                err-theme-limit)
        )
    )
)