pragma solidity 0.5.2; 

contract ERC677Receiver {
  function onTokenTransfer(address _sender, uint _value, bytes memory _data)  public;
}