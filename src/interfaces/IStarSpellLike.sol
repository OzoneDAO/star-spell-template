// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

interface IStarSpellLike {

    /**
     * @notice Executes actions performed on behalf of the `SubProxy` – i.e. the actual payload
     * @dev Required, will be called by the StarGuard during permissionless execution
     */
    function execute() external;

    /**
     * @notice Checks if the star payload is executable in the current block
     * @dev Required, useful for implementing "earliest launch date" or "office hours" strategy
     * @return result The result of the check (true = executable, false = not)
     */
    function isExecutable() external view returns (bool result);
}