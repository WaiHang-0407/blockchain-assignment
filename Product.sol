//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Product {
    
    string public productName = "Chaw House";
    uint public productPrice = 10 ether;
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    address payable public buyer;
 
    //event ProductCreated(string productName, uint productPrice, address payable owner);

    function getInitialProduct() public view returns (string memory, uint, address) {
        return (productName, productPrice, owner);
    }
    
    function setProduct(string memory _productName, uint _price) public {
        //require a valid name
        require(bytes(_productName).length > 0);

        //require a valid price
        require(_price > 0);
        
        productName = _productName;
        productPrice = _price;
        owner = payable(msg.sender);
        //emit ProductCreated(productName, productPrice, owner);

    }

    function buyProduct(address payable _toReceiver) public payable{
        buyer = payable(msg.sender);
        _toReceiver.transfer(msg.value);
        //update the ownership
        owner = buyer;
    }


}