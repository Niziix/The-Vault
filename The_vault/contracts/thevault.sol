// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiCryptoVault {
    struct Deposit {
        uint256 amount;
        uint256 unlockTime;
        uint256 interestRate;
    }

    mapping(address => mapping(string => Deposit[])) public userDeposits;
    mapping(string => AggregatorV3Interface) public priceFeeds;
    mapping(string => address) public tokenAddresses;

    event Deposited(address indexed user, string crypto, uint256 amount, uint256 unlockTime, uint256 interestRate);
    event Withdrawn(address indexed user, string crypto, uint256 amount, uint256 interestEarned);

    constructor() {
        // Price Feeds (Chainlink)
        priceFeeds["AVAX"] = AggregatorV3Interface(0x0A77230d17318075983913bC2145DB16C7366156);
        priceFeeds["RLUSD"] = AggregatorV3Interface(0x0000000000000000000000000000000000000000); // Non spécifié
        priceFeeds["ETH"] = AggregatorV3Interface(0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419);
        priceFeeds["BTC"] = AggregatorV3Interface(0xf4030086522a5beea4988f8ca5b36dbc97bee88c);
        priceFeeds["BNB"] = AggregatorV3Interface(0x14e613ac84a31f709eadbdf89c6cc390fdc9540a);
        priceFeeds["SOL"] = AggregatorV3Interface(0x0000000000000000000000000000000000000000); // Non spécifié
        priceFeeds["ADA"] = AggregatorV3Interface(0x882554df528115a743c4537828da8d5b58e52544);
        priceFeeds["DOT"] = AggregatorV3Interface(0xacb51f1a83922632ca02b25a8164c10748001a7f);
        priceFeeds["MATIC"] = AggregatorV3Interface(0x7a8f80d1a7c4b5ebf0b1b1b1b1b1b1b1b1b1b1b1);
        priceFeeds["XRP"] = AggregatorV3Interface(0xced6b9b8a36c7d0d8a7b1b1b1b1b1b1b1b1b1b1b1);
        priceFeeds["DOGE"] = AggregatorV3Interface(0x3ab0a0d137d4f946fbb19eecc6e92e64660231c8);
        priceFeeds["LTC"] = AggregatorV3Interface(0x6f2c7f4d4c8b5e1b1b1b1b1b1b1b1b1b1b1b1b1b1);

        // Token Addresses (ERC-20)
        tokenAddresses["RLUSD"] = 0xCfd748B9De538c9f5b1805e8db9e1d4671f7F2ec;
        tokenAddresses["BTC"] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599; // WBTC
        tokenAddresses["BNB"] = 0xB8c77482e45F1F44dE1745F52C74426C631bDD52;
        tokenAddresses["SOL"] = 0x7D8c5F61d1bE2aE1d7bB2a3bF1b1c5b1b1b1b1b1; // Exemple fictif
        tokenAddresses["MATIC"] = 0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0;
    }

    function deposit(string memory crypto, uint256 amount, uint256 lockDuration) external payable {
        require(
            lockDuration == 1 days || lockDuration == 7 days || 
            lockDuration == 30 days || lockDuration == 365 days,
            "Invalid lock duration"
        );

        if (keccak256(abi.encodePacked(crypto)) == keccak256(abi.encodePacked("AVAX"))) {
            require(msg.value > 0, "Must send AVAX to deposit");
            amount = msg.value;
        } else {
            require(amount > 0, "Must send tokens to deposit");
            IERC20(tokenAddresses[crypto]).transferFrom(msg.sender, address(this), amount);
        }

        uint256 interestRate = getDynamicInterestRate(crypto, lockDuration);
        uint256 unlockTime = block.timestamp + lockDuration;

        userDeposits[msg.sender][crypto].push(Deposit(amount, unlockTime, interestRate));

        emit Deposited(msg.sender, crypto, amount, unlockTime, interestRate);
    }

    function withdraw(string memory crypto, uint256 index) external {
        require(index < userDeposits[msg.sender][crypto].length, "Invalid deposit index");
        Deposit storage userDeposit = userDeposits[msg.sender][crypto][index];
        require(block.timestamp >= userDeposit.unlockTime, "Funds are still locked");
        require(userDeposit.amount > 0, "No funds to withdraw");

        uint256 amount = userDeposit.amount;
        uint256 interest = (amount * userDeposit.interestRate) / 100;
        uint256 totalAmount = amount + interest;

        userDeposit.amount = 0; // Mark as withdrawn

        if (keccak256(abi.encodePacked(crypto)) == keccak256(abi.encodePacked("AVAX"))) {
            payable(msg.sender).transfer(totalAmount);
        } else {
            IERC20(tokenAddresses[crypto]).transfer(msg.sender, totalAmount);
        }

        emit Withdrawn(msg.sender, crypto, amount, interest);
    }

    function getDeposits(address user, string memory crypto) external view returns (Deposit[] memory) {
        return userDeposits[user][crypto];
    }

    function getDynamicInterestRate(string memory crypto, uint256 lockDuration) internal view returns (uint256) {
        (, int price, , , ) = priceFeeds[crypto].latestRoundData();
        require(price > 0, "Invalid price from oracle");

        uint256 baseRate = uint256(price) / 1000;

        if (lockDuration == 1 days) return baseRate / 5;
        if (lockDuration == 7 days) return baseRate / 3;
        if (lockDuration == 30 days) return baseRate / 2;
        if (lockDuration == 365 days) return baseRate;

        return 0;
    }
}
