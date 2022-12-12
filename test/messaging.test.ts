import {expect} from "chai";
import {ethers} from "hardhat";
import {
  MockInbox__factory,
  MockOutbox__factory,
} from "@hyperlane-xyz/core";
import {CONTRACT_NAMES, EVENTS_NAMES, FUNCTION_NAMES, GAS_LIMIT} from "../utils/constants";

describe("Hyperlane EIP-5164", function () {
  describe("Hyperlane EIP-5164 Message Sending and Receiving", function () {
    it(`Can send a message to ${CONTRACT_NAMES.EIP5164_CALL_TARGET} via ${CONTRACT_NAMES.HYPERLANE_EIP5164_RELAYER} and ${CONTRACT_NAMES.HYPERLANE_EIP5164_EXECUTOR}`, async function () {
      const originDomain = 1;
      const destinationDomain = 2;
      const testMessage = "This is a test"
      const signer = (await ethers.getSigners())[0];
      const inbox = await new MockInbox__factory(signer as any).deploy();
      await inbox.deployed();
      const outbox = await new MockOutbox__factory(signer as any).deploy(
        originDomain,
        inbox.address
      );
      await outbox.deployed();

      const executorFactory = await ethers.getContractFactory(
        CONTRACT_NAMES.HYPERLANE_EIP5164_EXECUTOR
      );
      const executor = await executorFactory.deploy(inbox.address, originDomain);

      const relayerFactory = await ethers.getContractFactory(
        CONTRACT_NAMES.HYPERLANE_EIP5164_RELAYER
      );
      const relayer = await relayerFactory.deploy(
        outbox.address,
        destinationDomain,
        executor.address,
        GAS_LIMIT.MAX
      );

      const callTargetFactory = await ethers.getContractFactory(
        CONTRACT_NAMES.EIP5164_CALL_TARGET
      );
      const callTarget = await callTargetFactory.deploy(executor.address);

      const calls = [
        {
          target: callTarget.address,
          data: ethers.utils.arrayify(
            callTarget.interface.encodeFunctionData(
              FUNCTION_NAMES.EIP5164_CALL_TARGET_RECEIVE_MESSAGE, [
                testMessage
              ]
            )
          ),
        }
      ];
      await expect(
        relayer.relayCalls(calls, GAS_LIMIT.CALL)
      ).to.emit(relayer, EVENTS_NAMES.RELAYED_CALLS)
        .withArgs(1, signer.address, (value) => {
          expect(value.map(i => ({
            target: i.target,
            data: ethers.utils.arrayify(i.data),
          }))).to.eql(calls);
          return true;
        }, GAS_LIMIT.CALL);

      await inbox.processNextPendingMessage();

      expect(await callTarget.lastNonce()).to.equal(1);
      expect(await callTarget.lastSender()).to.equal(signer.address);
      expect(await callTarget.lastMessage()).to.equal(testMessage);
    });
  });
});
