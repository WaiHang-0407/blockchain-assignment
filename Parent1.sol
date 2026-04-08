// Parent1.sol

pragma solidity ^0.8.0;

abstract contract Parent1Interface {

function setValue(uint256 _a, uint256 _b) external virtual;

function getValue() external view virtual returns (uint256);

}

contract Parent1 is Parent1Interface {

uint256 internal sum;

function setValue(uint256 _a, uint256 _b) external override {

uint256 result = _a + _b;

sum += result;

}

function getValue() external view override returns (uint256) {

return sum;

}

}