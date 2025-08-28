// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Social Media Content Creation Platform
 * @dev A decentralized smart contract for content creators to monetize their social media content
 * @author Your Name
 */
contract SocialMediaContentCreation {
    
    // State variables
    address public owner;
    uint256 public contentCounter;
    uint256 public constant PLATFORM_FEE_PERCENTAGE = 5; // 5% platform fee
    
    // Structs
    struct Content {
        uint256 id;
        address creator;
        string title;
        string description;
        string contentHash; // IPFS hash for content storage
        uint256 price; // Price in wei
        uint256 totalEarnings;
        uint256 purchaseCount;
        bool isActive;
        uint256 createdAt;
    }
    
    struct Creator {
        address creatorAddress;
        string username;
        uint256 totalContentCreated;
        uint256 totalEarnings;
        bool isVerified;
    }
    
    // Mappings
    mapping(uint256 => Content) public contents;
    mapping(address => Creator) public creators;
    mapping(address => mapping(uint256 => bool)) public hasPurchased;
    mapping(address => uint256[]) public creatorContents;
    
    // Events
    event ContentCreated(
        uint256 indexed contentId,
        address indexed creator,
        string title,
        uint256 price
    );
    
    event ContentPurchased(
        uint256 indexed contentId,
        address indexed buyer,
        address indexed creator,
        uint256 amount
    );
    
    event CreatorRegistered(
        address indexed creator,
        string username
    );
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyRegisteredCreator() {
        require(bytes(creators[msg.sender].username).length > 0, "Creator not registered");
        _;
    }
    
    modifier contentExists(uint256 _contentId) {
        require(_contentId > 0 && _contentId <= contentCounter, "Content does not exist");
        _;
    }
    
    // Constructor
    constructor() {
        owner = msg.sender;
        contentCounter = 0;
    }
    
    /**
     * @dev Register as a content creator on the platform
     * @param _username Unique username for the creator
     */
    function registerCreator(string memory _username) external {
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(bytes(creators[msg.sender].username).length == 0, "Creator already registered");
        
        creators[msg.sender] = Creator({
            creatorAddress: msg.sender,
            username: _username,
            totalContentCreated: 0,
            totalEarnings: 0,
            isVerified: false
        });
        
        emit CreatorRegistered(msg.sender, _username);
    }
    
    /**
     * @dev Create and publish new content on the platform
     * @param _title Title of the content
     * @param _description Description of the content
     * @param _contentHash IPFS hash where the content is stored
     * @param _price Price for accessing the content (in wei)
     */
    function createContent(
        string memory _title,
        string memory _description,
        string memory _contentHash,
        uint256 _price
    ) external onlyRegisteredCreator {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_contentHash).length > 0, "Content hash cannot be empty");
        require(_price > 0, "Price must be greater than 0");
        
        contentCounter++;
        
        contents[contentCounter] = Content({
            id: contentCounter,
            creator: msg.sender,
            title: _title,
            description: _description,
            contentHash: _contentHash,
            price: _price,
            totalEarnings: 0,
            purchaseCount: 0,
            isActive: true,
            createdAt: block.timestamp
        });
        
        creatorContents[msg.sender].push(contentCounter);
        creators[msg.sender].totalContentCreated++;
        
        emit ContentCreated(contentCounter, msg.sender, _title, _price);
    }
    
    /**
     * @dev Purchase access to premium content
     * @param _contentId ID of the content to purchase
     */
    function purchaseContent(uint256 _contentId) 
        external 
        payable 
        contentExists(_contentId) 
    {
        Content storage content = contents[_contentId];
        require(content.isActive, "Content is not active");
        require(msg.value == content.price, "Incorrect payment amount");
        require(!hasPurchased[msg.sender][_contentId], "Already purchased this content");
        require(msg.sender != content.creator, "Cannot purchase your own content");
        
        // Calculate platform fee and creator earnings
        uint256 platformFee = (msg.value * PLATFORM_FEE_PERCENTAGE) / 100;
        uint256 creatorEarnings = msg.value - platformFee;
        
        // Update content stats
        content.totalEarnings += creatorEarnings;
        content.purchaseCount++;
        
        // Update creator stats
        creators[content.creator].totalEarnings += creatorEarnings;
        
        // Mark as purchased
        hasPurchased[msg.sender][_contentId] = true;
        
        // Transfer earnings to creator
        payable(content.creator).transfer(creatorEarnings);
        
        emit ContentPurchased(_contentId, msg.sender, content.creator, msg.value);
    }
    
    // View functions
    function getContent(uint256 _contentId) 
        external 
        view 
        contentExists(_contentId) 
        returns (Content memory) 
    {
        return contents[_contentId];
    }
    
    function getCreator(address _creator) 
        external 
        view 
        returns (Creator memory) 
    {
        return creators[_creator];
    }
    
    function getCreatorContentIds(address _creator) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return creatorContents[_creator];
    }
    
    function hasUserPurchased(address _user, uint256 _contentId) 
        external 
        view 
        returns (bool) 
    {
        return hasPurchased[_user][_contentId];
    }
    
    // Owner functions
    function verifyCreator(address _creator) external onlyOwner {
        require(bytes(creators[_creator].username).length > 0, "Creator not registered");
        creators[_creator].isVerified = true;
    }
    
    function withdrawPlatformFees() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    function updatePlatformOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }
}
