// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BridgeValidator
 * @notice Detects suspicious bridge activity and prevents exploits
 * @author Base Sentinel
 * @dev Proof-of-concept for cross-chain exploit detection
 */
contract BridgeValidator {
    // Events
    event SuspiciousTransfer(address indexed user, uint256 amount, uint256 timestamp);
    event LargeTransferBlocked(address indexed user, uint256 amount, uint256 timestamp);
    event PatternDetected(bytes32 patternHash, uint256 timestamp);
    event EmergencyPause(string reason);

    // State variables
    mapping(address => uint256) public userTransferCount;
    mapping(address => uint256) public lastTransferTime;
    mapping(bytes32 => bool) public knownAttackPatterns;
    
    uint256 public constant LARGE_TRANSFER_THRESHOLD = 1000 * 1e18; // 1000 tokens
    uint256 public constant RUSH_THRESHOLD = 10; // 10 transfers in 5 minutes
    uint256 public constant TIME_WINDOW = 300; // 5 minutes
    
    bool public emergencyPause;
    address public owner;
    
    // Constructor
    constructor() {
        owner = msg.sender;
        // Initialize known attack patterns
        _initializeAttackPatterns();
    }
    
    // Main validation function
    function validateTransfer(address user, uint256 amount, bytes32 transferHash) external returns (bool isValid) {
        require(!emergencyPause, "Emergency pause active");
        
        uint256 currentTime = block.timestamp;
        uint256 userCount = userTransferCount[user];
        
        // Check for large transfers
        if (amount > LARGE_TRANSFER_THRESHOLD) {
            if (userCount > 0 && (currentTime - lastTransferTime[user]) < TIME_WINDOW) {
                emit LargeTransferBlocked(user, amount, currentTime);
                return false;
            }
        }
        
        // Check for transfer rush
        if (userCount >= RUSH_THRESHOLD) {
            emit SuspiciousTransfer(user, amount, currentTime);
            return false;
        }
        
        // Check for known attack patterns
        if (knownAttackPatterns[transferHash]) {
            emit PatternDetected(transferHash, currentTime);
            return false;
        }
        
        // Update user state
        userTransferCount[user]++;
        lastTransferTime[user] = currentTime;
        
        return true;
    }
    
    // Owner functions
    function addAttackPattern(bytes32 patternHash) external {
        require(msg.sender == owner, "Only owner");
        knownAttackPatterns[patternHash] = true;
    }
    
    function removeAttackPattern(bytes32 patternHash) external {
        require(msg.sender == owner, "Only owner");
        knownAttackPatterns[patternHash] = false;
    }
    
    function setLargeTransferThreshold(uint256 threshold) external {
        require(msg.sender == owner, "Only owner");
        LARGE_TRANSFER_THRESHOLD = threshold;
    }
    
    function setRushThreshold(uint256 threshold) external {
        require(msg.sender == owner, "Only owner");
        RUSH_THRESHOLD = threshold;
    }
    
    function emergencyPauseTransfer(string memory reason) external {
        require(msg.sender == owner, "Only owner");
        emergencyPause = true;
        emit EmergencyPause(reason);
    }
    
    function emergencyResume() external {
        require(msg.sender == owner, "Only owner");
        emergencyPause = false;
    }
    
    // Reset user counters
    function resetUserCounter(address user) external {
        require(msg.sender == owner, "Only owner");
        userTransferCount[user] = 0;
        lastTransferTime[user] = 0;
    }
    
    // View functions
    function getUserTransferCount(address user) external view returns (uint256) {
        return userTransferCount[user];
    }
    
    function isInRushMode(address user) external view returns (bool) {
        return (userTransferCount[user] >= RUSH_THRESHOLD && 
                (block.timestamp - lastTransferTime[user]) < TIME_WINDOW);
    }
    
    // Internal functions
    function _initializeAttackPatterns() internal {
        // Example: Known re-entrancy pattern hash
        bytes32 reentrancyPattern = keccak256(abi.encodePacked("REENTRANCY_CALL"));
        knownAttackPatterns[reentrancyPattern] = true;
        
        // Example: Batch transfer overflow pattern
        bytes32 overflowPattern = keccak256(abi.encodePacked("BATCH_OVERFLOW"));
        knownAttackPatterns[overflowPattern] = true;
    }
}
