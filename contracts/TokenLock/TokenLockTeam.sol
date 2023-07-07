pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenLockTeam {
    address public owner;
    address public manager;
    IERC20 public token;

    uint256 public startTime;  //set starting date when deploy the contract
    uint256 public releasedTotal;
    uint256 public constant DECIMAL_FACTOR = 1000; // reserve 3 digits of decimals
    uint256 public constant ReleasePace = 8333333;  //monthly release pace

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
        lastReleaseTime=startTime;
    }

    function assignManager(address _manager) external onlyOwner {
        manager = _manager;
        emit changeManager(block.timestamp, _manager);
    }


    function getCurrentBalance() view public returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        return balance;
    }


    function getReleaseAmount(uint256 _currentTime) internal returns (uint256) {
        uint256 releaseAmount;
        uint256 elapsedTime;

        elapsedTime = _currentTime - lastReleaseTime;
        releaseAmount += elapsedTime/30 days * ReleasePace * DECIMAL_FACTOR; //release every 30 days
        lastReleaseTime = _currentTime;
        return releaseAmount/DECIMAL_FACTOR;
    }
// withdraw all relased token
    function withdrawToken() external onlyManager {
        uint256 balance = getCurrentBalance();
        require(balance>0,"all tokens released.");

        uint256 currentTime= block.timestamp;
        require( currentTime>= startTime, "The release of the token has not started yet.");
        uint256 releaseAmount = getReleaseAmount(currentTime);
        if (balance< releaseAmount){
            releaseAmount=balance;
        }

        token.transfer(manager,releaseAmount);
        releasedTotal+=releaseAmount;

    }

}
