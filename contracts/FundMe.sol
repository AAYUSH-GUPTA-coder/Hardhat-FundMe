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
    mapping(address => uint256) private s_addressToAmountFunded;
    mapping(address => bool) private s_isAlreadyFunder;
    address[] private s_funders;
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10**18;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
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
        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
            revert SEND_MORE_ETH();
        }

        s_addressToAmountFunded[msg.sender] += msg.value;
        // condition to check whether the msg.sender is already a funder
        if (!s_isAlreadyFunder[msg.sender]) {
            s_isAlreadyFunder[msg.sender] = true;
            s_funders.push(msg.sender);
        }
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NOT_OWNER();
        _;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!callSuccess) revert TRANSFER_FUND_FAIL();
        // require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mapping can't be in memory
        // Performing all the looping function in memnory to save gas
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        if (!callSuccess) revert TRANSFER_FUND_FAIL();
    }

    // getter function
    function getOnwer() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getIsAlreadyFunder(address funder) public view returns (bool) {
        return s_isAlreadyFunder[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
