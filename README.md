# IdrisRaffle

## Overview
**IdrisRaffle** is a decentralized raffle smart contract built on **Ethereum**, leveraging **Chainlink VRF** for secure and verifiable randomness. This ensures that the raffle results are provably fair and tamper-proof. The contract allows participants to enter by paying a specified entrance fee, and a winner is selected at random after certain conditions are met.

## Key Features
- **Fair Randomness**: Utilizes **Chainlink VRF (Verifiable Random Function)** for an unbiased winner selection process.
- **Automation-Ready**: Supports upkeep checks to determine when it's time to draw a winner.
- **Robust Security**: Implements best practices such as the **Checks-Effects-Interactions (CEI)** pattern to prevent re-entrancy attacks.
- **Efficient State Management**: Uses an enumerated **RaffleState** to handle open and calculating states.

## Technologies Used
- **Solidity 0.8.28**
- **Chainlink VRF (V2 Plus)**
- **Brownie Framework**

## Contract Layout
The contract follows Solidity best practices:

1. **Version Declaration**  
2. **Imports** (Chainlink libraries)
3. **Custom Errors**
4. **Type Declarations** (RaffleState enum)
5. **State Variables** (Immutable and mutable variables)
6. **Events** (Logging crucial actions)
7. **Modifiers** (None currently)
8. **Functions**
   - **Constructor**: Initializes state variables
   - **External Functions**: `enterRaffle()` for participation
   - **Public Functions**: `checkUpkeep()` and `performUpkeep()` for upkeep automation
   - **Internal Functions**: `fulfillRandomWords()` for random number consumption
   - **View Functions**: Getters for key variables

## How It Works
1. **Entering the Raffle**: Users enter the raffle by sending **ETH** greater than or equal to the `i_entranceFee`.
2. **Automated Upkeep**: `checkUpkeep()` checks if enough time has passed, there are enough participants, and the contract has sufficient balance.
3. **Winner Selection**: Once conditions are met, `performUpkeep()` requests a random number from Chainlink VRF.
4. **Randomness Fulfillment**: The winner is selected via `fulfillRandomWords()` and the entire balance is sent to the winner.

## Custom Errors
- `raffle__SendMoreToEnterRaffle()` — Thrown when insufficient ETH is sent.
- `raffle__TransferFailed()` — Thrown when sending ETH to the winner fails.
- `raffle__RaffleNotOpen()` — Thrown when trying to enter while raffle is calculating.
- `raffle__UpKeepNotNeeded()` — Thrown when upkeep conditions are not met.

## Events
- `raffleEntered(address indexed participant)` — Emitted when a user enters the raffle.
- `WinnerPicked(address indexed winner)` — Emitted when a winner is selected.
- `RequstedRaffleWinner(uint256 indexed requestId)` — Emitted when a random number request is made.

## Deployment
To deploy this contract, you will need to provide:
- **Entrance Fee**: Minimum amount required to participate.
- **Interval**: Time interval for upkeep checks.
- **VRF Coordinator**: Address of the Chainlink VRF Coordinator.
- **Gas Lane**: Specific gas lane key for randomness requests.
- **Subscription ID**: Chainlink subscription ID for funding requests.
- **Callback Gas Limit**: Gas limit for the randomness callback.

## Security Considerations
- **Re-entrancy Protection**: Adheres to the **Checks-Effects-Interactions** (CEI) pattern.
- **Immutable Variables**: Critical variables marked as immutable to reduce gas costs.
- **Proper Error Handling**: Uses custom errors instead of `require` to save gas.

## Getters and State Insights
- `getEntranceFee()` — Returns the required entrance fee.
- `getRaffleState()` — Returns the current state of the raffle.
- `getPlayer(uint256)` — Returns the address of a specific participant.
- `getLastTimeStamp()` — Returns the last upkeep timestamp.
- `getRecentWinner()` — Returns the most recent raffle winner.

## Conclusion
**IdrisRaffle** is designed for transparency, fairness, and automation. By integrating Chainlink VRF, it ensures that the raffle process is completely verifiable and secure. Feel free to explore and contribute!

