//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract GeneratePackedUserOp is Script {
    using MessageHashUtils for bytes32;
    uint256 private constant FOUNDRY_DEFAULT_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function generateSignedUserOp(
        bytes memory callData,
        HelperConfig.NetworkConfig memory config
    ) public returns (PackedUserOperation memory) {
        uint256 nonce = vm.getNonce(config.account);
        PackedUserOperation memory userOp = _generateUnsignedOps(
            config.account,
            nonce,
            callData
        );
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(
            userOp
        );
        bytes32 digest = userOpHash.toEthSignedMessageHash();
        if (block.chainid == 31337) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(
                FOUNDRY_DEFAULT_PRIVATE_KEY,
                digest
            );
            userOp.signature = abi.encodePacked(r, s, v);
        } else {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(config.account, digest);
            userOp.signature = abi.encodePacked(r, s, v);
        }

        return userOp;
    }

    function _generateUnsignedOps(
        address sender,
        uint256 nonce,
        bytes memory callData
    ) internal returns (PackedUserOperation memory) {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        return
            PackedUserOperation({
                sender: sender,
                nonce: nonce,
                initCode: hex"",
                callData: callData,
                accountGasLimits: bytes32(
                    (uint256(verificationGasLimit) << 128) | callGasLimit
                ),
                preVerificationGas: verificationGasLimit,
                gasFees: bytes32(
                    (uint256(maxPriorityFeePerGas) << 128) | maxFeePerGas
                ),
                paymasterAndData: hex"",
                signature: hex""
            });
    }
}
