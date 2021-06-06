// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Utils.sol";
import "./BeldexTransfer.sol";
import "./BeldexRedeem.sol";


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

    uint256 public redeem_fee_numerator = 1;
    uint256 public redeem_fee_denominator = 100;
    uint256 public transfer_fee_numerator = 1;
    uint256 public transfer_fee_denominator = 5;
    
    BeldexTransfer beldex_transfer;

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

    event TransferOccurred(Utils.G1Point[] parties); 
    event LogUint256(string label, uint256 indexed value);

    constructor(address _transfer,address _redeem, uint256 _unit) public {
        beldex_agency = msg.sender;
        beldex_transfer = BeldexTransfer(_transfer);
        beldex_redeem = BeldexRedeem(_redeem);
        unit = _unit;

    }

    function toUnitAmount(uint256 nativeAmount) internal view returns (uint256) {
        require(nativeAmount % unit == 0, "Native amount must be multiple of a unit.");
        uint256 amount = nativeAmount / unit;
        require(0 <= amount && amount <= MAX, "Amount out of range."); 
        return amount;
    }

    function toNativeAmount(uint256 unitAmount) internal view returns (uint256) {
        require(0 <= unitAmount && unitAmount <= MAX, "Amount out of range");
        return unitAmount * unit;
    }

    function setRedeemFeeStrategy(uint256 numerator, uint256 denominator) public {
        require(msg.sender == beldex_agency, "Permission denied: Only admin can change redeem fee strategy.");
        redeem_fee_numerator = numerator;
        redeem_fee_denominator = denominator;
    }

    function setTransferFeeStrategy(uint256 numerator, uint256 denominator) public {
        require(msg.sender == beldex_agency, "Permission denied: Only admin can change transfer fee strategy.");
        transfer_fee_numerator = numerator;
        transfer_fee_denominator = denominator;
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

    function rollOver(bytes32 yHash) internal {
        uint256 e = 0;
        if (round_base == 0)
            e = block.number / round_len;
        else if (round_base == 1)
            e = block.timestamp / round_len;
        else
            revert("Invalid round base.");

        if (last_roll_over[yHash] < e) {
            Utils.G1Point[2][2] memory scratch = [acc[yHash], pending[yHash]];
            acc[yHash][0] = scratch[0][0].pAdd(scratch[1][0]);
            acc[yHash][1] = scratch[0][1].pAdd(scratch[1][1]);
            delete pending[yHash];
            last_roll_over[yHash] = e;
        }
        if (last_global_update < e) {
            last_global_update = e;
            delete nonce_set;
        }
    }

    function mintBase(Utils.G1Point memory y, uint256 amount, bytes memory encGuess) internal {

        require(amount <= MAX && balance_log + amount <= MAX, "[Beldex mint] Mint pushes contract past maximum value.");
        balance_log += amount;
        deposits_log += amount;
        mint_count_log += 1;

        bytes32 yHash = keccak256(abi.encode(y));
        require(registered(yHash), "[Beldex mint] Account not yet registered.");
        rollOver(yHash);

        Utils.G1Point memory scratch = pending[yHash][0];
        scratch = scratch.pAdd(Utils.g().pMul(amount));
        pending[yHash][0] = scratch;

        guess[yHash] = encGuess;
    }

    function redeemBase(Utils.G1Point memory y, uint256 amount, Utils.G1Point memory u, bytes memory proof, bytes memory encGuess) internal {

        require(balance_log >= amount, "[Beldex redeem] Failed: Invalid redeem amount.");
        balance_log -= amount;
        

        bytes32 yHash = keccak256(abi.encode(y));
        require(registered(yHash), "[Beldex redeem] Account not yet registered.");
        rollOver(yHash);

        Utils.G1Point[2] memory scratch = pending[yHash];
        pending[yHash][0] = scratch[0].pAdd(Utils.g().pMul(amount.gNeg()));

        scratch = acc[yHash]; // simulate debit of acc---just for use in verification, won't be applied
        scratch[0] = scratch[0].pAdd(Utils.g().pMul(amount.gNeg()));
        bytes32 uHash = keccak256(abi.encode(u));
        for (uint256 i = 0; i < nonce_set.length; i++) {
            require(nonce_set[i] != uHash, "[Beldex redeem] Nonce already seen!");
        }
        nonce_set.push(uHash);

        guess[yHash] = encGuess;

        BeldexRedeem.Statement memory beldex_stm = beldex_redeem.wrapStatement(scratch[0], scratch[1], y, last_global_update, u, msg.sender);
        BeldexRedeem.Proof memory beldex_proof = beldex_redeem.unserialize(proof);

        require(beldex_redeem.verify(beldex_stm, beldex_proof), "[Beldex redeem] Failed: verification!");
    }

    function transfer(Utils.G1Point[] memory C, Utils.G1Point memory D, 
                      Utils.G1Point[] memory y, Utils.G1Point memory u, 
                      bytes memory proof) public payable {

        uint256 startGas = gasleft();

        // TODO: check that sender and receiver should NOT be equal.
        uint256 size = y.length;
        Utils.G1Point[] memory CLn = new Utils.G1Point[](size);
        Utils.G1Point[] memory CRn = new Utils.G1Point[](size);
        require(C.length == size, "[Beldex transfer] Input array length mismatch!");


        for (uint256 i = 0; i < size; i++) {
            bytes32 yHash = keccak256(abi.encode(y[i]));
            require(registered(yHash), "[Beldex transfer] Account not yet registered.");
            rollOver(yHash);
            Utils.G1Point[2] memory scratch = pending[yHash];
            pending[yHash][0] = scratch[0].pAdd(C[i]);
            pending[yHash][1] = scratch[1].pAdd(D);

            scratch = acc[yHash];
            CLn[i] = scratch[0].pAdd(C[i]);
            CRn[i] = scratch[1].pAdd(D);
        }

        bytes32 uHash = keccak256(abi.encode(u));
        for (uint256 i = 0; i < nonce_set.length; i++) {
            require(nonce_set[i] != uHash, "[Beldex transfer] Nonce already seen!");
        }
        nonce_set.push(uHash);

        BeldexTransfer.Statement memory beldex_stm = beldex_transfer.wrapStatement(CLn, CRn, C, D, y, last_global_update, u);
        BeldexTransfer.Proof memory beldex_proof = beldex_transfer.unserialize(proof);

        require(beldex_transfer.verify(beldex_stm, beldex_proof), "[Beldex transfer] Failed: verification");

        uint256 usedGas = startGas - gasleft();
        
        uint256 fee = (usedGas * transfer_fee_numerator / transfer_fee_denominator) * tx.gasprice;
        if (fee > 0) {
            require(msg.value >= fee, "[Beldex transfer] Not enough fee sent with the transfer transaction.");
            beldex_agency.transfer(fee);
            transfer_fee_log = transfer_fee_log + fee;
        }
        msg.sender.transfer(msg.value - fee);

        emit TransferOccurred(y);
    }

}