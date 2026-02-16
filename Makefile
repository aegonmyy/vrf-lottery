-include .env
build:; forge build
deploy-sepolia:; forge script C:/Users/Alameen/Documents/javascript/solidity/projects/lottery/script/RandomWinnerPicker.s..sol:test_deploy --rpc-url http://127.0.0.1:8545 --private-key $(priv_key) --rpc-url $(rpc_url) --verify --etherscan-api-key $(etherscan_api_key)