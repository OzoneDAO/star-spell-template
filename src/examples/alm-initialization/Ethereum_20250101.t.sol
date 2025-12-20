// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

import { LiquidityLayerTestBase } from "../../test-harness/LiquidityLayerTestBase.sol";

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { Ethereum } from "../../address-registry/Ethereum.sol";

import { RateLimitHelpers } from "../../libraries/RateLimitHelpers.sol";

import { IALMProxyLike }          from "../../interfaces/IALMProxyLike.sol";
import { IRateLimitsLike }        from "../../interfaces/IRateLimitsLike.sol";
import { IMainnetControllerLike } from "../../interfaces/IMainnetControllerLike.sol";
import { IAllocatorVaultLike }    from '../../interfaces/IAllocatorVaultLike.sol';
import { IVatLike }           from '../../interfaces/IVatLike.sol';
import { IPSMLike }           from '../../interfaces/IPSMLike.sol';
import { IPoolManagerLike }   from '../../interfaces/IPoolManagerLike.sol';
import { IWithdrawalManagerLike } from '../../interfaces/IWithdrawalManagerLike.sol';
import { IPermissionManagerLike } from '../../interfaces/IPermissionManagerLike.sol';
import { IMaplePoolManagerLike } from '../../interfaces/IMaplePoolManagerLike.sol';
import { IAutoLineLike }       from '../../interfaces/IAutoLineLike.sol';

import { Ethereum_20250101 as Spell } from "./Ethereum_20250101.sol";

import { ChainIdUtils } from "../../libraries/ChainId.sol";

