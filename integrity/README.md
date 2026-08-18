# Integrity Checks — are the "known" building blocks really what they claim to be?

Every shared/library component in the graph was compared against **real upstream**, not against a
copy shipped with the project, so a doctored baseline could not hide here.

## Summary

| Component | Claim | Verified against | Result |
|---|---|---|---|
| Target `Context.sol` | OpenZeppelin v4.4.1 | OZ GitHub tag `v4.4.1` | **IDENTICAL** |
| Target `Ownable.sol` | (labeled) OZ v4.7.0 | OZ GitHub tag `v4.7.0` | **IDENTICAL** |
| Fee-Safe proxy | GnosisSafeProxy 1.3.0 | `@gnosis.pm/safe-contracts@1.3.0` npm `deployedBytecode` | **byte-identical** |
| Safe singleton | GnosisSafeL2 1.3.0 | npm 1.3.0 **and** ETH-mainnet code at same addr | **byte-identical (both)** |
| Fallback handler | CompatibilityFallbackHandler 1.3.0 | npm 1.3.0 **and** ETH-mainnet code at same addr | **byte-identical (both)** |

No modified, forked, or "close-but-not-equal" building block was found. No diff to surface.

---

## 1. Target's OpenZeppelin blocks

The target inlines two OZ files. A whitespace-normalized comparison (dropping the flattener's
injected `// File:` header, the stripped `SPDX` line, and the removed `import`, and normalizing the
on-chain source's CRLF line endings) against the genuine upstream tags:

* `contracts/Context.sol` ≡ **OZ v4.4.1** `contracts/utils/Context.sol`
* `contracts/Ownable.sol` ≡ **OZ v4.7.0** `contracts/access/Ownable.sol`

Upstream copies used for the diff are in [`upstream-openzeppelin/`](./upstream-openzeppelin/).

**Observation (not a vulnerability):** the project **mixed OZ minor versions** — `Context` from
4.4.1, `Ownable` from 4.7.0. The 4.7.0 `Ownable` only refactors the owner check into an internal
`_checkOwner()` (for overridability); it enforces the identical
`require(owner() == _msgSender(), "Ownable: caller is not the owner")`. No behavioral or security
difference. Both files are unmodified genuine OZ.

## 2. Gnosis Safe stack — two independent proofs

### 2a. Against the published npm package (upstream source of truth)
On-chain runtime bytecode vs `deployedBytecode` from `@gnosis.pm/safe-contracts@1.3.0`
(reference hex preserved in [`upstream-safe-1.3.0/`](./upstream-safe-1.3.0/)):

* Proxy `0x831be9…ef430` runtime == `GnosisSafeProxy.json.deployedBytecode` → **match**
* Singleton `0xfb1bffc9…7191ea` runtime == `GnosisSafeL2.json.deployedBytecode` → **match**
* Fallback `0x017062a1…573804` runtime == `CompatibilityFallbackHandler.json.deployedBytecode` → **match**

### 2b. Against Ethereum mainnet (deterministic-deployment cross-check)
Safe 1.3.0 is deployed at the **same address on every chain** via the eip155 deployment. The Base
runtime bytecode is byte-identical to the Ethereum-mainnet runtime at the same address:

| Contract | Address | Base `sha256` | Mainnet `sha256` |
|---|---|---|---|
| GnosisSafeL2 singleton | `0xfb1bffc9…7191ea` | `44f2f280…a906aead` | `44f2f280…a906aead` ✅ |
| CompatibilityFallbackHandler | `0x017062a1…573804` | `3171b501…bc70d4b8` | `3171b501…bc70d4b8` ✅ |

(The proxy is a per-Safe deployment so it has no same-address sibling on mainnet; it is covered by
2a instead.)

This makes the fee Safe's executing code provably the **canonical, unmodified Gnosis Safe 1.3.0** —
its behavior is the audited, well-known Safe behavior, and the only variable is its signer set /
config, which is recorded in [`../state/authority.md`](../state/authority.md).

## 3. Simulation (empirical behavior from an unprivileged caller)

`eth_call` from arbitrary address `0x1111…1111` against current chain state
(raw: [`../state/raw-rpc/simulation_results.json`](../state/raw-rpc/simulation_results.json)):

| Call | Result | Proves |
|---|---|---|
| `setFeeDestination(0x…dead)` | revert `"Ownable: caller is not the owner"` | admin frozen |
| `setProtocolFeePercent(…)` | revert `"Ownable: caller is not the owner"` | admin frozen |
| `setSubjectFeePercent(…)` | revert `"Ownable: caller is not the owner"` | admin frozen |
| `buyShares(self, 1)` value 0 | success (`0x`) | trade path is permissionless (no signature/whitelist gate) |

**Caveat, per method:** simulation proves a guard *exists and triggers*; because the target is fully
verified (and holds no secrets in its own bytecode — it's plain source), there is no "guard whose
secret might be public" concern here. The clean simulation is corroborating evidence, not the sole
basis for any claim — the source and the integrity diffs above are.

---

## Method / reproduction
* OZ upstream fetched from `raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/{v4.4.1,v4.7.0}`.
* Safe upstream from `npm pack @gnosis.pm/safe-contracts@1.3.0` → `build/artifacts/**/*.json` `deployedBytecode`.
* On-chain bytecode via `eth_getCode` (Base `mainnet.base.org`; Ethereum `ethereum-rpc.publicnode.com`).
* Comparisons by `diff` / `sha256sum`; normalized comparisons for source (CRLF, SPDX, import, flattener header).
