// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

interface IStarGuardLike {
    function plot(address addr_, bytes32 tag_) external;
    function exec() external returns (address addr);
}