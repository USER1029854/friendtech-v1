# Node 1 — FriendtechSharesV1 (TARGET)

- Address: `0xCF205808Ed36593aa40a44F10c7f7C2F67d4A4d4` on Base (8453)
- Verified, solc 0.8.18, optimizer off, **not a proxy**.
- Files:
  - `contracts/FriendtechShares.sol` — the target contract logic (bonding curve, buy/sell, fees).
  - `contracts/Ownable.sol`, `contracts/Context.sol` — OpenZeppelin (see /integrity: Context=v4.4.1, Ownable=v4.7.0, both genuine).
  - `FriendtechSharesV1.as-verified.flat.sol` — exact flattened source as verified on Etherscan.
  - `abi.json`, `_metadata.json` — ABI and compiler metadata.
- Runtime bytecode: `/bytecode/01-target.runtime.hex`; creation bytecode: `/bytecode/01-target.creation.hex`.
- Live state: owner renounced (`0x0`); protocolFeePercent=0; subjectFeePercent=5%; reserve 913.58 ETH. See /state.
