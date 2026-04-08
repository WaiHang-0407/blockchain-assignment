// Child1.sol

pragma solidity ^0.8.0;

import "./Parent1.sol";

contract Child1 {

Parent1Interface public parent1Contract;

constructor(address _parent1ContractAddress) {

parent1Contract = Parent1Interface(_parent1ContractAddress);

}

function setValueFromChild(uint256 _a, uint256 _b) external {

parent1Contract.setValue(_a, _b);

}

function getValueFromChild() external view returns (uint256) {

return parent1Contract.getValue();

}

}