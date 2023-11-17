import { expect } from 'chai';
import { ethers } from 'hardhat';
import { MockInbox__factory, MockOutbox__factory } from '@hyperlane-xyz/core';
import { CONTRACT_NAMES, EVENTS_NAMES, FUNCTION_NAMES } from '../utils/constants';

describe('Hyperlane ERC-5164', function () {
  describe('Hyperlane ERC-5164 Message Sending and Receiving', function () {
    it(`Can send a message to ${CONTRACT_NAMES.EIP5164_MESSAGE_TARGET} via ${CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_DISPATCHER} and ${CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_EXECUTOR}`, async function () {
      const originChainId = 1;
      const destinationDomain = 2;
      const destinationChainId = 2;
      const testMessage = 'This is a test';
      const signer = (await ethers.getSigners())[0];

      // Deploy inbox
      const inbox = await new MockInbox__factory(signer as any).deploy();
      await inbox.deployed();

      // Deploy outbox
      const outbox = await new MockOutbox__factory(signer as any).deploy(originChainId, inbox.address);
      await outbox.deployed();

      // Deploy ERC-5164 executor/Hyperlane receiver
      const executorFactory = await ethers.getContractFactory(CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_EXECUTOR);
      const executor = await executorFactory.deploy(inbox.address, originChainId);

      // Deploy ERC-5164 dispatcher/Hyperlane sender
      const dispatcherFactory = await ethers.getContractFactory(CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_DISPATCHER);
      const dispatcher = await dispatcherFactory.deploy(originChainId, outbox.address, [destinationDomain], [destinationChainId], [executor.address]);

      // Deploy message target contract
      const messageTargetFactory = await ethers.getContractFactory(CONTRACT_NAMES.EIP5164_MESSAGE_TARGET);
      const messageTarget = await messageTargetFactory.deploy(executor.address);

      // Send a message to the message target via the EIP-5164 dispatcher/ Hyperlane sender
      const message = ethers.utils.arrayify(
        messageTarget.interface.encodeFunctionData(FUNCTION_NAMES.EIP5164_MESSAGE_TARGET_RECEIVE_MESSAGE, [testMessage]),
      );
      // messageId = keccak256(abi.encodePacked(chainId, dispatcherAddress, messageNonce))
      const messageIdPacked = ethers.utils.solidityPack(["uint256", "address", "uint256"], [destinationChainId, executor.address, 1]);
      const messageId = ethers.utils.solidityKeccak256(["bytes"], [messageIdPacked]);
      await expect(dispatcher.dispatchMessage(destinationChainId, messageTarget.address, message))
        .to.emit(dispatcher, EVENTS_NAMES.DISPATCHED_MESSAGE)
        .withArgs(
          messageId,
          signer.address,
          destinationChainId,
          messageTarget.address,
          message
        );

      // Process the message
      await inbox.processNextPendingMessage({ gasLimit: 30000000 });

      // Validate that the message was delivered to the call target
      expect(await messageTarget.lastMessageId()).to.equal(messageId);
      expect(await messageTarget.lastSender()).to.equal(signer.address);
      expect(await messageTarget.lastMessage()).to.equal(testMessage);
      expect(await messageTarget.lastChainId()).to.equal(originChainId);
    });
  });
});
