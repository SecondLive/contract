pragma solidity ^ 0.6.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../library/Governance.sol";
import "../interface/ISecondLiveNFT.sol";

contract SecondLiveBlindBox is Governance, ReentrancyGuard {
    using SafeMath for uint256;

    // Flag of initialize data
    bool private initialized;

    mapping(uint256 => uint256) public _startTimes;
    mapping(address => mapping(uint256 =>uint256)) public _claimMembers;
    mapping(address => mapping(uint256 =>uint256)) public _whitelists;

    mapping(uint256 => address) public _projManagers;

    mapping(uint256 => uint256[]) public _projNFTIds;

    ISecondLiveNFT public _secondLive;
 
    event eveNFTReceived(
        address operator,
        address indexed from,
        uint256 indexed id,
        uint256 value,
        bytes data
    );

    function initialize(ISecondLiveNFT secondLive) public {
        require(!initialized, "initialize: Already initialized!");
        _governance = msg.sender;
        _secondLive = secondLive;
        initialized = true;
    }
   
    function claim(uint256 proj) public nonReentrant returns (uint256) {
        require(_startTimes[proj] > 0, "not set start");
        require(block.timestamp >= _startTimes[proj], "claim not start");
        require(_whitelists[msg.sender][proj] > 0, "sender can not claim");
        require(_whitelists[msg.sender][proj] > _claimMembers[msg.sender][proj], "sender has claim");
        uint256[] memory nftIds = _projNFTIds[proj];
        uint256 seed = computerSeed();
        
        // 1-10000
        uint256 _qualityBase = 10000;
        uint256 divBase = 100;

        uint256 quality = seed%_qualityBase;
        uint256 power;
        uint256 nftId;
        if(quality < _qualityBase.mul(40).div(divBase)) {
            nftId = nftIds[0];
            power = 60;
        }else if(_qualityBase.mul(40).div(divBase) <= quality && quality <  _qualityBase.mul(65).div(divBase)){
            nftId = nftIds[1];
            power = 75;
        }else if(_qualityBase.mul(65).div(divBase) <= quality && quality <  _qualityBase.mul(85).div(divBase)){
            nftId = nftIds[2];
            power = 80;
        }else if(_qualityBase.mul(85).div(divBase) <= quality && quality <  _qualityBase.mul(98).div(divBase)){
            nftId = nftIds[3];
            power = 88;
        }else {
            nftId = nftIds[4];
            power = 98;
        }

        bytes memory _data = '0x0';
        ISecondLiveNFT.Attribute memory attribute;
        attribute.rule = 1;// blindbox
        attribute.format = proj;// project
        attribute.extra = nftId;
        attribute.quality = power;
        _secondLive.mint(msg.sender, nftId, 1, _data, attribute);
        _claimMembers[msg.sender][proj] += 1;
    }

    // onlyGovernance
    function setProjManager(uint256 proj, address manager) external onlyGovernance {
        _projManagers[proj] = manager;
    }

    function setProjNFTIds(uint256 proj, uint256[] calldata nftIds) external onlyGovernance {
        require(nftIds.length == 5, "nftIds's length is not 5");
        _projNFTIds[proj] = nftIds;
    }

    // project set
    function setProjStartTimes(uint256 proj, uint256 startTime) external {
        require((msg.sender == _governance || msg.sender == _projManagers[proj]), "not governance or manager");
        _startTimes[proj] = startTime;
    }

    function setWhitelists(uint256 proj, address[] calldata users, uint256[] calldata chances) external {
        require((msg.sender == _governance || msg.sender == _projManagers[proj]), "not governance or manager");
        for (uint256 i = 0; i < users.length; i++) {
            _whitelists[users[i]][proj] = chances[i];
        }
    }

    function setWhitelist(uint256 proj, address user, uint256 chance) external {
        require((msg.sender == _governance || msg.sender == _projManagers[proj]), "not governance or manager");
        _whitelists[user][proj] = chance;
    }

    function computerSeed() private view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));
        return seed;
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4) {
        
        if(address(this) != operator) {
            return 0;
        }

        emit eveNFTReceived(operator, from, id, value, data);
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}