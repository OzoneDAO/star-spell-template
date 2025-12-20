// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

interface IMaplePoolManagerLike {
    function poolDelegate() external view returns (address);
    function globals() external view returns (address);
}

