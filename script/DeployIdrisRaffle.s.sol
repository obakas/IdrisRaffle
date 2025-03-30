// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {IdrisRaffle} from "../src/IdrisRaffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {CreateSubsription, FundSubscription, AddConsumer} from "../script/Interactions.s.sol";

contract DeployIdrisRaffle is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (IdrisRaffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubsription createSubsription = new CreateSubsription();
            (config.subscriptionId, config.vrfCoordinatorV2_5) =
                createSubsription.createSubscription(config.vrfCoordinatorV2_5, config.account);

            FundSubscription fundSubcription = new FundSubscription();
            fundSubcription.fundSubscription(config.vrfCoordinatorV2_5, config.subscriptionId, config.link, config.account);
        }

        vm.startBroadcast(config.account);
        IdrisRaffle raffle = new IdrisRaffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinatorV2_5,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinatorV2_5, config.subscriptionId, config.account);
        return (raffle, helperConfig);
    }
}
