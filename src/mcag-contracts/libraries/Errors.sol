// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Errors {
    error CANNOT_SET_TO_ADDRESS_ZERO();
    error ERC721_APPROVAL_TO_CURRENT_OWNER();
    error ERC721_APPROVE_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED_FOR_ALL();
    error ERC721_INVALID_TOKEN_ID();
    error ERC721_CALLER_IS_NOT_TOKEN_OWNER();
    error ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(address account, bytes32 role);
    error BLACKLIST_CALLER_IS_NOT_BLACKLISTER();
    error BLACKLIST_ACCOUNT_IS_BLACKLISTED(address account);
    error TRANSMITTED_ANSWER_TOO_HIGH(int256 answer, int256 maxAnswer);
    error TOKEN_IS_NOT_TRANSFERABLE();
}
