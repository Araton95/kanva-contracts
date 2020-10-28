pragma solidity ^0.5.12;

interface IERC1155Tradable {
  function totalSupply(uint256 _id) external view returns (uint256);
  function maxSupply(uint256 _id) external view returns (uint256);
  function mint(address _to, uint256 _id, uint256 _quantity, bytes calldata _data) external;
}