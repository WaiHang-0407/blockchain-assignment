//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ballot {

struct Voter {

uint weight;

bool voted;

uint8 vote;

}

struct Proposal {

uint proposalID;

string topic;

uint voteCount;

}

uint public proposalCount=0;

uint public VoterCount=0;

address public chairperson;

//Voter struct is used to define a mapping of address.

mapping(address => Voter) voters;

Proposal[] public proposals;

constructor (){

chairperson = msg.sender;

voters[chairperson].weight = 2;

}
function addProposalDetail(uint _id, string memory _subjectProposal) public {

Proposal memory b = Proposal(_id, _subjectProposal, 0);

proposals.push(b);

proposalCount++;

}

// Give $(toVoter) the right to vote on this ballot.

// May only be called by $(chairperson). Instead of use if statement to do validation of chairperson,we can use CUSTOM MODIFIER

function register(address toVoter) public {

if (msg.sender != chairperson || voters[toVoter].voted) return;

voters[toVoter].weight = 1;

voters[toVoter].voted = false;

VoterCount ++;

}

/// Give a single vote to proposal $(toProposal).

function vote(uint8 toProposal) public {

Voter storage sender = voters[msg.sender];

if (sender.voted || toProposal >= proposals.length) return;

sender.voted = true;

sender.vote = toProposal;

proposals[toProposal].voteCount += sender.weight;

}

function winningProposal() public view returns (uint8 _winningProposal) {

uint256 winningVoteCount = 0;

for (uint8 prop = 0; prop < proposals.length; prop++)

if (proposals[prop].voteCount > winningVoteCount) {

winningVoteCount = proposals[prop].voteCount;

_winningProposal = prop;

}

}

}