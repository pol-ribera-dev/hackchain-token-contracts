// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/HackTokenERC20.sol";
import "../src/IncentivesPool.sol";
import "../src/ReputationBunises.sol";

contract ReputationTest is Test {

    HackToken _hacktoken;
    IncentivesPool _pool;
    ReputationBonuses _reputation;

    address public admin = vm.addr(1);

    address public randomUser = vm.addr(2);

    function setUp() public {
        vm.startPrank(admin);
        _hacktoken = new HackToken();
        _pool = new IncentivesPool(address(_hacktoken));
        _reputation = new ReputationBonuses(address(_pool));
        _pool.grantRole(_pool.DISTRIBUTOR_ROLE(), address(_reputation));
        vm.stopPrank();

        vm.warp(block.timestamp + 36 days);

    }

    // Bonus
    //M15
    function testBonusReputationTalentCorrect() external {
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _reputation.registerWinner(ReputationBonuses.UserRole.Talent, randomUser);

        vm.stopPrank();

        vm.startPrank(randomUser);

        _reputation.claimBonus(ReputationBonuses.UserRole.Talent);
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 5000 * 1e18, amountAfterUser);

        vm.stopPrank();
    }

    function testBonusReputationInvalidAddress() external {
        vm.startPrank(admin);

        vm.expectRevert(ReputationBonuses.InvalidAddress.selector);   
        _reputation.registerWinner(ReputationBonuses.UserRole.Talent, address(0));

        vm.stopPrank();
    }

    function testBonusReputationAlreadyRegistered() external {
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        _reputation.registerWinner(ReputationBonuses.UserRole.Talent, randomUser);
        vm.expectRevert(ReputationBonuses.WinnerAlreadyRegistered.selector);   
        _reputation.registerWinner(ReputationBonuses.UserRole.Talent, randomUser);

        vm.stopPrank();
    }

    function testBonusReputationRegisterDiferentRoles() external {
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        _reputation.registerWinner(ReputationBonuses.UserRole.Talent, randomUser);
        _reputation.registerWinner(ReputationBonuses.UserRole.Educator, randomUser);

        vm.stopPrank();
    }

    function testBonusReputationRegisterDiferentMonth() external {
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        _reputation.registerWinner(ReputationBonuses.UserRole.Talent, randomUser);
        vm.warp(block.timestamp + 36 days);
        _reputation.registerWinner(ReputationBonuses.UserRole.Talent, randomUser);

        vm.stopPrank();
    }

    function testNoBonusForThisMonth() external {
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        vm.stopPrank();

        vm.startPrank(randomUser);

        vm.expectRevert(ReputationBonuses.NoBonusForThisMonth.selector);
        _reputation.claimBonus(ReputationBonuses.UserRole.Talent);

        vm.stopPrank();
    }

    function testNotTheWinner() external {
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        _reputation.registerWinner(ReputationBonuses.UserRole.Talent, admin);

        vm.stopPrank();

        vm.startPrank(randomUser);

        vm.expectRevert(ReputationBonuses.NotTheWinner.selector);
        _reputation.claimBonus(ReputationBonuses.UserRole.Talent);

        vm.stopPrank();
    }

    function testAlreadyClaimed() external {
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        _reputation.registerWinner(ReputationBonuses.UserRole.Talent, randomUser);

        vm.stopPrank();

        vm.startPrank(randomUser);

        _reputation.claimBonus(ReputationBonuses.UserRole.Talent);
        vm.expectRevert(ReputationBonuses.AlreadyClaimed.selector);
        _reputation.claimBonus(ReputationBonuses.UserRole.Talent);

        vm.stopPrank();
    }

    function testClaimWindowExpired() external {
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        _reputation.registerWinner(ReputationBonuses.UserRole.Talent, randomUser);

        vm.stopPrank();

        vm.startPrank(randomUser);

        vm.warp(block.timestamp + 4 days);

        vm.expectRevert(ReputationBonuses.ClaimWindowExpired.selector);
        _reputation.claimBonus(ReputationBonuses.UserRole.Talent);

        vm.stopPrank();
    }

    //M16
    function testBonusReputationEducatorCorrect() external {
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _reputation.registerWinner(ReputationBonuses.UserRole.Educator, randomUser);

        vm.stopPrank();

        vm.startPrank(randomUser);

        _reputation.claimBonus(ReputationBonuses.UserRole.Educator);
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 5000 * 1e18, amountAfterUser);

        vm.stopPrank();
    }


    //M17
    function testBonusReputationRecruiterCorrect() external {
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _reputation.registerWinner(ReputationBonuses.UserRole.Recruiter, randomUser);

        vm.stopPrank();

        vm.startPrank(randomUser);

        _reputation.claimBonus(ReputationBonuses.UserRole.Recruiter);
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 5000 * 1e18, amountAfterUser);

        vm.stopPrank();
    }
}