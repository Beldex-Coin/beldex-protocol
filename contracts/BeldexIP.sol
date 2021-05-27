// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Utils.sol";

contract BeldexIP {
    using Utils for uint256;
    using Utils for Utils.G1Point;

    struct Statement {
        Utils.G1Point[] hs; // "overridden" parameters.
        Utils.G1Point u;
        Utils.G1Point P;
    }

    struct Proof {
        Utils.G1Point[] ls;
        Utils.G1Point[] rs;
        uint256 a;
        uint256 b;
    }

    function verifyInnerProduct(Utils.G1Point[] memory hs, Utils.G1Point memory u, Utils.G1Point memory P, Proof memory proof, uint256 salt) public view returns (bool) {
        Statement memory statement;
        statement.hs = hs;
        statement.u = u;
        statement.P = P;

        return verify(statement, proof, salt);
    }

    struct IPInfo {
        uint256 o;
        uint256[] challenges;
        uint256[] otherExponents;
    }

    function verify(Statement memory statement, Proof memory proof, uint256 salt) internal view returns (bool) {
        //verify Inner Product
    }


}