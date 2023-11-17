// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {ERC5164MessageTargetBase} from "../utils/ERC5164MessageTargetBase.sol";

/**
 * @title MockERC5164MessageTarget implementation
 * @notice Mock implementation of an ERC5164MesssageTarget
 */
contract MockERC5164MessageTarget is ERC5164MessageTargetBase {
    /// @notice messageId of the last received ERC5164 message
    bytes32 public lastMessageId;

    /// @notice Address of the last sender of ERC5164 message
    address public lastSender;

    /// @notice Last received ERC5164 message
    string public lastMessage;

    /// @notice Last received chain id
    uint256 public lastChainId;

    /**
     * @notice Emitted when a message is received.
     * @param messageId MessageId to uniquely identify the message
     * @param sender Address of the sender
     * @param message Message that was relayed
     */
    event ReceivedMessage(bytes32 messageId, uint256 fromChainId, address sender, string message);

    /**
     * @notice MockERC5164MessageTarget constructor.
     * @param executor_ Address of the `MessageExecutor` contract
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(address executor_) ERC5164MessageTargetBase(executor_) {}

    /**
     * @notice Receives a message from the origin chain
     * @param message Message that was relayed
     * @dev Only accepts messages from trusted executors
     */
    function receiveMessage(string calldata message) external onlyTrustedExecutor {
        address from = _msgSender();
        uint256 fromChainId = _fromChainId();
        bytes32 messageId = _messageId();

        lastMessageId = messageId;
        lastSender = from;
        lastMessage = message;
        lastChainId = fromChainId;
        emit ReceivedMessage(messageId, fromChainId, from, message);
    }
}
