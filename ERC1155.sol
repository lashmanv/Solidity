// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract ArtCollectible is Ownable, ERC1155 {
    // Base URI
    string private baseURI;
    string public name;

    uint256 public lastMintedId =0;
    mapping(uint256 => mapping(uint => bool)) public chainIds;

    constructor()ERC1155("ipfs://QmbMFuZEBPyTkwySPHF2FRXnwhZUhR7EzVz9wkeqDe9uEi/{id}.json"){
        setName('Mandelbrot Julia Set Collection');
    }

    function setURI(string memory _newuri) public onlyOwner {
        _setURI(_newuri);
    }

    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts)public onlyOwner{
        _mintBatch(msg.sender, ids, amounts, '');
    }

    function mint(uint256 id, uint256 amount) public onlyOwner {
        require(id<=4);
        _mint(msg.sender,id,amount,'');
        chainIds[id][lastMintedId]=true;
        lastMintedId=id;
    }

    function uri(uint256 _tokenId) override public pure returns (string memory){
        return string(abi.encodePacked("https://gateway.pinata.cloud/ipfs/QmbMFuZEBPyTkwySPHF2FRXnwhZUhR7EzVz9wkeqDe9uEi/",Strings.toString(_tokenId),".json"));    
    }
}
