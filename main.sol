// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "./scn.sol";
import "@openzeppelin/contracts@4.4.2/token/ERC1155/utils/ERC1155Holder.sol";

contract certification is ERC1155Holder{
    
    mapping(string => Company) public companies;
    mapping(string => bool) public registered;
    mapping(string => mapping(uint =>bool)) public isVoted;
    mapping(string => mapping(uint =>uint)) public issue_approvedAmount;
    uint proposalAmount = 0;
    string[] public companyNames;
    event CompanyCreation(address indexed creator, uint indexed token_id);

    modifier isRegistered(string memory company_name) {
        require(registered[company_name], "Unidentified Company");
        _;
    }

    function create_newCompany(string memory company_name, string memory date, uint total_amount, address[] memory board_address, uint minimum_approval) public {
        require(!registered[company_name], "Duplicated Company");
        Company c = new Company(company_name,  date, total_amount, board_address, minimum_approval);

        companies[company_name] = c;
        registered[company_name] = true;
        companyNames.push(company_name);
        console.log("Company %s register!", company_name);
    }


    function showCompany() public view{
        console.log("SCS address: %s", address(this));
        for(uint i = 0; i < companyNames.length; ++i) {
            console.log("%s: %s", companyNames[i], address(companies[companyNames[i]]));
        }
    }
    
    function issuestock(string memory company_name, uint total_amount) 
    public 
    isRegistered(company_name) 
    {
        Company c = companies[company_name];
        c.submitAction(msg.sender, "issuestock", total_amount, address(this));
    }

    function burn(string memory company_name, uint total_amount) 
    public 
    isRegistered(company_name) 
    {
        Company c = companies[company_name];
        c.submitAction(msg.sender, "burn", total_amount, address(this));
    }

    function reissue_stock(string memory company_name, uint total_amount)
    public
    isRegistered(company_name)
    {
        Company c = companies[company_name];
        c.submitAction(msg.sender, "reissue_stock", total_amount, address(this));
    }

    function transfer(string memory company_name, address target, uint total_amount) 
    public
    isRegistered(company_name)
    {
        Company c = companies[company_name];
        c.submitAction(msg.sender, "transfer", total_amount, target);
    }
 
    function redeem(string memory company_name, address target, uint total_amount) 
    public
    
    isRegistered(company_name)
    {
        Company c = companies[company_name];
        c.submitAction(msg.sender, "redeem", total_amount, target);
    }

    // function issue_action(string memory company_name, uint stage) public view 
    
    // {  uint proposalAmount = 0; 
    //    return proposalAmount;
    // }

    function confirmAction(string memory company_name, uint stage) 
    public 
    isRegistered(company_name)
    {
        Company c = companies[company_name];
        c.confirmAction(msg.sender, stage);
    }

    function issueApprove(string memory company_name, uint stage) 
    public 
    isRegistered(company_name)
    {
        require(!isVoted[company_name][stage],"you voted");
        isVoted[company_name][stage]= true;
        proposalAmount +=1;
        issue_approvedAmount[company_name][stage] = proposalAmount;
    }

}
