require('dotenv').config();
import * as ethers from 'ethers';
import {
  chainConnectionConfigs,
  ChainName,
  ChainNameToDomainId,
  DomainIdToChainName,
  hyperlaneCoreAddresses,
  MultiProvider,
} from '@hyperlane-xyz/sdk';
import '@nomicfoundation/hardhat-toolbox';
import '@nomiclabs/hardhat-etherscan';
import 'hardhat-gas-reporter';
import { HardhatUserConfig, task, types } from 'hardhat/config';
import networks from './hardhat.network';
import { CONTRACT_NAMES, FUNCTION_NAMES, GAS_LIMIT } from './utils/constants';

const SOLIDITY_VERSION = '0.8.17';
const ETHERSCAN_API_KEY: string = process.env.ETHERSCAN_API_KEY!;
const MOONSCAN_API_KEY: string = process.env.MOONSCAN_API_KEY ?? "";
const POLYSCAN_API_KEY: string = process.env.POLYSCAN_API_KEY ?? "";
const SNOWTRACE_API_KEY: string = process.env.SNOWTRACE_API_KEY ?? "";
const ARBISCAN_API_KEY: string = process.env.ARBISCAN_API_KEY ?? "";

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  networks,
  solidity: {
    version: SOLIDITY_VERSION,
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts',
  },
  etherscan: {
    apiKey: {
      // Mainnet
      mainnet: ETHERSCAN_API_KEY,
      optimisticEthereum: ETHERSCAN_API_KEY,
      arbitrumOne: ARBISCAN_API_KEY,
      moonbeam: MOONSCAN_API_KEY,
      polygon: POLYSCAN_API_KEY,
      avalanche: SNOWTRACE_API_KEY,
      // Testnet
      goerli: ETHERSCAN_API_KEY,
      sepolia: ETHERSCAN_API_KEY,
      ropsten: ETHERSCAN_API_KEY,
      rinkeby: ETHERSCAN_API_KEY,
      kovan: ETHERSCAN_API_KEY,
      optimisticGoerli: ETHERSCAN_API_KEY,
      arbitrumGoerli: ARBISCAN_API_KEY,
      moonriver: MOONSCAN_API_KEY,
      moonbaseAlpha: MOONSCAN_API_KEY,
      //mumbai: POLYSCAN_API_KEY,
      //fuji: SNOWTRACE_API_KEY,
    },
  },
  typechain: {
    outDir: './types',
    target: 'ethers-v5',
    alwaysGenerateOverloads: false,
  },
  gasReporter: {
    enabled: !!process.env.REPORT_GAS,
  },
};

const multiProvider = new MultiProvider(chainConnectionConfigs);

task('deploy-executor', `deploys the ${CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_EXECUTOR} contract`)
  .addParam('origin', 'the name of the origin chain', undefined, types.string, false)
  .setAction(async (taskArgs, hre) => {
    console.log(
      `Deploying ${CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_EXECUTOR} on ${hre.network.name} for messages from ${taskArgs.origin}`,
    );
    const remote = hre.network.name as ChainName;
    const origin = taskArgs.origin as ChainName;
    const inbox = hyperlaneCoreAddresses[remote].inboxes[origin];

    const originDomain = ChainNameToDomainId[origin];

    const factory = await hre.ethers.getContractFactory(CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_EXECUTOR);

    const contract = await factory.deploy(inbox, originDomain);
    await contract.deployTransaction.wait();

    console.log(
      `Deployed ${CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_EXECUTOR} to ${contract.address} on ${hre.network.name} listening to the outbox on ${origin} with transaction ${contract.deployTransaction.hash}`,
    );
    console.log(`You can verify the contracts with:`);
    console.log(`$ yarn hardhat verify --network ${hre.network.name} ${contract.address} ${inbox} ${originDomain}`);
  });

