// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

interface IAllocatorVaultLike {
    function wards(address usr) external view returns (uint256);
}

