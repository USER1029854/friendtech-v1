# Unresolved / Not-Readable-On-Chain

This is the explicit list of everything that could bear on the target's security but is **not** fully
readable from on-chain code. Keep it short by design: the friend.tech V1 graph is small and almost
entirely verified. There are **no unverified contracts, no undecompiled bytecode, and no black boxes**
in the value path — so the "decompile + extract constants + simulate" recovery workflow did not need
to be applied to any contract (every node is verified source; the Safe stack is additionally proven
byte-identical to canonical upstream). What remains open is two off-chain / key-custody items.

---

## 1. The three fee-Safe signer keys (off-chain key custody)

* **What they are:** the 2-of-3 EOAs controlling the fee Safe `0x831be9…ef430`
  (`0x68d49950…2f40ce`, `0xdd9176ea…403f742` = deployer, `0xddc4f58f…56000e3`).
* **What they control *now*:** only the Safe's own **~14.82 ETH** of accumulated protocol fees. Any 2
  of them can move that balance anywhere. They do **not** control the target's 913.58 ETH reserve,
  because the target's ownership is renounced (`owner() = 0x0`).
* **What they controlled *historically*:** from 2023-12-02 to 2024-09-07 the Safe was the target's
  **admin** — 2 of these 3 keys could have re-pointed `protocolFeeDestination` or changed either fee
  rate. That window is closed (renounced), but it is part of the system's trust history.
* **Why it can't be resolved further:** a private key has no bytecode and no address-level state to
  read. Off-chain custody (hardware wallet? shared? hot key?) is unknowable from the chain.
* **Evidence that bounds it:** Safe `nonce = 39` and its tx history show the multisig was actively,
  normally operated by these three EOAs through the 2024-09 renounce; **no modules and no guard** are
  installed (so no hidden bypass of the 2-of-3). See [`state/authority.md`](./state/authority.md).
* **What would go wrong if compromised:** loss of the Safe's ~14.82 ETH only. No path to the target's
  reserve. (This is scope-bounding, not an exploitability verdict.)

## 2. The friend.tech off-chain backend / API (social & eligibility layer)

* **What it is:** friend.tech's off-chain service that maps X/Twitter accounts ⇄ `sharesSubject`
  addresses, gates the app UI/login, and historically ran points/airdrop accounting.
* **What decision it controls:** *which* curves the app surfaces and *who* the UI lets trade, plus
  off-chain reward accounting — a **social/eligibility** layer.
* **Crucial scoping fact (evidenced from the target's own code):** in V1 this backend is **NOT in the
  on-chain trust path of the funds.** `buyShares`/`sellShares` contain **no `ecrecover`, no signature
  parameter, no oracle/backend call** — the contract never consults the backend. Anyone can trade any
  subject directly against the contract (proven by the permissionless-`buyShares` simulation in
  [`integrity/README.md`](./integrity/README.md)). Therefore a compromise of the backend **cannot**
  mint shares, drain the reserve, or change fees; its blast radius is the app experience and off-chain
  points, not the 913.58 ETH.
* **Why it's listed anyway:** it is a real off-chain component in the *product*, and naming it (and
  its bounded blast radius) is what keeps it from being a silent assumption. If the auditor's scope
  includes the friend.tech points/airdrop token system, that is a **separate** set of contracts the
  target does not reference — out of this target's graph.

---

## Explicitly checked and NOT unresolved (so the auditor doesn't re-chase them)

* **`protocolFeeDestination`** — resolved: Gnosis Safe proxy → `GnosisSafeL2` v1.3.0 singleton +
  `CompatibilityFallbackHandler`, all verified & byte-identical to upstream. Saved in `contracts/`.
* **`owner()`** — resolved: `0x0` (renounced); the setters are proven frozen.
* **The Safe's singleton/fallback/modules/guard** — all read (modules: none, guard: none) and saved.
* **Target upgradeability / delegatecall / selfdestruct** — none exist (verified source; not a proxy).
* **Any hidden minter or standing approval over "the token"** — N/A: there is no token, no ERC-20,
  no `approve`; shares are internal ledger entries mutated only by `buyShares`/`sellShares`.

## Decompiler availability (for the record)
No contract in this graph required decompilation (all verified). Had one been needed, note that this
environment did **not** ship a decompiler by default; `panoramix`/`heimdall` would have to be
installed first. This is stated here only so the assumption is explicit — it did not block any node
in this particular target.
