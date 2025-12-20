// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

import { IAccessControl } from 'lib/openzeppelin-contracts/contracts/access/IAccessControl.sol';

interface IMainnetControllerLike is IAccessControl {

    /**********************************************************************************************/
    /*** Admin functions                                                                        ***/
    /**********************************************************************************************/

    function setMintRecipient(uint32 destinationDomain, bytes32 mintRecipient) external;

    function setLayerZeroRecipient(uint32 destinationEndpointId, bytes32 layerZeroRecipient) external;

    function setMaxSlippage(address pool, uint256 maxSlippage) external;

    function setCentrifugeRecipient(uint16 centrifugeId, bytes32 recipient) external;

    /**********************************************************************************************/
    /*** Relayer vault functions                                                                ***/
    /**********************************************************************************************/

    function mintUSDS(uint256 usdsAmount) external;

    function burnUSDS(uint256 usdsAmount) external;

    /**********************************************************************************************/
    /*** Relayer ERC4626 functions                                                              ***/
    /**********************************************************************************************/

    function depositERC4626(address token, uint256 amount) external returns (uint256 shares);

    function withdrawERC4626(address token, uint256 amount) external returns (uint256 shares);

    function redeemERC4626(address token, uint256 shares) external returns (uint256 assets);

    /**********************************************************************************************/
    /*** Relayer ERC7540 functions                                                              ***/
    /**********************************************************************************************/

    function requestDepositERC7540(address token, uint256 amount) external;

    function claimDepositERC7540(address token) external;

    function requestRedeemERC7540(address token, uint256 shares) external;

    function claimRedeemERC7540(address token) external;

    /**********************************************************************************************/
    /*** Relayer Maple functions                                                                ***/
    /**********************************************************************************************/

    function requestMapleRedemption(address mapleToken, uint256 shares) external;

    function cancelMapleRedemption(address mapleToken, uint256 shares) external;

    /**********************************************************************************************/
    /*** Relayer PSM functions                                                                  ***/
    /**********************************************************************************************/

    function swapUSDSToUSDC(uint256 usdcAmount) external;

    function swapUSDCToUSDS(uint256 usdcAmount) external;

    /**********************************************************************************************/
    /*** View functions                                                                         ***/
    /**********************************************************************************************/

    function buffer() external view returns (address);

    function maxSlippages(address pool) external view returns (uint256);

    function mintRecipients(uint32 destinationDomain) external view returns (bytes32);

    function layerZeroRecipients(uint32 destinationEndpointId) external view returns (bytes32);

    function centrifugeRecipients(uint16 centrifugeId) external view returns (bytes32);

    function psmTo18ConversionFactor() external view returns (uint256);

    /**********************************************************************************************/
    /*** Role constants                                                                         ***/
    /**********************************************************************************************/

    function FREEZER() external view returns (bytes32);

    function RELAYER() external view returns (bytes32);

    function LIMIT_4626_DEPOSIT() external view returns (bytes32);

    function LIMIT_4626_WITHDRAW() external view returns (bytes32);

    function LIMIT_7540_DEPOSIT() external view returns (bytes32);

    function LIMIT_7540_REDEEM() external view returns (bytes32);

    function LIMIT_LAYERZERO_TRANSFER() external view returns (bytes32);

    function LIMIT_MAPLE_REDEEM() external view returns (bytes32);

    function LIMIT_SUSDE_COOLDOWN() external view returns (bytes32);

    function LIMIT_USDC_TO_CCTP() external view returns (bytes32);

    function LIMIT_USDC_TO_DOMAIN() external view returns (bytes32);

    function LIMIT_USDS_MINT() external view returns (bytes32);

    function LIMIT_USDS_TO_USDC() external view returns (bytes32);

    function proxy() external view returns (address);
    function cctp() external view returns (address);
    function daiUsds() external view returns (address);
    function psm() external view returns (address);
    function rateLimits() external view returns (address);
    function vault() external view returns (address);

    function dai() external view returns (address);
    function usds() external view returns (address);
    function usde() external view returns (address);
    function usdc() external view returns (address);
    function susde() external view returns (address);
}

