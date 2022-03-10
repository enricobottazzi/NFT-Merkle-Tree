const hre = require("hardhat");
/**
 * Deploys a test set of contracts: ERC721, Base64.sol, PrivateAirdrop
 */
async function main() {

    // HERE I NEED TO DEPLOY the library 
    let MerkleTreeFactory = await hre.ethers.getContractFactory("DynamicMerkleTree")
    let MerkleTreeContract = await MerkleTreeFactory.deploy()

    
    // HERE I NEED TO DEPLOY MY ERC721 contract 
    let NFTFactory = await hre.ethers.getContractFactory("onChainNFT", {
        libraries: {
            DynamicMerkleTree : MerkleTreeContract.address,
        }
    });
    
    let NFT = await NFTFactory.deploy()
    console.log(`ERC721 address: ${NFT.address}`)
}

main()
    .then(() => process.exit(0))
    .catch(e => {
        console.error(e);
        process.exit(1);
    })