// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IERC721 {
    function transferFrom(address from, address to, uint nftId) external;
}

contract EnglishAuction {
    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, uint amount);

    IERC721 public immutable nft;
    uint public immutable nftId;

    address payable public immutable seller;
    uint public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint public highestBid;

    // mapping from bidder to amount of ETH the bidder can withdraw
    mapping(address => uint) public bids;

    constructor(address _nft, uint _nftId, uint _startingBid) {
        nft = IERC721(_nft);
        nftId = _nftId;

        seller = payable(msg.sender);
        highestBid = _startingBid;
    }
    
    modifier isSeller() {
        require(msg.sender == seller, "Only seller can start this auction");
        _;
    }
    
    modifier isStarted() {
        require(!started, "Auction already started");
        _;
    }
    
    modifier notStarted() {
        require(started, "Auction not started");
        _;
    }
    
    modifier isEnded() {
        require(!ended, "Cannot bid, Auction ended");
        _;
    }
    
    modifier expired() {
        require(block.timestamp >= endAt, "expired");
        _;
    }
    
    modifier notExpired() {
         require(endAt > block.timestamp, "not expired");
         _;
    }
    
    function start() external isSeller isStarted{
        nft.transferFrom(seller, address(this), nftId);
        started = true;
        endAt = block.timestamp + 7 days;
        
        emit Start();
    }

    function bid() external payable notStarted notExpired isEnded {
        require(msg.value > highestBid, "Bid is lower then highest bid");
        
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit Bid(highestBidder, highestBid);
    }

    function withdraw() external {
        uint totalBidSize = bids[msg.sender];
        // if (msg.sender == highestBidder) {
        //     totalBidSize -= highestBid;            
        // }

        bids[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: totalBidSize}("");
        require(success, "withdraw failed");
        
        emit Withdraw(msg.sender, totalBidSize);
    }

    function end() external notStarted isEnded expired {
        ended = true;
        
        if (highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, nftId);   
            seller.transfer(highestBid);
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }
        emit End(highestBidder, highestBid);
    }
}
