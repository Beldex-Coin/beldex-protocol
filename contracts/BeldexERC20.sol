// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./Utils.sol";
import "./BeldexBase.sol";


contract RazeERC20 is RazeBase {

    ERC20 token;

    constructor(address _token, address _transfer, address _redeem, uint256 _unit) RazeBase(_transfer, _redeem, _unit) public {
        token = ERC20(_token);
    }

    function mint(Utils.G1Point memory y, uint256 unitAmount, bytes memory encGuess) public {
        mintBase(y, unitAmount, encGuess);

        uint256 nativeAmount = toNativeAmount(unitAmount);

        // In order for the following to succeed, `msg.sender` have to first approve `this` to spend the nativeAmount.
        require(token.transferFrom(msg.sender, address(this), nativeAmount), "[Raze mint] Native 'transferFrom' failed.");
    }

}