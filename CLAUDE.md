# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build contracts (Foundry)
forge build

# Run Solidity tests
forge test

# Run single test file
forge test --match-path test/OpenLotto.t.sol

# Run single test function
forge test --match-test testCreateLottery

# Run tests with verbosity (shows traces on failure)
forge test -vvv

# Lint Solidity
solhint src/**/*.sol

# Run TypeScript bindings tests
npm test

# Format Solidity code
forge fmt

# Build with ABI output (required for bindings)
forge build --extra-output-files abi
```

## Local Development

```bash
# Start local Anvil node
anvil

# Minimal deploy (requires LOTTERY_MANAGER_ADDR env var)
LOTTERY_MANAGER_ADDR=0x... forge script script/DeployOpenLotto.s.sol --tc DeployOpenLotto --rpc-url http://127.0.0.1:8545 --broadcast

# Deploy + seed N dummy lotteries (requires LOTTERY_MANAGER_PRIV_KEY and NUM_LOTTERIES)
LOTTERY_MANAGER_PRIV_KEY=0x... NUM_LOTTERIES=5 forge script script/DeployOpenLottoWithSampleData.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

Fresh clones need submodules: `git clone --recurse-submodules ...` (or `git submodule update --init --recursive`). Libraries in `lib/` are git submodules.

## Architecture

OpenLotto is a blockchain lottery platform built with three core contract components:

**OpenLotto.sol** - Main interface contract implementing ERC721 (tickets as NFTs) with AccessControl and ReentrancyGuard. Handles lottery creation, ticket purchases, prize claims, and fund distribution.

**LotteryOperatorInterface** (in LotteryModel.sol) - Abstract contract that operators must implement to define lottery game logic. Operators handle ticket validation, prize calculation, and winner determination. Each lottery type has its own operator contract. `src/operators/BaseLotteryOperator.sol` is the base implementation to subclass when building a new operator.

**Database Layer** - Two separate storage contracts:
- `LotteryDatabase`: Stores lottery configurations and state (reserve, round jackpots)
- `TicketDatabase`: Stores ticket data and round-specific flags

Data models:
- `LotteryModel.LotteryItem`: Lottery configuration including rounds, bet price, distribution/prize pools, operator reference
- `TicketModel.TicketItem`: Ticket data linking to lottery, rounds played, and bet count

Key design patterns:
- Uses PRBMath's `UD60x18` for fixed-point decimal arithmetic (prize/distribution percentages)
- Distribution pools split incoming funds between addresses (or reserve if `address(0)`)
- Prize pools define how jackpots are distributed across prize tiers
- Operators are pluggable via `LotteryOperatorInterface` - lottery behavior is defined by the operator contract, not OpenLotto itself

## Roles

- `LOTTERY_MANAGER_ROLE` on `OpenLotto` — required to call `CreateLottery`. Granted to the lottery manager address at deploy time.
- `OPERATOR_CONTROLER_ROLE` on each operator contract — must be granted to the `OpenLotto` contract address so OpenLotto can drive the operator. `CreateLottery` fails fast with `OperatorRoleMissing()` if this is not set up. Wiring this up is required whenever a new operator is deployed (see `script/DeployOpenLottoWithSampleData.s.sol` for the pattern).

## Ticket lifecycle

Tickets move through three explicit states per round:

1. **Unclaimed** — right after `BuyTicket`. The ticket's round flags are `FLAG_NONE`.
2. **Claimed** — the operator (and only the operator) calls `OpenLotto.ClaimTicket(id, round)` after resolving the round, which sets `FLAG_CLAIMED`. This is the authorisation signal that the operator recognises this ticket as eligible to withdraw a prize.
3. **Withdrawn** — the ticket owner calls `WithdrawTicket(id, round)`. The contract snapshots the jackpot on the first withdrawal of the round (so subsequent winners compute their share against the same pot), decrements the live jackpot by the amount paid, and sends it to the NFT owner. If the transfer fails the whole call reverts with `WithdrawFailed()` and the ticket stays claimed so the owner can retry.

## Solidity / Formatting

- Contracts target `pragma solidity ^0.8.22`.
- `forge fmt` is configured in `foundry.toml` with: 120-col line length, 4-space indent, double quotes, long int types (`uint256`, not `uint`), thousands underscores in numeric literals, and multiline function headers. Run `forge fmt` before committing.

## Import Aliases (remappings.txt)

```
@prb/math/    → lib/prb-math/src/
@openzeppelin/ → lib/openzeppelin-contracts/contracts/
@src          → src/
@models       → src/models
@database     → src/database
@test         → test/
```

## TypeScript Bindings

The `src/bindings/` directory contains TypeScript/ethers.js bindings for interacting with deployed contracts. Published as `@apuigsech/openlotto-bindings` to GitHub Packages. The CI workflow merges ABIs from multiple contracts before building bindings.
