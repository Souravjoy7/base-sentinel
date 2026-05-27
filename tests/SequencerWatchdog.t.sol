// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {SequencerWatchdog} from "../src/SequencerWatchdog.sol";

contract SequencerWatchdogTest is Test {
    SequencerWatchdog public watchdog;
    address public owner = address(1);
    address public user = address(2);

    function setUp() public {
        watchdog = new SequencerWatchdog();
        vm.prank(owner);
        watchdog.updateLastBlock();
    }

    function test_initialState() public {
        assertTrue(watchdog.isSequencerHealthy());
        assertEquals(watchdog.getTimeSinceLastBlock(), 0);
    }

    function test_normalOperation() public {
        // Simulate normal sequencer activity
        vm.warp(block.timestamp + 60); // 1 minute later
        assertTrue(watchdog.checkSequencer());
        assertTrue(watchdog.isSequencerHealthy());
    }

    function test_warningThreshold() public {
        // Warp past warning threshold but not critical
        vm.warp(block.timestamp + 301); // 5 minutes + 1 second
        assertFalse(watchdog.checkSequencer());
        assertFalse(watchdog.isSequencerHealthy());
        
        // Check event emission
        vm.expectEmit(true, false, false, true);
        emit SequencerWatchdog.SequencerWarning(block.timestamp, 301);
        watchdog.checkSequencer();
    }

    function test_criticalThreshold() public {
        // Warp past critical threshold
        vm.warp(block.timestamp + 601); // 10 minutes + 1 second
        assertFalse(watchdog.checkSequencer());
        assertTrue(watchdog.emergencyFreeze());
        
        // Check emergency freeze event
        vm.expectEmit(true, false, false, true);
        emit SequencerWatchdog.EmergencyFreezeTriggered(block.timestamp, "Sequencer critical threshold exceeded");
        watchdog.checkSequencer();
    }

    function test_recoveryAfterWarning() public {
        // Trigger warning
        vm.warp(block.timestamp + 301);
        watchdog.checkSequencer();
        
        // Recovery (receive function simulates sequencer activity)
        payable(address(watchdog)).transfer(0);
        assertTrue(watchdog.isSequencerHealthy());
        
        // Check recovery event
        vm.expectEmit(true, false, false, true);
        emit SequencerWatchdog.SequencerRecovered(block.timestamp);
        watchdog.checkSequencer();
    }

    function test_ownerFunctions() public {
        // Test threshold update
        vm.prank(owner);
        watchdog.setThresholds(600, 1200);
        assertEquals(watchdog.WARNING_THRESHOLD(), 600);
        assertEquals(watchdog.CRITICAL_THRESHOLD(), 1200);
        
        // Test unfreeze
        vm.warp(block.timestamp + 601);
        watchdog.checkSequencer(); // Should trigger emergency freeze
        assertTrue(watchdog.emergencyFreeze());
        
        vm.prank(owner);
        watchdog.unfreeze();
        assertFalse(watchdog.emergencyFreeze());
    }

    function test_onlyOwnerFunctions() public {
        vm.expectRevert("Only owner");
        vm.prank(user);
        watchdog.setThresholds(600, 1200);
        
        vm.expectRevert("Only owner");
        vm.prank(user);
        watchdog.unfreeze();
    }

    function test_fallbackUpdatesTime() public {
        vm.warp(block.timestamp + 100);
        uint256 timeBefore = watchdog.getTimeSinceLastBlock();
        
        // Send ether to trigger fallback
        payable(address(watchdog)).transfer(1);
        
        uint256 timeAfter = watchdog.getTimeSinceLastBlock();
        assertLess(timeAfter, timeBefore);
    }
}
