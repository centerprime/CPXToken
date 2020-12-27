pragma solidity 0.5.2; 
import "./access/Ownable.sol";
import "./token/ERC20.sol";
import "./token/ERC677Token.sol";
import "./role/SignerRole.sol";


//****************************************************************************//
//---------------------  CPX TOKEN MAIN CODE STARTS HERE ---------------------//
//****************************************************************************//
    
contract CPXToken is Ownable, TokenERC20, ERC677Token, SignerRole {
    
    
    /***************************************/
    /* Custom Code for the ERC20 CPX TOKEN */
    /***************************************/

    /* Public variables of the token */
    string private tokenName = "CenterPrime";
    string private tokenSymbol = "CPX";
    uint256 private initialSupply = 1000000000;  //1000000000 Billion
    
    
    /* Records for the fronzen accounts */
    mapping (address => bool) public frozenAccount;
    
    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor () TokenERC20(initialSupply, tokenName, tokenSymbol) public {
        
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value)  internal {
        require(!safeguard);
        require (_to != address(0x0));                      // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to].add(_value) >= balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);        // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }
    
    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
            frozenAccount[target] = freeze;
        emit  FrozenFunds(target, freeze);
    }


    /****************************************/
    /* Custom Code for the ERC865 CPX TOKEN */
    /****************************************/

     /* Nonces of transfers performed */
    mapping(bytes32 => bool) transactionHashes;
    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event ApprovalPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    
    
      /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount)  public onlyOwner  {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(this), target, mintedAmount);
    }
    
     /**
     * @notice Submit a presigned transfer
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function transferPreSigned(
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlySigner
        returns (bool)
    {
        require(_to != address(0), 'Invalid _to address');
        bytes32 hashedTx = keccak256(abi.encodePacked('transferPreSigned', address(this), _to, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from == _from, 'Invalid _from address');

        balanceOf[from] = balanceOf[from].sub(_value).sub(_fee);
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }
	
	
     /**
     * @notice Submit a presigned approval
     * @param _spender address The address which will spend the funds.
     * @param _value uint256 The amount of tokens to allow.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function approvePreSigned(
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlySigner
        returns (bool)
    {
        require(_spender != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('approvePreSigned', address(this), _spender, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from != address(0), 'Invalid _from address');
        allowance[from][_spender] = _value;
        balanceOf[from] = balanceOf[from].sub(_fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Approval(from, _spender, _value);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, _value, _fee);
        return true;
    }
    
     /**
     * @notice Increase the amount of tokens that an owner allowed to a spender.
     * @param _spender address The address which will spend the funds.
     * @param _addedValue uint256 The amount of tokens to increase the allowance by.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function increaseApprovalPreSigned(
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlySigner
        returns (bool)
    {
        require(_spender != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('increaseApprovalPreSigned', address(this), _spender, _addedValue, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from != address(0), 'Invalid _from address');
        allowance[from][_spender] = allowance[from][_spender].add(_addedValue);
        balanceOf[from] = balanceOf[from].sub(_fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Approval(from, _spender, allowance[from][_spender]);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowance[from][_spender], _fee);
        return true;
    }
    
     /**
     * @notice Decrease the amount of tokens that an owner allowed to a spender.
     * @param _spender address The address which will spend the funds.
     * @param _subtractedValue uint256 The amount of tokens to decrease the allowance by.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function decreaseApprovalPreSigned(
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlySigner
        returns (bool)
    {
        require(_spender != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('decreaseApprovalPreSigned', address(this), _spender, _subtractedValue, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from != address(0), 'Invalid _from address');
        if (_subtractedValue > allowance[from][_spender]) {
            allowance[from][_spender] = 0;
        } else {
            allowance[from][_spender] = allowance[from][_spender].sub(_subtractedValue);
        }
        balanceOf[from] = balanceOf[from].sub(_fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Approval(from, _spender, _subtractedValue);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowance[from][_spender], _fee);
        return true;
    }
     /**
     * @notice Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the spender.
     * @param _nonce uint256 Presigned transaction number.
     */
    function transferFromPreSigned(
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlySigner
        returns (bool)
    {
        require(_to != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('transferFromPreSigned', address(this), _from, _to, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address spender = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(spender != address(0), 'Invalid _from address');
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][spender] = allowance[_from][spender].sub(_value);
        balanceOf[spender] = balanceOf[spender].sub(_fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Transfer(_from, _to, _value);
        emit Transfer(spender, msg.sender, _fee);
        return true;
    }
   
   
     /**
  * @dev transfer token to a specified address with additional data if the recipient is a contract.
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  * @param _data The extra data to be passed to the receiving contract.
  */
  function transferAndCall(address _to, uint _value, bytes memory _data)
    public
    validRecipient(_to)
    returns (bool success)
  {
    return super.transferAndCall(_to, _value, _data);
  }
      
    //Just in case, owner wants to transfer Ether from contract to owner address
    function manualWithdrawEther() public onlyOwner{
        address(owner).transfer(address(this).balance);
    }
    
    //Just in case, owner wants to transfer Tokens from contract to owner address
    //tokenAmount must be in WEI
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner{
        _transfer(address(this), msg.sender, tokenAmount);
    }
    
    /**
     * Change safeguard status on or off
     *
     * When safeguard is true, then all the non-owner functions will stop working.
     * When safeguard is false, then all the functions will resume working back again!
     */
    function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;    
        }
    }
      // MODIFIERS

    modifier validRecipient(address _recipient) {
    require(_recipient != address(0) && _recipient != address(this));
    _;
  }


}