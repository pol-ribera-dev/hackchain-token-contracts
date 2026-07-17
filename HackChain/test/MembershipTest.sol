// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/HackTokenERC20.sol";
import "../src/IncentivesPool.sol";
import "../src/MembershipSystem.sol";

contract StakingTest is Test {

    HackToken _hacktoken;
    IncentivesPool _pool;
    MembershipSystem _membership;

    address public tresury  = vm.addr(99);

    address public admin = vm.addr(1);

    address public randomUser = vm.addr(2);

    function setUp() public {
        vm.startPrank(admin);
        _hacktoken = new HackToken();
        _pool = new IncentivesPool(address(_hacktoken));
        _membership = new MembershipSystem(address(_hacktoken), address(_pool), tresury);
        _pool.grantRole(_pool.DEPOSITOR_ROLE(), address(_membership));
        vm.stopPrank();
    }

    // Membership
    //M3
    function testAdvancedMembershipCorrect() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(randomUser, 110000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        uint amountBeforeTresury = _hacktoken.balanceOf(tresury);
        uint amountBeforePool = _hacktoken.balanceOf(address(_pool));

        _hacktoken.approve(address(_membership), 50000 * 1e18);
        _membership.activateAdvancedMembership();

        uint amountAfterUser = _hacktoken.balanceOf(randomUser);
        uint amountAfterTresury = _hacktoken.balanceOf(tresury);
        uint amountAfterPool = _hacktoken.balanceOf(address(_pool));

        assertEq(amountBeforeUser, amountAfterUser + 50000 * 1e18);
        assertEq(amountBeforeTresury + 25000 * 1e18, amountAfterTresury);
        assertEq(amountBeforePool + 25000 * 1e18, amountAfterPool);
        
        _hacktoken.approve(address(_membership), 50000 * 1e18);
        _membership.cancelAdvancedMembership();
        
        uint amountAfterCancelUser = _hacktoken.balanceOf(randomUser);
        uint amountAfterCancelPool = _hacktoken.balanceOf(address(_pool));
        
        assertEq(amountAfterUser, amountAfterCancelUser + 1000 * 1e18);
        assertEq(amountAfterPool + 1000 * 1e18, amountAfterCancelPool);

        vm.stopPrank();
        
    }

    //M13

     function testMembershipCorrect() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(randomUser, 30000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        uint amountBeforeTresury = _hacktoken.balanceOf(tresury);


        _hacktoken.approve(address(_membership), 30000 * 1e18);
        _membership.activateAcademicMembership(MembershipSystem.AcademicTier.Monthly);

        uint amountAfterUser = _hacktoken.balanceOf(randomUser);
        uint amountAfterTresury = _hacktoken.balanceOf(tresury);

        assertEq(amountBeforeUser, amountAfterUser + 30000 * 1e18);
        assertEq(amountBeforeTresury + 15000 * 1e18, amountAfterTresury);
        vm.stopPrank();
        // Falta comprovar educadors
    }

}