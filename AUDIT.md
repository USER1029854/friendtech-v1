# Security Audit — friend.tech V1 (`FriendtechSharesV1`)

**Scope:** the on-chain system assembled in this repo — the target `FriendtechSharesV1`
(`0xCF205808…d4A4d4`, Base 8453) and everything in its trust graph (the fee-destination Gnosis
Safe stack). **Question asked:** can an unprivileged attacker take value or seize control they
weren't entitled to?

**Verdict: no qualifying vulnerability found in the on-chain code as deployed.**
The bonding curve is exactly solvent (proven numerically below), has no rounding surface, no
secret-gated path, follows checks-effects-interactions, and its only privileged role
(`Ownable.owner`) is **renounced** (`owner() == address(0)`), which freezes the entire admin
surface. The fee Safe is byte-identical to canonical Gnosis Safe 1.3.0, is gated by a 2-of-3 owner
signature set with no modules and no guard, and holds **no power over the target**. Residual risk is
off-chain (Safe key custody; the friend.tech backend; the absence of slippage protection is a user
risk, not a protocol theft) — enumerated in §6–7.

This is a completeness-first audit: every externally-reachable entry point is enumerated and
accounted for (Artifact 1, §3), and the state-dependency compositions — reentrancy interleavings,
call-splitting/repetition, boundary cases, cross-subject interaction — are worked explicitly
(Artifact 2, §4). Nothing was triaged out by "looks unimportant."

---

## 1. System model — how value and power actually move

`FriendtechSharesV1` is a **bonding-curve shares market**. For each `sharesSubject` address there is
an independent integer supply curve. State is two mappings — `sharesSupply[subject]` and
`sharesBalance[subject][holder]` — there is **no ERC-20, nothing transferable, no `approve`, no
minter**. The contract custodies native ETH (currently **913.58 ETH**) as the reserve backing every
subject's curve, commingled in one balance.

* **What backs a unit of value:** the marginal price of the (n+1)-th share of any subject is
  `getPrice(n,1) = n² · 1e18/16000` wei. The reserve owed to a subject with supply S is
  `Σ_{i=0}^{S-1} i²·1e18/16000` — the integral of the discrete curve.
* **Where value enters:** `buyShares` — the buyer sends `price + protocolFee + subjectFee`; `price`
  is retained (reserve grows by exactly `price`), the two fees are forwarded out.
* **Where value leaves:** `sellShares` — reserve pays out exactly `price` total (`price − fees` to
  the seller, `protocolFee` to the fee Safe, `subjectFee` to the subject). There is **no `withdraw`,
  no `selfdestruct`, no arbitrary-call, no `receive`/`fallback`** — ETH can leave *only* via
  `sellShares`' bonding-curve payout.
* **Who may do what, and how it's proven:**
  * *Trade* (`buyShares`/`sellShares`): permissionless — any address, gated only by identity for the
    first share (`supply>0 || subject==msg.sender`) and by owning shares to sell
    (`sharesBalance ≥ amount`). No signature, no whitelist, no backend gate on-chain (confirmed:
    zero `ecrecover`/merkle/preimage logic; see §5).
  * *Admin* (`setFeeDestination`, `setProtocolFeePercent`, `setSubjectFeePercent`,
    `transferOwnership`, `renounceOwnership`): `onlyOwner`. **Owner is `address(0)` (renounced
    2024-09-07)** → all five are permanently uncallable (empirically: each reverts
    `"Ownable: caller is not the owner"` from any address).

**Safety properties honest users rely on** (targets for attack):
1. *Solvency:* the reserve is always ≥ the sum of what all holders can realize by selling. (§4.A)
2. *Conservation:* a buy adds exactly `price`, a sell removes exactly `price`; no path lets ETH
   leave except a curve-priced sell of shares the caller owns. (§4.A/§4.B)
3. *No privilege escalation:* no unprivileged caller can gain admin or move another party's shares
   or the reserve. (§3, §5)

---

## 2. Configuration audit (code as deployed, not in the abstract)

| Parameter | Live value | Coherent? |
|---|---|---|
| `owner` | `0x0` (renounced) | Yes — freezes admin; also means **no party can rescue/upgrade** (immutable by design). |
| `protocolFeeDestination` | `0x831be9…ef430` (2-of-3 Safe) | Yes — a value sink; canonical Safe (integrity-verified). |
| `protocolFeePercent` | **0** | Coherent with code (no div-by-zero/underflow at 0). Note: protocol earns nothing now and it **cannot be changed** (owner renounced). Not a security issue. |
| `subjectFeePercent` | `5e16` (5%) | Coherent. With the exact price (multiple of `6.25e13`), `price·5e16/1e18` is an **exact integer** — no fee-rounding surface at this value (verified). |
| reserve | 913.58 ETH | Matches an exactly-solvent curve; no stored "expected reserve" to contradict. |

