//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TeamUpdateRSS is Ownable {
    
    struct Team {
        string Name;
        string Logo;
        uint ID;
        string Update;
    }

    
    uint public TeamIDCount;
    mapping (uint => mapping(address => bool)) public team_whitelist;
    mapping (uint => uint) TeamtoArray ; //maps team ID to locaiton of teams array
    string admin_page ="https://google.com"; //admin page

    //Teams Array
    Team[] public Teams;

    constructor() {
        require(msg.sender != address(0));
        console.log("We have been constructed by: %s ", Ownable.owner());
        Teams.push(Team({Name: "Deleted Team", Logo: "Deleted Logo", ID: 0, Update: "This team has been deleted."}));
    }


    //Function adding Teams
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
        return newTeam.ID;
    }

    //function to delete teams
    function del_team (uint _id) public{
        require(msg.sender == Ownable.owner());

        //make sure the team hasn't already been deleted and team reference actually exists in array.
        require(TeamtoArray[_id]> 0 && TeamtoArray[_id] < get_Total_Teams());  

        Teams[TeamtoArray[_id]] = Teams[Teams.length - 1];
        TeamtoArray[Teams[Teams.length - 1].ID] = TeamtoArray[_id];

        Teams.pop();
        TeamtoArray[_id] = 0;
    }

    //function to add whitelist for a team
    function add_team_whitelist(uint _ID, address _addr) public {
        require(msg.sender == Ownable.owner());
        require(_ID < TeamIDCount);
        require(TeamtoArray[_ID]> 0); //team not deleted

        team_whitelist[_ID][_addr]=true;
    }


    //function to remove whitelist for a team
    function del_team_whitelist(uint _ID, address _addr) public {
        require(msg.sender == Ownable.owner());
        require(_ID < TeamIDCount);
        require(TeamtoArray[_ID]> 0); //team not deleted

        team_whitelist[_ID][_addr]=false;
    }

    
    //function to see if an address is admin
    function is_admin_addr() public view returns (bool){
        return (msg.sender == Ownable.owner());
    }

    //function to get the admin page
    function get_admin_page() public view returns (string memory){
        require (msg.sender == Ownable.owner());
        return admin_page;
    }


    //function to set the admin page
    function set_admin_page(string memory _url) public {
        require (msg.sender == Ownable.owner());
        admin_page = _url;
    }


    //function to check to see if an address is whitelisted for a team
    function is_addr_whitelisted(uint _ID) public view returns (bool){
        require(_ID < TeamIDCount);
        require(TeamtoArray[_ID]> 0); //team not deleted
        return team_whitelist[_ID][msg.sender];
    }


    //function to update team update, can be called by anyone whitelisted for that team
    function add_team_update(uint _ID, string memory _update) public {
        require(TeamtoArray[_ID]> 0); //team not deleted
        require(_ID < TeamIDCount);
        require(team_whitelist[_ID][msg.sender]==true);
        Teams[TeamtoArray[_ID]].Update = _update;
    }

    //function to update team logo, can be called by anyone whitelisted for that team
    function update_team_logo(uint _ID, string memory _logo) public {
        require(TeamtoArray[_ID]> 0); //team not deleted
        require(_ID < TeamIDCount );
        require(team_whitelist[_ID][msg.sender]==true);
        Teams[TeamtoArray[_ID]].Logo = _logo;
    }

    //function to update team name, can be called by anyone whitelisted for that team
    function update_team_name(uint _ID, string memory _name) public {
        require(TeamtoArray[_ID]> 0); //team not deleted
        require(_ID < TeamIDCount); 
        require(team_whitelist[_ID][msg.sender]==true);
        Teams[TeamtoArray[_ID]].Logo = _name;
    }

    //return the total number of teams
    function get_Total_Teams() public view returns (uint) {
        return Teams.length;
    }

    //return team update
    function get_team_update (uint _ID) public view returns (string memory){
        require(_ID < TeamIDCount);
        return Teams[TeamtoArray[_ID]].Update;
    }

    //return team name
    function get_team_name (uint _ID) public view returns (string memory){
        require(_ID < TeamIDCount);
        return Teams[TeamtoArray[_ID]].Name;
    }
    
    //return team logo
    function get_team_logo (uint _ID) public view returns (string memory){
        require(_ID < TeamIDCount);
        return Teams[TeamtoArray[_ID]].Logo;
    }
    
    //get the list of all teams
    function get_teams() public view returns(Team[] memory){
        return Teams;
    }

}
