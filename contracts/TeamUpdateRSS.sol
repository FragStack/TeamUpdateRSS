//SPDX-License-Identifier: MIT
//@title: a contract that allows teams to provide updates on the blockchain. Whitelisted team members can add updates. Owner can add/remote teams or whitelisted team memebers.
//@author: Dysan & FragStack Crew
//contract addr: 0xC4529712eFCFC264bE0f80C357775476c1986892

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TeamUpdateRSS is Ownable {

    //@dev: Team schema for team data    
    struct Team {
        string Name;
        string Logo;
        uint ID;
        string Update;
    }

    //@dev: Event for when an item for the Teams array is updated.
    event TeamsUpdated();

    
    //@dev: This is the TeamID Counter. TeamIDs are not reused for deleted teams. It will keep incrementing Team IDs for new teams.
    uint public TeamIDCount;
    
    //@dev: This is a mapping to test if an address is whitelisted for a team. mapping [TEAMID][ADDRESS].
    //@return: bool
    mapping (uint => mapping(address => bool)) public team_whitelist; 

    //@dev:maps team ID to location of teams array
    mapping (uint => uint) TeamtoArray; 
    
    //@dev: admin webpage string
    string admin_page ="https://google.com"; 

    //@dev: Teams Array. Only active teams are stored in this array. Deleted teams are removed from this array.
    Team[] public Teams;

    constructor() {
        require(msg.sender != address(0));
        console.log("We have been constructed by: %s ", Ownable.owner());
        
        //@dev: Item 0 in Teams array is the deleted item place holder. All deleted Teams will point this this item.
        Teams.push(Team({Name: "Deleted Team", Logo: "Deleted Logo", ID: 0, Update: "This team has been deleted."}));
    }


    //@notice: function to add new teams. Can only be called by contract owner.
    //@param: string memory _name - This is the team name
    //@param: string memory _logo - This is URL for team logo
    //@param: string memory _update - This is the team update
    //@return: the function will return the TeamID
    function add_team (string memory _name, string memory _logo, string memory _update) public returns (uint){
        require(msg.sender == Ownable.owner());
        Team memory newTeam;
        newTeam.Name = _name;
        newTeam.Logo = _logo;
        newTeam.ID = TeamIDCount;
        team_whitelist[TeamIDCount][msg.sender]=true;
        TeamtoArray[TeamIDCount] = Teams.length;
        newTeam.Update = _update;
        TeamIDCount++;
        Teams.push(newTeam);
        emit TeamsUpdated();
        return newTeam.ID;
    }

    
    //@notice: function to delete teams. Can only be called by contract owner.
    //@param: uint _id - This is the team id
    function del_team (uint _id) public{
        require(msg.sender == Ownable.owner());

        //make sure the team hasn't already been deleted and team reference actually exists in array.
        require(TeamtoArray[_id]> 0 && TeamtoArray[_id] < get_Total_Teams());  

        //delete by shifting last element to the deleted object place.
        Teams[TeamtoArray[_id]] = Teams[Teams.length - 1];

        //update the TeamtoArray reference for the last item you moved.
        TeamtoArray[Teams[Teams.length - 1].ID] = TeamtoArray[_id];

        //pop the last element of array.
        Teams.pop();
        
        //set the deleted item to point to Teams array element 0 (place holder for deleted items)
        TeamtoArray[_id] = 0;
        emit TeamsUpdated();
    }

    //@notice: function to add a wallet address to the whitelist for a team. Can only be called by contract owner.
    //@param: uint _id - This is the team id
    //@param: address _addr - This is the wallet address to be whitelisted
    function add_team_whitelist(uint _ID, address _addr) public {
        //make sure the owner is calling this function, the ID is valid and has not been deleted.
        require(msg.sender == Ownable.owner() && _ID < TeamIDCount && TeamtoArray[_ID]> 0);
        team_whitelist[_ID][_addr]=true;
        
    }


    //@notice: function to remove a wallet address from the whitelist for a team. Can only be called by contract owner.
    //@param: uint _id - This is the team id
    //@param: address _addr - This is the wallet address to be removed from thewhitelist
    function del_team_whitelist(uint _ID, address _addr) public {
        //make sure the owner is calling this function, the ID is valid and has not been deleted.
        require(msg.sender == Ownable.owner() && _ID < TeamIDCount && TeamtoArray[_ID]> 0);
        team_whitelist[_ID][_addr]=false;
    }

    //@notice: function to see if the caller is the admin (owner)
    //@return: bool - true - if caller is admin (owner)
    //              - false - if caller is not admin (owner)
    function is_admin_addr() public view returns (bool){
        return (msg.sender == Ownable.owner());
    }

    //@notice: function to get the admin page. Requires owner.
    //@return: string - admin URL for contract
    function get_admin_page() public view returns (string memory){
        require (msg.sender == Ownable.owner());
        return admin_page;
    }


    //@notice: function to set the admin page. Requires owner.
    //@param: string memory _url - The URL of the admin page
    function set_admin_page(string memory _url) public {
        require (msg.sender == Ownable.owner());
        admin_page = _url;
    }


    //@notice: function to check to see if the caller's address is whitelisted for a team
    //@param: uint _ID - team id to check to see if caller's address is whitelisted.
    //@return: bool - true - the address is whitelisted for the team
    //              - false - the address is not whitelisted for the team
    function is_addr_whitelisted(uint _ID) public view returns (bool){
        //Check to see if the ID is valid and has not been deleted.
        require(_ID < TeamIDCount && TeamtoArray[_ID]> 0);
        return team_whitelist[_ID][msg.sender];
    }


    
    //@notice: function to update the team update, can be called by anyone that has been whitelisted for that team
    //@param: uint _ID - team id for the team
    //@param: string memory _update - team update
    function add_team_update(uint _ID, string memory _update) public {
        //make sure the caller is whitelisted, the ID is valid and has not been deleted.
        require(team_whitelist[_ID][msg.sender]==true && TeamtoArray[_ID]> 0 && _ID < TeamIDCount); 
        Teams[TeamtoArray[_ID]].Update = _update;
        emit TeamsUpdated();
    }

    
    //@notice: function to update team logo, can be called by anyone whitelisted for that team
    //@param: uint _ID - team id for the team
    //@param: string memory _logo - team logo URL
    function update_team_logo(uint _ID, string memory _logo) public {
        //make sure the caller is whitelisted, the ID is valid and has not been deleted.
        require(team_whitelist[_ID][msg.sender]==true && TeamtoArray[_ID]> 0 && _ID < TeamIDCount); 
        Teams[TeamtoArray[_ID]].Logo = _logo;
        emit TeamsUpdated();
    }


    //@notice: function to update team name, can be called by anyone whitelisted for that team
    //@param: uint _ID - team id for the team
    //@param: string memory _logo - team name
    function update_team_name(uint _ID, string memory _name) public {
        //make sure the caller is whitelisted, the ID is valid and has not been deleted.
        require(team_whitelist[_ID][msg.sender]==true && TeamtoArray[_ID]> 0 && _ID < TeamIDCount); 
        Teams[TeamtoArray[_ID]].Name = _name;
        emit TeamsUpdated();
    }

    //@notice: function to return the total number of teams
    //@return: uint - returns the total number of items in the teams array
    function get_Total_Teams() public view returns (uint) {
        return Teams.length;
    }

    
    //@notice: function to return the team update
    //@return: string memory - returns the team update
    function get_team_update (uint _ID) public view returns (string memory){
        require(_ID < TeamIDCount);
        return Teams[TeamtoArray[_ID]].Update;
    }


    //@notice: function to return the team name
    //@return: string memory - returns the team name
    function get_team_name (uint _ID) public view returns (string memory){
        require(_ID < TeamIDCount);
        return Teams[TeamtoArray[_ID]].Name;
    }
    
    //@notice: function to return the team logo
    //@return: string memory - returns the team logo
    function get_team_logo (uint _ID) public view returns (string memory){
        require(_ID < TeamIDCount);
        return Teams[TeamtoArray[_ID]].Logo;
    }
    

    //@notice: function to get all teams
    //@return: Team[] memory - returns the team struct array for all teams
    function get_teams() public view returns(Team[] memory){
        return Teams;
    }

}
