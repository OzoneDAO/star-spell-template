// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

interface IPoolManagerLike {
    function updateTranchePrice(uint64 poolId, bytes16 trancheId, uint128 assetId, uint128 price, uint64 computedAt) external;
    function manager() external view returns (address);
    function poolDelegate() external view returns (address);
    function withdrawalManager() external view returns (address);
}

