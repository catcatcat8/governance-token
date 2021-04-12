import brownie
import pytest


@pytest.mark.parametrize("idx", range(3))
def test_approve(token, idx):
    owners = token.getOwners()
    assert token.allowance(owners[0], owners[idx]) == 0

    token.approve(owners[1], 10**19, {'from': owners[0]})
    assert token.allowance(owners[0], owners[1]) == 10**19

    token.approve(owners[1], 12345678, {'from': owners[0]})
    assert token.allowance(owners[0], owners[1]) == 12345678


def test_transfer_from_with_approval(token):
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