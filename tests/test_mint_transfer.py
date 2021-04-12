import brownie

def test_mint_and_transfer_tokens(token):
    owners = token.getOwners()
    total_balances = token.totalBalances()
    total_supply = token.totalSupply()
    amount = 0.5*(10**18)  # 0.5 ether
    token.deposit({'value' : amount, 'from' : owners[0]})

    assert token.balanceOf(owners[0]) == amount  # 1 token = 1 wei
    assert token.totalBalances() == total_balances + amount
    assert token.totalSupply() == total_supply + amount

    sender = token.getOwners()[1]
    send_tokens = 0.2*(10**18)
    token.transfer(sender, 0.2*(10**18), {'from' : owners[0]})

    assert token.balanceOf(owners[0]) == amount - send_tokens
    assert token.balanceOf(sender) == send_tokens


def test_mint_propotions_of_deposit_shares(accounts, token):
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


def test_insufficient_balance_transfer(token):
    owners = token.getOwners()
    sender_balance = token.balanceOf(owners[0])
    receiver_balance = token.balanceOf(owners[1])
    
    with brownie.reverts():
        token.transfer(owners[1], sender_balance + 1, {'from' : owners[0]})