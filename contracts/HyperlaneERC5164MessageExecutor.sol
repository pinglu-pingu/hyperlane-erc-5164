// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {IInbox} from "@hyperlane-xyz/core/interfaces/IInbox.sol";
import {IMessageRecipient} from "@hyperlane-xyz/core/interfaces/IMessageRecipient.sol";
import {TypeCasts} from "@hyperlane-xyz/core/contracts/libs/TypeCasts.sol";

import {IERC5164MessageDispatcher} from "./interfaces/IERC5164MessageDispatcher.sol";
import {IERC5164MessageExecutor} from "./interfaces/IERC5164MessageExecutor.sol";
import {ERC5164MessageExecutorBase} from "./utils/ERC5164MessageExecutorBase.sol";

/**
 * @title HyperlaneERC5164MessageExecutor implementation
 * @notice `MessageExecutor` implementation that receives messages via a Hyperlane `Inbox` as its transporter
 */
contract HyperlaneERC5164MessageExecutor is ERC5164MessageExecutorBase, IMessageRecipient {
    /// @notice `Inbox` contract reference
    IInbox public inbox;

    /// @notice Hyperlane identifier of origin chain
    uint32 public originDomain;

    /**
     * @notice HyperlaneERC5164MessageExecutor constructor.
     * @param inbox_ Address of the Hyperlane `Inbox` contract
     * @param originDomain_ Hyperlane identifier of origin chain
     */
    constructor(address inbox_, uint32 originDomain_) {
        inbox = IInbox(inbox_);
        originDomain = originDomain_;
    }

    /// @notice Restrict access to trusted `Inbox` contract
    /// @dev Also validates the origin domain identifier
    modifier onlyTrustedInbox(uint32 _origin) {
        require(_origin == originDomain && msg.sender == address(inbox), "not a trusted inbox");
        _;
    }

    // @inheritdoc IMessageRecipient
    function handle(uint32 _origin, bytes32 /*_sender*/, bytes calldata _message) external onlyTrustedInbox(_origin) {
        (address _to, uint256 _fromChainId, address _from, bytes32 _messageId, bytes memory _data) = abi.decode(
            _message,
            (address, uint256, address, bytes32, bytes)
        );
        _executeMessage(_to, _fromChainId, _from, _messageId, _data);
    }
}
