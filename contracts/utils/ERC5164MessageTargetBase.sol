// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/**
 * @title ERC5164MessageTargetBase abstract contract
 * @notice Abstract implementation of an ERC5164MessageTarget contract
 *         The ERC5164MessageTarget contract is the final recipient of an ERC-5164 message.
 * @dev It receives messages from a trusted `MessageExecutor`
 *      and retrieves the appended `data`, `messageId`, `fromChainId` and `from` (via `_msgInfo()`)
 */
abstract contract ERC5164MessageTargetBase {
    /// @notice Address of the trusted executor contract.
    address public immutable trustedExecutor;

    /**
     * @notice ERC5164MessageTargetBase constructor.
     * @param _executor Address of the `MessageExecutor` contract
     */
    constructor(address _executor) {
        require(_executor != address(0), "executor can't be zero address");
        trustedExecutor = _executor;
    }

    /**
     * @notice Check which executor this contract trust.
     */
    modifier onlyTrustedExecutor() {
        require(msg.sender == trustedExecutor, "not a trusted executor");
        _;
    }

    /**
     * @notice Retrieve signer address from call data.
     * @return _signer Address of the signer
     */
    function _msgSender() internal view onlyTrustedExecutor returns (address payable) {
        address payable _signer = payable(msg.sender);

        if (msg.data.length >= 20) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                _signer := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        }

        return _signer;
    }

    /**
     * @notice Retrieve _fromChainId from call data.
     * @return _callDataFromChainId Id of the origin chain where the message was sent from
     */
    function _fromChainId() internal pure returns (uint256) {
        uint256 _callDataFromChainId;

        if (msg.data.length >= 52) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                _callDataFromChainId := calldataload(sub(calldatasize(), 52))
            }
        }

        return _callDataFromChainId;
    }

    /**
     * @notice Retrieve messageId from call data.
     * @return _callDataMessageId Nonce uniquely identifying the message that was executed
     */
    function _messageId() internal pure returns (bytes32) {
        bytes32 _callDataMessageId;

        if (msg.data.length >= 84) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                _callDataMessageId := calldataload(sub(calldatasize(), 84))
            }
        }

        return _callDataMessageId;
    }
}
