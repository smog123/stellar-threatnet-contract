# SorobanThreatNet — On-Chain Threat Registry

A Soroban (Stellar) smart contract storing **SHA-256 hashes** of confirmed
threat indicators (malicious wallet addresses, phishing domains, scam tokens)
directly on the Stellar ledger. Clients can verify an indicator against the
ledger without trusting the ThreatNet API — zero-trust verification.

This is the **contract repository** for Stellar ThreatNet. The application
layer (API, dashboard, SDKs, CLI, extension) lives in
[`stellar-threatnet-app`](https://github.com/smog123/stellar-threatnet-app).

The authoritative, function-by-function contract specification is in
[`SPEC.md`](SPEC.md); the coding-agent system prompt is in
[`AGENT_SYSTEM_PROMPT.md`](AGENT_SYSTEM_PROMPT.md).

## Why hashes?

Raw wallet addresses and domains are sensitive indicators. The contract stores
only `BytesN<32>` SHA-256 hashes, so the ledger never leaks the underlying
values. The off-chain ThreatNet API maps values → hashes for lookups.

## API

| Function | Description |
| --- | --- |
| `initialize(admin)` | Set the admin address (call once). |
| `publish_threat_indicator(admin, hash, level, score)` | Insert/update an indicator. Admin only. |
| `get_threat_indicator(hash)` | Read an indicator record. |
| `get_total_indicators()` | Count of published indicators. |

`ThreatLevel`: `Trusted=0`, `UnderInvestigation=1`, `Suspicious=2`,
`ConfirmedMalicious=3`.

## Build & test

Requires Rust stable (2024+). Toolchain is not pinned — the current
`soroban-sdk 27` works with modern rustc.

```bash
cargo test                                   # unit tests (host)
# Rust 1.82+ must use the wasm32v1-none target (Soroban-optimized wasm)
rustup target add wasm32v1-none
cargo build --target wasm32v1-none --release
```

## Deploy

```bash
# Install the soroban CLI, then:
soroban contract deploy --wasm target/wasm32v1-none/release/soroban_threatnet.wasm \
  --source <admin-secret> --network testnet --rpc-url https://soroban-testnet.stellar.org
soroban contract invoke --id <CONTRACT_ID> --source <admin-secret> --network testnet \
  -- initialize --admin <ADMIN_ADDRESS>
```

> Note: the maintained stellar-cli is a drop-in for `soroban`; for deploy it
> needs `--rpc-url` plus `--network-passphrase` (the deploy script resolves the
> passphrase from `NETWORK` automatically).

## Deployed addresses

| Network | Contract ID |
| --- | --- |
| Testnet | [`CB34YG3ZGQ3FGK32D6GMMFKKK4SPWN5QURF4VCCQ67ZHBILJBH2KBCG5`](https://stellar.expert/explorer/testnet/contract/CB34YG3ZGQ3FGK32D6GMMFKKK4SPWN5QURF4VCCQ67ZHBILJBH2KBCG5) |

Deployed 2026-08-08 via `scripts/deploy.sh` (stellar-cli 27.1.0);
`initialize(admin: GASHO6ZALWWEDTLUSXWSLMWBLX3EK3PXJMJX5IBCYQKVQDMJARHP3HYL)`
executed once. Mainnet deployment is pending.

## Security notes

- Only the admin can publish. Rotation requires a governance change.
- `publish` requires `admin.require_auth()` — the caller must own the admin key.
- Scores are clamped to 0–100 on-chain.
- An untracked hash returns `None` — absence of an on-chain record is *not* a
  trust signal; treat it as unknown.
