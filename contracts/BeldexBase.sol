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

    uint256 public balance_log = 0;
    uint256 public users_log = 0;
    uint256 public redeem_fee_log = 0;
    uint256 public transfer_fee_log = 0;
    uint256 public deposits_log = 0;
    uint256 public mint_count_log = 0;
    


    mapping(bytes32 => Utils.G1Point[2]) acc; // main account mapping
    mapping(bytes32 => Utils.G1Point[2]) pending; // storage for pending transfers
    mapping(bytes32 => uint256) public last_roll_over;
    bytes32[] nonce_set; // would be more natural to use a mapping, but they can't be deleted / reset!
    uint256 public last_global_update = 0;

    mapping(bytes32 => bytes) guess;

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

    function register(Utils.G1Point memory y, uint256 c, uint256 s) public {
        // allows y to participate. c, s should be a Schnorr signature on "this"
        Utils.G1Point memory K = Utils.g().pMul(s).pAdd(y.pMul(c.gNeg()));
        uint256 challenge = uint256(keccak256(abi.encode(address(this), y, K))).gMod();
        require(challenge == c, "Invalid registration signature!");
        bytes32 yHash = keccak256(abi.encode(y));
        require(!registered(yHash), "Account already registered!");

        pending[yHash][0] = y;
        pending[yHash][1] = Utils.g();

        users_log = users_log + 1;
    }

    function registered(bytes32 yHash) public view returns (bool) {
        Utils.G1Point memory zero = Utils.G1Point(0, 0);
        Utils.G1Point[2][2] memory scratch = [acc[yHash], pending[yHash]];
        return !(scratch[0][0].pEqual(zero) && scratch[0][1].pEqual(zero) && scratch[1][0].pEqual(zero) && scratch[1][1].pEqual(zero));
    }
    function getBalance(Utils.G1Point[] memory y, uint256 round) view public returns (Utils.G1Point[2][] memory accounts) {
        uint256 size = y.length;
        accounts = new Utils.G1Point[2][](size);
        for (uint256 i = 0; i < size; i++) {
            bytes32 yHash = keccak256(abi.encode(y[i]));
            accounts[i] = acc[yHash];
            if (last_roll_over[yHash] < round) {
                Utils.G1Point[2] memory scratch = pending[yHash];
                accounts[i][0] = accounts[i][0].pAdd(scratch[0]);
                accounts[i][1] = accounts[i][1].pAdd(scratch[1]);
            }
        }
    }

    function getAccountState (Utils.G1Point memory y) public view returns (Utils.G1Point[2] memory y_available, Utils.G1Point[2] memory y_pending) {
        bytes32 yHash = keccak256(abi.encode(y));
        y_available = acc[yHash];
        y_pending = pending[yHash];
        return (y_available, y_pending);
    }

    function getGuess (Utils.G1Point memory y) public view returns (bytes memory y_guess) {
        bytes32 yHash = keccak256(abi.encode(y));
        y_guess = guess[yHash];
        return y_guess;
    }

}