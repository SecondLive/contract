pragma solidity ^ 0.6.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interface/IERC2981.sol";
import "../library/String.sol";
import "../library/Governance.sol";
import "../interface/ISecondLiveNFT.sol";


contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title SecondLiveNFT
 * 
 * Registry :  0x1087dcBFaFc13E4a08688B805ded0C2474EB1c9D
 */
contract SecondLiveNFT is ISecondLiveNFT, ERC1155, Governance, IERC2981, ReentrancyGuard {
    using Strings for string;
    
    // Flag of initialize data
    bool private initialized;
    
    address proxyRegistryAddress;

    // for minters
    mapping(address => bool) public _minters;
  
    mapping(uint256 => Attribute) public attributes;

    string public name;
    string public symbol;

    mapping(uint256 => string) private uris;
    string private baseMetadataURI;

    /// @dev
    /// bytes4(keccak256("royaltyInfo(uint256)")) == 0xcef6d368
    /// bytes4(keccak256("onRoyaltiesReceived(address,address,uint256,address,uint256,bytes32)")) == 0xe8cb9d99
    /// bytes4(0xcef6d368) ^ bytes4(0xe8cb9d99) == 0x263d4ef1
    bytes4 private constant _INTERFACE_ID_ERC721ROYALTIES = 0x263d4ef1;

    /// @notice Called to return both the creator's address and the royalty percentage
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @return receiver - address of who should be sent the royalty payment
    /// @return amount - a percentage calculated as a fixed point
    ///         with a scaling factor of 100000 (5 decimals), such that
    ///         100% would be the value 10000000, as 10000000/100000 = 100.
    ///         1% would be the value 100000, as 100000/100000 = 1
    struct RoyaltyInfo {
        address creator;
        uint256 amount;
    }

    uint256 public _defultRoyalty = 0; // 1000000; // 10%
    mapping(uint256 => RoyaltyInfo) private _royaltyInfos;

    event CreatorChanged(uint256 indexed _id, address indexed _creator);
    event RoyaltyChanged(uint256 indexed _id, uint256 indexed _royalty);
    event DefultRoyaltyChanged(uint256 _royalty);

    event URI(string _uri, uint256 indexed _id);

    event SecondLiveNFTAdd(address indexed account, uint256 indexed id, uint256 indexed amount, Attribute attribute);
    event SecondLiveNFTsAdd(address indexed account, uint256[] id, uint256[] amount, Attribute[] attributes);
    event AttributeChanged(uint256 indexed id, Attribute attribute);
    
    constructor() public ERC1155("") {
        // Royalties interface 
        _registerInterface(_INTERFACE_ID_ERC721ROYALTIES);
        setURIPrefix("https://api.secondlive.world/backend/v1/metadata/bsc/");
    }

    // --- Init ---
    function initialize(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) public {
        require(!initialized, "initialize: Already initialized!");
        _governance = msg.sender;
       
        name = _name;
        symbol = _symbol;

        // Royalties interface 
        _registerInterface(0x263d4ef1);
        setURIPrefix("https://api.secondlive.world/backend/v1/metadata/bsc/");

        proxyRegistryAddress = _proxyRegistryAddress;

        initialized = true;
    }
    
    function uri(uint256 _id) public view override returns(string memory) {
        require(_exists(_id), "SecondLiveNFT#uri: NONEXISTENT_TOKEN");

        if (bytes(uris[_id]).length > 0) {
            return uris[_id];
        }
        return Strings.strConcat(baseMetadataURI, Strings.uint2str(_id));
    }
    
    function isApprovedForAll(address _owner, address _operator) public view override(ERC1155, IERC1155) returns (bool isOperator) {
        // Whitelist TreasureLand proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }
        return super.isApprovedForAll(_owner, _operator);
    }

    function royaltyInfo(uint256 _id) external view override returns (address receiver, uint256 amount) {
        receiver = _royaltyInfos[_id].creator;
        amount = _royaltyInfos[_id].amount;
    }
    
    // onlyGovernance
    function mint(
        address account, 
        uint256 id, 
        uint256 amount,
        bytes calldata data,
        Attribute memory attribute) 
    external override nonReentrant {
        require(_minters[msg.sender], "SecondLiveNFT: INVALID_MINTER.");
        if (_exists(id) == false) {
            _royaltyInfos[id].creator = account;
            _royaltyInfos[id].amount = _defultRoyalty;
            attributes[id] = attribute;
        }
        _mint(account, id, amount, data);
        require(id > 0, "SecondLiveNFT: INVALID_ID.");

        emit SecondLiveNFTAdd(
            account, 
            id, 
            amount,
            attribute);
    }

    function mintBatch(
        address to, 
        uint256[] calldata ids, 
        uint256[] calldata amounts, 
        bytes calldata data,
        Attribute[] calldata _attributes) 
    external override nonReentrant {
        require(_minters[msg.sender], "SecondLiveNFT: INVALID_MINTER.");
        require(ids.length == _attributes.length, "SecondLiveNFT: INVALID_ARRAY_LENGTH.");
        require(amounts.length == _attributes.length, "SecondLiveNFT: INVALID_ARRAY_LENGTH.");
        _mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            require(id > 0, "SecondLiveNFT: INVALID_ID.");
            if (_exists(id) == false) {
                _royaltyInfos[id].creator = to;
                _royaltyInfos[id].amount = _defultRoyalty;
                Attribute memory attribute = _attributes[i];
                attributes[id] = attribute;
            }
        }

        emit SecondLiveNFTsAdd(
            to, 
            ids, 
            amounts, 
            _attributes);
    }
    
    function burn(
        address account, 
        uint256 id, 
        uint256 amount) 
    external nonReentrant {
        require((msg.sender == account) || isApprovedForAll(account, msg.sender), "SecondLiveNFT#burn: INVALID_OPERATOR");
        require(balanceOf(account, id) >= amount, "SecondLiveNFT#burn: Trying to burn more tokens than you own");
        _burn(account, id, amount);
    }

    function burnBatch(
        address account, 
        uint256[] calldata ids, 
        uint256[] calldata amounts) 
    external nonReentrant {
        require((msg.sender == account) || isApprovedForAll(account, msg.sender), "SecondLiveNFT#burn: INVALID_OPERATOR");
         for (uint i = 0; i < ids.length; i++) {
            require(balanceOf(account, ids[i]) >= amounts[i], "SecondLiveNFT#burn: Trying to burn more tokens than you own");
        }
        _burnBatch(account, ids, amounts);
    }

    function addMinter(address minter) public onlyGovernance {
        _minters[minter] = true;
    }

    function removeMinter(address minter) public onlyGovernance {
        _minters[minter] = false;
    }
    
    function updateProxyRegistryAddress(address _proxyRegistryAddress) external onlyGovernance{
        require(_proxyRegistryAddress != address(0), "No zero address");
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setCreator(uint256 _id, address _to) public onlyGovernance {
        require(_to != address(0),"SecondLiveNFT: INVALID_ADDRESS.");
        _royaltyInfos[_id].creator = _to;
        emit CreatorChanged(_id, _to);
    }

    function setRoyalty(uint256 _id, uint256 _amount) public onlyGovernance {
        _royaltyInfos[_id].amount = _amount;
        emit RoyaltyChanged(_id, _amount);
    }

    function setAttribute(uint256 id, Attribute memory attribute) public onlyGovernance {
        attributes[id] = attribute;
        emit AttributeChanged(id, attribute);
    }

    function getAttribute(uint256 id) external view override returns (Attribute memory attribute) {
        attribute = attributes[id];
    }

    function updateUri(uint256 _id, string calldata _uri) external onlyGovernance {
        if (bytes(_uri).length > 0) {
            uris[_id] = _uri;
            emit URI(_uri, _id);
        }
    }

    function setURIPrefix(string memory _newBaseMetadataURI) public onlyGovernance {
        baseMetadataURI = _newBaseMetadataURI;
    }
    
    function setDefultRoyalty(uint256 _royalty) public onlyGovernance {
        _defultRoyalty = _royalty;
        emit DefultRoyaltyChanged(_royalty);
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return _royaltyInfos[_id].creator != address(0);
    }

    function onRoyaltiesReceived(address _royaltyRecipient, address _buyer, uint256 _tokenId, address _tokenPaid, uint256 _amount, bytes32 _metadata) external override returns (bytes4) {
        emit RoyaltiesReceived(_royaltyRecipient, _buyer, _tokenId, _tokenPaid, _amount, _metadata);    
        return bytes4(keccak256("onRoyaltiesReceived(address,address,uint256,address,uint256,bytes32)"));
    }

    function version() public pure returns (string memory) {
        return "1.0.0";
    }

}