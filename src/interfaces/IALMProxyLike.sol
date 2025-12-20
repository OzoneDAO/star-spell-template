// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

import { IAccessControl } from 'lib/openzeppelin-contracts/contracts/access/IAccessControl.sol';

interface IALMProxyLike is IAccessControl {
    /**
     * @dev    This function retrieves a constant `bytes32` value that represents the controller.
     * @return The `bytes32` identifier of the controller.
     */
    function CONTROLLER() external view returns (bytes32);
}

