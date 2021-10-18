pragma solidity ^0.6.6;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ISecondLiveNFT is IERC1155 {
    
    struct Attribute {
        uint256 rule; // 1
        uint256 quality; // power 
        uint256 format; // proj
        uint256 extra; // tokenId
    }

    function mint(
        address account, 
        uint256 id, 
        uint256 amount,
        bytes calldata data,
        Attribute calldata attribute) external;
        
    function mintBatch(
        address to, 
        uint256[] calldata ids, 
        uint256[] calldata amounts, 
        bytes calldata data,
        Attribute[] calldata _attributes) external;

    function getAttribute(uint256 id) 
        external 
        view 
        returns (Attribute memory attribute);

}
