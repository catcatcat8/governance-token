import brownie

def test_add_new_owner_and_mint(accounts, token):
    owners = token.getOwners()
    owners_number_before_adding = len(owners)
    token.addOwner(accounts[4], {'from': accounts[4]})
    owners = token.getOwners()
    owners_number_after_adding = len(owners)

    assert owners_number_before_adding == owners_number_after_adding - 1
    assert token.isOwner(accounts[4]) == True
    assert token.balanceOf(accounts[4]) == 0

    total_supply = token.totalSupply()
    new_owner_tokens = 1000
    token.deposit({'value': new_owner_tokens, 'from': accounts[4]})

    assert token.balanceOf(accounts[4]) == new_owner_tokens
    assert token.totalSupply() == total_supply + new_owner_tokens


def test_add_owner_not_msg_sender(accounts, token):
    with brownie.reverts():
        token.addOwner(accounts[4], {'from': accounts[5]})


def test_add_already_existing_owner(token):
    owners = token.getOwners()
    with brownie.reverts():
        token.addOwner(owners[0], {'from': owners[0]})