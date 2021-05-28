// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Utils.sol";


contract BeldexBase {

    using Utils for uint256;
    using Utils for Utils.G1Point;

    /*
       Max units that can be handled by beldex.
    */
    uint256 public constant MAX = 2**32-1;

    /* 
       The # of tokens that constitute one unit.
       Balances, mints, redeems, and transfers are all interpreted in terms of unit, rather than token. 
    */
    uint256 public unit; 

    uint256 public round_len = 24; 
    uint256 public round_base = 0; // 0 for block, 1 for second (usually just for test)


    address payable public beldex_agency; 



    mapping(bytes32 => Utils.G1Point[2]) acc; // main account mapping
    mapping(bytes32 => Utils.G1Point[2]) pending; // storage for pending transfers
    mapping(bytes32 => uint256) public last_roll_over;
    bytes32[] nonce_set; // would be more natural to use a mapping, but they can't be deleted / reset!
    uint256 public last_global_update = 0;


    constructor() public {
        beldex_agency = msg.sender;

    }

    function setRoundBase (uint256 _round_base) public {
        require(msg.sender == beldex_agency, "Permission denied: Only admin can change round base.");
        round_base = _round_base;
    }

    function setRoundLen (uint256 _round_len) public {
        require(msg.sender == beldex_agency, "Permission denied: Only admin can change round length.");
        round_len = _round_len;
    }

    function setUnit (uint256 _unit) public {
        require(msg.sender == beldex_agency, "Permission denied: Only admin can change unit.");
        unit = _unit;
    }

    function setBeldexAgency (address payable _beldex_agency) public {
        require(msg.sender == beldex_agency, "Permission denied: Only admin can change agency.");
        beldex_agency = _beldex_agency;
    }

}