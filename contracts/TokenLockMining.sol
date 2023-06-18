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
    uint256 public constant halfeIntervals = 1 hours;//730 days; 
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

    // function getReleaseAmount(uint256 _currentTime) internal returns (uint256) {
    //     uint256 elapsedTime = _currentTime - lastReleaseTime; 
    //     uint256 halfCount = elapsedTime /halfeIntervals;
    //     uint256 releaseAmount;
    //     for (uint i = 0; i <halfCount-1; i++) {
    //         releaseAmount=halfeIntervals/1 hours * lastReleasePace;
    //         lastReleasePace/=2;
    //         lastReleaseTime+=halfeIntervals/1 seconds;
    //     }
    //     releaseAmount = (_currentTime-lastReleaseTime)/1 hours * lastReleasePace;
    //     return releaseAmount;
    // }

    function getReleaseAmount(uint256 _currentTime) internal returns (uint256) {
        uint256 halfDate=startTime;
        uint256 releaseAmount;
        uint256 elapsedTime;
        while (halfDate<_currentTime) {
            if (halfDate>lastReleaseTime){
                elapsedTime = (halfDate - lastReleaseTime)/1 hours;
                releaseAmount += elapsedTime * lastReleasePace;  
                lastReleaseTime = halfDate;
                lastReleasePace /=2;
            }
            halfDate +=halfeIntervals/1 seconds;
        }
        elapsedTime = _currentTime - lastReleaseTime;
        releaseAmount += elapsedTime/1 hours * lastReleasePace;
        lastReleaseTime = _currentTime;
        return releaseAmount;
    }

    function withdrawToken() external onlyManager {
        uint256 balance = getCurrentBalance();
        require(balance>0,"all tokens released.");

        uint256 currentTime= block.timestamp;
        uint256 releaseAmount = getReleaseAmount(currentTime);

        require (balance >= releaseAmount, "not enough balance.");

        token.transfer(manager,releaseAmount);
        releasedTotal+=releaseAmount;

    }

}