import brownie

def test_withdraw(accounts, token):
    amount = 1000
    token.deposit({'value' : amount, 'from': accounts[0]})
    balance = token.balanceOf(accounts[2])

    withdraw_amount = 200
    account_balance_before_withdraw = accounts[2].balance()
    token.withdraw(withdraw_amount, {'from': accounts[2]})

    assert token.balanceOf(accounts[2]) == balance - withdraw_amount
    assert accounts[2].balance() == account_balance_before_withdraw + withdraw_amount