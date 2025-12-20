// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

interface IVatLike {
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
}