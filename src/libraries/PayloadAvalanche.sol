// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

import { Avalanche } from "../address-registry/Avalanche.sol";
import { LiquidityLayerHelpers } from "./LiquidityLayerHelpers.sol";

/**
 * @dev Base smart contract for Avalanche spells
 * @author Ozone
 */
abstract contract PayloadAvalanche {

    function _onboardERC7540Vault(address vault, uint256 depositMax, uint256 depositSlope) internal {
        LiquidityLayerHelpers.onboardERC7540Vault(
            Avalanche.ALM_RATE_LIMITS,
            vault,
            depositMax,
            depositSlope
        );
    }

    function _onboardERC4626Vault(address vault, uint256 depositMax, uint256 depositSlope) internal {
        LiquidityLayerHelpers.onboardERC4626Vault(
            Avalanche.ALM_RATE_LIMITS,
            vault,
            depositMax,
            depositSlope
        );
    }

    function _setCentrifugeCrosschainTransferRateLimit(address centrifugeVault, uint16 destinationCentrifugeId, uint256 maxAmount, uint256 slope) internal {
        LiquidityLayerHelpers.setCentrifugeCrosschainTransferRateLimit(
            Avalanche.ALM_RATE_LIMITS,
            centrifugeVault,
            destinationCentrifugeId,
            maxAmount,
            slope
        );
    }

    function _onboardAaveToken(address token, uint256 depositMax, uint256 depositSlope) internal {
        LiquidityLayerHelpers.onboardAaveToken(
            Avalanche.ALM_RATE_LIMITS,
            token,
            depositMax,
            depositSlope
        );
    }

    function _onboardCurvePool(
        address controller,
        address pool,
        uint256 maxSlippage,
        uint256 swapMax,
        uint256 swapSlope,
        uint256 depositMax,
        uint256 depositSlope,
        uint256 withdrawMax,
        uint256 withdrawSlope
    ) internal {
        LiquidityLayerHelpers.onboardCurvePool(
            controller,
            Avalanche.ALM_RATE_LIMITS,
            pool,
            maxSlippage,
            swapMax,
            swapSlope,
            depositMax,
            depositSlope,
            withdrawMax,
            withdrawSlope
        );
    }

    function _onboardSyrupUSDCVault(
        address syrupUSDCVault,
        uint256 depositMax,
        uint256 depositSlope,
        uint256 redeemMax,
        uint256 redeemSlope) internal {
        LiquidityLayerHelpers.onboardSyrupUSDCVault({
            rateLimits:     Avalanche.ALM_RATE_LIMITS,
            syrupUSDCVault: syrupUSDCVault,
            depositMax:     depositMax,
            depositSlope:   depositSlope,
            redeemMax:      redeemMax,
            redeemSlope:    redeemSlope
        });
    }
}