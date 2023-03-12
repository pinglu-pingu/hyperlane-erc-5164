// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { IOutbox } from "@hyperlane-xyz/core/interfaces/IOutbox.sol";
import { TypeCasts } from "@hyperlane-xyz/core/contracts/libs/TypeCasts.sol";

import { IERC5164CrossChainRelayer } from "./interfaces/IERC5164CrossChainRelayer.sol";
import { IERC5164CrossChainExecutor } from "./interfaces/IERC5164CrossChainExecutor.sol";
import { Call } from "./utils/Call.sol";

/**
 * @title HyperlaneERC5164Relayer implementation
 * @notice `CrossChainRelayer` implementation that also uses a Hyperlane `Outbox` as its transporter
 */
contract HyperlaneERC5164Relayer is IERC5164CrossChainRelayer {
  /// @notice `Outbox` contract reference
  IOutbox public outbox;

  /// @notice Hyperlane identifier of destination chain
  uint32 public destinationDomain;

  /// @notice `CrossChainExecutor` contract reference
  IERC5164CrossChainExecutor public executor;

  /// @notice Gas limit of receiving chain
  uint256 public immutable maxGasLimit;

  /// @notice Nonce to uniquely identify each batch of calls.
  uint256 internal nonce;

  /**
   * @notice HyperlaneERC5164Relayer constructor.
   * @param outbox_ Address of the Hyperlane `Outbox` contract
   * @param destinationDomain_ Hyperlane identifier of destination chain
   * @param executor_ Address of the `CrossChainExecutor` contract
   */
  constructor(address outbox_, uint32 destinationDomain_, address executor_, uint256 maxGasLimit_) {
    outbox = IOutbox(outbox_);
    destinationDomain = destinationDomain_;
    executor = IERC5164CrossChainExecutor(executor_);
    require(maxGasLimit_ > 0, "max gas limit must be greater than zero");
    maxGasLimit = maxGasLimit_;
  }

  /// @inheritdoc IERC5164CrossChainRelayer
  function relayCalls(Call[] calldata calls, uint256 gasLimit) external payable returns (uint256) {
    uint256 _maxGasLimit = maxGasLimit;

    if (gasLimit > _maxGasLimit) {
      revert GasLimitTooHigh(gasLimit, _maxGasLimit);
    }

    nonce++;
    uint256 _nonce = nonce;

    bytes32 recipient = TypeCasts.addressToBytes32(address(executor));
    outbox.dispatch(destinationDomain, recipient, abi.encode(_nonce, msg.sender, calls));

    emit RelayedCalls(_nonce, msg.sender, calls, gasLimit);
    return _nonce;
  }
}
