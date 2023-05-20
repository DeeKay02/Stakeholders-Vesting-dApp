// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VestingSchedule {
    struct Org {
        address orgAddress;
        address owner;
        address tokenAddress;
        mapping(string => uint256) vestingTime;
        mapping(address => string) stakeholders;
        uint256 timestamp;

    }

    mapping(address => Org) Orgs;
    mapping(address => address) orgOwners;
    mapping(address => address[]) OrgStakeholders;
    mapping(address => uint256) amountToDisburse;


    function createOrg(address _orgAddress, address _owner, address _token, string[] memory stakeholders, uint256[] memory times) public {
        Orgs[_orgAddress].owner = _owner;
        Orgs[_orgAddress].tokenAddress = _token;
        Orgs[_orgAddress].timestamp = block.timestamp;
        for(uint i=0;i<stakeholders.length;i++){
            Orgs[_orgAddress].vestingTime[stakeholders[i]] = times[i];
        }
    }

    function addWhitelist(address _orgAddress, address[] memory _whitelist, string[] memory _stakeholder, uint[] memory _amt) public {
        OrgStakeholders[_orgAddress] = _whitelist;
        for(uint i=0;i<_stakeholder.length;i++){
            Orgs[_orgAddress].stakeholders[_whitelist[i]] = _stakeholder[i];
            amountToDisburse[_whitelist[i]] = _amt[i];
        }
    }

    function sendTokensToContract(address _token, uint _amt, address _orgAdd) public payable {
        require(_orgAdd == orgOwners[_orgAdd]);
        ERC20 orgToken = ERC20(_token);
        orgToken.transferFrom(payable(msg.sender), payable(address(this)), _amt);
    }

    function claimToken(address _org) public {
        string memory _stakeholder = Orgs[_org].stakeholders[address(msg.sender)];
        if(bytes(_stakeholder).length > 0) {
            if(Orgs[_org].timestamp + Orgs[_org].vestingTime[_stakeholder] < block.timestamp) {
                ERC20 orgToken = ERC20(Orgs[_org].tokenAddress);
                orgToken.transfer(msg.sender, amountToDisburse[msg.sender]);
            }
            else revert("Vesting period is not over!");
        }
        else revert("Address is not Whitelisted!");
    }
}