// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {IERC5164MessageDispatcher} from "../interfaces/IERC5164MessageDispatcher.sol";
import {IERC5164MessageExecutor} from "../interfaces/IERC5164MessageExecutor.sol";

/**
 * @title MessageExecutor abstract contract.
 * @notice EIP-5164 MessageExecutor abstract implementation.
 * @dev Implements custom _executeMessage function that can be called by child contracts to execute received calls.
 */
abstract contract ERC5164MessageExecutorBase is IERC5164MessageExecutor {
    /**
     * @notice MessageId to uniquely identify the message that was executed.
     *         messageId => boolean
     * @dev Ensure that batch of calls cannot be replayed once they have been executed.
     */
    mapping(bytes32 => bool) public executedMessageIds;

    /**
     * @notice Execute message from the origin chain.
     * @dev Will revert if the message fails.
     * @dev Must emit the `MessageIdExecuted` event once the message has been executed.
     * @param to Address of the recipient on the destination chain
     * @param fromChainId Chain id of the origin chain
     * @param from Address of the sender on the origin chain
     * @param messageId Message id to uniquely identify the message
     * @param data Array of data being executed
     */
    function _executeMessage(
        address to,
        uint256 fromChainId,
        address from,
        bytes32 messageId,
        bytes memory data
    ) internal {
        if (executedMessageIds[messageId]) {
            revert MessageIdAlreadyExecuted(messageId);
        }
        executedMessageIds[messageId] = true;

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = to.call(abi.encodePacked(data, messageId, fromChainId, from));
        if (!success) {
            revert  MessageFailure(messageId, returnData);
        }

        emit MessageIdExecuted(fromChainId, messageId);
    }
}
