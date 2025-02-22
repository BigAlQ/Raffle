// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import  {Script} from "lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/Mock/LinkToken.t.sol";
import {CommonBase} from "lib/forge-std/src/Base.sol";
 
abstract contract CodeConstants {
    /* VRF Mock Values */
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public MOCK_WEI_PER_UNIT_LINK = 4e15;



    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
} 

contract HelperConfig is CodeConstants,Script{
    error HelperConfig__InvalidChainId();

    struct NetworkConfig{
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionID;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainID (uint256 chainId) public  returns(NetworkConfig memory){
        if(networkConfigs[chainId].vrfCoordinator != address(0)){
        return networkConfigs[chainId];
    }
        else if (chainId == LOCAL_CHAIN_ID){
            return getAnvilEthConfig();
        }
        else{
            revert HelperConfig__InvalidChainId();
        }
        
    }

    function getConfig() public returns (NetworkConfig memory){
        return getConfigByChainID(block.chainid);
    }

    function getSepoliaEthConfig () public pure returns(NetworkConfig memory) {
        return NetworkConfig( {
            entranceFee: 0.01 ether,    
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callbackGasLimit: 500000,
            subscriptionID: 61636622198041075945159848815591503836449750359887027646361660113437689092736,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x7370712d10a32587B6ADDE48e510a98dc739250a
        });
    }

    function getAnvilEthConfig ()  public returns(NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)){
            return localNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = 
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK,MOCK_WEI_PER_UNIT_LINK);
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();
        localNetworkConfig =  NetworkConfig( {
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            // The gas lane doesnt matter because the Mock will always make it work
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callbackGasLimit: 500000,
            subscriptionID: 0,
            link: address(linkToken),
            account: DEFAULT_SENDER  // Default foundry sender from CommonBase
        });
        return localNetworkConfig;

}
}

