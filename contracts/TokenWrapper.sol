pragma solidity ^0.5.12;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract TokenWrapper {
	using SafeMath for uint256;
  using SafeERC20 for IERC20;

	IERC20 private _lpToken;
	uint256 private _totalSupply;

	mapping(address => uint256) private _balances;

	constructor(IERC20 lpTokenAddress) public {
		_lpToken = lpTokenAddress;
	}

	function stake(uint256 amount) public {
		_lpToken.safeTransferFrom(msg.sender, address(this), amount);

		_totalSupply = _totalSupply.add(amount);
		_balances[msg.sender] = _balances[msg.sender].add(amount);
	}

	function withdraw(uint256 amount) public {
		_lpToken.safeTransfer(msg.sender, amount);

		_totalSupply = _totalSupply.sub(amount);
		_balances[msg.sender] = _balances[msg.sender].sub(amount);
	}

  function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}

  function lpToken() public view returns (address) {
    return address(_lpToken);
  }
}