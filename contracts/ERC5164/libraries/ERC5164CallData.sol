// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/**
 * @title ERC5164CallData
 * @notice Library to declare and manipulate Call(s).
 */
library ERC5164CallData {
  /**
   * @notice Call data structure
   * @param target Address that will be called on the receiving chain
   * @param data Data that will be sent to the `target` address
   */
  struct Call {
    address target;
    bytes data;
  }
}
