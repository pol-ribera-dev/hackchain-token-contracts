// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/HackTokenERC20.sol";
import "../src/IncentivesPool.sol";
import "../src/TalentBonuses.sol";
import "../src/EducatorBonuses.sol";
import "../src/RecruiterBonuses.sol";

contract BonusTest is Test {

    HackToken _hacktoken;
    IncentivesPool _pool;
    TalentBonuses _bonus;
    EducatorBonuses _bonusEducator;
    RecruiterBonuses _bonusRec;

    address public admin = vm.addr(1);

    address public randomUser = vm.addr(2);

    function setUp() public {
        vm.startPrank(admin);
        _hacktoken = new HackToken();
        _pool = new IncentivesPool(address(_hacktoken));
        _bonus = new TalentBonuses(address(_hacktoken), address(_pool));
        _bonusEducator = new EducatorBonuses(address(_pool));
        _bonusRec = new RecruiterBonuses(address(_pool));
        _pool.grantRole(_pool.DISTRIBUTOR_ROLE(), address(_bonus));
        _pool.grantRole(_pool.DISTRIBUTOR_ROLE(), address(_bonusEducator));
        _pool.grantRole(_pool.DISTRIBUTOR_ROLE(), address(_bonusRec));
        vm.stopPrank();
    }

    // Bonus
    //M4
    function testBonusDegreeCorrect() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 50000 * 1e18);
        _hacktoken.approve(address(_pool), 50000 * 1e18);
        _pool.fundPool(50000 * 1e18);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);

        _bonus.rewardSchoolingDegree(randomUser, keccak256("master"));

        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 50000 * 1e18, amountAfterUser);

        vm.stopPrank();
        
    }

    function testBonusTwoDegreeCorrect() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 500000 * 1e18);
        _hacktoken.approve(address(_pool), 500000 * 1e18);
        _pool.fundPool(500000 * 1e18);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);

        _bonus.rewardSchoolingDegree(randomUser, keccak256("ESO"));
        _bonus.rewardSchoolingDegree(randomUser, keccak256("master"));
        
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 100000 * 1e18, amountAfterUser);

        vm.stopPrank();
        
    }

    function testBonusDegreeInvalidAddress() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 50000 * 1e18);
        _hacktoken.approve(address(_pool), 50000 * 1e18);
        _pool.fundPool(50000 * 1e18);

        vm.expectRevert(TalentBonuses.InvalidAddress.selector);
        _bonus.rewardSchoolingDegree(address(0), keccak256("master"));

        vm.stopPrank();
    }

    function testBonusDegreeAlreadyRewarded() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 50000 * 1e18);
        _hacktoken.approve(address(_pool), 50000 * 1e18);
        _pool.fundPool(50000 * 1e18);

        _bonus.rewardSchoolingDegree(randomUser, keccak256("master"));
        vm.expectRevert(TalentBonuses.DegreeAlreadyRewarded.selector);
        _bonus.rewardSchoolingDegree(randomUser, keccak256("master"));

        vm.stopPrank();
        
    }

    //M11
    function testBonusHiredCorrect() external {

        vm.warp(block.timestamp + 100 days);

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);

        _bonus.rewardTalentHired(randomUser);

        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 5000 * 1e18, amountAfterUser);

        vm.stopPrank();
        
    }

    function testBonusHiredInvalidAddress() external {

        vm.warp(block.timestamp + 100 days);

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        vm.expectRevert(TalentBonuses.InvalidAddress.selector);
        _bonus.rewardTalentHired(address(0));

        vm.stopPrank();
        
    }

    function testBonusHiredSameMonth() external {

        vm.warp(block.timestamp + 100 days);

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        _bonus.rewardTalentHired(randomUser);
        vm.expectRevert(TalentBonuses.HiringAlreadyRewardedThisMonth.selector);
        _bonus.rewardTalentHired(randomUser);

        vm.stopPrank();
    }

    function testBonusHiredDiferentMonthCorrect() external {

        vm.warp(block.timestamp + 100 days);

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 50000 * 1e18);
        _hacktoken.approve(address(_pool), 50000 * 1e18);
        _pool.fundPool(50000 * 1e18);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);

        _bonus.rewardTalentHired(randomUser);
        vm.warp(block.timestamp + 31 days);
        _bonus.rewardTalentHired(randomUser);

        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 10000 * 1e18, amountAfterUser);

        vm.stopPrank();
        
    }


    //M23

    function testGitHubCorrect() external {
        
        vm.startPrank(admin);
        _hacktoken.mintTokens(randomUser, 10000 * 1e18);
        vm.stopPrank();

        vm.startPrank(randomUser);
        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _hacktoken.approve(address(_bonus), 10000 * 1e18);
        _bonus.fundProject(keccak256("repository.com"), 10000 * 1e18);
        vm.stopPrank();

        vm.startPrank(admin);
        address[] memory talents = new address[](4);
        talents[0] = address(3);
        talents[1] = address(4);
        talents[2] = address(5);
        talents[3] = address(6);
        
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1 * 1e18;
        amounts[1] = 2 * 1e18;
        amounts[2] = 3 * 1e18;
        amounts[3] = 4 * 1e18;
                
        uint amountBeforeTalent3 = _hacktoken.balanceOf(address(5));

        _bonus.distributeToTalents(keccak256("repository.com"), talents, amounts);
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);
        uint amountAfterTalent3 = _hacktoken.balanceOf(address(5));

        assertEq(amountBeforeUser, amountAfterUser + 10000 * 1e18);
        assertEq(amountBeforeTalent3 + 3 * 1e18, amountAfterTalent3);

        vm.stopPrank();

    }

    //M20
    function testBonusAPICorrect() external {

        uint reward = 50000;
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, reward * 1e18);
        _hacktoken.approve(address(_pool), reward * 1e18);
        _pool.fundPool(reward * 1e18);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);

        _bonusEducator.rewardApiIntegration(randomUser);

        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + reward * 1e18, amountAfterUser);

        vm.stopPrank();
        
    }

    // M21
    function testBonusPDFCorrect() external {

        uint reward = 10000;
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, reward * 1e18);
        _hacktoken.approve(address(_pool), reward * 1e18);
        _pool.fundPool(reward * 1e18);

        _bonusEducator.registerLegacyCert(randomUser, address(3));
        _bonusEducator.registerLegacyCert(randomUser, address(4));
        _bonusEducator.registerLegacyCert(randomUser, address(5));
        _bonusEducator.registerLegacyCert(randomUser, address(6));
        _bonusEducator.registerLegacyCert(randomUser, address(7));
        _bonusEducator.registerLegacyCert(randomUser, address(8));
        _bonusEducator.registerLegacyCert(randomUser, address(9));
        _bonusEducator.registerLegacyCert(randomUser, address(10));
        _bonusEducator.registerLegacyCert(randomUser, address(11));
        _bonusEducator.registerLegacyCert(randomUser, address(12));
        
        vm.stopPrank();

        vm.startPrank(randomUser);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _bonusEducator.claimLegacyCertsBonus();
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + reward * 1e18, amountAfterUser);

        vm.stopPrank();
    }

    // M22
    function testBonusFirst10Correct() external {

        uint reward = 10000;
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, reward * 1e18);
        _hacktoken.approve(address(_pool), reward * 1e18);
        _pool.fundPool(reward * 1e18);

        _bonusEducator.registerActiveTalent(randomUser, address(3));
        _bonusEducator.registerActiveTalent(randomUser, address(4));
        _bonusEducator.registerActiveTalent(randomUser, address(5));
        _bonusEducator.registerActiveTalent(randomUser, address(6));
        _bonusEducator.registerActiveTalent(randomUser, address(7));
        _bonusEducator.registerActiveTalent(randomUser, address(8));
        _bonusEducator.registerActiveTalent(randomUser, address(9));
        _bonusEducator.registerActiveTalent(randomUser, address(10));
        _bonusEducator.registerActiveTalent(randomUser, address(11));
        _bonusEducator.registerActiveTalent(randomUser, address(12));
        
        vm.stopPrank();

        vm.startPrank(randomUser);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);
        _bonusEducator.claimFirstTalentsBonus();
        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + reward * 1e18, amountAfterUser);

        vm.stopPrank();
        
    }
    
    // M24
    function testBonusEducatorHiredCorrect() external {
        address randomUser2 = address(3);
        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 5000 * 1e18);
        _hacktoken.approve(address(_pool), 5000 * 1e18);
        _pool.fundPool(5000 * 1e18);

        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);

        _bonusEducator.rewardTalentHired(randomUser, randomUser2);

        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 5000 * 1e18, amountAfterUser);

        vm.stopPrank();
        
    }

    // M27

    function testBonusRegisterCorrect() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 50000 * 1e18);
        _hacktoken.approve(address(_pool), 50000 * 1e18);
        _pool.fundPool(50000 * 1e18);
        _bonusRec.registerRecruiter(randomUser);
        vm.stopPrank();

        vm.warp(block.timestamp + 10 days);

        vm.startPrank(randomUser);
        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);

        _bonusRec.claimRegistrationBonus();

        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 50000 * 1e18, amountAfterUser);

        vm.stopPrank();
        
    }

    // M28

    function testBonus4ReclutersCorrect() external {
        vm.warp(block.timestamp + 100 days);

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 40000 * 1e18);
        _hacktoken.approve(address(_pool), 40000 * 1e18);
        _pool.fundPool(40000 * 1e18);
        _bonusRec.registerHiring(randomUser);
        _bonusRec.registerHiring(randomUser);
        _bonusRec.registerHiring(randomUser);
        _bonusRec.registerHiring(randomUser);
        vm.stopPrank();


        vm.startPrank(randomUser);
        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);

        _bonusRec.claimMonthlyHiringBonus();

        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 40000 * 1e18, amountAfterUser);

        vm.stopPrank();
        
    }

    // M29

    function testBonusKYCCorrect() external {

        vm.startPrank(admin);
        
        _hacktoken.mintTokens(admin, 200000 * 1e18);
        _hacktoken.approve(address(_pool), 200000 * 1e18);
        _pool.fundPool(200000 * 1e18);
        _bonusRec.verifyKyc(randomUser);
        vm.stopPrank();

        vm.startPrank(randomUser);
        uint amountBeforeUser = _hacktoken.balanceOf(randomUser);

        _bonusRec.claimKycBonus();

        uint amountAfterUser = _hacktoken.balanceOf(randomUser);

        assertEq(amountBeforeUser + 200000 * 1e18, amountAfterUser);

        vm.stopPrank();
        
    }


}