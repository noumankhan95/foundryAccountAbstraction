//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";

contract AccountAbstraction is IAccount, Ownable {
    error AccountAbstraction__NotFronEntryPoint();
    error AccountAbstraction__NotFronEntryPointOrOwner();
    error AccountAbstraction__ExecuteFailed(bytes);

    address immutable i_entryPoint;

    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = entryPoint;
    }

    modifier requireFromEntryPoint() {
        if (msg.sender != i_entryPoint) {
            revert AccountAbstraction__NotFronEntryPoint();
        }
        _;
    }
    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != i_entryPoint && msg.sender != owner()) {
            revert AccountAbstraction__NotFronEntryPointOrOwner();
        }
        _;
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external requireFromEntryPoint returns (uint256 validationData) {
        validationData = _verifySignature(userOp, userOpHash);
        _payPrefund(missingAccountFunds);
    }

    function execute(
        address dest,
        uint256 value,
        bytes calldata funcData
    ) external requireFromEntryPointOrOwner {
        (bool success, bytes memory result) = dest.call{value: value}(funcData);
        if (!success) {
            revert AccountAbstraction__ExecuteFailed(result);
        }
    }

    //EIP-191 version
    function _verifySignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view returns (uint256) {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            userOpHash
        );

        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        }

        return SIG_VALIDATION_SUCCESS;
    }

    function _payPrefund(uint256 _missingFunds) internal {
        if (_missingFunds > 0) {
            (bool success, ) = i_entryPoint.call{value: _missingFunds}("");
        }
    }

    receive() external payable {}
}
