// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { IERC5164CrossChainRelayer } from "./IERC5164CrossChainRelayer.sol";

/**
 * @title CrossChainExecutor interface
 * @notice CrossChainExecutor interface of the ERC-5164 standard as defined in the EIP.
 */
interface IERC5164CrossChainExecutor {
  /**
   * @notice Emitted when calls have successfully been executed.
   * @param relayer Address of the contract that relayed the calls on the origin chain
   * @param nonce Nonce to uniquely identify the batch of calls
   */
  event ExecutedCalls(IERC5164CrossChainRelayer indexed relayer, uint256 indexed nonce);

  /**
   * @notice Emitted when a batch of calls has already been executed.
   * @param nonce Nonce to uniquely identify the batch of calls that were re-executed
   */
  error CallsAlreadyExecuted(uint256 nonce);

  /**
   * @notice Custom error emitted if a call to a target contract fails.
   * @param callIndex Index of the failed call
   * @param errorData Error data returned by the failed call
   */
  error CallFailure(uint256 callIndex, bytes errorData);
}
