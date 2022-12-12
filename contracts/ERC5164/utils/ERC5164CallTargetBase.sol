// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/**
 * @title ERC5164CallTargetBase abstract contract
 * @notice Abstract implementation of an ERC5164CallTarget contract
 *         The ERC5164CallTarget contract is the final recipient of an ERC-5164 cross-chain call.
 * @dev It receives calls from a trusted `CrossChainExecutor`
 *      and retrieves the appended `sender` (via `_msgSender()`) and `nonce` (via `_nonce()`)
 */
abstract contract ERC5164CallTargetBase {
  /// @notice Address of the trusted executor contract.
  address public immutable trustedExecutor;

  /**
   * @notice ERC5164CallTargetBase constructor.
   * @param _executor Address of the `CrossChainExecutor` contract
   */
  constructor(address _executor) {
    require(_executor != address(0), "executor can't be zero address");
    trustedExecutor = _executor;
  }

  /**
   * @notice Check which executor this contract trust.
   */
  modifier onlyTrustedExecutor() {
    require(msg.sender == trustedExecutor);
    _;
  }

  /**
   * @notice Retrieve signer address from call data.
   * @return _signer Address of the signer
   */
  function _msgSender() internal view onlyTrustedExecutor returns (address payable) {
    address payable _signer = payable(msg.sender);

    if (msg.data.length >= 20) {
      assembly {
        _signer := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    }

    return _signer;
  }

  /**
   * @notice Retrieve nonce from call data.
   * @return _callDataNonce Nonce uniquely identifying the message that was executed
   */
  function _nonce() internal pure returns (uint256) {
    uint256 _callDataNonce;

    if (msg.data.length >= 52) {
      assembly {
        _callDataNonce := calldataload(sub(calldatasize(), 52))
      }
    }

    return _callDataNonce;
  }
}
