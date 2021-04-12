import brownie
import pytest

@pytest.mark.parametrize("idx", range(3))
def test_owner_generated_with_zero_balance(token, idx):
    owners = token.getOwners()

    assert token.isOwner(owners[idx]) == True
    assert token.balanceOf(owners[idx]) == 0