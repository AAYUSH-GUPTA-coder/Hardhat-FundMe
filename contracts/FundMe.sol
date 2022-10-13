// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NOT_OWNER();
error SEND_MORE_ETH();
error TRANSFER_FUND_FAIL();

/** @title A contract for crowd Funding
 * @author Aayush Gupta
 * @notice This contract is to demo a sample funding contracts
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State Variables
    mapping(address => uint256) public addressToAmountFunded;
    mapping(address => bool) public isAlreadyFunder;
    address[] public funders;
    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10**18;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This function funds this contract
     * @dev This implements price feeds as our Library
     */
    function fund() public payable {
        if (msg.value.getConversionRate(priceFeed) < MINIMUM_USD) {
            revert SEND_MORE_ETH();
        }

        addressToAmountFunded[msg.sender] += msg.value;
        // condition to check whether the msg.sender is already a funder
        if (!isAlreadyFunder[msg.sender]) {
            isAlreadyFunder[msg.sender] = true;
            funders.push(msg.sender);
        }
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NOT_OWNER();
        _;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!callSuccess) revert TRANSFER_FUND_FAIL();
        // require(callSuccess, "Call failed");
    }
}
