pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

interface EACAggregatorProxy {
    function latestAnswer() external view returns (int256);
}

contract Options {
    
    using SafeERC20 for IERC20;
    
    IERC20 Weth = IERC20(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
    IERC20 DaiToken = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    
    uint ethPrice;
    uint premiumn = 1;
    uint timePeriod = 2 days;
    
    address owner;
    
    mapping(address => bool) hasPendingOption;
    mapping(address => uint) optionWorth;
    mapping(address => uint) optionPrice;
    mapping(address => uint) deadline;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    
    function updateEthPriceChainlink() public returns (uint) {
        int256 chainEthPrice = EACAggregatorProxy(0x9326BFA02ADD2366b30bacB125260Af641031331).latestAnswer();
        ethPrice = uint(chainEthPrice/100000000);
        return ethPrice;
    }   
    
    function buyOption(uint _amount) public {
        
        require(hasPendingOption[msg.sender] != true, "You have a pending option, please execute that first.");
        require(Weth.balanceOf(address(this)) >= _amount, "This contract does not have that much available");
        updateEthPriceChainlink();
        
        uint BuyingPrice = ethPrice * _amount;
        uint UserPrice = BuyingPrice + (ethPrice * premiumn);
        
        require(DaiToken.balanceOf(msg.sender) >= UserPrice, "You don't have that much Dai available");
        
        DaiToken.transferFrom(msg.sender, address(this), premiumn);
        optionWorth[msg.sender] = _amount;
        optionPrice[msg.sender] = BuyingPrice;
        deadline[msg.sender] = block.timestamp + timePeriod;
        
    }
    
    function sellOption() public {
        
        require(hasPendingOption[msg.sender] == true, "You do not have a pending option");
        require(deadline[msg.sender] < block.timestamp, "This option has expired");
        require(Weth.balanceOf(address(this)) >= optionWorth[msg.sender], "This contract does not have this much available");
        
        DaiToken.transferFrom(msg.sender, address(this), optionPrice[msg.sender]);
        Weth.transferFrom(address(this), msg.sender, optionWorth[msg.sender]);
        
        hasPendingOption[msg.sender] = false;
    }
    
    function clearOption() public {
        
        require(hasPendingOption[msg.sender] = true, "You need an option to clear first");
        
        hasPendingOption[msg.sender] = false;
        
    }
    
    function withdrawDai() public onlyOwner {
        
        DaiToken.transferFrom(address(this), owner, DaiToken.balanceOf(address(this)));
        
    }
    
}
