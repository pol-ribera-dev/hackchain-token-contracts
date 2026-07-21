// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/HackTokenERC20.sol";
import "../src/IncentivesPool.sol";
import "../src/StakingContract.sol";
import "../src/ReferralSystem.sol";

contract StakingTest is Test {

    HackToken _hacktoken;
    IncentivesPool _pool;
    StakingContract _staking;
    ReferralSystem _referal;

    address public admin = vm.addr(1);

    address public referrerUser = vm.addr(2);

    address public referredUser = vm.addr(3);

    function setUp() public {
        vm.startPrank(admin);
        _hacktoken = new HackToken();
        _pool = new IncentivesPool(address(_hacktoken));
        _staking = new StakingContract(address(_hacktoken), address(_pool));
        _referal = new ReferralSystem(address(_pool), address(_staking));
        _pool.grantRole(_pool.DISTRIBUTOR_ROLE(), address(_referal));
        vm.stopPrank();
    }

    // Sistema de referidos
    //M2
    function testReferCorrect() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(referredUser, 1500 * 1e18);
        vm.stopPrank();

        vm.startPrank(referredUser);

        uint amountBefore = _hacktoken.balanceOf(referrerUser);
        _referal.registerReferral(referrerUser);

        _hacktoken.approve(address(_staking), 1000 * 1e18);

        _staking.stake(1000 * 1e18, 30 days);

        _referal.validateReferral();

        uint amountAfter = _hacktoken.balanceOf(referrerUser);
        assertEq(amountAfter, amountBefore + 1000 * 1e18);

        vm.stopPrank();
    }

    function testReferInvalidAddress() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(referredUser, 1500 * 1e18);
        vm.stopPrank();

        vm.startPrank(referredUser);

        vm.expectRevert(ReferralSystem.InvalidAddress.selector);
        _referal.registerReferral(address(0));

        vm.stopPrank();
    }

    function testReferCannotReferYourself() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(referredUser, 1500 * 1e18);
        vm.stopPrank();

        vm.startPrank(referredUser);

        vm.expectRevert(ReferralSystem.CannotReferYourself.selector);
        _referal.registerReferral(referredUser);

        vm.stopPrank();
    }

    function testReferAlreadyReferred() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(referredUser, 1500 * 1e18);
        vm.stopPrank();

        vm.startPrank(referredUser);

        _referal.registerReferral(referrerUser);
        vm.expectRevert(ReferralSystem.AlreadyReferred.selector);
        _referal.registerReferral(referrerUser);

        vm.stopPrank();
    }

    function testValidateReferNotReferred() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(referredUser, 1500 * 1e18);
        vm.stopPrank();

        vm.startPrank(referredUser);

        _hacktoken.approve(address(_staking), 1000 * 1e18);

        _staking.stake(1000 * 1e18, 30 days);
        
        vm.expectRevert(ReferralSystem.NotReferred.selector);
        _referal.validateReferral();

        vm.stopPrank();
    }

    function testValidateReferReferralAlreadyValidated() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(referredUser, 1500 * 1e18);
        vm.stopPrank();

        vm.startPrank(referredUser);

        _referal.registerReferral(referrerUser);

        _hacktoken.approve(address(_staking), 1000 * 1e18);

        _staking.stake(1000 * 1e18, 30 days);
        _referal.validateReferral();

        vm.expectRevert(ReferralSystem.ReferralAlreadyValidated.selector);
        _referal.validateReferral();

        vm.stopPrank();
    }

    function testValidateReferReferredUserNotStaking() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(referredUser, 1500 * 1e18);
        vm.stopPrank();

        vm.startPrank(referredUser);
        _referal.registerReferral(referrerUser);
        _hacktoken.approve(address(_staking), 1000 * 1e18);
        vm.expectRevert(ReferralSystem.ReferredUserNotStaking.selector);
        _referal.validateReferral();

        vm.stopPrank(); 
    }

    function testValidateReferMonthlyLimitReached() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 15000 * 1e18);
        _hacktoken.approve(address(_pool), 15000 * 1e18);
        _pool.fundPool(15000 * 1e18);
        _hacktoken.mintTokens(referredUser, 1500 * 1e18);
        _hacktoken.mintTokens(address(11), 1500 * 1e18);
        _hacktoken.mintTokens(address(12), 1500 * 1e18);
        _hacktoken.mintTokens(address(13), 1500 * 1e18);
        _hacktoken.mintTokens(address(14), 1500 * 1e18);
        _hacktoken.mintTokens(address(15), 1500 * 1e18);

        vm.stopPrank();

        vm.startPrank(address(11));
        _referal.registerReferral(referrerUser);
        _hacktoken.approve(address(_staking), 1000 * 1e18);
        _staking.stake(1000 * 1e18, 30 days);
        _referal.validateReferral();
        vm.stopPrank();

        vm.startPrank(address(12));
        _referal.registerReferral(referrerUser);
        _hacktoken.approve(address(_staking), 1000 * 1e18);
        _staking.stake(1000 * 1e18, 30 days);
        _referal.validateReferral();
        vm.stopPrank();

        vm.startPrank(address(13));
        _referal.registerReferral(referrerUser);
        _hacktoken.approve(address(_staking), 1000 * 1e18);
        _staking.stake(1000 * 1e18, 30 days);
        _referal.validateReferral();
        vm.stopPrank();

        vm.startPrank(address(14));
        _referal.registerReferral(referrerUser);
        _hacktoken.approve(address(_staking), 1000 * 1e18);
        _staking.stake(1000 * 1e18, 30 days);
        _referal.validateReferral();
        vm.stopPrank();

        vm.startPrank(address(15));
        _referal.registerReferral(referrerUser);
        _hacktoken.approve(address(_staking), 1000 * 1e18);
        _staking.stake(1000 * 1e18, 30 days);
        _referal.validateReferral();
        vm.stopPrank();

        vm.startPrank(referredUser);
        _referal.registerReferral(referrerUser);
        _hacktoken.approve(address(_staking), 1000 * 1e18);
        _staking.stake(1000 * 1e18, 30 days);
        vm.expectRevert(ReferralSystem.MonthlyLimitReached.selector);
        _referal.validateReferral();

        vm.stopPrank();
    }

    function testValidateRefer6referredDiferentsMonth() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 15000 * 1e18);
        _hacktoken.approve(address(_pool), 15000 * 1e18);
        _pool.fundPool(15000 * 1e18);
        _hacktoken.mintTokens(referredUser, 1500 * 1e18);
        _hacktoken.mintTokens(address(11), 1500 * 1e18);
        _hacktoken.mintTokens(address(12), 1500 * 1e18);
        _hacktoken.mintTokens(address(13), 1500 * 1e18);
        _hacktoken.mintTokens(address(14), 1500 * 1e18);
        _hacktoken.mintTokens(address(15), 1500 * 1e18);

        vm.stopPrank();

        uint amountBefore = _hacktoken.balanceOf(referrerUser);

        vm.startPrank(address(11));
        _referal.registerReferral(referrerUser);
        _hacktoken.approve(address(_staking), 1000 * 1e18);
        _staking.stake(1000 * 1e18, 30 days);
        _referal.validateReferral();
        vm.stopPrank();

        vm.startPrank(address(12));
        _referal.registerReferral(referrerUser);
        _hacktoken.approve(address(_staking), 1000 * 1e18);
        _staking.stake(1000 * 1e18, 30 days);
        _referal.validateReferral();
        vm.stopPrank();

        vm.startPrank(address(13));
        _referal.registerReferral(referrerUser);
        _hacktoken.approve(address(_staking), 1000 * 1e18);
        _staking.stake(1000 * 1e18, 30 days);
        _referal.validateReferral();
        vm.stopPrank();

        vm.startPrank(address(14));
        _referal.registerReferral(referrerUser);
        _hacktoken.approve(address(_staking), 1000 * 1e18);
        _staking.stake(1000 * 1e18, 30 days);
        _referal.validateReferral();
        vm.stopPrank();

        vm.startPrank(address(15));
        _referal.registerReferral(referrerUser);
        _hacktoken.approve(address(_staking), 1000 * 1e18);
        _staking.stake(1000 * 1e18, 30 days);
        _referal.validateReferral();
        vm.stopPrank();

        vm.warp(block.timestamp + 31 days);

        vm.startPrank(referredUser);
        _referal.registerReferral(referrerUser);
        _hacktoken.approve(address(_staking), 1000 * 1e18);
        _staking.stake(1000 * 1e18, 30 days);
        _referal.validateReferral();

        uint amountAfter = _hacktoken.balanceOf(referrerUser);

        assertEq(amountAfter, amountBefore + 6000 * 1e18);

        vm.stopPrank();
    }
}