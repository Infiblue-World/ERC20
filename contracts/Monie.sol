// contracts/MinieToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Lock.sol";

contract MonieToken is ERC20 {
    Lock public lock;
    address[] public signers;

    constructor(uint256 initialSupply, address _lock)
        ERC20("$INFIBLUE WORLD", "$MONIE")
    {
        lock = Lock(_lock);
        _mint(msg.sender, initialSupply);
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address sender = msg.sender;
        uint256 current_locked = lock.check_lock(sender).current_locked;
        if (block.timestamp <= 1725174000 && current_locked > 0) {
            uint256 balance = balanceOf(sender);
            require(balance - amount >= current_locked);
        }
        _transfer(sender, to, amount);
        return true;
    }
}