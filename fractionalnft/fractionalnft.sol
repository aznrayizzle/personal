pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract FractionalNFT is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant TOKEN_PRICE = 1; // 1 ERC-20 token per token

    IERC20 public erc20Token;

    uint256 public totalSupply;

    mapping(uint256 => uint256) public tokenShares;
    mapping(address => mapping(uint256 => uint256)) public userShares;

    constructor(address _erc20Token, address initialOwner) ERC721("FractionalNFT", "FNFT") Ownable(initialOwner) {
        erc20Token = IERC20(_erc20Token);
        Ownable(msg.sender);
    }
    
    event SharesTransferred(address indexed from, address indexed to, uint256 indexed tokenId, uint256 shares);

    function mint(uint256 _numTokens) external {
        require(totalSupply + _numTokens <= MAX_SUPPLY, "Exceeds maximum supply");

        uint256 totalCost = 0;

        for (uint256 i = 0; i < _numTokens; i++) {
            uint256 tokenId = totalSupply + 1;
            _safeMint(msg.sender, tokenId);
            tokenShares[tokenId] = 100; // Initially, the owner holds 100% of the shares
            userShares[msg.sender][tokenId] = 100;

            totalCost = totalCost.add(TOKEN_PRICE);

            totalSupply++; // Update total supply
        }

        erc20Token.transferFrom(msg.sender, address(this), totalCost);
    }

    function transferShares(address _to, uint256 _tokenId, uint256 _shares) external {
        emit SharesTransferred(msg.sender, _to, _tokenId, _shares);

        require(isApprovedForAll(msg.sender, ownerOf(_tokenId)), "Not approved or owner");
        require(_shares <= userShares[msg.sender][_tokenId], "Insufficient shares");

        userShares[msg.sender][_tokenId] = userShares[msg.sender][_tokenId].sub(_shares);
        userShares[_to][_tokenId] = userShares[_to][_tokenId].add(_shares);
    }

    function getShares(address _owner, uint256 _tokenId) external view returns (uint256) {
        return userShares[_owner][_tokenId];
    }

    function withdrawERC20() external onlyOwner {
        uint256 balance = erc20Token.balanceOf(address(this));
        erc20Token.transfer(owner(), balance);
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }
}