task('deploy-dispatcher', `deploys the ${CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_DISPATCHER} contract`)
  .addParam('executor', `address of the ${CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_EXECUTOR}`, undefined, types.string, false)
  .addParam(
    'remote',
    `Name of the remote chain on which ${CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_EXECUTOR} is on`,
    undefined,
    types.string,
    false,
  )
  .setAction(async (taskArgs, hre) => {
    console.log(`Deploying ${CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_DISPATCHER} on ${hre.network.name}`);
    const origin = hre.network.name as ChainName;
    const outbox = hyperlaneCoreAddresses[origin].outbox;

    const remote = taskArgs.remote as ChainName;
    const remoteDomain = ChainNameToDomainId[remote];

    const factory = await hre.ethers.getContractFactory(CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_DISPATCHER);

    const contract = await factory.deploy(outbox, remoteDomain, taskArgs.executor, GAS_LIMIT.MAX);
    await contract.deployTransaction.wait();

    console.log(
      `Deployed ${CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_DISPATCHER} to ${contract.address} on ${hre.network.name} with transaction ${contract.deployTransaction.hash}`,
    );

    console.log(`You can verify the contracts with:`);
    console.log(
      `$ yarn hardhat verify --network ${hre.network.name} ${contract.address} ${outbox} ${remoteDomain} ${taskArgs.executor} ${GAS_LIMIT.MAX}`,
    );
  });

task('deploy-message-target', `deploys the ${CONTRACT_NAMES.EIP5164_MESSAGE_TARGET} contract`)
  .addParam('executor', `address of the ${CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_EXECUTOR}`, undefined, types.string, false)
  .setAction(async (taskArgs, hre) => {
    console.log(`Deploying ${CONTRACT_NAMES.EIP5164_MESSAGE_TARGET} on ${hre.network.name}`);

    const factory = await hre.ethers.getContractFactory(CONTRACT_NAMES.EIP5164_MESSAGE_TARGET);

    const contract = await factory.deploy(taskArgs.executor);
    await contract.deployTransaction.wait();

    console.log(
      `Deployed ${CONTRACT_NAMES.EIP5164_MESSAGE_TARGET} to ${contract.address} on ${hre.network.name} with transaction ${contract.deployTransaction.hash}`,
    );

    console.log(`You can verify the contracts with:`);
    console.log(`$ yarn hardhat verify --network ${hre.network.name} ${contract.address} ${taskArgs.executor}`);
  });

task(`send-message`, `sends a message via a deployed ${CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_DISPATCHER}`)
  .addParam('dispatcher', `Address of the ${CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_DISPATCHER}`, undefined, types.string, false)
  .addParam('destinationChainId', 'the id of the destination chain', undefined, types.int, false)
  .addParam('target', `address of the ${CONTRACT_NAMES.EIP5164_MESSAGE_TARGET}`, undefined, types.string, false)
  .addParam('message', 'the message you want to send', 'HelloWorld', types.string)
  .setAction(async (taskArgs, hre) => {
    const dispatcherFactory = await hre.ethers.getContractFactory(CONTRACT_NAMES.HYPERLANE_EIP5164_MESSAGE_DISPATCHER);
    const dispatcher = dispatcherFactory.attach(taskArgs.dispatcher);

    const callTargetFactory = await hre.ethers.getContractFactory(CONTRACT_NAMES.EIP5164_MESSAGE_TARGET);
    const callTarget = callTargetFactory.attach(taskArgs.target);

    const executor = await dispatcher.executor();
    const remoteDomain = await dispatcher.destinationDomain();
    const remote = DomainIdToChainName[remoteDomain];

    console.log(`Dispatching message "${taskArgs.message}" from ${hre.network.name} to ${remote}`);

    // dispatcher.dispatchMessage(destinationChainId, messageTarget.address, message)
    const tx = await dispatcher.dispatchMessage(
      [
        taskArgs.destinationChainId,
        callTarget.address,
        ethers.utils.arrayify(
          callTarget.interface.encodeFunctionData(FUNCTION_NAMES.EIP5164_MESSAGE_TARGET_RECEIVE_MESSAGE, [
            taskArgs.message as string,
          ]),
        )
      ]
    );
    await tx.wait();

    console.log(
      `Send message at txHash ${tx.hash}. Check the explorer at https://explorer.hyperlane.xyz/?search=${tx.hash}`,
    );

    const recipientUrl = await multiProvider.getChainConnection(remote).getAddressUrl(executor);
    console.log(`Check out the explorer page for receiver ${recipientUrl}#events`);
  });

export default config;
