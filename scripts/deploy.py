#!/usr/bin/python3

from brownie import GovernanceToken, accounts


def main():
    return GovernanceToken.deploy((accounts[1], accounts[2], accounts[3]), {'from': accounts[0]})
