// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title An ERC20 Token "Burner"
/// @author @Keyrxng
/// @notice for testnet purpopes in burning test tokens
contract Burner is Ownable {

    address dead = 0x000000000000000000000000000000000000dEaD;

    uint public tokenSetsDestroyed;
    mapping(address => uint) public usersUsageCount;

    constructor() {}

    /// @notice sends all supply tokens to the "dead" address, tracks individual usage as well as individual token sets destroyed
    /// @param _tokens array of deployed ERC20 addresses
    function batchBurn(address[] calldata _tokens) public {
        require(_tokens.length != 0, "length is nil");

        for(uint x = 0; x < _tokens.length; x++){
            uint bal = fetchBal(_tokens[x]);
            require(bal != 0, "nil bal");
            IERC20(_tokens[x]).transferFrom(msg.sender, dead, bal);
        }
        usersUsageCount[msg.sender]++;
        tokenSetsDestroyed++;
    }

    /// @notice returns the token balance of a given address
    /// @param _token address of deployed ERC20 token
    function fetchBal(address _token) internal view returns(uint){
        return IERC20(_token).balanceOf(msg.sender);
    }

    /// @notice allows owner to withdraw any ETH accidentally sent to the contract
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}

