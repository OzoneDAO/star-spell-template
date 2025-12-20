-include .env 

#Deploy
deploy:; forge script script/Deploy.s.sol:Deploy --sender ${ETH_FROM} --private-key ${PRIVATE_KEY} --rpc-url ${MAINNET_RPC_URL} --broadcast --verify --etherscan-api-key ${MAINNET_API_KEY} --retries 10 --delay 10


