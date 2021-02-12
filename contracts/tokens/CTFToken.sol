// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CyberTimeFinanceToken is ERC20 {

    // list of addresses which can mint CFT Tokens
    mapping (address => bool) public minters; 

    // owner of the contract
    address public owner;

    // Modifiers
    modifier onlyOwner() {
        require(isOwner(), "CTF: caller is not the owner");
        _;
    }

    constructor(address _owner) ERC20("CyberTime Finance Token", "CTF") {
        // set owner
        owner = _owner;
    }

    // mint tokens
    function mint(address _to, uint256 _amt) external {
        require(minters[msg.sender] == true, "CTF: Invalid Minter");
        _mint(_to, _amt);
    }

    /** 
        Admin Functionalities
    */

    // Admin can add new minter
    function addMinter(address _newMinter) public onlyOwner {
        minters[_newMinter] = true;
    }

    // Admin can remove minter
    function removeMinter(address _minter) public onlyOwner {
        minters[_minter] = false;
    }

    // Checks if sender is owner
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    // Changes owner
    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}