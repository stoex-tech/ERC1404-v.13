// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// Test Suite 9   -  Test minting and burning tokens
// Test different scenarios related to minintg like check minting while currentTotalInvestors
// restrition is in place. Also check all scenario related to currentTotalInvestors getting
// increased or decreased as result of minting and burbing
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ERC1404.sol";
import "./helpers/ERC1404_Base_Setup.sol";
import { IERC20Errors } from "lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

contract ERC1404_Check_Mint_Burns is ERC1404_Base_Setup {
    function setUp() public override {
        ERC1404_Base_Setup.setUp();
        token.modifyKYCData(addr1, 1, 1);
    }

    function test_Mint_New_Tokens_To_Issuer(uint128 amount) public {
        vm.assume(amount > 0);
        token.mint(token.owner(), amount);
        assertEq(token.balanceOf(token.owner()), amount + initialSupply);
        assertEq(token.totalSupply(), amount + initialSupply);
        assertEq(token.currentTotalInvestors(), 0);
    }

    function test_Mint_New_Tokens_To_Investor(uint128 amount) public {
        vm.assume(amount > 0);
        token.mint(addr1, amount);
        assertEq(token.balanceOf(addr1), amount);
        assertEq(token.totalSupply(), amount + initialSupply);
        assertEq(token.currentTotalInvestors(), 1);
    }

    function test_Mint_New_Tokens_As_Investor(uint128 amount) public {
        vm.assume(amount > 0);
        vm.startPrank(addr1);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, addr1, token.MINTER_ROLE()));
        token.mint(addr1, amount);
    }

    function test_Mint_New_Tokens_To_Investor_Not_Whitelisted(uint128 amount) public {
        vm.assume(amount > 0);
        vm.expectRevert("Address is not yet whitelisted by issuer");
        token.mint(addr4, amount);
    }

    function test_Mint_New_Tokens_Zero_Amount() public {
        vm.expectRevert("Zero amount cannot be minted");
        token.mint(addr1, 0);
    }

    function test_Burn_Tokens_Zero_Amount(uint128 amount) public {
        vm.assume(amount > 0);
        token.mint(addr1, amount);
        vm.expectRevert("Zero amount cannot be burned");
        token.burn(addr1, 0);
    }


    function test_Burn_Tokens_Issuer(uint128 amount) public {
        vm.assume(amount > 0);
        token.mint(token.owner(), amount);
        token.burn(token.owner(), amount);
        assertEq(token.balanceOf(token.owner()), initialSupply);
        assertEq(token.totalSupply(), initialSupply);
    }

    function test_Check_Address_Cannot_Burn_More_Than_Balance_Issuer() public {
        uint moreThanInitialSupply = initialSupply + 1;
        address owner = token.owner();
        uint walletBalance = token.balanceOf(owner);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, owner, walletBalance, moreThanInitialSupply));
        token.burn(owner, moreThanInitialSupply);
    }

    function test_Check_Address_Cannot_Burn_More_Than_Balance_Investor() public {
        uint walletBalance = token.balanceOf(addr1);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, addr1, walletBalance, initialSupply));
        token.burn(addr1, initialSupply);
    }  
}
