# Configuration State — live parameter values the code's correctness depends on

Chain: **Base mainnet (8453)**. Values pinned to block **`50120188`**.
Raw: [`raw-rpc/state_snapshot.json`](./raw-rpc/state_snapshot.json).
Cross-checked two ways for each parameter: direct `eth_call` of the getter **and** raw
`eth_getStorageAt` of the backing slot (storage layout below).

## Storage layout (verified against read values)

`FriendtechSharesV1 is Ownable is Context`. `Context` has no state; `Ownable` contributes `_owner`
at slot 0; the rest follow in declaration order:

| Slot | Variable | Live raw value | Decoded |
|---|---|---|---|
| 0 | `Ownable._owner` | `0x…0000` | `0x0` (renounced) |
| 1 | `protocolFeeDestination` | `0x…831be9…ef430` | the fee Safe |
| 2 | `protocolFeePercent` | `0x…0000` | **0** |
| 3 | `subjectFeePercent` | `0x…00b1a2bc2ec50000` | `5e16` = **5 %** |
| 4 | `sharesBalance` (mapping) | — | per-subject/holder ledger |
| 5 | `sharesSupply` (mapping) | — | per-subject supply |

## Parameters

### `protocolFeeDestination` = `0x831be9…ef430`
The Gnosis Safe (see [`authority.md`](./authority.md)). Receives `price * protocolFeePercent / 1e18`
on every buy and sell. **Frozen** (owner renounced).

### `protocolFeePercent` = `0`  ⚠ worth a second look
Fee math is `protocolFee = price * protocolFeePercent / 1 ether`. At `0`, the protocol fee is
exactly zero on every trade, so `protocolFeeDestination` receives nothing from current activity.

* This is **internally coherent** with the code — `0` causes no revert/underflow anywhere
  (`getBuyPriceAfterFee` adds 0; `getSellPriceAfterFee` subtracts 0).
* It is **notable** because friend.tech is popularly described as charging a 5 % protocol fee; the
  live on-chain value is 0 and, with ownership renounced, **cannot be changed back**. An auditor
  reading only marketing/《5 % protocol fee》assumptions would be wrong about the current deployment.
* Whether it was set to 0 before renouncing or always 0 is an off-repo historical question; the
  audit-relevant fact is the **current, immutable** value = 0.

### `subjectFeePercent` = `5e16` (5 %)
`subjectFee = price * 5e16 / 1e18` → 5 % of price, paid to the `sharesSubject` on each trade.
**Frozen**.

### Reserve (native ETH held by target) = **913.58 ETH**
This is the bonding-curve backing. It is not a configured parameter but the pool's real balance.
It reconciles with the curve only in aggregate (sum over all subjects of the integral of the price
curve up to each `sharesSupply`); no single stored value claims a "should-be" reserve, so there is
no stored-vs-real mismatch to flag at the contract level. The reserve is **actively changing** — the
most recent transactions are `sellShares` calls (e.g. 2026-08-17), which draw it down.

## Coherence check
* `protocolFeePercent (0) + subjectFeePercent (5e16)` = `5e16` < `1e18`. On a **sell**, payout is
  `price − protocolFee − subjectFee`; with the fee sum at 5 % this stays positive (no underflow) for
  any `price ≥ 0`. Parameters are mutually coherent with the checked-arithmetic (0.8.18) code.
* No parameter references an external address other than the fee Safe (already resolved). There are
  no oracle sources, routers, strategy addresses, caps, or epoch/boundary settings in this contract —
  the parameter surface is just the two fee rates + the fee destination, all recorded above.
