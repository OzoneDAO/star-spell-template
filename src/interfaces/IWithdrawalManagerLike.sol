// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

interface IWithdrawalManagerLike {
    function processRedemptions(uint256 maxSharesToProcess) external;
}

