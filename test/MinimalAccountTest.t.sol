//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AccountAbstraction} from "src/AccountAbstraction.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {DeployContract} from "script/DeployScript.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract MinimalAccountTest is Test {
    HelperConfig helperConfig;
    AccountAbstraction account;
    ERC20Mock usdc;

    function setUp() public {
        DeployContract deployContract = new DeployContract();
        (helperConfig, account) = deployContract.run();
        usdc = new ERC20Mock();
    }

    function testOwnerCanExecuteCommands() public {
        assertEq(usdc.balanceOf(address(account)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory funcData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            account,
            1000e18
        );
        vm.prank(account.owner());
        account.execute(dest, value, funcData);

        assertEq(usdc.balanceOf(address(account)), 1000e18);
    }
}
