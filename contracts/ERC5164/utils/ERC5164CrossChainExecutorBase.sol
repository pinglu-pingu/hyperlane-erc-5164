// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../interfaces/IERC5164CrossChainRelayer.sol";
import "../interfaces/IERC5164CrossChainExecutor.sol";
import "../libraries/ERC5164CallData.sol";

/**
 * @title CrossChainExecutor abstract contract.
 * @notice EIP-5164 CrossChainExecutor abstract implementation.
 * @dev Implements custom _executeCalls function that can be called by child contracts to execute received calls.
 */
abstract contract ERC5164CrossChainExecutorBase is IERC5164CrossChainExecutor {
  /**
   * @notice Nonce to uniquely identify the batch of calls that were executed.
   *         nonce => boolean
   * @dev Ensure that batch of calls cannot be replayed once they have been executed.
   */
  mapping(uint256 => bool) public executedNonces;

  /**
   * @notice Execute calls from the origin chain.
   * @dev Will revert if `_calls` have already been executed.
   * @dev Will revert if a call fails.
   * @dev Must emit the `ExecutedCalls` event once calls have been executed.
   * @param relayer Address of the relayer on the origin chain
   * @param nonce Nonce to uniquely identify the batch of calls
   * @param sender Address of the sender on the origin chain
   * @param calls Array of calls being executed
   */
  function _executeCalls(
    IERC5164CrossChainRelayer relayer,
    uint256 nonce,
    address sender,
    ERC5164CallData.Call[] memory calls
  ) internal {
    if (executedNonces[nonce]) {
      revert CallsAlreadyExecuted(nonce);
    }

    executedNonces[nonce] = true;

    uint256 callsLength = calls.length;
    for (uint256 idx; idx < callsLength; idx++) {
      ERC5164CallData.Call memory _call = calls[idx];

      (bool success, bytes memory returnData) = _call.target.call(
        abi.encodePacked(_call.data, nonce, sender)
      );

      if (!success) {
        revert CallFailure(idx, returnData);
      }
    }

    emit ExecutedCalls(relayer, nonce);
  }
}
