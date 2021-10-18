pragma solidity ^0.6.0;

/**
 * @dev Implementation of royalties for 721s
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-2981.md
 */
interface IERC2981 {
    // ERC165 bytes to add to interface array - set in parent contract
    // implementing this standard
    //
    // bytes4(keccak256("royaltyInfo(uint256)")) == 0xcef6d368
    // bytes4(keccak256("onRoyaltiesReceived(address,address,uint256,address,uint256,bytes32)")) == 0xe8cb9d99
    // bytes4(0xcef6d368) ^ bytes4(0xe8cb9d99) == 0x263d4ef1
    // bytes4 private constant _INTERFACE_ID_ERC721ROYALTIES = 0x263d4ef1;
    // _registerInterface(_INTERFACE_ID_ERC721ROYALTIES);

    // @notice Called to return both the creator's address and the royalty percentage
    // @param _tokenId - the NFT asset queried for royalty information
    // @return receiver - address of who should be sent the royalty payment
    // @return amount - a percentage calculated as a fixed point
    //         with a scaling factor of 100000 (5 decimals), such that
    //         100% would be the value 10000000, as 10000000/100000 = 100.
    //         1% would be the value 100000, as 100000/100000 = 1
    function royaltyInfo(uint256 _tokenId) external view returns (address receiver, uint256 amount);

    // @notice Called when royalty is transferred to the receiver. This
    //         emits the RoyaltiesReceived event as we want the NFT contract
    //         itself to contain the event for easy tracking by royalty receivers.
    // @param _royaltyRecipient - The address of who is entitled to the
    //                            royalties as specified by royaltyInfo().
    // @param _buyer - If known, the address buying the NFT on a secondary
    //                 sale. 0x0 if not known.
    // @param _tokenId - the ID of the ERC-721 token that was sold
    // @param _tokenPaid - The address of the ERC-20 token used to pay the
    //                     royalty fee amount. Set to 0x0 if paid in the
    //                     native asset (ETH).
    // @param _amount - The amount being paid to the creator using the
    //                  correct decimals from _tokenPaid's ERC-20 contract
    //                  (i.e. if 7 decimals, 10000000 for 1 token paid)
    // @param _metadata - Arbitrary data attached to this payment
    // @return `bytes4(keccak256("onRoyaltiesReceived(address,address,uint256,address,uint256,bytes32)"))`
    function onRoyaltiesReceived(address _royaltyRecipient, address _buyer, uint256 _tokenId, address _tokenPaid, uint256 _amount, bytes32 _metadata) external returns (bytes4);

    // @dev This event MUST be emitted by `onRoyaltiesReceived()`.
    event RoyaltiesReceived(
        address indexed _royaltyRecipient,
        address indexed _buyer,
        uint256 indexed _tokenId,
        address _tokenPaid,
        uint256 _amount,
        bytes32 _metadata
    );

}