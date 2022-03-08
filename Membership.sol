// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol" ;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";



contract Membership{

    using Address for address;
    using SafeMath for uint256;
    // using SafeERC20 for IERC20;

    address public owner;
    address payable public paymentAddress;
    uint256 public paymentAmount; //
    uint256 public subscriptionDuration;
  
    struct PaymentHistory {
        uint256 paymentAmt;
        uint256 subscriptionStarted;
        uint256 subscriptionExpiration;
    }

    mapping(address=>PaymentHistory[]) paymentLog;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event PaymentAddressSet(address indexed paymentAddr);
    event PaymentAmountSet(uint256 indexed paymentAmt);
    event CheckValidSub(bool indexed isValid);
    event SubscriptionDurationSet(uint256 indexed subscriptionDur);
    event PaymentComplete(address indexed payer, address indexed payee, uint256  amount, uint256  subStart, uint256  subEnd);


    modifier isOwner(){
        require(msg.sender == owner,"Caller is not owner");
        _;
    }

    constructor (address _paymentAddress, uint256 _paymentAmount, uint256 _subscriptionDuration){
        require(msg.sender != _paymentAddress, "Contract owner cannot accept payments");
        require(_paymentAmount > 0 && _paymentAmount < 1e20, "Payment amount out of bounds");
        require(_subscriptionDuration > 0, "Subscription Duration must be greater than 0");
        
        owner = msg.sender;
        paymentAddress = payable(_paymentAddress);
        paymentAmount = _paymentAmount;
        subscriptionDuration = _subscriptionDuration;


        emit OwnerSet(address(0),owner);
        emit PaymentAddressSet(paymentAddress);
        emit PaymentAmountSet(paymentAmount);
        emit SubscriptionDurationSet(subscriptionDuration);


    }
    // /**
    //  * @dev Pay for premium subscription
    //  * @param _tokenAdress address to check
    //  */
    function payForPremium(/*address _tokenAddress*/) public payable   {
        // IERC20(_tokenAdress).transferFrom(msg.sender,paymentAddress,paymentAmount);
        require(msg.sender != owner,"Owner cannot pay for premium");
        require(msg.sender != paymentAddress,"Payment address cannot pay for premium");
        require(checkSubscriptionValid(msg.sender) != true, "You already have a valid subscription");
        require(msg.value == paymentAmount, "Invalid payment amount");

        //Add check for token address?
        //Add token address to constructor?
        // IERC20(_tokenAddress).transferFrom(msg.sender, paymentAddress, paymentAmount);

        Address.sendValue(paymentAddress, msg.value); //send eth

        uint256 subStart = block.timestamp;
        uint256 subEnd = subscriptionDuration.add(block.timestamp);

        paymentLog[msg.sender].push(PaymentHistory(paymentAmount,subStart,subEnd));

        emit PaymentComplete(msg.sender,paymentAddress, paymentAmount,subStart,subEnd);
      
    }
    /**
     * @dev Gets the amount of times a user has purchased a subscription
     * @param _userAddress address to check
     */
    function getSubscriptionCount(address _userAddress) external view returns (uint256){
        return paymentLog[_userAddress].length;
    }
    /**
     * @dev Get user's payment history
     * @param _userAddress address to check
     */
    function getPaymentHistory(address _userAddress) external view returns (PaymentHistory[] memory){
        return paymentLog[_userAddress];
    }
    /**
     * @dev Check if user's subscription is valid
     * @param _userAddress address to check
     */
    function checkSubscriptionValid(address _userAddress) public  returns (bool) {
        if (paymentLog[_userAddress].length > 0) {
            uint256 last_index = paymentLog[_userAddress].length-1;
            if (block.timestamp > paymentLog[_userAddress][last_index].subscriptionExpiration){
                emit CheckValidSub(false);
                return false; //expired
            }
            emit CheckValidSub(true);
            return true; //valid
        }

        emit CheckValidSub(false);
        return false; //No payment ever made 
        
        
    }
     /**
     * @dev Change payment amount
     * @param _newPaymentAmount new payment amount
     */
    function changePaymentAmount(uint256 _newPaymentAmount) public isOwner {
        require(_newPaymentAmount > 0 && _newPaymentAmount < 1e20, "Payment amount out of bounds");
        
        paymentAmount = _newPaymentAmount;

        emit PaymentAmountSet(paymentAmount);
    } 

    /**
     * @dev Change subscription duration
     * @param _newSubscriptionDuration new subscription duration
     */
    function changeSubscriptionDuration(uint256 _newSubscriptionDuration) public isOwner {
        require(_newSubscriptionDuration > 0, "Subscription Duration must be greater than 0");

        subscriptionDuration = _newSubscriptionDuration;

        emit SubscriptionDurationSet(subscriptionDuration);
    } 

    /**
     * @dev Change payment address
     * @param _newAddress new payment address
     */
    function changePaymentAddress(address _newAddress) public isOwner {
        require(owner != _newAddress, "Contract owner cannot accept payments");
        require(paymentAddress != _newAddress, "Payment address identical");
        
        paymentAddress = payable(_newAddress);
        
        emit PaymentAddressSet(paymentAddress);
    } 


    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        require(owner != newOwner, "Contract owner identical");

        owner = newOwner;
        emit OwnerSet(owner, newOwner);
    }


}
