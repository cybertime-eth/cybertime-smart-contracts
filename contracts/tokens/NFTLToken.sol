// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NFTLToken is ERC20 {

    address public farmingContract;
    address public owner;

    constructor(address _owner, uint256 _initialMintAmt) ERC20("CyberTime Finance Token", "CTF") {
        owner = _owner;
        _mint(_owner, _initialMintAmt);
    }

    // mint tokens
    function mint(address _to, uint256 _amt) public {
        require(farmingContract == msg.sender, "CTFToken: You are not authorised to mint");
        _mint(_to, _amt);
    }

    function addFarmingContract(address _farmingContractAddr) public {
        require(msg.sender == owner, "CTFToken: You're not owner");
        require(farmingContract == address(0), "Farming Contract Already Added");
        farmingContract = _farmingContractAddr;
   }
}