pragma solidity 0.5.2; 
import "./token/ERC20.sol";

contract ERC677 is TokenERC20 {
  function transferAndCall(address to, uint value, bytes memory data)  public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint value, bytes data);
}
