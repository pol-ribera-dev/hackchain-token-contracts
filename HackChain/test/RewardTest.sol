// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/HackTokenERC20.sol";
import "../src/IncentivesPool.sol";
import "../src/EventRewards.sol";

contract RewardTest is Test {

    HackToken _hacktoken;
    IncentivesPool _pool;
    EventRewards _reward;

    address public admin = vm.addr(1);

    address public randomUser = vm.addr(2);

    function setUp() public {
        vm.startPrank(admin);
        _hacktoken = new HackToken();
        _pool = new IncentivesPool(address(_hacktoken));
        _reward = new EventRewards(address(_pool));
        _pool.grantRole(_pool.DISTRIBUTOR_ROLE(), address(_reward));
        vm.stopPrank();
    }

    // Reward
    //M5
    function testRewardCorrect() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 30000 * 1e18);
        _hacktoken.approve(address(_pool), 30000 * 1e18);
        _pool.fundPool(30000 * 1e18);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);

        _reward.rewardPromoEvent(randomUser, keccak256("talk"), 13);

        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 30000 * 1e18, amountAfterUser);

        vm.stopPrank();
        
    }

    function testRewardInvalidAddress() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 30000 * 1e18);
        _hacktoken.approve(address(_pool), 30000 * 1e18);
        _pool.fundPool(30000 * 1e18);

        vm.expectRevert(EventRewards.InvalidAddress.selector);
        _reward.rewardPromoEvent(address(0), keccak256("talk"), 13);

        vm.stopPrank();
    }

    function testRewardNotEnoughAttendees() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 30000 * 1e18);
        _hacktoken.approve(address(_pool), 30000 * 1e18);
        _pool.fundPool(30000 * 1e18);

        vm.expectRevert(EventRewards.NotEnoughAttendees.selector);
        _reward.rewardPromoEvent(randomUser, keccak256("talk"), 7);

        vm.stopPrank();
    }

    function testRewardAlreadyRewarded() external {
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 30000 * 1e18);
        _hacktoken.approve(address(_pool), 30000 * 1e18);
        _pool.fundPool(30000 * 1e18);

        _reward.rewardPromoEvent(randomUser, keccak256("talk"), 13);
        vm.expectRevert(EventRewards.PromoEventAlreadyRewarded.selector);
        _reward.rewardPromoEvent(randomUser, keccak256("talk"), 13);

        vm.stopPrank();
    }
    

    //M10
    function testGo4EventsCorrect() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 4000 * 1e18);
        _hacktoken.approve(address(_pool), 4000 * 1e18);
        _pool.fundPool(4000 * 1e18);

        _reward.registerTalentAttendance(randomUser);
        _reward.registerTalentAttendance(randomUser);
        _reward.registerTalentAttendance(randomUser);
        _reward.registerTalentAttendance(randomUser);
        vm.stopPrank();

        vm.startPrank(randomUser);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _reward.claimTalentAttendanceReward();
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 4000 * 1e18, amountAfterUser);
        vm.stopPrank();
        
    }

    function testRegisterInvalidAddress() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 4000 * 1e18);
        _hacktoken.approve(address(_pool), 4000 * 1e18);
        _pool.fundPool(4000 * 1e18);

        vm.expectRevert(EventRewards.InvalidAddress.selector);
        _reward.registerTalentAttendance(address(0));
        
        vm.stopPrank();
    }

    function testGo4EventsMonthlyRewardAlreadyClaimed() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 4000 * 1e18);
        _hacktoken.approve(address(_pool), 4000 * 1e18);
        _pool.fundPool(4000 * 1e18);

        _reward.registerTalentAttendance(randomUser);
        _reward.registerTalentAttendance(randomUser);
        _reward.registerTalentAttendance(randomUser);
        _reward.registerTalentAttendance(randomUser);
        vm.stopPrank();

        vm.startPrank(randomUser);

        _reward.claimTalentAttendanceReward();
        vm.expectRevert(EventRewards.MonthlyRewardAlreadyClaimed.selector);
        _reward.claimTalentAttendanceReward();

        vm.stopPrank();
    }

    function testGo4EventsNotEnoughEventsThisMonth() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 4000 * 1e18);
        _hacktoken.approve(address(_pool), 4000 * 1e18);
        _pool.fundPool(4000 * 1e18);

        _reward.registerTalentAttendance(randomUser);
        _reward.registerTalentAttendance(randomUser);
        _reward.registerTalentAttendance(randomUser);
        vm.stopPrank();

        vm.startPrank(randomUser);

        vm.expectRevert(EventRewards.NotEnoughEventsThisMonth.selector);
        _reward.claimTalentAttendanceReward();

        vm.stopPrank();
    }

    function testGo4EventsDiferentMonth() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 4000 * 1e18);
        _hacktoken.approve(address(_pool), 4000 * 1e18);
        _pool.fundPool(4000 * 1e18);

        _reward.registerTalentAttendance(randomUser);
        _reward.registerTalentAttendance(randomUser);
        _reward.registerTalentAttendance(randomUser);
        _reward.registerTalentAttendance(randomUser);
        vm.stopPrank();

        vm.startPrank(randomUser);

        _reward.claimTalentAttendanceReward();
        vm.warp(block.timestamp + 36 days);
        vm.expectRevert(EventRewards.NotEnoughEventsThisMonth.selector);
        _reward.claimTalentAttendanceReward();

        vm.stopPrank();
    }

    // M18 
    function testRewardFirstEventCorrect() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);

        _reward.rewardEducatorFirstEvent(randomUser);

        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 5000 * 1e18, amountAfterUser);

        vm.stopPrank();
    }

    function testRewardFirstEventInvalidAddress() external {

        vm.startPrank(admin);
        vm.expectRevert(EventRewards.InvalidAddress.selector);
        _reward.rewardEducatorFirstEvent(address(0));
        vm.stopPrank();

    }

    function testRewardFirstEventAlreadyRewarded() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        _reward.rewardEducatorFirstEvent(randomUser);
        vm.expectRevert(EventRewards.FirstEventAlreadyRewarded.selector);
        _reward.rewardEducatorFirstEvent(randomUser);

        vm.stopPrank();
    }


    // M19
    function testCreate4EventsCorrect() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 4000 * 1e18);
        _hacktoken.approve(address(_pool), 4000 * 1e18);
        _pool.fundPool(4000 * 1e18);

        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        vm.stopPrank();

        vm.startPrank(randomUser);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _reward.claimEducatorMonthlyReward();
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 4000 * 1e18, amountAfterUser);
        vm.stopPrank();
        
    }

    function testCreate4EventsDiferentMonthCorrect() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 4000 * 1e18);
        _hacktoken.approve(address(_pool), 4000 * 1e18);
        _pool.fundPool(4000 * 1e18);

        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        vm.stopPrank();

        vm.startPrank(randomUser);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _reward.claimEducatorMonthlyReward();
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 4000 * 1e18, amountAfterUser);
        vm.stopPrank();
        
        vm.warp(block.timestamp + 31 days);

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 4000 * 1e18);
        _hacktoken.approve(address(_pool), 4000 * 1e18);
        _pool.fundPool(4000 * 1e18);

        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        vm.stopPrank();

        vm.startPrank(randomUser);

        amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _reward.claimEducatorMonthlyReward();
        amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 4000 * 1e18, amountAfterUser);
        vm.stopPrank();

    }

    function testCreate4EventsRegisterInvalidAddress() external {

        vm.startPrank(admin);
        vm.expectRevert(EventRewards.InvalidAddress.selector);
        _reward.registerEducatorEvent(address(0));
        vm.stopPrank();
        
    }

    function testCreate4EventsAlreadyClaimed() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 8000 * 1e18);
        _hacktoken.approve(address(_pool), 8000 * 1e18);
        _pool.fundPool(8000 * 1e18);

        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);

        vm.stopPrank();

        vm.startPrank(randomUser);
        _reward.claimEducatorMonthlyReward();
        vm.stopPrank();

        vm.startPrank(admin);
        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        vm.stopPrank();

        vm.startPrank(randomUser);
        vm.expectRevert(EventRewards.MonthlyRewardAlreadyClaimed.selector);
        _reward.claimEducatorMonthlyReward();
        vm.stopPrank();
        
    }

    function testCreate4EventsNotEnoughEventsThisMonth() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 4000 * 1e18);
        _hacktoken.approve(address(_pool), 4000 * 1e18);
        _pool.fundPool(4000 * 1e18);

        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        vm.stopPrank();

        vm.startPrank(randomUser);

        vm.expectRevert(EventRewards.NotEnoughEventsThisMonth.selector);
        _reward.claimEducatorMonthlyReward();

        vm.stopPrank();
        
    }

    function testCreate4EventsDiferentMonthNotEnoughEvents() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 4000 * 1e18);
        _hacktoken.approve(address(_pool), 4000 * 1e18);
        _pool.fundPool(4000 * 1e18);

        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        _reward.registerEducatorEvent(randomUser);
        vm.stopPrank();

        vm.startPrank(randomUser);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _reward.claimEducatorMonthlyReward();
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 4000 * 1e18, amountAfterUser);
        vm.stopPrank();
        
        vm.warp(block.timestamp + 31 days);

        vm.startPrank(randomUser);
        vm.expectRevert(EventRewards.NotEnoughEventsThisMonth.selector);
        _reward.claimEducatorMonthlyReward();
        vm.stopPrank();

    }

}