# Data Classification Guidance

Use this guide to classify stored application data by sensitivity, choose a
minimum storage control, and handle searchable sensitive fields without querying
plaintext. It complements `rules/global/security-baseline.md`, which covers
general OWASP-style security controls.

This pattern was validated in a production deployment in a PII-heavy domain. The
framework remains domain-agnostic; examples below use a generic user profile.

## Tier Model

| Tier | Definition | Generic user profile examples |
|---|---|---|
| T1 — Strictly confidential: legal criminal liability if exposed | Data whose exposure can trigger criminal liability, severe identity theft, or regulated critical-identity harm. | Government IDs, financial account numbers, biometric data |
| T2 — Confidential: personal information protection law obligations | Personal information protected by privacy law, contract, or user expectation. | Phone, full name, date of birth, address, nationality |
| T3 — Internal: business data not for external disclosure | Operational or business data that is not public but is not highly sensitive alone. | Application status, review notes, internal scores |
| T4 — Public: safe for external display | Data intended or acceptable for public display. | Company name, job title, industry category |

## Storage And Handling Requirements

| Tier | Minimum storage control | Key management | Logging and access |
|---|---|---|---|
| T1 | Strong symmetric encryption at rest, such as AES-256-GCM or an equivalent authenticated-encryption mode. | Key managed by KMS, HSM, or an equivalent managed secret service. | Access logged. Never write values to application logs, traces, analytics payloads, or error reports. |
| T2 | Strong symmetric encryption at rest, such as AES-256-GCM or an equivalent authenticated-encryption mode. | Key managed by KMS, HSM, or an equivalent managed secret service. | Never write values to application logs, traces, analytics payloads, or error reports. |
| T3 | Internal access control only. No field encryption is required unless the same record combines T3 with T1/T2 data and the storage boundary cannot isolate them. | Normal application secret management. | Internal-only visibility. Avoid logging when the value is combined with T1/T2 context. |
| T4 | No encryption required beyond normal platform controls. | Not applicable. | Public-facing display is acceptable. |

Algorithm recommendations are baseline guidance, not a library mandate. Use
well-maintained platform or framework cryptography APIs, and prefer authenticated
encryption for reversible sensitive-field storage.

## Searchable Encryption Pattern: Dual-Field

### Problem

Encrypted fields cannot be queried directly. Random nonces make correct
encryption non-deterministic, so the same plaintext produces different
ciphertext each time.

### Solution

For each searchable sensitive field, store two fields:

| Field | Purpose | Contents |
|---|---|---|
| `encrypted_value` | Display and decryption | AES-256-GCM encrypted plaintext, or equivalent AEAD ciphertext |
| `value_hash` | Query index and unique constraint | `HMAC-SHA256(plaintext, HMAC_KEY)` |

Query by recomputing the keyed hash from the user's input:

```sql
WHERE value_hash = hmac(input, HMAC_KEY)
```

Never query plaintext, and never use reversible encryption output as a lookup
token. The HMAC key must be different from the encryption key.

### Example

For a generic user profile phone number, store:

| Logical value | Stored field |
|---|---|
| Display value | `phone_encrypted_value` |
| Search value | `phone_value_hash` |

When a user searches by phone number, normalize the input, compute
`HMAC-SHA256(normalized_phone, HMAC_KEY)`, and query the hash column. Decrypt
only the records the caller is authorized to view.

## Encryption Implementation Rules

1. Centralize crypto logic in a single package or module. Do not scatter
   encryption, decryption, HMAC, nonce handling, or key-version checks across
   handlers and services.
2. Use a random nonce (IV) for every encryption operation. Store the encoded
   value as `nonce || ciphertext` in base64, with enough metadata to identify
   the algorithm and key version.
3. Never hardcode keys. Read keys from environment variables, KMS, HSM, or an
   equivalent managed secret path. Do not commit real keys, sample production
   keys, or copied key material.
4. Separate keys by purpose. Encryption keys and HMAC keys must be independent;
   compromise of one must not automatically compromise both confidentiality and
   lookup integrity.
5. Support key rotation. During the rotation window, write with the current key
   version and validate or decrypt against both current and previous accepted
   versions. After backfill and cutover, retire the previous version.
6. Keep plaintext lifetime short. Decrypt only at the boundary that needs the
   value, avoid passing plaintext through broad service objects, and redact it
   from errors, logs, metrics, and traces.

## Relationship To Constitutional Principles

Cross-reference: `docs/operating-rules.md` § "Constitutional principles".

- T1/T2 fields unencrypted in storage = violation of Constitutional Principle 1
  (Never expose credentials).
- Logging T1/T2 fields = violation of Constitutional Principle 1.
- Security tests that verify encryption, HMAC lookup, key separation, or log
  redaction must not be deleted, skipped, or weakened to make a suite pass.

## Implementation Checklist

- Classify each stored field as T1, T2, T3, or T4 before schema design.
- Encrypt T1/T2 values at rest with authenticated encryption.
- Keep T1/T2 values out of application logs and observability payloads.
- Add access logging for T1 reads and writes.
- Use the dual-field pattern for searchable T1/T2 values.
- Store `value_hash` with a keyed HMAC, not a plain hash.
- Keep HMAC keys separate from encryption keys.
- Route all crypto operations through one audited module.

## Standards Notes

- NIST FIPS 197 defines AES, including AES-256.
- NIST SP 800-38D defines GCM as an authenticated-encryption mode for approved
  symmetric block ciphers.
- NIST FIPS 198-1 defines HMAC with approved cryptographic hash functions.
- OWASP cryptographic storage and key-management guidance reinforces using
  established algorithms, managed key storage, independent keys, and planned key
  rotation instead of custom cryptography.
