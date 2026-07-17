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

}