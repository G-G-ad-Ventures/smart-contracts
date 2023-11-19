// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IERC721 {
    function transferFrom(address _from, address _to, uint _nftId) external;
}

contract DutchAuction {
    uint private constant DURATION = 7 days;

    IERC721 public immutable nft;
    uint public immutable nftId;

    address payable public immutable seller;
    uint public immutable startingPrice; // $1000
    uint public immutable startAt; // today
    uint public immutable expiresAt; // 30 days
    uint public immutable discountRate; // $50

    constructor(
        uint _startingPrice,
        uint _discountRate,
        address _nft,
        uint _nftId
    ) {
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        startAt = block.timestamp;
        expiresAt = block.timestamp + DURATION;
        discountRate = _discountRate;

        require(
            _startingPrice >= _discountRate * DURATION,
            "starting price < min"
        );

        nft = IERC721(_nft);
        nftId = _nftId;
    }

    function getPrice() public view returns (uint) {
        uint timeElapsed = block.timestamp - startAt;
        uint discount = timeElapsed * discountRate;
        return startingPrice - discount; 
    }

    function buy() external payable {
        require(expiresAt > block.timestamp, "Auction expired!");
        uint price = getPrice();
        require(msg.value >= price, "value sent is less then auction rpice");
        
        nft.transferFrom(seller, msg.sender, nftId);
        uint refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        
        selfdestruct(seller);
    }
}