No parameter combination makes a guard vacuous or an accounting assumption false. The one
interaction worth stating: because `owner==0`, `protocolFeePercent` is stuck at 0 forever — an
economic curiosity, not an exploit. Fee exactness was checked *for the deployed 5%*, not in general
(a future value not divisible appropriately could introduce dust, but ownership is renounced so no
value can ever change).

---

## 3. ARTIFACT 1 — Complete externally-reachable entry-point enumeration

### 3.1 `FriendtechSharesV1` (all 18 ABI functions; no `receive`/`fallback`)

| # | Function | Mut. | Guard | Why an arbitrary caller can't abuse it |
|---|----------|------|-------|----------------------------------------|
| 1 | `setFeeDestination(address)` | write | `onlyOwner` | owner=`0x0`; reverts for everyone. Frozen. |
| 2 | `setProtocolFeePercent(uint256)` | write | `onlyOwner` | Frozen (as above). |
| 3 | `setSubjectFeePercent(uint256)` | write | `onlyOwner` | Frozen. |
| 4 | `transferOwnership(address)` | write | `onlyOwner` | Frozen — no one can (re)claim ownership. |
| 5 | `renounceOwnership()` | write | `onlyOwner` | Frozen (already renounced). |
| 6 | `buyShares(address,uint256)` | payable | first-share identity check + payment check | See §4.B. Adds exactly `price` to reserve; CEI-ordered; only mints caller's own balance. First buy of a subject requires `subject==msg.sender`; first buy with `amount≥2` reverts (underflow in `getPrice(0,·)`), a self-inflicted revert. |
| 7 | `sellShares(address,uint256)` | payable | `supply>amount` + `sharesBalance≥amount` | See §4.B. Removes exactly `price`; can only sell shares the caller owns; can't sell the last share. CEI-ordered. |
| 8 | `getPrice(uint256,uint256)` | pure | n/a | Pure math, no state, no value. |
| 9 | `getBuyPrice(address,uint256)` | view | n/a | Read-only. |
| 10 | `getSellPrice(address,uint256)` | view | n/a | Read-only (reverts on `amount>supply` underflow — harmless view). |
| 11 | `getBuyPriceAfterFee(address,uint256)` | view | n/a | Read-only. |
| 12 | `getSellPriceAfterFee(address,uint256)` | view | n/a | Read-only. |
| 13 | `owner()` | view | n/a | Read-only (returns `0x0`). |
| 14 | `protocolFeeDestination()` | view | n/a | Read-only. |
| 15 | `protocolFeePercent()` | view | n/a | Read-only. |
| 16 | `subjectFeePercent()` | view | n/a | Read-only. |
| 17 | `sharesBalance(address,address)` | view | n/a | Read-only. |
| 18 | `sharesSupply(address)` | view | n/a | Read-only. |

