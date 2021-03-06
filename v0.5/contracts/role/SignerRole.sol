pragma solidity 0.5.2; 
import "./access/Ownable.sol";
import "./role/Roles.sol";

contract SignerRole is Ownable {
    using Roles for Roles.Role;

    event Signerdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signers;

    constructor () public {
        // _addSigner(msg.sender);
    }
    
    modifier onlySigner() {
        require(isSigner(msg.sender));
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }
    
    
    function addSigner(address account) public onlyOwner {
        _addSigner(account);
    }

    function renounceSigner(address account) public onlyOwner{
        _removeSigner(account);
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit Signerdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
    }
}
