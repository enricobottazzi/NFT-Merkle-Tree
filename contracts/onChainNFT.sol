
   
//__/\\\\\\\\\\\\\\\_________________________________________________________________________________/\\\\\\\\\______/\\\\\\\\\\\\____
// _\/\\\///////////________________________________________________________________________________/\\\///////\\\___\/\\\////////\\\__
//___\/\\\_____________________________/\\\\\\\\___/\\\_____________________________________________\/\\\_____\/\\\___\/\\\______\//\\\_
//____\/\\\\\\\\\\\______/\\/\\\\\\____/\\\////\\\_\///___/\\/\\\\\\_______/\\\\\\\\______/\\\\\\\\__\/\\\\\\\\\\\/____\/\\\_______\/\\\_
//_____\/\\\///////______\/\\\////\\\__\//\\\\\\\\\__/\\\_\/\\\////\\\____/\\\/////\\\___/\\\/////\\\_\/\\\//////\\\____\/\\\_______\/\\\_
//______\/\\\_____________\/\\\__\//\\\__\///////\\\_\/\\\_\/\\\__\//\\\__/\\\\\\\\\\\___/\\\\\\\\\\\__\/\\\____\//\\\___\/\\\_______\/\\\_
//_______\/\\\_____________\/\\\___\/\\\__/\\_____\\\_\/\\\_\/\\\___\/\\\_\//\\///////___\//\\///////___\/\\\_____\//\\\__\/\\\_______/\\\__
//________\/\\\\\\\\\\\\\\\_\/\\\___\/\\\_\//\\\\\\\\__\/\\\_\/\\\___\/\\\__\//\\\\\\\\\\__\//\\\\\\\\\\_\/\\\______\//\\\_\/\\\\\\\\\\\\/___
//_________\///////////////__\///____\///___\////////___\///__\///____\///____\//////////____\//////////__\///________\///__\////////////_____
//______________________________________________________________________________________________________________________parker@engineerd.io____
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";
import "./DynamicMerkleTree.sol";

contract onChainNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    mapping(uint256 => Word) public wordsToTokenId;
    
    struct TreeNode {
        address sender;
        address receiver;
        uint256 tokenId;
        string tokenURI;
    }

    uint256 public stringLimit = 45;
    uint256 public len; // this uint represents the number of commitments inside the merkle tree
    bytes32 public rootHash; // this represents the hash of the merkle tree

    struct Word {
        string name;
        string description;
        string bgHue;
        string textHue;
    }

    constructor() ERC721("onChainNFT", "OCNFT") {
    }

    function mint(string memory _nftName, string memory _nftDescription, address _receiver, bytes32[] memory proof) public payable onlyOwner {
        uint256 supply = totalSupply();
        bytes memory strBytes = bytes(_nftName);
        require(strBytes.length <= stringLimit, "String input exceeds limit.");
        require(nameExists(_nftName) != true, "Name already exists!");

        Word memory newWord = Word(
            _nftName,
            _nftDescription,
            randomNum(361, block.difficulty, supply).toString(),
            randomNum(361, block.timestamp, supply).toString()
        );

        if (msg.sender != owner()) {
            require(msg.value >= 0.005 ether);
        }

        wordsToTokenId[supply + 1] = newWord; // Add word to mapping @tokenId
        _safeMint(_receiver, supply + 1);

        TreeNode memory node = TreeNode({sender: msg.sender, receiver: _receiver, tokenId: supply + 1, tokenURI: tokenURI(1)});

        rootHash = DynamicMerkleTree.append(
                len,
                rootHash,
                keccak256(abi.encode(node)),
                proof
            );
        len = len + 1;
    }

    function _verify (
        uint256 _idx,
        uint256 _len,
        bytes32 _root,
        bytes32 _leafHash,
        bytes32[] memory _proof
    ) public pure returns (bool) {

        return DynamicMerkleTree.verify(_idx,_len, _root, _leafHash, _proof);
    }


    function nameExists(string memory _name) public view returns (bool) {
        bool result = false;
        //totalSupply function starts at 1, as does out wordToTokenId mapping
        for (uint256 i = 1; i <= totalSupply(); i++) {
            string memory text = wordsToTokenId[i].name;
            if (
                keccak256(abi.encodePacked(text)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                result = true;
            }
        }
        return result;
    }

    function randomNum(
        uint256 _mod,
        uint256 _seed,
        uint256 _salt
    ) public view returns (uint256) {
        uint256 num = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, _seed, _salt)
            )
        ) % _mod;
        return num;
    }

    function buildImage(uint256 _tokenId) private view returns (string memory) {
        Word memory currentWord = wordsToTokenId[_tokenId];
        string memory random = randomNum(361, 3, 3).toString();
        return
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg">',
                        '<rect id="svg_11" height="600" width="503" y="0" x="0" fill="hsl(',
                        currentWord.bgHue,
                        ',50%,25%)"/>',
                        '<text font-size="18" y="10%" x="80%" fill="hsl(',
                        random,
                        ',100%,80%)">Token: ',
                        _tokenId.toString(),
                        "</text>",
                        '<text font-size="18" y="50%" x="50%" text-anchor="middle" fill="hsl(',
                        random,
                        ',100%,80%)"> NFT Name: ',
                        currentWord.name,
                        'NFT Description: ',
                        currentWord.description,
                        "</text>",
                        "</svg>"
                    )
                )
            );
    }

    function buildMetadata(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        Word memory currentWord = wordsToTokenId[_tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                currentWord.name,
                                '", "description":"',
                                currentWord.description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                buildImage(_tokenId),
                                '", "attributes": ',
                                "[",
                                '{"trait_type": "TextColor",',
                                '"value":"',
                                currentWord.textHue,
                                '"}',
                                "]",
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return buildMetadata(_tokenId);
    }

    //only owner
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function _hash(address _from, address _to, uint256 _tokenId)
    internal view returns (bytes32)
    {
        string memory _tokenURI = tokenURI(_tokenId);
        return keccak256(abi.encodePacked(_from, _to, _tokenId, _tokenURI));
    }





}