Only **two** functions move value (#6, #7) and neither has a bypassable guard; the other 16 are
either frozen admin or pure/view. There is no unglamorous "claim/sweep/recycle/settle" function —
the surface is genuinely this small.

### 3.2 Fee-destination Gnosis Safe (`0x831be9…`, proxy → `GnosisSafeL2` 1.3.0 + fallback handler)

Byte-identical to canonical upstream (see `integrity/`). Enumerated by category; an **unprivileged
attacker holds none of the required capabilities**, and critically the **Safe has no authority over
the target** (target ownership renounced), so even full control of the Safe touches only the Safe's
own ~14.82 ETH, not the 913 ETH reserve.

| Category | Functions | Guard | Reachable by unprivileged attacker? |
|---|---|---|---|
| Execute | `execTransaction` | ≥2 valid owner sigs (threshold=2) over the Safe tx hash | No — can't forge 2-of-3 ECDSA. |
| Module exec | `execTransactionFromModule[ReturnData]` | `msg.sender` ∈ enabled modules | No — **modules list is empty**, always reverts. |
| Self-admin | `addOwnerWithThreshold`, `removeOwner`, `swapOwner`, `changeThreshold`, `enableModule`, `disableModule`, `setFallbackHandler`, `setGuard` | `authorized` = `msg.sender==address(this)` (only via `execTransaction`) | No — requires the 2-of-3. |
| Setup | `setup` | one-shot; reverts once initialized | No — already set up (nonce=39). |
| Signature helpers | `approveHash`, `checkSignatures`, `checkNSignatures` | approvals only count for owners | No — a non-owner approval is inert. |
| Sim/pure/views | `requiredTxGas`, `simulateAndRevert`, `getOwners`, `getThreshold`, `nonce`, `isOwner`, `getStorageAt`, `VERSION`, `domainSeparator`, `getModulesPaginated`, … | revert-by-design / read-only | No state effect. |

---

## 4. ARTIFACT 2 — State-dependency map & compositions examined

### 4.A State writers → readers

| State | Written by | Read by | Trust concern |
|---|---|---|---|
| `sharesSupply[subj]` | `buyShares` (+amount), `sellShares` (−amount) | `buyShares`/`sellShares` (price), `getBuyPrice`/`getSellPrice` | Price is a function of supply. Can an attacker move supply, then price off the stale value? Examined below — no, because price is read from a local snapshot taken *before* any external call, and writes precede calls (CEI). |
| `sharesBalance[subj][holder]` | `buyShares` (+), `sellShares` (−) | `sellShares` (ownership check) | Only the holder's own slot is mutated; the sell check reads the caller's own balance. No cross-holder write. |
| `protocolFeeDestination` / `protocolFeePercent` / `subjectFeePercent` | frozen (owner=0) | fee math in buy/sell/quotes | Immutable during any attack — cannot be shifted mid-sequence. |
| contract ETH balance (reserve) | `buyShares` (+), `sellShares` (−), donations | implicit (payouts) | Conservation proven below; no function reads `address(this).balance` to price anything, so balance can't be flash-loan-distorted into a bad quote. |

**Key structural fact:** no pricing input is read from any *manipulable external* source — not
`address(this).balance`, not an AMM reserve, not an oracle, not `block.timestamp`. Price depends only
on the subject's own integer `supply`, which the attacker can only move by paying the exact curve
price. This removes the entire "distort a reserve then price off it / flash-loan" class by
construction.

### 4.B Compositions worked (pairs, sequences, repetition, boundaries)

1. **Reentrancy via attacker-controlled recipients.** `buyShares` calls
   `protocolFeeDestination` then `sharesSubject`; `sellShares` calls `msg.sender`,
   `protocolFeeDestination`, `sharesSubject`. `sharesSubject`/`msg.sender` can be attacker contracts.
   *But every state effect (balance, supply) is written before these calls (lines 71–72 before
   74–75; lines 86–87 before 89–91), and nothing is read after them except the `success` require.*
   A reentrant `buy`/`sell` sees fully-consistent, already-updated state and is just an independent,
   correctly-priced trade. Traced the worst case (buy 1 then reenter to sell the just-minted share at
   the new supply): nets to **0** for the attacker, reserve returns to its prior value. No half-updated
   state exists to harvest. **Not exploitable.**
2. **Call-splitting / repetition (N small vs 1 large).** Because `1e18/16000 = 6.25e13` exactly,
   `getPrice` has **no floor rounding**; it is perfectly additive: `getPrice(S,a) == Σ_{k<a}
   getPrice(S+k,1)` (verified over 2000 random cases, 0 mismatches). So splitting a buy or sell
   changes the reserve in/out by **exactly zero**. At the deployed `subjectFeePercent=5e16`, the fee
   is also exact, so splitting saves **0 wei** (verified: max gain 0). **No repetition profit.**
3. **Buy-low/sell-high within one tx (self-priced curve).** Buying raises supply and thus the next
   price; selling lowers it. A round trip buy(S→S+1) then sell(S+1→S) pays `getPrice(S,1)` in and
   takes `getPrice(S,1)` out — identical, minus/plus symmetric fees. When `subject==attacker` the
   subject-fee washes; net **0**. No divergence between the buy and sell price of the same marginal
   share to arbitrage. **No profit.**
4. **Boundary — first share / last share.** `getPrice(0,1)=0` (free first share) is offset by
   `supply>amount` forbidding the sale of the last share: the free share is permanently unsellable,
   so the 0-cost mint can never be redeemed for >0. Solvency table (S=1…1000) shows **surplus=0**:
   reserve contributed by buys exactly equals payout selling down to supply 1. **No boundary leak.**
5. **Cross-subject via the commingled reserve.** Subjects share one ETH pot but each curve is
   independently exact (each buy/sell touches only that subject's supply/balance and moves the pot by
   that subject's own `price`). No sequence over subjects A,B lets B's backing be drained by moving
   A: every withdrawal is bounded by the caller's own shares of that specific subject. **No cross-subject
   insolvency.**
6. **Overpayment.** `buyShares` requires `msg.value ≥ …` and never refunds excess — excess is
   retained in the reserve (increases solvency). A footgun that loses the *payer* money; gives an
   attacker nothing. **Not a theft vector.**

### 4.C Conservation/solvency proof (numeric)
For every supply S ∈ {1,2,3,10,100,1000}: `Σ_{i=0}^{S-1} getPrice(i,1)` (reserve in) **==**
`Σ_{sup=2}^{S} getPrice(sup−1,1)` (payout selling S→1), surplus **0**. Combined with exact additivity
(no rounding) and CEI (no reentrant over-withdrawal), the reserve can never be made to pay out more
than was paid in for any subject. The economic-extraction bar is therefore never met.

---

## 5. Secret / hardcoded-signer check (mechanical)

The task's "check the secrets" step applies to any value-moving path gated by something other than
caller identity. **There is no such path here** — `FriendtechSharesV1` contains no `ecrecover`, no
merkle proof, no hash-preimage, no key-in-state. To confirm mechanically, the deployed **runtime
bytecode was scanned for embedded constants**:

* **PUSH20:** only `0xffff…ff` (the address-cast mask). **No hardcoded address / signer.**
* **PUSH32:** only the `Error(string)`/`Panic(uint256)` selectors, revert-string fragments, and the
  two event topics (`Trade`, `OwnershipTransferred`). **No private key, no signer hash, no secret.**

So the class "function passes access-control review and simulation but is opened by a constant anyone
can read" **cannot exist** in this contract. (The Safe's signature scheme is the canonical Safe 1.3.0
EIP-712 design, domain-separated to the Safe's own address+chainid; its signers are the 3 EOAs held
off-chain, not constants in code.)

---

## 6. Off-chain boundary (stated plainly)

The chain does **not** contain the whole system, and a clean on-chain result does **not** imply the
product is unconditionally safe:

* **Safe signer keys (2-of-3, off-chain).** The fee Safe's ~14.82 ETH is protected only by custody
  of ≥2 of the 3 signer keys. This is unverifiable from the chain. If 2 keys are compromised, the
  Safe's own balance is lost — **but this does not reach the target's 913 ETH** (ownership renounced;
  the Safe has no target authority). Bounded blast radius.
* **friend.tech backend/API.** Maps X handles ⇄ subject addresses and gates the app UI/points. It is
  **not in the on-chain fund-custody path** for V1 — the contract never consults it (proven by the
  permissionless-trade behavior and the absence of any signature check). A backend compromise cannot
  mint shares, move the reserve, or change fees; its effect is limited to the social/UI layer.
* **No cross-chain / bridge component** is in this target's graph.

**Assumptions that would change the verdict if wrong:** (a) that the runtime bytecode I scanned is
what executes — verified, the target is verified source and I read the deployed code directly;
(b) that the Safe is the audited canonical 1.3.0 — verified byte-identical to upstream and to
Ethereum mainnet; (c) Safe *internal* security is the well-known audited Safe model — I verified
byte-identity, I did not re-derive Safe's internals. None of (a)–(c) is a load-bearing unknown for
the target's reserve.

---

## 7. Non-qualifying observations (disclosed, not vulnerabilities)

* **A subject can brick its own market.** If a `sharesSubject` is a contract that reverts on receiving
  the `subjectFee`, both `buyShares` and `sellShares` for that subject revert (the `success` require),
  trapping that subject's holders' ETH in the reserve. It is **griefing by a subject against its own
  buyers** — the subject gains nothing (they too can't sell), and it can't touch other subjects'
  funds. A holder risk to note, not an attacker theft. (Note: not currently mitigated by
  `protocolFeePercent=0` because the *subject* fee, not protocol fee, is the reverting transfer.)
* **No slippage/deadline protection** on `buyShares`/`sellShares`. Prices move with supply, so trades
  are sandwichable — this is transaction-ordering risk, explicitly out of scope, and a user-experience
  risk rather than a protocol theft.
* **Overpayment is not refunded** (§4.B.6) — payer footgun.
* **First share of a subject can only be bought one at a time** (`amount≥2` underflow-reverts at
  `supply==0`) — functional quirk, self-inflicted revert.

---

## 8. Method / reproducibility
* Source: verified Etherscan source in `contracts/`; behavior cross-checked against deployed runtime
  bytecode in `bytecode/`.
* Numeric proofs (additivity, fee-exactness, solvency) and the bytecode constant scan are simple
  Python over the on-chain values; results embedded above.
* Live authority/config from `state/` (owner renounced; Safe 2-of-3, no modules/guard; fees 0%/5%).
* Integrity (Safe canonical, OZ genuine) from `integrity/`.
