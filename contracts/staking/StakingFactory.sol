pragma solidity ^0.5.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/ownership/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { StakingRewards } from "./StakingRewards.sol";
import { PaletteRewards } from "./PaletteRewards.sol";


contract StakingFactory is Ownable {
  using SafeERC20 for IERC20;

  uint256 public stakingRewardsGenesis;

  // immutables
  address public rewardsToken;

  // the staking tokens for which the rewards contract has been deployed
  address[] public stakingTokens;

  // info about rewards for a particular staking token
  struct StakingRewardsInfo {
    address stakingRewards;
    uint256 rewardAmount;
  }

  // rewards info by staking token
  mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingToken;

  constructor(
    address _rewardsToken,
    uint256 _stakingRewardsGenesis
  ) Ownable() public {
    require(_stakingRewardsGenesis >= block.timestamp, 'constructor: genesis too soon');

    rewardsToken = _rewardsToken;
    stakingRewardsGenesis = _stakingRewardsGenesis;
  }

  ///// permissioned functions

  // deploy a staking reward contract for the staking token, and store the reward amount
  // the reward will be distributed to the staking reward contract no sooner than the genesis
  function deploy(address stakingToken, uint256 rewardAmount) public onlyOwner {
    StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
    require(info.stakingRewards == address(0) || info.rewardAmount == 0, 'deploy: already deployed or not finished!');

    info.stakingRewards = address(new StakingRewards(address(this), rewardsToken, stakingToken));
    info.rewardAmount = rewardAmount;

    stakingTokens.push(stakingToken);
  }

  function deployKnv(address kanvaNft, address stakingToken, uint256 rewardAmount) public onlyOwner {
    StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
    require(info.stakingRewards == address(0) || info.rewardAmount == 0, 'deployKnv: already deployed or not finished!');

    // Deploy genesis pool and transfer its ownership to the main owner address
    PaletteRewards genPool = new PaletteRewards(kanvaNft, address(this), rewardsToken, stakingToken);
    genPool.transferOwnership(msg.sender);

    info.stakingRewards = address(genPool);
    info.rewardAmount = rewardAmount;

    stakingTokens.push(stakingToken);
  }

  ///// permissionless functions

  // call notifyRewardAmount for all staking tokens.
  function notifyRewardAmounts() public {
    require(stakingTokens.length > 0, 'notifyRewardAmounts: called before any deploys');

    for (uint256 i = 0; i < stakingTokens.length; i++) {
      notifyRewardAmount(stakingTokens[i]);
    }
  }

  // notify reward amount for an individual staking token.
  // this is a fallback in case the notifyRewardAmounts costs too much gas to call for all contracts
  function notifyRewardAmount(address stakingToken) public {
    require(block.timestamp >= stakingRewardsGenesis, 'notifyRewardAmount: not ready');

    StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
    require(info.stakingRewards != address(0), 'notifyRewardAmount: not deployed');

    if (info.rewardAmount > 0) {
      uint256 rewardAmount = info.rewardAmount;
      info.rewardAmount = 0;

      IERC20(rewardsToken).safeTransfer(info.stakingRewards, rewardAmount);
      StakingRewards(info.stakingRewards).notifyRewardAmount(rewardAmount);
    }
  }
}