# Node 3 — GnosisSafeL2 v1.3.0 (the fee Safe's implementation)

- Address: `0xfb1bffc9d739b8d520daf37df666da4c687191ea` on Base (8453)
- This is the code that actually runs when the fee Safe (Node 2) is called (via delegatecall).
- Verified source is the full Safe 1.3.0 contract set (standard-json-input). The deployed contract
  is `contracts/GnosisSafeL2.sol` (extends `contracts/GnosisSafe.sol`); the other files are its
  dependencies + the rest of the Safe repo bundled in the verification input.
- Integrity: runtime bytecode is byte-identical BOTH to `@gnosis.pm/safe-contracts@1.3.0`
  `GnosisSafeL2.deployedBytecode` AND to the Ethereum-mainnet code at the same address. Canonical, unmodified.
- `_compiler_settings.json` holds the exact standard-json compiler settings used.
