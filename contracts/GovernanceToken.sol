// Lebedev Evgenii 2021 technopark-governance-token

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GovernanceToken is IERC20, Ownable {
    using SafeMath for uint256;

    /// @notice EIP-20 token name for this token
    string public name = "LebedevToken";

    /// @notice EIP-20 token symbol for this token
    string public symbol = "LEB";

    /// @notice EIP-20 token decimals for this token
    uint8 public decimals = 18;

    /// @notice Total balances of tokens among the owners
    uint256 public override totalSupply = 0;  // total balances = 0 by default


    /// @dev Owners of GovernanceToken
    address[] public owners;
    mapping (address => bool) public isOwner;

    /// @dev Allowance amounts on behalf of others
    mapping(address => mapping(address => uint256)) internal allowances;

    /// @dev Owners' balances of GovernanceToken
    mapping(address => uint256) internal balances;


    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice An event thats emitted when owner receives tokens
    event MintTokens(address receiver, uint256 value);

    /// @notice An event of adding the new owner of tokens
    event NewParticipant(address new_participant);

    /// @notice An event thats emitted when owner of tokens deposits ether
    event EtherDepositFromParticipant(address participant, uint256 value);

    /// @notice An event thats emitted when non-owner deposits ether
    event EtherDepositFromNonParticipant(address sender, uint256 value);  // стороннее лицо кладет Ether в контракт 


    /// @dev Creating owners of GovernanceToken
    /// @param _owners Owners of GovernanceToken
    constructor(address[] memory _owners) public {
        for (uint i=0; i<_owners.length; i++) {
            require(_owners[i] != address(0));
            owners.push(_owners[i]);
            isOwner[_owners[i]] = true;
            balances[_owners[i]] = 0;
        }
    }

    /*
     *  ERC20 Functions
     */

    function allowance(address account, address spender) external override view returns (uint256) {
        return allowances[account][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(isOwner[msg.sender]);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(isOwner[msg.sender]);
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        balances[sender] = senderBalance - amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }


    /// @dev Ether deposit
    function deposit() external payable {
        if (msg.value > 0) {
            /*
             *  If the ether was deposited by the owner of GovernanceToken, he gets tokens at the rate of 1 LebedevToken = 1 Ether
             */
            if (isOwner[msg.sender]) {
                mint(msg.sender, msg.value);
                emit EtherDepositFromParticipant(msg.sender, msg.value);
            }
            /*
             *  If the ether was deposited by the non-owner of GovernanceToken, all owners gets tokens in shares proportional to the balance of GovernanceToken
             */
            else {
                require(!isOwner[msg.sender]);
                calculateTokens(msg.value);
                emit EtherDepositFromNonParticipant(msg.sender, msg.value);
            }
        }
    }

    /// @dev Calculation of the shares of tokens in proportion to the balances of the owners
    /// @param _newEther The depositted Ether
    function calculateTokens(uint256 _newEther) internal {
        uint256 share;

        if (totalSupply == 0) {
            for (uint i=0; i<owners.length; i++) {
                share = _newEther.div(owners.length);
                mint(owners[i], share);
            }
        } else {
            uint256 totalBalancesBeforeMint = totalSupply;
            for (uint i=0; i<owners.length; i++) {
                if (balances[owners[i]] != 0) {
                    share = balances[owners[i]].mul(_newEther).div(totalBalancesBeforeMint);
                    mint(owners[i], share);
                }
            }
        }
    }

    /// @dev Adding tokens to the balance of the owner
    /// @param _account Owner of the GovernanceToken
    /// @param _tokens Value of tokens
    function mint(address _account, uint256 _tokens) internal {
        require(isOwner[_account], "GovernanceToken::mint: mint to non-owner");

        totalSupply = totalSupply.add(_tokens);
        balances[_account] = balances[_account].add(_tokens);
        emit MintTokens(_account, _tokens);
    }

    function addOwner(address _account) public {
        require(!isOwner[_account], "GovernanceToken::addOwner: owner already exists");
        require(msg.sender == _account, "GovernanceToken::addOwner: it is allowed to add only the account from which the contract function is launched");

        owners.push(_account);
        isOwner[_account] = true;
        balances[_account] = 0;
        emit NewParticipant(_account);
    }

    /// @dev Getting all owners of governance-token
    function getOwners() public view returns(address[] memory) {
        return owners;
    }
    
}
