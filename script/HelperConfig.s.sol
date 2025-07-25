//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

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
    address private constant FOUNDRY_DEFAULT_SENDER =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    address private constant DEFAULT_WALLET =
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
        console.log("Chain ID:", _chainId);
        if (networkConfigs[_chainId].account == address(0)) {
            revert HelperConfig__InvalidChainId();
        }
        return networkConfigs[_chainId];
    }

    function getEthSepoliaConfig()
        internal
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
                account: BURNER_WALLET
            });
    }

    function getAnvilConfig() internal pure returns (NetworkConfig memory) {
        vm.startBroadcast(FOUNDRY_DEFAULT_SENDER);
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();
        return
            NetworkConfig({
                entryPoint: address(entryPoint),
                account: FOUNDRY_DEFAULT_SENDER
            });
    }

    function run() external {}
}
