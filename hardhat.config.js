require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.27", // 确保与 Jewelry.sol 的版本一致
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
  },
};
