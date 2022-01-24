// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "@openzeppelin/contracts@4.4.2/token/ERC1155/ERC1155.sol";

contract Company is ERC1155 {

    uint TOKENID = 1;
    struct Action {
        address promotor;
        bool executed;
        uint numConfirmations;
        string actionName;
        uint _total_amount;
        address target;
    }

    string _company_name;
    string fundingDate;
    uint shares;
    address[] public _directors;
    uint public numConfirmationsRequired;

    Action[] public actions;

    mapping(address => bool) public Director;
    mapping(string => bool) public ValidAction;
    mapping(uint => mapping(address => bool)) public isConfirmed;

    event SubmitAction(
        address indexed director,
        uint indexed _stage
    );

    event ConfirmAction(
        address indexed director,
        uint indexed _stage
    );

    modifier isDirector(address _director) {
        require(Director[_director], "Not Director");
        _;
    }

    modifier isValidAction(string memory _action) {
        require(ValidAction[_action], "Invalid Action");
        _;
    }

    modifier notExecuted(uint stage) {
        require(!actions[stage].executed, "Executed Action");
        _;
    }
    
    modifier notConfirmed(address _director, uint stage) {
        require(!isConfirmed[stage][_director], "The director already confirmed");
        _;
    }

    constructor(string memory company_name, string memory _fundingDate, uint _shares, address[] memory directors, uint _numConfirmationsRequired) ERC1155("https://abcoathup.github.io/SampleERC1155/api/token/{id}.json")  {
        require(directors.length > 0, "owners required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= directors.length, "invalid number of required confirmations");
        require(_shares > 0, "shares should be at least 1");

        for (uint i = 0; i < directors.length; i++) {
            address director = directors[i];

            require(director != address(0), "invalid owner");
            require(!Director[director], "Director not unique");

            Director[director] = true;
            _directors.push(director);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        _company_name = company_name;
        fundingDate = _fundingDate;
        shares = _shares;

        issuestock(_shares);

        ValidAction["issuestock"] = true;
        ValidAction["burn"] = true;
        ValidAction["reissue_stock"] = true;
        ValidAction["transfer"] = true;
        ValidAction["redeem"] = true;
    }

    function compareString(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function submitAction(address _director, string memory _actionName, uint total_amount, address _target) 
    public 
    isDirector(_director)
    isValidAction(_actionName)
    {
        require(total_amount > 0);
        if (compareString(_actionName, "transfer") || compareString(_actionName, "redeem")) {
            require(_target != address(0));
        }

        uint _stage = actions.length;
        actions.push(
            Action({
                promotor: _director,
                executed: false,
                numConfirmations: 0,
                actionName: _actionName,
                _total_amount: total_amount,
                target: _target
            })
        );
        //isConfirmed[_stage][_director] = true;
        console.log("Public new action: (%s, %s)", _stage, _actionName);
        emit SubmitAction(_director, _stage);
    }
    
    function confirmAction(address _director, uint stage)
    public
    isDirector(_director)
    notExecuted(stage)
    notConfirmed(_director, stage)
    {
        Action storage action = actions[stage];
        action.numConfirmations += 1;
        isConfirmed[stage][_director] = true;
        console.log("Action %s - %s, number of confirm: %s", stage, action.actionName, action.numConfirmations);
        if (action.numConfirmations >= numConfirmationsRequired) {
            executeAction(stage);
            console.log("Action %s exectue", stage);
        }
        
        emit ConfirmAction(_director, stage);
    }

    function executeAction(uint stage) private{
        Action storage action = actions[stage];

        action.executed = true;

        if (compareString(action.actionName, "issuestock")) {
            issuestock(action._total_amount);
        }
        else if (compareString(action.actionName, "burn")) {
            burn(action._total_amount);
        }
        else if (compareString(action.actionName, "reissue_stock")) {
            reissue_stock(action._total_amount);
        }
        else if (compareString(action.actionName, "transfer")) {
            transfer(action.target, action._total_amount);
        }
        else if (compareString(action.actionName,"redeem")) {
            redeem(action.target, action._total_amount);
        }
        
    }

    function issuestock(uint total_amount) private {
        _mint(msg.sender, TOKENID, total_amount, "");
        console.log("issuestock Success!!");
    }
    
    function burn(uint total_amount) private {
        _burn(msg.sender, TOKENID, total_amount);
        console.log("Burn Success!!");

    }

    function reissue_stock(uint total_amount) private {
        _burn(msg.sender, TOKENID, total_amount);
        _mint(msg.sender, TOKENID, 2 * total_amount, "");
        console.log("reissue_stock Success!!");

    }

    function transfer(address target, uint total_amount) private {
        safeTransferFrom(msg.sender, target, TOKENID, total_amount, "");
        console.log("Transfer Success!!");

    }

    function redeem(address target, uint total_amount) private {
        safeTransferFrom(target, msg.sender, TOKENID, total_amount, "");
        _burn(msg.sender, TOKENID, total_amount);
        console.log("Redemption Success!!");

    }
}
