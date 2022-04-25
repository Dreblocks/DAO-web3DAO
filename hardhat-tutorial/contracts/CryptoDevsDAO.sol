//SPDX-license-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {

        function purchase(uint _tokenId) external payable;
        function getPrice() external view returns (uint);
        // @dev available() returns whether or not the given _tokenId has already been purchased
       // @return Returns a boolean value - true if available, false if not
        function available(uint _tokenId) external view returns (bool);
}

interface ICryptoDevsNFT {
     // @dev balanceOf returns the number of NFTs owned by the given address
    //@param owner - address to fetch number of NFTs for
    // @return Returns the number of NFTs owned
    function balanceOf(address owner) external view returns (uint256);

    //@dev tokenOfOwnerByIndex returns a tokenID at given index for owner
    //@param owner - address to fetch the NFT TokenID for
    // @param index - index of NFT in owned tokens array to fetch
    // @return Returns the TokenID of the NFT
    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint256);
}

contract CryptoDevsDAO is Ownable {

    enum Vote {
        YES,
        NO
    }
 
 struct Proposal {
// we need to track the nft to buy from the secondary marketplace
    uint256 nftTokenId;
// dealine to the voting end, the UNIX timestamp until which this proposal is active. 
//Proposal can be executed after the deadline has been exceeded.
    uint256 deadline;

    uint256 noVotes;
    uint256 yesVotes;
// gonna track if the proposal was executed already
    bool executed;
// track of which token id have been used for voting already
    mapping(uint256 => bool) voters;
 }

// a mapping that keep track of all the proposals
  mapping(uint256 => Proposal) public proposals;

  // the intial value of numproposal is zero
  uint256 public numProposals;

  // making a refenrence to the two contracts interface

  IFakeNFTMarketplace nftMarketplace;
  ICryptoDevsNFT cryptoDevsNFT;

// we intialize the two variables above in the constructor
// mark it as payable so we can send it some eth when the dao is first created
   constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
       nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
       cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
   }
// we create a modifier since the three functions are for memebrs only 
   modifier nftHolderOnly() {
       require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "not a DAO member");
       _;
   }

// this modifer requires that from the proposal mapping, this specific proposal dealine should not have passed
   modifier activeProposalOnly(uint256 proposalIndex) {
       require(proposals[proposalIndex].deadline > block.timestamp, "Dealine exceeded");
       _;
   }

// execution of the proposal happens after voting only 
   modifier inactiveProposalOnly(uint256 proposalIndex) {
// checks that dealine has already passed
       require(proposals[proposalIndex].deadline <= block.timestamp,"Dealine not exceeded");
       require(proposals[proposalIndex].executed == false, "proposal already executed");
       _;
   }





// we return the id of the freshly created proposal
// _nftTokenId refers to the nft you want to buy from the fakenftmarketplace
   function createProposal(uint256 _nftTokenId) external nftHolderOnly returns (uint256) {
       require(nftMarketplace.available(_nftTokenId), "NFT not for sale");
//we load a proposal from our mapping
// the first propossal that gets created gets the id zero
       Proposal storage proposal = proposals[numProposals];
// we track the nft token id
       proposal.nftTokenId = _nftTokenId;
       proposal.deadline = block.timestamp + 5 minutes;

// we increment the number of proposals
       numProposals++;

// we return the id of the newly created proposal
// we have to do minus one since we incremented
       return numProposals - 1;

   }


// if you are a member and the proposal is active then
// we get your nft balance then 
// we loop over all of your token ids to see how many votes you have left
   function voteOnProposal(uint256 proposalIndex, Vote vote) external nftHolderOnly activeProposalOnly(proposalIndex) {
       Proposal storage proposal = proposals[proposalIndex];

// we figure out the voting power based on much much nft the address has 
       uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
     // how many votes a person has
       uint256 numVotes = 0;

// we need to loop over has many nft a person has and check if that specific nfts have been used for voting yet

       for (uint256 i = 0; i < voterNFTBalance; i++) {
           // we get the token id, from tokenownerbyindex 
           uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
         // if this specific nft hasnt been used for voting yet
           if (proposal.voters[tokenId] == false) {
               numVotes++;
               proposal.voters[tokenId] = true;
           }
       }
       
       require(numVotes > 0, "Already VOTED");

       if (vote == Vote.YES) {
           proposal.yesVotes += numVotes;
       } else {
           proposal.noVotes += numVotes;
       }

   }


//if a proposal passed we going to let any member of the dao make the excetution and not just a team or the owner
   function executeProposal(uint256 proposalIndex) external nftHolderOnly  inactiveProposalOnly(proposalIndex) {

       Proposal storage proposal = proposals[proposalIndex];

       if (proposal.yesVotes > proposal.noVotes) {
           uint256 nftPrice = nftMarketplace.getPrice();
           require(address(this).balance >= nftPrice, "Not enough funds");
           nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
       }
       proposal.executed = true;
   }

   function withdrawEther() external onlyOwner {
       payable(owner()).transfer(address(this).balance);
         
   }

   receive() external payable {}
   fallback() external payable {}
}