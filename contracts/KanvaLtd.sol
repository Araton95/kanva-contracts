pragma solidity ^0.5.12;

import { Ownable } from "@openzeppelin/contracts/ownership/Ownable.sol";
import { MinterRole } from "@openzeppelin/contracts/access/roles/MinterRole.sol";
import { WhitelistAdminRole } from "@openzeppelin/contracts/access/roles/WhitelistAdminRole.sol";
import { ERC1155Tradable } from "./ERC1155Tradable.sol";


/**
 * @title KanvaLtd
 * KanvaLtd - Collect limited edition NFTs from Kanva Ltd
 */
contract KanvaLtd is ERC1155Tradable {
  string private _contractUri;

	constructor(
    string memory contractUri,
    string memory metadataUri,
    address proxyRegistryAddress
  )
    public
    ERC1155Tradable("Kanva LTD.", "KANVA", proxyRegistryAddress)
  {
    _contractUri = contractUri;
		_setBaseMetadataURI(metadataUri);
	}

	function contractURI() public view returns (string memory) {
		return _contractUri;
	}
}