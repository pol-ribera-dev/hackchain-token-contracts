// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/HackTokenERC20.sol";
import "../src/IncentivesPool.sol";
import "../src/StakingContract.sol";

contract StakingTest is Test {

    HackToken _hacktoken;
    IncentivesPool _pool;
    StakingContract _staking;


    /// @notice The contract owner (admin).
    address public admin = vm.addr(1);

    /// @notice Random user (not the owner).
    address public randomUser = vm.addr(2);

    /// @notice Deploys the HackToken contract, the Pool contract and the StakingContract
    function setUp() public {
        vm.startPrank(admin);
        _hacktoken = new HackToken();
        _pool = new IncentivesPool(address(_hacktoken));
        _staking = new StakingContract(address(_hacktoken), address(_pool));
        _pool.grantRole(_pool.DISTRIBUTOR_ROLE(), address(_staking));
        vm.stopPrank();
    }

    // Rendimientos adicionales a través de finanzas descentralizadas
    // M1
    function testStakeCorrect() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(randomUser, 11000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_staking), 11000 * 1e18);

        _staking.stake(1000 * 1e18, 30 days);
        _staking.stake(10000 * 1e18, 365 days);

        vm.warp(block.timestamp + 367 days);

        assert(_hacktoken.balanceOf(randomUser) == 0);

        _staking.unstake(0);

        assert(_hacktoken.balanceOf(randomUser) == 1050 * 1e18);

        _staking.unstake(1);

        assert(_hacktoken.balanceOf(randomUser) == (11000 + 1050) * 1e18);

        vm.stopPrank();
    }

    function testStakeFuzzInvalidDuration(uint256 time) external {

        vm.assume(time != 30 days);
        vm.assume(time != 365 days);

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(randomUser, 11000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_staking), 11000 * 1e18);
        
        vm.expectRevert(StakingContract.InvalidDuration.selector);
        _staking.stake(1000 * 1e18, time);

        vm.stopPrank();
    }

    function testStakeAmountTooLowMonth() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(randomUser, 11000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_staking), 11000 * 1e18);
        
        vm.expectRevert(StakingContract.AmountTooLow.selector);
        _staking.stake(100 * 1e18, 30 days);

        vm.stopPrank();
    }

    function testStakeAmountTooLowYear() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(randomUser, 11000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_staking), 11000 * 1e18);
        
        vm.expectRevert(StakingContract.AmountTooLow.selector);
        _staking.stake(100 * 1e18, 365 days);

        vm.stopPrank();
    }

    function testStakeNoFunds() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_staking), 11000 * 1e18);
        
        vm.expectRevert();
        _staking.stake(1000 * 1e18, 30 days);
        
        vm.stopPrank();
    }
    
    function testStakeNoApprove() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(randomUser, 11000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);
                
        vm.expectRevert();
        _staking.stake(1000 * 1e18, 30 days);
        
        vm.stopPrank();
    }

    function testUnstakeNotFound() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(randomUser, 11000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_staking), 11000 * 1e18);

        _staking.stake(1000 * 1e18, 30 days);

        vm.warp(block.timestamp + 367 days);

        vm.expectRevert(StakingContract.StakeNotFound.selector);
        _staking.unstake(1);

        vm.stopPrank();
    }

    function testUnstakeInactive() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(randomUser, 11000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_staking), 11000 * 1e18);

        _staking.stake(1000 * 1e18, 30 days);

        vm.warp(block.timestamp + 367 days);

        _staking.unstake(0);
        vm.expectRevert(StakingContract.StakeAlreadyInactive.selector);
        _staking.unstake(0);

        vm.stopPrank();
    }

    function testUnstakeNotOver() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(admin, 1500 * 1e18);
        _hacktoken.approve(address(_pool), 1500 * 1e18);
        _pool.fundPool(1500 * 1e18);
        _hacktoken.mintTokens(randomUser, 11000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_staking), 11000 * 1e18);

        _staking.stake(1000 * 1e18, 30 days);
        
        vm.expectRevert(StakingContract.StakingPeriodNotOver.selector);
        _staking.unstake(0);

        vm.stopPrank();
    }

    function testUnstakeNoPoolFunds() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(randomUser, 11000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_staking), 11000 * 1e18);

        _staking.stake(1000 * 1e18, 30 days);

        vm.warp(block.timestamp + 367 days);

        vm.expectRevert();
        _staking.unstake(0);

        vm.stopPrank();
    }

    //M6

    function testComisionsCorrect() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(randomUser, 100000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);

       
        _hacktoken.approve(address(_staking), 100000 * 1e18);
        _staking.stake(100000 * 1e18, 365 days);

        _staking.activateNoCommission();
        assertTrue(_staking.hasNoCommission(randomUser));

        _staking.deactivateNoCommission();
        assertFalse(_staking.hasNoCommission(randomUser));

        vm.stopPrank();
    }

    function testNoCommissionAlreadyActive() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(randomUser, 100000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);

        _hacktoken.approve(address(_staking), 100000 * 1e18);
        _staking.stake(100000 * 1e18, 365 days);
        _staking.activateNoCommission();
        vm.expectRevert(StakingContract.NoCommissionAlreadyActive.selector);        
        _staking.activateNoCommission();
        
        vm.stopPrank();
    }

    function testNoCommissionNotEligible() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(randomUser, 100000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);

        vm.expectRevert(StakingContract.NoCommissionNotEligible.selector);        
        _staking.activateNoCommission();
        
        vm.stopPrank();
    }

    function testNoCommissionNotActive() external {

        vm.startPrank(admin);
        _hacktoken.mintTokens(randomUser, 100000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);

        vm.expectRevert(StakingContract.NoCommissionNotActive.selector);        
        _staking.deactivateNoCommission();
        
        vm.stopPrank();
    }

}