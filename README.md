# Random Winner Picker

Simple on-chain lottery using Chainlink VRF v2.5

Players send ≥ 0.0001 ETH to enter.  
After 3+ players join, a random winner is automatically picked and receives the full prize pool.

## Features

- Provably fair randomness via Chainlink VRF
- Anyone can enter
- Automatic draw when enough players join
- Winner claims prize manually

## How to use

1. Deploy with your Chainlink VRF subscription ID and coordinator address
2. Players call `enter()` with value ≥ 0.0001 ETH
3. When 3+ players → randomness requested
4. Winner picked → prize assigned to their pending withdrawal
5. Winner calls `withdrawPrize()`