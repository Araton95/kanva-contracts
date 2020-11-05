pragma solidity ^0.5.12;

interface IKanvaLTD {
  function totalSupply(uint256 _id) external view returns (uint256);
  function mint(address _to, uint256 _id, uint256 _quantity, bytes calldata _data) external;
  function uri(uint256 _id) external view returns (string memory);
  function maxSupply(uint256 _id) external view returns (uint256);
  function contractURI() external view returns (string memory);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}