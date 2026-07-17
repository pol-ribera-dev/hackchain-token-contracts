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
        _penalty.applyIdentityFraudPenalty(randomUser);
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser * 90/100, amountAfterUser );


        vm.stopPrank();
        
    }


    // M9

    function testPenaltySaleCorrect() external {
        
        uint tokensSale = 8000 * 1e18; // amb 8000 no ha revertit

        vm.startPrank(randomUser);
        _hacktoken.approve(address(_penalty), 10000 * 1e18);
        vm.stopPrank();

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(randomUser, 10000 * 1e18);
        
        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _penalty.applyMassSalePenalty(randomUser, tokensSale, 100000 * 1e18);
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser - amountAfterUser,  tokensSale * 5/100);
        //comprovar que estiguin en tesoreria

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