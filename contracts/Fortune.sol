// SPDX-License-Identifier: MIT
// An example of a consumer contract that also owns and manages the subscription
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interface/ISeeker.sol";

contract FortuneController is VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    ISeeker SEEKER;
    address SEEKER_ADDRESS;
    uint64 LINK_SUBSCRIPTION_ID;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    // A reasonable default is 100000, but this value could be different
    // on other networks.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    // Rinkeby coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations

    // Rinkeby LINK token contract. For other networks, see
    // https://docs.chain.link/docs/vrf-contracts/#configurations

    constructor(
        address vrfCoordinator,
        address linkTokenContract,
        address seekerContract,
        uint64 linkSubscriptionId
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(linkTokenContract);
        SEEKER = ISeeker(seekerContract);
        SEEKER_ADDRESS = seekerContract;
        LINK_SUBSCRIPTION_ID = linkSubscriptionId;
        //Create a new subscription when you deploy the contract.
        // createNewSubscription();
    }

    enum RequestTypes {
        SPAWN,
        ATTACK_MOB,
        ATTACK_PLAYER
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() private {
        // Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            LINK_SUBSCRIPTION_ID,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        _wordRequests[requestId] = WordRequest(requestId);
    }

    function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        // s_randomWords = randomWords;
        WordRequest memory wordRequest = _wordRequests[requestId];
    }

    // State
    uint256 public MAX_SEEKERS = 100;
    uint256 public CURRENT_SEEKERS = 0;

    struct Seeker {
        uint256 atom;
        string name;
        string location;
    }

    struct WordRequest {
        uint256 requestId;
    }

    // Mapping from seeker ID to Seeker
    mapping(address => uint256[]) private _seekerLedger;
    mapping(uint256 => Seeker) private _seekers;
    mapping(uint256 => WordRequest) private _wordRequests;

    // Creation
    function spawnNewSeeker() external payable {
        require(CURRENT_SEEKERS < MAX_SEEKERS, "Current spawn limit reached.");

        uint256 seekerId = CURRENT_SEEKERS;

        SEEKER.spawnNewSeeker(msg.sender, seekerId);

        assignSeeker(seekerId);

        CURRENT_SEEKERS++;
    }

    function assignSeeker(uint256 seekerId) private {
        _seekers[seekerId] = Seeker(100, "Unknown", "Default");
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
    function changeSeekerName(uint256 seekerId, string memory newName)
        public
        onlySeekerOwner(seekerId)
    {
        _seekers[seekerId].name = newName;
    }

    // Internal
    function changeMaxSeekers(uint256 amount) public onlyOwner {
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
        if (from != msg.sender) {
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

    function setLinkSubscriptionId(uint64 id) external onlyOwner {
        LINK_SUBSCRIPTION_ID = id;
    }

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
    function withdraw(uint256 amount, address to) external onlyOwner {
        LINKTOKEN.transfer(to, amount);
    }

    modifier onlySeekerOwner(uint256 seekerId) {
        require(
            SEEKER.ownerOf(seekerId) == msg.sender,
            "You do not own this seeker."
        );
        _;
    }
}
