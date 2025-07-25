//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant ANVIL_CHAIN_ID = 31337;
    address private constant BURNER_WALLET =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    NetworkConfig public activeNetworkConfig;
    mapping(uint256 => NetworkConfig) internal networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfigs[ANVIL_CHAIN_ID] = getAnvilConfig();
    }

    function getConfigByChainId(
        uint256 _chainId
    ) public view returns (NetworkConfig memory) {
        if (networkConfigs[_chainId].entryPoint == address(0)) {
            revert HelperConfig__InvalidChainId();
        }
        return networkConfigs[_chainId];
    }

    function getEthSepoliaConfig()
        internal
        view
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
                account: BURNER_WALLET
            });
    }

    function getAnvilConfig() internal returns (NetworkConfig memory) {}

    function run() external {}
}
