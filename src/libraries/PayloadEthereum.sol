// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

import { Ethereum } from  "../address-registry/Ethereum.sol";
import { Avalanche } from "../address-registry/Avalanche.sol";

import { IExecutorLike } from         "../interfaces/IExecutorLike.sol";
import { IStarSpellLike } from        "../interfaces/IStarSpellLike.sol";
import { LiquidityLayerHelpers } from "./LiquidityLayerHelpers.sol";

import { CCTPForwarder }          from "xchain-helpers/forwarders/CCTPForwarder.sol";

/**
 * @dev Base smart contract for Ethereum spells
 * @author Ozone
 */
abstract contract PayloadEthereum is IStarSpellLike {
    
    // These need to be immutable (delegatecall) and can only be set in constructor
    address public immutable PAYLOAD_AVALANCHE;

    function isExecutable() external view virtual returns (bool result) {
        return true;
    }

    function execute() external {
        _execute();
       
        if (PAYLOAD_AVALANCHE != address(0)) {
            CCTPForwarder.sendMessage({
                messageTransmitter  : CCTPForwarder.MESSAGE_TRANSMITTER_CIRCLE_ETHEREUM,
                destinationDomainId : CCTPForwarder.DOMAIN_ID_CIRCLE_AVALANCHE,
                recipient           : Avalanche.GROVE_RECEIVER,
                messageBody         : _encodePayloadQueue(PAYLOAD_AVALANCHE)
            });
        }
    }

    function _execute() internal virtual;

    function _encodePayloadQueue(address _payload) internal pure returns (bytes memory) {
        address[] memory targets        = new address[](1);
        uint256[] memory values         = new uint256[](1);
        string[] memory signatures      = new string[](1);
        bytes[] memory calldatas        = new bytes[](1);
        bool[] memory withDelegatecalls = new bool[](1);

        targets[0]           = _payload;
        values[0]            = 0;
        signatures[0]        = 'execute()';
        calldatas[0]         = '';
        withDelegatecalls[0] = true;

        return abi.encodeCall(IExecutorLike.queue, (
            targets,
            values,
            signatures,
            calldatas,
            withDelegatecalls
        ));
    }

    function _setUSDSMintRateLimit(uint256 maxAmount, uint256 slope) internal {
        LiquidityLayerHelpers.setUSDSMintRateLimit(
            Ethereum.ALM_RATE_LIMITS,
            maxAmount,
            slope
        );
    }

    function _setUSDSToUSDCRateLimit(uint256 maxAmount, uint256 slope) internal {
        LiquidityLayerHelpers.setUSDSToUSDCRateLimit(
            Ethereum.ALM_RATE_LIMITS,
            maxAmount,
            slope
        );
    }

    function _onboardERC7540Vault(address vault, uint256 depositMax, uint256 depositSlope) internal {
        LiquidityLayerHelpers.onboardERC7540Vault(
            Ethereum.ALM_RATE_LIMITS,
            vault,
            depositMax,
            depositSlope
        );
    }

    function _onboardERC4626Vault(address vault, uint256 depositMax, uint256 depositSlope) internal {
        LiquidityLayerHelpers.onboardERC4626Vault(
            Ethereum.ALM_RATE_LIMITS,
            vault,
            depositMax,
            depositSlope
        );
    }

    function _setCentrifugeCrosschainTransferRateLimit(address centrifugeVault, uint16 destinationCentrifugeId, uint256 maxAmount, uint256 slope) internal {
        LiquidityLayerHelpers.setCentrifugeCrosschainTransferRateLimit(
            Ethereum.ALM_RATE_LIMITS,
            centrifugeVault,
            destinationCentrifugeId,
            maxAmount,
            slope
        );
    }

    function _onboardAaveToken(address token, uint256 depositMax, uint256 depositSlope) internal {
        LiquidityLayerHelpers.onboardAaveToken(
            Ethereum.ALM_RATE_LIMITS,
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
            Ethereum.ALM_RATE_LIMITS,
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
            rateLimits:     Ethereum.ALM_RATE_LIMITS,
            syrupUSDCVault: syrupUSDCVault,
            depositMax:     depositMax,
            depositSlope:   depositSlope,
            redeemMax:      redeemMax,
            redeemSlope:    redeemSlope
        });
    }
}