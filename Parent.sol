// Parent.sol

pragma solidity ^0.8.0;

contract Parent {

    uint256 internal sum;

    function setValue(uint256 _a, uint256 _b) external {

        uint256 result = _a + _b;

        sum += result;

    }

}