pragma solidity ^0.4.0;

contract StateTransV2 {

//Stage is enumerated variable, it is a Data Type

enum Stage {Init, Reg, Vote, Done}

Stage public stage; //stage is a data variable

uint startTime;

uint public timeNow;

constructor () public {

stage = Stage.Init;

startTime = now;

}

//Assuming the Stage change has to be enacted APPROX every 1 mintute

//timeNow variable is defined for understanding the process, you can simply use "now" Solidity defined variable

// Of course, time duration for the Stages may depend on your application

//1 minutes is set to illustrate the working

function advanceState () public {

timeNow = now;

// 1 minutes is too long for the demo time, change to 10 seconds

if (timeNow > (startTime+ 1 minutes))

{

startTime = timeNow;

if (stage == Stage.Init) {stage = Stage.Reg; return;}

if (stage == Stage.Reg) {stage = Stage.Vote; return;}

if (stage == Stage.Vote) {stage = Stage.Done; return;}

return;

}

}

}