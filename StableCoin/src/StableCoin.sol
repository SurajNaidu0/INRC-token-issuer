// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken{
    //Token metadata
    string public name;
    string public symbol;
    uint8 public decimals;

    // Tocken state
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    //Owner of the contract 
    address public owner;

    //Blacklist feature (similar to USDT)
    mapping(address => bool) public isBlacklisted;

    //Contract Pause feature
    bool public paused;

    //Event 
    // Events required by the ERC20 standard
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    // Additional events for admin functions
    event Blacklisted(address indexed target);
    event UnBlacklisted(address indexed target);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    // Pause feature (similar to USDT)
    event Paused();
    event Unpaused();

    //Errors
    error InsufficientBalance();
    error InsufficientAllowance();
    error AddressBlacklisted();
    error OnlyOwner();
    error ContractPaused();
    error AllowanceUnderflow();
  
    


    //
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;

        //Mint intial supply to the contract creator
        _mint(msg.sender, _initialSupply);
    }

    //Modifiers
     //Modifier to make a function callable only by the owner.
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }
    //Modifier to check if an address is not blacklisted.
    modifier notBlacklisted(address _address) {
        if (isBlacklisted[_address]) revert AddressBlacklisted();
        _;
    }
    //Modifier to check of the contract is not paused.
     modifier whenNotPaused() {
        if(paused) revert ContractPaused();
        _;
    }

    /**
     * @dev Transfer tokens from the sender to a recipient.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @return Success boolean.
     */
    function transfer(address _to, uint256 _value) public whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_to) returns (bool) {
        if (balanceOf[msg.sender] < _value) revert InsufficientBalance();

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    /**
     * @dev Transfer tokens from one address to another.
     * @param _from The address which you want to send tokens from.
     * @param _to The address which you want to transfer to.
     * @param _value The amount of tokens to be transferred.
     * @return Success boolean.
     */
    function transferFrom(address _from, address _to, uint256 _value) 
        public 
        whenNotPaused 
        notBlacklisted(_from) 
        notBlacklisted(_to) 
        notBlacklisted(msg.sender) 
        returns (bool) 
    {
        if(balanceOf[_from] < _value) revert InsufficientBalance();
        if(allowance[_from][msg.sender] <_value) revert InsufficientAllowance();
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        if (allowance[_from][msg.sender] != type(uint256).max) {
            allowance[_from][msg.sender] -= _value;
        }
        
        emit Transfer(_from, _to, _value);
        return true;
    }
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     * @return Success boolean.
     */
    function approve(address _spender, uint256 _value) 
        public 
        notBlacklisted(msg.sender) 
        notBlacklisted(_spender) 
        returns (bool) 
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    /**
     * @dev Increase the amount of tokens that an owner allows a spender to use.
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     * @return Success boolean.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) 
        public 
        notBlacklisted(msg.sender) 
        notBlacklisted(_spender) 
        returns (bool) 
    {
        allowance[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }
    /**
     * @dev Decrease the amount of tokens that an owner allows a spender to use.
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     * @return Success boolean.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) 
    public 
    notBlacklisted(msg.sender) 
    notBlacklisted(_spender) 
    returns (bool) 
    {
    uint256 currentAllowance = allowance[msg.sender][_spender];

    if (currentAllowance < _subtractedValue) revert AllowanceUnderflow();

    allowance[msg.sender][_spender] = currentAllowance - _subtractedValue;
    emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

    return true;
    }
    /**
     * @dev Internal function that mints an amount of the token and assigns it to an account.
     * @param _to The account that will receive the created tokens.
     * @param _amount The amount that will be created.
     */
    function _mint(address _to, uint256 _amount) internal {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        
        emit Transfer(address(0), _to, _amount);
        emit Mint(_to, _amount);
    }
    
    /**
     * @dev Burns tokens from a specific address.
     * @param _from The account whose tokens will be burnt.
     * @param _amount The amount that will be burnt.
     */
    function _burn(address _from, uint256 _amount) internal {
        if (balanceOf[_from] <_amount) revert InsufficientBalance();
        
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
        
        emit Transfer(_from, address(0), _amount);
        emit Burn(_from, _amount);
    }
    // ========== OWNER FUNCTIONS ==========
    /**
     * @dev Mint new tokens and assign them to an account.
     * Can only be called by the current owner.
     * @param _to The account that will receive the created tokens.
     * @param _amount The amount of tokens to create.
     */
    function mint(address _to, uint256 _amount) 
        public 
        onlyOwner
        notBlacklisted(_to) 
    {
        _mint(_to, _amount);
    }
    /**
     * @dev Burns tokens from a specified account.
     * Can only be called by the current owner.
     * @param _from The account whose tokens will be burnt.
     * @param _amount The amount of tokens to burn.
     */
    function burn(address _from, uint256 _amount) public onlyOwner notBlacklisted(_from){
        _burn(_from, _amount);
    }
    /**
     * @dev Add an address to the blacklist.
     * @param _address The address to blacklist.
     */
    function blacklist(address _address) 
        public 
        onlyOwner 
    {
        isBlacklisted[_address] = true;
        emit Blacklisted(_address);
    }
    /**
     * @dev Remove an address from the blacklist.
     * @param _address The address to remove from the blacklist.
     */
    function unBlacklist(address _address) 
        public 
        onlyOwner 
    {
        isBlacklisted[_address] = false;
        emit UnBlacklisted(_address);
    }
    /**
     * @dev Pause all token transfers.
     */
    function pause() 
        public 
        onlyOwner 
    {
        paused = true;
        emit Paused();
    }
    /**
     * @dev Unpause all token transfers.
     */
    function unpause() 
        public 
        onlyOwner 
    {
        paused = false;
        emit Unpaused();
    }
    /**
     * @dev Transfer ownership of the contract to a new account.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) 
        public 
        onlyOwner 
    {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}