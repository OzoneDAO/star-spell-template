// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.25;

import { IAccessControl } from 'lib/openzeppelin-contracts/contracts/access/IAccessControl.sol';

/**
 * @title  IExecutorLike
 * @author Ozone
 * @notice Defines the interface for the Executor
 */
interface IExecutorLike is IAccessControl {

    /******************************************************************************************************************/
    /*** Enums                                                                                                      ***/
    /******************************************************************************************************************/

    /**
     * @notice This enum contains all possible actions set states
     */
    enum ActionsSetState {
        Queued,
        Executed,
        Canceled,
        Expired
    }

    /******************************************************************************************************************/
    /*** Events                                                                                                     ***/
    /******************************************************************************************************************/

    /**
     * @notice This struct contains the data needed to execute a specified set of actions.
     * @param  targets           Array of targets to call.
     * @param  values            Array of values to pass in each call.
     * @param  signatures        Array of function signatures to encode in each call by the actions which can be empty strings.
     * @param  calldatas         Array of calldatas to pass in each call, appended to the signature at the same array index if not empty.
     * @param  withDelegateCalls Array of whether to delegatecall for each call.
     * @param  executionTime     Timestamp starting from which the actions set can be executed.
     * @param  executed          True if the actions set has been executed, false otherwise.
     * @param  canceled          True if the actions set has been canceled, false otherwise.
     */
    struct ActionsSet {
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        bool[] withDelegatecalls;
        uint256 executionTime;
        bool executed;
        bool canceled;
    }

    /******************************************************************************************************************/
    /*** State variables                                                                                            ***/
    /******************************************************************************************************************/

    /**
     * @notice The role that allows submission of a queued action.
     **/
    function SUBMISSION_ROLE() external view returns (bytes32);

    /**
     * @notice The role that allows a guardian to cancel a pending action.
     **/
    function GUARDIAN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the minimum grace period that can be set, 10 minutes.
     */
    function MINIMUM_GRACE_PERIOD() external view returns (uint256);

     /**
     * @notice Returns the total number of actions sets of the executor.
     * @return The number of actions sets.
     **/
    function actionsSetCount() external view returns (uint256);

    /**
     * @notice Returns the delay (between queuing and execution)
     * @return The value of the delay (in seconds)
     **/
    function delay() external view returns (uint256);

    /**
     * @notice Time after the execution time during which the actions set can be executed.
     * @return The value of the grace period (in seconds)
     **/
    function gracePeriod() external view returns (uint256);

    /******************************************************************************************************************/
    /*** ActionSet functions                                                                                        ***/
    /******************************************************************************************************************/

    /**
     * @notice Queue an ActionsSet.
     * @dev    If a signature is empty, calldata is used for the execution, calldata is appended to signature otherwise.
     * @param  targets           Array of targets to be called by the actions set.
     * @param  values            Array of values to pass in each call by the actions set.
     * @param  signatures        Array of function signatures to encode in each call by the actions which can be empty strings.
     * @param  calldatas         Array of calldata to pass in each call by the actions set.
     * @param  withDelegatecalls Array of whether to delegatecall for each call of the actions set.
     **/
    function queue(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        bool[] memory withDelegatecalls
    ) external;

    /**
     * @notice Execute the ActionsSet
     * @param  actionsSetId The id of the ActionsSet to execute
     **/
    function execute(uint256 actionsSetId) external payable;

    /**
     * @notice Cancel the ActionsSet.
     * @param  actionsSetId The id of the ActionsSet to cancel.
     **/
    function cancel(uint256 actionsSetId) external;

    /******************************************************************************************************************/
    /*** Misc functions                                                                                             ***/
    /******************************************************************************************************************/

    /**
     * @notice Allows to delegatecall a given target with an specific amount of value.
     * @dev    This function is external so it allows to specify a defined msg.value for the delegate call, reducing
     *         the risk that a delegatecall gets executed with more value than intended.
     * @return The bytes returned by the delegate call.
     **/
    function executeDelegateCall(address target, bytes calldata data)
        external
        payable
        returns (bytes memory);

    /******************************************************************************************************************/
    /*** View functions                                                                                             ***/
    /******************************************************************************************************************/

    /**
     * @notice Returns the data of an actions set.
     * @param  actionsSetId The id of the ActionsSet.
     * @return The data of the ActionsSet.
     **/
     function getActionsSetById(uint256 actionsSetId) external view returns (ActionsSet memory);

     /**
      * @notice Returns the current state of an actions set.
      * @param  actionsSetId The id of the ActionsSet.
      * @return The current state of theI ActionsSet.
      **/
     function getCurrentState(uint256 actionsSetId) external view returns (ActionsSetState);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
}

