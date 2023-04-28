// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract Arbitration {
    address public arbitrator;
    address public seller;
    address public buyer;
    uint public deposit = 0.5 ether;
    uint public productPrice = 1 ether;
    bool public buyerDepositSent;
    bool public sellerDepositSent;
    bool public productPaid;
    bool public contractClosed;
    mapping(address => uint) balances;
    bool public arbitrationCalled;
    address public arbitrationCalledBy;
    string[3][] private messages;
    bool arbitrationClosed; 
    
    constructor(address _buyer, address _seller, address _arbitrator) {
        buyer = _buyer;
        seller = _seller;
        arbitrator = _arbitrator;
    }
    
    modifier onlySeller() {
        require(msg.sender == seller, "MUST BE SELLER");
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "MUST BE BUYER");
        _;
    }

    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "MUST BE ARBITRATOR");
        _;
    }

    modifier onlyParty() {
        require((msg.sender == buyer) || (msg.sender == seller), "MUST BE PARTY");
        _;
    }

    modifier onlyParticipant() {
        require((msg.sender == buyer) || (msg.sender == seller) || (msg.sender == arbitrator),  "MUST BE PARTICIPANT");
        _;
    }

    modifier onlyDuringArbitration() {
        require(arbitrationCalled, "Possible only during arbitration");
        _;    
    }

    modifier restrictedDuringArbitration() {
        require(!arbitrationCalled, "Arbitration is called. Not possible");
        _;
    }

    modifier restrictWhenArbitrationClosed() {
        require(!arbitrationClosed, "Arbitration is already closed");
        _;
    }

    modifier restrictWhenContractIsClosed() {
        require(!contractClosed, "Arbitration is already closed");
        _;
    }

    function sendDepositAsBuyer() payable external onlyBuyer() restrictWhenContractIsClosed() {
        if (buyerDepositSent) {
            revert("The deposit has already been sent");
        }
        if (msg.value != deposit) {
            revert("Bad value of deposit");
        }
        balances[msg.sender] += msg.value;
        buyerDepositSent = true;
    }

    function sendProductPrice() payable external onlyBuyer() restrictWhenContractIsClosed() {
        if (productPaid) {
            revert("The product has already been paid for");
        }
        if (msg.value != productPrice) {
            revert("Bad value of product price");
        }
        balances[msg.sender] += msg.value;
        productPaid = true;
    }

    function sendDepositAsSeller() payable external onlySeller() restrictWhenContractIsClosed() {
        if (sellerDepositSent) {
            revert("The deposit has already been sent");
        }
        if (msg.value != deposit) {
            revert("Bad value of deposit");
        }
        balances[msg.sender] += msg.value;
        sellerDepositSent = true;
    }

    function callArbiter(string memory initMessage) public onlyParty() restrictWhenContractIsClosed() {
        if (arbitrationCalled) {
            revert("Arbitration is already called");
        }
        string memory currentTime = Strings.toString(block.timestamp);
        string memory sender = string(abi.encodePacked(msg.sender));
        messages.push([
            sender, 
            currentTime, 
            initMessage
        ]);
        arbitrationCalled = true;      
        arbitrationCalledBy = msg.sender;
    }

    function sendMessageToArbitration(string memory message) public onlyParticipant() onlyDuringArbitration() restrictWhenArbitrationClosed() {
        string memory currentTime = Strings.toString(block.timestamp);
        string memory sender = string(abi.encodePacked(msg.sender));
        messages.push([
            sender,
            currentTime,
            message
        ]);
    }

    function getArbitrationMessages() public view onlyParticipant() returns(string[3][] memory _messages) {
        _messages = messages;
    }

    function closeContract() public onlyBuyer() restrictedDuringArbitration() {
        if (!productPaid) {
            revert("Product should be paid");
        }

        payable(seller).transfer(productPrice);
        balances[buyer] -= productPrice;

        if (buyerDepositSent) {
            payable(buyer).transfer(deposit);
            balances[buyer] -= deposit;
        }

        if (sellerDepositSent) {
            payable(seller).transfer(deposit);
            balances[seller] -= deposit;
        }
        
        contractClosed = true;
    }

    function resolveTheDisputeInFavorOfTheSeller() public onlyArbitrator() onlyDuringArbitration() restrictWhenArbitrationClosed() {
        if (productPaid) {
            payable(seller).transfer(productPrice);
            balances[buyer] -= productPrice;
        }
        if (buyerDepositSent) {
            payable(seller).transfer(deposit);
            balances[buyer] -= deposit;
        }
        if (sellerDepositSent) {
            payable(seller).transfer(deposit);
            balances[seller] -= deposit;
        }
        arbitrationClosed = true;
    }

    function resolveTheDisputeInFavorOfTheBuyer() public onlyArbitrator() onlyDuringArbitration() restrictWhenArbitrationClosed() {
        if (productPaid) {
            payable(buyer).transfer(productPrice);
            balances[buyer] -= productPrice;
        }
        if (buyerDepositSent) {
            payable(buyer).transfer(deposit);
            balances[buyer] -= deposit;
        }
        if (sellerDepositSent) {
            payable(buyer).transfer(deposit);
            balances[seller] -= deposit;
        }
        arbitrationClosed = true;
    }

    function restitute() public onlyArbitrator() onlyDuringArbitration() restrictWhenArbitrationClosed() {
        if (productPaid) {
            payable(buyer).transfer(productPrice);
            balances[buyer] -= productPrice;
        }
        if (buyerDepositSent) {
            payable(buyer).transfer(deposit);
            balances[buyer] -= deposit;
        }
        if (sellerDepositSent) {
            payable(seller).transfer(deposit);
            balances[seller] -= deposit;
        }
        arbitrationClosed = true;
    }
}