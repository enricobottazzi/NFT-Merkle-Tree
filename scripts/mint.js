// Mint an NFT by choosing its name and description and append it to the merkle tree
const hre = require("hardhat");

async function main() {

    let ERC721_ADDR = "0x4c5859f0F772848b2D91F1D83E2Fe57935348029";
    let receiver = "0x9992847Cb19492673457f7f088Eb2d102F98aeCC"
    let NFT =  await hre.ethers.getContractAt("onChainNFT", ERC721_ADDR)
    let NFTName = "ZKUONE"
    let NFTDescription = "Test NFT for ZKU.one Week 1"
    proof = [NFT.rootHash()]
    await NFT.mint(NFTName, NFTDescription, receiver, proof);
    console.log(await NFT.tokenURI(1)); 
    console.log(await NFT.rootHash())
}

main().then(() => process.exit(0))
    .catch(e => {
        console.error(e);
        process.exit(-1);
    })