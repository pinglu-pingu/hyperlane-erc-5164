# Hyperlane EIP-5164 Implementation

[EIP-5164](https://eips.ethereum.org/EIPS/eip-5164) defines a cross-chain execution interface for EVM-based blockchains allowing contracts on one chain to call contracts on another.
This repo contains an implementation of EIP-5164 that uses [Hyperlane](https://www.hyperlane.xyz/) as the transport layer.

The two main contracts are [HyperlaneERC5164MessageDispatcher.sol](./contracts/HyperlaneERC5164MessageDispatcher.sol) and [HyperlaneERC5164MessageExecutor](./contracts/HyperlaneERC5164MessageExecutor.sol) 
which are implementations of EIP-5164 [MessageDispatcher](https://eips.ethereum.org/EIPS/eip-5164#messagedispatcher) and [MessageExecutor](https://eips.ethereum.org/EIPS/eip-5164#messageexecutor) respectively
as well implementations of Hyperlane [Message Sender](https://docs.hyperlane.xyz/hyperlane-docs/developers/messaging-api/send) and [Message Recipient](https://docs.hyperlane.xyz/hyperlane-docs/developers/messaging-api/receive) respectively 
allowing them to provide an EIP-5164 interface while using Hyperlane as the cross-chain transport layer.

## Instructions

### Install

```sh
$ yarn install
```

### Deploy and Run

#### Setup Environment
Create a `.env` file and set the following variables

- `PRIVATE_KEY`
- `ETHERSCAN_API_KEY`

Fund the account for the above private key with test tokens from a faucet (e.g the Paradigm faucet at [https://faucet.paradigm.xyz](https://faucet.paradigm.xyz).)

These additional variables can also be set depending on your networks of choice

- `MOONSCAN_API_KEY`
- `POLYSCAN_API_KEY`
- `SNOWTRACE_API_KEY`
- `ARBISCAN_API_KEY`

#### Compile contracts
```sh
$ yarn build
```

#### Clear cache and delete artifacts
```sh
$ yarn clean
```

#### Deploy Hyperlane EIP-5164 dispatcher and executor contracts

##### Deploy the Hyperlane EIP-5164 executor
```sh
$ yarn hardhat deploy-executor --network goerli --origin moonbasealpha
```

##### Deploy the Hyperlane EIP-5164 dispatcher
```sh
$ yarn hardhat deploy-dispatcher --network moonbasealpha --executor "EXECUTOR_ADDRESS" --remote goerli
```

#### Send messages via Hyperlane EIP-5164 dispatcher and executor contracts

##### Deploy an EIP-5164 call target
```sh
$ yarn hardhat deploy-call-target --network goerli --executor "EXECUTOR_ADDRESS"
```

##### Send a message to the EIP-5164 call target via the EIP-5164 dispatcher and executor contracts
```sh
$ yarn hardhat send-message --network moonbasealpha --dispatcher "DISPATCHER_ADDRESS" --target "MESSAGE_TARGET_ADDRESS" --message "MESSAGE"
```

### Automated Testing

#### Testing
```sh
$ yarn test
```

#### Coverage
```sh
$ yarn coverage
```

## Security and Liability

All contracts are WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

##  License

All smart contracts are released under GPL-3.0