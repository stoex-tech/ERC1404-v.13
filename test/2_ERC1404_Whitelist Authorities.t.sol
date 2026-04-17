// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// Test Suite 2   -  Test Whitelist authorities and set reset thier status.
// Check addresses after setting whitelist status
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ERC1404.sol";
import "./helpers/ERC1404_Base_Setup.sol";

import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

contract ERC1404_Whitelist_Authorities is ERC1404_Base_Setup {
    function setUp() public override {
        ERC1404_Base_Setup.setUp();
    }

    function test_CheckDefaultWhiteListAuthorityStatusForOwner() public view{
        // Check that owner of the token address is  whitelisted by default
        (uint receiveRestriction, uint sendRestriction) = token.getKYCData(token.owner());
        assertEq(receiveRestriction, 1);
        assertEq(sendRestriction, 1);
    }

    function test_CheckDefaultWhiteListAuthorityStatusForSwapContract() public view{
        // Check address set as Swap Token is also whitelisted
        (uint receiveRestriction, uint sendRestriction) = token.getKYCData(atomicSwapContractAddress);
        assertEq(receiveRestriction, 1);
        assertEq(sendRestriction, 1);
    }

    function test_getWhitelistAuthorityStatusNotWhitelisted() public view{
        bool v1 = token.hasRole(token.WHITELIST_ROLE(), addr1);
        assertEq(v1, false);
    }

    function test_SetWhitelistAuthorityStatus() public {
        token.grantRole(token.WHITELIST_ROLE(), addr1);
        bool v1 = token.hasRole(token.WHITELIST_ROLE(), addr1);
        assertEq(v1, true);
    }

    function test_removeWhitelistAuthorityStatusAsDeployer() public {
        token.grantRole(token.WHITELIST_ROLE(), addr1);
        // remove whitelist authority status
        token.revokeRole(token.WHITELIST_ROLE(), addr1);
        bool v2 = token.hasRole(token.WHITELIST_ROLE(), addr1);
        assertEq(v2, false);
    }

    function test_removeWhitelistAuthorityStatusAsTokenOwner() public {
        vm.startPrank(token.owner());
        token.grantRole(token.WHITELIST_ROLE(), addr1);
        // remove whitelist authority status
        token.revokeRole(token.WHITELIST_ROLE(), addr1);
        bool v2 = token.hasRole(token.WHITELIST_ROLE(), addr1);
        assertEq(v2, false);
        vm.stopPrank();
    }

    function test_notAuthorizedModifyKYCData() public {
        vm.startPrank(addr1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                addr1,
                token.WHITELIST_ROLE()
            )
        );
        token.modifyKYCData(addr2, 1, 1);
        vm.stopPrank();
    }

    function test_authorizedModifyKYCData() public {
        // set whitelist authority
        token.grantRole(token.WHITELIST_ROLE(), addr1);
        // now switch to whitelist authority and set another address whitelisted
        vm.prank(addr1);
        token.modifyKYCData(addr2, 1, 1);
        (uint receiveRestriction, uint sendRestriction) = token.getKYCData(addr2);
        assertEq(receiveRestriction, 1);
        assertEq(sendRestriction, 1);
    }
}
