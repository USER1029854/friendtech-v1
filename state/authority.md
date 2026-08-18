# Authority State — who holds power over the target, right now

Snapshot chain: **Base mainnet (8453)**. Reads pinned to block **`50120188`** unless noted.
Raw evidence: [`raw-rpc/state_snapshot.json`](./raw-rpc/state_snapshot.json),
[`raw-rpc/ownership_transferred_events.json`](./raw-rpc/ownership_transferred_events.json),
[`raw-rpc/simulation_results.json`](./raw-rpc/simulation_results.json).

## Target `FriendtechSharesV1` (0xCF205808…d4A4d4)

### `owner()` = `0x0000000000000000000000000000000000000000` — RENOUNCED

The only privileged role in the target is the OpenZeppelin `Ownable` owner. It currently holds the
**zero address**, i.e. ownership has been renounced. The three owner-gated functions are therefore
**permanently uncallable by anyone**:

| Function | Selector | Effect if it could be called |
|---|---|---|
| `setFeeDestination(address)` | `0xfbe53234` | change protocol-fee recipient |
| `setProtocolFeePercent(uint256)` | `0xa4983421` | change protocol fee |
| `setSubjectFeePercent(uint256)` | `0x5a8a764e` | change subject fee |

Proven empirically — each reverts `"Ownable: caller is not the owner"` when called from an
arbitrary unprivileged address (see [`configuration.md`](./configuration.md) and the simulation
evidence file).

### Ownership history (full `OwnershipTransferred` log)

| When (UTC) | Block | prevOwner → newOwner | Meaning |
|---|---|---|---|
| 2023-08-10 06:50 | 2430440 | `0x0` → `0xdd9176ea…403f742` | deploy; owner = deployer EOA |
| 2023-12-02 14:49 | 7379349 | `0xdd9176ea…403f742` → `0x831be9…ef430` | admin handed to the **fee Safe** |
| **2024-09-07 22:38** | 19417989 | `0x831be9…ef430` → `0x0` | **renounced by the Safe** |

Interpretation: for ~9 months (2023-12 → 2024-09) the fee Safe was simultaneously the fee recipient
**and** the admin (could re-point fees / change rates). Since 2024-09-07 there is **no live admin**;
the fee parameters and fee destination are frozen at the values in
[`configuration.md`](./configuration.md).

### Other authority vectors — checked and absent
* **Not a proxy.** Etherscan `Proxy=0`; the target's own runtime bytecode is the logic. No upgrade path, no implementation slot.
* **No `delegatecall`, no `selfdestruct`, no arbitrary external-call-with-data** in the source — nothing can be made to execute foreign code or be destroyed.
* **No minter / no token.** Shares are internal `mapping` entries; there is no ERC-20, no `mint`, no `approve`, so no external contract can hold a standing allowance or mint supply.
* **No pause / no access-control roles** beyond `Ownable`.

Net: the only party that ever held power over the target was the owner, and that role is now nobody.

---

## Fee-destination Safe `0x831be9e08185eba7d88aab1efc059336babef430`

A canonical **Gnosis Safe v1.3.0** (proxy → `GnosisSafeL2` singleton). It is downstream of the
target (receives the protocol fee) and, until 2024-09, was also its admin.

| Property | Value | How read |
|---|---|---|
| Version | `1.3.0` (`GnosisSafeL2`) | `VERSION()` = "1.3.0" |
| Type | 2-of-3 multisig | `getThreshold()` = `2`, `getOwners()` = 3 addrs |
| Threshold | **2** | `getThreshold()` |
| Nonce (txs executed) | **39** | `nonce()` = `0x27` |
| Singleton / masterCopy | `0xfb1bffc9…7191ea` | `masterCopy()` + storage slot 0 |
| Fallback handler | `0x017062a1…573804` (`CompatibilityFallbackHandler`) | storage slot `keccak("fallback_manager.handler.address")` |
| **Modules** | **none** | `getModulesPaginated(0x1,10)` → empty array, next = SENTINEL |
| **Guard** | **none** (`0x0`) | storage slot `keccak("guard_manager.guard.address")` |
| Native balance | **14.82 ETH** (accumulated protocol fees) | `eth_getBalance` |
| Last activity | 2024-09-08 (the renounce operations) | Blockscout txlist |

The **absence of modules and guard** matters: a Safe module can move funds bypassing the 2-of-3
threshold, and a guard can block/alter execution — neither exists here, so control of the Safe is
exactly its 2-of-3 signer set, nothing more.

### Safe signers (all externally-owned accounts — leaf nodes)

| Signer | Code | Nonce | Note |
|---|---|---|---|
| `0x68d499502055ab7d4927694d971de985342f40ce` | none (EOA) | 36 | active EOA |
| `0xdd9176ea3e7559d6b68b537ef555d3e89403f742` | none (EOA) | 17 | **= the target's deployer** |
| `0xddc4f58f22166a88b9976c417046bb10d56000e3` | none (EOA) | 4 | active EOA |

None is a contract, so the authority chain terminates at these three keys. They are off-chain
key-holders — see [`../UNRESOLVED.md`](../UNRESOLVED.md). Their power today is limited to the Safe's
own ~14.82 ETH; they have **no** remaining power over the target's 913.58 ETH reserve because the
target's ownership is renounced.
