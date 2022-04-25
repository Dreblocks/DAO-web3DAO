//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract FakeNFTMarketplace {
// maps tokens id to owners
    mapping(uint => address) public tokens;


// all nfts have the same price in the marketplace
    uint256 nftPrice = 0.001 ether;

    function purchase(uint _tokenId) external payable {
        require(msg.value == nftPrice, "the value is not enough");
        //we make that the nft hasnt been sold to someone 
        // you want the value to be the null address otherwise its not for sale 
        require(tokens[_tokenId] == address(0), "Not for sale");

        tokens[_tokenId] = msg.sender;

    }
// this is how you fetch the price of a given nft
    function getPrice() external view returns (uint) {
        return nftPrice;
    
    } 

// this function check if a nft is  for sale
    function available(uint _tokenId) external view returns (bool) {
        if (tokens[_tokenId] == address(0)) {
            return true; 
            }
            return false;
        }
}