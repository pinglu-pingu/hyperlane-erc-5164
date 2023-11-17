// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/**
 * @title MessageDispatcher interface
 * @notice MessageDispatcher interface of the ERC-5164 standard as defined in the EIP.
 */
interface IERC5164MessageDispatcher {

    /**
     * @notice Emitted when a message has successfully been dispatched to the executor chain.
     * @param messageId Unique identifier of the message
     * @param from Address of the sender
     * @param toChainId Chain id of the destination chain
     * @param to Address of the destination contract
     * @param data Data to be sent to the destination contract
     */
    event MessageDispatched(
        bytes32 indexed messageId,
        address indexed from,
        uint256 indexed toChainId,
        address to,
        bytes data
    );
    
    /**
        * @notice Broadcasts messages through a transport layer to one or more MessageExecutor contracts
        * @dev Must emit the `MessageDispatched` event when successfully called.
        * @dev Must revert if the `toChainId` is not supported.
        * @dev Must forward the message to the `MessageExecutor` contract(s) on the destination chain.
        * @dev Must use a uique messageId to identify the message.
        * @dev Must return the messageId to allow the message sender to track the message.
        * @dev May require payment. Some bridges may require payment in the native currency, so the function is payable.
        * @param messageId Unique identifier of the message
        * @param toChainId Chain id of the destination chain
        * @param to Address of the destination contract
        * @param data Data to be sent to the destination contract
     */
    function dispatchMessage(
        uint256 toChainId,
        address to,
        bytes calldata data
    ) external payable returns (bytes32 messageId);
}
