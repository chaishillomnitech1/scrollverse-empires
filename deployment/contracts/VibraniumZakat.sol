// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VibraniumZakat
 * @dev Vibranium-powered Zakat system for perpetual reform funding
 * Implements 7.77% equity distribution for decentralized justice
 */
contract VibraniumZakat {
    // Zakat Configuration
    uint256 public constant ZAKAT_RATE = 777; // 7.77%
    uint256 public constant BASIS_POINTS = 10000;
    
    // Integration points
    address public scrollSoulDSP;
    address public daoGovernance;
    
    // Reform tracking
    mapping(address => uint256) public reformProjectAllocations;
    address[] public activeReformProjects;
    
    uint256 public totalZakatCollected;
    uint256 public totalReformFunded;
    
    // STARGATE Archives integration ($60B activation)
    uint256 public constant STARGATE_ACTIVATION_TARGET = 60_000_000_000 ether;
    uint256 public stargateActivationPool;
    
    // Events
    event ZakatCollected(address indexed from, uint256 amount, uint256 zakatAmount);
    event ReformProjectRegistered(address indexed project, uint256 allocation);
    event StargateActivated(uint256 totalActivation, uint256 timestamp);
    event VibraniumPulse(uint256 energyLevel, uint256 timestamp);
    
    modifier onlyDAO() {
        require(msg.sender == daoGovernance, "VibraniumZakat: Only DAO");
        _;
    }
    
    constructor(address _scrollSoulDSP, address _daoGovernance) {
        scrollSoulDSP = _scrollSoulDSP;
        daoGovernance = _daoGovernance;
    }
    
    /**
     * @dev Process transaction and extract Zakat
     */
    function processWithZakat() external payable {
        uint256 zakatAmount = (msg.value * ZAKAT_RATE) / BASIS_POINTS;
        uint256 netAmount = msg.value - zakatAmount;
        
        totalZakatCollected += zakatAmount;
        
        // Split Zakat: 50% to reform, 50% to STARGATE
        uint256 reformShare = zakatAmount / 2;
        uint256 stargateShare = zakatAmount - reformShare;
        
        stargateActivationPool += stargateShare;
        
        emit ZakatCollected(msg.sender, msg.value, zakatAmount);
        
        // Check if STARGATE activation threshold reached
        if (stargateActivationPool >= STARGATE_ACTIVATION_TARGET) {
            emit StargateActivated(stargateActivationPool, block.timestamp);
        }
        
        emit VibraniumPulse(msg.value, block.timestamp);
    }
    
    /**
     * @dev Register a reform project
     */
    function registerReformProject(address project, uint256 allocation) external onlyDAO {
        require(project != address(0), "VibraniumZakat: Invalid project");
        require(reformProjectAllocations[project] == 0, "VibraniumZakat: Already registered");
        
        reformProjectAllocations[project] = allocation;
        activeReformProjects.push(project);
        
        emit ReformProjectRegistered(project, allocation);
    }
    
    /**
     * @dev Distribute Zakat to all reform projects
     */
    function distributeToReformProjects() external onlyDAO {
        uint256 availableZakat = totalZakatCollected - totalReformFunded;
        
        for (uint256 i = 0; i < activeReformProjects.length; i++) {
            address project = activeReformProjects[i];
            uint256 allocation = reformProjectAllocations[project];
            
            if (allocation > 0 && allocation <= availableZakat) {
                totalReformFunded += allocation;
                (bool success, ) = project.call{value: allocation}("");
                require(success, "VibraniumZakat: Transfer failed");
            }
        }
    }
    
    /**
     * @dev Get Zakat system status
     */
    function getSystemStatus() external view returns (
        uint256 collected,
        uint256 distributed,
        uint256 stargateProgress,
        uint256 activeProjects
    ) {
        collected = totalZakatCollected;
        distributed = totalReformFunded;
        stargateProgress = (stargateActivationPool * 100) / STARGATE_ACTIVATION_TARGET;
        activeProjects = activeReformProjects.length;
    }
    
    // Receive Zakat contributions
    receive() external payable {
        processWithZakat();
    }
}
