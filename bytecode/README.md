# On-chain bytecode artifacts

Runtime bytecode (`eth_getCode`) of every node, plus the target's creation bytecode.
Used for the integrity cross-checks in `/integrity`.

| File | Node | sha256 (first 16) |
| --- | --- | --- |
| 01-target.runtime.hex | FriendtechSharesV1 runtime | 2f0b9e95c65442cd |
| 01-target.creation.hex | FriendtechSharesV1 creation (from deploy tx) | — |
| 02-feeDestination-proxy.runtime.hex | GnosisSafeProxy runtime | eaa058e31ffce261 |
| 03-safe-singleton.runtime.hex | GnosisSafeL2 v1.3.0 runtime | 44f2f2806b3c2e4f |
| 04-fallback-handler.runtime.hex | CompatibilityFallbackHandler runtime | 3171b501f2cb37ea |

Singleton (03) and fallback (04) sha256 match Ethereum mainnet at the same addresses (see /integrity).
