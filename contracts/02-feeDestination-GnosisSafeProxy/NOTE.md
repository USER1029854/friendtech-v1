# Node 2 — GnosisSafeProxy (protocolFeeDestination shell)

- Address: `0x831be9e08185eba7d88aab1efc059336babef430` on Base (8453)
- This is the value the target stores in `protocolFeeDestination` and pays the protocol fee to.
- It is a **proxy**: a 171-byte GnosisSafeProxy that reads its singleton from storage slot 0 and
  `delegatecall`s everything to it. The real logic is Node 3 (the singleton).
  - `masterCopy()` / slot0 = `0xfb1bffc9d739b8d520daf37df666da4c687191ea` (Node 3).
- `GnosisSafeProxy.sol` — verified source (solc 0.7.6).
- Runtime bytecode `/bytecode/02-feeDestination-proxy.runtime.hex` is byte-identical to
  `@gnosis.pm/safe-contracts@1.3.0` `GnosisSafeProxy.deployedBytecode` (see /integrity).
- The Safe's live config (2-of-3, no modules, no guard, signers) is in `/state/authority.md`.
