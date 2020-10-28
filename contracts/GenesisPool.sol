pragma solidity ^0.5.12;

import { Ownable } from "@openzeppelin/contracts/ownership/Ownable.sol";
import { IERC1155Tradable } from "./IERC1155Tradable.sol";
import "./TokenWrapper.sol";


contract GenesisPool is TokenWrapper, Ownable {
	IERC1155Tradable public _kanvaNft;

	mapping(address => uint256) public lastUpdateTime;
	mapping(address => uint256) public points;
	mapping(uint256 => uint256) public cards;

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

	constructor(
    IERC1155Tradable kanvaNft,
    IERC20 lpTokenAddress
  )
    public
    TokenWrapper(lpTokenAddress)
  {
		_kanvaNft = kanvaNft;
	}

	function addCard(uint256 cardId, uint256 amount) external onlyOwner {
		cards[cardId] = amount;

		emit CardAdded(cardId, amount);
	}

	function redeem(uint256 card) public updateReward(msg.sender) {
		require(cards[card] != 0, "redeem: Card not found!");
		require(points[msg.sender] >= cards[card], "redeem: Not enough points to redeem for card!");
		require(_kanvaNft.totalSupply(card) < _kanvaNft.maxSupply(card), "redeem: Max cards minted!");

		points[msg.sender] = points[msg.sender].sub(cards[card]);
		_kanvaNft.mint(msg.sender, card, 1, "");

		emit Redeemed(msg.sender, cards[card]);
	}

	// stake visibility is public as overriding TokenWrapper's stake() function
	function stake(uint256 amount) public updateReward(msg.sender) {
		require(amount.add(balanceOf(msg.sender)) <= 5 * 1e8, "stake: Cannot stake more than 5 kanva!");

		super.stake(amount);
		emit Staked(msg.sender, amount);
	}

	function withdraw(uint256 amount) public updateReward(msg.sender) {
		require(amount > 0, "withdraw: Cannot withdraw 0!");

		super.withdraw(amount);
		emit Withdrawn(msg.sender, amount);
	}

	function exit() public {
		withdraw(balanceOf(msg.sender));
	}

	function earned(address account) public view returns (uint256) {
		return points[account].add(
      block.timestamp.sub(lastUpdateTime[account]).mul(1e18).div(86400).mul(balanceOf(account).div(1e8))
    );
	}
}