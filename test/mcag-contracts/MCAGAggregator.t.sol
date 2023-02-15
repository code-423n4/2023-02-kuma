// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {AccessController} from "@mcag/AccessController.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "@mcag/libraries/Errors.sol";
import {MCAGAggregator} from "@mcag/MCAGAggregator.sol";
import {Roles} from "@mcag/libraries/Roles.sol";
import {Test} from "forge-std/Test.sol";

contract MCAGAggregatorTest is Test {
    event AccessControllerSet(address accesController);
    event AnswerTransmitted(address indexed transmitter, uint80 roundId, int256 answer);
    event MaxAnswerSet(int256 oldMaxAnswer, int256 newMaxAnswer);

    int256 private constant _MAX_ANSWER = 100000000831951628484471512; // 30%

    AccessController private _accessController;
    MCAGAggregator private _mcagAggregator;

    uint8 private _decimals = 27;
    string private _description = "10 YEAR US TREASURY";

    address private _alice = vm.addr(1);

    function setUp() external {
        _accessController = new AccessController();
        _mcagAggregator = new MCAGAggregator(_description, _MAX_ANSWER, IAccessControl(address(_accessController)));
        vm.label(address(_accessController), "AccessController");
        vm.label(address(_mcagAggregator), "MCAGAggregator");
        vm.label(_alice, "Alice");
    }

    function test_constructor() public {
        vm.expectEmit(false, false, false, true);
        emit AccessControllerSet(address(_accessController));
        vm.expectEmit(false, false, false, true);
        emit MaxAnswerSet(0, _MAX_ANSWER);

        MCAGAggregator newMCAGAggregator = new MCAGAggregator(_description, _MAX_ANSWER, _accessController);

        assertEq(newMCAGAggregator.version(), 1);
        assertEq(newMCAGAggregator.description(), _description);
        assertEq(newMCAGAggregator.decimals(), _decimals);
        assertEq(address(newMCAGAggregator.accessController()), address(_accessController));
    }

    function test_constructor_RevertWhen_InitializedWithInvalidParameters() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.CANNOT_SET_TO_ADDRESS_ZERO.selector));
        new MCAGAggregator(_description, _MAX_ANSWER, IAccessControl(address(0)));
    }

    function test_transmit() public {
        int256 _answer = 100000000124368065631882031; // 4%
        vm.expectEmit(true, false, false, true);
        emit AnswerTransmitted(address(this), 1, _answer);
        _mcagAggregator.transmit(_answer);
        (uint80 roundId, int256 answer,, uint256 updatedAt, uint80 answeredInRound) = _mcagAggregator.latestRoundData();

        assertEq(roundId, 1);
        assertEq(answer, _answer);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 1);
    }

    function test_transmit_RevertWhen_CallerDoesNotHaveTransmitterRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.MCAG_TRANSMITTER_ROLE
            )
        );
        vm.prank(_alice);
        _mcagAggregator.transmit(100000000124368065631882031);
    }

    function test_transmit_RevertWhen_AnswerGtMaxAnswer() public {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.TRANSMITTED_ANSWER_TOO_HIGH.selector, _MAX_ANSWER + 1, _MAX_ANSWER)
        );
        _mcagAggregator.transmit(_MAX_ANSWER + 1);
    }

    function test_setMaxAnswer() public {
        int256 newMaxAnswer = 100000000578137865680459171; // 20%
        vm.expectEmit(false, false, false, true);
        emit MaxAnswerSet(_MAX_ANSWER, newMaxAnswer);
        _mcagAggregator.setMaxAnswer(newMaxAnswer);

        assertEq(_mcagAggregator.maxAnswer(), newMaxAnswer);
    }

    function test_setMaxAnswer_RevertWhen_CallerDoesNotHaveManagerRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE.selector, _alice, Roles.MCAG_MANAGER_ROLE
            )
        );
        vm.prank(_alice);
        _mcagAggregator.setMaxAnswer(100000000578137865680459171);
    }
}
