// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

import { IERC4626 } from "forge-std/interfaces/IERC4626.sol";

import { Ethereum }  from "../address-registry/Ethereum.sol";

import { IALMProxyLike }          from "../interfaces/IALMProxyLike.sol";
import { IRateLimitsLike }        from "../interfaces/IRateLimitsLike.sol";
import { IMainnetControllerLike } from "../interfaces/IMainnetControllerLike.sol";

import { RateLimitHelpers }   from "../libraries/RateLimitHelpers.sol";
import { LiquidityLayerHelpers } from "../libraries/LiquidityLayerHelpers.sol";
import { ChainId, ChainIdUtils } from "../libraries/ChainId.sol";

import { TestBase } from "./TestBase.sol";

struct LiquidityLayerContext {
    address     controller;
    IALMProxyLike   proxy;
    IRateLimitsLike rateLimits;
    address     relayer;
    address     freezer;
}

abstract contract LiquidityLayerTestBase is TestBase {

    function _getLiquidityLayerContext(ChainId chain) internal view returns(LiquidityLayerContext memory ctx) {
        address controller;
        if(chainData[chain].spellExecuted) {
            controller = chainData[chain].newController;
        } else {
            controller = chainData[chain].prevController;
        }
        if (chain == ChainIdUtils.Ethereum()) {
            ctx = LiquidityLayerContext({ controller: controller, 
                                          proxy: IALMProxyLike(Ethereum.ALM_PROXY),
                                          rateLimits: IRateLimitsLike(Ethereum.ALM_RATE_LIMITS),
                                          relayer: Ethereum.ALM_RELAYER,
                                          freezer: Ethereum.ALM_FREEZER });
        } else {
            revert("Chain not supported by LiquidityLayerTestBase context");
        }
    }

    function _getLiquidityLayerContext() internal view returns(LiquidityLayerContext memory) {
        return _getLiquidityLayerContext(ChainIdUtils.fromUint(block.chainid));
    }

    function _assertRateLimit(
        bytes32 key,
        uint256 maxAmount,
        uint256 slope,
        string memory message
    ) internal view {
        IRateLimitsLike.RateLimitData memory rateLimit = _getLiquidityLayerContext().rateLimits.getRateLimitData(key);
        assertEq(rateLimit.maxAmount, maxAmount, message);
        assertEq(rateLimit.slope,     slope, message);
    }

    function _assertUnlimitedRateLimit(
        bytes32 key
    ) internal view {
        IRateLimitsLike.RateLimitData memory rateLimit = _getLiquidityLayerContext().rateLimits.getRateLimitData(key);
        assertEq(rateLimit.maxAmount, type(uint256).max);
        assertEq(rateLimit.slope,     0);
    }

    function _assertZeroRateLimit(
        bytes32 key,
        string memory message
    ) internal view {
        IRateLimitsLike.RateLimitData memory rateLimit = _getLiquidityLayerContext().rateLimits.getRateLimitData(key);
        assertEq(rateLimit.maxAmount, 0, message);
        assertEq(rateLimit.slope,     0, message);
    }

    function _testERC4626Onboarding(
        address vault,
        uint256 expectedDepositAmount,
        uint256 depositMax,
        uint256 depositSlope
    ) internal {
        LiquidityLayerContext memory ctx = _getLiquidityLayerContext();
        bool unlimitedDeposit = depositMax == type(uint256).max;

        // Note: ERC4626 signature is the same for mainnet and foreign
        deal(IERC4626(vault).asset(), address(ctx.proxy), expectedDepositAmount);
        bytes32 depositKey = RateLimitHelpers.makeAssetKey(
            LiquidityLayerHelpers.LIMIT_4626_DEPOSIT,
            vault
        );
        bytes32 withdrawKey = RateLimitHelpers.makeAssetKey(
            LiquidityLayerHelpers.LIMIT_4626_WITHDRAW,
            vault
        );

        _assertZeroRateLimit(depositKey, "Deposit rate limit should be zero before spell execution");
        _assertZeroRateLimit(withdrawKey, "Withdraw rate limit should be zero before spell execution");

        vm.prank(ctx.relayer);
        vm.expectRevert("RateLimits/zero-maxAmount");
        IMainnetControllerLike(ctx.controller).depositERC4626(vault, expectedDepositAmount);

        executeAllPayloadsAndBridges();

        // Reload the context after spell execution to get the new controller after potential controller upgrade
        ctx = _getLiquidityLayerContext();

        _assertRateLimit(depositKey, depositMax, depositSlope, "Deposit rate limit should be set correctly after spell execution");
        _assertRateLimit(withdrawKey, type(uint256).max, 0, "Withdraw rate limit should be unlimited after spell execution");

        if (!unlimitedDeposit) {
            vm.prank(ctx.relayer);
            vm.expectRevert("RateLimits/rate-limit-exceeded");
            IMainnetControllerLike(ctx.controller).depositERC4626(vault, depositMax + 1);
        }

        assertEq(ctx.rateLimits.getCurrentRateLimit(depositKey),  depositMax);
        assertEq(ctx.rateLimits.getCurrentRateLimit(withdrawKey), type(uint256).max);

        vm.prank(ctx.relayer);
        IMainnetControllerLike(ctx.controller).depositERC4626(vault, expectedDepositAmount);

        assertEq(ctx.rateLimits.getCurrentRateLimit(depositKey),  unlimitedDeposit ? type(uint256).max : depositMax - expectedDepositAmount);
        assertEq(ctx.rateLimits.getCurrentRateLimit(withdrawKey), type(uint256).max);

        vm.prank(ctx.relayer);
        IMainnetControllerLike(ctx.controller).withdrawERC4626(vault, expectedDepositAmount / 2);

        assertEq(ctx.rateLimits.getCurrentRateLimit(depositKey),  unlimitedDeposit ? type(uint256).max : depositMax - expectedDepositAmount);
        assertEq(ctx.rateLimits.getCurrentRateLimit(withdrawKey), type(uint256).max);

        if (!unlimitedDeposit) {
            // Do some sanity checks on the slope
            // This is to catch things like forgetting to divide to a per-second time, etc

            // We assume it takes at least 1 day to recharge to max
            uint256 dailySlope = depositSlope * 1 days;
            assertLe(dailySlope, depositMax);

            // It shouldn"t take more than 30 days to recharge to max
            uint256 monthlySlope = depositSlope * 30 days;
            assertGe(monthlySlope, depositMax);
        }
    }
}

