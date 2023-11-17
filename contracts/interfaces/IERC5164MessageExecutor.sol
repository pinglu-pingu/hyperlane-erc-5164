// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {IERC5164MessageDispatcher} from "./IERC5164MessageDispatcher.sol";

/**
 * @title IERC5164MessageExecutor interface
 * @notice MessageExecutor interface of the ERC-5164 standard as defined in the EIP.
 */
interface IERC5164MessageExecutor {
    /**
     * @notice Emitted once a message or message batch has been executed.
     * @param fromChainId Chain id of the sender
     * @param messageId Unique identifier of the message or message batch
     */
    event MessageIdExecuted(uint256 indexed fromChainId, bytes32 indexed messageId);

    /**
     * @notice Emitted when a message has already been executed.
     * @param messageId Unique identifier of the message or message batch
     */
    error MessageIdAlreadyExecuted(bytes32 messageId);

    /**
     * @notice Custom error emitted if a call to a target contract fails.
     * @param messageId Unique identifier of the message or message batch
     * @param errorData Error data returned by the failed call
     */
    error MessageFailure(bytes32 messageId, bytes errorData);
}
