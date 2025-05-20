// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Tokenized Real-World Asset Ownership Syndicate
 * @dev This contract allows for the creation and management of tokenized real-world assets
 * with fractional ownership capabilities.
 */
contract Project is ERC1155, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    Counters.Counter private _assetIds;
    
    struct AssetInfo {
        string name;
        string description;
        uint256 totalShares;
        uint256 pricePerShare;
        bool isActive;
        address payable creator;
    }
    
    // Mapping from asset ID to its information
    mapping(uint256 => AssetInfo) public assets;
    
    // Events
    event AssetCreated(uint256 indexed assetId, string name, uint256 totalShares, uint256 pricePerShare);
    event SharesPurchased(uint256 indexed assetId, address indexed buyer, uint256 shares);
    event AssetStatusChanged(uint256 indexed assetId, bool isActive);
    
    constructor() ERC1155("https://api.tokenized-rwa-syndicate.com/assets/{id}.json") Ownable(msg.sender) {
        // Constructor initialization
    }
    
    /**
     * @dev Creates a new tokenized real-world asset
     * @param name Asset name
     * @param description Asset description
     * @param totalShares Total number of shares available for this asset
     * @param pricePerShare Price per share in wei
     */
    function createAsset(
        string memory name,
        string memory description,
        uint256 totalShares,
        uint256 pricePerShare
    ) external onlyOwner {
        require(totalShares > 0, "Total shares must be greater than zero");
        require(pricePerShare > 0, "Price per share must be greater than zero");
        
        uint256 newAssetId = _assetIds.current();
        _assetIds.increment();
        
        assets[newAssetId] = AssetInfo({
            name: name,
            description: description,
            totalShares: totalShares,
            pricePerShare: pricePerShare,
            isActive: true,
            creator: payable(msg.sender)
        });
        
        // Mint all shares to the contract creator initially
        _mint(msg.sender, newAssetId, totalShares, "");
        
        emit AssetCreated(newAssetId, name, totalShares, pricePerShare);
    }
    
    /**
     * @dev Allows users to purchase shares of a tokenized asset
     * @param assetId ID of the asset to purchase shares of
     * @param shareAmount Number of shares to purchase
     */
    function purchaseShares(uint256 assetId, uint256 shareAmount) external payable nonReentrant {
        AssetInfo storage asset = assets[assetId];
        
        require(asset.isActive, "Asset is not active for purchase");
        require(shareAmount > 0, "Share amount must be greater than zero");
        require(balanceOf(asset.creator, assetId) >= shareAmount, "Not enough shares available");
        require(msg.value == asset.pricePerShare * shareAmount, "Incorrect payment amount");
        
        // Transfer shares from creator to buyer
        _safeTransferFrom(asset.creator, msg.sender, assetId, shareAmount, "");
        
        // Transfer payment to asset creator
        asset.creator.transfer(msg.value);
        
        emit SharesPurchased(assetId, msg.sender, shareAmount);
    }
    
    /**
     * @dev Allows the owner to toggle the active status of an asset
     * @param assetId ID of the asset to update
     * @param isActive New active status
     */
    function setAssetStatus(uint256 assetId, bool isActive) external onlyOwner {
        require(assets[assetId].totalShares > 0, "Asset does not exist");
        
        assets[assetId].isActive = isActive;
        
        emit AssetStatusChanged(assetId, isActive);
    }

    /**
     * @dev Allows the owner to update the price per share of an asset
     * @param assetId ID of the asset to update
     * @param newPrice New price per share in wei
     */
    function updatePricePerShare(uint256 assetId, uint256 newPrice) external onlyOwner {
        require(assets[assetId].totalShares > 0, "Asset does not exist");
        require(newPrice > 0, "Price must be greater than zero");

        assets[assetId].pricePerShare = newPrice;
    }
    
    /**
     * @dev Returns the number of assets created
     */
    function getAssetCount() external view returns (uint256) {
        return _assetIds.current();
    }
}
