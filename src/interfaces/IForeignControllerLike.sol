// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

import { IAccessControl } from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';

interface IForeignControllerLike is IAccessControl {

    /**********************************************************************************************/
    /*** Events                                                                                 ***/
    /**********************************************************************************************/

    event CCTPTransferInitiated(
        uint64  indexed nonce,
        uint32  indexed destinationDomain,
        bytes32 indexed mintRecipient,
        uint256 usdcAmount
    );

    event CentrifugeRecipientSet(uint16 indexed destinationCentrifugeId, bytes32 recipient);

    event LayerZeroRecipientSet(uint32 indexed destinationEndpointId, bytes32 layerZeroRecipient);

    event MintRecipientSet(uint32 indexed destinationDomain, bytes32 mintRecipient);

    event RelayerRemoved(address indexed relayer);

    /**********************************************************************************************/
    /*** Admin functions                                                                        ***/
    /**********************************************************************************************/

    function setMintRecipient(uint32 destinationDomain, bytes32 mintRecipient) external;

    function setLayerZeroRecipient(uint32 destinationEndpointId, bytes32 layerZeroRecipient) external;

    function setCentrifugeRecipient(uint16 destinationCentrifugeId, bytes32 recipient) external;

    /**********************************************************************************************/
    /*** Freezer functions                                                                      ***/
    /**********************************************************************************************/

    function removeRelayer(address relayer) external;

    /**********************************************************************************************/
    /*** Relayer PSM functions                                                                  ***/
    /**********************************************************************************************/

    function depositPSM(address asset, uint256 amount) external returns (uint256 shares);

    function withdrawPSM(address asset, uint256 maxAmount) external returns (uint256 assetsWithdrawn);

    /**********************************************************************************************/
    /*** Relayer bridging functions                                                             ***/
    /**********************************************************************************************/

    function transferUSDCToCCTP(uint256 usdcAmount, uint32 destinationDomain) external;

    function transferTokenLayerZero(
        address oftAddress,
        uint256 amount,
        uint32 destinationEndpointId
    ) external payable;

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
    /*** Relayer Centrifuge functions                                                           ***/
    /**********************************************************************************************/

    function cancelCentrifugeDepositRequest(address token) external;

    function claimCentrifugeCancelDepositRequest(address token) external;

    function cancelCentrifugeRedeemRequest(address token) external;

    function claimCentrifugeCancelRedeemRequest(address token) external;

    function transferSharesCentrifuge(
        address token,
        uint128 amount,
        uint16 destinationCentrifugeId
    ) external payable;

    /**********************************************************************************************/
    /*** Relayer Aave functions                                                                 ***/
    /**********************************************************************************************/

    function depositAave(address aToken, uint256 amount) external;

    function withdrawAave(address aToken, uint256 amount) external returns (uint256 amountWithdrawn);

    /**********************************************************************************************/
    /*** View functions                                                                         ***/
    /**********************************************************************************************/

    function mintRecipients(uint32 destinationDomain) external view returns (bytes32);

    function layerZeroRecipients(uint32 destinationEndpointId) external view returns (bytes32);

    function centrifugeRecipients(uint16 destinationCentrifugeId) external view returns (bytes32);

    /**********************************************************************************************/
    /*** Role constants                                                                         ***/
    /**********************************************************************************************/

    function FREEZER() external view returns (bytes32);

    function RELAYER() external view returns (bytes32);

    function LIMIT_4626_DEPOSIT() external view returns (bytes32);

    function LIMIT_4626_WITHDRAW() external view returns (bytes32);

    function LIMIT_7540_DEPOSIT() external view returns (bytes32);

    function LIMIT_7540_REDEEM() external view returns (bytes32);

    function LIMIT_AAVE_DEPOSIT() external view returns (bytes32);

    function LIMIT_AAVE_WITHDRAW() external view returns (bytes32);

    function LIMIT_CENTRIFUGE_TRANSFER() external view returns (bytes32);

    function LIMIT_LAYERZERO_TRANSFER() external view returns (bytes32);

    function LIMIT_PSM_DEPOSIT() external view returns (bytes32);

    function LIMIT_PSM_WITHDRAW() external view returns (bytes32);

    function LIMIT_USDC_TO_CCTP() external view returns (bytes32);

    function LIMIT_USDC_TO_DOMAIN() external view returns (bytes32);

    function proxy() external view returns (address);
    function cctp() external view returns (address);
    function daiUsds() external view returns (address);
    function ethenaMinter() external view returns (address);
    function psm() external view returns (address);
    function rateLimits() external view returns (address);
    function vault() external view returns (address);

    function dai() external view returns (address);
    function usds() external view returns (address);
    function usde() external view returns (address);
    function usdc() external view returns (address);
    function susde() external view returns (address);

    //function DEFAULT_ADMIN_ROLE() external view returns (address);
    //function FREEZER() external view returns (address);
    //function RELAYER() external view returns (address);
}

