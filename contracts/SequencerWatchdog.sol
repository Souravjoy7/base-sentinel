// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SequencerWatchdog
 * @notice Monitors Base sequencer liveness and provides early warnings
 * @author Base Sentinel
 * @dev This contract is a proof-of-concept for detecting sequencer downtime
 */
contract SequencerWatchdog {
    // Events
    event SequencerWarning(uint256 timestamp, uint256 blocksSinceLast);
    event SequencerRecovered(uint256 timestamp);
    event EmergencyFreezeTriggered(uint256 timestamp, string reason);

    // State variables
    uint256 public lastSequencerBlock;
    uint256 public  WARNING_THRESHOLD = 300; // 5 minutes in blocks
    uint256 public  CRITICAL_THRESHOLD = 600; // 10 minutes in blocks
    bool public emergencyFreeze;
    address public owner;

    // Constructor
    constructor() {
        owner = msg.sender;
        lastSequencerBlock = block.timestamp;
    }

    // External functions
    function checkSequencer() external returns (bool isHealthy) {
        uint256 timeSinceLast = block.timestamp - lastSequencerBlock;
        
        if (timeSinceLast > CRITICAL_THRESHOLD) {
            if (!emergencyFreeze) {
                emergencyFreeze = true;
                emit EmergencyFreezeTriggered(block.timestamp, "Sequencer critical threshold exceeded");
            }
            return false;
        }
        
        if (timeSinceLast > WARNING_THRESHOLD) {
            emit SequencerWarning(block.timestamp, timeSinceLast);
            return false;
        }
        
        emit SequencerRecovered(block.timestamp);
        return true;
    }

    // Fallback function to update sequencer block time
    receive() external payable {
        // Only update if not in emergency freeze
        if (!emergencyFreeze) {
            lastSequencerBlock = block.timestamp;
        }
    }

    // Owner functions
    function updateLastBlock() external {
        require(msg.sender == owner, "Only owner");
        lastSequencerBlock = block.timestamp;
        emergencyFreeze = false;
    }

    function setThresholds(uint256 warning, uint256 critical) external {
        require(msg.sender == owner, "Only owner");
        require(warning < critical, "Warning must be less than critical");
        WARNING_THRESHOLD = warning;
        CRITICAL_THRESHOLD = critical;
    }

    function unfreeze() external {
        require(msg.sender == owner, "Only owner");
        emergencyFreeze = false;
        lastSequencerBlock = block.timestamp;
    }

    // View functions
    function getTimeSinceLastBlock() external view returns (uint256) {
        return block.timestamp - lastSequencerBlock;
    }

    function isSequencerHealthy() external view returns (bool) {
        return (block.timestamp - lastSequencerBlock) <= WARNING_THRESHOLD;
    }
}
