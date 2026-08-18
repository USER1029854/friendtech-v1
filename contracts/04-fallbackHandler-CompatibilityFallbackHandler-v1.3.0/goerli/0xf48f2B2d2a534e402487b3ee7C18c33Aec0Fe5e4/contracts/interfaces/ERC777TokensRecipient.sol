// File: goerli/0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4/contracts/interfaces/ERC777TokensRecipient.sol


pragma solidity >=0.7.0 <0.9.0;

interface ERC777TokensRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

