pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenLockMining {
    address public owner;
    address public manager;
    IERC20 public token;

    uint256 public startTime;
    uint256 public releasedTotal;
    uint256 public constant halfeIntervals = 730 days; //halves every 24 months
    uint256 public constant initialReleasePace = 1000;

    uint256 public lastReleasePace; 
    uint256 public lastReleaseTime;
    

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
    }

    function getCurrentPace() view public returns (uint256) {
        uint256 elapsedTime = block.timestamp - startTime; 
        uint256 yearsPassed = elapsedTime/halfeIntervals;
        uint256 releasePace = initialReleasePace >> yearsPassed;
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
        uint256 pseudoLastRelasePace = lastReleasePace;
        uint256 pseudoLastReleaseTime = lastReleaseTime;
        while (halfDate<_currentTime) {
            if (halfDate>pseudoLastReleaseTime){
                elapsedTime = (halfDate - pseudoLastReleaseTime)/1 hours;  //release every hour
                releaseAmount += elapsedTime * pseudoLastRelasePace;  
                pseudoLastReleaseTime = halfDate;
                pseudoLastRelasePace /=2;
            }
            halfDate +=halfeIntervals/1 seconds;
        }
        elapsedTime = _currentTime - pseudoLastReleaseTime;
        releaseAmount += elapsedTime/1 hours * pseudoLastRelasePace;
        return (releaseAmount, pseudoLastRelasePace);
    }
// withdraw all relased token
    function withdrawToken() external onlyManager {
        uint256 balance = getCurrentBalance();
        require(balance>0,"all tokens released.");

        uint256 currentTime= block.timestamp;
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