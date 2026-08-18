# Node 4 — CompatibilityFallbackHandler v1.3.0 (the fee Safe's fallback handler)

- Address: `0x017062a1de2fe6b99be3d9d37841fed19f573804` on Base (8453)
- Set as the Safe's fallback handler (storage slot keccak("fallback_manager.handler.address")).
  The Safe delegatecalls here for calls its own code doesn't implement (EIP-1271 isValidSignature,
  token-receiver hooks, on-chain `simulate`, etc.).
- Verified source (solc 0.7.6). The deployed contract is
  `.../contracts/handler/CompatibilityFallbackHandler.sol`; sibling files are its dependencies as
  submitted for verification (the `goerli/0xf48f…/` path prefix is just the verification label used
  by the canonical deployment — the code is the standard handler).
- `CompatibilityFallbackHandler.as-verified.flat.sol` — the exact source as returned by Etherscan.
- Integrity: runtime bytecode byte-identical to npm 1.3.0 `CompatibilityFallbackHandler.deployedBytecode`
  AND to Ethereum-mainnet code at the same address. Canonical, unmodified.
