// File: goerli/0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4/contracts/common/SelfAuthorized.sol


pragma solidity >=0.7.0 <0.9.0;

/// @title SelfAuthorized - authorizes current contract to perform actions
/// @author Richard Meissner - <richard@gnosis.pm>
contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}

