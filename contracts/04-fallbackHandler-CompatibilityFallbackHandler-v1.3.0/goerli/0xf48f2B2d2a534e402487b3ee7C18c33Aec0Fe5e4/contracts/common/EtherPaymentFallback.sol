// File: goerli/0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4/contracts/common/EtherPaymentFallback.sol


pragma solidity >=0.7.0 <0.9.0;

/// @title EtherPaymentFallback - A contract that has a fallback to accept ether payments
/// @author Richard Meissner - <richard@gnosis.pm>
contract EtherPaymentFallback {
    event SafeReceived(address indexed sender, uint256 value);

    /// @dev Fallback function accepts Ether transactions.
    receive() external payable {
        emit SafeReceived(msg.sender, msg.value);
    }
}

