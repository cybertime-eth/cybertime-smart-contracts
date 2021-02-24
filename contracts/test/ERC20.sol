// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {

    // list of addresses which can mint CFT Tokens
    mapping (address => bool) public minters; 

    // owner of the contract
    address public owner;

    constructor(string memory _name, string memory _symbol, address _owner) ERC20(_name, _symbol) {
        // set owner
        owner = _owner;
        _mint(owner, 10000000 * (10**18));
    }

    function mint(address _to, uint256 _amt) public {
        _mint(_to, _amt);
    }
}