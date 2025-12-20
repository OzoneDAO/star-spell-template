// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

import { IAccessControl } from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';

interface IRateLimitsLike is IAccessControl {

    /**********************************************************************************************/
    /*** Structs                                                                                ***/
    /**********************************************************************************************/

    /**
     * @dev   Struct representing a rate limit.
     *        The current rate limit is calculated using the formula:
     *        `currentRateLimit = min(slope * (block.timestamp - lastUpdated) + lastAmount, maxAmount)`.
     * @param maxAmount   Maximum allowed amount at any time.
     * @param slope       The slope of the rate limit, used to calculate the new
     *                    limit based on time passed. [tokens / second]
     * @param lastAmount  The amount left available at the last update.
     * @param lastUpdated The timestamp when the rate limit was last updated.
     */
    struct RateLimitData {
        uint256 maxAmount;
        uint256 slope;
        uint256 lastAmount;
        uint256 lastUpdated;
    }

    /**********************************************************************************************/
    /*** State variables                                                                        ***/
    /**********************************************************************************************/

    /**
     * @dev    Returns the controller identifier as a bytes32 value.
     * @return The controller identifier.
     */
    function CONTROLLER() external view returns (bytes32);

    /**********************************************************************************************/
    /*** Admin functions                                                                        ***/
    /**********************************************************************************************/

    /**
     * @dev   Sets rate limit data for a specific key.
     * @param key         The identifier for the rate limit.
     * @param maxAmount   The maximum allowed amount for the rate limit.
     * @param slope       The slope value used in the rate limit calculation.
     * @param lastAmount  The amount left available at the last update.
     * @param lastUpdated The timestamp when the rate limit was last updated.
     */
    function setRateLimitData(
        bytes32 key,
        uint256 maxAmount,
        uint256 slope,
        uint256 lastAmount,
        uint256 lastUpdated
    ) external;

    /**
     * @dev   Sets rate limit data for a specific key with
     *        `lastAmount == maxAmount` and `lastUpdated == block.timestamp`.
     * @param key       The identifier for the rate limit.
     * @param maxAmount The maximum allowed amount for the rate limit.
     * @param slope     The slope value used in the rate limit calculation.
     */
    function setRateLimitData(bytes32 key, uint256 maxAmount, uint256 slope) external;

    /**
     * @dev   Sets an unlimited rate limit.
     * @param key The identifier for the rate limit.
     */
    function setUnlimitedRateLimitData(bytes32 key) external;

    /**********************************************************************************************/
    /*** Getter Functions                                                                       ***/
    /**********************************************************************************************/

    /**
     * @dev    Retrieves the RateLimitData struct associated with a specific key.
     * @param  key The identifier for the rate limit.
     * @return The data associated with the rate limit.
     */
    function getRateLimitData(bytes32 key) external view returns (RateLimitData memory);

    /**
     * @dev    Retrieves the current rate limit for a specific key.
     * @param  key The identifier for the rate limit.
     * @return The current rate limit value for the given key.
     */
    function getCurrentRateLimit(bytes32 key) external view returns (uint256);
}

