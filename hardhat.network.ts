import { HardhatUserConfig } from 'hardhat/config';
import { chainConnectionConfigs, objMap } from '@hyperlane-xyz/sdk';

const accounts: Array<string> = [process.env.PRIVATE_KEY];
const networks: HardhatUserConfig['networks'] = {
  ...objMap(chainConnectionConfigs, (_chain, cc) => ({
    url: (cc.provider.connection.url || '').toString().trim(),
    accounts,
  })),
  moonbeanLocalTestnet: {
    chainId: 1281,
    url: 'http://127.0.0.1:9933',
    accounts,
  },
};

export default networks;
