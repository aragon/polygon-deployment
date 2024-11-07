# Polygon Contracts deployment

## Setup

To get started, ensure that [Foundry](https://getfoundry.sh/) is installed on your computer.

<details>
  <summary>Also make sure to install [GNU Make](https://www.gnu.org/software/make/).</summary>
  
  ```sh
  # debian
  sudo apt install build-essential

  # arch
  sudo pacman -S base-devel

  # nix
  nix-env -iA nixpkgs.gnumake

  # macOS
  brew install make
  ```

</details>

### Using the Makefile

The `Makefile` as the target launcher of the project. It's the recommended way to work with it. It manages the env variables of common tasks and executes only the steps that require being run.

```
$ make 
Available targets:

- make init    Check the required tools and dependencies
- make clean   Clean the build artifacts

- make test            Run unit tests, locally
- make test-coverage   Generate an HTML coverage report under ./report

- make pre-deploy-mint-testnet   Simulate a deployment to the testnet, minting test token(s)
- make pre-deploy-testnet        Simulate a deployment to the testnet
- make pre-deploy-prodnet        Simulate a deployment to the production network

- make deploy-testnet        Deploy to the testnet and verify
- make deploy-prodnet        Deploy to the production network and verify
```

Run `make init`:
- It ensures that Foundry is installed
- It runs a first compilation of the project
- It copies `.env.example` into `.env` and `.env.test.example` into `.env.test`

Next, customize the values of `.env` and optionally `.env.test`.

### Understanding `.env.example`

The env.example file contains descriptions for all the initial settings. 

## Deployment

Deployments are done using the deployment factory. This is a singleton contract that will:

- Deploy all contracts
- Set permissions
- Transfer ownership to a freshly deployed multisig
- Store the addresses of the deployment in a single source of truth that can be queried at any time.

Check the available make targets to simulate and deploy the smart contracts:

```
- make pre-deploy-testnet    Simulate a deployment to the defined testnet
- make pre-deploy-prodnet    Simulate a deployment to the defined production network
- make deploy-testnet        Deploy to the defined testnet network and verify
- make deploy-prodnet        Deploy to the production network and verify
```

### Deployment Checklist

- [ ] I have cloned the official repository on my computer and I have checked out the corresponding branch
- [ ] I am using the latest official docker engine, running a Debian Linux (stable) image
  - [ ] I have run `docker run --rm -it -v .:/deployment debian:bookworm-slim`
  - [ ] I have run `apt update && apt install -y make curl git vim neovim bc`
  - [ ] I have run `curl -L https://foundry.paradigm.xyz | bash`
  - [ ] I have run `source /root/.bashrc && foundryup`
  - [ ] I have run `cd /deployment`
  - [ ] I have run `make init`
  - [ ] I have printed the contents of `.env` and `.env.test` on the screen
- [ ] I am opening an editor on the `/deployment` folder, within the Docker container
- [ ] The `.env` file contains the correct parameters for the deployment
  - [ ] I have created a brand new burner wallet with `cast wallet new` and copied the private key to `DEPLOYMENT_PRIVATE_KEY` within `.env`
  - [ ] I have reviewed the target network and RPC URL
  - [ ] I have checked that the JSON file under `MULTISIG_MEMBERS_JSON_FILE_NAME` contains the correct list of signers
  - [ ] I have ensured all multisig members have undergone a proper security review and are aware of the security implications of being on said multisig
  - [ ] I have checked that `MIN_APPROVALS` and `MULTISIG_PROPOSAL_EXPIRATION_PERIOD` are correct
  - [ ] I have verified that `TOKEN1_ADDRESS` corresponds to an ERC20 contract on the target chain (same for TOKEN2 if applicable)
  - [ ] I have checked that `VE_TOKEN1_NAME` and `VE_TOKEN1_SYMBOL` are correct (same for TOKEN2 if applicable)
  - I have checked that fee percent, warmup period, cooldown period, min lock duration, and min deposit:
    - [ ] Have the expected values
    - [ ] Cannot leave the voting contract or user tokens locked out
  - [ ] I have checked that `VOTING_PAUSED` is true, should voting not be active right away
  - [ ] The multisig plugin repo and version:
    - [ ] Correspond to the official contract on the target network
    - [ ] Point to the latest stable release available
  - The plugin ENS subdomain
    - [ ] Contains a meaningful and unique value
  - The given OSx addresses:
    - [ ] Exist on the target network
    - [ ] Contain the latest stable official version of the OSx DAO implementation, the Plugin Setup Processor and the Plugin Repo Factory
    - [ ] I have verified the values on https://www.npmjs.com/package/@aragon/osx-commons-configs?activeTab=code > `/@aragon/osx-commons-configs/dist/deployments/json/`
- [ ] I have updated the `CurveConstantLib` and `Clock` with any new constants.
- [ ] All my unit tests pass (`make test`)
- **Target test network**
  - [ ] I have deployed my contracts successfully to the target testnet
    - `make deploy-testnet`
  - [ ] I have updated `FACTORY_ADDRESS` on `.env.test` with the address of the deployed factory
  - If there is a live token with an address holding ≥ 3000 tokens on the testnet:
    - [ ] I have defined `TEST_TOKEN_WHALE` on `.env.test`
- **Target production network**
  - If the live token has an address holding ≥ 3000 tokens on the prodnet:
    - [ ] I have defined `TEST_TOKEN_WHALE` on `.env.test`
    - [ ] I have updated `TOKEN1_ADDRESS` to have the address of the testnet token deployed above
    - [ ] I have reverted `TOKEN1_ADDRESS` to the intended address of the token on the production network
- [ ] My deployment wallet is a newly created account, ready for safe production deploys.
- My computer:
  - [ ] Is running in a safe physical location and a trusted network
  - [ ] It exposes no services or ports
  - [ ] The wifi or wired network used does does not have open ports to a WAN
- [ ] I have previewed my deploy without any errors
  - `make pre-deploy-prodnet`
- [ ] My wallet has sufficient native token for gas
  - At least, 15% more than the estimated simulation
- [ ] Unit tests still run clean
- [ ] I have run `git status` and it reports no local changes
- [ ] The current local git branch corresponds to its counterpart on `origin`
  - [ ] I confirm that the rest of members of the ceremony pulled the last commit of my branch and reported the same commit hash as my output for `git log -n 1`
- [ ] I have initiated the production deployment with `make deploy-prodnet`

### Post deployment checklist

- [ ] The deployment process completed with no errors
- [ ] The deployed factory was deployed by the deployment address
- [ ] The reported contracts have been created created by the newly deployed factory
- [ ] The smart contracts are correctly verified on Etherscan or the corresponding block explorer
- [ ] The output of the latest `deployment-*.log` file corresponds to the console output
- [ ] I have transferred the remaining funds of the deployment wallet to the address that originally funded it
  - `make refund`

### Manual from the command line

You can of course run all commands from the command line:

```sh
# Load the env vars
source .env
```

```sh
# run unit tests
forge test --no-match-path "test/fork/**/*.sol"
```

```sh
# Set the right RPC URL
RPC_URL="https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}"
```

```sh
# Run the deployment script

# If using Etherscan
forge script --chain "$NETWORK" script/Deploy.s.sol:Deploy --rpc-url "$RPC_URL" --broadcast --verify

# If using BlockScout
forge script --chain "$NETWORK" script/Deploy.s.sol:Deploy --rpc-url "$RPC_URL" --broadcast --verify --verifier blockscout --verifier-url "https://sepolia.explorer.mode.network/api\?"
```

If you get the error Failed to get EIP-1559 fees, add `--legacy` to the command:

```sh
forge script --chain "$NETWORK" script/Deploy.s.sol:Deploy --rpc-url "$RPC_URL" --broadcast --verify --legacy
```

If some contracts fail to verify on Etherscan, retry with this command:

```sh
forge script --chain "$NETWORK" script/Deploy.s.sol:Deploy --rpc-url "$RPC_URL" --verify --legacy --private-key "$DEPLOYMENT_PRIVATE_KEY" --resume
```
