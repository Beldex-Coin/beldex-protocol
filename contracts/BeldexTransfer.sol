// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Utils.sol";
import "./BeldexIP.sol";

contract BeldexTransfer {
    using Utils for uint256;
    using Utils for Utils.G1Point;

    uint256 constant UNITY = 0x14a3074b02521e3b1ed9852e5028452693e87be4e910500c7ba9bbddb2f46edd; // primitive 2^28th root of unity modulo q.

    BeldexIP ip;

    struct Statement {
        Utils.G1Point[] ct_l;
        Utils.G1Point[] ct_r;
        Utils.G1Point[] C;
        Utils.G1Point D;
        Utils.G1Point[] pk;
        uint256 epoch;
        Utils.G1Point u;
    }

    struct Proof {
        Utils.G1Point BA;
        Utils.G1Point BS;
        Utils.G1Point A;
        Utils.G1Point B;

        Utils.G1Point[] CLnG;
        Utils.G1Point[] CRnG;
        Utils.G1Point[] C_0G;
        Utils.G1Point[] DG;
        Utils.G1Point[] y_0G;
        Utils.G1Point[] gG;
        Utils.G1Point[] C_XG;
        Utils.G1Point[] y_XG;

        uint256[] f;
        uint256 z_A;
        uint256 z_C;
        uint256 z_E;

        Utils.G1Point[2] tCommits;
        uint256 tHat;
        uint256 mu;

        uint256 c;
        uint256 s_sk;
        uint256 s_r;
        uint256 s_b;
        uint256 s_tau;

        BeldexIP.Proof ipProof;
    }

    constructor(address _ip) public {
        ip = BeldexIP(_ip);
    }

    struct TransferInfo {
        uint256 y;
        uint256[64] ys;
        uint256 z;
        uint256[2] zs; // [z^2, z^3]
        uint256[64] twoTimesZSquared;
        uint256 zSum;
        uint256 x;
        uint256 t;
        uint256 k;
        Utils.G1Point tEval;
    }

    struct SigmaInfo {
        uint256 c;
        Utils.G1Point A_y;
        Utils.G1Point A_D;
        Utils.G1Point A_b;
        Utils.G1Point A_X;
        Utils.G1Point A_t;
        Utils.G1Point gEpoch;
        Utils.G1Point A_u;
    }

    struct AnonInfo {
        uint256 m;
        uint256 N;
        uint256 v;
        uint256 w;
        uint256 vPow;
        uint256 wPow;
        uint256[2][] f; // could just allocate extra space in the proof?
        uint256[2][] r; // each poly is an array of length N. evaluations of prods
        Utils.G1Point temp;
        Utils.G1Point CLnR;
        Utils.G1Point CRnR;
        Utils.G1Point[2][] CR;
        Utils.G1Point[2][] yR;
        Utils.G1Point C_XR;
        Utils.G1Point y_XR;
        Utils.G1Point gR;
        Utils.G1Point DR;
    }

    struct IPInfo {
        Utils.G1Point P;
        Utils.G1Point u_x;
        Utils.G1Point[] hPrimes;
        Utils.G1Point hPrimeSum;
        uint256 o;
    }

}
