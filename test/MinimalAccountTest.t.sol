//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AccountAbstraction} from "src/AccountAbstraction.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {DeployContract} from "script/DeployScript.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {GeneratePackedUserOp, PackedUserOperation, IEntryPoint} from "script/SendPackedUserOp.s.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

// import {IEntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;
    HelperConfig helperConfig;
    AccountAbstraction account;
    ERC20Mock usdc;
    GeneratePackedUserOp packedData;

    function setUp() public {
        DeployContract deployContract = new DeployContract();
        (helperConfig, account) = deployContract.run();
        usdc = new ERC20Mock();
        packedData = new GeneratePackedUserOp();
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

    function testnonOwnerCantExecute() public {
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory funcData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            account,
            1000e18
        );
        vm.prank(makeAddr("someone"));

        vm.expectRevert(
            AccountAbstraction
                .AccountAbstraction__NotFronEntryPointOrOwner
                .selector
        );
        account.execute(dest, value, funcData);
    }

    function testRecoveredSignedOp() public {
        bytes memory funcData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            account,
            1000e18
        );
        bytes memory executeCallData = abi.encodeWithSelector(
            account.execute.selector,
            address(usdc),
            0,
            funcData
        );
        PackedUserOperation memory signedUserOp = packedData
            .generateSignedUserOp(
                executeCallData,
                helperConfig.getConfigByChainId(block.chainid)
            );
        bytes32 hashedUserOp = IEntryPoint(
            helperConfig.getConfigByChainId(block.chainid).entryPoint
        ).getUserOpHash(signedUserOp);

        address signer = ECDSA.recover(
            hashedUserOp.toEthSignedMessageHash(),
            signedUserOp.signature
        );
        assertEq(signer, account.owner());
    }
}
