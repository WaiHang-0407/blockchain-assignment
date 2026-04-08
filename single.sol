// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Parent {

    uint internal sum;

    function setValue(uint _a, uint _b) external {

        uint a = _a;

        uint b = _b;

        sum = a + b;

    }

}

contract Child is Parent {

    function getValue() public view returns (uint) {

        return sum;

    }

    function getValueFromParent() external view returns (uint) {

        return Child.getValue();

    }

}