import brownie
import pytest

@pytest.mark.parametrize("idx", range(3))
def test_owner_generated_with_zero_balance(token, idx):
    owners = token.getOwners()

    assert token.balanceOf(owners[idx]) == 0


def test_mint_and_transfer_tokens(token):
    total_balances = 0
    total_supply = token.totalSupply()
    owner = token.getOwners()[0]
    amount = 0.5*(10**18)  # 0.5 ether
    token.deposit({'value' : amount, 'from' : owner})

    assert token.balanceOf(owner) == amount  # 1 token = 1 wei
    assert token.totalBalances() == total_balances + amount
    assert token.totalSupply() == total_supply + amount

    sender = token.getOwners()[1]
    send_tokens = 0.2*(10**18)
    token.transfer(sender, 0.2*(10**18), {'from' : owner})

    assert token.balanceOf(owner) == amount - send_tokens
    assert token.balanceOf(sender) == send_tokens


def test_propotions_of_deposit_shares(accounts, token):
    owners = token.getOwners()  # owners have zero balance
    owners_number = len(owners)  # 3 by default
    amount = 1000
    token.deposit({'value' : amount, 'from': accounts[0]})

    assert token.balanceOf(owners[0]) == amount // owners_number
    assert token.balanceOf(owners[1]) == amount // owners_number
    assert token.balanceOf(owners[2]) == amount // owners_number

    balances = amount // owners_number
    token.transfer(owners[1], balances, {'from' : owners[0]})  # current shares should be: owner0 = 0%, owner1 = 66.(6)%, owner2 = 33.(3)%

    owner_0_balance = token.balanceOf(owners[0])
    owner_1_balance = token.balanceOf(owners[1])
    owner_2_balance = token.balanceOf(owners[2])
    total_balances = token.totalBalances()

    new_tokens = 500
    token.deposit({'value' : new_tokens, 'from' : accounts[0]})

    assert token.balanceOf(owners[0]) == owner_0_balance + (owner_0_balance * new_tokens // total_balances)
    assert token.balanceOf(owners[1]) == owner_1_balance + (owner_1_balance * new_tokens // total_balances)
    assert token.balanceOf(owners[2]) == owner_2_balance + (owner_2_balance * new_tokens // total_balances)



def test_insufficient_balance(token):
    owners = token.getOwners()
    sender_balance = token.balanceOf(owners[0])
    receiver_balance = token.balanceOf(owners[1])
    
    with brownie.reverts():
        token.transfer(owners[1], sender_balance + 1, {'from' : owners[0]})


@pytest.mark.parametrize("idx", range(3))
def test_approve(token, idx):
    owners = token.getOwners()
    assert token.allowance(owners[0], owners[idx]) == 0

    token.approve(owners[1], 10**19, {'from': owners[0]})
    assert token.allowance(owners[0], owners[1]) == 10**19

    token.approve(owners[1], 12345678, {'from': owners[0]})
    assert token.allowance(owners[0], owners[1]) == 12345678


def test_transfer_from(token):
    owners = token.getOwners()
    receiver_balance = token.balanceOf(owners[2])
    amount = 100000

    token.deposit({'value' : amount, 'from': owners[0]})
    token.approve(owners[1], amount, {'from': owners[0]})
    token.transferFrom(owners[0], owners[2], amount, {'from': owners[1]})

    assert token.balanceOf(owners[2]) == receiver_balance + amount
    

def test_transfer_from_with_no_approval(token):
    owners = token.getOwners()
    token.deposit({'value' : 100000, 'from': owners[0]})
    balance = token.balanceOf(owners[0])

    with brownie.reverts():
        token.transferFrom(owners[0], owners[2], balance, {'from': owners[1]})
    