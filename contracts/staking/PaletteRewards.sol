pragma solidity ^0.5.12;

import { Ownable } from "@openzeppelin/contracts/ownership/Ownable.sol";

import { IKanvaLTD } from "../kanva/IKanvaLTD.sol";
import { StakingRewards } from "./StakingRewards.sol";


contract PaletteRewards is StakingRewards, Ownable {
	IKanvaLTD public _kanvaNft;

  uint256 public constant MIN_STAKE = 0.5 ether;
  uint256 public constant MAX_STAKE = 5 ether;

	mapping(uint256 => uint256) public cards;
	mapping(address => uint256) public pallettes;
  mapping(address => uint256) public stakedBalance;
	mapping(address => uint256) public palletteLastUpdateTime;

	event CardAdded(uint256 card, uint256 points);
	event Redeemed(address indexed user, uint256 amount);

	modifier updatePalletteReward(address account) {
		if (account != address(0)) {
			pallettes[account] = earned(account);
			palletteLastUpdateTime[account] = block.timestamp;
		}
		_;
	}

	constructor(
    address kanvaNft,
    address _rewardsDistribution,
    address _rewardsToken,
    address _stakingToken
  ) public StakingRewards(_rewardsDistribution, _rewardsToken, _stakingToken) {
		_kanvaNft = IKanvaLTD(kanvaNft);
	}

	function addCard(uint256 cardId, uint256 amount) external onlyOwner {
		cards[cardId] = amount;

		emit CardAdded(cardId, amount);
	}

	function redeem(uint256 card) public updatePalletteReward(msg.sender) {
		require(cards[card] != 0, "redeem: Card not found!");
		require(pallettes[_msgSender()] >= cards[card], "redeem: Not enough points to redeem for card!");
		require(_kanvaNft.totalSupply(card) < _kanvaNft.maxSupply(card), "redeem: Max cards minted!");

		pallettes[_msgSender()] = pallettes[_msgSender()].sub(cards[card]);
		_kanvaNft.mint(_msgSender(), card, 1, "");

		emit Redeemed(_msgSender(), cards[card]);
	}

	function stake(uint256 amount) public updatePalletteReward(msg.sender) {
    // Stake for PLTE reward
    if (amount >= MIN_STAKE && amount.add(stakedBalance[msg.sender]) <= MAX_STAKE) {
      stakedBalance[msg.sender] = stakedBalance[msg.sender].add(amount);
    }

    // Resume staking for KNV reward
		super.stake(amount);
	}

	function palletteEarned(address account) public view returns (uint256) {
		return pallettes[account].add(
      block.timestamp.sub(palletteLastUpdateTime[account])
      .mul(1 ether)
      .div(86400)
      .mul(
        stakedBalance[account]
        .div(1 ether)
      )
    );
	}
}