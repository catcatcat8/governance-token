pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract GovernanceToken is IERC20, Ownable {
    
    using SafeMath for uint256;

    event MintTokens(address receiver, uint256 value);
    event TransferTokens(address from, address to, uint256 value);
    event NewParticipant(address new_participant);  // добавление нового владельца governance-токена
    event EtherDepositFromParticipant(address participant, uint256 value);  // владелец governance-токена докупает токен за Ether
    event EtherDepositFromNonParticipant(address sender, uint256 value);  // стороннее лицо кладет Ether в контракт

    string public name = "LebedevToken";
    string public symbol = "LEB";
    uint8 public decimals = 18;
    uint256 public leftTokens = 100000e18; // 100 thousands tokens
    uint256 public totalBalances = 0;

    /// @dev Владельцы GovernanceToken
    address[] public owners;
    mapping (address => bool) public isOwner;

    /// @dev Балансы владельцев GovernanceToken
    mapping(address => uint256) balances; 

    /*
     *  Modifiers
     */
    

    /// @dev Указание участников governance-token
    /// @param _owners Участники, между которыми будут распределяться доли при переводе эфира сторонним лицом в контракт
    constructor(address[] memory _owners) public {
        for (uint i=0; i<_owners.length; i++) {
            require(_owners[i] != address(0));
            owners.push(_owners[i]);
            isOwner[_owners[i]] = true;
            balances[_owners[i]] = 0;
        }
    }

    /// @dev Добавление эфира в контракт
    function Pay() external payable {
        if (msg.value > 0) {
            /*
             *  Если эфир закидывает стороннее лицо - токены распределяются в соответствии с балансами владельцев токенов
             *  Если эфир закидывает владелец governance-токена, он приобретает токены себе по курсу: 1 LebedevToken = 1 Ether
             */
            if (isOwner[msg.sender]) {
                mint(msg.sender, msg.value);
                emit EtherDepositFromParticipant(msg.sender, msg.value);
            }
            else {
                require(!isOwner[msg.sender]);
                calculateTokens(msg.value);
                emit EtherDepositFromNonParticipant(msg.sender, msg.value);
            }
        }
    }

    /// @dev Расчет доли токенов в соответствии с балансами владельцев
    function calculateTokens(uint256 _newEther) internal {
        uint256 share;

        if (totalBalances == 0) {
            for (uint i=0; i<owners.length; i++) {
                share = _newEther.div(owners.length);
                mint(owners[i], share);
            }
        } else {
            for (uint i=0; i<owners.length; i++) {
                if (balances[owners[i]] != 0) {
                    share = balances[owners[i]].div(totalBalances).mul(_newEther);
                    mint(owners[i], share);
                }
            }
        }
    }

    /// @dev Прибавление токенов на баланс
    function mint(address _account, uint256 _tokens) internal {
        require(_account != address(0));
        require(isOwner[_account]);
        leftTokens = leftTokens.sub(_tokens);
        totalBalances = totalBalances.add(_tokens);
        balances[_account].add(_tokens);
        emit MintTokens(_account, _tokens);
    }

}