//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Script} from "forge-std/Script.sol";
import {AccountAbstraction} from "../src/AccountAbstraction.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployContract is Script {
    function run() external returns (HelperConfig, AccountAbstraction) {
        return deployAccount();
    }

    function deployAccount()
        internal
        returns (HelperConfig, AccountAbstraction)
    {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig
            .getConfigByChainId(block.chainid);

        vm.startBroadcast(config.account);
        AccountAbstraction account = new AccountAbstraction(config.entryPoint);
        account.transferOwnership(config.account);
        vm.stopBroadcast();

        return (helperConfig, account);
    }
}
