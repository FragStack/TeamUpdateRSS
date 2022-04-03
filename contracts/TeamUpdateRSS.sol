//SPDX-License-Identifier: MIT
//@title: a contract that allows teams to provide updates on the blockchain. Whitelisted team members can add updates. Owner can add/remote teams or whitelisted team memebers.
//@author: Dysan & FragStack Crew
//contract addr: 0xAae8575034Ae134340a654B1AC0CfaaFae0A5969

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TeamUpdateRSS is Ownable {

    //@dev: Team schema for team data    
    struct Team {
        string name;
        string logo;
        uint id;
        string update;
    }

    //@dev: Event for when an item for the teams array is updated.
    event TeamsUpdated();

    
    //@dev: This is the TeamID Counter. TeamIDs are not reused for deleted teams. It will keep incrementing Team IDs for new teams.
    uint public teamIDCount;
    
    //@dev: This is a mapping to test if an address is whitelisted for a team. mapping [TEAMID][ADDRESS].
    //@return: bool
    mapping (uint => mapping(address => bool)) public teamWhitelist; 

    //@dev:maps team ID to location of teams array
    mapping (uint => uint) internal teamToArray; 
    
    //@dev: admin webpage string
    string public adminPage ="https://google.com"; 

    //@dev: teams Array. Only active teams are stored in this array. Deleted teams are removed from this array.
    Team[] public teams;

    constructor() {
        require(msg.sender != address(0), "msg.sender is address 0");
        console.log("We have been constructed by: %s ", Ownable.owner());
        //@dev: Item 0 in teams array is the deleted item place holder. All deleted teams will point this this item.
        teams.push(Team({name: "Deleted Team", logo: "Deleted Logo", id: 0, update: "This team has been deleted."}));
    }

    //@notice: function to add new teams. Can only be called by contract owner.
    //@param: string memory _name - This is the team name
    //@param: string memory _logo - This is URL for team logo
    //@param: string memory _update - This is the team update
    //@return: the function will return the TeamID
    function addTeam (string memory _name, string memory _logo, string memory _update) public returns (uint){
        require(msg.sender == Ownable.owner(), "Caller is not owner.");
        Team memory newTeam;
        newTeam.name = _name;
        newTeam.logo = _logo;
        newTeam.id = teamIDCount;
        teamWhitelist[teamIDCount][msg.sender]=true;
        teamToArray[teamIDCount] = teams.length;
        newTeam.update = _update;
        teamIDCount++;
        teams.push(newTeam);
        emit TeamsUpdated();
        return newTeam.id;
    }

    
    //@notice: function to delete teams. Can only be called by contract owner.
    //@param: uint _id - This is the team id
    function delTeam (uint _id) public {
        require(msg.sender == Ownable.owner(), "Caller is not owner.");

        //make sure the team hasn't already been deleted and team reference actually exists in array.
        require(teamToArray[_id]> 0 && teamToArray[_id] < getTotalteams(), "ID not valid.");  

        //delete by shifting last element to the deleted object place.
        teams[teamToArray[_id]] = teams[teams.length - 1];

        //update the teamToArray reference for the last item you moved.
        teamToArray[teams[teams.length - 1].id] = teamToArray[_id];

        //pop the last element of array.
        teams.pop();
        
        //set the deleted item to point to teams array element 0 (place holder for deleted items)
        teamToArray[_id] = 0;
        emit TeamsUpdated();
    }

    //@notice: function to add a wallet address to the whitelist for a team. Can only be called by contract owner.
    //@param: uint _id - This is the team id
    //@param: address _addr - This is the wallet address to be whitelisted
    function addTeamWhitelist(uint _id, address _addr) public {
        //make sure the owner is calling this function, the ID is valid and has not been deleted.
        require(msg.sender == Ownable.owner() && _id < teamIDCount && teamToArray[_id]> 0, "ID not valid.");
        teamWhitelist[_id][_addr]=true;
    }


    //@notice: function to remove a wallet address from the whitelist for a team. Can only be called by contract owner.
    //@param: uint _id - This is the team id
    //@param: address _addr - This is the wallet address to be removed from thewhitelist
    function delTeamWhitelist(uint _id, address _addr) public {
        //make sure the owner is calling this function, the ID is valid and has not been deleted.
        require(msg.sender == Ownable.owner() && _id < teamIDCount && teamToArray[_id]> 0, "ID not valid.");
        teamWhitelist[_id][_addr]=false;
    }

    //@notice: function to see if the caller is the admin (owner)
    //@return: bool - true - if caller is admin (owner)
    //              - false - if caller is not admin (owner)
    function isAdminAddr() public view returns (bool){
        return (msg.sender == Ownable.owner());
    }

    //@notice: function to get the admin page. Requires owner.
    //@return: string - admin URL for contract
    function getAdminPage() public view returns (string memory){
        require (msg.sender == Ownable.owner(), "Caller is not owner.");
        return adminPage;
    }

    //@notice: function to set the admin page. Requires owner.
    //@param: string memory _url - The URL of the admin page
    function setAdminPage(string memory _url) public {
        require (msg.sender == Ownable.owner(), "Caller is not owner.");
        adminPage = _url;
    }

    //@notice: function to check to see if the caller's address is whitelisted for a team
    //@param: uint _id - team id to check to see if caller's address is whitelisted.
    //@return: bool - true - the address is whitelisted for the team
    //              - false - the address is not whitelisted for the team
    function isAddrWhitelisted(uint _id) public view returns (bool){
        //Check to see if the ID is valid and has not been deleted.
        require(_id < teamIDCount && teamToArray[_id]> 0, "ID not valid.");
        return teamWhitelist[_id][msg.sender];
    }


    
    //@notice: function to update the team update, can be called by anyone that has been whitelisted for that team
    //@param: uint _id - team id for the team
    //@param: string memory _update - team update
    function addTeamUpdate(uint _id, string memory _update) public {
        //make sure the caller is whitelisted, the ID is valid and has not been deleted.
        require(teamWhitelist[_id][msg.sender]==true && teamToArray[_id]> 0 && _id < teamIDCount, "ID not valid."); 
        teams[teamToArray[_id]].update = _update;
        emit TeamsUpdated();
    }

    
    //@notice: function to update team logo, can be called by anyone whitelisted for that team
    //@param: uint _id - team id for the team
    //@param: string memory _logo - team logo URL
    function updateTeamLogo(uint _id, string memory _logo) public {
        //make sure the caller is whitelisted, the ID is valid and has not been deleted.
        require(teamWhitelist[_id][msg.sender]==true && teamToArray[_id]> 0 && _id < teamIDCount, "ID not valid."); 
        teams[teamToArray[_id]].logo = _logo;
        emit TeamsUpdated();
    }


    //@notice: function to update team name, can be called by anyone whitelisted for that team
    //@param: uint _id - team id for the team
    //@param: string memory _logo - team name
    function updateTeamName(uint _id, string memory _name) public {
        //make sure the caller is whitelisted, the ID is valid and has not been deleted.
        require(teamWhitelist[_id][msg.sender]==true && teamToArray[_id]> 0 && _id < teamIDCount , "ID not valid."); 
        teams[teamToArray[_id]].name = _name;
        emit TeamsUpdated();
    }

    //@notice: function to return the total number of teams
    //@return: uint - returns the total number of items in the teams array
    function getTotalteams() public view returns (uint) {
        return teams.length;
    }

    
    //@notice: function to return the team update
    //@return: string memory - returns the team update
    function getTeamUpdate (uint _id) public view returns (string memory){
        require(_id < teamIDCount, "ID is too big");
        return teams[teamToArray[_id]].update;
    }


    //@notice: function to return the team name
    //@return: string memory - returns the team name
    function getTeamName (uint _id) public view returns (string memory){
        require(_id < teamIDCount, "ID is too big");
        return teams[teamToArray[_id]].name;
    }
    
    //@notice: function to return the team logo
    //@return: string memory - returns the team logo
    function getTeamLogo (uint _id) public view returns (string memory){
        require(_id < teamIDCount, "ID is too big");
        return teams[teamToArray[_id]].logo;
    }
    

    //@notice: function to get all teams
    //@return: Team[] memory - returns the team struct array for all teams
    function getTeams() public view returns(Team[] memory){
        return (teams);
    }

    //@notice: function to construct a bool[] memory of whitelisted teams of an address. The location of the true corresponds to the teams array. Example: if bool[1] = true, it means the address is whitelisted for item 1 of teams[] array.
    //@return: bool[] memory - returns an array of boolean to specify the teams the address is whitelisted for
    function getWhitelistedTeamsForAddress(address adr) public view returns (bool[] memory){
        uint len = teams.length;
        bool[] memory whitelistedID = new bool[](len);
        for (uint i=1 ; i < len ; i++){
            if (teamWhitelist[teams[i].id][adr] == true){
                whitelistedID[i] = true;
            }
        }
        return (whitelistedID);
    }

    //@notice: function to get all teams and whitelisted teams for the msg.sender
    //@return: Team[] memory, bool[] memory - returns the team struct array for all teams and bool[] of which teams the caller is whitelisted for
    function getTeamsAndWhitelist() public view returns (Team[] memory, bool[] memory){
        return(getTeams(), getWhitelistedTeamsForAddress(msg.sender));
    }
}