contract Ethereum_20250101Test is LiquidityLayerTestBase {

    Spell internal SPELL;
    address internal DEPLOYER;

    address internal constant MCD_IAM_AUTO_LINE = 0xC7Bdd1F2B16447dcf3dE045C4a039A60EC2f0ba3;

    bytes32 internal constant ALLOCATOR_ILK = "ALLOCATOR-OBEX-A";

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAD = 10 ** 45;

    IALMProxyLike          almProxy   = IALMProxyLike(Ethereum.ALM_PROXY);
    IRateLimitsLike        rateLimits = IRateLimitsLike(Ethereum.ALM_RATE_LIMITS);
    IMainnetControllerLike controller = IMainnetControllerLike(Ethereum.ALM_CONTROLLER);

    constructor() {
        id = "20250101";
    }

    function _setupAddresses() internal virtual {
        SPELL = Spell(chainData[ChainIdUtils.Ethereum()].payload);
    }

    function setUp() public {
        setupMainnetDomain({ mainnetForkBlock: 23770489  }); //24055133
        _setupAddresses();

        vm.startPrank(Ethereum.PAUSE_PROXY);
        IPSMLike(address(controller.psm())).kiss(address(almProxy));
        vm.stopPrank();
    }

    function test_almSystemDeployment() public view {
        assertEq(almProxy.hasRole(0x0, Ethereum.SUB_PROXY),   true, "incorrect-admin-almProxy");
        assertEq(rateLimits.hasRole(0x0, Ethereum.SUB_PROXY), true, "incorrect-admin-rateLimits");
        assertEq(controller.hasRole(0x0, Ethereum.SUB_PROXY), true, "incorrect-admin-controller");

        assertEq(almProxy.hasRole(0x0, DEPLOYER),   false, "incorrect-admin-almProxy");
        assertEq(rateLimits.hasRole(0x0, DEPLOYER), false, "incorrect-admin-rateLimits");
        assertEq(controller.hasRole(0x0, DEPLOYER), false, "incorrect-admin-controller");

        assertEq(address(controller.proxy()),                Ethereum.ALM_PROXY,            "incorrect-almProxy");
        assertEq(address(controller.rateLimits()),           Ethereum.ALM_RATE_LIMITS,      "incorrect-rateLimits");
        assertEq(address(controller.vault()),                Ethereum.ALLOCATOR_VAULT,      "incorrect-vault");
        assertEq(address(controller.buffer()),               Ethereum.ALLOCATOR_BUFFER,     "incorrect-buffer");
        assertEq(address(controller.psm()),                  Ethereum.PSM,                  "incorrect-psm");
        assertEq(address(controller.daiUsds()),              Ethereum.DAI_USDS,             "incorrect-daiUsds");
        assertEq(address(controller.cctp()),                 Ethereum.CCTP_TOKEN_MESSENGER, "incorrect-cctpMessenger");
        assertEq(address(controller.dai()),                  Ethereum.DAI,                  "incorrect-dai");
        assertEq(address(controller.susde()),                Ethereum.SUSDE,                "incorrect-susde");
        assertEq(address(controller.usdc()),                 Ethereum.USDC,                 "incorrect-usdc");
        assertEq(address(controller.usde()),                 Ethereum.USDE,                 "incorrect-usde");
        assertEq(address(controller.usds()),                 Ethereum.USDS,                 "incorrect-usds");

        assertEq(controller.psmTo18ConversionFactor(), 1e12, "incorrect-psmTo18ConversionFactor");

        IVatLike vat = IVatLike(Ethereum.VAT);

        ( uint256 Art, uint256 rate,, uint256 line, ) = vat.ilks(ALLOCATOR_ILK);

        assertEq(Art,  0, "incorrect-normalized-debt-should-be-zero-initial");
        assertEq(rate, 1e27, "incorrect-rate-should-be-1e27-initial");
        assertEq(line, 10_000_000e45, "incorrect-debt-ceiling-should-be-10m-initial");

        assertEq(IERC20(Ethereum.USDS).balanceOf(Ethereum.SUB_PROXY),  0, "incorrect-usds-balance-sub-proxy-should-be-zero-initial");
    }

    function test_almSystemInitialization() public {
        executeMainnetPayload();

        assertEq(almProxy.hasRole(almProxy.CONTROLLER(), Ethereum.ALM_CONTROLLER), true, "incorrect-controller-almProxy");

        assertEq(rateLimits.hasRole(rateLimits.CONTROLLER(), Ethereum.ALM_CONTROLLER), true, "incorrect-controller-rateLimits");

        assertEq(controller.hasRole(controller.FREEZER(), Ethereum.ALM_FREEZER), true, "incorrect-freezer-controller");
        assertEq(controller.hasRole(controller.RELAYER(), Ethereum.ALM_RELAYER), true, "incorrect-relayer-controller");
        assertEq(controller.hasRole(controller.RELAYER(), SPELL.OZONE_OEA_RELAYER()), true, "incorrect-relayer-controller for Ozone OEA");

        assertEq(IAllocatorVaultLike(Ethereum.ALLOCATOR_VAULT).wards(Ethereum.ALM_PROXY), 1, "incorrect-vault-ward");

        assertEq(IERC20(Ethereum.USDS).allowance(Ethereum.ALLOCATOR_BUFFER, Ethereum.ALM_PROXY), type(uint256).max, "incorrect-usds-allowance");
    }

    function test_basicRateLimits() public {
        _assertRateLimit({
            key: controller.LIMIT_USDS_MINT(),
            maxAmount: 0,
            slope: 0,
            message: "before execution: incorrect-usds-mint-rate-limit"
        });

        _assertRateLimit({
            key: controller.LIMIT_USDS_TO_USDC(),
            maxAmount: 0,
            slope: 0,
            message: "before execution: incorrect-usds-to-usdc-rate-limit"
        });

        executeMainnetPayload();

        _assertRateLimit({
            key: controller.LIMIT_USDS_MINT(),
            maxAmount: 100_000_000e18,
            slope: 50_000_000e18 / uint256(1 days),
            message: "after execution: incorrect-usds-mint-rate-limit"
        });

        _assertRateLimit({
            key: controller.LIMIT_USDS_TO_USDC(),
            maxAmount: 100_000_000e6,
            slope: 50_000_000e6 / uint256(1 days),
            message: "after execution: incorrect-usds-to-usdc-rate-limit"
        });
    }

    function test_SyrupUSDCRateLimitSetup() public {
        _assertRateLimit({
            key: RateLimitHelpers.makeAssetKey(
                controller.LIMIT_4626_DEPOSIT(),
                SPELL.SYRUP_USDC_VAULT()
            ),
            maxAmount: 0,
            slope: 0,
            message: "before execution: incorrect-syrup-usdc-deposit-rate-limit"
        });

        _assertRateLimit({
            key: RateLimitHelpers.makeAssetKey(
                controller.LIMIT_MAPLE_REDEEM(),
                SPELL.SYRUP_USDC_VAULT()
            ), 
            maxAmount: 0,
            slope: 0,
            message: "before execution: incorrect-syrup-usdc-redeem-rate-limit"
        });

        executeMainnetPayload();

        _assertRateLimit({
            key: RateLimitHelpers.makeAssetKey(
                controller.LIMIT_4626_DEPOSIT(),
                SPELL.SYRUP_USDC_VAULT()
            ),
            maxAmount: 100_000_000e6,
            slope: 20_000_000e6 / uint256(1 days),
            message: "after execution: incorrect-syrup-usdc-deposit-rate-limit"
        });

        _assertRateLimit({
            key: RateLimitHelpers.makeAssetKey(
                controller.LIMIT_MAPLE_REDEEM(),
                SPELL.SYRUP_USDC_VAULT()
            ),
            maxAmount: type(uint256).max,
            slope: 0,
            message: "after execution: incorrect-syrup-usdc-redeem-rate-limit"
        });
    }

    function test_allocateToSyrupUSDC() public {
        IVatLike vat = IVatLike(Ethereum.VAT);
        IPermissionManagerLike permissionManager = IPermissionManagerLike(0xBe10aDcE8B6E3E02Db384E7FaDA5395DD113D8b3);

        // Increase the debt ceiling to allow minting
        vm.prank(Ethereum.PAUSE_PROXY);
        IAutoLineLike(MCD_IAM_AUTO_LINE).setIlk({
            ilk:  ALLOCATOR_ILK,
            line: 2_500_000_000 * RAD,  // 2.5B total line
            gap:  250_000_000 * RAD,     // 250M gap
            ttl:  1 days
        });

        executeMainnetPayload();

        // Whitelist ALM_PROXY with Maple permission manager
        address poolManager = IPoolManagerLike(SPELL.SYRUP_USDC_VAULT()).manager();
        address poolDelegate = IMaplePoolManagerLike(poolManager).poolDelegate();
        
        address[] memory lenders  = new address[](1);
        bool[]    memory booleans = new bool[](1);
        lenders[0]  = Ethereum.ALM_PROXY;
        booleans[0] = true;

        // Use pool delegate instead of admin (permissions changed after Jan 2025)
        vm.prank(poolDelegate);
        permissionManager.setLenderAllowlist(
            poolManager,
            lenders,
            booleans
        );

        // Execute auto-line to increase ceiling
        IAutoLineLike(MCD_IAM_AUTO_LINE).exec(ALLOCATOR_ILK);

        ( uint256 Art,,, uint256 line, ) = vat.ilks(ALLOCATOR_ILK);
        assertEq(Art,  0, "after execution: incorrect-normalized-debt-should-be-zero-after-auto-line");
        assertEq(line, 250_000_000 * RAD, "after execution: incorrect-debt-ceiling-should-be-250m-after-auto-line");  // Should now be 250M

        vm.warp(block.timestamp + 10 days);

        vm.startPrank(Ethereum.ALM_RELAYER);
        controller.mintUSDS(100_000_000e18);
        controller.swapUSDSToUSDC(100_000_000e6);
        controller.depositERC4626(SPELL.SYRUP_USDC_VAULT(), 100_000_000e6);

        // Verify the allocation worked
        assertGt(IERC20(SPELL.SYRUP_USDC_VAULT()).balanceOf(Ethereum.ALM_PROXY), 0, "should have SyrupUSDC shares");
        vm.warp(block.timestamp + 10 days);
        controller.mintUSDS(100_000_000e18);
        // controller.swapUSDSToUSDC(100_000_000e6);
        // controller.depositERC4626(SPELL.SYRUP_USDC_VAULT(), 100_000_000e6);
        vm.stopPrank();
    }

    function test_redeemSyrupUSDC() public {
        IVatLike vat = IVatLike(Ethereum.VAT);
        IPermissionManagerLike permissionManager = IPermissionManagerLike(0xBe10aDcE8B6E3E02Db384E7FaDA5395DD113D8b3);

        // Increase the debt ceiling to allow minting
        vm.prank(Ethereum.PAUSE_PROXY);
        IAutoLineLike(MCD_IAM_AUTO_LINE).setIlk({
            ilk:  ALLOCATOR_ILK,
            line: 2_500_000_000 * RAD,  // 2.5B total line
            gap:  250_000_000 * RAD,     // 250M gap
            ttl:  1 days
        });

        executeMainnetPayload();

        // Whitelist ALM_PROXY with Maple permission manager
        address poolManager = IPoolManagerLike(SPELL.SYRUP_USDC_VAULT()).manager();
        address poolDelegate = IMaplePoolManagerLike(poolManager).poolDelegate();
        
        address[] memory lenders  = new address[](1);
        bool[]    memory booleans = new bool[](1);
        lenders[0]  = Ethereum.ALM_PROXY;
        booleans[0] = true;

        // Use pool delegate instead of admin (permissions changed after Jan 2025)
        vm.prank(poolDelegate);
        permissionManager.setLenderAllowlist(
            poolManager,
            lenders,
            booleans
        );

        // Execute auto-line to increase ceiling
        IAutoLineLike(MCD_IAM_AUTO_LINE).exec(ALLOCATOR_ILK);

        ( uint256 Art,,, uint256 line, ) = vat.ilks(ALLOCATOR_ILK);
        assertEq(Art,  0, "after execution: incorrect-normalized-debt-should-be-zero-after-auto-line");
        assertEq(line, 250_000_000 * RAD, "after execution: incorrect-debt-ceiling-should-be-250m-after-auto-line");  // Should now be 250M

        vm.warp(block.timestamp + 10 days);

        vm.startPrank(Ethereum.ALM_RELAYER);
        controller.mintUSDS(100_000_000e18);
        controller.swapUSDSToUSDC(100_000_000e6);
        uint256 shares = controller.depositERC4626(SPELL.SYRUP_USDC_VAULT(), 100_000_000e6);
        assertGt(shares, 0, "should have SyrupUSDC shares");

        address manager = IPoolManagerLike(SPELL.SYRUP_USDC_VAULT()).manager();
        uint256 withdrawalManagerSharesBefore = IERC20(SPELL.SYRUP_USDC_VAULT()).balanceOf(IPoolManagerLike(manager).withdrawalManager());

        controller.requestMapleRedemption(SPELL.SYRUP_USDC_VAULT(), shares);
        assertEq(IERC20(SPELL.SYRUP_USDC_VAULT()).balanceOf(Ethereum.ALM_PROXY), 0, "should have no SyrupUSDC shares");
        assertEq(IERC20(SPELL.SYRUP_USDC_VAULT()).balanceOf(IPoolManagerLike(manager).withdrawalManager()), withdrawalManagerSharesBefore + shares, "should have SyrupUSDC shares in withdrawal manager");
        vm.stopPrank();
        
        address USDC = Ethereum.USDC;
        uint256 proxyBalanceBefore = IERC20(USDC).balanceOf(Ethereum.ALM_PROXY);
        //prank as the withdrawal manager to process the redemptions
        IWithdrawalManagerLike withdrawalManager = IWithdrawalManagerLike(IPoolManagerLike(manager).withdrawalManager());
        vm.startPrank(address(poolDelegate));
        withdrawalManager.processRedemptions(shares);
        vm.stopPrank();

        uint256 proxyBalanceAfter = IERC20(USDC).balanceOf(Ethereum.ALM_PROXY);
        assertEq(proxyBalanceAfter, proxyBalanceBefore + 100_000_000 * 1e6 - 1, "should have USDC in proxy");
    }
}