pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract rs20 is ERC20 {
    
    constructor() ERC20("RS", "RS") {
        
        _mint(msg.sender, 2013);
        
    }
    
    
    
}

