// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/**
 * @notice Call structure
 * @param target Address that will be called on the receiving chain
 * @param data Data that will be sent to the `target` address
 */
struct Call {
    address target;
    bytes data;
}
