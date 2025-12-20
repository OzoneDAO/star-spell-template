// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

import { LiquidityLayerTestBase } from "../../test-harness/LiquidityLayerTestBase.sol";

import { Ethereum_20251231 as Spell } from "./Ethereum_20251231.sol";

import { ChainIdUtils } from "../../libraries/ChainId.sol";

contract Ethereum_202512313Test is LiquidityLayerTestBase {

    Spell internal SPELL;
    address internal DEPLOYER;

    constructor() {
        id = "20251231";
    }

    function _setupAddresses() internal virtual {
        SPELL = Spell(chainData[ChainIdUtils.Ethereum()].payload);
    }

    function setUp() public {
        setupMainnetDomain({ mainnetForkBlock: 24055133  });
        _setupAddresses();
    }

    function test_ETHEREUM_PayloadBytecodeMatches() public {
        _assertPayloadBytecodeMatches(ChainIdUtils.Ethereum());
    }
}