// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DAOGovernance
 * @dev Decentralized Autonomous Organization governance for ScrollVerse
 * Implements the DAO strategy as the opening move for deployment
 */
contract DAOGovernance {
    // Governance State
    address public scrollSoulDSP;
    mapping(address => bool) public councilMembers;
    mapping(bytes32 => Proposal) public proposals;
    
    uint256 public proposalCount;
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant EXECUTION_DELAY = 2 days;
    
    struct Proposal {
        bytes32 id;
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    
    // Events
    event ProposalCreated(bytes32 indexed proposalId, address indexed proposer, string description);
    event VoteCast(bytes32 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(bytes32 indexed proposalId);
    event CouncilMemberAdded(address indexed member);
    event DAODeployed(uint256 timestamp);
    
    modifier onlyCouncil() {
        require(councilMembers[msg.sender], "DAOGovernance: Only council");
        _;
    }
    
    constructor() {
        councilMembers[msg.sender] = true;
        emit CouncilMemberAdded(msg.sender);
        emit DAODeployed(block.timestamp);
    }
    
    /**
     * @dev Set the ScrollSoul DSP address (deployment opening move)
     */
    function setScrollSoulDSP(address _scrollSoulDSP) external onlyCouncil {
        require(scrollSoulDSP == address(0), "DAOGovernance: DSP already set");
        scrollSoulDSP = _scrollSoulDSP;
    }
    
    /**
     * @dev Add a council member
     */
    function addCouncilMember(address member) external onlyCouncil {
        require(!councilMembers[member], "DAOGovernance: Already member");
        councilMembers[member] = true;
        emit CouncilMemberAdded(member);
    }
    
    /**
     * @dev Create a new proposal
     */
    function createProposal(string calldata description) external onlyCouncil returns (bytes32) {
        bytes32 proposalId = keccak256(abi.encodePacked(proposalCount, block.timestamp, msg.sender));
        proposalCount++;
        
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + VOTING_PERIOD;
        
        emit ProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }
    
    /**
     * @dev Cast a vote on a proposal
     */
    function castVote(bytes32 proposalId, bool support) external onlyCouncil {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.startTime, "DAOGovernance: Voting not started");
        require(block.timestamp <= proposal.endTime, "DAOGovernance: Voting ended");
        require(!proposal.hasVoted[msg.sender], "DAOGovernance: Already voted");
        
        proposal.hasVoted[msg.sender] = true;
        
        if (support) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }
        
        emit VoteCast(proposalId, msg.sender, support, 1);
    }
    
    /**
     * @dev Execute a passed proposal
     */
    function executeProposal(bytes32 proposalId) external onlyCouncil {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime + EXECUTION_DELAY, "DAOGovernance: Execution delay");
        require(!proposal.executed, "DAOGovernance: Already executed");
        require(proposal.forVotes > proposal.againstVotes, "DAOGovernance: Proposal rejected");
        
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }
    
    /**
     * @dev Get proposal status
     */
    function getProposalStatus(bytes32 proposalId) external view returns (
        address proposer,
        uint256 forVotes,
        uint256 againstVotes,
        bool executed,
        bool canExecute
    ) {
        Proposal storage proposal = proposals[proposalId];
        proposer = proposal.proposer;
        forVotes = proposal.forVotes;
        againstVotes = proposal.againstVotes;
        executed = proposal.executed;
        canExecute = !executed && 
                     block.timestamp > proposal.endTime + EXECUTION_DELAY &&
                     forVotes > againstVotes;
    }
}
