// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {IOutbox} from "@hyperlane-xyz/core/interfaces/IOutbox.sol";
import {TypeCasts} from "@hyperlane-xyz/core/contracts/libs/TypeCasts.sol";

import {IERC5164MessageDispatcher} from "./interfaces/IERC5164MessageDispatcher.sol";
import {IERC5164MessageExecutor} from "./interfaces/IERC5164MessageExecutor.sol";

struct ExecutorInfo {
    /// @notice Address of the `MessagesExecutor` contract
    address executor;
    /// @notice Hyperlane identifier of executor's domaina
    uint32 domainId;
    /// @notice Chain id of executor's domain
    uint256 chainId;
}

/**
 * @title HyperlaneERC5164MessageDispatcher implementation
 * @notice `IERC5164Dispatcher` implementation that also uses a Hyperlane `Outbox` as its transporter
 */
contract HyperlaneERC5164MessageDispatcher is IERC5164MessageDispatcher {
    /// @notice `Outbox` contract reference
    IOutbox public outbox;

    /// @notice Chain id of the current chain
    uint256 internal chainId;

    /// @notice Hyperlane identifier of destination chain mapping to `MessageExecutor` contract reference
    mapping(uint => ExecutorInfo) public executorInfoForChain;

    /// @notice Id to uniquely identify each message.
    uint256 internal messageNonce;

    function existsExecutorInfoForChain(uint chainId) public view returns (bool) {
        return executorInfoForChain[chainId].executor != address(0);
    }

    /**
     * @notice HyperlaneERC5164MessageDispatcher constructor.
     * @param outbox_ Address of the Hyperlane `Outbox` contract
     * @param destinationDomains_ Hyperlane identifier of destination chains
     * @param executors_ Address of the `MessagesExecutor` contracts for each chain
     */
    constructor(uint256 chainId_, address outbox_, uint32[] memory destinationDomains_, uint256[] memory destinationChainIds_, address[] memory executors_) {
        outbox = IOutbox(outbox_);
        require(destinationDomains_.length == destinationChainIds_.length && destinationDomains_.length == executors_.length, "arrays length mismatch");
        require(destinationDomains_.length > 0, "arrays must have elements");
        for (uint i = 0; i < destinationChainIds_.length; i++) {
            bool alreadyExists = existsExecutorInfoForChain(destinationDomains_[i]);
            require(!alreadyExists, "only one executors per domain");
            executorInfoForChain[destinationChainIds_[i]] = ExecutorInfo(executors_[i], destinationDomains_[i], destinationChainIds_[i]);
        }
        chainId = chainId_;
    }

    /**
     * @notice messageId generator
     */
    function _getNewMessageId(uint256 destinationChainId, address executorAddress) internal returns (bytes32) {
        messageNonce++;
        return keccak256(abi.encodePacked(destinationChainId, executorAddress, messageNonce));
    }

    /// @inheritdoc IERC5164MessageDispatcher
    function dispatchMessage(
        uint256 toChainId,
        address to,
        bytes calldata data
    ) external payable returns (bytes32 messageId) {
        uint32 destinationDomain = executorInfoForChain[toChainId].domainId;
        address executorAddr = executorInfoForChain[toChainId].executor;
        require(executorAddr != address(0), "executor not found for domain");

        messageId = _getNewMessageId(toChainId, executorAddr);
        bytes32 recipient = TypeCasts.addressToBytes32(executorAddr);

        outbox.dispatch(destinationDomain, recipient, abi.encode(to, chainId, msg.sender, messageId, data));

        emit MessageDispatched(messageId, msg.sender, toChainId, to, data);
        return messageId;
    }
}
