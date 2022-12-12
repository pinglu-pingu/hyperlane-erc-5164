// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../ERC5164/utils/ERC5164CallTargetBase.sol";

/**
 * @title MockERC5164CallTarget implementation
 * @notice Mock implementation of an ERC5164CallTarget
 */
contract MockERC5164CallTarget is ERC5164CallTargetBase {

  /// @notice nonce of the last received batch of ERC5164 calls
  uint256 public lastNonce;

  /// @notice Address of the last sender of ERC5164 calls
  address public lastSender;

  /// @notice Last received ERC5164 message
  string public lastMessage;

  /**
   * @notice Emitted when a message is received.
   * @param nonce Nonce to uniquely identify the batch of calls
   * @param sender Address of the sender
   * @param message Message that was relayed
   */
  event ReceivedMessage(uint256 nonce, address sender, string message);

  /// @inheritdoc ERC5164CallTargetBase
  /**
   * @notice MockERC5164CallTarget constructor.
   * @param executor_ Address of the `CrossChainExecutor` contract
   */
  constructor(address executor_) ERC5164CallTargetBase(executor_) {
  }

  /**
   * @notice Receives a message from the origin chain
   * @param message Message that was relayed
   * @dev Only accepts messages from trusted executors
   */
  function receiveMessage(string memory message) external onlyTrustedExecutor {
    uint256 nonce = _nonce();
    address msgSender = _msgSender();

    lastNonce = nonce;
    lastSender = msgSender;
    lastMessage = message;
    emit ReceivedMessage(nonce, msgSender, message);
  }
}