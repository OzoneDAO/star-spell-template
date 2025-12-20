// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

interface IPermissionManagerLike {
    function admin() external view returns (address);
    function setLenderAllowlist(address pool, address[] calldata lenders, bool[] calldata booleans) external;
}

