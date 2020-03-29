pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";

import {Registry} from "./Registry.sol";

contract BlendToken is Initializable, Ownable, ERC20, ERC20Detailed {

    bool public distributionPhase;
    Registry public registry;
    address public orchestrator;

    modifier onlyOrchestrator() {
        require(
            _msgSender() == orchestrator,
            "Unauthorized: sender is not the Orchestrator"
        );
        _;
    }

    function initialize(
        address initialHolder,
        uint256 initialSupply,
        address registryAddress,
        address orchestratorAddress
    )
        public
        initializer
    {
        ERC20Detailed.initialize("Blend Token", "BLEND", 18);
        _mint(initialHolder, initialSupply);
        registry = Registry(registryAddress);
        orchestrator = orchestratorAddress;
    }

    function setRegistry(address newRegistry) public onlyOwner {
        registry = Registry(newRegistry);
    }

    function setOrchestrator(address newOrchestrator) public onlyOwner {
        orchestrator = newOrchestrator;
    }

    function transfer(address recipient, uint256 amount)
        public
        returns (bool)
    {
        if (registry.isTenderAddress(recipient)) {
            registry.recordTransfer(_msgSender(), recipient, amount);
        }
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        returns (bool)
    {
        if (registry.isTenderAddress(recipient)) {
            registry.recordTransfer(sender, recipient, amount);
        }
        return super.transferFrom(sender, recipient, amount);
    }

    function unlock(address tenderAddress, uint256 amount) public {
        require(
            !distributionPhase,
            "Cannot unlock funds at distribution phase"
        );
        require(
            amount <= balanceOf(tenderAddress),
            "Insufficient balance"
        );
        require(
            amount <= registry.getLockedAmount(tenderAddress, _msgSender()),
            "Insufficient funds locked"
        );
        _transfer(tenderAddress, _msgSender(), amount);
        registry.recordUnlock(tenderAddress, _msgSender(), amount);
    }

    function startDistributionPhase() public onlyOrchestrator {
        distributionPhase = true;
    }

    function stopDistributionPhase() public onlyOrchestrator {
        distributionPhase = false;
    }

    function burn(address tenderAddress, uint256 amount)
        public
        onlyOrchestrator
    {
        require(
            distributionPhase,
            "Burn is allowed only at distribution phase"
        );
        require(
            amount <= balanceOf(tenderAddress),
            "Insufficient balance"
        );
        require(
            registry.isTenderAddress(tenderAddress),
            "Burning from regular addresses is not allowed"
        );
        _burn(tenderAddress, amount);
    }
}
