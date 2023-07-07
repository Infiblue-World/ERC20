pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenLockSocialFi {
    address public owner;
    address public manager;
    IERC20 public token;

    uint256 public startTime;
    uint256 public releasedTotal;
    uint256 public constant halfeIntervals = 1095 days; //halves every 36 months
    uint256 public constant DECIMAL_FACTOR = 1000; // reserve 3 digits of decimals
    uint256 public constant initialReleasePace = 8000;

    uint256 public lastReleasePace; 
    uint256 public lastReleaseTime;

    event changeManager(uint256 indexed time, address manager);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this functure.");
        _;
    }

    constructor(address _tokenAddress, uint256 _startTime) {
        owner = msg.sender;
        startTime = _startTime;
        token = IERC20(_tokenAddress);
        lastReleasePace=initialReleasePace;
        lastReleaseTime=startTime;
    }

    function assignManager(address _manager) external onlyOwner {
        manager = _manager;
        emit changeManager(block.timestamp, _manager);
    }

    function getCurrentPace() view public returns (uint256) {
        require (block.timestamp >=startTime,"The release of the token has not started yet.");
        uint256 elapsedTime = block.timestamp - startTime; 
        uint256 yearsPassed = elapsedTime/halfeIntervals;
        uint256 releasePace = initialReleasePace * DECIMAL_FACTOR;
        releasePace >> yearsPassed;
        releasePace/=DECIMAL_FACTOR;
        return releasePace;
    }

    function getCurrentBalance() view public returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        return balance;
    }


    function getReleaseAmount(uint256 _currentTime) view internal returns (uint256,uint256) {
        uint256 halfDate=startTime;
        uint256 releaseAmount;
        uint256 elapsedTime;
        uint256 pseudoLastRelasePace = lastReleasePace * DECIMAL_FACTOR;
        uint256 pseudoLastReleaseTime = lastReleaseTime;
        while (halfDate<_currentTime) {
            if (halfDate>pseudoLastReleaseTime){
                elapsedTime = (halfDate - pseudoLastReleaseTime)/24 hours;  //release every hour
                releaseAmount += elapsedTime * pseudoLastRelasePace;  
                pseudoLastReleaseTime = halfDate;
                pseudoLastRelasePace /=2;
            }
            halfDate +=halfeIntervals/1 seconds;
        }
        elapsedTime = _currentTime - pseudoLastReleaseTime;
        releaseAmount += elapsedTime/24 hours * pseudoLastRelasePace;
        releaseAmount/=DECIMAL_FACTOR;
        return (releaseAmount, pseudoLastRelasePace);
    }

    // withdraw all relased token
    function withdrawToken() external onlyManager {
        uint256 balance = getCurrentBalance();
        require(balance>0,"all tokens released.");

        uint256 currentTime= block.timestamp;
        require( currentTime>= startTime, "The release of the token has not started yet.");
        uint256 releaseAmount;
        uint256 pseudoLastRelasePace;
        (releaseAmount,pseudoLastRelasePace) = getReleaseAmount(currentTime);

        require (balance >= releaseAmount, "not enough balance.");

        token.transfer(manager,releaseAmount);
        releasedTotal+=releaseAmount;
        lastReleaseTime = currentTime;
        lastReleasePace=pseudoLastRelasePace;

    }

}
