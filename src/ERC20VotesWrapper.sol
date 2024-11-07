// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStakeManager {
    // validator replacement
    function startAuction(
        uint256 validatorId,
        uint256 amount,
        bool acceptDelegation,
        bytes calldata signerPubkey
    ) external;

    function currentValidatorSetSize() external view returns (uint256);

    function getValidatorContract(
        uint256 validatorId
    ) external view returns (address);

    function confirmAuctionBid(
        uint256 validatorId,
        uint256 heimdallFee
    ) external;

    function transferFunds(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external returns (bool);

    function transferFundsPOL(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external returns (bool);

    function delegationDeposit(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external returns (bool);

    function delegationDepositPOL(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external returns (bool);

    function unstake(uint256 validatorId) external;

    function unstakePOL(uint256 validatorId) external;

    function totalStakedFor(address addr) external view returns (uint256);

    function stakeFor(
        address user,
        uint256 amount,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes memory signerPubkey
    ) external;

    function updateValidatorState(uint256 validatorId, int256 amount) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function validatorStake(
        uint256 validatorId
    ) external view returns (uint256);

    function epoch() external view returns (uint256);

    function getRegistry() external view returns (address);

    function withdrawalDelay() external view returns (uint256);

    function delegatedAmount(
        uint256 validatorId
    ) external view returns (uint256);

    function decreaseValidatorDelegatedAmount(
        uint256 validatorId,
        uint256 amount
    ) external;

    function withdrawDelegatorsReward(
        uint256 validatorId
    ) external returns (uint256);

    function delegatorsReward(
        uint256 validatorId
    ) external view returns (uint256);

    function dethroneAndStake(
        address auctionUser,
        uint256 heimdallFee,
        uint256 validatorId,
        uint256 auctionAmount,
        bool acceptDelegation,
        bytes calldata signerPubkey
    ) external;

    function NFTCounter() external view returns (uint256);

    enum Status {
        Inactive,
        Active,
        Locked,
        Unstaked
    }

    struct Validator {
        uint256 amount;
        uint256 reward;
        uint256 activationEpoch;
        uint256 deactivationEpoch;
        uint256 jailTime;
        address signer;
        address contractAddress;
        Status status;
        uint256 commissionRate;
        uint256 lastCommissionUpdate;
        uint256 delegatorsReward;
        uint256 delegatedAmount;
        uint256 initialRewardPerStake;
    }

    function validators(uint256) external view returns (Validator memory);
}

// note this contract interface is only for stakeManager use
interface IValidatorShare {
    function withdrawRewards() external;

    function unstakeClaimTokens() external;

    function getLiquidRewards(address user) external view returns (uint256);

    function owner() external view returns (address);

    function restake() external returns (uint256, uint256);

    function unlock() external;

    function lock() external;

    function getTotalStake(
        address user
    ) external view returns (uint256, uint256);

    function drain(
        address token,
        address payable destination,
        uint256 amount
    ) external;

    function slash(
        uint256 valPow,
        uint256 delegatedAmount,
        uint256 totalAmountToSlash
    ) external returns (uint256);

    function updateDelegation(bool delegation) external;

    function migrateOut(address user, uint256 amount) external;

    function migrateIn(address user, uint256 amount) external;
}

contract ERC20VotesWrapper {
    IStakeManager immutable stakeManager;

    constructor(address stakeManager_) payable {
        stakeManager = IStakeManager(stakeManager_);
    }

    function getTotalActiveStake(address user) public view returns (uint256) {
        uint256 totalStakingPower = 0;
        uint256 numValidators = stakeManager.NFTCounter();
        uint256 currentEpoch = stakeManager.epoch();

        for (uint256 i = 0; i < numValidators; i++) {
            // (,,,uint256 deactivationEpoch,,,address contractAddress,,,,,,) = stakeManager.validators(i);
            IStakeManager.Validator memory validator = stakeManager.validators(
                i
            );
            if (
                validator.contractAddress != address(0) &&
                (validator.deactivationEpoch == 0 ||
                    validator.deactivationEpoch > currentEpoch)
            ) {
                (uint256 userStake, ) = IValidatorShare(
                    validator.contractAddress
                ).getTotalStake(user);
                totalStakingPower += userStake;
            }
        }
        return totalStakingPower;
    }
}
