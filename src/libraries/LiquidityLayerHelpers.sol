// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

import { RateLimitHelpers } from       "./RateLimitHelpers.sol";
import { IRateLimitsLike } from        "../interfaces/IRateLimitsLike.sol";
import { IMainnetControllerLike } from "../interfaces/IMainnetControllerLike.sol";

/**
 * @notice Helper functions for _AGENT_ Liquidity Layer
 */
library LiquidityLayerHelpers {

    bytes32 public constant LIMIT_4626_DEPOSIT        = keccak256("LIMIT_4626_DEPOSIT");
    bytes32 public constant LIMIT_4626_WITHDRAW       = keccak256("LIMIT_4626_WITHDRAW");
    bytes32 public constant LIMIT_USDS_MINT           = keccak256("LIMIT_USDS_MINT");
    bytes32 public constant LIMIT_USDS_TO_USDC        = keccak256("LIMIT_USDS_TO_USDC");
    bytes32 public constant LIMIT_MAPLE_REDEEM        = keccak256("LIMIT_MAPLE_REDEEM");
    bytes32 public constant LIMIT_7540_DEPOSIT        = keccak256("LIMIT_7540_DEPOSIT");
    bytes32 public constant LIMIT_7540_REDEEM         = keccak256("LIMIT_7540_REDEEM");
    bytes32 public constant LIMIT_CENTRIFUGE_TRANSFER = keccak256("LIMIT_CENTRIFUGE_TRANSFER");
    bytes32 public constant LIMIT_AAVE_DEPOSIT        = keccak256("LIMIT_AAVE_DEPOSIT");
    bytes32 public constant LIMIT_AAVE_WITHDRAW       = keccak256("LIMIT_AAVE_WITHDRAW");
    bytes32 public constant LIMIT_CURVE_DEPOSIT       = keccak256("LIMIT_CURVE_DEPOSIT");
    bytes32 public constant LIMIT_CURVE_SWAP          = keccak256("LIMIT_CURVE_SWAP");
    bytes32 public constant LIMIT_CURVE_WITHDRAW      = keccak256("LIMIT_CURVE_WITHDRAW");

    /**
     * @notice Onboard an ERC4626 vault
     * @dev This will set the deposit to the given numbers with
     *      the withdraw limit set to unlimited.
     */
    function onboardERC4626Vault(
        address rateLimits,
        address vault,
        uint256 depositMax,
        uint256 depositSlope
    ) internal {
        bytes32 depositKey = RateLimitHelpers.makeAssetKey(
            LIMIT_4626_DEPOSIT,
            vault
        );
        bytes32 withdrawKey = RateLimitHelpers.makeAssetKey(
            LIMIT_4626_WITHDRAW,
            vault
        );
        IRateLimitsLike(rateLimits).setRateLimitData(depositKey, depositMax, depositSlope);
        IRateLimitsLike(rateLimits).setUnlimitedRateLimitData(withdrawKey);
    }

    /**
     * @notice Onboard an ERC7540 vault
     * @dev This will set the deposit to the given numbers with
     *      the redeem limit set to unlimited.
     */
    function onboardERC7540Vault(
        address rateLimits,
        address vault,
        uint256 depositMax,
        uint256 depositSlope
    ) internal {
        bytes32 depositKey = RateLimitHelpers.makeAssetKey(
            LIMIT_7540_DEPOSIT,
            vault
        );
        bytes32 redeemKey = RateLimitHelpers.makeAssetKey(
            LIMIT_7540_REDEEM,
            vault
        );

        IRateLimitsLike(rateLimits).setRateLimitData(depositKey, depositMax, depositSlope);
        IRateLimitsLike(rateLimits).setUnlimitedRateLimitData(redeemKey);
    }

    /**
     * @notice Onboard the SyrupUSDC vault
     * @dev This will set the deposit and redeem limits to the given numbers.
     */
    function onboardSyrupUSDCVault(address rateLimits,address syrupUSDCVault,uint256 depositMax,uint256 depositSlope,uint256 redeemMax,uint256 redeemSlope) internal {
        bytes32 depositKey = RateLimitHelpers.makeAssetKey(
            LIMIT_4626_DEPOSIT,
            syrupUSDCVault
        );
        bytes32 withdrawKey = RateLimitHelpers.makeAssetKey(LIMIT_MAPLE_REDEEM, syrupUSDCVault);
        IRateLimitsLike(rateLimits).setRateLimitData(depositKey, depositMax, depositSlope);
        IRateLimitsLike(rateLimits).setRateLimitData(withdrawKey, redeemMax, redeemSlope);
    }

    /**
     * @notice Onboard an Aave token
     * @dev This will set the deposit to the given numbers with
     *      the withdraw limit set to unlimited.
     */
    function onboardAaveToken(
        address rateLimits,
        address token,
        uint256 depositMax,
        uint256 depositSlope
    ) internal {
        bytes32 depositKey = RateLimitHelpers.makeAssetKey(
            LIMIT_AAVE_DEPOSIT,
            token
        );
        bytes32 withdrawKey = RateLimitHelpers.makeAssetKey(
            LIMIT_AAVE_WITHDRAW,
            token
        );

        IRateLimitsLike(rateLimits).setRateLimitData(depositKey, depositMax, depositSlope);
        IRateLimitsLike(rateLimits).setUnlimitedRateLimitData(withdrawKey);
    }

    /**********************************************************************************************/
    /*** Curve functions                                                                        ***/
    /**********************************************************************************************/

    /**
     * @notice Onboard a Curve pool
     * @dev This will set the rate limit for a Curve pool
     *      for the swap, deposit, and withdraw functions.
     */
    function onboardCurvePool(
        address controller,
        address rateLimits,
        address pool,
        uint256 maxSlippage,
        uint256 swapMax,
        uint256 swapSlope,
        uint256 depositMax,
        uint256 depositSlope,
        uint256 withdrawMax,
        uint256 withdrawSlope
    ) internal {
        IMainnetControllerLike(controller).setMaxSlippage(pool, maxSlippage);

        if (swapMax != 0) {
            bytes32 swapKey = RateLimitHelpers.makeAssetKey(
                LIMIT_CURVE_SWAP,
                pool
            );
            IRateLimitsLike(rateLimits).setRateLimitData(swapKey, swapMax, swapSlope);
        }

        if (depositMax != 0) {
            bytes32 depositKey = RateLimitHelpers.makeAssetKey(
                LIMIT_CURVE_DEPOSIT,
                pool
            );
            IRateLimitsLike(rateLimits).setRateLimitData(depositKey, depositMax, depositSlope);
        }

        if (withdrawMax != 0) {
            bytes32 withdrawKey = RateLimitHelpers.makeAssetKey(
                LIMIT_CURVE_WITHDRAW,
                pool
            );
            IRateLimitsLike(rateLimits).setRateLimitData(withdrawKey, withdrawMax, withdrawSlope);
        }
    }

    /**********************************************************************************************/
    /*** Centrifuge functions                                                                   ***/
    /**********************************************************************************************/

    /**
     * @notice Set the rate limit for a Centrifuge cross-chain transfer
     * @dev This will set the rate limit for a Centrifuge cross-chain transfer
     */
    function setCentrifugeCrosschainTransferRateLimit(
        address rateLimits,
        address centrifugeVault,
        uint16  destinationCentrifugeId,
        uint256 maxAmount,
        uint256 slope
    ) internal {
        bytes32 centrifugeCrosschainTransferKey = keccak256(abi.encode(LIMIT_CENTRIFUGE_TRANSFER, centrifugeVault, destinationCentrifugeId));

        IRateLimitsLike(rateLimits).setRateLimitData(centrifugeCrosschainTransferKey, maxAmount, slope);
    }

    function setUSDSMintRateLimit(
        address rateLimits,
        uint256 maxAmount,
        uint256 slope
    ) internal {
        bytes32 mintKey = LIMIT_USDS_MINT;

        IRateLimitsLike(rateLimits).setRateLimitData(mintKey, maxAmount, slope);
    }

    /**
     * @notice Set the USDSToUSDC rate limit
     * @dev This will set the USDSToUSDC rate limit to the given numbers.
     */
    function setUSDSToUSDCRateLimit(
        address rateLimits,
        uint256 maxUsdcAmount,
        uint256 slope
    ) internal {
        bytes32 usdsToUsdcKey = LIMIT_USDS_TO_USDC;

        IRateLimitsLike(rateLimits).setRateLimitData(usdsToUsdcKey, maxUsdcAmount, slope);
    }
}