pragma solidity ^0.5.12;

import { Ownable } from "@openzeppelin/contracts/ownership/Ownable.sol";
import { IERC1155Tradable } from "./IERC1155Tradable.sol";
import "./TokenWrapper.sol";


contract GenesisPool is TokenWrapper, Ownable {
	IERC1155Tradable public _kanvaNft;

  uint256 public constant MIN_STAKE = 0.5 ether;
  uint256 public constant MAX_STAKE = 5 ether;

	mapping(uint256 => uint256) public cards;
	mapping(address => uint256) public points;
	mapping(address => uint256) public lastUpdateTime;

	event CardAdded(uint256 card, uint256 points);
	event Staked(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event Redeemed(address indexed user, uint256 amount);

	modifier updateReward(address account) {
		if (account != address(0)) {
			points[account] = earned(account);
			lastUpdateTime[account] = block.timestamp;
		}
		_;
	}

	constructor(IERC1155Tradable kanvaNft, IERC20 lpTokenAddress) public TokenWrapper(lpTokenAddress) {
		_kanvaNft = kanvaNft;
	}

	function addCard(uint256 cardId, uint256 amount) external onlyOwner {
		cards[cardId] = amount;

		emit CardAdded(cardId, amount);
	}

	function redeem(uint256 card) public updateReward(_msgSender()) {
		require(cards[card] != 0, "redeem: Card not found!");
		require(points[_msgSender()] >= cards[card], "redeem: Not enough points to redeem for card!");
		require(_kanvaNft.totalSupply(card) < _kanvaNft.maxSupply(card), "redeem: Max cards minted!");

		points[_msgSender()] = points[_msgSender()].sub(cards[card]);
		_kanvaNft.mint(_msgSender(), card, 1, "");

		emit Redeemed(_msgSender(), cards[card]);
	}

	// stake visibility is public as overriding TokenWrapper's stake() function
	function stake(uint256 amount) public updateReward(_msgSender()) {
    require(amount >= MIN_STAKE, "stake: Cannot stake less than provided min amount!");
		require(amount.add(balanceOf(_msgSender())) <= MAX_STAKE, "stake: Cannot stake more than provided max amount!");

		super.stake(amount);
		emit Staked(_msgSender(), amount);
	}

	function withdraw(uint256 amount) public updateReward(_msgSender()) {
		require(amount > 0, "withdraw: Cannot withdraw 0!");

		super.withdraw(amount);
		emit Withdrawn(_msgSender(), amount);
	}

	function exit() public {
		withdraw(balanceOf(_msgSender()));
	}

	function earned(address account) public view returns (uint256) {
		return points[account].add(
      block.timestamp.sub(lastUpdateTime[account]).mul(1 ether).div(86400).mul(balanceOf(account).div(1 ether))
    );
	}
}