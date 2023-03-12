// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { IInbox } from "@hyperlane-xyz/core/interfaces/IInbox.sol";
import { IMessageRecipient } from "@hyperlane-xyz/core/interfaces/IMessageRecipient.sol";
import { TypeCasts } from "@hyperlane-xyz/core/contracts/libs/TypeCasts.sol";

import { IERC5164CrossChainRelayer } from "./interfaces/IERC5164CrossChainRelayer.sol";
import { ERC5164CrossChainExecutorBase } from "./utils/ERC5164CrossChainExecutorBase.sol";
import { Call } from "./utils/Call.sol";

/**
 * @title HyperlaneERC5164Executor implementation
 * @notice `CrossChainExecutor` implementation that receives messages via a Hyperlane `Inbox` as its transporter
 */
contract HyperlaneERC5164Executor is ERC5164CrossChainExecutorBase, IMessageRecipient {
  /// @notice `Inbox` contract reference
  IInbox public inbox;

  /// @notice Hyperlane identifier of origin chain
  uint32 public originDomain;

  /**
   * @notice HyperlaneERC5164Executor constructor.
   * @param inbox_ Address of the Hyperlane `Inbox` contract
   * @param originDomain_ Hyperlane identifier of origin chain
   */
  constructor(address inbox_, uint32 originDomain_) {
    inbox = IInbox(inbox_);
    originDomain = originDomain_;
  }

  /// @notice Restrict access to trusted `Inbox` contract
  /// @dev Also validates the origin domain identifier
  modifier onlyTrustedInbox(uint32 _origin) {
    require(_origin == originDomain && msg.sender == address(inbox));
    _;
  }

  // @inheritdoc IMessageRecipient
  function handle(
    uint32 _origin,
    bytes32 _sender,
    bytes calldata _message
  ) external onlyTrustedInbox(_origin) {
    IERC5164CrossChainRelayer _relayer = IERC5164CrossChainRelayer(TypeCasts.bytes32ToAddress(_sender));

    (uint256 _nonce, address _callsSender, Call[] memory _calls) = abi.decode(
      _message,
      (uint256, address, Call[])
    );

    _executeCalls(_relayer, _nonce, _callsSender, _calls);
  }
}