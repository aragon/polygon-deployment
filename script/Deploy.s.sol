// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {DelegateRegistry} from "../src/DelegateRegistry.sol";
import {ERC20VotesWrapper} from "../src/ERC20VotesWrapper.sol";

contract Deploy is Script {
    DelegateRegistry public delegateRegistry;
    ERC20VotesWrapper public erc20VotesWrapper;

    function setUp() public {}

    modifier broadcast() {
        uint256 privKey = vm.envUint("DEPLOYMENT_PRIVATE_KEY");
        vm.startBroadcast(privKey);
        console.log("Deploying from:", vm.addr(privKey));

        _;

        vm.stopBroadcast();
    }

    function run() public broadcast {
        delegateRegistry = new DelegateRegistry();
        console.log("Delegate registry", address(delegateRegistry));


        address stakeManager = vm.envAddress("STAKE_MANAGER");
        erc20VotesWrapper = new ERC20VotesWrapper(stakeManager);
        console.log("ERC20 Votes wrapper", address(erc20VotesWrapper));
    }
}
