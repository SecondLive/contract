echo "deploy begin....."

TF_CMD=node_modules/.bin/truffle-flattener

echo "" >  ./deployments/SecondLiveNFT.full.sol
cat  ./scripts/head.sol >  ./deployments/SecondLiveNFT.full.sol
$TF_CMD ./contracts/SecondLive/SecondLiveNFT.sol >>  ./deployments/SecondLiveNFT.full.sol 
 
echo "deploy end....."
