// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {BridgeValidator} from "../src/BridgeValidator.sol";

contract BridgeValidatorTest is Test {
    BridgeValidator public validator;
    address public owner = address(1);
    address public user = address(2);
    
    uint256 public constant LARGE_TRANSFER_THRESHOLD = 1000 * 1e18;
    uint256 public constant RUSH_THRESHOLD = 10;

    function setUp() public {
        validator = new BridgeValidator();
    }

    function test_initialState() public {
        assertFalse(validator.emergencyPause());
        assertEquals(validator.LARGE_TRANSFER_THRESHOLD(), LARGE_TRANSFER_THRESHOLD);
        assertEquals(validator.RUSH_THRESHOLD(), RUSH_THRESHOLD);
    }

    function test_normalTransfer() public {
        bytes32 transferHash = keccak256(abi.encodePacked("NORMAL_TRANSFER"));
        assertTrue(validator.validateTransfer(user, 100 * 1e18, transferHash));
        assertEquals(validator.getUserTransferCount(user), 1);
    }

    function test_largeTransferAllowed() public {
        // Large transfer should be allowed if not in rush mode
        bytes32 transferHash = keccak256(abi.encodePacked("LARGE_TRANSFER"));
        assertTrue(validator.validateTransfer(user, LARGE_TRANSFER_THRESHOLD + 1, transferHash));
        assertEquals(validator.getUserTransferCount(user), 1);
    }

    function test_largeTransferBlockedDuringRush() public {
        // First, put user in rush mode
        for (uint256 i = 0; i < RUSH_THRESHOLD; i++) {
            bytes32 hash = keccak256(abi.encodePacked("TRANSFER", i));
            validator.validateTransfer(user, 100 * 1e18, hash);
        }
        
        // Now try large transfer - should be blocked
        bytes32 largeHash = keccak256(abi.encodePacked("LARGE_TRANSFER"));
        assertFalse(validator.validateTransfer(user, LARGE_TRANSFER_THRESHOLD + 1, largeHash));
        
        // Check event
        vm.expectEmit(true, false, false, true);
        emit BridgeValidator.LargeTransferBlocked(user, LARGE_TRANSFER_THRESHOLD + 1, block.timestamp);
        validator.validateTransfer(user, LARGE_TRANSFER_THRESHOLD + 1, largeHash);
    }

    function test_suspiciousTransferEvent() public {
        // Put user in rush mode
        for (uint256 i = 0; i < RUSH_THRESHOLD; i++) {
            bytes32 hash = keccak256(abi.encodePacked("TRANSFER", i));
            validator.validateTransfer(user, 100 * 1e18, hash);
        }
        
        // Next transfer should trigger suspicious event
        bytes32 hash = keccak256(abi.encodePacked("SUSPICIOUS_TRANSFER"));
        vm.expectEmit(true, false, false, true);
        emit BridgeValidator.SuspiciousTransfer(user, 100 * 1e18, block.timestamp);
        validator.validateTransfer(user, 100 * 1e18, hash);
    }

    function test_knownAttackPatternBlocked() public {
        // Add known attack pattern
        bytes32 attackPattern = keccak256(abi.encodePacked("REENTRANCY_CALL"));
        vm.prank(owner);
        validator.addAttackPattern(attackPattern);
        
        // Try to use attack pattern - should be blocked
        bytes32 transferHash = keccak256(abi.encodePacked("REENTRANCY_CALL"));
        assertFalse(validator.validateTransfer(user, 100 * 1e18, transferHash));
        
        // Check pattern detected event
        vm.expectEmit(true, false, false, true);
        emit BridgeValidator.PatternDetected(attackPattern, block.timestamp);
        validator.validateTransfer(user, 100 * 1e18, transferHash);
    }

    function test_emergencyPause() public {
        // Activate emergency pause
        vm.prank(owner);
        validator.emergencyPauseTransfer("Test emergency");
        
        // All transfers should be blocked
        bytes32 hash = keccak256(abi.encodePacked("TRANSFER"));
        assertFalse(validator.validateTransfer(user, 100 * 1e18, hash));
        
        // Check pause event
        vm.expectEmit(true, false, false, true);
        emit BridgeValidator.EmergencyPause("Test emergency");
        validator.emergencyPauseTransfer("Test emergency");
    }

    function test_emergencyResume() public {
        // First pause
        vm.prank(owner);
        validator.emergencyPauseTransfer("Test");
        
        // Then resume
        vm.prank(owner);
        validator.emergencyResume();
        
        // Now transfers should work
        bytes32 hash = keccak256(abi.encodePacked("TRANSFER"));
        assertTrue(validator.validateTransfer(user, 100 * 1e18, hash));
    }

    function test_ownerFunctions() public {
        // Test threshold updates
        vm.prank(owner);
        validator.setLargeTransferThreshold(2000 * 1e18);
        assertEquals(validator.LARGE_TRANSFER_THRESHOLD(), 2000 * 1e18);
        
        vm.prank(owner);
        validator.setRushThreshold(5);
        assertEquals(validator.RUSH_THRESHOLD(), 5);
        
        // Test pattern management
        bytes32 pattern = keccak256(abi.encodePacked("TEST_PATTERN"));
        vm.prank(owner);
        validator.addAttackPattern(pattern);
        assertTrue(validator.knownAttackPatterns(pattern));
        
        vm.prank(owner);
        validator.removeAttackPattern(pattern);
        assertFalse(validator.knownAttackPatterns(pattern));
    }

    function test_onlyOwnerFunctions() public {
        vm.expectRevert("Only owner");
        vm.prank(user);
        validator.setLargeTransferThreshold(2000 * 1e18);
        
        vm.expectRevert("Only owner");
        vm.prank(user);
        validator.emergencyPauseTransfer("Test");
        
        vm.expectRevert("Only owner");
        vm.prank(user);
        validator.addAttackPattern(keccak256("TEST"));
    }

    function test_userCounterReset() public {
        // Make some transfers
        for (uint256 i = 0; i < 5; i++) {
            bytes32 hash = keccak256(abi.encodePacked("TRANSFER", i));
            validator.validateTransfer(user, 100 * 1e18, hash);
        }
        
        assertEquals(validator.getUserTransferCount(user), 5);
        
        // Reset counter
        vm.prank(owner);
        validator.resetUserCounter(user);
        
        assertEquals(validator.getUserTransferCount(user), 0);
    }

    function test_rushModeDetection() public {
        // Initially not in rush mode
        assertFalse(validator.isInRushMode(user));
        
        // Put in rush mode
        for (uint256 i = 0; i < RUSH_THRESHOLD; i++) {
            bytes32 hash = keccak256(abi.encodePacked("TRANSFER", i));
            validator.validateTransfer(user, 100 * 1e18, hash);
        }
        
        assertTrue(validator.isInRushMode(user));
        
        // Wait for time window to expire
        vm.warp(block.timestamp + 301);
        assertFalse(validator.isInRushMode(user));
    }
}
