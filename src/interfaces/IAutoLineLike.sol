// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

interface IAutoLineLike {
    function setIlk(
        bytes32 ilk,
        uint256 line,
        uint256 gap,
        uint256 ttl
    ) external;
    function exec(bytes32) external;
}

