// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Utils.sol";
import "./BeldexIP.sol";

contract BeldexRedeem {
    using Utils for uint256;
    using Utils for Utils.G1Point;

    BeldexIP ip;

    struct Statement {
        Utils.G1Point ct_l;
        Utils.G1Point ct_r;
        Utils.G1Point pk;
        uint256 epoch; 
        Utils.G1Point u;
        address sender;
    }

    struct Proof {
        Utils.G1Point BA;
        Utils.G1Point BS;

        Utils.G1Point[2] tCommits;
        uint256 tHat;
        uint256 mu;

        uint256 c;
        uint256 s_sk;
        uint256 s_b;
        uint256 s_tau;

        BeldexIP.Proof ip_proof;
    }

    constructor(address _ip) public {
        ip = BeldexIP(_ip);
    }

    struct RedeemInfo {
        uint256 y;
        uint256[32] ys;
        uint256 z;
        uint256 z2; 
        uint256 z3;
        uint256[32] twoTimesZSquared;
        uint256 x;
        uint256 t;
        uint256 k;
        Utils.G1Point tEval;
    }

    struct SigmaInfo {
        uint256 c;
        Utils.G1Point A_y;
        Utils.G1Point A_b;
        Utils.G1Point A_t;
        Utils.G1Point gEpoch;
        Utils.G1Point A_u;
    }

    struct IPInfo {
        Utils.G1Point P;
        Utils.G1Point u_x;
        Utils.G1Point[] hPrimes;
        Utils.G1Point hPrimeSum;
        uint256 o;
    }

    function gSum() internal pure returns (Utils.G1Point memory) {
        return Utils.G1Point(0x2257118d30fe5064dda298b2fac15cf96fd51f0e7e3df342d0aed40b8d7bb151, 0x0d4250e7509c99370e6b15ebfe4f1aa5e65a691133357901aa4b0641f96c80a8);
    }

    function wrapStatement (Utils.G1Point memory ct_l, Utils.G1Point memory ct_r, Utils.G1Point memory pk, uint256 epoch, Utils.G1Point memory u, address sender) public pure returns (Statement memory statement) {
        statement.ct_l = ct_l;
        statement.ct_r = ct_r;
        statement.pk = pk;
        statement.epoch = epoch;
        statement.u = u;
        statement.sender = sender;
        return statement;
    }


    function unserialize(bytes memory arr) external pure returns (Proof memory proof) {
        proof.BA = Utils.G1Point(Utils.slice(arr, 0), Utils.slice(arr, 32));
        proof.BS = Utils.G1Point(Utils.slice(arr, 64), Utils.slice(arr, 96));

        proof.tCommits = [Utils.G1Point(Utils.slice(arr, 128), Utils.slice(arr, 160)), Utils.G1Point(Utils.slice(arr, 192), Utils.slice(arr, 224))];
        proof.tHat = uint256(Utils.slice(arr, 256));
        proof.mu = uint256(Utils.slice(arr, 288));

        proof.c = uint256(Utils.slice(arr, 320));
        proof.s_sk = uint256(Utils.slice(arr, 352));
        proof.s_b = uint256(Utils.slice(arr, 384));
        proof.s_tau = uint256(Utils.slice(arr, 416));

        BeldexIP.Proof memory ip_proof;
        ip_proof.ls = new Utils.G1Point[](5);
        ip_proof.rs = new Utils.G1Point[](5);
        for (uint256 i = 0; i < 5; i++) { // 2^5 = 32.
            ip_proof.ls[i] = Utils.G1Point(Utils.slice(arr, 448 + i * 64), Utils.slice(arr, 480 + i * 64));
            ip_proof.rs[i] = Utils.G1Point(Utils.slice(arr, 448 + (5 + i) * 64), Utils.slice(arr, 480 + (5 + i) * 64));
        }
        ip_proof.a = uint256(Utils.slice(arr, 448 + 5 * 128));
        ip_proof.b = uint256(Utils.slice(arr, 480 + 5 * 128));
        proof.ip_proof = ip_proof;

        return proof;
    }
}