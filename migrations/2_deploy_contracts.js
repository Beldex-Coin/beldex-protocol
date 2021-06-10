var Utils = artifacts.require("Utils");
var BeldexIP = artifacts.require("BeldexIP");
var BeldexRedeem = artifacts.require("BeldexRedeem");
var BeldexTransfer = artifacts.require("BeldexTransfer");
var BeldexETH = artifacts.require("BeldexETH");

module.exports = function(deployer) {

    console.log("Deploying Utils, TestBeldexToken, BeldexIP...");
    return Promise.all([
        deployer.deploy(Utils),
        deployer.deploy(BeldexIP)
    ])
    .then(() => {
        console.log("Deploying BeldexRedeem, BeldexTransfer...");
        return Promise.all([
            deployer.deploy(BeldexRedeem, BeldexIP.address),
            deployer.deploy(BeldexTransfer, BeldexIP.address)
        ]);
    })
    .then(() => {
        console.log("Deploying BeldexETH");
        return Promise.all([
            deployer.deploy(BeldexETH, BeldexTransfer.address, BeldexRedeem.address, "10000000000000000"),
        ]);
    });
};
