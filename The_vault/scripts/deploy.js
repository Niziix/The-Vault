async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Déploiement avec le compte :", deployer.address);

    const Vault = await ethers.getContractFactory("TheVault");
    const vault = await Vault.deploy();
    await vault.deployed();

    console.log("Vault déployé à :", vault.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
