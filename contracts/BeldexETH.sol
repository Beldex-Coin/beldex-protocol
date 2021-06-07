// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Utils.sol";
import "./BeldexBase.sol";

contract BeldexETH is BeldexBase {

    constructor(address _transfer, address _redeem, uint256 _unit) BeldexBase(_transfer, _redeem, _unit) public {
    }

    function mint(Utils.G1Point memory y, uint256 unitAmount, bytes memory encGuess) public payable {
        uint256 mUnitAmount = toUnitAmount(msg.value);
        require(unitAmount == mUnitAmount, "[Beldex mint] Specified mint amount is differnet from the paid amount.");

        mintBase(y, unitAmount, encGuess);
    }

}