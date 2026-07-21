// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/HackTokenERC20.sol";
import "../src/IncentivesPool.sol";
import "../src/PenaltySystem.sol";

contract PenaltyTest is Test {

    HackToken _hacktoken;
    IncentivesPool _pool;
    PenaltySystem _penalty;

    address public tresury  = vm.addr(99);

    address public admin = vm.addr(1);

    address public randomUser = vm.addr(2);

    function setUp() public {
        vm.startPrank(admin);
        _hacktoken = new HackToken();
        _pool = new IncentivesPool(address(_hacktoken));
        _penalty = new PenaltySystem(address(_hacktoken), address(_pool), tresury);
        _pool.grantRole(_pool.DEPOSITOR_ROLE(), address(_penalty));
        vm.stopPrank();
    }

    // Identity
    //M7
    function testPenaltyIdentityCorrect() external {

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_penalty), 10000 * 1e18);
        vm.stopPrank();

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(randomUser, 10000 * 1e18);
        
        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        uint amountBeforePool = _pool.actualBalance();
        _penalty.applyIdentityFraudPenalty(randomUser);
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);
        uint amountAfterPool = _pool.actualBalance();

        assertEq(amountBeforeUser * 90/100, amountAfterUser);
        assertEq(amountAfterPool - amountBeforePool,  amountBeforeUser * 10/100);

        vm.stopPrank();
        
    }

    function testPenaltyIdentityInvalidAddress() external {

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_penalty), 10000 * 1e18);
        vm.stopPrank();

        vm.startPrank(admin);
        
        vm.expectRevert(PenaltySystem.InvalidAddress.selector);
        _penalty.applyIdentityFraudPenalty(address(0));

        vm.stopPrank();
    }

    function testPenaltyIdentityNotGreaterThanZero() external {

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_penalty), 10000 * 1e18);
        vm.stopPrank();

        vm.startPrank(admin);
        
        vm.expectRevert(PenaltySystem.AmountMustBeGreaterThanZero.selector);
        _penalty.applyIdentityFraudPenalty(randomUser);

        vm.stopPrank();
    }

    // M9

    function testPenaltySaleCorrect() external {
        
        uint tokensSale = 8000 * 1e18;

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_penalty), 10000 * 1e18);
        vm.stopPrank();

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(randomUser, 10000 * 1e18);
        
        uint amountBeforePool = _pool.actualBalance();
        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _penalty.applyMassSalePenalty(randomUser, tokensSale, 100000 * 1e18);
        uint amountAfterPool = _pool.actualBalance();
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser - amountAfterUser,  tokensSale * 5/100);
        assertEq(amountAfterPool - amountBeforePool,  tokensSale * 5/100);

        vm.stopPrank();
    }

    // amb 8000 no ha revertit
    function testPenaltySaleInvalidAddress() external {
        
        uint tokensSale = 8000 * 1e18; 

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_penalty), 10000 * 1e18);
        vm.stopPrank();

        vm.startPrank(admin);
        
        vm.expectRevert(PenaltySystem.InvalidAddress.selector);
        _penalty.applyMassSalePenalty(address(0), tokensSale, 100000 * 1e18);

        vm.stopPrank();
    }

    function testPenaltySaleAmountMustBeGreaterThanZero() external {

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_penalty), 10000 * 1e18);
        vm.stopPrank();

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(randomUser, 10000 * 1e18);
        
        vm.expectRevert(PenaltySystem.AmountMustBeGreaterThanZero.selector);
        _penalty.applyMassSalePenalty(randomUser, 0, 100000 * 1e18);

        vm.stopPrank();
    }

    function testPenaltySaleNot1Percent() external {
        
        uint tokensSale = 1000 * 1e18; 

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_penalty), 1500 * 1e18);
        vm.stopPrank();

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(randomUser, 1500 * 1e18);
        
        vm.expectRevert("User does not hold 1% of supply");
        _penalty.applyMassSalePenalty(randomUser, tokensSale, 500000 * 1e18);

        vm.stopPrank();
    }

    function testPenaltySaleNot50PercentOfHoldings() external {
        
        uint tokensSale = 8000 * 1e18; 

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_penalty), 10000 * 1e18);
        vm.stopPrank();

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(randomUser, 20000 * 1e18);
        
        vm.expectRevert("Sale does not exceed 50% of holdings");
        _penalty.applyMassSalePenalty(randomUser, tokensSale, 100000 * 1e18);

        vm.stopPrank();
    }


    //M14

    function testPenaltyNoShowCorrect() external {

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_penalty), 10000 * 1e18);
        vm.stopPrank();

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(randomUser, 10000 * 1e18);
        
        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _penalty.applyNoShowPenalty(randomUser);
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser * 95/100, amountAfterUser);

        vm.stopPrank();
    }

    // M25
    function testPenaltyNoEventCorrect() external {

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_penalty), 10000 * 1e18);
        vm.stopPrank();

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(randomUser, 10000 * 1e18);
        
        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _penalty.applyEducatorInactivityPenalty(randomUser);
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser * 95/100, amountAfterUser);

        vm.stopPrank();
    }

    // M26
    function testPenaltyPlagiarismCorrect() external {

        address randomUser2 = address(3);

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_penalty), 10000 * 1e18);
        vm.stopPrank();

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(randomUser, 10000 * 1e18);
        
        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        uint amountBeforeUser2 = _hacktoken.balanceOf(randomUser2);
        _penalty.applyPlagiarismPenalty(randomUser, randomUser2, false);
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);
        uint amountAfterUser2 = _hacktoken.balanceOf(randomUser2);

        assertEq(amountBeforeUser * 90/100, amountAfterUser);
        assertEq(amountBeforeUser2 + amountBeforeUser * 10/100, amountAfterUser2);

        vm.stopPrank();
    }

    //M30
    function testPenaltyNoReclutedCorrect() external {

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_penalty), 10000 * 1e18);
        vm.stopPrank();

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(randomUser, 10000 * 1e18);
        
        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _penalty.applyRecruiterInactivityPenalty(randomUser);
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser * 95/100, amountAfterUser);

        vm.stopPrank();
    }
    


}