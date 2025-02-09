const contractAddress = "TON_CONTRACT_ADDRESS"; // Remplace par l'adresse de ton contrat
const contractABI = [
    {
        "inputs": [
            { "internalType": "string", "name": "crypto", "type": "string" },
            { "internalType": "uint256", "name": "amount", "type": "uint256" },
            { "internalType": "uint256", "name": "lockDuration", "type": "uint256" }
        ],
        "name": "deposit",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "string", "name": "crypto", "type": "string" },
            { "internalType": "uint256", "name": "index", "type": "uint256" }
        ],
        "name": "withdraw",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            { "internalType": "address", "name": "user", "type": "address" },
            { "internalType": "string", "name": "crypto", "type": "string" }
        ],
        "name": "getDeposits",
        "outputs": [
            {
                "components": [
                    { "internalType": "uint256", "name": "amount", "type": "uint256" },
                    { "internalType": "uint256", "name": "unlockTime", "type": "uint256" },
                    { "internalType": "uint256", "name": "interestRate", "type": "uint256" }
                ],
                "internalType": "struct MultiCryptoVault.Deposit[]",
                "name": "",
                "type": "tuple[]"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
];

// Connecter Metamask
async function connectWallet() {
    if (window.ethereum) {
        try {
            await window.ethereum.request({ method: "eth_requestAccounts" });
            const provider = new ethers.providers.Web3Provider(window.ethereum);
            const signer = provider.getSigner();
            window.contract = new ethers.Contract(contractAddress, contractABI, signer);
            alert("Wallet connecté !");
        } catch (error) {
            console.error("Connexion échouée", error);
        }
    } else {
        alert("Installez Metamask !");
    }
}

// Déposer des cryptos
async function depositCrypto(duration) {
    if (!window.contract) return alert("Connecte ton wallet d'abord !");

    const amount = document.getElementById("crypto-amount").value;
    const crypto = document.getElementById("crypto-select").value;
    const lockDuration = getTimeInSeconds(duration);

    if (!amount || amount <= 0) return alert("Entrez un montant valide.");

    try {
        if (crypto === "AVAX") {
            const value = ethers.utils.parseEther(amount);
            let tx = await window.contract.deposit(crypto, 0, lockDuration, { value });
            await tx.wait();
        } else {
            const value = ethers.utils.parseUnits(amount, 18);
            let tx = await window.contract.deposit(crypto, value, lockDuration);
            await tx.wait();
        }
        alert("Dépôt réussi !");
    } catch (error) {
        console.error("Échec du dépôt", error);
    }
}

// Retirer les fonds après l’expiration du timer
async function withdrawCrypto(crypto, index) {
    if (!window.contract) return alert("Connecte ton wallet d'abord !");

    try {
        let tx = await window.contract.withdraw(crypto, index);
        await tx.wait();
        alert("Retrait réussi !");
    } catch (error) {
        console.error("Échec du retrait", error);
    }
}

// Récupérer les dépôts de l’utilisateur
async function getUserDeposits() {
    if (!window.contract) return alert("Connecte ton wallet d'abord !");

    try {
        const address = await window.ethereum.request({ method: "eth_accounts" });
        const crypto = document.getElementById("crypto-select").value;
        const deposits = await window.contract.getDeposits(address[0], crypto);

        const scoreboard = document.getElementById("scoreboard-list");
        scoreboard.innerHTML = "";

        deposits.forEach((deposit, index) => {
            const unlockDate = new Date(deposit.unlockTime * 1000);
            const listItem = document.createElement("li");
            listItem.innerHTML = `${deposit.amount / 1e18} ${crypto} - Déblocage le : ${unlockDate.toLocaleString()}`;
            const withdrawButton = document.createElement("button");
            withdrawButton.textContent = "Retirer";
            withdrawButton.onclick = () => withdrawCrypto(crypto, index);
            listItem.appendChild(withdrawButton);
            scoreboard.appendChild(listItem);
        });
    } catch (error) {
        console.error("Impossible de récupérer les dépôts", error);
    }
}

// Convertir la durée en secondes
function getTimeInSeconds(duration) {
    switch (duration) {
        case '1 day': return 1 * 24 * 60 * 60;
        case '1 week': return 7 * 24 * 60 * 60;
        case '1 month': return 30 * 24 * 60 * 60;
        case '1 year': return 365 * 24 * 60 * 60;
        default: return 0;
    }
}
