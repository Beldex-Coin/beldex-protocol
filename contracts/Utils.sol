// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

library Utils {

    uint256 constant GROUP_ORDER = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    uint256 constant FIELD_ORDER = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    function gAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        return addmod(x, y, GROUP_ORDER);
    }

    function gMul(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulmod(x, y, GROUP_ORDER);
    }

    function gInv(uint256 x) internal view returns (uint256) {
        return gExp(x, GROUP_ORDER - 2);
    }

    function gMod(uint256 x) internal pure returns (uint256) {
        return x % GROUP_ORDER;
    }

    function gSub(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x - y : GROUP_ORDER - y + x;
    }

    function gNeg(uint256 x) internal pure returns (uint256) {
        return GROUP_ORDER - x;
    }

    function gExp(uint256 base, uint256 exponent) internal view returns (uint256 output) {
        uint256 order = GROUP_ORDER;
        assembly {
            let m := mload(0x40)
            mstore(m, 0x20)
            mstore(add(m, 0x20), 0x20)
            mstore(add(m, 0x40), 0x20)
            mstore(add(m, 0x60), base)
            mstore(add(m, 0x80), exponent)
            mstore(add(m, 0xa0), order)
            if iszero(staticcall(gas(), 0x05, m, 0xc0, m, 0x20)) { // staticcall or call?
                revert(0, 0)
            }
            output := mload(m)
        }
    }

    function fieldExp(uint256 base, uint256 exponent) internal view returns (uint256 output) { // warning: mod p, not q
        uint256 order = FIELD_ORDER;
        assembly {
            let m := mload(0x40)
            mstore(m, 0x20)
            mstore(add(m, 0x20), 0x20)
            mstore(add(m, 0x40), 0x20)
            mstore(add(m, 0x60), base)
            mstore(add(m, 0x80), exponent)
            mstore(add(m, 0xa0), order)
            if iszero(staticcall(gas(), 0x05, m, 0xc0, m, 0x20)) { // staticcall or call?
                revert(0, 0)
            }
            output := mload(m)
        }
    }

}