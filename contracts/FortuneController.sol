// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "./interface/ISeeker.sol";

contract FortuneController is VRFConsumerBase, Ownable {
    ISeeker SEEKER;
    address SEEKER_ADDRESS;
    uint256 LINK_FEE = 0.0001 * 10**18; // 0.0001 LINK Fee on Polygon

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    constructor(
        address vrfCoordinator,
        address linkTokenContract,
        address seekerContract
    ) VRFConsumerBase(vrfCoordinator, linkTokenContract) {
        SEEKER = ISeeker(seekerContract);
        SEEKER_ADDRESS = seekerContract;
    }

    // State
    uint256 public MAX_SEEKERS = 100;
    uint256 public CURRENT_SEEKERS = 0;

    struct Seeker {
        uint256 atom;
        uint256 id;
        string name;
        string location;
        uint16 hp;
        uint16 strength;
        uint16 dexterity;
        uint16 agility;
        uint16 intelligence;
        uint16 will;
        uint16 luck;
        uint16 special;
    }

    enum RequestType {
        SPAWN,
        ATTACK_MOB,
        ATTACK_PLAYER
    }

    struct NumberRequest {
        RequestType requestType;
    }

    // Mapping from seeker ID to Seeker
    mapping(address => uint256[]) private _seekerLedger;
    mapping(uint256 => Seeker) private _seekers;
    mapping(bytes32 => NumberRequest) private numberRequests;

    function getRandomNumber(RequestType requestType) internal {
        require(
            LINK.balanceOf(address(this)) >= LINK_FEE,
            "Not enough LINK - fill contract with faucet"
        );
        bytes32 requestId = requestRandomness(keyHash, LINK_FEE);
        numberRequests[requestId] = NumberRequest(requestType);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        handleRequest(requestId, randomness);
    }

    function handleRequest(bytes32 requestId, uint256 randomness) private {
        NumberRequest memory numberRequest = numberRequests[requestId];

        if (numberRequest.requestType == RequestType.SPAWN) {} else if (
            numberRequest.requestType == RequestType.ATTACK_MOB
        ) {}
    }

    // Creation
    function spawnNewSeeker() external payable {
        require(CURRENT_SEEKERS < MAX_SEEKERS, "Current spawn limit reached.");

        uint256 seekerId = CURRENT_SEEKERS;

        SEEKER.spawnNewSeeker(msg.sender, seekerId);

        // assignSeeker(seekerId);

        CURRENT_SEEKERS++;
    }

    function moldSeeker() private {}

    function assignSeeker(uint256 seekerId) private {
        // _seekers[seekerId] = Seeker(100, "Unknown", "Default");
    }

    // Seeker Functionality
    function attackMob(uint256 attackerId) public onlySeekerOwner(attackerId) {}

    function attackPlayer(uint256 attackerId, uint256 defenderId)
        public
        onlySeekerOwner(attackerId)
    {}

    function useItem() public {}

    function craftItem() public {}

    function reviveSeeker(uint256 seekerId) public {}

    // Item Buy/Sell
    function buyItem() public {}

    function sellItem() public {}

    // Public Seeker Settings
    function setSeekerName(uint256 seekerId, string memory newName)
        public
        onlySeekerOwner(seekerId)
    {
        _seekers[seekerId].name = newName;
    }

    // Internal
    function setMaxSeekers(uint256 amount) public onlyOwner {
        MAX_SEEKERS = amount;
    }

    function afterTokenTransfer(
        address from,
        address to,
        uint256 seekerId
    ) external {
        require(
            msg.sender == SEEKER_ADDRESS,
            "Can only be called from the Seeker contract."
        );

        // Delete from current owner's inventory and add to new owner's inventory.
        if (from != SEEKER_ADDRESS) {
            findAndRemoveSeeker(from, seekerId);
        }

        if (to != address(0)) {
            _seekerLedger[to].push(seekerId);
        }
    }

    function findAndRemoveSeeker(address owner, uint256 seekerId) private {
        uint256[] storage seekers = _seekerLedger[owner];

        for (uint256 i = 0; i < seekers.length; i++) {
            if (seekers[i] == seekerId) {
                seekers[i] = seekers[seekers.length - 1];
                seekers.pop();
                break;
            }
        }
    }

    // function setLinkSubscriptionId(uint64 id) external onlyOwner {
    //     // LINK_SUBSCRIPTION_ID = id;
    // }

    // Create a new subscription when the contract is initially deployed.
    // function createNewSubscription() private onlyOwner {
    //     // Create a subscription with a new subscription ID.
    //     address[] memory consumers = new address[](1);
    //     consumers[0] = address(this);
    //     s_subscriptionId = COORDINATOR.createSubscription();
    //     // Add this contract as a consumer of its own subscription.
    //     COORDINATOR.addConsumer(s_subscriptionId, consumers[0]);
    // }

    // Assumes this contract owns link.
    // 1000000000000000000 = 1 LINK
    // function topUpSubscription(uint256 amount) external onlyOwner {
    //     LINKTOKEN.transferAndCall(
    //         address(COORDINATOR),
    //         amount,
    //         abi.encode(s_subscriptionId)
    //     );
    // }

    // function addConsumer(address consumerAddress) external onlyOwner {
    //     // Add a consumer contract to the subscription.
    //     COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
    // }

    // function removeConsumer(address consumerAddress) external onlyOwner {
    //     // Remove a consumer contract from the subscription.
    //     COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
    // }

    // function cancelSubscription(address receivingWallet) external onlyOwner {
    //     // Cancel the subscription and send the remaining LINK to a wallet address.
    //     COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
    //     s_subscriptionId = 0;
    // }

    // Transfer this contract's funds to an address.
    // 1000000000000000000 = 1 LINK
    // function withdraw(uint256 amount, address to) external onlyOwner {
    //     LINKTOKEN.transfer(to, amount);
    // }

    modifier onlySeekerOwner(uint256 seekerId) {
        require(
            SEEKER.ownerOf(seekerId) == msg.sender,
            "You do not own this seeker."
        );
        _;
    }
}
