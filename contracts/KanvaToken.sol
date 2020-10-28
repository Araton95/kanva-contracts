pragma solidity ^0.5.12;

import { ERC20Detailed } from "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";


/**
 * @title Kanva Token
 * @dev Implementation of the Kanva Token
 */
contract KanvaToken is ERC20Detailed, ERC20Burnable {
    /**
     * @param receiver wallet who should receive all initial tokens
     */
    constructor(address receiver) public ERC20Detailed("Kanva", "KNV", 8) {
        _mint(receiver, 48_000 * 1e8);
    }
}