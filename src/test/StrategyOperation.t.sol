// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
pragma abicoder v2;

import {StrategyFixture} from "./utils/StrategyFixture.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Vm} from "forge-std/Vm.sol";
import {IVault} from "../interfaces/Vault.sol";
import "forge-std/console2.sol"; // for test logging only

// NOTE: if the name of the strat or file changes this needs to be updated
import {Strategy} from "../Strategy.sol";
import "../interfaces/Hop/ISwap.sol";

contract StrategyOperationsTest is StrategyFixture {
    // setup is run on before each test
    function setUp() public override {
        // setup vault
        super.setUp();
    }

    function testSetupVaultOK() public {

        // Logic for multi-want testing
        for (uint8 i = 0; i < assetFixtures.length; ++i) {
            AssetFixture memory _assetFixture = assetFixtures[i];
            IVault vault = _assetFixture.vault;
            Strategy strategy = _assetFixture.strategy;
            IERC20 want = _assetFixture.want;
            uint8 _wantDecimals = ERC20(address(want)).decimals();
            string memory _wantSymbol = ERC20(address(want)).symbol();
        //

            console2.log("address of vault", address(vault));
            assertTrue(address(0) != address(vault));
            assertEq(vault.token(), address(want));
            assertEq(vault.depositLimit(), type(uint256).max);
        }
    }

    // TODO: add additional check on strat params
    function testSetupStrategyOK() public {
        
        // Logic for multi-want testing
        for (uint8 i = 0; i < assetFixtures.length; ++i) {
            AssetFixture memory _assetFixture = assetFixtures[i];
            IVault vault = _assetFixture.vault;
            Strategy strategy = _assetFixture.strategy;
            IERC20 want = _assetFixture.want;
            uint8 _wantDecimals = ERC20(address(want)).decimals();
            string memory _wantSymbol = ERC20(address(want)).symbol();
        //

            console2.log("address of strategy", address(strategy));
            assertTrue(address(0) != address(strategy));
            assertEq(address(strategy.vault()), address(vault));
        }
    }

    /// Test Operations
    function testStrategyOperation(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);

        // Logic for multi-want testing
        for (uint8 i = 0; i < assetFixtures.length; ++i) {
            AssetFixture memory _assetFixture = assetFixtures[i];
            IVault vault = _assetFixture.vault;
            Strategy strategy = _assetFixture.strategy;
            IERC20 want = _assetFixture.want;
            uint8 _wantDecimals = ERC20(address(want)).decimals();
            string memory _wantSymbol = ERC20(address(want)).symbol();
            if (_wantDecimals != 18) {
                uint256 _decimalDifference = 18 - _wantDecimals;
                _amount = _amount / (10 ** _decimalDifference);
            }
            if (keccak256(abi.encodePacked(_wantSymbol)) == keccak256(abi.encodePacked("WETH"))) {
                _amount = _amount / 1_000; // fuzz amount modifier for WETH e.g. 100 WETH --> 0.1 ETH
            }
        //

            deal(address(want), user, _amount);

            uint256 balanceBefore = want.balanceOf(address(user));
            vm.prank(user);
            want.approve(address(vault), _amount);
            vm.prank(user);
            vault.deposit(_amount);
            assertRelApproxEq(want.balanceOf(address(vault)), _amount, DELTA);

            skip(3 minutes);
            vm.prank(strategist);
            strategy.harvest();
            assertRelApproxEq(strategy.estimatedTotalAssets(), _amount, DELTA);

            // tend
            vm.prank(strategist);
            strategy.tend();

            vm.prank(user);
            vault.withdraw();

            assertRelApproxEq(want.balanceOf(user), balanceBefore, DELTA);
        }
    }

    function testEmergencyExit(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);

        // Logic for multi-want testing
        for (uint8 i = 0; i < assetFixtures.length; ++i) {
            AssetFixture memory _assetFixture = assetFixtures[i];
            IVault vault = _assetFixture.vault;
            Strategy strategy = _assetFixture.strategy;
            IERC20 want = _assetFixture.want;
            uint8 _wantDecimals = ERC20(address(want)).decimals();
            string memory _wantSymbol = ERC20(address(want)).symbol();
            if (_wantDecimals != 18) {
                uint256 _decimalDifference = 18 - _wantDecimals;
                _amount = _amount / (10 ** _decimalDifference);
            }
            if (keccak256(abi.encodePacked(_wantSymbol)) == keccak256(abi.encodePacked("WETH"))) {
                _amount = _amount / 1_000; // fuzz amount modifier for WETH e.g. 100 WETH --> 0.1 ETH
            }
        //

            deal(address(want), user, _amount);

            // Deposit to the vault
            vm.prank(user);
            want.approve(address(vault), _amount);
            vm.prank(user);
            vault.deposit(_amount);
            skip(1);
            vm.prank(strategist);
            strategy.harvest();
            assertRelApproxEq(strategy.estimatedTotalAssets(), _amount, DELTA);

            // set emergency and exit
            vm.prank(gov);
            strategy.setEmergencyExit();
            skip(1);
            vm.prank(strategist);
            strategy.harvest();
            assertLt(strategy.estimatedTotalAssets(), _amount);
        }
    }

    function testProfitableHarvest(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);

        // Logic for multi-want testing
        for (uint8 i = 0; i < assetFixtures.length; ++i) {
            AssetFixture memory _assetFixture = assetFixtures[i];
            IVault vault = _assetFixture.vault;
            Strategy strategy = _assetFixture.strategy;
            IERC20 want = _assetFixture.want;
            uint8 _wantDecimals = ERC20(address(want)).decimals();
            string memory _wantSymbol = ERC20(address(want)).symbol();
            if (_wantDecimals != 18) {
                uint256 _decimalDifference = 18 - _wantDecimals;
                _amount = _amount / (10 ** _decimalDifference);
            }
            if (keccak256(abi.encodePacked(_wantSymbol)) == keccak256(abi.encodePacked("WETH"))) {
                _amount = _amount / 1_000; // fuzz amount modifier for WETH e.g. 100 WETH --> 0.1 ETH
            }
        //

            deal(address(want), user, _amount);

            // Deposit to the vault
            vm.prank(user);
            want.approve(address(vault), _amount);
            vm.prank(user);
            vault.deposit(_amount);
            assertRelApproxEq(want.balanceOf(address(vault)), _amount, DELTA);

            uint256 beforePps = vault.pricePerShare();

            // Harvest 1: Send funds through the strategy
            skip(1);
            vm.prank(strategist);
            strategy.harvest();
            assertRelApproxEq(strategy.estimatedTotalAssets(), _amount, DELTA);

            // TODO: Add some code before harvest #2 to simulate earning yield

            // Harvest 2: Realize profit
            skip(1);
            vm.prank(strategist);
            strategy.harvest();
            skip(6 hours);

            // TODO: Uncomment the lines below
            // uint256 profit = want.balanceOf(address(vault));
            // assertGt(want.balanceOf(address(strategy)) + profit, _amount);
            // assertGt(vault.pricePerShare(), beforePps)
        }
    }

    function testChangeDebt(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);

        // Logic for multi-want testing
        for (uint8 i = 0; i < assetFixtures.length; ++i) {
            AssetFixture memory _assetFixture = assetFixtures[i];
            IVault vault = _assetFixture.vault;
            Strategy strategy = _assetFixture.strategy;
            IERC20 want = _assetFixture.want;
            uint8 _wantDecimals = ERC20(address(want)).decimals();
            string memory _wantSymbol = ERC20(address(want)).symbol();
            if (_wantDecimals != 18) {
                uint256 _decimalDifference = 18 - _wantDecimals;
                _amount = _amount / (10 ** _decimalDifference);
            }
            if (keccak256(abi.encodePacked(_wantSymbol)) == keccak256(abi.encodePacked("WETH"))) {
                _amount = _amount / 1_000; // fuzz amount modifier for WETH e.g. 100 WETH --> 0.1 ETH
            }
        //

            deal(address(want), user, _amount);

            // Deposit to the vault and harvest
            vm.prank(user);
            want.approve(address(vault), _amount);
            vm.prank(user);
            vault.deposit(_amount);
            vm.prank(gov);
            vault.updateStrategyDebtRatio(address(strategy), 5_000);
            skip(1);
            vm.prank(strategist);
            strategy.harvest();
            uint256 half = uint256(_amount / 2);
            assertRelApproxEq(strategy.estimatedTotalAssets(), half, DELTA);

            vm.prank(gov);
            vault.updateStrategyDebtRatio(address(strategy), 10_000);
            skip(1);
            vm.prank(strategist);
            strategy.harvest();
            assertRelApproxEq(strategy.estimatedTotalAssets(), _amount, DELTA);

            // In order to pass these tests, you will need to implement prepareReturn.
            // TODO: uncomment the following lines.
            // vm.prank(gov);
            // vault.updateStrategyDebtRatio(address(strategy), 5_000);
            // skip(1);
            // vm.prank(strategist);
            // strategy.harvest();
            // assertRelApproxEq(strategy.estimatedTotalAssets(), half, DELTA);
        }
    }

    function testProfitableHarvestOnDebtChange(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);

        // Logic for multi-want testing
        for (uint8 i = 0; i < assetFixtures.length; ++i) {
            AssetFixture memory _assetFixture = assetFixtures[i];
            IVault vault = _assetFixture.vault;
            Strategy strategy = _assetFixture.strategy;
            IERC20 want = _assetFixture.want;
            uint8 _wantDecimals = ERC20(address(want)).decimals();
            string memory _wantSymbol = ERC20(address(want)).symbol();
            if (_wantDecimals != 18) {
                uint256 _decimalDifference = 18 - _wantDecimals;
                _amount = _amount / (10 ** _decimalDifference);
            }
            if (keccak256(abi.encodePacked(_wantSymbol)) == keccak256(abi.encodePacked("WETH"))) {
                _amount = _amount / 1_000; // fuzz amount modifier for WETH e.g. 100 WETH --> 0.1 ETH
            }
        //

            deal(address(want), user, _amount);

            // Deposit to the vault
            vm.prank(user);
            want.approve(address(vault), _amount);
            vm.prank(user);
            vault.deposit(_amount);
            assertRelApproxEq(want.balanceOf(address(vault)), _amount, DELTA);

            uint256 beforePps = vault.pricePerShare();

            // Harvest 1: Send funds through the strategy
            skip(1);
            vm.prank(strategist);
            strategy.harvest();
            assertRelApproxEq(strategy.estimatedTotalAssets(), _amount, DELTA);

            // TODO: Add some code before harvest #2 to simulate earning yield

            vm.prank(gov);
            vault.updateStrategyDebtRatio(address(strategy), 5_000);

            // In order to pass these tests, you will need to implement prepareReturn.
            // TODO: uncomment the following lines.
            /*
            // Harvest 2: Realize profit
            skip(1);
            vm.prank(strategist);
            strategy.harvest();
            //Make sure we have updated the debt ratio of the strategy
            assertRelApproxEq(
                strategy.estimatedTotalAssets(), 
                _amount / 2, 
                DELTA
            );
            skip(6 hours);

            //Make sure we have updated the debt and made a profit
            uint256 vaultBalance = want.balanceOf(address(vault));
            StrategyParams memory params = vault.strategies(address(strategy));
            //Make sure we got back profit + half the deposit
            assertRelApproxEq(
                _amount / 2 + params.totalGain, 
                vaultBalance, 
                DELTA
            );
            assertGe(vault.pricePerShare(), beforePps);
            */
        }
    }

    function testSweep(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);

        // Logic for multi-want testing
        for (uint8 i = 0; i < assetFixtures.length; ++i) {
            AssetFixture memory _assetFixture = assetFixtures[i];
            IVault vault = _assetFixture.vault;
            Strategy strategy = _assetFixture.strategy;
            IERC20 want = _assetFixture.want;
            uint8 _wantDecimals = ERC20(address(want)).decimals();
            string memory _wantSymbol = ERC20(address(want)).symbol();
            if (_wantDecimals != 18) {
                uint256 _decimalDifference = 18 - _wantDecimals;
                _amount = _amount / (10 ** _decimalDifference);
            }
            if (keccak256(abi.encodePacked(_wantSymbol)) == keccak256(abi.encodePacked("WETH"))) {
                _amount = _amount / 1_000; // fuzz amount modifier for WETH e.g. 100 WETH --> 0.1 ETH
            }
        //

            deal(address(want), user, _amount);

            // Strategy want token doesn't work
            vm.prank(user);
            want.transfer(address(strategy), _amount);
            assertEq(address(want), address(strategy.want()));
            assertGt(want.balanceOf(address(strategy)), 0);

            vm.prank(gov);
            vm.expectRevert("!want");
            strategy.sweep(address(want));

            // Vault share token doesn't work
            vm.prank(gov);
            vm.expectRevert("!shares");
            strategy.sweep(address(vault));

            // TODO: If you add protected tokens to the strategy.
            // Protected token doesn't work
            // vm.prank(gov);
            // vm.expectRevert("!protected");
            // strategy.sweep(strategy.protectedToken());

            // TODO: Problem here (0xValjohn)
            uint256 beforeBalance = weth.balanceOf(gov);
            uint256 wethAmount = 1 ether;
            deal(address(weth), user, wethAmount);
            vm.prank(user);
            weth.transfer(address(strategy), wethAmount);
            assertNeq(address(weth), address(strategy.want()));
            assertEq(weth.balanceOf(user), 0);
            vm.prank(gov);
            strategy.sweep(address(weth));
            assertRelApproxEq(
                weth.balanceOf(gov),
                wethAmount + beforeBalance,
                DELTA
            );
        }
    }

    function testTriggers(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);

        // Logic for multi-want testing
        for (uint8 i = 0; i < assetFixtures.length; ++i) {
            AssetFixture memory _assetFixture = assetFixtures[i];
            IVault vault = _assetFixture.vault;
            Strategy strategy = _assetFixture.strategy;
            IERC20 want = _assetFixture.want;
            uint8 _wantDecimals = ERC20(address(want)).decimals();
            string memory _wantSymbol = ERC20(address(want)).symbol();
            if (_wantDecimals != 18) {
                uint256 _decimalDifference = 18 - _wantDecimals;
                _amount = _amount / (10 ** _decimalDifference);
            }
            if (keccak256(abi.encodePacked(_wantSymbol)) == keccak256(abi.encodePacked("WETH"))) {
                _amount = _amount / 1_000; // fuzz amount modifier for WETH e.g. 100 WETH --> 0.1 ETH
            }
        //

            deal(address(want), user, _amount);

            // Deposit to the vault and harvest
            vm.prank(user);
            want.approve(address(vault), _amount);
            vm.prank(user);
            vault.deposit(_amount);
            vm.prank(gov);
            vault.updateStrategyDebtRatio(address(strategy), 5_000);
            skip(1);
            vm.prank(strategist);
            strategy.harvest();

            strategy.harvestTrigger(0);
            strategy.tendTrigger(0);
        }
    }

    function testLosses(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);

        // Logic for multi-want testing
        for (uint8 i = 0; i < assetFixtures.length; ++i) {
            AssetFixture memory _assetFixture = assetFixtures[i];
            IVault vault = _assetFixture.vault;
            Strategy strategy = _assetFixture.strategy;
            IERC20 want = _assetFixture.want;
            uint8 _wantDecimals = ERC20(address(want)).decimals();
            string memory _wantSymbol = ERC20(address(want)).symbol();
            if (_wantDecimals != 18) {
                uint256 _decimalDifference = 18 - _wantDecimals;
                _amount = _amount / (10 ** _decimalDifference);
            }
            if (keccak256(abi.encodePacked(_wantSymbol)) == keccak256(abi.encodePacked("WETH"))) {
                _amount = _amount / 1_000; // fuzz amount modifier for WETH e.g. 100 WETH --> 0.1 ETH
            }
        //

            deal(address(want), user, _amount);

            // TODO: test here
        }
    }

    function testLimitedLiquiditWithProfit(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);

        // Logic for multi-want testing
        for (uint8 i = 0; i < assetFixtures.length; ++i) {
            AssetFixture memory _assetFixture = assetFixtures[i];
            IVault vault = _assetFixture.vault;
            Strategy strategy = _assetFixture.strategy;
            IERC20 want = _assetFixture.want;
            uint8 _wantDecimals = ERC20(address(want)).decimals();
            string memory _wantSymbol = ERC20(address(want)).symbol();
            if (_wantDecimals != 18) {
                uint256 _decimalDifference = 18 - _wantDecimals;
                _amount = _amount / (10 ** _decimalDifference);
            }
            if (keccak256(abi.encodePacked(_wantSymbol)) == keccak256(abi.encodePacked("WETH"))) {
                _amount = _amount / 1_000; // fuzz amount modifier for WETH e.g. 100 WETH --> 0.1 ETH
            }
        //

            deal(address(want), user, _amount);

            // TODO: test here
        }
    }

    function testLimitedLiquiditWithLoss(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);

        // Logic for multi-want testing
        for (uint8 i = 0; i < assetFixtures.length; ++i) {
            AssetFixture memory _assetFixture = assetFixtures[i];
            IVault vault = _assetFixture.vault;
            Strategy strategy = _assetFixture.strategy;
            IERC20 want = _assetFixture.want;
            uint8 _wantDecimals = ERC20(address(want)).decimals();
            string memory _wantSymbol = ERC20(address(want)).symbol();
            if (_wantDecimals != 18) {
                uint256 _decimalDifference = 18 - _wantDecimals;
                _amount = _amount / (10 ** _decimalDifference);
            }
            if (keccak256(abi.encodePacked(_wantSymbol)) == keccak256(abi.encodePacked("WETH"))) {
                _amount = _amount / 1_000; // fuzz amount modifier for WETH e.g. 100 WETH --> 0.1 ETH
            }
        //

            deal(address(want), user, _amount);

            // TODO: test here
        }
    }


}
