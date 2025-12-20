// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

import { IMainnetControllerLike } from "../interfaces/IMainnetControllerLike.sol";

import { IALMProxyLike }   from "../interfaces/IALMProxyLike.sol";
import { IRateLimitsLike } from "../interfaces/IRateLimitsLike.sol";

interface IBufferLike {
    function approve(address, address, uint256) external;
}

interface IPSMLike {
    function kiss(address) external;
}

interface IVaultLike {
    function buffer() external view returns (address);
    function rely(address) external;
}

library MainnetControllerInit {

    /**********************************************************************************************/
    /*** Structs and constants                                                                  ***/
    /**********************************************************************************************/

    struct ControllerInstance {
        address almProxy;
        address controller;
        address rateLimits;
    }

    struct CheckAddressParams {
        address admin;
        address proxy;
        address rateLimits;
        address vault;
        address psm;
        address daiUsds;
        address cctp;
    }

    struct ConfigAddressParams {
        address   freezer;
        address[] relayers;
        address   oldController;
    }

    struct MintRecipient {
        uint32  domain;
        bytes32 mintRecipient;
    }

    struct LayerZeroRecipient {
        uint32  destinationEndpointId;
        bytes32 recipient;
    }

    struct CentrifugeRecipient {
        uint16  destinationCentrifugeId;
        bytes32 recipient;
    }

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

    /**********************************************************************************************/
    /*** Internal library functions                                                             ***/
    /**********************************************************************************************/

    function initAlmSystem(
        address vault,
        address usds,
        ControllerInstance    memory controllerInst,
        ConfigAddressParams   memory configAddresses,
        CheckAddressParams    memory checkAddresses,
        MintRecipient[]       memory mintRecipients,
        LayerZeroRecipient[]  memory layerZeroRecipients,
        CentrifugeRecipient[] memory centrifugeRecipients
    )
        internal
    {
        // Step 1: Do sanity checks outside of the controller

        require(IALMProxyLike(controllerInst.almProxy).hasRole(DEFAULT_ADMIN_ROLE, checkAddresses.admin),     "MainnetControllerInit/incorrect-admin-almProxy");
        require(IRateLimitsLike(controllerInst.rateLimits).hasRole(DEFAULT_ADMIN_ROLE, checkAddresses.admin), "MainnetControllerInit/incorrect-admin-rateLimits");

        // Step 2: Initialize the controller

        _initController(controllerInst, configAddresses, checkAddresses, mintRecipients, layerZeroRecipients, centrifugeRecipients);

        // Step 3: Configure almProxy within the allocation system

        require(vault == checkAddresses.vault, "MainnetControllerInit/incorrect-vault");

        IVaultLike(vault).rely(controllerInst.almProxy);
        IBufferLike(IVaultLike(vault).buffer()).approve(usds, controllerInst.almProxy, type(uint256).max);
    }

    function upgradeController(
        ControllerInstance    memory controllerInst,
        ConfigAddressParams   memory configAddresses,
        CheckAddressParams    memory checkAddresses,
        MintRecipient[]       memory mintRecipients,
        LayerZeroRecipient[]  memory layerZeroRecipients,
        CentrifugeRecipient[] memory centrifugeRecipients
    )
        internal
    {
        _initController(controllerInst, configAddresses, checkAddresses, mintRecipients, layerZeroRecipients, centrifugeRecipients);

        IALMProxyLike   almProxy   = IALMProxyLike(controllerInst.almProxy);
        IRateLimitsLike rateLimits = IRateLimitsLike(controllerInst.rateLimits);

        require(configAddresses.oldController != address(0), "MainnetControllerInit/old-controller-zero-address");

        require(almProxy.hasRole(almProxy.CONTROLLER(), configAddresses.oldController),     "MainnetControllerInit/old-controller-not-almProxy-controller");
        require(rateLimits.hasRole(rateLimits.CONTROLLER(), configAddresses.oldController), "MainnetControllerInit/old-controller-not-rateLimits-controller");

        almProxy.revokeRole(almProxy.CONTROLLER(), configAddresses.oldController);
        rateLimits.revokeRole(rateLimits.CONTROLLER(), configAddresses.oldController);
    }

    function pauseProxyInitAlmSystem(address psm, address almProxy) internal {
        IPSMLike(psm).kiss(almProxy);  // To allow using no fee functionality
    }

    /**********************************************************************************************/
    /*** Private helper functions                                                               ***/
    /**********************************************************************************************/

    function _initController(
        ControllerInstance    memory controllerInst,
        ConfigAddressParams   memory configAddresses,
        CheckAddressParams    memory checkAddresses,
        MintRecipient[]       memory mintRecipients,
        LayerZeroRecipient[]  memory layerZeroRecipients,
        CentrifugeRecipient[] memory centrifugeRecipients
    )
        private
    {
        // Step 1: Perform controller sanity checks

        IMainnetControllerLike newController = IMainnetControllerLike(controllerInst.controller);

        require(newController.hasRole(DEFAULT_ADMIN_ROLE, checkAddresses.admin), "MainnetControllerInit/incorrect-admin-controller");

        require(address(newController.proxy())      == controllerInst.almProxy,   "MainnetControllerInit/incorrect-almProxy");
        require(address(newController.rateLimits()) == controllerInst.rateLimits, "MainnetControllerInit/incorrect-rateLimits");

        require(address(newController.vault())   == checkAddresses.vault,   "MainnetControllerInit/incorrect-vault");
        require(address(newController.psm())     == checkAddresses.psm,     "MainnetControllerInit/incorrect-psm");
        require(address(newController.daiUsds()) == checkAddresses.daiUsds, "MainnetControllerInit/incorrect-daiUsds");
        require(address(newController.cctp())    == checkAddresses.cctp,    "MainnetControllerInit/incorrect-cctp");

        require(newController.psmTo18ConversionFactor() == 1e12, "MainnetControllerInit/incorrect-psmTo18ConversionFactor");

        require(configAddresses.oldController != address(newController), "MainnetControllerInit/old-controller-is-new-controller");

        // Step 2: Configure ACL permissions controller, almProxy, and rateLimits

        IALMProxyLike   almProxy   = IALMProxyLike(controllerInst.almProxy);
        IRateLimitsLike rateLimits = IRateLimitsLike(controllerInst.rateLimits);

        almProxy.grantRole(almProxy.CONTROLLER(),        address(newController));
        newController.grantRole(newController.FREEZER(), configAddresses.freezer);
        rateLimits.grantRole(rateLimits.CONTROLLER(),    address(newController));

        for (uint256 i; i < configAddresses.relayers.length; ++i) {
            newController.grantRole(newController.RELAYER(), configAddresses.relayers[i]);
        }

        // Step 3: Configure the mint recipients on other domains

        for (uint256 i; i < mintRecipients.length; ++i) {
            newController.setMintRecipient(mintRecipients[i].domain, mintRecipients[i].mintRecipient);
        }

        // Step 4: Configure LayerZero recipients

        for (uint256 i; i < layerZeroRecipients.length; ++i) {
            newController.setLayerZeroRecipient(layerZeroRecipients[i].destinationEndpointId, layerZeroRecipients[i].recipient);
        }

        // Step 5: Configure the centrifuge recipients

        for (uint256 i; i < centrifugeRecipients.length; ++i) {
            newController.setCentrifugeRecipient(centrifugeRecipients[i].destinationCentrifugeId, centrifugeRecipients[i].recipient);
        }
    }

}